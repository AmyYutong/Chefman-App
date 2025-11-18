#!/usr/bin/env python3
"""
更新食谱中的 creator 信息，连接到实际的用户账户
"""

import firebase_db
from firebase_db import db, doc_to_dict, get_timestamp

def update_recipe_creators():
    """更新所有食谱的 creator_id 和 creator_username"""
    
    print("=" * 60)
    print("更新食谱 Creator 信息")
    print("=" * 60)
    
    # 初始化 Firebase
    firebase_db.init_firebase()
    
    # 1. 获取所有用户，建立 username -> user_info 映射
    print("\n1. 加载用户账户...")
    users_ref = db.collection('users')
    username_to_user = {}
    
    for doc in users_ref.limit(1000).get():
        user_data = doc_to_dict(doc)
        if user_data:
            username = user_data.get('username', '').strip()
            if username:
                doc_id = doc.id
                # 生成整数 ID
                if doc_id.isdigit():
                    user_id = int(doc_id)
                else:
                    user_id = abs(hash(doc_id)) % (10**9)
                
                username_to_user[username] = {
                    'doc_id': doc_id,
                    'user_id': user_id,
                    'username': username,
                    'email': user_data.get('email', '')
                }
    
    print(f"   ✅ 找到 {len(username_to_user)} 个用户账户")
    print(f"   用户列表: {', '.join(sorted(username_to_user.keys()))}")
    
    # 2. 获取所有食谱
    print("\n2. 加载食谱...")
    recipes_ref = db.collection('recipes')
    recipes_to_update = []
    
    for doc in recipes_ref.limit(1000).get():
        recipe_data = doc_to_dict(doc)
        if recipe_data:
            creator_username = recipe_data.get('creator_username', '').strip()
            current_creator_id = recipe_data.get('creator_id')
            
            recipes_to_update.append({
                'doc_id': doc.id,
                'title': recipe_data.get('title', 'N/A'),
                'current_creator_username': creator_username,
                'current_creator_id': current_creator_id,
                'recipe_data': recipe_data
            })
    
    print(f"   ✅ 找到 {len(recipes_to_update)} 个食谱")
    
    # 3. 更新食谱
    print("\n3. 更新食谱 creator 信息...")
    updated_count = 0
    skipped_count = 0
    error_count = 0
    
    for recipe in recipes_to_update:
        doc_id = recipe['doc_id']
        title = recipe['title']
        creator_username = recipe['current_creator_username']
        
        if not creator_username:
            print(f"   ⚠️  跳过 '{title[:40]}': 没有 creator_username")
            skipped_count += 1
            continue
        
        # 查找对应的用户
        if creator_username in username_to_user:
            user_info = username_to_user[creator_username]
            new_creator_id = user_info['user_id']
            new_creator_username = user_info['username']
            
            # 检查是否需要更新
            current_id = recipe['current_creator_id']
            needs_update = False
            
            # 如果 creator_id 不匹配，需要更新
            if current_id != new_creator_id:
                if isinstance(current_id, str) or isinstance(current_id, int):
                    if str(current_id) != str(new_creator_id):
                        needs_update = True
                else:
                    needs_update = True
            
            if needs_update:
                try:
                    # 更新食谱文档
                    recipe_doc_ref = recipes_ref.document(doc_id)
                    recipe_doc_ref.update({
                        'creator_id': new_creator_id,
                        'creator_username': new_creator_username,
                        'updated_at': get_timestamp()
                    })
                    print(f"   ✅ 更新 '{title[:40]}': {creator_username} (ID: {current_id} -> {new_creator_id})")
                    updated_count += 1
                except Exception as e:
                    print(f"   ❌ 更新失败 '{title[:40]}': {e}")
                    error_count += 1
            else:
                print(f"   ✓  已正确 '{title[:40]}': {creator_username} (ID: {current_id})")
        else:
            print(f"   ⚠️  跳过 '{title[:40]}': 用户 '{creator_username}' 不存在")
            skipped_count += 1
    
    # 4. 总结
    print("\n" + "=" * 60)
    print("更新完成！")
    print("=" * 60)
    print(f"✅ 成功更新: {updated_count} 个食谱")
    print(f"✓  已正确: {len(recipes_to_update) - updated_count - skipped_count - error_count} 个食谱")
    print(f"⚠️  跳过: {skipped_count} 个食谱（无 creator_username 或用户不存在）")
    if error_count > 0:
        print(f"❌ 错误: {error_count} 个食谱")
    print("=" * 60)

if __name__ == "__main__":
    update_recipe_creators()

