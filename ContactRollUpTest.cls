@isTest
public with sharing class ContactRollUpTest {
    @isTest
    static void testRollUpSummary() {
        // Step 1: Create Accounts
        Account acc1 = new Account(Name = 'Test 002', First_Name__c = 'Account 1',Last_Name__c = 'Test Name002');
        Account acc2 = new Account(Name = 'Test 001',First_Name__c = 'Account 1',Last_Name__c = 'Test Name001');
        insert new List<Account>{ acc1, acc2 };

        // Step 2: Create Contacts
        Contact con1 = new Contact(FirstName = 'John', LastName = 'Doe', AccountId = acc1.Id);
        Contact con2 = new Contact(FirstName = 'Jane', LastName = 'Smith', AccountId = acc1.Id);
        Contact con3 = new Contact(FirstName = 'Sam', LastName = 'Wilson', AccountId = acc2.Id);
        insert new List<Contact>{ con1, con2, con3 };

        // Verify roll-up count on Account
        Account updatedAcc1 = [SELECT Number_Of_Contacts__c FROM Account WHERE Id = :acc1.Id];
        system.debug('updatedAcc1 '+updatedAcc1.Number_Of_Contacts__c);
        Account updatedAcc2 = [SELECT Number_Of_Contacts__c FROM Account WHERE Id = :acc2.Id];
        system.debug('updatedAcc2 '+updatedAcc2.Number_Of_Contacts__c);
        System.assertEquals(2, updatedAcc1.Number_Of_Contacts__c, 'Account 1 should have 2 contacts');
        System.assertEquals(1, updatedAcc2.Number_Of_Contacts__c, 'Account 2 should have 1 contact');
    }
}

