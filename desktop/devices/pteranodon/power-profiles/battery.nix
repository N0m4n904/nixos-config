# BATTERY profile — applied while the COSMIC power widget is set to "Power
# Saver" (power-profiles-daemon `power-saver`). Low-power CPU envelope, Bluetooth
# radio off, dimmed display. Watched and applied by the battery-watch service in
# ./default.nix; reverted (CPU restored to the active dev/gaming mode, Bluetooth
# unblocked, brightness restored) when the widget leaves Power Saver.
#
# Pure data. PPT limits are in milliwatts.
{
  ppt = {
    stapm = 22000; # sustained (STAPM) limit — efficient, cool, long battery
    fast = 35000; # fast PPT (short bursts) so it still feels responsive
    slow = 22000; # slow PPT
    apuSlow = 22000; # APU PPT — the real sustained cap on Phoenix
    tctlTemp = 70; # thermal ceiling (C)
    dgpuSkinTemp = 51; # firmware default dGPU skin-temp limit
  };

  brightnessPercent = 30; # backlight level (% of max) while on battery profile
  disableBluetooth = true; # rfkill block the Bluetooth radio

  # Auto-engage this profile when discharging at/below this charge % (in
  # addition to the manual COSMIC "Power Saver" trigger). null disables it.
  autoBelowPercent = 20;
}
