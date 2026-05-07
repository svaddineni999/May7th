/*********************************************************************************
Test Class Name : PC_Test_Eletter2Controller
Description     : Test class for PC_eLetter2Controller
Created By      : Satheesh Kumar
Created Date    : July 08, 2020
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
----------------------------------------------------------------------------------
Satheesh Kumar            08-Jul-2020          Initial Version
Satheesh Kumar            07-Dec-2020          [PC-7096] Added logic to cover task and document reply eletter workflow
Hitha Avalakki            10-Nov-2021          [PC-8319] Added logic to cover consent model changes for eletter
Hitha Avalakki            18-Nov-2021          [PC-8319] Edited method callout parameter for getEletterInfo()
*********************************************************************************/
@isTest
public class PC_Test_Eletter2Controller {
    private static Id patientRecordTypeId;
    private static Id physicianRecordTypeId;
    private static Case programCase;
    private static User eletterAdminUser1;
    private static Account physician;
    private static String eletterContextREPLY = PC_Constants.PC_ELETTER_CONTEXT_REPLY;
    private static String eletterContextNEW = PC_Constants.PC_ELETTER_CONTEXT_NEW;
    private static PC_eLetter__c caseEletter;
    private static PC_eLetter__c interactionEletter;
    private static PC_eLetter__c caseEletterWithNoTargetRecipients;

    //testing data setup for all methods in this class
    @testSetup static void setupTestData() {
        // Create User Record
        User adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'eletteruser1@test.com', 'user1');
        PC_Database.ins(adminUser);

