/*********************************************************************************
Test Class Name : PC_Test_SMSSender2
Description     : Test class for PC_SMSSender2Controller
Created By      : Chetna Mohapatra
Created Date    : Jan 11, 2021
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
----------------------------------------------------------------------------------
Chetna Mohapatra          Jan 11, 2021            Initial Version
Chetna Mohapatra          Jun 28, 2021            Changed testGetInitInfo, testSendMessage methods and added testGetEletterInfoCase method.
*********************************************************************************/

 @IsTest
 private class PC_Test_SMSSender2 {
     private static User adminUser;
     private static User careCoordinator;
     private static Account patient;
     private static Account physician;
     private static Account manufacturer;
     private static PC_Engagement_Program__c engmtProgram;
     private static Case programCase;
     private static String programCaseId;
     private static PC_eLetter__c caseEletter;
     private static String eletterId;
     private static String blankErrorMessage='The Sender Number is blank in the Patient Connect Settings. Please contact the System Administrator.';
     /*********************************************************************************
    Method Name    : createTestData
    Author         : Chetna Mohapatra
    Description    : This method is used for creating test data
    Return Type    : void
    *********************************************************************************/

     private static void createTestData() {

         adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'smsadminuser@email.com', 'admin');
         PC_Database.ins(adminUser, false);

         careCoordinator= PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'carecoordinate@email.com', 'CareCo');
         PC_Database.ins(careCoordinator, false);

         patient = PC_Test_Setup.createSampleAccount('John', PC_Constants.PATIENT_RECORD_TYPE);
         patient.PC_Date_of_Birth__c = date.today().addDays(-100);
         patient.phone = '919439594358';
         patient = (Account) PC_Database.ins(patient, false);
         // check if patient is created
         system.assertNotEquals(patient.Id, null);

         physician = PC_Test_Setup.createSampleAccount('Jared', PC_Constants.PHYSICIAN_RECORD_TYPE);
         physician.PC_Date_of_Birth__c = date.today().addDays(-500);
         physician.phone = '919439594358';
         physician = (Account) PC_Database.ins(physician, false);
         // check if physician is created
         system.assertNotEquals(physician.Id, null);

         //Create Manufacturer
         List<Account> manufacturers = PC_Test_Setup.createAccounts('testmanufacturer', 1, PC_Constants.MANUFACTURER_RECORD_TYPE);
         manufacturer = (Account) PC_Database.ins(manufacturers[0], false);

         //Create Engagement Program
         engmtProgram = PC_Test_Setup.createEngagementProgram('TestPgm', manufacturer.Id);
         engmtProgram.PC_Program_Code__c = 'TestPgm';
         engmtProgram = (PC_Engagement_Program__c) PC_Database.ins(engmtProgram, false);

         programCase = PC_Test_Setup.createCase(adminUser, patient);
         programCase.PC_Engagement_Program__c = engmtProgram.Id;
         programCase.PC_Physician__c = physician.Id;
         programCase.PC_Care_Coordinator__c = careCoordinator.Id;
         programCase.PC_Enrollment_Date__c = date.today().addDays(-10);
         programCase = (Case) PC_Database.ins(programCase, false);
         programCaseId= programCase.Id;
         // check if program Case is created
         system.assertNotEquals(programCase.Id, null);

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

         List<PC_eLetter__c> eLetterList = new List<PC_eLetter__c>();
         //Create eLetter
         caseEletter = new PC_eLetter__c(
                 Name = 'Patient Welcome SMS',
                 PC_Object_Record_Types__c = 'Program',
                 PC_Target_Recipients__c = 'HCO; Treating Physician',
                 PC_Allow_Send_to_Patient__c = true,
                 PC_Category__c = 'SMS',
                 PC_Source_Object__c = 'Case',
                 PC_Template_Name__c = 'Email_Template_Name'
         );
         eLetterList.add(caseEletter);
         PC_Database.ins(eLetterList,false);
         eletterId= caseEletter.Id;
         system.assertNotEquals(caseEletter.Id, null);

         // Create Engagement Program Eletter for Case
         PC_Engagement_Program_Eletter__c caseEngagementProgEletter = new PC_Engagement_Program_Eletter__c();
         caseEngagementProgEletter.PC_eLetter__c = caseEletter.Id;
         caseEngagementProgEletter.PC_Engagement_Program__c = engmtProgram.Id;
         caseEngagementProgEletter.PC_PreConfiguredSMSRecipients__c = '[{"name" : "Richard Sean", "phone": "+919861157655", "role": "ENT"}]';
         PC_Database.ins(caseEngagementProgEletter,false);
         system.assertNotEquals(caseEngagementProgEletter.Id, null);

     }
     /*********************************************************************************
        Method Name    : testGetInitInfo
        Description    : Test getInitInfo method
        Return Type    : void
        Parameter      : None
     *********************************************************************************/
     @isTest static void testGetInitInfo() {
         try {
             Test.startTest();
             createTestData();
             system.runAs(adminUser) {
                 //create a category list for SMS.
                 List<String> smsCategoryList = new List<String>{
                         'SMS'
                 };
                 system.debug('Program Case results-->' + PC_SMSSender2Controller.getInitInfo(programCaseId, smsCategoryList));
                 System.assertEquals(3, PC_SMSSender2Controller.getInitInfo(programCaseId, smsCategoryList).recipients.size());
             }
             Test.stopTest();
         } catch (Exception ex) {
             system.debug('exception in testGetInitInfo >>' + ex.getStackTraceString());
             system.assert(!String.isBlank(ex.getMessage()));
         }
     }
     /*********************************************************************************
    Method Name    : testGetEletterInfoCase
    Description    : Test getEletterInfo method
    Return Type    : void
    Parameter      : None
    *********************************************************************************/
     @isTest static void testGetEletterInfoCase() {
         try {
             Test.StartTest();
             createTestData();
             system.runAs(adminUser) {
                 //Case
                 PC_SMSSender2Controller.EletterInfo caseELetterInfo = PC_SMSSender2Controller.getEletterInfo(eletterId, programCaseId);
                 caseELetterInfo.eLetterRecipients[0].sendSms = true;
                 String caseRecipientJSON = System.JSON.serialize(caseELetterInfo.eLetterRecipients);
                 System.assertEquals(3, caseELetterInfo.eLetterRecipients.size());
             }
             Test.StopTest();
         } catch (Exception ex) {
             system.debug('exception in testGetEletterInfoCase >>' + ex.getMessage());
             system.assert(!String.isBlank(ex.getMessage()));
         }
     }
     /*********************************************************************************
    Method Name    : testSendMessage
    Description    : Test sendMessage method
    Return Type    : void
    Parameter      : None
    *********************************************************************************/
     @isTest static void testSendMessage() {
         String messageBody='Test Message';
         String sender='(774) 273-7543';
         try {
             Test.startTest();
             createTestData();
             String selectedRecipient= '[{"disableSms": false,"hasNoPhoneNumber": false,"Id": "'+patient.Id+'","name": "John","phone": "919439594358","recipientType": "Account","role": "Patient","msgBody":"'+messageBody+'","sendSms": false}]';
             system.runAs(adminUser) {
                 PC_SMSSender2Controller.sendMessage(messageBody,programCaseId,sender,selectedRecipient, eletterId);
             }
             Test.stopTest();
         }
         catch (Exception ex) {
             system.debug('exception in testSendMessage >>' + ex.getMessage());
             system.assert(!String.isBlank(ex.getMessage()));
         }
     }

 }