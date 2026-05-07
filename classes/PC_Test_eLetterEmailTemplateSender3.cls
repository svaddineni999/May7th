/*********************************************************************************
Class Name      : PC_Test_eLetterEmailTemplateSender3
Description     :
Created By      : Satheesh Kumar
Created Date    : 02 Dec,2020
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------
Satheesh Kumar           02 Dec,2020              Initial Version
*********************************************************************************/

@isTest
private class PC_Test_eLetterEmailTemplateSender3 {
    
    private static User adminUser;
    private static Account physicianAcc;
    private static Contact physicianCon;
    private static Account patientAcc;
    private static User careCoordinator;
    private static Case programCase;
    private static EmailTemplate emailTemplate;
    private static PC_eLetter__c eletter;
    private static PC_eLetter__c eletter2;
    private static PC_System_Settings__c cSetting;
    private static List<PC_eLetter.RecipientWrapper> recipients;
    private static List<String> attachmentIds;
    
    private static void createTestData() {
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'userpctest@test2.com', 'test2');
        PC_Database.ins(adminUser);
        system.runAs(adminUser) {
            //Create Care Coordinator
            careCoordinator = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@t2.com', 'test2');
            careCoordinator = (User) PC_Database.ins(careCoordinator);

            physicianAcc = PC_Test_Setup.newAccount (null, 'Account Name', 'phyician', 'lastName', PC_Constants.PHYSICIAN_RECORD_TYPE);
            physicianAcc.PC_Email__c = 'test@test.com';
            // check if physician is created
            PC_Database.ins(physicianAcc);
            system.assertNotEquals(physicianAcc.Id, null);
            
            physicianCon = [SELECT Id, Email FROM Contact WHERE AccountId = :physicianAcc.Id];
            system.assertNotEquals(physicianCon.Id, null);
            // set physician contact email address
            physicianCon.Email = 'test@test.com';
            PC_Database.upd(physicianCon);
            
            physicianAcc.HealthCloudGA__PrimaryContact__c = physicianCon.Id;
            physicianAcc.HealthCloudGA__PrimaryContact__r = physicianCon;
            PC_Database.upd(physicianAcc);
            system.assertEquals (physicianCon.Email, 'test@test.com');
            
            patientAcc = PC_Test_Setup.newAccount (null, 'Account Name', 'patient', 'lastName', PC_Constants.PATIENT_RECORD_TYPE);
            PC_Database.ins(patientAcc);
            // check if patient is created
            system.assertNotEquals(patientAcc.Id, null);
            
            programCase = PC_Test_Setup.newCase(null, patientAcc.Id, PC_Constants.CASE_PROGRAM_RECORD_TYPE);
            PC_Database.ins(programCase);
            // check of program case is created
            system.assertNotEquals(programCase.Id, null);
            
            PC_Association__c aAssociation = PC_Test_Setup.createAssociation(physicianAcc, programCase, 'Treating Physician', system.today(), null);
            // create association between patient and physician
            system.assertNotEquals(aAssociation.Id, null);
            
            // create an email template
            emailTemplate = new EmailTemplate (
                developerName = 'Email_Template_Name',
                FolderId = UserInfo.getUserId(),
                TemplateType = 'Text',
                Name = 'Email Template Name',
                Body = 'This is an Email Body',
                IsActive = TRUE
            );
            PC_Database.ins(emailTemplate);
            // check if email template has been created
            system.assertNotEquals(aAssociation.Id, null);
            // create eltter
            eletter = new PC_eLetter__c (
                Name = 'Test 1',
                PC_Target_Recipients__c = 'HCO; Treating Physician',
                PC_Communication_Language__c = 'English',
                PC_Send_to_User__c = false,
                PC_Source_Object__c = 'Case',
                PC_Template_Name__c = 'Email_Template_Name'
            );
            PC_Database.ins(eletter);
            // check if eletter has been created
            system.assertNotEquals(eletter.Id, null);
            
            // create eletter2
            eletter2 = new PC_eLetter__c (
                Name = 'Test 1',
                PC_Target_Recipients__c = 'HCO; Treating Physician',
                PC_Communication_Language__c = 'English',
                PC_Send_to_User__c = true,
                PC_Source_Object__c = 'Case',
                PC_Template_Name__c = 'Email_Template_Name'
            );
            PC_Database.ins(eletter2);
            // check if eletter has been created
            system.assertNotEquals(eletter2.Id, null);
            
            // create a record for the custom setting
            cSetting = new PC_System_Settings__c();
            cSetting.PC_eLetter_Sender_Class__c = 'PC_eLetterEmailTemplateSender3';
            PC_Database.ins(cSetting);
            // instantiate PC_eletterService sendLetter method
            recipients = new List<PC_eLetter.RecipientWrapper>();
            recipients.add(new PC_eLetter.RecipientWrapper(physicianAcc));
            recipients.add(new PC_eLetter.RecipientWrapper(careCoordinator));
            PC_eLetter.RecipientWrapper preConfiguredUser = new PC_eLetter.RecipientWrapper();
            preConfiguredUser.Id = null;
            preConfiguredUser.communicationLanguage = '';
            preConfiguredUser.type = PC_eLetter.RecipientType.PRE_CONFIGURED_EMAIL.name();
            preConfiguredUser.fax = '9878767898';
            preConfiguredUser.email = 'test2@test.com';
            preConfiguredUser.name = 'testUser3';
            recipients.add(preConfiguredUser);

            //Create attachment for email
            Attachment attachment = PC_Test_Setup.createAttachment(programCase.Id); // Adding one attachment to email
            PC_Database.ins(attachment);
            //check if attachment is created
            system.assertNotEquals(attachment.Id, null);
            
            attachmentIds = new List<String>();
            attachmentIds.add(attachment.Id);
            
            ContentDocument contentDocument = PC_Test_Setup.createFile(programCase.Id); // Adding one file to email
            system.assertNotEquals(ContentDocument.Id, null);
            String contentVersionId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE ContentDocumentId = :ContentDocument.Id].Id;
            attachmentIds.add(contentVersionId);
        }
    }
    
    /*********************************************************************************
    Method Name    : testSendEletter
    Author         : Satheesh Kumar
    Description    : This method is used for testing "SendLetter"
    Return Type    : void
    *********************************************************************************/
    @isTest static void testSendEletter() {
        try {
            createTestData();
            Test.startTest();
            system.runAs(adminUser) {
                String subject = 'Custom Subject';
                Boolean isEmailSecure = PC_Constants.TRUE_BOOLEAN;
                PC_eLetter2Controller.SendLetterRequest eLetterRequest = new PC_eLetter2Controller.SendLetterRequest();
                PC_eLetter2Controller.FromAddress fromAddress = new PC_eLetter2Controller.FromAddress();
                fromAddress.name =  UserInfo.getUserName();
                fromAddress.address = UserInfo.getUserEmail();
                fromAddress.fromId = UserInfo.getUserId();
                
                eLetterRequest.fromAddress = fromAddress;
                eLetterRequest.eletterId = eletter.Id;
                eLetterRequest.recordId = programCase.Id;
                eLetterRequest.attachmentIds = attachmentIds;
                eLetterRequest.isSecureEmail = PC_Constants.TRUE_BOOLEAN;
                eLetterRequest.sendToCurrentUser = PC_Constants.TRUE_BOOLEAN;
                eLetterRequest.subject = subject;
                eLetterRequest.communicationMethod = PC_Constants.EMAIL;
                
                // Send to currentUser = False
                PC_eLetterService.sendLetter(programCase.Id, eletter, 'Email', recipients, FALSE, eLetterRequest);
            }
            Test.stopTest();
        } catch (Exception ex) {
            system.debug('exception StackTraceString >>' + ex.getStackTraceString());
            system.assert(false, ex.getMessage());
        }
    }

    /*********************************************************************************
    Method Name    : testSendToMe
    Author         : Satheesh Kumar
    Description    : This method is used for testing "SendToMe" functionality
    Return Type    : void
    *********************************************************************************/
    @isTest static void testSendToMe() {
        try {
            createTestData();
            Test.startTest();
            system.runAs(adminUser) {
                String subject = 'Custom Subject';
                Boolean isEmailSecure = PC_Constants.TRUE_BOOLEAN;
                PC_eLetter2Controller.SendLetterRequest eLetterRequest = new PC_eLetter2Controller.SendLetterRequest();
                PC_eLetter2Controller.FromAddress fromAddress = new PC_eLetter2Controller.FromAddress();
                fromAddress.name =  UserInfo.getUserName();
                fromAddress.address = UserInfo.getUserEmail();
                fromAddress.fromId = UserInfo.getUserId();

                eLetterRequest.fromAddress = fromAddress;
                eLetterRequest.eletterId = eletter.Id;
                eLetterRequest.recordId = programCase.Id;
                eLetterRequest.attachmentIds = attachmentIds;
                eLetterRequest.isSecureEmail = PC_Constants.TRUE_BOOLEAN;
                eLetterRequest.sendToCurrentUser = PC_Constants.TRUE_BOOLEAN;
                eLetterRequest.subject = subject;
                eLetterRequest.communicationMethod = PC_Constants.EMAIL;

                // Send to currentUser = True
                eLetterRequest.eletterId = eletter2.Id;
                eLetterRequest.isSecureEmail = PC_Constants.FALSE_BOOLEAN;
                PC_eLetterService.sendLetter(programCase.Id, eletter, 'Email', recipients, TRUE, eLetterRequest);
            }
            Test.stopTest();
        } catch (Exception ex) {
            system.debug('exception at testSendToMe method. StackTraceString >>' + ex.getStackTraceString());
            system.assert(false, ex.getMessage());
        }
    }


    /*********************************************************************************
    Method Name    : testCustomSendLetter
    Author         : Satheesh Kumar
    Description    : This method is used for testing custom message in eletter functionality
    Return Type    : void
    *********************************************************************************/
    @isTest static void testCustomSendLetter() {
        try {
            createTestData();
            Test.startTest();
            system.runAs(adminUser) {
                String subject = 'Custom Subject';
                Boolean isEmailSecure = PC_Constants.TRUE_BOOLEAN;
                PC_eLetter2Controller.SendLetterRequest eLetterRequest = new PC_eLetter2Controller.SendLetterRequest();
                PC_eLetter2Controller.FromAddress fromAddress = new PC_eLetter2Controller.FromAddress();
                fromAddress.name =  UserInfo.getUserName();
                fromAddress.address = UserInfo.getUserEmail();
                fromAddress.fromId = UserInfo.getUserId();

                eLetterRequest.fromAddress = fromAddress;
                eLetterRequest.eletterId = eletter.Id;
                eLetterRequest.recordId = programCase.Id;
                eLetterRequest.attachmentIds = attachmentIds;
                eLetterRequest.isSecureEmail = PC_Constants.TRUE_BOOLEAN;
                eLetterRequest.sendToCurrentUser = PC_Constants.TRUE_BOOLEAN;
                eLetterRequest.subject = subject;
                eLetterRequest.communicationMethod = PC_Constants.EMAIL;

                // eletterId = null
                eLetterRequest.eletterId = null;
                PC_eLetterService.sendLetter(programCase.Id, eletter, 'Email', recipients, FALSE, eLetterRequest);
            }
            Test.stopTest();
        } catch (Exception ex) {
            system.debug('exception at testCustomSendLetter - StackTraceString >>' + ex.getStackTraceString());
            system.assert(false, ex.getMessage());
        }
    }
}