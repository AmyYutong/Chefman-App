# 🚀 如何运行 Chefman Studio API

## 快速启动

### 1. 启动后端服务器

```bash
cd Backend
export GOOGLE_APPLICATION_CREDENTIALS="flutter-ai-playground-59e0e-firebase-adminsdk-fbsvc-79858a6bea.json"
uvicorn main:app --reload --host 127.0.0.1 --port 8000
```

### 2. 验证服务器运行

打开浏览器访问：
- API 根路径：http://127.0.0.1:8000
- API 文档：http://127.0.0.1:8000/docs
- 交互式 API：http://127.0.0.1:8000/redoc

### 3. 运行 iOS 应用

1. 打开 Xcode
2. 打开项目：`ChefmanApp/ChefmanApp.xcodeproj`
3. 选择目标设备（模拟器或真机）
4. 点击运行按钮（⌘+R）

## 📋 详细步骤

### 后端服务器

#### 方法 1：使用终端（推荐）

```bash
# 1. 进入后端目录
cd "/Users/yangyutong/Desktop/Chefman Studio App/Test/Backend"

# 2. 设置 Firebase 密钥环境变量
export GOOGLE_APPLICATION_CREDENTIALS="flutter-ai-playground-59e0e-firebase-adminsdk-fbsvc-79858a6bea.json"

# 3. 启动服务器
uvicorn main:app --reload --host 127.0.0.1 --port 8000
```

#### 方法 2：创建启动脚本

创建 `start_server.sh`：

```bash
#!/bin/bash
cd "$(dirname "$0")"
export GOOGLE_APPLICATION_CREDENTIALS="flutter-ai-playground-59e0e-firebase-adminsdk-fbsvc-79858a6bea.json"
uvicorn main:app --reload --host 127.0.0.1 --port 8000
```

然后运行：
```bash
chmod +x start_server.sh
./start_server.sh
```

### iOS 应用

1. **打开 Xcode**
   - 双击 `ChefmanApp/ChefmanApp.xcodeproj`

2. **选择运行目标**
   - 在 Xcode 顶部选择模拟器（如 iPhone 15）或连接的设备

3. **运行应用**
   - 点击运行按钮（▶️）或按 `⌘+R`

4. **查看日志**
   - 在 Xcode 底部控制台查看应用日志

## 🔍 检查服务器状态

### 检查服务器是否运行

```bash
curl http://127.0.0.1:8000/
```

应该返回：
```json
{"message":"Chefman Studio API","version":"1.0.0","database":"Firebase Firestore"}
```

### 检查 API 端点

```bash
# 获取用户列表
curl http://127.0.0.1:8000/users

# 获取食谱列表
curl http://127.0.0.1:8000/recipes
```

## ⚠️ 常见问题

### 问题 1：服务器启动失败

**错误**：`ModuleNotFoundError: No module named 'firebase_admin'`

**解决**：
```bash
cd Backend
pip3 install -r requirements.txt
```

### 问题 2：Firebase 连接失败

**错误**：`Firebase 服务账号密钥文件未找到`

**解决**：
- 确保 `flutter-ai-playground-59e0e-firebase-adminsdk-fbsvc-79858a6bea.json` 文件在 `Backend` 目录下
- 检查环境变量是否正确设置

### 问题 3：端口被占用

**错误**：`Address already in use`

**解决**：
```bash
# 查找占用端口的进程
lsof -ti:8000

# 杀死进程
kill -9 $(lsof -ti:8000)

# 或使用其他端口
uvicorn main:app --reload --host 127.0.0.1 --port 8001
```

### 问题 4：iOS 应用无法连接服务器

**检查**：
1. 确保后端服务器正在运行
2. 检查 `APIConfig.swift` 中的 `baseURL` 是否正确
3. 在模拟器中，使用 `http://127.0.0.1:8000`
4. 在真机上，需要使用你的 Mac 的 IP 地址（如 `http://192.168.1.100:8000`）

## 📱 iOS 应用配置

### Debug 模式（开发）
- 使用本地服务器：`http://127.0.0.1:8000`
- 在模拟器中运行

### Release 模式（TestFlight/生产）
- 需要更新 `APIConfig.swift` 中的生产环境 URL
- 确保后端服务器已部署到公网

## 🛠️ 开发工作流

1. **启动后端服务器**
   ```bash
   cd Backend
   export GOOGLE_APPLICATION_CREDENTIALS="flutter-ai-playground-59e0e-firebase-adminsdk-fbsvc-79858a6bea.json"
   uvicorn main:app --reload
   ```

2. **在 Xcode 中运行 iOS 应用**
   - 打开项目
   - 选择模拟器
   - 运行（⌘+R）

3. **测试功能**
   - 登录/注册
   - 浏览食谱
   - 创建食谱
   - 收藏/点赞

## 📊 服务器日志

服务器运行时会显示：
- 请求日志
- 错误信息
- 数据库操作

查看实时日志以调试问题。

---

**需要帮助？** 检查服务器日志和 Xcode 控制台输出。

