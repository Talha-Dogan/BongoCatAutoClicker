# ============================================================
#  ClickEngine.ps1
#  Sorumluluk (SRP): Tiklama akisini yonetir. Donanim katmani
#  (Interop) ile davranis katmanini (Humanizer) birlestirir.
#  Arayuzu (UI) bilmez -> sunum katmanindan bagimsizdir.
#  Bagimliliklar disaridan dot-source ile saglanir.
# ============================================================

# Varsayilan, insansi ayarlarla yeni bir motor durumu olusturur.
function New-ClickEngine {
    return [pscustomobject]@{
        # --- Calisma durumu ---
        Running    = $false
        ClickCount = 0
        Rng        = (New-Object System.Random)

        # --- Ayarlar (insan benzeri varsayilanlar) ---
        Settings = @{
            ButtonType        = 'Left'   # Left / Right
            BaseIntervalMs    = 120
            VariancePercent   = 25       # Gauss sapmasi (insansilik)
            HoldMinMs         = 40
            HoldMaxMs         = 90
            JitterRadiusPx    = 2        # tiklama noktasi etrafindaki sapma
            MicroBreakChance  = 0.03     # ~%3 ihtimalle uzun duraklama
            MicroBreakMinMs   = 600
            MicroBreakMaxMs   = 1800
            RepeatLimit       = 0        # 0 = sinirsiz
            HumanizeEnabled   = $true
        }
    }
}

# Tek bir insansi tiklama gerceklestirir (jitter + degisken hold dahil).
function Invoke-EngineClick {
    param([pscustomobject]$Engine)

    $s = $Engine.Settings

    if ($s.HumanizeEnabled -and $s.JitterRadiusPx -gt 0) {
        $pos    = Get-CursorPosition
        $offset = Get-JitterOffset -Rng $Engine.Rng -RadiusPx $s.JitterRadiusPx
        Set-CursorPosition -X ($pos.X + $offset.X) -Y ($pos.Y + $offset.Y)
    }

    $hold = if ($s.HumanizeEnabled) {
        Get-HumanizedHold -Rng $Engine.Rng -MinMs $s.HoldMinMs -MaxMs $s.HoldMaxMs
    } else {
        $s.HoldMinMs
    }

    Invoke-MouseClick -Button $s.ButtonType -HoldMs $hold
    $Engine.ClickCount++
}

# Bir sonraki tiklamaya kadar beklenecek sureyi (ms) dondurur.
function Get-EngineNextDelay {
    param([pscustomobject]$Engine)

    $s = $Engine.Settings
    if (-not $s.HumanizeEnabled) {
        return [Math]::Max(1, $s.BaseIntervalMs)
    }

    return Get-HumanizedDelay -Rng $Engine.Rng `
        -BaseMs $s.BaseIntervalMs `
        -VariancePercent $s.VariancePercent `
        -MicroBreakChance $s.MicroBreakChance `
        -MicroBreakMinMs $s.MicroBreakMinMs `
        -MicroBreakMaxMs $s.MicroBreakMaxMs
}

# Tekrar sinirina ulasildi mi?
function Test-EngineLimitReached {
    param([pscustomobject]$Engine)
    $limit = $Engine.Settings.RepeatLimit
    return ($limit -gt 0 -and $Engine.ClickCount -ge $limit)
}
