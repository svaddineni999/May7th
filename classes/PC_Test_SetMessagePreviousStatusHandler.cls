/*********************************************************************************************************
Class Name      : PC_Test_SetMessagePreviousStatusHandler
Description     : Test class for PC_SetMessagePreviousStatusHandler
Created Date    : May 10, 2021
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer          Date                   Description
--------------------------------------------------------------------------------------------------------------
Chetna Mohapatra      May 10, 2021         [PC-7707] Initial Version
***************************************************************************************************************/
@isTest
 public class PC_Test_SetMessagePreviousStatusHandler {
    private static User adminUser;
    private static PC_Message__c message;
    public static Account patientAccount;
    public static Case programCase;

    @testSetup static void setup() {
        // Create Admin User
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'testAdminUser12@test.com', 'test12');
        PC_Database.ins(adminUser);
        //Create Patient Account
        patientAccount = PC_Test_Setup.createPatient('Test Patient 12');
        patientAccount.PC_Date_of_Birth__c = Date.today();
        patientAccount = (Account) PC_Database.ins(patientAccount, false);
        // Create Program case
        programCase = PC_Test_Setup.createProgram(patientAccount);
        programCase = (Case) PC_Database.ups(programCase);
    }
    /**
     * This methods verifies if Message previous status is getting assigned on current status update
     */
    @isTest static void testMessagePreviousStatusUpdate() {
        Case caseRecord = [Select Id from Case LIMIT 1];
        User adminUser12 = [Select Id from User WHERE username = 'testAdminUser12@test.com'];
        System.runAs(adminUser12) {
            Test.StartTest();
            //Create a Message record on Case and assign a current status
            message= PC_Test_Setup.createMessage(caseRecord);
            message.PC_FromAlias__c= '48484848';
            message.PC_Type__c='Outbound';
            message.PC_Message_Status__c= 'Draft';
            message=(PC_Message__c) PC_Database.ins(message, false);
            system.assertNotEquals(message.Id, null);

            //Update the message status on the record
            message.PC_Message_Status__c='Queued';
            message=(PC_Message__c) PC_Database.upd(message, false);
            PC_Message__c msg= [Select PC_MessagePreviousStatus__c from PC_Message__c where PC_FromAlias__c= '48484848'];
            system.assertEquals(msg.PC_MessagePreviousStatus__c, 'Draft');
            Test.StopTest();

        }
    }
}