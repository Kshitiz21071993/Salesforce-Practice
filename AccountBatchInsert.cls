public class AccountBatchInsert implements Database.Batchable<SObject> {
    
    // Class-level variable declaration
    private List<Account> accList;

    public Database.QueryLocator start(Database.BatchableContext BC) {
        System.debug('Inside Start Method Of Batch Job.');
        // No query needed for batch insert, so return an empty query.
        return Database.getQueryLocator([SELECT Id FROM Account]);
    }

    public void execute(Database.BatchableContext BC, List<SObject> scope) {
        System.debug('Inside Execute Method Of Batch Job.');
        
        // Initialize the list if it's not already initialized
        if (accList == null) {
            accList = new List<Account>();
        }

        // Example loop to insert two accounts
        for(Integer i = 0; i <2000; i++) {
            accList.add(new Account(
                Name = 'Test Account Priyanka ' + i,
                First_Name__c = 'Test Account' + i,
                Last_Name__c = 'Priyanka' + i,
                Rating = 'Cold'
            ));
        }

        System.debug('Inserting Account(s): ' + accList.size());
        insert accList;
    }

    public void finish(Database.BatchableContext BC) {
        // Now you can access accList here because it's declared at the class level
        System.debug('List of Accounts processed: ' + accList);
        System.debug('Batch Process Completed.');
    }
}