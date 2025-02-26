/**
* @description       : Handles sending email notifications to users based on Creation/Updatation on Assignment if Status = Assigned
* @author            : Ishita Sonchhatra
* @created date      :
* @group             :
* @last modified on  : 09-24-2024
* @last modified by  : Archie Agrawal
* TB_Assignment_Resource_Assignment_Notification
**/
public class TB_AssignmentEmailNotification implements TB_QueueableWrapper {
        // Indicates whether to perform a chain job for email notifications.  
        @testVisible
        private static Boolean doChainJob = true;
        private List<pse_Assignment_c>  newAssignmentsList;
        private Map<Id,pse_Assignment_c> oldAssignmentsMap;
     
        //Custom setting
        @testVisible    
        TB_TeamBuilderSettings_c tbSettings = TB_TeamBuilderSettings_c.getInstance();
       
        /**  
        * This constructor is used to create an instance of the class without passing any values.
        * @params None
        */
     
        public TB_AssignmentEmailNotification(){
        }
     
        public TB_AssignmentEmailNotification(List<pse_Assignmentc> newAssignmentsList,Map<id,pseAssignment_c> oldAssignmentsMap){
            this.newAssignmentsList = newAssignmentsList;
            this.oldAssignmentsMap = oldAssignmentsMap;
        }
     
        /**  
         * @Method : sendNotification
        * Sends email notifications to users when they are assigned to a project, so that they are aware of their next assignment.  
        * @param newAssignmentsList The list of new assignment records.  
        * @param oldAssignmentsMap The map of old assignment records.
        * @return
        */  
       
        public Id sendNotification(List<pse_Assignmentc> newAssignmentsList,Map<id,pseAssignment_c> oldAssignmentsMap){
            // Variable declarations...
            try{
                // This code declares a map to store user information and queries an email template based on a specific developer name.
                Set<id> projectIdSet = new Set<id>();
                // looping over list of assignments
                for (pse_Assignment_c assignment : newAssignmentsList){
                    if(assignment.pse_Status_c== TB_ConstantClass.ASSIGNMENT_STATUS_ASSIGNED
                       && oldAssignmentsMap?.get(assignment.id).pse_Status_c <> TB_ConstantClass.ASSIGNMENT_STATUS_ASSIGNED){
                           projectIdSet.add(assignment.pse_Project_c);
                       }
                }  
                if(!projectIdSet.isEmpty()){
                    Map<Id,Set<Id>> userMap = new Map<Id,Set<Id>>();
                    // searching for email templates
                    EmailTemplate assignResourceEmailTemplate = [SELECT Id, Name, DeveloperName FROM EmailTemplate
                                                                 WHERE DeveloperName = :TB_AssignmentConstants.ASSIGNMENT_EMAIL_TEMPLATE LIMIT 1];
                   
                    //Set of User Constant
                    Set<String> userIdSet = new Set<String>();
                    userIdSet.add(TB_AssignmentConstants.LEVEL_2_USER);
                    userIdSet.add(TB_AssignmentConstants.LEVEL_1_USER);
                   
                    //Map of Project to check Standard Project
                    Map<Id, pse_Projc> projectMap = new Map<Id, pseProj_c>([SELECT Id, RecordType.DeveloperName
                                                                                  FROM pse_Proj_c
                                                                                  WHERE ID IN:projectIdSet
                                                                                  AND RecordType.DeveloperName != :TB_ConstantClass.GLOBAL_PROJECT_RECORD_TYPE_API_NAME]);
                    //Set of resource/contact associated to Salesforce User and is present in new Assignment List
                    Set<id> contactIdSet = new Set<id>();
                    for (pse_Assignment_c assignment : newAssignmentsList){
                        if(assignment.pse_Status_c== TB_ConstantClass.ASSIGNMENT_STATUS_ASSIGNED
                           && oldAssignmentsMap?.get(assignment.id).pse_Status_c <> TB_ConstantClass.ASSIGNMENT_STATUS_ASSIGNED
                           && projectMap.containsKey(assignment.pse_Project_c)){
                               contactIdSet.add(assignment.pse_Resource_c);
                           }
                    }
                   
                    Map<Id, Contact> contactMap = new Map<Id, Contact>([SELECT Id, pse_Salesforce_User_c
                                                                        FROM Contact
                                                                        WHERE ID IN:contactIdSet
                                                                        AND pse_Salesforce_User_c != null
                                                                        AND pse_Is_Resource_Active_c = true
                                                                        AND pse_Is_Resource_c = true
                                                                        AND pse_Salesforce_User_r.IsActive = true
                                                                        AND pse_Salesforce_Userr.TB_Persona_c IN :userIdSet]);
                   
                    // Add User to user map by checking the criteria
                    for (pse_Assignment_c assignment : newAssignmentsList) {
                        if (assignment.pse_Status_c == TB_ConstantClass.ASSIGNMENT_STATUS_ASSIGNED
                            && oldAssignmentsMap?.get(assignment.id).pse_Status_c <> TB_ConstantClass.ASSIGNMENT_STATUS_ASSIGNED
                            && contactMap.containsKey(assignment.pse_Resource_c)) {
                                Set<Id> userSet = new Set<Id>();
                                userSet.add(contactMap.get(assignment.pse_Resourcec).pseSalesforce_User_c);
                                userMap.put(assignment.Id, userSet);
                            }
                    }
                    Boolean isDoExecute = false;
                    // Send email notifications if user map is not empty
                    if(UserMap?.size() > 0) {
                        isDoExecute = true;
                       
       
                    }
                    if(!tbSettings.TB_Project_Rel_Records_Sharing_Bypass__c && isDoExecute){
                        //Integer delayInMinutes = tbSettings.TB_DelayInMinutes__c.intValue();
                    Integer delayInMinutes = Integer.ValueOf(tbSettings.TB_DelayInMinutes__c) ;
                    // Call asyncExecutionLimitEmail method from TB_Utility class
                    TB_Utility.asyncExecutionLimitEmail();
                        return System.enqueueJob(new TB_SendEmailQueueable(UserMap,assignResourceEmailTemplate.Id), delayInMinutes);
                    }
                }
            }
            catch (Exception exp) {
                // Log the error
                SDF_LGR_LoggerManager.DBLoggerTB.error(exp, 'TB_AssignmentEmailNotification', 'sendNotification');
                // Optionally, you can rethrow the exception or perform other error handling actions
            }
           
            return null;
        }
     
         // Method to process the email notifications
        public Id process(){
            if(!this.newAssignmentsList.isEmpty()){
                return sendNotification(this.newAssignmentsList, this.oldAssignmentsMap);
            }
            return null;
        }
    }