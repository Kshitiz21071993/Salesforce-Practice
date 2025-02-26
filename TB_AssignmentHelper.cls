/**
* @author : Puneet Jalota
* @date : 2/12/2024
* @description : Represents the Assignment trigger helper which handles all the logic.
* @revisions
* [Date]             [Owner]      [Defect/Story]       [Description]
*
*/
public class TB_AssignmentHelper {
        public static final String TB_ASSIGNMENTHELPER = 'TB_AssignmentHelper';
        public static final String TB_ASSIGNMENTCREATE = 'Create';
        public static final String TB_ASSIGNMENTTUPDATE = 'Update';
        private static final String MANAGER_PICKLIST_VALUE = '1840263';
        private static final String PROJECT_FIELD_API_NAME = 'pse_Project_c';
        private static final String ASSIGNMENT_OBJECT_API_NAME = 'pse_Assignment_c';
        private static final String  SELF_DIRECTED_GLOBAL = 'TB_Self_Directed_Global';
        public Map <String, String> uuIdMap = new Map <String, String> ();
        Map<ID, List<String>> prjctIdTeamMemSalesforceIdListMap = new Map<ID, List<String>>();
        Map<ID, List<String>> prjctIdDcTeamMemSalesforceIdListMap = new Map<ID, List<String>>();
        Map<ID, List<String>> prjctIdEMTeamMemSalesforceIdListMap = new Map<ID, List<String>>();
        public static Boolean ASSIGNMNET_RESOURCE_UPDATED = false; // by pass validation of resource request when Assignment resource is changed
        private static final String  PublishCallbackUsageInApex = 'PublishCallbackUsageInApex';
        public static final Map<Id, Map<Id, Integer>> prjctIdAssignmentResourceCountMap = new Map<Id, Map<Id, Integer>>(); // map of projectId and AssignmentResourceCount Map
        // get the Project Type values from custom label
        public static final List<String> projectTypes = System.Label.TB_Project_Type.split(',');
        //get the Project Sub type values : Added as part of PBI 383898
        public static final List<String> projectSubTypes = System.Label.TB_Project_Sub_Type.split(',');
        // get the Assignment Status values from Constant Class
        public static final List<String> assignmentStatus = new List<String>{TB_ConstantClass.RESOURCE_REQUEST_REQUEST_STATUS_ASSIGNED, TB_ConstantClass.ASSIGNMENT_STATUS_COMPLETED};
        //Custom setting
        @testVisible
        TB_TeamBuilderSettings_c tbSettings = TB_TeamBuilderSettings_c.getInstance();
        private static ID LOGGEDINUSERPROFILEID;
     
        /**
        * @MethodName: TB_AssignmentHelper
        * @Description: This is a non parametorized constructor
        * @param :
        * @createdDate : 07/21/2024
        * @return void
        */
        public TB_AssignmentHelper(){
            LOGGEDINUSERPROFILEID=UserInfo.getProfileId();
        }
        /**
        * @MethodName: beforeInsertDirector
        * @Description: This method will get the list of parameters on before insert event
        * @param : List<pse_Assignment_c> newList
        * @createdDate : 17/07/2024
        * @return void
        */
         public void beforeInsertDirector(List < pse_Assignment_c > newList) {
     
            Set<Id> prjctIdSet = new set<Id>();
            // Collect the parent Resource Request Ids
            Set<Id> resourceRequestIds = new Set<Id>();
            Set<Id> allProjects = new Set<Id>();
            Set<String> assignmentExternalIDs=new Set<String>();
            try{
                List<pse_Assignmentc> filteredAssignments = new List<pseAssignment_c>();
                // Set<Id> assignmentIds = TB_Utility.getIdSet(newList);
                for(pse_Assignment_c assignment : newList){
                    allProjects.add(assignment.pse_Project_c);
                }
     
                Map<Id, pse_Projc> standardProjects = new Map<Id, pseProjc>([SELECT Id FROM pseProj_c WHERE ID IN :allProjects AND (RecordType.DeveloperName = 'TB_Standard' or RecordType.DeveloperName='TB_Self_Directed_Global')]); //Selef directed project check is done as part of PBI 383898
     
                for(pse_Assignment_c assgnmnt : newList){
                    if(standardProjects.containsKey(assgnmnt.pse_Project_c)) {
                        filteredAssignments.add(assgnmnt);
     
                        if(String.isNotBlank(assgnmnt.pse_Resourcec) && assgnmnt.TB_Resource_Request_Status_c != TB_ConstantClass.RESOURCE_REQUEST_REQUEST_STATUS_HELD){
                            prjctIdSet.add(assgnmnt.pse_Project_c);
                        }
                    }
     
                    // Added Resource Request Status condition to by pass when Resource Request Resource is changed from held to Assigned from staffing matches
     
                    if(assgnmnt.pse_Resource_Request_c != null){
                        resourceRequestIds.add(assgnmnt.pse_Resource_Request_c);
                    }
                     //380696: nullifying TB_External_Reference_ID__c for Splitted Assignment
                    if(!String.isBlank(assgnmnt.TB_External_Reference_ID__c)){
                        assignmentExternalIDs.add(assgnmnt.TB_External_Reference_ID__c);
                    }
                }
     
                //check whether the assignmentExternalIDs Set is empty or not and pass assignmentExternalIDs and list of Assignments
                //check whether the assignmentExternalIDs Set is empty or not and pass assignmentExternalIDs and list of Assignments
                if((!assignmentExternalIDs.isEmpty() || !resourceRequestIds.isEmpty()) && LOGGEDINUSERPROFILEID != System.Label.TB_Integration_Profile_ID){
                    clearExternalIDOnAssignment(assignmentExternalIDs,resourceRequestIds,newList);
                }  
     
                // Query the parent Resource Requests
     
                if (!resourceRequestIds.isEmpty()) {
                    Map<Id, String> resourceRequestValues = getResourceRequestValues(resourceRequestIds);
                    populateExternalReferenceId(newList, resourceRequestValues);
                }
                // check whether the projectId Set is empty or not and pass projectId and list of Assignments
                if(!prjctIdSet.isEmpty()){
                    validateAssignmentsResource(prjctIdSet, filteredAssignments, true);
                }
     
                if(!allProjects.isEmpty()){
                    updateEngagementLeaderTeamMemId(allProjects, newList);
                    updateConfidentialAssignments(allProjects,newList);
                }
            }catch(exception exp){
                SDF_LGR_LoggerManager.DBLoggerTB.error(exp, TB_ASSIGNMENTHELPER, 'beforeInsertDirector');
            }
        }
     
        /**
        * @description : This methods update the confidential on Assignments for confidential projects
        * @param projects : Set of Project Id's and List of Resource Requests
        **/
        private static void updateConfidentialAssignments(Set<Id>projectIdSet , List<pse_Assignment_c> assignmentList){
            Map<Id,pse_Projc> confidentialProjectMap = new Map<Id,pseProjc>([SELECT Id , TB_Confidentialc FROM pseProjc WHERE Id IN:projectIdSet AND TB_Confidential_c =: TB_ConstantClass.YES]);
            if(!confidentialProjectMap.isEmpty()){
                for(pse_Assignment_c asn : assignmentList){
                    if(confidentialProjectMap.containsKey(asn.pse_Project_c)){
                        asn.TB_Confidential__c = True;
                    }
                }
            }  
        }
       
