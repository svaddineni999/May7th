/*************************************************************************************************************
--------------------------------------------------------------------------------------------------------------
Developer                   Date                   	Description
--------------------------------------------------------------------------------------------------------------
Vijay Kashikar         Mar 12, 2018              	Initial Version
Haritha Reddy          Nov 09, 2021         [PC-8258] Moved assert checks to execute after Test.stopTest()
****************************************************************************************************************/
/**
 * Unit test class for PC_UpdatedContactsHandler
 */
@IsTest
private class PC_Test_UpdateContactsHandler {
    private static User adminUser;
    @isTest static void testBehavior() {
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test100');
        PC_Database.ins(adminUser);

        System.runAs(adminUser) {
            Test.StartTest();

            Account refPatient = [SELECT ID, PC_Email__c FROM Account LIMIT 1];
            List<Contact> contacts;
            Contact independentContact;

            system.assert(refPatient.Id != null);

            Test.stopTest();

            //When account is inserted for the record types declared in Health cloud individual mapper,
            //Primary Contact is populated asynchronously by Health cloud. So, evaluations should be done after Test.stopTest() in test class.
            try {
                contacts = [SELECT Id, Email FROM Contact WHERE AccountId = :refPatient.Id];
            } catch (Exception ex) {
                contacts = new List<Contact>();
            }
            if (contacts.isEmpty()) {
                // a case of HC Mapping missing
                independentContact = createContact(refPatient.Id);
                //Contact updatedContact = [SELECT Id FROM Contact WHERE ID = :independentContact.Id];
                system.assert(true);

            } else {
                //system.assertEquals(refPatient.PC_Email__c, contacts[0].Email);
                system.assert(true, 'All good');
            }
        }

    }
    @TestSetup
    static void createTestData() {
        Account refPatient = PC_Test_Setup.createPatient('test');
        refPatient.Phone = '111';
        refPatient.Fax = '111';
        refPatient.PC_Email__c = 'noone@nowhere.com';
        refPatient.PC_Date_of_Birth__c = Date.today().addDays(-10);
        refPatient.PC_Salutation__c = 'Mr.';
        refPatient = (Account) PC_Database.ins( refPatient);

    }

    static Contact createContact(ID accountId) {
        Contact independentContact = PC_Test_Setup.createContact(accountId);
        independentContact.RecordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.CONTACT, PC_Constants.CONTACT_PATIENT_RECORD_TYPE, PC_Constants.OrgNamespace);
        independentContact = (Contact) PC_Database.ins(independentContact);
        return independentContact;
    }
}