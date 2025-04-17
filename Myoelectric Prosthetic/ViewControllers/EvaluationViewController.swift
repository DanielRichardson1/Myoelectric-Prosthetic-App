// EvaluationViewController.swift
import UIKit

class EvaluationViewController: UIViewController {
    // MARK: - Properties
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let evaluateButton = UIButton(type: .system)
    private let statusLabel = UILabel()
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNotifications()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateStatusLabel()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Evaluation"
        
        // Title Label
        titleLabel.text = "Evaluate Model"
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        // Description Label
        descriptionLabel.text = """
        Before evaluating, ensure that you have completed the calibration process.

        During evaluation, you can perform grasping motions at your own pace.

        The machine learning model will classify your grasp type in real time and results will be displayed based on the system's classification.
        """
        descriptionLabel.font = UIFont.systemFont(ofSize: 16)
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .left
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(descriptionLabel)
        
        // Evaluate Button
        evaluateButton.setTitle("Evaluate", for: .normal)
        evaluateButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        evaluateButton.backgroundColor = .systemBlue
        evaluateButton.setTitleColor(.white, for: .normal)
        evaluateButton.layer.cornerRadius = 12
        evaluateButton.addTarget(self, action: #selector(evaluateButtonTapped), for: .touchUpInside)
        evaluateButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(evaluateButton)
        
        // Status Label
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.font = UIFont.systemFont(ofSize: 14)
        statusLabel.textAlignment = .center
        statusLabel.textColor = .secondaryLabel
        view.addSubview(statusLabel)
        
        // Set Constraints
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            descriptionLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            
            evaluateButton.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 32),
            evaluateButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            evaluateButton.widthAnchor.constraint(equalToConstant: 200),
            evaluateButton.heightAnchor.constraint(equalToConstant: 50),
            
            statusLabel.topAnchor.constraint(equalTo: evaluateButton.bottomAnchor, constant: 16),
            statusLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20)
        ])
    }
    
    // MARK: - Notifications
    private func setupNotifications() {
        // Observe connection status changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleConnectionStatusChanged),
            name: SimpleMQTTClient.connectionStatusChangedNotification,
            object: nil
        )
    }
    
    @objc private func handleConnectionStatusChanged(_ notification: Notification) {
        DispatchQueue.main.async {
            self.updateStatusLabel()
        }
    }
    
    private func updateStatusLabel() {
        if SimpleMQTTClient.shared.connected {
            statusLabel.text = "Status: Connected"
            statusLabel.textColor = .systemGreen
            evaluateButton.isEnabled = true
        } else {
            statusLabel.text = "Status: Not Connected"
            statusLabel.textColor = .systemRed
            evaluateButton.isEnabled = false
        }
    }
    
    // MARK: - Actions
    @objc private func evaluateButtonTapped() {
        // Safety check for MQTT connection
        guard SimpleMQTTClient.shared.connected else {
            presentAlert(title: "Not Connected", message: "Please connect to the MQTT broker first.")
            return
        }
        
        // Send evaluation start message over MQTT
        SimpleMQTTClient.shared.publish(to: "state", message: "evaluation start")
        
        // Present evaluation process screen
        let evaluationProcess = EvaluationProcessViewController()
        evaluationProcess.modalPresentationStyle = .fullScreen
        present(evaluationProcess, animated: true)
    }
    
    private func presentAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// EvaluationProcessViewController.swift
class EvaluationProcessViewController: UIViewController {
    // MARK: - Properties
    private let titleLabel = UILabel()
    private let imageView = UIImageView()
    private let classificationLabel = UILabel()
    private let instructionsLabel = UILabel()
    private let statusLabel = UILabel()
    private let closeButton = UIButton(type: .system)
    
    // Dictionary to map classification to image names
    private let imagePaths: [GraspType: String] = [
        .rest: "rest",
        .powerSphere: "power_sphere",
        .largeDiameter: "large_diameter"
    ]
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNotifications()
        startProcess()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Title Label
        titleLabel.text = "Waiting for classification..."
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        // Image View
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        
        // Classification Label
        classificationLabel.text = "Current Classification: None"
        classificationLabel.font = UIFont.systemFont(ofSize: 20)
        classificationLabel.textAlignment = .center
        classificationLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(classificationLabel)
        
        // Instructions Label
        instructionsLabel.text = "Perform different grasp types to see real-time classification"
        instructionsLabel.font = UIFont.systemFont(ofSize: 16)
        instructionsLabel.textAlignment = .center
        instructionsLabel.numberOfLines = 0
        instructionsLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(instructionsLabel)
        
        // Status Label
        statusLabel.text = "System Status: Ready"
        statusLabel.font = UIFont.systemFont(ofSize: 14)
        statusLabel.textAlignment = .center
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)
        
        // Close Button
        closeButton.setTitle("Close Evaluation", for: .normal)
        closeButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        closeButton.backgroundColor = .systemRed
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.layer.cornerRadius = 12
        closeButton.addTarget(self, action: #selector(closeEvaluation), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(closeButton)
        
        // Set Constraints
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            imageView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 200),
            imageView.heightAnchor.constraint(equalToConstant: 200),
            
            classificationLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20),
            classificationLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            classificationLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            instructionsLabel.topAnchor.constraint(equalTo: classificationLabel.bottomAnchor, constant: 20),
            instructionsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            instructionsLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            statusLabel.topAnchor.constraint(equalTo: instructionsLabel.bottomAnchor, constant: 20),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            closeButton.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 40),
            closeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 200),
            closeButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    // MARK: - Notifications
    private func setupNotifications() {
        // Subscribe to classification updates
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleClassificationReceived),
            name: SimpleMQTTClient.classificationReceivedNotification,
            object: nil
        )
    }
    
    // MARK: - Process Management
    private func startProcess() {
        // Update status
        statusLabel.text = "System Status: Evaluating..."
        
        // Publish state
        SimpleMQTTClient.shared.publish(to: "state", message: "evaluating")
        
        // Set default image
        updateDisplay(graspType: .rest)
    }
    
    @objc private func handleClassificationReceived(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let graspType = userInfo["graspType"] as? GraspType else { return }
        
        DispatchQueue.main.async {
            self.updateDisplay(graspType: graspType)
        }
    }
    
    private func updateDisplay(graspType: GraspType) {
        // Update image
        if let imageName = imagePaths[graspType] {
            imageView.image = UIImage(named: imageName)
        }
        
        // Update classification label
        classificationLabel.text = "Current Classification: \(graspType.displayName)"
        
        // Update title based on classification
        switch graspType {
        case .rest:
            titleLabel.text = "Resting Position Detected"
        case .powerSphere:
            titleLabel.text = "Power Sphere Grasp Detected"
        case .largeDiameter:
            titleLabel.text = "Large Diameter Grasp Detected"
        }
    }
    
    @objc private func closeEvaluation() {
        // Publish state change
        SimpleMQTTClient.shared.publish(to: "state", message: "evaluation end")
        
        // Dismiss view controller
        dismiss(animated: true)
    }
}
