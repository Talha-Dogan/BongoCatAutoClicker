# ============================================================
#  Localization.ps1
#  Sorumluluk (SRP): Dil desteği (İngilizce / Türkçe)
# ============================================================

$script:lang = "EN"  # Default language

$script:strings = @{
    "EN" = @{
        # Başlık ve genel
        "TITLE" = "Bongo Cat Auto Clicker"
        "EMOJI_CAT" = "🐱"
        "EMOJI_MII" = "😊"
        "EMOJI_PAW" = "🐾"
        "EMOJI_MUSIC" = "🎵"
        "EMOJI_TURBO" = "⚡"

        # Gruplar
        "GRP_SPEED" = "🐾 Click Speed"
        "GRP_HUMAN" = "🐾 Human-Like Behavior (Anti-Ban)"
        "GRP_CLICK" = "🐾 Click Options"

        # Ayarlar
        "BASE_INTERVAL" = "Base interval (ms):"
        "VARIANCE" = "Speed variance (%):"
        "HUMAN_MODE" = "Human-like mode (recommended)"
        "JITTER" = "Cursor jitter (pixels):"
        "HOLD_MIN" = "Hold time min (ms):"
        "HOLD_MAX" = "Hold time max (ms):"
        "BREAK_CHANCE" = "Break chance (%):"
        "TURBO_MODE" = "⚡ TURBO MODE (1000+ CPS)"
        "MOUSE_BUTTON" = "Mouse button:"
        "REPEAT" = "Repeat (0 = unlimited):"

        # Butonlar
        "BTN_START" = "▶  START  (F6)"
        "BTN_STOP" = "⏸  STOP  (F6)"

        # Durum
        "STATUS_RUNNING" = "😸 Status: RUNNING"
        "STATUS_STOPPED" = "💤 Status: STOPPED"
        "CLICK_COUNT" = "🐾 Clicks: "
        "INFO_TEXT" = "F6 = start/stop  •  move cursor to target and press"

        # Dil seçimi
        "LANGUAGE" = "Language:"
    }

    "TR" = @{
        # Başlık ve genel
        "TITLE" = "Bongo Cat Auto Clicker"
        "EMOJI_CAT" = "🐱"
        "EMOJI_MII" = "😊"
        "EMOJI_PAW" = "🐾"
        "EMOJI_MUSIC" = "🎵"
        "EMOJI_TURBO" = "⚡"

        # Gruplar
        "GRP_SPEED" = "🐾 Tiklama Hızı"
        "GRP_HUMAN" = "🐾 İnsansı Davranış (Anti-Ban)"
        "GRP_CLICK" = "🐾 Tıklama Seçenekleri"

        # Ayarlar
        "BASE_INTERVAL" = "Temel aralık (ms):"
        "VARIANCE" = "Hız değişkenliği (%):"
        "HUMAN_MODE" = "İnsansı mod (önerilir)"
        "JITTER" = "İmleç sapması (piksel):"
        "HOLD_MIN" = "Basılı tutma min (ms):"
        "HOLD_MAX" = "Basılı tutma maks (ms):"
        "BREAK_CHANCE" = "Mola olasılığı (%):"
        "TURBO_MODE" = "⚡ TURBO MOD (1000+ CPS)"
        "MOUSE_BUTTON" = "Fare tuşu:"
        "REPEAT" = "Tekrar (0 = sınırsız):"

        # Butonlar
        "BTN_START" = "▶  BAŞLAT  (F6)"
        "BTN_STOP" = "⏸  DURDUR  (F6)"

        # Durum
        "STATUS_RUNNING" = "😸 Durum: ÇALIŞIYOR"
        "STATUS_STOPPED" = "💤 Durum: DURDU"
        "CLICK_COUNT" = "🐾 Tiklama: "
        "INFO_TEXT" = "F6 = başlat/durdur  •  imleci hedefe getirip bas"

        # Dil seçimi
        "LANGUAGE" = "Dil:"
    }
}

function Get-String {
    param([string]$Key)
    return $script:strings[$script:lang][$Key]
}

function Set-Language {
    param([string]$newLang)
    if ($script:strings.ContainsKey($newLang)) {
        $script:lang = $newLang
        return $true
    }
    return $false
}

function Get-AvailableLanguages {
    return $script:strings.Keys
}
