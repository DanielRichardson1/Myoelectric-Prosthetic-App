// GraphViewController.swift
import UIKit
import DGCharts

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
        connectionStatusLabel.text = "Status: Disconnected"
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
        
        // Set titles for each graph to indicate what they're displaying
        graph1.setTitle("Voltage Channel 1", isSecondaryGraph: false)
        graph2.setTitle("Voltage Channel 2", isSecondaryGraph: true)
        
        // Initialize graphs with any existing data from SensorDataManager
        let dataManager = SensorDataManager.shared
        
        // Initialize graph1 with voltage0 data
        for dataPoint in dataManager.voltage0Data {
            graph1.addDataPoint(dataPoint.value)
        }
        
        // Initialize graph2 with voltage1 data
        for dataPoint in dataManager.voltage1Data {
            graph2.addDataPoint(dataPoint.value)
        }
        
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
              let voltage0 = userInfo["voltage0"] as? Double,
              let voltage1 = userInfo["voltage1"] as? Double else { return }
        
        // Update graphs with their respective voltage values
        DispatchQueue.main.async {
            self.graph1.addDataPoint(voltage0)
            self.graph2.addDataPoint(voltage1)
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
            connectionStatusLabel.text = "Status: Connected"
            connectionStatusLabel.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.3)
            connectionStatusLabel.textColor = .systemGreen
        } else {
            connectionStatusLabel.text = "Status: Disconnected"
            connectionStatusLabel.backgroundColor = UIColor.systemRed.withAlphaComponent(0.3)
            connectionStatusLabel.textColor = .systemRed
        }
    }
}
