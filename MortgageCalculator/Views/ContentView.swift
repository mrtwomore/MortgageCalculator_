import SwiftUI

struct ContentView: View {
    @State private var loanAmount: String = "525000"
    @State private var interestRate: String = "5.05"
    @State private var loanTerm: String = "27.5"
    @State private var paymentFrequency: String = "Monthly"
    @State private var additionalPayment: String = "0"
    @State private var showAmortizationSchedule = false
    @State private var showComparisonView = false
    @State private var showSavedScenarios = false
    @State private var showingScenarioSaveSheet = false
    @State private var newScenarioName = ""
    @State private var showInputError = false
    @State private var inputErrorMessage = ""
    @State private var calculationResult: CalculationResult?
    
    @EnvironmentObject private var scenarioStore: ScenarioStore
    
    var frequencies = ["Weekly", "Fortnightly", "Monthly"]
    
    // Validate input fields
    private func validateInputs() -> Bool {
        // Check loan amount
        guard let loanAmountValue = Double(loanAmount), loanAmountValue > 0 else {
            inputErrorMessage = "Please enter a valid loan amount greater than 0"
            showInputError = true
            return false
        }
        
        // Check interest rate
        guard let interestRateValue = Double(interestRate), interestRateValue > 0 else {
            inputErrorMessage = "Please enter a valid interest rate greater than 0"
            showInputError = true
            return false
        }
        
        // Check loan term
        guard let loanTermValue = Double(loanTerm), loanTermValue > 0 else {
            inputErrorMessage = "Please enter a valid loan term greater than 0"
            showInputError = true
            return false
        }
        
        // Check additional payment (can be 0 or greater)
        guard let additionalPaymentValue = Double(additionalPayment), additionalPaymentValue >= 0 else {
            inputErrorMessage = "Please enter a valid additional payment (0 or greater)"
            showInputError = true
            return false
        }
        
        return true
    }
    
    // Calculate results when values change
    private func calculateResults() {
        guard validateInputs() else { return }
        
        guard let loanAmountValue = Double(loanAmount),
              let interestRateValue = Double(interestRate),
              let loanTermValue = Double(loanTerm),
              let additionalPaymentValue = Double(additionalPayment) else {
            calculationResult = nil
            return
        }
        
        // Use the calculator service to perform calculations
        calculationResult = MortgageCalculatorService.shared.calculateMortgage(
            loanAmount: loanAmountValue,
            interestRate: interestRateValue,
            loanTerm: loanTermValue,
            frequency: paymentFrequency,
            additionalPayment: additionalPaymentValue
        )
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Loan Details")) {
                    TextField("Loan Amount ($)", text: $loanAmount)
                        .keyboardType(.decimalPad)
                        .onChange(of: loanAmount) { _ in calculateResults() }
                    
                    TextField("Interest Rate (%)", text: $interestRate)
                        .keyboardType(.decimalPad)
                        .onChange(of: interestRate) { _ in calculateResults() }
                    
                    TextField("Loan Term (years)", text: $loanTerm)
                        .keyboardType(.decimalPad)
                        .onChange(of: loanTerm) { _ in calculateResults() }
                    
                    Picker("Payment Frequency", selection: $paymentFrequency) {
                        ForEach(frequencies, id: \.self) {
                            Text($0)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: paymentFrequency) { _ in calculateResults() }
                }
                
                Section(header: Text("Additional Payments")) {
                    TextField("Additional Payment (per period)", text: $additionalPayment)
                        .keyboardType(.decimalPad)
                        .onChange(of: additionalPayment) { _ in calculateResults() }
                }
                
                if let result = calculationResult {
                    PaymentSummaryView(result: result)
                    
                    if let additionalPaymentScenario = result.additionalPaymentScenario {
                        AdditionalPaymentSummaryView(scenario: additionalPaymentScenario)
                    }
                } else {
                    Section {
                        Text("Please enter valid numbers")
                            .foregroundColor(.red)
                    }
                }
                
                Section {
                    ActionButtonsView(
                        validateInputs: validateInputs,
                        showAmortizationSchedule: $showAmortizationSchedule,
                        showComparisonView: $showComparisonView,
                        showingScenarioSaveSheet: $showingScenarioSaveSheet,
                        showSavedScenarios: $showSavedScenarios
                    )
                }
            }
            .navigationTitle("Mortgage Calculator")
            .onAppear {
                // Calculate initial results
                calculateResults()
            }
            .alert(inputErrorMessage, isPresented: $showInputError) {
                Button("OK", role: .cancel) {}
            }
            .sheet(isPresented: $showAmortizationSchedule) {
                if let result = calculationResult {
                    AmortizationScheduleView(
                        amortizationSchedule: result.amortizationSchedule,
                        loanAmount: Double(loanAmount) ?? 0,
                        interestRate: Double(interestRate) ?? 0,
                        loanTerm: Double(loanTerm) ?? 0,
                        frequency: paymentFrequency
                    )
                } else {
                    Text("Invalid input values")
                }
            }
            .sheet(isPresented: $showComparisonView) {
                if let result = calculationResult {
                    ComparisonView(scenarios: result.comparisonScenarios)
                } else {
                    Text("Invalid input values")
                }
            }
            .sheet(isPresented: $showSavedScenarios) {
                SavedScenariosView(
                    onSelectScenario: { scenario in
                        loadScenario(scenario)
                        showSavedScenarios = false
                    }
                )
            }
            .alert("Save Scenario", isPresented: $showingScenarioSaveSheet) {
                TextField("Scenario Name", text: $newScenarioName)
                
                Button("Cancel", role: .cancel) {
                    newScenarioName = ""
                }
                
                Button("Save") {
                    saveCurrentScenario()
                    newScenarioName = ""
                }
            } message: {
                Text("Enter a name to identify this mortgage scenario")
            }
        }
    }
    
    // Save current scenario to the store
    private func saveCurrentScenario() {
        guard let loanAmountValue = Double(loanAmount),
              let interestRateValue = Double(interestRate),
              let loanTermValue = Double(loanTerm),
              let additionalPaymentValue = Double(additionalPayment),
              !newScenarioName.isEmpty else {
            return
        }
        
        let scenario = SavedScenario(
            name: newScenarioName,
            loanAmount: loanAmountValue,
            interestRate: interestRateValue,
            loanTerm: loanTermValue,
            paymentFrequency: paymentFrequency,
            additionalPayment: additionalPaymentValue,
            createdDate: Date()
        )
        
        scenarioStore.saveScenario(scenario)
    }
    
    // Load a saved scenario
    private func loadScenario(_ scenario: SavedScenario) {
        loanAmount = String(format: "%.0f", scenario.loanAmount)
        interestRate = String(format: "%.2f", scenario.interestRate)
        loanTerm = String(format: "%.1f", scenario.loanTerm)
        paymentFrequency = scenario.paymentFrequency
        additionalPayment = String(format: "%.0f", scenario.additionalPayment)
        
        // Calculate with new values
        calculateResults()
    }
}

