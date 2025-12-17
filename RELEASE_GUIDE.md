# 🚀 Release Guide

This internal guide details the steps to build the `MIDI Gloves` application and publish it to GitHub Releases for users to download.

## 1. Update Version (Optional)

If you are releasing a new version, update `version` in `pubspec.yaml`:

```yaml
version: 1.0.1+2
```

## 2. Build the APK

Open your terminal in the project root (`midi_gloves_app`) and run:

```bash
flutter build apk --release
```

**Output Location:**
The built APK will be located at:
`build/app/outputs/flutter-apk/app-release.apk`

## 3. Create a GitHub Release

1.  Go to the **[Releases](../../releases)** page of your GitHub repository.
2.  Click **"Draft a new release"**.
3.  **Choose a tag**: Create a new version tag (e.g., `v1.0.0`).
4.  **Release title**: Give it a name (e.g., `Initial Release` or `v1.0.0`).
5.  **Description**: detailed description of what's new. Use the button "Generate release notes" if you want to auto-fill based on PRs.
6.  **Attach binaries**:
    - Drag and drop the `app-release.apk` file you built in Step 2 into the "Attach binaries by dropping them here..." box.
    - _Tip:_ You can rename `app-release.apk` to something more specific like `MidiGloves_v1.0.0.apk` before uploading.
7.  Click **"Publish release"**.

## 4. Verify

Go to your `README.md` on the main page. The "Download" link should now lead users to the release you just created, where they can find the APK under "Assets".
