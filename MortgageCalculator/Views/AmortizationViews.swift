import SwiftUI
import Charts

struct AmortizationScheduleView: View {
    var amortizationSchedule: [PaymentPeriod]
    var loanAmount: Double
    var interestRate: Double
    var loanTerm: Double
    var frequency: String
    
    @State private var selectedChartDataType = "Balance"
    private let chartDataTypes = ["Balance", "Principal vs Interest", "Payment Breakdown"]
    
    private var yearlySummary: [YearlySummary] {
        return MortgageCalculatorService.shared.generateYearlySummary(
            amortizationSchedule: amortizationSchedule,
            frequency: frequency
        )
    }
    
    var body: some View {
        VStack {
            Picker("Chart Type", selection: $selectedChartDataType) {
                ForEach(chartDataTypes, id: \.self) { type in
                    Text(type)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            if #available(iOS 16.0, *) {
                if selectedChartDataType == "Balance" {
                    BalanceChart(yearlySummary: yearlySummary)
                        .frame(height: 250)
                        .padding()
                } else if selectedChartDataType == "Principal vs Interest" {
                    PrincipalVsInterestChart(yearlySummary: yearlySummary)
                        .frame(height: 250)
                        .padding()
                } else {
                    PaymentBreakdownChart(yearlySummary: yearlySummary.prefix(1))
                        .frame(height: 250)
                        .padding()
                }
            } else {
                // Fallback for iOS 15 and earlier
                FallbackChartView(yearlySummary: yearlySummary, chartType: selectedChartDataType)
                    .frame(height: 250)
                    .padding()
            }
            
            List {
                Section(header: Text("Loan Summary")) {
                    HStack {
                        Text("Loan Amount:")
                        Spacer()
                        Text("$\(String(format: "%.2f", loanAmount))")
                    }
                    
                    HStack {
                        Text("Interest Rate:")
                        Spacer()
                        Text("\(String(format: "%.2f", interestRate))%")
                    }
                    
                    HStack {
                        Text("Loan Term:")
                        Spacer()
                        Text("\(String(format: "%.1f", loanTerm)) years")
                    }
                    
                    HStack {
                        Text("Payment Frequency:")
                        Spacer()
                        Text(frequency)
                    }
                }
                
                Section(header: Text("Amortization Schedule")) {
                    let frequencyValue = PaymentFrequencies.frequencies[frequency] ?? 12
                    
                    ForEach(0..<amortizationSchedule.count, id: \.self) { index in
                        let payment = amortizationSchedule[index]
                        let paymentNumber = index + 1
                        
                        // Only show key payments to reduce memory usage and improve performance
                        if paymentNumber == 1 || paymentNumber % frequencyValue == 0 || paymentNumber == amortizationSchedule.count {
                            VStack(alignment: .leading) {
                                Text("Payment \(paymentNumber)")
                                    .font(.headline)
                                
                                HStack {
                                    Text("Principal:")
                                    Spacer()
                                    Text("$\(String(format: "%.2f", payment.principalPayment))")
                                }
                                
                                HStack {
                                    Text("Interest:")
                                    Spacer()
                                    Text("$\(String(format: "%.2f", payment.interestPayment))")
                                }
                                
                                HStack {
                                    Text("Remaining Balance:")
                                    Spacer()
                                    Text("$\(String(format: "%.2f", payment.remainingBalance))")
                                }
                            }
                            .padding(.vertical, 5)
                        }
                    }
                }
            }
        }
        .navigationTitle("Amortization Schedule")
    }
}

// Fallback chart for iOS 15 and earlier
struct FallbackChartView: View {
    var yearlySummary: [YearlySummary]
    var chartType: String
    
    var body: some View {
        VStack {
            Text("Charts require iOS 16 or later")
                .font(.headline)
                .padding()
            
            if chartType == "Balance" {
                Text("Balance Summary:")
                    .font(.subheadline)
                
                ScrollView(.horizontal) {
                    HStack(spacing: 15) {
                        ForEach(yearlySummary) { year in
                            VStack {
                                Text("Year \(year.year)")
                                    .font(.caption)
                                
                                Text("$\(String(format: "%.0f", year.remainingBalance))")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            .padding(.vertical, 5)
                            .padding(.horizontal, 10)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                }
            } else if chartType == "Principal vs Interest" {
                Text("Principal vs Interest Summary:")
                    .font(.subheadline)
                
                ScrollView(.horizontal) {
                    HStack(spacing: 15) {
                        ForEach(yearlySummary) { year in
                            VStack {
                                Text("Year \(year.year)")
                                    .font(.caption)
                                
                                Text("P: $\(String(format: "%.0f", year.principalPaid))")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                
                                Text("I: $\(String(format: "%.0f", year.interestPaid))")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                            .padding(.vertical, 5)
                            .padding(.horizontal, 10)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                }
            } else {
                Text("Payment Breakdown Summary:")
                    .font(.subheadline)
                
                if let firstYear = yearlySummary.first {
                    HStack(spacing: 20) {
                        VStack {
                            Text("Principal")
                                .font(.caption)
                            
                            Text("$\(String(format: "%.0f", firstYear.principalPaid))")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                        
                        VStack {
                            Text("Interest")
                                .font(.caption)
                            
                            Text("$\(String(format: "%.0f", firstYear.interestPaid))")
                                .font(.subheadline)
                                .foregroundColor(.red)
                        }
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .padding()
                }
            }
        }
    }
}

@available(iOS 16.0, *)
struct BalanceChart: View {
    var yearlySummary: [YearlySummary]
    
    var body: some View {
        Chart {
            ForEach(yearlySummary) { year in
                LineMark(
                    x: .value("Year", year.year),
                    y: .value("Balance", year.remainingBalance)
                )
                .foregroundStyle(.blue)
                .interpolationMethod(.catmullRom)
            }
        }
        .chartXAxisLabel("Year")
        .chartYAxisLabel("Balance")
        .chartYScale(domain: [0, yearlySummary.first?.remainingBalance ?? 0])
    }
}

@available(iOS 16.0, *)
struct PrincipalVsInterestChart: View {
    var yearlySummary: [YearlySummary]
    
    var body: some View {
        Chart {
            ForEach(yearlySummary) { year in
                BarMark(
                    x: .value("Year", year.year),
                    y: .value("Principal", year.principalPaid)
                )
                .foregroundStyle(.blue)
                
                BarMark(
                    x: .value("Year", year.year),
                    y: .value("Interest", year.interestPaid)
                )
                .foregroundStyle(.red)
            }
        }
        .chartXAxisLabel("Year")
        .chartYAxisLabel("Amount")
    }
}

@available(iOS 16.0, *)
struct PaymentBreakdownChart: View {
    var yearlySummary: [YearlySummary]
    
    var body: some View {
        Chart {
            ForEach(yearlySummary) { year in
                SectorMark(
                    angle: .value("Principal", year.principalPaid),
                    innerRadius: .ratio(0.5),
                    angularInset: 1.0
                )
                .foregroundStyle(.blue)
                .annotation(position: .overlay) {
                    Text("Principal")
                        .font(.caption)
                        .foregroundColor(.white)
                }
                
                SectorMark(
                    angle: .value("Interest", year.interestPaid),
                    innerRadius: .ratio(0.5),
                    angularInset: 1.0
                )
                .foregroundStyle(.red)
                .annotation(position: .overlay) {
                    Text("Interest")
                        .font(.caption)
                        .foregroundColor(.white)
                }
            }
        }
    }
} 