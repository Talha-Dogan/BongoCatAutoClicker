# ============================================================
#  TurboEngine.ps1
#  Sorumluluk (SRP): Maksimum hizli tiklama. WinForms zamanlayicisi
#  ~60/sn ile sinirlidir; 1000+ CPS icin ayri, yuksek oncelikli bir
#  is parcacigi ve Stopwatch tabanli hassas hizlandirma gerekir.
#  Bu katman SADECE en yuksek hizli tiklamadan sorumludur.
# ============================================================

if (-not ('Native.BongoTurbo' -as [type])) {
    Add-Type -Namespace 'Native' -Name 'BongoTurbo' -UsingNamespace @(
        'System.Threading', 'System.Diagnostics'
    ) -MemberDefinition @'
[DllImport("user32.dll")]
private static extern void mouse_event(uint dwFlags, uint dx, uint dy, uint dwData, int dwExtraInfo);

private static volatile bool _running = false;
private static long _count = 0;
private static System.Threading.Thread _thread;

public static bool IsRunning { get { return _running; } }
public static long Count { get { return System.Threading.Interlocked.Read(ref _count); } }

// right  : sag tus mu?
// cps    : hedef tiklama/sn (0 = sinirsiz, donanimin elverdigi kadar)
// limit  : toplam tiklama siniri (0 = sinirsiz)
public static void Start(bool right, int cps, long limit)
{
    Stop();
    _running = true;
    _count = 0;
    uint down = right ? 0x0008u : 0x0002u;
    uint up   = right ? 0x0010u : 0x0004u;

    _thread = new System.Threading.Thread(delegate()
    {
        long freq = System.Diagnostics.Stopwatch.Frequency;
        long ticksPerClick = (cps > 0) ? (freq / cps) : 0;
        System.Diagnostics.Stopwatch sw = System.Diagnostics.Stopwatch.StartNew();
        long next = sw.ElapsedTicks;

        while (_running)
        {
            mouse_event(down, 0, 0, 0, 0);
            mouse_event(up,   0, 0, 0, 0);
            long c = System.Threading.Interlocked.Increment(ref _count);

            if (limit > 0 && c >= limit) { break; }

            if (ticksPerClick > 0)
            {
                next += ticksPerClick;
                while (sw.ElapsedTicks < next)
                {
                    if (!_running) { break; }
                }
            }
        }
        _running = false;
    });
    _thread.IsBackground = true;
    _thread.Priority = System.Threading.ThreadPriority.Highest;
    _thread.Start();
}

public static void Stop()
{
    _running = false;
    if (_thread != null && _thread.IsAlive) { _thread.Join(250); }
    _thread = null;
}
'@ | Out-Null
}

# --- PowerShell sarmalayicilari ---
function Start-Turbo {
    param(
        [ValidateSet('Left', 'Right')] [string]$Button = 'Left',
        [int]$Cps = 1000,
        [long]$Limit = 0
    )
    [Native.BongoTurbo]::Start(($Button -eq 'Right'), $Cps, $Limit)
}

function Stop-Turbo        { [Native.BongoTurbo]::Stop() }
function Get-TurboCount    { return [Native.BongoTurbo]::Count }
function Test-TurboRunning { return [Native.BongoTurbo]::IsRunning }
