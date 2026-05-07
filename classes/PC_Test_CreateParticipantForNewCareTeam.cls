/*********************************************************************************************************
Class Name      : PC_Test_CreateParticipantForNewCareTeam
Description     : Test class for PC_CreateParticipantForNewCareTeamMember
Created Date    : Nov 20, 2021
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer            Date                Description
--------------------------------------------------------------------------------------------------------------
Haritha Reddy        Nov 20, 2021        [PC-8312] Initial Version
***************************************************************************************************************/
@isTest
public class PC_Test_CreateParticipantForNewCareTeam {
    private static User adminUser,careCoordinator1,careCoordinator2;
    private static Account patient;
    private static Case programCase;
    private static PC_Interaction__c interactonRecord;

    @testSetup static void setup() {
        // Create Admin User
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'testAdminUser1@test.com', 'test1');
        PC_Database.ins(adminUser);

        //Create Care Coordinator
        careCoordinator1 = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'testCCUser2@test.com', 'test2');
        careCoordinator1 = (User) PC_Database.ins(careCoordinator1);

        //Create Care Coordinator
        careCoordinator2 = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'testCCUser3@test.com', 'test3');
        careCoordinator2 = (User) PC_Database.ins(careCoordinator2);

        patient = PC_Test_Setup.createSampleAccount('', PC_Constants.PATIENT_RECORD_TYPE);
        patient.PC_Date_of_Birth__c = date.today().addDays(-100);
        patient = (Account)PC_Database.ins(patient, false);
        system.assertNotEquals(patient.Id, null);

        programCase = PC_Test_Setup.createCase(adminUser, patient);
        programCase.PC_Care_Coordinator__c = careCoordinator1.Id;
        programCase = (Case)PC_Database.ins(programCase, false);
        system.assertNotEquals(programCase.Id, null);
    }

    @isTest static void testParticipantCreation() {
        User adminUser1 = [Select Id from User WHERE username = 'testAdminUser1@test.com'];
        User ccUser1 = [Select Id from User WHERE username = 'testCCUser2@test.com'];
        User ccUser2 = [Select Id from User WHERE username = 'testCCUser3@test.com'];
        Case caseRecord = [Select Id from Case  LIMIT 1];

        System.runAs(adminUser1) {

            Test.StartTest();

            interactonRecord = new PC_Interaction__c();
            interactonRecord.PC_Patient_Program__c = caseRecord.Id;
            interactonRecord.PC_Participants__c = 'HCO; Care Coordinator';
            interactonRecord.PC_Status__c = 'Requested';
            interactonRecord = (PC_Interaction__c)PC_Database.ins(interactonRecord, false);

            caseRecord.PC_Care_Coordinator__c = ccUser2.Id;
            caseRecord = (Case)PC_Database.upd(caseRecord, false);

            Test.stopTest();

            List<PC_InteractionParticipant__c> interactionParticipants = new List<PC_InteractionParticipant__c>();
            PC_Association__c association = [Select Id from PC_Association__c
                                            where PC_Program__c =: caseRecord.id  AND PC_Associated_User__c =: ccUser2.id LIMIT 1];

            interactionParticipants = [Select Id,PC_Association__c FROM PC_InteractionParticipant__c WHERE PC_Association__c =: association.Id];
            System.assertEquals(interactionParticipants.size(), 1);
            System.assertEquals(interactionParticipants[0].PC_Association__c, association.Id);

        }
    }
}