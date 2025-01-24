@IsTest(seeAllData=false)
public class AccountTriggerTest {
    
 @TestSetup()
    Private static Void SetUpdata(){
        List<Account> accountList = new List<Account>();
        Account accountRecord = new Account();
        accountRecord.Name = 'Test Account';
        accountRecord.Phone = '9087654321';
        accountRecord.First_Name__c = 'Test';
        accountRecord.Last_Name__c = 'Tes1';
        accountList.add(accountRecord);

        Account accountRecord1 = new Account();
        accountRecord1.Name = 'Test Account';
        accountRecord1.Phone = '9087654321';
        accountRecord1.ShippingStreet = '123 Main Street';
        accountRecord1.First_Name__c = 'Test';
        accountRecord1.Last_Name__c = 'Tes1';
        accountList.add(accountRecord1);

        insert accountList;
 
         List<Account> accList = [Select Id,name,Description,rating,Phone,Industry 
                             FROM Account
                             where name = 'Test Account'];
        system.debug('Inside setup data acc with same name size '+accList.size());
        
    }
    
    @IsTest
    Private Static void BeforeInsert(){
        
              
         Account newRecord3 = new Account();
        newRecord3.Name ='Iron Mountain2';
        newRecord3.Phone = '90713433773';
        newRecord3.First_Name__c = 'Iron';
        newRecord3.Last_Name__c = 'Mountain2';
      Test.startTest();         
            try{
                insert newRecord3; 
               }
                catch(DmlException e) {
                System.debug('The following exception has occurred: ' + e.getMessage());
                }  
        Test.stopTest(); 
    }
       
     @IsTest
    Private Static void BeforeUpdate(){
        Account accountRecord2 = new Account();
        accountRecord2.Name = 'Test Account1';
        //accountRecord2.Phone = '9087654321';
        accountRecord2.ShippingStreet = '123 Main Street';
        accountRecord2.ShippingCity = 'Florida';
        accountRecord2.First_Name__c = 'Test';
        accountRecord2.Last_Name__c = 'Tes1';
        //accountList.add(accountRecord2);
        insert accountRecord2;
        
        List<Account> accList = [Select Id,name,Description,rating,Phone,Industry 
                             FROM Account
                             where name = 'Test Account1'];
        Account account = accList.get(0);
        account.name = 'Test Account1_Updated';
        update account;
    }

    
    }