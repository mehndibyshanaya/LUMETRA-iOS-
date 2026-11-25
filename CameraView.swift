import AVFoundation
import SwiftUI

struct CameraView: View {
    @EnvironmentObject private var camera: CameraManager
    @State private var showManual = false
    @State private var orientationLocked = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()
                if camera.permissionGranted {
                    CameraPreview(camera: camera).ignoresSafeArea()
                    controls
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "camera.fill").font(.system(size: 42))
                        Text("LUMETRA").font(.system(size: 25, weight: .bold, design: .rounded)).tracking(3)
                        Text(camera.permissionMessage ?? "Camera access is needed.")
                            .multilineTextAlignment(.center).foregroundColor(.white.opacity(0.65))
                        Button("TRY AGAIN") { camera.requestPermission() }
                    }.padding(30)
                }
            }
            .onAppear { camera.setOrientation(geo.size.width > geo.size.height ? .landscapeRight : .portrait) }
            .onChange(of: geo.size) { size in
                if !orientationLocked {
                    camera.setOrientation(size.width > size.height ? .landscapeRight : .portrait)
                }
            }
        }
        .statusBarHidden(true)
        .alert(camera.alertMessage ?? "", isPresented: Binding(
            get: { camera.alertMessage != nil },
            set: { if !$0 { camera.alertMessage = nil } }
        )) { Button("OK") { camera.alertMessage = nil } }
    }

    private var controls: some View {
        VStack {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("LUMETRA").font(.system(size: 18, weight: .bold, design: .rounded)).tracking(2)
                    Text(camera.status).font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(camera.isRecording ? .red : .white.opacity(0.7))
                }
                Spacer()
                Button { camera.flash.toggle() } label: {
                    Image(systemName: camera.flash ? "bolt.fill" : "bolt.slash")
                }
                Button { camera.toggleTorch() } label: {
                    Image(systemName: camera.torch ? "flashlight.on.fill" : "flashlight.off.fill")
                }
                Button { camera.switchCamera() } label: { Image(systemName: "camera.rotate") }
            }
            .font(.system(size: 18)).foregroundColor(.white)
            .padding(.horizontal, 20).padding(.top, 12)

            Spacer()

            HStack {
                Image(systemName: "viewfinder")
                Text("TAP TO FOCUS").font(.system(size: 10, weight: .semibold, design: .monospaced)).tracking(1)
                Spacer()
                Text(camera.isFront ? "FRONT" : "REAR").font(.system(size: 9, weight: .medium, design: .monospaced))
            }
            .foregroundColor(.white.opacity(0.85))
            .padding(10).background(.black.opacity(0.4), in: Capsule())

            Spacer()

            HStack(spacing: 18) {
                lensButton("0.5×") { camera.selectUltraWide(true) }.disabled(camera.isFront)
                lensButton("1×") { camera.selectUltraWide(false) }
                lensButton("2×") { camera.setZoom(2) }
            }.padding(.bottom, 18)

            VStack(spacing: 16) {
                HStack(spacing: 22) {
                    Button("PHOTO") { camera.setMode(photo: true) }
                        .foregroundColor(camera.isPhotoMode ? .white : .white.opacity(0.45))
                    Button("VIDEO") { camera.setMode(photo: false) }
                        .foregroundColor(!camera.isPhotoMode ? .white : .white.opacity(0.45))
                }.font(.system(size: 11, weight: .bold, design: .monospaced)).tracking(1.5)

                HStack {
                    Button { showManual = true } label: {
                        VStack(spacing: 5) {
                            Image(systemName: "slider.horizontal.3").font(.system(size: 21))
                            Text("PRO").font(.system(size: 8, weight: .bold, design: .monospaced))
                        }.frame(width: 65, height: 64)
                    }
                    Spacer()
                    Button { camera.isPhotoMode ? camera.capturePhoto() : camera.recordButton() } label: {
                        ZStack {
                            Circle().stroke(.white, lineWidth: 4).frame(width: 76, height: 76)
                            if camera.isPhotoMode {
                                Circle().fill(.white).frame(width: 62, height: 62)
                            } else {
                                RoundedRectangle(cornerRadius: camera.isRecording ? 7 : 30)
                                    .fill(.red).frame(width: camera.isRecording ? 27 : 58,
                                                     height: camera.isRecording ? 27 : 58)
                            }
                        }
                    }
                    Spacer()
                    Button { orientationLocked.toggle() } label: {
                        VStack(spacing: 5) {
                            Image(systemName: orientationLocked ? "lock.rotation" : "rotate.3d")
                                .font(.system(size: 21))
                            Text("LOCK").font(.system(size: 8, weight: .bold, design: .monospaced))
                        }.frame(width: 65, height: 64)
                    }
                }.foregroundColor(.white)
            }
            .padding(.horizontal, 10).padding(.top, 12).padding(.bottom, 18)
            .background(LinearGradient(colors: [.clear, .black.opacity(0.8)], startPoint: .top, endPoint: .bottom))
        }
        .sheet(isPresented: $showManual) { ManualPanel().environmentObject(camera).presentationDetents([.medium, .large]) }
    }

    private func lensButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(camera.lens == title ? .black : .white)
                .frame(width: 48, height: 38)
                .background(camera.lens == title ? .white : .black.opacity(0.45), in: Capsule())
        }
    }
}

struct ManualPanel: View {
    @EnvironmentObject private var camera: CameraManager
    @State private var iso: Double = 100
    @State private var shutter: Double = 1.0 / 60.0
    @State private var focus: Double = 0.5
    private let shutters: [(String, Double)] = [
        ("1/30", 1.0/30.0), ("1/48", 1.0/48.0), ("1/50", 1.0/50.0),
        ("1/60", 1.0/60.0), ("1/100", 1.0/100.0), ("1/120", 1.0/120.0)
    ]
    var body: some View {
        NavigationStack {
            Form {
                Section("EXPOSURE") {
                    HStack {
                        Text("ISO").frame(width: 45, alignment: .leading)
                        Slider(value: $iso, in: 25...1600, step: 1)
                        Text("\(Int(iso))").monospacedDigit().frame(width: 45)
                    }
                    Picker("SHUTTER", selection: $shutter) {
                        ForEach(shutters, id: \.1) { item in Text(item.0).tag(item.1) }
                    }
                    Button("APPLY MANUAL EXPOSURE") {
                        camera.setManualExposure(iso: Float(iso), shutter: shutter)
                    }
                    Button("RETURN TO AUTO EXPOSURE") { camera.autoExposure() }
                }
                Section("FOCUS") {
                    HStack {
                        Text("NEAR").font(.caption2)
                        Slider(value: $focus, in: 0...1).onChange(of: focus) { camera.setFocus(Float($0)) }
                        Text("FAR").font(.caption2)
                    }
                }
                Section {
                    Text("Tap the viewfinder for autofocus. Manual ranges depend on the active camera.")
                        .font(.footnote).foregroundColor(.secondary)
                }
            }
            .navigationTitle("PRO CONTROLS")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                iso = Double(camera.iso)
                shutter = camera.shutter
                focus = Double(camera.focus)
            }
        }
    }
}
