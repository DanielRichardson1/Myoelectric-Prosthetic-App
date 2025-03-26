// GraphViewController.swift
import UIKit
import Charts

class GraphViewController: UIViewController {
    // MARK: - Properties
    private let graph1 = GraphView()
    private let graph2 = GraphView()
    private let stackView = UIStackView()
    private let connectionStatusLabel = UILabel()
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNotifications()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Connect to MQTT if not connected
        if !SimpleMQTTClient.shared.connected {
            SimpleMQTTClient.shared.connect()
        }
        
        // Update connection status
        updateConnectionStatus()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Sensor Data"
        
        // Connection Status Label
        connectionStatusLabel.translatesAutoresizingMaskIntoConstraints = false
        connectionStatusLabel.font = UIFont.systemFont(ofSize: 14)
        connectionStatusLabel.textAlignment = .center
        connectionStatusLabel.layer.cornerRadius = 5
        connectionStatusLabel.layer.masksToBounds = true
        connectionStatusLabel.backgroundColor = .systemGray5
        connectionStatusLabel.textColor = .label
        connectionStatusLabel.text = "MQTT: Disconnected"
        view.addSubview(connectionStatusLabel)
        
        // Configure stack view
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add graphs to stack view
        stackView.addArrangedSubview(graph1)
        stackView.addArrangedSubview(graph2)
        
        // Add stack view to main view
        view.addSubview(stackView)
        
        // Set constraints
        NSLayoutConstraint.activate([
            connectionStatusLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            connectionStatusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            connectionStatusLabel.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.8),
            connectionStatusLabel.heightAnchor.constraint(equalToConstant: 28),
            
            stackView.topAnchor.constraint(equalTo: connectionStatusLabel.bottomAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
        
        // Update connection status
        updateConnectionStatus()
    }
    
    // MARK: - Notifications
    private func setupNotifications() {
        // Observe sensor data updates
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSensorDataReceived),
            name: SimpleMQTTClient.sensorDataReceivedNotification,
            object: nil
        )
        
        // Observe connection status changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleConnectionStatusChanged),
            name: SimpleMQTTClient.connectionStatusChangedNotification,
            object: nil
        )
    }
    
    // MARK: - Event Handlers
    @objc private func handleSensorDataReceived(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let value = userInfo["value"] as? Double else { return }
        
        // Update both graphs with new data
        DispatchQueue.main.async {
            self.graph1.addDataPoint(value)
            self.graph2.addDataPoint(value)
        }
    }
    
    @objc private func handleConnectionStatusChanged(_ notification: Notification) {
        DispatchQueue.main.async {
            self.updateConnectionStatus()
        }
    }
    
    private func updateConnectionStatus() {
        let isConnected = SimpleMQTTClient.shared.connected
        
        if isConnected {
            connectionStatusLabel.text = "MQTT: Connected"
            connectionStatusLabel.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.3)
            connectionStatusLabel.textColor = .systemGreen
        } else {
            connectionStatusLabel.text = "MQTT: Disconnected"
            connectionStatusLabel.backgroundColor = UIColor.systemRed.withAlphaComponent(0.3)
            connectionStatusLabel.textColor = .systemRed
        }
    }
}
