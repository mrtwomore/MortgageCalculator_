import Foundation

// Service class for mortgage calculations
class MortgageCalculatorService {
    
    // MARK: - Singleton
    static let shared = MortgageCalculatorService()
    
    // Private initializer to enforce singleton
    private init() {}
    
    // MARK: - Public Methods
    
    /// Calculate the complete mortgage result including payments, schedules and comparison scenarios
    func calculateMortgage(
        loanAmount: Double,
        interestRate: Double,
        loanTerm: Double,
        frequency: String,
        additionalPayment: Double
    ) -> CalculationResult {
        // Calculate basic payment
        let basePayment = calculatePeriodicPayment(
            loanAmount: loanAmount,
            interestRate: interestRate,
            loanTerm: loanTerm,
            frequency: frequency
        )
        
        // Generate amortization schedule
        let schedule = generateAmortizationSchedule(
            loanAmount: loanAmount,
            interestRate: interestRate,
            loanTerm: loanTerm,
            frequency: frequency
        )
        
        let totalInterest = schedule.last?.totalInterestPaid ?? 0
        
        // Calculate additional payment scenario if provided
        var additionalPaymentResult: ComparisonScenario? = nil
        if additionalPayment > 0 {
            additionalPaymentResult = calculateAdditionalPaymentScenario(
                loanAmount: loanAmount,
                interestRate: interestRate,
                loanTerm: loanTerm,
                frequency: frequency,
                basePayment: basePayment,
                additionalPayment: additionalPayment,
                baseTotalInterest: totalInterest
            )
        }
        
        // Calculate comparison scenarios
        let scenarios = calculateComparisonScenarios(
            loanAmount: loanAmount,
            interestRate: interestRate,
            loanTerm: loanTerm,
            frequency: frequency,
            basePayment: basePayment,
            baseTotalInterest: totalInterest
        )
        
        return CalculationResult(
            periodicPayment: basePayment,
            totalInterest: totalInterest,
            totalCost: loanAmount + totalInterest,
            amortizationSchedule: schedule,
            comparisonScenarios: scenarios,
            additionalPaymentScenario: additionalPaymentResult
        )
    }
    
    /// Calculates the periodic payment for a mortgage loan
    func calculatePeriodicPayment(
        loanAmount: Double,
        interestRate: Double,
        loanTerm: Double,
        frequency: String
    ) -> Double {
        // Get number of payments per year
        let paymentsPerYear = Double(PaymentFrequencies.frequencies[frequency] ?? 12)
        
        // Convert annual rate to periodic rate
        let periodicRate = (interestRate / 100) / paymentsPerYear
        
        // Calculate number of payments
        let numberOfPayments = loanTerm * paymentsPerYear
        
        // Calculate periodic payment using the loan payment formula
        // P = (L * r * (1 + r)^n) / ((1 + r)^n - 1)
        let powerFactor = pow(1 + periodicRate, numberOfPayments)
        let numerator = loanAmount * periodicRate * powerFactor
        let denominator = powerFactor - 1
        
        return numerator / denominator
    }
    
    // MARK: - Private Methods
    
    /// Generate amortization schedule with standard payment
    private func generateAmortizationSchedule(
        loanAmount: Double,
        interestRate: Double,
        loanTerm: Double,
        frequency: String
    ) -> [PaymentPeriod] {
        // Get number of payments per year
        let paymentsPerYear = Double(PaymentFrequencies.frequencies[frequency] ?? 12)
        
        // Convert annual rate to periodic rate
        let periodicRate = (interestRate / 100) / paymentsPerYear
        
        // Calculate periodic payment
        let payment = calculatePeriodicPayment(
            loanAmount: loanAmount, 
            interestRate: interestRate, 
            loanTerm: loanTerm, 
            frequency: frequency
        )
        
        return generateSchedule(
            loanAmount: loanAmount,
            periodicRate: periodicRate,
            payment: payment,
            numberOfPayments: Int(loanTerm * paymentsPerYear),
            paymentsPerYear: paymentsPerYear
        )
    }
    
    /// Generate amortization schedule with a fixed payment amount
    private func generateScheduleWithFixedPayment(
        loanAmount: Double,
        interestRate: Double,
        loanTerm: Double,
        frequency: String,
        fixedPayment: Double
    ) -> [PaymentPeriod] {
        // Get number of payments per year
        let paymentsPerYear = Double(PaymentFrequencies.frequencies[frequency] ?? 12)
        
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
        
        // For fixed payment, we don't know the exact number of payments upfront
        // We'll set a reasonable maximum and break the loop when balance reaches zero
        let maxPayments = Int(loanTerm * paymentsPerYear * 2)
        
        return generateSchedule(
            loanAmount: loanAmount,
            periodicRate: periodicRate,
            payment: payment,
            numberOfPayments: maxPayments,
            paymentsPerYear: paymentsPerYear,
            stopAtZeroBalance: true
        )
    }
    
