import Foundation

struct MortgageRequest: Codable {
    let loanAmount: Double
    let interestRate: Double
    let loanTerm: Double
    let paymentFrequency: PaymentFrequency
    let additionalPayment: Double?
    let lumpSumPayment: Double?
}

struct MortgageResponse: Codable {
    let monthlyPayment: Double
    let totalInterest: Double
    let totalPayment: Double
    let amortizationSchedule: [PaymentDetails]
}

struct RatesResponse: Codable {
    let lastUpdated: Date
    let rates: [LenderRate]
}

struct LenderRate: Codable {
    let lenderName: String
    let fixedRates: [Rate]
    let variableRates: [Rate]
}

struct Rate: Codable {
    let term: Int
    let rate: Double
    let apr: Double
    let type: RateType
}

enum RateType: String, Codable {
    case fixed = "FIXED"
    case variable = "VARIABLE"
} 