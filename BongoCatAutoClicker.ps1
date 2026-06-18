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

# --- Ceviri kayit sistemi ---
$script:translatables = New-Object System.Collections.ArrayList
function Register-Translatable {
    param($Control, [string]$Key)
    [void]$script:translatables.Add([pscustomobject]@{ Control = $Control; Key = $Key })
    $Control.Text = Get-String $Key
}

# ================== TEMA ==================
$cBg       = [System.Drawing.Color]::FromArgb(248, 236, 243)
$cCard     = [System.Drawing.Color]::FromArgb(255, 255, 255)
$cBorder   = [System.Drawing.Color]::FromArgb(245, 210, 228)
$cHeader   = [System.Drawing.Color]::FromArgb(200, 90, 135)
$cText     = [System.Drawing.Color]::FromArgb(90, 60, 75)
$cSubText  = [System.Drawing.Color]::FromArgb(170, 130, 150)
$cGo       = [System.Drawing.Color]::FromArgb(100, 200, 150)
$cGoHover  = [System.Drawing.Color]::FromArgb(80, 185, 133)
$cStop     = [System.Drawing.Color]::FromArgb(255, 120, 145)
$cStopHover= [System.Drawing.Color]::FromArgb(240, 100, 128)
$cGoTxt    = [System.Drawing.Color]::FromArgb(30, 120, 80)
$cStopTxt  = [System.Drawing.Color]::FromArgb(200, 50, 80)
$cInput    = [System.Drawing.Color]::FromArgb(252, 245, 249)
$cInputBdr = [System.Drawing.Color]::FromArgb(230, 195, 215)
$cBanner1  = [System.Drawing.Color]::FromArgb(255, 140, 180)
$cBanner2  = [System.Drawing.Color]::FromArgb(220, 95, 148)
$cShadow   = [System.Drawing.Color]::FromArgb(240, 210, 225)
$cWinBtn   = [System.Drawing.Color]::FromArgb(255, 230, 245)
$cAccent   = [System.Drawing.Color]::FromArgb(255, 105, 160)

$fEmoji = "Segoe UI Emoji"
$fUI    = "Segoe UI"

# --- Yuvarlatilmis yol ---
function New-RoundedPath {
    param([int]$W, [int]$H, [int]$R)
    $d = $R * 2
    $p = New-Object System.Drawing.Drawing2D.GraphicsPath
    $p.AddArc(0,       0,       $d, $d, 180, 90)
    $p.AddArc($W-$d-1, 0,       $d, $d, 270, 90)
    $p.AddArc($W-$d-1, $H-$d-1, $d, $d,   0, 90)
    $p.AddArc(0,       $H-$d-1, $d, $d,  90, 90)
    $p.CloseFigure()
    return $p
}

# --- Kart paneli ---
# Paint event KULLANILMIYOR: PS5.1'de Panel.Add_Paint BackColor render'ini bozuyor.
# Accent bar -> child Panel (BackColor), border -> BorderStyle yok + hdr separator.
function New-Card {
    param($Parent, [int]$X, [int]$Y, [int]$W, [int]$H, [string]$TitleKey)

    # Golge (arkada, sade pembe panel)
    $sh           = New-Object System.Windows.Forms.Panel
    $sh.Location  = New-Object System.Drawing.Point(($X + 3), ($Y + 4))
    $sh.Size      = New-Object System.Drawing.Size($W, $H)
    $sh.BackColor = $cShadow
    $Parent.Controls.Add($sh)

    # Kart govdesi: beyaz, Paint event YOK
    $panel           = New-Object System.Windows.Forms.Panel
    $panel.Location  = New-Object System.Drawing.Point($X, $Y)
    $panel.Size      = New-Object System.Drawing.Size($W, $H)
    $panel.BackColor = $cCard
    $panel.BorderStyle = 'None'
    $Parent.Controls.Add($panel)
    # KRITIK: golge panel z-order'da onde kalip karti kapatiyordu.
    # Karti one al ki icerigi (basliklar, checkbox, numeric) gorunsun.
    $panel.BringToFront()
    $sh.SendToBack()

    # Sol accent cubugu (child Panel - Paint event gerekmez)
    $bar           = New-Object System.Windows.Forms.Panel
    $bar.Location  = New-Object System.Drawing.Point(0, 0)
    $bar.Size      = New-Object System.Drawing.Size(5, $H)
    $bar.BackColor = $cAccent
    $panel.Controls.Add($bar)

    # Baslik separator (ince pembe cizgi, alt kenara)
    $sep           = New-Object System.Windows.Forms.Panel
    $sep.Location  = New-Object System.Drawing.Point(0, 35)
    $sep.Size      = New-Object System.Drawing.Size($W, 1)
    $sep.BackColor = $cBorder
    $panel.Controls.Add($sep)

    # Baslik etiketi
    $hdr           = New-Object System.Windows.Forms.Label
    $hdr.Font      = New-Object System.Drawing.Font($fUI, 9, [System.Drawing.FontStyle]::Bold)
    $hdr.ForeColor = $cHeader
    $hdr.BackColor = $cCard
    $hdr.Location  = New-Object System.Drawing.Point(18, 9)
    $hdr.Size      = New-Object System.Drawing.Size(($W - 30), 22)
    $panel.Controls.Add($hdr)
    Register-Translatable $hdr $TitleKey

    return $panel
}