        /**
        * PBI: #380696
        * @MethodName: clearExternalIDOnAssignment
        * @Description: This method will clear TB_External_Reference_ID_c field on Assignment if any other Assignment exists with same value and also clear pseResource_Request_c field if any other Assignment exists with same value
        * @param : set<String> assignmentExternalIDs,Set<Id> resourceRequestIds, List<pse_Assignment_c> newList
        * @createdDate : 07/17/2024
        * @return : void
        * */
        public void clearExternalIDOnAssignment(Set<String> assignmentExternalIDs,Set<Id> resourceRequestIds, List<pse_Assignment_c> newList){
            try{
               
                SET<String> existingAssExternalIDs=new SET<String>();
                SET<String> existingRRIDs=new SET<String>();
                for(pse_Assignmentc assRec:[SELECT TB_External_Reference_IDc,pseResource_Requestc FROM pseAssignmentc WHERE TB_External_Reference_IDc IN : assignmentExternalIDs OR pseResource_Request_c IN : resourceRequestIds]){
                    if(!String.isBlank(assRec.TB_External_Reference_ID__c)){
                        existingAssExternalIDs.add(assRec.TB_External_Reference_ID__c);
                    }
                    if(assRec.pse_Resource_Request_c!=NULL){
                        existingRRIDs.add(assRec.pse_Resource_Request_c);
                    }
                }
               
                for(pse_Assignment_c assRec:newList){
                    if(!String.isBlank(assRec.TB_External_Reference_ID_c) && existingAssExternalIDs.contains(assRec.TB_External_Reference_ID_c)){
                        assRec.TB_External_Reference_ID__c='';
                    }
                    //PBI 394687. Removing RR link from new splitted assignment.
                    if(assRec.pse_Resource_Requestc!=NULL && existingRRIDs.contains(assRec.pseResource_Request_c)){
                        assRec.pse_Resource_Request_c=NULL;
                    }
                }
            }catch(exception exp){
                SDF_LGR_LoggerManager.DBLoggerTB.error(exp, TB_ASSIGNMENTHELPER , 'clearExternalIDOnAssignment');
            }
        }
     
             /**
        * @MethodName: afterUpdateDirector
        * @Description: This method will get the list of parameters on after update event
        * @param : List < pse_Assignmentc > newList, Map < Id, pseAssignment_c > newMap
        * @createdDate : 03/06/2024
        * @return void
        * */
            public void afterUpdateDirector(List < pse_Assignmentc > newList, Map < Id, pseAssignment_c > oldMap) {
                Set<ID> assignmentResourceToShareToScheduleIdSet = new Set<ID>();
                Set<ID> assignmentResourceToRemoveToScheduleIdSet = new Set<ID>();
                Map<ID, ID> assgnmentIdResourceIdMap = new Map<ID, ID>();
                try{
                    for(pse_Assignment_c assgnmnt : newList){
     
                        /* When resource is changed on Assignment share the record with New Resource */
                        if(oldMap.get(assgnmnt.Id).pse_Resourcec != assgnmnt.pseResource_c
                           && String.isNotBlank(assgnmnt.pse_Resource_c)
                           && String.isNotBlank(assgnmnt.pse_Schedule_c)){
                               assgnmentIdResourceIdMap.put(assgnmnt.Id, assgnmnt.pse_Resource_c);
                               assignmentResourceToShareToScheduleIdSet.add(assgnmnt.pse_Schedule_c);
                               assignmentResourceToRemoveToScheduleIdSet.add(oldMap.get(assgnmnt.Id).pse_Resource_c);
                           }
                    }
     
                    if(!assignmentResourceToShareToScheduleIdSet.isEmpty()){
                        TB_ScheduleHelper schHelper = new TB_ScheduleHelper();
                        schHelper.createShareRecordForAssignmentNamedResource(assignmentResourceToShareToScheduleIdSet);
                        schHelper.deleteShareRecordForNamedResource(assignmentResourceToRemoveToScheduleIdSet);
                    }
     
                    if(!assgnmentIdResourceIdMap.isEmpty()){
                        createShareRecordForAssignmentNamedResource(assgnmentIdResourceIdMap);
                    }
                }catch(exception exp){
                    SDF_LGR_LoggerManager.DBLoggerTB.error(exp, TB_ASSIGNMENTHELPER, 'afterInsertDirector');
                }
            }
     
            /**
        * @MethodName: afterInsertDirector
        * @Description: This method will get the list of parameters on after insert event
        * @param : List < pse_Assignmentc > newList, Map < Id, pseAssignment_c > newMap
        * @createdDate : 24/05/2024
        * @return void
        * */
            public void afterInsertDirector(List < pse_Assignmentc > newList, Map < Id, pseAssignment_c > newMap) {
                Set<Id> createdByIdSet = new Set<Id>();
                Map<ID, ID> assgnmentIdResourceIdMap = new Map<ID, ID>();
                Set<ID> assignmentResourceToShareToScheduleIdSet = new Set<ID>();
                try{
                    for(pse_Assignment_c assgnmnt : newList){
                        // store the createdbyId in createdByIdSet
                        if(String.isNotBlank(assgnmnt.pse_Project_c)){
                            createdByIdSet.add(assgnmnt.createdById);
                        }
     
                        if(String.isNotBlank(assgnmnt.pse_Resource_c)){
                            assgnmentIdResourceIdMap.put(assgnmnt.Id, assgnmnt.pse_Resource_c);
                        }
     
                        if(String.isNotBlank(assgnmnt.pse_Schedule_c)){
                            assignmentResourceToShareToScheduleIdSet.add(assgnmnt.pse_Schedule_c);
                        }
                    }
     
                    // if createdByIdSet is not empty map requestor name on Assignment
                    if(!createdByIdSet.isEmpty()){
                        updateRequestorName(createdByIdSet, newList);
                    }
     
                    if(!assgnmentIdResourceIdMap.isEmpty()){
                        createShareRecordForAssignmentNamedResource(assgnmentIdResourceIdMap);
                    }
     
                    if(!assignmentResourceToShareToScheduleIdSet.isEmpty()){
                        TB_ScheduleHelper schHelper = new TB_ScheduleHelper();
                        schHelper.createShareRecordForAssignmentNamedResource(assignmentResourceToShareToScheduleIdSet);
                    }
                }catch(exception exp){
                    SDF_LGR_LoggerManager.DBLoggerTB.error(exp, TB_ASSIGNMENTHELPER, 'afterInsertDirector');
                }
            }
     
        /**
        * @MethodName: createShareRecordForAssignmentNamedResource
        * @Description: This method will Create the share record for Assignment named resource
        * @param : Set<ID> schToshare
        * @createdDate : 06/3/2024
        * @return : void
        * @story #: 301518
        * */
        public void createShareRecordForAssignmentNamedResource(Map<ID, ID> assgnmentIdResourceIdMap){
            List<SObject> shareRecordList = new List<SObject>();
     
            try{
                // Frame map of ScheduleId and Assignment Resoure ID
                for(pse_Assignmentc assignmemt : [SELECT ID, pseSchedulec, pseResource_c,
                                                        pse_Resourcer.pseSalesforce_User_c,
                                                        pse_Resourcer.pseSalesforce_User_r.ID,
                                                        pse_Resourcer.TB_Persona_c,
                                                        pse_Projectr.TB_Confidential_c,
                                                        pse_Projectr.pseEngagement_c,
                                                        pse_Projectr.pseOpportunity_c,
                                                        pse_Project_r.RecordType.DeveloperName,
                                                        pse_Project_c
                                                        FROM pse_Assignment_c
                                                        WHERE pse_Resource_c != null
                                                        AND Id IN: assgnmentIdResourceIdMap.keySet()
                                                        AND pse_Resourcer.pseSalesforce_User_r.IsActive = True]) {
                    String accessLevel =    assignmemt.pse_Resourcer.TB_Persona_c == TB_UserConstants.LEVEL_1_USER ?
                                            TB_ConstantClass.READ_ACCESS_LEVEL : TB_ConstantClass.EDIT_ACCESS_LEVEL;
     
                    Id userId = assignmemt.pse_Resourcer.pseSalesforce_User_c;
     
                    shareRecordList.add(
                        TB_RecordSharingHelper.createShareRecord(
                            assignmemt.Id,
                            userId,
                            Type.forName(TB_ConstantClass.ASSIGNMENT_SHARE_API_NAME),
                            TB_ConstantClass.EDIT_ACCESS_LEVEL
                        )
                    );
     
                    if(assignmemt.pse_Project_r.RecordType.DeveloperName != TB_ConstantClass.STANDARD_PROJECT_RECORD_TYPE_API_NAME) {
                        return;
                    }
     
                    Id engagementId = assignmemt.pse_Projectr.pseEngagement_c;
                    Id opportunityId = assignmemt.pse_Projectr.pseOpportunity_c;
     
                    shareRecordList.add(
                        TB_RecordSharingHelper.createShareRecord(
                            assignmemt.pse_Project_c,
                            userId,
                            Type.forName(TB_ConstantClass.PROJECT_SHARE_API_NAME),
                            accessLevel
                        )
                    );
     
                    if(engagementId != null) {
                        shareRecordList.add(
                            TB_RecordSharingHelper.createShareRecord(
                                engagementId,
                                userId,
                                Type.forName(TB_ConstantClass.ENGAGEMENT_SHARE_API_NAME),
                                accessLevel
                            )
                        );
                    }
     
                    if(opportunityId != null) {
                        shareRecordList.add(
                            TB_RecordSharingHelper.createShareRecord(
                                opportunityId,
                                userId,
                                Type.forName(TB_ConstantClass.OPPORTUNITY_SHARE_API_NAME),
                                accessLevel
                            )
                        );
                    }
                }
     
                // insert Share List
                if(!shareRecordList.isEmpty()) {
                    List<Database.SaveResult> saveResults = Database.insert(shareRecordList, false);
                    SDF_LGR_LoggerManager.DBLoggerTB.error(saveResults, TB_ASSIGNMENTHELPER, 'createShareRecordForAssignmentNamedResource');
                }
            }catch(exception exp){
                SDF_LGR_LoggerManager.DBLoggerTB.error(exp, TB_ASSIGNMENTHELPER, 'createShareRecordForAssignmentNamedResource');
            }
        }
     
