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

# --- Ceviri kayit sistemi: kontrol -> dil anahtari ---
# Dil degisince tum kayitli kontroller otomatik guncellenir.
$script:translatables = New-Object System.Collections.ArrayList
function Register-Translatable {
    param($Control, [string]$Key)
    [void]$script:translatables.Add([pscustomobject]@{ Control = $Control; Key = $Key })
    $Control.Text = Get-String $Key
}

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
    param($Parent, [int]$X, [int]$Y, [int]$W, [int]$H, [string]$TitleKey)
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
    $hdr.Font     = New-Object System.Drawing.Font($fUI, 10, [System.Drawing.FontStyle]::Bold)
    $hdr.ForeColor = $cHeader
    $hdr.BackColor = $cCard
    $hdr.Location = New-Object System.Drawing.Point(16, 10)
    $hdr.Size     = New-Object System.Drawing.Size(($W - 30), 22)
    $panel.Controls.Add($hdr)
    Register-Translatable $hdr $TitleKey
    return $panel
}

# --- Etiketli sayisal alan (DRY) ---
function Add-LabeledNumeric {
    param($Parent, [string]$LabelKey, [int]$Y, [int]$Min, [int]$Max, [decimal]$Value, [int]$Inc = 1)
    $lbl          = New-Object System.Windows.Forms.Label
    $lbl.Font     = New-Object System.Drawing.Font($fUI, 9)
    $lbl.ForeColor = $cText
    $lbl.BackColor = $cCard
    $lbl.Location = New-Object System.Drawing.Point(18, ($Y + 2))
    $lbl.Size     = New-Object System.Drawing.Size(200, 22)
    $Parent.Controls.Add($lbl)
    Register-Translatable $lbl $LabelKey

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
$titleLabel.Font     = New-Object System.Drawing.Font($fUI, 15, [System.Drawing.FontStyle]::Bold)
$titleLabel.ForeColor = $cHeader
$titleLabel.Location = New-Object System.Drawing.Point(0, 62)
$titleLabel.Size     = New-Object System.Drawing.Size(412, 30)
$titleLabel.TextAlign = "MiddleCenter"
$form.Controls.Add($titleLabel)
Register-Translatable $titleLabel "TITLE"

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
$grpSpeed = New-Card $form 18 142 376 102 "GRP_SPEED"
$intervalBox = Add-LabeledNumeric $grpSpeed "BASE_INTERVAL" 38 1 600000 $engine.Settings.BaseIntervalMs 10
$varianceBox = Add-LabeledNumeric $grpSpeed "VARIANCE" 70 0 90 $engine.Settings.VariancePercent 5

# --- KART 2: Insan Benzeri Davranis ---
$grpHuman = New-Card $form 18 254 376 232 "GRP_HUMAN"
$humanCheck          = New-Object System.Windows.Forms.CheckBox
$humanCheck.Font     = New-Object System.Drawing.Font($fUI, 9, [System.Drawing.FontStyle]::Bold)
$humanCheck.ForeColor = $cGoTxt
$humanCheck.BackColor = $cCard
$humanCheck.Location = New-Object System.Drawing.Point(18, 36)
$humanCheck.Size     = New-Object System.Drawing.Size(340, 24)
$humanCheck.Checked  = $engine.Settings.HumanizeEnabled
$grpHuman.Controls.Add($humanCheck)
Register-Translatable $humanCheck "HUMAN_MODE"

$jitterBox   = Add-LabeledNumeric $grpHuman "JITTER" 66 0 50 $engine.Settings.JitterRadiusPx 1
$holdMinBox  = Add-LabeledNumeric $grpHuman "HOLD_MIN"  98 0 1000 $engine.Settings.HoldMinMs 5
$holdMaxBox  = Add-LabeledNumeric $grpHuman "HOLD_MAX" 130 0 1000 $engine.Settings.HoldMaxMs 5
$breakBox    = Add-LabeledNumeric $grpHuman "BREAK_CHANCE" 162 0 100 ([decimal]($engine.Settings.MicroBreakChance * 100)) 1

$turboCheck          = New-Object System.Windows.Forms.CheckBox
$turboCheck.Font     = New-Object System.Drawing.Font($fUI, 9, [System.Drawing.FontStyle]::Bold)
$turboCheck.ForeColor = [System.Drawing.Color]::FromArgb(255, 140, 0)
$turboCheck.BackColor = $cCard
$turboCheck.Location = New-Object System.Drawing.Point(18, 198)
$turboCheck.Size     = New-Object System.Drawing.Size(360, 24)
$turboCheck.Checked  = $false
$grpHuman.Controls.Add($turboCheck)
Register-Translatable $turboCheck "TURBO_MODE"

# --- KART 3: Tiklama Secenekleri ---
$grpClick = New-Card $form 18 496 376 102 "GRP_CLICK"
$btnTypeLabel          = New-Object System.Windows.Forms.Label
$btnTypeLabel.Font     = New-Object System.Drawing.Font($fUI, 9)
$btnTypeLabel.ForeColor = $cText
$btnTypeLabel.BackColor = $cCard
$btnTypeLabel.Location = New-Object System.Drawing.Point(18, 40)
$btnTypeLabel.Size     = New-Object System.Drawing.Size(200, 22)
$grpClick.Controls.Add($btnTypeLabel)
Register-Translatable $btnTypeLabel "MOUSE_BUTTON"

$typeBox          = New-Object System.Windows.Forms.ComboBox
$typeBox.Location = New-Object System.Drawing.Point(225, 38)
$typeBox.Size     = New-Object System.Drawing.Size(148, 24)
$typeBox.DropDownStyle = "DropDownList"
$typeBox.FlatStyle = "Flat"
$typeBox.BackColor = $cInput
$typeBox.ForeColor = $cText
$typeBox.Font     = New-Object System.Drawing.Font($fUI, 9)
[void]$typeBox.Items.Add((Get-String "MOUSE_LEFT"))
[void]$typeBox.Items.Add((Get-String "MOUSE_RIGHT"))
$typeBox.SelectedIndex = 0
$grpClick.Controls.Add($typeBox)

$repeatBox = Add-LabeledNumeric $grpClick "REPEAT" 70 0 10000000 $engine.Settings.RepeatLimit 10

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
    $s.ButtonType       = if ($typeBox.SelectedIndex -eq 1) { 'Right' } else { 'Left' }
    $s.BaseIntervalMs   = [int]$intervalBox.Value
    $s.VariancePercent  = [double]$varianceBox.Value
    $s.JitterRadiusPx   = [int]$jitterBox.Value
    $s.HoldMinMs        = [int]$holdMinBox.Value
    $s.HoldMaxMs        = [Math]::Max([int]$holdMinBox.Value, [int]$holdMaxBox.Value)
    $s.MicroBreakChance = [double]$breakBox.Value / 100.0
    $s.RepeatLimit      = [int]$repeatBox.Value
    $s.HumanizeEnabled  = [bool]$humanCheck.Checked
}

