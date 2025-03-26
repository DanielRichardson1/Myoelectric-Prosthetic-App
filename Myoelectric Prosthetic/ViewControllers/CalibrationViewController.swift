// CalibrationViewController.swift
import UIKit

class CalibrationViewController: UIViewController {
    // MARK: - UI Components
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let calibrateButton = UIButton(type: .system)
    private let statusLabel = UILabel()
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        setupNotifications()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateStatusLabel()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - UI Configuration
    private func configureUI() {
        view.backgroundColor = .systemBackground
        title = "Calibration"
        
        // Title Label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Calibration Process"
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .label
        view.addSubview(titleLabel)
        
        // Description Label
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.text = """
        Press 'Calibrate' to start the calibration process.

        You will perform:
        - 20 seconds of rest
        - 10 cycles of: 2 seconds rest, 2 seconds grasping

        This will be done for two grasp types:
        1. Power Sphere
        2. Large Diameter

        Follow the instructions carefully when prompted.
        """
        descriptionLabel.font = UIFont.systemFont(ofSize: 16)
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .left
        descriptionLabel.textColor = .label
        view.addSubview(descriptionLabel)
        
        // Calibrate Button
        calibrateButton.translatesAutoresizingMaskIntoConstraints = false
        calibrateButton.setTitle("Calibrate", for: .normal)
        calibrateButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        calibrateButton.backgroundColor = .systemBlue
        calibrateButton.setTitleColor(.white, for: .normal)
        calibrateButton.layer.cornerRadius = 12
        calibrateButton.addTarget(self, action: #selector(calibrateButtonTapped), for: .touchUpInside)
        view.addSubview(calibrateButton)
        
        // Status Label
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.font = UIFont.systemFont(ofSize: 14)
        statusLabel.textAlignment = .center
        statusLabel.textColor = .secondaryLabel
        view.addSubview(statusLabel)
        
        // Setup Constraints
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
            descriptionLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            
            calibrateButton.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 32),
            calibrateButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            calibrateButton.widthAnchor.constraint(equalToConstant: 200),
            calibrateButton.heightAnchor.constraint(equalToConstant: 50),
            
            statusLabel.topAnchor.constraint(equalTo: calibrateButton.bottomAnchor, constant: 16),
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
            statusLabel.text = "MQTT Status: Connected"
            statusLabel.textColor = .systemGreen
            calibrateButton.isEnabled = true
        } else {
            statusLabel.text = "MQTT Status: Not Connected"
            statusLabel.textColor = .systemRed
            calibrateButton.isEnabled = false
        }
    }
    
    // MARK: - Actions
    @objc private func calibrateButtonTapped() {
        // Safety check for MQTT connection
        guard SimpleMQTTClient.shared.connected else {
            presentAlert(title: "Not Connected", message: "Please connect to the MQTT broker first.")
            return
        }
        
        // Send calibration start command
        SimpleMQTTClient.shared.publish(to: "state", message: "calibration start")
        
        // Present calibration process view controller
        let calibrationProcess = CalibrationProcessViewController()
        calibrationProcess.modalPresentationStyle = .fullScreen
        present(calibrationProcess, animated: true)
    }
    
    private func presentAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// CalibrationProcessViewController.swift
class CalibrationProcessViewController: UIViewController {
    // MARK: - UI Components
    private let instructionLabel = UILabel()
    private let imageView = UIImageView()
    private let timerLabel = UILabel()
    private let repLabel = UILabel()
    private let progressView = UIProgressView()
    private let cancelButton = UIButton(type: .system)
    
    // MARK: - Properties
    private var timer: Timer?
    private var timeLeft = 0
    private var totalTime = 0
    private var repCount = 0
    private var currentStep = 0
    private var currentPrompt = "rest"
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        startCalibrationProcess()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - UI Configuration
    private func configureUI() {
        view.backgroundColor = .systemBackground
        
        // Instruction Label
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        instructionLabel.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        instructionLabel.textAlignment = .center
        instructionLabel.numberOfLines = 0
        instructionLabel.textColor = .label
        view.addSubview(instructionLabel)
        
        // Image View
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 12
        imageView.backgroundColor = .secondarySystemBackground
        view.addSubview(imageView)
        
        // Timer Label
        timerLabel.translatesAutoresizingMaskIntoConstraints = false
        timerLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 24, weight: .bold)
        timerLabel.textAlignment = .center
        timerLabel.textColor = .label
        view.addSubview(timerLabel)
        
        // Progress View
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.progressTintColor = .systemBlue
        progressView.trackTintColor = .systemGray5
        progressView.progress = 0.0
        view.addSubview(progressView)
        
        // Rep Label
        repLabel.translatesAutoresizingMaskIntoConstraints = false
        repLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        repLabel.textAlignment = .center
        repLabel.textColor = .secondaryLabel
        view.addSubview(repLabel)
        
