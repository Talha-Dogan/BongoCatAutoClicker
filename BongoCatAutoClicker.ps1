# ============================================================
#  Bongo Cat Auto Clicker  -  Ana Uygulama (Composition Root)
#  Sorumluluk (SRP): Sunum katmani (UI) ve katmanlarin birlestirilmesi.
#
#  Mimari (SOLID):
#    Interop.ps1     -> donanim (Win32)        [SRP]
#    Humanizer.ps1   -> insansi zamanlama      [SRP]
#    ClickEngine.ps1 -> orkestrasyon           [SRP, DIP]
#    bu dosya        -> arayuz + birlestirme
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

# --- Motoru olustur ---
$engine = New-ClickEngine

# --- Tema renkleri ---
$cBg     = [System.Drawing.Color]::FromArgb(248, 244, 236)
$cAccent = [System.Drawing.Color]::FromArgb(120, 90, 70)
$cGo     = [System.Drawing.Color]::FromArgb(140, 200, 140)
$cStop   = [System.Drawing.Color]::FromArgb(232, 140, 140)
$cGoTxt  = [System.Drawing.Color]::FromArgb(40, 150, 40)
$cStopTxt= [System.Drawing.Color]::FromArgb(190, 60, 60)

# --- Yardimci: etiketli sayisal alan (DRY) ---
function Add-LabeledNumeric {
    param($Parent, [string]$Text, [int]$Y, [int]$Min, [int]$Max, [decimal]$Value, [int]$Inc = 1, [int]$Decimals = 0)
    $lbl          = New-Object System.Windows.Forms.Label
    $lbl.Text     = $Text
    $lbl.Location = New-Object System.Drawing.Point(14, ($Y + 2))
    $lbl.Size     = New-Object System.Drawing.Size(210, 22)
    $Parent.Controls.Add($lbl)

    $num          = New-Object System.Windows.Forms.NumericUpDown
    $num.Location = New-Object System.Drawing.Point(228, $Y)
    $num.Size     = New-Object System.Drawing.Size(150, 24)
    $num.Minimum  = $Min
    $num.Maximum  = $Max
    $num.Value    = $Value
    $num.Increment = $Inc
    $num.DecimalPlaces = $Decimals
    $Parent.Controls.Add($num)
    return $num
}

# ================== FORM ==================
$form               = New-Object System.Windows.Forms.Form
$form.Text          = "Bongo Cat Auto Clicker"
$form.Size          = New-Object System.Drawing.Size(430, 670)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox   = $false
$form.BackColor     = $cBg
$form.Font          = New-Object System.Drawing.Font("Segoe UI", 9)
$form.Topmost       = $true

# --- Baslik ---
$catLabel          = New-Object System.Windows.Forms.Label
$catLabel.Text     = "=^_^=  Bongo Cat Auto Clicker"
$catLabel.Font     = New-Object System.Drawing.Font("Segoe UI", 15, [System.Drawing.FontStyle]::Bold)
$catLabel.Location = New-Object System.Drawing.Point(15, 12)
$catLabel.Size     = New-Object System.Drawing.Size(390, 32)
$catLabel.TextAlign = "MiddleCenter"
$catLabel.ForeColor = $cAccent
$form.Controls.Add($catLabel)

$pawLabel          = New-Object System.Windows.Forms.Label
$pawLabel.Text     = "_/\_      _/\_"
$pawLabel.Font     = New-Object System.Drawing.Font("Consolas", 14, [System.Drawing.FontStyle]::Bold)
$pawLabel.Location = New-Object System.Drawing.Point(15, 44)
$pawLabel.Size     = New-Object System.Drawing.Size(390, 26)
$pawLabel.TextAlign = "MiddleCenter"
$pawLabel.ForeColor = $cAccent
$form.Controls.Add($pawLabel)

# --- GRUP 1: Tiklama Hizi ---
$grpSpeed          = New-Object System.Windows.Forms.GroupBox
$grpSpeed.Text     = " Tiklama Hizi "
$grpSpeed.Location = New-Object System.Drawing.Point(15, 78)
$grpSpeed.Size     = New-Object System.Drawing.Size(395, 100)
$grpSpeed.Font     = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($grpSpeed)

