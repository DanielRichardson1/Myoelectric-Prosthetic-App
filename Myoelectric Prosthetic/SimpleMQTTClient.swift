// SimpleMQTTClient.swift
import Foundation
import MQTTNIO
import NIO

// MQTT Client delegate protocol
protocol MQTTClientDelegate: AnyObject {
    func mqttDidConnect()
    func mqttDidDisconnect(error: Error?)
    func mqttDidReceiveMessage(_ topic: String, message: String)
}

class SimpleMQTTClient {
    // Singleton instance
    static let shared = SimpleMQTTClient()
    
    // MQTT client
    private var client: MQTTClient?
    
    // Connection state
    private(set) var isConnected = false
    
    // Default connection settings
    private var host = "172.20.10.6"
    private var port = 1883
    private var clientID = "ios_app_\(UUID().uuidString)"
    
    // Topic strings
    static let topicSensor = "sensor"
    static let topicClassOutput = "class_output"
    static let topicState = "state"
    static let topicTrainingPrompt = "training_prompt"
    
    // Delegate to notify about MQTT events
    weak var delegate: MQTTClientDelegate?
    
    // Notifications
    static let sensorDataReceivedNotification = Notification.Name("sensorDataReceived")
    static let classificationReceivedNotification = Notification.Name("classificationReceived")
    static let connectionStatusChangedNotification = Notification.Name("MQTTConnectionStatusChanged")
    
    // Private initializer for singleton
    private init() {}
    
    // Connect to MQTT broker
    func connect(host: String? = nil, port: Int? = nil) {
        // Update connection parameters if provided
        if let host = host {
            self.host = host
        }
        
        if let port = port {
            self.port = port
        }
        
        // Create MQTT configuration with correct parameters for MQTTNIO
        let configuration = MQTTConfiguration(
            target: .host(self.host, port: self.port),
            clientId: clientID,
            clean: true,
            keepAliveInterval: .seconds(60)
        )
        
        // Create the MQTT client with message handling
        client = MQTTClient(
            configuration: configuration,
            eventLoopGroupProvider: .createNew
        )
        
        // Set up publish handler directly
        client?.whenMessage { [weak self] message in
            guard let self = self else { return }
            
            let topic = message.topic
            guard let payload = message.payload.string else {
                return
            }
            
            print("Received message on topic \(topic): \(payload)")
            
            // Process message based on topic
            self.processMessage(topic: topic, payload: payload)
            
            // Notify delegate
            self.delegate?.mqttDidReceiveMessage(topic, message: payload)
        }
        
        // Connect to the MQTT broker
        client?.connect().whenComplete { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success:
                print("Connected to MQTT broker")
                self.isConnected = true
                
                // Subscribe to topics
                self.subscribeToTopics()
                
                // Notify delegate
                self.delegate?.mqttDidConnect()
                
                // Post notification
                NotificationCenter.default.post(
                    name: SimpleMQTTClient.connectionStatusChangedNotification,
                    object: nil,
                    userInfo: ["isConnected": true]
                )
                
            case .failure(let error):
                print("Failed to connect to MQTT broker: \(error)")
                self.isConnected = false
                
                // Notify delegate
                self.delegate?.mqttDidDisconnect(error: error)
                
                // Post notification
                NotificationCenter.default.post(
                    name: SimpleMQTTClient.connectionStatusChangedNotification,
                    object: nil,
                    userInfo: ["isConnected": false]
                )
            }
        }
    }
    
    // Subscribe to required topics
    private func subscribeToTopics() {
        subscribe(to: SimpleMQTTClient.topicSensor)
        subscribe(to: SimpleMQTTClient.topicClassOutput)
        subscribe(to: SimpleMQTTClient.topicState)
    }
    
    // Disconnect from MQTT broker
    func disconnect() {
        client?.disconnect().whenComplete { [weak self] result in
            guard let self = self else { return }
            
            self.isConnected = false
            print("Disconnected from MQTT broker")
            
            // Notify delegate
            self.delegate?.mqttDidDisconnect(error: nil)
            
            // Post notification
            NotificationCenter.default.post(
                name: SimpleMQTTClient.connectionStatusChangedNotification,
                object: nil,
                userInfo: ["isConnected": false]
            )
        }
    }
    
    // Subscribe to a topic
    func subscribe(to topic: String) {
        // Try different subscription methods depending on the MQTTNIO version
        client?.subscribe(
            to: topic,
            qos: .atMostOnce
        ).whenComplete { result in
            switch result {
            case .success:
                print("Subscribed to topic: \(topic)")
            case .failure(let error):
                print("Failed to subscribe to topic \(topic): \(error)")
            }
        }
    }
    
    // Publish a message to a topic
    func publish(to topic: String, message: String) {
        client?.publish(
            message,
            to: topic,
            qos: .atMostOnce
        ).whenComplete { result in
            switch result {
            case .success:
                print("Published message to topic \(topic)")
            case .failure(let error):
                print("Failed to publish message to topic \(topic): \(error)")
            }
        }
    }
    
    // Process incoming messages
    private func processMessage(topic: String, payload: String) {
        switch topic {
        case SimpleMQTTClient.topicSensor:
            handleSensorData(payload)
            
        case SimpleMQTTClient.topicClassOutput:
            handleClassification(payload)
            
        default:
            break
        }
    }
    
    // Handle received sensor data
    private func handleSensorData(_ message: String) {
        guard let value = Double(message) else { return }
        
        // Add the value to sensor data manager
        SensorDataManager.shared.addDataPoint(value: value)
        
        // Post notification
        NotificationCenter.default.post(
            name: SimpleMQTTClient.sensorDataReceivedNotification,
            object: nil,
            userInfo: ["value": value]
        )
    }
    
    // Handle received classification data
    private func handleClassification(_ message: String) {
        let normalizedMessage = message.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Determine grasp type from message
        var graspType: GraspType
        
        if let numericGraspType = GraspType.from(numericValue: normalizedMessage) {
            graspType = numericGraspType
        } else if let parsedType = GraspType(rawValue: normalizedMessage) {
            graspType = parsedType
        } else {
            // Default to rest if unable to parse
            graspType = .rest
        }
        
        // Post notification
        NotificationCenter.default.post(
            name: SimpleMQTTClient.classificationReceivedNotification,
            object: nil,
            userInfo: ["graspType": graspType]
        )
    }
    
    // Check if connected
    var connected: Bool {
        return isConnected
    }
}