# --- Etiketli sayisal alan ---
function Add-LabeledNumeric {
    param($Parent, [string]$LabelKey, [int]$Y, [int]$Min, [int]$Max, [decimal]$Value, [int]$Inc = 1)

    $lbl          = New-Object System.Windows.Forms.Label
    $lbl.Font     = New-Object System.Drawing.Font($fUI, 8.5)
    $lbl.ForeColor = $cText
    $lbl.BackColor = $cCard
    $lbl.Location = New-Object System.Drawing.Point(18, ($Y + 3))
    $lbl.Size     = New-Object System.Drawing.Size(190, 20)
    $Parent.Controls.Add($lbl)
    Register-Translatable $lbl $LabelKey

    $num          = New-Object System.Windows.Forms.NumericUpDown
    $num.Location = New-Object System.Drawing.Point(215, $Y)
    $num.Size     = New-Object System.Drawing.Size(148, 26)
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
$form.Text          = "Bongo Cat Auto Clicker"
$form.ClientSize    = New-Object System.Drawing.Size(420, 820)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "None"
$form.BackColor     = $cBg
$form.Font          = New-Object System.Drawing.Font($fUI, 9)
$form.Topmost       = $true
$form.Region        = New-Object System.Drawing.Region((New-RoundedPath 420 820 20))

# --- Surukleme ---
$script:dragging = $false
$script:dragOff  = New-Object System.Drawing.Point(0, 0)
function Add-DragHandler {
    param($Control)
    $Control.Add_MouseDown({
        param($s, $e)
        if ($e.Button -eq 'Left') {
            $script:dragging = $true
            $script:dragOff  = New-Object System.Drawing.Point($e.X, $e.Y)
        }
    })
    $Control.Add_MouseMove({
        param($s, $e)
        if ($script:dragging) {
            $pt = $s.PointToScreen((New-Object System.Drawing.Point($e.X, $e.Y)))
            $form.Location = New-Object System.Drawing.Point(($pt.X - $script:dragOff.X), ($pt.Y - $script:dragOff.Y))
        }
    })
    $Control.Add_MouseUp({ $script:dragging = $false })
}

# ---- HERO BANNER ----
$banner          = New-Object System.Windows.Forms.Panel
$banner.Location = New-Object System.Drawing.Point(0, 0)
$banner.Size     = New-Object System.Drawing.Size(420, 160)
$banner.Add_Paint({
    param($s, $e)
    $g = $e.Graphics
    $g.SmoothingMode = 'AntiAlias'
    # Gradyan arka plan
    $rect  = New-Object System.Drawing.Rectangle(0, 0, $s.Width, $s.Height)
    $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
                $rect, $cBanner1, $cBanner2,
                [System.Drawing.Drawing2D.LinearGradientMode]::Vertical)
    $g.FillRectangle($brush, $rect)
    $brush.Dispose()
    # Alt kenarda hafif beyaz separator
    $sepPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(40, 255, 255, 255), 1)
    $g.DrawLine($sepPen, 0, $s.Height - 1, $s.Width, $s.Height - 1)
    $sepPen.Dispose()
}.GetNewClosure())
$form.Controls.Add($banner)
Add-DragHandler $banner

