/*********************************************************************************************************
Class Name      : PC_Test_SendAdverseEventEmailController
Description     :
Created By      : Deloitte
Created Date    :
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer                  Date                   Description
Kanteti Kishore           May 5,2020             [PC-5940]Test Class for PC_SendAdverseEventEmailController Component
Hitha Avalakki            Feb 26, 2021           [PC-7442] Replaced PC_Test_Setup.createCases() with PC_Test_Setup.createProgramCases() method.
****************************************************************************************************************/

@IsTest(seeAllData=False)
public with sharing class PC_Test_SendAdverseEventEmailController {
    private static User objUser;
    private static String patientName = 'Patient';
    private static String manufacturerName ='Manufacturer';
    private static String engagementProgramName = 'Program';
    private static String userMail = 'user@t1234.com' ;
    private static String userName = 'TestName' ;
    private static String emailTemplateName = 'PC_TestTemplateName' ;
    private static String adverseEventName = 'Adverse Event' ;
    private static String adverseEvent2Name = 'Adverse Event 2' ;
    private static String senderClassName = 'PC_eLetterEmailTemplateSender' ;

    @testSetup static void setup() {
        objUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, userMail, userName);
        PC_Database.ins(objUser);
        system.runAs(objUser) {
            // Create patient account
            List<Account> accounts = new List<Account>();
            accounts = PC_Test_Setup.createAccounts(patientName, 1, PC_Constants.PATIENT_RECORD_TYPE);
            PC_Database.ins(accounts, false);

            //Create Manufacturer
            List<Account> manufacturerAccounts = new List<Account>();
            manufacturerAccounts = PC_Test_Setup.createAccounts(manufacturerName,1,PC_Constants.MANUFACTURER_RECORD_TYPE);
            PC_Database.ins(manufacturerAccounts, false);

            //Create Engagement Program
            PC_Engagement_Program__c engProgram = new PC_Engagement_Program__c();
            engProgram = PC_Test_Setup.createEngagementProgram(engagementProgramName,manufacturerAccounts[0].Id);
            PC_Database.ins(engProgram, false);

            //Create Case
            List<Case> cases = new List<Case>();
            //[PC-7442] Replaced PC_Test_Setup.createCases() with PC_Test_Setup.createProgramCases() method.
            cases = PC_Test_Setup.createProgramCases(accounts, 1);
            cases[0].PC_Engagement_Program__c =  engProgram.Id;
            PC_Database.ins(cases, false);

            //create Adverse event
            PC_AdverseEvent__c adverseEvent = new PC_AdverseEvent__c();
            adverseEvent = PC_Test_Setup.createAdverseEvents(accounts[0].Id);
            adverseEvent.PC_Care_Program__c = cases[0].Id;
            PC_Database.ins(adverseEvent, false);

            //create Adverse event2
            PC_AdverseEvent2__c adverseEvent2 = new PC_AdverseEvent2__c();
            adverseEvent2 = PC_Test_Setup.newAdverseEvent2(accounts[0].Id);
            //adverseEvent2.PC_Care_Program__c = cases[0].Id;
            PC_Database.ins(adverseEvent2, false);

            //Create Email Template
            EmailTemplate newMailTemplate = new EmailTemplate();
            newMailTemplate = PC_Test_Setup.createEmailTemplate(emailTemplateName);
            PC_Database.ins(newMailTemplate, false);

            //Create eLetter
            PC_eLetter__c eLetter = new PC_eLetter__c();
            eLetter = PC_Test_Setup.createEletter();
            eLetter.PC_Source_Object__c = adverseEventName;
            eLetter.PC_Template_Name__c = emailTemplateName;
            PC_Database.ins(eLetter, false);

            //Create eLetter
            PC_eLetter__c eLetter2 = new PC_eLetter__c();
            eLetter2 = PC_Test_Setup.createEletter();
            eLetter2.PC_Source_Object__c = adverseEvent2Name;
            eLetter2.PC_Template_Name__c = emailTemplateName;
            PC_Database.ins(eLetter2, false);

            //Create engagement program eLetter
            PC_Engagement_Program_Eletter__c engagementProgramEletter = new PC_Engagement_Program_Eletter__c();
            engagementProgramEletter = PC_Test_Setup.createEngagementProgramEletter(engProgram.Id,eLetter.Id,userMail);
            PC_Database.ins(engagementProgramEletter, false);

            //Create System Settings
            PC_System_Settings__c cSetting = new PC_System_Settings__c();
            cSetting.PC_eLetter_Sender_Class__c = senderClassName;
            PC_Database.ins(cSetting);
        }
    }
    @isTest static void testGetEmailAddressAndTemplateDetails() {
        Test.StartTest();
        PC_AdverseEvent__c adverseEvent = new PC_AdverseEvent__c();
        adverseEvent = [SELECT Id FROM PC_AdverseEvent__c LIMIT 1];
        PC_SendAdverseEventEmailController.EmailAddressAndTemplatesWrapper emailAddressAndTemplatesWrapper = new PC_SendAdverseEventEmailController.EmailAddressAndTemplatesWrapper();
        emailAddressAndTemplatesWrapper = PC_SendAdverseEventEmailController.getEmailAddressAndTemplateDetails(adverseEvent.Id);
        system.assertNotEquals(emailAddressAndTemplatesWrapper,null);

        PC_AdverseEvent2__c adverseEvent2 = new PC_AdverseEvent2__c();
        adverseEvent2 = [SELECT Id FROM PC_AdverseEvent2__c LIMIT 1];
        PC_SendAdverseEventEmailController.EmailAddressAndTemplatesWrapper emailAddressAndTemplatesWrapper2 = new PC_SendAdverseEventEmailController.EmailAddressAndTemplatesWrapper();
        emailAddressAndTemplatesWrapper2 = PC_SendAdverseEventEmailController.getEmailAddressAndTemplateDetails(adverseEvent2.Id);
        system.assertNotEquals(emailAddressAndTemplatesWrapper2,null);
        Test.StopTest();
    }
    @isTest static void testSendAdverseEventMail() {
        Test.StartTest();
        PC_AdverseEvent__c adverseEvent = new PC_AdverseEvent__c();
        adverseEvent = [SELECT Id FROM PC_AdverseEvent__c LIMIT 1];
        PC_eLetter__c eLetter = new PC_eLetter__c();
        eLetter = [SELECT Id FROM PC_eLetter__c WHERE PC_Source_Object__c =: adverseEventName LIMIT 1];
        List<String> addresses = new List<String>();
        addresses.add(userMail);
        PC_SendAdverseEventEmailController.sendAdverseEventMail(addresses,String.valueOf(eLetter.Id),adverseEvent.Id);
        Test.StopTest();
    }
}