# LUMETRA — iOS camera app project

**Tagline:** Control the Light. Shape the Frame.

This is the complete starter project bundle for the first LUMETRA development milestone. It includes the Swift source, an XcodeGen project definition, and GitHub Actions workflows.

## What is included in this milestone

- Live AVFoundation camera preview
- Camera permission handling
- Front/rear camera switching
- Rear wide and ultra-wide lens switching when available
- Tap-to-focus and autofocus
- Digital zoom
- Photo capture and save to Photos
- MOV video recording and save to Photos
- Basic manual ISO and shutter-duration controls
- Manual focus control where supported
- Flash and torch controls
- Basic portrait/landscape capture orientation handling
- Dark SwiftUI camera interface

## Important: this is a starter build, not a finished camera product

The source has not been compiled or tested on an Apple device in this environment. It must be built with Xcode on macOS and tested on the iPhone. Treat this as a development foundation; compiler/API fixes may be required during the first Xcode build.

The regular iPhone 13 is not an iPhone 13 Pro. Do not assume ProRes, Apple Log/Log 2, ProRes RAW, Open Gate, or other Pro-only features are available. LUMETRA should only expose capture options supported by the active device and camera format.

## Project setup

This repository uses **XcodeGen** to create `LUMETRA.xcodeproj` from `project.yml`.

### On a Mac

1. Install Xcode and open it once to complete setup.
2. Install XcodeGen: `brew install xcodegen`
3. Open Terminal in the project folder.
4. Run: `xcodegen generate`
5. Open `LUMETRA.xcodeproj` in Xcode.
6. Select the LUMETRA scheme and your iPhone 13 as the run destination.
7. Set your Apple Development Team under **Signing & Capabilities** if building directly in Xcode.
8. Connect the iPhone, accept the trust prompts, and press Run.

The app's bundle identifier is currently `com.lumetra.camera`. Change it in `project.yml` if you need a unique identifier for your Apple Developer account.

## GitHub Actions

Two manual workflows are included under `.github/workflows/`.

### 1. Build unsigned

File: `.github/workflows/ios-build-unsigned.yml`

- Does not require Apple signing secrets.
- Generates the Xcode project using XcodeGen.
- Builds the app for iPhoneOS.
- Packages an **unsigned** IPA and uploads it as a GitHub Actions artifact.

An unsigned IPA is not ready to install on a normal iPhone. It is useful as a build artifact, but it still needs valid Apple signing and provisioning before device installation.

### 2. Build signed IPA

File: `.github/workflows/ios-build-signed.yml`

This workflow requires valid Apple signing assets and a provisioning profile that includes the test iPhone's UDID. Add these GitHub repository Actions secrets:

- `IOS_CERTIFICATE_P12_BASE64` — Base64-encoded Apple Development `.p12` certificate
- `IOS_CERTIFICATE_PASSWORD` — password protecting that `.p12`
- `IOS_PROVISIONING_PROFILE_BASE64` — Base64-encoded development provisioning profile
- `APPLE_TEAM_ID` — Apple Developer Team ID

The provisioning profile must match the app bundle ID `com.lumetra.camera`. If you change the bundle ID in `project.yml`, update the workflow's `BUNDLE_ID` value too.

For the signed workflow, ensure the provisioning profile's display name is correctly configured in the export options if your Apple account requires an explicit profile mapping. Apple signing configuration can vary by account and certificate type.

To run either workflow: open the repository on GitHub → **Actions** → select the workflow → **Run workflow**. Download the resulting artifact from the completed run.

## On Windows

You can manage the repository and edit files through the GitHub website on Windows. The actual iOS build and signing run on a macOS runner in GitHub Actions. You do not need VS Code for the documented GitHub website workflow.

## Planned next milestones

1. Validate and stabilize the capture pipeline on iPhone 13.
2. Add format and frame-rate discovery (720p/1080p/4K where supported).
3. Add codec selection (H.264/HEVC where supported).
4. Add white balance, exposure compensation, and recording telemetry.
5. Add monitoring tools such as histogram, zebra, focus peaking, guides, and audio meters.
6. Add LUT monitoring and a media browser, with hardware capability checks.

Do not advertise a feature as supported until it has been verified on the target iPhone and capture format.
