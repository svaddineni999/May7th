/*********************************************************************************************************
Class Name      : PC_Test_SetReminderLogStatusHandler
Description     : Test class for PC_SetReminderLogStatusHandler
Created Date    : Oct 15, 2021
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer                Date                   Description
--------------------------------------------------------------------------------------------------------------
Kishore Kanteti      Oct 15, 2021             Initial Version
***************************************************************************************************************/
@isTest
public class PC_Test_SetReminderLogStatusHandler{
    private static User adminUser;
    private static PC_Message__c message;
    public static Account patientAccount;
    public static Case programCase;
    public static PC_ReminderQueue__c reminderQueue;
    public static PC_ReminderLog__c reminderLog;
    private static final String DELIVERED = 'Delivered';
    private static final String UNDELIVERED = 'Undelivered';
    private static final String SETTING_NAME = 'PC_SMSReminder';
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
        //Create a Message record on Case and assign an account
        message = PC_Test_Setup.createMessage(programCase);
        message.PC_ReceiverAccount__c = patientAccount.Id;
        message = (PC_Message__c) PC_Database.ins(message, false);

        //Create Reminder Queue
        reminderQueue = PC_Test_Setup.createReminderQueues(programCase.Id,SETTING_NAME,1)[0];
        reminderQueue = (PC_ReminderQueue__c) PC_Database.ins(reminderQueue, false);

        //Create Reminder log
        reminderLog = PC_Test_Setup.createReminderLog(reminderQueue.Id);
        reminderLog.PC_SalesforceID__c = message.Id;
        reminderLog = (PC_ReminderLog__c) PC_Database.ins(reminderLog, false);
    }
    /**
     * This methods verifies if reminder log status changes on change of Message status
     */
    @isTest static void testReminderLogStatusSuccess() {
        User adminUser1 = [Select Id from User WHERE username = 'testAdminUser111@test.com'];
        Account smsPatient=[SELECT Id FROM Account WHERE PC_First_Name__c ='SMS Patient'];
        PC_Message__c messageToUpdate = [SELECT Id,PC_Message_Status__c FROM PC_Message__c WHERE PC_ReceiverAccount__c =: smsPatient.Id];
        System.runAs(adminUser1) {
            Test.StartTest();
            messageToUpdate.PC_Message_Status__c = DELIVERED;
            PC_Database.upd(messageToUpdate, false);
            Test.StopTest();
            PC_ReminderLog__c updatedLog = new PC_ReminderLog__c();
            updatedLog = [SELECT Id,PC_Status__c FROM PC_ReminderLog__c WHERE PC_SalesforceID__c =: messageToUpdate.Id LIMIT 1];
            System.assertEquals(true,updatedLog != null);
            System.assertEquals('SUCCESS',updatedLog.PC_Status__c);
        }
    }

    /**
     * This methods verifies if reminder log status changes on change of Message status
     */
    @isTest static void testReminderLogStatusFailed() {
        User adminUser1 = [Select Id from User WHERE username = 'testAdminUser111@test.com'];
        Account smsPatient=[SELECT Id FROM Account WHERE PC_First_Name__c ='SMS Patient'];
        PC_Message__c messageToUpdate = [SELECT Id,PC_Message_Status__c FROM PC_Message__c WHERE PC_ReceiverAccount__c =: smsPatient.Id];
        System.runAs(adminUser1) {
            Test.StartTest();
            messageToUpdate.PC_Message_Status__c = UNDELIVERED;
            PC_Database.upd(messageToUpdate, false);
            Test.StopTest();
            PC_ReminderLog__c updatedLog = new PC_ReminderLog__c();
            updatedLog = [SELECT Id,PC_Status__c FROM PC_ReminderLog__c WHERE PC_SalesforceID__c =: messageToUpdate.Id LIMIT 1];
            System.assertEquals(true,updatedLog != null);
            System.assertEquals('FAILED',updatedLog.PC_Status__c);
        }
    }
}