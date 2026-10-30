Set ws = CreateObject("Wscript.Shell")
ws.Run "powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File ""D:\Tools\SysMon\sysmon.ps1""", 0, False
