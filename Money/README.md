# Mortgage Amortization Calculator

A web-based mortgage calculator that helps visualize different mortgage scenarios including:
- Basic mortgage amortization
- Impact of lump sum payments
- Effect of offset accounts

## Features

- Calculate monthly payments and total interest
- View amortization schedules
- Compare different scenarios (baseline, lump sum, offset)
- Interactive graphs showing balance over time
- Export amortization schedules to CSV
- Mobile-friendly interface

## Installation

1. Clone this repository
2. Install the required dependencies:
```bash
pip install -r requirements.txt
```

## Usage

1. Run the application:
```bash
python app.py
```

2. Open your web browser and navigate to `http://localhost:5000`

3. Enter your mortgage details:
   - Principal amount
   - Annual interest rate
   - Term in years
   - Optional lump sum payment and month
   - Optional offset account amount

4. Click "Simulate" to see the results

## Default Values

The calculator comes with some default values:
- Principal: NZD 525,000
- Annual Interest Rate: 5.05%
- Term: 27.5 years
- Lump Sum: NZD 140,000 (month 1)
- Offset Amount: NZD 140,000

You can modify these values in the web interface as needed. 