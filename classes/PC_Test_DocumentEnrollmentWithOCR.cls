/**
* Created by sathekumar on 7/6/2021.
*/

@IsTest
private class PC_Test_DocumentEnrollmentWithOCR {

    private static User objUser;
    private static PC_Document__c oDoc;
    private static PC_Document__c oDoc1;
    private static String DOCUMENT_NAME = 'DocumentEnrollmentWithOCR1';
    private static String DOCUMENT2_NAME = 'DocumentEnrollmentWithOCR2';
    private static final String USER_ALIAS = 'ocrUser1';
    private static final String USER_EMAIL = 'ocruser1@test.com';
    private static final String ENG_PROGRAM_NAME = 'OcrProg';
    private static final String DOC_CATEGORY = 'Enrollment Form';
    private static final String onlineApplicantName = 'testApplicant1';
    private static final String OCR_TEMPLATE_TYPE_NAME = 'testOcrTemplateType1';

    @testSetup static void createTestData(){
        //Insert User
        objUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, USER_EMAIL, USER_ALIAS);
        objUser = (User) PC_Database.ins(objUser);
        system.runAs(objUser){
            //Create Manufacturer
            Account manufacturerAcc = PC_Test_Setup.createTestAccount(PC_Constants.MANUFACTURER_RECORD_TYPE);
            PC_Database.ins(manufacturerAcc, false);

            //Create engagement Program
            PC_Engagement_Program__c engagementProgram = PC_Test_Setup.createEngagementProgram('ProgramA', manufacturerAcc.Id);
            PC_Database.ins(engagementProgram, false);

            //Create Applicant
            PC_Applicant__c onlineApplicant1 = PC_Test_Setup.createApplicant('testApplicant1');
            onlineApplicant1.PC_IsCreatedUsingOCR__c = true;
            onlineApplicant1.PC_IsReviewed__c = false;
            PC_Database.ins(onlineApplicant1, false);

            //Create the Enrollment Case with Applicant
            Case reqEnrollCase = new Case(
                Status 	= 'Open',
                Origin = 'Web',
                RecordTypeId = PC_SYSTEM.recordTypeId('Case', PC_Constants.CASE_ENROLLMENT_RECORD_TYPE),
                Type = PC_Constants.CASE_ENROLLMENT_RECORD_TYPE_NAME,
                PC_Engagement_Program__c = engagementProgram.Id,
                OwnerId					 = objUser.Id,
                PC_ActiveApplicant__c	 = onlineApplicant1.Id
            );
            PC_Database.ins(reqEnrollCase, false);

            // Create Document1 with applicant
            Id recordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.DOCUMENT_OBJECT, PC_Constants.DOCUMENT_FAX_INBOUND_RECORD_TYPE);
            oDoc = PC_Test_Setup.createDocument(PC_Constants.DOCUMENT_FAX_INBOUND_RECORD_TYPE, PC_Constants.DOCUMENT_STATUS_REVIEW_NEEDED, ENG_PROGRAM_NAME + 'A');
            oDoc.RecordTypeId = recordTypeId;
            oDoc.PC_Document_Name__c = DOCUMENT_NAME;
            oDoc.PC_Applicant__c = onlineApplicant1.Id;
            PC_Database.ins(oDoc, false);

