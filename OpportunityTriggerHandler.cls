public with sharing class OpportunityTriggerHandler {
    
    Public Void handleBeforeInsert(List<Opportunity> oppRecords){
        OpportunityTriggerHelper.discountCalculation(oppRecords);
   }
    
    Public Void handleBeforeUpdate(List<Opportunity> oppRecords){
        OpportunityTriggerHelper.discountCalculation(oppRecords);
      
    }
    
    
    Public Void handleAfterInsert(List<Opportunity> oppRecords, Map<Id,Opportunity> oldOppRecords){
        for(Opportunity opp : oppRecords){
            if(opp.Discount__c != Null && opp.Amount != Null){
                Decimal discount = (opp.Discount__c*opp.Amount)/100;
                Decimal discountedAmount  = opp.Amount - discount;
                opp.Discounted_Price__c = discount;
                opp.PriceAfterDiscount__c = discountedAmount;
            }
    } 
    
    
}
    Public Void handleAfterInsertorUpdate(List<Opportunity> oppRecords, Map<Id,Opportunity> oldOppRecords){
        OpportunityTriggerHelper.closedOpportunity(oppRecords, oldOppRecords);

}
}