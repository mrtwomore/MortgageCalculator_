import Foundation

struct Formatters {
    static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }()
    
    static let percentFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }()
    
    static let decimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        return formatter
    }()
    
    static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
    
    static let mediumDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    static func formatCurrency(_ value: Double) -> String {
        return currencyFormatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
    
    static func formatPercent(_ value: Double) -> String {
        return percentFormatter.string(from: NSNumber(value: value / 100.0)) ?? "0%"
    }
    
    static func formatDecimal(_ value: Double) -> String {
        return decimalFormatter.string(from: NSNumber(value: value)) ?? "0"
    }
    
    static func formatDate(_ date: Date, style: DateFormatter.Style = .medium) -> String {
        switch style {
        case .short:
            return shortDateFormatter.string(from: date)
        default:
            return mediumDateFormatter.string(from: date)
        }
    }
} 