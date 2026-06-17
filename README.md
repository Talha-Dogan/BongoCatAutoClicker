# 🐱 Bongo Cat Auto Clicker

<p align="center">
  <img alt="Platform" src="https://img.shields.io/badge/platform-Windows%2010%20%7C%2011-0078D6?logo=windows">
  <img alt="Language" src="https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?logo=powershell&logoColor=white">
  <img alt="Install" src="https://img.shields.io/badge/install-not%20required-success">
  <img alt="License" src="https://img.shields.io/badge/license-MIT-green">
</p>

<p align="center">
  <a href="../../archive/refs/heads/main.zip"><strong>⬇️ Download ZIP</strong></a>
</p>

---

# 📖 ENGLISH

A lightweight, **human-like** auto clicker for Windows with a friendly Bongo Cat themed UI. **No installation required** — it runs on the PowerShell that already ships with Windows. Just double-click and go.

## ⚠️ Disclaimer

This software is provided for **educational and personal use** (e.g. testing, accessibility, idle/offline games, automating repetitive desktop tasks). Automating input in **online games or third‑party services may violate their Terms of Service** and could lead to account suspension. **You are solely responsible** for how you use this tool. The author provides it "as is" with **no warranty** and accepts **no liability** for any consequences (see [LICENSE](LICENSE)). Do not use it for cheating, fraud, or any unlawful purpose.

## ✨ Features

- 🧠 **Two click modes:**
  - **Normal mode:** Human-like behavior (Gaussian intervals, micro-breaks, hold randomization, cursor jitter) — anti-ban optimization
  - **⚡ Turbo mode:** 1000+ CPS ultra-fast clicking (zero delays) — raw speed
- ⌨️ **Global hotkey `F6`** — start/stop even while the game window is focused
- 🖱️ Left / right click, clicks at the **current cursor position**
- 🔢 Repeat limit (or unlimited) with a completion sound
- 🎨 Cute pastel Bongo Cat themed UI, live click counter, paw animation, state-reactive emoji
- 📦 **Zero dependencies** — no Python, no .NET SDK, no admin rights needed to run

## 🚀 Quick Start

1. Click **⬇️ Download ZIP** above
2. Extract `BongoCatAutoClicker-main.zip`
3. Double-click **`BongoCatAutoClicker.bat`**
4. Move cursor to target, press **`F6`** to start
5. Press **`F6`** again to stop

> **If your game runs as administrator:**
> Right-click `BongoCatAutoClicker.bat` → **Run as administrator**

## 🔒 Windows Security Warning

You may see a **"The publisher could not be verified"** warning when running the `.bat` file. This is **normal and safe** — it appears because the file is unsigned (no commercial certificate). 

**Why it's safe:**
- ✅ Source code is 100% open on GitHub — inspect it freely
- ✅ No internet connection needed; no telemetry
- ✅ Only uses built-in Windows APIs
- ✅ Community-reviewed

**To remove the warning permanently:**
1. Right-click `BongoCatAutoClicker.bat` → **Properties**
2. Scroll to bottom → Check **"Unblock"** ✓
3. Click **"Apply"** → **"OK"**
4. Done! Run the file — no warning next time.

**If warning appears again:**
1. Click **"More info"** 
2. Click **"Run anyway"**

