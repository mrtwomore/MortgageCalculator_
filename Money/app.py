import matplotlib
matplotlib.use('Agg')
from flask import Flask, render_template, request, send_file, make_response, jsonify
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import io
import base64
from datetime import datetime, timedelta
from reportlab.lib import colors
from reportlab.lib.pagesizes import letter
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
import os
from io import StringIO
import csv
from pandas.tseries.offsets import DateOffset
import xlsxwriter
from dateutil.relativedelta import relativedelta

app = Flask(__name__)
app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', 'your-secret-key-here')

PAYMENT_FREQUENCIES = {
    'weekly': 52,
    'fortnightly': 26,
    'monthly': 12
}

BANK_RATES = [
    {"name": "ANZ",    "url": "https://www.anz.co.nz/personal/home-loans-mortgages/loan-types/?cid=sem--homeloans--c&PPC=1&s_kwcid=AL!9240!3!610517541270!e!!g!!anz%20mortgage%20rates&gclsrc=aw.ds&gad_source=1&gbraid=0AAAAADhVokrPmEX5EQ0pHL0gWR5TC6WZx&gclid=Cj0KCQiA_NC9BhCkARIsABSnSTb4zwPCVHOSC6htvVCsAa7-SmDr7pOAekJRKcRX2MDc35kPfpORAxQaAtmmEALw_wcB", "rate": "5.5%"},
    {"name": "ASB",    "url": "https://www.asb.co.nz/home-loans-mortgages/interest-rates-fees.html?s_kwcid=AL!16325!3!609084324433!e!!g!!asb%20mortgage%20rate&gclsrc=aw.ds&gad_source=1&gbraid=0AAAAAD3w4ELnBw6-UJIn4_3RcY3YIa5Q7", "rate": "5.6%"},
    {"name": "BNZ",    "url": "https://www.bnz.co.nz/personal-banking/home-loans/compare-bnz-home-loan-rates", "rate": "5.7%"},
    {"name": "Westpac","url": "https://www.westpac.co.nz/home-loans-mortgages/interest-rates/", "rate": "6.0%"}
]

BANK_SCRAPE_INFO = {
    "ANZ": {
        "url": "https://www.anz.co.nz/personal/home-loans-mortgages/loan-types/?cid=sem--homeloans--c&PPC=1&s_kwcid=AL!9240!3!610517541270!e!!g!!anz%20mortgage%20rates&gclsrc=aw.ds&gad_source=1&gbraid=0AAAAADhVokrPmEX5EQ0pHL0gWR5TC6WZx&gclid=Cj0KCQiA_NC9BhCkARIsABSnSTb4zwPCVHOSC6htvVCsAa7-SmDr7pOAekJRKcRX2MDc35kPfpORAxQaAtmmEALw_wcB",
        "selector": "div.rateBox span.rate"  # update with the actual selector based on ANZ's page structure
    },
    "ASB": {
        "url": "https://www.asb.co.nz/home-loans-mortgages/interest-rates-fees.html?s_kwcid=AL!16325!3!609084324433!e!!g!!asb%20mortgage%20rate&gclsrc=aw.ds&gad_source=1&gbraid=0AAAAAD3w4ELnBw6-UJIn4_3RcY3YIa5Q7",
        "selector": "div.rate-display"  # update selector as needed based on ASB's page
    },
    "BNZ": {
        "url": "https://www.bnz.co.nz/personal-banking/home-loans/compare-bnz-home-loan-rates",
        "selector": "span.rateValue"  # update selector to match BNZ's page structure
    },
    "Westpac": {
        "url": "https://www.westpac.co.nz/home-loans-mortgages/interest-rates/",
        "selector": "div.interest-rate"  # update with the actual selector based on Westpac's page
    }
}

def calculate_payment(principal, annual_rate, years, frequency='monthly'):
    """Calculate the periodic payment amount."""
    # Convert annual rate to periodic rate
    # Using simple division for weekly/fortnightly payments like banks do
    periodic_rate = (annual_rate / 100) / PAYMENT_FREQUENCIES[frequency]
    
    # Calculate number of payments
    n_payments = years * PAYMENT_FREQUENCIES[frequency]
    
    # Calculate periodic payment using the loan payment formula
    # P = L[c(1 + c)^n]/[(1 + c)^n - 1]
    # where P = payment, L = principal, c = periodic rate, n = number of payments
    numerator = periodic_rate * (1 + periodic_rate)**n_payments
    denominator = (1 + periodic_rate)**n_payments - 1
    payment = principal * (numerator / denominator)
    
    # Round to 2 decimal places to match bank calculations
    return round(payment, 2)

