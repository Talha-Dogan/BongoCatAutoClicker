# ============================================================
#  TurboEngine.ps1
#  Sorumluluk (SRP): Maksimum hizli tiklama modu.
#  WinForms timer'i mumkun olan en kisa araliga (1 ms) ayarlar ve
#  her tikte bir grup (burst) ham tiklama yapar. Boylece ~1000+ CPS
#  elde edilir; ayri thread olmadigi icin her zaman F6 ile durdurulur.
# ============================================================

# Her timer tikinde yapilacak ham tiklama sayisi.
# WinForms timer ~64 Hz calistigi icin 20 x 64 ≈ 1280 CPS verir.
$script:TurboBurstSize = 20

function Enable-TurboMode {
    param($ClickTimer)
    $ClickTimer.Interval = 1   # mumkun olan en kisa aralik (0 gecersiz)
}

function Disable-TurboMode {
    param($ClickTimer)
    $ClickTimer.Interval = 50  # normal yenileme hizi
}

# Turbo tiki: bir grup ham (hold'suz) tiklama yapar, sayaci artirir.
# $Engine.ClickCount guncellenir; limit asilirsa $true doner.
function Invoke-TurboBurst {
    param([pscustomobject]$Engine)
    $btn = $Engine.Settings.ButtonType
    $limit = $Engine.Settings.RepeatLimit
    for ($i = 0; $i -lt $script:TurboBurstSize; $i++) {
        Invoke-MouseClick -Button $btn -HoldMs 0
        $Engine.ClickCount++
        if ($limit -gt 0 -and $Engine.ClickCount -ge $limit) { return $true }
    }
    return $false
}
