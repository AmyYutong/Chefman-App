#!/usr/bin/env python3
"""
更新用户文档，添加或更新 'id' 字段
"""

import firebase_db
from firebase_db import db, doc_to_dict, get_timestamp

def update_user_ids():
    """更新所有用户的 id 字段"""
    
    print("=" * 60)
    print("更新用户 ID 字段")
    print("=" * 60)
    
    # 初始化 Firebase
    firebase_db.init_firebase()
    
    # 获取所有用户
    print("\n加载用户...")
    users_ref = db.collection('users')
    users_to_update = []
    
    for doc in users_ref.limit(1000).get():
        user_data = doc_to_dict(doc)
        if user_data:
            doc_id = doc.id
            # 计算用户 ID
            if doc_id.isdigit():
                user_id = int(doc_id)
            else:
                user_id = abs(hash(doc_id)) % (10**9)
            
            current_id = user_data.get('id')
            needs_update = False
            
            # 检查是否需要更新
            if current_id is None:
                needs_update = True
            elif isinstance(current_id, str):
                needs_update = True
            elif current_id != user_id:
                needs_update = True
            
            if needs_update:
                users_to_update.append({
                    'doc_id': doc_id,
                    'username': user_data.get('username', 'N/A'),
                    'current_id': current_id,
                    'new_id': user_id
                })
    
    print(f"   ✅ 找到 {len(users_to_update)} 个需要更新的用户\n")
    
    # 更新用户
    updated_count = 0
    for user_info in users_to_update:
        try:
            user_doc_ref = users_ref.document(user_info['doc_id'])
            user_doc_ref.update({
                'id': user_info['new_id'],
                'updated_at': get_timestamp()
            })
            print(f"   ✅ 更新 '{user_info['username']}': {user_info['current_id']} -> {user_info['new_id']}")
            updated_count += 1
        except Exception as e:
            print(f"   ❌ 更新失败 '{user_info['username']}': {e}")
    
    print("\n" + "=" * 60)
    print(f"完成！成功更新 {updated_count}/{len(users_to_update)} 个用户")
    print("=" * 60)

if __name__ == "__main__":
    update_user_ids()

