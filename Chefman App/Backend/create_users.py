#!/usr/bin/env python3
"""
创建用户账户脚本
"""

import firebase_db
from firebase_db import db, get_timestamp
from main import get_password_hash
from datetime import datetime

def create_user(username, email, password="chef1234", **kwargs):
    """创建用户账户"""
    users_ref = db.collection('users')
    
    # 检查用户名是否已存在
    username_query = users_ref.where('username', '==', username).limit(1).get()
    if username_query:
        print(f"⚠️ 用户名 '{username}' 已存在，跳过创建")
        return None
    
    # 检查邮箱是否已存在
    email_query = users_ref.where('email', '==', email).limit(1).get()
    if email_query:
        print(f"⚠️ 邮箱 '{email}' 已存在，跳过创建")
        return None
    
    # 生成密码哈希
    hashed_password = get_password_hash(password)
    
    # 创建用户数据
    user_data = {
        'username': username,
        'email': email,
        'password_hash': hashed_password,
        'phone_number': kwargs.get('phone_number'),
        'first_name': kwargs.get('first_name'),
        'last_name': kwargs.get('last_name'),
        'gender': kwargs.get('gender', 'Not specified'),
        'birth_date': kwargs.get('birth_date'),
        'bio': kwargs.get('bio'),
        'profile_image_url': kwargs.get('profile_image_url'),
        'address': kwargs.get('address'),
        'city': kwargs.get('city'),
        'country': kwargs.get('country'),
        'postal_code': kwargs.get('postal_code'),
        'is_active': True,
        'is_verified': False,
        'created_at': get_timestamp(),
        'updated_at': get_timestamp(),
        'last_login_at': None
    }
    
    # 移除 None 值
    user_data = {k: v for k, v in user_data.items() if v is not None}
    
    # 添加到 Firestore
    doc_ref = users_ref.add(user_data)[1]  # add() returns (timestamp, DocumentReference)
    print(f"✅ 用户 '{username}' 创建成功！")
    print(f"   文档 ID: {doc_ref.id}")
    print(f"   邮箱: {email}")
    print(f"   密码: {password}")
    return doc_ref

def main():
    print("=" * 50)
    print("创建用户账户")
    print("=" * 50)
    
    # 初始化 Firebase
    firebase_db.init_firebase()
    
    # 创建用户列表
    users_to_create = [
        {
            'username': 'chef_mason',
            'email': 'chef_mason@chefman.com',
            'password': 'chef1234',
            'first_name': 'Mason',
            'last_name': 'Chef',
            'bio': 'Professional chef specializing in modern Mexican cuisine',
            'gender': 'Male'
        },
        {
            'username': 'chef_luna',
            'email': 'chef_luna@chefman.com',
            'password': 'chef1234',
            'first_name': 'Luna',
            'last_name': 'Chef',
            'bio': 'Expert in Mediterranean and healthy cooking',
            'gender': 'Female'
        },
        {
            'username': 'chef_evelyn',
            'email': 'chef_evelyn@chefman.com',
            'password': 'chef1234',
            'first_name': 'Evelyn',
            'last_name': 'Chef',
            'bio': 'Dessert specialist and pastry chef',
            'gender': 'Female'
        }
    ]
    
    print(f"\n准备创建 {len(users_to_create)} 个用户账户...\n")
    
    created_count = 0
    for user_info in users_to_create:
        try:
            result = create_user(**user_info)
            if result:
                created_count += 1
            print()
        except Exception as e:
            print(f"❌ 创建用户 '{user_info['username']}' 失败: {e}\n")
    
    print("=" * 50)
    print(f"完成！成功创建 {created_count}/{len(users_to_create)} 个用户")
    print("=" * 50)
    print("\n所有用户的默认密码是: chef1234")
    print("请提醒用户首次登录后修改密码。")

if __name__ == "__main__":
    main()

