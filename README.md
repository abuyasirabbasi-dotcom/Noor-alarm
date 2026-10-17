# Noor Alarm (نور الارم)

Smart alarm app: wake-up math mission, prayer-time alarms, Hijri calendar,
English / اردو / العربية (with right-to-left layout), and slots for Islamic ringtones.

## APK kaise banayein (bina technical knowledge ke)

Aapko apne computer par kuch install karne ki zaroorat nahi. GitHub (free) APK khud bana deta hai.

1. https://github.com par free account banayein, phir **New repository** banayein (naam: `noor-alarm`).
2. Is poore folder ki saari files repository mein upload karein
   (**Add file > Upload files**; `.github` folder bhi shamil hona chahiye).
3. **Actions** tab kholein > **Build APK** > **Run workflow**.
4. 5-10 minute baad build poora hone par us run ko kholein aur neeche
   **Artifacts > noor-alarm-apk** download karein. Is mein `app-release.apk` hai.
5. APK ko phone mein bhej kar install karein (Android Settings mein "unknown sources" ki ijazat deni hogi).

Agar build fail ho jaye, to run ka error text copy kar ke mujhe bhej dein, main fix kar dunga.

## Islamic ringtones

`assets/audio/README.txt` parhein. Apni licensed audio files in naamon se rakhein:
`azan_makkah`, `azan_madinah`, `takbeer`, `quran_recitation`, `morning_dua`.
App unhein khud pehchan leti hai. Azan/Quran ki recordings aam taur par copyrighted hoti hain,
sirf wahi use karein jinki ijazat ho.

## Features

- Alarms: repeat days, label, ringtone, vibration, volume, 9-minute snooze
- Wake-up missions: solve 3 math problems, or shake the phone 25 times, to stop the alarm
  (if the phone has no motion sensor, the shake mission falls back to math)
- Qibla compass (Prayer tab) using the phone's compass sensor
- Prayer alarms: Fajr/Dhuhr/Asr/Maghrib/Isha/Sunrise with +/- minute offset, updated daily
- Prayer times: GPS or preset cities, 5 calculation methods, Hanafi / other Asr
- Hijri calendar: month view, Gregorian dates, Islamic dates, 1-2 day moon-sighting adjustment
- Languages: English, Urdu, Arabic

## Known limits (version 1)

- Android only (iOS needs a Mac and extra setup).
- The APK is signed with a debug key: fine for installing yourself, not for Google Play.
- Urdu uses the phone's default Arabic-script font (not Nastaliq).
- Not yet included: QR/photo missions, sleep tracking.
- Qibla needs a phone with a compass (magnetometer) sensor; keep it away from magnets/metal.
- Some phone brands (Xiaomi, Oppo, Vivo, Huawei) kill background apps; the user may need to
  allow "Autostart" and "Battery: no restrictions" for reliable alarms.

## Developers

`flutter create --platforms=android .` then `python3 tool/patch_android.py`, then `flutter run`.
`tool/make_tones.py` regenerates the built-in tones.
