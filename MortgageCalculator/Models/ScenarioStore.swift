import Foundation
import SwiftUI
import UniformTypeIdentifiers

/// Manages persistent storage of saved scenarios
class ScenarioStore: ObservableObject {
    @Published var savedScenarios: [SavedScenario] = []
    @Published var errorMessage: String = ""
    @Published var showError: Bool = false
    
    private let saveKey = "savedMortgageScenarios"
    
    init() {
        loadScenarios()
    }
    
    /// Load scenarios from UserDefaults
    func loadScenarios() {
        if let data = UserDefaults.standard.data(forKey: saveKey) {
            do {
                self.savedScenarios = try JSONDecoder().decode([SavedScenario].self, from: data)
            } catch {
                self.errorMessage = "Failed to load saved scenarios: \(error.localizedDescription)"
                self.showError = true
                self.savedScenarios = []
            }
        } else {
            // No saved data
            self.savedScenarios = []
        }
    }
    
    /// Save scenarios to UserDefaults
    func saveScenarios() {
        do {
            let encoded = try JSONEncoder().encode(savedScenarios)
            UserDefaults.standard.set(encoded, forKey: saveKey)
        } catch {
            self.errorMessage = "Failed to save scenarios: \(error.localizedDescription)"
            self.showError = true
        }
    }
    
    /// Add a new scenario
    func addScenario(_ scenario: SavedScenario) {
        savedScenarios.append(scenario)
        saveScenarios()
    }
    
    /// Remove scenarios at specified indices
    func removeScenario(at offsets: IndexSet) {
        savedScenarios.remove(atOffsets: offsets)
        saveScenarios()
    }
    
    /// Update an existing scenario
    func updateScenario(_ scenario: SavedScenario) {
        if let index = savedScenarios.firstIndex(where: { $0.id == scenario.id }) {
            savedScenarios[index] = scenario
            saveScenarios()
        }
    }
    
    /// Get data for a scenario (for sharing)
    func scenarioData(for scenario: SavedScenario) -> Data? {
        return try? JSONEncoder().encode(scenario)
    }
    
    /// Save the provided scenario to the store
    func saveScenario(_ scenario: SavedScenario) {
        addScenario(scenario)
    }
}

// Helper for creating share sheet for scenarios
struct ScenarioShareSheet: UIViewControllerRepresentable {
    let scenarioData: Data
    let scenarioName: String
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        // Create a temporary URL to share
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("\(scenarioName).mortgagescenario")
        
        do {
            try scenarioData.write(to: fileURL)
        } catch {
            print("Failed to write scenario file: \(error)")
        }
        
        // Create the activity view controller
        let activityViewController = UIActivityViewController(
            activityItems: [fileURL],
            applicationActivities: nil
        )
        
        // Exclude activities that don't make sense for our file type
        activityViewController.excludedActivityTypes = [
            .assignToContact,
            .saveToCameraRoll,
            .postToFlickr,
            .postToVimeo,
            .postToTencentWeibo,
            .postToTwitter,
            .postToFacebook,
            .print
        ]
        
        return activityViewController
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// Generic share sheet for sharing content
struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
} 