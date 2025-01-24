public with sharing class OpportunityTriggerHelper {

/*
Method to Calculate Discount
*/
    Public Static Void discountCalculation(List<Opportunity> newRecords){
         for(Opportunity opp : newRecords){
            if(opp.Discount__c != Null && opp.Amount != Null){
                Decimal discount = (opp.Discount__c*Opp.Amount)/100;
                Decimal discountedAmount  = opp.Amount - discount;
                opp.Discounted_Price__c = discount;
                opp.PriceAfterDiscount__c = discountedAmount;
            }
        }  
    }

/*
Name: ClosedOpportunityTrigger, Object: Opportunity, Events: after insert and after update 
Condition: Stage is Closed Won , Operation: Create a task, Subject: Follow Up Test Task
WhatId: the opportunity ID (associates the task with the opportunity) 
Bulkify the Apex trigger so that it can insert or update 200 or more opportunities.
*/
public static void closedOpportunity(List<Opportunity> newRecords, Map<Id, Opportunity> oldRecords) {
    // List to hold tasks
    List<Task> taskList = new List<Task>();

    for (Opportunity newOpp : newRecords) {
        //If both conditions are true (oldRecords is not null and contains the newOpp.Id), 
        //fetch the old record: oldRecords.get(newOpp.Id).Otherwise, assign null to oldOpp.

        Opportunity oldOpp = (oldRecords != null && oldRecords.containsKey(newOpp.Id)) ? oldRecords.get(newOpp.Id) : null;

        // Condition: StageName is 'Closed Won' and either it's a new record or the stage has changed
        if (newOpp.StageName == 'Closed Won' && (oldOpp == null || newOpp.StageName != oldOpp.StageName)) {
            taskList.add(new Task(
                Subject = 'Follow Up Test Task',
                WhatId = newOpp.Id
            ));
        }
    }

    // Insert tasks if the list is not empty
    if (!taskList.isEmpty()) {
        insert taskList;
    }
}
}