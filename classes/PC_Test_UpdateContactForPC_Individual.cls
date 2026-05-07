/*********************************************************************************************************
Class Name      : PC_Test_UpdateContactForPC_Individual
Description     : Test class for PC_UpdateContactForPC_Individual
Created Date    : Sep 15, 2021
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer          Date                   Description
--------------------------------------------------------------------------------------------------------------
Haritha Reddy      Sep 15, 2021         [PC-8160] Initial Version
Haritha Reddy      Sep 29, 2021         [PC-8161] Added assert check to verify primary contact is getting updated on PC Individual Account update
***************************************************************************************************************/
@isTest
public class PC_Test_UpdateContactForPC_Individual {
    private static User adminUser;

    @testSetup static void setup() {
        // Create Admin User
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'testAdminUser1@test.com', 'test1');
        PC_Database.ins(adminUser);

    }

    @isTest static void testBulkAccountUpdate_PCIndividual() {
        User adminUser1 = [Select Id from User WHERE username = 'testAdminUser1@test.com'];
        System.runAs(adminUser1) {
            Test.StartTest();

            List<Account> physicianAccounts = PC_Test_Setup.createAccounts('test', 200, PC_Constants.PHYSICIAN_RECORD_TYPE);
            physicianAccounts = (List<Account>)PC_Database.ins(physicianAccounts, false);
            System.assertEquals(physicianAccounts.size(), 200);


            for(Account acc: physicianAccounts){
                acc.PC_Email__c = 'test@email.com';
            }
            physicianAccounts = (List<Account>)PC_Database.upd(physicianAccounts);

            Set<Id> accountIds = (new Map<Id,SObject>(physicianAccounts)).keySet();
            List<Contact> contactList = [Select Id,Email,account.PC_Email__c,account.HealthCloudGA__PrimaryContact__c from Contact where AccountId IN: accountIds];
            System.assertEquals(contactList.size(), 200);

            for(Contact cont: contactList){
                System.assertEquals(cont.Id, cont.account.HealthCloudGA__PrimaryContact__c);
                System.assertEquals(cont.Email, String.valueOf(cont.account.PC_Email__c));
            }

            Test.stopTest();
        }
    }
}