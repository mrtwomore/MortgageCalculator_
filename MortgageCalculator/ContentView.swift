import SwiftUI

struct ContentView: View {
    @State private var loanAmount: String = "300000"
    @State private var interestRate: String = "5.0"
    @State private var loanTerm: String = "30"
    @State private var amortizationSchedule: [PaymentDetails] = []
    
    private var monthlyPayment: Double {
        guard let amount = Double(loanAmount),
              let rate = Double(interestRate),
              let term = Double(loanTerm) else { return 0 }
        
        return MortgageCalculator.calculateMonthlyPayment(
            loanAmount: amount,
            annualInterestRate: rate,
            loanTermYears: term
        )
    }
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Loan Details")) {
                    TextField("Loan Amount", text: $loanAmount)
                        .keyboardType(.decimalPad)
                    
                    TextField("Interest Rate (%)", text: $interestRate)
                        .keyboardType(.decimalPad)
                    
                    TextField("Loan Term (Years)", text: $loanTerm)
                        .keyboardType(.decimalPad)
                }
                
                Section(header: Text("Monthly Payment")) {
                    Text("$\(monthlyPayment, specifier: "%.2f")")
                        .font(.headline)
                }
                
                Section(header: Text("Amortization Schedule")) {
                    Button("Calculate Schedule") {
                        calculateSchedule()
                    }
                    
                    ForEach(Array(amortizationSchedule.enumerated()), id: \.offset) { index, payment in
                        VStack(alignment: .leading) {
                            Text("Month \(index + 1)")
                                .font(.headline)
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Principal: $\(payment.principal, specifier: "%.2f")")
                                    Text("Interest: $\(payment.interest, specifier: "%.2f")")
                                }
                                Spacer()
                                Text("Balance: $\(payment.remainingBalance, specifier: "%.2f")")
                                    .font(.caption)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Mortgage Calculator")
        }
    }
    
    private func calculateSchedule() {
        guard let amount = Double(loanAmount),
              let rate = Double(interestRate),
              let term = Double(loanTerm) else { return }
        
        amortizationSchedule = MortgageCalculator.calculateAmortizationSchedule(
            loanAmount: amount,
            annualInterestRate: rate,
            loanTermYears: term
        )
    }
} 