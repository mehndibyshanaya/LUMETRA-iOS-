import AVFoundation
import SwiftUI

struct CameraPreview: UIViewRepresentable {
    @ObservedObject var camera: CameraManager
    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session = camera.session
        view.previewLayer.videoGravity = .resizeAspectFill
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.tap(_:)))
        view.addGestureRecognizer(tap)
        return view
    }
    func updateUIView(_ view: PreviewView, context: Context) {
        view.previewLayer.session = camera.session
    }
    func makeCoordinator() -> Coordinator { Coordinator(camera: camera) }
    final class Coordinator: NSObject {
        let camera: CameraManager
        init(camera: CameraManager) { self.camera = camera }
        @objc func tap(_ gesture: UITapGestureRecognizer) {
            guard let view = gesture.view as? PreviewView else { return }
            let p = gesture.location(in: view)
            camera.focusAt(view.previewLayer.captureDevicePointConverted(fromLayerPoint: p))
        }
    }
}
final class PreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
}