        // Cancel Button
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        cancelButton.backgroundColor = .systemRed
        cancelButton.setTitleColor(.white, for: .normal)
        cancelButton.layer.cornerRadius = 12
        cancelButton.addTarget(self, action: #selector(cancelCalibration), for: .touchUpInside)
        view.addSubview(cancelButton)
        
        // Setup Constraints
        NSLayoutConstraint.activate([
            instructionLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32),
            instructionLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            instructionLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
            
            imageView.topAnchor.constraint(equalTo: instructionLabel.bottomAnchor, constant: 24),
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 240),
            imageView.heightAnchor.constraint(equalToConstant: 240),
            
            timerLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 24),
            timerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            progressView.topAnchor.constraint(equalTo: timerLabel.bottomAnchor, constant: 12),
            progressView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 40),
            progressView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -40),
            progressView.heightAnchor.constraint(equalToConstant: 8),
            
            repLabel.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 16),
            repLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            cancelButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -32),
            cancelButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cancelButton.widthAnchor.constraint(equalToConstant: 180),
            cancelButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    // MARK: - Calibration Process
    private func startCalibrationProcess() {
        // Start with the first step
        currentStep = 0
        timeLeft = CalibrationSequence.sequence[currentStep].duration
        totalTime = timeLeft
        updateStepDisplay()
        
        // Publish initial rest state
        publishTrainingPrompt("rest")
    }
    
    private func updateStepDisplay() {
        let step = CalibrationSequence.sequence[currentStep]
        
        // Update UI
        instructionLabel.text = step.instruction
        
        // Load and set image
        if let image = UIImage(named: step.imageName) {
            imageView.image = image
        } else {
            // Fallback to system image if image not found
            imageView.image = UIImage(systemName: "hand.raised.fill")
        }
        
        // Update timer and progress
        updateTimerDisplay()
        
        // Update rep count if not in the initial rest period
        if currentStep != 0 {
            repLabel.text = "Repetition: \(repCount)/10"
        } else {
            repLabel.text = ""
        }
        
        // Start timer if not already running
        startTimer()
        
        // Publish the current training prompt
        publishTrainingPrompt(step.prompt)
    }
    
    private func startTimer() {
        // Invalidate existing timer if any
        timer?.invalidate()
        
        // Create new timer
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
        
        // Add to RunLoop to ensure it runs in scroll views
        RunLoop.current.add(timer!, forMode: .common)
    }
    
    private func updateTimerDisplay() {
        timerLabel.text = "Time Remaining: \(timeLeft + 1)"
        
        // Update progress bar
        let progress = Float(totalTime - timeLeft) / Float(totalTime)
        progressView.setProgress(progress, animated: true)
    }
    
    private func publishTrainingPrompt(_ prompt: String) {
        if prompt != currentPrompt {
            currentPrompt = prompt
            print("Publishing training prompt: \(prompt)")
            SimpleMQTTClient.shared.publish(to: "training_prompt", message: prompt)
        }
    }
    
    @objc private func updateTimer() {
        timeLeft -= 1
        
        if timeLeft >= 0 {
            updateTimerDisplay()
        } else {
            timer?.invalidate()
            
            // Determine next step based on current state
            moveToNextStep()
        }
    }
    
    private func moveToNextStep() {
        // Handle step transitions based on the Python implementation logic
        if currentStep == 0 {
            // After initial rest period, start first rep
            repCount = 1
            instructionLabel.text = "\(CalibrationSequence.sequence[currentStep].instruction): \(repCount)/10"
            currentStep += 1
        }
        else if currentStep == 1 || currentStep == 4 {
            // Prepare step -> actual grasp step
            currentStep += 1
        }
        else if currentStep == 2 || currentStep == 5 {
            // After grasp step
            if repCount < 10 {
                repCount += 1
                instructionLabel.text = "\(CalibrationSequence.sequence[currentStep].instruction): \(repCount)/10"
                currentStep += 1
            } else {
                // Reset rep count after completing 10 reps
                repCount = 1
                currentStep += 2 // Skip to next grasp type preparation
            }
        }
        else if (currentStep == 3 || currentStep == 6) && repCount <= 10 {
            // After relaxing, go back to the grasp step
            currentStep -= 1
        }
        else {
            // Move to next step
            currentStep += 1
        }
        
        // Check if we've completed all steps
        if currentStep < CalibrationSequence.sequence.count {
            // Set time for next step
            timeLeft = CalibrationSequence.sequence[currentStep].duration
            totalTime = timeLeft
            updateStepDisplay()
        } else {
            // Calibration complete
            completeCalibration()
        }
    }
    
    private func completeCalibration() {
        // Show completion feedback (haptic, animation, etc.)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Publish final rest state
        publishTrainingPrompt("rest")
        SimpleMQTTClient.shared.publish(to: "state", message: "calibration end")
        
        // Show completion alert
        let alert = UIAlertController(
            title: "Calibration Complete",
            message: "The calibration process has been completed successfully.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.dismiss(animated: true)
        })
        
        present(alert, animated: true)
    }
    
    @objc private func cancelCalibration() {
        // Publish cancel message
        SimpleMQTTClient.shared.publish(to: "training_prompt", message: "cancel")
        
        // Stop the timer
        timer?.invalidate()
        timer = nil
        
        // Show confirmation alert
        let alert = UIAlertController(
            title: "Calibration Cancelled",
            message: "The calibration process has been cancelled.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.dismiss(animated: true)
        })
        
        present(alert, animated: true)
    }
}
