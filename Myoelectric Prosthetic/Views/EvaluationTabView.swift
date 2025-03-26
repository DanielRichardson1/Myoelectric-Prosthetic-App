//
//  EvaluationTabView.swift
//  Myoelectric Prosthetic
//
//  Created by Daniel Richardson on 3/26/25.
//

import SwiftUI

struct EvaluationTabView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        return UINavigationController(rootViewController: EvaluationViewController())
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // No updates needed
    }
}
