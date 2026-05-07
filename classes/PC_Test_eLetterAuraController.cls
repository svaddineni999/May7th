/*********************************************************************************
Test Class Name : PC_Test_eLetterAuraController
Description     : Test class for PC_eLetterAuraController
Created By      : Roxana Ivan 
Created Date    : June 21, 2016
Modification Log:
---------------------------------------------------------------------------------- 
Developer                   Date                   Description
----------------------------------------------------------------------------------            
Roxana Ivan            June 21, 2016          Initial Version
Mayuresh Patil         Oct 18, 2017           [PC-2069] Fixing issues due to association trigger
Hitha Avalakki         Mar 12, 2019           [PC-4487] Test code to fetch eLetters as per engagement program
*********************************************************************************/
@isTest
public class PC_Test_eLetterAuraController { 
    static final String PHYSICIAN_RECORD_TYPE = 'PC_Physician';
    static final String ACCOUNT_OBJ = 'Account';
    static final String MOCK_SENDER = 'PC_Test_MockELetterSender';
    private static User adminUser;
    
    /*********************************************************************************
    Method Name    : Test 
    Description    : Test create new user functionality
    Return Type    : void
    Parameter      : None
    *********************************************************************************/
    @isTest
    static void getLetters() {
        Test.StartTest();
        // create a record for the custom setting
        PC_System_Settings__c cSetting = new PC_System_Settings__c();
        cSetting.PC_eLetter_Sender_Class__c = MOCK_SENDER;
        PC_Database.ins(cSetting);

        //Create eLetter
        PC_eLetter__c eletter = new PC_eLetter__c (
            Name = 'Test 1',
            PC_Target_Recipients__c = 'HCO; Treating Physician', 
            PC_Communication_Language__c = 'English',
            PC_Send_to_User__c= false,
            PC_Source_Object__c = 'Case'
        );
        PC_Database.ins(eletter);

        Id accountRecordTypeId = PC_System.recordTypeId(ACCOUNT_OBJ, PHYSICIAN_RECORD_TYPE);
        Account account = new Account();
        account.Name = 'Physician Name';
        account.RecordTypeId = accountRecordTypeId;
        account.PC_Specialist_Type__c = 'Cardiologist';
        account.Type = 'Specialist';
        account.PC_Sub_Type__c = 'Other';
        account.PC_Email__c = 'test@test.com';
        PC_Database.ins(account);
        Case programCase = PC_Test_Setup.newCase(account.Id, PC_Constants.CASE_PROGRAM_RECORD_TYPE);
        PC_Database.ins(programCase);

        System.assertEquals(1, PC_eLetterAuraController.getLetters(programCase.Id).size());

        PC_Association__c association = PC_Test_eLetterAuraController.createAssociation(account, programCase, 'Treating Physician', Date.today().addDays(1));
        
        List<PC_eLetter_Recipient> getRecipients =  PC_eLetterAuraController.getRecipients(eletter.Id, programCase.Id);
        getRecipients[0].sendEmail = true;
        String recipientJSON = System.JSON.serialize(getRecipients);
        System.debug('@@Tejas r'+getRecipients);
        System.assertEquals(account.PC_Email__c, getRecipients[0].recipient.email);
        String rType = (String) String.valueOf(PC_eLetter.RecipientType.ACCOUNT);
        String recepients = '[{"bDisableEmail":false,"bDisableFax":false,"bDisableSendToMe":true,"communicationLanguage":"English","recipient":{"Id":"'+ account.Id+'","communicationLanguage":"English","type":"'+rType+'","email":"test@test.com","name":"Name."},"recipientType":"Specialist","sendEmail":true,"sendFax":false,"sendToMe":false}]';
        String returnMessage = PC_eLetterAuraController.sendOutboundDocuments(recipientJSON, eletter.Id, programCase.Id);
        System.debug('@@Tejas'+returnMessage);
        System.assertNotEquals(returnMessage, null);
        Test.StopTest();
    }

