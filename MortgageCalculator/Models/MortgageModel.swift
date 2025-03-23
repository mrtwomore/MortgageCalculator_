import Foundation

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

struct MortgageScenario: Identifiable, Codable {
    var id = UUID()
    var name: String = "Default Scenario"
    var loanAmount: Double
    var interestRate: Double
    var loanTermYears: Double
    var loanType: LoanType.RawValue
    var paymentFrequency: PaymentFrequency.RawValue
    var lumpSumPayments: [LumpSumPayment] = []
    var additionalPayment: Double = 0
    
    var effectivePayment: Double {
        return regularPayment + additionalPayment
    }
    
    var regularPayment: Double {
        let frequency = PaymentFrequency(rawValue: paymentFrequency) ?? .monthly
        return MortgageCalculator.calculatePayment(
            loanAmount: loanAmount, 
            annualInterestRate: interestRate, 
            loanTermYears: loanTermYears,
            frequency: frequency
        )
    }
}

struct LumpSumPayment: Identifiable, Codable {
    var id = UUID()
    var amount: Double
    var paymentDate: Date
    var paymentNumber: Int
    
    init(amount: Double, paymentNumber: Int) {
        self.amount = amount
        self.paymentNumber = paymentNumber
        self.paymentDate = Date()
    }
}

struct PaymentDetails: Identifiable {
    var id = UUID()
    let paymentNumber: Int
    let principal: Double
    let interest: Double
    let totalPayment: Double
    let remainingBalance: Double
    let date: Date
    
    var principalToDatePercentage: Double = 0
    var interestToDate: Double = 0
} 