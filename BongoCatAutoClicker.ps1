# ============================================================
#  Bongo Cat Auto Clicker  -  Ana Uygulama (Composition Root)
#  Sorumluluk (SRP): Sunum katmani (UI) ve katmanlarin birlestirilmesi.
#
#  Mimari (SOLID):
#    src/Interop.ps1     -> donanim (Win32)        [SRP]
#    src/Humanizer.ps1   -> insansi zamanlama      [SRP]
#    src/ClickEngine.ps1 -> orkestrasyon           [SRP, DIP]
#    bu dosya            -> arayuz + birlestirme
#
#  Calistirmak icin: BongoCatAutoClicker.bat dosyasina cift tiklayin.
# ============================================================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# --- Bagimliliklari yukle (dot-source) ---
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $root 'src\Interop.ps1')
. (Join-Path $root 'src\Humanizer.ps1')
. (Join-Path $root 'src\ClickEngine.ps1')
. (Join-Path $root 'src\TurboEngine.ps1')
. (Join-Path $root 'src\Localization.ps1')

# --- Motoru olustur ---
$engine = New-ClickEngine
$script:turboMode = $false
$script:turboThread = $null

# ================== TEMA (pastel, sevimli) ==================
$cBg      = [System.Drawing.Color]::FromArgb(255, 233, 241)   # yumusak pembe arka plan
$cCard    = [System.Drawing.Color]::FromArgb(255, 252, 253)   # kart (neredeyse beyaz)
$cBorder  = [System.Drawing.Color]::FromArgb(255, 194, 214)   # kart kenari
$cHeader  = [System.Drawing.Color]::FromArgb(217, 105, 144)   # baslik pembesi
$cText    = [System.Drawing.Color]::FromArgb(109, 76, 87)     # ana metin (sicak kahve)
$cGo      = [System.Drawing.Color]::FromArgb(151, 214, 178)   # nane yesili (baslat)
$cGoHover = [System.Drawing.Color]::FromArgb(130, 200, 160)
$cStop    = [System.Drawing.Color]::FromArgb(255, 145, 160)   # mercan (durdur)
$cStopHover=[System.Drawing.Color]::FromArgb(240, 125, 142)
$cGoTxt   = [System.Drawing.Color]::FromArgb(56, 142, 99)
$cStopTxt = [System.Drawing.Color]::FromArgb(214, 80, 102)
$cInput   = [System.Drawing.Color]::FromArgb(255, 248, 251)   # giris kutusu

$fEmoji   = "Segoe UI Emoji"
$fUI      = "Segoe UI"

# --- Yuvarlatilmis kose yolu (GraphicsPath) ---
function New-RoundedPath {
    param([int]$W, [int]$H, [int]$Radius)
    $d = $Radius * 2
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $path.AddArc(0, 0, $d, $d, 180, 90)
    $path.AddArc($W - $d - 1, 0, $d, $d, 270, 90)
    $path.AddArc($W - $d - 1, $H - $d - 1, $d, $d, 0, 90)
    $path.AddArc(0, $H - $d - 1, $d, $d, 90, 90)
    $path.CloseFigure()
    return $path
}

# --- Sevimli yuvarlak kart paneli olustur ---
function New-Card {
    param($Parent, [int]$X, [int]$Y, [int]$W, [int]$H, [string]$Title)
    $panel          = New-Object System.Windows.Forms.Panel
    $panel.Location = New-Object System.Drawing.Point($X, $Y)
    $panel.Size     = New-Object System.Drawing.Size($W, $H)
    $panel.BackColor = $cCard
    $path = New-RoundedPath $W $H 16
    $panel.Region = New-Object System.Drawing.Region($path)
    $panel.Add_Paint({
        param($s, $e)
        $e.Graphics.SmoothingMode = 'AntiAlias'
        $p = New-RoundedPath $s.Width $s.Height 16
        $pen = New-Object System.Drawing.Pen($cBorder, 1.5)
        $e.Graphics.DrawPath($pen, $p)
        $pen.Dispose(); $p.Dispose()
    }.GetNewClosure())
    $Parent.Controls.Add($panel)

    $hdr          = New-Object System.Windows.Forms.Label
    $hdr.Text     = $Title
    $hdr.Font     = New-Object System.Drawing.Font($fUI, 10, [System.Drawing.FontStyle]::Bold)
    $hdr.ForeColor = $cHeader
    $hdr.BackColor = $cCard
    $hdr.Location = New-Object System.Drawing.Point(16, 10)
    $hdr.Size     = New-Object System.Drawing.Size(($W - 30), 22)
    $panel.Controls.Add($hdr)
    return $panel
}

