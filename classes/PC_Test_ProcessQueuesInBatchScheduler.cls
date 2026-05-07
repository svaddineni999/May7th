/*********************************************************************************************************
Class Name      : PC_Test_ProcessQueuesInBatchScheduler
Description     : Test class for PC_ProcessQueuesInBatchScheduler class.
Created By      : Deloitte
Created Date    : June 21, 2021
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer          Log#         Date                   Description
--------------------------------------------------------------------------------------------------------------
Kanteti Kishore               June 21, 2021          Initial Version
Kanteti Kishore               Oct  15, 2021          [PC-8183] Modified code to support SMS reminder functionality using eLetters
***********************************************************************************************************/

@IsTest
public class PC_Test_ProcessQueuesInBatchScheduler{
    private static final String EMAIL_SETTING_NAME = 'PC_AppointmentEmailReminder';
    private static final String SMS_SETTING_NAME = 'PC_SMSReminder';

    @testSetup static void setup(){
        //Create Treating Physician
        Id physicianRecordTypeId = PC_System.recordTypeId(PC_Constants.PC_ACCOUNT, PC_Constants.PHYSICIAN_RECORD_TYPE);
        Account physician = new Account();
        physician.Name = 'Physician Name';
        physician.RecordTypeId = physicianRecordTypeId;
        physician.PC_Specialist_Type__c = 'Cardiologist';
        physician.Type = 'Specialist';
        physician.PC_Sub_Type__c = 'Other';
        physician.PC_Email__c = 'testphy@test.com';
        physician.Phone='34567863456';
        PC_Database.ins(physician, false);

        //Create Manufacturer
        Account manufacturerAcc = PC_Test_Setup.createTestAccount(PC_Constants.MANUFACTURER_RECORD_TYPE);
        PC_Database.ins(manufacturerAcc, false);

        //Create engagement Program
        PC_Engagement_Program__c engagementProgram = PC_Test_Setup.createEngagementProgram('ProgramA', manufacturerAcc.Id);
        PC_Database.ins(engagementProgram, false);

        //Create Patient Account
        Id patientRecordTypeId = PC_System.recordTypeId(PC_Constants.PC_ACCOUNT, PC_Constants.PATIENT_RECORD_TYPE);
        Account patient = new Account(Name = 'Patient1', RecordTypeId = patientRecordTypeId);
        PC_Database.ins(patient, false);

        //Create Program Case
        Case programCase = PC_Test_Setup.createProgram(patient);

        //Create Manufacturer
        List<Account>  manufacturers = PC_Test_Setup.createAccounts('testmanufacturer', 1, PC_Constants.MANUFACTURER_RECORD_TYPE);
        Account manufacturer = new Account();
        manufacturer = (Account)PC_Database.ins(manufacturers[0], false);

        //Create Engagement Program
        PC_Engagement_Program__c enmtProgram= PC_Test_Setup.createEngagementProgram('TestPgm',manufacturer.Id );
        enmtProgram.PC_Program_Code__c = 'TestPgm';
        enmtProgram = (PC_Engagement_Program__c) PC_Database.ins(enmtProgram, false);

        //Create Care Coordinator
        User careCoordinator = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@t2.com', 'test2');
        careCoordinator.Phone = '93457543223';
        careCoordinator = (User) PC_Database.ins(careCoordinator);

        //Create Case
        Case caseOne = PC_Test_Setup.createCase(careCoordinator,patient);
        caseOne.PC_Engagement_Program__c= enmtProgram.Id;
        caseOne.PC_Care_Coordinator__c      =   careCoordinator.Id;
        caseOne.PC_Physician__c             =   physician.Id;
        caseOne = (Case) PC_Database.ins(caseOne, false);

        //Create eLetter
        PC_eLetter__c eletter = PC_Test_Setup.createEletter();
        eLetter.Name = 'Sample eLetter';
        eLetter.PC_Target_Recipients__c = 'Care Coordinator; Treating Physician';
        eLetter.PC_Send_to_User__c= false;
        eletter = (PC_eLetter__c) PC_Database.ins(eletter);

        User objUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@t1234.com', 'test1');
        PC_Database.ins(objUser);

        //Create Email Template
        system.runAs(objUser) {
            EmailTemplate emailTemplate = new EmailTemplate (
                    developerName = 'Email_Template_Name',
                    FolderId = UserInfo.getUserId(),
                    TemplateType = 'Text',
                    Name = 'Email Template Name',
                    Body = 'This is an Email Body',
                    IsActive = TRUE
            );
            PC_Database.ins(emailTemplate);
        }

        // Create Engagement Program Eletter for Case
        PC_Engagement_Program_Eletter__c caseEngagementProgramEletter = new PC_Engagement_Program_Eletter__c();
        caseEngagementProgramEletter.PC_eLetter__c = eLetter.Id;
        caseEngagementProgramEletter.PC_Engagement_Program__c = enmtProgram.Id;
        PC_Database.ins(caseEngagementProgramEletter,false);

        //Create Interaction
        PC_Interaction__c interaction = PC_Test_Setup.newInteraction(programCase.Id);
        interaction = (PC_Interaction__c) PC_Database.ins(interaction,false);

        //Create Email Related Reminder Queues
        List<PC_ReminderQueue__c> reminderQueues = PC_Test_Setup.createReminderQueues(interaction.Id,EMAIL_SETTING_NAME,10);
        //Expired Reminder Queue
        reminderQueues[4].PC_DueDate__c = System.today().addDays(-4);
        //Minimum Interval Not Met
        reminderQueues[5].PC_LastSuccessfulReminderSent__c = System.now();
        //No handler for the channel
        reminderQueues[6].PC_ReminderChannel__c = 'Fax';

        //Create SMS Related Reminder Queues
        List<PC_ReminderQueue__c> smsReminderQueues = PC_Test_Setup.createReminderQueues(caseOne.Id,SMS_SETTING_NAME,2);
        for(PC_ReminderQueue__c queue :  smsReminderQueues){
            queue.PC_ReminderChannel__c = 'SMS';
        }
        //Creating Care Coordinator Recipient
        PC_ReminderQueue.RecipientDetail careCoordinatorRecipient = new PC_ReminderQueue.RecipientDetail();
        careCoordinatorRecipient.id = careCoordinator.Id;
        careCoordinatorRecipient.name = careCoordinator.Name;
        careCoordinatorRecipient.address = careCoordinator.Phone;
        careCoordinatorRecipient.type = 'User';
        smsReminderQueues[0].PC_Recipient__c = JSON.serialize(careCoordinatorRecipient);

        //Creating Physician Recipient
        PC_ReminderQueue.RecipientDetail physicianRecipient = new PC_ReminderQueue.RecipientDetail();
        physicianRecipient.id = physician.Id;
        physicianRecipient.name = physician.Name;
        physicianRecipient.address = physician.Phone;
        physicianRecipient.type = 'Account';
        smsReminderQueues[1].PC_Recipient__c = JSON.serialize(physicianRecipient);

        reminderQueues.addAll(smsReminderQueues);
        reminderQueues = (List<PC_ReminderQueue__c>) PC_Database.ins(reminderQueues, false);
    }
    @isTest static void testProcessQueuesBatch() {
        //Create admin User
        User adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test100');
        adminUser = (User) PC_Database.ins(adminUser);

        System.runAs(adminUser) {
            Test.StartTest();
            SchedulableContext sc = null;
            PC_ProcessQueuesInBatchScheduler queuesInBatchScheduler = new PC_ProcessQueuesInBatchScheduler();
            queuesInBatchScheduler.execute(sc);
            Test.StopTest();
        }
    }
    @isTest static void testProcessQueuesBatchFailedScenario() {
        //Create admin User
        User adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test100');
        adminUser = (User) PC_Database.ins(adminUser);
        List<PC_ReminderQueue__c> createdQueues = [SELECT Id, PC_Recipient__c, PC_ReminderSetting__c FROM PC_ReminderQueue__c];
        createdQueues[7].PC_RecordID__c = '12345';
        PC_Database.upd(createdQueues,false);
        System.runAs(adminUser) {
            Test.StartTest();
            SchedulableContext sc = null;
            PC_ProcessQueuesInBatchScheduler queuesInBatchScheduler = new PC_ProcessQueuesInBatchScheduler();
            queuesInBatchScheduler.execute(sc);
            Test.StopTest();
        }
    }
    @isTest static void testReminderLogTrigger() {
        //Create admin User
        User adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test100');
        adminUser = (User) PC_Database.ins(adminUser);
        PC_ReminderQueue__c reminderQueue = [SELECT Id FROM PC_ReminderQueue__c LIMIT 1];
        System.runAs(adminUser) {
            Test.StartTest();
            PC_ReminderLog__c reminderLog = new PC_ReminderLog__c();
            reminderLog.PC_ReminderQueue__c = reminderQueue.Id;
            reminderLog.PC_Status__c = PC_Constants.SUCCESS;
            reminderLog.PC_StatusDetails__c = PC_Constants.SUCCESS;
            PC_Database.ins(reminderLog);
            PC_ReminderLog__c insertedLog = new PC_ReminderLog__c();
            insertedLog = [SELECT Id,PC_Status__c,PC_StatusDetails__c FROM PC_ReminderLog__c LIMIT 1];
            insertedLog.PC_StatusDetails__c +=  PC_Constants.SUCCESS;
            PC_Database.upd(insertedLog,false);
            Test.StopTest();
        }
    }
}