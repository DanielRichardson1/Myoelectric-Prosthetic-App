//
//  MainTabBarController.swift
//  Myoelectric Prosthetic
//
//  Created by Daniel Richardson on 3/24/25.
//

import UIKit

class MainTabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
    }
    
    private func setupTabs() {
        // Create view controllers for each tab
        let graphViewController = GraphViewController()
        let calibrationViewController = CalibrationViewController()
        let evaluationViewController = EvaluationViewController()
        
        // Set tab bar items
        graphViewController.tabBarItem = UITabBarItem(
            title: "Graphs",
            image: UIImage(systemName: "waveform.path"),
            tag: 0
        )
        
        calibrationViewController.tabBarItem = UITabBarItem(
            title: "Calibrate",
            image: UIImage(systemName: "slider.horizontal.3"),
            tag: 1
        )
        
        evaluationViewController.tabBarItem = UITabBarItem(
            title: "Evaluate",
            image: UIImage(systemName: "checkmark.circle"),
            tag: 2
        )
        
        // Embed each view controller in a navigation controller
        let graphNavController = UINavigationController(rootViewController: graphViewController)
        let calibrationNavController = UINavigationController(rootViewController: calibrationViewController)
        let evaluationNavController = UINavigationController(rootViewController: evaluationViewController)
        
        // Set the view controllers for the tab bar controller
        self.viewControllers = [
            graphNavController,
            calibrationNavController,
            evaluationNavController
        ]
        
        // Set the default selected tab
        self.selectedIndex = 0
    }
}