# --- Etiketli sayisal alan (DRY) ---
function Add-LabeledNumeric {
    param($Parent, [string]$Text, [int]$Y, [int]$Min, [int]$Max, [decimal]$Value, [int]$Inc = 1)
    $lbl          = New-Object System.Windows.Forms.Label
    $lbl.Text     = $Text
    $lbl.Font     = New-Object System.Drawing.Font($fUI, 9)
    $lbl.ForeColor = $cText
    $lbl.BackColor = $cCard
    $lbl.Location = New-Object System.Drawing.Point(18, ($Y + 2))
    $lbl.Size     = New-Object System.Drawing.Size(200, 22)
    $Parent.Controls.Add($lbl)

    $num          = New-Object System.Windows.Forms.NumericUpDown
    $num.Location = New-Object System.Drawing.Point(225, $Y)
    $num.Size     = New-Object System.Drawing.Size(148, 24)
    $num.Minimum  = $Min
    $num.Maximum  = $Max
    $num.Value    = $Value
    $num.Increment = $Inc
    $num.BorderStyle = 'FixedSingle'
    $num.BackColor = $cInput
    $num.ForeColor = $cText
    $num.Font     = New-Object System.Drawing.Font($fUI, 9)
    $Parent.Controls.Add($num)
    return $num
}

# ================== FORM ==================
$form               = New-Object System.Windows.Forms.Form
$form.Text          = "😊 $(Get-String 'TITLE')"
$form.ClientSize    = New-Object System.Drawing.Size(412, 790)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox   = $false
$form.BackColor     = $cBg
$form.Font          = New-Object System.Drawing.Font($fUI, 9)
$form.Topmost       = $true

# --- Sevimli kedi yuzu (duruma gore degisir) ---
$catLabel          = New-Object System.Windows.Forms.Label
$catLabel.Text     = "🐱  💤"
$catLabel.Font     = New-Object System.Drawing.Font($fEmoji, 26)
$catLabel.Location = New-Object System.Drawing.Point(0, 14)
$catLabel.Size     = New-Object System.Drawing.Size(412, 48)
$catLabel.TextAlign = "MiddleCenter"
$form.Controls.Add($catLabel)

$titleLabel          = New-Object System.Windows.Forms.Label
$titleLabel.Text     = "Bongo Cat Auto Clicker"
$titleLabel.Font     = New-Object System.Drawing.Font($fUI, 15, [System.Drawing.FontStyle]::Bold)
$titleLabel.ForeColor = $cHeader
$titleLabel.Location = New-Object System.Drawing.Point(0, 62)
$titleLabel.Size     = New-Object System.Drawing.Size(412, 30)
$titleLabel.TextAlign = "MiddleCenter"
$form.Controls.Add($titleLabel)

$pawLabel          = New-Object System.Windows.Forms.Label
$pawLabel.Text     = "🐾 . . . . . 🐾"
$pawLabel.Font     = New-Object System.Drawing.Font($fEmoji, 11)
$pawLabel.Location = New-Object System.Drawing.Point(0, 92)
$pawLabel.Size     = New-Object System.Drawing.Size(412, 24)
$pawLabel.TextAlign = "MiddleCenter"
$form.Controls.Add($pawLabel)

# --- Dil seçimi ---
$langLabel          = New-Object System.Windows.Forms.Label
$langLabel.Text     = "Language / Dil:"
$langLabel.Font     = New-Object System.Drawing.Font($fUI, 8)
$langLabel.ForeColor = $cText
$langLabel.Location = New-Object System.Drawing.Point(14, 118)
$langLabel.Size     = New-Object System.Drawing.Size(80, 18)
$form.Controls.Add($langLabel)

$langBox          = New-Object System.Windows.Forms.ComboBox
$langBox.Location = New-Object System.Drawing.Point(98, 116)
$langBox.Size     = New-Object System.Drawing.Size(60, 24)
$langBox.DropDownStyle = "DropDownList"
$langBox.BackColor = $cInput
$langBox.ForeColor = $cText
$langBox.Font     = New-Object System.Drawing.Font($fUI, 7)
[void]$langBox.Items.Add("English")
[void]$langBox.Items.Add("Türkçe")
[void]$langBox.Items.Add("中文")
[void]$langBox.Items.Add("हिन्दी")
[void]$langBox.Items.Add("Español")
[void]$langBox.Items.Add("Français")
[void]$langBox.Items.Add("العربية")
[void]$langBox.Items.Add("বাংলা")
[void]$langBox.Items.Add("Português")
[void]$langBox.Items.Add("Русский")
[void]$langBox.Items.Add("اردو")
$langBox.SelectedIndex = 0  # English default
$form.Controls.Add($langBox)

