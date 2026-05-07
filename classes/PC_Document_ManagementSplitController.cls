/******************************************************************************
Modification Log:
-------------------------------------------------------------------------------
Developer               Date            Description
-------------------------------------------------------------------------------
Mike Klumpenaar			2/25/2019		PC-4474 Included PC_Sorted_Parent_Pg_Num__c to child doc query before splitting
Tejas Patel             8/29/2019       PC-5334 Check for parent and child owner added along with status check for Ready for Split and Split Failure
Tejas Patel             26 Sept 2019    PC-5512 isAdmin flag introduced to handle admin level split
Shishir Bansal          06-Dec-2019      [PC-5792] Avoid hardcoding of string variable
Haritha Reddy          Dec 13, 2019      [PC-5791] Added error handling for updateStatus Method
Vijay Kashikar         21-Jan-21         [PC-7102] Added FLS Checks
Vijay Kashikar         21-Jan-21         [PC-7102] Added sharing clause
Kishore Kanteti        21-May-2021       [PC-7739] Used method convertNumbersToRange() to convert Numbers to Range for PC_Sorted_Parent_Pg_Num__c
Hitha Avalakki         20-Oct-21         [PC-8197] Added code to check if Salesforce file/attachment is supported on document records when attachments/salesforce files are fetched,
                                                   when an attachment/salesforce file split is initiated and when a split request is executed resulting in child documents status change
Satheesh Kumar         22-Jul-2022       [PC-8438] Added logic to consider salesforce files in the absence of any attachment on the document record when both 'Use Salesforce Files' and 'Salesforce Strict File mode' value is 'False'.
******************************************************************************/

/**
 * Created by havalakki on 3/12/2018.
 */
