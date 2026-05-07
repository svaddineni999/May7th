/*********************************************************************************************************
Class Name      : PC_Test_SetMessageReadValueHandler
Description     : Test class for PC_SetMessageReadValueHandler
Created Date    : Oct 25, 2021
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer                Date                   Description
--------------------------------------------------------------------------------------------------------------
Chetna Mohapatra      Oct 25, 2021             Initial Version
***************************************************************************************************************/
@isTest
public class PC_Test_SetMessageReadValueHandler {
    private static User adminUser;
    @testSetup static void setup() {
        // Create Admin User
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'testAdmin57@test.com', 'test57');
        PC_Database.ins(adminUser);

    }
    /**
    * Verifies if the Message Read value is checked for Outbound Message records post the status gets updated to Delivered.
    */
    @isTest static void testBulkMessageReadValueAssignment() {
        User test57 = [Select Id from User WHERE username = 'testAdmin57@test.com'];
        System.runAs(test57) {
            Test.StartTest();

            List<Account> patientAccounts = PC_Test_Setup.createAccounts('test', 200, PC_Constants.PATIENT_RECORD_TYPE);
            patientAccounts = (List<Account>) PC_Database.ins(patientAccounts, false);
            System.assertEquals(patientAccounts.size(), 200);

            List<Case> messageCases = PC_Test_Setup.createProgramCases(patientAccounts, 200);
            messageCases = (List<Case>) PC_Database.ins(messageCases, false);
            Set<Id> caseIds = (new Map<Id,SObject>(messageCases)).keySet();
            System.assertEquals(messageCases.size(), 200);

            List<PC_Message__c> Messages = new List<PC_Message__c>();
            PC_Message__c msg = new PC_Message__c();
            for (Case messageCase : messageCases) {
                //Create a Outbound message record on Case and assign a status other than Delivered.
                msg = PC_Test_Setup.createMessage(messageCase);
                msg.PC_Type__c = PC_Constants.OUTBOUND;
                msg.PC_FromAlias__c= '48484848';
                msg.PC_Message_Status__c= 'Draft';
                Messages.add(msg);
            }
            if (!Messages.isEmpty() && Messages != null) {
                PC_Database.ins(Messages, true);//bulk-insert
                System.assertEquals(Messages.size(),200);
            }
           List<PC_Message__c> toUpdateMessages= new List<PC_Message__c>();
            for( PC_Message__c eachMessage : Messages){
                eachMessage.PC_Message_Status__c='Delivered';
                toUpdateMessages.add(eachMessage);
            }
            PC_Database.upd(toUpdateMessages, true);//bulk-update
            Set<Id> updatedMessageIds = (new Map<Id,SObject>(toUpdateMessages)).keySet();
            List<PC_Message__c> updatedMessages= new List<PC_Message__c>(
                 [SELECT Id, PC_Message_Status__c,PC_Message_Read__c FROM PC_Message__c WHERE Id IN: updatedMessageIds ]
            );
            for(PC_Message__c updatedMessage: updatedMessages){
                System.assertEquals(updatedMessage.PC_Message_Read__c, true);
            }
            Test.StopTest();
        }
    }
}