        User carecoordinator = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'eletteruser101@test.com', 'user2');
        PC_Database.ins(carecoordinator);

        User reimbursementSpecialist = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'eletteruser103@test.com', 'user3');
        PC_Database.ins(reimbursementSpecialist);

        // create a record for the custom setting
        PC_System_Settings__c cSetting = new PC_System_Settings__c();
        cSetting.PC_eLetter_Sender_Class__c = 'PC_Test_MockELetterSender';
        PC_Database.ins(cSetting);

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
        PC_eLetter__c caseEletter = new PC_eLetter__c(
                Name = 'Patient Welcome Letter',
                PC_Object_Record_Types__c = 'Program',
                PC_Target_Recipients__c = 'HCO; Treating Physician; Care Coordinator; Reimbursement Specialist',
                PC_Send_to_User__c = true,
                PC_Category__c = 'Email;Fax',
                PC_Source_Object__c = 'Case',
                PC_Template_Name__c = 'Email_Template_Name',
                PC_Allow_Send_to_Patient__c=true
        );
        eLetterList.add(caseEletter);

        //Create eLetter with no target recipients
        PC_eLetter__c caseEletterWithNoTargetRecipients = new PC_eLetter__c(
                Name = 'Patient Welcome Letter Without TargetRecipients',
                PC_Object_Record_Types__c = 'Program',
                PC_Allow_Send_to_Patient__c = true,
                PC_Category__c = 'Email;Fax',
                PC_Source_Object__c = 'Case',
                PC_Template_Name__c = 'Email_Template_Name'
        );
        eLetterList.add(caseEletterWithNoTargetRecipients);

        PC_eLetter__c interactionEletter = new PC_eLetter__c(
                Name = 'ELetter for Interaction',
                PC_Source_Object__c = 'Interaction',
                PC_Target_Recipients__c = 'HCO; Treating Physician',
                PC_Send_to_User__c = false,
                PC_Category__c = 'Email;Fax',
                PC_Template_Name__c = 'Email_Template_Name'
        );
        eLetterList.add(interactionEletter);
        PC_eLetter__c programCovEletter = new PC_eLetter__c(
                Name = 'ELetter for Program Coverage',
                PC_Object_Record_Types__c = 'Private Coverage',
                PC_Target_Recipients__c = 'HCO; Treating Physician',
                PC_Send_to_User__c = false,
                PC_Category__c = 'Email;Fax',
                PC_Source_Object__c = 'Program Coverage',
                PC_Template_Name__c = 'Email_Template_Name'
        );
        eLetterList.add(programCovEletter);
        PC_Database.ins(eLetterList);

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
        programCase.PC_Care_Coordinator__c = carecoordinator.Id;
        programCase.PC_Reimbursment_Specialist__c = reimbursementSpecialist.Id;
        PC_Database.ins(programCase, false);

        //Create interaction Record
        PC_Interaction__c interactionRecord = PC_Test_Setup.newInteraction(programCase.Id);
        PC_Database.ins(interactionRecord);

        //Create Program Coverage
        PC_Program_Coverage__c progCoverageRecord = PC_Test_Setup.createProgramCoverage(programCase.Id);
        PC_Database.ins(progCoverageRecord);

        // Create Engagement Program Eletter for Case
        PC_Engagement_Program_Eletter__c caseEngagementProgEletter = new PC_Engagement_Program_Eletter__c();
        caseEngagementProgEletter.PC_eLetter__c = caseEletter.Id;
        caseEngagementProgEletter.PC_Engagement_Program__c = engagementProgram.Id;
        caseEngagementProgEletter.PC_PreConfiguredEmailRecipients__c = 'example@test.com,example2@test.com';
        PC_Database.ins(caseEngagementProgEletter);

        // Create Engagement Program Eletter for Interaction Record
        PC_Engagement_Program_Eletter__c interactionEngagementProgEletter = new PC_Engagement_Program_Eletter__c();
        interactionEngagementProgEletter.PC_eLetter__c = interactionEletter.Id;
        interactionEngagementProgEletter.PC_Engagement_Program__c = engagementProgram.Id;
        PC_Database.ins(interactionEngagementProgEletter);

        // Create Engagement Program Eletter for Program Coverage
        PC_Engagement_Program_Eletter__c progCovEngagementProgEletter = new PC_Engagement_Program_Eletter__c();
        progCovEngagementProgEletter.PC_eLetter__c = programCovEletter.Id;
        progCovEngagementProgEletter.PC_Engagement_Program__c = engagementProgram.Id;
        PC_Database.ins(progCovEngagementProgEletter);

        //Create inbound document record
        PC_Document__c inDocument = new PC_Document__c();
        inDocument.RecordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.DOCUMENT_OBJECT, PC_Constants.DOCUMENT_EMAIL_INBOUND_RECORD_TYPE);
        inDocument.PC_Document_Status__c = PC_Constants.DOCUMENT_STATUS_REVIEW_NEEDED;
        inDocument.PC_From_Name__c = 'Physician Name';
        inDocument.PC_From_Email_Address__c = 'testphy@test.com';
        inDocument.PC_Engagement_Program__c = engagementProgram.Id;
        PC_Database.ins(inDocument, false);

        PC_Document_Log__c docLogObj = new PC_Document_Log__c();
        docLogObj.PC_Document__c = inDocument.Id;
        docLogObj.PC_Program__c = programCase.Id;
        docLogObj.PC_Association_Type__c = 'Case: Program';
        docLogObj.PC_Association_Record_Name__c = programCase.CaseNumber;
        PC_Database.ins(docLogObj, false);

        // Create inbound task
        Task inboundTask = new Task();
        inboundTask.WhatId = programCase.Id;
        inboundTask.RecordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.PC_TASK, PC_Constants.PC_ELETTER);
        inboundTask.PC_Document__c = inDocument.Id;
        inboundTask.PC_Direction__c = PC_Constants.INBOUND;
        inboundTask.PC_Channel__c = PC_Constants.PC_TASK_CHANNEL_EMAIL;
        inboundTask.Description = 'InboundEmail';
        inboundTask.Subject = 'InboundEmail';
        inboundTask.ActivityDate = system.today();
        inboundTask.Status = PC_Constants.PC_STATUS_NOT_STARTED;
        inboundTask.OwnerId = UserInfo.getUserId();
        PC_Database.ins(inboundTask, false);

        //Create service for patient and other association roles
        PC_Service__c serviceRecord = PC_Test_Setup.createServiceRecordForPatientRole();
        serviceRecord.PC_CareTeamPermissionRequiredRoles__c = 'HCO;Treating Physician;Care Coordinator;Reimbursement Specialist';
        PC_Database.ins(serviceRecord);

        //Create engagement program service record
        PC_Engagement_Program_Service__c engagement_program_service = PC_Test_Setup.createEngagementProgramServiceRecord(serviceRecord.Id,caseEletter.Id,engagementProgram.Id);
        PC_Database.ins(engagement_program_service);

        //Create service record for Patient role
        PC_Service__c serviceRecordPat = PC_Test_Setup.createServiceRecordForPatientRole();
        PC_Database.ins(serviceRecordPat);

        //Create engagement program service record for service record
        PC_Engagement_Program_Service__c engagement_program_service_Pat = PC_Test_Setup.createEngagementProgramServiceRecord(serviceRecordPat.Id,caseEletter.Id,engagementProgram.Id);
        PC_Database.ins(engagement_program_service_Pat);

        //Create service record with no consent records
        PC_Service__c serviceRecordWithNoConsent= PC_Test_Setup.createServiceRecordForPatientRole();
        PC_Database.ins(serviceRecordWithNoConsent);

        //Create engagement program service record for service record with no consent records
        PC_Engagement_Program_Service__c engagementProgramServiceNoConsent = PC_Test_Setup.createEngagementProgramServiceRecord(serviceRecordWithNoConsent.Id,caseEletter.Id,engagementProgram.Id);
        PC_Database.ins(engagementProgramServiceNoConsent);

        //Create program service permission records
        PC_Program_Service_Permission__c patientPermissionRecordWithEarlierEndDate =  PC_Test_Setup.createProgramServicePermissionRecord(programCase.Id,serviceRecordPat.Id,true,null);
        patientPermissionRecordWithEarlierEndDate.PC_Start_Date__c = Date.today().addDays(-30);
        patientPermissionRecordWithEarlierEndDate.PC_End_Date__c = Date.today().addDays(20);
        PC_Database.ins(patientPermissionRecordWithEarlierEndDate);

        //Create program service permission records
        PC_Program_Service_Permission__c patientPermissionRecordWithLaterEndDate =  PC_Test_Setup.createProgramServicePermissionRecord(programCase.Id,serviceRecordPat.Id,true,null);
        patientPermissionRecordWithLaterEndDate.PC_Start_Date__c = Date.today().addDays(-20);
        patientPermissionRecordWithLaterEndDate.PC_End_Date__c = Date.today().addDays(30);
        PC_Database.ins(patientPermissionRecordWithLaterEndDate);

        //Create service records
        PC_Service__c serviceRecordWithNoPatientConsent = PC_Test_Setup.createServiceRecordForPatientRole();
        serviceRecordWithNoPatientConsent.PC_CareTeamPermissionRequiredRoles__c = 'HCO;Treating Physician';
        PC_Database.ins(serviceRecordWithNoPatientConsent);

        PC_Engagement_Program_Service__c engagement_program_service1 = PC_Test_Setup.createEngagementProgramServiceRecord(serviceRecordWithNoPatientConsent.Id,caseEletter.Id,engagementProgram.Id);
        PC_Database.ins(engagement_program_service1);

        List<PC_Association__c> associationsList1 = [SELECT Id,PC_Role__c,PC_AssociationStatus__c,PC_Account__c,PC_Associated_User__c FROM PC_Association__c WHERE PC_Program__c=:programCase.Id AND PC_AssociationStatus__c=:PC_Constants.STATUS_ACTIVE];

        List<PC_Program_Service_Permission__c> programServicePermissionRecords =  new List<PC_Program_Service_Permission__c>();

        //Create program service permission records for non patient roles
        for(PC_Association__c association: associationsList1){
            if(association.PC_Role__c == PC_Constants.ROLE_TREATING_PHYSICIAN) {
                PC_Program_Service_Permission__c treatingPhyPermissionRecord1 = PC_Test_Setup.createProgramServicePermissionRecord(programCase.Id,serviceRecordWithNoPatientConsent.Id,false,association.Id);
                programServicePermissionRecords.add(treatingPhyPermissionRecord1);

                PC_Program_Service_Permission__c treatingPhyPermissionRecord2 = PC_Test_Setup.createProgramServicePermissionRecord(programCase.Id,serviceRecord.Id,false,association.Id);
                programServicePermissionRecords.add(treatingPhyPermissionRecord2);
            }
            if(association.PC_Role__c == PC_Constants.PC_ROLE_CARE_COORDINATOR){
                PC_Program_Service_Permission__c ccPhyPermissionRecord = PC_Test_Setup.createProgramServicePermissionRecord(programCase.Id,serviceRecord.Id,false,association.Id);
                ccPhyPermissionRecord.PC_CareTeamMemberResponse__c='Declined';
                programServicePermissionRecords.add(ccPhyPermissionRecord);
            }
            if(association.PC_Role__c == PC_Constants.PC_ROLE_REIMBURSEMENT_SPECIALIST){
                PC_Program_Service_Permission__c reimbursementSpecPermissionRecord = PC_Test_Setup.createProgramServicePermissionRecord(programCase.Id,serviceRecord.Id,false,association.Id);
                reimbursementSpecPermissionRecord.PC_End_Date__c = Date.today().addDays(-10);
                programServicePermissionRecords.add(reimbursementSpecPermissionRecord);
            }
        }

        PC_Database.ins(programServicePermissionRecords);

        PC_Program_Service_Permission__c patientPermissionRecord =PC_Test_Setup.createProgramServicePermissionRecord(programCase.Id,serviceRecord.Id,true,null);
        PC_Database.ins(patientPermissionRecord);
    }

    @isTest private static void getTestData() {
        //grab the case that was created in the setupTestData method
        patientRecordTypeId = PC_System.recordTypeId(PC_Constants.PC_ACCOUNT, PC_Constants.PATIENT_RECORD_TYPE);
        programCase = [SELECT Id FROM Case WHERE Account.RecordTypeId = :patientRecordTypeId LIMIT 1];
        // check if program Case is fetched
        system.assertNotEquals(programCase.Id, null);

        //Physician
        physicianRecordTypeId = PC_System.recordTypeId(PC_Constants.PC_ACCOUNT, PC_Constants.PHYSICIAN_RECORD_TYPE);
        physician = [Select Id, PC_Email__c from Account where RecordTypeId = :physicianRecordTypeId LIMIT 1];

        //get the User1 record that was created in the setupTestData method
        eletterAdminUser1 = [select Id from User where Username = 'eletteruser1@test.com' LIMIT 1];

        //Fetching Case Eletter
        caseEletter = [Select Id, Name from PC_eLetter__c where Name = 'Patient Welcome Letter' LIMIT 1];
        system.assertNotEquals(caseEletter.Id, null);

        //Fetching Case Eletter With NoTargetRecipients
        caseEletterWithNoTargetRecipients = [Select Id, Name from PC_eLetter__c where Name = 'Patient Welcome Letter Without TargetRecipients' LIMIT 1];
        system.assertNotEquals(caseEletterWithNoTargetRecipients.Id, null);


        //Fetching Interaction Eletter
        interactionEletter = [Select Id, Name from PC_eLetter__c where Name = 'ELetter for Interaction' LIMIT 1];
        system.assertNotEquals(interactionEletter.Id, null);
    }

    /*********************************************************************************
    Method Name    : testGetEletterTemplates
    Description    : Test getEletterTemplates method
    Return Type    : void
    Parameter      : None
    *********************************************************************************/
    @isTest static void testGetEletterTemplates() {
        try {
            getTestData();
            system.runAs(eletterAdminUser1) {
                Test.StartTest();
                List<String> emailCategoryList = new List<String>{
                        'Email'
                };
                List<String> faxCategoryList = new List<String>{
                        'Fax'
                };
                // Case
                System.assertEquals(1, (PC_eLetter2Controller.getEletterTemplates(programCase.Id, emailCategoryList, faxCategoryList)).eletterTemplateList.size());
                System.assertEquals(1, (PC_eLetter2Controller.getEletterTemplates(programCase.Id, emailCategoryList, faxCategoryList)).eletterFromAddressList.size());

                // Interaction Record
                PC_Interaction__c interactionRecord = [SELECT Id, PC_Patient_Program__c FROM PC_Interaction__c WHERE PC_Patient_Program__c = :programCase.Id LIMIT 1];
                if (String.isBlank(PC_Utility.getRecordTypeNameByRecordId(interactionRecord.Id))) {
                    System.assertEquals(1, (PC_eLetter2Controller.getEletterTemplates(interactionRecord.Id, emailCategoryList, faxCategoryList)).eletterTemplateList.size());
                }

                // Program Coverage
                PC_Program_Coverage__c progCoverageRecord = [SELECT Id, PC_Program__c FROM PC_Program_Coverage__c WHERE PC_Program__c = :programCase.Id LIMIT 1];
                Exception capturedException;
                try {
                    PC_eLetter2Controller.getEletterTemplates(progCoverageRecord.Id, emailCategoryList, faxCategoryList);
                } catch (Exception e) {
                    capturedException = e;
                    System.assertNotEquals(null, capturedException, 'Exception should be thrown');
                }

                // Document Record
                PC_Document_Log__c docLogObj = [SELECT Id, PC_Document__c, PC_Program__c FROM PC_Document_Log__c WHERE PC_Program__c = :programCase.Id LIMIT 1];
                system.assertNotEquals(docLogObj.Id, null);
                System.assertEquals(1, (PC_eLetter2Controller.getEletterTemplates(docLogObj.PC_Document__c, emailCategoryList, faxCategoryList)).eletterFromAddressList.size());

                // Task Record
                Task taskObj = [SELECT Id, WhatId FROM Task WHERE WhatId = :programCase.Id LIMIT 1];
                system.assertNotEquals(taskObj.Id, null);
                System.assertEquals(1, (PC_eLetter2Controller.getEletterTemplates(taskObj.Id, emailCategoryList, faxCategoryList)).eletterFromAddressList.size());

                Test.StopTest();
            }
        } catch (Exception ex) {
            system.debug('exception in testSendLetter >>' + ex.getMessage());
            system.debug('exception in testSendLetter getStackTraceString >>' + ex.getStackTraceString());
            system.assert(false, ex.getMessage());
        }
    }

    /*********************************************************************************
    Method Name    : testGetEletterInfo
    Description    : Test getEletterInfo method
    Return Type    : void
    Parameter      : None
    *********************************************************************************/
    @isTest static void testGetEletterInfoCase() {
        try {
            getTestData();
            system.runAs(eletterAdminUser1) {
                Test.StartTest();
                //Case
                PC_eLetter2Controller.EletterInfo caseELetterInfo = PC_eLetter2Controller.getEletterInfo(caseEletter.Id, programCase.Id, eletterContextNEW,false);
                caseELetterInfo.eLetterRecipients[0].sendEmail = true;
                caseELetterInfo.eLetterRecipients[0].sendFax = true;

                for(PC_eLetter_Recipient eLetterRecipient: caseELetterInfo.eLetterRecipients){
                    if(!String.isBlank(eLetterRecipient.recipientRole)){
                        System.assert(eLetterRecipient.programServicePermissionRecordsList!=null && !eLetterRecipient.programServicePermissionRecordsList.isEmpty() && eLetterRecipient.programServicePermissionRecordsList.size()>=1);
                    }
                }

                String caseRecipientJSON = System.JSON.serialize(caseELetterInfo.eLetterRecipients);
                System.assertEquals(physician.PC_Email__c, caseELetterInfo.eLetterRecipients[0].recipient.email);

                //Document Reply
                PC_Document_Log__c docLogObj = [SELECT Id, PC_Document__c, PC_Program__c FROM PC_Document_Log__c WHERE PC_Program__c = :programCase.Id LIMIT 1];
                system.assertNotEquals(docLogObj.Id, null);
                String documentId = docLogObj.PC_Document__c;
                PC_eLetter2Controller.EletterInfo documentELetterInfo = PC_eLetter2Controller.getEletterInfo(caseEletter.Id, documentId, eletterContextREPLY,true);
                System.assertEquals(physician.PC_Email__c, documentELetterInfo.eLetterRecipients[0].recipient.email);


                // Test Case - SendOutboundDocuments - SentToMe - true
                PC_eLetter2Controller.SendLetterRequest eLetterRequest = new PC_eLetter2Controller.SendLetterRequest();
                PC_eLetter2Controller.FromAddress fromAddress = new PC_eLetter2Controller.FromAddress();
                fromAddress.name = UserInfo.getUserName();
                fromAddress.address = UserInfo.getUserEmail();
                fromAddress.fromId = UserInfo.getUserId();
                eLetterRequest.fromAddress = fromAddress;
                eLetterRequest.eletterId = caseEletter.Id;
                eLetterRequest.recordId = programCase.Id;
                eLetterRequest.sendToCurrentUser = true;
                eLetterRequest.subject = 'Test Subject';
                eLetterRequest.communicationMethod = PC_Constants.EMAIL;

                String returnMessage = PC_eLetter2Controller.sendOutboundDocuments(System.JSON.serialize(eLetterRequest), caseRecipientJSON);
                System.assertNotEquals(returnMessage, null);

                // Test Document Reply - SendOutboundDocuments - SentToMe - false,
                eLetterRequest.recordId = documentId;
                eLetterRequest.eletterId = caseEletter.Id;
                eLetterRequest.sendToCurrentUser = false;
                String returnMessage2 = PC_eLetter2Controller.sendOutboundDocuments(System.JSON.serialize(eLetterRequest), caseRecipientJSON);
                System.assertNotEquals(returnMessage2, null);

                Test.StopTest();
            }
        } catch (Exception ex) {
            system.debug('exception in testGetEletterInfoCase >>' + ex.getMessage());
            system.assert(false, ex.getMessage());
        }
    }

    /*********************************************************************************
    Method Name    : testGetEletterRecipientsWithNoTargetRecipients
    Description    : Test getEletterInfo method
    Return Type    : void
    Parameter      : None
    *********************************************************************************/
    @isTest static void testGetEletterRecipientsWithNoTargetRecipients() {
        try {
            getTestData();
            system.runAs(eletterAdminUser1) {
                Test.StartTest();
                //Case
                PC_eLetter2Controller.EletterInfo caseELetterInfo = PC_eLetter2Controller.getEletterInfo(caseEletterWithNoTargetRecipients.Id, programCase.Id, eletterContextNEW,true);
                System.debug(caseELetterInfo.eLetterRecipients.size());
                System.assertEquals(1, caseELetterInfo.eLetterRecipients.size());
            }
        } catch (Exception ex) {
            system.debug('exception in testGetEletterRecipientsWithNoTargetRecipients >>' + ex.getMessage());
            system.assert(false, ex.getMessage());
        }
    }

    /*********************************************************************************
    Method Name    : testGetEletterInfoProgramCoverage
    Description    : Test testGetEletterInfo method
    Return Type    : void
    Parameter      : None
    *********************************************************************************/
    @isTest static void testGetEletterInfoProgramCoverage() {
        try {
            getTestData();
            system.runAs(eletterAdminUser1) {
                Test.StartTest();
                PC_Program_Coverage__c progCoverageRecord = [SELECT Id, PC_Program__c FROM PC_Program_Coverage__c WHERE PC_Program__c = :programCase.Id LIMIT 1];
                PC_eLetter2Controller.getEletterInfo(caseEletter.Id, progCoverageRecord.Id, eletterContextNEW,true);
                Test.StopTest();
            }
        } catch (Exception ex) {
            system.debug('exception in testGetEletterInfoProgramCoverage >>' + ex.getMessage());
            system.assert(false, ex.getMessage());
        }
    }

    /*********************************************************************************
    Method Name    : testGetEletterInfoInteraction
    Description    : Test getEletterInfo method
    Return Type    : void
    Parameter      : None
    *********************************************************************************/
    @isTest static void testGetEletterInfoInteraction() {
        try {
            getTestData();
            system.runAs(eletterAdminUser1) {
                Test.StartTest();
                //Interaction
                PC_Interaction__c interactionRecord = [SELECT Id, PC_Patient_Program__c FROM PC_Interaction__c WHERE PC_Patient_Program__c = :programCase.Id LIMIT 1];
                PC_eLetter2Controller.EletterInfo interactionELetterInfo = PC_eLetter2Controller.getEletterInfo(interactionEletter.Id, interactionRecord.Id, eletterContextNEW,true);
                String interactionRecipientJSON = System.JSON.serialize(interactionELetterInfo.eLetterRecipients);

                System.assertEquals(physician.PC_Email__c, interactionELetterInfo.eLetterRecipients[0].recipient.email);

                Task taskObj = [SELECT Id, WhatId FROM Task WHERE WhatId = :programCase.Id LIMIT 1];
                system.assertNotEquals(taskObj.Id, null);
                // Test Case - SendOutboundDocuments - SentToMe - false, Task Reply
                PC_eLetter2Controller.SendLetterRequest eLetterRequest = new PC_eLetter2Controller.SendLetterRequest();
                eLetterRequest.recordId = taskObj.Id;
                eLetterRequest.eletterId = interactionEletter.Id;
                eLetterRequest.sendToCurrentUser = false;
                String returnMessage3 = PC_eLetter2Controller.sendOutboundDocuments(System.JSON.serialize(eLetterRequest), interactionRecipientJSON);
                System.assertNotEquals(returnMessage3, null);

                Test.StopTest();
            }
        } catch (Exception ex) {
            system.debug('exception in testGetEletterInfoInteraction >>' + ex.getMessage());
            system.assert(false, ex.getMessage());
        }
    }

    /*********************************************************************************
    Method Name    : testTaskReply
    Description    : Test getEletterInfo method
    Return Type    : void
	Parameter      : None
    *********************************************************************************/
    @isTest static void testTaskReply() {
        try {
            getTestData();
            system.runAs(eletterAdminUser1) {
                Test.StartTest();

                //Task Reply
                Task taskObj = [SELECT Id, WhatId FROM Task WHERE WhatId = :programCase.Id LIMIT 1];
                system.assertNotEquals(taskObj.Id, null);
                PC_eLetter2Controller.EletterInfo taskELetterInfo = PC_eLetter2Controller.getEletterInfo(caseEletter.Id, taskObj.Id, eletterContextREPLY,true);
                System.assertEquals(physician.PC_Email__c, taskELetterInfo.eLetterRecipients[0].recipient.email);

                Test.StopTest();
            }
        } catch (Exception ex) {
            system.debug('exception in testTaskReply >>' + ex.getMessage());
            system.assert(false, ex.getMessage());
        }
    }
}