# Dil degisince tum arayuzu guncelle
function Update-UILanguage {
    # Kayitli sabit etiketler (kart basliklari, alan etiketleri, checkbox'lar)
    foreach ($t in $script:translatables) {
        $t.Control.Text = Get-String $t.Key
    }
    # Form basligi
    $form.Text = "😊 $(Get-String 'TITLE')"
    # Fare tusu listesi (secimi koru)
    $sel = $typeBox.SelectedIndex
    $typeBox.Items.Clear()
    [void]$typeBox.Items.Add((Get-String "MOUSE_LEFT"))
    [void]$typeBox.Items.Add((Get-String "MOUSE_RIGHT"))
    $typeBox.SelectedIndex = [Math]::Max(0, $sel)
    # Duruma bagli dinamik etiketler
    if ($engine.Running -or $script:turboMode) {
        $toggleBtn.Text   = Get-String 'BTN_STOP'
        $statusLabel.Text = Get-String 'STATUS_RUNNING'
    } else {
        $toggleBtn.Text   = Get-String 'BTN_START'
        $statusLabel.Text = Get-String 'STATUS_STOPPED'
    }
    $countLabel.Text = "$(Get-String 'CLICK_COUNT')$($engine.ClickCount)"
    $infoLabel.Text  = Get-String 'INFO_TEXT'
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
        $statusLabel.Text      = Get-String 'STATUS_RUNNING'
        $statusLabel.ForeColor = $cGoTxt
        $toggleBtn.Text        = Get-String 'BTN_STOP'
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
        $statusLabel.Text      = Get-String 'STATUS_STOPPED'
        $statusLabel.ForeColor = $cStopTxt
        $toggleBtn.Text        = Get-String 'BTN_START'
        $toggleBtn.BackColor   = $cGo
        $toggleBtn.Tag         = "go"
        $pawLabel.Text         = "🐾 . . . . . 🐾"
    }
}

# Tiklama zamanlayicisi (normal + turbo mod)
$clickTimer          = New-Object System.Windows.Forms.Timer
$clickTimer.Interval = 50
$clickTimer.Add_Tick({
    if (-not $engine.Running) { return }

    if ($script:turboMode) {
        # Turbo: her tikte bir grup ham tiklama (yuksek CPS)
        $reached = Invoke-TurboBurst -Engine $engine
        $countLabel.Text = "$(Get-String 'CLICK_COUNT')$($engine.ClickCount)"
        if ($pawLabel.Text -eq "🐾 . . . . . 🐾") { $pawLabel.Text = "🐾 ✦ ✦ ✦ 🐾" }
        else { $pawLabel.Text = "🐾 . . . . . 🐾" }
        if ($reached) {
            Set-Running $false
            [System.Media.SystemSounds]::Asterisk.Play()
        }
    } else {
        # Normal: insansi tek tiklama
        Sync-SettingsFromUI
        Invoke-EngineClick -Engine $engine
        $countLabel.Text = "$(Get-String 'CLICK_COUNT')$($engine.ClickCount)"
        if ($pawLabel.Text -eq "🐾 . . . . . 🐾") { $pawLabel.Text = "🐾 ✦ ✦ ✦ 🐾" }
        else { $pawLabel.Text = "🐾 . . . . . 🐾" }
        if (Test-EngineLimitReached -Engine $engine) {
            Set-Running $false
            [System.Media.SystemSounds]::Asterisk.Play()
            return
        }
        $clickTimer.Interval = Get-EngineNextDelay -Engine $engine
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
        Update-UILanguage
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
Update-UILanguage   # baslangic dilini (EN) tum dinamik etiketlere uygula
[void]$form.ShowDialog()

