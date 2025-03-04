import SwiftUI
import Charts
import UniformTypeIdentifiers
import PDFKit
import WebKit

// Define a custom UTType for our mortgage scenario files
extension UTType {
    static var mortgageScenario: UTType {
        UTType(exportedAs: "com.mortgagecalculator.scenario")
    }
}

// The saved scenario model - must be Codable for sharing
struct SavedScenario: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var loanAmount: Decimal
    var interestRate: Decimal
    var loanTerm: Decimal
    var paymentFrequency: String
    var additionalPayment: Decimal
    var createdDate: Date
    
    static func == (lhs: SavedScenario, rhs: SavedScenario) -> Bool {
        return lhs.id == rhs.id
    }
}

// Manages persistent storage of saved scenarios
class ScenarioStore: ObservableObject {
    @Published var savedScenarios: [SavedScenario] = []
    @Published var errorMessage: String = ""
    @Published var showError: Bool = false
    
    private let saveKey = "savedMortgageScenarios"
    
    init() {
        loadScenarios()
    }
    
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
    
    func saveScenarios() {
        do {
            let encoded = try JSONEncoder().encode(savedScenarios)
            UserDefaults.standard.set(encoded, forKey: saveKey)
        } catch {
            self.errorMessage = "Failed to save scenarios: \(error.localizedDescription)"
            self.showError = true
        }
    }
    
    func addScenario(_ scenario: SavedScenario) {
        savedScenarios.append(scenario)
        saveScenarios()
    }
    
    func removeScenario(at offsets: IndexSet) {
        savedScenarios.remove(atOffsets: offsets)
        saveScenarios()
    }
    
    func updateScenario(_ scenario: SavedScenario) {
        if let index = savedScenarios.firstIndex(where: { $0.id == scenario.id }) {
            savedScenarios[index] = scenario
            saveScenarios()
        }
    }
    
    // Share a scenario as a file
    func scenarioData(for scenario: SavedScenario) -> Data? {
        return try? JSONEncoder().encode(scenario)
    }
    
    // Save current scenario to the store
    func saveScenario(_ scenario: SavedScenario) {
        addScenario(scenario)
    }
}

struct MortgageCalculator: App {
    @StateObject private var scenarioStore = ScenarioStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(scenarioStore)
                .onOpenURL { url in
                    // Handle opening scenario files
                    handleOpenURL(url)
                }
        }
    }
    
    private func handleOpenURL(_ url: URL) {
        guard url.pathExtension == "mortgagescenario" else { return }
        
        // Get access to the imported file
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        
        do {
            let data = try Data(contentsOf: url)
            let scenario = try JSONDecoder().decode(SavedScenario.self, from: data)
            
            // Add to stored scenarios if not already present
            if !scenarioStore.savedScenarios.contains(where: { $0.id == scenario.id }) {
                // Create a new ID to avoid potential conflicts
                var newScenario = scenario
                newScenario.id = UUID()
                newScenario.name += " (Shared)"
                scenarioStore.addScenario(newScenario)
            }
        } catch {
            print("Error importing scenario: \(error)")
        }
    }
}

// Dictionary to map payment frequencies to numbers of payments per year
let PAYMENT_FREQUENCIES: [String: Int] = [
    "Weekly": 52,
    "Fortnightly": 26,
    "Monthly": 12
]

// Fallback chart for iOS 15 and earlier
struct FallbackChartView: View {
    var yearlySummary: [YearlySummary]
    var chartType: String
    
