/*********************************************************************************
Class Name      : PC_OcrQueueUtil
Description     : Utility Methods releated to OCR Queue
Created By      : Deloitte
Created Date    : 22-Oct-21
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   	Description
-----------------------------------------------------------------------------------
Satheesh Kumar            22-Oct-2021              Initial Version(PC-8235)
*********************************************************************************/

public with sharing class PC_OcrQueueUtil {

    public inherited sharing class OcrAutomationTaskSetting {
        public String templateTypeName { get; set; }
        public Boolean notifyOnCompletion { get; set; }
        public OcrAutomationTaskSetting() {
            templateTypeName = PC_Constants.EMPTY_STRING;
            notifyOnCompletion = PC_Constants.FALSE_BOOLEAN;
        }
    }

    public inherited sharing class Request {
        public String documentId { get; set; }
        public String templateTypeId { get; set; }
        public Boolean notifyOnCompletion { get; set; }

        public Request() {
            this.documentId = PC_Constants.EMPTY_STRING;
            this.templateTypeId = PC_Constants.EMPTY_STRING;
            this.notifyOnCompletion = PC_Constants.FALSE_BOOLEAN;
        }
    }

    public inherited sharing class Response {
        public String status { get; set; }
        public String errorMessage { get; set; }
        public List<String> recordIds { get; set; }

        public Response() {
            this.status = PC_Constants.EMPTY_STRING;
            this.errorMessage = PC_Constants.EMPTY_STRING;
            this.recordIds = new List<String>();
        }
    }

    /*********************************************************************************
    Method Name    : getTemplateId
    Description    : method used to get the templateTypeId by using template type name
    Return Type    : String
    Parameter      : String
    *********************************************************************************/
    public static String getTemplateId(String templateTypeName){
        String templateId = PC_Constants.EMPTY_STRING;
        if (String.isNotBlank(templateTypeName)) {
            // FLS Check
            List<String> ocrTemplateTypeFields = new List<String>{PC_Constants.getQualifiedAPIName('PC_APIName__c')};
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_OcrTemplateType__c'), PC_Database.Operation.Reading, ocrTemplateTypeFields);
            List<PC_OcrTemplateType__c> templateTypeList = [SELECT Id, PC_APIName__c FROM PC_OcrTemplateType__c WHERE PC_APIName__c = :templateTypeName];
            if (templateTypeList.size() > 0) {
                templateId = templateTypeList[0].Id;
            }
        }
        return templateId;
    }

    /*********************************************************************************
    Method Name    : createOcrQueue
    Description    : method used to create OCR Queue
    Return Type    : Response
    Parameter      : Request
    *********************************************************************************/
    public static Response createOcrQueue(Request ocrQueueRequest, String runningUser) {
        Response response = new Response();
        PC_OcrQueue__c ocrQueue = new PC_OcrQueue__c();
        List<PC_OcrQueue__c> createdQueues = new List<PC_OcrQueue__c>();
        try {
            String documentContentId = getDocumentContentId(ocrQueueRequest.documentId);

            if(String.isBlank(documentContentId)) {
                throw new PC_OcrQueueUtilException(String.format('No files found in this document {0}. Therefore, the document is not queued to OCR', new List<String>{ocrQueueRequest.documentId}));
            }
            ocrQueue.PC_SourceDocument__c = ocrQueueRequest.documentId;
            ocrQueue.PC_Status__c = PC_Constants.PC_OCR_STATUS_QUEUED;
            ocrQueue.PC_OcrTemplateType__c = String.isNotBlank(ocrQueueRequest.templateTypeId) ? ocrQueueRequest.templateTypeId : null;
            ocrQueue.PC_IsActive__c = true;
            ocrQueue.PC_NotifyStatus__c = ocrQueueRequest.notifyOnCompletion;
            ocrQueue.PC_SourceContentId__c = documentContentId;
            ocrQueue.OwnerId = runningUser;
            PC_Database.ins(ocrQueue);
            createdQueues.add(ocrQueue);
            List<String> queueRecordIds = new List<String>();
            if (!createdQueues.isEmpty()) {
                queueRecordIds.addAll(new Map<String, PC_OcrQueue__c>(createdQueues).keySet());
            } else {
                throw new PC_OcrQueueUtilException('Something has gone wrong. No OCR Queues are created.');
            }
            response.recordIds = queueRecordIds;
            response.status = PC_Constants.SUCCESS;
        } catch (Exception ex) {
            response.status = PC_Constants.ERROR;
            response.errorMessage = ex.getMessage() + ex.getStackTraceString();
            PC_Utility.createExceptionLog(ex);
        }
        return response;
    }

    /*********************************************************************************
    Method Name    : getDocumentContentId
    Description    : method used to get the contentId(Attachment Id or File Content Version Id) of the document using document Id
    Return Type    : String
    Parameter      : String
    *********************************************************************************/
    public static String getDocumentContentId(String documentId) {
        String documentContentId = PC_Constants.EMPTY_STRING;
        try {
            Boolean useSalesforceFiles = PC_SYSTEM.useSalesforceFiles();
            Boolean useFileStrictMode = PC_SYSTEM.useDocumentPreviewInStrictMode();

            //FLS Check Attachment
            List<String> attachmentFields = new List<String>{'Id', 'Name'};
            PC_Database.assertAccess('Attachment', PC_Database.Operation.Reading, attachmentFields);
            List<Attachment> lstAttachment = [SELECT Id, Name FROM Attachment WHERE ParentId = :documentId ORDER BY createdDate DESC LIMIT 1];

            //FLS Check ContentDocumentLink
            List<String> cdlFields = new List<String>{'ContentDocumentId', 'ContentDocument.ContentModifiedDate', 'LinkedEntityId'};
            PC_Database.assertAccess('ContentDocumentLink', PC_Database.Operation.Reading, cdlFields);
            List<ContentDocumentLink> lstContentDocumentLink = [SELECT ContentDocumentId,ContentDocument.ContentModifiedDate FROM ContentDocumentLink WHERE LinkedEntityId = :documentId order by ContentDocument.ContentModifiedDate desc LIMIT 1];

            if ((useSalesforceFiles && lstContentDocumentLink.size() > 0) || (useSalesforceFiles && useFileStrictMode) ||
                    ((!useFileStrictMode && !useSalesforceFiles) && (lstContentDocumentLink.size() > 0 && lstAttachment.size() == 0))) {
                String contentDocumentId = lstContentDocumentLink[0].ContentDocumentId;
                if (String.isNotBlank(contentDocumentId)) {
                    //FLS Check
                    List<String> cvFields = new List<String>{'Id', 'FileExtension', 'FileType', 'ContentDocumentId'};
                    PC_Database.assertAccess('ContentVersion', PC_Database.Operation.Reading, cvFields);
                    documentContentId = [SELECT Id, FileExtension, FileType, ContentDocumentId FROM ContentVersion WHERE ContentDocumentId = :contentDocumentId AND IsLatest = true LIMIT 1] ?.Id;
                }
            } else {
                if (lstAttachment.size() > 0) {
                    documentContentId = lstAttachment[0].Id;
                }
            }
        } catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return documentContentId;
    }

    /********************************************************************
    Method Name    : validateOcrSetup
    Description    : method used to validate the OCR Service Setup
    Return Type    : void
    Parameter      : null
    *********************************************************************/
    public static void validateOcrSetup() {
        String useOCR = PC_SYSTEM.getPatientConnectSetting('PC_UseOCR', PC_Constants.FALSE_STRING);
        if (Boolean.valueOf(useOCR)) {
            String ocrService = PC_SYSTEM.getPatientConnectSetting(PC_Constants.PC_OCR_SERVICE_PROVIDER, PC_Constants.PC_OCR_SERVICE_AMAZON_TEXTRACT);
            if (Test.isRunningTest()) {
                ocrService = PC_Constants.PC_OCR_SERVICE_AMAZON_TEXTRACT;
            }
            if (String.isNotBlank(ocrService)) {
                if (ocrService.equalsIgnoreCase(PC_Constants.PC_OCR_SERVICE_AMAZON_TEXTRACT)) {
                    PC_OCR.getExtractService(PC_Constants.PC_DEFAULT_TEXTRACT_OCRSERVICE_CLASSNAME);
                } else {
                    PC_OCR.getExtractService(PC_Constants.EMPTY_STRING);
                }
            } else {
                throw new PC_OcrQueueUtilException(System.label.PC_OcrServiceNotConfigured);
            }
        } else {
            throw new PC_OcrQueueUtilException(System.label.PC_OcrFeatureNotEnabled);
        }
    }

    public inherited sharing class PC_OcrQueueUtilException extends Exception {}
}