        /**
        * @MethodName: updateRequestorName
        * @Description: This method will fetch the assignments and segregates based on createdbyId and updates Requestor name accordingly.
        * @param : Set<Id> createdByIdSet, List<pse_Assignment_c> newList
        * @createdDate : 24/05/2024
        * @return void
        * */
        private static void updateRequestorName(Set<Id> createdByIdSet, List<pse_Assignment_c> newList) {
     
            Set<Id> assgnmentCreatedByIdSet = new Set<Id>();
            Set<Id> assignmentPrjctIdSet = new Set<Id>();
            Set<Id> assignmentIdSet = new Set<Id>();
            try{
                Map<ID, User> createdByIdProfileNameMap = new Map<ID, User>([SELECT ID, ProfileId, Profile.Name FROM User WHERE ID IN: createdByIdSet]);
                for(pse_Assignment_c assignmnt : newList){
                    // Add createdById to set, if assignment is from Team builder
                    if(createdByIdProfileNameMap.get(assignmnt.CreatedById).Profile.Name != TB_ConstantClass.INTEGRATION_PROFILE){
                        assgnmentCreatedByIdSet.add(assignmnt.CreatedById);
                        assignmentIdSet.add(assignmnt.Id);
                        // Add ProjectId to set, if assignment is from flex
                    }else if(createdByIdProfileNameMap.get(assignmnt.CreatedById).Profile.Name == TB_ConstantClass.INTEGRATION_PROFILE){
                        assignmentPrjctIdSet.add(assignmnt.pse_Project_c);
                        assignmentIdSet.add(assignmnt.Id);
                    }
                }
                if(!createdByIdSet.isEmpty()){
                    updateRequestorNameFromCreatedUser(assgnmentCreatedByIdSet, assignmentIdSet);
                }
     
                if(!assignmentPrjctIdSet.isempty()){
                    updateRequestorNameFromProject(assignmentPrjctIdSet, assignmentIdSet);
                }
            } catch (Exception exp) {
                SDF_LGR_LoggerManager.DBLoggerTB.error(exp, TB_ASSIGNMENTHELPER, 'updateRequestorName');
            }
        }
     
        /**
        * @MethodName: updateRequestorNameFromCreatedUser
        * @Description: This method will update the requestor name from createdby user's contact
        * @param :Set<Id> createdByIdSet, Set<Id> assignmentIdSet
        * @createdDate : 24/05/2024
        * @return : void
        * */
        private static void updateRequestorNameFromCreatedUser(Set<Id> createdByIdSet, Set<Id> assignmentIdSet) {
     
            Map<ID, ID> salesoforceUserIdConIdMap = new Map<ID, ID>();
            List<pse_Assignmentc> assgnmentListToUpdate = new List<pseAssignment_c>();
            try{
                // frame map of Salesforce User and it's contact Id
                for(Contact con : [SELECT ID, pse_Salesforce_Userc FROM Contact WHERE pseSalesforce_User_c IN: createdByIdSet]){
                    salesoforceUserIdConIdMap.put(con.pse_Salesforce_User_c, con.Id);
                }
     
                // Map requestor name to CreatedById's Contact
                for (pse_Assignmentc assign : [SELECT Id, CreatedById, TB_SystemInitiatedProcessc,TB_Requestor_Namec FROM pseAssignment_c WHERE ID IN: assignmentIdSet]) {
                    assign.TB_Requestor_Name__c = SalesoforceUserIdConIdMap.get(assign.CreatedById);
                    assign.TB_SystemInitiatedProcess__c = System.currentTimeMillis();
                    assgnmentListToUpdate.add(assign);
                }
     
                 if(!assgnmentListToUpdate.isEmpty()){
                    Database.Update(assgnmentListToUpdate);
                }
            } catch (Exception exp) {
                SDF_LGR_LoggerManager.DBLoggerTB.error(exp, TB_ASSIGNMENTHELPER, 'updateRequestorNameFromCreatedUser');
            }
        }
     
        /**
        * @MethodName: updateRequestorNameFromProject
        * @Description: This method will update the requestor name from assignment Project's Project Manager
        * @param : Set<Id> assignmentPrjctIdSet, List<pse_Assignment_c> newList
        * @createdDate : 24/05/2024
        * @return : void
        * */
        private static void updateRequestorNameFromProject(Set<Id> assignmentPrjctIdSet, Set<Id> assignmentIdSet) {
     
            Map<ID, ID> projectIdProjectManagerIdMap = new Map<ID, ID>();
            List<pse_Assignmentc> assgnmentListToUpdate = new List<pseAssignment_c>();
            try{
                // frame map of Project Id and it's project manager Id
                for(pse_Projc prj : [SELECT Id, pseProject_Managerc FROM pseProj_c WHERE ID IN: assignmentPrjctIdSet]){
                    projectIdProjectManagerIdMap.put(prj.Id, prj.pse_Project_Manager_c);
                }
     
                // Map requestor name to CreatedById's Contact
                for (pse_Assignmentc assign : [SELECT Id, pseProjectc, TB_Requestor_Namec FROM pseAssignment_c WHERE ID IN: assignmentIdSet]) {
                    assign.TB_Requestor_Name_c = projectIdProjectManagerIdMap.get(assign.pseProject_c);
                    assign.TB_SystemInitiatedProcess__c = System.currentTimeMillis();
                    assgnmentListToUpdate.add(assign);
                }
     
                if(!assgnmentListToUpdate.isEmpty()){
                    Database.Update(assgnmentListToUpdate);
                }
            } catch (Exception exp) {
                SDF_LGR_LoggerManager.DBLoggerTB.error(exp, TB_ASSIGNMENTHELPER, 'updateRequestorNameFromProject');
            }
        }
     
