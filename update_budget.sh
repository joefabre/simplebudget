#!/bin/bash

echo "SimpleBudget - Set Budget to Zero Utility"
echo "=========================================="
echo "This script will set all budget amounts to 0."

# Find the Core Data SQLite database file
DB_FILE=$(find ~/Library/Developer/CoreSimulator/Devices -name "SimpleBudget.sqlite" 2>/dev/null | head -n 1)

if [ -z "$DB_FILE" ]; then
  echo "Error: Could not find SimpleBudget.sqlite database file."
  exit 1
fi

echo "Found database at: $DB_FILE"
echo "Updating budget amounts to 0..."

# Run the SQL script on the database
sqlite3 "$DB_FILE" < update_budget.sql

if [ $? -eq 0 ]; then
  echo "Budget successfully set to zero."
  echo "You'll see this change next time you open the app."
else
  echo "Error: Failed to update the database."
  echo "Try launching the app and setting the budget to 0 manually."
  exit 1
fi

