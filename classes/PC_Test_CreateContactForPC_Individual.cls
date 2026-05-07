/*********************************************************************************************************
Class Name      : PC_Test_CreateContactForPC_Individual
Description     : Test class for PC_CreateContactForPC_Individual
Created Date    : Sep 15, 2021
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer          Date                   Description
--------------------------------------------------------------------------------------------------------------
Haritha Reddy      Sep 15, 2021         [PC-8160] Initial Version
Haritha Reddy      Sep 29, 2021         [PC-8161] Added assert check to verify if primary contact is getting populated on PC Individual Account creation
***************************************************************************************************************/
@isTest
public class PC_Test_CreateContactForPC_Individual {
    private static User adminUser;

    @testSetup static void setup() {
        // Create Admin User
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'testAdminUser1@test.com', 'test1');
        PC_Database.ins(adminUser);

    }

    @isTest static void testBulkAccountInsert_PCIndividual() {
        User adminUser1 = [Select Id from User WHERE username = 'testAdminUser1@test.com'];
        System.runAs(adminUser1) {
            Test.StartTest();

            List<Account> physicianAccounts = PC_Test_Setup.createAccounts('test', 200, PC_Constants.PHYSICIAN_RECORD_TYPE);
            physicianAccounts = (List<Account>)PC_Database.ins(physicianAccounts, false);
            System.assertEquals(physicianAccounts.size(), 200);

            Set<Id> accountIds = (new Map<Id,SObject>(physicianAccounts)).keySet();
            List<Contact> contactList = [Select Id,Email,LastName,FirstName,Fax,Phone,Birthdate,Salutation,account.PC_Email__c,account.HealthCloudGA__PrimaryContact__c,
                    account.PC_Last_Name__c,account.PC_First_Name__c,account.Fax,account.Phone,account.PC_Date_of_Birth__c,account.PC_Salutation__c
                                            from Contact where AccountId IN: accountIds];
            System.assertEquals(contactList.size(), 200);

            for(Contact cont: contactList){
                System.assertEquals(cont.Email, cont.account.PC_Email__c);
                System.assertEquals(cont.LastName, cont.account.PC_Last_Name__c);
                System.assertEquals(cont.FirstName, cont.account.PC_First_Name__c);
                System.assertEquals(cont.Fax, cont.account.Fax);
                System.assertEquals(cont.Phone, cont.account.Phone);
                System.assertEquals(cont.Birthdate, cont.account.PC_Date_of_Birth__c);
                System.assertEquals(cont.Salutation, cont.account.PC_Salutation__c);
                System.assertEquals(cont.Id, cont.account.HealthCloudGA__PrimaryContact__c);
            }
            Test.stopTest();
        }
    }

    @isTest static void testBulkAccountInsert_HCIndividual() {
        User adminUser1 = [Select Id from User WHERE username = 'testAdminUser1@test.com'];
        System.runAs(adminUser1) {
            Test.StartTest();

            List<Account> patientAccounts = PC_Test_Setup.createAccounts('test', 200, PC_Constants.PATIENT_RECORD_TYPE);
            patientAccounts = (List<Account>)PC_Database.ins(patientAccounts, false);
            System.assertEquals(patientAccounts.size(), 200);

            Set<Id> accountIds = (new Map<Id,SObject>(patientAccounts)).keySet();
            List<Contact> contactList = [Select Id from Contact where AccountId IN: accountIds];
            System.assertEquals(contactList.size(), 200);

            Test.stopTest();
        }
    }

    @isTest static void testBulkAccountInsert_NotIndividual() {
        User adminUser1 = [Select Id from User WHERE username = 'testAdminUser1@test.com'];
        System.runAs(adminUser1) {
            Test.StartTest();

            List<Account> hcoAccounts = PC_Test_Setup.createAccounts('test', 200, PC_Constants.HCO_RecordType);
            hcoAccounts = (List<Account>)PC_Database.ins(hcoAccounts, false);
            System.assertEquals(hcoAccounts.size(), 200);

            Set<Id> accountIds = (new Map<Id,SObject>(hcoAccounts)).keySet();
            List<Contact> contactList = [Select Id from Contact where AccountId IN: accountIds];
            System.assertEquals(contactList.size(), 0);

            Test.stopTest();
        }
    }
}