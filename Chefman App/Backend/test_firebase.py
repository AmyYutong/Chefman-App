#!/usr/bin/env python3
"""Test Firebase connection"""

import sys
import os

print("=" * 50)
print("Firebase Connection Test")
print("=" * 50)

# Check if key file exists
key_file = "flutter-ai-playground-59e0e-firebase-adminsdk-fbsvc-79858a6bea.json"
print(f"\n1. Checking key file: {key_file}")
if os.path.exists(key_file):
    print(f"   ✅ Key file found: {os.path.abspath(key_file)}")
    print(f"   File size: {os.path.getsize(key_file)} bytes")
else:
    print(f"   ❌ Key file NOT found!")
    sys.exit(1)

# Check environment variable
print(f"\n2. Checking GOOGLE_APPLICATION_CREDENTIALS environment variable")
env_var = os.getenv('GOOGLE_APPLICATION_CREDENTIALS')
if env_var:
    print(f"   ✅ Set to: {env_var}")
else:
    print(f"   ⚠️  Not set (will use default path)")

# Try to initialize Firebase
print(f"\n3. Attempting to initialize Firebase...")
try:
    import firebase_db
    db = firebase_db.init_firebase()
    print("   ✅ Firebase initialized successfully!")
except Exception as e:
    print(f"   ❌ Firebase initialization failed!")
    print(f"   Error: {e}")
    sys.exit(1)

# Try to access database
print(f"\n4. Testing database access...")
try:
    collections = list(db.collections())
    print(f"   ✅ Database access successful!")
    print(f"   Found {len(collections)} collections")
    if collections:
        print(f"   Collections: {[c.id for c in collections[:10]]}")
except Exception as e:
    print(f"   ⚠️  Error accessing collections: {e}")
    print(f"   This might be a permissions issue or network problem")

# Try a simple query
print(f"\n5. Testing a simple query...")
try:
    users_ref = db.collection('users')
    users = users_ref.limit(1).get()
    print(f"   ✅ Query successful! Found {len(users)} user(s) in test query")
except Exception as e:
    print(f"   ⚠️  Query error: {e}")

print("\n" + "=" * 50)
print("Test completed!")
print("=" * 50)

