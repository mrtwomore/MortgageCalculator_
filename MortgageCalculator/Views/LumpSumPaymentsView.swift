import SwiftUI

struct LumpSumPaymentsView: View {
    @Binding var scenario: MortgageScenario
    @State private var newLumpSumAmount: String = ""
    @State private var newLumpSumPaymentNumber: String = ""
    @State private var showingAddSheet = false
    
    var body: some View {
        List {
            Section(header: Text("Current Lump Sum Payments")) {
                if scenario.lumpSumPayments.isEmpty {
                    Text("No lump sum payments added")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ForEach(scenario.lumpSumPayments.sorted(by: { $0.paymentNumber < $1.paymentNumber })) { payment in
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Payment \(payment.paymentNumber)")
                                    .font(.headline)
                                Text(Formatters.formatCurrency(payment.amount))
                                    .foregroundColor(.green)
                            }
                            Spacer()
                            Text("One-time payment")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .onDelete(perform: deleteLumpSumPayment)
                }
            }
            
            Section {
                Button(action: {
                    showingAddSheet = true
                }) {
                    Label("Add Lump Sum Payment", systemImage: "plus.circle")
                }
            }
        }
        .navigationTitle("Lump Sum Payments")
        .sheet(isPresented: $showingAddSheet) {
            NavigationView {
                Form {
                    Section(header: Text("New Lump Sum Payment")) {
                        TextField("Amount", text: $newLumpSumAmount)
                            .keyboardType(.decimalPad)
                        
                        TextField("Payment Number", text: $newLumpSumPaymentNumber)
                            .keyboardType(.numberPad)
                    }
                    
                    Section {
                        Text("Add a one-time payment to reduce your principal faster.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .navigationTitle("Add Lump Sum")
                .navigationBarItems(
                    leading: Button("Cancel") {
                        showingAddSheet = false
                        newLumpSumAmount = ""
                        newLumpSumPaymentNumber = ""
                    },
                    trailing: Button("Add") {
                        addLumpSumPayment()
                        showingAddSheet = false
                    }
                    .disabled(newLumpSumAmount.isEmpty || newLumpSumPaymentNumber.isEmpty)
                )
            }
        }
    }
    
    private func addLumpSumPayment() {
        guard let amount = Double(newLumpSumAmount),
              let paymentNumber = Int(newLumpSumPaymentNumber) else {
            return
        }
        
        let newPayment = LumpSumPayment(amount: amount, paymentNumber: paymentNumber)
        scenario.lumpSumPayments.append(newPayment)
        
        // Reset input fields
        newLumpSumAmount = ""
        newLumpSumPaymentNumber = ""
    }
    
    private func deleteLumpSumPayment(at offsets: IndexSet) {
        let sortedPayments = scenario.lumpSumPayments.sorted(by: { $0.paymentNumber < $1.paymentNumber })
        let paymentsToRemove = offsets.map { sortedPayments[$0] }
        
        for payment in paymentsToRemove {
            if let index = scenario.lumpSumPayments.firstIndex(where: { $0.id == payment.id }) {
                scenario.lumpSumPayments.remove(at: index)
            }
        }
    }
} 