def generate_schedule(principal, annual_rate, years, frequency='monthly'):
    """Generate amortization schedule."""
    # Convert annual rate to periodic rate using simple division
    periodic_rate = (annual_rate / 100) / PAYMENT_FREQUENCIES[frequency]
    
    # Calculate payment with rounding
    payment = calculate_payment(principal, annual_rate, years, frequency)
    
    # Initialize lists to store values
    payments = []
    remaining_balance = principal
    total_interest = 0
    annual_interest = 0
    year_number = 1
    
    for payment_num in range(1, years * PAYMENT_FREQUENCIES[frequency] + 1):
        # Calculate interest with rounding
        interest_payment = round(remaining_balance * periodic_rate, 2)
        principal_payment = round(payment - interest_payment, 2)
        
        # Handle final payment rounding
        if remaining_balance < principal_payment:
            principal_payment = remaining_balance
            payment = principal_payment + interest_payment
        
        remaining_balance = round(remaining_balance - principal_payment, 2)
        total_interest = round(total_interest + interest_payment, 2)
        annual_interest = round(annual_interest + interest_payment, 2)
        
        # Calculate the current year
        current_year = (payment_num - 1) // PAYMENT_FREQUENCIES[frequency] + 1
        
        # If we've moved to a new year, reset the annual interest
        if current_year != year_number:
            annual_interest = interest_payment
            year_number = current_year
        
        if remaining_balance < 0:
            remaining_balance = 0
        
        payments.append({
            'Payment #': payment_num,
            'Payment': payment,
            'Principal': principal_payment,
            'Interest': interest_payment,
            'Remaining Balance': remaining_balance,
            'Total Interest Paid': total_interest,
            'Annual Interest': annual_interest,
            'Loan Paid (%)': round(((principal - remaining_balance) / principal) * 100, 1),
            'Year': current_year
        })
        
        if remaining_balance == 0:
            break
    
    return pd.DataFrame(payments)

def calculate_comparison_scenarios(principal, annual_rate, years, frequency='monthly'):
    """Calculate different payment scenarios with increased payments."""
    base_payment = calculate_payment(principal, annual_rate, years, frequency)
    base_schedule = generate_schedule(principal, annual_rate, years, frequency)
    
    if base_schedule.empty:
        return []
    
    base_total_interest = base_schedule['Total Interest Paid'].iloc[-1]
    base_years = len(base_schedule) / PAYMENT_FREQUENCIES[frequency]
    base_total_paid = principal + base_total_interest
    
    scenarios = []
    increases = [10, 25, 50]  # Percentage increases
    
    for increase in increases:
        increased_payment = base_payment * (1 + increase/100)
        
        # Generate schedule with increased payment
        increased_schedule = generate_schedule_with_payment(
            principal, annual_rate, years, frequency,
            fixed_payment=increased_payment
        )
        
        if increased_schedule.empty:
            continue
            
        increased_total_interest = increased_schedule['Total Interest Paid'].iloc[-1]
        increased_years = len(increased_schedule) / PAYMENT_FREQUENCIES[frequency]
        increased_total_paid = principal + increased_total_interest
        
        interest_savings = base_total_interest - increased_total_interest
        time_saved = base_years - increased_years
        
        scenarios.append({
            'increase_percentage': increase,
            'new_payment': increased_payment,
            'years_to_pay': increased_years,
            'interest_savings': interest_savings,
            'time_saved': time_saved,
            'total_paid': increased_total_paid,
            'total_saved': base_total_paid - increased_total_paid
        })
    
    return scenarios

