# Technical Documentation

## Core Calculations

### Monthly Payment Calculation
The monthly payment is calculated using the standard mortgage payment formula:
```
M = P * (r * (1 + r)^n) / ((1 + r)^n - 1)

Where:
M = Monthly Payment
P = Principal (Loan Amount)
r = Monthly Interest Rate (Annual Rate / 12)
n = Total Number of Payments (Years * 12)
```

### Amortization Schedule
Each payment is broken down into:
- Principal Payment
- Interest Payment
- Remaining Balance

The process for each payment:
1. Calculate interest: Balance * Monthly Rate
2. Calculate principal: Monthly Payment - Interest
3. Update balance: Previous Balance - Principal Payment

## Data Models

### PaymentDetails
```swift
struct PaymentDetails {
    let principal: Double      // Principal portion of payment
    let interest: Double      // Interest portion of payment
    let totalPayment: Double  // Total payment amount
    let remainingBalance: Double // Remaining loan balance
}
```

### MortgageScenario
```swift
struct MortgageScenario: Codable, Identifiable {
    let id: UUID
    var loanAmount: Double
    var interestRate: Double
    var loanTerm: Double
    var paymentFrequency: PaymentFrequency
    var additionalPayment: Double
    var lumpSumPayment: Double
    var offsetAmount: Double
}
```

### PaymentFrequency
```swift
enum PaymentFrequency: String, Codable {
    case weekly = "Weekly"
    case biweekly = "Bi-weekly"
    case monthly = "Monthly"
    
    var paymentsPerYear: Int {
        switch self {
        case .weekly: return 52
        case .biweekly: return 26
        case .monthly: return 12
        }
    }
}
```

## View Structure

### InputView
- Form-based input for mortgage details
- Input validation and formatting
- Real-time calculation updates

### ResultsView
- Payment summary display
- Interactive payment adjustment slider
- Payment increase scenarios
- Export options

### AmortizationView
- Scrollable table of payment schedule
- Column sorting options
- Search/filter capabilities
- Pagination for performance

## Data Export

### CSV Format
```csv
Payment #,Date,Payment Amount,Principal,Interest,Remaining Balance,Total Interest Paid
1,2024-03-01,2684.11,600.78,2083.33,499399.22,2083.33
2,2024-04-01,2684.11,603.28,2080.83,498795.94,4164.16
```

### PDF Report Sections
1. Loan Summary
   - Loan details
   - Payment summary
   - Total costs

2. Payment Scenarios
   - Base scenario
   - Increased payment scenarios
   - Savings comparison

3. Amortization Schedule
   - Monthly breakdown
   - Running totals
   - Visual charts

## State Management

### ScenarioStore
- Manages saved scenarios
- Handles persistence
- Provides CRUD operations

### UserDefaults Storage
```swift
// Save scenario
func saveScenario(_ scenario: MortgageScenario) {
    var scenarios = loadScenarios()
    scenarios.append(scenario)
    if let encoded = try? JSONEncoder().encode(scenarios) {
        UserDefaults.standard.set(encoded, forKey: "savedScenarios")
    }
}
```

## Performance Considerations

1. Amortization Table
   - Lazy loading for large schedules
   - Pagination (20-50 items per page)
   - Cache calculations

2. Real-time Updates
   - Debounce user input
   - Batch updates
   - Background calculation for complex scenarios

3. Export Operations
   - Asynchronous processing
   - Progress indication
   - Background thread execution

## Testing Strategy

1. Unit Tests
   - Core calculations
   - Data model validation
   - State management

2. UI Tests
   - Input validation
   - Navigation flow
   - Export functionality

3. Performance Tests
   - Large loan terms
   - Multiple scenarios
   - Export operations 