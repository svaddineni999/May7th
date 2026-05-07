/**
 * Created by sathekumar on 11/24/2020.
 */

@IsTest
private class PC_Test_PreviewEletter2 {

    //test data setup for all methods in this class
    @testSetup static void setupTestData() {
        // Create User Record
        User adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'eletteruser1@test.com', 'user1');
        PC_Database.ins(adminUser);

        system.runAs(adminUser) {
            // create an email template
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

        //Create eLetter
        PC_eLetter__c caseEletter = new PC_eLetter__c(
                Name = 'Patient Welcome Letter',
                PC_Object_Record_Types__c = 'Program',
                PC_Target_Recipients__c = 'HCO; Treating Physician',
                PC_Send_to_User__c = true,
                PC_Source_Object__c = 'Case',
                PC_Template_Name__c = 'Email_Template_Name'
        );
        PC_Database.ins(caseEletter);

        //Create Treating Physician
        Id physicianRecordTypeId = PC_System.recordTypeId(PC_Constants.PC_ACCOUNT, PC_Constants.PHYSICIAN_RECORD_TYPE);
        Account physician = new Account();
        physician.Name = 'Physician Name';
        physician.RecordTypeId = physicianRecordTypeId;
        physician.PC_Specialist_Type__c = 'Cardiologist';
        physician.Type = 'Specialist';
        physician.PC_Sub_Type__c = 'Other';
        physician.PC_Email__c = 'testphy@test.com';
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
        Case programCase = PC_Test_Setup.createCase(adminUser, patient);
        programCase.PC_Engagement_Program__c = engagementProgram.Id;
        programCase.PC_Physician__c = physician.Id;
        programCase.PC_Enrollment_Date__c = date.today().addDays(-10);
        programCase.PC_Treatment_Start_Date__c = date.today();
        programCase.IsEscalated = false;
        PC_Database.ins(programCase, false);

        // Create Engagement Program Eletter for Case
        PC_Engagement_Program_Eletter__c caseEngagementProgEletter = new PC_Engagement_Program_Eletter__c();
        caseEngagementProgEletter.PC_eLetter__c = caseEletter.Id;
        caseEngagementProgEletter.PC_Engagement_Program__c = engagementProgram.Id;
        PC_Database.ins(caseEngagementProgEletter);
    }

    @isTest static void testGetTemplatePreviewForRecipients() {
        String patientId;
        try {
            //grab the case that was created in the setupTestData method
            Id patientRecordTypeId = PC_System.recordTypeId(PC_Constants.PC_ACCOUNT, PC_Constants.PATIENT_RECORD_TYPE);
            Case programCase = [SELECT Id, AccountId FROM Case WHERE Account.RecordTypeId = :patientRecordTypeId LIMIT 1];
            // check if program Case is fetched
            system.assertNotEquals(programCase.Id, null);

            patientId = programCase.AccountId;

            //get the User1 record that was created in the setupTestData method
            User user1 = [select Id from User where Username = 'eletteruser1@test.com' LIMIT 1];
            system.debug('user1--->' + user1.Id);
            system.runAs(user1) {
                Test.StartTest();
                //Case
                PC_eLetter__c caseEletter = [Select Id, Name from PC_eLetter__c where Name = 'Patient Welcome Letter' LIMIT 1];
                system.assertNotEquals(caseEletter.Id, null);
                PC_eLetter2Controller.RenderedMailTemplate renderedMailTemplate = PC_PreviewEletter2.getTemplatePreviewForRecipients(caseEletter.Id, programCase.Id, patientId);
                system.assertNotEquals(renderedMailTemplate, null);
                Test.StopTest();
            }
        } catch (Exception ex) {
            system.debug('exception in testGetTemplatePreviewForRecipients >>' + ex.getMessage());
            system.assert(false, ex.getMessage());
        }
    }
}