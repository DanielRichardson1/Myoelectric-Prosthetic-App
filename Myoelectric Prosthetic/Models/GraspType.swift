//
//  GraspType.swift
//  Myoelectric Prosthetic
//
//  Created by Daniel Richardson on 3/24/25.
//

import Foundation

enum GraspType: String, CaseIterable {
    case rest = "rest"
    case powerSphere = "power sphere"
    case largeDiameter = "large diameter"
    
    var displayName: String {
        switch self {
        case .rest:
            return "Rest"
        case .powerSphere:
            return "Power Sphere Grasp"
        case .largeDiameter:
            return "Large Diameter Grasp"
        }
    }
    
    var imageName: String {
        switch self {
        case .rest:
            return "rest"
        case .powerSphere:
            return "power_sphere"
        case .largeDiameter:
            return "large_diameter"
        }
    }
    
    // Helper method to convert numeric values (from Python code)
    static func from(numericValue: String) -> GraspType? {
        switch numericValue {
        case "0":
            return .rest
        case "1":
            return .powerSphere
        case "2":
            return .largeDiameter
        default:
            return nil
        }
    }
}

// AppState.swift
import Foundation

enum AppState: String {
    case idle = "idle"
    case calibrationStart = "calibration start"
    case calibrationEnd = "calibration end"
    case evaluationStart = "evaluation start"
    case evaluating = "evaluating"
    case evaluationComplete = "evaluation_complete"
    case evaluationEnd = "evaluation end"
}

// CalibrationStep.swift
import Foundation

struct CalibrationStep {
    let instruction: String
    let imageName: String
    let duration: Int
    let prompt: String
}

// CalibrationSequence.swift
import Foundation

class CalibrationSequence {
    // Replicates the steps from the Python code
    static let sequence: [CalibrationStep] = [
        // Initial rest period
        CalibrationStep(instruction: "Rest for 20 seconds", imageName: "rest", duration: 19, prompt: "rest"),
        
        // Power Sphere sequence
        CalibrationStep(instruction: "Prepare for Power Sphere Grasp", imageName: "rest", duration: 2, prompt: "rest"),
        CalibrationStep(instruction: "Power Sphere Grasp", imageName: "power_sphere", duration: 2, prompt: "power sphere"),
        CalibrationStep(instruction: "Relax your hand", imageName: "rest", duration: 2, prompt: "rest"),
        
        // Large Diameter sequence
        CalibrationStep(instruction: "Prepare for Large Diameter Grasp", imageName: "rest", duration: 2, prompt: "rest"),
        CalibrationStep(instruction: "Large Diameter Grasp", imageName: "large_diameter", duration: 2, prompt: "large diameter"),
        CalibrationStep(instruction: "Relax your hand", imageName: "rest", duration: 2, prompt: "rest"),
    ]
}

// SensorDataPoint.swift
import Foundation

struct SensorDataPoint {
    let timestamp: Date
    let value: Double
}

// SensorDataManager.swift
class SensorDataManager {
    static let shared = SensorDataManager()
    
    // Maximum number of data points to keep for the graphs
    private let maxDataPoints = 100
    
    // Data arrays for the two voltage channels
    private(set) var voltage0Data: [SensorDataPoint] = []
    private(set) var voltage1Data: [SensorDataPoint] = []
    
    // Notification name for when data is updated
    static let dataUpdatedNotification = Notification.Name("sensorDataUpdated")
    
    // Add data points for both voltage channels
    func addDataPoints(voltage0: Double, voltage1: Double) {
        let timestamp = Date()
        let point0 = SensorDataPoint(timestamp: timestamp, value: voltage0)
        let point1 = SensorDataPoint(timestamp: timestamp, value: voltage1)
        
        // Update voltage0 data
        if voltage0Data.count >= maxDataPoints {
            voltage0Data.removeFirst()
        }
        voltage0Data.append(point0)
        
        // Update voltage1 data
        if voltage1Data.count >= maxDataPoints {
            voltage1Data.removeFirst()
        }
        voltage1Data.append(point1)
        
        // Notify observers that data has been updated
        NotificationCenter.default.post(name: SensorDataManager.dataUpdatedNotification, object: nil)
    }
    
    func clearData() {
        voltage0Data.removeAll()
        voltage1Data.removeAll()
        NotificationCenter.default.post(name: SensorDataManager.dataUpdatedNotification, object: nil)
    }
}