def generate_schedule_with_payment(principal, annual_rate, years, frequency='monthly', fixed_payment=None):
    """Generate amortization schedule with a fixed payment amount."""
    # Convert annual rate to periodic rate using simple division
    periodic_rate = (annual_rate / 100) / PAYMENT_FREQUENCIES[frequency]
    
    # Use provided payment or calculate if not provided
    min_payment = calculate_payment(principal, annual_rate, years, frequency)
    payment = round(fixed_payment, 2) if fixed_payment is not None else min_payment
    
    if payment < min_payment:
        payment = min_payment  # Ensure payment is at least the minimum required
    
    # Initialize lists to store values
    payments = []
    remaining_balance = round(principal, 2)  # Start with rounded balance
    total_interest = 0
    annual_interest = 0
    year_number = 1
    
    while remaining_balance > 0:
        # Calculate interest with rounding
        interest_payment = round(remaining_balance * periodic_rate, 2)
        principal_payment = round(min(payment - interest_payment, remaining_balance), 2)
        
        # Adjust final payment if needed
        if principal_payment > remaining_balance:
            principal_payment = remaining_balance
            payment = round(interest_payment + principal_payment, 2)
        
        # Update balances with rounding
        remaining_balance = round(remaining_balance - principal_payment, 2)
        total_interest = round(total_interest + interest_payment, 2)
        annual_interest = round(annual_interest + interest_payment, 2)
        
        payment_num = len(payments) + 1
        current_year = (payment_num - 1) // PAYMENT_FREQUENCIES[frequency] + 1
        
        # Reset annual interest for new year
        if current_year != year_number:
            annual_interest = interest_payment
            year_number = current_year
        
        # Record payment details
        payments.append({
            'Payment #': payment_num,
            'Payment': payment,
            'Principal': principal_payment,
            'Interest': interest_payment,
            'Remaining Balance': remaining_balance,
            'Total Interest Paid': total_interest,
            'Annual Interest': annual_interest,
            'Loan Paid (%)': round(((principal - remaining_balance) / principal) * 100, 1),
            'Year': current_year
        })
        
        # Safety check to prevent infinite loops
        if payment_num > years * PAYMENT_FREQUENCIES[frequency] * 2:
            break
    
    return pd.DataFrame(payments)

@app.route('/', methods=['GET', 'POST'])
def index():
    if request.method == 'POST':
        try:
            principal = float(request.form['principal'])
            annual_rate = float(request.form['annual_rate'])
            years = int(request.form['years'])
            frequency = request.form.get('frequency', 'monthly')
            
            payment = calculate_payment(principal, annual_rate, years, frequency)
            schedule = generate_schedule(principal, annual_rate, years, frequency)
            
            if not schedule.empty:
                # Calculate total interest and other summary stats
                total_interest = schedule['Total Interest Paid'].iloc[-1]
                total_payments = len(schedule)
                
                # Calculate comparison scenarios
                scenarios = calculate_comparison_scenarios(
                    principal, annual_rate, years, frequency
                )
                
                return render_template('index.html',
                                    principal=principal,
                                    annual_rate=annual_rate,
                                    years=years,
                                    frequency=frequency,
                                    payment=payment,
                                    schedule=schedule.to_dict('records'),
                                    total_interest=total_interest,
                                    original_term=years,
                                    actual_years_to_pay=total_payments / PAYMENT_FREQUENCIES[frequency],
                                    scenarios=scenarios,
                                    bank_rates=BANK_RATES)
            else:
                return render_template('index.html',
                                    principal=principal,
                                    payment=0,
                                    schedule=[])
                                    
        except ValueError:
            return render_template('index.html', bank_rates=BANK_RATES, error="Invalid input. Please enter valid numbers.")
    
    return render_template('index.html', bank_rates=BANK_RATES)