            //Attach file to Document1
            ContentDocument conDocObj = PC_Test_Setup.createFile(oDoc.Id);
            String contentVersionId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE ContentDocumentId = :conDocObj.Id AND IsLatest = true LIMIT 1]?.Id;

            //Create document2 with applicant and Enrollment Case
            oDoc1 = PC_Test_Setup.createDocument(PC_Constants.DOCUMENT_FAX_INBOUND_RECORD_TYPE, PC_Constants.DOCUMENT_STATUS_REVIEW_NEEDED, ENG_PROGRAM_NAME + 'B');
            oDoc1.PC_Document_Name__c = DOCUMENT2_NAME;
            oDoc1.PC_Applicant__c = onlineApplicant1.Id;
            oDoc1.RecordTypeId = recordTypeId;
            PC_Database.ins(oDoc1, false);

            //Create a Documnet Log
            PC_Document_Log__c docLog = createDocumentLog(oDoc1.Id, reqEnrollCase.Id);
            PC_Database.ins(docLog, false);

            //Create template type
            PC_OcrTemplateType__c ocrTemplateTypeObj = new PC_OcrTemplateType__c();
            ocrTemplateTypeObj.Name = OCR_TEMPLATE_TYPE_NAME;
            ocrTemplateTypeObj.PC_APIName__c = OCR_TEMPLATE_TYPE_NAME;
            ocrTemplateTypeObj.PC_Label__c = OCR_TEMPLATE_TYPE_NAME;
            ocrTemplateTypeObj.PC_IsActive__c = PC_Constants.TRUE_BOOLEAN;
            PC_Database.ins(ocrTemplateTypeObj, false);

            // Create OCR Queue for document2
            PC_OcrQueue__c ocrQueueObj = new PC_OcrQueue__c();
            ocrQueueObj.PC_Status__c = 'In Progress';
            ocrQueueObj.PC_IsActive__c = PC_Constants.TRUE_BOOLEAN;
            ocrQueueObj.PC_OcrTemplateType__c = ocrTemplateTypeObj.Id;
            ocrQueueObj.PC_SourceDocument__c = oDoc1.Id;
            ocrQueueObj.PC_SourceContentId__c = contentVersionId;
            PC_Database.ins(ocrQueueObj, false);
        }
    }

    public static PC_Document_Log__c createDocumentLog(Id documentId, Id program) {
        PC_Document_Log__c docObj = new PC_Document_Log__c();
        docObj.PC_Document__c = documentId;
        docObj.PC_Program__c = program;
        return docObj;
    }

    @isTest static void testCheckDocumentOcrStatus() {
        objUser = [Select Id from User where Alias =: USER_ALIAS];
        system.runAs(objUser){
            Test.startTest();

            PC_DocumentEnrollmentWithOCR.DocumentStatus documentStatus = new PC_DocumentEnrollmentWithOCR.DocumentStatus();
            PC_Document__c docObj1 = [SELECT Id, PC_Document_Name__c FROM PC_Document__c WHERE PC_Document_Name__c =:DOCUMENT_NAME LIMIT 1];
            documentStatus = PC_DocumentEnrollmentWithOCR.checkDocumentOcrStatus(docObj1.Id);
            system.assertEquals(documentStatus.applicantExistOnDocument, true);
            system.assertEquals(documentStatus.enrollmentCaseExistOnDocument, false);
            system.assertEquals(documentStatus.previousOcrQueueStatus, null);

            PC_Document__c docObj2 = [SELECT Id, PC_Document_Name__c FROM PC_Document__c WHERE PC_Document_Name__c =:DOCUMENT2_NAME LIMIT 1];
            documentStatus = PC_DocumentEnrollmentWithOCR.checkDocumentOcrStatus(docObj2.Id);
            system.assertEquals(documentStatus.applicantExistOnDocument, true);
            system.assertEquals(documentStatus.enrollmentCaseExistOnDocument, true);
            system.assertEquals(documentStatus.previousOcrQueueStatus, 'In Progress');

            Test.stopTest();
        }
    }

    @isTest static void testCancelOCR() {
        objUser = [Select Id from User where Alias =: USER_ALIAS];
        system.runAs(objUser){
            Test.startTest();
            PC_Document__c docObj = [SELECT Id, PC_Document_Name__c FROM PC_Document__c WHERE PC_Document_Name__c =:DOCUMENT_NAME LIMIT 1];
            String responseString = PC_DocumentEnrollmentWithOCR.cancelOCR(docObj.Id);
            system.assertEquals(responseString,  System.Label.PC_NotAbleToCancelOcrMessage);

            PC_Document__c docObj2 = [SELECT Id, PC_Document_Name__c FROM PC_Document__c WHERE PC_Document_Name__c =:DOCUMENT2_NAME LIMIT 1];
            String responseString2 = PC_DocumentEnrollmentWithOCR.cancelOCR(docObj2.Id);
            system.assertEquals(responseString2, null);
            Test.stopTest();
        }
    }

    @isTest static void testGetApplicantOcrDetails() {
        objUser = [Select Id from User where Alias =: USER_ALIAS];
        system.runAs(objUser){
            Test.startTest();
            PC_DocumentEnrollmentWithOCR.ApplicantOcrDetails applicantOcrDetails = new PC_DocumentEnrollmentWithOCR.ApplicantOcrDetails();
            List<PC_Applicant__c> applicantList = [Select Id, PC_Last_Name__c from PC_Applicant__c WHERE PC_Last_Name__c = 'testApplicant1' LIMIT 1];
            Case enrollmentCase = [Select Id, PC_ActiveApplicant__c from Case where PC_ActiveApplicant__c =: applicantList[0].Id];
            applicantOcrDetails = PC_DocumentEnrollmentWithOCR.getApplicantOcrDetails(enrollmentCase.Id);
            if(applicantOcrDetails.isOcrEnabled){
                system.assertEquals(applicantOcrDetails.isCreatedUsingOCR, true);
                system.assertEquals(applicantOcrDetails.isReviewed, false);
            } else {
                system.assertEquals(applicantOcrDetails.isCreatedUsingOCR, false);
                system.assertEquals(applicantOcrDetails.isReviewed, false);
            }
            Test.stopTest();
        }
    }
}