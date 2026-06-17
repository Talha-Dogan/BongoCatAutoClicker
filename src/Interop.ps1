# ============================================================
#  Interop.ps1
#  Sorumluluk (SRP): Isletim sistemi seviyesinde fare ve klavye
#  girisi. Sadece Win32 API sarmalayicilari icerir; ust katman
#  bu detaylari bilmez (bagimlilik tersine cevirme - DIP).
# ============================================================

$script:InteropSignature = @'
[DllImport("user32.dll", CharSet=CharSet.Auto, CallingConvention=CallingConvention.StdCall)]
public static extern void mouse_event(uint dwFlags, uint dx, uint dy, uint dwData, int dwExtraInfo);

[DllImport("user32.dll")]
public static extern short GetAsyncKeyState(int vKey);

[DllImport("user32.dll")]
public static extern bool GetCursorPos(out POINT lpPoint);

[DllImport("user32.dll")]
public static extern bool SetCursorPos(int X, int Y);

[StructLayout(LayoutKind.Sequential)]
public struct POINT { public int X; public int Y; }
'@

if (-not ('Native.BongoInterop' -as [type])) {
    Add-Type -MemberDefinition $script:InteropSignature -Name 'BongoInterop' -Namespace 'Native' | Out-Null
}

# Fare olayi sabitleri
$script:MOUSEEVENTF_LEFTDOWN  = 0x0002
$script:MOUSEEVENTF_LEFTUP    = 0x0004
$script:MOUSEEVENTF_RIGHTDOWN = 0x0008
$script:MOUSEEVENTF_RIGHTUP   = 0x0010

function Get-CursorPosition {
    $p = New-Object Native.BongoInterop+POINT
    [void][Native.BongoInterop]::GetCursorPos([ref]$p)
    return @{ X = $p.X; Y = $p.Y }
}

function Set-CursorPosition {
    param([int]$X, [int]$Y)
    [void][Native.BongoInterop]::SetCursorPos($X, $Y)
}

function Test-KeyDown {
    param([int]$VirtualKey)
    return ([Native.BongoInterop]::GetAsyncKeyState($VirtualKey) -band 0x8000) -ne 0
}

# Hassas, bloklamayan kisa bekleme (Start-Sleep'ten daha kesin).
function Wait-PreciseMs {
    param([int]$Milliseconds)
    if ($Milliseconds -le 0) { return }
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    while ($sw.ElapsedMilliseconds -lt $Milliseconds) { }
    $sw.Stop()
}

# Tek bir fiziksel tiklama: bas -> bekle -> birak.
# HoldMs > 0 olmasi, oyunlarin tiklamayi gercek kabul etmesi icin onemli.
function Invoke-MouseClick {
    param(
        [ValidateSet('Left', 'Right')] [string]$Button = 'Left',
        [int]$HoldMs = 50
    )
    if ($Button -eq 'Right') {
        [Native.BongoInterop]::mouse_event($script:MOUSEEVENTF_RIGHTDOWN, 0, 0, 0, 0)
        Wait-PreciseMs $HoldMs
        [Native.BongoInterop]::mouse_event($script:MOUSEEVENTF_RIGHTUP,   0, 0, 0, 0)
    } else {
        [Native.BongoInterop]::mouse_event($script:MOUSEEVENTF_LEFTDOWN,  0, 0, 0, 0)
        Wait-PreciseMs $HoldMs
        [Native.BongoInterop]::mouse_event($script:MOUSEEVENTF_LEFTUP,    0, 0, 0, 0)
    }
}