// MARK: - Helper Views

struct PaymentSummaryView: View {
    let result: CalculationResult
    
    var body: some View {
        Section(header: Text("Payment Summary")) {
            HStack {
                Text("Monthly Payment:")
                Spacer()
                Text("$\(String(format: "%.2f", result.periodicPayment))")
                    .fontWeight(.bold)
            }
            
            HStack {
                Text("Total Interest:")
                Spacer()
                Text("$\(String(format: "%.2f", result.totalInterest))")
                    .fontWeight(.bold)
            }
            
            HStack {
                Text("Total Cost:")
                Spacer()
                Text("$\(String(format: "%.2f", result.totalCost))")
                    .fontWeight(.bold)
            }
        }
    }
}

struct AdditionalPaymentSummaryView: View {
    let scenario: ComparisonScenario
    
    var body: some View {
        Section(header: Text("With Additional Payments")) {
            HStack {
                Text("New Payment:")
                Spacer()
                Text("$\(String(format: "%.2f", scenario.newPayment))")
                    .fontWeight(.bold)
            }
            
            HStack {
                Text("Time Saved:")
                Spacer()
                Text("\(String(format: "%.1f", scenario.timeSaved)) years")
                    .fontWeight(.bold)
            }
            
            HStack {
                Text("Interest Savings:")
                Spacer()
                Text("$\(String(format: "%.2f", scenario.interestSavings))")
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
            }
        }
    }
}

struct ActionButtonsView: View {
    let validateInputs: () -> Bool
    @Binding var showAmortizationSchedule: Bool
    @Binding var showComparisonView: Bool
    @Binding var showingScenarioSaveSheet: Bool
    @Binding var showSavedScenarios: Bool
    
    var body: some View {
        Group {
            Button(action: {
                if validateInputs() {
                    self.showAmortizationSchedule = true
                }
            }) {
                HStack {
                    Image(systemName: "list.bullet")
                    Text("View Amortization Schedule")
                }
            }
            
            Button(action: {
                if validateInputs() {
                    self.showComparisonView = true
                }
            }) {
                HStack {
                    Image(systemName: "chart.bar")
                    Text("Payment Comparison Scenarios")
                }
            }
            
            Button(action: {
                if validateInputs() {
                    self.showingScenarioSaveSheet = true
                }
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                    Text("Save This Scenario")
                }
            }
            
            Button(action: {
                self.showSavedScenarios = true
            }) {
                HStack {
                    Image(systemName: "folder")
                    Text("Saved Scenarios")
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(ScenarioStore())
    }
} 