    /// Core implementation of schedule generation - handles both fixed payment and standard scenarios
    private func generateSchedule(
        loanAmount: Double,
        periodicRate: Double,
        payment: Double,
        numberOfPayments: Int,
        paymentsPerYear: Double,
        stopAtZeroBalance: Bool = false
    ) -> [PaymentPeriod] {
        // Initialize values
        var schedule: [PaymentPeriod] = []
        var remainingBalance = loanAmount
        var totalInterestPaid: Double = 0
        var annualInterest: Double = 0
        var yearNumber = 1
        
        // Pre-allocate capacity to avoid reallocations
        schedule.reserveCapacity(numberOfPayments)
        
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
            
            // Stop if the loan is paid off and we're using the stop at zero option
            if remainingBalance == 0 && stopAtZeroBalance {
                break
            }
        }
        
        return schedule
    }
    
    /// Calculate the scenario for additional payments
    private func calculateAdditionalPaymentScenario(
        loanAmount: Double,
        interestRate: Double,
        loanTerm: Double,
        frequency: String,
        basePayment: Double,
        additionalPayment: Double,
        baseTotalInterest: Double
    ) -> ComparisonScenario? {
        let increasedPayment = basePayment + additionalPayment
        
        let increasedSchedule = generateScheduleWithFixedPayment(
            loanAmount: loanAmount,
            interestRate: interestRate,
            loanTerm: loanTerm,
            frequency: frequency,
            fixedPayment: increasedPayment
        )
        
        if let lastPayment = increasedSchedule.last {
            let paymentsPerYear = Double(PaymentFrequencies.frequencies[frequency] ?? 12)
            let increasedTotalInterest = lastPayment.totalInterestPaid
            let increasedYears = Double(increasedSchedule.count) / paymentsPerYear
            let interestSavings = baseTotalInterest - increasedTotalInterest
            let timeSaved = loanTerm - increasedYears
            
            return ComparisonScenario(
                increasePercentage: (additionalPayment / basePayment) * 100,
                newPayment: increasedPayment,
                yearsToPay: increasedYears,
                interestSavings: interestSavings,
                timeSaved: timeSaved,
                totalPaid: loanAmount + increasedTotalInterest,
                totalSaved: (loanAmount + baseTotalInterest) - (loanAmount + increasedTotalInterest)
            )
        }
        
        return nil
    }
    
    /// Calculate comparison scenarios for different payment increases
    private func calculateComparisonScenarios(
        loanAmount: Double,
        interestRate: Double,
        loanTerm: Double,
        frequency: String,
        basePayment: Double,
        baseTotalInterest: Double
    ) -> [ComparisonScenario] {
        let increases = [10.0, 25.0, 50.0] // Percentage increases
        var scenarios: [ComparisonScenario] = []
        let baseTotalPaid = loanAmount + baseTotalInterest
        
        // Pre-allocate capacity
        scenarios.reserveCapacity(increases.count)
        
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
                let paymentsPerYear = Double(PaymentFrequencies.frequencies[frequency] ?? 12)
                let increasedTotalInterest = lastPayment.totalInterestPaid
                let increasedYears = Double(increasedSchedule.count) / paymentsPerYear
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
    
    /// Generate yearly summary data for charts
    func generateYearlySummary(
        amortizationSchedule: [PaymentPeriod],
        frequency: String
    ) -> [YearlySummary] {
        let frequencyPerYear = Double(PaymentFrequencies.frequencies[frequency] ?? 12)
        var years: [YearlySummary] = []
        
        let yearCount = Int(ceil(Double(amortizationSchedule.count) / frequencyPerYear))
        
        // Pre-allocate capacity
        years.reserveCapacity(yearCount)
        
        for year in 1...yearCount {
            let startIndex = (year - 1) * Int(frequencyPerYear)
            let endIndex = min(startIndex + Int(frequencyPerYear) - 1, amortizationSchedule.count - 1)
            
            if startIndex < amortizationSchedule.count {
                let yearStart = amortizationSchedule[startIndex]
                let yearEnd = amortizationSchedule[endIndex]
                
                let principalPaid: Double
                let interestPaid: Double
                
                if year == 1 {
                    principalPaid = yearEnd.totalPrincipalPaid
                    interestPaid = yearEnd.totalInterestPaid
                } else {
                    let previousYearEnd = amortizationSchedule[min((year - 2) * Int(frequencyPerYear) + Int(frequencyPerYear) - 1, amortizationSchedule.count - 1)]
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
} 