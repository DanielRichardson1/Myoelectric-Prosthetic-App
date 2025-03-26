import SwiftUI
import MQTTNIO

@main
struct MyoelectricProstheticApp: App {
    // Initialize app components
    init() {
        _ = SimpleMQTTClient.shared
        setupAppearance()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
    private func setupAppearance() {
        UINavigationBar.appearance().tintColor = .systemBlue
    }
}
