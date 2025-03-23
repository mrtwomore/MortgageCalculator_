import Foundation
import SwiftUI

class ScenarioStore: ObservableObject {
    @Published var scenarios: [MortgageScenario] = []
    @Published var currentScenario: MortgageScenario
    
    private static let storeKey = "savedMortgageScenarios"
    
    init() {
        // Load saved scenarios
        if let savedScenarios = Self.loadScenarios() {
            scenarios = savedScenarios
            // Use the first one as current or create a default one
            currentScenario = scenarios.first ?? Self.createDefaultScenario()
        } else {
            // Create a default scenario if no saved scenarios exist
            currentScenario = Self.createDefaultScenario()
            scenarios = [currentScenario]
            saveScenarios()
        }
    }
    
    static func createDefaultScenario() -> MortgageScenario {
        return MortgageScenario(
            name: "Default Scenario",
            loanAmount: 300000,
            interestRate: 5.0,
            loanTermYears: 30,
            loanType: LoanType.fixed.rawValue,
            paymentFrequency: PaymentFrequency.monthly.rawValue
        )
    }
    
    func addScenario(_ scenario: MortgageScenario) {
        scenarios.append(scenario)
        saveScenarios()
    }
    
    func updateScenario(_ scenario: MortgageScenario) {
        if let index = scenarios.firstIndex(where: { $0.id == scenario.id }) {
            scenarios[index] = scenario
            saveScenarios()
        }
    }
    
    func deleteScenario(_ scenario: MortgageScenario) {
        scenarios.removeAll { $0.id == scenario.id }
        saveScenarios()
    }
    
    func duplicateScenario(_ scenario: MortgageScenario) -> MortgageScenario {
        var copy = scenario
        copy.id = UUID()
        copy.name = "\(scenario.name) (Copy)"
        scenarios.append(copy)
        saveScenarios()
        return copy
    }
    
    func saveScenarios() {
        if let encoded = try? JSONEncoder().encode(scenarios) {
            UserDefaults.standard.set(encoded, forKey: Self.storeKey)
        }
    }
    
    static func loadScenarios() -> [MortgageScenario]? {
        if let data = UserDefaults.standard.data(forKey: storeKey),
           let decoded = try? JSONDecoder().decode([MortgageScenario].self, from: data) {
            return decoded
        }
        return nil
    }
} 