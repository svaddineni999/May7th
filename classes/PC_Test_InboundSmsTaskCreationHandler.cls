/*********************************************************************************************************
Class Name      : PC_Test_InboundSmsTaskCreationHandler
Description     : Test class for PC_InboundSmsTaskCreationHandler
Created Date    : Oct 18, 2021
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer                Date                   Description
--------------------------------------------------------------------------------------------------------------
Chetna Mohapatra      Oct 18, 2021             Initial Version
***************************************************************************************************************/
@isTest
public class PC_Test_InboundSmsTaskCreationHandler {
    private static User adminUser;
    @testSetup static void setup() {
        // Create Admin User
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'testAdmin55@test.com', 'test55');
        PC_Database.ins(adminUser);

    }
    /**
    * Verifies if task is initiated on bulk insert of Inbound Message records, each having a sender account & program case
    */
    @isTest static void testBulkInboundSmsTaskCreation() {
        User test55 = [Select Id from User WHERE username = 'testAdmin55@test.com'];
        System.runAs(test55) {
            Test.StartTest();

            List<Account> patientAccounts = PC_Test_Setup.createAccounts('test', 200, PC_Constants.PATIENT_RECORD_TYPE);
            patientAccounts = (List<Account>) PC_Database.ins(patientAccounts, false);
            System.assertEquals(patientAccounts.size(), 200);

            List<Case> senderCases = PC_Test_Setup.createProgramCases(patientAccounts, 200);
            senderCases = (List<Case>) PC_Database.ins(senderCases, false);
            Set<Id> caseIds = (new Map<Id,SObject>(senderCases)).keySet();
            System.assertEquals(senderCases.size(), 200);

            List<PC_Message__c> inboundMessages = new List<PC_Message__c>();
            PC_Message__c inboundMessage = new PC_Message__c();
            for (Case senderCase : senderCases) {
                inboundMessage = PC_Test_Setup.createMessage(senderCase);
                inboundMessage.PC_Type__c = PC_Constants.INBOUND;
                inboundMessage.PC_SenderAccount__c = senderCase.AccountId;
                inboundMessages.add(inboundMessage);
            }
            if (!inboundMessages.isEmpty() && inboundMessages != null) {
                PC_Database.ins(inboundMessages, true);//bulk-insert
                System.assertEquals(inboundMessages.size(),200);
            }
            List<Task> messageTasks= new List<Task>([ SELECT Id FROM Task WHERE WhatId IN:caseIds]);
            System.assertEquals(messageTasks.size(),200);
            Test.StopTest();
        }
    }
}