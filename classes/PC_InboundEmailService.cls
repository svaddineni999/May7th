/*********************************************************************************************************
Class Name      : PC_InboundEmailService
Description     : This class will be invoked when salesforce receives an email.
Created By      : Tetiana Danylyshyn
Created Date    : May 31, 2016
Modification Log:
-------------------------------------------------------------------------------------------------------------- 
Developer                   Date                   Description
--------------------------------------------------------------------------------------------------------------            
Tetiana Danylyshyn          May 31, 2016            Initial Version
Shabda Bhujad               Dec 07, 2016            Added FLS check to createDocumentRecord method
Mayuresh Patil              Jan 05, 2017            Removed association to PC_Email_Details__c
Ajinkya Deshmukh            Jun 20, 2017            FLS Check Added (Code Merge)
Mayuresh Patil              Jun 12, 2017            [PC-1670] - Updated record type for Attachment document records for inbound emails;
Shabda Bhujad               Jul 25, 2017            [PC-1966] - Removed the update to docRec.PC_To_Email_Address__c from method createDocumentRecord()
Mayuresh Patil              Jul 26, 2017            Updated CRUD/FLS Checks
Shishir Bansal              Jun 27, 2019            [PC-4809] Adding files/Attachment feature based on the custom metadata settings
Shishir Bansal              Jul 10,2019             [PC-4809] Replaced cid with Blob value of the image attachment
****************************************************************************************************************/
/**
 * This class will be invoked when salesforce receives an email in eletter
 */
