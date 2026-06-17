# ============================================================
#  build-exe.ps1
#  Bongo Cat Auto Clicker'i tek basli .exe dosyasina derler.
#
#  Kullanim:
#    1. PowerShell'i AC (Admin degilse de olur)
#    2. bu klasore git: cd C:\Users\Talha\Desktop\BomboclsAutoClicker
#    3. calistir: .\build-exe.ps1
#
#  Sonuc: BongoCatAutoClicker.exe olu?ur (paylas?lir, bagimlilik yok)
# ============================================================

$ErrorActionPreference = "Stop"

Write-Output "=== Bongo Cat Auto Clicker .EXE Derlemesi ==="
Write-Output ""

# PS2EXE kurulu mu kontrol et
$ps2exe = Get-Module ps2exe -ListAvailable
if (-not $ps2exe) {
    Write-Output "ps2exe modulu bulunmadi. Yükleniyor..."
    try {
        Install-Module ps2exe -Scope CurrentUser -Force -ErrorAction Stop
        Write-Output "✓ ps2exe yüklendi"
    } catch {
        Write-Output "✗ HATA: ps2exe yüklenemedi"
        Write-Output "   Elle yükleyin: Install-Module ps2exe -Scope CurrentUser"
        exit 1
    }
}

Write-Output "✓ ps2exe modu bulundu"
Write-Output ""

$scriptPath = "BongoCatAutoClicker.ps1"
$exePath = "BongoCatAutoClicker.exe"

if (-not (Test-Path $scriptPath)) {
    Write-Output "✗ HATA: $scriptPath bulunmadi (calisma klasöründe olmali)"
    exit 1
}

Write-Output "Derlenior..."
Write-Output "  Giris : $scriptPath"
Write-Output "  Cikis : $exePath"
Write-Output ""

try {
    ps2exe -inputFile $scriptPath -outputFile $exePath -runtime ps50 -STA -NonInteractive -Visible -ErrorAction Stop
    Write-Output "✓ Derleme basarili!"
    Write-Output ""
    Write-Output "=== HAZIR ==="
    Write-Output "$exePath dosyasini herhangi bir Windows cihazina kopyalayip cift tiklayin."
    Write-Output ""
    Write-Output "VirusTotal kontrolü icin (güvenlik):"
    Write-Output "  https://www.virustotal.com/gui/home/upload"
} catch {
    Write-Output "✗ Derleme hatasi:"
    Write-Output $_.Exception.Message
    exit 1
}