**Verify it's safe:**
- Right-click `.bat` → Edit → Full source code visible
- [GitHub source](https://github.com/Talha-Dogan/BongoCatAutoClicker) — open & transparent
- Only built-in Windows APIs, zero telemetry

## ⚙️ Settings

| Setting | Description |
|---------|-------------|
| **Base interval (ms)** | Average delay between clicks. `100` ≈ 10 clicks/sec |
| **Speed variance (%)** | Randomness around average (Gaussian). Higher = more human |
| **Human-like mode** | Enable anti-pattern behavior (recommended) |
| **Cursor jitter (px)** | Random pixel offset per click (0 = exact spot) |
| **Hold time min/max (ms)** | How long button is pressed (randomized in range) |
| **Break chance (%)** | Probability of inserting a longer human-like pause |
| **Mouse button** | Left or Right click |
| **Repeat (0 = unlimited)** | Stop after N clicks or run indefinitely |

## 🧱 Architecture

Clean separation of concerns (SOLID — single responsibility per file):

```
BongoCatAutoClicker.ps1   → UI + composition root
src/
 ├─ Interop.ps1           → Win32 hardware layer (mouse, key state)
 ├─ Humanizer.ps1         → human-like timing/jitter (pure functions)
 ├─ ClickEngine.ps1       → orchestration (combines layers)
 └─ TurboEngine.ps1        → fast-mode toggle (timer interval control)
```

## 🛠️ How Human-Like Timing Works

Instead of a fixed interval, the next delay is drawn from a **normal distribution** (Box–Muller) centered on your base interval, with occasional longer "micro-breaks." Hold times and cursor jitter are randomized too. Result: a click stream that looks far less mechanical.

## 🔧 Building & Development

### Run from Source (No Build Needed)
```bash
git clone https://github.com/Talha-Dogan/BongoCatAutoClicker.git
cd BongoCatAutoClicker
BongoCatAutoClicker.bat
```

### Build Standalone .exe (Optional)
```powershell
# Install ps2exe (one-time)
Install-Module ps2exe -Scope CurrentUser -Force

# Compile
ps2exe -inputFile BongoCatAutoClicker.ps1 -outputFile BongoCatAutoClicker.exe -runtime ps50
```

## 📄 License

[MIT](LICENSE) © 2026 Talha Doğan

---

---

# 📖 TÜRKÇE

Hafif, **insan benzeri** davranan, Windows için Bongo Cat temalı sevimli bir otomatik tıklayıcı. **Kurulum gerektirmez** — Windows'ta hazır gelen PowerShell ile çalışır. Çift tıkla, hazır.

## ⚠️ Yasal Uyarı

Bu yazılım **eğitim ve kişisel kullanım** amacıyla sunulur (test, erişilebilirlik, çevrimdışı/idle oyunlar, tekrarlayan masaüstü işlerini otomatikleştirme vb.). **Çevrimiçi oyunlarda veya üçüncü taraf servislerde** otomasyon kullanmak, ilgili platformun **Kullanım Koşulları'nı ihlal edebilir** ve hesap askıya alınmasına yol açabilir. Aracı **nasıl kullandığınızdan yalnızca siz sorumlusunuz**. Yazılım "olduğu gibi" sunulur; **hiçbir garanti verilmez** ve doğabilecek sonuçlardan yazar **sorumlu tutulamaz** ([LICENSE](LICENSE)). Hile, dolandırıcılık veya yasa dışı amaçlarla kullanmayın.

## ✨ Özellikler

- 🧠 **İki tıklama modu:**
  - **Normal mod:** İnsansı davranış (Gauss dağılımlı aralıklar, mikro molalar, değişken basılı tutma, imleç sapması) — anti-ban optimizasyonu
  - **⚡ Turbo mod:** 1000+ CPS ultra-hızlı tıklama (sıfır gecikme) — saf hız
- ⌨️ **Global F6 kısayol** — oyun penceresi ön planda olsa bile çalışır
- 🖱️ Sol / Sağ tık, imlecin **o anki konumuna** tıklar
- 🔢 Tekrar limiti (veya sınırsız) tamamlanma sesi ile
- 🎨 Sevimli pastel Bongo Cat teması, canlı tıklama sayacı, pati animasyonu, duruma göre değişen emoji
- 📦 **Sıfır bağımlılık** — Python, .NET SDK, yönetici hakkı gerekli değil

## 🚀 Hızlı Başlangıç

1. Yukarıdaki **⬇️ ZIP İndir**'e tıkla
2. `BongoCatAutoClicker-main.zip` dosyasını aç
3. **`BongoCatAutoClicker.bat`**'a çift tıkla
4. İmleci hedefe getir, **`F6`**'ya bas (başlat)
5. **`F6`**'ya tekrar bas (durdur)

> **Oyun yönetici olarak çalışıyorsa:**
> `BongoCatAutoClicker.bat` → sağ tık → **Yönetici olarak çalıştır**

## 🔒 Windows Güvenlik Uyarısı

`.bat` dosyasını çalıştırırken **"Yayıncı doğrulanamadı"** uyarısı görebilirsin. Bu **normal ve güvenlidir** — dosya imzasız olduğu için (ticari sertifika yok) gösterilir.

**Neden güvenlidir:**
- ✅ Kaynak kod tamamen açık GitHub'da — istediğin zaman inspekt et
- ✅ İnternet bağlantısı gerektirmez; telemetri yok
- ✅ Sadece yerleşik Windows API'leri kullanır
- ✅ Toplum tarafından gözden geçirilmiş

**Uyarıyı kalıcı olarak kaldırmak için:**
1. `BongoCatAutoClicker.bat` → sağ tık → **Özellikler**
2. Aşağı kaydır → **"Engellemeyi kaldır"** ✓
3. **"Uygula"** → **"Tamam"**
4. Bitir! Dosyayı çalıştır — bir daha uyarı gelmez.

**Eğer uyarı tekrar gelirse:**
1. **"Daha fazla bilgi"** tıkla
2. **"Yine de çalıştır"** tıkla

**Güvenli olduğunu doğrula:**
- `.bat` → sağ tık → Düzenle → Tüm kaynak kodu görünür
- [GitHub kaynağı](https://github.com/Talha-Dogan/BongoCatAutoClicker) — açık ve şeffaf
- Sadece yerleşik Windows API'leri, sıfır telemetri

## ⚙️ Ayarlar

| Ayar | Açıklama |
|------|----------|
| **Temel aralık (ms)** | Tıklamalar arası ortalama gecikme. `100` ≈ sn'de 10 tıklama |
| **Hız değişkenliği (%)** | Ortalama etrafında rastgelelik (Gauss). Yüksek = daha insansı |
| **İnsansı mod** | Anti-pattern davranışını aç (önerilir) |
| **İmleç sapması (px)** | Her tıklamada rastgele piksel sapması (0 = tam konum) |
| **Basılı tutma min/maks (ms)** | Tuş basılı kalma süresi (aralıkta rastgele) |
| **Mola olasılığı (%)** | Uzun insan benzeri duraklama ekleme ihtimali |
| **Fare tuşu** | Sol veya Sağ tık |
| **Tekrar (0 = sınırsız)** | N tıklamadan sonra dur veya sınırsız çalış |

## 🧱 Mimari

Sorumlulukların net ayrılması (SOLID — dosya başına tek sorumluluk):

```
BongoCatAutoClicker.ps1   → UI + birleştirme noktası
src/
 ├─ Interop.ps1           → Win32 donanım katmanı (fare, tuş durumu)
 ├─ Humanizer.ps1         → İnsansı zamanlama/sapma (saf fonksiyonlar)
 ├─ ClickEngine.ps1        → Orkestrasyon (katmanları birleştirir)
 └─ TurboEngine.ps1        → Hızlı mod toggle (timer interval kontrolü)
```

## 🛠️ İnsansı Zamanlama Nasıl Çalışır

Sabit aralık yerine, bir sonraki gecikme **normal dağılım**dan (Box–Muller) hesaplanır. Ara sıra daha uzun "mikro molalar" eklenir. Basılı tutma süresi ve imleç sapması da rastgeleştirilir. Sonuç: robotik olmayan, doğal görünen bir tıklama akışı.

## 🔧 Derleme & Geliştirme

### Kaynak Koddan Çalıştırma (Derlemeye Gerek Yok)
```bash
git clone https://github.com/Talha-Dogan/BongoCatAutoClicker.git
cd BongoCatAutoClicker
BongoCatAutoClicker.bat
```

### Bağımsız .exe Dosyası Oluştur (İsteğe Bağlı)
```powershell
# ps2exe kur (bir kez)
Install-Module ps2exe -Scope CurrentUser -Force

# Derle
ps2exe -inputFile BongoCatAutoClicker.ps1 -outputFile BongoCatAutoClicker.exe -runtime ps50
```

## 📄 Lisans

[MIT](LICENSE) © 2026 Talha Doğan
