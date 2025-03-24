import Foundation
import SwiftUI

public class MortgageCalculator {
    public static func calculatePayment(loanAmount: Double, annualInterestRate: Double, loanTermYears: Double, frequency: PaymentFrequency = .monthly) -> Double {
        let periodicInterestRate = annualInterestRate / Double(frequency.paymentsPerYear) / 100.0
        let numberOfPayments = loanTermYears * Double(frequency.paymentsPerYear)
        
        let denominator = pow(1 + periodicInterestRate, numberOfPayments) - 1
        let payment = loanAmount * (periodicInterestRate * pow(1 + periodicInterestRate, numberOfPayments)) / denominator
        
        return payment
    }
    
    public static func calculateAmortizationSchedule(scenario: MortgageScenario) -> [PaymentDetails] {
        var schedule: [PaymentDetails] = []
        let frequency = scenario.paymentFrequency
        let regularPayment = scenario.regularPayment
        let effectivePayment = scenario.effectivePayment
        let periodicInterestRate = scenario.interestRate / Double(frequency.paymentsPerYear) / 100.0
        let numberOfPayments = Int(scenario.loanTermYears * Double(frequency.paymentsPerYear))
        
        var remainingBalance = scenario.loanAmount
        var totalInterestPaid = 0.0
        let startDate = Date()
        
        // Sort lump sum payments by payment number
        let sortedLumpSums = scenario.lumpSumPayments.sorted(by: { $0.paymentNumber < $1.paymentNumber })
        var lumpSumIndex = 0
        
        for paymentNumber in 1...numberOfPayments {
            // Calculate payment date based on frequency
            let dateComponent: DateComponents
            switch frequency {
            case .weekly:
                dateComponent = DateComponents(day: 7 * paymentNumber)
            case .biweekly:
                dateComponent = DateComponents(day: 14 * paymentNumber)
            case .monthly:
                dateComponent = DateComponents(month: paymentNumber)
            }
            let paymentDate = Calendar.current.date(byAdding: dateComponent, to: startDate) ?? startDate
            
            // Apply any lump sum payments that occur at this payment number
            var lumpSumAmount = 0.0
            while lumpSumIndex < sortedLumpSums.count && sortedLumpSums[lumpSumIndex].paymentNumber == paymentNumber {
                lumpSumAmount += sortedLumpSums[lumpSumIndex].amount
                lumpSumIndex += 1
            }
            
            // Calculate interest for this period
            let interestPayment = remainingBalance * periodicInterestRate
            
            // Calculate principal with effective payment (regular + additional)
            var principalPayment = effectivePayment - interestPayment
            
            // Add lump sum to principal payment
            principalPayment += lumpSumAmount
            
            // Ensure we don't overpay
            if principalPayment > remainingBalance {
                principalPayment = remainingBalance
            }
            
            // Update remaining balance
            remainingBalance -= principalPayment
            
            // Update total interest paid
            totalInterestPaid += interestPayment
            
            // Calculate percentage of loan paid
            let principalToDatePercentage = (scenario.loanAmount - remainingBalance) / scenario.loanAmount * 100
            
            // Create payment details
            let payment = PaymentDetails(
                paymentNumber: paymentNumber,
                principal: principalPayment,
                interest: interestPayment,
                totalPayment: principalPayment + interestPayment,
                remainingBalance: remainingBalance,
                date: paymentDate,
                principalToDatePercentage: principalToDatePercentage,
                interestToDate: totalInterestPaid
            )
            schedule.append(payment)
            
            // If balance is zero, we've paid off the loan
            if remainingBalance <= 0.01 {
                break
            }
        }
        
        return schedule
    }
    
    public static func calculateSavings(baseScenario: MortgageScenario, comparisonScenario: MortgageScenario) -> (timeSaved: Double, interestSaved: Double) {
        let baseSchedule = calculateAmortizationSchedule(scenario: baseScenario)
        let comparisonSchedule = calculateAmortizationSchedule(scenario: comparisonScenario)
        
        let basePaymentCount = baseSchedule.count
        let comparisonPaymentCount = comparisonSchedule.count
        
        let baseFrequency = baseScenario.paymentFrequency
        let comparisonFrequency = comparisonScenario.paymentFrequency
        
        // Calculate time saved
        let timeSaved = Double(basePaymentCount) / Double(baseFrequency.paymentsPerYear) - Double(comparisonPaymentCount) / Double(comparisonFrequency.paymentsPerYear)
        
        // Calculate total interest for both scenarios
        let baseTotalInterest = baseSchedule.last?.interestToDate ?? 0
        let comparisonTotalInterest = comparisonSchedule.last?.interestToDate ?? 0
        
        // Calculate interest saved
        let interestSaved = baseTotalInterest - comparisonTotalInterest
        
        return (timeSaved: timeSaved, interestSaved: interestSaved)
    }
} 