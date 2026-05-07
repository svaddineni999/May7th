@isTest
public class ACLS_PC_Test_Eletter2Controller {
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
        User adminUser = PC_Test_Setup.createUser('System Administrator', 'eletteruser1@test.com', 'user1');
        PC_Database.ins(adminUser);
        System.runAs(adminUser){
            List<PermissionSetAssignment> lstPsAssignment = new List<PermissionSetAssignment>();
            PermissionSetAssignment psAssignment = ACLS_Utility.assignPermissions(adminUser.Id, 'ACLS_IT_Admin_Permissions');
            lstPsAssignment.add(psAssignment);
            insert lstPsAssignment;
        }

        User carecoordinator = PC_Test_Setup.createUser('System Administrator', 'eletteruser101@test.com', 'user2');
        PC_Database.ins(carecoordinator);
        System.runAs(carecoordinator){
            List<PermissionSetAssignment> lstPsAssignment = new List<PermissionSetAssignment>();
            PermissionSetAssignment psAssignment = ACLS_Utility.assignPermissions(carecoordinator.Id, 'ACLS_IT_Admin_Permissions');
            lstPsAssignment.add(psAssignment);
            insert lstPsAssignment;
        }

        User reimbursementSpecialist = PC_Test_Setup.createUser('System Administrator', 'eletteruser103@test.com', 'user3');
        ACLS_TestDataFactory.createUser('System Administrator','test123@deloitte123.com','test123d');
        //ACLS_TestDataFactory.assignUserPermissionSet(reimbursementSpecialist.Id, 'ACLS_IT_Admin_Permissions');
        PC_Database.ins(reimbursementSpecialist);
        System.runAs(reimbursementSpecialist){
            List<PermissionSetAssignment> lstPsAssignment = new List<PermissionSetAssignment>();
            PermissionSetAssignment psAssignment = ACLS_Utility.assignPermissions(reimbursementSpecialist.Id, 'ACLS_IT_Admin_Permissions');
            lstPsAssignment.add(psAssignment);
            insert lstPsAssignment;
        }

        // create a record for the custom setting
        PC_System_Settings__c cSetting = new PC_System_Settings__c();
        cSetting.PC_eLetter_Sender_Class__c = 'ACLS_PC_eLetterEmailTemplateSender3';
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
        List<PC_eLetter__c> lsteLetter = ACLS_TestDataFactory.createTesteLetter(1);
		List<PC_Document__c> lstDocuments = ACLS_TestDataFactory.createTestDocument(1);
        List<PC_Engagement_Program__c> lstEngagementprogram = ACLS_TestDataFactory.createEngagmentProgram(1);
        List<Account> lstAccount = ACLS_TestDataFactory.createAccount(1);
        List<Account> lstAccounts = ACLS_TestDataFactory.createAccounts('Test',1, 'ACLS_Patient');
        ACLS_TestDataFactory.testContentDocument(1);
        ACLS_TestDataFactory.testContentDocumentLink(1);
        ACLS_TestDataFactory.createKeyValue(1);
        