public with sharing class PC_Document_ManagementSplitController {
    private static List<PC_PicklistFieldManager.PicklistEntryWrapper> docStatusLabels = PC_PicklistFieldManager.getPicklistEntryWrappers(PC_Document__c.PC_Document_Status__c);
    private static String statusLabel;
    private static String parentDocStatusLabel;

    /*********************************************************************************
    Method Name    : getChildDocs
    Description    : lists all child document records for a parent document
    Input Params   : String ParentID
    Return Type    : DocumentWrapper
    *********************************************************************************/
    @AuraEnabled
     public static String getChildDocs(Id ParentID,Boolean isRelatedComponent, Boolean isAdmin) {

        String relationTypeSplit=System.Label.PC_RELATION_TYPE_SPLIT; // split
        String relationTypeOriginal=System.Label.PC_RELATION_TYPE_ORIGINAL; // original
        String childDocDescription=System.Label.PC_Doc_Split_Child_Desc; //Split document: Pages
        String parentDocDescription=System.Label.PC_Doc_Split_Parent_Desc; //Original document before split

        List<PC_Document__c> parentDocumentList=new List<PC_Document__c>();
        List<PC_Document__c> parentDocDetailsList=new List<PC_Document__c>();

        List<DocumentWrapper> lstChildDocWrapper = new List<DocumentWrapper>();

        OuterDocumentWrapper outerDocumentWrapper=new OuterDocumentWrapper();
        try {
            List<String> fields = new List<String>{
                    'Name', PC_Constants.getQualifiedAPIName('PC_ParentPgRange__c'), PC_Constants.getQualifiedAPIName('PC_Document_Status__c'),
                    PC_Constants.getQualifiedAPIName('PC_Parent_Document__c'), PC_Constants.getQualifiedAPIName('PC_Page_Count__c'), PC_Constants.getQualifiedAPIName('PC_IsSplit__c')
            };

            //FLS check access before SOQL
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Document__c'), PC_Database.Operation.Reading, fields);

            //get a list of child documents for a parent document
            List<PC_Document__c> lstchildDoc = [
                    SELECT Id, Name, PC_ParentPgRange__c, PC_Document_Status__c, PC_Parent_Document__c, PC_Page_Count__c, CreatedDate, PC_Parent_Document__r.OwnerId, OwnerId
                    FROM PC_Document__c
                    WHERE PC_Parent_Document__c = :ParentID AND PC_IsSplit__c = true
                    ORDER BY CreatedDate desc
            ];

            if (lstchildDoc != null && lstchildDoc.size() > 0) {
                for (PC_Document__c childDoc : lstchildDoc) {
                    for (PC_PicklistFieldManager.PicklistEntryWrapper pew : docStatusLabels) {
                        if (pew.value == childDoc.PC_Document_Status__c) {
                            statusLabel = pew.label;
                        }
                    }

                    lstChildDocWrapper.add(new DocumentWrapper(childDoc, statusLabel, relationTypeSplit,childDocDescription+' <' + childDoc.PC_ParentPgRange__c + '>',isAdmin));
                }
            }

            /*The following code fetches the parent document details of a document record which need to be shown in the 'Related'
            component in document viewer*/
            if(isRelatedComponent){
                List<String> documentFields = new List<String>();
                documentFields.add(PC_Constants.getQualifiedAPIName('PC_Parent_Document__c'));
                documentFields.add(PC_Constants.getQualifiedAPIName('PC_ParentPgRange__c'));
                documentFields.add(PC_Constants.getQualifiedAPIName('PC_Document_Status__c'));
                PC_Database.assertAccess(PC_Constants.DOCUMENT_OBJECT, PC_Database.Operation.Reading, documentFields);
                parentDocDetailsList = [SELECT Id,PC_Parent_Document__c FROM PC_Document__c WHERE Id = :ParentID];

                Id parentDocId = parentDocDetailsList[0].PC_Parent_Document__c;

                //FLS is done above
                parentDocumentList = [
                        SELECT Id, Name, PC_ParentPgRange__c, PC_Document_Status__c, PC_Parent_Document__c, PC_Page_Count__c, CreatedDate, PC_Parent_Document__r.OwnerId, OwnerId
                        FROM PC_Document__c
                        WHERE Id = :parentDocId
                ];

                if (null != parentDocumentList && !parentDocumentList.isEmpty()) {
                    for (PC_Document__c parentDoc : parentDocumentList) {
                        for (PC_PicklistFieldManager.PicklistEntryWrapper pew : docStatusLabels) {
                            if (pew.value == parentDoc.PC_Document_Status__c) {
                                parentDocStatusLabel = pew.label;
                            }
                        }

                        lstChildDocWrapper.add(new DocumentWrapper(parentDoc, parentDocStatusLabel, relationTypeOriginal, parentDocDescription, isAdmin));
                    }
                }
            }

            outerDocumentWrapper.childDocumentWrapperList=lstChildDocWrapper;
            outerDocumentWrapper.hasAttachment=checkDocHasAttachment(ParentID);
        } catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        //return lstChildDocWrapper;
        return JSON.serialize(outerDocumentWrapper);
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
                childDoc.PC_Sorted_Parent_Pg_Num__c= PC_Utility.convertNumbersToRange(ParentPgNum);
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
    public static void updChildDoc(String docId, String pgRange, String ParentPgNum, String pageCount) {
        PC_Document__c childDoc = new PC_Document__c();
        List<String> fields = new List<String>{};
        try{
            if (docId != null ) {

                Set<Id> docIdSet = new Set<Id>();
                docIdSet.add(docId);

                /* PC-8197: Delete existing attachments or salesforce files if present on document record*/
                processDocumentSalesforceFileAndAttachments(docIdSet);

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
                    childDoc.PC_Correlation_Id__c = PC_Constants.EMPTY_STRING;
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
    public static void updateStatus(Id parentDocId, Boolean isAdmin){
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

            PC_Document__c parentDoc = [SELECT Id, Name, PC_Document_Status__c, OwnerId FROM PC_Document__c WHERE Id = :parentDocId];

            String query = 'SELECT Id, Name, PC_Sorted_Parent_Pg_Num__c, PC_Document_Status__c, OwnerId FROM PC_Document__c';
            String whereQuery = ' WHERE PC_Parent_Document__c =' + '\'' + parentDocId + '\'';
            whereQuery += ' AND PC_IsSplit__c = true';
            if (isAdmin == false) {
                whereQuery += ' AND OwnerId = ' + '\'' + parentDoc.OwnerId + '\'';
            }

            whereQuery += ' AND (PC_Document_Status__c =' + '\'' + PC_Constants.DOCUMENT_STATUS_READY_FOR_SPLIT + '\'';
            whereQuery += ' OR PC_Document_Status__c =' + '\'' + PC_Constants.DOCUMENT_STATUS_SPLIT_FAILURE + '\'' + ')';
            List<PC_Document__c> lstchildDoc = PC_Database.queryWithAccess(query + whereQuery, true);

            //set parent document status to 'Split in Progress'
            parentDoc.PC_Document_Status__c = PC_Constants.DOCUMENT_STATUS_SPLIT_IN_PROGRESS;
            //create a unique correlationId to mark every transaction as document id + timestamp
            String correlationId = (String) parentDocId + system.now();
            parentDoc.PC_Correlation_Id__c = correlationId;

            if (lstchildDoc != null && lstchildDoc.size() > 0) {
                for (PC_Document__c childDoc : lstchildDoc) {
                    //set child document status to 'Awaiting Attachment'
                    childDoc.PC_Document_Status__c = PC_Constants.DOCUMENT_STATUS_AWAITING_ATTACHMENT;
                    childDoc.PC_Correlation_Id__c = correlationId;
                    childDocumentIds.add(childDoc.Id);
                }
            }

            /* PC-8197: Added code to delete existing attachments or salesforce file if present on document record*/
            processDocumentSalesforceFileAndAttachments(childDocumentIds);

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
        @AuraEnabled public String relationType {get; set;}
        @AuraEnabled public String description {get; set;}
        @AuraEnabled public String createdDate {get; set;}
        @AuraEnabled public Boolean enableSplit {get; set;} //Set to true if child doc and parent doc owner's match

        public DocumentWrapper(PC_Document__c doc, String statusLabel,String relationType,String description, Boolean isAdmin) {
            this.DocumentId = doc.Id;
            this.DocumentName = doc.Name;
            this.DocumentPageRange = doc.PC_ParentPgRange__c;
            this.DocumentStatus = doc.PC_Document_Status__c;
            this.DocumentStatusLabel = statusLabel;
            this.ParentDocumentId = doc.PC_Parent_Document__c;
            this.PageCount = (Integer) doc.PC_Page_Count__c;
            this.DocUrl = '/'+ doc.Id; //PC-1677 - Added docURL attribute
            this.relationType=relationType;
            this.description=description;
            this.createdDate=String.valueOf(Date.valueOf(doc.CreatedDate).month()+'/'+
                    Date.valueOf(doc.CreatedDate).day()+'/'+
                    String.valueOf(Date.valueOf(doc.CreatedDate).year()).right(2));
            this.enableSplit = (isAdmin == true) ? true : (doc.PC_Parent_Document__r.OwnerId != null ? (doc.PC_Parent_Document__r.OwnerId == doc.OwnerId ? true : false) : false);
        }
    }

    @AuraEnabled
    public static Boolean checkDocHasAttachment(Id docId){
        Boolean hasAttachments=false;
        try{
            /* PC-8197: Added code to get the setting to decide if Salesforce File or Attachment needs to be considered */
            PC_Constants.UseAttachmentOrSalesforceFile  useAttachmentOrSalesforceFile = PC_SYSTEM.getFileOrAttachmentInUse();

            if(useAttachmentOrSalesforceFile == PC_Constants.UseAttachmentOrSalesforceFile.UseFile){
                /* PC-8197: Added code to check if document has Salesforce file*/
                hasAttachments = checkIfDocHasSalesforceFile(docId);
            }
            else if(useAttachmentOrSalesforceFile == PC_Constants.UseAttachmentOrSalesforceFile.UseAttachment) {
                /* PC-8197: Added code to check if document has Attachment file*/
                hasAttachments = checkIfDocHasAttachment(docId);
            } else if(useAttachmentOrSalesforceFile == PC_Constants.UseAttachmentOrSalesforceFile.UseFileAndAttachment || useAttachmentOrSalesforceFile == PC_Constants.UseAttachmentOrSalesforceFile.UseAttachmentAndFile){
                hasAttachments = checkIfDocHasSalesforceFileOrAttachment(docId, useAttachmentOrSalesforceFile);
            }
            return hasAttachments;
        }catch(Exception ex){
            PC_Utility.createExceptionLog(ex);
        }
        return hasAttachments;
    }

    /**********************************************************************************************
    Method Name    : checkIfDocHasSalesforceFile
    Description    : This method checks if a document record has Salesforce file or attachments as per Patient Connect custom metadata settings
    parameters     : Id, PC_Constants.UseAttachmentOrSalesforceFile
    Return Type    : Boolean
    User Story     : PC-8438
    **********************************************************************************************/
    private static Boolean checkIfDocHasSalesforceFileOrAttachment(Id docId, PC_Constants.UseAttachmentOrSalesforceFile useAttachmentOrSalesforceFile) {
        Boolean hasAttachments = false;
        if (useAttachmentOrSalesforceFile == PC_Constants.UseAttachmentOrSalesforceFile.UseFileAndAttachment) {
            hasAttachments = checkIfDocHasSalesforceFile(docId);
            if (hasAttachments == false) {
                hasAttachments = checkIfDocHasAttachment(docId);
            }
        } else {
            hasAttachments = checkIfDocHasAttachment(docId);
            if (hasAttachments == false) {
                hasAttachments = checkIfDocHasSalesforceFile(docId);
            }
        }
        return hasAttachments;
    }

    /**********************************************************************************************
    Method Name    : checkIfDocHasSalesforceFile
    Description    : This method checks if a document record has Salesforce file
    parameters     : Id(docId)
    Return Type    : Boolean
    User Story     : PC-8197
    **********************************************************************************************/
    private static Boolean checkIfDocHasSalesforceFile(Id docId){
        Boolean hasAttachments=false;
        List<String> fields = new List<String>{'ContentDocumentId', 'Id'};
        //Check if user has access to peform the READ operation
        PC_Database.assertAccess(PC_Constants.PC_CONTENTDOCUMENTLINK, PC_Database.Operation.Reading, fields);
        List<ContentDocumentLink> listContentDocumentsLink = [SELECT ContentDocumentId, Id FROM ContentDocumentLink WHERE LinkedEntityId = :docId ];
        if (null != listContentDocumentsLink && !listContentDocumentsLink.isEmpty()) {
            hasAttachments = true;
        }
        return hasAttachments;
    }

    /**********************************************************************************************
    Method Name    : checkIfDocHasAttachment
    Description    : This method checks if a document record has Attachment
    parameters     : Id
    Return Type    : Boolean
    User Story     : PC-8197
    **********************************************************************************************/
    private static Boolean checkIfDocHasAttachment(Id docId){
        Boolean hasAttachments=false;
        List<String> fields = new List<String>{'Name', 'Body'};
        //Check if user has access to peform the READ operation
        PC_Database.assertAccess(PC_Constants.PC_ATTACHMENT, PC_Database.Operation.Reading, fields);
       List<Attachment> lstAttachments = [SELECT Id, Name, Body FROM Attachment WHERE ParentId = :docId order by CreatedDate desc];
        if (null != lstAttachments && !lstAttachments.isEmpty()) {
            hasAttachments = true;
        }
        return hasAttachments;
    }

    /**********************************************************************************************
    Method Name    : processDocumentSalesforceFileAndAttachments
    Description    : This method deletes existing Salesforce files or Attachments on document record or child document records
    parameters     : Set<Id>
    Return Type    : void
    User Story     : PC-8197
    **********************************************************************************************/
    public static void processDocumentSalesforceFileAndAttachments(Set<Id> docIdSet){
        /* PC-8197: Added code to check if Salesforce file or Attachment is supported on document record*/
        PC_Constants.UseAttachmentOrSalesforceFile useAttachmentOrSalesforceFile = PC_SYSTEM.getFileOrAttachmentInUse();

        if((useAttachmentOrSalesforceFile == PC_Constants.UseAttachmentOrSalesforceFile.UseFile)){

            /* PC-8197: Added code to delete any existing Salesforce file if present on document record*/
            deleteExistingSalesforceFilesOnDocRecords(docIdSet);
        }

         else if(useAttachmentOrSalesforceFile == PC_Constants.UseAttachmentOrSalesforceFile.UseAttachment) {

            /* PC-8197: Added code to delete any existing Attachment file if present on document record*/
            deleteExistingAttachmentFilesOnDocRecords(docIdSet);
        } else if (useAttachmentOrSalesforceFile == PC_Constants.UseAttachmentOrSalesforceFile.UseFileAndAttachment || useAttachmentOrSalesforceFile == PC_Constants.UseAttachmentOrSalesforceFile.UseAttachmentAndFile) {
             deleteExistingAttachmentOrFilesOnDocRecords(docIdSet, useAttachmentOrSalesforceFile);
         }
    }

    /**********************************************************************************************
    Method Name    : deleteExistingSalesforceFilesOnDocRecords
    Description    : This method deletes existing Salesforce files or Attachments on document record or child document records
    parameters     : Set<Id>, PC_Constants.UseAttachmentOrSalesforceFile
    Return Type    : void
    User Story     : PC-8438
    **********************************************************************************************/
    private static void deleteExistingAttachmentOrFilesOnDocRecords(Set<Id> docIdSet, PC_Constants.UseAttachmentOrSalesforceFile useAttachmentOrSalesforceFile){
        Boolean hasAttachments = false;
        if (useAttachmentOrSalesforceFile == PC_Constants.UseAttachmentOrSalesforceFile.UseFileAndAttachment) {
            hasAttachments = deleteExistingSalesforceFilesOnDocRecords(docIdSet);
            if (hasAttachments == false) {
                hasAttachments = deleteExistingAttachmentFilesOnDocRecords(docIdSet);
            }
        } else {
            hasAttachments = deleteExistingAttachmentFilesOnDocRecords(docIdSet);
            if (hasAttachments == false) {
                hasAttachments = deleteExistingSalesforceFilesOnDocRecords(docIdSet);
            }
        }
    }

    /**********************************************************************************************
    Method Name    : deleteExistingSalesforceFilesOnDocRecords
    Description    : This method deletes existing Salesforce files on document record or child document records
    parameters     : Set<Id>
    Return Type    : void
    User Story     : PC-8197
    **********************************************************************************************/
    private static Boolean deleteExistingSalesforceFilesOnDocRecords(Set<Id> docIdSet) {
        Boolean hasAttachments = false;
        List<String> fields = new List<String>{};
        Set<Id> contentDocumentIdSet = new Set<Id>();
        fields = new List<String>{'ContentDocumentId'};
        //Check if user has access to peform the READ operation
        PC_Database.assertAccess(PC_Constants.PC_CONTENTDOCUMENTLINK, PC_Database.Operation.Reading, fields);
        List<ContentDocumentLink> listContentDocumentsLink = [SELECT ContentDocumentId, Id FROM ContentDocumentLink WHERE LinkedEntityId IN :docIdSet];

        if (listContentDocumentsLink.size() > 0) {
            for (ContentDocumentLink contentId : listContentDocumentsLink) {
                contentDocumentIdSet.add(contentId.ContentDocumentId);
            }

            List<ContentDocument> listContentDocuments = [SELECT Id FROM ContentDocument WHERE Id IN :contentDocumentIdSet];
            if (listContentDocuments.size() > 0) {
                PC_Database.del(listContentDocuments, true);
            }
            hasAttachments = (listContentDocuments.size() > 0);
        }
        return hasAttachments;
    }

    /**********************************************************************************************
    Method Name    : deleteExistingAttachmentFilesOnDocRecords
    Description    : This method deletes existing Attachments on document record or child document records
    parameters     : Set<Id>
    Return Type    : void
    User Story     : PC-8197
    **********************************************************************************************/
    private static Boolean deleteExistingAttachmentFilesOnDocRecords(Set<Id> docIdSet){
        List<String> fields = new List<String>{};
        //Check FLS before SOQL
        fields = new List<String>{'Id'};
        PC_Database.assertAccess(PC_Constants.PC_ATTACHMENT, PC_Database.Operation.Reading, fields);
        List<Attachment> lstAttachments = [SELECT Id FROM Attachment WHERE ParentId IN :docIdSet];
        if (lstAttachments.size() > 0) {
            PC_Database.del(lstAttachments, true);
        }
        return (lstAttachments.size() > 0);
    }

    public inherited sharing class OuterDocumentWrapper{

        public List<DocumentWrapper> childDocumentWrapperList {get;set;}
        public Boolean hasAttachment{get;set;}
        OuterDocumentWrapper(){
            childDocumentWrapperList=new List<DocumentWrapper>();
            hasAttachment=false;
        }
    }
}