# Pencere butonlari (saga yasli)
$btnClose          = New-Object System.Windows.Forms.Label
$btnClose.Text     = "✕"
$btnClose.Font     = New-Object System.Drawing.Font($fUI, 11, [System.Drawing.FontStyle]::Bold)
$btnClose.ForeColor = [System.Drawing.Color]::White
$btnClose.BackColor = [System.Drawing.Color]::Transparent
$btnClose.Location = New-Object System.Drawing.Point(388, 8)
$btnClose.Size     = New-Object System.Drawing.Size(24, 24)
$btnClose.TextAlign = "MiddleCenter"
$btnClose.Cursor   = [System.Windows.Forms.Cursors]::Hand
$btnClose.Add_Click({ $form.Close() })
$btnClose.Add_MouseEnter({ $btnClose.ForeColor = [System.Drawing.Color]::FromArgb(255,200,200) })
$btnClose.Add_MouseLeave({ $btnClose.ForeColor = [System.Drawing.Color]::White })
$banner.Controls.Add($btnClose)

$btnMin          = New-Object System.Windows.Forms.Label
$btnMin.Text     = "─"
$btnMin.Font     = New-Object System.Drawing.Font($fUI, 10, [System.Drawing.FontStyle]::Bold)
$btnMin.ForeColor = [System.Drawing.Color]::White
$btnMin.BackColor = [System.Drawing.Color]::Transparent
$btnMin.Location = New-Object System.Drawing.Point(360, 8)
$btnMin.Size     = New-Object System.Drawing.Size(24, 24)
$btnMin.TextAlign = "MiddleCenter"
$btnMin.Cursor   = [System.Windows.Forms.Cursors]::Hand
$btnMin.Add_Click({ $form.WindowState = 'Minimized' })
$btnMin.Add_MouseEnter({ $btnMin.ForeColor = [System.Drawing.Color]::FromArgb(255,230,150) })
$btnMin.Add_MouseLeave({ $btnMin.ForeColor = [System.Drawing.Color]::White })
$banner.Controls.Add($btnMin)

# Kedi emoji
$catLabel          = New-Object System.Windows.Forms.Label
$catLabel.Text     = "🐱"
$catLabel.Font     = New-Object System.Drawing.Font($fEmoji, 36)
$catLabel.Location = New-Object System.Drawing.Point(0, 18)
$catLabel.Size     = New-Object System.Drawing.Size(420, 60)
$catLabel.TextAlign = "MiddleCenter"
$catLabel.BackColor = [System.Drawing.Color]::Transparent
$catLabel.ForeColor = [System.Drawing.Color]::White
$banner.Controls.Add($catLabel)
Add-DragHandler $catLabel

# Uygulama adi
$titleLabel          = New-Object System.Windows.Forms.Label
$titleLabel.Font     = New-Object System.Drawing.Font($fUI, 14, [System.Drawing.FontStyle]::Bold)
$titleLabel.ForeColor = [System.Drawing.Color]::White
$titleLabel.Location = New-Object System.Drawing.Point(0, 82)
$titleLabel.Size     = New-Object System.Drawing.Size(420, 34)
$titleLabel.TextAlign = "MiddleCenter"
$titleLabel.BackColor = [System.Drawing.Color]::Transparent
$banner.Controls.Add($titleLabel)
Register-Translatable $titleLabel "TITLE"
Add-DragHandler $titleLabel