         /**
    * @MethodName: getResourceRequestValues
    * @Description: This method will get the resource request Id
    * @param : Set<Id> resourceRequestIds
    * @createdDate : 24/04/2024
    * @return resourceRequestValues
    * */
        private Map<Id, String> getResourceRequestValues(Set<Id> resourceRequestIds) {
            Map<Id, String> resourceRequestValues = new Map<Id, String>();
            for (pse_Resource_Requestc resourceRequest : [SELECT Id, TB_RR_Source_Idc FROM pseResource_Request_c WHERE Id IN :resourceRequestIds]) {
                resourceRequestValues.put(resourceRequest.Id, resourceRequest.TB_RR_Source_Id__c);
            }
            return resourceRequestValues;
        }
     
        /**
    * @MethodName: populateExternalReferenceId
    * @Description: This method will get the TB_External_Reference_ID__c
    * @param : List<pse_Assignment_c> newList, Map<Id, String> resourceRequestValues
    * @createdDate : 24/04/2024
    * @return n/a
    * */
        private void populateExternalReferenceId(List<pse_Assignment_c> newList, Map<Id, String> resourceRequestValues) {
            for (pse_Assignment_c assign : newList) {
                if (resourceRequestValues.containsKey(assign.pse_Resource_Requestc) && String.isBlank(assign.TB_External_Reference_ID_c)) {
                    assign.TB_External_Reference_ID_c = resourceRequestValues.get(assign.pseResource_Request_c);
                }
            }
        }
     
        /**
    * @MethodName: updateScheduleField
    * @Description: This method will update external reference id field on schedule.
    * @param : List<pse_Assignmentc> newAssignments, Map<Id, pseAssignment_c> oldAssignmentsMap
    * @createdDate : 24/04/2024
    * @return void
    * */
        public void updateScheduleField( Map<Id, pse_Assignmentc> newAssignmentsMap, Map<Id, pseAssignment_c> oldAssignmentsMap) {
            try {
                if(LOGGEDINUSERPROFILEID==System.Label.TB_Integration_Profile_ID){
                    List<pse_Schedulec> schedulesToUpdate = new List<pseSchedule_c>();
                    List<pse_Resource_Requestc> rrToUpdate = new List<pseResource_Request_c>();
                    Set<Id> assignmentIdsForScheduleUpdate=new Set<Id>();
                    Set<Id> assignmentIdsForRRUpdate=new Set<Id>();
                    // Collect the assignment IDs and external reference values
                    //  PBI: 362213 assignment.TB_External_Reference_ID__c != null , removing this check
                    for (Id assId :newAssignmentsMap.keySet()) {
                        if (newAssignmentsMap.get(assId).TB_External_Reference_ID_c != oldAssignmentsMap.get(assId).TB_External_Reference_IDc && String.isBlank(newAssignmentsMap.get(assId).pseResource_Request_c)){
                            assignmentIdsForScheduleUpdate.add(assId);
                        }
                        else if(newAssignmentsMap.get(assId).TB_External_Reference_ID_c != oldAssignmentsMap.get(assId).TB_External_Reference_IDc && newAssignmentsMap.get(assId).pseResource_Request_c != NULL){
                            assignmentIdsForRRUpdate.add(assId);
                        }
                    }
     
                    if(!assignmentIdsForScheduleUpdate.isEmpty()){
                        for(Id assId:newAssignmentsMap.keySet()){
                            if(assignmentIdsForScheduleUpdate.contains(assId)){
                                pse_Schedulec schRec=new pseSchedule_c();
                                schRec.id = newAssignmentsMap.get(assId).pse_Schedule_c;
                                schRec.TB_Source_Id_c = newAssignmentsMap.get(assId).TB_External_Reference_ID_c;
                                schedulesToUpdate.add(schRec);
                            }
                        }
                    }
                    if(!assignmentIdsForRRUpdate.isEmpty()){
                        for(Id assId:newAssignmentsMap.keySet()){
                            if(assignmentIdsForRRUpdate.contains(assId)){
                                pse_Resource_Requestc resReq = new pseResource_Request_c();
                                resReq.id = newAssignmentsMap.get(assId).pse_Resource_Request_c;
                                resReq.TB_RR_Source_Id_c = newAssignmentsMap.get(assId).TB_External_Reference_ID_c;
                                rrToUpdate.add(resReq);
                            }
                        }
                    }
     
                    if(!schedulesToUpdate.isEmpty()){
                        List<Database.SaveResult> updateResults = Database.update(schedulesToUpdate);
                        SDF_LGR_LoggerManager.DBLoggerTB.error(updateResults, TB_ASSIGNMENTHELPER, 'updateScheduleField');
                    }
                    if(!rrToUpdate.isEmpty()){
                        List<Database.SaveResult> updateResults = Database.update(rrToUpdate);
                        SDF_LGR_LoggerManager.DBLoggerTB.error(updateResults, TB_ASSIGNMENTHELPER, 'updateScheduleField');
                    }
                }
            } catch (Exception exp) {
                SDF_LGR_LoggerManager.DBLoggerTB.error(exp, TB_ASSIGNMENTHELPER, 'updateScheduleField');
            }
        }
     /**
    * @MethodName: beforeUpdateDirector
    * @Description: This method will get the list of parameters on after update event
    * @param : Map<Id, pse_Assignmentc> newMap, Map< Id, pseAssignment_c> oldMap
    * @createdDate : 03/19/2024
    * @return void
    * */
        public void beforeUpdateDirector(Map<Id, pse_Assignmentc> newMap, Map< Id, pseAssignment_c> oldMap) {
            Set<Id> prjctIdSet = new set<Id>();
            try{
                for(pse_Assignment_c assgnmnt : newMap.values()){
                    if(assgnmnt.pse_Resourcec != oldMap.get(assgnmnt.Id).pseResource_c){
                        ASSIGNMNET_RESOURCE_UPDATED = true;
                        prjctIdSet.add(assgnmnt.pse_Project_c);
                    }
                    //Added as part of 474189. If any update done by non-integration user, then updating TB_Last_Modified_By_Source__c with Team Builder value.
                    if(LOGGEDINUSERPROFILEID!=System.Label.TB_Integration_Profile_ID){
                        assgnmnt.TB_Last_Modified_By_Source__c=TB_ConstantClass.TeamBuilder;
                    }
                }
                // check whether the projectId Set is empty or not and pass projectId and list of resource request
                if(!prjctIdSet.isEmpty()){
                    validateAssignmentsResource(prjctIdSet, newMap.values(), false);
                }
            }catch(exception exp){
                SDF_LGR_LoggerManager.DBLoggerTB.error(exp, TB_ASSIGNMENTHELPER, 'beforeUpdateDirector');
            }
        }
     
