# pc-monitor

Windows 桌面悬浮系统监控条（PowerShell + WinForms，零依赖）。

## 功能

- 实时显示：↓下载 / ↑上传 / RAM% / CPU%
- 黑底 70% 透明，绿色文字；RAM 或 CPU 超 80% 整条变红告警
- 宽度随文字动态调整，高度固定 36px
- 默认右下角（WorkingArea.Right/Bottom 各减 8px），可拖动，双击关闭
- 开机自启：HKLM Run 键指向 `sysmon-launch.vbs`

## 文件

- `sysmon.ps1` — 主程序（v22）
- `sysmon-launch.vbs` — 隐藏启动器（双击启动，不弹黑窗）

## 安装

1. 复制 `sysmon.ps1` 和 `sysmon-launch.vbs` 到 `D:\Tools\SysMon\`
2. 双击 `sysmon-launch.vbs` 启动
3. 开机自启：`Win+R` → `shell:startup` 或写 HKLM `\SOFTWARE\Microsoft\Windows\CurrentVersion\Run`

## 技术要点

- 网速：.NET `NetworkInformation.NetworkInterface`（比 WMI 性能计数器可靠）
- 内存：WMI `Win32_OperatingSystem`
- CPU：kernel32 `GetSystemTimes` P/Invoke（XP 起可用，无需管理员、不依赖性能计数器库）；分母只用 kernel+user
- PowerShell 2.0 / .NET 2.0 兼容（Win7）

## 历史

2026-10-30 下午从 v1 迭代到 v22：箭头符号、透明度、动态宽度、定位、CPU 取数方案逐一验证。
Win7 上如遇性能计数器损坏，先管理员跑 `lodctr /R`（跑两次）再重启。
