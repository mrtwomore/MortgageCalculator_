import Foundation
import SwiftUI

// Re-export all our models
@_exported import struct MortgageCalculator.MortgageScenario
@_exported import struct MortgageCalculator.PaymentDetails
@_exported import struct MortgageCalculator.LumpSumPayment
@_exported import enum MortgageCalculator.LoanType
@_exported import enum MortgageCalculator.PaymentFrequency

// Re-export all our services
@_exported import class MortgageCalculator.ScenarioStore
@_exported import class MortgageCalculator.MortgageCalculator
@_exported import struct MortgageCalculator.Formatters
@_exported import struct MortgageCalculator.ExportManager

// Re-export all our views
@_exported import struct MortgageCalculator.LumpSumPaymentsView
@_exported import struct MortgageCalculator.MortgageChartView

// This is a module file that ensures all components are properly exported
// and available throughout the app. In a real project, this would be done
// through proper module organization. 