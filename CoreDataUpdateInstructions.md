# Core Data Model Update Instructions

Follow these steps to update the Account entity in the Core Data model:

## Open the Data Model Editor

1. Open your project in Xcode
2. Navigate to the `SimpleBudget.xcdatamodeld` file in the Project Navigator
3. Click on it to open the Core Data model editor

## Update the Account Entity

1. Select the "Account" entity in the editor

2. In the Attributes inspector (right panel), ensure the Account entity has the following settings:
   - Class: "Account"
   - Module: "SimpleBudget" 
   - Codegen: "Class Definition"

3. Make sure the Account entity has the following attributes (add any that are missing):

| Attribute      | Type      | Optional | Default Value |
|----------------|-----------|----------|---------------|
| id             | UUID      | NO       | nil           |
| name           | String    | NO       | nil           |
| type           | String    | NO       | nil           |
| balance        | Double    | NO       | 0.0           |
| isDebt         | Boolean   | NO       | NO            |
| interestRate   | Double    | NO       | 0.0           |
| dueDate        | Date      | YES      | nil           |
| icon           | String    | YES      | nil           |
| notes          | String    | YES      | nil           |

4. Ensure the Account entity has the following relationships:

| Relationship   | Destination | Type      | Inverse              | Optional | Delete Rule |
|----------------|-------------|-----------|----------------------|----------|-------------|
| transactions   | Transaction | To-Many   | account (Transaction)| YES      | Nullify     |

5. Save the changes

## Update the Data Model Version

1. If your app has already been released or you have existing data:
   - Select the .xcdatamodeld file
   - Editor > Add Model Version
   - Set the new version as the current version in the model file inspector

2. Create a migration plan:
   - Compare old and new model versions
   - Set up a migration policy if needed

## Compile and Test

1. Build the project to ensure Core Data generates the updated model classes
2. Test the app to verify that the new attributes work correctly

## Notes

- After updating the Core Data model, you may need to clean and rebuild the project
- If you're working with existing data, make sure to perform migrations correctly
- You may need to update any code that uses the Account entity to handle the new attributes