        /**
    * @MethodName: validateAssignmentsResource
    * author : ManiTeja
    * @Description: This method will validate Resource request whether the resource on Assignment is same as associated Project's Resource Request Resource
    * @param : set<Id> prjctIdSet, List<pse_Assignment_c> newList
    * @createdDate : 15/03/2024
    * @Story : #262168
    * @return void
    */
        public static void validateAssignmentsResource(set<Id> prjctIdSet, List<pse_Assignment_c> newList, Boolean isInsert){
                    Map<Id, Set<Id>> prjctIdResourceListMap = new Map<Id, Set<Id>>();
            Map<Id, Set<Id>> prjctIdAssignmentResourceListMap = new Map<Id, Set<Id>>();
     
            // get the Resource Request Status values from Constant Class
            List<String> resReqStatus = new List<String>{TB_ConstantClass.RESOURCE_REQUEST_REQUEST_STATUS_HELD};
                try{
                    if(!TB_ResourceRequestHelper.RESOURCE_REQUEST_UPDATED){
                        // frame the map of projectId and List of it's associated Resource Request Resources
                        for(pse_Resource_Requestc resReq : [SELECT Id, pseStatusc, pseStaffer_Resourcec, pseProjectc, pseProjectr.pseProject_Typec, pseProjectr.pseStagec FROM pseResource_Request_c
                                                               WHERE pse_Project_c IN : prjctIdSet
                                                               AND pse_Projectr.pseProject_Type_c IN: projectTypes
                                                               AND pse_Status_c IN: resReqStatus]){
                                                                   if(prjctIdResourceListMap.containsKey(resReq.pse_Project_c)){
                                                                       prjctIdResourceListMap.get(resReq.pse_Projectc).add(resReq.pseStaffer_Resource_c);
                                                                   }else{
                                                                       prjctIdResourceListMap.put(resReq.pse_Projectc, new Set<Id>{resReq.pseStaffer_Resource_c});
                                                                   }
                                                               }
                    }
                    // frame the map of projectId and List of it's associated Resource on Assignments
     
                    for(pse_Assignmentc assignmnt : [SELECT Id, pseProjectc, pseStatusc, pseResourcec, pseProjectr.pseProject_Typec,pseProjectr.TB_Project_Sub_Typec FROM pseAssignment_c
                                                        WHERE pse_Project_c IN : prjctIdSet
                                                        AND (pse_Projectr.pseProject_Typec IN: projectTypes OR pseProjectr.TB_Project_Sub_Type_c IN: projectSubTypes) //Subtype condition added as part of PBI 383898:Neha Singh
                                                        AND (pse_Projectr.TB_Is_Buenos_Aires_ACc = false)      //TB_Is_Buenos_Aires_AC_c is added as a part of PBI 418901
                                                        AND pse_Status_c IN: assignmentStatus]){
                                                            if(prjctIdAssignmentResourceListMap.containsKey(assignmnt.pse_Project_c)){
                                                                prjctIdAssignmentResourceListMap.get(assignmnt.pse_Projectc).add(assignmnt.pseResource_c);
                                                            }else{
                                                                prjctIdAssignmentResourceListMap.put(assignmnt.pse_Projectc, new Set<Id>{assignmnt.pseResource_c});
                                                            }
                                                        }
                    // check whether the map prjctIdResourceListMap or prjctIdAssignmentResourceListMap is empty
                    // and check for duplication of Resource on associated project Resource Requests Resource
                    Boolean isAssignmentHavingDuplicateResource = false;
                    for(pse_Assignment_c rec : newList){
     
                        if((!prjctIdResourceListMap.isEmpty()
                            && String.isNotBlank(rec.pse_Resource_c)
                            && !prjctIdResourceListMap.get(rec.pse_Project_c).isEmpty()
                            && prjctIdResourceListMap.get(rec.pse_Projectc).contains(rec.pseResource_c)) ||
                           (!prjctIdAssignmentResourceListMap.isEmpty()
                            && prjctIdAssignmentResourceListMap.containsKey(rec.pse_Project_c)
                            && String.isNotBlank(rec.pse_Resource_c)
                            && !prjctIdAssignmentResourceListMap.get(rec.pse_Project_c).isEmpty()
                            && prjctIdAssignmentResourceListMap.get(rec.pse_Projectc).contains(rec.pseResource_c))){
                                isAssignmentHavingDuplicateResource = true;
                             rec.addError(System.Label.TB_Assignment_Resource_Validation_message);
                           }
                    }
                   
                    if(!isAssignmentHavingDuplicateResource){
                        validateNewAssignmentRecords(prjctIdSet, newList);
                    }
                   
                }catch(exception exp){
                    SDF_LGR_LoggerManager.DBLoggerTB.error(exp, TB_ASSIGNMENTHELPER, 'validateResourceRequest');
             }
        }
     
                /**
        * @MethodName: validateNewAssignmentRecords
        * @Description: This method will check the whether the list of Assignments that are inserted and have duplicate Resources
        * @param : List<pse_Assignment_c> newList, set<Id> prjctIdSet
        * @createdDate : 09/10/2024
        * @return void
        * */
                public static void validateNewAssignmentRecords(set<Id> prjctIdSet, List<pse_Assignment_c> newList){
                    Set<Id> filteredAssignmentPrjctIdSet = new Set<ID>();
                    for(pse_Projc prj : [SELECT Id, pseProject_Typec, TB_Project_Sub_Typec FROM pseProj_c WHERE ID IN : prjctIdSet
                                            AND (pse_Project_Typec IN: projectTypes OR TB_Project_Sub_Type_c IN: projectSubTypes) ]){
                                                filteredAssignmentPrjctIdSet.add(prj.Id);
                                            }
                   
                    //frame the map of projectId and AssignmentResourceCount Map
                    for (pse_Assignment_c assignmnt : newList) {
                        if(filteredAssignmentPrjctIdSet.contains(assignmnt.pse_Projectc) && assignmentStatus.contains(assignmnt.pseStatus_c)){
                            Id projectId = assignmnt.pse_Project_c;  
                            Id resourceId = assignmnt.pse_Resource_c;  
                            if (!prjctIdAssignmentResourceCountMap.containsKey(projectId)) {  
                                prjctIdAssignmentResourceCountMap.put(projectId, new Map<Id, Integer>());  
                            }  
                            Map<Id, Integer> resourceCountMap = prjctIdAssignmentResourceCountMap.get(projectId);  
                            if (resourceCountMap.containsKey(resourceId)) {  
                                resourceCountMap.put(resourceId, resourceCountMap.get(resourceId) + 1);  
                            } else {  
                                resourceCountMap.put(resourceId, 1);  
                            }  
                        }
                    }
                   
                    for (pse_Assignment_c assignmnt : newList) {
                        if((!prjctIdAssignmentResourceCountMap.isEmpty()
                            && prjctIdAssignmentResourceCountMap.containsKey(assignmnt.pse_Project_c)
                            && String.isNotBlank(assignmnt.pse_Resource_c)
                            && !prjctIdAssignmentResourceCountMap.get(assignmnt.pse_Project_c).isEmpty()
                            && prjctIdAssignmentResourceCountMap.get(assignmnt.pse_Projectc).get(assignmnt.pseResource_c) > 1)){
                                assignmnt.addError(System.Label.TB_Assignment_Resource_Validation_message);
                            }  
                    }
                }
        /**
    * @MethodName: assignmentPlatformEventPublish
    * @Description: This method will get the list of parameters on after insert, after update event
    * @param : List<pse_Assignmentc> newList, Map< Id, pseAssignmentc> newMap, Map< Id, pseAssignment_c> oldMap, String eventName
    * @createdDate : 02/12/2024
    * @return void
    * */
        public void assignmentPlatformEventPublish(List<pse_Assignmentc> newList, Map<Id, pseAssignmentc> newMap, Map< Id, pseAssignment_c> oldMap,String eventName) {
            List<TB_AssignmentEvent_e> platformeventsToPublish=new List<TB_AssignmentEvent_e>();
            try{
                //PBI-394621, Removing SOQLs, Instead we'll use loggedin User's Profile ID.
                if (eventName == TB_ASSIGNMENTCREATE) {
                    platformeventsToPublish.addAll(createAssignmentEvents(newMap));
                } else if (eventName == TB_ASSIGNMENTTUPDATE) {
                    platformeventsToPublish.addAll(updateAssignmentEvents(newMap, oldMap));
                }
     
                if (!platformeventsToPublish.isEmpty()) {
           
                    //Checking org callback limits
                    Map<String,System.OrgLimit> mapOrgLimits = OrgLimits.getMap();
                    System.OrgLimit apiCallbackRequestsLimit = mapOrgLimits.get(PublishCallbackUsageInApex);
                    if(apiCallbackRequestsLimit.getValue() < TB_TeamBuilderSettings_c.getInstance().TB_MaximumPublishCallbackUsageInApex_c){
                        EventBus.publish(platformEventsToPublish, new TB_PlatformEventsCallBackClass(uuIdMap));
                    }
                    else{
                        EventBus.publish(platformEventsToPublish);
                    }
                   
                }
            }catch(exception exp){
                SDF_LGR_LoggerManager.DBLoggerTB.error(exp, TB_ASSIGNMENTHELPER , 'assignmentPlatformEventPublish');
            }
     
        }
    /**
* @MethodName: createAssignmentEvents
* @Description: This method will prepare list of Assignment events for created Assignment records
* @param : Map< Id, pse_Assignment_c> newMap
* @createdDate : 02/12/2024
* @return List<TB_AssignmentEvent__e>
* */
    private List<TB_AssignmentEvent_e> createAssignmentEvents(Map<Id, pseAssignment_c> newMap) {
            List<TB_AssignmentEvent_e> events=new List<TB_AssignmentEvent_e>();
            for(ID assId: newMap.keySet()){
                if(LOGGEDINUSERPROFILEID!=System.Label.TB_Integration_Profile_ID && (newMap.get(assId).TB_Project_Type_c == TB_ProjectConstants.EXT_WITHOUT_CREDIT_PROJ_TYPE || newMap.get(assId).TB_Project_Typec == TB_ProjectConstants.EXT_WITH_CREDIT_PROJ_TYPE) && newMap.get(assId).TB_Project_Record_Type_Name_c != SELF_DIRECTED_GLOBAL){
                    TB_AssignmentEvent_e assignmentEvent = (TB_AssignmentEvente) TB_AssignmentEvent_e.sObjectType.newSObject(null, true);
                    assignmentEvent.TB_Operation__c=TB_ASSIGNMENTCREATE;
                    assignmentEvent.TB_Record_ID__c=assId;
                    assignmentEvent.TB_Updated_Fields__c='';
                    assignmentEvent.TB_Source_c=newMap.get(assId).TB_Last_Modified_By_Source_c;
                    uuIdMap.put(assignmentEvent.EventUuid, assId);
                    events.add(assignmentEvent);
                }
            }
            return events;
        }
     
