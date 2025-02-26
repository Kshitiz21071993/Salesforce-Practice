/**
 * @description       : Assignment Trigger Handler which will be used for all trigger events
 * @author            : Srushti Bikkannavar
 * @group             :
 * @last modified on  : 08-17-2024
 * @last modified by  : Nithin C.H
**/
 
public inherited sharing class TB_AssignmentTrigger implements fferpcore.PluggableTriggerApi.Plugin {
   
    private List<pse_Assignmentc> records = new List<pseAssignment_c>();
    private Boolean isBypassFlagEnabled = false;
    public static final String TB_ASSIGNMENTCREATE = 'Create';
    public static final String TB_ASSIGNMENTTUPDATE = 'Update';
    private Boolean isBypassPlatformEventsFlag = false;
    // Store the instance of TB_TeamBuilderSettings__c  
    private TB_TeamBuilderSettings__c teamBuilderSettings;
   
    /**
    * @description Constructor of TB_AssignmentTrigger class
    * @param records List of new records
    */
    public TB_AssignmentTrigger(List<SObject> records) {
        this.records = (List<pse_Assignment_c>) records;
       
        // Get the instance of TB_TeamBuilderSettings__c  
        this.teamBuilderSettings = TB_TeamBuilderSettings__c.getInstance();  
         
        // Check if the trigger should be bypassed based on user settings  
        this.isBypassFlagEnabled = this.teamBuilderSettings.TB_Bypass_Apex_Triggers__c;  
        // Check if platform events generation should be bypassed based on user settings  
        this.isBypassPlatformEventsFlag = this.teamBuilderSettings.TB_Bypass_Platform_Events__c;
    }
   
    /**
    * @description Handles before insert for Assignment
    */
    public void onBeforeInsert() {
        if(!this.isBypassFlagEnabled && !TB_Recursion_Handler.runOnce(Trigger.newMap?.keySet(), Trigger.oldMap?.keySet(), Trigger.operationType)){
            new TB_AssignmentHelper().beforeInsertDirector(this.records);
            new TB_AssignmentTriggerHelper().beforeInsertDirector(this.records);
        }
       
    }
   
    /**
    * @description Handles after insert for Assignment
    */
    public void onAfterInsert() {
        Map<Id, pse_Assignmentc> recordsMap = new Map<Id, pseAssignment_c>(this.records);
        TB_AssignmentHelper assignmentHelper = new TB_AssignmentHelper();
        if(!this.isBypassFlagEnabled && !TB_Recursion_Handler.runOnce(Trigger.newMap?.keySet(), Trigger.oldMap?.keySet(), Trigger.operationType) ){
       
            assignmentHelper.addProjectTeamMembers(this.records);
            //assignmentHelper.insertAssignToScheduleEvent (recordsMap);
            if(!System.isQueueable()){
                assignmentHelper.shareRecordsWithProjectTeamMembers(this.records);
            }else{
                TB_AssignmentHelper.shareRecords(recordsMap.keySet());
            }
            assignmentHelper.afterInsertDirector(this.records, recordsMap);
            assignmentHelper.getProjectIds(this.records,null);
            new TB_AssignmentTriggerHelper().afterInsertDirector(this.records, recordsMap);
        }
        //Moving the integration logic for creating Platform events outside of recursion checks
        //to ensure that no events triggered by indirect field updates are missed.
        //Recursion can prevent these events creation and disrupt data synchronization.
        if(!this.isBypassFlagEnabled && !this.isBypassPlatformEventsFlag){
            assignmentHelper.assignmentPlatformEventPublish(this.records, recordsMap,null,TB_ASSIGNMENTCREATE);
        }
    }
   
    /**
    * @description Handles before update for Assignment
    * @param existingRecords Map of Old Assignment.
    */
    public void onBeforeUpdate(Map<Id, SObject> existingRecords) {
        if(!this.isBypassFlagEnabled) {//Removed Recursion check for Before Update Trigger, oldmap and newmap resources were giving same values after swap the resource.
            Map<Id, pse_Assignmentc> recordsMap = new Map<Id, pseAssignment_c>(this.records);
            new TB_AssignmentTriggerHelper().beforeUpdateDirector(recordsMap.values());
            new TB_AssignmentHelper().beforeUpdateDirector(recordsMap, (Map<Id, pse_Assignment_c>)existingRecords);
        }
    }
   
    /**
    * @description Handles after update for Assignment
    * Used in triggers or trigger handlers to handle post-update tasks.
    * @param existingRecords Map of Assignment records before update, keyed by IDs.
    */
    public void onAfterUpdate(Map<Id, SObject> existingRecords) {
        Map<Id, pse_Assignmentc> recordsMap = new Map<Id, pseAssignment_c>(this.records);
        Map<Id, pse_Assignmentc> existingAssignmentRecords = (Map<Id, pseAssignment_c> )existingRecords;
        TB_AssignmentHelper assignmentHelper = new TB_AssignmentHelper();
        if(!this.isBypassFlagEnabled && !TB_Recursion_Handler.runOnce(Trigger.newMap?.keySet(), Trigger.oldMap?.keySet(), Trigger.operationType) ){
           
            assignmentHelper.getProjectIds(this.records, existingAssignmentRecords);
            assignmentHelper.afterUpdateDirector(recordsMap.values(), existingAssignmentRecords);
            new TB_AssignmentTriggerHelper().afterUpdateDirector(this.records,existingAssignmentRecords);
 
            // Instantiates TB_AssignmentEmailNotification class to send email notifications.
            TB_AssignmentEmailNotification objNotification= new TB_AssignmentEmailNotification();
            // Sends email notifications for the updated Assignment records.
            objNotification.sendNotification(recordsMap.values(), existingAssignmentRecords);
        }
       
        //Moving the integration logic for creating Platform events outside of recursion checks
        //to ensure that no events triggered by indirect field updates are missed.
        //Recursion can prevent these events creation and disrupt data synchronization.
        if(!this.isBypassFlagEnabled){
            assignmentHelper.updateScheduleField(recordsMap, existingAssignmentRecords);  //method used for updating FlexForecast StaffLine ID field on Schedule
        }
        if(!this.isBypassFlagEnabled && !this.isBypassPlatformEventsFlag){
            assignmentHelper.assignmentPlatformEventPublish(null,recordsMap, existingAssignmentRecords, TB_ASSIGNMENTTUPDATE);
        }
    }
   
    /**
    * @description Handles after delete for Assignment
    */
    public void onAfterDelete() {
        if(!this.isBypassFlagEnabled  && !TB_Recursion_Handler.runOnce(Trigger.newMap?.keySet(), Trigger.oldMap?.keySet(), Trigger.operationType)){
            new TB_AssignmentHelper().getProjectIds(this.records, null);
            new TB_AssignmentTriggerHelper().afterDeleteDirector(this.records);
        }
    }
   
    /**
    * @description Handles before delete for Assignment
    */
    public void onBeforeDelete() {
        if(!this.isBypassFlagEnabled  && !TB_Recursion_Handler.runOnce(Trigger.newMap?.keySet(), Trigger.oldMap?.keySet(), Trigger.operationType)){
            new TB_AssignmentTriggerHelper().validateRecordsBeforeDelete(this.records);
        }
    }
   
    /**
    * @description Handles after undelete for Assignment
    */
    public void onAfterUndelete() {
        if(!this.isBypassFlagEnabled){
            new TB_AssignmentHelper().getProjectIds(this.records, null);
        }
    }
}