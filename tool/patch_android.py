#!/usr/bin/env python3
"""Patch the Flutter-generated android/ folder for Noor Alarm.

Run from the project root after `flutter create --platforms=android .`
Exits with an error if an expected change could not be applied.
"""
import pathlib
import re
import sys

ROOT = pathlib.Path("android/app")
MANIFEST = ROOT / "src/main/AndroidManifest.xml"

PERMISSIONS = [
    "RECEIVE_BOOT_COMPLETED",
    "WAKE_LOCK",
    "VIBRATE",
    "USE_FULL_SCREEN_INTENT",
    "FOREGROUND_SERVICE",
    "FOREGROUND_SERVICE_MEDIA_PLAYBACK",
    "ACCESS_NOTIFICATION_POLICY",
    "POST_NOTIFICATIONS",
    "SCHEDULE_EXACT_ALARM",
    "USE_EXACT_ALARM",
    "ACCESS_COARSE_LOCATION",
    "ACCESS_FINE_LOCATION",
]
SERVICE = (
    '<service android:name='
    '"com.gdelataillade.alarm.services.NotificationOnKillService" />'
)

errors = []


def patch_manifest() -> None:
    if not MANIFEST.exists():
        errors.append(f"{MANIFEST} not found")
        return
    text = MANIFEST.read_text(encoding="utf-8")

    # 1. permissions (before <application>)
    lines = "".join(
        f'    <uses-permission android:name="android.permission.{p}"/>\n'
        for p in PERMISSIONS
        if f'android.permission.{p}"' not in text
    )
    if lines:
        if "<application" not in text:
            errors.append("<application> tag not found in manifest")
            return
        text = text.replace("<application", lines + "    <application", 1)

    # 2. app name
    text = re.sub(r'android:label="[^"]*"', 'android:label="Noor Alarm"', text, count=1)

    # 3. show over the lock screen when an alarm rings
    if "android:showWhenLocked" not in text:
        marker = 'android:name=".MainActivity"'
        if marker not in text:
            errors.append("MainActivity not found in manifest")
            return
        text = text.replace(
            marker,
            marker
            + '\n            android:showWhenLocked="true"'
            + '\n            android:turnScreenOn="true"',
            1,
        )

    # 4. service used by the alarm plugin
    if "NotificationOnKillService" not in text:
        if "</application>" not in text:
            errors.append("</application> not found in manifest")
            return
        text = text.replace("</application>", "    " + SERVICE + "\n    </application>", 1)

    MANIFEST.write_text(text, encoding="utf-8")


def patch_gradle() -> None:
    done = False
    for name in ("build.gradle.kts", "build.gradle"):
        path = ROOT / name
        if not path.exists():
            continue
        src = path.read_text(encoding="utf-8")
        replacement = "minSdk = 23" if name.endswith(".kts") else "minSdkVersion 23"
        new = re.sub(
            r"minSdk(?:Version)?(?:\s*=\s*|\s+)flutter\.minSdkVersion",
            replacement,
            src,
        )
        if new != src:
            path.write_text(new, encoding="utf-8")
            done = True
        elif re.search(r"minSdk(?:Version)?(?:\s*=\s*|\s+)(2[3-9]|[3-9]\d)\b", src):
            done = True  # already 23 or higher
    if not done:
        errors.append("could not set minSdk to 23 in android/app/build.gradle(.kts)")


patch_manifest()
patch_gradle()

if errors:
    for e in errors:
        print("PATCH ERROR:", e, file=sys.stderr)
    sys.exit(1)
print("Android project patched.")
