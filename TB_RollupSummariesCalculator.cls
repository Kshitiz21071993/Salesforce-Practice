/**  * @description       : This class calculates roll-up summaries for a given set of parent records based on child records.  * 
@author            : Nishkarsh Manav  *
 @group             :  * @last modified on  : 07-29-2024
 * @last modified by  : Nishkarsh Manav
 **/ 

 public inherited sharing class TB_RollupSummariesCalculator { 
    private Set<String> parentRecordIds = new Set<String>();    
     private String childObjectName;    
     private String parentLookupFieldName;    
     private String fieldToAggregate;     
    private AccessLevel accessLevel =System.AccessLevel.SYSTEM_MODE;   
     private String additionalFilters = '';      
    
     /**      * @description Retrieves the set of parent record IDs.      *     
                 * @return The set of parent record IDs.     
    * */     
    
    public Set<String> getParentRecordIds() {         
    return parentRecordIds;    
     }      
    
     /**    
    * @description Constructor to initialize the parent records.      
    *     
     * @param parentRecordIds List of parent record IDs.     
     **/     
    public TB_RollupSummariesCalculator(List<String> parentRecordIds) {       
      if(parentRecordIds != null && !parentRecordIds.isEmpty()){           
      this.parentRecordIds.addAll(parentRecordIds);           
      this.parentRecordIds.remove(null);         }     }      
    
     /** 
      * @description Constructor to initialize the parent records.      *   
      * @param parentRecordIds Set of parent record IDs.      
    **/     
    public TB_RollupSummariesCalculator(Set<String> parentRecordIds) {     
        if(parentRecordIds != null && !parentRecordIds.isEmpty()){    
           this.parentRecordIds.addAll(parentRecordIds);           
            this.parentRecordIds.remove(null);       
          }   
         }      
    
    /**     
    * @description Constructor to initialize the parent record IDs.           
    * @description Retrieves the API name of the child object.  
     * @return The API name of the child object.      
     * **/    
    
     public String getChildObjectName() {      
       return childObjectName;     }      
    
     /** @description Setter method for setting the child object name.           
        * @param childObjectName API name of the child object.     
        * @return TB_RollupSummariesCalculator instance for method chaining. 
    **/         
    
    public TB_RollupSummariesCalculator setChildObjectName(String childObjectName) { 
       this.childObjectName = childObjectName;        
       return this;     }       

    
    /** @description Retrieves the API name of the parent lookup field on the child object.      *     
     * @return The API name of the parent lookup field on the child object.     
    * */  
    
       public String getParentLookupFieldName() {     
        return parentLookupFieldName;     }    
    
    
    /**      
    @description Setter method for setting the parent lookup field name.      *   
    * @param parentLookupFieldName API name of the parent lookup field on the child object.    
    * @return TB_RollupSummariesCalculator instance for method chaining.     
    */   
    
      public TB_RollupSummariesCalculator setParentLookupFieldName(String parentLookupFieldName) {  
            this.parentLookupFieldName = parentLookupFieldName;         
            return this;     }     
    
      /**      * @description Retrieves the API name of the field to aggregate on the child object.      *  
        * @return The API name of the field to aggregate on the child object.    
      */     
    public String getFieldToAggregate() {     
        return fieldToAggregate;     }      
     /**    
    
      * @description Setter method for setting the field to aggregate.     
     *     
     * @param fieldToAggregate API name of the field to aggregate on the child object.     
     * @return TB_RollupSummariesCalculator instance for method chaining.      
    */    
    
     public TB_RollupSummariesCalculator setFieldToAggregate(String fieldToAggregate) {    
         this.fieldToAggregate = fieldToAggregate;          
     return this;     }       /**  
    
        * @description Retrieves additional filters to be applied to the SOQL query.      *   
       * @return Additional filters to be applied to the SOQL query.     
     */     
    public String getAdditionalFilters() { 
            return additionalFilters;     }    
    
       /**
        *  @description Setter method for setting additional filters for the SOQL query.     
        * @param additionalFilters Additional filters to be applied to the SOQL query.      
         * @return TB_RollupSummariesCalculator instance for method chaining.    
      */     
    
    public TB_RollupSummariesCalculator setAdditionalFilters(String additionalFilters) {    
     if(String.isNotBlank(additionalFilters)) {       
          this.additionalFilters = additionalFilters;  }    
           return this;     }      
    
     /**     
     * @description Retrieves the access level for the database query.     
     *      
    * @return The access level for the database query.    
      */     
    
    public AccessLevel getAccessLevel() {        
     return accessLevel;     }      
     /**      * @description Setter method for setting the access level for the database query.      *    
      * @param accessLevel Access level for the database query.      
    * @return TB_RollupSummariesCalculator instance for method chaining.      
    */     
    
    public TB_RollupSummariesCalculator setAccessLevel(AccessLevel accessLevel) {      
       if(accessLevel != null) {   
              this.accessLevel = accessLevel;         }     
          return this;     }     
    
      /**      * @description Calculates the roll-up summary values for the given parent records.      *
          * @return Map containing parent record IDs mapped to their respective roll-up summary values.   
       * @throws IllegalStateException if required properties are not set.      
    */     
    
    public Map<String, Decimal> calculateSum() {
     TB_RollupSummariesHelper helper = new TB_RollupSummariesHelper(this);     
        helper.validateRequiredProperties();     
         return helper.performRollUpSummaryNumberCalculation(AggregateOperator.SUM);    
     }     
    
      /**        * @description calculates the count of roll-up summaries using the COUNT operator.      
      * It instantiates a TB_RollupSummariesHelper object with the current object as a parameter and assigns it to the variable "helper".     
       * It then calls the "validateRequiredProperties" method on the "helper" object to validate any required properties.        
    * @returns the result of calling the "performRollUpSummaryNumberCalculation" method on the "helper" object with the AggregateOperator.COUNT parameter.      
      * */       
      public Map<String, Decimal> calculateCount() {      
       TB_RollupSummariesHelper helper = new TB_RollupSummariesHelper(this);     
        helper.validateRequiredProperties();           
    return helper.performRollUpSummaryNumberCalculation(AggregateOperator.COUNT);  
       }       
    
    public Map<String, Date> calculateMaxDate() {  
           TB_RollupSummariesHelper helper = new TB_RollupSummariesHelper(this);    
         helper.validateRequiredProperties();       
        return helper.performRollUpSummaryDateCalculation(AggregateOperator.Max);     }       
    
/**  * @description       : This class calculates roll-up summaries for a given set of parent records based on child records.  * 
@author            : Nishkarsh Manav  *
 @group             :  * @last modified on  : 07-29-2024
 * @last modified by  : Nishkarsh Manav
 **/ 

public inherited sharing class TB_RollupSummariesCalculator { 
private Set<String> parentRecordIds = new Set<String>();    
 private String childObjectName;    
 private String parentLookupFieldName;    
 private String fieldToAggregate;     
private AccessLevel accessLevel =System.AccessLevel.SYSTEM_MODE;   
 private String additionalFilters = '';      

 /**      * @description Retrieves the set of parent record IDs.      *     
             * @return The set of parent record IDs.     
* */     

public Set<String> getParentRecordIds() {         
return parentRecordIds;    
 }      

 /**    
* @description Constructor to initialize the parent records.      
*     
 * @param parentRecordIds List of parent record IDs.     
 **/     
public TB_RollupSummariesCalculator(List<String> parentRecordIds) {       
  if(parentRecordIds != null && !parentRecordIds.isEmpty()){           
  this.parentRecordIds.addAll(parentRecordIds);           
  this.parentRecordIds.remove(null);         }     }      

 /**      * @description Constructor to initialize the parent records.      *   
           * @param parentRecordIds Set of parent record IDs.      
**/     
public TB_RollupSummariesCalculator(Set<String> parentRecordIds) {     
    if(parentRecordIds != null && !parentRecordIds.isEmpty()){         
            this.parentRecordIds.addAll(parentRecordIds);           
             this.parentRecordIds.remove(null);         }     }       

/**     
* @description Retrieves the API name of the child object.  
 * @return The API name of the child object.      **/    

 public String getChildObjectName() {      
   return childObjectName;     }      

 /**      * @description Setter method for setting the child object name.      *      
          * @param childObjectName API name of the child object.     
      * @return TB_RollupSummariesCalculator instance for method chaining.      */     

public TB_RollupSummariesCalculator setChildObjectName(String childObjectName) { 
        this.childObjectName = childObjectName;        
   return this;     }       

/**      * @description Retrieves the API name of the parent lookup field on the child object.      *     
 * @return The API name of the parent lookup field on the child object.     * */  

   public String getParentLookupFieldName() {     
    return parentLookupFieldName;     }    


   /**      
* @description Setter method for setting the parent lookup field name.      *   
   * @param parentLookupFieldName API name of the parent lookup field on the child object.    
  * @return TB_RollupSummariesCalculator instance for method chaining.     
 */   

  public TB_RollupSummariesCalculator setParentLookupFieldName(String parentLookupFieldName) {         this.parentLookupFieldName = parentLookupFieldName;         
          return this;     }     

  /**      * @description Retrieves the API name of the field to aggregate on the child object.      *  
    * @return The API name of the field to aggregate on the child object.    
  */     
public String getFieldToAggregate() {     
    return fieldToAggregate;     }      
 /**    

  * @description Setter method for setting the field to aggregate.     
 *     
 * @param fieldToAggregate API name of the field to aggregate on the child object.     
 * @return TB_RollupSummariesCalculator instance for method chaining.      
*/    

 public TB_RollupSummariesCalculator setFieldToAggregate(String fieldToAggregate) {    
     this.fieldToAggregate = fieldToAggregate;          
 return this;     }       /**  

    * @description Retrieves additional filters to be applied to the SOQL query.      *   
   * @return Additional filters to be applied to the SOQL query.     
 */     
public String getAdditionalFilters() { 
        return additionalFilters;     }    

   /**      * @description Setter method for setting additional filters for the SOQL query.      *      * @param additionalFilters Additional filters to be applied to the SOQL query.      
* @return TB_RollupSummariesCalculator instance for method chaining.    
  */     

public TB_RollupSummariesCalculator setAdditionalFilters(String additionalFilters) {    
 if(String.isNotBlank(additionalFilters)) {       
      this.additionalFilters = additionalFilters;  }    
       return this;     }      

 /**     
 * @description Retrieves the access level for the database query.     
 *      
* @return The access level for the database query.    
  */     

public AccessLevel getAccessLevel() {        
 return accessLevel;     }      
 /**      * @description Setter method for setting the access level for the database query.      *    
  * @param accessLevel Access level for the database query.      
* @return TB_RollupSummariesCalculator instance for method chaining.      
*/     

public TB_RollupSummariesCalculator setAccessLevel(AccessLevel accessLevel) {      
   if(accessLevel != null) {   
          this.accessLevel = accessLevel;         }     
      return this;     }     

  /**      * @description Calculates the roll-up summary values for the given parent records.      *
      * @return Map containing parent record IDs mapped to their respective roll-up summary values.   
   * @throws IllegalStateException if required properties are not set.      
*/     

public Map<String, Decimal> calculateSum() {
 TB_RollupSummariesHelper helper = new TB_RollupSummariesHelper(this);     
    helper.validateRequiredProperties();     
     return helper.performRollUpSummaryNumberCalculation(AggregateOperator.SUM);    
 }     

  /**        * @description calculates the count of roll-up summaries using the COUNT operator.      
  * It instantiates a TB_RollupSummariesHelper object with the current object as a parameter and assigns it to the variable "helper".     
   * It then calls the "validateRequiredProperties" method on the "helper" object to validate any required properties.        
* @returns the result of calling the "performRollUpSummaryNumberCalculation" method on the "helper" object with the AggregateOperator.COUNT parameter.      
  * */       
  public Map<String, Decimal> calculateCount() {      
   TB_RollupSummariesHelper helper = new TB_RollupSummariesHelper(this);     
    helper.validateRequiredProperties();           
return helper.performRollUpSummaryNumberCalculation(AggregateOperator.COUNT);  
   }       

public Map<String, Date> calculateMaxDate() {  
       TB_RollupSummariesHelper helper = new TB_RollupSummariesHelper(this);    
     helper.validateRequiredProperties();       
    return helper.performRollUpSummaryDateCalculation(AggregateOperator.Max);   
  }       

/**  
Enum for aggregate operators    
**/

public enum AggregateOperator { 
    SUM,   
    AVG,      
    COUNT,        
    COUNT_DISTINCT,   
    MIN,     
    MAX    
 }
}
}
    