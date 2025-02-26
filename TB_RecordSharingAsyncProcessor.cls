/**
 * @description       : A queueable Apex class to asynchronously handle sharing of records based on project-wise team members.
 * @author            : Nishkarsh Manav
 * @group             :
 * @last modified on  : 08-29-2024
 * @last modified by  : Nishkarsh Manav
**/
public without sharing class TB_RecordSharingAsyncProcessor implements Queueable {
        private List<sObject> recordsToShare; // List of records to be shared
        private String projectFieldName; // API name of the project field
        private Type objType; // Type of the object for which sharing records are created
        private String parentObjShareName; // API name of the parent object share
        private String parentLookupFieldName; // API name of the lookup field to parent object
        private TB_QueueableWrapper successorJob; //job to be called after the current job
     
        private static final Map<String, String> TEAM_SHARING_ROW_CAUSE_MAP = new Map<String, String> {
            TB_ConstantClass.SCHEDULE_SHARE_API_NAME => Schema.pse_ScheduleShare.RowCause.TB_Team_Sharing_c,
            TB_ConstantClass.ENGAGEMENT_SHARE_API_NAME => Schema.fferpcore_ff_EngagementShare.RowCause.TB_Team_Sharing_c,
            TB_ConstantClass.ASSIGNMENT_SHARE_API_NAME => Schema.pse_AssignmentShare.RowCause.TB_Team_Sharing_c,
            TB_ConstantClass.PROJECT_SHARE_API_NAME => Schema.pse_ProjShare.RowCause.TB_Team_Sharing_c,
            TB_ConstantClass.RES_REQUEST_SHARE_API_NAME => Schema.pse_Resource_RequestShare.RowCause.TB_Team_Sharing_c
        };
     
        /**
         * @description Constructs a new TB_RecordSharingAsyncProcessor object with the provided parameters.
         *
         * @param records List of records to be shared
         * @param projectFieldApiName API name of the project field
         * @param objApiName API name of the object for which sharing records are created
         */
     
         public TB_RecordSharingAsyncProcessor(List<sObject> records, String projectFieldApiName, String objApiName) {
             this(records, projectFieldApiName, objApiName, null);
         }
     
        /**
         * @description Constructs a new TB_RecordSharingAsyncProcessor object with the provided parameters.
         *
         * @param records List of records to be shared
         * @param projectFieldApiName API name of the project field
         * @param objApiName API name of the object for which sharing records are created
         * @param successorJob the next job to be executed
         */
        public TB_RecordSharingAsyncProcessor(List<sObject> records, String projectFieldApiName, String objApiName, TB_QueueableWrapper successorJob) {
            this.recordsToShare = records;
            this.projectFieldName = projectFieldApiName;
            this.objType = Type.forName(objApiName);
            this.successorJob = successorJob;
        }
     
        /**
        * @description Sets the information about the parent object and its lookup field for sharing.
        *
        * @param parentObjShareApiName The API name of the parent object's sharing object.
        * @param lookupFieldName The API name of the lookup field on the parent object.
        */
        public void setParentObjectInfo(String parentObjShareApiName, String lookupFieldName) {
            this.parentObjShareName = parentObjShareApiName;
            this.parentLookupFieldName = lookupFieldName;
        }
     
        /**
         * @description Executes the queueable job. Retrieves sharing records for project-wise team members and inserts them.
         *
         * @param context The QueueableContext instance
         */
        public void execute(QueueableContext context) {
            try{
                // Create a list of share object records for all team members
                List<sObject> sharingRecords = getSharingRecords(getProjectWiseResources());
     
                // Insert sharing records
                Database.SaveResult[] srList = Database.insert(sharingRecords, false);
                // Log the errors occured while inserting the record
                SDF_LGR_LoggerManager.DBLoggerTB.error(srList, 'TB_RecordSharingAsyncProcessor', 'execute');
     
                if(this.successorJob != null){
                    this.successorJob.process();
                }
            } catch(Exception ex) {
                SDF_LGR_LoggerManager.DBLoggerTB.error(ex, 'TB_RecordSharingAsyncProcessor', 'execute');
            }
        }
     
        /**
         * @description Retrieves project-wise team members from the provided records.
         *
         * @return A map of project IDs to sets of user IDs representing team members
         */
        private Map<String, Set<String>> getProjectWiseResources() {
            // Map to store project-wise team members
            Map<String, Set<String>> existingUsersOnProjects = new Map<String, Set<String>>();
            Set<String> projectIds = new Set<String>();
     
           // Extract unique project IDs from recordsToShare
            for(sObject rec : this.recordsToShare) {
                projectIds.add((String) rec.get(this.projectFieldName));
            }
     
            // Query TB_Management_Team__c records for each unique project ID
            for(TB_Management_Team_c projectTeam : [SELECT Id, TB_Namer.pseSalesforce_Userc, TB_Projectc FROM TB_Management_Teamc WHERE TB_Project_c IN :projectIds AND
                                                    TB_Project__r.RecordType.DeveloperName != :TB_ConstantClass.GLOBAL_PROJECT_RECORD_TYPE_API_NAME AND
                                                    TB_Name_r.pseSalesforce_User_r.IsActive = True]) {
                // Get the set of users for the current project
                Set<String> usersOnCurrentProject = existingUsersOnProjects.get(projectTeam.TB_Project__c);
     
                // If there are no users for the current project, create a new set
                usersOnCurrentProject = usersOnCurrentProject == null ? new Set<String>() : usersOnCurrentProject;
     
                // Add the user ID to the set of users for the current project
                usersOnCurrentProject.add(projectTeam.TB_Name_r.pseSalesforce_User_c);
     
                // Update the map with the set of users for the current project
                existingUsersOnProjects.put(projectTeam.TB_Project__c, usersOnCurrentProject);
            }
     
            return existingUsersOnProjects;
        }
     
        /**
         * @description Generates sharing records for the provided project-wise team members.
         *
         * @param existingUsersOnProjects A map of project IDs to sets of user IDs representing team members
         * @return List of sharing records
         */
        private List<sObject> getSharingRecords(Map<String, Set<String>> existingUsersOnProjects) {
            List<sObject> sharingRecords = new List<sObject>();
     
            for(SObject record : this.recordsToShare) {
                String projectId = (String) record.get(this.projectFieldName);
                Set<String> usersOnProject = existingUsersOnProjects.get(projectId);
                if(usersOnProject != null && !usersOnProject.isEmpty()) {
                    sharingRecords.addAll(createSharingRecordsForAllTeamMembers(record.Id, usersOnProject));
     
                    // Create share record of parent object
                    sharingRecords.addAll(createParentSharingRecords(record, usersOnProject));
                }
            }
     
            // Arrange sharing records by object type to avoid Salesforce 10 chunks error
            return TB_Utility.groupRecordsByObjType(sharingRecords);
        }
     
        private List<SObject> createParentSharingRecords(SObject record, Set<String> usersOnProject) {
            List<sObject> sharingRecords = new List<sObject>();
     
            if(String.isNotBlank(this.parentLookupFieldName) && String.isNotBlank(this.parentObjShareName)){
                String projectParentRecordId = (String) record.get(this.parentLookupFieldName);
     
                if(String.isNotBlank(projectParentRecordId)){
                    sharingRecords.addAll(createSharingRecordsForAllTeamMembers(projectParentRecordId, usersOnProject, this.parentObjShareName));
                }
            }
     
            return sharingRecords;
        }
     
        /**
         * @description Creates sharing records with edit access for all provided team members.
         *
         * @param recordId ID of the record being shared
         * @param userIds Set of user IDs representing team members
         * @return List of sharing records
         */
        private List<SObject> createSharingRecordsForAllTeamMembers(String recordId, Set<String> userIds) {
            return createSharingRecordsForAllTeamMembers(recordId, userIds, this.objType);
        }
     
        private List<SObject> createSharingRecordsForAllTeamMembers(String recordId, Set<String> userIds, String objShareName) {
            return createSharingRecordsForAllTeamMembers(recordId, userIds, Type.forName(objShareName));
        }
     
        private List<SObject> createSharingRecordsForAllTeamMembers(String recordId, Set<String> userIds, Type objType) {
            List<SObject> sharingRecs = new List<SObject>();
     
            for(String userId : userIds) {
                if(String.isNotBlank(recordId) && String.isNotBlank(userId)) {
                    sharingRecs.add(TB_RecordSharingHelper.createShareRecordWithEditAccess(recordId, userId, objType));
                }
            }
     
            return sharingRecs;
        }
    }