$intervalBox = Add-LabeledNumeric $grpSpeed "Temel aralik (ms):" 28 1 600000 $engine.Settings.BaseIntervalMs 10
$varianceBox = Add-LabeledNumeric $grpSpeed "Hiz degiskenligi (%):" 62 0 90 $engine.Settings.VariancePercent 5

# --- GRUP 2: Insan Benzeri Davranis (Anti-Ban) ---
$grpHuman          = New-Object System.Windows.Forms.GroupBox
$grpHuman.Text     = " Insan Benzeri Davranis (Anti-Ban) "
$grpHuman.Location = New-Object System.Drawing.Point(15, 186)
$grpHuman.Size     = New-Object System.Drawing.Size(395, 196)
$grpHuman.Font     = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($grpHuman)

$humanCheck          = New-Object System.Windows.Forms.CheckBox
$humanCheck.Text     = "Insansi mod (onerilir)"
$humanCheck.Location = New-Object System.Drawing.Point(14, 24)
$humanCheck.Size     = New-Object System.Drawing.Size(360, 24)
$humanCheck.Checked  = $engine.Settings.HumanizeEnabled
$grpHuman.Controls.Add($humanCheck)

$jitterBox   = Add-LabeledNumeric $grpHuman "Imlec sapmasi (piksel):" 56 0 50 $engine.Settings.JitterRadiusPx 1
$holdMinBox  = Add-LabeledNumeric $grpHuman "Basili tutma min (ms):"  90 0 1000 $engine.Settings.HoldMinMs 5
$holdMaxBox  = Add-LabeledNumeric $grpHuman "Basili tutma maks (ms):" 124 0 1000 $engine.Settings.HoldMaxMs 5
$breakBox    = Add-LabeledNumeric $grpHuman "Mola olasiligi (%):" 158 0 100 ([decimal]($engine.Settings.MicroBreakChance * 100)) 1

# --- GRUP 3: Tiklama Secenekleri ---
$grpClick          = New-Object System.Windows.Forms.GroupBox
$grpClick.Text     = " Tiklama Secenekleri "
$grpClick.Location = New-Object System.Drawing.Point(15, 390)
$grpClick.Size     = New-Object System.Drawing.Size(395, 100)
$grpClick.Font     = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($grpClick)

$btnTypeLabel          = New-Object System.Windows.Forms.Label
$btnTypeLabel.Text     = "Fare tusu:"
$btnTypeLabel.Location = New-Object System.Drawing.Point(14, 30)
$btnTypeLabel.Size     = New-Object System.Drawing.Size(210, 22)
$btnTypeLabel.Font     = New-Object System.Drawing.Font("Segoe UI", 9)
$grpClick.Controls.Add($btnTypeLabel)

$typeBox          = New-Object System.Windows.Forms.ComboBox
$typeBox.Location = New-Object System.Drawing.Point(228, 28)
$typeBox.Size     = New-Object System.Drawing.Size(150, 24)
$typeBox.DropDownStyle = "DropDownList"
$typeBox.Font     = New-Object System.Drawing.Font("Segoe UI", 9)
[void]$typeBox.Items.Add("Sol")
[void]$typeBox.Items.Add("Sag")
$typeBox.SelectedIndex = 0
$grpClick.Controls.Add($typeBox)

$repeatBox = Add-LabeledNumeric $grpClick "Tekrar (0 = sinirsiz):" 62 0 10000000 $engine.Settings.RepeatLimit 10
$repeatBox.Font = New-Object System.Drawing.Font("Segoe UI", 9)

# --- Baslat / Durdur ---
$toggleBtn          = New-Object System.Windows.Forms.Button
$toggleBtn.Text     = "BASLAT  (F6)"
$toggleBtn.Location = New-Object System.Drawing.Point(15, 502)
$toggleBtn.Size     = New-Object System.Drawing.Size(395, 52)
$toggleBtn.Font     = New-Object System.Drawing.Font("Segoe UI", 13, [System.Drawing.FontStyle]::Bold)
$toggleBtn.BackColor = $cGo
$toggleBtn.ForeColor = [System.Drawing.Color]::White
$toggleBtn.FlatStyle = "Flat"
$toggleBtn.FlatAppearance.BorderSize = 0
$form.Controls.Add($toggleBtn)

