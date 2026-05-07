/**
 * Created by sathekumar on 11/18/2021.
 */

@IsTest
private class PC_Test_OcrResult_Trigger {
    private static User adminUser;
    private static Case reqEnrollCase;
    private static PC_Document__c oDoc;
    private static PC_Document__c oDoc2;
    private static PC_OcrTemplateType__c ocrTemplateTypeObj;
    private static PC_OcrQueue__c ocrQueueObj;
    private static PC_OcrQueue__c ocrQueueObj2;
    private static PC_OcrResult__c ocrResultObj;
    private static PC_Applicant__c onlineApplicant1;
    private static PC_Prescription__c prescription;
    private static String OCR_TEMPLATE_TYPE_NAME = 'test_OcrResult_Trigger_OcrTemplateType2';
    private static String DOCUMENT_NAME = 'ocrResultTestDocument1';
    private static final String ENG_PROGRAM_NAME = 'OCREng1';

    @isTest static void testOcrResultTrigger() {
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'userpctest@test2.com', 'test2');
        PC_Database.ins(adminUser, false);
        system.runAs(adminUser) {
            Test.StartTest();

            //Create the Manufacturer and Engagement Program for Enrollment Case
            Account manuAcc = PC_Test_Setup.createTestAccount(PC_Constants.MANUFACTURER_RECORD_TYPE);
            PC_Database.ins(manuAcc, false);

            PC_Engagement_Program__c engPrgA = PC_Test_Setup.createEngagementProgram(ENG_PROGRAM_NAME, manuAcc.Id);
            PC_Database.ins(engPrgA, false);

            //Create Applicant
            onlineApplicant1 = PC_Test_Setup.createApplicant('Patel');
            PC_Database.ins(onlineApplicant1, false);

            //Create the Enrollment Case with Applicant
            reqEnrollCase = new Case(
                    Status = 'Open',
                    Origin = 'Web',
                    RecordTypeId = PC_SYSTEM.recordTypeId('Case', PC_Constants.CASE_ENROLLMENT_RECORD_TYPE),
                    Type = PC_Constants.CASE_ENROLLMENT_RECORD_TYPE_NAME,
                    PC_Engagement_Program__c = engPrgA.Id,
                    OwnerId = adminUser.Id,
                    PC_ActiveApplicant__c = onlineApplicant1.Id
            );
            PC_Database.ins(reqEnrollCase, false);

            // Create PC Document
            Id recordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.DOCUMENT_OBJECT, PC_Constants.DOCUMENT_FAX_INBOUND_RECORD_TYPE);
            oDoc = new PC_Document__c();
            oDoc.PC_Document_Status__c = PC_Constants.DOCUMENT_STATUS_REVIEW_NEEDED;
            oDoc.PC_Page_Count__c = 5;
            oDoc.PC_Engagement_Program__c = engPrgA.Id;
            oDoc.RecordTypeId = recordTypeId;
            oDoc.PC_Document_Name__c = DOCUMENT_NAME;
            PC_Database.ins(oDoc, false);

            // Create PC Document2
            oDoc2 = new PC_Document__c();
            oDoc2.RecordTypeId = recordTypeId;
            oDoc2.PC_Document_Status__c = PC_Constants.DOCUMENT_STATUS_REVIEW_NEEDED;
            oDoc2.PC_Page_Count__c = 5;
            oDoc2.PC_Engagement_Program__c = engPrgA.Id;
            oDoc2.PC_Applicant__c = onlineApplicant1.Id;
            oDoc2.PC_Document_Name__c = DOCUMENT_NAME + '2';
            PC_Database.ins(oDoc2, false);

            //Attach file to PC Document
            ContentDocument conDocObj = PC_Test_Setup.createFile(oDoc.Id);
            String contentVersionId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE ContentDocumentId = :conDocObj.Id AND IsLatest = true LIMIT 1] ?.Id;

            //Create a Document Log
            PC_Document_Log__c docObj = new PC_Document_Log__c();
            docObj.PC_Document__c = oDoc.Id;
            docObj.PC_Program__c = reqEnrollCase.Id;
            PC_Database.ins(docObj, false);

            // Create OCR Queue
            ocrQueueObj = new PC_OcrQueue__c();
            ocrQueueObj.PC_Status__c = 'Queued';
            ocrQueueObj.PC_IsActive__c = PC_Constants.TRUE_BOOLEAN;
            ocrQueueObj.PC_SourceDocument__c = oDoc.Id;
            ocrQueueObj.PC_SourceContentId__c = contentVersionId;
            PC_Database.ins(ocrQueueObj, false);

            // Create OCR Queue2
            ocrQueueObj2 = new PC_OcrQueue__c();
            ocrQueueObj2.PC_Status__c = 'Queued';
            ocrQueueObj2.PC_IsActive__c = PC_Constants.TRUE_BOOLEAN;
            ocrQueueObj2.PC_SourceDocument__c = oDoc2.Id;
            ocrQueueObj2.PC_SourceContentId__c = contentVersionId;
            PC_Database.ins(ocrQueueObj2, false);

            //Create prescription
            prescription = new PC_Prescription__c();
            PC_Database.ins(prescription, false);

            // Create OCR Results
            ocrResultObj = new PC_OcrResult__c();
            ocrResultObj.PC_OcrQueue__c = ocrQueueObj.Id;
            ocrResultObj.PC_ResultingRecordId__c = onlineApplicant1.Id;
            ocrResultObj.PC_ResultStatus__c = 'Success';
            PC_Database.ins(ocrResultObj, false);

            // Create OCR Results2
            PC_OcrResult__c ocrResultObj2 = new PC_OcrResult__c();
            ocrResultObj2.PC_OcrQueue__c = ocrQueueObj2.Id;
            ocrResultObj2.PC_ResultingRecordId__c = onlineApplicant1.Id;
            ocrResultObj2.PC_ResultStatus__c = 'Success';
            PC_Database.ins(ocrResultObj2, false);

            // Create OCR Results3
            PC_OcrResult__c ocrResultObj3 = new PC_OcrResult__c();
            ocrResultObj3.PC_OcrQueue__c = ocrQueueObj.Id;
            ocrResultObj3.PC_ResultingRecordId__c = prescription.Id;
            ocrResultObj3.PC_ResultStatus__c = 'Success';
            PC_Database.ins(ocrResultObj3, false);

            Test.stopTest();
        }
    }
}