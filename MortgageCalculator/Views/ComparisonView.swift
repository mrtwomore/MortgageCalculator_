import SwiftUI

struct ComparisonView: View {
    let scenarios: [ComparisonScenario]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(scenarios) { scenario in
                    Section(header: Text("+\(Int(scenario.increasePercentage))% Payment Increase")) {
                        VStack(spacing: 8) {
                            HStack {
                                Text("New Payment:")
                                Spacer()
                                Text("$\(String(format: "%.2f", scenario.newPayment))")
                                    .font(.headline)
                            }
                            
                            HStack {
                                Text("Years to Pay:")
                                Spacer()
                                Text("\(String(format: "%.1f", scenario.yearsToPay)) years")
                            }
                            
                            HStack {
                                Text("Time Saved:")
                                Spacer()
                                Text("\(String(format: "%.1f", scenario.timeSaved)) years")
                                    .foregroundColor(.green)
                            }
                            
                            HStack {
                                Text("Interest Savings:")
                                Spacer()
                                Text("$\(String(format: "%.2f", scenario.interestSavings))")
                                    .foregroundColor(.green)
                            }
                            
                            HStack {
                                Text("Total Savings:")
                                Spacer()
                                Text("$\(String(format: "%.2f", scenario.totalSaved))")
                                    .font(.headline)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Payment Scenarios")
        }
    }
}

struct ComparisonView_Previews: PreviewProvider {
    static var previews: some View {
        ComparisonView(scenarios: [
            ComparisonScenario(
                increasePercentage: 10.0,
                newPayment: 3300.0,
                yearsToPay: 25.0,
                interestSavings: 25000.0,
                timeSaved: 2.5,
                totalPaid: 500000.0,
                totalSaved: 25000.0
            ),
            ComparisonScenario(
                increasePercentage: 25.0,
                newPayment: 3750.0,
                yearsToPay: 22.0,
                interestSavings: 50000.0,
                timeSaved: 5.5,
                totalPaid: 475000.0,
                totalSaved: 50000.0
            )
        ])
    }
} 