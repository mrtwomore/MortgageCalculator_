import Foundation
import UniformTypeIdentifiers

// Model structures for the Mortgage Calculator app

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
    var loanAmount: Double
    var interestRate: Double
    var loanTerm: Double
    var paymentFrequency: String
    var additionalPayment: Double
    var createdDate: Date
    
    static func == (lhs: SavedScenario, rhs: SavedScenario) -> Bool {
        return lhs.id == rhs.id
    }
}

// Payment period in the amortization schedule
struct PaymentPeriod: Identifiable {
    let id: Int
    let periodNumber: Int
    let payment: Double
    let principalPayment: Double
    let interestPayment: Double
    let remainingBalance: Double
    let totalInterestPaid: Double
    let annualInterest: Double
    let percentagePaid: Double
    let year: Int
    
    var totalPrincipalPaid: Double {
        return payment * Double(periodNumber) - totalInterestPaid
    }
}

// Summary of yearly payment data for charts
struct YearlySummary: Identifiable {
    var id = UUID()
    var year: Int
    var remainingBalance: Double
    var principalPaid: Double
    var interestPaid: Double
    
    var totalPaid: Double {
        principalPaid + interestPaid
    }
}

// Comparison scenario for payment increase analysis
struct ComparisonScenario: Identifiable {
    var id: UUID = UUID()
    let increasePercentage: Double
    let newPayment: Double
    let yearsToPay: Double
    let interestSavings: Double
    let timeSaved: Double
    let totalPaid: Double
    let totalSaved: Double
}

// Result of mortgage calculation
struct CalculationResult {
    let periodicPayment: Double
    let totalInterest: Double
    let totalCost: Double
    let amortizationSchedule: [PaymentPeriod]
    let comparisonScenarios: [ComparisonScenario]
    let additionalPaymentScenario: ComparisonScenario?
}

// Payment frequencies enum with constant values
enum PaymentFrequencies {
    // Dictionary mapping payment frequencies to payments per year
    static let frequencies: [String: Int] = [
        "Weekly": 52,
        "Fortnightly": 26,
        "Monthly": 12
    ]
} 