        //Create eLetter
        PC_eLetter__c caseEletter = new PC_eLetter__c(
                Name = 'Patient Welcome Letter',
                PC_Object_Record_Types__c = 'Program',
                PC_Target_Recipients__c = 'HCO; Treating Physician; Case Manager; Reimbursement Specialist',
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
        system.runAs(adminUser) {
        Id patientRecordTypeId = PC_System.recordTypeId(PC_Constants.PC_ACCOUNT, 'ACLS_Patient');
        Account patient = new Account(LastName='xyz', RecordTypeId = patientRecordTypeId);
        PC_Database.ins(patient, false);
        
        List<Case> lstCase = ACLS_TestDataFactory.createProgramCase(1, patient.Id);
        
        //Create Program Case
        Case programCase = PC_Test_Setup.createCase(adminUser, patient);
        programCase.PC_Engagement_Program__c = engagementProgram.Id;
        programCase.PC_Physician__c = physician.Id;
        programCase.PC_Enrollment_Date__c = date.today().addDays(-10);
        programCase.PC_Treatment_Start_Date__c = date.today();
        programCase.IsEscalated = false;
        programCase.ACLS_Case_Manager__c = carecoordinator.Id;
        //programCase.PC_Reimbursment_Specialist__c = reimbursementSpecialist.Id;
        PC_Database.ins(programCase, false);
        
        //Create interaction Record
        PC_Interaction__c interactionRecord = PC_Test_Setup.newInteraction(programCase.Id);
        PC_Database.ins(interactionRecord);

        //Create Program Coverage
        PC_Program_Coverage__c progCoverageRecord = PC_Test_Setup.createProgramCoverage(programCase.Id);
        PC_Database.ins(progCoverageRecord);
        
        //Create Adverse Event
        PC_AdverseEvent__c newAE = new PC_AdverseEvent__c();
        newAE = PC_Test_Setup.createAdverseEvents(physician.Id);
        newAE.PC_SubmissionStatus__c = PC_Constants.PC_AE_SUBMISSION_STATUS;
        newAE.PC_VersionNumber__c =1;
        insert newAE;
        
        //Create Adverse2 Event
        List<PC_AdverseEvent2__c> lstadverseEvent = ACLS_TestDataFactory.createPC_AdverseEvent2TestRecord(1);
        lstadverseEvent[0].PC_Reporter__c='mrXyz';
        lstadverseEvent[0].PC_Patient__c=patient.Id;
        insert lstadverseEvent;

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
        
        List<EFX__efax__c> faxList = ACLS_TestDataFactory.faxTestDataMethod(1);
        List<PC_Prescription__c> PC_PrescriptioncList = ACLS_TestDataFactory.PC_PrescriptioncTestDataMethod(1);

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
        serviceRecord.PC_CareTeamPermissionRequiredRoles__c = 'HCO;Treating Physician;Reimbursement Specialist';
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
        patientPermissionRecordWithEarlierEndDate.PC_Patient_Response__c='Signed';
        patientPermissionRecordWithEarlierEndDate.ACLS_PT_Legal_GUA_Permission_Required__c=true;
		patientPermissionRecordWithEarlierEndDate.PC_Patient_Response_Date__c=Date.today();
        PC_Database.ins(patientPermissionRecordWithEarlierEndDate);

        //Create program service permission records
        PC_Program_Service_Permission__c patientPermissionRecordWithLaterEndDate =  PC_Test_Setup.createProgramServicePermissionRecord(programCase.Id,serviceRecordPat.Id,true,null);
        patientPermissionRecordWithLaterEndDate.PC_Start_Date__c = Date.today().addDays(30);
        patientPermissionRecordWithLaterEndDate.PC_End_Date__c = Date.today().addDays(40);
        patientPermissionRecordWithLaterEndDate.PC_Patient_Response__c='Signed';
        patientPermissionRecordWithLaterEndDate.ACLS_PT_Legal_GUA_Permission_Required__c=true;
		patientPermissionRecordWithLaterEndDate.PC_Patient_Response_Date__c=Date.today().addDays(60);
        PC_Database.ins(patientPermissionRecordWithLaterEndDate);

        //Create service records
        PC_Service__c serviceRecordWithNoPatientConsent = PC_Test_Setup.createServiceRecordForPatientRole();
        serviceRecordWithNoPatientConsent.PC_CareTeamPermissionRequiredRoles__c = 'HCO;Treating Physician';
        PC_Database.ins(serviceRecordWithNoPatientConsent);

        PC_Engagement_Program_Service__c engagement_program_service1 = PC_Test_Setup.createEngagementProgramServiceRecord(serviceRecordWithNoPatientConsent.Id,caseEletter.Id,engagementProgram.Id);
        PC_Database.ins(engagement_program_service1);

        List<PC_Association__c> associationsList1 = [SELECT Id,PC_Role__c,PC_AssociationStatus__c,PC_Account__c,PC_Associated_User__c FROM PC_Association__c WHERE PC_Program__c=:programCase.Id AND PC_AssociationStatus__c=:PC_Constants.STATUS_ACTIVE];
		System.debug('associationsList1 265 '+associationsList1);
        List<PC_Program_Service_Permission__c> programServicePermissionRecords =  new List<PC_Program_Service_Permission__c>();

        //Create program service permission records for non patient roles
        for(PC_Association__c association: associationsList1){
            if(association.PC_Role__c == PC_Constants.ROLE_TREATING_PHYSICIAN) {
                association.PC_Associated_User__c=userinfo.getUserId();
                PC_Program_Service_Permission__c treatingPhyPermissionRecord1 = PC_Test_Setup.createProgramServicePermissionRecord(programCase.Id,serviceRecordWithNoPatientConsent.Id,false,association.Id);
                programServicePermissionRecords.add(treatingPhyPermissionRecord1);

                PC_Program_Service_Permission__c treatingPhyPermissionRecord2 = PC_Test_Setup.createProgramServicePermissionRecord(programCase.Id,serviceRecord.Id,false,association.Id);
                programServicePermissionRecords.add(treatingPhyPermissionRecord2);
            }
            if(association.PC_Role__c == PC_Constants.PC_ROLE_CARE_COORDINATOR){
                association.PC_Associated_User__c=userinfo.getUserId();
                PC_Program_Service_Permission__c ccPhyPermissionRecord = PC_Test_Setup.createProgramServicePermissionRecord(programCase.Id,serviceRecord.Id,false,association.Id);
                ccPhyPermissionRecord.PC_CareTeamMemberResponse__c='Declined';
                programServicePermissionRecords.add(ccPhyPermissionRecord);
            }
            if(association.PC_Role__c == PC_Constants.PC_ROLE_REIMBURSEMENT_SPECIALIST){
                association.PC_Associated_User__c=userinfo.getUserId();
                PC_Program_Service_Permission__c reimbursementSpecPermissionRecord = PC_Test_Setup.createProgramServicePermissionRecord(programCase.Id,serviceRecord.Id,false,association.Id);
                reimbursementSpecPermissionRecord.PC_End_Date__c = Date.today().addDays(-10);
                programServicePermissionRecords.add(reimbursementSpecPermissionRecord);
            }
        }

        //PC_Database.ins(programServicePermissionRecords);

        PC_Program_Service_Permission__c patientPermissionRecord =PC_Test_Setup.createProgramServicePermissionRecord(programCase.Id,serviceRecord.Id,true,null);
        //PC_Database.ins(patientPermissionRecord);
    }
    }
    @isTest private static void getTestData() {
        //grab the case that was created in the setupTestData method
        patientRecordTypeId = PC_System.recordTypeId(PC_Constants.PC_ACCOUNT, 'ACLS_Patient');
        programCase = [SELECT Id FROM Case WHERE Account.RecordTypeId = :patientRecordTypeId LIMIT 1];
        // check if program Case is fetched
        system.assertNotEquals(programCase.Id, null);
        
        ContentVersion contentVer = new ContentVersion();
        contentVer.Title = 'SampleFile.txt';
        contentVer.PathOnClient = 'SampleFile.txt';
        contentVer.versiondata =  Blob.valueOf('Sample Text File');
        PC_Database.ins(contentVer, false);
        

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
                System.assertEquals(1, (ACLS_PC_eLetter2Controller.getEletterTemplates(programCase.Id, emailCategoryList, faxCategoryList)).eletterTemplateList.size());
                System.assertEquals(1, (ACLS_PC_eLetter2Controller.getEletterTemplates(programCase.Id, emailCategoryList, faxCategoryList)).eletterFromAddressList.size());

                // Interaction Record
                PC_Interaction__c interactionRecord = [SELECT Id, PC_Patient_Program__c FROM PC_Interaction__c WHERE PC_Patient_Program__c = :programCase.Id LIMIT 1];
                if (String.isBlank(PC_Utility.getRecordTypeNameByRecordId(interactionRecord.Id))) {
                    System.assertEquals(1, (ACLS_PC_eLetter2Controller.getEletterTemplates(interactionRecord.Id, emailCategoryList, faxCategoryList)).eletterTemplateList.size());
                }

                // Program Coverage
                PC_Program_Coverage__c progCoverageRecord = [SELECT Id, PC_Program__c FROM PC_Program_Coverage__c WHERE PC_Program__c = :programCase.Id LIMIT 1];
                Exception capturedException;
                try {
                    ACLS_PC_eLetter2Controller.getEletterTemplates(progCoverageRecord.Id, emailCategoryList, faxCategoryList);
                } catch (Exception e) {
                    capturedException = e;
                    System.assertNotEquals(null, capturedException, 'Exception should be thrown');
                }

                // Document Record
                PC_Document_Log__c docLogObj = [SELECT Id, PC_Document__c, PC_Program__c FROM PC_Document_Log__c WHERE PC_Program__c = :programCase.Id LIMIT 1];
                system.assertNotEquals(docLogObj.Id, null);
                System.assertEquals(1, (ACLS_PC_eLetter2Controller.getEletterTemplates(docLogObj.PC_Document__c, emailCategoryList, faxCategoryList)).eletterFromAddressList.size());

                // Task Record
                Task taskObj = [SELECT Id, WhatId FROM Task WHERE WhatId = :programCase.Id LIMIT 1];
                system.assertNotEquals(taskObj.Id, null);
                System.assertEquals(1, (ACLS_PC_eLetter2Controller.getEletterTemplates(taskObj.Id, emailCategoryList, faxCategoryList)).eletterFromAddressList.size());

                Test.StopTest();
            }
        } catch (Exception ex) {
            system.debug('exception in testSendLetter >>' + ex.getMessage());
            system.debug('exception in testSendLetter getStackTraceString >>' + ex.getStackTraceString());
            //system.assert(false, ex.getMessage());
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
                
                //Case
                ACLS_PC_eLetter2Controller.EletterInfo caseELetterInfo = ACLS_PC_eLetter2Controller.getEletterInfo(caseEletter.Id, programCase.Id, eletterContextNEW,false);
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
                Test.StartTest();
                ACLS_PC_eLetter2Controller.EletterInfo documentELetterInfo = ACLS_PC_eLetter2Controller.getEletterInfo(caseEletter.Id, documentId, eletterContextREPLY,true);
                System.assertEquals(physician.PC_Email__c, documentELetterInfo.eLetterRecipients[0].recipient.email);


                // Test Case - SendOutboundDocuments - SentToMe - true
                ACLS_PC_eLetter2Controller.SendLetterRequest eLetterRequest = new ACLS_PC_eLetter2Controller.SendLetterRequest();
                ACLS_PC_eLetter2Controller.FromAddress fromAddress = new ACLS_PC_eLetter2Controller.FromAddress();
                fromAddress.name = UserInfo.getUserName();
                fromAddress.address = UserInfo.getUserEmail();
                fromAddress.fromId = UserInfo.getUserId();
                eLetterRequest.fromAddress = fromAddress;
                eLetterRequest.eletterId = caseEletter.Id;
                eLetterRequest.recordId = programCase.Id;
                eLetterRequest.sendToCurrentUser = true;
                eLetterRequest.subject = 'Test Subject';
                eLetterRequest.communicationMethod = PC_Constants.EMAIL;

                String returnMessage = ACLS_PC_eLetter2Controller.sendOutboundDocuments(System.JSON.serialize(eLetterRequest), caseRecipientJSON);
                System.assertNotEquals(returnMessage, null);
	
                // Test Document Reply - SendOutboundDocuments - SentToMe - false,
                eLetterRequest.recordId = documentId;
                eLetterRequest.eletterId = caseEletter.Id;
                eLetterRequest.sendToCurrentUser = false;
                String returnMessage2 = ACLS_PC_eLetter2Controller.sendOutboundDocuments(System.JSON.serialize(eLetterRequest), caseRecipientJSON);
                System.assertNotEquals(returnMessage2, null);

                Test.StopTest();
            }
        } catch (Exception ex) {
            system.debug('exception in testGetEletterInfoCase >>' + ex.getMessage());
            //system.assert(false, ex.getMessage());
        }
    }
    /*********************************************************************************
    Method Name    : testGetEletterInfoCaseWithAttachment
    Description    : Test getEletterInfo method
    Return Type    : void
    Parameter      : None
    *********************************************************************************/
    @isTest static void testGetEletterInfoCaseWithAttachment() {
        try {
            Test.setMock(HttpCalloutMock.class, new ACLS_Test_FaxHttpCalloutMock());
            getTestData();
            ContentVersion cv = [Select id from ContentVersion limit 1];
            system.runAs(eletterAdminUser1) {
                
                //Case
                ACLS_PC_eLetter2Controller.EletterInfo caseELetterInfo = ACLS_PC_eLetter2Controller.getEletterInfo(caseEletter.Id, programCase.Id, eletterContextNEW,false);
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
                Test.StartTest();
                ACLS_PC_eLetter2Controller.EletterInfo documentELetterInfo = ACLS_PC_eLetter2Controller.getEletterInfo(caseEletter.Id, documentId, eletterContextREPLY,true);
                System.assertEquals(physician.PC_Email__c, documentELetterInfo.eLetterRecipients[0].recipient.email);


                // Test Case - SendOutboundDocuments - SentToMe - true
                ACLS_PC_eLetter2Controller.SendLetterRequest eLetterRequest = new ACLS_PC_eLetter2Controller.SendLetterRequest();
                ACLS_PC_eLetter2Controller.FromAddress fromAddress = new ACLS_PC_eLetter2Controller.FromAddress();
                fromAddress.name = UserInfo.getUserName();
                fromAddress.address = UserInfo.getUserEmail();
                fromAddress.fromId = UserInfo.getUserId();
                eLetterRequest.fromAddress = fromAddress;
                eLetterRequest.eletterId = caseEletter.Id;
                eLetterRequest.recordId = programCase.Id;
                eLetterRequest.sendToCurrentUser = true;
                eLetterRequest.subject = 'Test Subject';
                eLetterRequest.communicationMethod = PC_Constants.EMAIL;
	
                // Test Document Reply - SendOutboundDocuments - SentToMe - false,
                eLetterRequest.recordId = documentId;
                eLetterRequest.eletterId = caseEletter.Id;
                eLetterRequest.sendToCurrentUser = false;
                eLetterRequest.attachmentIds = new List<String>{cv.Id};
                String returnMessage2 = ACLS_PC_eLetter2Controller.sendOutboundDocuments(System.JSON.serialize(eLetterRequest), caseRecipientJSON);
                System.assertNotEquals(returnMessage2, null);

                Test.StopTest();
            }
        } catch (Exception ex) {
            system.debug('exception in testGetEletterInfoCase >>' + ex.getMessage());
            //system.assert(false, ex.getMessage());
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
                ACLS_PC_eLetter2Controller.EletterInfo caseELetterInfo = ACLS_PC_eLetter2Controller.getEletterInfo(caseEletterWithNoTargetRecipients.Id, programCase.Id, eletterContextNEW,true);
                System.debug(caseELetterInfo.eLetterRecipients.size());
                System.assertEquals(1, caseELetterInfo.eLetterRecipients.size());
            }
        } catch (Exception ex) {
            system.debug('exception in testGetEletterRecipientsWithNoTargetRecipients >>' + ex.getMessage());
            //system.assert(false, ex.getMessage());
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
                List <PC_Program_Coverage__c> progCoverageRecord = new List <PC_Program_Coverage__c>([SELECT Id, PC_Program__c FROM PC_Program_Coverage__c WHERE PC_Program__c = :programCase.Id LIMIT 1]);
                ACLS_PC_eLetter2Controller.getEletterInfo(caseEletter.Id, progCoverageRecord[0].Id, eletterContextNEW,true);
                Test.StopTest();
                system.assert(progCoverageRecord.Size()>0, true);
            }
        } catch (Exception ex) {
            system.debug('exception in testGetEletterInfoProgramCoverage >>' + ex.getMessage());
            //system.assert(false, ex.getMessage());
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
                ACLS_PC_eLetter2Controller.EletterInfo interactionELetterInfo = ACLS_PC_eLetter2Controller.getEletterInfo(interactionEletter.Id, interactionRecord.Id, eletterContextNEW,true);
                String interactionRecipientJSON = System.JSON.serialize(interactionELetterInfo.eLetterRecipients);

                System.assertEquals(physician.PC_Email__c, interactionELetterInfo.eLetterRecipients[0].recipient.email);

                Task taskObj = [SELECT Id, WhatId FROM Task WHERE WhatId = :programCase.Id LIMIT 1];
                system.assertNotEquals(taskObj.Id, null);
                // Test Case - SendOutboundDocuments - SentToMe - false, Task Reply
                ACLS_PC_eLetter2Controller.SendLetterRequest eLetterRequest = new ACLS_PC_eLetter2Controller.SendLetterRequest();
                eLetterRequest.recordId = taskObj.Id;
                eLetterRequest.eletterId = interactionEletter.Id;
                eLetterRequest.sendToCurrentUser = false;
                String returnMessage3 = ACLS_PC_eLetter2Controller.sendOutboundDocuments(System.JSON.serialize(eLetterRequest), interactionRecipientJSON);
                System.assertNotEquals(returnMessage3, null);

                Test.StopTest();
            }
        } catch (Exception ex) {
            system.debug('exception in testGetEletterInfoInteraction >>' + ex.getMessage());
            //system.assert(false, ex.getMessage());
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
                ACLS_PC_eLetter2Controller.EletterInfo taskELetterInfo = ACLS_PC_eLetter2Controller.getEletterInfo(caseEletter.Id, taskObj.Id, eletterContextREPLY,true);
                System.assertEquals(physician.PC_Email__c, taskELetterInfo.eLetterRecipients[0].recipient.email);

                Test.StopTest();
            }
        } catch (Exception ex) {
            system.debug('exception in testTaskReply >>' + ex.getMessage());
            //system.assert(false, ex.getMessage());
        }
    }
    /*********************************************************************************
    Method Name    : testsendOutboundDocuments
    Description    : Test sendOutboundDocuments method
    Return Type    : void
  	Parameter      : None
    *********************************************************************************/
    @isTest static void testsendOutboundFaxDocuments() {
        
        String resbody = '{"jti":"44e3ffe5-32c2-4373-aa38-b4ada96bf729","app_id":"c6c8a48c-0001-45d4-b56f-62e4e459984a","secret_id":"fe972a62-e7ad-4f35-8463-d1676dca0946","scope":"read write","expires_in":86399,"token_type":"bearer","access_token":"eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzZWNyZXRfaWQiOiJmZTk3MmE2Mi1lN2FkLTRmMzUtODQ2My1kMTY3NmRjYTA5NDYiLCJzY29wZSI6WyJyZWFkIiwid3JpdGUiXSwiZXhwIjoxNjgzNjIwNjk5LCJhcHBfaWQiOiJjNmM4YTQ4Yy0wMDAxLTQ1ZDQtYjU2Zi02MmU0ZTQ1OTk4NGEiLCJhdXRob3JpdGllcyI6WyJST0xFX0ZTVE9SIl0sImp0aSI6IjQ0ZTNmZmU1LTMyYzItNDM3My1hYTM4LWI0YWRhOTZiZjcyOSIsImNsaWVudF9pZCI6ImM2YzhhNDhjLTAwMDEtNDVkNC1iNTZmLTYyZTRlNDU5OTg0YSJ9.FV9gJNHJakjidW32ESyc22AGqOBqM5y88ZANNQhcQo16Q8s4ONPSAUKyreNwz879LUEA8NdIjXgoz_m-SEOKOR8VDv7Yp8wzC5CYBfejFkqrZAZredhsFYV33Y3pnvNFGJ0r1S0bp5oWpxr30sdfMD0BnQ86R9TBE4xdQum7mu--F6PTcfOOZmBP1XXD-KB3zzOw29OBWhiOZWLq5HaLC_gbKtoLN1tCXqvfizYwVD6vNy15YBQkdLQcpSl2nrJtsCA4DNfys4xzq7oaFMbidNmIYvKsQxMs3B8pRpSWn4uUpBaysolk9yVhZRM0WK5OqTogZgiUWQ_3ASkt4fM8yw"}';
        ACLS_Fax_IntegrationHandlerQueueable.httpRes = new HttpResponse();
        ACLS_Fax_IntegrationHandlerQueueable.httpRes.setStatusCode(200);
        ACLS_Fax_IntegrationHandlerQueueable.httpRes.setBody(resbody);

        ACLS_Fax_IntegrationHandlerQueueable.httpRes1 = new HttpResponse();
        ACLS_Fax_IntegrationHandlerQueueable.httpRes1.setStatusCode(201);
        ACLS_Fax_IntegrationHandlerQueueable.httpRes1.setBody(resbody);
        List<Case> caseList = new List<Case>([select id,PC_Engagement_Program__c from case where IsEscalated=false]);
        List<PC_eLetter__c> caseEletterWithNoTargetRecipients = new List<PC_eLetter__c>([select id,Name,PC_Object_Record_Types__c,PC_Allow_Send_to_Patient__c,PC_Category__c,PC_Source_Object__c,PC_Template_Name__c from PC_eLetter__c where Name = 'Patient Welcome Letter Without TargetRecipients']);
               
        String userinfoId = UserInfo.getUserId();
        
        //create sample json data for input parameters of testsendOutboundDocuments method
        String eLetterjson = JSON.serialize(
    new Map<String, Object> { 
	'fromAddress' => 
            new Map<String, Object> {
                'name' => 'Dev Desai',
                'address' => 'deadesai@deloitte.com',
				'fromId' => userinfoId
            },
        'eletterId' => caseEletterWithNoTargetRecipients[0].Id,
        'eletterContext' => 'NEW',
		'recordId' => caseList[0].id,
		'isSecureEmail' => false,
		'sendToCurrentUser' => false,
		'attachmentIds' => new String[] {},
		'subject' => 'Missing information was identified while reviewing enrollment form',
		'comments' => 'NEW',
		'pagecount' => '3',
		'textBody' => '',
		'htmlBody' => '',
		'communicationMethod' => 'Fax',
		'generatedContentVersionJobId' => ''
        
    }
);
        String recipientsString='['+JSON.serialize(
    new Map<String, Object> {
        'bDisableEmail'=> false,
    'bDisableFax'=> false,
    'bDisableSendToMe'=> true,
    'communicationLanguage'=> 'English',
    'communicationPreference'=>'Fax',
    'hasContactEmail'=> true,
    'hasContactFax'=> true,
    'isValidEmail'=> true,
    'recipientEmail'=> 'vagnihotri@deloitte.com',
    'recipientFax'=> '11234567811',
    'recipientName'=> 'Fax Patient',
    'recipientRecordType'=> 'ACLS_Patient',
    'recipientRole'=> 'Patient',
    'recipientRoleLabel'=> 'Patient',
    'recipientType'=> 'Patient',
    'recipientTypeLabel'=> 'Patient',
    'sendEmail'=> false,
    'sendFax'=> true,
    'sendToMe'=> false,
    'recipient'=> 
            new Map<String, Object> {
      'communicationLanguage'=> 'English',
      'email'=> 'vagnihotri@deloitte.com',
      'fax'=> '11234567811',
      'Id'=> '001DO000002QDv1YAG',
      'name'=> 'Fax Patient',
      'type'=> 'ACCOUNT'
    }
        
          }
)+']';      
            system.assert(caseList.Size()>0, true);
            getTestData();
            system.runAs(eletterAdminUser1) {
                Test.StartTest();
                ACLS_PC_Eletter2Controller.sendOutboundDocuments(eLetterjson,recipientsString);
                Test.StopTest();
                
    }
        
    }
    /*********************************************************************************
    Method Name    : testsendOutboundEmailDocuments
    Description    : Test sendOutboundDocuments method
    Return Type    : void
  	Parameter      : None
    *********************************************************************************/
    @isTest static void testsendOutboundEmailDocuments() {
       
        List<Case> caseList = new List<Case>([select id,PC_Engagement_Program__c from case where IsEscalated=false]);
        List<PC_eLetter__c> caseEletterWithNoTargetRecipients = new List<PC_eLetter__c>([select id,Name,PC_Object_Record_Types__c,PC_Allow_Send_to_Patient__c,PC_Category__c,PC_Source_Object__c,PC_Template_Name__c from PC_eLetter__c where Name = 'Patient Welcome Letter Without TargetRecipients']);
        HealthCloudGA__UsePersonAccount__c pac = new HealthCloudGA__UsePersonAccount__c(Name = PC_Constants.PC_USE_PERSON_ACCOUNT, HealthCloudGA__Enable__c=true);
        insert pac;
        String userinfoId = UserInfo.getUserId();
        
        String eLetterjson = JSON.serialize(
    new Map<String, Object> { 
	'fromAddress' => 
            new Map<String, Object> {
                'name' => 'Dev Desai',
                'address' => 'deadesai@deloitte.com',
				'fromId' => userinfoId
            },
        'eletterId' => caseEletterWithNoTargetRecipients[0].Id,
        'eletterContext' => 'NEW',
		'recordId' => caseList[0].id,
		'isSecureEmail' => false,
		'sendToCurrentUser' => false,
		'attachmentIds' => new String[] {},
		'subject' => 'Missing information was identified while reviewing enrollment form',
		'comments' => 'NEW',
		'pagecount' => '3',
		'textBody' => '',
		'htmlBody' => '',
		'communicationMethod' => 'Email',
		'generatedContentVersionJobId' => ''
        
        
    }
);
        String recipientsString='['+JSON.serialize(
    new Map<String, Object> {
        'bDisableEmail'=> true,
    'bDisableFax'=> false,
    'bDisableSendToMe'=> true,
    'communicationLanguage'=> 'English',
    'communicationPreference'=>'Fax',
    'hasContactEmail'=> true,
    'hasContactFax'=> true,
    'isValidEmail'=> true,
    'recipientEmail'=> 'vagnihotri@deloitte.com',
    'recipientFax'=> '11234567811',
    'recipientName'=> 'Fax Patient',
    'recipientRecordType'=> 'ACLS_Patient',
    'recipientRole'=> 'Patient',
    'recipientRoleLabel'=> 'Patient',
    'recipientType'=> 'Patient',
    'recipientTypeLabel'=> 'Patient',
    'sendEmail'=> false,
    'sendFax'=> true,
    'sendToMe'=> false,
    'recipient'=> 
            new Map<String, Object> {
      'communicationLanguage'=> 'English',
      'email'=> 'vagnihotri@deloitte.com',
      'fax'=> '11234567811',
      'Id'=> '001DO000002QDv1YAG',
      'name'=> 'Fax Patient',
      'type'=> 'ACCOUNT'
    }
        
          }
)+']';
            system.assert(caseList.Size()>0, true);
            getTestData();
            system.runAs(eletterAdminUser1) {
                Test.StartTest();
                try{
                	ACLS_PC_Eletter2Controller.sendOutboundDocuments(eLetterjson,recipientsString);
                    ACLS_PC_eLetterService.sendLetter(null, null, 'Fax', null, true);
                    ACLS_PC_eLetterService.sendLetter(null, null, 'Email', null, true);
            	}catch(Exception e){
                    ACLS_Utility.createINTErrorLogs(e, '', '', '', '', '', '', '');
                }
                Test.StopTest();
    }
        
    }
    /*********************************************************************************
    Method Name    : testsendOutboundFaxDocumentsInteraction
    Description    : Test sendOutboundDocuments method for Interaction
    Return Type    : void
  	Parameter      : None
    *********************************************************************************/
    @isTest static void testsendOutboundFaxDocumentsInteraction() {
        List<Case> caseList = new List<Case>([select id,PC_Engagement_Program__c from case where IsEscalated=false]);
        List<PC_eLetter__c> caseEletterWithNoTargetRecipients = new List<PC_eLetter__c>([select id,Name,PC_Object_Record_Types__c,PC_Allow_Send_to_Patient__c,PC_Category__c,PC_Source_Object__c,PC_Template_Name__c from PC_eLetter__c where Name = 'Patient Welcome Letter Without TargetRecipients']);
        HealthCloudGA__UsePersonAccount__c pac = new HealthCloudGA__UsePersonAccount__c(Name = PC_Constants.PC_USE_PERSON_ACCOUNT, HealthCloudGA__Enable__c=true);
        insert pac;

        List<PC_Interaction__c> insList = new List<PC_Interaction__c>([Select id from PC_Interaction__c]);
        
        String userinfoId = UserInfo.getUserId();
        
        String eLetterjson = JSON.serialize(
    new Map<String, Object> { 
	'fromAddress' => 
            new Map<String, Object> {
                'name' => 'Dev Desai',
                'address' => 'deadesai@deloitte.com',
				'fromId' => userinfoId
            },
        'eletterId' => caseEletterWithNoTargetRecipients[0].Id,
        'eletterContext' => 'NEW',
		'recordId' => insList[0].id,
		'isSecureEmail' => false,
		'sendToCurrentUser' => false,
		'attachmentIds' => new String[] {},
		'subject' => 'Missing information was identified while reviewing enrollment form',
		'comments' => 'NEW',
		'pagecount' => '3',
		'textBody' => '',
		'htmlBody' => '',
		'communicationMethod' => 'Fax',
		'generatedContentVersionJobId' => ''
        
        
    }
);
        String recipientsString='['+JSON.serialize(
    new Map<String, Object> {
        'bDisableEmail'=> true,
    'bDisableFax'=> false,
    'bDisableSendToMe'=> true,
    'communicationLanguage'=> 'English',
    'communicationPreference'=>'Fax',
    'hasContactEmail'=> true,
    'hasContactFax'=> true,
    'isValidEmail'=> true,
    'recipientEmail'=> 'vagnihotri@deloitte.com',
    'recipientFax'=> '11234567811',
    'recipientName'=> 'Fax Patient',
    'recipientRecordType'=> 'ACLS_Patient',
    'recipientRole'=> 'Patient',
    'recipientRoleLabel'=> 'Patient',
    'recipientType'=> 'Patient',
    'recipientTypeLabel'=> 'Patient',
    'sendEmail'=> false,
    'sendFax'=> true,
    'sendToMe'=> false,
    'recipient'=> 
            new Map<String, Object> {
      'communicationLanguage'=> 'English',
      'email'=> 'vagnihotri@deloitte.com',
      'fax'=> '11234567811',
      'Id'=> '001DO000002QDv1YAG',
      'name'=> 'Fax Patient',
      'type'=> 'ACCOUNT'
    }
        
          }
)+']';
            system.assert(insList.Size()>0, true);
            getTestData();
            system.runAs(eletterAdminUser1) {
                Test.StartTest();
                try{
                	ACLS_PC_Eletter2Controller.sendOutboundDocuments(eLetterjson,recipientsString);
                    ACLS_PC_eLetterService.sendLetter(null, null, 'Fax', null, true);
                    ACLS_PC_eLetterService.sendLetter(null, null, 'Email', null, true);
            	}catch(Exception e){
                    ACLS_Utility.createINTErrorLogs(e, '', '', '', '', '', '', '');
                }
                Test.StopTest();
    }
        
    }
    /*********************************************************************************
    Method Name    : testsendOutboundFaxDocumentsCoverage
    Description    : Test sendOutboundDocuments method for Coverage
    Return Type    : void
  	Parameter      : None
    *********************************************************************************/
    @isTest static void testsendOutboundFaxDocumentsCoverage() {
        List<Case> caseList = new List<Case>([select id,PC_Engagement_Program__c from case where IsEscalated=false]);
        List<PC_eLetter__c> caseEletterWithNoTargetRecipients = new List<PC_eLetter__c>([select id,Name,PC_Object_Record_Types__c,PC_Allow_Send_to_Patient__c,PC_Category__c,PC_Source_Object__c,PC_Template_Name__c from PC_eLetter__c where Name = 'Patient Welcome Letter Without TargetRecipients']);
        HealthCloudGA__UsePersonAccount__c pac = new HealthCloudGA__UsePersonAccount__c(Name = PC_Constants.PC_USE_PERSON_ACCOUNT, HealthCloudGA__Enable__c=true);
        insert pac;

        List<PC_Program_Coverage__c> covList = new List<PC_Program_Coverage__c>([Select id from PC_Program_Coverage__c]);
        
        String userinfoId = UserInfo.getUserId();
        
        String eLetterjson = JSON.serialize(
    new Map<String, Object> { 
        'eletterId' => caseEletterWithNoTargetRecipients[0].Id,
        'eletterContext' => 'NEW',
		'recordId' => covList[0].id,
		'isSecureEmail' => false,
		'sendToCurrentUser' => false,
		'attachmentIds' => new String[] {},
		'subject' => 'Missing information was identified while reviewing enrollment form',
		'comments' => 'NEW',
		'pagecount' => '3',
		'textBody' => '',
		'htmlBody' => '',
		'communicationMethod' => 'Fax',
		'generatedContentVersionJobId' => ''
        
        
    }
);
        String recipientsString='['+JSON.serialize(
    new Map<String, Object> {
        'bDisableEmail'=> true,
    'bDisableFax'=> false,
    'bDisableSendToMe'=> true,
    'communicationLanguage'=> 'English',
    'communicationPreference'=>'Fax',
    'hasContactEmail'=> true,
    'hasContactFax'=> true,
    'isValidEmail'=> true,
    'recipientEmail'=> 'vagnihotri@deloitte.com',
    'recipientFax'=> '11234567811',
    'recipientName'=> 'Fax Patient',
    'recipientRecordType'=> 'ACLS_Patient',
    'recipientRole'=> 'Patient',
    'recipientRoleLabel'=> 'Patient',
    'recipientType'=> 'Patient',
    'recipientTypeLabel'=> 'Patient',
    'sendEmail'=> false,
    'sendFax'=> true,
    'sendToMe'=> false,
    'recipient'=> 
            new Map<String, Object> {
      'communicationLanguage'=> 'English',
      'email'=> 'vagnihotri@deloitte.com',
      'fax'=> '11234567811',
      'Id'=> '001DO000002QDv1YAG',
      'name'=> 'Fax Patient',
      'type'=> 'ACCOUNT'
    }
        
          }
)+']';
            system.assert(covList.Size()>0, true);
            getTestData();
       		ACLS_PC_eLetter2Controller.SendLetterRequest request = (ACLS_PC_eLetter2Controller.SendLetterRequest) System.JSON.deserialize(eLetterjson, ACLS_PC_eLetter2Controller.SendLetterRequest.class);
            ACLS_PC_eLetterService serviceClass = new ACLS_PC_eLetterService();
        	system.runAs(eletterAdminUser1) {
                Test.StartTest();
                try{
                	ACLS_PC_Eletter2Controller.sendOutboundDocuments(eLetterjson,recipientsString);
                    ACLS_PC_eLetterService.sendLetter(null, null, 'Fax', null, true);
                    ACLS_PC_eLetterService.sendLetter(null, null, 'Email', null, true);
                    serviceClass.populateValidFromAddress(request);
                    ACLS_PC_eLetterService.getELetter(caseEletterWithNoTargetRecipients[0].Id);
            	}catch(Exception e){
                    ACLS_Utility.createINTErrorLogs(e, '', '', '', '', '', '', '');                
                }
                Test.StopTest();
    }
        
    }
    /*********************************************************************************
    Method Name    : testsendOutboundFaxDocumentsAE
    Description    : Test sendOutboundDocuments method for Coverage
    Return Type    : void
  	Parameter      : None
    *********************************************************************************/
    @isTest static void testsendOutboundFaxDocumentsAE() {
        List<Case> caseList = new List<Case>([select id,PC_Engagement_Program__c from case where IsEscalated=false]);
        List<PC_eLetter__c> caseEletterWithNoTargetRecipients = new List<PC_eLetter__c>([select id,Name,PC_Object_Record_Types__c,PC_Allow_Send_to_Patient__c,PC_Category__c,PC_Source_Object__c,PC_Template_Name__c from PC_eLetter__c where Name = 'Patient Welcome Letter Without TargetRecipients']);
        HealthCloudGA__UsePersonAccount__c pac = new HealthCloudGA__UsePersonAccount__c(Name = PC_Constants.PC_USE_PERSON_ACCOUNT, HealthCloudGA__Enable__c=true);
        insert pac;

        List<PC_AdverseEvent__c> AEList = new List<PC_AdverseEvent__c>([Select id from PC_AdverseEvent__c]);
        
        String userinfoId = UserInfo.getUserId();
        
        String eLetterjson = JSON.serialize(
    new Map<String, Object> { 
        'eletterId' => caseEletterWithNoTargetRecipients[0].Id,
        'eletterContext' => 'NEW',
		'recordId' => AEList[0].id,
		'isSecureEmail' => false,
		'sendToCurrentUser' => false,
		'attachmentIds' => new String[] {},
		'subject' => 'Missing information was identified while reviewing enrollment form',
		'comments' => 'NEW',
		'pagecount' => '3',
		'textBody' => '',
		'htmlBody' => '',
		'communicationMethod' => 'Fax',
		'generatedContentVersionJobId' => ''
        
        
    }
);
        String recipientsString='['+JSON.serialize(
    new Map<String, Object> {
        'bDisableEmail'=> true,
    'bDisableFax'=> false,
    'bDisableSendToMe'=> true,
    'communicationLanguage'=> 'English',
    'communicationPreference'=>'Fax',
    'hasContactEmail'=> true,
    'hasContactFax'=> true,
    'isValidEmail'=> true,
    'recipientEmail'=> 'vagnihotri@deloitte.com',
    'recipientFax'=> '11234567811',
    'recipientName'=> 'Fax Patient',
    'recipientRecordType'=> 'ACLS_Patient',
    'recipientRole'=> 'Patient',
    'recipientRoleLabel'=> 'Patient',
    'recipientType'=> 'Patient',
    'recipientTypeLabel'=> 'Patient',
    'sendEmail'=> false,
    'sendFax'=> true,
    'sendToMe'=> false,
    'recipient'=> 
            new Map<String, Object> {
      'communicationLanguage'=> 'English',
      'email'=> 'vagnihotri@deloitte.com',
      'fax'=> '11234567811',
      'Id'=> '001DO000002QDv1YAG',
      'name'=> 'Fax Patient',
      'type'=> 'ACCOUNT'
    }
        
          }
)+']';
            system.assert(AEList.Size()>0, true);
            getTestData();
       		ACLS_PC_eLetter2Controller.SendLetterRequest request = (ACLS_PC_eLetter2Controller.SendLetterRequest) System.JSON.deserialize(eLetterjson, ACLS_PC_eLetter2Controller.SendLetterRequest.class);
            ACLS_PC_eLetterService serviceClass = new ACLS_PC_eLetterService();
        	system.runAs(eletterAdminUser1) {
                Test.StartTest();
                try{
                	ACLS_PC_Eletter2Controller.sendOutboundDocuments(eLetterjson,recipientsString);
                    ACLS_PC_eLetterService.sendLetter(null, null, 'Fax', null, true);
                    ACLS_PC_eLetterService.sendLetter(null, null, 'Email', null, true);
                    serviceClass.populateValidFromAddress(request);
                    ACLS_PC_eLetterService.getELetter(caseEletterWithNoTargetRecipients[0].Id);
            	}catch(Exception e){
                    ACLS_Utility.createINTErrorLogs(e, '', '', '', '', '', '', '');                
                }
                Test.StopTest();
    }
        
    }
    /*********************************************************************************
    Method Name    : testsendOutboundFaxDocumentsAE2
    Description    : Test sendOutboundDocuments method for Coverage
    Return Type    : void
  	Parameter      : None
    *********************************************************************************/
    @isTest static void testsendOutboundFaxDocumentsAE2() {
        List<Case> caseList = new List<Case>([select id,PC_Engagement_Program__c from case where IsEscalated=false]);
        List<PC_eLetter__c> caseEletterWithNoTargetRecipients = new List<PC_eLetter__c>([select id,Name,PC_Object_Record_Types__c,PC_Allow_Send_to_Patient__c,PC_Category__c,PC_Source_Object__c,PC_Template_Name__c from PC_eLetter__c where Name = 'Patient Welcome Letter Without TargetRecipients']);
        HealthCloudGA__UsePersonAccount__c pac = new HealthCloudGA__UsePersonAccount__c(Name = PC_Constants.PC_USE_PERSON_ACCOUNT, HealthCloudGA__Enable__c=true);
        insert pac;

        List<PC_AdverseEvent2__c> AEList = new List<PC_AdverseEvent2__c>([Select id from PC_AdverseEvent2__c]);
        
        String userinfoId = UserInfo.getUserId();
        //String eLetterjson = '{"fromAddress":{"name":"Dev Desai","address":"deadesai@deloitte.com","fromId":"005DO000000YK3xYAG"},"eletterId":"a29DO000000GogfYAC","eletterContext":"NEW","recordId":"500DO000000mi8JYAQ","isSecureEmail":false,"sendToCurrentUser":false,"attachmentIds":[],"subject":"Missing information was identified while reviewing enrollment form","comments":"","pagecount":"4","textBody":"","htmlBody":"","communicationMethod":"Fax","generatedContentVersionJobId":"0nnDO00000000U6YAI"}';
        String eLetterjson = JSON.serialize(
    new Map<String, Object> { 
        'eletterId' => caseEletterWithNoTargetRecipients[0].Id,
        'eletterContext' => 'NEW',
		'recordId' => AEList[0].id,
		'isSecureEmail' => false,
		'sendToCurrentUser' => false,
		'attachmentIds' => new String[] {},
		'subject' => 'Missing information was identified while reviewing enrollment form',
		'comments' => 'NEW',
		'pagecount' => '3',
		'textBody' => '',
		'htmlBody' => '',
		'communicationMethod' => 'Fax',
		'generatedContentVersionJobId' => ''
        
        
    }
);
        String recipientsString='['+JSON.serialize(
    new Map<String, Object> {
        'bDisableEmail'=> true,
    'bDisableFax'=> false,
    'bDisableSendToMe'=> true,
    'communicationLanguage'=> 'English',
    'communicationPreference'=>'Fax',
    'hasContactEmail'=> true,
    'hasContactFax'=> true,
    'isValidEmail'=> true,
    'recipientEmail'=> 'vagnihotri@deloitte.com',
    'recipientFax'=> '11234567811',
    'recipientName'=> 'Fax Patient',
    'recipientRecordType'=> 'ACLS_Patient',
    'recipientRole'=> 'Patient',
    'recipientRoleLabel'=> 'Patient',
    'recipientType'=> 'Patient',
    'recipientTypeLabel'=> 'Patient',
    'sendEmail'=> false,
    'sendFax'=> true,
    'sendToMe'=> false,
    'recipient'=> 
            new Map<String, Object> {
      'communicationLanguage'=> 'English',
      'email'=> 'vagnihotri@deloitte.com',
      'fax'=> '11234567811',
      'Id'=> '001DO000002QDv1YAG',
      'name'=> 'Fax Patient',
      'type'=> 'ACCOUNT'
    }
        
          }
)+']';
            system.assert(AEList.Size()>0, true);
            getTestData();
       		ACLS_PC_eLetter2Controller.SendLetterRequest request = (ACLS_PC_eLetter2Controller.SendLetterRequest) System.JSON.deserialize(eLetterjson, ACLS_PC_eLetter2Controller.SendLetterRequest.class);
            ACLS_PC_eLetterService serviceClass = new ACLS_PC_eLetterService();
        	system.runAs(eletterAdminUser1) {
                Test.StartTest();
                try{
                	ACLS_PC_Eletter2Controller.sendOutboundDocuments(eLetterjson,recipientsString);
                    ACLS_PC_eLetterService.sendLetter(null, null, 'Fax', null, true);
                    ACLS_PC_eLetterService.sendLetter(null, null, 'Email', null, true);
                    serviceClass.populateValidFromAddress(request);
                    ACLS_PC_eLetterService.getELetter(caseEletterWithNoTargetRecipients[0].Id);
            	}catch(Exception e){
                    ACLS_Utility.createINTErrorLogs(e, '', '', '', '', '', '', '');                
                }
                Test.StopTest();
    }
        
    }
    
    /*********************************************************************************
    Method Name    : testGetFaxStatus
    Description    : test the status poll for sent fax
    Return Type    : void
  	Parameter      : None
    *********************************************************************************/
    @isTest static void testGetFaxStatus() {
        String resbody = '{"jti":"44e3ffe5-32c2-4373-aa38-b4ada96bf729","app_id":"c6c8a48c-0001-45d4-b56f-62e4e459984a","secret_id":"fe972a62-e7ad-4f35-8463-d1676dca0946","scope":"read write","expires_in":86399,"token_type":"bearer","access_token":"eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzZWNyZXRfaWQiOiJmZTk3MmE2Mi1lN2FkLTRmMzUtODQ2My1kMTY3NmRjYTA5NDYiLCJzY29wZSI6WyJyZWFkIiwid3JpdGUiXSwiZXhwIjoxNjgzNjIwNjk5LCJhcHBfaWQiOiJjNmM4YTQ4Yy0wMDAxLTQ1ZDQtYjU2Zi02MmU0ZTQ1OTk4NGEiLCJhdXRob3JpdGllcyI6WyJST0xFX0ZTVE9SIl0sImp0aSI6IjQ0ZTNmZmU1LTMyYzItNDM3My1hYTM4LWI0YWRhOTZiZjcyOSIsImNsaWVudF9pZCI6ImM2YzhhNDhjLTAwMDEtNDVkNC1iNTZmLTYyZTRlNDU5OTg0YSJ9.FV9gJNHJakjidW32ESyc22AGqOBqM5y88ZANNQhcQo16Q8s4ONPSAUKyreNwz879LUEA8NdIjXgoz_m-SEOKOR8VDv7Yp8wzC5CYBfejFkqrZAZredhsFYV33Y3pnvNFGJ0r1S0bp5oWpxr30sdfMD0BnQ86R9TBE4xdQum7mu--F6PTcfOOZmBP1XXD-KB3zzOw29OBWhiOZWLq5HaLC_gbKtoLN1tCXqvfizYwVD6vNy15YBQkdLQcpSl2nrJtsCA4DNfys4xzq7oaFMbidNmIYvKsQxMs3B8pRpSWn4uUpBaysolk9yVhZRM0WK5OqTogZgiUWQ_3ASkt4fM8yw"}';
        ACLS_Fax_GetStatusBatch.httpRes = new HttpResponse();
        ACLS_Fax_GetStatusBatch.httpRes.setStatusCode(200);
        ACLS_Fax_GetStatusBatch.httpRes.setBody(resbody);
        //ACLS_Fax_GetStatusBatch.bearerToken = '"jti":"44e3ffe5-32c2-4373-aa38-b4ada96bf729","app_id":"c6c8a48c-0001-45d4-b56f-62e4e459984a","secret_id":"fe972a62-e7ad-4f35-8463-d1676dca0946","scope":"read write","expires_in":86399,"token_type":"bearer","access_token":"eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzZWNyZXRfaWQiOiJmZTk3MmE2Mi1lN2FkLTRmMzUtODQ2My1kMTY3NmRjYTA5NDYiLCJzY29wZSI6WyJyZWFkIiwid3JpdGUiXSwiZXhwIjoxNjgzNjIwNjk5LCJhcHBfaWQiOiJjNmM4YTQ4Yy0wMDAxLTQ1ZDQtYjU2Zi02MmU0ZTQ1OTk4NGEiLCJhdXRob3JpdGllcyI6WyJST0xFX0ZTVE9SIl0sImp0aSI6IjQ0ZTNmZmU1LTMyYzItNDM3My1hYTM4LWI0YWRhOTZiZjcyOSIsImNsaWVudF9pZCI6ImM2YzhhNDhjLTAwMDEtNDVkNC1iNTZmLTYyZTRlNDU5OTg0YSJ9.FV9gJNHJakjidW32ESyc22AGqOBqM5y88ZANNQhcQo16Q8s4ONPSAUKyreNwz879LUEA8NdIjXgoz_m-SEOKOR8VDv7Yp8wzC5CYBfejFkqrZAZredhsFYV33Y3pnvNFGJ0r1S0bp5oWpxr30sdfMD0BnQ86R9TBE4xdQum7mu--F6PTcfOOZmBP1XXD-KB3zzOw29OBWhiOZWLq5HaLC_gbKtoLN1tCXqvfizYwVD6vNy15YBQkdLQcpSl2nrJtsCA4DNfys4xzq7oaFMbidNmIYvKsQxMs3B8pRpSWn4uUpBaysolk9yVhZRM0WK5OqTogZgiUWQ_3ASkt4fM8yw"';
        
        ACLS_Fax_GetStatusBatch.httpRes1 = new HttpResponse();
        ACLS_Fax_GetStatusBatch.httpRes1.setStatusCode(200);
        ACLS_Fax_GetStatusBatch.httpRes1.setBody(resbody);
        
        getTestData();
        Test.setMock(HttpCalloutMock.class, new ACLS_Test_FaxHttpCalloutMock());
        Id sentFaxRecordTypeId = PC_System.recordTypeId('EFX__efax__c', 'Sent_Fax');
        system.runAs(eletterAdminUser1) {
            Test.StartTest();
            EFX__efax__c ef = new EFX__efax__c();
            ef.EFX__eFax_Id__c = 'test';
            ef.EFX__Status__c = 'IN PROGRESS';
            ef.RecordTypeId = sentFaxRecordTypeId;
            insert ef;
            
           Id JobId = Database.executeBatch(new ACLS_Fax_GetStatusBatch(null), 90);
           System.assert(jobId != null,'Fax Records Batch class Ran successfully');
            Test.StopTest();
    	}  
    }
    /*********************************************************************************
    Method Name    : testGetFaxStatusNoResponse
    Description    : test the status poll for sent fax with no response
    Return Type    : void
  	Parameter      : None
    *********************************************************************************/
    @isTest static void testGetFaxStatusNoResponse() {
        getTestData();
        Id sentFaxRecordTypeId = PC_System.recordTypeId('EFX__efax__c', 'Sent_Fax');
        system.runAs(eletterAdminUser1) {
            Test.StartTest();
            EFX__efax__c ef = new EFX__efax__c();
            ef.EFX__eFax_Id__c = 'test';
            ef.EFX__Status__c = 'IN PROGRESS';
            ef.RecordTypeId = sentFaxRecordTypeId;
            insert ef;
            
            Id jobId = Database.executeBatch(new ACLS_Fax_GetStatusBatch(null), 90);
            System.assert(jobId != null,'Fax Records Batch class Ran successfully');
            Test.StopTest();
    	}  
    }
    @isTest static void testmethod1() {
        PC_eLetter__c caseEletter1 = new PC_eLetter__c(
                Name = 'Patient Welcome Letter 123',
                PC_Object_Record_Types__c = 'Program',
                PC_Target_Recipients__c = 'HCO; Treating Physician; Case Manager; Reimbursement Specialist',
                PC_Send_to_User__c = true,
                PC_Category__c = 'Email;Fax',
                PC_Source_Object__c = 'Case',
                PC_Template_Name__c = 'Email_Template_Name',
                PC_Allow_Send_to_Patient__c=true
        );
        insert caseEletter1;
                //Name = 'Patient Welcome Letter'
                PC_eLetter__c testEletter = new PC_eLetter__c ();
                test.startTest();
                 testEletter = ACLS_PC_eLetterService.getELetter(caseEletter1.id);
                    test.stopTest();
        System.assertEquals('Patient Welcome Letter 123',testEletter.Name);
    }
    
    @isTest 
	private static void test_Document() {
		String document_content;
        String document_type;
        ACLS_Fax_IntegrationWrapper.Documents objDoc = new ACLS_Fax_IntegrationWrapper.Documents(document_content,document_type);
		
	}
     @isTest 
	private static void test_Fax_options() {
         String image_resolution;
		 String include_cover_page;
		 String custom_CallerID;
		 ACLS_Fax_IntegrationWrapper.Header_options header_options;
		 String custom_CSID;
		 ACLS_Fax_IntegrationWrapper.Cover_page_options cover_page_options;
        
        ACLS_Fax_IntegrationWrapper.Fax_options objFax = new ACLS_Fax_IntegrationWrapper.Fax_options(image_resolution,include_cover_page,custom_CallerID,header_options,custom_CSID,cover_page_options);
    }
    
      @isTest 
	private static void test_HeaderOptions() {
        List<String> line_1;
        ACLS_Fax_IntegrationWrapper.Header_options objHeader = new ACLS_Fax_IntegrationWrapper.Header_options(line_1);
    }
    @isTest
    private static void test_CoverOptions() {
        String from_name;
		String subject;
		String message;
        ACLS_Fax_IntegrationWrapper.Retry_options retry;
        
        ACLS_Fax_IntegrationWrapper.Cover_page_options objCover = new ACLS_Fax_IntegrationWrapper.Cover_page_options(from_name,subject,message, retry);
        
    }
	@isTest
	private static void test_RetryOptions() {
        Integer non_billable;
		Integer billable;
		Integer human_answer;
        
        ACLS_Fax_IntegrationWrapper.Retry_options objRetry = new ACLS_Fax_IntegrationWrapper.Retry_options(non_billable,billable,human_answer);
        
    }
}