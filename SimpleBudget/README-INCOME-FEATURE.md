# Income Management Feature for SimpleBudget

This document provides an overview of the income management feature added to the SimpleBudget app.

## Features Added

### 1. Income Sources Management
- Users can add multiple income sources when creating or editing a budget
- Each income source includes name, amount, and frequency (monthly, bi-weekly, weekly)
- Automatic calculation of monthly equivalent value for different payment frequencies

### 2. Budget Validation
- Expenses budget can be validated against total income
- Warning displayed if budget exceeds available income
- Remaining amount calculation shows the difference between income and budget

### 3. Dashboard Updates
- Dashboard now shows total monthly income
- Income usage visualization with progress bars
- Budget allocation indicator showing how much of income is allocated
- "Available" metric showing remaining funds after expenses
- Number of income sources indicator

### 4. Data Persistence
- Income sources are stored as JSON in the Core Data model
- Backward compatible with existing budgets (which have no income sources)

## Technical Implementation

### Core Data Model
- Added `incomeSourcesJSON` attribute to the Budget entity to store serialized income sources

### Budget Extension
- Created `Budget+Extensions.swift` to add income management functionality
- Defined `IncomeSource` struct with name, amount, and frequency properties
- Added computed properties for `totalMonthlyIncome` and `remainingBudget`
- Implemented JSON serialization/deserialization for income sources

### UI Components
- Enhanced AddBudgetView with income sources management
- Updated DashboardView to display income information
- Added appropriate visualization components for income vs. expenses

## Usage
1. When creating a budget, tap "Add Income Source"
2. Enter income source details (name, amount, frequency)
3. Add multiple income sources as needed
4. Set your expense budget
5. Dashboard will show the relationship between income and expenses

## Future Enhancements
- Category-specific budgeting based on income
- Income forecasting and trends
- Multiple currency support
- Income vs. expense reports