# Pati dekorasyon
$pawLabel          = New-Object System.Windows.Forms.Label
$pawLabel.Text     = "🐾 ∙ ∙ ∙ ∙ ∙ 🐾"
$pawLabel.Font     = New-Object System.Drawing.Font($fEmoji, 10)
$pawLabel.Location = New-Object System.Drawing.Point(0, 120)
$pawLabel.Size     = New-Object System.Drawing.Size(420, 28)
$pawLabel.TextAlign = "MiddleCenter"
$pawLabel.ForeColor = [System.Drawing.Color]::FromArgb(200, 255, 230, 245)
$pawLabel.BackColor = [System.Drawing.Color]::Transparent
$banner.Controls.Add($pawLabel)
Add-DragHandler $pawLabel

# ---- Dil secici (banner altinda, ince) ----
$langRow          = New-Object System.Windows.Forms.Panel
$langRow.Location = New-Object System.Drawing.Point(0, 160)
$langRow.Size     = New-Object System.Drawing.Size(420, 36)
$langRow.BackColor = [System.Drawing.Color]::FromArgb(252, 240, 248)
$form.Controls.Add($langRow)

$langLabel          = New-Object System.Windows.Forms.Label
$langLabel.Text     = "🌍"
$langLabel.Font     = New-Object System.Drawing.Font($fEmoji, 10)
$langLabel.ForeColor = $cSubText
$langLabel.Location = New-Object System.Drawing.Point(16, 7)
$langLabel.Size     = New-Object System.Drawing.Size(22, 22)
$langLabel.BackColor = [System.Drawing.Color]::Transparent
$langRow.Controls.Add($langLabel)

$langBox          = New-Object System.Windows.Forms.ComboBox
$langBox.Location = New-Object System.Drawing.Point(42, 6)
$langBox.Size     = New-Object System.Drawing.Size(130, 24)
$langBox.DropDownStyle = "DropDownList"
$langBox.FlatStyle = "Flat"
$langBox.BackColor = $cCard
$langBox.ForeColor = $cText
$langBox.Font     = New-Object System.Drawing.Font($fUI, 8.5)
foreach ($l in @("English","Türkçe","中文","हिन्दी","Español","Français","العربية","বাংলা","Português","Русский","اردو")) {
    [void]$langBox.Items.Add($l)
}
$langBox.SelectedIndex = 0
$langRow.Controls.Add($langBox)

# ---- KART 1: Hiz ----
$grpSpeed    = New-Card $form 16 208 388 100 "GRP_SPEED"
$intervalBox = Add-LabeledNumeric $grpSpeed "BASE_INTERVAL" 36 1 600000 $engine.Settings.BaseIntervalMs 10
$varianceBox = Add-LabeledNumeric $grpSpeed "VARIANCE"      68 0 90 $engine.Settings.VariancePercent 5

# ---- KART 2: Insan Benzeri ----
$grpHuman = New-Card $form 16 320 388 240 "GRP_HUMAN"

$humanCheck          = New-Object System.Windows.Forms.CheckBox
$humanCheck.Font     = New-Object System.Drawing.Font($fUI, 9, [System.Drawing.FontStyle]::Bold)
$humanCheck.ForeColor = $cGoTxt
$humanCheck.BackColor = $cCard
$humanCheck.Location = New-Object System.Drawing.Point(18, 36)
$humanCheck.Size     = New-Object System.Drawing.Size(350, 24)
$humanCheck.Checked  = $engine.Settings.HumanizeEnabled
$grpHuman.Controls.Add($humanCheck)
Register-Translatable $humanCheck "HUMAN_MODE"

$jitterBox  = Add-LabeledNumeric $grpHuman "JITTER"       66 0 50 $engine.Settings.JitterRadiusPx 1
$holdMinBox = Add-LabeledNumeric $grpHuman "HOLD_MIN"     98 0 1000 $engine.Settings.HoldMinMs 5
$holdMaxBox = Add-LabeledNumeric $grpHuman "HOLD_MAX"    130 0 1000 $engine.Settings.HoldMaxMs 5
$breakBox   = Add-LabeledNumeric $grpHuman "BREAK_CHANCE" 162 0 100 ([decimal]($engine.Settings.MicroBreakChance * 100)) 1

