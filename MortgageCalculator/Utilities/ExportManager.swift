import Foundation
import UIKit
import PDFKit
import Charts
import SwiftUI

class ExportManager {
    // Export amortization schedule to CSV
    static func exportToCSV(scenario: MortgageScenario, payments: [PaymentDetails]) -> URL? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        
        var csvString = "Payment Number,Date,Payment Amount,Principal,Interest,Remaining Balance,Principal Paid to Date (%),Interest Paid to Date\n"
        
        for payment in payments {
            let row = [
                "\(payment.paymentNumber)",
                dateFormatter.string(from: payment.date),
                formatter.string(from: NSNumber(value: payment.totalPayment)) ?? "0",
                formatter.string(from: NSNumber(value: payment.principal)) ?? "0",
                formatter.string(from: NSNumber(value: payment.interest)) ?? "0",
                formatter.string(from: NSNumber(value: payment.remainingBalance)) ?? "0",
                String(format: "%.2f%%", payment.principalToDatePercentage),
                formatter.string(from: NSNumber(value: payment.interestToDate)) ?? "0"
            ].joined(separator: ",")
            
            csvString.append(row + "\n")
        }
        
        // Get directory
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileName = "\(scenario.name.replacingOccurrences(of: " ", with: "_"))_Amortization.csv"
        let fileURL = directory.appendingPathComponent(fileName)
        
