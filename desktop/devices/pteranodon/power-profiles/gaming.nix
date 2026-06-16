# GAMING profile — Gamescope / Steam session.
# CPU runs at the same full power envelope as DEV (lowering it doesn't free GPU
# headroom — the dGPU is capped by its skin-temp limit, not by CPU budget — and
# only hurts CPU-heavy games). tctl is the only thermal limit; the fan keeps its
# own faster-ramp game-mode curve.
#
# Pure data, consumed by ./default.nix. PPT limits are in milliwatts.
{
  fanStrategy = "gaming";

  ppt = {
    stapm = 60000; # sustained (STAPM) limit
    fast = 75000; # fast PPT (short bursts)
    slow = 60000; # slow PPT
    apuSlow = 60000; # APU PPT — the real sustained cap on Phoenix (stock 30W)
    tctlTemp = 95; # thermal ceiling (C); only CPU thermal limit in game mode
    dgpuSkinTemp = 85; # dGPU skin-temp limit (C); firmware default 51 throttles
    # the RX 7700S hard (holds it ~40W/low clock even when cold) — this unlocks it
  };

  fan = {
    fanSpeedUpdateFrequency = 3;
    movingAverageInterval = 20;
    speedCurve = [
      {
        temp = 0;
        speed = 20;
      }
      {
        temp = 45;
        speed = 25;
      }
      {
        temp = 55;
        speed = 35;
      }
      {
        temp = 65;
        speed = 50;
      }
      {
        temp = 75;
        speed = 70;
      }
      {
        temp = 85;
        speed = 90;
      }
      {
        temp = 92;
        speed = 100;
      }
    ];
  };
}