# --- KART 1: Tiklama Hizi ---
$grpSpeed = New-Card $form 18 142 376 102 "🐾 Tiklama Hizi"
$intervalBox = Add-LabeledNumeric $grpSpeed "Temel aralik (ms):" 38 1 600000 $engine.Settings.BaseIntervalMs 10
$varianceBox = Add-LabeledNumeric $grpSpeed "Hiz degiskenligi (%):" 70 0 90 $engine.Settings.VariancePercent 5

# --- KART 2: Insan Benzeri Davranis ---
$grpHuman = New-Card $form 18 254 376 232 "🐾 Insan Benzeri Davranis (Anti-Ban)"
$humanCheck          = New-Object System.Windows.Forms.CheckBox
$humanCheck.Text     = "Insansi mod (onerilir)"
$humanCheck.Font     = New-Object System.Drawing.Font($fUI, 9, [System.Drawing.FontStyle]::Bold)
$humanCheck.ForeColor = $cGoTxt
$humanCheck.BackColor = $cCard
$humanCheck.Location = New-Object System.Drawing.Point(18, 36)
$humanCheck.Size     = New-Object System.Drawing.Size(340, 24)
$humanCheck.Checked  = $engine.Settings.HumanizeEnabled
$grpHuman.Controls.Add($humanCheck)

$jitterBox   = Add-LabeledNumeric $grpHuman "Imlec sapmasi (piksel):" 66 0 50 $engine.Settings.JitterRadiusPx 1
$holdMinBox  = Add-LabeledNumeric $grpHuman "Basili tutma min (ms):"  98 0 1000 $engine.Settings.HoldMinMs 5
$holdMaxBox  = Add-LabeledNumeric $grpHuman "Basili tutma maks (ms):" 130 0 1000 $engine.Settings.HoldMaxMs 5
$breakBox    = Add-LabeledNumeric $grpHuman "Mola olasiligi (%):" 162 0 100 ([decimal]($engine.Settings.MicroBreakChance * 100)) 1

$turboCheck          = New-Object System.Windows.Forms.CheckBox
$turboCheck.Text     = "⚡ TURBO MOD (1000+ CPS, insansi mod kapat)"
$turboCheck.Font     = New-Object System.Drawing.Font($fUI, 9, [System.Drawing.FontStyle]::Bold)
$turboCheck.ForeColor = [System.Drawing.Color]::FromArgb(255, 140, 0)
$turboCheck.BackColor = $cCard
$turboCheck.Location = New-Object System.Drawing.Point(18, 198)
$turboCheck.Size     = New-Object System.Drawing.Size(340, 24)
$turboCheck.Checked  = $false
$grpHuman.Controls.Add($turboCheck)

# --- KART 3: Tiklama Secenekleri ---
$grpClick = New-Card $form 18 496 376 102 "🐾 Tiklama Secenekleri"
$btnTypeLabel          = New-Object System.Windows.Forms.Label
$btnTypeLabel.Text     = "Fare tusu:"
$btnTypeLabel.Font     = New-Object System.Drawing.Font($fUI, 9)
$btnTypeLabel.ForeColor = $cText
$btnTypeLabel.BackColor = $cCard
$btnTypeLabel.Location = New-Object System.Drawing.Point(18, 40)
$btnTypeLabel.Size     = New-Object System.Drawing.Size(200, 22)
$grpClick.Controls.Add($btnTypeLabel)

$typeBox          = New-Object System.Windows.Forms.ComboBox
$typeBox.Location = New-Object System.Drawing.Point(225, 38)
$typeBox.Size     = New-Object System.Drawing.Size(148, 24)
$typeBox.DropDownStyle = "DropDownList"
$typeBox.FlatStyle = "Flat"
$typeBox.BackColor = $cInput
$typeBox.ForeColor = $cText
$typeBox.Font     = New-Object System.Drawing.Font($fUI, 9)
[void]$typeBox.Items.Add("Sol")
[void]$typeBox.Items.Add("Sag")
$typeBox.SelectedIndex = 0
$grpClick.Controls.Add($typeBox)