        /**
    * @MethodName: updateAssignmentEvents
    * @Description: This method will prepare list of Assignment events for updated Assignment records
    * @param : Map< Id, pse_Assignmentc> newMap,Map<Id, pseAssignment_c> oldMap
    * @createdDate : 02/12/2024
    * @return List<TB_AssignmentEvent__e>
    * */
        private List<TB_AssignmentEvent_e> updateAssignmentEvents(Map<Id, pseAssignmentc> newMap, Map<Id, pseAssignment_c> oldMap) {
            List<TB_AssignmentEvent_e> events = new List<TB_AssignmentEvent_e>();
            Map<String, String> assignmentRecord = TB_PlatformEventsUtil.getPlatformEventTriggerFields(ASSIGNMENT_OBJECT_API_NAME);
            //Map<String, String> metaRecordsForAssignment = getPlatformEventTriggerFields();
            for (Id assId : newMap.keySet()) {
                //Commenting out following condition as part of PBI 342994 - newMap.get(assId).lastModifiedBy.Profile.Name != TB_ConstantClass.INTEGRATION_PROFILE &&
                if(TB_PlatformEventsUtil.hasModifiedFields(newMap.get(assId),oldMap.get(assId),assignmentRecord,ASSIGNMENT_OBJECT_API_NAME) && (newMap.get(assId).TB_Project_Type_c == TB_ProjectConstants.EXT_WITHOUT_CREDIT_PROJ_TYPE || newMap.get(assId).TB_Project_Typec == TB_ProjectConstants.EXT_WITH_CREDIT_PROJ_TYPE) && newMap.get(assId).TB_Project_Record_Type_Name_c != SELF_DIRECTED_GLOBAL) {
                    TB_AssignmentEvent_e assignmentEvent = (TB_AssignmentEvente) TB_AssignmentEvent_e.sObjectType.newSObject(null, true);
                    assignmentEvent.TB_Operation__c = TB_ASSIGNMENTTUPDATE;
                    assignmentEvent.TB_Record_ID__c = assId;
                    assignmentEvent.TB_Updated_Fields__c = TB_PlatformEventsUtil.getModifiedFields(newMap.get(assId),oldMap.get(assId),assignmentRecord,ASSIGNMENT_OBJECT_API_NAME);
                    assignmentEvent.TB_Source_c = newMap.get(assId).TB_Last_Modified_By_Source_c;
                    uuIdMap.put(assignmentEvent.EventUuid, assId);
                    events.add(assignmentEvent);
                }
            }
            return events;
        }
     
        /**
    * @MethodName: insertAssignToScheduleEvent
    * @Description: This method will prepare list of Schedule events for Assignment records
    * @param : Map< Id, pse_Assignment_c> newMap
    * @createdDate : 03/27/2024
    * @return : Void
    * */
        //Commenting this method per PBI #408057
        /*
        public void insertAssignToScheduleEvent(Map<Id, pse_Assignment_c> newMap) {
     
            List<TB_ScheduleEvent_e> events = new List<TB_ScheduleEvent_e>();
            try{
                //PBI-394621, avoiding SOQL. Instead we'll use loggedin User's Profile ID.
                for(Id assId:newMap.keySet()){
                    if(LOGGEDINUSERPROFILEID!=System.Label.TB_Integration_Profile_ID && newMap.get(assId).TB_External_Reference_ID_c == Null && newMap.get(assId).TB_Flex_Budget_IDc != NULL && newMap.get(assId).pseResource_Requestc == NULL && newMap.get(assId).pseSchedule_c != NULL){
                        TB_ScheduleEvent_e scheduleEvent = (TB_ScheduleEvente)TB_ScheduleEvent_e.sObjectType.newSObject(null, true);
                        scheduleEvent.TB_Operation__c = TB_ASSIGNMENTCREATE;
                        scheduleEvent.TB_Record_ID_c = newMap.get(assId).pseSchedule_c;
                        scheduleEvent.TB_End_Date_c = newMap.get(assId).pseEnd_Date_c;
                        scheduleEvent.TB_Assignment_ID__c = assId;
                        scheduleEvent.TB_Resource_Request_ID__c = '';
                        scheduleEvent.TB_Source_c = newMap.get(assId).TB_Last_Modified_By_Source_c;
                        uuIdMap.put(scheduleEvent.EventUuid, assId);
                        events.add(scheduleEvent);
                    }
                }
                if (!events.isEmpty()) {
                    EventBus.publish(events, new TB_PlatformEventsCallBackClass(uuIdMap));
                }
            }catch(exception exp){
                SDF_LGR_LoggerManager.DBLoggerTB.error(exp, TB_ASSIGNMENTHELPER , 'insertAssignToScheduleEvent');
            }
        }
        */
        /**
        * @description Adds project team members based on the provided list of assignment records.
        *
        * @param assignments List of assignment records to process.
        */
         public void addProjectTeamMembers(List<pse_Assignment_c> assignments) {
            try {
                Map<Id, pse_Assignmentc> allAssignmentsMap = new Map<Id, pseAssignment_c>(assignments);
                List<pse_Assignmentc> standardProjectAssignments = new List<pseAssignment_c>();
                 
                for (pse_Assignmentc standardProjectAssignment : [SELECT Id FROM pseAssignmentc WHERE Id IN :allAssignmentsMap.keySet() AND pseProject_r.RecordType.DeveloperName = :TB_ConstantClass.STANDARD_PROJECT_RECORD_TYPE_API_NAME]) {
                    standardProjectAssignments.add(allAssignmentsMap.get(standardProjectAssignment.Id));
                }
     
                if(standardProjectAssignments.isEmpty()){
                    return;
                }
     
                // Prepare a list of project team members on the basis of their management level
                List<TB_Management_Team__c> projectTeams = getProjectTeamsToCreate(standardProjectAssignments);
     
                // Insert project teams
                if(!projectTeams.isEmpty()){
                    List<Database.SaveResult> saveResults = Database.insert(projectTeams, false);
                    SDF_LGR_LoggerManager.DBLoggerTB.error(saveResults, TB_ASSIGNMENTHELPER, 'addProjectTeamMembers');
                }
            } catch (Exception ex) {
                // Log any exceptions
                SDF_LGR_LoggerManager.DBLoggerTB.error(ex, TB_ASSIGNMENTHELPER, 'addProjectTeamMembers');
            }
        }
     
