# ============================================================
#  Humanizer.ps1
#  Sorumluluk (SRP): Insan davranisini taklit eden zamanlama ve
#  konum politikalari. "Ne zaman, ne kadar gecikme, ne kadar
#  sapma" kararlarini uretir. Tiklamayi KENDISI yapmaz; sadece
#  sayilar uretir (saf fonksiyonlar - test edilebilir).
# ============================================================

# Insan tepkileri normal (Gauss) dagilim gosterir; tekduze
# rastgelelik yerine ortalama etrafinda kumelenme daha dogaldir.
function Get-GaussianValue {
    param(
        [System.Random]$Rng,
        [double]$Mean,
        [double]$StdDev
    )
    $u1 = 1.0 - $Rng.NextDouble()
    $u2 = 1.0 - $Rng.NextDouble()
    $stdNormal = [Math]::Sqrt(-2.0 * [Math]::Log($u1)) * [Math]::Sin(2.0 * [Math]::PI * $u2)
    return $Mean + ($StdDev * $stdNormal)
}

# Bir sonraki tiklamaya kadar gecikmeyi insansi sekilde hesaplar.
#  - Temel araligin etrafinda Gauss dagilimi
#  - Belirli olasilikla daha uzun "mikro mola" (insanin duraklamasi)
function Get-HumanizedDelay {
    param(
        [System.Random]$Rng,
        [int]$BaseMs,
        [double]$VariancePercent,   # ornek: 20 -> std sapma = base * %20
        [double]$MicroBreakChance,  # 0..1 arasi olasilik
        [int]$MicroBreakMinMs,
        [int]$MicroBreakMaxMs
    )

    # Ara sira insan gibi uzun duraklama
    if ($MicroBreakChance -gt 0 -and $Rng.NextDouble() -lt $MicroBreakChance) {
        $extra = $Rng.Next($MicroBreakMinMs, [Math]::Max($MicroBreakMinMs + 1, $MicroBreakMaxMs + 1))
        return $extra
    }

    $stdDev = [Math]::Abs($BaseMs * ($VariancePercent / 100.0))
    $delay  = Get-GaussianValue -Rng $Rng -Mean $BaseMs -StdDev $stdDev

    # Asiri uclari makul sinirlar icinde tut (base'in %40-%200 araligi)
    $min = [Math]::Max(1, [int]($BaseMs * 0.4))
    $max = [int]($BaseMs * 2.0)
    if ($delay -lt $min) { $delay = $min }
    if ($delay -gt $max) { $delay = $max }
    return [int]$delay
}

# Basili tutma suresini de hafifce degistir (her tiklama ayni olmasin).
function Get-HumanizedHold {
    param(
        [System.Random]$Rng,
        [int]$MinMs,
        [int]$MaxMs
    )
    if ($MaxMs -le $MinMs) { return $MinMs }
    return $Rng.Next($MinMs, $MaxMs + 1)
}

# Tiklama noktasinin etrafinda kucuk rastgele sapma uretir.
# Insanlar her seferinde tam ayni pikselе tiklamaz.
function Get-JitterOffset {
    param(
        [System.Random]$Rng,
        [int]$RadiusPx
    )
    if ($RadiusPx -le 0) { return @{ X = 0; Y = 0 } }
    $dx = $Rng.Next(-$RadiusPx, $RadiusPx + 1)
    $dy = $Rng.Next(-$RadiusPx, $RadiusPx + 1)
    return @{ X = $dx; Y = $dy }
}
