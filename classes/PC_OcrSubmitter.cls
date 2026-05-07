/*****************************************************************************************
Class Name    	: PC_OcrSubmitter
Description     : Controller which helps to queue the document for OCR
Created By      : Deloitte
Created Date    : May 11, 2021
Modification Log:
--------------------------------------------------------------------------------------------
Developer                   Date                   Description
---------------------------------------------------------------------------------------------
Satheesh Kumar             May 11, 2021           Initial Version
*********************************************************************************************/

public with sharing class PC_OcrSubmitter {

    /*******************************************************************
    Method Name    : validateDocument
    Description    : method used to validate the OCR document
    Return Type    : void
    Parameter      : String (documentId)
    *******************************************************************/
    public static String getDocumentExtension(String documentId) {
        String extension;
        Boolean useSalesforceFiles = PC_SYSTEM.useSalesforceFiles();
        Boolean useFileStrictMode = PC_SYSTEM.useDocumentPreviewInStrictMode();

        //FLS Check Attachment
        List<String> attachmentFields = new List<String>{'Id', 'Name'};
        PC_Database.assertAccess('Attachment', PC_Database.Operation.Reading, attachmentFields);
        List<Attachment> lstAttachment = [SELECT Id, Name FROM Attachment WHERE ParentId = :documentId order by createdDate desc LIMIT 1];

        //FLS Check ContentDocumentLink
        List<String> cdlFields = new List<String>{'ContentDocumentId', 'ContentDocument.ContentModifiedDate', 'LinkedEntityId'};
        PC_Database.assertAccess('ContentDocumentLink', PC_Database.Operation.Reading, cdlFields);
        List<ContentDocumentLink> lstContentDocumentLink = [SELECT ContentDocumentId,ContentDocument.ContentModifiedDate FROM ContentDocumentLink WHERE LinkedEntityId = :documentId order by ContentDocument.ContentModifiedDate desc LIMIT 1];

        if((useSalesforceFiles && lstContentDocumentLink.size() > 0) || (useSalesforceFiles && useFileStrictMode && lstContentDocumentLink.size() > 0) ||
                ((!useFileStrictMode && !useSalesforceFiles) && (lstContentDocumentLink.size() > 0 && lstAttachment.size() == 0))){
            String contentDocumentId = lstContentDocumentLink[0].ContentDocumentId;
            if (String.isNotBlank(contentDocumentId)) {
                //FLS Check
                List<String> cvFields = new List<String>{'Id', 'FileExtension', 'FileType', 'ContentDocumentId'};
                PC_Database.assertAccess('ContentVersion', PC_Database.Operation.Reading, cvFields);
                extension = [SELECT Id, FileExtension, FileType, ContentDocumentId FROM ContentVersion WHERE ContentDocumentId = :contentDocumentId AND IsLatest = true LIMIT 1] ?.FileExtension;
            }
        } else {
            if(lstAttachment.size() > 0){
                String attName = lstAttachment[0].Name;
                if (String.isNotBlank(attName)) {
                    List<String> parts = (attName.toLowerCase()).splitByCharacterType();
                    extension = parts[parts.size() - 1];
                }
            }
        }
        return extension;
    }

    /**
     * Method helps to check the document extension is valid for OCR
     * @param documentId Id of the document
     */
    @AuraEnabled
    public static void validateDocument(String documentId) {
        String extension;
        Boolean isValid;
        try {
            extension = getDocumentExtension(documentId);
            if (String.isNotBlank(extension)) {
                isValid = isExtensionValidForOCR(extension.toLowerCase());
                if (!isValid) {
                    throw new AuraHandledException(System.label.PC_InvalidDocumentTypeMessage);
                }
            } else {
                throw new AuraHandledException(System.label.PC_NoFilesFoundMessage);
            }
        } catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
    }

    /**
     * Method helps to check the document is ready for OCR.
     * @param documentId  Id of the document
     */
    @AuraEnabled
    public static void checkDocumentReadyForOCR(String documentId) {
        Boolean isValid;
        try {
            //FLS Check
            List<String> ocrQueueFields = new List<String>{PC_Constants.getQualifiedAPIName('PC_SourceDocument__c'), PC_Constants.getQualifiedAPIName('PC_Status__c'), PC_Constants.getQualifiedAPIName('PC_IsActive__c')};
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_OcrQueue__c'), PC_Database.Operation.Reading, ocrQueueFields);
            if (String.isNotBlank(documentId)) {
                List<PC_OcrQueue__c> queueList = [
                        SELECT Id, PC_SourceDocument__c, PC_Status__c, PC_IsActive__c
                        FROM PC_OcrQueue__c
                        WHERE PC_SourceDocument__c = :documentId AND PC_Status__c IN ('Queued', 'In Progress') AND PC_IsActive__c = true
                ];
                if (queueList.size() > 0) {
                    throw new AuraHandledException(System.label.PC_OcrInProgressMessage);
                }
            }
        } catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
    }

    /********************************************************************
    Method Name    : validateOcrSetup
    Description    : method used to validate the OCR Service Setup
    Return Type    : void
    Parameter      : null
    *********************************************************************/

    @AuraEnabled
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
                throw new AuraHandledException(System.label.PC_OcrServiceNotConfigured);
            }
        } else {
            throw new AuraHandledException(System.label.PC_OcrFeatureNotEnabled);
        }
    }

    /**
     * Method helps to validate the template type mapping object with applicant of the document record.
     * If Applicant already exists, then it will return the validation message.
     * @param documentId  Id of the document
     * @param templateTypeId  Id of the OCR template type
     */
    @AuraEnabled
    public static validationMessage validateTemplateWithDocument(String documentId, String templateTypeId) {
        ValidationMessage validationMessage = new ValidationMessage();
        // Check FLS for PC_Document__c
        List<String> pcDocumentFields = new List<String>{'Id', PC_Constants.getQualifiedAPIName('PC_Applicant__c')};
        PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Document__c'), PC_Database.Operation.Reading, pcDocumentFields);
        PC_Document__c documentObj = [SELECT Id, PC_Applicant__c FROM PC_Document__c WHERE Id = :documentId];
        List<PC_OcrTemplateMapping__c> templateMappings = getOcrTemplateMapping(templateTypeId);
        if (templateMappings.size() == 0) {
            validationMessage.errorMessages.add(System.label.PC_NoActiveMappingsForSelectedTemplate);
        }
        for (PC_OcrTemplateMapping__c mapping : templateMappings) {
            if (mapping.PC_TargetObject__c == PC_Constants.CANDIDATE_PATIENT_OBJECT) {
                if (isEnrollmentCaseExists(documentId)) {
                    validationMessage.warningMessages.add(System.label.PC_EnrollmentCaseAlreadyExistsWarning);
                } else if (String.isNotBlank(documentObj.PC_Applicant__c)) {
                    validationMessage.warningMessages.add(System.label.PC_ApplicantLinkedAlreadyWarning);
                }
            }
        }
        return validationMessage;
    }

    /**
     * Method checks enrollment case exists for the document record
     * @param documentId  Id of the document
     */
    private static Boolean isEnrollmentCaseExists(String documentId) {
        Id recordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.PC_CASE, PC_Constants.CASE_ENROLLMENT_RECORD_TYPE);
        List<PC_Document_Log__c> docLog = [
                SELECT PC_Program__c, PC_Program__r.RecordTypeId
                FROM PC_Document_Log__c
                WHERE PC_Document__c = :documentId
                AND (PC_Program__r.RecordTypeId = :recordTypeId)
                LIMIT 1
        ];
        if (docLog.isEmpty()) {
            return false;
        } else {
            return true;
        }
    }

    /**
     * Method returns the OCR template mappings for the template type
     * @param templateTypeId  Id of the OCR template type
     */
    public static List<PC_OcrTemplateMapping__c> getOcrTemplateMapping(String templateTypeId) {
        List<PC_OcrTemplateMapping__c> templateMappings = new List<PC_OcrTemplateMapping__c>();
        templateMappings = [SELECT Id, PC_OcrTemplateType__c, PC_TargetObject__c, PC_IsActive__c FROM PC_OcrTemplateMapping__c WHERE PC_IsActive__c = true AND PC_OcrTemplateType__c = :templateTypeId];
        return templateMappings;
    }

    /********************************************************************
    Method Name    : enqueueDocument
    Description    : method used to enqueue the document for OCR
    Return Type    : String
    Parameter      : String (documentInfoJSON)
    *********************************************************************/

    @AuraEnabled
    public static DocumentQueueInfo enqueueDocument(String documentInfoJSON) {
        DocumentQueueInfo queueInfo = new DocumentQueueInfo();
        PC_OcrQueue__c ocrQueue = new PC_OcrQueue__c();
        try {
            DocumentInfo documentInfoObj = new DocumentInfo();
            documentInfoObj = (DocumentInfo) JSON.deserialize(documentInfoJSON, DocumentInfo.class);
            system.debug('documentInfo--->' + documentInfoObj);
            String documentContentId = PC_OcrQueueUtil.getDocumentContentId(documentInfoObj.documentId);
            ocrQueue.PC_SourceDocument__c = documentInfoObj.documentId;
            ocrQueue.PC_Status__c = PC_Constants.PC_OCR_STATUS_QUEUED;
            ocrQueue.PC_OcrTemplateType__c = documentInfoObj.templateTypeId;
            ocrQueue.PC_IsActive__c = true;
            ocrQueue.PC_NotifyStatus__c = documentInfoObj.notifyOnCompletion;
            ocrQueue.PC_SourceContentId__c = documentContentId;
            PC_Database.ins(ocrQueue);
            queueInfo.queueId = ocrQueue.Id;
            queueInfo.name = [SELECT Id, Name FROM PC_OcrQueue__c WHERE id = :ocrQueue.Id] ?.Name;
        } catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return queueInfo;
    }

    /********************************************************************
    Method Name    : isExtensionValidForOCR
    Description    : Return true if the extension is valid for OCR Process
    Return Type    : Boolean
    Parameter      : extension
    *********************************************************************/
    public static Boolean isExtensionValidForOCR(String extension) {
        //set<String> setExtAllowed = new set<String>{'jpg', 'jpeg', 'png', 'pdf'};
        List<String> setExtAllowed = getSupportedFileTypes();
        if (setExtAllowed.contains(extension)) {
            return true;
        }
        return false;
    }

    /**
     * This method returns the Supported File Types for the OCR to Process
     */
    public static List<String> getSupportedFileTypes() {
        List<String> supportedFileTypes = new List<String>();
        String useOCR = PC_Constants.EMPTY_STRING;
        try {
            useOCR = PC_SYSTEM.getPatientConnectSetting('PC_UseOCR', PC_Constants.FALSE_STRING);
            if (Boolean.valueOf(useOCR)) {
                String ocrService = PC_SYSTEM.getPatientConnectSetting(PC_Constants.PC_OCR_SERVICE_PROVIDER, PC_Constants.PC_OCR_SERVICE_AMAZON_TEXTRACT);
                if (Test.isRunningTest()) {
                    ocrService = PC_Constants.PC_OCR_SERVICE_AMAZON_TEXTRACT;
                }
                if (String.isNotBlank(ocrService)) {
                    if (ocrService.equalsIgnoreCase(PC_Constants.PC_OCR_SERVICE_AMAZON_TEXTRACT)) {
                        PC_OCR.ExtractDocument handler = PC_OCR.getExtractService(PC_Constants.PC_DEFAULT_TEXTRACT_OCRSERVICE_CLASSNAME);
                        supportedFileTypes = handler.getSupportedFileTypes();
                    } else {
                        PC_OCR.ExtractDocument handler = PC_OCR.getExtractService(PC_Constants.EMPTY_STRING);
                        supportedFileTypes = handler.getSupportedFileTypes();
                    }
                } else {
                    throw new AuraHandledException(System.label.PC_OcrServiceNotConfigured);
                }
            } else {
                throw new AuraHandledException(System.label.PC_OcrFeatureNotEnabled);
            }
        } catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return supportedFileTypes;
    }

    /********************************************************************
    Method Name    : getDocumentContentId
    Description    : returns ContentId (ContentVersionId or AttachmentId) of the document
    Return Type    : String
    Parameter      : documentId
    *********************************************************************/
    public static String getDocumentContentId(String documentId) {
        String documentContentId;
        try {
            Boolean useSalesforceFiles = PC_SYSTEM.useSalesforceFiles();
            if (useSalesforceFiles) {
                //FLS Check
                List<String> cdlFields = new List<String>{'ContentDocumentId', 'ContentDocument.ContentModifiedDate', 'LinkedEntityId'};
                PC_Database.assertAccess('ContentDocumentLink', PC_Database.Operation.Reading, cdlFields);
                String contentDocumentId = [SELECT ContentDocumentId,ContentDocument.ContentModifiedDate FROM ContentDocumentLink WHERE LinkedEntityId = :documentId order by ContentDocument.ContentModifiedDate desc LIMIT 1] ?.ContentDocumentId;
                if (String.isNotBlank(contentDocumentId)) {
                    //FLS Check
                    List<String> cvFields = new List<String>{'Id', 'FileExtension', 'FileType', 'ContentDocumentId'};
                    PC_Database.assertAccess('ContentVersion', PC_Database.Operation.Reading, cvFields);
                    documentContentId = [SELECT Id, FileExtension, FileType, ContentDocumentId FROM ContentVersion WHERE ContentDocumentId = :contentDocumentId AND IsLatest = true LIMIT 1] ?.Id;
                }
            } else {
                //FLS Check
                List<String> attachmentFields = new List<String>{'Id', 'Name'};
                PC_Database.assertAccess('Attachment', PC_Database.Operation.Reading, attachmentFields);
                documentContentId = [SELECT Id, Name FROM Attachment WHERE ParentId = :documentId ORDER BY createdDate DESC LIMIT 1] ?.Id;
            }
        } catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return documentContentId;
    }

    public inherited sharing class DocumentInfo {
        @AuraEnabled public String documentId { get; set; }
        @AuraEnabled public String templateTypeId { get; set; }
        @AuraEnabled public Boolean notifyOnCompletion { get; set; }

        public DocumentInfo() {
            this.documentId = PC_Constants.EMPTY_STRING;
            this.templateTypeId = PC_Constants.EMPTY_STRING;
            this.notifyOnCompletion = PC_Constants.FALSE_BOOLEAN;
        }
    }

    public inherited sharing class DocumentQueueInfo {
        @AuraEnabled public String queueId { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String objectApiName { get; set; }

        public DocumentQueueInfo() {
            this.queueId = PC_Constants.EMPTY_STRING;
            this.name = PC_Constants.EMPTY_STRING;
            this.objectApiName = PC_Constants.getQualifiedAPIName('PC_OcrQueue__c');
        }
    }

    public inherited sharing class ValidationMessage {
        @AuraEnabled public List<String> errorMessages { get; set; }
        @AuraEnabled public List<String> warningMessages { get; set; }

        public ValidationMessage() {
            errorMessages = new List<String>();
            warningMessages = new List<String>();
        }
    }


    public inherited sharing class PC_OcrSubmitterException extends Exception {
    }
}