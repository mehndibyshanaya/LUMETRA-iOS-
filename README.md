# LUMETRA iOS — Foundation 0.1

Initial native SwiftUI + AVFoundation camera app source, intended for first testing on **iPhone 13**.

## Included
- Live camera preview and camera permission handling
- Rear/front camera switching
- Rear wide/ultra-wide lens switching where available
- Tap-to-focus and autofocus
- Digital zoom
- Photo capture and save to Photos
- Video recording to MOV and save to Photos
- Basic manual ISO and shutter-duration controls
- Manual focus slider where supported
- Flash and torch controls
- Portrait/landscape orientation updates based on interface orientation

## Important device notes
The regular iPhone 13 is not an iPhone 13 Pro. It does not support Apple ProRes recording. Apple Log/Log 2, ProRes RAW, Open Gate and many advanced cinema features are not included in this first milestone. Available controls and formats depend on the active camera and device.

This source has **not** been compiled or tested in Xcode here. It is an initial development foundation, not a finished/release-ready app or IPA.

## Build on a Mac
1. Open Xcode and create a new iOS App named `LUMETRA`, using SwiftUI and Swift.
2. Set the deployment target to iOS 16 or later.
3. Add the four Swift files in the `LUMETRA` folder to the app target.
4. In the app target Info settings, add:
   - `Privacy - Camera Usage Description` (`NSCameraUsageDescription`): `LUMETRA uses the camera to capture photos and videos.`
   - `Privacy - Photo Library Additions Usage Description` (`NSPhotoLibraryAddUsageDescription`): `LUMETRA saves captured photos and videos to your Photos library.`
5. Enable portrait and both landscape orientations in the target settings.
6. Connect the iPhone 13, select it as the run destination, configure signing, then build and run.

## Windows workflow
Source editing and GitHub management can be done on Windows. Native iOS compilation and IPA signing require macOS and Xcode (a local Mac or suitable Mac build service).

## Next milestone
Add a recording configuration engine for 720p/1080p/4K where available, frame-rate selection, H.264/HEVC codec selection, recording settings display, timecode groundwork and a media browser.
