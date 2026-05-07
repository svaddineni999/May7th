/*********************************************************************************
Class Name      : PC_Test_eLetterEmailTemplateSender2
Description     :
Created By      : Ajinkya Deshmukh
Created Date    : March 16, 2016
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------
Ajinkya Deshmukh          March 16, 2016              Initial Version
Mayuresh Patil            July 5, 2017                PC-1868 Resolved Force Scanner issues - 	Avoid calling soql without a where clause or limit statement
Shabda Bhujad			  July 14, 2017		   		  [PC-1897] Added the check the test outcomes only if the trigger handler is active.
Mayuresh Patil            Oct 18, 2017                [PC-2069] Fixing issues due to association trigger
Satheesh Kumar            Jul 15, 2020                [PC-6352] Updated test class to reflect the changes done to the PC_eLetterEmailTemplateSender class
*********************************************************************************/
@isTest
public class PC_Test_eLetterEmailTemplateSender2 {
    public static final String ACCOUNT_OBJ = 'Account';
    private static User adminUser;
    public static Boolean isTriggerActive = True;


    private static Account physicianAcc;
    private static Contact physicianCon;
    private static Account patientAcc;
    private static User careCoordinator;
    private static Case programCase;
    private static EmailTemplate emailTemplate;
    private static PC_eLetter__c eletter;
    private static PC_System_Settings__c cSetting;
    private static List<PC_eLetter.RecipientWrapper> recipients;
    private static List<String> attachmentIds;

    /*********************************************************************************
	Method Name    : createTestData
	Author         : Tejas Patel
	Description    : This method is used for creating test data
	Return Type    : void
	Parameter      :
	*********************************************************************************/

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

            // create a record for the custom setting
            cSetting = new PC_System_Settings__c();
            cSetting.PC_eLetter_Sender_Class__c = 'PC_eLetterEmailTemplateSender2';
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
    Method Name    : testSendLetter
    Description    : Test send eletter functionality
    Return Type    : void
    Parameter      : None
    *********************************************************************************/
    @isTest static void testSendLetter() {
        try {
            createTestData();
            Test.startTest();
            if(isTriggerActive) {
                system.runAs(adminUser) {
                    PC_eLetterService.sendLetter(programCase.Id, eletter, 'Email', recipients, FALSE);
                    List<PC_Document__c> checkDocument = [SELECT Id, (SELECT Id FROM Attachments) FROM PC_Document__c LIMIT 10];
                    // check if the document is created
                    system.assertEquals(checkDocument.size(), 3);
                    // check if the attachment is created
                    system.debug('@@C' + checkDocument[0].Attachments);
                    Boolean useSalesforceFiles = PC_SYSTEM.useSalesforceFiles();
                    if (useSalesforceFiles) {
                        Set<Id> docIds = (new Map<Id, PC_Document__c>(checkDocument)).keySet();
                        List<ContentDocumentLink> lstContentDocs = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId IN:docIds];
                        system.assertEquals(lstContentDocs.size(), 3);
                    } else {
                        system.assertEquals(checkDocument[0].Attachments.size(), 1);
                    }
                }
            }
            Test.stopTest();
        } catch (Exception ex) {
            system.debug('exception in testSendLetter >>' + ex.getMessage());
            system.assert(false, ex.getMessage());
        }
    }

    /*********************************************************************************
    Method Name    : testSendEletterWithAttachments
    Author         : Satheesh Kumar
    Description    : This method is used for testing "SendLetter" with attachments
    Return Type    : void
    *********************************************************************************/
    @isTest static void testSendEletterWithAttachments() {
        try {
            createTestData();
            Test.startTest();
            if(isTriggerActive) {
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

                    PC_eLetterService.sendLetter(programCase.Id, eletter, 'Email', recipients, FALSE, eLetterRequest);
                    eLetterRequest.isSecureEmail = PC_Constants.FALSE_BOOLEAN;
                    eLetterRequest.sendToCurrentUser = PC_Constants.FALSE_BOOLEAN;
                    PC_eLetterService.sendLetter(programCase.Id, eletter, 'Email', recipients, true, eLetterRequest);
                }
            }
            Test.stopTest();
        } catch (Exception ex) {
            system.debug('exception in testSendLetter >>' + ex.getMessage());
            system.assert(false, ex.getMessage());
        }
    }
}