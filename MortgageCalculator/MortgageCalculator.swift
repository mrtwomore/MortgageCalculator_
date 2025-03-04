// This file is kept for compatibility but all functionality has been moved
// to dedicated files with better organization.
//
// See:
// - Models/Models.swift - All data models
// - Models/MortgageCalculatorService.swift - Calculation services
// - Models/ScenarioStore.swift - Scenario storage
// - Views/* - UI components
//
// This reorganization improves:
// - Performance by eliminating redundant calculations
// - Memory usage by optimizing data structures
// - Code maintainability through better separation of concerns 

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
} 