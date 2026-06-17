# ============================================================
#  TurboEngine.ps1
#  Sorumluluk (SRP): Maksimum hizli tiklama modu.
#  Ayrı thread yerine, timer interval'i 0 yaparak ultra-fast mode.
#  Güvenli: her zaman kontrol edilebilir, kapatılabilir.
# ============================================================

# Turbo modu sadece normal engine'i interval=0 ile kullanmak demek
# Separate thread'e gerek yok, WinForms timer bunu handle ediyor

function Enable-TurboMode {
    param($ClickTimer)
    $ClickTimer.Interval = 0  # Maximum speed (tight loop)
}

function Disable-TurboMode {
    param($ClickTimer)
    $ClickTimer.Interval = 50  # Normal refresh rate
}