    var body: some View {
        VStack {
            Text("Charts require iOS 16 or later")
                .font(.headline)
                .padding()
            
            if chartType == "Balance" {
                Text("Balance Summary:")
                    .font(.subheadline)
                
                ScrollView(.horizontal) {
                    HStack(spacing: 15) {
                        ForEach(yearlySummary) { year in
                            VStack {
                                Text("Year \(year.year)")
                                    .font(.caption)
                                
                                Text("$\(String(format: "%.0f", NSDecimalNumber(decimal: year.remainingBalance).doubleValue))")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            .padding(.vertical, 5)
                            .padding(.horizontal, 10)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                }
            } else if chartType == "Principal vs Interest" {
                Text("Principal vs Interest Summary:")
                    .font(.subheadline)
                
                ScrollView(.horizontal) {
                    HStack(spacing: 15) {
                        ForEach(yearlySummary) { year in
                            VStack {
                                Text("Year \(year.year)")
                                    .font(.caption)
                                
                                Text("P: $\(String(format: "%.0f", NSDecimalNumber(decimal: year.principalPaid).doubleValue))")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                
                                Text("I: $\(String(format: "%.0f", NSDecimalNumber(decimal: year.interestPaid).doubleValue))")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                            .padding(.vertical, 5)
                            .padding(.horizontal, 10)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                }
            } else {
                Text("Payment Breakdown Summary:")
                    .font(.subheadline)
                
                if let firstYear = yearlySummary.first {
                    HStack(spacing: 20) {
                        VStack {
                            Text("Principal")
                                .font(.caption)
                            
                            Text("$\(String(format: "%.0f", NSDecimalNumber(decimal: firstYear.principalPaid).doubleValue))")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                        
                        VStack {
                            Text("Interest")
                                .font(.caption)
                            
                            Text("$\(String(format: "%.0f", NSDecimalNumber(decimal: firstYear.interestPaid).doubleValue))")
                                .font(.subheadline)
                                .foregroundColor(.red)
                        }
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .padding()
                }
            }
        }
    }
}

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
    
    @EnvironmentObject private var scenarioStore: ScenarioStore
    
    var frequencies = ["Weekly", "Fortnightly", "Monthly"]
    
    // Validate input fields
    private func validateInputs() -> Bool {
        // Check loan amount
        guard let loanAmountValue = Decimal(string: loanAmount), loanAmountValue > 0 else {
            inputErrorMessage = "Please enter a valid loan amount greater than 0"
            showInputError = true
            return false
        }
        
        // Check interest rate
        guard let interestRateValue = Decimal(string: interestRate), interestRateValue > 0 else {
            inputErrorMessage = "Please enter a valid interest rate greater than 0"
            showInputError = true
            return false
        }
        
        // Check loan term
        guard let loanTermValue = Decimal(string: loanTerm), loanTermValue > 0 else {
            inputErrorMessage = "Please enter a valid loan term greater than 0"
            showInputError = true
            return false
        }
        
        // Check additional payment (can be 0 or greater)
        guard let additionalPaymentValue = Decimal(string: additionalPayment), additionalPaymentValue >= 0 else {
            inputErrorMessage = "Please enter a valid additional payment (0 or greater)"
            showInputError = true
            return false
        }
        
        return true
    }
    
    // Results of calculation
    private var calculationResult: CalculationResult? {
        guard let loanAmountValue = Decimal(string: loanAmount),
              let interestRateValue = Decimal(string: interestRate),
              let loanTermValue = Decimal(string: loanTerm) else {
            return nil
        }
        
        // Basic calculations
        let basePayment = calculatePeriodicPayment(
            loanAmount: loanAmountValue,
            interestRate: interestRateValue,
            loanTerm: loanTermValue,
            frequency: paymentFrequency
        )
        
        let schedule = generateAmortizationSchedule(
            loanAmount: loanAmountValue,
            interestRate: interestRateValue,
            loanTerm: loanTermValue,
            frequency: paymentFrequency
        )
        
        let totalInterest = schedule.last?.totalInterestPaid ?? 0
        
        // Additional payment scenario (if applicable)
        var additionalPaymentResult: ComparisonScenario? = nil
        if let additionalPaymentValue = Decimal(string: additionalPayment), additionalPaymentValue > 0 {
            let increasedPayment = basePayment + additionalPaymentValue
            let increasedSchedule = generateScheduleWithFixedPayment(
                loanAmount: loanAmountValue,
                interestRate: interestRateValue,
                loanTerm: loanTermValue,
                frequency: paymentFrequency,
                fixedPayment: increasedPayment
            )
            
            if let lastPayment = increasedSchedule.last {
                let increasedTotalInterest = lastPayment.totalInterestPaid
                let increasedYears = Decimal(increasedSchedule.count) / Decimal(PAYMENT_FREQUENCIES[paymentFrequency] ?? 12)
                let interestSavings = totalInterest - increasedTotalInterest
                let timeSaved = loanTermValue - increasedYears
                
                additionalPaymentResult = ComparisonScenario(
                    increasePercentage: (additionalPaymentValue / basePayment) * 100,
                    newPayment: increasedPayment,
                    yearsToPay: increasedYears,
                    interestSavings: interestSavings,
                    timeSaved: timeSaved,
                    totalPaid: loanAmountValue + increasedTotalInterest,
                    totalSaved: (loanAmountValue + totalInterest) - (loanAmountValue + increasedTotalInterest)
                )
            }
        }
        
        // Comparison scenarios (10%, 25%, 50% increase)
        let scenarios = calculateComparisonScenarios(
            loanAmount: loanAmountValue,
            interestRate: interestRateValue,
            loanTerm: loanTermValue,
            frequency: paymentFrequency,
            basePayment: basePayment,
            baseTotalInterest: totalInterest
        )
        
        return CalculationResult(
            periodicPayment: basePayment,
            totalInterest: totalInterest,
            totalCost: loanAmountValue + totalInterest,
            amortizationSchedule: schedule,
            comparisonScenarios: scenarios,
            additionalPaymentScenario: additionalPaymentResult
        )
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Loan Details")) {
                    TextField("Loan Amount ($)", text: $loanAmount)
                        .keyboardType(.decimalPad)
                    
                    TextField("Interest Rate (%)", text: $interestRate)
                        .keyboardType(.decimalPad)
                    
                    TextField("Loan Term (years)", text: $loanTerm)
                        .keyboardType(.decimalPad)
                    
                    Picker("Payment Frequency", selection: $paymentFrequency) {
                        ForEach(frequencies, id: \.self) {
                            Text($0)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("Additional Payments")) {
                    TextField("Additional Payment (per period)", text: $additionalPayment)
                        .keyboardType(.decimalPad)
                }
                
                if let result = calculationResult {
                    Section(header: Text("Payment Summary")) {
                        HStack {
                            Text("\(paymentFrequency) Payment:")
                            Spacer()
                            Text("$\(String(format: "%.2f", NSDecimalNumber(decimal: result.periodicPayment).doubleValue))")
                                .fontWeight(.bold)
                        }
                        
                        HStack {
                            Text("Total Interest:")
                            Spacer()
                            Text("$\(String(format: "%.2f", NSDecimalNumber(decimal: result.totalInterest).doubleValue))")
                                .fontWeight(.bold)
                        }
                        
                        HStack {
                            Text("Total Cost:")
                            Spacer()
                            Text("$\(String(format: "%.2f", NSDecimalNumber(decimal: result.totalCost).doubleValue))")
                                .fontWeight(.bold)
                        }
                    }
                    
                    if let additionalPaymentScenario = result.additionalPaymentScenario {
                        Section(header: Text("With Additional Payments")) {
                            HStack {
                                Text("New Payment:")
                                Spacer()
                                Text("$\(String(format: "%.2f", NSDecimalNumber(decimal: additionalPaymentScenario.newPayment).doubleValue))")
                                    .fontWeight(.bold)
                            }
                            
                            HStack {
                                Text("Time Saved:")
                                Spacer()
                                Text("\(String(format: "%.1f", NSDecimalNumber(decimal: additionalPaymentScenario.timeSaved).doubleValue)) years")
                                    .fontWeight(.bold)
                            }
                            
                            HStack {
                                Text("Interest Savings:")
                                Spacer()
                                Text("$\(String(format: "%.2f", NSDecimalNumber(decimal: additionalPaymentScenario.interestSavings).doubleValue))")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                } else {
                    Section {
                        Text("Please enter valid numbers")
                            .foregroundColor(.red)
                    }
                }
                
                Section {
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
                    
                    // New buttons for scenario management
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
            .navigationTitle("Mortgage Calculator")
            .alert(inputErrorMessage, isPresented: $showInputError) {
                Button("OK", role: .cancel) {}
            }
            .sheet(isPresented: $showAmortizationSchedule) {
                if let result = calculationResult {
                    AmortizationScheduleView(
                        amortizationSchedule: result.amortizationSchedule,
                        loanAmount: Decimal(string: loanAmount) ?? 0,
                        interestRate: Decimal(string: interestRate) ?? 0,
                        loanTerm: Decimal(string: loanTerm) ?? 0,
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
    
    func calculatePeriodicPayment(loanAmount: Decimal, interestRate: Decimal, loanTerm: Decimal, frequency: String) -> Decimal {
        // Get number of payments per year
        let paymentsPerYear = Decimal(PAYMENT_FREQUENCIES[frequency] ?? 12)
        
        // Convert annual rate to periodic rate
        let periodicRate = (interestRate / 100) / paymentsPerYear
        
        // Calculate number of payments
        let numberOfPayments = loanTerm * paymentsPerYear
        
        // Calculate periodic payment using the loan payment formula
        // For Decimal, we need to use NSDecimalNumber for power operations
        let periodicRateDouble = NSDecimalNumber(decimal: periodicRate).doubleValue
        let numberOfPaymentsDouble = NSDecimalNumber(decimal: numberOfPayments).doubleValue
        
        let powerFactor = pow(1 + periodicRateDouble, numberOfPaymentsDouble)
        let powerFactorDecimal = Decimal(powerFactor)
        
        let numerator = loanAmount * periodicRate * powerFactorDecimal
        let denominator = powerFactorDecimal - 1
        
        return numerator / denominator
    }
    
    func generateAmortizationSchedule(loanAmount: Decimal, interestRate: Decimal, loanTerm: Decimal, frequency: String) -> [PaymentPeriod] {
        // Get number of payments per year
        let paymentsPerYear = Decimal(PAYMENT_FREQUENCIES[frequency] ?? 12)
        
        // Convert annual rate to periodic rate
        let periodicRate = (interestRate / 100) / paymentsPerYear
        
        // Calculate periodic payment
        let payment = calculatePeriodicPayment(
            loanAmount: loanAmount, 
            interestRate: interestRate, 
            loanTerm: loanTerm, 
            frequency: frequency
        )
        
        // Initialize values
        var schedule: [PaymentPeriod] = []
        var remainingBalance = loanAmount
        var totalInterestPaid: Decimal = 0
        var annualInterest: Decimal = 0
        var yearNumber = 1
        
        let numberOfPayments = Int(loanTerm * paymentsPerYear)
        
        for periodNumber in 1...numberOfPayments {
            // Calculate interest payment
            let interestPayment = remainingBalance * periodicRate
            var principalPayment = payment - interestPayment
            
            // Handle final payment adjustment
            if remainingBalance < principalPayment {
                principalPayment = remainingBalance
            }
            
            remainingBalance -= principalPayment
            totalInterestPaid += interestPayment
            annualInterest += interestPayment
            
            // Calculate current year
            let currentYear = Int((Double(periodNumber - 1) / paymentsPerYear) + 1)
            
            // Reset annual interest for new year
            if currentYear != yearNumber {
                annualInterest = interestPayment
                yearNumber = currentYear
            }
            
            // Ensure remaining balance doesn't go below zero
            if remainingBalance < 0 {
                remainingBalance = 0
            }
            
            // Add payment to schedule
            let period = PaymentPeriod(
                id: periodNumber,
                periodNumber: periodNumber,
                payment: payment,
                principalPayment: principalPayment,
                interestPayment: interestPayment,
                remainingBalance: remainingBalance,
                totalInterestPaid: totalInterestPaid,
                annualInterest: annualInterest,
                percentagePaid: ((loanAmount - remainingBalance) / loanAmount) * 100,
                year: currentYear
            )
            
            schedule.append(period)
            
            // Stop if the loan is paid off
            if remainingBalance == 0 {
                break
            }
        }
        
        return schedule
    }
    
    func generateScheduleWithFixedPayment(loanAmount: Decimal, interestRate: Decimal, loanTerm: Decimal, frequency: String, fixedPayment: Decimal) -> [PaymentPeriod] {
        // Get number of payments per year
        let paymentsPerYear = Decimal(PAYMENT_FREQUENCIES[frequency] ?? 12)
        
        // Convert annual rate to periodic rate
        let periodicRate = (interestRate / 100) / paymentsPerYear
        
        // Calculate minimum payment (to ensure the fixed payment is sufficient)
        let minPayment = calculatePeriodicPayment(
            loanAmount: loanAmount, 
            interestRate: interestRate, 
            loanTerm: loanTerm, 
            frequency: frequency
        )
        
        // Use the fixed payment if it's greater than the minimum, otherwise use minimum
        let payment = max(fixedPayment, minPayment)
        
        // Initialize values
        var schedule: [PaymentPeriod] = []
        var remainingBalance = loanAmount
        var totalInterestPaid: Decimal = 0
        var annualInterest: Decimal = 0
        var yearNumber = 1
        var periodNumber = 1
        
        // Continue until the loan is paid off
        while remainingBalance > 0 {
            // Calculate interest payment
            let interestPayment = remainingBalance * periodicRate
            var principalPayment = payment - interestPayment
            
            // Handle final payment adjustment
            if principalPayment > remainingBalance {
                principalPayment = remainingBalance
            }
            
            remainingBalance -= principalPayment
            totalInterestPaid += interestPayment
            annualInterest += interestPayment
            
            // Calculate current year
            let currentYear = Int((Double(periodNumber - 1) / paymentsPerYear) + 1)
            
            // Reset annual interest for new year
            if currentYear != yearNumber {
                annualInterest = interestPayment
                yearNumber = currentYear
            }
            
            // Ensure remaining balance doesn't go below zero
            if remainingBalance < 0 {
                remainingBalance = 0
            }
            
            // Add payment to schedule
            let period = PaymentPeriod(
                id: periodNumber,
                periodNumber: periodNumber,
                payment: principalPayment + interestPayment,
                principalPayment: principalPayment,
                interestPayment: interestPayment,
                remainingBalance: remainingBalance,
                totalInterestPaid: totalInterestPaid,
                annualInterest: annualInterest,
                percentagePaid: ((loanAmount - remainingBalance) / loanAmount) * 100,
                year: currentYear
            )
            
            schedule.append(period)
            
            // Safety check to prevent infinite loops (unlikely but possible with very small payments)
            if periodNumber > Int(loanTerm * paymentsPerYear * 2) {
                break
            }
            
            periodNumber += 1
        }
        
        return schedule
    }
    
    func calculateComparisonScenarios(loanAmount: Decimal, interestRate: Decimal, loanTerm: Decimal, frequency: String, basePayment: Decimal, baseTotalInterest: Decimal) -> [ComparisonScenario] {
        let increases = [10.0, 25.0, 50.0] // Percentage increases
        var scenarios: [ComparisonScenario] = []
        
        let baseTotalPaid = loanAmount + baseTotalInterest
        
        for increase in increases {
            let increasedPayment = basePayment * (1 + increase/100)
            
            let increasedSchedule = generateScheduleWithFixedPayment(
                loanAmount: loanAmount,
                interestRate: interestRate,
                loanTerm: loanTerm,
                frequency: frequency,
                fixedPayment: increasedPayment
            )
            
            if let lastPayment = increasedSchedule.last {
                let increasedTotalInterest = lastPayment.totalInterestPaid
                let increasedYears = Double(increasedSchedule.count) / Double(PAYMENT_FREQUENCIES[frequency] ?? 12)
                let interestSavings = baseTotalInterest - increasedTotalInterest
                let timeSaved = loanTerm - increasedYears
                let increasedTotalPaid = loanAmount + increasedTotalInterest
                
                let scenario = ComparisonScenario(
                    increasePercentage: increase,
                    newPayment: increasedPayment,
                    yearsToPay: increasedYears,
                    interestSavings: interestSavings,
                    timeSaved: timeSaved,
                    totalPaid: increasedTotalPaid,
                    totalSaved: baseTotalPaid - increasedTotalPaid
                )
                
                scenarios.append(scenario)
            }
        }
        
        return scenarios
    }
    
    // Save current scenario to the store
    private func saveCurrentScenario() {
        guard let loanAmountValue = Decimal(string: loanAmount),
              let interestRateValue = Decimal(string: interestRate),
              let loanTermValue = Decimal(string: loanTerm),
              let additionalPaymentValue = Decimal(string: additionalPayment),
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
        loanAmount = NSDecimalNumber(decimal: scenario.loanAmount).stringValue
        interestRate = NSDecimalNumber(decimal: scenario.interestRate).stringValue
        loanTerm = NSDecimalNumber(decimal: scenario.loanTerm).stringValue
        paymentFrequency = scenario.paymentFrequency
        additionalPayment = NSDecimalNumber(decimal: scenario.additionalPayment).stringValue
    }
}

struct AmortizationScheduleView: View {
    var amortizationSchedule: [PaymentPeriod]
    var loanAmount: Decimal
    var interestRate: Decimal
    var loanTerm: Decimal
    var frequency: String
    
    @State private var selectedChartDataType = "Balance"
    private let chartDataTypes = ["Balance", "Principal vs Interest", "Payment Breakdown"]
    
    private var yearlySummary: [YearlySummary] {
        let frequencyPerYear = PAYMENT_FREQUENCIES[frequency] ?? 12
        var years: [YearlySummary] = []
        
        for year in 1...Int(ceil(Double(amortizationSchedule.count) / Double(frequencyPerYear))) {
            let startIndex = (year - 1) * frequencyPerYear
            let endIndex = min(startIndex + frequencyPerYear - 1, amortizationSchedule.count - 1)
            
            if startIndex < amortizationSchedule.count {
                let yearStart = amortizationSchedule[startIndex]
                let yearEnd = amortizationSchedule[endIndex]
                
                let principalPaid: Decimal
                let interestPaid: Decimal
                
                if year == 1 {
                    principalPaid = yearEnd.totalPrincipalPaid
                    interestPaid = yearEnd.totalInterestPaid
                } else {
                    let previousYearEnd = amortizationSchedule[min((year - 2) * frequencyPerYear + frequencyPerYear - 1, amortizationSchedule.count - 1)]
                    principalPaid = yearEnd.totalPrincipalPaid - previousYearEnd.totalPrincipalPaid
                    interestPaid = yearEnd.totalInterestPaid - previousYearEnd.totalInterestPaid
                }
                
                years.append(YearlySummary(
                    year: year,
                    remainingBalance: yearEnd.remainingBalance,
                    principalPaid: principalPaid,
                    interestPaid: interestPaid
                ))
            }
        }
        
        return years
    }
    
    var body: some View {
        VStack {
            Picker("Chart Type", selection: $selectedChartDataType) {
                ForEach(chartDataTypes, id: \.self) { type in
                    Text(type)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            if #available(iOS 16.0, *) {
                if selectedChartDataType == "Balance" {
                    BalanceChart(yearlySummary: yearlySummary)
                } else if selectedChartDataType == "Principal vs Interest" {
                    PrincipalVsInterestChart(yearlySummary: yearlySummary)
                } else {
                    PaymentBreakdownChart(yearlySummary: yearlySummary)
                }
            } else {
                // Fallback for iOS 15 and earlier
                FallbackChartView(yearlySummary: yearlySummary, chartType: selectedChartDataType)
            }
            
            List {
                Section(header: Text("Loan Summary")) {
                    HStack {
                        Text("Loan Amount:")
                        Spacer()
                        Text("$\(String(format: "%.2f", NSDecimalNumber(decimal: loanAmount).doubleValue))")
                    }
                    
                    HStack {
                        Text("Interest Rate:")
                        Spacer()
                        Text("\(String(format: "%.2f", NSDecimalNumber(decimal: interestRate).doubleValue))%")
                    }
                    
                    HStack {
                        Text("Loan Term:")
                        Spacer()
                        Text("\(String(format: "%.1f", NSDecimalNumber(decimal: loanTerm).doubleValue)) years")
                    }
                    
                    HStack {
                        Text("Payment Frequency:")
                        Spacer()
                        Text(frequency)
                    }
                }
                
                Section(header: Text("Amortization Schedule")) {
                    ForEach(0..<amortizationSchedule.count, id: \.self) { index in
                        let payment = amortizationSchedule[index]
                        let paymentNumber = index + 1
                        
                        if paymentNumber == 1 || paymentNumber % (PAYMENT_FREQUENCIES[frequency] ?? 12) == 0 || paymentNumber == amortizationSchedule.count {
                            VStack(alignment: .leading) {
                                Text("Payment \(paymentNumber)")
                                    .font(.headline)
                                
                                HStack {
                                    Text("Principal:")
                                    Spacer()
                                    Text("$\(String(format: "%.2f", NSDecimalNumber(decimal: payment.principalPayment).doubleValue))")
                                }
                                
                                HStack {
                                    Text("Interest:")
                                    Spacer()
                                    Text("$\(String(format: "%.2f", NSDecimalNumber(decimal: payment.interestPayment).doubleValue))")
                                }
                                
                                HStack {
                                    Text("Remaining Balance:")
                                    Spacer()
                                    Text("$\(String(format: "%.2f", NSDecimalNumber(decimal: payment.remainingBalance).doubleValue))")
                                }
                            }
                            .padding(.vertical, 5)
                        }
                    }
                }
            }
        }
        .navigationTitle("Amortization Schedule")
    }
}

@available(iOS 16.0, *)
struct BalanceChart: View {
    var yearlySummary: [YearlySummary]
    
    var body: some View {
        Chart {
            ForEach(yearlySummary) { year in
                LineMark(
                    x: .value("Year", year.year),
                    y: .value("Balance", year.remainingBalance)
                )
                .foregroundStyle(.blue)
                .interpolationMethod(.catmullRom)
            }
        }
        .chartXAxisLabel("Year")
        .chartYAxisLabel("Balance")
    }
}

@available(iOS 16.0, *)
struct PrincipalVsInterestChart: View {
    var yearlySummary: [YearlySummary]
    
    var body: some View {
        Chart {
            ForEach(yearlySummary) { year in
                BarMark(
                    x: .value("Year", year.year),
                    y: .value("Principal", year.principalPaid)
                )
                .foregroundStyle(.blue)
                
                BarMark(
                    x: .value("Year", year.year),
                    y: .value("Interest", year.interestPaid)
                )
                .foregroundStyle(.red)
            }
        }
        .chartXAxisLabel("Year")
        .chartYAxisLabel("Amount")
    }
}

@available(iOS 16.0, *)
struct PaymentBreakdownChart: View {
    var yearlySummary: [YearlySummary]
    
    var body: some View {
        Chart {
            ForEach(yearlySummary) { year in
                SectorMark(
                    angle: .value("Paid", year.principalPaid),
                    innerRadius: .ratio(0.5),
                    angularInset: 1.0
                )
                .foregroundStyle(.blue)
                .annotation(position: .overlay) {
                    Text("Principal")
                        .font(.caption)
                        .foregroundColor(.white)
                }
                
                SectorMark(
                    angle: .value("Interest", year.interestPaid),
                    innerRadius: .ratio(0.5),
                    angularInset: 1.0
                )
                .foregroundStyle(.red)
                .annotation(position: .overlay) {
                    Text("Interest")
                        .font(.caption)
                        .foregroundColor(.white)
                }
            }
        }
    }
}

struct ComparisonView: View {
    let scenarios: [ComparisonScenario]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(scenarios) { scenario in
                    Section(header: Text("+\(Int(NSDecimalNumber(decimal: scenario.increasePercentage).doubleValue))% Payment Increase")) {
                        VStack(spacing: 8) {
                            HStack {
                                Text("New Payment:")
                                Spacer()
                                Text("$\(String(format: "%.2f", NSDecimalNumber(decimal: scenario.newPayment).doubleValue))")
                                    .font(.headline)
                            }
                            
                            HStack {
                                Text("Years to Pay:")
                                Spacer()
                                Text("\(String(format: "%.1f", NSDecimalNumber(decimal: scenario.yearsToPay).doubleValue)) years")
                            }
                            
                            HStack {
                                Text("Time Saved:")
                                Spacer()
                                Text("\(String(format: "%.1f", NSDecimalNumber(decimal: scenario.timeSaved).doubleValue)) years")
                                    .foregroundColor(.green)
                            }
                            
                            HStack {
                                Text("Interest Savings:")
                                Spacer()
                                Text("$\(String(format: "%.2f", NSDecimalNumber(decimal: scenario.interestSavings).doubleValue))")
                                    .foregroundColor(.green)
                            }
                            
                            HStack {
                                Text("Total Savings:")
                                Spacer()
                                Text("$\(String(format: "%.2f", NSDecimalNumber(decimal: scenario.totalSaved).doubleValue))")
                                    .font(.headline)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Payment Scenarios")
        }
    }
}

// Data structures

struct PaymentPeriod: Identifiable {
    let id: Int
    let periodNumber: Int
    let payment: Decimal
    let principalPayment: Decimal
    let interestPayment: Decimal
    let remainingBalance: Decimal
    let totalInterestPaid: Decimal
    let annualInterest: Decimal
    let percentagePaid: Decimal
    let year: Int
}

struct YearlySummary: Identifiable {
    var id = UUID()
    var year: Int
    var remainingBalance: Decimal
    var principalPaid: Decimal
    var interestPaid: Decimal
    
    var totalPaid: Decimal {
        principalPaid + interestPaid
    }
}

struct ComparisonScenario: Identifiable {
    var id: UUID = UUID()
    let increasePercentage: Decimal
    let newPayment: Decimal
    let yearsToPay: Decimal
    let interestSavings: Decimal
    let timeSaved: Decimal
    let totalPaid: Decimal
    let totalSaved: Decimal
}

struct CalculationResult {
    let periodicPayment: Decimal
    let totalInterest: Decimal
    let totalCost: Decimal
    let amortizationSchedule: [PaymentPeriod]
    let comparisonScenarios: [ComparisonScenario]
    let additionalPaymentScenario: ComparisonScenario?
}

// Helper struct for sharing content
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

// A view for managing saved scenarios
struct SavedScenariosView: View {
    @EnvironmentObject private var scenarioStore: ScenarioStore
    @State private var scenarioToShare: SavedScenario?
    @State private var showingShareSheet = false
    var onSelectScenario: (SavedScenario) -> Void
    
    var body: some View {
        NavigationView {
            List {
                ForEach(scenarioStore.savedScenarios) { scenario in
                    VStack(alignment: .leading) {
                        Text(scenario.name)
                            .font(.headline)
                        
                        HStack {
                            Text("Loan: $\(String(describing: scenario.loanAmount))")
                            Spacer()
                            Text("Rate: \(String(describing: scenario.interestRate))%")
                        }
                        .font(.subheadline)
                        
                        HStack {
                            Text("Term: \(String(describing: scenario.loanTerm)) years")
                            Spacer()
                            Text("Frequency: \(scenario.paymentFrequency)")
                        }
                        .font(.subheadline)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onSelectScenario(scenario)
                    }
                    .contextMenu {
                        Button {
                            scenarioToShare = scenario
                            showingShareSheet = true
                        } label: {
                            Label("Share with Partner", systemImage: "square.and.arrow.up")
                        }
                        
                        Button(role: .destructive) {
                            if let index = scenarioStore.savedScenarios.firstIndex(where: { $0.id == scenario.id }) {
                                scenarioStore.removeScenario(at: IndexSet(integer: index))
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
                .onDelete { indexSet in
                    scenarioStore.removeScenario(at: indexSet)
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

// Custom share sheet for scenarios
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
} 