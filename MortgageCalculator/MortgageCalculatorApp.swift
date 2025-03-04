import SwiftUI

// This is the main entry point for the application
@main
struct MortgageCalculatorApp: App {
    // Initialize the scenario store here (or later)
    // @StateObject private var scenarioStore = ScenarioStore()
    
    var body: some Scene {
        WindowGroup {
            // Start with a placeholder until we can fix import issues
            Text("Mortgage Calculator App")
                // We'll add .environmentObject(scenarioStore) once fixed
        }
    }
} 