import asyncio
import json
import os
from datetime import datetime
from typing import Dict, Set

from websockets import serve
from websockets.exceptions import ConnectionClosed

class FamilyCircle:
    def __init__(self, circle_id: str, master_password: str):
        self.circle_id = circle_id
        self.master_password = master_password
        self.member_device_ids: Set[str] = set()
        self.messages: List[Dict] = []

class Server:
    def __init__(self):
        self.circles: Dict[str, FamilyCircle] = {}
        self.clients: Dict[str, Set] = {}  # device_id -> set of WebSocket connections

    async def handle_connection(self, websocket, path):
        try:
            # Аутентификация
            auth_message = await websocket.recv()
            auth_data = json.loads(auth_message)
            
            if auth_data['type'] != 'auth':
                await websocket.close()
                return

            nickname = auth_data['nickname']
            device_id = auth_data['deviceId']

            # Создаем запись клиента
            if device_id not in self.clients:
                self.clients[device_id] = set()
            self.clients[device_id].add(websocket)

            while True:
                try:
                    message = await websocket.recv()
                    data = json.loads(message)

                    if data['type'] == 'create_circle':
                        circle = FamilyCircle(
                            data['circle']['id'],
                            data['circle']['masterPassword']
                        )
                        self.circles[circle.circle_id] = circle
                        await websocket.send(json.dumps({
                            'type': 'circle_created',
                            'circleId': circle.circle_id
                        }))

                    elif data['type'] == 'join_circle':
                        circle = self.circles.get(data['circleId'])
                        if not circle or circle.master_password != data['masterPassword']:
                            await websocket.send(json.dumps({
                                'type': 'error',
                                'message': 'Неверный мастер-пароль'
                            }))
                            continue

                        circle.member_device_ids.add(device_id)
                        await websocket.send(json.dumps({
                            'type': 'circle_joined',
                            'circleId': circle.circle_id
                        }))

                    elif data['type'] == 'message':
                        circle = None
                        for c in self.circles.values():
                            if device_id in c.member_device_ids:
                                circle = c
                                break

                        if not circle:
                            await websocket.send(json.dumps({
                                'type': 'error',
                                'message': 'Не найден семейный круг'
                            }))
                            continue

                        message_data = {
                            'type': 'message',
                            'text': data['text'],
                            'sender': nickname,
                            'timestamp': datetime.now().isoformat(),
                        }

                        # Отправляем сообщение всем членам круга
                        for device in circle.member_device_ids:
                            if device in self.clients:
                                for ws in self.clients[device]:
                                    try:
                                        await ws.send(json.dumps(message_data))
                                    except ConnectionClosed:
                                        continue

                except json.JSONDecodeError:
                    continue

        except ConnectionClosed:
            # Удаляем соединение при отключении
            if device_id in self.clients:
                self.clients[device_id].remove(websocket)
                if not self.clients[device_id]:
                    del self.clients[device_id]

    async def start(self):
        port = int(os.getenv('PORT', '10000'))  # Используем 10000 по умолчанию, если PORT не установлен
        server = await serve(self.handle_connection, '0.0.0.0', port)
        print(f'Server started on port {port}')
        return server

if __name__ == '__main__':
    server = Server()
    asyncio.get_event_loop().run_until_complete(server.start())
    asyncio.get_event_loop().run_forever()
