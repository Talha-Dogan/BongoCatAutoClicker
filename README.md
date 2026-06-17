# 🐱 Bongo Cat Auto Clicker

<p align="center">
  <img alt="Platform" src="https://img.shields.io/badge/platform-Windows%2010%20%7C%2011-0078D6?logo=windows">
  <img alt="Language" src="https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?logo=powershell&logoColor=white">
  <img alt="Install" src="https://img.shields.io/badge/install-not%20required-success">
  <img alt="License" src="https://img.shields.io/badge/license-MIT-green">
</p>

<p align="center">
  <a href="../../releases/latest"><strong>⬇️ Download</strong></a> •
  <a href="#features-özellikler"><strong>✨ Features</strong></a> •
  <a href="README_ZH.md"><strong>中文文档</strong></a> •
  <a href="#building--development-summary"><strong>🔧 Development</strong></a>
</p>

A lightweight, **human-like** auto clicker for Windows with a friendly Bongo Cat themed UI.
**No installation required** — it runs on the PowerShell that already ships with Windows. Just double-click and go.

> Hafif, **insan benzeri** davranan, Bongo Cat temalı bir otomatik tıklayıcı.
> **Kurulum gerektirmez** — Windows'ta hazır gelen PowerShell ile çalışır. Çift tıkla, hazır.

---

## ⚠️ Disclaimer / Yasal Uyarı

**English** — This software is provided for **educational and personal use** (e.g. testing, accessibility, idle/offline games, automating repetitive desktop tasks). Automating input in **online games or third‑party services may violate their Terms of Service** and could lead to account suspension. **You are solely responsible** for how you use this tool. The author provides it "as is" with **no warranty** and accepts **no liability** for any consequences (see [LICENSE](LICENSE)). Do not use it for cheating, fraud, or any unlawful purpose.

**Türkçe** — Bu yazılım **eğitim ve kişisel kullanım** amacıyla sunulur (test, erişilebilirlik, çevrimdışı/idle oyunlar, tekrarlayan masaüstü işlerini otomatikleştirme vb.). **Çevrimiçi oyunlarda veya üçüncü taraf servislerde** otomasyon kullanmak, ilgili platformun **Kullanım Koşulları'nı ihlal edebilir** ve hesap askıya alınmasına yol açabilir. Aracı **nasıl kullandığınızdan yalnızca siz sorumlusunuz**. Yazılım "olduğu gibi" sunulur; **hiçbir garanti verilmez** ve doğabilecek sonuçlardan yazar **sorumlu tutulamaz** ([LICENSE](LICENSE)). Hile, dolandırıcılık veya yasa dışı amaçlarla kullanmayın.

---

## ✨ Features / Özellikler

- 🧠 **Two click modes:**
  - **Normal mode:** Human-like behavior (Gaussian intervals, micro-breaks, hold randomization, cursor jitter) — anti-ban optimization
  - **⚡ Turbo mode:** 1000+ CPS ultra-fast clicking (high-priority thread, zero delays) — raw speed
- ⌨️ **Global hotkey `F6`** — start/stop even while the game window is focused
- 🖱️ Left / right click, clicks at the **current cursor position**
- 🔢 Repeat limit (or unlimited) with a completion sound
- 🎨 Cute pastel Bongo Cat themed UI, live click counter, paw animation, state-reactive emoji
- 📦 **Zero dependencies** — no Python, no .NET SDK, no admin rights needed to run

---

## 🚀 Quick Start / Hızlı Başlangıç

1. **Download / clone** this repository.
2. Double-click **`BongoCatAutoClicker.bat`**.
3. Adjust the settings, move your cursor over the target, and press **`F6`** (or click **BAŞLAT**).
4. Press **`F6`** again to stop.

> If a game runs **as administrator**, run the launcher as admin too:
> right-click `BongoCatAutoClicker.bat` → **Run as administrator**.
>
> Oyun **yönetici olarak** çalışıyorsa başlatıcıyı da yönetici çalıştırın:
> `BongoCatAutoClicker.bat` → sağ tık → **Yönetici olarak çalıştır**.

### Requirements / Gereksinimler
- Windows 10 / 11 (Windows PowerShell 5.1 — preinstalled)
- No internet connection or installation needed

---

## ⚙️ Settings / Ayarlar

| Setting (UI) | Açıklama |
| --- | --- |
| **Temel aralık (ms)** | Average delay between clicks. `100` ≈ 10 clicks/sec. |
| **Hız değişkenliği (%)** | Randomness around the average (Gaussian std-dev). Higher = more human. |
| **İnsansı mod** | Master toggle for all human-like behavior. Recommended ON. |
| **İmleç sapması (piksel)** | Random pixel offset around the click point. `0` = click exact spot. |
| **Basılı tutma min / maks (ms)** | How long the button is held down per click (randomized in this range). |
| **Mola olasılığı (%)** | Chance per click to insert a longer human-like pause. |
| **Fare tuşu** | Left (`Sol`) or right (`Sag`) click. |
| **Tekrar (0 = sınırsız)** | Stop after N clicks (plays a sound), or run until you stop it. |

---

## 🧱 Architecture / Mimari

The code follows a clean separation of concerns (SOLID — single responsibility per file):

```
BongoCatAutoClicker.ps1   → UI + composition root (presentation)
src/
 ├─ Interop.ps1           → Win32 hardware layer (mouse, key state)            [SRP]
 ├─ Humanizer.ps1         → human-like timing/jitter policy (pure, testable)   [SRP]
 ├─ ClickEngine.ps1       → orchestration: combines Interop + Humanizer       [SRP, DIP]
 └─ TurboEngine.ps1        → high-priority thread for 1000+ CPS ultra-fast     [SRP]
```

- **Interop** knows only the OS; it has no idea a UI exists.
- **Humanizer** produces numbers (delays, offsets) and is pure/testable — it never clicks.
- **ClickEngine** wires hardware + behavior together via injected functions (dependency inversion).
- **The UI** is just presentation and the place where everything is composed.

This makes the timing logic unit-testable and each piece replaceable without touching the others.

---

## 🛠️ How human-like timing works

Instead of a fixed interval, the next delay is drawn from a **normal distribution** (Box–Muller transform) centered on your base interval, clamped to a sane range, with an occasional longer "micro-break." Hold times and a tiny cursor jitter are randomized too. The result is a click stream that looks far less mechanical than a constant-rate clicker.

---

## 🔧 Building & Development Summary

### Run from Source (No Build Needed)
```bash
git clone https://github.com/Talha-Dogan/BongoCatAutoClicker.git
cd BongoCatAutoClicker
BongoCatAutoClicker.bat
```

### Build Standalone .exe
To create a single `.exe` file (no PowerShell visible):

1. **Install PS2EXE** (one-time setup):
   ```powershell
   Install-Module ps2exe -Scope CurrentUser -Force
   ```

2. **Compile**:
   ```powershell
   ps2exe -inputFile BongoCatAutoClicker.ps1 -outputFile BongoCatAutoClicker.exe -runtime ps50
   ```

3. Share the `.exe` — it includes all modules bundled.

### Project Structure
- `BongoCatAutoClicker.ps1` — main UI
- `BongoCatAutoClicker.bat` — launcher (hides PowerShell window)
- `src/` — modular engine components (SOLID)
- `LICENSE`, `README.md` — docs

### Antivirus / Security
- **VirusTotal**: [Check latest release](../../releases/latest)
- The tool uses only standard Win32 APIs and Windows.Forms (both built-in)
- Source is fully transparent — inspect the code before running

---

## 📄 License

[MIT](LICENSE) © 2026 Talha Doğan