@app.route('/export-pdf', methods=['POST'])
def export_pdf():
    """Export mortgage schedule as PDF."""
    try:
        # Get form data
        principal = float(request.form['principal'])
        annual_rate = float(request.form['annual_rate'])
        years = int(request.form['years'])
        frequency = request.form['frequency']
        
        # Generate schedule
        schedule = generate_schedule(principal, annual_rate, years, frequency)
        
        if not schedule.empty:
            # Create PDF in memory
            buffer = io.BytesIO()
            doc = SimpleDocTemplate(
                buffer,
                pagesize=letter,
                rightMargin=50,
                leftMargin=50,
                topMargin=50,
                bottomMargin=50
            )
            
            # Get styles
            styles = getSampleStyleSheet()
            title_style = ParagraphStyle(
                'CustomTitle',
                parent=styles['Heading1'],
                fontSize=24,
                spaceAfter=30
            )
            
            # Create story (content)
            story = []
            
            # Add title
            story.append(Paragraph('Mortgage Amortization Schedule', title_style))
            story.append(Spacer(1, 20))
            
            # Add summary information
            payment = calculate_payment(principal, annual_rate, years, frequency)
            total_interest = schedule['Total Interest Paid'].iloc[-1]
            years_to_pay = len(schedule) / PAYMENT_FREQUENCIES[frequency]
            
            summary_data = [
                ['Principal Amount:', f'${principal:,.2f}'],
                ['Annual Interest Rate:', f'{annual_rate}%'],
                ['Payment Frequency:', frequency.capitalize()],
                [f'{frequency.capitalize()} Payment:', f'${payment:,.2f}'],
                ['Total Interest:', f'${total_interest:,.2f}'],
                ['Years to Pay:', f'{years_to_pay:.1f}'],
                ['Total Cost:', f'${principal + total_interest:,.2f}']
            ]
            
            summary_table = Table(summary_data, colWidths=[200, 200])
            summary_table.setStyle(TableStyle([
                ('FONTNAME', (0, 0), (-1, -1), 'Helvetica'),
                ('FONTSIZE', (0, 0), (-1, -1), 12),
                ('TEXTCOLOR', (0, 0), (0, -1), colors.grey),
                ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
                ('BOTTOMPADDING', (0, 0), (-1, -1), 12),
            ]))
            
            story.append(summary_table)
            story.append(Spacer(1, 30))
            
            # Add amortization schedule
            story.append(Paragraph('Amortization Schedule', styles['Heading2']))
            story.append(Spacer(1, 20))
            
            # Prepare table data
            table_data = [['Payment #', 'Payment', 'Principal', 'Interest', 'Remaining Balance', 'Total Interest', 'Loan Paid (%)']]
            for _, row in schedule.iterrows():
                table_data.append([
                    str(int(row['Payment #'])),
                    f"${row['Payment']:,.2f}",
                    f"${row['Principal']:,.2f}",
                    f"${row['Interest']:,.2f}",
                    f"${row['Remaining Balance']:,.2f}",
                    f"${row['Total Interest Paid']:,.2f}",
                    f"{row['Loan Paid (%)']:.1f}%"
                ])
            
            # Create table
            schedule_table = Table(table_data, repeatRows=1)
            schedule_table.setStyle(TableStyle([
                ('FONTNAME', (0, 0), (-1, -1), 'Helvetica'),
                ('FONTSIZE', (0, 0), (-1, -1), 8),
                ('GRID', (0, 0), (-1, -1), 1, colors.black),
                ('BACKGROUND', (0, 0), (-1, 0), colors.grey),
                ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
                ('ALIGN', (0, 0), (-1, -1), 'RIGHT'),
                ('ALIGN', (0, 0), (0, -1), 'LEFT'),  # Left align first column
                ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ]))
            
            story.append(schedule_table)
            
            # Build PDF
            doc.build(story)
            buffer.seek(0)
            
            # Create response
            response = make_response(buffer.getvalue())
            response.headers['Content-Type'] = 'application/pdf'
            response.headers['Content-Disposition'] = f'attachment; filename=mortgage_schedule_{frequency}_{datetime.now().strftime("%Y%m%d_%H%M%S")}.pdf'
            return response
        
    except Exception as e:
        print(f"Error generating PDF: {str(e)}")
        return 'Error generating PDF', 500
    
    return 'No data to export', 400