global without sharing class PC_InboundEmailService implements Messaging.InboundEmailHandler {
    /**
     * Creates Inbound Document record with all the details of Email received.
     */
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
        try{


            Boolean useSalesforceFiles = PC_SYSTEM.useSalesforceFiles();


            system.debug('email--'+email);

            result.success = createInboundRecord(email, envelope, useSalesforceFiles);
           // result.success = true;
        } catch(Exception ex){
            PC_Utility.createExceptionLog(ex);
            result.success = false;
            result.message = ex.getMessage();
        }
        return result;
    }

    /*********************************************************************************
    Method Name    : createInboundRecord
    Description    : Method to create document and attachment
    Parameters     : Messaging.InboundEmail, Messaging.InboundEnvelope
    Return Type    : boolean
    *********************************************************************************/
    public static boolean createInboundRecord(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope , Boolean useSalesforceFiles){
        Id idRecordType = PC_SYSTEM.recordTypeId(PC_Constants.DOCUMENT_OBJECT, PC_Constants.DOCUMENT_EMAIL_INBOUND_RECORD_TYPE);
        Id idAttachmentRecordType = PC_SYSTEM.recordTypeId(PC_Constants.DOCUMENT_OBJECT, PC_Constants.DOCUMENT_EMAIL_ATTACHMENT_RECORD_TYPE);
        if (idRecordType != null && idAttachmentRecordType != null){
            createDocumentRecord(email, envelope, idRecordType, idAttachmentRecordType , useSalesforceFiles);
        }
        return true;
    }

    /*********************************************************************************
    Method Name    : createDocumentRecord
    Description    : create Document, Attachment and Email details for inbound email
    Parameters     : Messaging.InboundEmail, Messaging.InboundEnvelope, id
    Return Type    : PC_Document__c
    *********************************************************************************/
    public static PC_Document__c createDocumentRecord(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope, Id idRecType, Id idAttachmentRecType , Boolean isSalesforceFilesUsed) {

        List<PC_Document__c> docuList = new List<PC_Document__c>();
        PC_Document__c attchDoc = new PC_Document__c();
        List<Attachment> attchList = new List<Attachment>();
        Attachment attch = new Attachment();
        List<ContentDocumentLink> contentDocumentList = new List<ContentDocumentLink>();
        ContentDocumentLink contentDocLink = new ContentDocumentLink();
        ContentVersion contentVersion = new ContentVersion();
        Map<Id, String> contentDocMap = new Map<Id, String>();
        Map<String, String> docuMap = new Map<String, String>();
        Map<Id, Id> contentDocVersion = new Map<Id, Id>();
        Integer i = 0;
        Attachment emailContent;
        //Create a list of attachments
        Map< String, Id > mapAttachments = new Map< String, Id >();
        ContentVersion parentContentVersion;
        ContentVersion parentContentVersion1;


        //create parent PC_Document__c record
        PC_Document__c docRec = new PC_Document__c();
        try {
            docRec = createDoc(email, envelope, idRecType);
            PC_Database.ins(docRec);
        } catch (Exception e) {
            PC_Utility.logAndThrowException(e);
        }
        if (isSalesforceFilesUsed != null) {

            if (isSalesforceFilesUsed) {
                parentContentVersion = createFileAttachment(email, docRec);
            } else {
                //create Attachment record of email body
                emailContent = createAttachment(email, docRec);
            }
        }

        /*create PC_Document__c and Attachment records for each attachment
        from the incoming email with the lookup to the parent document */
        if (email.textAttachments != null) {
            for (Messaging.Inboundemail.TextAttachment tAttachment : email.textAttachments) {
                attchDoc = new PC_Document__c();
                attchDoc.RecordTypeId = idAttachmentRecType;
                attchDoc.PC_Parent_Document__c = docRec.Id;
                attchDoc.PC_Description__c = tAttachment.fileName;
                attchDoc.PC_From_Name__c = email.fromName;
                attchDoc.PC_From_Email_Address__c = email.fromAddress;
                attchDoc.PC_To_Email_Address_Inbound__c = envelope.toAddress;
                docuList.add(attchDoc);

                if (isSalesforceFilesUsed) {

                    contentVersion = new ContentVersion();
                    contentVersion.Title = tAttachment.fileName;
                    contentVersion.PathOnClient = tAttachment.fileName;
                    contentVersion.VersionData = Blob.valueOf(tAttachment.body);
                    PC_Database.ins(contentVersion);

                    ContentDocumentLink cdl = new ContentDocumentLink();
                    cdl.ContentDocumentId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.id].ContentDocumentId;
                    cdl.ShareType = 'V';
                    contentDocVersion.put(cdl.ContentDocumentId ,contentVersion.Id );
                    contentDocumentList.add(cdl);
                    contentDocMap.put(cdl.ContentDocumentId, contentVersion.Title);
                }

                else {

                    attch = new Attachment();
                    attch.Name = tAttachment.fileName;
                    attch.Body = Blob.valueOf(tAttachment.body);
                    //attch.ContentType = 'text/plain';
                    attch.ContentType = tAttachment.mimeTypeSubType;
                    attchList.add(attch);
                }
            }
        }

        if (email.binaryAttachments != null) {
            for (Messaging.Inboundemail.BinaryAttachment bAttachment : email.binaryAttachments) {
                attchDoc = new PC_Document__c();
                attchDoc.RecordTypeId = idAttachmentRecType;
                attchDoc.PC_Parent_Document__c = docRec.Id;
                attchDoc.PC_Description__c = bAttachment.fileName;
                attchDoc.PC_From_Name__c = email.fromName;
                attchDoc.PC_From_Email_Address__c = email.fromAddress;
                attchDoc.PC_To_Email_Address_Inbound__c = envelope.toAddress;
                docuList.add(attchDoc);
                if (isSalesforceFilesUsed) {
                    contentVersion = new ContentVersion();
                    contentVersion.Title = bAttachment.fileName;
                    contentVersion.PathOnClient = bAttachment.fileName;
                    contentVersion.VersionData = bAttachment.body;

                    PC_Database.ins(contentVersion);

                    contentDocLink = new ContentDocumentLink();
                    contentDocLink.ContentDocumentId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.id].ContentDocumentId;
                    contentDocLink.ShareType = 'V'; // enum in PC_Constants

                    contentDocumentList.add(contentDocLink);

                    contentDocMap.put(contentDocLink.ContentDocumentId, contentVersion.Title);

                    contentDocVersion.put(contentDocLink.ContentDocumentId ,contentVersion.Id );
                    for (integer ii = 0; ii < bAttachment.headers.size(); ii++) {


                        String headerValue = bAttachment.headers[ii].value;
                        if (headerValue.startsWith('ii') || headerValue.startsWith('<image')) {
                            headerValue = headerValue.replaceAll('<', '').replaceAll('>', '');
                            mapAttachments.put(headerValue, null);
                        }
                    }

                } else {

                    attch = new Attachment();
                    attch.Name = bAttachment.fileName;
                    attch.Body = bAttachment.body;
                    //attch.ContentType = 'application/pdf';
                    attch.ContentType = bAttachment.mimeTypeSubType;
                    attchList.add(attch);

                    for (integer ii = 0; ii < bAttachment.headers.size(); ii++) {
                        String headerValue = bAttachment.headers[ii].value;
                        if (headerValue.startsWith('ii') || headerValue.startsWith('<image')) {
                            headerValue = headerValue.replaceAll('<', '').replaceAll('>', '');
                            mapAttachments.put(headerValue, null);
                        }
                    }
                }
            }
        }
        if (docuList.size() > 0) {
            try {
                PC_Database.ins(docuList);//CRUD/FLS enforced in database ins method
            } catch (Exception e) {
                PC_Utility.logAndThrowException(e);
            }
        }
        for (PC_Document__c doc : docuList) {
            docuMap.put(PC_Constants.PC_ATTACHMENT + i + doc.PC_Description__c, doc.Id);
            i++;
        }

        if (isSalesforceFilesUsed != null) {
            if (isSalesforceFilesUsed) {
                for (ContentDocumentLink cdl : contentDocumentList) {
                    for (Integer j = 0; j <= i; j++) {

                        if (docuMap.keyset().contains(PC_Constants.PC_ATTACHMENT + j + contentDocMap.get(cdl.ContentDocumentId))) {
                            cdl.LinkedEntityId = docuMap.get(PC_Constants.PC_ATTACHMENT + j + contentDocMap.get(cdl.ContentDocumentId));
                            docuMap.remove(PC_Constants.PC_ATTACHMENT + j + contentDocMap.get(cdl.ContentDocumentId));
                            break;
                        }
                    }
                }
                if (contentDocumentList.size() > 0) {

                    try {
                        PC_Database.ins(contentDocumentList);//CRUD/FLS enforced in database ins method

                        for (ContentDocumentLink att : contentDocumentList) {
                            for (String name : mapAttachments.keySet()) {
                                if(contentDocMap.get(att.ContentDocumentId) !=null) {
                                    if (name.contains(contentDocMap.get(att.ContentDocumentId))) {   // error is here  -todo-    Map<Id, String> contentDocMap
                                        mapAttachments.put(name, contentDocVersion.get(att.ContentDocumentId)); // Map< String, Id >mapAttachments
                                    }
                                }
                            }
                        }
                    } catch (Exception e) {
                        PC_Utility.logAndThrowException(e);
                    }
                }
            } else {
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
                        PC_Database.ins(attchList);//CRUD/FLS enforced in database ins method

                        for (Attachment att : attchList) {
                            for (String name : mapAttachments.keySet()) {
                                if (name.contains(att.Name)) {
                                    mapAttachments.put(name, att.Id);
                                }
                            }
                        }
                    } catch (Exception e) {
                        PC_Utility.logAndThrowException(e);
                    }
                }
            }
        }

        if (isSalesforceFilesUsed != null) {
            if (isSalesforceFilesUsed) {
                //Process inline images and update the HTML Body
                for (String headerValue : mapAttachments.keySet()) {


                    Blob img;
                    List<ContentVersion> bodyList = [SELECT VersionData FROM ContentVersion WHERE Id= :mapAttachments.get(headerValue)];
                    img = (Blob) bodyList[0].get('VersionData');
                    String newText = String.valueOf(email.htmlBody).replaceAll('cid:' + headerValue, 'data:image/png;base64,' +EncodingUtil.base64Encode(img));
                    Id ContentDocumentId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :parentContentVersion.id].ContentDocumentId;
                    parentContentVersion1 = new ContentVersion();
                    parentContentVersion1.Title = email.subject +  PC_Constants.HTML_FORMAT;
                    parentContentVersion1.PathOnClient = email.subject +  PC_Constants.HTML_FORMAT;
                    parentContentVersion1.VersionData = Blob.valueOf(newText);
                    parentContentVersion1.ContentDocumentId = ContentDocumentId;
                    PC_Database.ins(parentContentVersion1, true);

                }
            }
            else {
                //Process inline images and update the HTML Body
                for (String headerValue : mapAttachments.keySet()) {
                    //Reference Link
                    //String refLink = URL.getSalesforceBaseUrl().toExternalForm() + '/servlet/servlet.FileDownload?file=' + mapAttachments.get(headerValue);
                    //String imageTag = '<img src="' + refLink + 'alt="Image not Found"/>';

                    Blob img;
                    List<Attachment> bodyList = [SELECT Body  FROM Attachment WHERE Id= :mapAttachments.get(headerValue)];
                    img = (Blob) bodyList[0].get('Body');

                   // String newText = String.valueOf(email.htmlBody).replaceAll('cid:' + headerValue, refLink);
                    String newText = String.valueOf(email.htmlBody).replaceAll('cid:' + headerValue, 'data:image/png;base64,' +EncodingUtil.base64Encode(img));
                    emailContent.Body = Blob.valueOf(newText);
                }
                PC_Database.upd(emailContent);
            }
        }
        return docRec;
    }

    /*********************************************************************************
    Method Name    : createFileAttachment
    Author         : Shishir Bansal
    Description    : This method is used for creating a file attachment object
    Return Type    : ContentVersion
    Parameter      : Id docId
    *********************************************************************************/
    public static ContentVersion createFileAttachment(Messaging.InboundEmail email,  PC_Document__c docRec) {

        ContentVersion contentVersion;

        try {
            contentVersion = new ContentVersion();

            if (email.htmlBody != null) {
                contentVersion.Title = email.subject + PC_Constants.HTML_FORMAT;
                contentVersion.PathOnClient = email.subject + PC_Constants.HTML_FORMAT;
                contentVersion.VersionData = Blob.valueOf(email.htmlBody);
            } else {
                contentVersion.Title = email.subject + PC_Constants.TXT_FORMAT;
                contentVersion.PathOnClient = email.subject + PC_Constants.TXT_FORMAT;
                contentVersion.VersionData = Blob.valueOf(email.plainTextBody);
            }
            PC_Database.ins(contentVersion);

            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.id].ContentDocumentId;
            cdl.LinkedEntityId = docRec.Id;
            cdl.ShareType = 'V';
            PC_Database.ins(cdl);
        }
        catch (Exception e) {
            PC_Utility.logAndThrowException(e);
        }
        return contentVersion;
    }



    /*********************************************************************************
    Method Name    : createAttachment
    Author         : Shishir Bansal
    Description    : This method is used for creating an attachment object
    Return Type    : Attachment
    Parameter      : Messaging.InboundEmail , PC_Document__c docRec
    *********************************************************************************/
    public static Attachment createAttachment(Messaging.InboundEmail email,  PC_Document__c docRec) {
        Attachment parentEmailContent;

        try {
            // emailContent.Name = email.subject + PC_Constants.TXT_FORMAT;

            parentEmailContent = new Attachment();

            if (email.htmlBody != null) {
                parentEmailContent.Name = email.subject + PC_Constants.HTML_FORMAT;
                parentEmailContent.Body = Blob.valueOf(email.htmlBody);
                parentEmailContent.ContentType = 'text/html';
            } else {
                parentEmailContent.Name = email.subject + PC_Constants.TXT_FORMAT;
                parentEmailContent.Body = Blob.valueOf(email.plainTextBody);
                parentEmailContent.ContentType = 'text/plain';
            }
            parentEmailContent.ParentId = docRec.Id;
            PC_Database.ins(parentEmailContent);


        } catch (Exception e) {
            PC_Utility.logAndThrowException(e);
        }
        return parentEmailContent;
    }


    /*********************************************************************************
    Method Name    : createDocumentRecord
    Author         : Shishir Bansal
    Description    : This method is used for generating document record details
    Return Type    : PC_Document__c
    Parameter      : Messaging.InboundEmail , PC_Document__c docRec
    *********************************************************************************/
    public static PC_Document__c createDoc(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope, Id idRecType) {
        PC_Document__c tempDocRec = new PC_Document__c();

        try {
            // emailContent.Name = email.subject + PC_Constants.TXT_FORMAT;

            tempDocRec.RecordTypeId = idRecType;
            tempDocRec.PC_From_Name__c = email.fromName;
            tempDocRec.PC_Description__c = email.subject;
            tempDocRec.PC_From_Email_Address__c = email.fromAddress;
            tempDocRec.PC_To_Email_Address_Inbound__c = envelope.toAddress;
        } catch (Exception e) {
            PC_Utility.logAndThrowException(e);
        }
        return tempDocRec;
    }
}