$repeatBox = Add-LabeledNumeric $grpClick "Tekrar (0 = sinirsiz):" 70 0 10000000 $engine.Settings.RepeatLimit 10

# --- Baslat / Durdur (yuvarlak buton) ---
$toggleBtn          = New-Object System.Windows.Forms.Button
$toggleBtn.Text     = "▶  BASLAT  (F6)"
$toggleBtn.Location = New-Object System.Drawing.Point(18, 612)
$toggleBtn.Size     = New-Object System.Drawing.Size(376, 56)
$toggleBtn.Font     = New-Object System.Drawing.Font($fUI, 13, [System.Drawing.FontStyle]::Bold)
$toggleBtn.BackColor = $cGo
$toggleBtn.ForeColor = [System.Drawing.Color]::White
$toggleBtn.FlatStyle = "Flat"
$toggleBtn.FlatAppearance.BorderSize = 0
$toggleBtn.Cursor   = [System.Windows.Forms.Cursors]::Hand
$toggleBtn.Region   = New-Object System.Drawing.Region((New-RoundedPath 376 56 20))
$form.Controls.Add($toggleBtn)

# --- Durum / sayac / bilgi ---
$statusLabel          = New-Object System.Windows.Forms.Label
$statusLabel.Text     = "💤 Durum: DURDU"
$statusLabel.Font     = New-Object System.Drawing.Font($fUI, 11, [System.Drawing.FontStyle]::Bold)
$statusLabel.Location = New-Object System.Drawing.Point(0, 678)
$statusLabel.Size     = New-Object System.Drawing.Size(412, 24)
$statusLabel.TextAlign = "MiddleCenter"
$statusLabel.ForeColor = $cStopTxt
$form.Controls.Add($statusLabel)

$countLabel          = New-Object System.Windows.Forms.Label
$countLabel.Text     = "🐾 Tiklama: 0"
$countLabel.Font     = New-Object System.Drawing.Font($fUI, 10)
$countLabel.ForeColor = $cText
$countLabel.Location = New-Object System.Drawing.Point(0, 704)
$countLabel.Size     = New-Object System.Drawing.Size(412, 22)
$countLabel.TextAlign = "MiddleCenter"
$form.Controls.Add($countLabel)

$infoLabel          = New-Object System.Windows.Forms.Label
$infoLabel.Text     = "F6 = baslat/durdur  •  imleci hedefe getirip basin"
$infoLabel.Font     = New-Object System.Drawing.Font($fUI, 8)
$infoLabel.Location = New-Object System.Drawing.Point(0, 726)
$infoLabel.Size     = New-Object System.Drawing.Size(412, 18)
$infoLabel.TextAlign = "MiddleCenter"
$infoLabel.ForeColor = [System.Drawing.Color]::FromArgb(180, 150, 160)
$form.Controls.Add($infoLabel)

# ================== MANTIK ==================

function Sync-SettingsFromUI {
    $s = $engine.Settings
    $s.ButtonType       = if ($typeBox.SelectedItem -eq "Sag") { 'Right' } else { 'Left' }
    $s.BaseIntervalMs   = [int]$intervalBox.Value
    $s.VariancePercent  = [double]$varianceBox.Value
    $s.JitterRadiusPx   = [int]$jitterBox.Value
    $s.HoldMinMs        = [int]$holdMinBox.Value
    $s.HoldMaxMs        = [Math]::Max([int]$holdMinBox.Value, [int]$holdMaxBox.Value)
    $s.MicroBreakChance = [double]$breakBox.Value / 100.0
    $s.RepeatLimit      = [int]$repeatBox.Value
    $s.HumanizeEnabled  = [bool]$humanCheck.Checked
}

function Update-HumanControlsEnabled {
    $on = [bool]$humanCheck.Checked
    $jitterBox.Enabled   = $on
    $holdMaxBox.Enabled  = $on
    $breakBox.Enabled    = $on
    $varianceBox.Enabled = $on
}

