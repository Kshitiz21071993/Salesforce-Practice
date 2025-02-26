/**
* @author : Srushti
* @date : 07/03/2024
* @description : This queueable class is used to create Assignments from Held RRs.
* @Story : #257073
* @revisions
* [Date]             [Owner]      [Defect/Story]       [Description]
*/
 
public class TB_CreateAssignmentFromHeldRR_Queueable implements Queueable  {
    private static final String PROJECT_FIELD_API_NAME = 'pse_Project_c';
    //boolean to bypass TB_RecordSharingAsyncProcessor in Assignment Trigger
    public static Boolean assignmentFromQueueable = false;
    private static Integer past7Days = -7;
    private static Integer future30Days = 30;
    private static Integer future3Days = 3;
 
   
    /**
    * @MethodName: execute
    * @Description: This method contains the logic to create Assignments and update RR
    * @param : Queueable context
    * @createdDate : 07/03/2024
    * @Story : #257073
    * @return void
    */

 public void execute(QueueableContext context) {
        List<pse_Assignmentc> listOfAssignmentsToCreate = new List<pseAssignment_c>();
        Map<Id,pse_Resource_Requestc> resourceRequestMap = new Map<Id,pseResource_Request_c>();
        Date pastDays = System.today().addDays(past7Days);
        Date futureWeekDays = System.today().addDays(future3Days);
        Date futureDays = System.today().addDays(future30Days);
               
        try{
            //Query and iterate all the RRs which are in Held status and Project is in Ready to Staff/Submitted
            for(pse_Resource_Requestc eachRR: [SELECT Id, TB_Opportunity_Statusc, TB_Sub_LoS_1c, pseStart_Datec, TB_LoSc, pseProject_c,
                                                  TB_Project_Status_c, pseStatusc, psePreferred_Schedulec, pseStaffer_Resource_c
                                                  FROM pse_Resource_Request_c
                                                  WHERE pse_Status_c =: TB_ConstantClass.RESOURCE_REQUEST_REQUEST_STATUS_HELD
                                                  AND (TB_Project_Status__c =: TB_ConstantClass.RESOURCE_REQUEST_PROJECT_STAGE_READY_TO_STAFF
                                                       OR TB_Project_Status__c =: TB_ConstantClass.RESOURCE_REQUEST_REQUEST_STATUS_SUBMITTED)
                                                  AND pse_Staffer_Resourcec != NULL AND pseAssignmentc = NULL AND (pseStart_Datec >=: pastDays AND pseStart_Date_c <=: futureDays)]){
                                                      if( (eachRR.TB_LoS_c != null && eachRR.TB_LoSc == TB_ConstantClass.ADVISORY_SUB_LOS_1 && eachRR.TB_Opportunity_Status_c == TB_ConstantClass.WON_OPPTY_STAGE
                                                          && (eachRR.pse_Start_Datec >= pastDays && eachRR.pseStart_Date_c <= futureWeekDays) &&
                                                         eachRR.TB_Project_Status__c == TB_ConstantClass.RESOURCE_REQUEST_PROJECT_STAGE_READY_TO_STAFF) ||
                                                         ((eachRR.TB_Sub_LoS_1_c != null && (eachRR.TB_LoSc != null && (eachRR.TB_Sub_LoS_1c == TB_ConstantClass.CONSULTING_SOL_SUB_LOS_1 || eachRR.TB_Sub_LoS_1_c == TB_ConstantClass.TRUST_SOL_SUB_LOS_1)
                                                            && eachRR.TB_LoS__c == TB_ProjectConstants.LOS_TYPE_TAX)
                                                           || eachRR.TB_Sub_LoS_1_c == TB_ProjectConstants.LOS_TYPE_ASSURANCE) && (eachRR.pseStart_Datec >= pastDays && eachRR.pseStart_Date_c <= futureDays))) {
                                                               //call createAssignment method to create and link an Assignment to the RR
                                                               pse_Assignmentc assignment = createAssignment(eachRR.pseProjectc, eachRR.pseStaffer_Resourcec, eachRR.Id, eachRR.psePreferred_Schedule_c);
                                                               resourceRequestMap.put(eachRR.Id,eachRR);
                                                               listOfAssignmentsToCreate.add(assignment);
                                                           }
                                                  }
           
            Set<Id> newAssignmentsIds = new Set<Id>();
            if(!listOfAssignmentsToCreate.isEmpty()){
                //Mark boolean to true to bypass this TB_RecordSharingAsyncProcessor and chain it in this class
                assignmentFromQueueable = true;
                Database.SaveResult[] saveResults = Database.insert(listOfAssignmentsToCreate, false);
                for (Database.SaveResult saveResult : saveResults) {
                    if (saveResult.isSuccess()) {
                        newAssignmentsIds.add(saveResult.getId());
                    }
                }
            }
           
            if(!listOfAssignmentsToCreate.isEmpty() && !newAssignmentsIds.isEmpty()){
                //call updateResourceRequests to update RRs
                updateResourceRequests(listOfAssignmentsToCreate, newAssignmentsIds, resourceRequestMap);
            }
            if(!newAssignmentsIds.isEmpty()){
                //call chainQueuable to chain the next job
                chainQueuable(newAssignmentsIds);
            }
 
        }catch(exception exp){
            SDF_LGR_LoggerManager.DBLoggerTB.error(exp, 'TB_CreateAssignmentFromHeldRR_Queueable', 'execute');
        }
    }
   
   
    /**
    * @MethodName: createAssignment
    * @Description: This method will create an Assignment and link it to the RR
    * @param : Id projId, Id resourceId, Id resourceReqId, Id scheduleId
    * @createdDate : 07/03/2024
    * @Story : #257073
    * @return pse_Assignment_c
    */
   
