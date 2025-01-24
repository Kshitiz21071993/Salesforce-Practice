public with sharing class RollUpSummaryExample{
    public static void handleRollup(List<Contact> contacts) {
        // Step 1: Get all affected Account IDs
        Set<Id> accountIds = new Set<Id>();
        for (Contact c : contacts) {
            if (c.AccountId != null) {
                accountIds.add(c.AccountId);
            }
        }

        // Step 2: Query related Contacts for these Accounts
        List<Contact> relatedContacts = [
            SELECT Id, AccountId
            FROM Contact
            WHERE AccountId IN :accountIds
        ];

        // Step 3: Call the RollUpSummaryCalculator to update the Account field
        RollUpSummaryCalculator.updateRollup(
            relatedContacts,               // List of child records (Contacts)
            'Account',                     // Parent object name
            'Number_of_Contacts__c',       // Field to update on the parent
             null,                          // Pass null for counting
            'AccountId'                    // Lookup field linking child to parent
        );
    }
}