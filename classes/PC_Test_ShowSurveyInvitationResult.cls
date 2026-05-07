/**
 * Created by vkashikar on 7/8/2021.
 */

@isTest
private class PC_Test_ShowSurveyInvitationResult {
    private static User adminUser;
    private static Account manufacturerAccount;
    private static List<Account> patientAccounts;
    private static PC_Engagement_Program__c engagementProgram;
    private static List<Case> programCases;
    private static List<Case> papCases;
    private static PC_SurveyInvitationRelatedObjects__c surveyInvitationRelatedObject;

    @isTest(SeeAllData=true)
    static void testAll() {
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test100');
        PC_Database.ins(adminUser);
        system.runAs(adminUser) {
            manufacturerAccount = PC_Test_Setup.createAccount('Test', PC_System.recordTypeId('Account', PC_Constants.MANUFACTURER_RECORD_TYPE));
            PC_Database.ins(manufacturerAccount);

            patientAccounts = PC_Test_Setup.createAccounts('patient', 1, PC_Constants.PATIENT_RECORD_TYPE);
            PC_Database.ins(patientAccounts);

            engagementProgram = PC_Test_Setup.createEngagementProgram('675464', manufacturerAccount.Id);
            PC_Database.ins(engagementProgram);

            programCases = PC_Test_Setup.createProgramCases(patientAccounts, 1);
            for (Case c : programCases) {
                c.PC_Engagement_Program__c = engagementProgram.Id;
            }
            PC_Database.ins(programCases);

            papCases = PC_Test_Setup.createCases(patientAccounts, 1, PC_Constants.PAP_RECORD_TYPE);
            for (Case c : programCases) {
                c.ParentId = programCases[0].Id;
                //Test.setCreatedDate(c.Id, System.now());
            }
            PC_Database.ins(papCases);

            PC_EmbedSurveyController embedSurveyController = new PC_EmbedSurveyController();
            String surveyName = PC_SYSTEM.getSettingByEngagementProgram(engagementProgram.PC_Program_Code__c, PC_Constants.PATIENT_CONNECT_SETTING_PAP_SURVEY, PC_Constants.SETTINGS_TYPE.PATIENT_CONNECT_SETTING, PC_Constants.DEFAULT_PAP_SURVEY);

            system.debug('surveyName=' + surveyName);
            String surveyInvitationLink = PC_EmbedSurveyController.generateSurveyLink(String.valueOf(programCases[0].Id), String.valueOf(engagementProgram.Id), 'PC_PAP');
            SurveyInvitation surveyInvitation = [SELECT InvitationLink FROM SurveyInvitation ORDER BY CreatedDate DESC LIMIT 1];
            system.debug('surveyInvitationLink' + surveyInvitationLink);
            system.assert(surveyInvitationLink.compareTo(surveyInvitation.InvitationLink) == 0);
            // If we were allowed to update the invitation case like below, then we would not have been compelled to
            // create PAP cases. Hence, now, we will manually insert records into Survey Invitation Related Records objects
            //surveyInvitation.ResponseStatus = 'Completed';
            //PC_Database.upd(surveyInvitation);
            surveyInvitationRelatedObject = new PC_SurveyInvitationRelatedObjects__c();
            surveyInvitationRelatedObject.PC_SurveyInvitation__c = surveyInvitation.Id;
            surveyInvitationRelatedObject.PC_SurveyCategory__c = 'PC_PAP';
            PC_Database.ins(surveyInvitationRelatedObject);

            testPositive_WithoutAccountId(engagementProgram.Id, programCases[0].Id, 'PC_PAP');
            testNegative_WithoutContext( engagementProgram.Id, patientAccounts[0].Id, programCases[0].Id);


            surveyInvitationRelatedObject.PC_ResultingCase__c = papCases[0].Id;
            surveyInvitationRelatedObject.PC_Account__c = patientAccounts[0].Id;
            surveyInvitationRelatedObject.PC_Case__c = programCases[0].Id;

            PC_Database.upd(surveyInvitationRelatedObject);

            testPositive_WithAllValues(engagementProgram.Id, patientAccounts[0].Id, programCases[0].Id, 'PC_PAP');


            //PC_ShowSurveyInvitationResult.SurveyInvitationResult surveyInvitationResult = PC_ShowSurveyInvitationResult.getInvitationResult(engagementProgram.Id, patientAccounts[0].Id, programCases[0].Id, 'PC_PAP');
            system.debug('****');
            //system.debug(papCases[0].CreatedDate.format());
            //system.debug(surveyInvitationResult);
            //PC_ShowSurveyInvitationResult.Row row = new PC_ShowSurveyInvitationResult.Row(surveyInvitationRelatedObject);
            //system.assert(row.resultCaseNumber != null);
            try {
                PC_ShowSurveyInvitationResult.Row row = new PC_ShowSurveyInvitationResult.Row(surveyInvitationRelatedObject);
                system.assert(false);
            }
            catch(NullPointerException nullPointerException) {
                system.assert(true); // expected
            }
            catch(Exception ex) {
                system.assert(false);
            }
        }
    }
    private static void testPositive_WithAllValues(String engagementProgramId, String accountId, String caseId, String workflowContext) {
        try {
            PC_ShowSurveyInvitationResult.SurveyInvitationResult surveyInvitationResult =
                    PC_ShowSurveyInvitationResult.getInvitationResult(engagementProgramId, accountId, caseId, 'PC_PAP');
            system.assert(true);
        }
        catch (Exception ex) {
            system.assert(false);
        }
    }

    private static void testPositive_WithoutAccountId(String engagementProgramId, String caseId, String workflowContext) {
        try {
            PC_ShowSurveyInvitationResult.SurveyInvitationResult surveyInvitationResult =
                    PC_ShowSurveyInvitationResult.getInvitationResult(engagementProgramId, NULL, caseId, 'PC_PAP');
            system.assert(true);
        }
        catch (Exception ex) {
            system.assert(false);
        }
    }
    private static void testNegative_WithoutContext(String engagementProgramId, String accountId, String caseId) {
        try {
            PC_ShowSurveyInvitationResult.SurveyInvitationResult surveyInvitationResult =
                    PC_ShowSurveyInvitationResult.getInvitationResult(engagementProgramId, accountId, caseId, NULL);
            system.assert(false);
        }
        catch (Exception ex) {
            system.assert(true); // Expected
        }
    }
}