         /**
        * @description  Using future method to share to enqueue sharing job. So that PSA and Team builder code wont conflicts
        * @param assignmentIds
        **/
        @future
        public  static void shareRecords(Set<Id> assignmentIds){
            TB_TeamBuilderSettings_c tbSettingsInstance = TB_TeamBuilderSettings_c.getInstance();
     
            if(tbSettingsInstance.TB_Project_Rel_Records_Sharing_Bypass__c || TB_CreateAssignmentFromHeldRR_Queueable.assignmentFromQueueable){
                return;
            }
     
            List<pse_Assignmentc> assignments = [SELECT Id, pseProjectc, pseSchedulec FROM pseAssignment_c WHERE Id IN :assignmentIds];
            TB_RecordSharingAsyncProcessor sharingProcessor = new TB_RecordSharingAsyncProcessor(assignments, TB_AssignmentConstants.PROJECT_FIELD_API_NAME, TB_ConstantClass.ASSIGNMENT_SHARE_API_NAME);
            sharingProcessor.setParentObjectInfo(TB_ConstantClass.SCHEDULE_SHARE_API_NAME, 'pse_Schedule_c');
     
            TB_Utility.asyncExecutionLimitEmail();
     
            System.enqueueJob(sharingProcessor, Integer.ValueOf(tbSettingsInstance.TB_DelayInMinutes__c));
        }
     
        /**
    * @description Enqueues a job to asynchronously share records with project team members.
    *
    * @param assignments List of pse_Assignment_c records to be shared with project team members.
    */
        public void shareRecordsWithProjectTeamMembers(List<pse_Assignment_c> assignments) {
            TB_RecordSharingAsyncProcessor sharingProcessor = new TB_RecordSharingAsyncProcessor(assignments, PROJECT_FIELD_API_NAME, TB_ConstantClass.ASSIGNMENT_SHARE_API_NAME);
            sharingProcessor.setParentObjectInfo(TB_ConstantClass.SCHEDULE_SHARE_API_NAME, 'pse_Schedule_c');
            //Integer delayInMinutes = tbSettings.TB_DelayInMinutes__c.intValue();
            Integer delayInMinutes = Integer.ValueOf(tbSettings.TB_DelayInMinutes__c) ;
            TB_Utility.asyncExecutionLimitEmail();
            //added check to prevent queueing this job from TB_CreateAssignmentFromHeldRR_Queueable since it is chained in TB_CreateAssignmentFromHeldRR_Queueable - #257073
            if(!tbSettings.TB_Project_Rel_Records_Sharing_Bypass__c && !TB_CreateAssignmentFromHeldRR_Queueable.assignmentFromQueueable){
                System.enqueueJob(sharingProcessor,delayInMinutes);
            }
        }
     
        /**
        * @description Retrieves project teams to create based on the provided list of assignment records.
        *
        * @param assignments List of assignment records to process.
        * @return List of project team records to create.
        */
        private static List<TB_Management_Team_c> getProjectTeamsToCreate(List<pseAssignment_c> assignments) {
            // Initialize variables
            List<TB_Management_Team_c> teams = new List<TB_Management_Team_c>();
            List<pse_Assignmentc> filteredAssignments = new List<pseAssignment_c>();
            Set<Id> projectIds = new Set<Id>();
            Set<Id> assignmentIds = TB_Utility.getIdSet(assignments);
            Set<String> validPersonaForManagementRec = new Set<String> { TB_UserConstants.LEVEL_2_USER, TB_UserConstants.PEOPLE_TEAM_USER, TB_UserConstants.DEPLOYMENT_ENABLEMENT_TEAM_USER  };
           
         
            // Filter assignments based on management level
            for (pse_Assignmentc assignmentRec : [SELECT Id, pseProjectc, pseResourcec FROM pseAssignmentc WHERE ID IN :assignmentIds AND pseResourcer.pseSalesforce_Userr.TB_Persona_c IN :validPersonaForManagementRec]) {
               
                filteredAssignments.add(assignmentRec);
                projectIds.add(assignmentRec.pse_Project_c);
            }
     
            // Retrieve existing project teams
            List<String> existingProjectTeamsIdentifiers = new List<String>();
            if(!projectIds.isEmpty()) {
                for (TB_Management_Team_c existingTeam : [SELECT Id, TB_Projectc, TB_Namec FROM TB_Management_Teamc WHERE TB_Project_c IN :projectIds]) {
                    existingProjectTeamsIdentifiers.add(existingTeam.TB_Project_c + '~' + existingTeam.TB_Name_c);
                }
     
                // Create project teams to insert
                for (pse_Assignment_c assignmentRec : filteredAssignments) {
                    String identifier = assignmentRec.pse_Projectc + '~' + assignmentRec.pseResource_c;
                    if (!existingProjectTeamsIdentifiers.contains(identifier)) {
                        teams.add(createProjectTeamRec(assignmentRec));
                    }
                }
            }
     
            return teams;
        }
     
        /**
    * @description Creates a project team record from the provided assignment record.
    *
    * @param assignmentRec Assignment record to create project team from.
    * @return Created project team record.
    */
        @TestVisible
        private static TB_Management_Team_c createProjectTeamRec(pseAssignment_c assignmentRec) {
            TB_Management_Team_c team = new TB_Management_Team_c();
     
            team.TB_Project_c = assignmentRec.pseProject_c;
            team.TB_Role_on_Project__c = TB_ConstantClass.PROJECT_TEAM_MEMBER;
            team.TB_Name_c = assignmentRec.pseResource_c;
     
            return team;
        }
     