function Set-Running {
    param([bool]$state)
    if ($state) {
        Sync-SettingsFromUI
        $catLabel.Text         = "😸  🎵"
        $statusLabel.Text      = "😸 Durum: CALISIYOR"
        $statusLabel.ForeColor = $cGoTxt
        $toggleBtn.Text        = "⏸  DURDUR  (F6)"
        $toggleBtn.BackColor   = $cStop
        $toggleBtn.Tag         = "stop"

        if ([bool]$turboCheck.Checked) {
            $script:turboMode = $true
            $engine.Running = $true
            Enable-TurboMode -ClickTimer $clickTimer
            $clickTimer.Start()
        } else {
            $script:turboMode = $false
            $engine.Running = $true
            Disable-TurboMode -ClickTimer $clickTimer
            $clickTimer.Start()
        }
    } else {
        $engine.Running = $false
        $script:turboMode = $false
        $clickTimer.Stop()
        Disable-TurboMode -ClickTimer $clickTimer
        $catLabel.Text         = "🐱  💤"
        $statusLabel.Text      = "💤 Durum: DURDU"
        $statusLabel.ForeColor = $cStopTxt
        $toggleBtn.Text        = "▶  BASLAT  (F6)"
        $toggleBtn.BackColor   = $cGo
        $toggleBtn.Tag         = "go"
        $pawLabel.Text         = "🐾 . . . . . 🐾"
    }
}

# Tiklama zamanlayicisi (normal + turbo mod)
$clickTimer          = New-Object System.Windows.Forms.Timer
$clickTimer.Interval = 50
$clickTimer.Add_Tick({
    if ($engine.Running) {
        Sync-SettingsFromUI
        Invoke-EngineClick -Engine $engine
        $countLabel.Text = "🐾 Tiklama: $($engine.ClickCount)"
        if ($pawLabel.Text -eq "🐾 . . . . . 🐾") { $pawLabel.Text = "🐾 ✦ ✦ ✦ 🐾" }
        else { $pawLabel.Text = "🐾 . . . . . 🐾" }
        if (Test-EngineLimitReached -Engine $engine) {
            Set-Running $false
            [System.Media.SystemSounds]::Asterisk.Play()
            return
        }
        if (-not $script:turboMode) {
            $clickTimer.Interval = Get-EngineNextDelay -Engine $engine
        }
    }
})

# Global kisayol (F6)
$VK_F6 = 0x75
$script:hotkeyWasDown = $false
$hotkeyTimer          = New-Object System.Windows.Forms.Timer
$hotkeyTimer.Interval = 40
$hotkeyTimer.Add_Tick({
    $isDown = Test-KeyDown -VirtualKey $VK_F6
    if ($isDown -and -not $script:hotkeyWasDown) { Set-Running (-not $engine.Running) }
    $script:hotkeyWasDown = $isDown
})
$hotkeyTimer.Start()

# --- Olaylar ---
# Dil seçim (index -> dil kodu)
$langCodes = @("EN", "TR", "ZH", "HI", "ES", "FR", "AR", "BN", "PT", "RU", "UR")
$langBox.Add_SelectedIndexChanged({
    if ($langBox.SelectedIndex -ge 0 -and $langBox.SelectedIndex -lt $langCodes.Count) {
        Set-Language $langCodes[$langBox.SelectedIndex]

        # Tüm UI string'lerini güncelle
        $form.Text = "😊 $(Get-String 'TITLE')"
        $titleLabel.Text = Get-String 'TITLE'
        $toggleBtn.Text = if ($engine.Running) { Get-String 'BTN_STOP' } else { Get-String 'BTN_START' }
        $statusLabel.Text = if ($engine.Running) { Get-String 'STATUS_RUNNING' } else { Get-String 'STATUS_STOPPED' }
        $countLabel.Text = "$(Get-String 'CLICK_COUNT')$($engine.ClickCount)"
        $infoLabel.Text = "F6 = $(Get-String 'BTN_START')"
    }
})

$toggleBtn.Add_Click({ Set-Running (-not $engine.Running) })
$toggleBtn.Add_MouseEnter({
    if ($toggleBtn.Tag -eq "stop") { $toggleBtn.BackColor = $cStopHover } else { $toggleBtn.BackColor = $cGoHover }
})
$toggleBtn.Add_MouseLeave({
    if ($toggleBtn.Tag -eq "stop") { $toggleBtn.BackColor = $cStop } else { $toggleBtn.BackColor = $cGo }
})
$humanCheck.Add_CheckedChanged({ Update-HumanControlsEnabled })
$turboCheck.Add_CheckedChanged({
    if ($turboCheck.Checked) {
        $humanCheck.Checked = $false
        $humanCheck.Enabled = $false
    } else {
        $humanCheck.Enabled = $true
    }
})
$form.Add_FormClosing({
    $clickTimer.Stop()
    $hotkeyTimer.Stop()
})

