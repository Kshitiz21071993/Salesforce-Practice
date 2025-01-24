/**  * @description       : Helper class for managing Resource Request trigger operations within the TB application.
  *   Validates records to ensure data integrity before trigger execution  
* @author            : Nishkarsh Manav  
* @group             :  
* @last modified on  : 07-04-2024  *
 @last modified by  : Priyanka LNU **/ 

 public inherited sharing class TB_ResRequestTriggerHelper {   
    // Constants     private static final String PROJECT_FIELD_API_NAME = 'pse__Project__c';  
     private static final String CLASS_NAME = 'TB_ResRequestTriggerHelper';   
    private static final String UPDATE_TOTAL_HOURS_METHOD_NAME = 'updateSumOfTotalHoursOnProjects';     
  private static final String UPDATE_TOTAL_HOURS_ASYNC_METHOD_NAME = 'updateTotalHoursOnProjectsAsync';    
   private static final String UPDATE_TOTAL_HOURS_ASYNC_METHOD_UPDATE_ACTION = 'updateTotalHoursOnProjectsAsync - Record Update Transaction';    
   private static final String OBJECT_NAME = 'pse__Resource_Request__c';  
     private static final String PARENT_LOOKUP_FIELD_NAME = 'pse__Project__c';  
     private static final String FIELD_TO_AGGREGATE = 'pse__SOW_Hours__c';   
    private static final String ADDITIONAL_FILTERS = 'AND pse__Status__c IN (\'Ready to Staff\', \'Hold\', \'Pause Search\', \'Submitted\')';   
    private static final String ADDITIONAL_FILTERS_FOR_STATUS_HOLD = 'AND pse__Status__c IN (\'Hold\')';     
      private static final List<String> RES_REQ_VALID_STATUS = new List<String> {TB_ConstantClass.RESOURCE_REQUEST_REQUEST_STATUS_READY_TO_STAFF,   
   TB_ConstantClass.RESOURCE_REQUEST_REQUEST_STATUS_HELD, TB_ConstantClass.RESOURCE_REQUEST_REQUEST_STATUS_PAUSE_SEARCH,
  TB_ConstantClass.RESOURCE_REQUEST_REQUEST_STATUS_SUBMITTED   
    };   
  
      /**      
  * @description Validates the given list of Resource Request records.     
   *      
  * @param records List of pse__Resource_Request__c records to be validated.    
    */     
  public void validateRecords(List<pse__Resource_Request__c> records) {       
    // Create a new TB_ProjectTeamValidator instance    
       TB_ProjectTeamValidator validator = new TB_ProjectTeamValidator();      
       // Validate the records using validator class       
    validator.validateRecords(PROJECT_FIELD_API_NAME, records);  
     }      
  
   /**      * @description Trigger handler method for after insert event.     
   *      * @param resRequests List of pse__Resource_Request__c records inserted.     
   */     
  
  public void afterInsertDirector(List<pse__Resource_Request__c> resRequests) {         updateSumOfTotalHoursOnProjects(resRequests);     }    
  
     /**      * @description Trigger handler method for after update event.   
     *      * @param resRequests List of pse__Resource_Request__c records updated.      
  * @param oldResRequests Map of old pse__Resource_Request__c records by Id.     
   */ 
  
      public void afterUpdateDirector(List<pse__Resource_Request__c> resRequests, Map<Id, pse__Resource_Request__c> oldResRequests) {     
      updateSumOfTotalHoursOnProjects(resRequests, oldResRequests);     
      updateSumOfTotalHoursOnProjectsForStatusHold(resRequests,oldResRequests);     
  }      
  
   /**
        * @description Trigger handler method for after delete event. 
       *      * @param resRequests List of pse__Resource_Request__c records deleted.     
   */    
  
   public void afterDeleteDirector(List<pse__Resource_Request__c> resRequests) {      
     updateSumOfTotalHoursOnProjects(resRequests);     
      updateSumOfTotalHoursOnProjectsForStatusHold(resRequests); 
      }   
  
      /**      * @description Trigger handler method for after undelete event.      *    
    * @param resRequests List of pse__Resource_Request__c records undeleted.  
      */    
   public void afterUnDeleteDirector(List<pse__Resource_Request__c> resRequests) {       
    updateSumOfTotalHoursOnProjects(resRequests);  
     }       
  
  /**      * @description Updates the sum of total hours on projects asynchronously.      
  *      * @param resRequests List of pse__Resource_Request__c records.   
     */     
  
  private void updateSumOfTotalHoursOnProjects(List<pse__Resource_Request__c> resRequests) {         
  updateSumOfTotalHoursOnProjects(resRequests, new Map<Id, pse__Resource_Request__c>());   
    }        
  
       /**      * @description Updates the sum of total hours on projects asynchronously when the RR status is Hold.    
    *      * @param resRequests List of pse__Resource_Request__c records.      
  */     
  
  private void updateSumOfTotalHoursOnProjectsForStatusHold(List<pse__Resource_Request__c> resRequests) {       
    updateSumOfTotalHoursOnProjectsForStatusHold(resRequests, new Map<Id, pse__Resource_Request__c>());    
   }      
  
   /**   
     * @description Updates the sum of total hours on projects asynchronously.      
  *      * @param resRequests List of pse__Resource_Request__c records.    
    * @param oldResRequests Map of old pse__Resource_Request__c records by Id.      
  */     
  
  private void updateSumOfTotalHoursOnProjects(List<pse__Resource_Request__c> resRequests, Map<Id, pse__Resource_Request__c> oldResRequests) {     
      try {         
      Set<String> projectIds = extractProjectIdsForSTHCalculation(resRequests, oldResRequests);          
       if(!projectIds.isEmpty()){               
    updateTotalHoursOnProjectsAsync(projectIds);    
           }      
     } catch (Exception ex) {      
         SDF_LGR_LoggerManager.DBLoggerTB.error(ex, CLASS_NAME, UPDATE_TOTAL_HOURS_METHOD_NAME);      
     }     }         
  
      /**      * @description Updates the sum of total hours on projects asynchronously when the RR status is Hold.      *
        * @param resRequests List of pse__Resource_Request__c records.
        * @param oldResRequests Map of old pse__Resource_Request__c records by Id.  
      */    
  
   private void updateSumOfTotalHoursOnProjectsForStatusHold(List<pse__Resource_Request__c> resRequests, Map<Id, pse__Resource_Request__c> oldResRequest) {   
        try {            
     Set<String> projectIds = extractProjectIdsForSTHCalculation(resRequests, oldResRequest);   
              if(!projectIds.isEmpty()){            
       updateTotalHoursOnProjectsAsyncForStatusHold(projectIds);    
           }    
       } catch (Exception ex) 
  { SDF_LGR_LoggerManager.DBLoggerTB.error(ex, CLASS_NAME, UPDATE_TOTAL_HOURS_METHOD_NAME);    
       }     }    
  
     /**      * @description Extracts project IDs for sum of total hours calculation.      *  
      * @param resRequests List of pse__Resource_Request__c records.   
     * @param oldResRequests Map of old pse__Resource_Request__c records by Id.  
      *      * @return Set of project IDs.    
    */    
  
   private Set<String> extractProjectIdsForSTHCalculation(List<pse__Resource_Request__c> resRequests, Map<Id, pse__Resource_Request__c> oldResRequests) {        
   Set<String> projectIds = new Set<String>();        
     for (pse__Resource_Request__c resReq : resRequests) {  
             pse__Resource_Request__c oldResReq = oldResRequests.get(resReq.Id);   
            if (oldResReq == null && isValidResReqForSTHCalculation(resReq)) {            
  projectIds.add(resReq.pse__Project__c);          
     }           
    if (oldResReq != null && isValidResReqForSTHCalculation(resReq, oldResReq)) {                 
  projectIds.add(resReq.pse__Project__c);            
       if (resReq.pse__Project__c != oldResReq.pse__Project__c) {                     
  projectIds.add(oldResReq.pse__Project__c);         
     }   }        
   }     
        return projectIds;   }     
  
    /**      * @description Checks if the pse__Resource_Request__c record is valid for sum of total hours calculation.      
  *      * @param resReq pse__Resource_Request__c record.    
    * @return Boolean indicating if the record is valid.    
    */   
  
    private static Boolean isValidResReqForSTHCalculation(pse__Resource_Request__c resReq) {     
      return resReq.pse__SOW_Hours__c != 0 && resReq.pse__Project__c != null && RES_REQ_VALID_STATUS.contains(resReq.pse__Status__c);     }    
  
     /**      * @description Checks if the pse__Resource_Request__c record is valid for sum of total hours calculation.      
  *      * @param resReq pse__Resource_Request__c record.     
   * @param oldResReq Old version of pse__Resource_Request__c record.     
   * @return Boolean indicating if the record is valid. 
       */ 
  
  private static Boolean isValidResReqForSTHCalculation(pse__Resource_Request__c resReq, pse__Resource_Request__c oldResReq) {   
        return (RES_REQ_VALID_STATUS.contains(resReq.pse__Status__c) ||  RES_REQ_VALID_STATUS.contains(oldResReq.pse__Status__c)) && (resReq.pse__SOW_Hours__c != oldResReq.pse__SOW_Hours__c || resReq.pse__Project__c != oldResReq.pse__Project__c || resReq.pse__Status__c != oldResReq.pse__Status__c);     
  }   
  
      /**  @description Updates the total hours on projects asynchronously.   
     *      * @param projectIds Set of project IDs.      
  */     
  
  @future     private static void updateTotalHoursOnProjectsAsync(Set<String> projectIds) {      
     try {            
   // Calculate the sum of total hours for each project using the Rollup Summaries Calculator           
    Map<String, Decimal> totalHoursSumByProjectMap = getTotalHoursCalculator(projectIds).calculateSum();      
           // Prepare a list of projects with updated total hours     
          List<pse__Proj__c> projectsToUpdate = getProjectsWithUpdatedTotalHours(totalHoursSumByProjectMap);       
          // Update the projects with the updated total hours in the database     
          Database.SaveResult[] srList = Database.update(projectsToUpdate, false);      
           // Log the errors occurred while updating the records         
      SDF_LGR_LoggerManager.DBLoggerTB.error(srList, CLASS_NAME, UPDATE_TOTAL_HOURS_ASYNC_METHOD_UPDATE_ACTION);    
       } catch (Exception ex) {            
   SDF_LGR_LoggerManager.DBLoggerTB.error(ex, CLASS_NAME, UPDATE_TOTAL_HOURS_ASYNC_METHOD_NAME);  
         }     } 
  
      /**      * @description Updates the total hours on projects asynchronously when the RR status is Hold..     
   *      * @param projectIds Set of project IDs.      
  */     
  @future     
  private static void updateTotalHoursOnProjectsAsyncForStatusHold(Set<String> projectIds) {    
       try {    
      
       // Calculate the sum of total hours for each project using the Rollup Summaries Calculator    
           Map<String, Decimal> totalHoursSumByProjectMap = getTotalHoursCalculatorForStatusHold(projectIds).calculateSum();          
       // Prepare a list of projects with updated total hours          
     List<pse__Proj__c> projectsToUpdate = getProjectsWithUpdatedTotalHoursForStatusHold(totalHoursSumByProjectMap);       
          // Update the projects with the updated total hours in the database           
    Database.SaveResult[] srList = Database.update(projectsToUpdate, false);      
           // Log the errors occurred while updating the records          
     SDF_LGR_LoggerManager.DBLoggerTB.error(srList, CLASS_NAME, UPDATE_TOTAL_HOURS_ASYNC_METHOD_UPDATE_ACTION);    
       } catch (Exception ex) {   
            SDF_LGR_LoggerManager.DBLoggerTB.error(ex, CLASS_NAME, UPDATE_TOTAL_HOURS_ASYNC_METHOD_NAME);       
    }     }       
  
  /**      * @description Retrieves the total hours calculator instance.      *  
      * @param projectIds Set of project IDs.     
   * @return TB_RollupSummariesCalculator instance.      
  */   
  
    private static TB_RollupSummariesCalculator getTotalHoursCalculator(Set<String> projectIds) {   
        return new TB_RollupSummariesCalculator(projectIds)        
       .setChildObjectName(OBJECT_NAME)            
   .setParentLookupFieldName(PARENT_LOOKUP_FIELD_NAME)  
             .setFieldToAggregate(FIELD_TO_AGGREGATE)     
          .setAdditionalFilters(ADDITIONAL_FILTERS);   
    }         
  
      /**      
  * @description Retrieves the total hours calculator instance when the RR status is Hold..    
    *      * @param projectIds Set of project IDs.      
  * @return TB_RollupSummariesCalculator instance.   
     */
  
       private static TB_RollupSummariesCalculator getTotalHoursCalculatorForStatusHold(Set<String> projectIds) {    
       return new TB_RollupSummariesCalculator(projectIds)   
            .setChildObjectName(OBJECT_NAME)          
     .setParentLookupFieldName(PARENT_LOOKUP_FIELD_NAME)     
          .setFieldToAggregate(FIELD_TO_AGGREGATE)        
       .setAdditionalFilters(ADDITIONAL_FILTERS_FOR_STATUS_HOLD);   
    }      
  
   /**      
  * @description Retrieves the list of projects with updated total hours.     
   *      * @param totalHoursSumByProjectMap Map containing project IDs mapped to their total hours. 
       * @return List of pse__Proj__c records to update.     
   */     
  
  private static List<pse__Proj__c> getProjectsWithUpdatedTotalHours(Map<String, Decimal> totalHoursSumByProjectMap) {         List<pse__Proj__c> projectsToUpdate = new List<pse__Proj__c>();        
     for (String projectId : totalHoursSumByProjectMap.keySet()) {      
         pse__Proj__c proj = new pse__Proj__c();      
         proj.Id = projectId;             proj.TB_Sum_of_the_Total_Hours__c = totalHoursSumByProjectMap.get(projectId); 
              projectsToUpdate.add(proj);         }       
         return projectsToUpdate;     }    
  
    /**      * @description Retrieves the list of projects with updated total hours  when the RR status is Hold.. 
       *      * @param totalHoursSumByProjectMap Map containing project IDs mapped to their total hours.     
   * @return List of pse__Proj__c records to update.     
   */   
  
    private static List<pse__Proj__c> getProjectsWithUpdatedTotalHoursForStatusHold(Map<String, Decimal> totalHoursSumByProjectMap) {     
      List<pse__Proj__c> projectsToUpdate = new List<pse__Proj__c>();           for (String projectId : totalHoursSumByProjectMap.keySet()) {     
          pse__Proj__c proj = new pse__Proj__c();     
          proj.Id = projectId;             proj.TB_Total_Held_Hours__c = totalHoursSumByProjectMap.get(projectId);      
         projectsToUpdate.add(proj);         }           
        return projectsToUpdate;     } }
  