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
Shishir Bansal              Jul 10,2019              [PC-4809] Replaced cid with Blob value of the image attachment
Satheesh Kumar              Jul 10, 2020            [PC-6364] Added logic to create task for inbound email and link the inbound email document to case record if it a reply
Satheesh Kumar              Jul 16, 2020            [PC-6551] Added logic to fetch threadId either from email body or email subject. Modified regex in extractThreadId method to support threadId in email subject
Satheesh Kumar              Aug 05, 2020            [PC-6622] Added logic to populate Engagement Program field in Inbound Email Document
Satheesh Kumar              Dec 04, 2020            [PC-7083] Populate Action Component in inbound email task record
Satheesh Kumar              Dec 04, 2020            [PC-6685] Populating name field in the inbound task record based on from address.
****************************************************************************************************************/
/**
 * This class will be invoked when salesforce receives an email in eletter2
 */
global without sharing class PC_InboundEmailService2 implements Messaging.InboundEmailHandler {

    private static String engagementProgramId;
    private static String recordId;
    private static String parentPCDocumentId;
    /**
     * Creates task, inbound Document record with all the details of Email received in eletter2. It links the inbound document to Case & outbound document.
     */
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
        try{
            Boolean useSalesforceFiles = PC_SYSTEM.useSalesforceFiles();
            system.debug('email--'+email);

            List<String> threadIds = getThreadIdFromEmail(email);
            if (threadIds != null && !threadIds.isEmpty()) {
                recordId = threadIds[0] ;
                parentPCDocumentId = threadIds[1];
            }
            // Get Engagement Program Id of record for populating Engagement Program field in PC Document
            if (string.isNotBlank(recordId)) {
                engagementProgramId = PC_eLetterService.getEngagementProgramId(recordId);
            }

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
                attchDoc.PC_Engagement_Program__c = docRec.PC_Engagement_Program__c;
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
                attchDoc.PC_Engagement_Program__c = docRec.PC_Engagement_Program__c;
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

                    //String newText = String.valueOf(email.htmlBody).replaceAll('cid:' + headerValue, refLink);
                    String newText = String.valueOf(email.htmlBody).replaceAll('cid:' + headerValue, 'data:image/png;base64,' +EncodingUtil.base64Encode(img));
                    emailContent.Body = Blob.valueOf(newText);
                }
                PC_Database.upd(emailContent);
            }
        }
        // create document link log and also create task for inbound email if it is a reply
        createDocumentLinkLog(docRec, email);
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
            tempDocRec.PC_Parent_Document__c = (String.isNotBlank(parentPCDocumentId) ? parentPCDocumentId : null);
            tempDocRec.PC_Engagement_Program__c = (String.isNotBlank(engagementProgramId) ? engagementProgramId : null);
            tempDocRec.PC_To_Email_Address_Inbound__c = envelope.toAddress;
        } catch (Exception e) {
            PC_Utility.logAndThrowException(e);
        }
        return tempDocRec;
    }

    /*********************************************************************************
    Method Name    : createLinkLogAndTask
    Author         : Satheesh Kumar
    Description    : This method is used for creating link log and task for inbound email
                     If threadId presents in subject, by using that it will link inbound email to triggered Object,
                     link inbound email to outbound email and create task for that inbound email
    Return Type    : void
    Parameter      : PC_Document__c docRec, Messaging.InboundEmail email
    *********************************************************************************/
    private static void createDocumentLinkLog(PC_Document__c inboundDocument, Messaging.InboundEmail email) {
        String contactId;
        List<PC_Document__c> outboundDocument;
        String outboundEmailSenderId = PC_Constants.EMPTY_STRING;
        Case caseObj;
        PC_Document_Log__c documentLog;
        String inboundEmailDocId = ((inboundDocument != null) ? inboundDocument.Id : null);
        String recordIdObjectType;

        try {
            if (String.isNotBlank(recordId)) {
                recordIdObjectType = String.valueOf(Id.valueOf(recordId).getSobjectType());
                //get the contact of the replied user
                contactId = getContactIdByEmailAddress(recordId, email.fromAddress);
                // Get Case Obj for creating link log (if recordId is of case type only)
                if (recordIdObjectType == PC_Constants.PC_CASE) {
                    // FLS Check
                    List<String> caseFields = new List<String>{
                            PC_Constants.getQualifiedAPIName('PC_Care_Coordinator__c'), PC_Constants.getQualifiedAPIName('PC_Engagement_Program__c'), 'Type', 'CaseNumber'
                    };
                    PC_Database.assertAccess(PC_Constants.PC_CASE, PC_Database.Operation.Reading, caseFields);
                    caseObj = [SELECT Id, OwnerId, AccountId, Type, CaseNumber, PC_Care_Coordinator__c, PC_Engagement_Program__c FROM Case WHERE Id = :recordId];
                }
            }

            //Below section is used to get the id of the user who send outbound email for this reply
            if (String.isNotBlank(parentPCDocumentId)) {
                String objType = String.valueOf(Id.valueOf(parentPCDocumentId).getSobjectType());
                if (objType == PC_Constants.DOCUMENT_OBJECT) {
                    // get outbound document sender id
                    // FLS Check
                    List<String> docFields = new List<String>{'Id', 'OwnerId'};
                    PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Document__c'), PC_Database.Operation.Reading, docFields);
                    outboundDocument = [SELECT Id, OwnerId, CreatedById FROM PC_Document__c WHERE Id = :parentPCDocumentId];
                    outboundEmailSenderId = (outboundDocument != null && !outboundDocument.isEmpty()) ? outboundDocument[0].CreatedById : PC_Constants.EMPTY_STRING;
                }
            }

            if (String.isNotBlank(recordId)) {
                recordIdObjectType = String.valueOf(Id.valueOf(recordId).getSobjectType());

                // Create link log, email message and Task (if recordId is of case type only)
                if (recordIdObjectType == PC_Constants.PC_CASE) {
                    Map<String, Schema.SObjectType> sObjectMap = Schema.getGlobalDescribe();
                    String objLabel = sObjectMap.get(PC_Constants.PC_CASE).getDescribe().getLabel();

                    // link the inbound email to case by creating document log
                    if (inboundEmailDocId != null) {
                        documentLog = new PC_Document_Log__c();
                        documentLog.PC_Document__c = inboundEmailDocId;
                        documentLog.PC_Program__c = recordId;
                        documentLog.PC_Association_Record_ID__c = recordId;
                        documentLog.PC_Association_Record_Name__c = ((caseObj != null && caseObj.CaseNumber != null) ? caseObj.CaseNumber : null);
                        documentLog.PC_Association_Type__c = ((caseObj.Type != null) ? (String.isNotBlank(objLabel) ? (objLabel + ': ' + caseObj.Type) : caseObj.Type) : null);
                        PC_Database.ins(documentLog);
                    }
                }
                //Email Message for inbound email
                createEmailMessageForInboundEmail(recordId, contactId, outboundEmailSenderId, email);
                // Create Task for inbound email and add it to case if it a reply
                String subject = System.Label.PC_InboundEmail_TaskSubject + ' ' + email.fromAddress;
                createTaskForInboundEmail(recordId, contactId, inboundEmailDocId, outboundEmailSenderId, subject);
            }
        } catch (Exception e) {
            PC_Utility.logAndThrowException(e);
        }
    }

    /*********************************************************************************
    Method Name    : createLinkLogAndTask
    Author         : Satheesh Kumar
    Description    : This method is used for creating task for inbound email
    Return Type    : Task
    Parameter      : String whatId, String contactId, String inboundEmailDocId, String ownerId, String subject
    *********************************************************************************/
    private static Task createTaskForInboundEmail(String whatId, String contactId, String inboundEmailDocId, String ownerId, String subject) {
        Task task = new Task();
        task.WhatId = whatId;
        task.WhoId = (String.isNotBlank(contactId) ? contactId : null);
        task.RecordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.PC_TASK, PC_Constants.PC_ELETTER);
        task.PC_Document__c = (String.isNotBlank(inboundEmailDocId) ? inboundEmailDocId : null);
        task.PC_Direction__c = PC_Constants.INBOUND;
        task.PC_Channel__c = PC_Constants.PC_TASK_CHANNEL_EMAIL;
        task.Description = subject;
        task.Subject = subject;
        task.ActivityDate = system.today();
        task.Status = PC_Constants.PC_STATUS_NOT_STARTED;
        task.PC_ActionComponent__c = PC_Constants.PC_TASK_ACTION_COMPONENT_ELETTER;
        task.OwnerId = (String.isNotBlank(ownerId) ? ownerId : UserInfo.getUserId());
        PC_Database.ins(task);
        return task;
    }

    /*********************************************************************************
    Method Name    : createEmailMessageForInboundEmail
    Author         : Satheesh Kumar
    Description    : This method is used for creating email message for inbound email
    Return Type    : void
    Parameter      : String recordId, String contactId, String ownerId, Messaging.InboundEmail email
    *********************************************************************************/
    private static void createEmailMessageForInboundEmail(String recordId, String contactId, String ownerId, Messaging.InboundEmail email) {
        // Create Task for Email Message
        /*Task emailTask = new Task();
        emailTask.WhatId = recordId;
        emailTask.WhoId = (String.isNotBlank(contactId) ? contactId : null);
        emailTask.RecordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.PC_TASK, PC_Constants.PC_ELETTER);
        emailTask.Description = email.plainTextBody;
        emailTask.Subject = email.subject;
        emailTask.ActivityDate = system.today();
        emailTask.TaskSubtype = 'Email';
        emailTask.Priority = PC_Constants.PC_PRIORITY_NORMAL;
        emailTask.Status = PC_Constants.COMPLETED;
        emailTask.OwnerId = (String.isNotBlank(ownerId) ? ownerId : UserInfo.getUserId());
        PC_Database.ins(emailTask);

        //Email Message for inbound email
        EmailMessage newEmail = new EmailMessage(FromAddress = email.fromAddress,
                FromName = email.fromName,
                ToAddress = email.toAddresses[0],
                Subject = email.subject,
                TextBody = email.plainTextBody,
                HtmlBody = email.htmlBody,
                RelatedToId = recordId,
                status = '2',
                Incoming = PC_Constants.TRUE_BOOLEAN,
                ParentId = (Id.valueOf(recordId).getSobjectType() == Case.sObjectType)? recordId : null,
                ActivityId = (emailTask.Id != null) ? emailTask.Id : null);
        PC_Database.ins(newEmail);*/
    }

    /*********************************************************************************
    Method Name    : extractRefId
    Author         : Satheesh Kumar
    Description    : This method is used to extract ThreadId from subject and returns List of Id's
                     Format of thread Id is [ ref:5002E0000XXXXXXXXX.a1H2E00000XXXXX:ref ]
    Return Type    : List<String>  Id's of outbound email document and the id where the eletter was triggered
    Parameter      : String subject
    *********************************************************************************/
    private static List<String> extractThreadId(String subject) {
        /*
        * This method accepts input string like 'sample text [ ref:5002E0000XXXXXXXXX.a1H2E00000XXXXX:ref ]'
        * and return List of 2Id's from the string ['5002E0000XXXXXXXXX', 'a1H2E00000XXXXX']
        */
        List<String> refIds = new List<String>();
        // pattern.compile compiles the regular expression into a Pattern object.
        pattern myPattern = pattern.compile('(?s).*\\[ ref:(.*)\\.(.*):ref \\].*');

        if(String.isNotBlank(subject)) {
            // Creating a Matcher object that matches the input string 'subject' against above Pattern object.
            matcher myMatcher = myPattern.matcher(subject);
            system.debug('ThreadId Matches myMatcher.matches()--->'+myMatcher.matches());
            // matches() method returns true if the specified string matches the regular expression, false otherwise.
            if (myMatcher.matches()) {
                if (myMatcher.groupCount() == 2) {
                    refIds.add(myMatcher.group(1));
                    refIds.add(myMatcher.group(2));
                }
                return refIds;
            }
        }
        return null;
    }

    /*********************************************************************************
    Method Name    : getThreadIdFromEmail
    Author         : Satheesh Kumar
    Description    : This method check threadId in email subject & body and returns List of Id's
    Return Type    : List<String>  Id's of outbound email document and the id where the eletter was triggered
    Parameter      : Messaging.InboundEmail email
    *********************************************************************************/
    private static List<String> getThreadIdFromEmail(Messaging.InboundEmail email) {
        List<String> refIds = new List<String>();
        // extract threadId from subject
        refIds = extractThreadId(email.subject);
        if (refIds == null || refIds.isEmpty()) {
            system.debug('plainTextBody-->' + email.plainTextBody);
            refIds = extractThreadId(email.plainTextBody);
        }
        return refIds;
    }

    /**
    * This method checks the email address with the care team member email address (only account type member)
    * if matches then returns contactId of the care team member.
    * @param caseId       caseId
    * @param fromAddress  emailAddress
    * @return String    returns the contactId
    */
    private static String getContactIdByEmailAddress(String caseId, String fromAddress) {
        String contactId;

        //FLS check for Case
        List<String> caseFields = new List<String>{'Id', 'Account'};
        PC_Database.assertAccess(PC_Constants.PC_CASE, PC_Database.Operation.Reading, caseFields);
        //FLS check for Account
        List<String> accountFields = new List<String>{'Id', 'HealthCloudGA__PrimaryContact__c'};
        PC_Database.assertAccess(PC_Constants.PC_ACCOUNT, PC_Database.Operation.Reading, accountFields);
        //FLS check for contact
        List<String> contactFields = new List<String>{'Id', 'Email'};
        PC_Database.assertAccess(PC_Constants.CONTACT, PC_Database.Operation.Reading, contactFields);
        //FLS check for Association
        List<String> assocFields= new List<String>{'Id',PC_Constants.getQualifiedAPIName('PC_Account__c'),PC_Constants.getQualifiedAPIName('PC_Program__c'), PC_Constants.getQualifiedAPIName('PC_AssociationStatus__c')};
        PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Association__c'), PC_Database.Operation.Reading, assocFields);

        contactId = [SELECT Id, Account.HealthCloudGA__PrimaryContact__c, Account.HealthCloudGA__PrimaryContact__r.Email FROM Case WHERE Id =:caseId and Account.HealthCloudGA__PrimaryContact__r.Email =: fromAddress] ?.Account.HealthCloudGA__PrimaryContact__c;
        if(String.isBlank(contactId)){
            contactId = [SELECT Id, PC_Account__c, PC_Account__r.HealthCloudGA__PrimaryContact__c, PC_Account__r.HealthCloudGA__PrimaryContact__r.Email FROM PC_Association__c WHERE PC_Program__c = :caseId AND PC_Account__c != null AND PC_Account__r.HealthCloudGA__PrimaryContact__r.Email = :fromAddress AND PC_AssociationStatus__c = :PC_Constants.ACTIVE LIMIT 1] ?.PC_Account__r.HealthCloudGA__PrimaryContact__c;
        }
        return contactId;
    }
}