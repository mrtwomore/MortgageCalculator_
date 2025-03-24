import Foundation
import SwiftUI

// This is a module file that acts as a central point for importing components.
// Instead of using @_exported which requires module setup, we'll directly define
// our types in the appropriate files and import them normally.

// Note: In a production app, you would organize these into proper Swift modules
// with Package.swift, but for simplicity we're using a flat structure.

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