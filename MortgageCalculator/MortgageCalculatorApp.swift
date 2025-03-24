import SwiftUI

// Import core Foundation
import Foundation

// Import our module file which re-exports all components
// In a real app, this would be handled by proper module organization
import MortgageCalculator

@main
struct MortgageCalculatorApp: App {
    // Initialize any required app-level services here
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
} 