public with sharing class AddPrimaryContact implements Queueable{
// Class variables to store the input arguments
    private Contact contactToInsert;
    private String stateAbbreviation;

 // Constructor to set the class variables
    public AddPrimaryContact(Contact contact, String stateAbbr) {
        this.contactToInsert = contact;
        this.stateAbbreviation = stateAbbr;
    }
    public void execute(QueueableContext context){
     // Query Accounts with the specified BillingState, limit to 200
     List<Account> accounts = [SELECT Id
                               FROM Account
                               WHERE BillingState = :stateAbbreviation
                               LIMIT 200];
     // List to hold new Contact records to insert
     List<Contact> contacts = new List<Contact>();
     for (Account acc : accounts) {
         // Add the cloned contact to the list of contacts to be inserted.
         contact cloneObj = contactToInsert.clone(false, false, false,false);
         cloneObj.AccountId = acc.Id;
         contacts.add(cloneObj);        
     }

     if(contacts.size() > 0){
         insert contacts;
     }
    }
}