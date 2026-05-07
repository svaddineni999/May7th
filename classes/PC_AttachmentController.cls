/*********************************************************************************
Class Name      : PC_AttachmentController
Description     : Methods for getting attachments for eletter2 lightning component
Created By      : Satheesh Kumar
Created Date    : 29-Jun-2020
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   	Description
-----------------------------------------------------------------------------------
Satheesh Kumar            29-Jun-2020              Initial Version
Satheesh Kumar            14-Oct-2020              [PC-6733] - Added new property contentDocumentId in RecordAttachment wrapper class to support attachment preview in eletter2
Satheesh Kumar            24-Nov-2020              [PC-6943] - Added logic to get all attachments of case when recordId is of type PC_Document
Haritha Reddy             21-Jan-2021              [PC-7102] Added FLS Check
Haritha Reddy             21-Jan-2021              [PC-7102] Force Reviewer scan issue fix. Updated Sharing declaration.
Satheesh Kumar            14-Jul-2022              [PC-8437] Modified code to prefer Attachments over Files in Attachment/File selection on eletter when both the 'Use Salesforce File' and Salesforce Files Strict Mode are set to 'false'
*********************************************************************************/

public with sharing class PC_AttachmentController {

    /**
    * Retrieves all available attachments based on input parameters
    *
    * @param recordId recordId for getting attachments
    * @param showAttachmentsOfRecord this flag helps to show record attachments.
    * @param showAttachmentsUsingDocumentLog this flag helps to show attachments of document log record
    * @param showAttachmentsOfRelatedCase this flag helps to show attachments of related case records
    * @param showAllAttachmentsOfDocument this flag helps to show more than one attachments of PC_Documents record
    * @return List<RecordAttachment>  returns list of attachment
    */
    @AuraEnabled
    public static List<RecordAttachment> getAttachments(Id recordId, Boolean showAttachmentsOfRecord, Boolean showAttachmentsUsingDocumentLog, Boolean showAttachmentsOfRelatedCase, Boolean showAllAttachmentsOfDocument) {
        List<RecordAttachment> recordAttachments = new List<RecordAttachment>();

        String objType = String.valueOf(recordId.getSobjectType());
        try {
            if (objType == PC_Constants.DOCUMENT_OBJECT) {
                // Check FLS for PC_Document_Log__c
                List<String> pcDocumentLogFields = new List<String>{'Id', PC_Constants.getQualifiedAPIName('PC_Program__c'), PC_Constants.getQualifiedAPIName('PC_Document__c')};
                List<PC_Document_Log__c> docLogList = new List<PC_Document_Log__c>();
                PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Document_Log__c'), PC_Database.Operation.Reading, pcDocumentLogFields);
                docLogList = [SELECT Id, PC_Program__c, PC_Document__c FROM PC_Document_Log__c WHERE PC_Document__c = :recordId and PC_Program__c != null];
                if (docLogList.size() > 0) {
                    recordId = docLogList[0].PC_Program__c;
                    objType = PC_Constants.PC_CASE;
                }
            }

            if (objType == PC_Constants.PC_INTERACTION) {
                PC_Interaction__c interactionObject = new PC_Interaction__c();
                //FLS Check of PC_Interaction__c Object
                List<String> interactionFields = new List<String>{'Id', PC_Constants.getQualifiedAPIName('PC_Patient_Program__c')};
                PC_Database.assertAccess(PC_Constants.PC_INTERACTION, PC_Database.Operation.Reading, interactionFields);
                interactionObject = [SELECT Id, PC_Patient_Program__c FROM PC_Interaction__c WHERE Id = :recordId];
                if (showAttachmentsOfRecord) {
                    recordAttachments = getAttachmentsOnRecord(recordId, showAttachmentsUsingDocumentLog, showAllAttachmentsOfDocument);
                }
                if (showAttachmentsOfRelatedCase) {
                    recordAttachments.addAll(getAttachmentsOnRecord(interactionObject.PC_Patient_Program__c, showAttachmentsUsingDocumentLog, showAllAttachmentsOfDocument));
                }
            } else if (objType == PC_Constants.PC_PROGRAM_COVERAGE) {
                PC_Program_Coverage__c progCoverageObject = new PC_Program_Coverage__c();
                //FLS Check of PC_Program_Coverage__c Object
                List<String> programCoverageFields = new List<String>{'Id', PC_Constants.getQualifiedAPIName('PC_Program__c')};
                PC_Database.assertAccess(PC_Constants.PC_PROGRAM_COVERAGE, PC_Database.Operation.Reading, programCoverageFields);
                progCoverageObject = [SELECT Id, PC_Program__c FROM PC_Program_Coverage__c WHERE Id = :recordId];
                if (showAttachmentsOfRecord) {
                    recordAttachments = getAttachmentsOnRecord(recordId, showAttachmentsUsingDocumentLog, showAllAttachmentsOfDocument);
                }
                if (showAttachmentsOfRelatedCase) {
                    recordAttachments.addAll(getAttachmentsOnRecord(progCoverageObject.PC_Program__c, showAttachmentsUsingDocumentLog, showAllAttachmentsOfDocument));
                }
            } else if (objType == PC_Constants.PC_TASK) {
                Task taskObj = new Task();
                //FLS Check of Task Object
                List<String> taskFields = new List<String>{'Id', 'WhatId'};
                PC_Database.assertAccess(PC_Constants.PC_TASK, PC_Database.Operation.Reading, taskFields);
                taskObj = [SELECT Id, WhatId FROM Task WHERE Id = :recordId];
                if (showAttachmentsOfRecord) {
                    recordAttachments = getAttachmentsOnRecord(recordId, showAttachmentsUsingDocumentLog, showAllAttachmentsOfDocument);
                }
                if (showAttachmentsOfRelatedCase) {
                    recordAttachments.addAll(getAttachmentsOnRecord(taskObj.WhatId, showAttachmentsUsingDocumentLog, showAllAttachmentsOfDocument));
                }
            } else if (objType == PC_Constants.PC_CASE) {
                recordAttachments = getAttachmentsOnRecord(recordId, showAttachmentsUsingDocumentLog, showAllAttachmentsOfDocument);
            }
        } catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        system.debug('mailAttachmentWrappers---' + recordAttachments);
        return recordAttachments;
    }

    /**
   * Retrieves all attachments on record based on input parameters
   *
   * @param recordId recordId for getting attachments
   * @param showAttachmentsUsingDocumentLog this flag helps to show attachments of document log record
   * @param showAllAttachmentsOfDocument this flag helps to show more than one attachments of PC_Documents record
   * @return List<RecordAttachment>  returns list of attachment
   */
    public static List<RecordAttachment> getAttachmentsOnRecord(Id recordId, Boolean showAttachmentsUsingDocumentLog, Boolean showAllAttachmentsOfDocument) {
        List<RecordAttachment> allRecordAttachments = new List<RecordAttachment>();
        RecordAttachment recordAttachment = new RecordAttachment();
        Boolean useSalesforceFiles = PC_SYSTEM.useSalesforceFiles();
        Boolean useFileStrictMode = PC_SYSTEM.useDocumentPreviewInStrictMode();
        Boolean showDocLogAttachments = showAttachmentsUsingDocumentLog;
        Boolean showAllAttachmentOfPCDocument = showAllAttachmentsOfDocument;

        //FLS Check
        List<String> attachmentFields = new List<String>{'Name', 'Body', 'ContentType', 'ParentId', 'BodyLength'};
        PC_Database.assertAccess('Attachment', PC_Database.Operation.Reading, attachmentFields);

        List<String> cdlFields = new List<String>{'LinkedEntityId', 'ContentDocument'};
        PC_Database.assertAccess('ContentDocumentLink', PC_Database.Operation.Reading, cdlFields);

        List<String> cvFields = new List<String>{'Id', 'Title', 'VersionData', 'FileExtension', 'FileType', 'PathOnClient', 'ContentDocumentId', 'ContentSize'};
        PC_Database.assertAccess('ContentVersion', PC_Database.Operation.Reading, cvFields);

        List<String> contentDocFields = new List<String>{'ContentModifiedDate', 'Title'};
        PC_Database.assertAccess('ContentDocument', PC_Database.Operation.Reading, contentDocFields);

        List<String> dlFields = new List<String>{'Id', 'Name', PC_Constants.getQualifiedAPIName('PC_Program__c'), PC_Constants.getQualifiedAPIName('PC_Document__c')};
        PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Document_Log__c'), PC_Database.Operation.Reading, dlFields);

        try {
            //Get all attachments/files of record based on patient connect setting
            Set<Id> caseContentDocumentLinkIds = new Set<Id>();
            for (ContentDocumentLink lstContentDocs : [SELECT ContentDocumentId,ContentDocument.ContentModifiedDate FROM ContentDocumentLink WHERE LinkedEntityId = :recordId order by ContentDocument.ContentModifiedDate desc]) {
                caseContentDocumentLinkIds.add(lstContentDocs.ContentDocumentId);
            }
            List<ContentVersion> caseContentVersionList = [SELECT Id, Title, VersionData, FileExtension, FileType, PathOnClient, ContentSize, ContentDocumentId FROM ContentVersion WHERE ContentDocumentId IN:caseContentDocumentLinkIds AND IsLatest = true];
            List<Attachment> caseAttachmentList = [SELECT Id, Name, Body, ContentType, BodyLength FROM Attachment WHERE ParentId = :recordId];

            if ((useSalesforceFiles && caseContentVersionList.size() > 0) || (useSalesforceFiles && useFileStrictMode) ||
                    (!useFileStrictMode && !useSalesforceFiles && (caseContentVersionList.size() > 0 && caseAttachmentList.size() == 0))) {
                for (ContentVersion cv : caseContentVersionList) {
                    recordAttachment = new RecordAttachment(cv);
                    allRecordAttachments.add(recordAttachment);
                }
            } else {
                for (Attachment attach : caseAttachmentList) {
                    recordAttachment = new RecordAttachment(attach);
                    allRecordAttachments.add(recordAttachment);
                }
            }

            // Below block of code helps to retrieve the document log attachments
            if (showDocLogAttachments) {

                //Get all PC Document of case
                Set<Id> pcDocumentIds = new Set<Id>();

                // Check FLS for PC_Document__c
                List<String> documentLogFields = new List<String>{PC_Constants.getQualifiedAPIName('PC_Program__c'), PC_Constants.getQualifiedAPIName('PC_Document__c')};
                PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Document_Log__c'), PC_Database.Operation.Reading, documentLogFields);

                for (PC_Document_Log__c documentLog : [SELECT Id, Name, PC_Program__c, PC_Document__c FROM PC_Document_Log__c WHERE PC_Program__c = :recordId]) {
                    pcDocumentIds.add(documentLog.PC_Document__c);
                }

                if (pcDocumentIds != null && !pcDocumentIds.isEmpty()) {
                    // Check FLS for PC_Document__c
                    List<String> pcDocumentFields = new List<String>{'Id', 'Name', PC_Constants.getQualifiedAPIName('PC_Document_Name__c')};
                    PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Document__c'), PC_Database.Operation.Reading, pcDocumentFields);
                    // Populate PC_Document map from SOQL query
                    Map<ID, PC_Document__c> mapOfPCDocuments = new Map<ID, PC_Document__c>([SELECT Id, Name, PC_Document_Name__c FROM PC_Document__c WHERE Id IN:pcDocumentIds]);
                    String docName;


                    //Get files of all PC Document
                    Set<Id> pcContentDocumentLinkIds = new Set<Id>();
                    Map<Id, List<Id>> pcDocumentAndContentDocumentIdsMap = new Map<Id, List<Id>>();
                    Map<Id, List<ContentVersion>> pcDocumentIdAndContentVersionListMap = new Map<Id, List<ContentVersion>>();
                    Map<Id, PC_Document__c> contentDocumentIdPCDocumentIdMap = new Map<Id, PC_Document__c>();
                    for (ContentDocumentLink lstContentDocs : [SELECT ContentDocumentId,ContentDocument.ContentModifiedDate,LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId IN:pcDocumentIds order by ContentDocument.ContentModifiedDate desc]) {
                        contentDocumentIdPCDocumentIdMap.put(lstContentDocs.ContentDocumentId, mapOfPCDocuments.get(lstContentDocs.LinkedEntityId));
                        //pcDocumentIds.remove(lstContentDocs.LinkedEntityId);
                        if (showAllAttachmentOfPCDocument) {
                            List<Id> contentDocumentIds = (pcDocumentAndContentDocumentIdsMap.get(lstContentDocs.LinkedEntityId) == null) ? new List<Id>() : pcDocumentAndContentDocumentIdsMap.get(lstContentDocs.LinkedEntityId);
                            contentDocumentIds.add(lstContentDocs.ContentDocumentId);
                            pcDocumentAndContentDocumentIdsMap.put(lstContentDocs.LinkedEntityId, contentDocumentIds);
                            pcContentDocumentLinkIds.add(lstContentDocs.ContentDocumentId);
                        } else if (!pcDocumentAndContentDocumentIdsMap.containsKey(lstContentDocs.LinkedEntityId)) {
                            List<Id> contentDocumentIds = (pcDocumentAndContentDocumentIdsMap.get(lstContentDocs.LinkedEntityId) == null) ? new List<Id>() : pcDocumentAndContentDocumentIdsMap.get(lstContentDocs.LinkedEntityId);
                            contentDocumentIds.add(lstContentDocs.ContentDocumentId);
                            pcDocumentAndContentDocumentIdsMap.put(lstContentDocs.LinkedEntityId, contentDocumentIds);
                            pcContentDocumentLinkIds.add(lstContentDocs.ContentDocumentId);
                        }
                    }

                    for (ContentVersion cv : [SELECT Id, Title, VersionData, FileExtension, FileType, PathOnClient, ContentSize, ContentDocumentId FROM ContentVersion WHERE ContentDocumentId IN:pcContentDocumentLinkIds AND IsLatest = true]) {
                        PC_Document__c doc = (contentDocumentIdPCDocumentIdMap.get(cv.ContentDocumentId));
                        List<ContentVersion> contentVersionList = (pcDocumentIdAndContentVersionListMap.get(doc.Id) == null) ? new List<ContentVersion>() : pcDocumentIdAndContentVersionListMap.get(doc.Id) ;
                        contentVersionList.add(cv);
                        pcDocumentIdAndContentVersionListMap.put(doc.Id, contentVersionList);
                    }

                    //Get Attachments of all PC Documents
                    Map<Id, List<Attachment>> pcDocumentIdAttachmentListMap = new Map<Id, List<Attachment>>();
                    Map<Id, PC_Document__c> attachmentIdPCDocumentIdMap = new Map<Id, PC_Document__c>();
                    for (Attachment att : [SELECT Id, Name, Body, ContentType, ParentId, BodyLength, createdDate FROM Attachment WHERE ParentId IN:pcDocumentIds order by createdDate desc]) {
                        attachmentIdPCDocumentIdMap.put(att.Id, mapOfPCDocuments.get(att.ParentId));
                        if (showAllAttachmentOfPCDocument) {
                            List<Attachment> attachmentList = (pcDocumentIdAttachmentListMap.get(att.ParentId) == null) ? new List<Attachment>() : pcDocumentIdAttachmentListMap.get(att.ParentId);
                            attachmentList.add(att);
                            pcDocumentIdAttachmentListMap.put(att.ParentId, attachmentList);
                        } else if (!pcDocumentIdAttachmentListMap.containsKey(att.ParentId)) {
                            List<Attachment> attachmentList = (pcDocumentIdAttachmentListMap.get(att.ParentId) == null) ? new List<Attachment>() : pcDocumentIdAttachmentListMap.get(att.ParentId);
                            attachmentList.add(att);
                            pcDocumentIdAttachmentListMap.put(att.ParentId, attachmentList);
                        }
                    }

                    for (Id documentId : mapOfPCDocuments.keySet()) {
                        List<ContentVersion> lstContentVers = (pcDocumentIdAndContentVersionListMap.get(documentId) == null) ? new List<ContentVersion>() : pcDocumentIdAndContentVersionListMap.get(documentId) ;
                        List<Attachment> lstAttachments = (pcDocumentIdAttachmentListMap.get(documentId) == null) ? new List<Attachment>() : pcDocumentIdAttachmentListMap.get(documentId) ;

                        if ((useSalesforceFiles && lstContentVers.size() > 0) || (useSalesforceFiles && useFileStrictMode) ||
                                (!useFileStrictMode && !useSalesforceFiles && (lstContentVers.size() > 0 && lstAttachments.size() == 0))) {
                            for (ContentVersion cv : lstContentVers) {
                                docName = (contentDocumentIdPCDocumentIdMap.get(cv.ContentDocumentId)).PC_Document_Name__c;
                                cv.Title = (String.isNotBlank(docName) ? docName : (contentDocumentIdPCDocumentIdMap.get(cv.ContentDocumentId)).Name) + ' : ' + cv.Title;
                                recordAttachment = new RecordAttachment(cv);
                                allRecordAttachments.add(recordAttachment);
                            }
                        } else {
                            for (Attachment att : lstAttachments) {
                                docName = (attachmentIdPCDocumentIdMap.get(att.Id)).PC_Document_Name__c;
                                att.Name = (String.isNotBlank(docName) ? docName : (attachmentIdPCDocumentIdMap.get(att.Id)).Name) + ' : ' + att.Name;
                                recordAttachment = new RecordAttachment(att);
                                allRecordAttachments.add(recordAttachment);
                            }
                        }
                    }
                }
            }
        } catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return allRecordAttachments;
    }

    /**
    * Create RecordAttachment for all the attachments passed
    *
    * @param attachmentIds recordId of attachments
    * @return List<RecordAttachment>  returns list of RecordAttachment
    */
    public static List<RecordAttachment> getRecordAttachments(List<String> attachmentIds) {
        List<RecordAttachment> recordAttachments = new List<RecordAttachment>();
        //FLS Check
        List<String> attachmentFields = new List<String>{'Name', 'Body', 'ContentType', 'ParentId', 'BodyLength', 'createdDate'};
        PC_Database.assertAccess('Attachment', PC_Database.Operation.Reading, attachmentFields);
        List<String> docFields = new List<String>{'Id', 'Name', 'Body', 'Type', 'ContentType', 'BodyLength'};
        PC_Database.assertAccess('document', PC_Database.Operation.Reading, docFields);

        // get email attachments (type: Attachments)
        for (Attachment att : [SELECT Id, Name, Body, ContentType, ParentId, BodyLength, createdDate FROM Attachment WHERE Id IN:attachmentIds]) {
            RecordAttachment recordAttachment = new RecordAttachment(att);
            recordAttachments.add(recordAttachment);
        }

        // get email attachments (type: Documents)
        for (Document document : [SELECT Id, Name, Body, Type, ContentType, BodyLength FROM Document WHERE Id IN:attachmentIds]) {
            RecordAttachment recordAttachment = new RecordAttachment(document);
            recordAttachments.add(recordAttachment);
        }

        return recordAttachments;
    }


    /**
    * wrapper for all types of attachment (document/files/attachment)
    */
    public inherited sharing class RecordAttachment {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String docName { get; set; }
        @AuraEnabled public String fileName { get; set; }
        @AuraEnabled public String type { get; set; }
        @AuraEnabled public String contentType { get; set; }
        @AuraEnabled public Integer contentSize { get; set; }
        @AuraEnabled public String contentDocumentId { get; set; }

        public RecordAttachment() {
            id = PC_Constants.EMPTY_STRING;
            docName = PC_Constants.EMPTY_STRING;
            fileName = PC_Constants.EMPTY_STRING;
            type = PC_Constants.EMPTY_STRING;
            contentType = PC_Constants.EMPTY_STRING;
            contentSize = 0;
            contentDocumentId = PC_Constants.EMPTY_STRING;
        }

        public RecordAttachment(Document doc) {
            id = doc.id;
            docName = doc.Name;
            fileName = doc.Name;
            type = (doc.Type).toLowercase();
            contentType = doc.ContentType;
            contentSize = doc.BodyLength;
            contentDocumentId = PC_Constants.EMPTY_STRING;
        }

        public RecordAttachment(Attachment att) {
            id = att.id;
            docName = att.Name;
            fileName = att.Name;
            type = ((att.Name != null) ? (att.Name).substringAfterLast('.') : att.ContentType).toLowercase();
            contentType = att.ContentType;
            contentSize = att.BodyLength;
            contentDocumentId = PC_Constants.EMPTY_STRING;
        }

        public RecordAttachment(ContentVersion conVer) {
            id = conVer.id;
            docName = (conVer.Title != null) ? conVer.Title : conVer.PathOnClient;
            fileName = (conVer.Title != null) ? conVer.Title : conVer.PathOnClient;
            type = (conVer.FileExtension).toLowercase();
            contentType = conVer.FileType;
            contentSize = conVer.ContentSize;
            contentDocumentId = conVer.ContentDocumentId;
        }
    }
}