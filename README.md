# Mortgage Calculator iOS App

A highly optimized mortgage calculator app for iOS that helps users calculate mortgage payments, amortization schedules, and compare payment scenarios.

## Features

- Fast and accurate mortgage payment calculations
- Interactive amortization schedule with beautiful charts
- Payment comparison scenarios to see the impact of making additional payments
- Save and share mortgage scenarios
- Optimized for performance and low resource usage

## Technical Optimizations

This app has been extensively optimized for performance:

1. **Code Structure Improvements**
   - Separated models, views, and calculation logic into dedicated files
   - Implemented proper MVVM architecture
   - Improved code reusability and maintainability

2. **Performance Optimizations**
   - Eliminated redundant calculations
   - Optimized algorithm implementation
   - Reduced memory allocations using capacity reservation
   - Cached calculation results where appropriate
   - Used a singleton calculator service to reduce instantiation overhead

3. **Memory Usage Improvements**
   - Switched from Decimal to Double for calculations to reduce conversion overhead
   - Only display subset of amortization schedule data instead of the full dataset
   - Optimized data structures with appropriate types

4. **UI Responsiveness**
   - Real-time calculation updates on input change
   - Streamlined UI with performance in mind
   - Optimized chart rendering

## How to Use

1. **Input your mortgage details:**
   - Loan amount
   - Interest rate
   - Loan term
   - Payment frequency

2. **Optional: Add additional payment amount**

3. **View results and explore options:**
   - View detailed amortization schedule
   - See payment comparison scenarios
   - Save and manage multiple scenarios

## Requirements

- iOS 15.0+
- Charts features require iOS 16.0+

## Installation

1. Clone the repository
2. Open the project in Xcode
3. Build and run the app on your device or simulator

## Usage

1. Enter your loan details (amount, interest rate, term, payment frequency)
2. Optionally add additional payments
3. View the payment summary
4. Explore the amortization schedule and payment comparison scenarios
5. Save scenarios for future reference

## Screenshots

[Screenshots will be added here]

## License

This project is available under the MIT license. See the LICENSE file for more info. 