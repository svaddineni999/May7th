/*********************************************************************************
Class Name      : PC_LookupSObjectLightningController
Description     : Controller class used for simulating a lookup search for lightning
Created By      : Deloitte               
Created Date    : June 08, 2016
Modification Log:
---------------------------------------------------------------------------------- 
Developer              Date                   Description
-----------------------------------------------------------------------------------            
Tetiana Danylyshyn    June 08, 2016          Initial Version
Alina Balan           July 14, 2016          Modified "lookup" method in order to accept custom object
Ajinkya Deshmukh	  June 20, 2017			 FLS Check Added (Code Merge)
Haritha Reddy         Jun 18, 2019           [PC-4912] Updated Change Owner logic to support Files
Hitha Avalakki        Nov 07, 2019           [PC-5503] Added a new method lookupUserOrGroup() to search
                                             User or Group records to assign them as the owner of document record.
Tejas Patel           Nov 14, 2019           PC-5725 Attachment owner changes only for User not Groups
Haritha Reddy         Dec 16, 2019           [PC-5791] Added error handling for methods where it is missing
Vijay Kashikar        21-Jan-21              [PC-7102] Added FLS Checks
Vijay Kashikar        21-Jan-2021            [PC-7102] Added sharing clause
Hitha Avalakki        Oct 12, 2021           [PC-8197] Added code to leverage PC_DocumentPreviewStrictMode custom metadata setting to change the owner of attachments or salesforce files when document owner is changed.
Hitha Avalakki        Oct 21, 2021           [PC-8197] Owner of Salesforce File or Attachment can only be of type User.Added code for the same
Satheesh Kumar        Jul 22, 2022           [PC-8438] Added logic to consider salesforce files in the absence of any attachment on the document record when both 'Use Salesforce Files' and 'Salesforce Strict File mode' value is 'False'.
*********************************************************************************/

