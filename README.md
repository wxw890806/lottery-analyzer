# 彩票规律分析器

专业彩票规律分析Android应用 - 支持云端构建

## 快速开始（无需安装Flutter）

### 方法：GitHub 云端构建

#### 第一步：注册 GitHub
1. 访问 https://github.com
2. 点击右上角 **Sign up** 注册账号
3. 验证邮箱

#### 第二步：创建仓库
1. 登录后点击右上角 **+** 号
2. 选择 **New repository**
3. 填写信息：
   - Repository name: `lottery-analyzer`
   - 选择 **Public**
   - **不要**勾选 "Add a README file"
4. 点击 **Create repository**

#### 第三步：上传文件
1. 在新创建的空仓库页面，找到 **"uploading an existing file"** 链接，点击它
2. 打开您电脑上的文件夹：`c:\Users\NING MEI\ComateProjects\comate-zulu-demo`
3. 选择里面的**所有文件和文件夹**，拖拽到 GitHub 页面
4. 等待上传完成
5. 在底部 "Commit changes" 处点击绿色按钮

#### 第四步：自动构建
上传完成后，GitHub 会自动开始构建（约1-2分钟后触发）

或者手动触发：
1. 点击仓库顶部的 **Actions** 标签
2. 左侧点击 **"Build APK"**
3. 右侧点击 **"Run workflow"** → **"Run workflow"**

#### 第五步：下载 APK
1. 等待构建完成（约5-10分钟）
2. 点击 Actions 中完成的构建任务
3. 在页面底部 **Artifacts** 处下载 **app-debug.apk**

#### 第六步：安装到手机
1. 将 APK 发送到手机
2. 开启手机设置中的"未知来源安装"权限
3. 点击 APK 安装

---

## 项目结构

```
lottery-analyzer/
├── lib/                    # 应用代码
│   ├── main.dart          # 入口
│   ├── models/            # 数据模型
│   ├── services/          # 服务层（分析/预测）
│   ├── providers/         # 状态管理
│   ├── screens/           # 界面
│   └── widgets/           # 组件
├── android/               # Android 配置
├── .github/workflows/     # 云构建配置
└── pubspec.yaml           # 依赖配置
```

## 功能

- 数据统计分析
- 多种预测策略
- 回测验证
- 热力图可视化

---

**注意**：本应用仅供学习研究，彩票中奖完全随机，请理性对待。
