# Mortgage Calculator iOS App

A comprehensive mortgage calculator that helps users understand their mortgage payments, amortization schedule, and the impact of payment adjustments.

## Features

### Core Features
- [x] Basic mortgage calculation
- [x] Monthly payment breakdown
- [x] Simple amortization schedule

### Planned Features
- [ ] Enhanced Input Options
  - [ ] Loan type selection (Fixed Rate, Variable)
  - [ ] Payment frequency (Weekly, Bi-weekly, Monthly)
  - [ ] Lump sum payments
  - [ ] Offset account integration
  
- [ ] Advanced Calculations
  - [ ] Payment adjustment calculator with slider
  - [ ] Multiple payment increase scenarios (10%, 25%, 50%)
  - [ ] Interest savings calculations
  - [ ] Time savings projections

- [ ] Detailed Amortization Schedule
  - [ ] Payment number tracking
  - [ ] Principal vs Interest breakdown
  - [ ] Running total of interest paid
  - [ ] Percentage of loan paid
  - [ ] Remaining balance tracking

- [ ] Export and Save Features
  - [ ] Export to CSV
  - [ ] Download PDF reports
  - [ ] Save scenarios
  - [ ] Load saved scenarios

- [ ] User Interface
  - [ ] Dark/Light mode support
  - [ ] Interactive payment adjustment slider
  - [ ] Responsive design
  - [ ] User authentication
  - [ ] Scenario comparison view

## Technical Requirements
- iOS 15.0+
- Xcode 13.0+
- Swift 5.5+
- SwiftUI 3.0+

## Installation

1. Clone the repository:
```bash
git clone https://github.com/mrtwomore/MortgageCalculator.git
```

2. Open the project in Xcode:
```bash
cd MortgageCalculator
open MortgageCalculator.xcodeproj
```

3. Build and run the project in Xcode

## Project Structure

```
MortgageCalculator/
├── Models/
│   ├── MortgageCalculator.swift     # Core calculation logic
│   ├── PaymentDetails.swift         # Payment data structures
│   └── ScenarioStore.swift          # Scenario management
├── Views/
│   ├── ContentView.swift            # Main view
│   ├── InputView.swift             # Input form view
│   ├── ResultsView.swift           # Results display
│   └── AmortizationView.swift      # Amortization schedule
└── Utilities/
    ├── Formatters.swift            # Number and currency formatting
    └── ExportManager.swift         # Export functionality
```

## Usage

1. Enter mortgage details:
   - Principal amount
   - Interest rate
   - Loan term
   - Payment frequency

2. View instant calculations:
   - Monthly/weekly payment amount
   - Total interest over loan term
   - Total cost of the mortgage

3. Explore payment scenarios:
   - Adjust payment amounts
   - See impact on loan term
   - Calculate interest savings

4. Export and save:
   - Download detailed amortization schedule
   - Save scenarios for later reference
   - Generate PDF reports

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details 