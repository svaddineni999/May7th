/**
* Created by havalakki on 6/9/2021.
* Modification Log:
* ----------------------------------------------------------------------------------
* Developer              Date                   	Description
* -----------------------------------------------------------------------------------
* Hitha Avalakki		 09-June-2021			Initial Version
*/

@IsTest
public with sharing class PC_Test_SurveyWorkflowController {
    private static User adminUser;
    public static final String engagementProgram = 'PRP';

    @isTest
    static void testAccountCaseRecordDetails() {
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test100');
        PC_Database.ins(adminUser);
        System.runAs(adminUser) {
            Test.StartTest();

            //Account
            Account  patient = PC_Test_Setup.createPatient('testpatient');
            patient = (Account)PC_Database.ins(patient, false);
            // patient is created
            system.assertNotEquals(patient.Id, null);

            //Manufacturer
            List<Account>  manufacturers = PC_Test_Setup.createAccounts('testmanufacturer', 1, PC_Constants.MANUFACTURER_RECORD_TYPE);
            Account manufacturer = (Account)PC_Database.ins(manufacturers[0], false);
            // manufacturer is created
            system.assertNotEquals(manufacturer.Id, null);

            //Engagement Program
            PC_Engagement_Program__c  engagement = PC_Test_Setup.createEngagementProgram(engagementProgram, manufacturer.Id);
            engagement = (PC_Engagement_Program__c)PC_Database.ins(engagement, false);
            // engagement is created
            system.assertNotEquals(engagement.Id, null);

            //Program
            Case programCase = PC_Test_Setup.newCase(patient.Id , PC_Constants.CASE_PROGRAM_RECORD_TYPE);
            programCase.PC_Engagement_Program__c = engagement.Id;
            programCase = (Case)PC_Database.ins(programCase, false);
            // Program Case is created
            system.assertNotEquals(programCase.Id, null);

            PC_SurveyWorkflowController.SobjectDataWrapper wrapperData= PC_SurveyWorkflowController.getAccountCaseRecordDetails(patient.Id,'','');
            System.assert(wrapperData.casesList.size()>=0);
            System.assert(wrapperData.accountsList.size()>=0);

            Test.stopTest();
        }
    }
}