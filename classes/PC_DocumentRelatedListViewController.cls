/*********************************************************************************
Class Name          : PC_DocumentRelatedListViewController
Description         : Controller for PC_DocumentRelatedListView Component
Created By          : Haritha Reddy
Created Date        : 04-Jun-2019
Modification Log    :
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------
Haritha Reddy          02-Jul-2019              [PC-5019]Initial Version
Haritha Reddy          May 05,2020              [PC-6249] Added limit to the inner SOQL queries
Haritha Reddy           21-Jan-2021             [PC-7102] Added FLS Check
Haritha Reddy         21-Jan-2021              [PC-7102] Force Reviewer scan issue fix. Updated Sharing declaration.
*********************************************************************************/

public with sharing class PC_DocumentRelatedListViewController {
    private static List<PC_PicklistFieldManager.PicklistEntryWrapper> docStatusLabels = PC_PicklistFieldManager.getPicklistEntryWrappers(PC_Document__c.PC_Document_Status__c);
    private static String statusLabel;
    /*********************************************************************************
    Method Name    : getChildDocs
    Description    : lists all child document records for a parent document
    Input Params   : String ParentID
    Return Type    : DocumentWrapper
    *********************************************************************************/
    @AuraEnabled
    public static String getChildDocs(Id ParentID,Boolean isRelatedComponent) {
        OuterDocumentWrapper allDocsWrapper = new OuterDocumentWrapper();
        List<DocumentWrapper> lstChildDocWrapper = new List<DocumentWrapper>();
        try {
            String previewChildDocType = getChildDocPreviewType();
            List<PC_Document__c> lstchildDoc = getDocList(ParentID,PC_Constants.DOCUMENT_TYPE_CHILD);
            List<PC_Document__c> parentDocumentList = getDocList(ParentID,PC_Constants.DOCUMENT_TYPE_PARENT);

            List<String> fields = new List<String>{PC_Constants.getQualifiedAPIName('PC_IsSplit__c')};
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Document__c'), PC_Database.Operation.Reading, fields);

            Boolean currentDocIsSplit = [SELECT Id,PC_IsSplit__c FROM PC_Document__c WHERE Id = :ParentID Limit 1].PC_IsSplit__c;

            if (lstchildDoc != null && lstchildDoc.size() > 0) {
                addChildDocumentsToWrapperList(lstchildDoc, PC_Constants.DOCUMENT_TYPE_CHILD , previewChildDocType, lstChildDocWrapper,currentDocIsSplit);
            }
            if (parentDocumentList !=  null && !parentDocumentList.isEmpty()) {
                addChildDocumentsToWrapperList(parentDocumentList, PC_Constants.DOCUMENT_TYPE_PARENT ,previewChildDocType, lstChildDocWrapper,currentDocIsSplit);
            }
        } catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        lstChildDocWrapper.sort();
        allDocsWrapper.childDocumentsList = lstChildDocWrapper;
        return JSON.serialize(allDocsWrapper);
    }

    /*********************************************************************************
    Class Name     : DocumentWrapper
    Description    : Wrapper class for PC_Document__c
    *********************************************************************************/
    public inherited sharing class DocumentWrapper implements Comparable {
        @AuraEnabled public Id DocumentId {get;set;}
        @AuraEnabled public String DocumentName {get; set;}
        @AuraEnabled public String DocumentStatusLabel {get; set;}
        @AuraEnabled public String ParentDocumentId {get; set;}
        @AuraEnabled public String DocUrl {get; set;} //PC-1677 - Added docURL attribute
        @AuraEnabled public String relationType {get; set;}
        @AuraEnabled public String description {get; set;}
        @AuraEnabled public String createdDate {get; set;}
        @AuraEnabled public String documentType {get; set;}
        @AuraEnabled public String contentTitle {get; set;}
        @AuraEnabled public Id contentId {get; set;}

        public Integer compareTo(Object instance)
        {
            DocumentWrapper that = (DocumentWrapper)instance;
            Integer c = relationType.compareTo(((DocumentWrapper)instance).relationType);
            if (c != 0) {
                return c;
            } else {
                if (this.createdDate > that.createdDate) return 1;
                if (this.createdDate < that.createdDate) return -1;
                return 0;
            }
        }

        public DocumentWrapper(PC_Document__c doc, String statusLabel,String relationType,String description,String documentType,String contentTitle,Id contentId) {
            this.DocumentId = doc.Id;
            this.DocumentName = doc.Name;
            this.DocumentStatusLabel = statusLabel;
            this.ParentDocumentId = doc.PC_Parent_Document__c;
            this.DocUrl = '/'+ doc.Id; //PC-1677 - Added docURL attribute
            this.relationType=relationType;
            this.description=description;
            this.createdDate=String.valueOf(Date.valueOf(doc.CreatedDate).month()+'/'+
                    Date.valueOf(doc.CreatedDate).day()+'/'+
                    String.valueOf(Date.valueOf(doc.CreatedDate).year()).right(2));
            this.documentType=documentType;
            this.contentTitle=contentTitle;
            this.contentId=contentId;
        }
    }
    public inherited sharing class OuterDocumentWrapper{

        public List<DocumentWrapper> childDocumentsList {get;set;}
        public Boolean isCommunity{get;set;}
        OuterDocumentWrapper(){
            this.childDocumentsList=new List<DocumentWrapper>();
            Id siteId = Site.getSiteId();
            if (siteId != null) {
                this.isCommunity = true;
            }else{
                this.isCommunity = false;
            }
        }
    }
    public static String getChildDocPreviewType(){
        String previewChildDocType;
        //Set previewChildDocType based on Patient Connect Settings
        Boolean useSalesforceFiles = PC_SYSTEM.useSalesforceFiles();
        Boolean useDocumentPreviewInStrictMode = PC_SYSTEM.useDocumentPreviewInStrictMode();
        if (useDocumentPreviewInStrictMode == PC_Constants.TRUE_BOOLEAN && useSalesforceFiles == PC_Constants.TRUE_BOOLEAN) {
            previewChildDocType = PC_Constants.DOCUMENT_TYPE_FILE;
        } else if (useDocumentPreviewInStrictMode == PC_Constants.TRUE_BOOLEAN && useSalesforceFiles == PC_Constants.FALSE_BOOLEAN) {
            previewChildDocType = PC_Constants.DOCUMENT_TYPE_ATTACHMENT;
        } else {
            previewChildDocType = PC_Constants.DOCUMENT_TYPE_BOTH;
        }
        return previewChildDocType;
    }

    public static List<PC_Document__c> getDocList(Id docId,String docType){
        //FLS Check
        List<String> attachmentFields = new List<String>{'Id','Name','ParentId'};
        PC_Database.assertAccess('Attachment',PC_Database.Operation.Reading, attachmentFields);

        List<String> cdlFields = new List<String>{'LinkedEntityId','ContentDocument'};
        PC_Database.assertAccess('ContentDocumentLink',PC_Database.Operation.Reading, cdlFields);

        List<String> contentDocFields = new List<String>{'ContentModifiedDate','Title'};
        PC_Database.assertAccess('ContentDocument',PC_Database.Operation.Reading, contentDocFields);

        List<String> fields = new List<String>{'Id','Name','CreatedDate','recordTypeId', PC_Constants.getQualifiedAPIName('PC_Document_Status__c'),
                PC_Constants.getQualifiedAPIName('PC_ParentPgRange__c'),PC_Constants.getQualifiedAPIName('PC_Parent_Document__c'),
                PC_Constants.getQualifiedAPIName('PC_IsSplit__c')};
        PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Document__c'), PC_Database.Operation.Reading, fields);

        List<PC_Document__c> docList = new List<PC_Document__c>();
        if(docType == PC_Constants.DOCUMENT_TYPE_CHILD){
            //get a list of child documents for a parent document
            docList = [SELECT Id, Name, PC_Document_Status__c, PC_Parent_Document__c, CreatedDate,PC_IsSplit__c,PC_ParentPgRange__c,recordTypeId,
                    (SELECT Id, Name FROM Attachments order by createdDate desc LIMIT 2000)
                    FROM PC_Document__c WHERE PC_Parent_Document__c = :docId];
        }else if(docType == PC_Constants.DOCUMENT_TYPE_PARENT){
            //get Parent Document record Id of current Document
            Id parentDocId;
            List<PC_Document__c> parentDocDetailsList = [SELECT Id,PC_Parent_Document__c FROM PC_Document__c WHERE Id = :docId];
            if(!parentDocDetailsList.isEmpty()){
                parentDocId = parentDocDetailsList[0].PC_Parent_Document__c;
            }

            docList = [SELECT Id, Name, PC_Document_Status__c, PC_Parent_Document__c, CreatedDate,PC_ParentPgRange__c,PC_IsSplit__c,recordTypeId,
            (SELECT Id, Name FROM Attachments order by createdDate desc LIMIT 2000)
            FROM PC_Document__c WHERE Id = :parentDocId];
        }

        return docList;
    }

    public static List<ContentDocumentLink> getRelatedFilesList(List<PC_Document__c> docList){
        //fetch files list from Documents
        set<Id> docIds = new set<Id>();
        for(PC_Document__c doc: docList){
            docIds.add(doc.Id);
        }
        List<ContentDocumentLink> filesList = new List<ContentDocumentLink>();
        if(!docIds.isEmpty()){

            List<String> cdlFields = new List<String>{'LinkedEntityId','ContentDocument'};
            PC_Database.assertAccess('ContentDocumentLink',PC_Database.Operation.Reading, cdlFields);

            List<String> contentDocFields = new List<String>{'ContentModifiedDate','Title'};
            PC_Database.assertAccess('ContentDocument',PC_Database.Operation.Reading, contentDocFields);

            filesList = [SELECT ContentDocumentId,ContentDocument.Title,LinkedEntityId
            FROM ContentDocumentLink WHERE LinkedEntityId IN: docIds order by ContentDocument.ContentModifiedDate desc];
        }

        return filesList;
    }


    public static void addChildDocumentsToWrapperList(List<PC_Document__c> docList, String docType, String previewChildDocType,
            List<DocumentWrapper> lstChildDocWrapper, Boolean currentDocIsSplit){
        String relationType,description;
        String childDocDescription=System.Label.PC_Doc_Split_Child_Desc; //Split document: Pages
        String parentDocDescription=System.Label.PC_Doc_Split_Parent_Desc; //Original document before split
        List<ContentDocumentLink> filesList = getRelatedFilesList(docList);

        for (PC_Document__c doc : docList) {
            for (PC_PicklistFieldManager.PicklistEntryWrapper pew : docStatusLabels) {
                if (pew.value == doc.PC_Document_Status__c) {
                    statusLabel = pew.label;
                }
            }
            //Set relation Type and Description for Split and other child Documents
            if(docType == PC_Constants.DOCUMENT_TYPE_PARENT){
                relationType = System.Label.PC_RELATION_TYPE_ORIGINAL;
                if(currentDocIsSplit){
                    description = parentDocDescription;
                }
            }else if(docType == PC_Constants.DOCUMENT_TYPE_CHILD && doc.PC_IsSplit__c) {
                relationType = System.Label.PC_RELATION_TYPE_SPLIT;
                description = childDocDescription+' <' + doc.PC_ParentPgRange__c + '>';
            }else if(doc.recordTypeId == PC_System.recordTypeId(PC_Constants.DOCUMENT_OBJECT, PC_Constants.DOCUMENT_EMAIL_ATTACHMENT_RECORD_TYPE)){
                relationType = System.Label.PC_RELATION_TYPE_EMAIL_ATTACHMENT;
                description = '';
            }else{
                relationType = System.Label.PC_RELATION_TYPE_OTHER;
            }
            //Add each child Document to the Wrapper
            if((previewChildDocType == PC_Constants.DOCUMENT_TYPE_ATTACHMENT || previewChildDocType == PC_Constants.DOCUMENT_TYPE_BOTH )&& !doc.Attachments.isEmpty()){
                for(Attachment attachment : doc.Attachments){
                    lstChildDocWrapper.add(new DocumentWrapper(doc, statusLabel, relationType,description,PC_Constants.DOCUMENT_TYPE_ATTACHMENT,
                            attachment.Name, attachment.Id));
                }
            }
            if((previewChildDocType == PC_Constants.DOCUMENT_TYPE_FILE || previewChildDocType == PC_Constants.DOCUMENT_TYPE_BOTH )&& !filesList.isEmpty()){
                for(ContentDocumentLink cdl : filesList){
                    if(cdl.LinkedEntityId == doc.Id){
                        lstChildDocWrapper.add(new DocumentWrapper(doc, statusLabel, relationType,description,PC_Constants.DOCUMENT_TYPE_FILE,
                                cdl.ContentDocument.Title, cdl.ContentDocumentId));
                    }
                }
            }
            Boolean isFileAvailable = false;
            for(ContentDocumentLink cdl : filesList){
                if(cdl.LinkedEntityId == doc.Id) {
                    isFileAvailable = true;
                }
            }

            if(doc.Attachments.isEmpty() && isFileAvailable == false){
                lstChildDocWrapper.add(new DocumentWrapper(doc, statusLabel, relationType,description,PC_Constants.DOCUMENT_TYPE_NONE,'', null));
            }
        }
    }
}