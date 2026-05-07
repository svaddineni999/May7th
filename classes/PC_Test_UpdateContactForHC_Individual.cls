/*********************************************************************************************************
Class Name      : PC_Test_UpdateContactForHC_Individual
Description     : Test class for PC_UpdateContactForHC_Individual
Created Date    : Sep 15, 2021
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer          Date                   Description
--------------------------------------------------------------------------------------------------------------
Haritha Reddy      Sep 15, 2021         [PC-8160] Initial Version
Haritha Reddy      Nov 09, 2021         [PC-8258] Moved assert checks to execute after Test.stopTest()
***************************************************************************************************************/
@isTest
public with sharing class PC_Test_UpdateContactForHC_Individual {
    private static User adminUser;

    @testSetup static void setup() {
        // Create Admin User
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'testAdminUser1@test.com', 'test1');
        PC_Database.ins(adminUser);

    }

    @isTest static void testBulkAccountUpdate_HCIndividual() {
        User adminUser1 = [Select Id from User WHERE username = 'testAdminUser1@test.com'];
        System.runAs(adminUser1) {
            Test.StartTest();

            List<Account> patientAccounts = PC_Test_Setup.createAccounts('test', 200, PC_Constants.PATIENT_RECORD_TYPE);
            patientAccounts = (List<Account>)PC_Database.ins(patientAccounts, false);
            System.assertEquals(patientAccounts.size(), 200);

            Test.stopTest();
            //When account is inserted for the record types declared in Health cloud individual mapper,
            //Primary Contact is populated asynchronously by Health cloud. So, evaluations should be done after Test.stopTest() in test class.
            Set<Id> accountIds = (new Map<Id,SObject>(patientAccounts)).keySet();
            List<Contact> contactList = [Select Id,AccountId from Contact where AccountId IN: accountIds];
            System.assertEquals(contactList.size(), 200);

            Map<Id,Id> accountToContactIdMap = new Map<Id,Id>();
            Set<Id> contactIds =  new Set<Id>();
            for(Contact cont: contactList){
                accountToContactIdMap.put(cont.AccountId, cont.Id);
                contactIds.add(cont.Id);
            }

            for(Account acc: patientAccounts){
                acc.PC_Email__c = 'test@email.com';
            }
            patientAccounts = (List<Account>)PC_Database.upd(patientAccounts);

            contactList = [Select Id,Email,account.PC_Email__c from Contact where Id IN: contactIds];
            for(Contact cont: contactList){
                System.assertEquals(cont.Email, String.valueOf(cont.account.PC_Email__c));
            }
        }
    }
}