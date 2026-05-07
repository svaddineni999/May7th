/**
 * Created by sathekumar on 10/10/2021.
 */

public with sharing class PC_OcrReviewDocumentController {
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

        if ((useSalesforceFiles && lstContentDocumentLink.size() > 0) || (useSalesforceFiles && useFileStrictMode && lstContentDocumentLink.size() > 0) ||
                ((!useFileStrictMode && !useSalesforceFiles) && (lstContentDocumentLink.size() > 0 && lstAttachment.size() == 0))) {
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

    @AuraEnabled
    public static DocumentInfo getDocumentInfo(String documentId, String templateCategoriesString) {
        DocumentInfo documentInfo = new DocumentInfo();
        List<String> templateCategories = (List<String>) JSON.deserialize(templateCategoriesString, List<String>.class);
        String templateTypeId = PC_Constants.EMPTY_STRING;
        system.debug('templateCategories-->'+templateCategories);
        try {
            //FLS Check Document
            List<String> documentFields = new List<String>{PC_Constants.getQualifiedAPIName('PC_Document_Name__c'), PC_Constants.getQualifiedAPIName('PC_Engagement_Program__c'), PC_Constants.getQualifiedAPIName('PC_EngagementProgramCode__c'), PC_Constants.getQualifiedAPIName('PC_Document_Category__c')};
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Document__c'), PC_Database.Operation.Reading, documentFields);
            // Document
            List<PC_Document__c> documentList = [
                    SELECT Id, Name, PC_Document_Name__c, PC_Engagement_Program__c, PC_EngagementProgramCode__c, PC_Document_Category__c
                    FROM PC_Document__c
                    WHERE Id = :documentId
            ];
            if(documentList.size() > 0){
                documentInfo.documentObj = documentList[0];
            }

            if (String.isNotBlank(documentId)) {
                // FLS Check PC_OcrQueue__c
                List<String> ocrQueueFields = new List<String>{PC_Constants.getQualifiedAPIName('PC_SourceDocument__c'), PC_Constants.getQualifiedAPIName('PC_Status__c'), PC_Constants.getQualifiedAPIName('PC_IsActive__c')};
                PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_OcrQueue__c'), PC_Database.Operation.Reading, ocrQueueFields);
                List<PC_OcrQueue__c> queueList = [
                        SELECT Id, PC_SourceDocument__c, PC_Status__c, PC_IsActive__c, PC_OcrTemplateType__c, PC_OcrTemplateType__r.Name
                        FROM PC_OcrQueue__c
                        WHERE PC_SourceDocument__c = :documentId
                        ORDER BY LastModifiedDate DESC
                        LIMIT 1
                ];
                if (queueList.size() > 0) {
                    documentInfo.ocrQueue = queueList[0];
                    if (String.isNotBlank(queueList[0].PC_OcrTemplateType__c)) {
                        templateTypeId = queueList[0].PC_OcrTemplateType__c;
                        documentInfo.isTemplateTypeIdPreConfigured = PC_Constants.TRUE_BOOLEAN;
                        documentInfo.templateTypeId = templateTypeId;
                        documentInfo.templateTypeName = queueList[0].PC_OcrTemplateType__r.Name;
                    } else {
                        String engagementProgram = documentInfo.documentObj ?.PC_Engagement_Program__c;
                        system.debug('engagementProgram--->' + engagementProgram);
                        if (String.isNotBlank(engagementProgram)) {
                            PC_OcrTemplateSelection.TemplateTypeSetting templateTypeSetting = new PC_OcrTemplateSelection.TemplateTypeSetting();
                            templateTypeSetting = tryAutoPickingTemplateType(engagementProgram, templateCategories); //new List<String>{'Prescription'});
                            if (templateTypeSetting != null) {
                                documentInfo.templateTypeId = templateTypeSetting.value;
                                documentInfo.templateTypeName = templateTypeSetting.label;
                                documentInfo.isTemplateTypeAutoSelected = PC_Constants.TRUE_BOOLEAN;
                                templateTypeId = documentInfo.templateTypeId;
                            }
                        }
                    }

                    // FLS Check PC_OcrResponse__c
                    List<String> ocrResponseFields = new List<String>{PC_Constants.getQualifiedAPIName('PC_OcrQueue__c'), PC_Constants.getQualifiedAPIName('PC_OcrStatus__c'), PC_Constants.getQualifiedAPIName('PC_OcrService__c')};
                    PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_OcrResponse__c'), PC_Database.Operation.Reading, ocrResponseFields);
                    List<PC_OcrResponse__c> ocrResponseList = [
                            SELECT Id, PC_OcrQueue__c, PC_OcrStatus__c, PC_OcrService__c
                            FROM PC_OcrResponse__c
                            WHERE PC_OcrStatus__c = :PC_Constants.PC_OCR_STATUS_SUCCESS and PC_OcrQueue__c = :documentInfo.ocrQueue.Id
                            ORDER BY LastModifiedDate DESC
                            LIMIT 1
                    ];
                    if (ocrResponseList.size() > 0) {
                        documentInfo.ocrResponse = ocrResponseList[0];
                    }

                    // FLS Check PC_OcrResult__c
                    List<String> ocrResultFields = new List<String>{
                            PC_Constants.getQualifiedAPIName('PC_OcrQueue__c'), PC_Constants.getQualifiedAPIName('PC_OcrResponse__c'), PC_Constants.getQualifiedAPIName('PC_ResultingRecordId__c'), PC_Constants.getQualifiedAPIName('PC_ResultStatus__c')
                    };
                    PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_OcrResult__c'), PC_Database.Operation.Reading, ocrResultFields);
                    // PC_OcrResult__c
                    documentInfo.ocrResults = [
                            SELECT Id, PC_OcrQueue__c, PC_OcrResponse__c, PC_ResultingRecordId__c, PC_ResultStatus__c
                            FROM PC_OcrResult__c
                            WHERE PC_ResultStatus__c = :PC_Constants.PC_OCR_STATUS_SUCCESS and PC_OcrQueue__c = :documentInfo.ocrQueue.Id
                    ];

                } else {
                    String engagementProgram = documentInfo.documentObj ?.PC_Engagement_Program__c;
                    system.debug('engagementProgram--->' + engagementProgram);
                    if (String.isNotBlank(engagementProgram)) {
                        PC_OcrTemplateSelection.TemplateTypeSetting templateTypeSetting = new PC_OcrTemplateSelection.TemplateTypeSetting();
                        templateTypeSetting = tryAutoPickingTemplateType(engagementProgram, templateCategories); //new List<String>{'Prescription'});
                        if (templateTypeSetting != null) {
                            documentInfo.templateTypeId = templateTypeSetting.value;
                            documentInfo.templateTypeName = templateTypeSetting.label;
                            documentInfo.isTemplateTypeAutoSelected = PC_Constants.TRUE_BOOLEAN;
                            templateTypeId = documentInfo.templateTypeId;
                        }
                    }
                }

                if (String.isNotBlank(templateTypeId)) {
                    // FLS Check PC_OcrTemplateType__c
                    List<String> ocrTemplateTypeFields = new List<String>{PC_Constants.getQualifiedAPIName('PC_IsActive__c'), PC_Constants.getQualifiedAPIName('PC_Label__c')
                    };
                    PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_OcrTemplateType__c'), PC_Database.Operation.Reading, ocrTemplateTypeFields);
                    // PC_OcrTemplateType__c
                    List<PC_OcrTemplateType__c> templateTypeList = [
                            SELECT Id, Name, PC_IsActive__c, PC_Label__c
                            FROM PC_OcrTemplateType__c
                            WHERE PC_IsActive__c = true and Id = :templateTypeId
                    ];
                    if (templateTypeList.size() > 0) {
                        documentInfo.templateType = templateTypeList[0];
                        // FLS Check PC_OcrTemplateMapping__c
                        List<String> ocrTemplateMappingFields = new List<String>{PC_Constants.getQualifiedAPIName('PC_OcrTemplateType__c'), PC_Constants.getQualifiedAPIName('PC_TargetObject__c'), PC_Constants.getQualifiedAPIName('PC_TargetObjectRecordType__c')};
                        PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_OcrTemplateMapping__c'), PC_Database.Operation.Reading, ocrTemplateMappingFields);
                        documentInfo.ocrTemplateMappings = [SELECT Id, Name, PC_OcrTemplateType__c, PC_TargetObject__c, PC_TargetObjectRecordType__c FROM PC_OcrTemplateMapping__c WHERE PC_IsActive__c = true AND PC_OcrTemplateType__c = :templateTypeId];
                        // Get RecordType Id
                        if ((documentInfo.ocrTemplateMappings).size() > 0 && String.isNotBlank(documentInfo.ocrTemplateMappings[0].PC_TargetObject__c)) {
                            Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(documentInfo.ocrTemplateMappings[0].PC_TargetObject__c);
                            Schema.DescribeSObjectResult describeSObjectResult = sObjectType.getDescribe();
                            if (String.isNotBlank(documentInfo.ocrTemplateMappings[0].PC_TargetObjectRecordType__c)) {
                                Map<String, Id> recordTypeIdMap = PC_OcrResponseHelper.getSObjectRecordTypeMap(documentInfo.ocrTemplateMappings[0].PC_TargetObject__c);
                                documentInfo.targetObjectRecordTypeId = recordTypeIdMap.get(documentInfo.ocrTemplateMappings[0].PC_TargetObjectRecordType__c);
                            } else {
                                List<Schema.RecordTypeInfo> rtInfos = describeSObjectResult.getRecordTypeInfos();
                                for (Schema.RecordTypeInfo rtInfo : rtInfos) {
                                    if (rtInfo.isDefaultRecordTypeMapping()) {
                                        documentInfo.targetObjectRecordTypeId = rtInfo.getRecordTypeId();
                                        break;
                                    }
                                }
                            }
                            documentInfo.targetObjectLabel = describeSObjectResult.getLabel();
                        }
                    }
                }
            }
        } catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return documentInfo;
    }

    @AuraEnabled
    public static OcrDocumentResponse getOcrDocumentFieldsMap(String templateTypeId, String ocrResponseId) {
        OcrDocumentResponse ocrDocumentResponse = new OcrDocumentResponse();
        Map<String, String> fieldValueMap = new Map<String, String> ();
        String extractedValues = PC_Constants.EMPTY_STRING;
        try {
            Map<Id, List<PC_OcrTemplateMapping__c>> ocrTemplateMappingMap = PC_OcrResponseHelper.getOcrTemplateMapping(new Set<Id>{templateTypeId});
            if(String.isNotBlank(ocrResponseId)){
                extractedValues = PC_OcrResponseHelper.parseOcrResponse(ocrResponseId);
            }
            if(ocrTemplateMappingMap.get(templateTypeId) != null && ocrTemplateMappingMap.get(templateTypeId).size() > 0) {
                List<PC_OcrTemplateMapping__c> ocrTemplateMappings = ocrTemplateMappingMap.get(templateTypeId);
                ocrDocumentResponse.ocrTemplateMappings = ocrTemplateMappings;
                // Get RecordType Id
                if (String.isNotBlank(ocrTemplateMappings[0].PC_TargetObject__c)) {
                    Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(ocrTemplateMappings[0].PC_TargetObject__c);
                    Schema.DescribeSObjectResult describeSObjectResult = sObjectType.getDescribe();
                    if (String.isNotBlank(ocrTemplateMappings[0].PC_TargetObjectRecordType__c)) {
                        Map<String, Id> recordTypeIdMap = PC_OcrResponseHelper.getSObjectRecordTypeMap(ocrTemplateMappings[0].PC_TargetObject__c);
                        ocrDocumentResponse.recordTypeId = recordTypeIdMap.get(ocrTemplateMappings[0].PC_TargetObjectRecordType__c);

                        //Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(ocrTemplateMappings[0].PC_TargetObject__c);
                        //Schema.DescribeSObjectResult describeSObjectResult = sObjectType.getDescribe();
                        //ocrDocumentResponse.recordTypeId = describeSObjectResult.getRecordTypeInfosByDeveloperName().get(ocrTemplateMappings[0].PC_TargetObjectRecordType__c).getRecordTypeId();
                    } else {
                        List<Schema.RecordTypeInfo> rtInfos = describeSObjectResult.getRecordTypeInfos();
                        for (Schema.RecordTypeInfo rtInfo : rtInfos) {
                            if (rtInfo.isDefaultRecordTypeMapping()) {
                                ocrDocumentResponse.recordTypeId = rtInfo.getRecordTypeId();
                                break;
                            }
                        }
                    }
                    ocrDocumentResponse.objectLabel = describeSObjectResult.getLabel();
                }
                if(String.isNotBlank(extractedValues)) {
                    fieldValueMap = PC_OcrResponseHelper.createObjectFieldAndResponseMap(extractedValues, ocrTemplateMappings[0].PC_FieldMapping__c);
                    ocrDocumentResponse.fieldValueMap = fieldValueMap;
                }
            } else {
                throw new PC_OcrReviewDocumentException(System.Label.PC_NoActiveTemplateMappingFound);
            }
            return ocrDocumentResponse;
        } catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
            return null;
        }
    }

    public static PC_OcrTemplateSelection.TemplateTypeSetting tryAutoPickingTemplateType(String engProgram, List<String> categoryList){
        List<PC_OcrTemplateSelection.TemplateTypeSetting> templateTypeSettings = new List<PC_OcrTemplateSelection.TemplateTypeSetting>();
        List<String> validCategory = PC_OcrTemplateSelection.checkAndRemoveInvalidCategory(categoryList);
        templateTypeSettings = PC_OcrTemplateSelection.getTemplateTypes(engProgram, validCategory);
        if(templateTypeSettings.size() == 1){
            return templateTypeSettings[0];
        } else {
            return null;
        }
    }

    @AuraEnabled
    public static void createLinkLog(String documentId, String targetRecordId){
        PC_Document_Log__c pcDocumentLog = new PC_Document_Log__c();
        String associationRecordName = PC_Constants.EMPTY_STRING;
        String recordTypeName = PC_Constants.EMPTY_STRING;
        String objectLabel = PC_Constants.EMPTY_STRING;
        String sObjectType = PC_Constants.EMPTY_STRING;
        try {
            Map<String, Schema.SObjectType> sObjectMap = Schema.getGlobalDescribe();
            sObjectType = String.valueOf(Id.valueOf(targetRecordId).getSobjectType());
            objectLabel = sObjectMap.get(sObjectType).getDescribe().getLabel();
            if(sObjectType != PC_Constants.CANDIDATE_PATIENT_OBJECT) {
                if (!isLinkLogExists(documentId, targetRecordId)) {
                    recordTypeName = PC_Utility.getRecordTypeNameByRecordId(targetRecordId);

                    List<sObject> sObj = new List<sObject>();
                    String query = 'Select Id, Name from ' + sObjectType + ' where id = \'' + targetRecordId + '\'';
                    sObj = PC_Database.queryWithAccess(query, false);
                    if (!sObj.isEmpty()) {
                        associationRecordName = (String) sObj[0].get('Name');
                    }
                    pcDocumentLog.PC_Document__c = documentId;
                    pcDocumentLog.PC_Association_Record_ID__c = targetRecordId;
                    pcDocumentLog.PC_Association_Record_Name__c = associationRecordName;
                    pcDocumentLog.PC_Association_Type__c = (String.isNotBlank(recordTypeName)) ? objectLabel + ': ' + recordTypeName : objectLabel;
                    PC_Database.ins(pcDocumentLog);
                }
            } else {
                //FLS Check Document
                List<String> documentFields = new List<String>{PC_Constants.getQualifiedAPIName('PC_Applicant__c')};
                PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Document__c'), PC_Database.Operation.Reading, documentFields);
                // Document
                List<PC_Document__c> documentList = [SELECT Id, PC_Applicant__c FROM PC_Document__c WHERE Id = :documentId AND PC_Applicant__c = null];
                if(documentList.size() > 0){
                    documentList[0].PC_Applicant__c = targetRecordId;
                    PC_Database.upd(documentList[0]);
                }
            }
        } catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
    }

    private static Boolean isLinkLogExists(String documentId, String targetRecordId){
        try {
            //FLS Check PC_Document_Log__c
            List<String> fields = new List<String>{PC_Constants.getQualifiedAPIName('PC_Document_Log__c'), PC_Constants.getQualifiedAPIName('PC_Program__c'), 'LastModifiedBy', 'LastModifiedDate', PC_Constants.getQualifiedAPIName('PC_Association_Record_Id__c'), PC_Constants.getQualifiedAPIName('PC_Association_Type__c'), PC_Constants.getQualifiedAPIName('PC_Association_Record_Name__c'), PC_Constants.getQualifiedAPIName('PC_Document__c')};
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Document_Log__c'), PC_Database.Operation.Reading, fields);

            List<PC_Document_Log__c> lstDocLogs = [
                    SELECT Name, PC_Document_Log__c, PC_Association_Record_Id__c, PC_Association_Type__c, PC_Association_Record_Name__c
                    FROM PC_Document_Log__c
                    WHERE PC_Document__c = :documentId AND PC_Association_Record_Id__c = :targetRecordId
            ];
            if (lstDocLogs.size() > 0) {
                return true;
            }
        } catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return false;
    }

    @AuraEnabled
    public static void completeOcrQueueAndCreateOcrResults(String ocrQueueId, String targetRecordId, String templateTypeId){
        system.debug('Create OCR Results'+templateTypeId);
        try {
            /*FLS Check for OCR Queue fields*/
            List<String> ocrQueueFields = new List<String>{PC_Constants.getQualifiedAPIName('PC_Status__c'), PC_Constants.getQualifiedAPIName('PC_OcrTemplateType__c'), PC_Constants.getQualifiedAPIName('PC_IsActive__c')};
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_OcrQueue__c'), PC_Database.Operation.Reading, ocrQueueFields);

            List<PC_OcrQueue__c> ocrQueueList = [Select Id, PC_Status__c, PC_OcrTemplateType__c, PC_IsActive__c FROM PC_OcrQueue__c where Id =:ocrQueueId];
            if (ocrQueueList.size() > 0 && ocrQueueList[0].PC_Status__c != PC_Constants.PC_OCR_QUEUE_STATUS_COMPLETED) {
                createOcrResults(ocrQueueId, targetRecordId);
                ocrQueueList[0].PC_Status__c = PC_Constants.PC_OCR_QUEUE_STATUS_COMPLETED;
                ocrQueueList[0].PC_IsActive__c = PC_Constants.FALSE_BOOLEAN;
                ocrQueueList[0].PC_OcrTemplateType__c = templateTypeId;
                PC_Database.upd(ocrQueueList[0]);
            }
        } catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
    }

    public static List<PC_OcrResult__c> createOcrResults(String ocrQueueId, String targetRecordId) {
        List<PC_OcrResult__c> ocrResults = new List<PC_OcrResult__c>();
        PC_OcrResult__c ocrResult = new PC_OcrResult__c();
        ocrResult.PC_ResultingRecordId__c = targetRecordId;
        ocrResult.PC_ResultStatus__c = 'Success';
        ocrResult.PC_OcrQueue__c = ocrQueueId;
        ocrResults.add(ocrResult);
        PC_Database.ins(ocrResults);
        return ocrResults;
    }

    public inherited sharing class OcrDocumentResponse{
        @AuraEnabled
        public Map<String, String> fieldValueMap;
        @AuraEnabled
        public String recordTypeId;
        @AuraEnabled
        public String objectLabel;
        @AuraEnabled
        public List<PC_OcrTemplateMapping__c> ocrTemplateMappings;

        public OcrDocumentResponse() {
            this.fieldValueMap = new Map<String, String> ();
            this.ocrTemplateMappings = new List<PC_OcrTemplateMapping__c> ();
            this.recordTypeId = PC_Constants.EMPTY_STRING;
            this.objectLabel = PC_Constants.EMPTY_STRING;
        }
    }

    public inherited sharing class DocumentInfo{
        @AuraEnabled
        public PC_Document__c documentObj;
        @AuraEnabled
        public PC_OcrQueue__c ocrQueue;
        @AuraEnabled
        public PC_OcrResponse__c ocrResponse;
        @AuraEnabled
        public PC_OcrTemplateType__c templateType;
        @AuraEnabled
        public String templateTypeId;
        @AuraEnabled
        public String templateTypeName;
        @AuraEnabled
        public Boolean isTemplateTypeIdPreConfigured;
        @AuraEnabled
        public Boolean isTemplateTypeAutoSelected;
        @AuraEnabled
        public String targetObjectRecordTypeId;
        @AuraEnabled
        public String targetObjectLabel;
        @AuraEnabled
        public List<PC_OcrTemplateMapping__c> ocrTemplateMappings;
        @AuraEnabled
        public List<PC_OcrResult__c> ocrResults;

        public DocumentInfo(){
            this.documentObj = new PC_Document__c();
            this.ocrQueue = new PC_OcrQueue__c();
            this.ocrResponse = new PC_OcrResponse__c();
            this.templateType = new PC_OcrTemplateType__c();
            this.templateTypeId = PC_Constants.EMPTY_STRING;
            this.templateTypeName = PC_Constants.EMPTY_STRING;
            this.targetObjectLabel = PC_Constants.EMPTY_STRING;
            this.targetObjectRecordTypeId = PC_Constants.EMPTY_STRING;
            this.isTemplateTypeIdPreConfigured = PC_Constants.FALSE_BOOLEAN;
            this.isTemplateTypeAutoSelected = PC_Constants.FALSE_BOOLEAN;
            this.ocrTemplateMappings = new List<PC_OcrTemplateMapping__c> ();
            this.ocrResults = new List<PC_OcrResult__c> ();
        }
    }

    public inherited sharing class PC_OcrReviewDocumentException extends Exception {}
}