@app.route('/export', methods=['POST'])
def export_csv():
    """Export mortgage schedule as CSV with modern payment tracking."""
    try:
        # Get form data
        principal = float(request.form['principal'])
        annual_rate = float(request.form['annual_rate'])
        years = int(request.form['years'])
        frequency = request.form['frequency']
        
        # Generate schedule
        schedule = generate_schedule(principal, annual_rate, years, frequency)
        
        if schedule.empty:
            return 'No data to export', 400
            
        # Create CSV in memory
        output = StringIO()
        writer = csv.writer(output)
        
        # Write header
        writer.writerow([
            'Done',          # Checkbox column renamed for clarity
            'Payment #',
            'Due Date',
            'Payment Amount',
            'Principal',
            'Interest',
            'Remaining Balance',
            'Total Interest',  # Renamed from "Total Interest Paid"
            'Progress (%)',    # Indicating it's a percentage value
            'Payment Complete',
            'Date Paid',
            'Notes'
        ])
        
        # Calculate payment dates based on frequency
        start_date = datetime.now()
        
        if frequency == 'weekly':
            date_increment = timedelta(days=7)
        elif frequency == 'fortnightly':
            date_increment = timedelta(days=14)
        else:  # monthly
            date_increment = DateOffset(months=1)
        
        # Write data rows
        for _, row in schedule.iterrows():
            if frequency == 'monthly':
                payment_date = start_date + DateOffset(months=int(row['Payment #'] - 1))
            else:
                payment_date = start_date + (date_increment * (row['Payment #'] - 1))
            
            writer.writerow([
                '',  # Empty checkbox
                int(row['Payment #']),
                payment_date.strftime('%Y-%m-%d'),
                f"{row['Payment']:.2f}",  # Numeric value without currency symbol
                f"{row['Principal']:.2f}",
                f"{row['Interest']:.2f}",
                f"{row['Remaining Balance']:.2f}",
                f"{row['Total Interest Paid']:.2f}",
                f"{row['Loan Paid (%)']:.1f}",  # Numeric progress (without % symbol) for easier Excel processing
                '',  # Payment Complete (to be marked "Yes" by the user)
                '',  # Date Paid
                ''   # Notes
            ])
        
        # Set variable for the last data row number (header is in row 1, so data rows start at row 2)
        data_end = len(schedule) + 1
        
        # Add tracking formulas at the bottom with improved formulas
        writer.writerow([])
        writer.writerow(['Payment Summary'])
        writer.writerow(['Total Payments:', f'=COUNTIF(J2:J{data_end}, "Yes")'])
        writer.writerow(['Progress:', f'=ROUND(COUNTIF(J2:J{data_end}, "Yes")/COUNTA(B2:B{data_end})*100,1)&"%"'])
        writer.writerow(['Next Due:', f'=IF(COUNTIF(J2:J{data_end},"Yes")>=COUNTA(B2:B{data_end}),"Complete!",INDEX(C2:C{data_end},COUNTIF(J2:J{data_end},"Yes")+1))'])
        
        # Add instructions
        writer.writerow([])
        writer.writerow(['Instructions:'])
        writer.writerow(['1. Mark "Yes" in the Payment Complete column to track payments'])
        writer.writerow(['2. Enter the payment date when completed'])
        writer.writerow(['3. Use the Notes column for any payment references'])
        
        # Prepare response
        output.seek(0)
        response = make_response(output.getvalue())
        response.headers['Content-Type'] = 'text/csv'
        response.headers['Content-Disposition'] = (
            f'attachment; filename=mortgage_tracker_{frequency}_{datetime.now().strftime("%Y%m%d_%H%M%S")}.csv'
        )
        
        return response
        
    except Exception as e:
        print(f"Error generating CSV: {str(e)}")
        return f'Error generating CSV: {str(e)}', 500

