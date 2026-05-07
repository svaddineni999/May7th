/**
* Created by havalakki on 6/9/2021.
* Modification Log:
* ----------------------------------------------------------------------------------
* Developer              Date                   	Description
* -----------------------------------------------------------------------------------
* Hitha Avalakki		 09-June-2021			Initial Version
*/

@IsTest
public with sharing class PC_Test_SurveyEligibilityCheckController {
    private static User adminUser;
    public static final String engagementProgram = 'PRP';
    public static Account  patient;
    public static List<Account>  manufacturers;
    public static PC_Engagement_Program__c  engagement;
    public static Case programCase;

    private static void createTestData() {
        //Account
        patient = PC_Test_Setup.createPatient('testpatient');
        patient = (Account)PC_Database.ins(patient, false);
        // patient is created
        system.assertNotEquals(patient.Id, null);

        //Manufacturer
        manufacturers = PC_Test_Setup.createAccounts('testmanufacturer', 1, PC_Constants.MANUFACTURER_RECORD_TYPE);
        Account manufacturer = (Account)PC_Database.ins(manufacturers[0], false);
        // manufacturer is created
        system.assertNotEquals(manufacturer.Id, null);

        //Engagement Program
        engagement = PC_Test_Setup.createEngagementProgram(engagementProgram, manufacturer.Id);
        engagement = (PC_Engagement_Program__c)PC_Database.ins(engagement, false);
        // engagement is created
        system.assertNotEquals(engagement.Id, null);

        //Program
        programCase = PC_Test_Setup.newCase(patient.Id , PC_Constants.CASE_PROGRAM_RECORD_TYPE);
        programCase.PC_Engagement_Program__c = engagement.Id;
        programCase = (Case)PC_Database.ins(programCase, false);
        // Program Case is created
        system.assertNotEquals(programCase.Id, null);

    }

    @isTest
    static void testIsAccountRecordId() {
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test100');
        PC_Database.ins(adminUser);
        createTestData();

        System.runAs(adminUser) {
            Test.StartTest();
            PC_SurveyWorkflowHelper.AccountCaseEngProgramWrapper wrapperData= PC_SurveyEligibilityCheckController.getAccountCaseDetails(patient.Id,'PC_PAP');
            System.assertEquals(wrapperData.accountId,patient.Id);
            wrapperData= PC_SurveyEligibilityCheckController.getAccountCaseDetails(programCase.Id,'PC_Copay');
            System.assertEquals(wrapperData.engagementProgramId,engagement.Id);
            Test.stopTest();
        }
    }

    @isTest
    static void testIsAccountRecordIdException() {
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test100');
        PC_Database.ins(adminUser);

        System.runAs(adminUser) {
            Test.StartTest();
            try {
                PC_SurveyWorkflowHelper.AccountCaseEngProgramWrapper wrapperData= PC_SurveyEligibilityCheckController.getAccountCaseDetails('undefined','PC_PAP');
            }
            catch (Exception ex) {
                system.assert(true);
            }
            Test.stopTest();
        }
    }

}