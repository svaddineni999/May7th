/*********************************************************************************************************
Class Name      : PC_EmailWebService 
Description     : REST API class that accepts a creation of a Document and an attachment from external service
Created By      : Tetiana Danylyshyn
Created Date    : May 30, 2016
Modification Log:
-------------------------------------------------------------------------------------------------------------- 
Developer          Log#         Date                   Description
--------------------------------------------------------------------------------------------------------------            
Tetiana Danylyshyn             	May 30, 2016          	Initial Version
Shabda Bhujad					Dec 07, 2016			Added FLS check to createDocumentRecord method
Mayuresh Patil					Jan 05, 2017			Removed association to PC_Email_Details__c
Shishir Bansal                  June 20, 2019          Based on useSalesforceFiles param(true/false) the content
                                                       will be linked as an attachment or files on Document object.
Shishir Bansal                  06-Dec-2019            [PC-5792] Avoid hardcoding of string variable
Hitha Avalakki                  17-Dec-2019            [PC-5766] Added code changes in order remove the SOQL statement from within for loop
****************************************************************************************************************/
/**
 * REST API class to create Document and an attachment.
 */
@RestResource(urlMapping='/Documents/*')
global with sharing class PC_EmailWebService {

    private static final string PC_SALESFORCE_FILES_VAL = 'useSalesforceFiles';
    private static final string PC_SHARING_OPTION = 'A';
    private static final string PC_SHARING_TYPE= 'V';

    Id idRecType = PC_SYSTEM.recordTypeId(PC_Constants.DOCUMENT_OBJECT, PC_Constants.DOCUMENT_EMAIL_INBOUND_RECORD_TYPE);
    List<PC_Document__c> docuList = new List<PC_Document__c>();
    PC_Document__c attchDoc = new PC_Document__c();
    PC_Document__c docRec = new PC_Document__c();

    /*********************************************************************************
    Method Name    : createInboundRecord
    Description    : method is used to handle REST API request
    Return Type    : Void 
    Parameters     : String, String, String, String             
    *********************************************************************************/
    /*
     * Creates Inbound record as either File or Attachment that is opted in the useSalesforceFiles setting
     */
    @HttpPost
    global static void createInboundRecord(List<PC_EmailServiceRequest> emails) {
        try {
            RestRequest req = RestContext.request;
            Boolean useSalesforceFiles = getSalesforceFilesCheck(req);
            PC_EmailWebService ews = new PC_EmailWebService();


            if (useSalesforceFiles) {
                for (PC_EmailServiceRequest email : emails) {
                    ews.createDocumentFilesRecord(email, useSalesforceFiles);
                }
            } else {
                for (PC_EmailServiceRequest email : emails) {
                    ews.createDocumentAttachmentsRecord(email, useSalesforceFiles);
                }
            }
        }catch (Exception e) {
            PC_Utility.logAndThrowException(e);
        }
    }
    /*********************************************************************************
    Method Name    : createDocumentRecord
    Description    : method is used to create documents with an attachments
    Return Type    : Void 
    Parameters     : PC_EmailServiceRequest             
    *********************************************************************************/
    private void createDocumentAttachmentsRecord(PC_EmailServiceRequest email,Boolean useSalesforceFiles ) {
        List<Attachment> attchList = new List<Attachment>();
        Attachment attch = new Attachment();
        Map<String, String> docuMap = new Map<String, String>();
        Integer i = 0;

        //create parent PC_Document__c record
        createParentDocumentRecord(email);

        //create attachment of main email body
        Attachment emailContent = new Attachment();
        try {
            emailContent.Name = email.subject + PC_Constants.TXT_FORMAT;
            emailContent.Body = Blob.valueOf(email.body.plainTextBody);
            emailContent.ParentId = docRec.Id;
            PC_Database.ins(emailContent);
        } catch (Exception e) {
            PC_Utility.logAndThrowException(e);
        }


        /*create PC_Document__c and Attachment records for each attachment
        from the incoming JSON with the lookup to the parent document */
        if (email.body.textAttachments != null) {
            for (PC_EmailServiceRequest.EmailAttachement tAttachment : email.body.textAttachments) {
                attchDoc = new PC_Document__c();
                attchDoc.RecordTypeId = idRecType;
                attchDoc.PC_Parent_Document__c = docRec.Id;
                attchDoc.PC_Description__c = tAttachment.fileName;
                attchDoc.PC_From_Name__c = email.fromName;
                docuList.add(attchDoc);


                attch = new Attachment();
                attch.Name = tAttachment.fileName;
                attch.Body = Blob.valueOf(tAttachment.body);
                attchList.add(attch);


            }
        }


        if (docuList.size() > 0) {
            try {
                PC_Database.ins(docuList);
            } catch (Exception e) {
                PC_Utility.logAndThrowException(e);
            }
        }
        for (PC_Document__c doc : docuList) {
            docuMap.put(PC_Constants.PC_ATTACHMENT + i + doc.PC_Description__c, doc.Id);
            i++;
        }

        for (Attachment att : attchList) {
            for (Integer j = 0; j <= i; j++) {
                if (docuMap.keyset().contains(PC_Constants.PC_ATTACHMENT + j + att.Name)) {
                    att.ParentId = docuMap.get(PC_Constants.PC_ATTACHMENT + j + att.Name);
                    docuMap.remove(PC_Constants.PC_ATTACHMENT + j + att.Name);
                    break;
                }
            }
        }
        if (attchList.size() > 0) {
            try {
                PC_Database.ins(attchList);
            } catch (Exception e) {
                PC_Utility.logAndThrowException(e);
            }
        }

    }


    /*********************************************************************************
       Method Name    : createDocumentFilesRecord
       Description    : method is used to create documents with a file as an attachment
       Return Type    : Void
       Parameters     : PC_EmailServiceRequest
       *********************************************************************************/
    private void createDocumentFilesRecord(PC_EmailServiceRequest email,Boolean useSalesforceFiles ) {
        List<ContentDocumentLink> contentDocumentLinkList = new List<ContentDocumentLink>();
        ContentDocumentLink cDocumentLink = new ContentDocumentLink();
        Map<String, String> docuMap = new Map<String, String>();
        ContentVersion contentVersion;
        Map<Id,String> contentVersionTitleMap = new Map<Id,String>();
        Integer i = 0;

        //create parent PC_Document__c record

        createParentDocumentRecord(email);

        try {

            // Adding file attachment to the parent document

            contentVersion = new ContentVersion();

            contentVersion.title = email.subject + PC_Constants.TXT_FORMAT;
            contentVersion.PathOnClient = email.subject + PC_Constants.TXT_FORMAT;
            contentVersion.versiondata =  Blob.valueOf(email.body.plainTextBody);
            contentVersion.SharingOption = PC_SHARING_OPTION;
            PC_Database.ins(contentVersion);


            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.id].ContentDocumentId;
            cdl.LinkedEntityId = docRec.Id;
            cdl.ShareType = PC_SHARING_TYPE;
            PC_Database.ins(cdl);

        }
        catch (Exception e) {
            PC_Utility.logAndThrowException(e);
        }

        List<Id> contentVersionIds = new List<Id>();
        if (email.body.textAttachments != null) {

            // creating child document list
            for (PC_EmailServiceRequest.EmailAttachement tAttachment : email.body.textAttachments) {
                attchDoc = new PC_Document__c();
                attchDoc.RecordTypeId = idRecType;
                attchDoc.PC_Parent_Document__c = docRec.Id;
                attchDoc.PC_Description__c = tAttachment.fileName;
                attchDoc.PC_From_Name__c = email.fromName;
                docuList.add(attchDoc);

                // creating child files attachment

                contentVersion = new ContentVersion();
                contentVersion.title =tAttachment.fileName;
                contentVersion.PathOnClient = tAttachment.fileName;
                contentVersion.versiondata = Blob.valueOf(tAttachment.body);
                contentVersion.SharingOption = PC_SHARING_OPTION;
                PC_Database.ins(contentVersion);

                if(contentVersion.Id !=null) {

                    /* Task: [PC-5766]
                    *  Author: Hitha Avalakki
                    *  Description: Following list contentVersionIds has been added in order to remove the SOQL statement from for loop*/
                    contentVersionIds.add(contentVersion.Id);
                }
            }

        }

        /* Task: [PC-5766]---START
        *  Author: Hitha Avalakki
        *  Description: Following changes have been added in order to remove the SOQL statement from for loop*/
        List<ContentVersion> contentVersionList =  new List<ContentVersion>();
        contentVersionList = [SELECT Id,Title, ContentDocumentId FROM ContentVersion WHERE Id IN: contentVersionIds];

        for(ContentVersion contentVersion1: contentVersionList){
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = contentVersion1.ContentDocumentId;
            cdl.ShareType = PC_SHARING_TYPE;

            contentVersionTitleMap.put(cdl.ContentDocumentId ,contentVersion1.title );
            contentDocumentLinkList.add(cdl);
        }

        /* Task: [PC-5766]---END*/

        if (docuList.size() > 0) {
            try {
                // inserting child document records
                PC_Database.ins(docuList);
            }
            catch (Exception e) {
                PC_Utility.logAndThrowException(e);
            }
        }
        for (PC_Document__c doc : docuList) {
            docuMap.put(PC_Constants.PC_ATTACHMENT + i + doc.PC_Description__c, doc.Id);
            i++;
        }



        for (ContentDocumentLink cdl : contentDocumentLinkList) {
            for (Integer j = 0; j <= i; j++) {
                if (docuMap.keyset().contains(PC_Constants.PC_ATTACHMENT + j + contentVersionTitleMap.get(cdl.ContentDocumentId))) {
                    cdl.LinkedEntityId = docuMap.get(PC_Constants.PC_ATTACHMENT + j + contentVersionTitleMap.get(cdl.ContentDocumentId));
                    docuMap.remove(PC_Constants.PC_ATTACHMENT + j +  contentVersionTitleMap.get(cdl.ContentDocumentId));
                    break;
                }

            }
        }
        if (contentDocumentLinkList.size() > 0) {
            try {

                // inserting contentdocument records
                PC_Database.ins(contentDocumentLinkList);
            } catch (Exception e) {
                PC_Utility.logAndThrowException(e);
            }
        }

    }


    /*********************************************************************************
      Method Name    : createParentDocumentRecord
      Description    : method is used to create documents with a file as an attachment
      Return Type    : Void
      Parameters     : PC_EmailServiceRequest
      *********************************************************************************/
    private void createParentDocumentRecord(PC_EmailServiceRequest email) {


        try {
            docRec.RecordTypeId = idRecType;
            docRec.PC_From_Name__c = email.fromName;
            docRec.PC_Description__c = email.subject;
            docRec.PC_From_Email_Address__c = email.fromAddress;
            PC_Database.ins(docRec);
        } catch (Exception e) {
            PC_Utility.logAndThrowException(e);
        }


    }


    /*********************************************************************************
  Method Name    : getSalesforceFilesCheck
  Description    : method is used to fetch boolean value from the request url
  Return Type    : Boolean
  Parameters     : RestRequest
  *********************************************************************************/


    private static Boolean getSalesforceFilesCheck( RestRequest req){
        Boolean useSalesforceFiles ;

        try {
            String salesforceFilesNullCheck = req.params.get(PC_SALESFORCE_FILES_VAL);
            if(!String.isBlank(salesforceFilesNullCheck)) {
                useSalesforceFiles = Boolean.valueOf(salesforceFilesNullCheck);
            }else{
                    useSalesforceFiles = PC_SYSTEM.useSalesforceFiles();
            }
            return useSalesforceFiles;
        }catch (Exception e) {
            PC_Utility.logAndThrowException(e);
        }
       return null;
    }
}