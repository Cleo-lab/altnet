import asyncio
import json
import os
import logging
from datetime import datetime
from typing import Dict, Set, List

from websockets import serve
from websockets.exceptions import ConnectionClosed

# Настройка логирования
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger('altnet_server')

class FamilyCircle:
    def __init__(self, circle_id: str, master_password: str):
        self.circle_id = circle_id
        self.master_password = master_password
        self.member_device_ids: Set[str] = set()
        self.messages: List[Dict] = []
        self.created_at = datetime.now()

class Server:
    def __init__(self):
        self.circles: Dict[str, FamilyCircle] = {}
        self.clients: Dict[str, Set] = {}  # device_id -> set of WebSocket connections
        logger.info("Server initialized")

    async def handle_connection(self, websocket, path):
        device_id = None
        nickname = None
        
        try:
            # Аутентификация
            auth_message = await websocket.recv()
            auth_data = json.loads(auth_message)
            
            if auth_data['type'] != 'auth':
                logger.warning(f"Invalid auth message type: {auth_data.get('type')}")
                await websocket.close(1008, "Invalid auth message type")
                return

            nickname = auth_data['nickname']
            device_id = auth_data['deviceId']
            
            logger.info(f"New connection from {nickname} (device: {device_id})")

            # Создаем запись клиента
            if device_id not in self.clients:
                self.clients[device_id] = set()
            self.clients[device_id].add(websocket)

            # Отправляем подтверждение аутентификации
            await websocket.send(json.dumps({
                'type': 'auth_success',
                'message': 'Successfully authenticated'
            }))

            while True:
                try:
                    message = await websocket.recv()
                    data = json.loads(message)
                    logger.debug(f"Received message from {nickname}: {data['type']}")

                    if data['type'] == 'create_circle':
                        if data['circle']['id'] in self.circles:
                            await websocket.send(json.dumps({
                                'type': 'error',
                                'message': 'Circle with this ID already exists'
                            }))
                            continue

                        circle = FamilyCircle(
                            data['circle']['id'],
                            data['circle']['masterPassword']
                        )
                        self.circles[circle.circle_id] = circle
                        circle.member_device_ids.add(device_id)
                        
                        logger.info(f"Created new circle {circle.circle_id} by {nickname}")
                        
                        await websocket.send(json.dumps({
                            'type': 'circle_created',
                            'circleId': circle.circle_id
                        }))

                    elif data['type'] == 'join_circle':
                        circle = self.circles.get(data['circleId'])
                        if not circle:
                            await websocket.send(json.dumps({
                                'type': 'error',
                                'message': 'Circle not found'
                            }))
                            continue

                        if circle.master_password != data['masterPassword']:
                            logger.warning(f"Failed join attempt for circle {data['circleId']} by {nickname}")
                            await websocket.send(json.dumps({
                                'type': 'error',
                                'message': 'Неверный мастер-пароль'
                            }))
                            continue

                        circle.member_device_ids.add(device_id)
                        logger.info(f"{nickname} joined circle {circle.circle_id}")
                        
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
                            'senderId': nickname,
                            'recipientId': 'group',
                            'content': data['content'],
                            'sentAt': datetime.now().isoformat(),
                        }

                        logger.info(f"New message in circle {circle.circle_id} from {nickname}")

                        # Отправляем сообщение всем членам круга
                        for device in circle.member_device_ids:
                            if device in self.clients:
                                for ws in self.clients[device]:
                                    try:
                                        await ws.send(json.dumps(message_data))
                                    except ConnectionClosed:
                                        logger.warning(f"Failed to send message to device {device}")
                                        continue

                except json.JSONDecodeError as e:
                    logger.error(f"JSON decode error: {e}")
                    continue
                except Exception as e:
                    logger.error(f"Error processing message: {e}")
                    await websocket.send(json.dumps({
                        'type': 'error',
                        'message': 'Internal server error'
                    }))

        except ConnectionClosed:
            logger.info(f"Connection closed for {nickname} (device: {device_id})")
        except Exception as e:
            logger.error(f"Unexpected error: {e}")
        finally:
            # Удаляем соединение при отключении
            if device_id and device_id in self.clients:
                self.clients[device_id].remove(websocket)
                if not self.clients[device_id]:
                    del self.clients[device_id]
                    logger.info(f"Removed all connections for device {device_id}")

    async def start(self):
        port = int(os.getenv('PORT', '10000'))
        server = await serve(self.handle_connection, '0.0.0.0', port)
        logger.info(f'Server started on port {port}')
        return server

if __name__ == '__main__':
    server = Server()
    asyncio.get_event_loop().run_until_complete(server.start())
    logger.info("Server is running...")
    asyncio.get_event_loop().run_forever()
