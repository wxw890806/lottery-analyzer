# GitHub Actions 云端构建指南

## 步骤 1：上传代码到 GitHub

1. 访问 https://github.com 注册/登录
2. 创建新仓库：点击 "+" → "New repository"
   - Repository name: `lottery-analyzer`
   - 选择 Public
3. 点击 "Create repository"
4. 将本文件夹的所有文件拖拽上传（或使用 git push）

## 步骤 2：触发自动构建

1. 进入仓库页面，点击 **Actions** 标签
2. 左侧点击 "Build APK"
3. 右侧点击 **"Run workflow"** → **"Run workflow"** 绿色按钮

## 步骤 3：下载 APK

1. 等待构建完成（约 5-10 分钟）
2. 点击构建任务 → Artifacts → app-debug.apk

## 全部免费！GitHub 每月提供 2000 分钟免费构建时间。

---
## 快速命令（如果已安装 Git）

```bash
git init
git add .
git commit -m "first commit"
git branch -M main
git remote add origin https://github.com/你的用户名/lottery-analyzer.git
git push -u origin main
```
