import SwiftUI

@main
struct LUMETRAApp: App {
    @StateObject private var camera = CameraManager()
    var body: some Scene {
        WindowGroup {
            CameraView().environmentObject(camera).preferredColorScheme(.dark)
        }
    }
}
