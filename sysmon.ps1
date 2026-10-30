Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class CpuUtil {
    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern bool GetSystemTimes(out long lpIdleTime, out long lpKernelTime, out long lpUserTime);
}
"@
$da = [char]0x2193
$ua = [char]0x2191
$form = New-Object System.Windows.Forms.Form
$form.FormBorderStyle = 0
$form.ShowInTaskbar = $false
$form.TopMost = $true
$form.BackColor = [System.Drawing.Color]::Black
$form.Opacity = 0.3
$form.StartPosition = 1
$label = New-Object System.Windows.Forms.Label
$label.ForeColor = [System.Drawing.Color]::Lime
$label.Font = New-Object System.Drawing.Font("Consolas", 14)
$label.Text = "starting..."
$label.Padding = New-Object System.Windows.Forms.Padding(12, 8, 12, 8)
$label.AutoSize = $true
$form.Controls.Add($label)
$form.ClientSize = New-Object System.Drawing.Size(320, 36)
$wa = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
$form.Location = New-Object System.Drawing.Point(($wa.Right - $form.Width - 8), ($wa.Bottom - $form.Height - 8))
$script:drag = $false
$script:mx = 0
$script:my = 0
$label.Add_MouseDown({ param($a,$b) $script:drag = $true; $script:mx = $b.X; $script:my = $b.Y })
$label.Add_MouseMove({ param($a,$b) if ($script:drag) { $form.Location = New-Object System.Drawing.Point(($form.Location.X + $b.X - $script:mx), ($form.Location.Y + $b.Y - $script:my)) } })
$label.Add_MouseUp({ param($a,$b) $script:drag = $false })
$label.Add_DoubleClick({ $form.Close() })
$script:prevRx = 0
$script:prevTx = 0
$script:firstNet = $true
$script:pIdle = 0
$script:pKern = 0
$script:pUser = 0
$script:firstCpu = $true
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 1000
$timer.Add_Tick({
try {
$rx = 0
$tx = 0
foreach ($nic in [System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces()) {
if ($nic.OperationalStatus -eq "Up" -and $nic.NetworkInterfaceType -ne "Loopback") {
$st = $nic.GetIPv4Statistics()
$rx += $st.BytesReceived
$tx += $st.BytesSent
}
}
if ($script:firstNet) { $script:prevRx = $rx; $script:prevTx = $tx; $script:firstNet = $false; $down = 0; $up = 0 } else {
$down = $rx - $script:prevRx
$up = $tx - $script:prevTx
$script:prevRx = $rx
$script:prevTx = $tx
}
if ($down -lt 0) { $down = 0 }
if ($up -lt 0) { $up = 0 }
if ($down -ge 1048576) { $dt = [math]::Round($down/1048576,2).ToString() + "MB/s" } elseif ($down -ge 1024) { $dt = [math]::Round($down/1024,1).ToString() + "KB/s" } else { $dt = $down.ToString() + "B/s" }
if ($up -ge 1048576) { $ut = [math]::Round($up/1048576,2).ToString() + "MB/s" } elseif ($up -ge 1024) { $ut = [math]::Round($up/1024,1).ToString() + "KB/s" } else { $ut = $up.ToString() + "B/s" }
$os = Get-WmiObject Win32_OperatingSystem
$rp = [math]::Round((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100)
$cp = 0
try {
$idle = 0; $kern = 0; $user = 0
$ok = [CpuUtil]::GetSystemTimes([ref]$idle, [ref]$kern, [ref]$user)
if (-not $ok) { throw "GetSystemTimes failed" }
if ($script:firstCpu) { $script:pIdle = $idle; $script:pKern = $kern; $script:pUser = $user; $script:firstCpu = $false } else {
$dIdle = $idle - $script:pIdle
$dKern = $kern - $script:pKern
$dUser = $user - $script:pUser
$script:pIdle = $idle; $script:pKern = $kern; $script:pUser = $user
$total = $dKern + $dUser
if ($total -gt 0) { $cp = [math]::Round((($total - $dIdle) / $total) * 100) }
}
} catch { $label.Text = "CPU ERR: " + $_.Exception.Message; return }
if ($cp -lt 0) { $cp = 0 }
if ($cp -gt 100) { $cp = 100 }
if ($rp -gt 80 -or $cp -gt 80) { $label.ForeColor = [System.Drawing.Color]::Red } else { $label.ForeColor = [System.Drawing.Color]::Lime }
$label.Text = $da + " " + $dt + "  " + $ua + " " + $ut + "  RAM " + $rp + "%  CPU " + $cp + "%"
$newW = $label.PreferredSize.Width + 6
if ($newW -lt 200) { $newW = 200 }
if ($newW -gt 600) { $newW = 600 }
$form.ClientSize = New-Object System.Drawing.Size($newW, 36)
if (-not $script:drag) {
$wa2 = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
$form.Location = New-Object System.Drawing.Point(($wa2.Right - $form.Width - 8), ($wa2.Bottom - $form.Height - 8))
}
} catch { $label.Text = "TICK ERR: " + $_.Exception.Message }
})
$timer.Start()
[System.Windows.Forms.Application]::Run($form)