$toggleBtn.Tag = "go"
Update-HumanControlsEnabled
[void]$form.ShowDialog()

# SIG # Begin signature block
# MIIFgwYJKoZIhvcNAQcCoIIFdDCCBXACAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUYM9J1quc4PDxZmAJiBTqo84U
# SpagggMhMIIDHTCCAgWgAwIBAgIQKDhswI3fToJKjstkm3OLJzANBgkqhkiG9w0B
# AQsFADAXMRUwEwYDVQQDDAxUYWxoYSBEb8SfYW4wHhcNMjYwNjE3MTYxNDM5WhcN
# MjcwNjE3MTYzNDM5WjAXMRUwEwYDVQQDDAxUYWxoYSBEb8SfYW4wggEiMA0GCSqG
# SIb3DQEBAQUAA4IBDwAwggEKAoIBAQDNIGM4RJcXcREY6X1rzl67uGeUxVJA/YUV
# tE33WO5AEGlw7CXYzs/dUYeDP2MEgRU08XPW0K0P1F9k5MIbGb6Mw8pQIfyo8sy1
# BP+on7tReta8IsHXx9mVz0UF8C+eumgy9JSqY/Nm5LOaNN7oWeX7pmIGbpVEjPJC
# w+UlvY0An/eVMzKksH2KiiWpAbooQkxoBIQjACaxJIWeeEy3xQHBiBC4gHTALR8G
# 4QD8cNaNsw7STtRVI1YhVcVJhRjHCvM2tMHKEmxe8FKc09K5SA5eyScIT8UTPW9S
# p4MnRCdUOQK13lgs13dlqkgtFoaxnjmX9e9NDR3ccOkb46EjkhAhAgMBAAGjZTBj
# MA4GA1UdDwEB/wQEAwIHgDATBgNVHSUEDDAKBggrBgEFBQcDAzAdBgNVHREEFjAU
# ghJ4bi0tdGFsaGEgZG9hbi1ocGIwHQYDVR0OBBYEFCUfwmMhsFphVW+CWsyNBFxW
# 322kMA0GCSqGSIb3DQEBCwUAA4IBAQAAS+NZsF/VpjSinxuNNSafEDdmy1OlK6+H
# Wj8mpykpuLuZvz/ImNIl0Jt3bsEVOORcpHPKSm7sYK9+6qb9dlgUpTFtqvPh18Ep
# X4vw4WMx4SW7Wh8ab5YmRrOlHuD/vHv7QwAO162K9hu69EoBo25SLYSyeabz6JjF
# VKpDOhs5mUeiUh/tGlKyUy4SUzlaGPQjE+t6pdkFd0bsiGO5ZVblq6tAXlAuJC9y
# v6fXLTqUdJHSWdq9v6abH9aacLKLcTMMJLuDlxGBv72jbUTmE2yJRKA4IAs0KQNy
# nSod5TgN+wrQPpUGAJ34FVljhfZXu2ufJX0t4V9YO9ZtfzjfJ6/DMYIBzDCCAcgC
# AQEwKzAXMRUwEwYDVQQDDAxUYWxoYSBEb8SfYW4CECg4bMCN306CSo7LZJtziycw
# CQYFKw4DAhoFAKB4MBgGCisGAQQBgjcCAQwxCjAIoAKAAKECgAAwGQYJKoZIhvcN
# AQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUw
# IwYJKoZIhvcNAQkEMRYEFF6jvxSoD11Uhn39I4AaLkN9gxViMA0GCSqGSIb3DQEB
# AQUABIIBALmJNqmI0eYvscK6xfZES3/MWx0cH2JM5BA+/nF1061ru4LSJvpFlW/v
# lpycjy/5VE4aFjZV4tMHhxBY6qsKkPub/iJYEQ1gp6/P4pJIK2CfSbQsZiMonX6o
# BJcX/toeqjETFXP3SQtwCGcV8eTrAL2L4EEy4CDW/5GECTHU8A0XSBWcfUZ0voWk
# Mn2nWAJ2Lym0y0MwqX+TcFdOCS7EVxrh3xTlmrQfYc0/Tk2IfkfSfsUmtqXSY/oA
# wsK7/+GA7w+AKwIYU3/epAzTbNSs3DfeWlpS3fmCYJAEy7mxZyHSrFBYM3t9HUNX
# b6iSt3JCy0JvJEraijpwdV6+oXsjyV8=
# SIG # End signature block