        /**
         * @description       : Retrieves project IDs from updated assignments and updates their assignment counts if changed.
         * @description       : Handles changes in project associations for assignments, updating counts accordingly.
         * @description       : Logs any exceptions encountered during the process.
         *
        **/
          public void getProjectIds( List<pse_Assignmentc > newList, Map < Id, pseAssignment_c > oldMap) {
            Set<Id> projectIdSet = new Set<Id>();
            try{
                for(pse_Assignment_c assignment : newList){
                    if(assignment.pse_Projectc <> oldMap?.get(assignment.Id).pseProject_c) {
                        projectIdSet.add(assignment.pse_Project_c);
                        projectIdSet.add(oldMap?.get(assignment.Id).pse_Project_c); //add both project ids in case of update
                     }
     
                    }
     
                // if createdByIdSet is not empty map requestor name on Assignment
                if(!projectIdSet.isEmpty()){
                    TB_AssignmentCounterHelper objAssignmentCounter= new TB_AssignmentCounterHelper();
                    objAssignmentCounter.updateAssignmentCountOnGlobalProjects(projectIdSet);
                }
            }catch(exception exp){
                SDF_LGR_LoggerManager.DBLoggerTB.error(exp, TB_ASSIGNMENTHELPER, 'getProjectIds');
            }
        }
            /**
        * PBI: #362070
        * @MethodName: updateEngagementLeaderTeamMemId
        * @Description: This method will update Store the Engagement Leader User Id of Project Team Members of Associate Project
        * @param : Id assignmentprjctIdSet, List<pse_Assignment_c> newList
        * @createdDate : 07/3/2024
        * @return : void
        * */
            public void updateEngagementLeaderTeamMemId(Set<ID> assignmentprjctIdSet, List<pse_Assignment_c> newList){
                List<String> peopleTeamRoles = new List<String>{TB_ConstantClass.PROJECT_TEAM_ROLE_DEPLOYMENT_CONSULTANT, TB_ConstantClass.PROJECT_TEAM_ROLE_PROJECT_TEAM_MEMBER};    
                    try{
                        for(TB_Management_Team_c pTeam : [SELECT ID, TB_Role_on_Projectc, TB_Projectc, TB_Namec, TB_Namer.pseSalesforce_User_c,
                                                        TB_Name_r.pseSalesforce_User_r.ID
                                                        FROM TB_Management_Team__c
                                                        WHERE TB_Project__c IN: assignmentprjctIdSet
                                                        AND TB_Name_r.pseSalesforce_User_r.ID != '']){
                                                                frameMapOfLevel2ProjectTeamSalesforceId(pTeam);
                                                            if(peopleTeamRoles.contains(pTeam.TB_Role_on_Project__c)){
                                                                frameMapOfPeopleTeamSalesforceId(pTeam);
                                                            }
                                                            //New Map for Engagement Manager PBI #396283 By BHARAT S
                                                            if(TB_ConstantClass.PROJECT_TEAM_ROLE_PROJECT_ENGAGEMENT_MANAGER == pTeam.TB_Role_on_Project__c){
                                                                frameMapOfEngagementManagerSalesforceId(pTeam);
                                                            }
                                                        }
                        // iterate the new List and map TB_Project_Team_EM_Ids__c with Project teams Engagement Leader User Id
                        for(pse_Assignment_c assignmnt : newList){
                            updateLevel2USerIdsOnAssignment(assignmnt);
                            updatePeopleTeamUserIdsOnAssignment(assignmnt);
                            updateEngMngrUserIdsOnAssignment(assignmnt);
                        }
                    }catch(exception exp){
                        SDF_LGR_LoggerManager.DBLoggerTB.error(exp, TB_ASSIGNMENTHELPER , 'updateEngagementLeaderTeamMemId');
                    }
            }
            /**
        * PBI: #361780
        * @MethodName: updateLevel2USerIdsOnAssignment
        * @Description: This method will update Store the Engagement Leader User Id of Project Team Members of Associate Project
        * @param :pse_Assignment_c assignmnt
        * @createdDate : 07/1/2024
        * @return : void
        * */
            public void updateLevel2USerIdsOnAssignment(pse_Assignment_c assignmnt){
                if(assignmnt.pse_Project_c != null &&  prjctIdTeamMemSalesforceIdListMap != null
                    && prjctIdTeamMemSalesforceIdListMap.containsKey(assignmnt.pse_Project_c)
                    && prjctIdTeamMemSalesforceIdListMap.get(assignmnt.pse_Project_c) != null
                    && !prjctIdTeamMemSalesforceIdListMap.get(assignmnt.pse_Project_c).isEmpty()){
                    String projectTeamElId = '';
                    for(String elId : prjctIdTeamMemSalesforceIdListMap.get(assignmnt.pse_Project_c)){
                        projectTeamElId = assignmnt.TB_Project_Team_EL_Ids__c + ',' + elId + ',';
                        assignmnt.TB_Project_Team_EL_Ids__c =  projectTeamElId.length() > 255 ? projectTeamElId.subString(0, 255) :  projectTeamElId;
                    }
                }
            }
            /**
        * PBI: #361780
        * @MethodName: updatePeopleTeamUserIdsOnAssignment
        * @Description: This method will update People Team User Id of Project Team Members of Associate Project
        * @param : pse_Assignment_c assignmnt
        * @createdDate : 07/1/2024
        * @return : void
        * */
            public void updatePeopleTeamUserIdsOnAssignment(pse_Assignment_c assignmnt){
                if( prjctIdDcTeamMemSalesforceIdListMap != null &&
                    prjctIdDcTeamMemSalesforceIdListMap.containsKey(assignmnt.pse_Project_c) &&
                    !prjctIdDcTeamMemSalesforceIdListMap.get(assignmnt.pse_Project_c).isEmpty()) {
                    String projectTeamPeopleTeamId = '';
                    for(String elId : prjctIdDcTeamMemSalesforceIdListMap.get(assignmnt.pse_Project_c)){
                        projectTeamPeopleTeamId = assignmnt.TB_Project_Team_DC_Ids__c + ',' + elId + ',';
                        assignmnt.TB_Project_Team_DC_Ids__c =  projectTeamPeopleTeamId.length() > 255 ? projectTeamPeopleTeamId.subString(0, 255) :  projectTeamPeopleTeamId;
                    }
                }
            }
          /**
        * PBI: #396283
        * @MethodName: updateEngMngrUserIdsOnAssignment
        * @Description: This method will update Store the Engagement Manager User Id of Project Team Members of Associate Project
        * @param :pse_Assignment_c assignmnt
        * @createdDate : 08/21/2024
        * @return : void
        * */
            public void updateEngMngrUserIdsOnAssignment(pse_Assignment_c assignmnt){
                if(prjctIdEMTeamMemSalesforceIdListMap != null
                    && prjctIdEMTeamMemSalesforceIdListMap.get(assignmnt.pse_Project_c) != null
                    && !prjctIdEMTeamMemSalesforceIdListMap.get(assignmnt.pse_Project_c).isEmpty()){
                    String projectTeamEMId = '';
                    for(String elId : prjctIdEMTeamMemSalesforceIdListMap.get(assignmnt.pse_Project_c)){
                        projectTeamEMId = assignmnt.TB_Project_Team_EM_Ids__C + ',' + elId + ',';
                        assignmnt.TB_Project_Team_EM_Ids__C =  projectTeamEMId.length() > 255 ? projectTeamEMId.subString(0, 255) :  projectTeamEMId;
                    }
                }
            }
            /**
        * PBI: #361780
        * @MethodName: frameMapOfLevel2ProjectTeamSalesforceId
        * @Description: This method will update Store the Engagement Leader User Id of Project Team Members of Associate Project
        * @param : TB_Management_Team__c pTeam
        * @createdDate : 07/1/2024
        * @return : void
        * */
            public void frameMapOfLevel2ProjectTeamSalesforceId(TB_Management_Team__c pTeam) {
                if(prjctIdTeamMemSalesforceIdListMap.containsKey(pTeam.TB_Project__c)){
                    prjctIdTeamMemSalesforceIdListMap.get(pTeam.TB_Project_c).add(pTeam.TB_Namer.pseSalesforce_User_r.ID);
                }else{
                    prjctIdTeamMemSalesforceIdListMap.put(pTeam.TB_Project_c, new List<String>{pTeam.TB_Namer.pseSalesforce_User_r.ID});
                }
            }
     
        /**
        * PBI: #361780
        * @MethodName: frameMapOfPeopleTeamSalesforceId
        * @Description: This method will update Store the People Team User Id of Project Team Members of Associate Project
        * @param : TB_Management_Team__c pTeam
        * @createdDate : 07/1/2024
        * @return : void
        * */
            public void frameMapOfPeopleTeamSalesforceId(TB_Management_Team__c pTeam){
                if(prjctIdDcTeamMemSalesforceIdListMap.containsKey(pTeam.TB_Project__c)){
                    prjctIdDcTeamMemSalesforceIdListMap.get(pTeam.TB_Project_c).add(pTeam.TB_Namer.pseSalesforce_User_r.ID);
                }else{
                    prjctIdDcTeamMemSalesforceIdListMap.put(pTeam.TB_Project_c, new List<String>{pTeam.TB_Namer.pseSalesforce_User_r.ID});
                }
            }
         /**
        * PBI: #396283
        * @MethodName: frameMapOfEngagementManagerSalesforceId
        * @Description: This method will update Store the Engagement Manager User Id of Project Team Members of Associate Project
        * @param : TB_Management_Team__c pTeam
        * @createdDate : 08/24/2024
        * @return : void
        * */
            public void frameMapOfEngagementManagerSalesforceId(TB_Management_Team__c pTeam){
                if(prjctIdEMTeamMemSalesforceIdListMap.containsKey(pTeam.TB_Project__c)){
                    prjctIdEMTeamMemSalesforceIdListMap.get(pTeam.TB_Project_c).add(pTeam.TB_Namer.pseSalesforce_User_r.ID);
                }else{
                    prjctIdEMTeamMemSalesforceIdListMap.put(pTeam.TB_Project_c, new List<String>{pTeam.TB_Namer.pseSalesforce_User_r.ID});
                }
            }
    }
    