    public static PC_Association__c createAssociation(Account account, Case caseObj, String roleName, Date endDate) {
        PC_Association__c association = new PC_Association__c (PC_Account__c = account.Id, PC_Program__c = caseObj.Id, PC_Role__c = roleName, PC_EndDate__c = endDate);

        return (PC_Association__c)PC_Database.ins(association);
    }

    /*********************************************************************************
    Method Name    : testSendToMe
    Description    : Test send eLetter to user
    Return Type    : void
    Parameter      : None
    *********************************************************************************/
    @isTest
    static void testSendToMe() {
        Test.StartTest();
        // create a record for the custom setting
        PC_System_Settings__c cSetting = new PC_System_Settings__c();
        cSetting.PC_eLetter_Sender_Class__c = MOCK_SENDER;
        PC_Database.ins(cSetting);

        //Create eLetter
        PC_eLetter__c eletter = new PC_eLetter__c (
            Name = 'Test 1',
            PC_Target_Recipients__c = 'HCO; Treating Physician', 
            PC_Communication_Language__c = 'English',
            PC_Send_to_User__c=  true,
            PC_Source_Object__c = 'Case'
        );
        PC_Database.ins(eletter);

        Id accountRecordTypeId = PC_System.recordTypeId(ACCOUNT_OBJ, PHYSICIAN_RECORD_TYPE);
        Account account = new Account();
        account.Name = 'Physician Name';
        account.RecordTypeId = accountRecordTypeId;
        account.PC_Specialist_Type__c = 'Cardiologist';
        account.Type = 'Specialist';
        account.PC_Sub_Type__c = 'Other';
        account.PC_Email__c = 'test@test.com';
        PC_Database.ins(account);

        Case programCase = PC_Test_Setup.newCase(account.Id, PC_Constants.CASE_PROGRAM_RECORD_TYPE);
        PC_Database.ins(programCase);

        PC_Association__c association = PC_Test_eLetterAuraController.createAssociation(account, programCase, 'Treating Physician', Date.today().addDays(1));

        List<PC_eLetter_Recipient> getRecipients =  PC_eLetterAuraController.getRecipients(eletter.Id, programCase.Id);
        System.debug('@Tejas Recepients :' + getRecipients[0].recipientEmail);
        System.assertEquals(account.PC_Email__c, getRecipients[0].recipient.email);

        String recepients = '[{"bDisableEmail":false,"bDisableFax":false,"bDisableSendToMe":true,"communicationLanguage":"English","recipient":{"Id":"'+ account.Id+'","PC_Communication_Language__c":"English","Type":"Specialist","PC_Email__c":"test@a.com","Name":"Name."},"recipientType":"Specialist","sendEmail":false,"sendFax":false,"sendToMe":true}]';
        String returnMessage = PC_eLetterAuraController.sendOutboundDocuments(recepients, eletter.Id, programCase.Id);

        System.assertNotEquals(returnMessage, null);
        Test.StopTest();
    }