$turboCheck          = New-Object System.Windows.Forms.CheckBox
$turboCheck.Font     = New-Object System.Drawing.Font($fUI, 9, [System.Drawing.FontStyle]::Bold)
$turboCheck.ForeColor = [System.Drawing.Color]::FromArgb(220, 120, 0)
$turboCheck.BackColor = $cCard
$turboCheck.Location = New-Object System.Drawing.Point(18, 202)
$turboCheck.Size     = New-Object System.Drawing.Size(360, 28)
$turboCheck.Checked  = $false
$grpHuman.Controls.Add($turboCheck)
Register-Translatable $turboCheck "TURBO_MODE"

# ---- KART 3: Tiklama Secenekleri ----
$grpClick = New-Card $form 16 572 388 106 "GRP_CLICK"

$btnTypeLabel          = New-Object System.Windows.Forms.Label
$btnTypeLabel.Font     = New-Object System.Drawing.Font($fUI, 8.5)
$btnTypeLabel.ForeColor = $cText
$btnTypeLabel.BackColor = $cCard
$btnTypeLabel.Location = New-Object System.Drawing.Point(18, 40)
$btnTypeLabel.Size     = New-Object System.Drawing.Size(190, 22)
$grpClick.Controls.Add($btnTypeLabel)
Register-Translatable $btnTypeLabel "MOUSE_BUTTON"

$typeBox          = New-Object System.Windows.Forms.ComboBox
$typeBox.Location = New-Object System.Drawing.Point(215, 38)
$typeBox.Size     = New-Object System.Drawing.Size(148, 26)
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

# ---- TOGGLE BUTONU ----
$toggleBtn          = New-Object System.Windows.Forms.Button
$toggleBtn.Location = New-Object System.Drawing.Point(16, 692)
$toggleBtn.Size     = New-Object System.Drawing.Size(388, 56)
$toggleBtn.Font     = New-Object System.Drawing.Font($fUI, 13, [System.Drawing.FontStyle]::Bold)
$toggleBtn.BackColor = $cGo
$toggleBtn.ForeColor = [System.Drawing.Color]::White
$toggleBtn.FlatStyle = "Flat"
$toggleBtn.FlatAppearance.BorderSize = 0
$toggleBtn.Cursor   = [System.Windows.Forms.Cursors]::Hand
$toggleBtn.Region   = New-Object System.Drawing.Region((New-RoundedPath 388 56 22))
$form.Controls.Add($toggleBtn)

# ---- STATUS ALANI ----
$statusPanel          = New-Object System.Windows.Forms.Panel
$statusPanel.Location = New-Object System.Drawing.Point(16, 758)
$statusPanel.Size     = New-Object System.Drawing.Size(388, 50)
$statusPanel.BackColor = $cCard
$statusPanel.Region   = New-Object System.Drawing.Region((New-RoundedPath 388 50 12))
$form.Controls.Add($statusPanel)

$statusLabel          = New-Object System.Windows.Forms.Label
$statusLabel.Font     = New-Object System.Drawing.Font($fUI, 10, [System.Drawing.FontStyle]::Bold)
$statusLabel.Location = New-Object System.Drawing.Point(0, 4)
$statusLabel.Size     = New-Object System.Drawing.Size(388, 22)
$statusLabel.TextAlign = "MiddleCenter"
$statusLabel.ForeColor = $cStopTxt
$statusLabel.BackColor = $cCard
$statusPanel.Controls.Add($statusLabel)

$countLabel          = New-Object System.Windows.Forms.Label
$countLabel.Font     = New-Object System.Drawing.Font($fUI, 8.5)
$countLabel.ForeColor = $cSubText
$countLabel.Location = New-Object System.Drawing.Point(0, 27)
$countLabel.Size     = New-Object System.Drawing.Size(388, 18)
$countLabel.TextAlign = "MiddleCenter"
$countLabel.BackColor = $cCard
$statusPanel.Controls.Add($countLabel)

$infoLabel          = New-Object System.Windows.Forms.Label
$infoLabel.Font     = New-Object System.Drawing.Font($fUI, 7.5)
$infoLabel.Location = New-Object System.Drawing.Point(0, 812)
$infoLabel.Size     = New-Object System.Drawing.Size(420, 0)
$infoLabel.Visible  = $false
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

