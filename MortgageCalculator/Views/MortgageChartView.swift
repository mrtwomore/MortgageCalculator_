import SwiftUI
import Charts

struct MortgageChartView: View {
    let payments: [PaymentDetails]
    @State private var chartType: ChartType = .balance
    @State private var selectedPayment: PaymentDetails?
    @State private var showingDataLabels = false
    
    enum ChartType: String, CaseIterable, Identifiable {
        case balance = "Balance"
        case payment = "Payment Breakdown"
        case interest = "Interest vs Principal"
        
        var id: String { self.rawValue }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker("Chart Type", selection: $chartType) {
                ForEach(ChartType.allCases) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            ZStack {
                switch chartType {
                case .balance:
                    balanceChart
                case .payment:
                    paymentBreakdownChart
                case .interest:
                    interestVsPrincipalChart
                }
            }
            .frame(height: 220)
            .padding()
            
            if let selected = selectedPayment {
                paymentDetailView(selected)
            }
            
            Toggle("Show Data Labels", isOn: $showingDataLabels)
                .padding(.horizontal)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private var balanceChart: some View {
        Chart {
            ForEach(payments) { payment in
                LineMark(
                    x: .value("Payment", payment.paymentNumber),
                    y: .value("Balance", payment.remainingBalance)
                )
                .foregroundStyle(.blue)
                .interpolationMethod(.monotone)
                
                if showingDataLabels && payment.paymentNumber % (max(payments.count / 10, 1)) == 0 {
                    PointMark(
                        x: .value("Payment", payment.paymentNumber),
                        y: .value("Balance", payment.remainingBalance)
                    )
                    .foregroundStyle(.blue)
                    .annotation(position: .top) {
                        Text(Formatters.formatCurrency(payment.remainingBalance))
                            .font(.caption2)
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                if let doubleValue = value.as(Double.self) {
                    AxisValueLabel {
                        Text(Formatters.formatCurrency(doubleValue))
                            .font(.caption)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: getStride())) { value in
                if let intValue = value.as(Int.self) {
                    AxisValueLabel {
                        Text("\(intValue)")
                            .font(.caption)
                    }
                }
            }
        }
        .chartTitle("Remaining Balance")
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle().fill(.clear).contentShape(Rectangle())
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                handleChartInteraction(geometry, proxy, value)
                            }
                            .onEnded { _ in
                                selectedPayment = nil
                            }
                    )
            }
        }
    }
    
    private var paymentBreakdownChart: some View {
        Chart {
            ForEach(payments) { payment in
                AreaMark(
                    x: .value("Payment", payment.paymentNumber),
                    y: .value("Principal", payment.principal)
                )
                .foregroundStyle(.green)
                .interpolationMethod(.monotone)
                
                AreaMark(
                    x: .value("Payment", payment.paymentNumber),
                    y: .value("Interest", payment.interest)
                )
                .foregroundStyle(.red)
                .interpolationMethod(.monotone)
                
                if showingDataLabels && payment.paymentNumber % (max(payments.count / 6, 1)) == 0 {
                    PointMark(
                        x: .value("Payment", payment.paymentNumber),
                        y: .value("Total", payment.principal + payment.interest)
                    )
                    .foregroundStyle(.secondary)
                    .annotation(position: .top) {
                        Text(Formatters.formatCurrency(payment.principal + payment.interest))
                            .font(.caption2)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                if let doubleValue = value.as(Double.self) {
                    AxisValueLabel {
                        Text(Formatters.formatCurrency(doubleValue))
                            .font(.caption)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: getStride())) { value in
                if let intValue = value.as(Int.self) {
                    AxisValueLabel {
                        Text("\(intValue)")
                            .font(.caption)
                    }
                }
            }
        }
        .chartForegroundStyleScale([
            "Principal": .green,
            "Interest": .red
        ])
        .chartLegend(position: .bottom) {
            HStack {
                HStack {
                    Rectangle()
                        .fill(.green)
                        .frame(width: 12, height: 12)
                    Text("Principal")
                        .font(.caption)
                }
                HStack {
                    Rectangle()
                        .fill(.red)
                        .frame(width: 12, height: 12)
                    Text("Interest")
                        .font(.caption)
                }
            }
        }
        .chartTitle("Payment Breakdown")
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle().fill(.clear).contentShape(Rectangle())
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                handleChartInteraction(geometry, proxy, value)
                            }
                            .onEnded { _ in
                                selectedPayment = nil
                            }
                    )
            }
        }
    }
    
