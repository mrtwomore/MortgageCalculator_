import Foundation

public enum PaymentFrequency: String {
    case weekly
    case biweekly
    case monthly
    
    public var paymentsPerYear: Int {
        switch self {
        case .weekly: return 52
        case .biweekly: return 26
        case .monthly: return 12
        }
    }
}

public struct LumpSumPayment {
    public let paymentNumber: Int
    public let amount: Double
    
    public init(paymentNumber: Int, amount: Double) {
        self.paymentNumber = paymentNumber
        self.amount = amount
    }
}

public struct MortgageScenario {
    public let loanAmount: Double
    public let interestRate: Double
    public let loanTermYears: Double
    public let paymentFrequency: PaymentFrequency
    public let regularPayment: Double
    public let effectivePayment: Double
    public let lumpSumPayments: [LumpSumPayment]
    
    public init(loanAmount: Double, 
         interestRate: Double, 
         loanTermYears: Double, 
         paymentFrequency: PaymentFrequency = .monthly, 
         regularPayment: Double, 
         effectivePayment: Double? = nil, 
         lumpSumPayments: [LumpSumPayment] = []) {
        self.loanAmount = loanAmount
        self.interestRate = interestRate
        self.loanTermYears = loanTermYears
        self.paymentFrequency = paymentFrequency
        self.regularPayment = regularPayment
        self.effectivePayment = effectivePayment ?? regularPayment
        self.lumpSumPayments = lumpSumPayments
    }
}

public struct PaymentDetails {
    public let paymentNumber: Int
    public let principal: Double
    public let interest: Double
    public let totalPayment: Double
    public let remainingBalance: Double
    public let date: Date
    public let principalToDatePercentage: Double
    public let interestToDate: Double
    
    public init(
        paymentNumber: Int,
        principal: Double,
        interest: Double,
        totalPayment: Double,
        remainingBalance: Double,
        date: Date,
        principalToDatePercentage: Double,
        interestToDate: Double
    ) {
        self.paymentNumber = paymentNumber
        self.principal = principal
        self.interest = interest
        self.totalPayment = totalPayment
        self.remainingBalance = remainingBalance
        self.date = date
        self.principalToDatePercentage = principalToDatePercentage
        self.interestToDate = interestToDate
    }
} 