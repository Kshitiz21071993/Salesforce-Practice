
/**  
* @description     : Helper class of Rollup Summaries Calculator  
* @author            : Nishkarsh Manav  
* @group             :  * @last modified on  : 07-30-2024 
 * @last modified by  : Nithin C.H 
**/ public inherited sharing class 

TB_RollupSummariesHelper {    
    private TB_RollupSummariesCalculator calculator;      
    // Query template for calculating roll-up summary     
   private static final String ROLLUP_SUMMARY_QUERY_TEMPLATE = 'SELECT {0}, {4}({1}) aggValue FROM {2} WHERE {0} IN :parentIds {3} GROUP BY {0}';   
    private static final String REQUIRED_PROPERTY_MISSING_ERROR_MESSAGE = 'Required properties are not set. Please set all required properties before calculating rollup summaries.';    
    private static final String AGGREGATE_RESULT_FIELD = 'aggValue';   
     private static final String BIND_PARAMETER_PARENT_IDS = 'parentIds';      
   
    /**      * @description Constructor for the TB_RollupSummariesHelper class.     
    *      * @param calculator An instance of TB_RollupSummariesCalculator that will be used for rollup calculations.   
      */     
   
   public TB_RollupSummariesHelper(TB_RollupSummariesCalculator calculator) {       
     // Assign the provided calculator instance to the class's calculator variable       
     this.calculator = calculator;     }     
     /**     
   
    * @description Performs the roll-up summary calculation based on the provided aggregate operator    
    *      * @param aggregateOperator Aggregate operator to perform the calculation.      
   *      * @return Map containing parent record IDs mapped to their respective roll-up summary values.    
     */    
    public Map<String, Decimal> performRollUpSummaryNumberCalculation(TB_RollupSummariesCalculator.AggregateOperator aggregateOperator) {  
          Map<String, Decimal> parentIdToRollupValue = initializeRollupDecimalValueMap(calculator.getParentRecordIds());        
    List<AggregateResult> results = queryDatabase(aggregateOperator.name());        
      for (AggregateResult ar : results) {      
          String parentId = (String) ar.get(calculator.getParentLookupFieldName());  
              Decimal aggValue = (Decimal) ar.get(AGGREGATE_RESULT_FIELD);       
           parentIdToRollupValue.put(parentId, aggValue);         }          
    return parentIdToRollupValue;     }    
   
      /**      * @description Performs the roll-up summary calculation based on the provided aggregate operator    
     *      * @param aggregateOperator Aggregate operator to perform the calculation.    
     *      * @return Map containing parent record IDs mapped to their respective roll-up summary values.    
     */     
   
   public Map<String, Date> performRollUpSummaryDateCalculation(TB_RollupSummariesCalculator.AggregateOperator aggregateOperator) {      
      Map<String, Date> parentIdToRollupValue = initializeRollupDateValueMap(calculator.getParentRecordIds());    
        List<AggregateResult> results = queryDatabase(aggregateOperator.name());  
            for (AggregateResult ar : results) {        
        String parentId = (String) ar.get(calculator.getParentLookupFieldName());    
            Object dateObject = ar.get(AGGREGATE_RESULT_FIELD);       
           if(dateObject != null){  
            Date aggValue = (dateObject instanceOf Date) ? (Date) dateObject : Date.parse((String) dateObject);        
              parentIdToRollupValue.put(parentId, aggValue);           
     }         
     }         
     return parentIdToRollupValue;    
    }       
   
   /**      
   * @description Validates if any required properties are missing.    
     * If any required property is missing, it throws a custom exception.     
    */     
   
   public void validateRequiredProperties() { 
           if (isAnyRequiredPropertyMissing()) { 
               // Throw a custom exception with a message indicating the missing required property            
    throw new TB_Utility.CustomException(REQUIRED_PROPERTY_MISSING_ERROR_MESSAGE);    
        }   
     }      
   
    // Queries the database using the constructed SOQL query     
   private List<AggregateResult> queryDatabase(String aggregateOperatorName) {   
         List<Object> queryParams = new List<Object> {  
    calculator.getParentLookupFieldName(),                         
    calculator.getFieldToAggregate(),       
    calculator.getChildObjectName(),      
     calculator.getAdditionalFilters(),          
     aggregateOperatorName };         
     String query = String.format(ROLLUP_SUMMARY_QUERY_TEMPLATE, queryParams);      
      Map<String, Object> bindParams = new Map<String, Object>{
    BIND_PARAMETER_PARENT_IDS => calculator.getParentRecordIds() };    
          return (List<AggregateResult>) 
   Database.queryWithBinds(query, bindParams, calculator.getAccessLevel());    
    }      
   
    // Initializes the map for storing roll-up summary values   
   
     private static Map<String, Decimal> initializeRollupDecimalValueMap(Set<String> parentRecordIds) {    
        Map<String, Decimal> parentIdToRollupValue = new Map<String, Decimal>();  
          for (String parentRecordId : parentRecordIds) {             parentIdToRollupValue.put(parentRecordId, 0); 
   // Initialize rollup value to 0        
    }          
    return parentIdToRollupValue;     }  
       
    // Initializes the map for storing roll-up summary values     
   
   private static Map<String, Date> initializeRollupDateValueMap(Set<String> parentRecordIds) {         Map<String, Date> parentIdToRollupValue = new Map<String, Date>();  
          for (String parentRecordId : parentRecordIds) {             parentIdToRollupValue.put(parentRecordId, null);      
      }           return parentIdToRollupValue;     }     
   
     // Checks if any of the required property is missing
        private Boolean isAnyRequiredPropertyMissing() {         return  calculator.getParentRecordIds().isEmpty() ||                 String.isBlank(calculator.getChildObjectName()) ||                 String.isBlank(calculator.getParentLookupFieldName()) ||                 String.isBlank(calculator.getFieldToAggregate());     } }
   

   