public class ContactTriggerHelper {
    
 /*
  * Develop an Apex Trigger to prevent the duplicate Contact record using Name & Email. 
  * So if there are duplicate records with the same Name & Email new Record should not get created.
  */  
    Public Static Void PreventDuplicateContact(List<Contact> NewRecords){
        Set<String> ContactName = new Set<String>();
        Set<String> ContactEmail = new Set<String>();
        for(Contact Con: NewRecords){
            ContactName.add(Con.Name);
            ContactEmail.add(Con.Email);
        }
        List<Contact> ExistingContact = [SELECT Id, Name, Email 
                                         FROM Contact 
                                         WHERE Name IN :ContactName AND Email IN:ContactEmail];
        
                for(Contact Con: NewRecords){
                    for(Contact ExsContact  : ExistingContact){
                        if(ExsContact.Name.contains(Con.Name) && ExsContact.Email.Contains(Con.Email)){
                            Con.addError('Duplicate Contact Found');
                            //Con.Name.addError('Duplicate Contact Found');
                           // Con.Name.
                           // 
                }
            }
        }
    }
    
/*
Develop an Apex Trigger on the Contact record so that when any Contact is created under any Account Record then, please
o	Populate the Contact Mailing Address with Account Shipping Address
o	Populate the Contact Other Address with the Account Billing Address
*/
    
    Public static void ContactAddreessSameAsAccountAddress(Map<Id, Contact> newMapRecords){
        system.debug('Inside ContactAddreessSameAsAccountAddress'); 
        Map<Id, Contact> newRecords = new Map<Id, Contact>([SELECT Id, Name,AccountId FROM Contact WHERE Id IN: NewMapRecords.keySet()]);
        Set<Id> AccId = new Set<Id>();
        for(Contact con  : newRecords.values()){
            if(con.AccountId != null){
             AccId.add(con.AccountId);
        }  
     }
        
        /*List<Account> AccRecord = [SELECT Id, ShippingAddress, BillingAddress
                                   FROM Account
                                   WHERE ID IN :AccId];
        */
 Map<Id, Account> accountMap = new Map<Id, Account>([SELECT Id,ShippingStreet,ShippingCity,ShippingState,ShippingPostalCode,ShippingCountry,
                                                    BillingStreet, BillingCity, BillingState, BillingPostalCode,BillingCountry
                                                    FROM Account
                                                    WHERE ID IN :AccId]);
        
                                        for(Contact con  : newRecords.values()){
                                           /* for(Account acc : AccRecord){
                                                if(acc.id == con.AccountId){
                                           */
                                            if(accountMap.containsKey(con.AccountId)){
                                             Account acc = accountMap.get(con.AccountId);
                                                
                                            
                                                con.MailingStreet = acc.ShippingStreet;
                                                con.MailingCity = acc.ShippingCity;
                                                con.MailingState = acc.ShippingState;
                                                con.MailingPostalCode = acc.ShippingPostalCode;
                                                con.MailingCountry = acc.ShippingCountry;
                                                
                                                // Populate Other Address fields
                                                con.OtherStreet = acc.BillingStreet;
                                                con.OtherCity = acc.BillingCity;
                                                con.OtherState = acc.BillingState;
                                                con.OtherPostalCode = acc.BillingPostalCode;
                                                con.OtherCountry = acc.BillingCountry;
                                            }
                            }
                        }

/*
 * Solution that will count the related contact related to the Account and store the information in the “Number of Contacts” field. 
 * Solution 1 - Using SubQuery which will fail while working with bulk record:    

    Public Static Void updateNumberOfContact(Set<Id> ConRecordsId){

        List<Contact> ConRecords = [SELECT Id, Name,AccountId FROM Contact WHERE Id IN :ConRecordsId];
        Set<Id> ConAccId = new Set<Id>();
        for(Contact Con : ConRecords){
            if(Con.AccountId != Null){
                ConAccId.add(Con.AccountId);
            }
        }
         system.debug('Size of Contact Account Ids'+ConAccId.size());   
        
         List<Account> AccList = [SELECT ID, Name, 
                                        (SELECT Id 
                                         FROM CONTACTS)
                                  FROM Account 
                                  WHERE ID IN : ConAccId];  
            system.debug('Retrieved data with size '+AccList.size());
            List<Account> updatedAccounts = new List<Account>();
            for(Account acc : AccList ){
                List<Contact> ConList = acc.Contacts;
                if(!ConList.IsEmpty()){
                    Integer Size = ConList.Size();
                    acc.Number_Of_Contacts__c = Size;
                    //updatedAccounts.add(acc);
                    
                } else{
                    acc.Number_Of_Contacts__c = 100;
                    
                }  
                updatedAccounts.add(acc);
            }
            Update updatedAccounts;
 */

        
//  Solution 2 - Using Aggregate Query which will be more efficient for bulk records:

     Public Static Void updateNumberOfContact(Map<Id, Contact> newRecordsMap)
     {
        /* 
         * key - RecordId
         * value - Record
         * keySet() - Set<Key> - Set<Id>
         * values() - List<Value> - List<Account>
        */

        /* Step1 - Get Account Ids */

        Set<Id> AccIdList = new Set<Id>();
        for(Contact Con : newRecordsMap.values())
        {
            if(Con.AccountId != Null)
            {
                AccIdList.add(Con.AccountId);
            }
        } 
         
         List<AggregateResult> AggregateList = [SELECT Count(Id) ContactCount, AccountId
                                               FROM Contact 
                                               WHERE AccountId IN: AccIdList
                                               GROUP BY AccountId];
         
         List<Account> AccountListToUpdate = new List<Account>();
         
         for(AggregateResult ag : AggregateList)
         {
             Integer ContactCount = (Integer)ag.get('ContactCount');
             String  AccountId = (String)ag.get('AccountId');
             Account acc = new Account();
             acc.Id = AccountId;
             acc.Number_Of_Contacts__c = ContactCount;
             AccountListToUpdate.add(acc);            
         }
         update AccountListToUpdate;
         
       }
    }