@app.route('/export-excel', methods=['POST'])
def export_excel():
    """Export mortgage schedule as an Excel file with enhanced formatting."""
    try:
        # Get form data
        principal = float(request.form['principal'])
        annual_rate = float(request.form['annual_rate'])
        years = int(request.form['years'])
        frequency = request.form['frequency']
        
        # Generate schedule
        schedule = generate_schedule(principal, annual_rate, years, frequency)
        if schedule.empty:
            return 'No data to export', 400
            
        output = io.BytesIO()
        workbook = xlsxwriter.Workbook(output, {'in_memory': True})
        worksheet = workbook.add_worksheet('Mortgage Tracker')
        
        # Define formats
        header_format = workbook.add_format({
            'bold': True, 'bg_color': '#D7E4BC', 'border': 1, 'align': 'center'
        })
        cell_format = workbook.add_format({'border': 1, 'align': 'center'})
        currency_format = workbook.add_format({
            'num_format': '$#,##0.00', 'border': 1, 'align': 'center'
        })
        percentage_format = workbook.add_format({
            'num_format': '0.0%', 'border': 1, 'align': 'center'
        })
        date_format = workbook.add_format({
            'num_format': 'yyyy-mm-dd', 'border': 1, 'align': 'center'
        })
        
        # Write header row in Excel (row 0)
        headers = [
            '✓', 'Payment #', 'Due Date', 'Payment Amount', 'Principal', 'Interest',
            'Remaining Balance', 'Total Interest Paid', 'Progress', 'Payment Complete',
            'Date Paid', 'Notes'
        ]
        for col_num, header in enumerate(headers):
            worksheet.write(0, col_num, header, header_format)
        
        # Start writing data from row 1
        start_date = datetime.now()
        if frequency == 'weekly':
            date_increment = timedelta(days=7)  # timedelta
        elif frequency == 'fortnightly':
            date_increment = timedelta(days=14)
        else:
            # For monthly payments, use relativedelta for proper month increments.
            date_increment = None
        
        row = 1
        for _, data in schedule.iterrows():
            payment_number = int(data['Payment #'])
            # Calculate due date based on frequency
            if frequency == 'monthly':
                due_date = start_date + relativedelta(months=payment_number - 1)
            else:
                due_date = start_date + (date_increment * (payment_number - 1))
            
            worksheet.write(row, 0, '', cell_format)  # Empty checkbox column
            worksheet.write_number(row, 1, payment_number, cell_format)
            worksheet.write_datetime(row, 2, due_date, date_format)
            worksheet.write_number(row, 3, data['Payment'], currency_format)
            worksheet.write_number(row, 4, data['Principal'], currency_format)
            worksheet.write_number(row, 5, data['Interest'], currency_format)
            worksheet.write_number(row, 6, data['Remaining Balance'], currency_format)
            worksheet.write_number(row, 7, data['Total Interest Paid'], currency_format)
            # Convert progress (Loan Paid (%)) into a fraction for Excel percentage formatting
            worksheet.write_number(row, 8, data['Loan Paid (%)'] / 100, percentage_format)
            worksheet.write(row, 9, '', cell_format)  # Payment Complete (to be filled in by user)
            worksheet.write(row, 10, '', cell_format)  # Date Paid
            worksheet.write(row, 11, '', cell_format)  # Notes
            row += 1
        
        # Determine Excel row indices (Excel rows are 1-indexed)
        data_start_excel = 2  # data begins at row 2 since header is row 1
        data_end_excel = row  # row now is the first empty row after data
        
        # Write a summary section below the data with formulas
        summary_start = row + 1
        worksheet.write(summary_start, 0, "Payment Summary", header_format)
        
        # Total Payments: Count of cells in the Payment Complete column (J) equal to "Yes"
        worksheet.write(summary_start + 1, 0, "Total Payments:", header_format)
        total_payments_formula = f'=COUNTIF(J{data_start_excel}:J{data_end_excel}, "Yes")'
        worksheet.write_formula(summary_start + 1, 1, total_payments_formula, cell_format)
        
        # Progress: Calculate the ratio of completed payments and format as a percentage
        worksheet.write(summary_start + 2, 0, "Progress:", header_format)
        progress_formula = f'=ROUND(COUNTIF(J{data_start_excel}:J{data_end_excel}, "Yes")/COUNTA(B{data_start_excel}:B{data_end_excel})*100,1)&"%"'
        worksheet.write_formula(summary_start + 2, 1, progress_formula, cell_format)
        
        # Next Due: Show the due date for the next payment that hasn't been marked complete;
        worksheet.write(summary_start + 3, 0, "Next Due:", header_format)
        next_due_formula = f'=IF(COUNTIF(J{data_start_excel}:J{data_end_excel},"Yes")>=COUNTA(B{data_start_excel}:B{data_end_excel}),"Complete!",' \
                           f'INDEX(C{data_start_excel}:C{data_end_excel},COUNTIF(J{data_start_excel}:J{data_end_excel},"Yes")+1))'
        worksheet.write_formula(summary_start + 3, 1, next_due_formula, cell_format)
        
        # Write instructions below the summary section
        instr_start = summary_start + 5
        worksheet.write(instr_start, 0, "Instructions:", header_format)
        worksheet.write(instr_start + 1, 0, '1. Mark "Yes" in the Payment Complete column to track payments.', cell_format)
        worksheet.write(instr_start + 2, 0, '2. Enter the payment date when completed.', cell_format)
        worksheet.write(instr_start + 3, 0, '3. Use the Notes column for any payment references.', cell_format)
        
        # Optionally, set column widths for better readability
        worksheet.set_column(0, 0, 4)    # Checkbox column
        worksheet.set_column(1, 1, 10)   # Payment #
        worksheet.set_column(2, 2, 12)   # Due Date
        worksheet.set_column(3, 3, 16)   # Payment Amount
        worksheet.set_column(4, 4, 12)   # Principal
        worksheet.set_column(5, 5, 10)   # Interest
        worksheet.set_column(6, 6, 18)   # Remaining Balance
        worksheet.set_column(7, 7, 18)   # Total Interest Paid
        worksheet.set_column(8, 8, 10)   # Progress
        worksheet.set_column(9, 9, 18)   # Payment Complete
        worksheet.set_column(10, 10, 12) # Date Paid
        worksheet.set_column(11, 11, 20) # Notes
        
        workbook.close()
        output.seek(0)
        
        response = make_response(output.read())
        response.headers[
            'Content-Type'] = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
        response.headers[
            'Content-Disposition'] = f'attachment; filename=mortgage_tracker_{frequency}_{datetime.now().strftime("%Y%m%d_%H%M%S")}.xlsx'
        return response
        
    except Exception as e:
        print(f"Error generating Excel file: {str(e)}")
        return f'Error generating Excel file: {str(e)}', 500

if __name__ == '__main__':
    app.run(debug=True)
