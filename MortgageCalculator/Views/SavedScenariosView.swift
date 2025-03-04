import SwiftUI

struct SavedScenariosView: View {
    @EnvironmentObject private var scenarioStore: ScenarioStore
    @State private var scenarioToShare: SavedScenario?
    @State private var showingShareSheet = false
    var onSelectScenario: (SavedScenario) -> Void
    
    var body: some View {
        NavigationView {
            List {
                if scenarioStore.savedScenarios.isEmpty {
                    Text("No saved scenarios yet")
                        .foregroundColor(.gray)
                        .italic()
                        .padding()
                } else {
                    ForEach(scenarioStore.savedScenarios) { scenario in
                        ScenarioCell(
                            scenario: scenario,
                            onTap: { onSelectScenario(scenario) },
                            onShare: {
                                scenarioToShare = scenario
                                showingShareSheet = true
                            },
                            onDelete: {
                                if let index = scenarioStore.savedScenarios.firstIndex(where: { $0.id == scenario.id }) {
                                    scenarioStore.removeScenario(at: IndexSet(integer: index))
                                }
                            }
                        )
                    }
                    .onDelete { indexSet in
                        scenarioStore.removeScenario(at: indexSet)
                    }
                }
            }
            .navigationTitle("Saved Scenarios")
            .toolbar {
                EditButton()
            }
            .sheet(isPresented: $showingShareSheet) {
                if let scenario = scenarioToShare, let data = scenarioStore.scenarioData(for: scenario) {
                    ScenarioShareSheet(scenarioData: data, scenarioName: scenario.name)
                }
            }
            .alert("Error", isPresented: $scenarioStore.showError) {
                Button("OK", role: .cancel) {
                    scenarioStore.showError = false
                }
            } message: {
                Text(scenarioStore.errorMessage)
            }
        }
    }
}

struct ScenarioCell: View {
    let scenario: SavedScenario
    let onTap: () -> Void
    let onShare: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(scenario.name)
                .font(.headline)
            
            HStack {
                Text("Loan: $\(String(format: "%.0f", scenario.loanAmount))")
                Spacer()
                Text("Rate: \(String(format: "%.2f", scenario.interestRate))%")
            }
            .font(.subheadline)
            
            HStack {
                Text("Term: \(String(format: "%.1f", scenario.loanTerm)) years")
                Spacer()
                Text("Frequency: \(scenario.paymentFrequency)")
            }
            .font(.subheadline)
            
            if scenario.additionalPayment > 0 {
                HStack {
                    Text("Additional Payment: $\(String(format: "%.0f", scenario.additionalPayment))")
                        .font(.subheadline)
                        .foregroundColor(.green)
                    Spacer()
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .contextMenu {
            Button {
                onShare()
            } label: {
                Label("Share with Partner", systemImage: "square.and.arrow.up")
            }
            
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

struct SavedScenariosView_Previews: PreviewProvider {
    static var scenarioStore: ScenarioStore = {
        let store = ScenarioStore()
        store.savedScenarios = [
            SavedScenario(
                name: "Home Purchase",
                loanAmount: 525000,
                interestRate: 5.05,
                loanTerm: 30,
                paymentFrequency: "Monthly",
                additionalPayment: 0,
                createdDate: Date()
            ),
            SavedScenario(
                name: "Refinance Option",
                loanAmount: 475000,
                interestRate: 4.5,
                loanTerm: 25,
                paymentFrequency: "Monthly",
                additionalPayment: 250,
                createdDate: Date()
            )
        ]
        return store
    }()
    
    static var previews: some View {
        SavedScenariosView(onSelectScenario: { _ in })
            .environmentObject(scenarioStore)
    }
} 