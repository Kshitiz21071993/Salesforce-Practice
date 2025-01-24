public class ContactTriggerHandler {
    
    Public Void HandleBeforeInsert(List<Contact> NewRecords)
    {
     ContactTriggerHelper.PreventDuplicateContact(NewRecords);
    }
    
    Public void HandleAfterInsert(Map<Id, Contact> newMapRecords)
    {        
     ContactTriggerHelper.ContactAddreessSameAsAccountAddress(newMapRecords);
     ContactTriggerHelper.updateNumberOfContact(newMapRecords);
       
    }
    
    Public void HandleAfterDelete(Map<Id, Contact> OldMapRecords)
    {        
     ContactTriggerHelper.updateNumberOfContact(OldMapRecords);
    }
    
}