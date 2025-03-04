import Foundation

struct PaymentDetails {
    let principal: Double
    let interest: Double
    let totalPayment: Double
    let remainingBalance: Double
}

class MortgageCalculator {
    static func calculateMonthlyPayment(loanAmount: Double, annualInterestRate: Double, loanTermYears: Double) -> Double {
        let monthlyInterestRate = annualInterestRate / 12.0 / 100.0
        let numberOfPayments = loanTermYears * 12
        
        let denominator = pow(1 + monthlyInterestRate, numberOfPayments) - 1
        let monthlyPayment = loanAmount * (monthlyInterestRate * pow(1 + monthlyInterestRate, numberOfPayments)) / denominator
        
        return monthlyPayment
    }
    
    static func calculateAmortizationSchedule(loanAmount: Double, annualInterestRate: Double, loanTermYears: Double) -> [PaymentDetails] {
        var schedule: [PaymentDetails] = []
        let monthlyPayment = calculateMonthlyPayment(loanAmount: loanAmount, annualInterestRate: annualInterestRate, loanTermYears: loanTermYears)
        let monthlyInterestRate = annualInterestRate / 12.0 / 100.0
        var remainingBalance = loanAmount
        
        for _ in 1...Int(loanTermYears * 12) {
            let interestPayment = remainingBalance * monthlyInterestRate
            let principalPayment = monthlyPayment - interestPayment
            remainingBalance -= principalPayment
            
            let payment = PaymentDetails(
                principal: principalPayment,
                interest: interestPayment,
                totalPayment: monthlyPayment,
                remainingBalance: remainingBalance
            )
            schedule.append(payment)
        }
        
        return schedule
    }
} 