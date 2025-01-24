public class ContactsBatchClass implements Database.Batchable<sObject>, Database.Stateful{
  
   // Maintains the states of the variables  
    private Integer successCount = 0;    
    private Integer failureCount = 0;
   /*private String query;   
   private Set<Id> contactIdsSet;    
   public ContactsBatchClass(String query, Set<Id> contactIdsSet){        
   this.query = query;
   }
   public ContactsBatchClass(){}
   */
   public Database.QueryLocator start(Database.BatchableContext batchContext){       
       System.debug('Start Method');
       return Database.getQueryLocator('SELECT Id, FirstName, Fax, Description, LastName, Name, Email, Phone, Account.Phone FROM Contact LIMIT 10000');
      }
  
   public void execute(Database.BatchableContext batchContext, List<Contact> contactList){
       System.debug(' contactList '+contactList.size());       
       for(Contact con: contactList){            
       con.FirstName = 'Batch';            
       con.Phone = con.Account.Phone;           
       con.Description = con.Description;           
       con.Fax = con.Fax;
      }
       List<Database.SaveResult> saveResult = Database.update(contactList, false);    
        System.debug(' contactList Updated'); 
       for(Database.SaveResult sr: saveResult){          
       if(sr.isSuccess()){              
        successCount = successCount + 1;
            System.debug(' contactList Updated' + successCount); 
           }else{
               failureCount = failureCount + 1;
               //System_Event__c event = Logger.logError('Simple Title');               
              // insert event;
             System.debug(' contactList Updated' + failureCount); 
           }
       }
   }
  
   public void finish(Database.BatchableContext batchContext){
       System.debug('Finish Method');
       System.debug(' successCount '+ successCount);
       System.debug(' failureCount '+ failureCount);
   }
}