function Update-UILanguage {
    foreach ($t in $script:translatables) {
        $t.Control.Text = Get-String $t.Key
    }
    $form.Text = "$(Get-String 'TITLE')"
    $sel = $typeBox.SelectedIndex
    $typeBox.Items.Clear()
    [void]$typeBox.Items.Add((Get-String "MOUSE_LEFT"))
    [void]$typeBox.Items.Add((Get-String "MOUSE_RIGHT"))
    $typeBox.SelectedIndex = [Math]::Max(0, $sel)
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
        $catLabel.Text         = "😸"
        $statusLabel.Text      = Get-String 'STATUS_RUNNING'
        $statusLabel.ForeColor = $cGoTxt
        $toggleBtn.Text        = Get-String 'BTN_STOP'
        $toggleBtn.BackColor   = $cStop
        $toggleBtn.Tag         = "stop"

        if ([bool]$turboCheck.Checked) {
            $script:turboMode = $true
            $engine.Running   = $true
            Enable-TurboMode -ClickTimer $clickTimer
            $clickTimer.Start()
        } else {
            $script:turboMode = $false
            $engine.Running   = $true
            Disable-TurboMode -ClickTimer $clickTimer
            $clickTimer.Start()
        }
    } else {
        $engine.Running   = $false
        $script:turboMode = $false
        $clickTimer.Stop()
        Disable-TurboMode -ClickTimer $clickTimer
        $catLabel.Text         = "🐱"
        $statusLabel.Text      = Get-String 'STATUS_STOPPED'
        $statusLabel.ForeColor = $cStopTxt
        $toggleBtn.Text        = Get-String 'BTN_START'
        $toggleBtn.BackColor   = $cGo
        $toggleBtn.Tag         = "go"
        $pawLabel.Text         = "🐾 ∙ ∙ ∙ ∙ ∙ 🐾"
    }
}

# Timer
$clickTimer          = New-Object System.Windows.Forms.Timer
$clickTimer.Interval = 50
$clickTimer.Add_Tick({
    if (-not $engine.Running) { return }

    if ($script:turboMode) {
        $reached = Invoke-TurboBurst -Engine $engine
        $countLabel.Text = "$(Get-String 'CLICK_COUNT')$($engine.ClickCount)"
        if ($pawLabel.Text -eq "🐾 ∙ ∙ ∙ ∙ ∙ 🐾") { $pawLabel.Text = "🐾 ✦ ✦ ✦ ✦ ✦ 🐾" }
        else { $pawLabel.Text = "🐾 ∙ ∙ ∙ ∙ ∙ 🐾" }
        if ($reached) {
            Set-Running $false
            [System.Media.SystemSounds]::Asterisk.Play()
        }
    } else {
        Sync-SettingsFromUI
        Invoke-EngineClick -Engine $engine
        $countLabel.Text = "$(Get-String 'CLICK_COUNT')$($engine.ClickCount)"
        if ($pawLabel.Text -eq "🐾 ∙ ∙ ∙ ∙ ∙ 🐾") { $pawLabel.Text = "🐾 ✦ ✦ ✦ ✦ ✦ 🐾" }
        else { $pawLabel.Text = "🐾 ∙ ∙ ∙ ∙ ∙ 🐾" }
        if (Test-EngineLimitReached -Engine $engine) {
            Set-Running $false
            [System.Media.SystemSounds]::Asterisk.Play()
            return
        }
        $clickTimer.Interval = Get-EngineNextDelay -Engine $engine
    }
})

# Global F6
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

# Olaylar
$langCodes = @("EN","TR","ZH","HI","ES","FR","AR","BN","PT","RU","UR")
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
        $humanCheck.Checked  = $false
        $humanCheck.Enabled  = $false
    } else {
        $humanCheck.Enabled  = $true
    }
})
$form.Add_FormClosing({
    $clickTimer.Stop()
    $hotkeyTimer.Stop()
})

$toggleBtn.Tag = "go"
Update-HumanControlsEnabled
Update-UILanguage
[void]$form.ShowDialog()
