import SwiftUI
import UIKit

struct ContentView: View {
    // State to track MQTT connection status
    @State private var isMQTTConnected = false
    
    var body: some View {
        TabView {
            // First Tab - Graph View
            GraphTabView()
                .tabItem {
                    Label("Graphs", systemImage: "waveform.path")
                }
            
            // Second Tab - Calibration View
            CalibrationTabView()
                .tabItem {
                    Label("Calibrate", systemImage: "slider.horizontal.3")
                }
            
            // Third Tab - Evaluation View
            EvaluationTabView()
                .tabItem {
                    Label("Evaluate", systemImage: "checkmark.circle")
                }
            
            // Fourth Tab - Settings/Connection View
            ConnectionSettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .onAppear {
            // Initialize MQTT settings when app appears
            setupMQTTNotifications()
            
            // Apply UIKit appearance customization
            UITabBar.appearance().backgroundColor = UIColor.systemBackground
        }
    }
    
    // MARK: - MQTT Setup
    private func setupMQTTNotifications() {
        // Set up notification observer for connection status
        NotificationCenter.default.addObserver(
            forName: SimpleMQTTClient.connectionStatusChangedNotification,
            object: nil,
            queue: .main
        ) { notification in
            if let isConnected = notification.userInfo?["isConnected"] as? Bool {
                self.isMQTTConnected = isConnected
            }
        }
        
        // Check current connection status
        self.isMQTTConnected = SimpleMQTTClient.shared.connected
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