public with sharing class PC_LookupSObjectLightningController {
    
    /*********************************************************************************
Method Name    : lookup
Author         : Tetiana Danylyshyn
Description    : Aura enabled method to search a specified SObject for a specific string
Return Type    : Result[]
Parameter      : String searchString
*********************************************************************************/
    @AuraEnabled
    public static Result[] lookup(String searchString, String objectAPIName) {
        String s = '%' + searchString + '%';
        List<Result> results = new List<Result>();
        try {
            List<SObject> lstObjects;

            if (!String.isBlank(objectAPIName)) {
                objectAPIName = objectAPIName.endsWithIgnoreCase('__c') ? PC_Constants.getQualifiedAPIName(objectAPIName) : objectAPIName;
                List<String> fields = new List<String>{'Name'};
                    PC_Database.assertAccess(objectAPIName ,PC_Database.Operation.Reading, fields);

                String sQuery = 'SELECT Id, Name FROM ' + objectAPIName + '  WHERE Name LIKE \'' + String.escapeSingleQuotes(s) + '\'  LIMIT 50';

                lstObjects = Database.query(sQuery);

            } else {
                List<String> fields = new List<String>{'Name'};
                PC_Database.assertAccess('User' ,PC_Database.Operation.Reading, fields);
                lstObjects = [SELECT Id, Name FROM User WHERE Name LIKE :s LIMIT 50];
            }
            if (lstObjects.size() > 0) {
                for (SObject obj : lstObjects) {
                    Result r = new Result(obj.get('Name') + '', obj.get('Id') + '');
                    results.add(r);
                }
            }
        } catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return results;
    }

    /*********************************************************************************
    Method Name    : lookupUserOrGroup
    Author         : Hitha Avalakki
    Description    : Aura enabled method to search a specified SObject for a specific string
    Return Type    : Result[]
    Parameter      : String searchString, String objectAPIName
    *********************************************************************************/
    @AuraEnabled
    public static Result[] lookupUserOrGroup(String searchString, String objectAPIName) {
        String s = '%' + searchString + '%';
        List<Result> results = new List<Result>();
        List<SObject> lstObjects = new List<SObject>();
        try {
            if (!String.isBlank(objectAPIName)) {
                objectAPIName = objectAPIName.endsWithIgnoreCase('__c') ? PC_Constants.getQualifiedAPIName(objectAPIName) : objectAPIName;
                List<String> fields = new List<String>{'Name'};
                PC_Database.assertAccess(objectAPIName ,PC_Database.Operation.Reading, fields);

                String sQuery = 'SELECT Id, Name FROM ' + objectAPIName + '  WHERE Name LIKE \'' + String.escapeSingleQuotes(s) + '\' ';

                /* Following query is used to search user or group records for a given string value*/
                if(objectAPIName.equals(PC_Constants.PC_USER)){
                    //Following SOSL query would be required if the 'Name' field of User object is encrypted
                    //sQuery = 'FIND {*'+String.escapeSingleQuotes(searchString) + '*} IN Name FIELDS RETURNING '+ objectAPIName + '(Id, Name'+ ' WHERE Name LIKE \'' + String.escapeSingleQuotes(s) + '\')  LIMIT 50';

                    sQuery = sQuery +' AND isActive = true LIMIT 50';

                }
                else if(objectAPIName.equals(PC_Constants.PC_Group)){
                    /* Following SOSL query has a condition to search only those Groups which are of type 'Queue' */
                    //Following SOSL query would be required if the 'Name' field of Group object is encrypted
                    //sQuery = 'FIND {*'+String.escapeSingleQuotes(searchString) + '*} IN Name FIELDS RETURNING '+ objectAPIName + '(Id, Name'+ ' WHERE Type=\'Queue\')  LIMIT 50';

                    String documentObjectAPIName =PC_Constants.DOCUMENT_OBJECT;
                    String queueObjectAPIName =PC_Constants.PC_Queue;

                    //Following query is required in order to fetch only those Queue records which are configured for PC_Document__c object.
                    String queueSobjectQuery = 'Id IN (SELECT QueueId FROM QueueSobject where SobjectType =:documentObjectAPIName)';
                    sQuery = sQuery + ' AND Type = :queueObjectAPIName AND ('+ queueSobjectQuery +') LIMIT 50';
                }

                lstObjects = Database.query(sQuery);

            }

            if (lstObjects.size() > 0) {
                for (SObject obj : lstObjects) {
                    Result r = new Result(obj.get('Name') + '', obj.get('Id') + '');
                    results.add(r);
                }
            }
        } catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return results;
    }
    
    /*********************************************************************************
Class Name    : Result
Author        : Tetiana Danylyshyn
Description   : Inner class to wrap up an SObject Label and its Id
*********************************************************************************/
    public inherited sharing class Result {
        @AuraEnabled public String SObjectLabel {get; set;}
        @AuraEnabled public Id SObjectId {get; set;}
        public Result(String sObjectLabel, Id sObjectId) {
            this.SObjectLabel = sObjectLabel;
            this.SObjectId = sObjectId;
        }
    }
    
    
    @AuraEnabled
    public static DocumentWrapper getDocRecord(Id docId) {
        DocumentWrapper docWrapper = new DocumentWrapper();
        /*
* FLS, additional fields to capture engagement program and manufacturer of the document
* and contructor for docFieldWrapper updated for [PC-1598]
*/
        if (String.isBlank(docId)) return docWrapper;
        
        try{
            //Create a list of fields to check if user has field level security on PC_Document__c fields
            List<String> fields = new List<String>{'Name', 'Owner.Name'};
                    
            //Check if user has access to peform the READ operation
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Document__c'),PC_Database.Operation.Reading, fields);
            
            PC_Document__c oDoc = [SELECT Id, Name,Owner.Name FROM PC_Document__c
                                   WHERE Id =: docId LIMIT 1];
            
            docWrapper.document = oDoc;
            
        }catch(Exception e) {
            PC_Utility.logAndThrowException(e);
        }
        return docWrapper;
    }
    
    
    @AuraEnabled
    public static DocumentWrapper reassignDocumentOwner(Id docId, Id ownerId, String sUserName, String userOrGroup) {
        DocumentWrapper docWrapper = getDocRecord(docId);
        try{

            //check if the owner is already the current user
            if (docWrapper.document.OwnerId != ownerId) {

                PC_Document__c doc = updateDocumentOwner(docWrapper.document, ownerId, sUserName, userOrGroup);
                docWrapper.document = doc;
            }
        }
        catch (Exception ex){
            throw ex;
        }
        return docWrapper;
    }
    
    /*********************************************************************************
Method Name    : updateDocumentOwner
Author         : Tetiana Danylyshyn
Description    : This method is used to update the document owner with the owner sent as param
Return Type    : PC_Document__c
Parameter      : PC_Document__c doc, Id ownerId, String sUserName
*********************************************************************************/
    @AuraEnabled
    public static PC_Document__c updateDocumentOwner(PC_Document__c doc, Id ownerId, String sUserName, String userOrGroup) {
        try {
            doc.OwnerId = ownerId;
            PC_Database.upd(doc);//Updated by mapatil to enforce CRUD/FLS

            /* PC-8197: Change owner of salesforce file or attachment file present on document record. */
            if(userOrGroup == PC_Constants.PC_USER){
                changeOwner(doc, ownerId);
            }

        } catch(Exception ex){
            PC_Utility.logAndThrowException(ex);
        }
        return doc;
    }
    
    
    /*********************************************************************************
Class Name     : DocumentWrapper
Description    : Wrapper class for PC_Document__c
*********************************************************************************/
    
    public inherited sharing class DocumentWrapper {
        @AuraEnabled public PC_Document__c document {get; set;}
        
        @AuraEnabled public Id loggedInUserId {get { return userinfo.getUserId();}}
        @AuraEnabled public Boolean loadFaxContainer {get; set;}
        @AuraEnabled public Boolean loadEmailContainer {get; set;}
        
        public DocumentWrapper() {
            
            loadFaxContainer = false;
            loadEmailContainer = false;
        }
    }

    /**********************************************************************************************
    Method Name    : changeOwner
    Description    : This method changes the owner of salesforce file (and/or attachment file) present on document record
    parameters     : PC_Document__c, Id
    Return Type    : None
    User Story     : PC-8197
    **********************************************************************************************/
    public static void changeOwner(PC_Document__c doc,Id ownerId){
        PC_Constants.UseAttachmentOrSalesforceFile useAttachmentOrSalesforceFile = PC_SYSTEM.getFileOrAttachmentInUse();

        if (useAttachmentOrSalesforceFile == PC_Constants.UseAttachmentOrSalesforceFile.UseFile) {
            changeOwnerOfSalesforceFileOnDocumentRecord(doc, ownerId);
        } else if (useAttachmentOrSalesforceFile == PC_Constants.UseAttachmentOrSalesforceFile.UseAttachment) {
            changeOwnerOfAttachmentOnDocumentRecord(doc, ownerId);
        } else if ((useAttachmentOrSalesforceFile == PC_Constants.UseAttachmentOrSalesforceFile.UseAttachmentAndFile) || (useAttachmentOrSalesforceFile == PC_Constants.UseAttachmentOrSalesforceFile.UseFileAndAttachment)) {
            changeOwnerOfAttachmentOrFileOnDocumentRecord(doc, useAttachmentOrSalesforceFile, ownerId);
        }
    }

    /**********************************************************************************************
     Method Name    : changeOwnerOfSalesforceFileOnDocumentRecord
     Description    : This method changes the owner of salesforce file or attachment file as per Patient Connect custom metadata settings)
     parameters     : PC_Document__c, PC_Constants.UseAttachmentOrSalesforceFile, Id
     Return Type    : None
     User Story     : PC-8438
     **********************************************************************************************/
    private static void changeOwnerOfAttachmentOrFileOnDocumentRecord(PC_Document__c doc, PC_Constants.UseAttachmentOrSalesforceFile useAttachmentOrSalesforceFile, Id ownerId){
        Boolean hasAttachments = false;
        if (useAttachmentOrSalesforceFile == PC_Constants.UseAttachmentOrSalesforceFile.UseFileAndAttachment) {
            hasAttachments = changeOwnerOfSalesforceFileOnDocumentRecord(doc,ownerId);
            if (hasAttachments == false) {
                hasAttachments = changeOwnerOfAttachmentOnDocumentRecord(doc,ownerId);
            }
        } else {
            hasAttachments = changeOwnerOfAttachmentOnDocumentRecord(doc,ownerId);
            if (hasAttachments == false) {
                hasAttachments = changeOwnerOfSalesforceFileOnDocumentRecord(doc,ownerId);
            }
        }
    }

    /**********************************************************************************************
    Method Name    : changeOwnerOfSalesforceFileOnDocumentRecord
    Description    : This method changes the owner of salesforce file
    parameters     : PC_Document__c, PC_Constants.UseAttachmentOrSalesforceFile,Id
    Return Type    : None
    User Story     : PC-8197
    **********************************************************************************************/
    private static Boolean changeOwnerOfSalesforceFileOnDocumentRecord(PC_Document__c doc, Id ownerId){
        //FLS Check
        List<String> cdlFields = new List<String>{'LinkedEntityId','ContentDocument'};
        PC_Database.assertAccess('ContentDocumentLink',PC_Database.Operation.Reading, cdlfields);

        List<ContentDocumentLink> lstContentDocs = [SELECT ContentDocumentId, ContentDocument.ContentModifiedDate FROM ContentDocumentLink
        WHERE LinkedEntityId =: doc.Id order by ContentDocument.ContentModifiedDate desc];

        if (lstContentDocs.size() > 0) {
            //FLS Check
            List<String> contentDocFields = new List<String>{'Id','OwnerId','ContentModifiedDate'};
            PC_Database.assertAccess('ContentDocument',PC_Database.Operation.Reading, contentDocfields);

            // Access check is done above.
            List<ContentDocument> relFile = [SELECT Id, OwnerId FROM ContentDocument WHERE Id =: lstContentDocs[0].ContentDocumentId Limit 1];
            if (relFile != null && relFile.size() > 0) {
                relFile[0].OwnerId = ownerId;
                PC_Database.upd(relFile, true);
            }
        }
        return (lstContentDocs.size() > 0);
    }

    /**********************************************************************************************
    Method Name    : changeOwnerOfAttachmentOnDocumentRecord
    Description    : This method changes the owner of attachment file as per Patient Connect custom metadata settings
    parameters     : PC_Document__c, PC_Constants.UseAttachmentOrSalesforceFile,Id
    Return Type    : None
    User Story     : PC-8197
    **********************************************************************************************/
    private static Boolean changeOwnerOfAttachmentOnDocumentRecord(PC_Document__c doc,Id ownerId){
        List<String> fields = new List<String>{'Name','Body'};
        //Check if user has access to peform the READ operation
        PC_Database.assertAccess(PC_Constants.PC_ATTACHMENT,PC_Database.Operation.Reading, fields);
        List<Attachment> lstAttachments = [SELECT Id, Name, Body FROM Attachment WHERE ParentId =: doc.Id order by CreatedDate desc];


        /** [PC-8197] : Update attachment file owner **/
        if (lstAttachments != null && lstAttachments.size() > 0) {
            lstAttachments[0].OwnerId = ownerId;
            PC_Database.upd(lstAttachments, true);//Updated by mapatil to enforce CRUD/FLS
        }
        return (lstAttachments.size() > 0);
    }
}