/*********************************************************************************
Class Name      : PC_DocumentSplitLightningController
Description     : Creates/deletes child document records as defined on document splitting section
Created By      : Prachi Nandgaonkar
Created Date    : 4-Jan-2017
Modification Log:
---------------------------------------------------------------------------------- 
Developer                   Date                   Description
-----------------------------------------------------------------------------------            
Prachi Nandgaonkar          4-Jan-17              Initial Version
Shabda Bhujad				9-Jan-17 			  Add logic diplay the records only for the parent document that renders the component 
												  Added logic to link the child documents to parent document for which the split is added
Prachi Nandgaonkar          20 Jan 17             Added Page Count field to document wrapper for page validation
Shabda Bhujad 				24-Jan-17			  Added the method to update the page range for the split document
Ajinkya Deshmukh			04-Apr-17			  Updated createChildDoc(). removed parentDoc Status updation. Its handled in the trigger.
Ajinkya Deshmukh			20-Jun-17			  FLS Check Added (Code Merge)
Shabda Bhujad				22-Jun-17			  [PC-1677] - Error occurs while trying to launch enrollment from child document window.
Mayuresh Patil				27-Jun-17			  [PC-1669] - Child Doc or email attachments should not appear in the split section since they are attachments of the email
Mayuresh Patil              29-Jun-17             [PC-1860] - Refresh (F5) on the browser is removing the Child attachment documents if a Parent Email Inbounding document is Split.
Tejas Patel                 July 25 2017           [PC-1927],[PC-1928],[PC-1918] Translation Issues
Mayuresh Patil              07-Sep-17             [PC-2193] FLS Check updated to new PC303 code
Mike Klumpenaar             27-Jan-18             [PC-2718] Added callout to PC_DocumentService in place of call to PC_DocumentSplitWebservice
Mike Klumpenaar             25-Feb-19             [PC-4474] Included PC_Sorted_Parent_Pg_Num__c to child doc query before splitting
Shishir Bansal              17-Apr-19              [PC-4913] Support Document Split Feature for both Attachments and Files
Haritha Reddy             Dec 13, 2019            [PC-5791] Added error handling for updateStatus Method
Vijay Kashikar            21-Jan-21               [PC-7102] Added FLS Checks
Vijay Kashikar            21-Jan-2021             [PC-7102] Added sharing clause
Kishore Kanteti           21-May-2021             [PC-7739] Used method convertNumbersToRange() to convert Numbers to Range for PC_Sorted_Parent_Pg_Num__c
*********************************************************************************/

