"""
Firebase Firestore 数据库连接
替换原来的 MySQL database.py
"""

import os
import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime, date
from typing import Optional

# 初始化 Firebase Admin SDK
def init_firebase():
    """初始化 Firebase，如果还没有初始化的话"""
    if not firebase_admin._apps:
        # 尝试从环境变量获取密钥文件路径
        service_account_path = os.getenv('GOOGLE_APPLICATION_CREDENTIALS')
        
        # 如果没有环境变量，尝试默认路径
        if not service_account_path:
            # 尝试当前目录下的密钥文件
            possible_paths = [
                'flutter-ai-playground-59e0e-firebase-adminsdk-fbsvc-79858a6bea.json',
                'service-account-key.json',
            ]
            
            for path in possible_paths:
                if os.path.exists(path):
                    service_account_path = path
                    break
        
        if service_account_path and os.path.exists(service_account_path):
            cred = credentials.Certificate(service_account_path)
            firebase_admin.initialize_app(cred)
        else:
            raise Exception(
                "Firebase 服务账号密钥文件未找到。"
                "请设置环境变量 GOOGLE_APPLICATION_CREDENTIALS 或"
                "将密钥文件放在当前目录下。"
            )
    
    return firestore.client()

# 初始化 Firestore 客户端
db = init_firebase()

# 辅助函数：转换 datetime/date 对象
def convert_to_firestore_datetime(dt):
    """将 datetime 或 date 转换为 Firestore 兼容格式"""
    if dt is None:
        return None
    if isinstance(dt, date) and not isinstance(dt, datetime):
        return datetime.combine(dt, datetime.min.time())
    return dt

# 辅助函数：从 Firestore 文档获取数据
def doc_to_dict(doc, include_id=True):
    """将 Firestore 文档转换为字典"""
    if not doc.exists:
        return None
    
    data = doc.to_dict()
    if include_id:
        data['id'] = int(doc.id) if doc.id.isdigit() else doc.id
    return data

# 辅助函数：处理时间戳
def get_timestamp():
    """获取当前时间戳"""
    return datetime.now()