    /*********************************************************************************
    Method Name    : testSendToMe
    Description    : Test send eLetter to user
    Return Type    : void
    Parameter      : None
    *********************************************************************************/
    @isTest
    static void testSendFax() {
        Test.StartTest();
        // create a record for the custom setting
        PC_System_Settings__c cSetting = new PC_System_Settings__c();
        cSetting.PC_eLetter_Sender_Class__c = MOCK_SENDER;
        PC_Database.ins(cSetting);

        //Create eLetter
        PC_eLetter__c eletter = new PC_eLetter__c (
            Name = 'Test 1',
            PC_Target_Recipients__c = 'HCO; Treating Physician', 
            PC_Communication_Language__c = 'English',
            PC_Send_to_User__c= false,
            PC_Source_Object__c = 'Case'
        );
        PC_Database.ins(eletter);

        Id accountRecordTypeId = PC_System.recordTypeId(ACCOUNT_OBJ, PHYSICIAN_RECORD_TYPE);
        Account account = new Account();
        account.Name = 'Physician Name';
        account.RecordTypeId = accountRecordTypeId;
        account.PC_Specialist_Type__c = 'Cardiologist';
        account.Type = 'Specialist';
        account.PC_Sub_Type__c = 'Other';
        account.PC_Email__c = 'test@test.com';
        PC_Database.ins(account);

        Case programCase = PC_Test_Setup.newCase(account.Id, PC_Constants.CASE_PROGRAM_RECORD_TYPE);
        PC_Database.ins(programCase);

        PC_eLetterAuraController.getLetters(programCase.Id);
        PC_Association__c association = PC_Test_eLetterAuraController.createAssociation(account, programCase, 'Treating Physician', Date.today().addDays(1));
        
        List<PC_eLetter_Recipient> getRecipients =  PC_eLetterAuraController.getRecipients(eletter.Id, programCase.Id);
        System.assertEquals(account.PC_Email__c, getRecipients[0].recipient.email);

        String recepients = '[{"bDisableEmail":false,"bDisableFax":false,"bDisableSendToMe":false,"communicationLanguage":"English","recipient":{"Id":"'+ account.Id+'","PC_Communication_Language__c":"English","Type":"Specialist","PC_Email__c":"test@a.com","Name":"Name."},"recipientType":"Specialist","sendEmail":false,"sendFax":true,"sendToMe":false}]';
        String returnMessage = PC_eLetterAuraController.sendOutboundDocuments(recepients, eletter.Id, programCase.Id);

        System.assertNotEquals(returnMessage, null);
        Test.StopTest();
    }
     /*********************************************************************************
    Method Name    : testSendToMe
    Description    : Test send eLetter to user
    Return Type    : void
    Parameter      : None
    *********************************************************************************/
    @isTest
    static void testNoRecepients() {
        Test.StartTest();
        // create a record for the custom setting
        PC_System_Settings__c cSetting = new PC_System_Settings__c();
        cSetting.PC_eLetter_Sender_Class__c = MOCK_SENDER;
        PC_Database.ins(cSetting);

        PC_eLetter__c eletter = new PC_eLetter__c (
            Name = 'Test 1',
            PC_Target_Recipients__c = 'HCO; Treating Physician', 
            PC_Communication_Language__c = 'English',
            PC_Send_to_User__c= false,
            PC_Source_Object__c = 'Case'
        );
        PC_Database.ins(eletter);

        Id accountRecordTypeId = PC_System.recordTypeId(ACCOUNT_OBJ, PHYSICIAN_RECORD_TYPE);
        Account account = new Account();
        account.Name = 'Physician Name';
        account.RecordTypeId = accountRecordTypeId;
        account.PC_Specialist_Type__c = 'Cardiologist';
        account.Type = 'Specialist';
        account.PC_Sub_Type__c = 'Other';
        account.PC_Email__c = 'test@test.com';
        PC_Database.ins(account);

        Case programCase = PC_Test_Setup.newCase(account.Id, PC_Constants.CASE_PROGRAM_RECORD_TYPE);
        PC_Database.ins(programCase);

        String recepients = '[{"bDisableEmail":false,"bDisableFax":false,"bDisableSendToMe":false,"communicationLanguage":"English","recipient":{},"recipientType":"Specialist","sendEmail":false,"sendFax":true,"sendToMe":false}]';
        String returnMessage = PC_eLetterAuraController.sendOutboundDocuments(recepients, eletter.Id, programCase.Id);
        System.assertNotEquals(returnMessage, null);
        Test.StopTest();
    }

