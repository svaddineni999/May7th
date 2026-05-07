/*********************************************************************************************************
Class Name      : PC_Test_UpsertIntParticipantsHandler
Description     : Test class for PC_UpsertInteractionParticipantsHandler
Created Date    : Nov 18, 2021
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer            Date                Description
--------------------------------------------------------------------------------------------------------------
Haritha Reddy        Nov 18, 2021        [PC-8339] Initial Version
***************************************************************************************************************/
@isTest
public class PC_Test_UpsertIntParticipantsHandler {
    private static User adminUser,careCoordinator,reimbursementSpecialist;
    private static Account patient;
    private static Case programCase;
    private static PC_Interaction__c interactonRecord;

    @testSetup static void setup() {
        // Create Admin User
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'testAdminUser1@test.com', 'test1');
        PC_Database.ins(adminUser);

        //Create Care Coordinator
        careCoordinator = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'testCCUser2@test.com', 'test2');
        careCoordinator = (User) PC_Database.ins(careCoordinator);

        //Create Care Coordinator
        reimbursementSpecialist = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'testRSUser3@test.com', 'test3');
        reimbursementSpecialist = (User) PC_Database.ins(reimbursementSpecialist);

        patient = PC_Test_Setup.createSampleAccount('', PC_Constants.PATIENT_RECORD_TYPE);
        patient.PC_Date_of_Birth__c = date.today().addDays(-100);
        patient = (Account)PC_Database.ins(patient, false);
        system.assertNotEquals(patient.Id, null);

        programCase = PC_Test_Setup.createCase(adminUser, patient);
        programCase.PC_Care_Coordinator__c = careCoordinator.Id;
        programCase.PC_Reimbursment_Specialist__c = reimbursementSpecialist.Id;
        programCase = (Case)PC_Database.ins(programCase, false);
        system.assertNotEquals(programCase.Id, null);

        interactonRecord = new PC_Interaction__c();
        interactonRecord.PC_Patient_Program__c = programCase.Id;
        interactonRecord.PC_Participants__c = 'HCO; Care Coordinator';
        interactonRecord.PC_Status__c = 'Requested';
        PC_Database.ins(interactonRecord, false);

    }

    @isTest static void testParticipantCreation() {
        User adminUser1 = [Select Id from User WHERE username = 'testAdminUser1@test.com'];
        User ccUser = [Select Id from User WHERE username = 'testCCUser2@test.com'];
        Case caseRecord = [Select Id from Case  LIMIT 1];
        PC_Association__c association = [Select Id from PC_Association__c
        where PC_Program__c =: caseRecord.id  AND PC_Associated_User__c =: ccUser.id LIMIT 1];

        System.runAs(adminUser1) {
            Test.StartTest();

            PC_Interaction__c interaction = new PC_Interaction__c();
            interaction.PC_Patient_Program__c = caseRecord.Id;
            interaction.PC_Participants__c = 'HCO; Care Coordinator';
            interaction.PC_Status__c = 'Requested';
            interaction = (PC_Interaction__c)PC_Database.ins(interaction, false);

            Test.stopTest();

            List<PC_InteractionParticipant__c> interactionParticipants = new List<PC_InteractionParticipant__c>();
            interactionParticipants = [Select Id,PC_Association__c FROM PC_InteractionParticipant__c WHERE PC_Interaction__c =: interaction.Id];
            System.assertEquals(interactionParticipants.size(), 1);
            System.assertEquals(interactionParticipants[0].PC_Association__c, association.Id);

        }
    }


    @isTest static void testParticipantUpdate() {
        User adminUser1 = [Select Id from User WHERE username = 'testAdminUser1@test.com'];
        User rsUser = [Select Id from User WHERE username = 'testRSUser3@test.com'];
        PC_Interaction__c interaction = [Select Id,PC_Participants__c from PC_Interaction__c  LIMIT 1];
        Case caseRecord = [Select Id from Case  LIMIT 1];
        PC_Association__c association = [Select Id from PC_Association__c
        where PC_Program__c =: caseRecord.id AND PC_Associated_User__c =: rsUser.Id LIMIT 1];

        System.runAs(adminUser1) {
            Test.StartTest();

            interaction.PC_Participants__c = 'HCO; Reimbursement Specialist';
            PC_Database.upd(interaction, false);

            Test.stopTest();

            List<PC_InteractionParticipant__c> interactionParticipants = new List<PC_InteractionParticipant__c>();
            interactionParticipants = [Select Id,PC_Association__c FROM PC_InteractionParticipant__c
            WHERE PC_Interaction__c =: interaction.Id AND PC_Association__r.PC_Associated_User__c =: rsUser.Id];
            System.assertEquals(interactionParticipants.size(), 1);
            System.assertEquals(interactionParticipants[0].PC_Association__c, association.Id);
        }
    }
}