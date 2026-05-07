/**
 * Created by sathekumar on 10/24/2021.
 */

@IsTest
private class PC_Test_OcrQueueUtil {

    private static User objUser;
    private static PC_Document__c oDoc;
    private static final String DOCUMENT_NAME = 'ocrTestDocumentText';
    private static final String DOCUMENT_NAME2 = 'ocrTestDocumentPdf';
    private static final String OCR_TEMPLATE_TYPE_NAME = 'testOcrTemplateType1';
    private static final String OCR_TEMPLATE_TYPE2_NAME = 'testOcrTemplateType2';
    private static final String OCR_TEMPLATE_MAPPING_NAME = 'testEnrollmentForm_CreateApplicant';
    private static final String USER_ALIAS = 'ocrUser1';
    private static final String USER_EMAIL = 'ocruser1@test.com';
    private static final String ENG_PROGRAM_NAME = 'Program';

    @testSetup static void createTestData(){
        //Insert User
        objUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, USER_EMAIL, USER_ALIAS);
        objUser = (User) PC_Database.ins(objUser);
        system.runAs(objUser){
            Id recordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.DOCUMENT_OBJECT, PC_Constants.DOCUMENT_FAX_INBOUND_RECORD_TYPE);
            // Create Document and attach Text file
            oDoc = PC_Test_Setup.createDocument(PC_Constants.DOCUMENT_FAX_INBOUND_RECORD_TYPE, PC_Constants.DOCUMENT_STATUS_REVIEW_NEEDED, ENG_PROGRAM_NAME + 'A');
            oDoc.RecordTypeId = recordTypeId;
            oDoc.PC_Document_Name__c = DOCUMENT_NAME;
            PC_Database.ins(oDoc, false);

            //Attach file to PC Document
            createTextFile(oDoc.Id);

            //Attach Attachment to PC Document
            Attachment pcAttachmentText = new Attachment();
            String name = 'abc';
            pcAttachmentText.body = Blob.valueof(name);
            pcAttachmentText.name = 'DemoName.txt';
            pcAttachmentText.ParentId = oDoc.Id;
            PC_Database.ins(pcAttachmentText, false);

            // Create DOcument and attach Pdf
            oDoc = new PC_Document__c();
            oDoc = PC_Test_Setup.createDocument(PC_Constants.DOCUMENT_FAX_INBOUND_RECORD_TYPE, PC_Constants.DOCUMENT_STATUS_REVIEW_NEEDED, ENG_PROGRAM_NAME + 'B');
            oDoc.RecordTypeId = recordTypeId;
            oDoc.PC_Document_Name__c = DOCUMENT_NAME2;
            PC_Database.ins(oDoc, false);

            //Attach file to PC Document
            PC_Test_Setup.createFile(oDoc.Id);

            //Attach Attachment to PC Document
            Attachment pcAttachmentPdf = PC_Test_Setup.createAttachment(oDoc.Id);
            PC_Database.ins(pcAttachmentPdf, false);

            //Create template type
            PC_OcrTemplateType__c ocrTemplateTypeObj = new PC_OcrTemplateType__c();
            ocrTemplateTypeObj.Name = OCR_TEMPLATE_TYPE_NAME;
            ocrTemplateTypeObj.PC_Label__c = OCR_TEMPLATE_TYPE_NAME;
            ocrTemplateTypeObj.PC_APIName__c = OCR_TEMPLATE_TYPE_NAME;
            ocrTemplateTypeObj.PC_IsActive__c = PC_Constants.TRUE_BOOLEAN;
            PC_Database.ins(ocrTemplateTypeObj, false);

            //Create template type 2
            PC_OcrTemplateType__c ocrTemplateTypeObj2 = new PC_OcrTemplateType__c();
            ocrTemplateTypeObj2.Name = OCR_TEMPLATE_TYPE2_NAME;
            ocrTemplateTypeObj2.PC_Label__c = OCR_TEMPLATE_TYPE2_NAME;
            ocrTemplateTypeObj2.PC_APIName__c = OCR_TEMPLATE_TYPE2_NAME;
            ocrTemplateTypeObj2.PC_IsActive__c = PC_Constants.TRUE_BOOLEAN;
            PC_Database.ins(ocrTemplateTypeObj2, false);