    private var interestVsPrincipalChart: some View {
        Chart {
            ForEach(payments) { payment in
                LineMark(
                    x: .value("Payment", payment.paymentNumber),
                    y: .value("Principal %", payment.principalToDatePercentage),
                    series: .value("Type", "Principal")
                )
                .foregroundStyle(.green)
                .interpolationMethod(.monotone)
                
                LineMark(
                    x: .value("Payment", payment.paymentNumber),
                    y: .value("Interest %", 100.0 - payment.principalToDatePercentage),
                    series: .value("Type", "Interest")
                )
                .foregroundStyle(.red)
                .interpolationMethod(.monotone)
                
                if showingDataLabels && payment.paymentNumber % (max(payments.count / 5, 1)) == 0 {
                    PointMark(
                        x: .value("Payment", payment.paymentNumber),
                        y: .value("Principal %", payment.principalToDatePercentage)
                    )
                    .foregroundStyle(.green)
                    .annotation(position: .top) {
                        Text(Formatters.formatPercent(payment.principalToDatePercentage))
                            .font(.caption2)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                if let doubleValue = value.as(Double.self) {
                    AxisValueLabel {
                        Text(Formatters.formatPercent(doubleValue))
                            .font(.caption)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: getStride())) { value in
                if let intValue = value.as(Int.self) {
                    AxisValueLabel {
                        Text("\(intValue)")
                            .font(.caption)
                    }
                }
            }
        }
        .chartForegroundStyleScale([
            "Principal": .green,
            "Interest": .red
        ])
        .chartLegend(position: .bottom)
        .chartTitle("Loan Progress")
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle().fill(.clear).contentShape(Rectangle())
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                handleChartInteraction(geometry, proxy, value)
                            }
                            .onEnded { _ in
                                selectedPayment = nil
                            }
                    )
            }
        }
    }
    
    private func paymentDetailView(_ payment: PaymentDetails) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Payment \(payment.paymentNumber)")
                    .font(.headline)
                Spacer()
                Text(Formatters.formatDate(payment.date))
                    .font(.caption)
            }
            
            Divider()
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Principal: \(Formatters.formatCurrency(payment.principal))")
                        .foregroundColor(.green)
                    Text("Interest: \(Formatters.formatCurrency(payment.interest))")
                        .foregroundColor(.red)
                    Text("Total: \(Formatters.formatCurrency(payment.totalPayment))")
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Balance: \(Formatters.formatCurrency(payment.remainingBalance))")
                        .foregroundColor(.blue)
                    Text("Principal Paid: \(Formatters.formatPercent(payment.principalToDatePercentage))")
                        .foregroundColor(.green)
                    Text("Interest to Date: \(Formatters.formatCurrency(payment.interestToDate))")
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
        .padding(.horizontal)
    }
    
    private func handleChartInteraction(_ geometry: GeometryProxy, _ proxy: ChartProxy, _ value: DragGesture.Value) {
        let xPosition = value.location.x - geometry[proxy.plotAreaFrame].origin.x
        guard xPosition >= 0, xPosition <= proxy.plotAreaSize.width else {
            return
        }
        
        let xScale = proxy.plotAreaSize.width / CGFloat(payments.count - 1)
        let paymentIndex = Int((xPosition / xScale).rounded())
        guard paymentIndex >= 0, paymentIndex < payments.count else { return }
        
        selectedPayment = payments[paymentIndex]
    }
    
    private func getStride() -> Int {
        let count = payments.count
        if count > 300 {
            return 50
        } else if count > 150 {
            return 25
        } else if count > 60 {
            return 10
        } else if count > 24 {
            return 6
        } else {
            return 3
        }
    }
} 