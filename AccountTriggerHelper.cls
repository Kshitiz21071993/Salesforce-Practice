public class AccountTriggerHelper {
/*
 *Develop an Apex Trigger so that every time when any account is created and Industry is Null 
 *then Set the Value of the Industry To Education.

 *AND


 *Develop an Apex Trigger so that every time when any account is created or updated 
 *then Set the Value of the Billing Address is to Shipping Address.
 */


    Public static Void UpdateAccountShippingAdreess(List<Account> AcclistRecord){
         for(Account acc : AcclistRecord){
             system.debug('Industry Value: '  + acc.Industry );
              if(acc.Industry == null){
                    acc.Industry = 'Education';
                }
                if(acc.Description == null){
                    acc.Description = 'Account Description is blank';
                }
                 //  acc.ShippingStreet == null => True
                if(acc.ShippingStreet == null || acc.ShippingCity == null || acc.ShippingState == null || acc.ShippingPostalCode == null|| acc.ShippingCountry == null){

                      acc.ShippingStreet         =  acc.BillingStreet; // data type must be same
                      acc.ShippingCity         =  acc.BillingCity;
                      acc.ShippingState         =  acc.BillingState;
                      acc.ShippingPostalCode  =  acc.BillingPostalCode;
                      acc.ShippingCountry     =  acc.BillingCountry;

                }
                
           }

    }
 /*
  * The business got to know that there are multiple accounts with the same name and rating. Now, as a developer, 
  * you need to make sure that no new duplicates are being created with the same name and rating.
  */
    
    
    Public Static Void CheckDuplicateAccount(List<Account> NewRecords){
       Set<String> AccountName = new Set<String>();
       Set<String> AccountRating = new Set<String>(); 
        
        for(Account acc : NewRecords){
            AccountName.add(acc.Name);
            AccountRating.add(acc.Rating);
        }
        
        List<Account> ExistingRecord = [Select Id, Name, Rating From Account where Name IN: AccountName AND Rating IN:AccountRating];
        for(Account acc : NewRecords){
            for(Account ExsRec : ExistingRecord){
                if(acc.Name == ExsRec.Name && acc.Rating == ExsRec.Rating){
                    try{
                    acc.addError('Duplicate Account Found');
                    acc.Name.addError('Duplicate Account Name Found');
                    acc.Rating.addError('Duplicate Account Name Found');
                    }
                    catch(System.Exception ex){
                        system.debug('Exception Executed for Duplcate Record ');
                    }
                }
            }
        }
    }

 /*
*Develop an Apex Trigger so that every time when any account is created add Task: 
*/
        Public Static Void AddTaskwithAccountCreation(List<Account> AccList){
             List<Task> tasklist = new List<Task>();
                                     for(Account acc : AccList){
                                         Task tk = new Task();
                                         tk.Subject = 'Create From Apex Trigger';
                                         tk.Status ='Not Started';
                                         tk.Priority ='High';
                                         tk.OwnerId = acc.OwnerId;
                                         tk.ActivityDate = Date.today().adddays(7);
                                         tk.WhatId = acc.Id;
                                         tasklist.add(tk);
                                     }
                                    insert tasklist;  
        }
    

}