            //Create template type mappings
            PC_OcrTemplateMapping__c ocrTemplateMappingObj = new PC_OcrTemplateMapping__c();
            ocrTemplateMappingObj.Name = OCR_TEMPLATE_MAPPING_NAME;
            ocrTemplateMappingObj.PC_OcrTemplateType__c = ocrTemplateTypeObj.Id;
            ocrTemplateMappingObj.PC_TargetObject__c = PC_Constants.getQualifiedAPIName('PC_Applicant__c');
            ocrTemplateMappingObj.PC_IsActive__c = PC_Constants.TRUE_BOOLEAN;
            ocrTemplateMappingObj.PC_FieldMapping__c = '{"properties": {},"formFields":[{"formField": "First Name", "apiName": "'+PC_Constants.getQualifiedAPIName('PC_First_Name__c')+'"},'+
                    '{"formField": "Last Name", "apiName": "'+PC_Constants.getQualifiedAPIName('PC_Last_Name__c')+'"},'+
                    '{"formField": "Email", "apiName": "'+PC_Constants.getQualifiedAPIName('PC_Patient_Email__c')+'"},'+
                    '{"formField": "Date of Birth", "apiName": "'+PC_Constants.getQualifiedAPIName('PC_Date_of_Birth__c')+'"},'+
                    '{"formField": "Phone Number", "apiName": "'+PC_Constants.getQualifiedAPIName('PC_Phone__c')+'"},'+
                    '{"formField": "City", "apiName": "'+PC_Constants.getQualifiedAPIName('PC_City__c')+'"},'+
                    '{"formField": "State", "apiName": "'+PC_Constants.getQualifiedAPIName('PC_State__c')+'"},'+
                    '{"formField": "Zip", "apiName": "'+PC_Constants.getQualifiedAPIName('PC_Zip_Code__c')+'"}]}';
            PC_Database.ins(ocrTemplateMappingObj, false);
        }
    }

    @isTest static void testGetTemplateId() {
        String contentId;
        objUser = [Select Id from User where Alias =: USER_ALIAS];
        system.runAs(objUser){
            Test.startTest();
            contentId = PC_OcrQueueUtil.getTemplateId(OCR_TEMPLATE_TYPE_NAME);
            system.assertNotEquals(contentId, null);
            Test.stopTest();
        }
    }

    @isTest static void testCreateOcrQueue() {
        PC_OcrQueueUtil.Request ocrQueueRequest = new PC_OcrQueueUtil.Request();
        PC_OcrQueueUtil.Response response = new PC_OcrQueueUtil.Response();
        String contentId;
        objUser = [Select Id from User where Alias =: USER_ALIAS];
        system.runAs(objUser){
            Test.startTest();
            PC_Document__c docObj = [SELECT Id, PC_Document_Name__c FROM PC_Document__c WHERE PC_Document_Name__c =:DOCUMENT_NAME LIMIT 1];
            // check if document is fetched
            system.assertNotEquals(docObj.Id, null);
            ocrQueueRequest.documentId = docObj.Id;
            ocrQueueRequest.templateTypeId = PC_OcrQueueUtil.getTemplateId(OCR_TEMPLATE_TYPE_NAME);
            response = PC_OcrQueueUtil.createOcrQueue(ocrQueueRequest, objUser.Id);
            system.assertEquals(response.status, PC_Constants.SUCCESS);
            Test.stopTest();
        }
    }

    private static contentDocument createTextFile(String relatedRecordId){
        ContentVersion contentVer = new ContentVersion();
        contentVer.Title = 'SampleFile.txt';
        contentVer.PathOnClient = 'SampleFile.txt';
        contentVer.versiondata =  Blob.valueOf('Sample Text File');
        PC_Database.ins(contentVer, false);

        ContentDocument contentDoc = new ContentDocument();
        if(contentVer != null) {
            String contentDocumentId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :contentVer.id].ContentDocumentId;
            contentDoc = [SELECT Id, Title FROM ContentDocument WHERE Id =: contentDocumentId];
            if(string.isNotBlank(relatedRecordId)) {
                ContentDocumentLink cdl = new ContentDocumentLink();
                cdl.ContentDocumentId = contentDocumentId;
                cdl.LinkedEntityId = relatedRecordId;
                cdl.ShareType = 'V';
                PC_Database.ins(cdl);
            }
        }
        return contentDoc;
    }
}