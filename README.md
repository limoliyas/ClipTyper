# ClipTyper

**ClipTyper** 是一个 macOS 菜单栏小工具，按下快捷键后自动从剪贴板读取文本并模拟逐字输入（自动打字效果），支持中文/英文不同速度设置，以及触发延迟调整。

## ✨ 功能特性

- 快捷键触发模拟打字（支持自定义）
- 支持中英文不同输入速度
- 支持设置延迟触发时间
- 完全离线运行，数据不会上传
- 菜单栏驻留，静默高效

## ⚠️ 第一次使用前请注意

macOS 出于安全考虑，**不允许未经授权的 App 模拟键盘输入**，你需要手动授予权限：

> 系统设置 > 隐私与安全性 > 辅助功能  
> ✅ 勾选你的 `ClipTyper.app`

否则快捷键虽然触发了，但不会有任何打字效果。

## 📦 构建方式

在终端执行脚本：

```bash
./scripts/build.sh
```



## **🧪 使用说明**

1. 启动 ClipTyper.app，会在菜单栏看到小图标
2. 默认快捷键：Control + Option + P
3. 可在菜单中修改快捷键、打字速度、触发延迟



## **🔧 项目结构**

```bash
.
├── Info.plist                # App 配置文件，包含应用的基本信息和设置
├── README.md                 # 项目的说明文档，包含如何使用、安装和贡献等信息
├── dist                       # 存放构建后的应用
│   ├── ClipTyper              # 编译后的可执行文件
│   ├── ClipTyper.app          # 生成的 macOS 应用
├── resources                  # 存放图标和其他资源文件
│   ├── icon.icns              # 应用的 .icns 格式图标，包含多种尺寸的图标
│   ├── icon.iconset           # 图标的不同尺寸（.png 格式），用于生成 .icns 文件
│   ├── logo.png               # 源图标，原始的 logo 图像，用于生成其他图标
│   └── logo_menu.png          # 菜单栏图标，用于在菜单栏显示的图标
├── scripts                    # 存放构建相关的脚本
│   └── build.sh               # 一键构建脚本，自动编译并生成 .app 文件
└── src                        # 源代码文件
    ├── AppDelegate.h          # AppDelegate 头文件，定义了应用的主要逻辑和接口
    ├── AppDelegate.mm         # AppDelegate 实现文件，包含应用启动和逻辑代码
    └── main.mm                # 应用的入口文件，执行应用的启动逻辑
```



## **📜 License**

MIT License - 免费、开源，欢迎使用和修改！