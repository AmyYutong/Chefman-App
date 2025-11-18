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
            current_dir = os.path.dirname(os.path.abspath(__file__))
            possible_paths = [
                os.path.join(current_dir, 'flutter-ai-playground-59e0e-firebase-adminsdk-fbsvc-79858a6bea.json'),
                os.path.join(current_dir, 'service-account-key.json'),
                'flutter-ai-playground-59e0e-firebase-adminsdk-fbsvc-79858a6bea.json',
                'service-account-key.json',
            ]
            
            for path in possible_paths:
                if os.path.exists(path):
                    service_account_path = os.path.abspath(path)
                    break
        
        if service_account_path and os.path.exists(service_account_path):
            if not os.path.isabs(service_account_path):
                service_account_path = os.path.abspath(service_account_path)
            
            try:
                cred = credentials.Certificate(service_account_path)
                firebase_admin.initialize_app(cred)
                print(f"✅ Firebase initialized successfully, using credentials file: {service_account_path}")
            except Exception as e:
                error_msg = str(e)
                if "invalid_grant" in error_msg or "Invalid JWT Signature" in error_msg:
                    raise Exception(
                        f"❌ Firebase 认证失败：密钥文件可能已过期或被撤销。\n"
                        f"请重新下载 Firebase 服务账号密钥文件。\n"
                        f"当前使用的密钥文件: {service_account_path}\n"
                        f"错误详情: {error_msg}\n\n"
                        f"解决步骤：\n"
                        f"1. 访问 Firebase Console: https://console.firebase.google.com/\n"
                        f"2. 选择项目: flutter-ai-playground-59e0e\n"
                        f"3. 进入 Project Settings → Service Accounts\n"
                        f"4. 点击 'Generate New Private Key'\n"
                        f"5. 下载新的密钥文件并替换当前文件"
                    )
                else:
                    raise Exception(f"❌ Firebase 初始化失败: {error_msg}")
        else:
            raise Exception(
                "❌ Firebase 服务账号密钥文件未找到。\n"
                "请设置环境变量 GOOGLE_APPLICATION_CREDENTIALS 或\n"
                "将密钥文件放在 Backend 目录下。"
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

