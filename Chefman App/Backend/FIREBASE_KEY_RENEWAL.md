# Firebase 密钥更新指南

## 问题症状

如果看到以下错误：
```
invalid_grant: Invalid JWT Signature
```

这表示 Firebase 服务账号密钥文件已过期或被撤销，需要重新下载。

## 解决步骤

### 1. 访问 Firebase Console

打开浏览器，访问：https://console.firebase.google.com/

### 2. 选择项目

选择你的 Firebase 项目：**flutter-ai-playground-59e0e**

### 3. 进入 Service Accounts 页面

1. 点击左上角的 **⚙️ 设置图标**
2. 选择 **Project settings**
3. 切换到 **Service accounts** 标签页

### 4. 生成新的私钥

1. 在页面底部找到 **"Generate new private key"** 按钮
2. 点击按钮
3. 会弹出警告对话框，点击 **"Generate key"**
4. 浏览器会自动下载一个新的 JSON 密钥文件

### 5. 替换旧密钥文件

1. 将下载的 JSON 文件重命名为：
   ```
   flutter-ai-playground-59e0e-firebase-adminsdk-fbsvc-79858a6bea.json
   ```

2. 将文件复制到 `Backend` 目录，替换旧文件：
   ```
   /Users/yangyutong/Desktop/Chefman Studio App/Chefman App/Backend/
   ```

3. **重要**：确保文件权限正确（可读）：
   ```bash
   chmod 644 flutter-ai-playground-59e0e-firebase-adminsdk-fbsvc-79858a6bea.json
   ```

### 6. 重启后端服务器

1. 停止当前运行的后端服务器（如果正在运行）
2. 重新启动服务器：
   ```bash
   cd Backend
   export GOOGLE_APPLICATION_CREDENTIALS="flutter-ai-playground-59e0e-firebase-adminsdk-fbsvc-79858a6bea.json"
   uvicorn main:app --reload --host 0.0.0.0 --port 8000
   ```

### 7. 验证连接

服务器启动后，应该看到：
```
✅ Firebase initialized successfully, using credentials file: /path/to/keyfile.json
```

## 注意事项

- ⚠️ **安全提示**：密钥文件包含敏感信息，不要提交到 Git 仓库
- ⚠️ 如果 `.gitignore` 中没有忽略 `.json` 文件，请添加：
  ```
  Backend/*.json
  Backend/flutter-ai-playground-59e0e-firebase-adminsdk-*.json
  ```
- ✅ 新密钥文件会立即生效，无需等待
- ✅ 旧密钥文件在生成新密钥后会自动失效

## 验证连接

测试 Firebase 连接：
```bash
cd Backend
python3 -c "import firebase_db; db = firebase_db.init_firebase(); print('✅ Firebase connected!')"
```

如果成功，会显示：
```
✅ Firebase initialized successfully, using credentials file: ...
✅ Firebase connected!
```

## 如果仍然失败

如果更新密钥后仍然无法连接，请检查：

1. **文件路径**：确保密钥文件在 `Backend` 目录下
2. **文件格式**：确保 JSON 文件格式正确，没有损坏
3. **网络连接**：确保可以访问 Google 服务
4. **防火墙**：确保没有阻止对 Firebase 的访问
5. **项目权限**：确保服务账号有访问 Firestore 的权限

## 联系支持

如果问题仍然存在，请提供：
- 完整的错误信息
- 密钥文件的前几行（隐藏敏感信息后）
- 服务器启动日志