    /*********************************************************************************
    Method Name    : getLettersAsPerEngagementProgram
    Description    : est code to fetch eLetters as per engagement program
    Return Type    : void
    Parameter      : None
    *********************************************************************************/
    @isTest
    static void getLettersAsPerEngagementProgram() {

        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'userpctest@test2.com', 'test2');
        PC_Database.ins(adminUser);
        system.runAs(adminUser) {

            List<PC_eLetter__c> eLetterList = new List<PC_eLetter__c>();
            //Create eLetter
            PC_eLetter__c caseEletter = new PC_eLetter__c(
                    Name = 'Patient Welcome Letter',
                    PC_Object_Record_Types__c = 'Program',
                    PC_Source_Object__c = 'Case'
            );
            eLetterList.add(caseEletter);
            PC_eLetter__c interactionEletter = new PC_eLetter__c(
                    Name = 'ELetter for Interaction',
                    PC_Source_Object__c = 'Interaction'
            );
            eLetterList.add(interactionEletter);
            PC_eLetter__c programCovEletter = new PC_eLetter__c(
                    Name = 'ELetter for Program Coverage',
                    PC_Object_Record_Types__c = 'Private Coverage',
                    PC_Source_Object__c = 'Program Coverage'
            );
            eLetterList.add(programCovEletter);
            PC_Database.ins(eLetterList);

            Account manufacturerAcc = PC_Test_Setup.createTestAccount(PC_Constants.MANUFACTURER_RECORD_TYPE);
            PC_Database.ins(manufacturerAcc, false);
            PC_Engagement_Program__c engagementProgram = PC_Test_Setup.createEngagementProgram('ProgramA', manufacturerAcc.Id);
            PC_Database.ins(engagementProgram, false);

            Account patientAccount = PC_Test_Setup.createSampleAccount('Test Patient', PC_Constants.PATIENT_RECORD_TYPE);
            PC_Database.ins(patientAccount);

            Case programCaseRecord = PC_Test_Setup.createProgram(patientAccount);
            programCaseRecord.PC_Engagement_Program__c = engagementProgram.Id;
            PC_Database.upd(programCaseRecord);

            PC_Interaction__c interactionRecord = PC_Test_Setup.newInteraction(programCaseRecord.Id);
            PC_Database.ins(interactionRecord);

            PC_Program_Coverage__c progCoverageRecord = PC_Test_Setup.createProgramCoverage(programCaseRecord.Id);
            PC_Database.ins(progCoverageRecord);

            PC_Engagement_Program_Eletter__c caseEngagementProgEletter = new PC_Engagement_Program_Eletter__c();
            caseEngagementProgEletter.PC_eLetter__c = caseEletter.Id;
            caseEngagementProgEletter.PC_Engagement_Program__c = engagementProgram.Id;
            PC_Database.ins(caseEngagementProgEletter);

            PC_Engagement_Program_Eletter__c interactionEngagementProgEletter = new PC_Engagement_Program_Eletter__c();
            interactionEngagementProgEletter.PC_eLetter__c = interactionEletter.Id;
            interactionEngagementProgEletter.PC_Engagement_Program__c = engagementProgram.Id;
            PC_Database.ins(interactionEngagementProgEletter);

            PC_Engagement_Program_Eletter__c progCovEngagementProgEletter = new PC_Engagement_Program_Eletter__c();
            progCovEngagementProgEletter.PC_eLetter__c = programCovEletter.Id;
            progCovEngagementProgEletter.PC_Engagement_Program__c = engagementProgram.Id;
            PC_Database.ins(progCovEngagementProgEletter);

            Test.StartTest();

            List<PC_LightningMap> caseELettersList = PC_eLetterAuraController.getLetters(programCaseRecord.Id);
            System.assert(caseELettersList.size() > 1);

            List<PC_LightningMap> interactionELettersList = PC_eLetterAuraController.getLetters(interactionRecord.Id);
            System.assert(interactionELettersList.size() > 1);

            List<PC_LightningMap> progCovELettersList = PC_eLetterAuraController.getLetters(progCoverageRecord.Id);

            Test.StopTest();
        }
    }
}