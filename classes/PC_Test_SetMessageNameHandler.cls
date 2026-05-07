/*********************************************************************************************************
Class Name      : PC_Test_SetMessageNameHandler
Description     : Test class for PC_SetMessageNameHandler
Created Date    : Jul 6, 2021
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer                Date                   Description
--------------------------------------------------------------------------------------------------------------
Chetna Mohapatra      Jul 6, 2021             Initial Version
***************************************************************************************************************/
@isTest
 public class PC_Test_SetMessageNameHandler {
    private static User adminUser;
    private static PC_Message__c message;
    public static Account patientAccount;
    public static Case programCase;

    @testSetup static void setup() {
        // Create Admin User
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'testAdminUser111@test.com', 'test111');
        PC_Database.ins(adminUser);
        //Create Patient Account
        patientAccount = PC_Test_Setup.createPatient('SMS Patient');
        patientAccount = (Account) PC_Database.ins(patientAccount, false);
        // Create Program case
        programCase = PC_Test_Setup.createProgram(patientAccount);
        programCase = (Case) PC_Database.ups(programCase);
    }
    /**
     * This methods verifies if Message name is getting assigned post record creation/insertion
     */
    @isTest static void testMessageNameAssignment() {
        Case caseRecord = [Select Id from Case LIMIT 1];
        User adminUser111 = [Select Id from User WHERE username = 'testAdminUser111@test.com'];
        Account smsPatient=[SELECT Id FROM Account WHERE PC_First_Name__c ='SMS Patient'];
        System.runAs(adminUser111) {
            Test.StartTest();
            //Create a Message record on Case and assign an account
            message = PC_Test_Setup.createMessage(caseRecord);
            message.PC_ReceiverAccount__c =smsPatient.Id;
            message = (PC_Message__c) PC_Database.ins(message, false);
            system.assertNotEquals(message.name, message.Id);
            //Create a Message record on Case and assign an external recipient
            message = PC_Test_Setup.createMessage(caseRecord);
            message.PC_ExternalRecipientName__c='Test External';
            message = (PC_Message__c) PC_Database.ins(message, false);
            system.assertNotEquals(message.name, message.Id);
            //Create a Message record on Case and assign a user
            message = PC_Test_Setup.createMessage(caseRecord);
            message.PC_ReceiverUser__c=adminUser111.Id;
            message = (PC_Message__c) PC_Database.ins(message, false);
            system.assertNotEquals(message.name, message.Id);

            Test.StopTest();
        }
    }
}