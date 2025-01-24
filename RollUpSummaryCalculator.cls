/**
     * Updates roll-up summary fields on parent records based on child records.
     *
     * @param childRecords List of child SObject records.
     * @param parentObjectName API name of the parent object.
     * @param parentField API name of the field on the parent object to update.
     * @param childFieldToSum API name of the field on the child object to sum.
     * @param childParentField API name of the field on the child object linking to the parent object.
     */
public with sharing class RollUpSummaryCalculator {

        public static void updateRollup(
            List<SObject> childRecords,
            String parentObjectName,
            String parentField,
            String childFieldToSum,
            String childParentField
        ) {
            if (childRecords == null || childRecords.isEmpty()) {
                return; // No records to process
            }
    
            // Map to hold aggregated values for parent records
            Map<Id, Decimal> rollupMap = new Map<Id, Decimal>();
    
            // Aggregate child records
            for (SObject child : childRecords) {
                Id parentId = (Id)child.get(childParentField);
    
                // Initialize the value if the key doesn't exist
                if (!rollupMap.containsKey(parentId)) {
                    rollupMap.put(parentId, 0);
                }
    
                // Handle count or sum logic
                if (String.isNotBlank(childFieldToSum)) {
                    Decimal fieldValue = (Decimal)child.get(childFieldToSum);
                    rollupMap.put(parentId, rollupMap.get(parentId) + (fieldValue != null ? fieldValue : 0));
                } else {
                    // Count the record if no field is provided to sum
                    rollupMap.put(parentId, rollupMap.get(parentId) + 1);
                }
            }
    
            // Query parent records to update
            List<SObject> parentRecordsToUpdate = new List<SObject>();
            for (Id parentId : rollupMap.keySet()) {
                SObject parentRecord = Schema.getGlobalDescribe().get(parentObjectName).newSObject(parentId);
                parentRecord.put(parentField, rollupMap.get(parentId));
                parentRecordsToUpdate.add(parentRecord);
            }
    
            // Update parent records
            if (!parentRecordsToUpdate.isEmpty()) {
                try {
                    update parentRecordsToUpdate;
                } catch (DmlException e) {
                    System.debug('Error updating parent records: ' + e.getMessage());
                }
            }
        }
    }