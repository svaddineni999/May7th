/**
* Created by sathekumar on 5/26/2021.
*/

@IsTest
private class PC_Test_OcrResponse_Trigger {
    private static User adminUser;
    public static Boolean isTriggerActive = True;
    private static PC_Document__c oDoc;
    private static PC_OcrTemplateType__c ocrTemplateTypeObj;
    private static PC_OcrQueue__c ocrQueueObj;
    private static PC_OcrResponse__c ocrResponseObj;
    private static String OCR_TEMPLATE_TYPE_NAME = 'test_OcrResponse_Trigger_OcrTemplateType2';
    private static String DOCUMENT_NAME = 'ocrTestDocument1';
    private static final String ENG_PROGRAM_NAME = 'testOcr';

    @isTest static void testOcrQueueTrigger() {
        if(isTriggerActive) {
            adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'userpctest@test2.com', 'test2');
            PC_Database.ins(adminUser, false);
            system.runAs(adminUser) {
                Test.StartTest();

                // Create PC Document
                oDoc = PC_Test_Setup.createDocument(PC_Constants.DOCUMENT_FAX_INBOUND_RECORD_TYPE, PC_Constants.DOCUMENT_STATUS_REVIEW_NEEDED, ENG_PROGRAM_NAME + 'B');
                Id recordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.DOCUMENT_OBJECT, PC_Constants.DOCUMENT_FAX_INBOUND_RECORD_TYPE);
                oDoc.RecordTypeId = recordTypeId;
                oDoc.PC_Document_Name__c = DOCUMENT_NAME;
                PC_Database.ins(oDoc, false);

                //Attach file to PC Document
                ContentDocument conDocObj = PC_Test_Setup.createFile(oDoc.Id);
                String contentVersionId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE ContentDocumentId = :conDocObj.Id AND IsLatest = true LIMIT 1]?.Id;

                //Create template type
                ocrTemplateTypeObj = new PC_OcrTemplateType__c();
                ocrTemplateTypeObj.Name = OCR_TEMPLATE_TYPE_NAME;
                ocrTemplateTypeObj.PC_APIName__c = OCR_TEMPLATE_TYPE_NAME;
                ocrTemplateTypeObj.PC_Label__c = OCR_TEMPLATE_TYPE_NAME;
                ocrTemplateTypeObj.PC_IsActive__c = PC_Constants.TRUE_BOOLEAN;
                ocrTemplateTypeObj.PC_CreateResultsAfterOCRCompletion__c = PC_Constants.TRUE_BOOLEAN;
                PC_Database.ins(ocrTemplateTypeObj, false);

                // Create OCR Queue
                ocrQueueObj = new PC_OcrQueue__c();
                ocrQueueObj.PC_Status__c = 'Queued';
                ocrQueueObj.PC_IsActive__c = PC_Constants.TRUE_BOOLEAN;
                ocrQueueObj.PC_OcrTemplateType__c = ocrTemplateTypeObj.Id;
                ocrQueueObj.PC_SourceDocument__c = oDoc.Id;
                ocrQueueObj.PC_SourceContentId__c = contentVersionId;
                PC_Database.ins(ocrQueueObj, false);

                // Create OCR Response
                ocrResponseObj = new PC_OcrResponse__c();
                ocrResponseObj.PC_OcrQueue__c = ocrQueueObj.Id;
                ocrResponseObj.PC_OcrService__c = 'Amazon Textract';
                ocrResponseObj.PC_OcrStatus__c = 'OCR Enqueue';
                PC_Database.ins(ocrResponseObj, false);

                Test.stopTest();
            }
        }
        System.debug('The Trigger is DeActivated : ' + isTriggerActive);
    }
}