    private pse_Assignment_c createAssignment(Id projId, Id resourceId, Id resourceReqId, Id scheduleId){
        //Create a new Assignment
        pse_Assignmentc assignment = new pseAssignment_c();
        assignment.pse_Project_c = projId;
        assignment.pse_Resource_c = resourceId;
        assignment.pse_Resource_Request_c = resourceReqId;
        assignment.pse_Schedule_c = scheduleId;
        return assignment;
    }
   
    /**
    * @MethodName: updateResourceRequests
    * @Description: This method updates the RRs
    * @param : List<pse_Assignmentc> assignments, Set<Id> assignmetnIds, Map<Id,pseResource_Request_c> rrMap
    * @createdDate : 07/03/2024
    * @Story : #257073
    * @return void
    */
   
    private void updateResourceRequests(List<pse_Assignmentc> assignments, Set<Id> assignmetnIds, Map<Id,pseResource_Request_c> rrMap){
        List<pse_Resource_Requestc> listOfRRToUpdate = new List<pseResource_Request_c>();
        for(pse_Assignment_c assignment: assignments){
            if(assignmetnIds.contains(assignment.Id) && rrMap.containsKey(assignment.pse_Resource_Request_c)){
                //Tag the assignment record and update status of RR to Assigned
                pse_Resource_Requestc eachRR = new pseResource_Request_c();
                eachRR.pse_Status_c = TB_ConstantClass.RESOURCE_REQUEST_REQUEST_STATUS_ASSIGNED;
                eachRR.pse_Assignment_c = assignment.Id;
                eachRR.Id = rrMap.get(assignment.pse_Resource_Request_c).Id;
                listOfRRToUpdate.add(eachRR);
            }
        }
       
        //update RR records
        if(!listOfRRToUpdate.isEmpty()){
            List<Database.SaveResult> saveResults = Database.update(listOfRRToUpdate, false);
            SDF_LGR_LoggerManager.DBLoggerTB.error(saveResults, 'TB_CreateAssignmentFromHeldRR_Queueable', 'updateResourceRequests');
        }
    }
   
     /**
    * @MethodName: chainQueuable
    * @Description: This method chains the next job
    * @param : List<pse_Assignment_c> assignments
    * @createdDate : 07/03/2024
    * @Story : #257073
    * @return void
    */
   
    @future
    private static void chainQueuable(Set<Id> assignmentIds){
        //Custom setting
        TB_TeamBuilderSettings_c tbSettingsInstance = TB_TeamBuilderSettings_c.getInstance();
        //chain TB_RecordSharingAsyncProcessor queueable
        //call TB_AssignmentEmailNotification queueuable in TB_RecordSharingAsyncProcessor
        List<pse_Assignmentc> assignments = [SELECT Id,pseStatusc, pseProjectc, pseResourcec, pseResource_Requestc, pseSchedule_c
                                                FROM pse_Assignment_c WHERE Id IN: assignmentIds];
        TB_AssignmentEmailNotification emailNotificationService = new TB_AssignmentEmailNotification(assignments, null);
        TB_RecordSharingAsyncProcessor sharingProcessor = new TB_RecordSharingAsyncProcessor(assignments, PROJECT_FIELD_API_NAME, TB_ConstantClass.ASSIGNMENT_SHARE_API_NAME, emailNotificationService);
        sharingProcessor.setParentObjectInfo(TB_ConstantClass.SCHEDULE_SHARE_API_NAME, 'pse_Schedule_c');
        Integer delayInMinutes = Integer.ValueOf(tbSettingsInstance.TB_DelayInMinutes__c) ;
        TB_Utility.asyncExecutionLimitEmail();
        if(!tbSettingsInstance.TB_Project_Rel_Records_Sharing_Bypass__c){
            System.enqueueJob(sharingProcessor, delayInMinutes);
        }
       
    }
}