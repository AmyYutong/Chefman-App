# 如何抑制系统日志（System Logs）

## 问题
在 Xcode 控制台中看到类似这样的系统日志：
```
load_eligibility_plist: Failed to open ... eligibility.plist: No such file or directory(2)
```

这些是 iOS 系统级别的日志，不影响应用功能，但会干扰开发调试。

## 解决方案

### 方法 1：在 Xcode Scheme 中设置环境变量（推荐）

这是最有效的方法，可以完全抑制系统日志：

1. **打开 Xcode Scheme 设置**
   - 在 Xcode 顶部菜单栏，点击 Scheme 选择器（项目名称旁边）
   - 选择 **Edit Scheme...**

2. **添加环境变量**
   - 在左侧选择 **Run**
   - 切换到 **Arguments** 标签
   - 在 **Environment Variables** 部分，点击 **+** 按钮
   - 添加以下环境变量：
     - **Name**: `OS_ACTIVITY_MODE`
     - **Value**: `disable`
   - 确保勾选了复选框（启用该环境变量）

3. **应用设置**
   - 点击 **Close** 保存设置
   - 重新运行应用（⌘+R）

### 方法 2：在 Xcode 控制台中使用过滤器

如果不想禁用所有系统日志，可以在控制台中使用过滤器：

1. 打开 Xcode 控制台（⌘+⇧+Y）
2. 在控制台底部的搜索框输入：
   - `-eligibility` - 隐藏 eligibility 相关日志
   - `-system` - 隐藏部分系统日志
   - 或者只显示你的应用日志：输入你的应用名称

### 方法 3：重置模拟器（临时解决）

有时重置模拟器可以清除这些日志：

1. 在 Xcode 中：**Device** → **Erase All Content and Settings...**
2. 或者使用命令行：
   ```bash
   xcrun simctl erase all
   ```

## 注意事项

- `OS_ACTIVITY_MODE=disable` 会隐藏**所有**系统日志，包括一些可能有用的调试信息
- 如果需要在某些情况下查看系统日志，可以临时禁用这个环境变量
- 这个设置只影响开发环境（Debug），不会影响生产环境（Release）

## 验证

设置完成后，重新运行应用，`load_eligibility_plist` 等系统日志应该不再显示。

