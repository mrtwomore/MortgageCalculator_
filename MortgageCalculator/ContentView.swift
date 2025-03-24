import Foundation
import SwiftUI
import Charts

// Platform-specific typealias for cross-platform compatibility
#if os(iOS)
import UIKit
import PDFKit

// iOS specific typealias
typealias PlatformViewControllerRepresentable = UIViewControllerRepresentable
typealias PlatformViewController = UIViewController
typealias PlatformView = UIView
typealias PlatformBarButtonItem = UIBarButtonItem
typealias PlatformActivityViewController = UIActivityViewController
#elseif os(macOS)
import AppKit
import PDFKit

// macOS specific typealias
typealias PlatformViewControllerRepresentable = NSViewControllerRepresentable
typealias PlatformViewController = NSViewController
typealias PlatformView = NSView
typealias PlatformBarButtonItem = NSToolbarItem
// For macOS we'll use custom implementation where needed
#endif

// Cross-platform UI helpers
extension View {
    @ViewBuilder
    func customActionSheet(
        isPresented: Binding<Bool>,
        title: String,
        message: String? = nil,
        buttons: [CustomActionButton]
    ) -> some View {
        #if os(iOS)
        self.actionSheet(isPresented: isPresented) {
            ActionSheet(
                title: Text(title),
                message: message != nil ? Text(message!) : nil,
                buttons: buttons.map { button in
                    switch button.role {
                    case .cancel:
                        return .cancel(Text(button.title))
                    case .destructive:
                        return .destructive(Text(button.title), action: button.action)
                    default:
                        return .default(Text(button.title), action: button.action)
                    }
                }
            )
        }
        #elseif os(macOS)
        self.popover(isPresented: isPresented) {
            VStack(alignment: .leading, spacing: 10) {
                Text(title).font(.headline)
                
                if let message = message {
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                ForEach(buttons.indices, id: \.self) { index in
                    let button = buttons[index]
                    Button(action: {
                        isPresented.wrappedValue = false
                        button.action?()
                    }) {
                        Text(button.title)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(button.role == .destructive ? .red : nil)
                }
            }
            .padding()
            .frame(width: 300)
        }
        #endif
    }
}

struct CustomActionButton {
    var title: String
    var role: ButtonRole?
    var action: (() -> Void)?
    
    static func cancel(_ title: String) -> CustomActionButton {
        CustomActionButton(title: title, role: .cancel, action: nil)
    }
    
    static func destructive(_ title: String, action: (() -> Void)? = nil) -> CustomActionButton {
        CustomActionButton(title: title, role: .destructive, action: action)
    }
    
    static func `default`(_ title: String, action: (() -> Void)? = nil) -> CustomActionButton {
        CustomActionButton(title: title, role: nil, action: action)
    }
}

// Import all local modules
import Foundation
import SwiftUI

// Forward declarations of required types
// Normally these would be available via module imports
struct MortgageScenario: Identifiable, Codable {
    var id: UUID
    var name: String
    var loanAmount: Double
    var interestRate: Double
    var loanTermYears: Double
    var loanType: String
    var paymentFrequency: String
    var lumpSumPayments: [LumpSumPayment]
    var additionalPayment: Double
    
    var effectivePayment: Double { regularPayment + additionalPayment }
    var regularPayment: Double { /* Implementation would be here */ 0.0 }
}

struct LumpSumPayment: Identifiable, Codable {
    var id: UUID
    var amount: Double
    var paymentDate: Date
    var paymentNumber: Int
}

struct PaymentDetails: Identifiable {
    var id: UUID
    let paymentNumber: Int
    let principal: Double
    let interest: Double
    let totalPayment: Double
    let remainingBalance: Double
    let date: Date
    var principalToDatePercentage: Double
    var interestToDate: Double
}

enum LoanType: String, CaseIterable, Identifiable {
    case fixed = "Fixed Rate"
    case variable = "Variable Rate"
    
    var id: String { self.rawValue }
}

enum PaymentFrequency: String, CaseIterable, Identifiable {
    case weekly = "Weekly"
    case biweekly = "Bi-Weekly"
    case monthly = "Monthly"
    
    var id: String { self.rawValue }
    
    var paymentsPerYear: Int {
        switch self {
        case .weekly: return 52
        case .biweekly: return 26
        case .monthly: return 12
        }
    }
}

// Mock implementation of required services and utilities for compiler satisfaction
class ScenarioStore: ObservableObject {
    @Published var scenarios: [MortgageScenario] = []
    @Published var currentScenario: MortgageScenario = ScenarioStore.createDefaultScenario()
    
    static func createDefaultScenario() -> MortgageScenario {
        MortgageScenario(
            id: UUID(),
            name: "Default Scenario",
            loanAmount: 300000,
            interestRate: 5.0,
            loanTermYears: 30,
            loanType: LoanType.fixed.rawValue,
            paymentFrequency: PaymentFrequency.monthly.rawValue,
            lumpSumPayments: [],
            additionalPayment: 0
        )
    }
    
    func updateScenario(_ scenario: MortgageScenario) {}
    
    func addScenario(_ scenario: MortgageScenario) {}
    
    func deleteScenario(_ scenario: MortgageScenario) {}
    
    func duplicateScenario(_ scenario: MortgageScenario) -> MortgageScenario { scenario }
}

class MortgageCalculator {
    static func calculateAmortizationSchedule(scenario: MortgageScenario) -> [PaymentDetails] { [] }
    static func calculateSavings(baseScenario: MortgageScenario, comparisonScenario: MortgageScenario) -> (timeSaved: Double, interestSaved: Double) { (0, 0) }
}

struct Formatters {
    static func formatCurrency(_ value: Double) -> String { "$\(value)" }
    static func formatPercent(_ value: Double) -> String { "\(value)%" }
    static func formatDate(_ date: Date) -> String { "01/01/2023" }
}

struct ExportManager {
    static func exportToCSV(scenario: MortgageScenario, payments: [PaymentDetails]) -> URL? { nil }
    static func generatePDFReport(scenario: MortgageScenario, payments: [PaymentDetails]) -> Data? { nil }
    static func shareFile(at url: URL, from viewController: AnyObject) {}
}

struct LumpSumPaymentsView: View {
    init(scenario: Binding<MortgageScenario>) {}
    var body: some View { Text("Lump Sum Payments") }
}

struct MortgageChartView: View {
    init(payments: [PaymentDetails]) {}
    var body: some View { Text("Mortgage Chart") }
}

// Note: The real implementations would come from your actual model files
// This is just to satisfy the compiler for ContentView

struct ContentView: View {
    @StateObject private var scenarioStore = ScenarioStore()
    @State private var amortizationSchedule: [PaymentDetails] = []
    @State private var showingScenarioSelector = false
    @State private var showingSaveOptions = false
    @State private var showingExportOptions = false
    @State private var newScenarioName = ""
    @State private var selectedTab = 0
    @State private var showingPDFPreview = false
    @State private var pdfData: Data?
    @State private var comparisonSchedule: [PaymentDetails] = []
    @State private var comparisonScenario: MortgageScenario?
    @AppStorage("colorScheme") private var colorScheme: String = "system"
    
    private var currentScenario: Binding<MortgageScenario> {
        Binding(
            get: { scenarioStore.currentScenario },
            set: { 
                scenarioStore.currentScenario = $0
                scenarioStore.updateScenario($0)
            }
        )
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            inputView
                .tabItem {
                    Label("Calculator", systemImage: "calculator")
                }
                .tag(0)
            
            resultsView
                .tabItem {
                    Label("Results", systemImage: "chart.pie")
                }
                .tag(1)
            
            amortizationScheduleView
                .tabItem {
                    Label("Schedule", systemImage: "calendar")
                }
                .tag(2)
            
            comparisonView
                .tabItem {
                    Label("Compare", systemImage: "arrow.left.arrow.right")
                }
                .tag(3)
            
            settingsView
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(4)
        }
        .onAppear {
            calculateSchedule()
        }
        .onChange(of: scenarioStore.currentScenario) { _ in
            calculateSchedule()
        }
        .sheet(isPresented: $showingPDFPreview) {
            if let data = pdfData {
                PDFPreview(data: data)
            }
        }
        .customActionSheet(
            isPresented: $showingSaveOptions,
            title: "Save Options",
            message: "Save or update the current scenario",
            buttons: [
                CustomActionButton.default("Save Current Scenario") {
                    scenarioStore.updateScenario(scenarioStore.currentScenario)
                },
                CustomActionButton.default("Save as New Scenario") {
                    showingScenarioSelector = true
                },
                CustomActionButton.cancel("Cancel")
            ]
        )
        .preferredColorScheme(getColorScheme())
    }
    
    private var inputView: some View {
        NavigationView {
            Form {
                Section(header: Text("Loan Details")) {
                    HStack {
                        Text("Loan Amount")
                        Spacer()
                        TextField("Loan Amount", value: currentScenario.loanAmount, format: .currency(code: "USD"))
                            #if os(iOS)
                            .keyboardType(.decimalPad)
                            #endif
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Interest Rate (%)")
                        Spacer()
                        TextField("Interest Rate", value: currentScenario.interestRate, format: .number)
                            #if os(iOS)
                            .keyboardType(.decimalPad)
                            #endif
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Loan Term (Years)")
                        Spacer()
                        TextField("Loan Term", value: currentScenario.loanTermYears, format: .number)
                            #if os(iOS)
                            .keyboardType(.decimalPad)
                            #endif
                            .multilineTextAlignment(.trailing)
                    }
                    
                    Picker("Loan Type", selection: currentScenario.loanType) {
                        ForEach(LoanType.allCases) { loanType in
                            Text(loanType.rawValue).tag(loanType.rawValue)
                        }
                    }
                    
                    Picker("Payment Frequency", selection: currentScenario.paymentFrequency) {
                        ForEach(PaymentFrequency.allCases) { frequency in
                            Text(frequency.rawValue).tag(frequency.rawValue)
                        }
                    }
                }
                
                Section(header: Text("Additional Payments")) {
                    HStack {
                        Text("Extra Payment")
                        Spacer()
                        TextField("Extra", value: currentScenario.additionalPayment, format: .currency(code: "USD"))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    NavigationLink(destination: LumpSumPaymentsView(scenario: currentScenario)) {
                        HStack {
                            Text("Lump Sum Payments")
                            Spacer()
                            Text("\(currentScenario.wrappedValue.lumpSumPayments.count)")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section(header: Text("Payment Summary")) {
                    HStack {
                        Text("Regular Payment")
                        Spacer()
                        Text(Formatters.formatCurrency(currentScenario.wrappedValue.regularPayment))
                            .bold()
                    }
                    
                    if currentScenario.wrappedValue.additionalPayment > 0 {
                        HStack {
                            Text("Additional Payment")
                            Spacer()
                            Text(Formatters.formatCurrency(currentScenario.wrappedValue.additionalPayment))
                                .foregroundColor(.green)
                        }
                        
                        HStack {
                            Text("Total Payment")
                            Spacer()
                            Text(Formatters.formatCurrency(currentScenario.wrappedValue.effectivePayment))
                                .bold()
                        }
                    }
                    
                    if !amortizationSchedule.isEmpty {
                        HStack {
                            Text("Total Interest")
                            Spacer()
                            Text(Formatters.formatCurrency(amortizationSchedule.last?.interestToDate ?? 0))
                                .foregroundColor(.red)
                        }
                        
                        HStack {
                            Text("Number of Payments")
                            Spacer()
                            Text("\(amortizationSchedule.count)")
                        }
                        
                        if currentScenario.wrappedValue.additionalPayment > 0 || !currentScenario.wrappedValue.lumpSumPayments.isEmpty {
                            let savedYears = (currentScenario.wrappedValue.loanTermYears * Double(PaymentFrequency(rawValue: currentScenario.wrappedValue.paymentFrequency)?.paymentsPerYear ?? 12) - Double(amortizationSchedule.count)) / Double(PaymentFrequency(rawValue: currentScenario.wrappedValue.paymentFrequency)?.paymentsPerYear ?? 12)
                            
                            if savedYears > 0 {
                                HStack {
                                    Text("Time Saved")
                                    Spacer()
                                    Text(String(format: "%.1f years", savedYears))
                                        .foregroundColor(.green)
                                        .bold()
                                }
                            }
                        }
                        
                        Section {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Balance Breakdown")
                                    .font(.headline)
                                
                                balanceBreakdownChart
                                    .frame(height: 180)
                                    .padding(.vertical, 8)
                                
                                Divider()
                                
                                Text("Payment Composition")
                                    .font(.headline)
                                
                                if let firstPayment = amortizationSchedule.first {
                                    firstPaymentPieChart(firstPayment)
                                        .frame(height: 180)
                                        .padding(.vertical, 8)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
            }
            .navigationTitle("Mortgage Calculator")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingScenarioSelector = true
                    }) {
                        Label("Scenarios", systemImage: "list.bullet")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingSaveOptions = true
                    }) {
                        Label("Save", systemImage: "square.and.arrow.down")
                    }
                }
            }
            .actionSheet(isPresented: $showingScenarioSelector) {
                CustomActionButton(title: "Select Scenario", role: nil, action: {
                    showingScenarioSelector = true
                })
            }
        }
    }
    
    private var scenarioSelectButtons: [CustomActionButton] {
        var buttons: [CustomActionButton] = scenarioStore.scenarios.map { scenario in
            CustomActionButton(title: scenario.name, role: nil, action: {
                scenarioStore.currentScenario = scenario
            })
        }
        
        buttons.append(CustomActionButton(title: "Create New Scenario", role: nil, action: {
            let newScenario = ScenarioStore.createDefaultScenario()
            scenarioStore.addScenario(newScenario)
            scenarioStore.currentScenario = newScenario
        }))
        
        buttons.append(CustomActionButton(title: "Cancel", role: .cancel, action: nil))
        
        return buttons
    }
    
    private var resultsView: some View {
        NavigationView {
            VStack(spacing: 0) {
                if !amortizationSchedule.isEmpty {
                    MortgageChartView(payments: amortizationSchedule)
                        .padding()
                }
                
                List {
                    Section(header: Text("Payment Breakdown")) {
                        HStack {
                            Text("Principal & Interest")
                            Spacer()
                            Text(Formatters.formatCurrency(currentScenario.wrappedValue.regularPayment))
                        }
                        
                        if currentScenario.wrappedValue.additionalPayment > 0 {
                            HStack {
                                Text("Additional Payment")
                                Spacer()
                                Text(Formatters.formatCurrency(currentScenario.wrappedValue.additionalPayment))
                                    .foregroundColor(.green)
                            }
                        }
                        
                        HStack {
                            Text("Total Monthly Payment")
                            Spacer()
                            Text(Formatters.formatCurrency(currentScenario.wrappedValue.effectivePayment))
                                .bold()
                        }
                    }
                    
                    Section(header: Text("Loan Progress")) {
                        if !amortizationSchedule.isEmpty {
                            HStack {
                                Text("Time to Payoff")
                                Spacer()
                                Text(String(format: "%.1f years", Double(amortizationSchedule.count) / Double(PaymentFrequency(rawValue: currentScenario.wrappedValue.paymentFrequency)?.paymentsPerYear ?? 12)))
                            }
                            
                            HStack {
                                Text("Total Payments")
                                Spacer()
                                Text(Formatters.formatCurrency(amortizationSchedule.reduce(0) { $0 + $1.totalPayment }))
                            }
                            
                            HStack {
                                Text("Total Interest")
                                Spacer()
                                Text(Formatters.formatCurrency(amortizationSchedule.last?.interestToDate ?? 0))
                                    .foregroundColor(.red)
                            }
                            
                            HStack {
                                Text("Interest to Principal Ratio")
                                Spacer()
                                Text(String(format: "%.1f%%", (amortizationSchedule.last?.interestToDate ?? 0) / currentScenario.wrappedValue.loanAmount * 100))
                            }
                        }
                    }
                    
                    Section {
                        Button(action: {
                            showingExportOptions = true
                        }) {
                            Label("Export Results", systemImage: "square.and.arrow.up")
                        }
                    }
                }
            }
            .navigationTitle("Payment Results")
            .actionSheet(isPresented: $showingExportOptions) {
                CustomActionButton(title: "Export Options", role: nil, action: {
                    showingExportOptions = true
                })
            }
        }
    }
    
    private var amortizationScheduleView: some View {
        NavigationView {
            List {
                ForEach(amortizationSchedule) { payment in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Payment \(payment.paymentNumber)")
                                .font(.headline)
                            Spacer()
                            Text(Formatters.formatDate(payment.date))
                                .font(.caption)
                        }
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Principal: \(Formatters.formatCurrency(payment.principal))")
                                    .foregroundColor(.primary)
                                Text("Interest: \(Formatters.formatCurrency(payment.interest))")
                                    .foregroundColor(.red)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text("Paid: \(Formatters.formatPercent(payment.principalToDatePercentage))")
                                    .foregroundColor(.green)
                                Text("Balance: \(Formatters.formatCurrency(payment.remainingBalance))")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Amortization Schedule")
        }
    }
    
    private var comparisonView: some View {
        NavigationView {
            VStack {
                if comparisonScenario == nil {
                    VStack(spacing: 20) {
                        Text("No Comparison Scenario Selected")
                            .font(.headline)
                        
                        Button("Select Scenario to Compare") {
                            showingScenarioSelector = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemGroupedBackground))
                } else if let comparison = comparisonScenario, !comparisonSchedule.isEmpty {
                    Form {
                        Section(header: Text("Current vs Comparison")) {
                            HStack {
                                Text("Current")
                                Spacer()
                                Text(currentScenario.wrappedValue.name)
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Text("Comparison")
                                Spacer()
                                Text(comparison.name)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Section(header: Text("Payment Comparison")) {
                            ComparisonRow(
                                label: "Payment",
                                value1: currentScenario.wrappedValue.effectivePayment,
                                value2: comparison.effectivePayment
                            )
                            
                            ComparisonRow(
                                label: "Loan Term",
                                value1: Double(amortizationSchedule.count) / Double(PaymentFrequency(rawValue: currentScenario.wrappedValue.paymentFrequency)?.paymentsPerYear ?? 12),
                                value2: Double(comparisonSchedule.count) / Double(PaymentFrequency(rawValue: comparison.paymentFrequency)?.paymentsPerYear ?? 12),
                                format: .years
                            )
                            
                            ComparisonRow(
                                label: "Total Interest",
                                value1: amortizationSchedule.last?.interestToDate ?? 0,
                                value2: comparisonSchedule.last?.interestToDate ?? 0
                            )
                            
                            ComparisonRow(
                                label: "Total Cost",
                                value1: currentScenario.wrappedValue.loanAmount + (amortizationSchedule.last?.interestToDate ?? 0),
                                value2: comparison.loanAmount + (comparisonSchedule.last?.interestToDate ?? 0)
                            )
                        }
                        
                        Section(header: Text("Savings with Better Scenario")) {
                            let (timeSaved, interestSaved) = MortgageCalculator.calculateSavings(
                                baseScenario: (amortizationSchedule.last?.interestToDate ?? 0) > (comparisonSchedule.last?.interestToDate ?? 0) ? currentScenario.wrappedValue : comparison,
                                comparisonScenario: (amortizationSchedule.last?.interestToDate ?? 0) > (comparisonSchedule.last?.interestToDate ?? 0) ? comparison : currentScenario.wrappedValue
                            )
                            
                            SavingsRow(label: "Time Saved", value: timeSaved, format: .years)
                            SavingsRow(label: "Interest Saved", value: interestSaved, format: .currency)
                        }
                        
                        Section {
                            Button("Clear Comparison") {
                                comparisonScenario = nil
                                comparisonSchedule = []
                            }
                            .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("Scenario Comparison")
            .actionSheet(isPresented: $showingScenarioSelector) {
                CustomActionButton(title: "Select Scenario to Compare", role: nil, action: {
                    showingScenarioSelector = true
                })
            }
        }
    }
    
    private var comparisonSelectButtons: [CustomActionButton] {
        var buttons: [CustomActionButton] = scenarioStore.scenarios
            .filter { $0.id != currentScenario.wrappedValue.id }
            .map { scenario in
                CustomActionButton(title: scenario.name, role: nil, action: {
                    comparisonScenario = scenario
                    comparisonSchedule = MortgageCalculator.calculateAmortizationSchedule(scenario: scenario)
                })
            }
        
        buttons.append(CustomActionButton(title: "Cancel", role: .cancel, action: nil))
        
        return buttons
    }
    
    private var settingsView: some View {
        NavigationView {
            Form {
                Section(header: Text("Appearance")) {
                    Picker("Color Scheme", selection: $colorScheme) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("Scenarios")) {
                    ForEach(scenarioStore.scenarios) { scenario in
                        HStack {
                            Text(scenario.name)
                            Spacer()
                            if scenario.id == currentScenario.wrappedValue.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            scenarioStore.deleteScenario(scenarioStore.scenarios[index])
                        }
                    }
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
    
    private func calculateSchedule() {
        amortizationSchedule = MortgageCalculator.calculateAmortizationSchedule(scenario: currentScenario.wrappedValue)
    }
    
    private func exportCSV() {
        #if os(iOS)
        if let fileURL = ExportManager.exportToCSV(scenario: currentScenario.wrappedValue, payments: amortizationSchedule) {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootViewController = windowScene.windows.first?.rootViewController else {
                return
            }
            
            ExportManager.shareFile(at: fileURL, from: rootViewController)
        }
        #else
        // macOS implementation would go here
        print("CSV export not implemented for macOS")
        #endif
    }
    
    private func exportPDF() {
        pdfData = ExportManager.generatePDFReport(scenario: currentScenario.wrappedValue, payments: amortizationSchedule)
        showingPDFPreview = true
    }
    
    private func getColorScheme() -> ColorScheme? {
        switch colorScheme {
        case "light":
            return .light
        case "dark":
            return .dark
        default:
            return nil
        }
    }
    
    private var balanceBreakdownChart: some View {
        Chart {
            let sampleInterval = max(1, amortizationSchedule.count / 20)
            let sampledData = stride(from: 0, to: amortizationSchedule.count, by: sampleInterval).map { amortizationSchedule[$0] }
            
            ForEach(sampledData) { payment in
                AreaMark(
                    x: .value("Payment", payment.paymentNumber),
                    y: .value("Principal Paid", currentScenario.wrappedValue.loanAmount - payment.remainingBalance)
                )
                .foregroundStyle(Color.green.gradient)
                
                AreaMark(
                    x: .value("Payment", payment.paymentNumber),
                    y: .value("Remaining Balance", payment.remainingBalance),
                    stacking: .normalized
                )
                .foregroundStyle(Color.red.gradient)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisValueLabel {
                    Text("Balance")
                        .font(.caption)
                }
            }
        }
        .chartForegroundStyleScale([
            "Principal Paid": .green,
            "Remaining Balance": .red
        ])
        .chartLegend(position: .bottom)
    }
    
    private func firstPaymentPieChart(_ payment: PaymentDetails) -> some View {
        Chart {
            SectorMark(
                angle: .value("Interest", payment.interest),
                innerRadius: .ratio(0.6),
                angularInset: 1.5
            )
            .cornerRadius(3)
            .foregroundStyle(.red)
            .annotation(position: .overlay) {
                Text("\(Int(payment.interest / payment.totalPayment * 100))%")
                    .font(.caption)
                    .foregroundColor(.white)
                    .fontWeight(.bold)
            }
            
            SectorMark(
                angle: .value("Principal", payment.principal),
                innerRadius: .ratio(0.6),
                angularInset: 1.5
            )
            .cornerRadius(3)
            .foregroundStyle(.green)
            .annotation(position: .overlay) {
                Text("\(Int(payment.principal / payment.totalPayment * 100))%")
                    .font(.caption)
                    .foregroundColor(.white)
                    .fontWeight(.bold)
            }
        }
        .chartLegend(position: .bottom) {
            HStack(spacing: 16) {
                HStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.green)
                        .frame(width: 16, height: 16)
                    Text("Principal")
                        .font(.caption)
                }
                
                HStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.red)
                        .frame(width: 16, height: 16)
                    Text("Interest")
                        .font(.caption)
                }
            }
        }
    }
}

struct ComparisonRow: View {
    let label: String
    let value1: Double
    let value2: Double
    let format: ValueFormat
    
    enum ValueFormat {
        case currency
        case years
        case percent
    }
    
    init(label: String, value1: Double, value2: Double, format: ValueFormat = .currency) {
        self.label = label
        self.value1 = value1
        self.value2 = value2
        self.format = format
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(label)
                .font(.headline)
                .padding(.bottom, 2)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Current")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    formatValue(value1)
                }
                
                Spacer()
                
                Text(difference > 0 ? "↑" : "↓")
                    .foregroundColor(getColor())
                    .font(.title2)
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Comparison")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    formatValue(value2)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private var difference: Double {
        value1 - value2
    }
    
    private func getColor() -> Color {
        switch format {
        case .currency, .years:
            return difference > 0 ? .red : .green
        case .percent:
            return difference > 0 ? .green : .red
        }
    }
    
    private func formatValue(_ value: Double) -> some View {
        switch format {
        case .currency:
            return Text(Formatters.formatCurrency(value))
        case .years:
            return Text(String(format: "%.1f years", value))
        case .percent:
            return Text(Formatters.formatPercent(value))
        }
    }
}

struct SavingsRow: View {
    let label: String
    let value: Double
    let format: ValueFormat
    
    enum ValueFormat {
        case currency
        case years
        case percent
    }
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            switch format {
            case .currency:
                Text(Formatters.formatCurrency(value))
                    .foregroundColor(.green)
                    .bold()
            case .years:
                Text(String(format: "%.1f years", value))
                    .foregroundColor(.green)
                    .bold()
            case .percent:
                Text(Formatters.formatPercent(value))
                    .foregroundColor(.green)
                    .bold()
            }
        }
    }
}

// MARK: - PDFPreview for iOS or macOS
#if os(iOS)
struct PDFPreview: PlatformViewControllerRepresentable {
    let data: Data
    
    func makeUIViewController(context: Context) -> PlatformViewController {
        let pdfView = PDFView()
        pdfView.document = PDFDocument(data: data)
        pdfView.autoScales = true
        
        let viewController = PlatformViewController()
        viewController.view = pdfView
        viewController.navigationItem.rightBarButtonItem = PlatformBarButtonItem(
            barButtonSystemItem: .action,
            target: context.coordinator,
            action: #selector(Coordinator.share(_:))
        )
        
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: PlatformViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        let parent: PDFPreview
        
        init(_ parent: PDFPreview) {
            self.parent = parent
        }
        
        @objc func share(_ sender: PlatformBarButtonItem) {
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("mortgage_report.pdf")
            
            do {
                try parent.data.write(to: tempURL)
                
                let activityViewController = PlatformActivityViewController(
                    activityItems: [tempURL],
                    applicationActivities: nil
                )
                
                if let sourceView = sender.value(forKey: "view") as? PlatformView {
                    activityViewController.popoverPresentationController?.sourceView = sourceView
                }
                
                UIApplication.shared.windows.first?.rootViewController?.present(
                    activityViewController,
                    animated: true,
                    completion: nil
                )
                
            } catch {
                print("Error creating PDF file: \(error)")
            }
        }
    }
}
#else
// Simple macOS implementation
struct PDFPreview: View {
    let data: Data
    
    var body: some View {
        Text("PDF Preview not implemented for macOS")
    }
}
#endif

// Extended model implementations for cross-platform compatibility
extension MortgageScenario: Equatable {
    static func == (lhs: MortgageScenario, rhs: MortgageScenario) -> Bool {
        lhs.id == rhs.id
    }
}

// Platform-specific UI components and behaviors
#if os(iOS)
import UIKit

// iOS-specific UI constants and types
typealias ActionSheet = UIAlertController
extension Color {
    static let systemGroupedBackground = Color(UIColor.systemGroupedBackground)
}

// iOS-specific UI modifiers
extension View {
    func keyboardType(_ type: UIKeyboardType) -> some View {
        self // Mock implementation for compiler
    }
    
    func multilineTextAlignment(_ alignment: TextAlignment) -> some View {
        self // Mock implementation for compiler
    }
    
    func customActionSheet(isPresented: Binding<Bool>, content: @escaping () -> ActionSheet) -> some View {
        self.actionSheet(isPresented: isPresented, content: content)
    }
}

#elseif os(macOS)
import AppKit

// macOS-specific UI constants and types
extension Color {
    static let systemGroupedBackground = Color.secondary.opacity(0.2)
}

// macOS-specific UI modifiers
extension View {
    // Stubs for iOS-specific modifiers
    func keyboardType(_ type: Int) -> some View {
        self // No-op for macOS
    }
    
    func multilineTextAlignment(_ alignment: TextAlignment) -> some View {
        self // Mapping to macOS equivalent would go here
    }
    
    // macOS uses different APIs for sheets/popovers
    func customActionSheet(isPresented: Binding<Bool>, content: @escaping () -> ActionSheet) -> some View {
        self.popover(isPresented: isPresented) {
            VStack(spacing: 10) {
                content().title
                if let message = content().message {
                    message
                }
                ForEach(0..<content().buttons.count, id: \.self) { index in
                    let button = content().buttons[index]
                    Button {
                        isPresented.wrappedValue = false
                        button.action?()
                    } label: {
                        button.label
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(button.role == .destructive ? .red : nil)
                }
            }
            .padding()
            .frame(width: 300)
        }
    }
}

// macOS equivalent would be different
enum UIKeyboardType {
    case decimalPad
}
#endif

// TextAlignment is shared between platforms but defined differently
extension TextAlignment {
    static var trailing: TextAlignment { .trailing }
} 