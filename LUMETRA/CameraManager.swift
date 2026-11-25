import AVFoundation
import Combine
import Photos
import UIKit

final class CameraManager: NSObject, ObservableObject {
    @Published var permissionGranted = false
    @Published var permissionMessage: String?
    @Published var status = "STARTING"
    @Published var isRecording = false
    @Published var isPhotoMode = true
    @Published var isFront = false
    @Published var zoom: CGFloat = 1
    @Published var lens = "1×"
    @Published var iso: Float = 100
    @Published var shutter = 1.0 / 60.0
    @Published var focus: Float = 0.5
    @Published var manualExposure = false
    @Published var flash = false
    @Published var torch = false
    @Published var alertMessage: String?

    let session = AVCaptureSession()
    private let queue = DispatchQueue(label: "lumetra.capture.queue")
    private let photoOutput = AVCapturePhotoOutput()
    private let movieOutput = AVCaptureMovieFileOutput()
    private var input: AVCaptureDeviceInput?
    private var device: AVCaptureDevice?
    private var orientation: AVCaptureVideoOrientation = .portrait

    override init() {
        super.init()
        requestPermission()
    }

    func requestPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permissionGranted = true
            configure()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] ok in
                DispatchQueue.main.async {
                    self?.permissionGranted = ok
                    if ok { self?.configure() }
                    else { self?.permissionMessage = "Camera access is required." }
                }
            }
        default:
            permissionMessage = "Allow camera access in iPhone Settings to use LUMETRA."
        }
    }

    private func configure() {
        queue.async {
            self.session.beginConfiguration()
            self.session.sessionPreset = .high
            guard let camera = self.findCamera(position: .back, type: .builtInWideAngleCamera),
                  let newInput = try? AVCaptureDeviceInput(device: camera),
                  self.session.canAddInput(newInput) else {
                self.session.commitConfiguration()
                DispatchQueue.main.async { self.status = "CAMERA UNAVAILABLE" }
                return
            }
            self.session.addInput(newInput)
            self.input = newInput
            self.device = camera
            if self.session.canAddOutput(self.photoOutput) { self.session.addOutput(self.photoOutput) }
            if self.session.canAddOutput(self.movieOutput) { self.session.addOutput(self.movieOutput) }
            self.session.commitConfiguration()
            self.session.startRunning()
            DispatchQueue.main.async {
                self.status = "READY"
                self.refreshValues()
            }
        }
    }

    private func findCamera(position: AVCaptureDevice.Position, type: AVCaptureDevice.DeviceType) -> AVCaptureDevice? {
        AVCaptureDevice.default(type, for: .video, position: position)
    }

    private func refreshValues() {
        guard let d = device else { return }
        iso = max(d.activeFormat.minISO, min(100, d.activeFormat.maxISO))
        focus = d.lensPosition
    }

    func switchCamera() {
        guard !isRecording else { return }
        replaceCamera(position: isFront ? .back : .front, type: .builtInWideAngleCamera)
        isFront.toggle()
        lens = "1×"
        zoom = 1
    }

    func selectUltraWide(_ ultra: Bool) {
        guard !isFront, !isRecording else { return }
        replaceCamera(position: .back, type: ultra ? .builtInUltraWideCamera : .builtInWideAngleCamera)
        lens = ultra ? "0.5×" : "1×"
        zoom = 1
    }

    private func replaceCamera(position: AVCaptureDevice.Position, type: AVCaptureDevice.DeviceType) {
        queue.async {
            guard let old = self.input,
                  let camera = self.findCamera(position: position, type: type),
                  let newInput = try? AVCaptureDeviceInput(device: camera) else { return }
            self.session.beginConfiguration()
            self.session.removeInput(old)
            if self.session.canAddInput(newInput) {
                self.session.addInput(newInput)
                self.input = newInput
                self.device = camera
            } else {
                self.session.addInput(old)
            }
            self.session.commitConfiguration()
            DispatchQueue.main.async { self.refreshValues() }
        }
    }

    func setZoom(_ value: CGFloat) {
        guard let d = device else { return }
        let target = max(1, min(value, d.activeFormat.videoMaxZoomFactor))
        queue.async {
            do {
                try d.lockForConfiguration()
                d.videoZoomFactor = target
                d.unlockForConfiguration()
                DispatchQueue.main.async { self.zoom = target }
            } catch { }
        }
    }

    func focusAt(_ point: CGPoint) {
        guard let d = device else { return }
        queue.async {
            do {
                try d.lockForConfiguration()
                if d.isFocusPointOfInterestSupported {
                    d.focusPointOfInterest = point
                    if d.isFocusModeSupported(.autoFocus) { d.focusMode = .autoFocus }
                }
                if d.isExposurePointOfInterestSupported {
                    d.exposurePointOfInterest = point
                    if d.isExposureModeSupported(.continuousAutoExposure) { d.exposureMode = .continuousAutoExposure }
                }
                d.unlockForConfiguration()
            } catch { }
        }
    }

    func setFocus(_ value: Float) {
        guard let d = device, d.isLockingFocusWithCustomLensPositionSupported else { return }
        queue.async {
            do {
                try d.lockForConfiguration()
                d.setFocusModeLocked(lensPosition: value, completionHandler: nil)
                d.unlockForConfiguration()
                DispatchQueue.main.async { self.focus = value }
            } catch { }
        }
    }

    func setManualExposure(iso newISO: Float, shutter seconds: Double) {
        guard let d = device else { return }
        let duration = CMTime(seconds: seconds, preferredTimescale: 1_000_000_000)
        let safeISO = max(d.activeFormat.minISO, min(newISO, d.activeFormat.maxISO))
        let safeDuration = CMTimeMaximum(d.activeFormat.minExposureDuration,
            CMTimeMinimum(duration, d.activeFormat.maxExposureDuration))
        queue.async {
            do {
                try d.lockForConfiguration()
                d.setExposureModeCustom(duration: safeDuration, iso: safeISO, completionHandler: nil)
                d.unlockForConfiguration()
                DispatchQueue.main.async {
                    self.iso = safeISO
                    self.shutter = CMTimeGetSeconds(safeDuration)
                    self.manualExposure = true
                }
            } catch { }
        }
    }

    func autoExposure() {
        guard let d = device else { return }
        queue.async {
            do {
                try d.lockForConfiguration()
                if d.isExposureModeSupported(.continuousAutoExposure) { d.exposureMode = .continuousAutoExposure }
                d.unlockForConfiguration()
                DispatchQueue.main.async { self.manualExposure = false }
            } catch { }
        }
    }

    func setMode(photo: Bool) { if !isRecording { isPhotoMode = photo } }

    func setOrientation(_ value: AVCaptureVideoOrientation) {
        orientation = value
        photoOutput.connection(with: .video)?.videoOrientation = value
        movieOutput.connection(with: .video)?.videoOrientation = value
    }

    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        settings.flashMode = flash && photoOutput.supportedFlashModes.contains(.on) ? .on : .off
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    func recordButton() {
        if isRecording {
            movieOutput.stopRecording()
        } else {
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("LUMETRA_\(Int(Date().timeIntervalSince1970)).mov")
            movieOutput.connection(with: .video)?.videoOrientation = orientation
            movieOutput.startRecording(to: url, recordingDelegate: self)
            isRecording = true
            status = "REC"
        }
    }

    func toggleTorch() {
        guard let d = device, d.hasTorch else { return }
        queue.async {
            do {
                try d.lockForConfiguration()
                if d.torchMode == .on {
                    d.torchMode = .off
                    DispatchQueue.main.async { self.torch = false }
                } else {
                    try d.setTorchModeOn(level: 0.7)
                    DispatchQueue.main.async { self.torch = true }
                }
                d.unlockForConfiguration()
            } catch { }
        }
    }

    private func saveVideo(_ url: URL) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else { return }
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            }) { ok, error in
                DispatchQueue.main.async { self.alertMessage = ok ? "Video saved to Photos." : (error?.localizedDescription ?? "Video could not be saved.") }
            }
        }
    }
}

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil, let data = photo.fileDataRepresentation(), let image = UIImage(data: data) else { return }
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else { return }
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }) { ok, _ in
                DispatchQueue.main.async { self.alertMessage = ok ? "Photo saved to Photos." : "Photo could not be saved." }
            }
        }
    }
}

extension CameraManager: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) { }
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL,
                    from connections: [AVCaptureConnection], error: Error?) {
        DispatchQueue.main.async {
            self.isRecording = false
            self.status = error == nil ? "READY" : "RECORDING ERROR"
            if error == nil { self.saveVideo(outputFileURL) }
        }
    }
}
