/*********************************************************************************
Class Name      : PC_Test_eLetterEmailTemplateSender
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
*********************************************************************************/
@isTest
public class PC_Test_eLetterEmailTemplateSender {
    public static final String ACCOUNT_OBJ = 'Account';
    private static User adminUser;
    public static Boolean isTriggerActive = True;

    /*********************************************************************************
Method Name    : Test
Description    : Test create new user functionality
Return Type    : void
Parameter      : None
*********************************************************************************/
    @isTest static void sendLetter() {
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'userpctest@test2.com', 'test2');
        PC_Database.ins(adminUser);
        system.runAs(adminUser) {
            Test.startTest();
            if(isTriggerActive) {
                Account physicianAcc = PC_Test_Setup.newAccount (null, 'Account Name', 'phyician', 'lastName', PC_Constants.PHYSICIAN_RECORD_TYPE);
                physicianAcc.PC_Email__c = 'test@test.com';
                // check if physician is created
                PC_Database.ins(physicianAcc);
                system.assertNotEquals(physicianAcc.Id, null);
                Contact physicianCon = [SELECT Id, Email FROM Contact WHERE AccountId =: physicianAcc.Id];
                system.assertNotEquals(physicianCon.Id, null);
                // set physician contact email address
                physicianCon.Email = 'test@test.com';
                PC_Database.upd(physicianCon);
                physicianAcc.HealthCloudGA__PrimaryContact__c = physicianCon.Id;
                physicianAcc.HealthCloudGA__PrimaryContact__r = physicianCon;
                PC_Database.upd(physicianAcc);
                system.assertEquals (physicianCon.Email , 'test@test.com');
                Account patientAcc = PC_Test_Setup.newAccount (null, 'Account Name', 'patient', 'lastName', PC_Constants.PATIENT_RECORD_TYPE);
                PC_Database.ins(patientAcc);
                // check if patient is created
                system.assertNotEquals(patientAcc.Id, null);
                Case programCase = PC_Test_Setup.newCase(null, patientAcc.Id, PC_Constants.CASE_PROGRAM_RECORD_TYPE);
                PC_Database.ins(programCase);
                // check of program case is created
                system.assertNotEquals(programCase.Id, null);
                PC_Association__c aAssociation = PC_Test_Setup.createAssociation(physicianAcc, programCase, 'Treating Physician', system.today(), null);
                // create association between patient and physician
                system.assertNotEquals(aAssociation.Id, null);
                // create an email template
                EmailTemplate emailTemplate = new EmailTemplate (
                    developerName = 'Email_Template_Name',
                    FolderId = UserInfo.getUserId(),
                    TemplateType= 'Text',
                    Name = 'Email Template Name',
                    Body = 'This is an Email Body',
                    IsActive = TRUE
                );
                PC_Database.ins(emailTemplate);
                // check if email template has been created
                system.assertNotEquals(aAssociation.Id, null);
                // create eltter
                PC_eLetter__c eletter = new PC_eLetter__c (
                    Name = 'Test 1',
                    PC_Target_Recipients__c = 'HCO; Treating Physician',
                    PC_Communication_Language__c = 'English',
                    PC_Send_to_User__c= false,
                    PC_Source_Object__c = 'Case',
                    PC_Template_Name__c = 'Email_Template_Name'
                );
                PC_Database.ins(eletter);
                // check if eletter has been created
                system.assertNotEquals(eletter.Id, null);
                // create a record for the custom setting
                PC_System_Settings__c cSetting = new PC_System_Settings__c();
                cSetting.PC_eLetter_Sender_Class__c = 'PC_eLetterEmailTemplateSender';
                PC_Database.ins(cSetting);
                // instantiate PC_eltterService sendLetter method
                List<PC_eLetter.RecipientWrapper> recipients = new List<PC_eLetter.RecipientWrapper>();
                recipients.add(new PC_eLetter.RecipientWrapper(physicianAcc));
                PC_eLetterService.sendLetter(programCase.Id, eLetter, 'Email',  recipients, FALSE);
                List<PC_Document__c> checkDocument = [SELECT Id, (SELECT Id FROM Attachments) FROM PC_Document__c LIMIT 10];
                // check if the document is created
                system.assertEquals(checkDocument.size(), 1);
                // check if the attachment is created
                system.debug('@@C'+ checkDocument[0].Attachments);
                Set<Id> t = (new Map<Id,PC_Document__c>(checkDocument)).keySet();
                List<ContentDocumentLink> l = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId IN: t];
                system.debug('@@l'+ l);
                Boolean useSalesforceFiles = PC_SYSTEM.useSalesforceFiles();
                if(useSalesforceFiles){

                    Set<Id> docIds = (new Map<Id,PC_Document__c>(checkDocument)).keySet();
                    List<ContentDocumentLink> lstContentDocs = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId IN: docIds];
                    system.assertEquals(lstContentDocs.size(), 1);
                }else{
                    system.assertEquals(checkDocument[0].Attachments.size(), 1);
                }
            }
            Test.stopTest();
        }
    }
}