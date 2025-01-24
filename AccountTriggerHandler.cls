public class AccountTriggerHandler {
    //Before Insert
    Public void handleBeforeInsert( List<Account> Acclist){
        system.debug('Inside handleBeforeInsert');
              AccountTriggerHelper.UpdateAccountShippingAdreess(Acclist);
              AccountTriggerHelper.CheckDuplicateAccount(Acclist);
            }
                 
    //Before Update
     Public void handleBeforeUpdate(List<Account> Acclist){
          system.debug('Inside handleBeforeUpdate');
              AccountTriggerHelper.UpdateAccountShippingAdreess(Acclist);
         if(Trigger.NewMap == Trigger.OldMap){
              AccountTriggerHelper.CheckDuplicateAccount(Acclist);
         }
    }
    
    //After Insert
    Public void handleAfterInsert(List<Account> AccList){
        system.debug('Inside handleAfterInsert');
          AccountTriggerHelper.AddTaskwithAccountCreation(AccList);
}
}