# --- Durum / sayac / bilgi ---
$statusLabel          = New-Object System.Windows.Forms.Label
$statusLabel.Text     = "Durum: DURDU"
$statusLabel.Font     = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$statusLabel.Location = New-Object System.Drawing.Point(15, 562)
$statusLabel.Size     = New-Object System.Drawing.Size(395, 24)
$statusLabel.TextAlign = "MiddleCenter"
$statusLabel.ForeColor = $cStopTxt
$form.Controls.Add($statusLabel)

$countLabel          = New-Object System.Windows.Forms.Label
$countLabel.Text     = "Tiklama: 0"
$countLabel.Font     = New-Object System.Drawing.Font("Segoe UI", 10)
$countLabel.Location = New-Object System.Drawing.Point(15, 588)
$countLabel.Size     = New-Object System.Drawing.Size(395, 22)
$countLabel.TextAlign = "MiddleCenter"
$form.Controls.Add($countLabel)

$infoLabel          = New-Object System.Windows.Forms.Label
$infoLabel.Text     = "F6 = baslat/durdur  -  imleci hedefe getirip basin"
$infoLabel.Font     = New-Object System.Drawing.Font("Segoe UI", 8)
$infoLabel.Location = New-Object System.Drawing.Point(15, 610)
$infoLabel.Size     = New-Object System.Drawing.Size(395, 20)
$infoLabel.TextAlign = "MiddleCenter"
$infoLabel.ForeColor = [System.Drawing.Color]::Gray
$form.Controls.Add($infoLabel)

# ================== MANTIK ==================

# UI -> motor ayarlarini senkronla
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

# Insansi alanlarin aktiflik durumunu guncelle
function Update-HumanControlsEnabled {
    $on = [bool]$humanCheck.Checked
    $jitterBox.Enabled  = $on
    $holdMaxBox.Enabled = $on
    $breakBox.Enabled   = $on
    $varianceBox.Enabled = $on
}

function Set-Running {
    param([bool]$state)
    $engine.Running = $state
    if ($state) {
        Sync-SettingsFromUI
        $statusLabel.Text      = "Durum: CALISIYOR"
        $statusLabel.ForeColor = $cGoTxt
        $toggleBtn.Text        = "DURDUR  (F6)"
        $toggleBtn.BackColor   = $cStop
        $clickTimer.Interval   = 1
        $clickTimer.Start()
    } else {
        $statusLabel.Text      = "Durum: DURDU"
        $statusLabel.ForeColor = $cStopTxt
        $toggleBtn.Text        = "BASLAT  (F6)"
        $toggleBtn.BackColor   = $cGo
        $clickTimer.Stop()
        $pawLabel.Text         = "_/\_      _/\_"
    }
}

# Tiklama zamanlayicisi
$clickTimer          = New-Object System.Windows.Forms.Timer
$clickTimer.Interval = 100
$clickTimer.Add_Tick({
    if (-not $engine.Running) { return }

    Sync-SettingsFromUI
    Invoke-EngineClick -Engine $engine
    $countLabel.Text = "Tiklama: $($engine.ClickCount)"

    # pati animasyonu
    if ($pawLabel.Text -eq "_/\_      _/\_") { $pawLabel.Text = " \/        \/ " }
    else { $pawLabel.Text = "_/\_      _/\_" }

    if (Test-EngineLimitReached -Engine $engine) {
        Set-Running $false
        [System.Media.SystemSounds]::Asterisk.Play()
        return
    }

    $clickTimer.Interval = Get-EngineNextDelay -Engine $engine
})

# Global kisayol (F6)
$VK_F6 = 0x75
$script:hotkeyWasDown = $false
$hotkeyTimer          = New-Object System.Windows.Forms.Timer
$hotkeyTimer.Interval = 40
$hotkeyTimer.Add_Tick({
    $isDown = Test-KeyDown -VirtualKey $VK_F6
    if ($isDown -and -not $script:hotkeyWasDown) {
        Set-Running (-not $engine.Running)
    }
    $script:hotkeyWasDown = $isDown
})
$hotkeyTimer.Start()

# --- Olaylar ---
$toggleBtn.Add_Click({ Set-Running (-not $engine.Running) })
$humanCheck.Add_CheckedChanged({ Update-HumanControlsEnabled })
$form.Add_FormClosing({ $clickTimer.Stop(); $hotkeyTimer.Stop() })

Update-HumanControlsEnabled
[void]$form.ShowDialog()
