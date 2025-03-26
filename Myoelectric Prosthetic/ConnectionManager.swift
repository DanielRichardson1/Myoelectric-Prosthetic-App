//
//  ConnectionManager.swift
//  Myoelectric Prosthetic
//
//  Created by Daniel Richardson on 3/24/25.
//

import UIKit

class ConnectionManager: UIViewController, MQTTClientDelegate {
    private let hostTextField = UITextField()
    private let portTextField = UITextField()
    private let connectButton = UIButton(type: .system)
    private let statusLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        // Set this as the MQTT client delegate
        SimpleMQTTClient.shared.delegate = self
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "MQTT Connection"
        
        // Host TextField
        hostTextField.placeholder = "Host (e.g., 172.20.10.6)"
        hostTextField.borderStyle = .roundedRect
        hostTextField.text = "172.20.10.6"
        hostTextField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hostTextField)
        
        // Port TextField
        portTextField.placeholder = "Port (e.g., 1883)"
        portTextField.borderStyle = .roundedRect
        portTextField.text = "1883"
        portTextField.keyboardType = .numberPad
        portTextField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(portTextField)
        
        // Connect Button
        connectButton.setTitle("Connect", for: .normal)
        connectButton.backgroundColor = .systemBlue
        connectButton.setTitleColor(.white, for: .normal)
        connectButton.layer.cornerRadius = 8
        connectButton.addTarget(self, action: #selector(connectButtonTapped), for: .touchUpInside)
        connectButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(connectButton)
        
        // Status Label
        statusLabel.text = "Not Connected"
        statusLabel.textAlignment = .center
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)
        
        // Set Constraints
        NSLayoutConstraint.activate([
            hostTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            hostTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            hostTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            portTextField.topAnchor.constraint(equalTo: hostTextField.bottomAnchor, constant: 20),
            portTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            portTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            connectButton.topAnchor.constraint(equalTo: portTextField.bottomAnchor, constant: 40),
            connectButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            connectButton.widthAnchor.constraint(equalToConstant: 200),
            connectButton.heightAnchor.constraint(equalToConstant: 50),
            
            statusLabel.topAnchor.constraint(equalTo: connectButton.bottomAnchor, constant: 20),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
        
        // Update UI based on current connection status
        updateConnectionUI()
    }
    
    @objc private func connectButtonTapped() {
        if SimpleMQTTClient.shared.connected {
            // Disconnect
            SimpleMQTTClient.shared.disconnect()
            updateConnectionUI()
        } else {
            // Connect
            guard let host = hostTextField.text, !host.isEmpty else {
                showAlert(message: "Please enter a valid host")
                return
            }
            
            guard let portText = portTextField.text, !portText.isEmpty,
                  let port = Int(portText) else {
                showAlert(message: "Please enter a valid port number")
                return
            }
            
            // Show connecting status
            statusLabel.text = "Connecting..."
            
            // Connect to MQTT broker
            SimpleMQTTClient.shared.connect(host: host, port: port)
        }
    }
    
    private func updateConnectionUI() {
        if SimpleMQTTClient.shared.connected {
            connectButton.setTitle("Disconnect", for: .normal)
            connectButton.backgroundColor = .systemRed
            statusLabel.text = "Connected"
            statusLabel.textColor = .systemGreen
        } else {
            connectButton.setTitle("Connect", for: .normal)
            connectButton.backgroundColor = .systemBlue
            statusLabel.text = "Not Connected"
            statusLabel.textColor = .systemRed
        }
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - MQTTClientDelegate
    func mqttDidConnect() {
        DispatchQueue.main.async {
            self.updateConnectionUI()
        }
    }
    
    func mqttDidDisconnect(error: Error?) {
        DispatchQueue.main.async {
            self.updateConnectionUI()
            if let error = error {
                self.showAlert(message: "Disconnected: \(error.localizedDescription)")
            }
        }
    }
    
    func mqttDidReceiveMessage(_ topic: String, message: String) {
        // Not needed for this view controller
    }
}
