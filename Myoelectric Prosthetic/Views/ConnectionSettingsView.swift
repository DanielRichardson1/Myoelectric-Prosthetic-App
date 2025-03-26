//
//  ConnectionSettingsView.swift
//  Myoelectric Prosthetic
//
//  Created by Daniel Richardson on 3/26/25.
//

import SwiftUI

struct ConnectionSettingsView: View {
    @State private var host = "172.20.10.6"
    @State private var port = "1883"
    @State private var isConnected = false
    @State private var statusMessage = "Not Connected"
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("MQTT Connection Settings")) {
                    TextField("Host", text: $host)
                    TextField("Port", text: $port)
                        .keyboardType(.numberPad)
                }
                
                Section {
                    Button(isConnected ? "Disconnect" : "Connect") {
                        toggleConnection()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isConnected ? Color.red : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                Section(header: Text("Status")) {
                    Text(statusMessage)
                        .foregroundColor(isConnected ? .green : .red)
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                // Update connection status when view appears
                isConnected = SimpleMQTTClient.shared.connected
                updateStatusMessage()
                
                // Setup observation for connection status changes
                NotificationCenter.default.addObserver(
                    forName: SimpleMQTTClient.connectionStatusChangedNotification,
                    object: nil,
                    queue: .main
                ) { notification in
                    if let newConnected = notification.userInfo?["isConnected"] as? Bool {
                        self.isConnected = newConnected
                        self.updateStatusMessage()
                    }
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Connection Status"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private func toggleConnection() {
        if isConnected {
            // Disconnect
            SimpleMQTTClient.shared.disconnect()
            showConnectionAlert(success: true, message: "Disconnecting...")
        } else {
            // Connect
            guard let portNumber = Int(port) else {
                showConnectionAlert(success: false, message: "Invalid port number")
                return
            }
            
            SimpleMQTTClient.shared.connect(host: host, port: portNumber)
            showConnectionAlert(success: true, message: "Connecting...")
        }
    }
    
    private func updateStatusMessage() {
        statusMessage = isConnected ? "Connected to \(host):\(port)" : "Not Connected"
    }
    
    private func showConnectionAlert(success: Bool, message: String) {
        alertMessage = message
        showAlert = true
    }
}
