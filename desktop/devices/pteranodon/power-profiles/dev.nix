# DEV profile — COSMIC desktop / development.
# Goal: maximum sustained CPU performance with a 95C thermal ceiling (matching
# desktop Ryzen 7000 Tjmax behaviour) and a fan curve that cools hard without
# screaming. Power envelope stays wide so light/bursty loads boost fully; the
# tctl ceiling governs sustained heavy load.
#
# Pure data, consumed by ./default.nix. PPT limits are in milliwatts.
{
  fanStrategy = "dev";

  ppt = {
    stapm = 60000; # sustained (STAPM) limit
    fast = 75000; # fast PPT (short bursts)
    slow = 60000; # slow PPT
    apuSlow = 60000; # APU PPT — the real sustained cap on Phoenix (stock 30W)
    tctlTemp = 95; # thermal ceiling (C); SMU throttles power to hold this
    dgpuSkinTemp = 51; # restore firmware default dGPU skin-temp limit on desktop
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
        temp = 50;
        speed = 22;
      }
      {
        temp = 60;
        speed = 30;
      }
      {
        temp = 70;
        speed = 40;
      }
      {
        temp = 78;
        speed = 44;
      }
      {
        temp = 85;
        speed = 52;
      }
      {
        temp = 90;
        speed = 58;
      }
      {
        # Steady-state operating point under sustained load (tctl caps temp here).
        temp = 95;
        speed = 66;
      }
      {
        # Emergency net only — tctl-temp=95 should keep us from reaching this.
        temp = 98;
        speed = 80;
      }
      {
        temp = 100;
        speed = 100;
      }
    ];
  };
}