public with sharing class PC_DocumentSplitLightningController {
    private static List<PC_PicklistFieldManager.PicklistEntryWrapper> docStatusLabels = PC_PicklistFieldManager.getPicklistEntryWrappers(PC_Document__c.PC_Document_Status__c);
    private static String statusLabel;

    /*********************************************************************************
    Method Name    : getChildDocs
    Description    : lists all child document records for a parent document
    Input Params   : String ParentID
    Return Type    : DocumentWrapper      
    *********************************************************************************/
    @AuraEnabled
    public static List<DocumentWrapper> getChildDocs(Id ParentID) {
        List<DocumentWrapper> lstChildDocWrapper = new List<DocumentWrapper>();
        try {
            List<String> fields = new List<String>{'Name', PC_Constants.getQualifiedAPIName('PC_ParentPgRange__c'),PC_Constants.getQualifiedAPIName('PC_Document_Status__c'),
                                                   PC_Constants.getQualifiedAPIName('PC_Parent_Document__c'),PC_Constants.getQualifiedAPIName('PC_Page_Count__c'),PC_Constants.getQualifiedAPIName('PC_IsSplit__c')};

            //FLS check access before SOQL
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Document__c'),PC_Database.Operation.Reading, fields);

            //get a list of child documents for a parent document
            List<PC_Document__c> lstchildDoc = [SELECT Id, Name, PC_ParentPgRange__c, PC_Document_Status__c, PC_Parent_Document__c, PC_Page_Count__c
                                                FROM PC_Document__c
                                                WHERE PC_Parent_Document__c =: ParentID AND PC_IsSplit__c = true
                                                ORDER BY CreatedDate desc ];
            if (lstchildDoc != null && lstchildDoc.size() > 0) {
                for(PC_Document__c childDoc: lstchildDoc) {
                    for(PC_PicklistFieldManager.PicklistEntryWrapper pew : docStatusLabels){
                        if(pew.value == childDoc.PC_Document_Status__c){
                            statusLabel = pew.label;
                        }
                    }
                    lstChildDocWrapper.add(new DocumentWrapper(childDoc , statusLabel));
                }
            }
        } catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return lstChildDocWrapper;
    }

    /*********************************************************************************
    Method Name    : createChildDoc
    Description    : creates child document records
    Input Params   : String PageRange
    Return Type    : void
    *********************************************************************************/
    @AuraEnabled
    public static void createChildDoc(String pgRange, Id ParentID, String ParentPgNum, String pageCount) {
        try{
            List<String> fields = new List<String>{PC_Constants.getQualifiedAPIName('PC_From_Name__c'),PC_Constants.getQualifiedAPIName('PC_From_Fax_Number__c'),PC_Constants.getQualifiedAPIName('PC_From_Email_Address__c'), PC_Constants.getQualifiedAPIName('PC_Page_Count__c'),
                                                   PC_Constants.getQualifiedAPIName('PC_Parent_Document__c'),PC_Constants.getQualifiedAPIName('PC_Document_Status__c')};
            //FLS check access before SOQL
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Document__c'),PC_Database.Operation.Reading, fields);
            //get values of the parent document record
            List<PC_Document__c> parentDocAttributes = [SELECT Id, OwnerId, RecordTypeId, PC_From_Name__c,PC_Parent_Document__c, PC_Document_Status__c,
                                                        PC_From_Fax_Number__c,PC_From_Email_Address__c,PC_Page_Count__c
                                                        FROM PC_Document__c
                                                        WHERE Id =: ParentID];
            if (parentDocAttributes != null && parentDocAttributes.size() > 0) {
                PC_Document__c childDoc = new PC_Document__c();
                //Inherting attributes from parent document
                childDoc.PC_Document_Status__c = PC_Constants.DOCUMENT_STATUS_READY_FOR_SPLIT;
                childDoc.RecordTypeId=parentDocAttributes[0].RecordTypeId;
                childDoc.OwnerId=parentDocAttributes[0].OwnerId;
                childDoc.PC_From_Name__c=parentDocAttributes[0].PC_From_Name__c;
                childDoc.PC_From_Fax_Number__c=parentDocAttributes[0].PC_From_Fax_Number__c;
                childDoc.PC_From_Email_Address__c=parentDocAttributes[0].PC_From_Email_Address__c;
                childDoc.PC_ParentPgRange__c = pgRange;
                childDoc.PC_Parent_Document__c=ParentID;
                childDoc.PC_Sorted_Parent_Pg_Num__c = PC_Utility.convertNumbersToRange(ParentPgNum);
                childDoc.PC_Page_Count__c = Integer.valueOf(pageCount);
                childDoc.PC_IsSplit__c = true;
                if(childDoc != null) {
                    PC_Database.ins(childDoc);//FLS/CRUD enforced in the PC_database ins method
                }
            }
        } catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
    }
    /*********************************************************************************
    Method Name    : deleteChildDoc
    Description    : deletes the child document record
    Input Params   : String DocumentNumber
    Return Type    : void
    *********************************************************************************/
    @AuraEnabled
    public static void deleteChildDoc(String docId) {
        List<PC_Document__c> childDoc = new List<PC_Document__c>();
        try {
            if (docId != null ) {
            	/*
		        * FLS Check for PC_Document__c
		        */
		    	List<String> fields = new List<String>{'Name'};
		        PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Document__c'), PC_Database.Operation.Reading, fields);
                childDoc = [SELECT Id, Name FROM PC_Document__c WHERE Id =: docId];
            }
            PC_Database.del(childDoc, true);
        } catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
    }

    /*********************************************************************************
    Method Name    : updChildDoc
    Description    : Delete existing attachment on the child doc
					 Updates the page range and correlation id of the child document record
    Input Params   : String Document Id, String Page Range, String Parent Page Numbers to be included in child, String Page Count
    Return Type    : void
    *********************************************************************************/
    @AuraEnabled
    public static void updChildDoc(String docId, String pgRange, String ParentPgNum, String pageCount ) {
        PC_Document__c childDoc = new PC_Document__c();

        try{


            system.debug('testing docId'+docId);
            if (docId != null ) {
                //Check FLS before SOQL
                Boolean  useSalesforceFiles = PC_SYSTEM.useSalesforceFiles();
                List<String> fields = new List<String>{'Id'};

                if(useSalesforceFiles) {
                    PC_Database.assertAccess(PC_Constants.PC_CONTENT_DOCUMENT, PC_Database.Operation.Reading, fields);
                    // check for FLS on ContentDocument Link

                    // single query and no limit
                    List<ContentDocumentLink> listContentDocumentsLink =[SELECT ContentDocumentId, Id FROM ContentDocumentLink WHERE LinkedEntityId  =:docId];

                    if(listContentDocumentsLink.size()>0) {
                        List<ContentDocument> listContentDocuments = [SELECT Id FROM ContentDocument WHERE Id = :listContentDocumentsLink[0].ContentDocumentId];
                        system.debug('listContentDocuments--' + listContentDocuments);
                        if (listContentDocuments.size() > 0) {
                            PC_Database.del(listContentDocuments, true);
                        }
                    }
                }

                else{
                    PC_Database.assertAccess(PC_Constants.PC_ATTACHMENT, PC_Database.Operation.Reading, fields);
                    List<Attachment> lstAttachments = [SELECT Id FROM Attachment WHERE ParentId = :docId];
                    if (lstAttachments.size() > 0) {
                        PC_Database.del(lstAttachments, true);
                    }
                }
                //Check FLS before SOQL
                fields = new List<String>{'Name', PC_Constants.getQualifiedAPIName('PC_ParentPgRange__c')};
                PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Document__c'),PC_Database.Operation.Reading, fields);
                childDoc = [SELECT Id, Name, PC_ParentPgRange__c FROM PC_Document__c WHERE Id =: docId];
            }
            if (childDoc != null) {
                //update the page range and the document status only if the pgRange is different from the previous value
                if(childDoc.PC_ParentPgRange__c != pgRange) {
                    childDoc.PC_ParentPgRange__c = pgRange;
                    childDoc.PC_Document_Status__c = PC_Constants.DOCUMENT_STATUS_READY_FOR_SPLIT;  //change child document status to 'Ready for Split' when page range is updated
                    childDoc.PC_Correlation_Id__c = '';
                    childDoc.PC_Sorted_Parent_Pg_Num__c = PC_Utility.convertNumbersToRange(ParentPgNum);
                    childDoc.PC_Page_Count__c = Integer.valueOf(pageCount);
                    childDoc.PC_IsSplit__c = true;
                    PC_Database.upd(childDoc);//FLS/CRUD is enforced in PC_Database upd method
                }
            }
         } catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
    }

    /*********************************************************************************
    Method Name    : getParentDocumentCount
    Description    : updates parent document and child document status when split request is made
    Input Params   : Id parentDocId
    Return Type    : void
    *********************************************************************************/
    @AuraEnabled
    public static Integer getParentDocumentCount(Id ParentID) {
        Integer pageCount = 0;
        try {
            List<String> fields = new List<String>{PC_Constants.getQualifiedAPIName('PC_Page_Count__c')};
            //FLS check before accessing SOQL
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Document__c'),PC_Database.Operation.Reading, fields);
            List<PC_Document__c> parentDocument = [SELECT id, OwnerId, PC_Page_Count__c FROM PC_Document__c WHERE Id =: ParentID];
            if(parentDocument.size()>0) {
                if(parentDocument[0].PC_Page_Count__c != null) {
	                pageCount = Integer.valueOf(parentDocument[0].PC_Page_Count__c);
                }
            }
        } catch (Exception e) {
            PC_Utility.logAndThrowException(e);
        }
        return pageCount;
    }

    /*********************************************************************************
    Method Name    : updateStatus
    Description    : updates parent document and child document status when split request is made
    Input Params   : Id parentDocId
    Return Type    : void
    *********************************************************************************/
    @AuraEnabled
    public static void updateStatus(Id parentDocId){
        try {
            //Set document status per the workflow
            Set <Id> childDocumentIds = new Set<Id>();

            /*
        * FLS Check for PC_Document__c
        */
            List<String> fields = new List<String>{
                    'Name', PC_Constants.getQualifiedAPIName('PC_Document_Status__c'), PC_Constants.getQualifiedAPIName('PC_Parent_Document__c'), PC_Constants.getQualifiedAPIName('PC_IsSplit__c')
            };
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Document__c'), PC_Database.Operation.Reading, fields);

            PC_Document__c parentDoc = [SELECT Id, Name, PC_Document_Status__c FROM PC_Document__c WHERE Id = :parentDocId];
            List<PC_Document__c> lstchildDoc = [
                    SELECT Id, Name, PC_Document_Status__c, PC_Sorted_Parent_Pg_Num__c
                    FROM PC_Document__c
                    WHERE PC_Parent_Document__c = :parentDocId AND PC_IsSplit__c = true
            ];
            //set parent document status to 'Split in Progress'
            parentDoc.PC_Document_Status__c = PC_Constants.DOCUMENT_STATUS_SPLIT_IN_PROGRESS;
            //create a unique correlationId to mark every transaction as document id + timestamp
            String correlationId = (String) parentDocId + system.now();
            parentDoc.PC_Correlation_Id__c = correlationId;

            system.debug('lstchildDoc--' + lstchildDoc);

            if (lstchildDoc != null && lstchildDoc.size() > 0) {
                for (PC_Document__c childDoc : lstchildDoc) {
                    //set child document status to 'Awaiting Attachment'
                    childDoc.PC_Document_Status__c = PC_Constants.DOCUMENT_STATUS_AWAITING_ATTACHMENT;
                    childDoc.PC_Correlation_Id__c = correlationId;
                    childDocumentIds.add(childDoc.Id);
                }
            }

// single query
            Boolean useSalesforceFiles = PC_SYSTEM.useSalesforceFiles();
            if (useSalesforceFiles) {
                List<String> contentDocumentLinkfields = new List<String>{
                        'ContentDocumentId', 'LinkedEntityId'
                };
                PC_Database.assertAccess('ContentDocumentLink', PC_Database.Operation.Reading, contentDocumentLinkfields);

                List<ContentDocumentLink> listContentDocumentsLink = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN :childDocumentIds];

                Set<Id> contentDocumentIdSet = new Set<Id>();

                if (listContentDocumentsLink.size() > 0) {
                    for (ContentDocumentLink contentId : listContentDocumentsLink) {

                        contentDocumentIdSet.add(contentId.ContentDocumentId);

                    }
                    List<String> contentDocumentFields = new List<String>{
                            'Id'
                    };
                    PC_Database.assertAccess('ContentDocument', PC_Database.Operation.Reading, contentDocumentFields);
                    List<ContentDocument> listContentDocuments = [SELECT Id FROM ContentDocument WHERE Id IN :contentDocumentIdSet];
                    if (listContentDocuments.size() > 0) {
                        PC_Database.del(listContentDocuments, true);
                    }
                }
            } else {
                List<String> attachementFields = new List<String>{
                        'Id', 'ParentId'
                };
                PC_Database.assertAccess('Attachment', PC_Database.Operation.Reading, attachementFields);
                List<Attachment> listAttachments = [SELECT Id FROM Attachment WHERE ParentId IN :childDocumentIds];
                system.debug('listAttachments--' + listAttachments);
                if (listAttachments.size() > 0) {
                    PC_Database.del(listAttachments, true);
                }
            }
            PC_Database.upd(parentDoc);
            PC_Database.upd(lstchildDoc);
            try {
                PC_DocumentService.splitDocument(parentDoc, lstchildDoc);
            } catch (PC_Document.SplitException e) {
                // Exception has already been logged by document service
                //TODO: Inform user that there is a problem with the request.
            }
        } catch (Exception e) {
            PC_Utility.logAndThrowException(e);
        }
    }

    /*********************************************************************************
    Class Name     : DocumentWrapper
    Description    : Wrapper class for PC_Document__c
    *********************************************************************************/
    public inherited sharing class DocumentWrapper {
        @AuraEnabled public Id DocumentId {get;set;}
        @AuraEnabled public String DocumentName {get; set;}
        @AuraEnabled public String DocumentPageRange {get; set;}
        @AuraEnabled public String DocumentStatus {get; set;}
        @AuraEnabled public String DocumentStatusLabel {get; set;}
        @AuraEnabled public String ParentDocumentId {get; set;}
        @AuraEnabled public Integer PageCount {get; set;}
        @AuraEnabled public String DocUrl {get; set;} //PC-1677 - Added docURL attribute

        public DocumentWrapper(PC_Document__c doc, String statusLabel) {
            this.DocumentId = doc.Id;
            this.DocumentName = doc.Name;
            this.DocumentPageRange = doc.PC_ParentPgRange__c;
            this.DocumentStatus = doc.PC_Document_Status__c;
            this.DocumentStatusLabel = statusLabel;
            this.ParentDocumentId = doc.PC_Parent_Document__c; 
            this.PageCount = (Integer) doc.PC_Page_Count__c;
            this.DocUrl = '/'+ doc.Id; //PC-1677 - Added docURL attribute
        }
    }
}