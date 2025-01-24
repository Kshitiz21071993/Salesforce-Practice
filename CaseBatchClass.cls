public class CaseBatchClass implements Database.batchable<sObject>, Database.Stateful{
    
    // instance member to retain state across transactions
    public Integer recordsProcessed = 0;
    
    Public Database.QueryLocator start(Database.batchableContext bc){
        System.debug('Inside Start Method');
        System.debug('recordsProcessed ' + recordsProcessed);
        return Database.getQueryLocator(
            'Select Id, Status, CreatedBy.Name, CreatedBy.Email FROM Task WHERE Status = \'Not Started\''
            
        );
    }
    public void execute(Database.BatchableContext bc, List<Task> Scope){
         System.debug('Inside Execute Method' + Scope );
         System.debug('Inside ExecuterecordsProcessed ' + recordsProcessed);
         List<Task> TaskUpdate = new List<Task>();
         System.debug('Inside caseUpdate ' + TaskUpdate);
         for(Task cs : Scope ){
             cs.Status = 'In Progress';
             TaskUpdate.add(cs);
             recordsProcessed = recordsProcessed + 1;
             System.debug('UpdatedrecordsProcessed ' + recordsProcessed);
            }
            update TaskUpdate;
            System.debug('TaskUpdated ' + recordsProcessed);
         System.debug('Inside UpdatedTask ' + TaskUpdate);
    }
       
    
    public void finish(Database.BatchableContext bc){
        
        
    }
    
    
}