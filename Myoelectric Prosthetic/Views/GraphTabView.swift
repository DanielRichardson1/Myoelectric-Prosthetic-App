//
//  GraphTabView.swift
//  Myoelectric Prosthetic
//
//  Created by Daniel Richardson on 3/26/25.
//

import SwiftUI

struct GraphTabView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        return UINavigationController(rootViewController: GraphViewController())
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // No updates needed
    }
}