        do {
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Error writing CSV file: \(error)")
            return nil
        }
    }
    
    // Generate a PDF report of the mortgage scenario
    static func generatePDFReport(scenario: MortgageScenario, payments: [PaymentDetails]) -> Data? {
        let pdfMetaData = [
            kCGPDFContextCreator: "Mortgage Calculator App",
            kCGPDFContextAuthor: "User",
            kCGPDFContextTitle: "\(scenario.name) Mortgage Report"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4 size
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            // Add content to the PDF
            let titleFont = UIFont.boldSystemFont(ofSize: 24.0)
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: titleFont
            ]
            
            let headerFont = UIFont.boldSystemFont(ofSize: 16.0)
            let headerAttributes: [NSAttributedString.Key: Any] = [
                .font: headerFont
            ]
            
            let textFont = UIFont.systemFont(ofSize: 12.0)
            let textAttributes: [NSAttributedString.Key: Any] = [
                .font: textFont
            ]
            
            // Title
            let titleString = "Mortgage Report: \(scenario.name)"
            let titleStringSize = titleString.size(withAttributes: titleAttributes)
            let titleStringRect = CGRect(x: (pageRect.width - titleStringSize.width) / 2.0,
                                         y: 40,
                                         width: titleStringSize.width,
                                         height: titleStringSize.height)
            titleString.draw(in: titleStringRect, withAttributes: titleAttributes)
            
            // Loan Details
            let loanDetailsTitle = "Loan Details"
            let loanDetailsTitleRect = CGRect(x: 40, y: 80, width: pageRect.width - 80, height: 20)
            loanDetailsTitle.draw(in: loanDetailsTitleRect, withAttributes: headerAttributes)
            
            let loanTypeString = "Loan Type: \(scenario.loanType)"
            let loanTypeRect = CGRect(x: 40, y: 105, width: pageRect.width - 80, height: 20)
            loanTypeString.draw(in: loanTypeRect, withAttributes: textAttributes)
            
            let loanAmountString = "Loan Amount: $\(String(format: "%.2f", scenario.loanAmount))"
            let loanAmountRect = CGRect(x: 40, y: 125, width: pageRect.width - 80, height: 20)
            loanAmountString.draw(in: loanAmountRect, withAttributes: textAttributes)
            
            let interestRateString = "Interest Rate: \(String(format: "%.2f", scenario.interestRate))%"
            let interestRateRect = CGRect(x: 40, y: 145, width: pageRect.width - 80, height: 20)
            interestRateString.draw(in: interestRateRect, withAttributes: textAttributes)
            
            let loanTermString = "Loan Term: \(String(format: "%.1f", scenario.loanTermYears)) years"
            let loanTermRect = CGRect(x: 40, y: 165, width: pageRect.width - 80, height: 20)
            loanTermString.draw(in: loanTermRect, withAttributes: textAttributes)
            
            let paymentFrequencyString = "Payment Frequency: \(scenario.paymentFrequency)"
            let paymentFrequencyRect = CGRect(x: 40, y: 185, width: pageRect.width - 80, height: 20)
            paymentFrequencyString.draw(in: paymentFrequencyRect, withAttributes: textAttributes)
            
            let regularPaymentString = "Regular Payment: $\(String(format: "%.2f", scenario.regularPayment))"
            let regularPaymentRect = CGRect(x: 40, y: 205, width: pageRect.width - 80, height: 20)
            regularPaymentString.draw(in: regularPaymentRect, withAttributes: textAttributes)
            
            if scenario.additionalPayment > 0 {
                let additionalPaymentString = "Additional Payment: $\(String(format: "%.2f", scenario.additionalPayment))"
                let additionalPaymentRect = CGRect(x: 40, y: 225, width: pageRect.width - 80, height: 20)
                additionalPaymentString.draw(in: additionalPaymentRect, withAttributes: textAttributes)
                
                let totalPaymentString = "Total Payment: $\(String(format: "%.2f", scenario.effectivePayment))"
                let totalPaymentRect = CGRect(x: 40, y: 245, width: pageRect.width - 80, height: 20)
                totalPaymentString.draw(in: totalPaymentRect, withAttributes: textAttributes)
            }
            
            // Summary
            let summaryTitle = "Payment Summary"
            let summaryTitleRect = CGRect(x: 40, y: 275, width: pageRect.width - 80, height: 20)
            summaryTitle.draw(in: summaryTitleRect, withAttributes: headerAttributes)
            
            let totalPaymentsString = "Total Number of Payments: \(payments.count)"
            let totalPaymentsRect = CGRect(x: 40, y: 300, width: pageRect.width - 80, height: 20)
            totalPaymentsString.draw(in: totalPaymentsRect, withAttributes: textAttributes)
            
            let totalInterestString = "Total Interest Paid: $\(String(format: "%.2f", payments.last?.interestToDate ?? 0))"
            let totalInterestRect = CGRect(x: 40, y: 320, width: pageRect.width - 80, height: 20)
            totalInterestString.draw(in: totalInterestRect, withAttributes: textAttributes)
            
            // Amortization Table Header
            let tableTitle = "Amortization Schedule (First 10 Payments)"
            let tableTitleRect = CGRect(x: 40, y: 350, width: pageRect.width - 80, height: 20)
            tableTitle.draw(in: tableTitleRect, withAttributes: headerAttributes)
            
            // Table header
            let headers = ["#", "Date", "Payment", "Principal", "Interest", "Balance"]
            let columnWidths: [CGFloat] = [30, 100, 80, 80, 80, 100]
            var xPosition: CGFloat = 40
            
            for (index, header) in headers.enumerated() {
                let headerRect = CGRect(x: xPosition, y: 375, width: columnWidths[index], height: 20)
                header.draw(in: headerRect, withAttributes: headerAttributes)
                xPosition += columnWidths[index]
            }
            
            // Table rows (first 10 payments)
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            
            for rowIndex in 0..<min(10, payments.count) {
                let payment = payments[rowIndex]
                xPosition = 40
                let yPosition: CGFloat = 400 + CGFloat(rowIndex) * 20
                
                let rowData = [
                    "\(payment.paymentNumber)",
                    dateFormatter.string(from: payment.date),
                    "$\(String(format: "%.2f", payment.totalPayment))",
                    "$\(String(format: "%.2f", payment.principal))",
                    "$\(String(format: "%.2f", payment.interest))",
                    "$\(String(format: "%.2f", payment.remainingBalance))"
                ]
                
                for (index, cellData) in rowData.enumerated() {
                    let cellRect = CGRect(x: xPosition, y: yPosition, width: columnWidths[index], height: 20)
                    cellData.draw(in: cellRect, withAttributes: textAttributes)
                    xPosition += columnWidths[index]
                }
            }
            
            // Date generated
            let dateString = "Report generated on \(dateFormatter.string(from: Date()))"
            let dateStringSize = dateString.size(withAttributes: textAttributes)
            let dateStringRect = CGRect(x: (pageRect.width - dateStringSize.width) / 2.0,
                                      y: pageRect.height - 40,
                                      width: dateStringSize.width,
                                      height: dateStringSize.height)
            dateString.draw(in: dateStringRect, withAttributes: textAttributes)
        }
        
        return data
    }
    
    // Share file with UIActivityViewController
    static func shareFile(at url: URL, from viewController: UIViewController, sourceView: UIView? = nil) {
        let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        if let popoverController = activityViewController.popoverPresentationController {
            if let sourceView = sourceView {
                popoverController.sourceView = sourceView
                popoverController.sourceRect = sourceView.bounds
            } else {
                popoverController.sourceView = viewController.view
                popoverController.sourceRect = CGRect(x: viewController.view.bounds.midX, y: viewController.view.bounds.midY, width: 0, height: 0)
            }
        }
        
        viewController.present(activityViewController, animated: true)
    }
} 