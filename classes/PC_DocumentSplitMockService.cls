/*******************************************************************************
Modification Log:
-------------------------------------------------------------------------------
Developer              Date            Description
-------------------------------------------------------------------------------
Satheesh Kumar       1/09/2022       Initial Version
******************************************************************************/

public with sharing class PC_DocumentSplitMockService implements PC_Document.Splitter {

    /**
     * Performs an document split and attach those attachments to child documents
     *
     * @param parentDoc The document to split with a Id and PC_Correlation__c
     * @param childDocs The child documents to create attachments for with Id and PC_Sorted_Parent_Pg_Num__c
     */
    public void splitDocument(PC_Document__c parentDoc, PC_Document__c[] childDocs) {
        Map<String, PC_Integration_Settings__c> mapIntegrationSettings = PC_Integration_Settings__c.getAll();
        PC_Integration_Settings__c splitServiceSettings = mapIntegrationSettings.get(PC_Constants.DOCUMENT_SPLIT_SERVICE);


        if (splitServiceSettings == null) {
            throw new PC_Document.SplitException('Missing PC_Integration_Settings__c record for: ' + PC_Constants.DOCUMENT_SPLIT_SERVICE);
        } else if (String.isBlank(splitServiceSettings.endpoint_Url__c)) {
            throw new PC_Document.SplitException('Missing endpoint_Url__c for ' + PC_Constants.DOCUMENT_SPLIT_SERVICE);
        }
        splitAndAddDocument(parentDoc, childDocs);

        //update document status
        parentDoc.PC_Document_Status__c = PC_Constants.DOCUMENT_STATUS_COMPLETE;

        for (PC_Document__c childDoc :childDocs) {
            childDoc.PC_Document_Status__c = PC_Constants.DOCUMENT_STATUS_COMPLETE;
        }

        PC_Database.upd(parentDoc, false);
        PC_Database.upd(childDocs, false);
    }


    /**
     * splitAndAddDocument methods helps to add attachments to the child documents
     *
     * @param parentDoc The document to split with a Id and PC_Correlation__c
     * @param childDocs The child documents to create attachments for with Id and PC_Sorted_Parent_Pg_Num__c
     */
    public static void splitAndAddDocument(PC_Document__c parentDoc, List<PC_Document__c> childDocs) {
        PC_Constants.UseAttachmentOrSalesforceFile useAttachmentOrSalesforceFile = PC_SYSTEM.getFileOrAttachmentInUse();
        Boolean hasAttachments = false;
        if ((useAttachmentOrSalesforceFile == PC_Constants.UseAttachmentOrSalesforceFile.UseFile)) {
            hasAttachments = createSplitDocsOnChildUsingSalesforceFile(parentDoc, childDocs);
            if (!hasAttachments) {
                throw new PC_Document.SplitException('Document without files cannot be split: ' + parentDoc.Id);
            }
        } else if (useAttachmentOrSalesforceFile == PC_Constants.UseAttachmentOrSalesforceFile.UseAttachment) {
            hasAttachments = createSplitDocsOnChildUsingAttachment(parentDoc, childDocs);
            if (!hasAttachments) {
                throw new PC_Document.SplitException('Document without attachment cannot be split: ' + parentDoc.Id);
            }
        } else if (useAttachmentOrSalesforceFile == PC_Constants.UseAttachmentOrSalesforceFile.UseFileAndAttachment || useAttachmentOrSalesforceFile == PC_Constants.UseAttachmentOrSalesforceFile.UseAttachmentAndFile) {
            createSplitDocsOnChildUsingSalesforceFileOrAttachment(parentDoc, childDocs, useAttachmentOrSalesforceFile);
        }
    }



    private static Boolean createSplitDocsOnChildUsingSalesforceFile(PC_Document__c parentDoc, List<PC_Document__c> childDocs){
        List<ContentDocumentLink> contentDocumentLinkList = new List<ContentDocumentLink>();
        Map<Id, ContentVersion> docToContentVersionMap = new Map<Id, ContentVersion>();
        List<ContentVersion> contentVersionListToCreate = new List<ContentVersion>();
        Set<Id> contentVersionIds = new Set<Id>();

        List<ContentDocumentLink> listContentDocumentLink = [SELECT ContentDocumentId, Id FROM ContentDocumentLink WHERE LinkedEntityId = :parentDoc.Id];
        if (listContentDocumentLink.size() > 0) {
            List<ContentVersion> listDocumentContentVersion = [SELECT Id, Title, VersionData, PathOnClient, ContentSize, ContentDocumentId FROM ContentVersion WHERE ContentDocumentId = :listContentDocumentLink[0].ContentDocumentId AND IsLatest = true];

            for (PC_Document__c childDoc : childDocs){
                // Creates the content version and implicitly creates content document
                ContentVersion cv = new ContentVersion();
                cv.Title = listDocumentContentVersion[0].Title;
                cv.PathOnClient = listDocumentContentVersion[0].PathOnClient;
                cv.VersionData = listDocumentContentVersion[0].VersionData;
                contentVersionListToCreate.add(cv);
                docToContentVersionMap.put(childDoc.Id, cv);
            }
            insert contentVersionListToCreate;

            for(ContentVersion cv: contentVersionListToCreate ) {
                contentVersionIds.add(cv.Id);
            }

            List<ContentVersion> newCVList = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN:contentVersionIds];
            ContentDocumentLink cdl;
            for (Id docId : docToContentVersionMap.keySet()) {
                for (ContentVersion cv : newCVList) {
                    if (cv.Id == docToContentVersionMap.get(docId).Id) {
                        cdl = new ContentDocumentLink();
                        cdl.ContentDocumentId = cv.ContentDocumentId;
                        cdl.LinkedEntityId = docId;
                        cdl.ShareType = PC_Constants.FILE_SHARE_TYPE_VIEWER;
                        contentDocumentLinkList.add(cdl);
                    }
                }
            }
            if(contentDocumentLinkList.size() > 0) {
                PC_Database.ins(contentDocumentLinkList);
            }
        }
        return (contentDocumentLinkList.size() > 0);
    }

    private static Boolean createSplitDocsOnChildUsingAttachment(PC_Document__c parentDoc, List<PC_Document__c> childDocs){
        List<Attachment> docAttachment = [SELECT Id, Name, Body, ContentType FROM Attachment WHERE ParentId = :parentDoc.Id order by createdDate desc];
        List<Attachment> attachmentList = new List<Attachment>();
        if (docAttachment.size() > 0) {
            Attachment attach;
            for (PC_Document__c childDoc : childDocs) {
                attach = new Attachment();
                attach.Body = docAttachment[0].Body;
                attach.Name = docAttachment[0].Name;
                attach.ContentType = docAttachment[0].ContentType;
                attach.IsPrivate = false;
                attach.ParentId = childDoc.Id;
                attachmentList.add(attach);
            }
            if (attachmentList.size() > 0) {
                PC_Database.ins(attachmentList);
            }
        }
        return (attachmentList.size() > 0);
    }

    private static void createSplitDocsOnChildUsingSalesforceFileOrAttachment(PC_Document__c parentDoc, List<PC_Document__c> childDocs, PC_Constants.UseAttachmentOrSalesforceFile useAttachmentOrSalesforceFile) {
        Boolean hasAttachments = false;
        if (useAttachmentOrSalesforceFile == PC_Constants.UseAttachmentOrSalesforceFile.UseFileAndAttachment) {
            hasAttachments = createSplitDocsOnChildUsingSalesforceFile(parentDoc, childDocs);
            if (hasAttachments == false) {
                hasAttachments = createSplitDocsOnChildUsingAttachment(parentDoc, childDocs);
            }
        } else {
            hasAttachments = createSplitDocsOnChildUsingAttachment(parentDoc, childDocs);
            if (hasAttachments == false) {
                hasAttachments = createSplitDocsOnChildUsingSalesforceFile(parentDoc, childDocs);
            }
        }
        if(!hasAttachments){
            throw new PC_Document.SplitException('Document without attachment cannot be split: ' + parentDoc.Id);
        }
    }

}