/*********************************************************************************
  Class Name      : PC_eLetterEmailTemplateSender3
  Description     :
  Created By      : Satheesh Kumar
  Created Date    : Nov 12, 2020
  Modification Log:
  ----------------------------------------------------------------------------------
  Developer                   Date                   Description
  -----------------------------------------------------------------------------------
  Satheesh Kumar           Nov 18, 2020              Initial Version
  Satheesh Kumar           Dec 15, 2020              Added isValidEmail check before setting toAddresses
  Vijay Kashikar           21-Jan-2021               [PC-7102] Added sharing clause
  *********************************************************************************/

public with sharing class PC_eLetterEmailTemplateSender3 implements PC_eLetter.Sender3 {
    static String sentEmailCopy = System.Label.PC_Sent_Email_Copy;
    static STRING currentUserType;
    static STRING PC_AutomatedTaskEmail;
    static ID OrgWideEmailAddressId;
    static String PC_ContentType = 'application/pdf' ;
    static Id EMAIL_ATTACHMENT_RECORD_TYPE = PC_SYSTEM.recordTypeId(PC_Constants.DOCUMENT_OBJECT, 'PC_Email_Attachment');
    static String emailTemplateId;

    public PC_eLetter.SenderResponse sendLetter(PC_eLetter.SenderRequest senderRequest) {
        PC_eLetter.SenderResponse response = new PC_eLetter.SenderResponse();
        Boolean sendToCurrentUser;
        String emailTemplateName;
        try {
            if (String.isNotBlank(senderRequest.eLetterId)) {
                PC_eLetter__c eLetter  = PC_eLetterService.getELetter(senderRequest.eLetterId);
                sendToCurrentUser = eLetter.PC_Send_to_User__c;
                emailTemplateName = eLetter.PC_Template_Name__c;
                /*
                * FLS Check for EmailTemplate
                */
                List<String> fields = new List<String>{'DeveloperName'};
                PC_Database.assertAccess(PC_Constants.PC_EMAIL_TEMPLATE,PC_Database.Operation.Reading, fields);
                List<EmailTemplate> emailTemplate = [SELECT Id FROM EmailTemplate WHERE DeveloperName =: emailTemplateName];
                if(emailTemplate.size() > 0){
                    emailTemplateId = emailTemplate[0].Id;
                }
            } else {
                sendToCurrentUser = false;
                emailTemplateId = PC_Constants.EMPTY_STRING;
            }
            currentUserType = UserInfo.getUserType();
            String threadIdSettingValue = PC_SYSTEM.getPatientConnectSetting(PC_Constants.PC_ELETTER_INSERT_THREAD_ID_IN_SUBJECT, PC_Constants.INACTIVE);
            Boolean isThreadIdSettingActive = threadIdSettingValue.equalsIgnoreCase(PC_Constants.INACTIVE) ? PC_Constants.FALSE_BOOLEAN : PC_Constants.TRUE_BOOLEAN;
            Boolean insertThreadIdInSubject = Boolean.valueOf(PC_SYSTEM.getPatientConnectSetting(PC_Constants.PC_ELETTER_INSERT_THREAD_ID_IN_SUBJECT, PC_Constants.TRUE_STRING));
            PC_AutomatedTaskEmail = PC_SYSTEM.getPatientConnectSetting(PC_Constants.PC_AUTOMATED_TASK_EMAIL, '');
            if (currentUserType == PC_Constants.PC_AUTOMATED_PROCESS_USERTYPE) {
                if (String.isBlank(PC_AutomatedTaskEmail)) {
                    throw new PC_eLetter.SenderException(System.Label.PC_NoOrgWideAddressConfigured);
                } else {
                    OrgWideEmailAddress o = [SELECT ID FROM OrgWideEmailAddress WHERE Address = :PC_AutomatedTaskEmail];
                    OrgWideEmailAddressId = o.Id;
                }
            } else if (String.isNotBlank(senderRequest.outgoingEmail.fromAddress.fromId)) {
                String fromId = senderRequest.outgoingEmail.fromAddress.fromId;
                String fromIdObjectType = String.valueOf(Id.valueOf(fromId).getSobjectType());
                if (fromIdObjectType != PC_Constants.PC_USER) {
                    OrgWideEmailAddressId = fromId;
                }
            }

            createEmailOutboundRecords(senderRequest);
            createDocumentLinkLog(senderRequest);

            List<Messaging.SingleEmailMessage> listEmailsToSend = new List<Messaging.SingleEmailMessage>();
            List<PC_eLetter.DocumentRecipient> documentRecipientList = senderRequest.documentRecipientList;
            for (PC_eLetter.DocumentRecipient documentRecipient : documentRecipientList) {
                List<String> toAddresses = new List<String>();
                Messaging.SingleEmailMessage aEmail = new Messaging.SingleEmailMessage();
                // Get Preview

                PC_eLetterPreviewController.PreviewRequest previewRequest = new PC_eLetterPreviewController.PreviewRequest();
                Messaging.SingleEmailMessage singleEmailMessage = new Messaging.SingleEmailMessage();
                if(String.isNotBlank(emailTemplateId)) {
                    previewRequest.whatId = String.valueOf(senderRequest.relatedToId);
                    previewRequest.whoId = documentRecipient.recipient.Id;
                    previewRequest.templateId = emailTemplateId;
                    singleEmailMessage = PC_eLetterService.geteLetterPreview(previewRequest);
                } else {
                    singleEmailMessage.setPlainTextBody(senderRequest.outgoingEmail.textBody);
                    singleEmailMessage.setHtmlBody(senderRequest.outgoingEmail.htmlBody);
                }

                // replyTo
                if (String.isNotBlank(senderRequest.outgoingEmail.replyTo)) {
                    aEmail.setReplyTo(senderRequest.outgoingEmail.replyTo);
                }

                // fromAddress
                if (String.isNotBlank(String.valueOf(OrgWideEmailAddressId))) {
                    aEmail.setOrgWideEmailAddressId(OrgWideEmailAddressId);
                }

                // setSaveAsActivity and setWhatId
                if (documentRecipient.recipient.type == PC_eLetter.RecipientType.USER.name()) {
                    aEmail.setSaveAsActivity(false);
                }else if(documentRecipient.recipient.type == PC_eLetter.RecipientType.CONTACT.name()){
                    aEmail.setWhatId(senderRequest.relatedToId);
                }

                // setTargetObjectId, setToAddress
                if (documentRecipient.recipient.Id != null) {
                    aEmail.setTargetObjectId(documentRecipient.recipient.Id);
                } else if (!sendToCurrentUser) {
                    if (PC_Utility.isValidEmail(documentRecipient.recipient.email)) {
                        toAddresses.add(documentRecipient.recipient.email);
                        aEmail.setToAddresses(toAddresses);
                    } else {
                        throw new PC_eLetter.SenderException(System.Label.PC_Eletter2_InvalidRecipientEmail);
                    }
                }

                // SendToCurrentUser
                if (sendToCurrentUser) {
                    aEmail.setTreatTargetObjectAsRecipient(PC_Constants.FALSE_BOOLEAN);
                    toAddresses.add(UserInfo.getUserEmail());
                    aEmail.setToAddresses(toAddresses);
                    aEmail.setSaveAsActivity(false);
                }

                // Adding ThreadId
                String threadId = PC_Utility.getThreadId(new List<String>{senderRequest.relatedToId, documentRecipient.document.Id});

                // Adding [Secure] tag to Subject
                String secureTag = (senderRequest.isSecureEmail != null && senderRequest.isSecureEmail) ? ' ' + System.Label.PC_EmailSecureTag + ' ' : ' ';
                if (String.isNotBlank(senderRequest.outgoingEmail.subject)) {
                    aEmail.setSubject(senderRequest.outgoingEmail.subject + secureTag + ((insertThreadIdInSubject && isThreadIdSettingActive) ? threadId : ''));
                } else {
                    aEmail.setSubject(singleEmailMessage.getSubject() + secureTag + ((insertThreadIdInSubject && isThreadIdSettingActive) ? threadId : ''));
                }

                // Adding Attachments to email
                aEmail.setEntityAttachments(senderRequest.outgoingEmail.attachmentIds);

                // Set TextBody
                aEmail.setPlainTextBody(singleEmailMessage.getPlainTextBody() + ((!insertThreadIdInSubject && isThreadIdSettingActive) ? '\n' + threadId : ''));

                // Set HtmlBody
                if (String.isNotBlank(singleEmailMessage.getHtmlBody())) {
                    aEmail.setHtmlBody((!insertThreadIdInSubject && isThreadIdSettingActive) ? singleEmailMessage.getHtmlBody()+ '<br>' + threadId : singleEmailMessage.getHtmlBody());
                }
                listEmailsToSend.add(aEmail);
            }
            Messaging.SendEmailResult[] emailResults = Messaging.sendEmail(listEmailsToSend);
            if (emailResults[0].success) {
                response.isSuccess = emailResults[0].success;
            } else {
                response.isSuccess = emailResults[0].success;
                response.errorMessage = emailResults[0].errors[0].message;
            }
        } catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return response;
    }

    /**
    * Creates Document Link Log with case for all outbound documents
    *
    * @param request  Eletter SenderRequest Object
    * @return void
    */
    public void createDocumentLinkLog(PC_eLetter.SenderRequest senderRequest){
        List<PC_Document_Log__c> pcDocumentLogs = new List<PC_Document_Log__c>();
        String objType = String.valueOf(Id.valueOf(senderRequest.relatedToId).getSobjectType());
        Map<String, Schema.SObjectType> sObjectMap = Schema.getGlobalDescribe();
        String objLabel = PC_Constants.EMPTY_STRING;
        Case caseObj;
        if (objType == PC_Constants.PC_CASE) {
            objLabel = sObjectMap.get(PC_Constants.PC_CASE).getDescribe().getLabel();
            //FLS check for case
            List<String> caseFields = new List<String>{'Id', 'AccountId', 'Type', 'CaseNumber'};
            PC_Database.assertAccess(PC_Constants.PC_CASE, PC_Database.Operation.Reading, caseFields);
            caseObj = [SELECT Id, AccountId, Type, CaseNumber FROM Case WHERE Id = :senderRequest.relatedToId];
        }

        //create document link log for all outbound PC_Documents with case
        for (PC_eLetter.DocumentRecipient documentRecipient : senderRequest.documentRecipientList) {
            PC_Document_Log__c pcDocumentLog = new PC_Document_Log__c();
            if (objType == PC_Constants.PC_CASE && caseObj != null) {
                pcDocumentLog = new PC_Document_Log__c();
                pcDocumentLog.PC_Document__c = documentRecipient.document.Id;
                pcDocumentLog.PC_Program__c = senderRequest.relatedToId;
                pcDocumentLog.PC_Association_Record_ID__c = senderRequest.relatedToId;
                pcDocumentLog.PC_Association_Record_Name__c = ((caseObj.CaseNumber != null) ? caseObj.CaseNumber : null);
                pcDocumentLog.PC_Association_Type__c = ((caseObj.Type != null) ? (String.isNotBlank(objLabel) ? (objLabel + ': ' + caseObj.Type) : caseObj.Type) : null);
                pcDocumentLogs.add(pcDocumentLog);
            }
        }
        if(pcDocumentLogs != null && !pcDocumentLogs.isEmpty()) {
            PC_Database.ins(pcDocumentLogs);
        }
    }

    /**
    * Creates Email Outbound attachments and attached to Outbound PC Document
    *
    * @param request  Eletter SenderRequest Object
    * @return void
    */
    public void createEmailOutboundRecords(PC_eLetter.SenderRequest request){
        List<String> attachmentIds = request.outgoingEmail.attachmentIds;
        List<PC_eLetter.DocumentRecipient> documentRecipients = request.documentRecipientList;
        Boolean useSalesforceFiles = PC_SYSTEM.useSalesforceFiles();

        String threadIdSettingValue = PC_SYSTEM.getPatientConnectSetting(PC_Constants.PC_ELETTER_INSERT_THREAD_ID_IN_SUBJECT, PC_Constants.INACTIVE);
        Boolean isThreadIdSettingActive = threadIdSettingValue.equalsIgnoreCase(PC_Constants.INACTIVE) ? PC_Constants.FALSE_BOOLEAN : PC_Constants.TRUE_BOOLEAN;
        Boolean insertThreadIdInSubject = Boolean.valueOf(PC_SYSTEM.getPatientConnectSetting(PC_Constants.PC_ELETTER_INSERT_THREAD_ID_IN_SUBJECT, PC_Constants.TRUE_STRING));

        ContentVersion contentVersion;
        Attachment attach;
        List<Attachment> attachmentList = new List<Attachment>();
        List<ContentVersion> contentVersionList = new List<ContentVersion>();
        List<ContentDocumentLink> contentDocumentLinkList = new List<ContentDocumentLink>();
        Map<Id, ContentVersion> fileToDocMap = new Map<Id, ContentVersion>();
        String whatId, whoId, body;
        String threadId;

        for (PC_eLetter.DocumentRecipient documentRecipient : documentRecipients) {
            // ThreadId
            threadId = PC_Utility.getThreadId(new List<String>{ request.relatedToId, documentRecipient.document.Id });

            PC_eLetterPreviewController.PreviewRequest previewRequest = new PC_eLetterPreviewController.PreviewRequest();
            Messaging.SingleEmailMessage singleEmailMessage = new Messaging.SingleEmailMessage();
            system.debug('emailTemplateId--->'+emailTemplateId);
            if (String.isNotBlank(emailTemplateId)) {
                previewRequest.whatId = String.valueOf(request.relatedToId);
                previewRequest.whoId = documentRecipient.recipient.Id;
                previewRequest.templateId = emailTemplateId;
                singleEmailMessage = PC_eLetterService.geteLetterPreview(previewRequest);
            } else {
                singleEmailMessage.setPlainTextBody(request.outgoingEmail.textBody);
            }
            String pdfBody = singleEmailMessage.getPlainTextBody() + ((!insertThreadIdInSubject && isThreadIdSettingActive) ? '\n' + threadId : '');
            system.debug('pdfBody--'+pdfBody);
            // Enclose the emailBody with <pre> tag to get pre formatted text in PDF document
            pdfBody = PC_Utility.encloseStringWithPreTag(new List<String>{ pdfBody });
            blob blobBody = blob.toPDF(pdfBody);

            if (useSalesforceFiles) {
                contentVersion = new ContentVersion();
                contentVersion.title = sentEmailCopy + PC_Constants.PDF_FORMAT;
                contentVersion.PathOnClient = sentEmailCopy + PC_Constants.PDF_FORMAT;
                contentVersion.VersionData = blobBody;
                contentVersion.SharingOption = PC_Constants.FILE_SHARING_OPTION_ALLOWED;
                contentVersionList.add(contentVersion);
                fileToDocMap.put(documentRecipient.document.Id, contentVersion);

            } else {
                attach = new Attachment();
                attach.Body = blobBody;
                attach.Name = sentEmailCopy + PC_Constants.PDF_FORMAT;
                attach.ContentType = PC_ContentType;
                attach.IsPrivate = false;
                attach.ParentId = documentRecipient.document.Id;
                attachmentList.add(attach);
            }
        }

        if (useSalesforceFiles) {
            PC_Database.ins(contentVersionList);
            Set<Id> contentVerIds = new Set<Id>();
            for (ContentVersion cv : contentVersionList) {
                contentVerIds.add(cv.Id);
            }

            List<ContentVersion> newCVList = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN:contentVerIds];
            ContentDocumentLink cdl;
            for (Id docId : fileToDocMap.keySet()) {
                for (ContentVersion cv : newCVList) {
                    if (cv.Id == fileToDocMap.get(docId).Id) {
                        cdl = new ContentDocumentLink();
                        cdl.ContentDocumentId = cv.ContentDocumentId;
                        cdl.LinkedEntityId = docId;
                        cdl.ShareType = PC_Constants.FILE_SHARE_TYPE_VIEWER;
                        contentDocumentLinkList.add(cdl);
                    }
                }
            }
            PC_Database.ins(contentDocumentLinkList);
        } else {
            PC_Database.ins(attachmentList);
        }

        // create Email Attachment Document if email has any attachments attached
        if (attachmentIds != null && !attachmentIds.isEmpty()) {
            createMailAttachmentDocument(attachmentIds, documentRecipients, useSalesforceFiles, request);
        }
    }

    /**
    * Creating new PC Document(email attachment type) for all attachment which we send in outbound email and link it with the Parent Outbound email type Document
    * [PC-6352] - View all attachments in outbound email type document
    *
    * @param attachmentIds      ids of all attachments as List<String>
    * @param documentRecipients List of DocumentWrapper (associating recipients and outbound documents)
    * @param useSalesforceFiles
    * @return void
    */
    public void createMailAttachmentDocument(List<String> attachmentIds, List<PC_eLetter.DocumentRecipient> documentRecipients, Boolean useSalesforceFiles, PC_eLetter.SenderRequest request) {
        List<PC_Document__c> pcDocuments = new List<PC_Document__c>();

        ContentVersion cVersion;
        Attachment attach;
        List<ContentVersion> contentVersionList = new List<ContentVersion>();
        List<Attachment> attachmentList = new List<Attachment>();
        List<ContentDocumentLink> contentDocumentLinkList = new List<ContentDocumentLink>();
        List<DocumentFileWrapper> docFileList = new List<DocumentFileWrapper>();
        Map<Id, String> contentVersionPCDocument = new Map<Id, String>();
        Map<Id, String> attachmentDocumentMap = new Map<Id, String>();
        Map<Id, String> contentDocumentContentVersion = new Map<Id, String>();

        List<MailAttachment> mailAttachments = getAttachedDocuments(attachmentIds);
        system.debug('mailAttachments---' + mailAttachments);
        try {
            for (PC_eLetter.DocumentRecipient docWrapper : documentRecipients) {
                for (MailAttachment mailAttachment : mailAttachments) {
                    PC_Document__c doc = new PC_Document__c(
                            RecordTypeId = EMAIL_ATTACHMENT_RECORD_TYPE,
                            PC_Document_Status__c = PC_Constants.PC_NEW,
                            PC_Parent_Document__c = docWrapper.document.Id,
                            PC_Engagement_Program__c = docWrapper.document.PC_Engagement_Program__c,
                            PC_Description__c = mailAttachment.fileName,
                            PC_From_Name__c = request.outgoingEmail.fromAddress.name,
                            PC_From_Email_Address__c = request.outgoingEmail.fromAddress.address,
                            PC_To_Email_Address__c = PC_Utility.isValidEmail(docWrapper.recipient.email) ? docWrapper.recipient.email : PC_Constants.EMPTY_STRING
                    );
                    pcDocuments.add(doc);

                    if (useSalesforceFiles) {
                        cVersion = new ContentVersion();
                        cVersion.title = mailAttachment.fileName;
                        cVersion.PathOnClient = mailAttachment.fileName;
                        cVersion.VersionData = mailAttachment.body;
                        cVersion.SharingOption = PC_Constants.FILE_SHARING_OPTION_ALLOWED;
                        contentVersionList.add(cVersion);
                        docFileList.add(new DocumentFileWrapper(doc, cVersion));
                    } else {
                        attach = new Attachment();
                        attach.Name = mailAttachment.fileName;
                        attach.Body = mailAttachment.body;
                        attach.IsPrivate = false;
                        docFileList.add(new DocumentFileWrapper(doc, attach));
                    }
                }
            }

            PC_Database.ins(pcDocuments);

            if (useSalesforceFiles) {
                PC_Database.ins(contentVersionList);
                for (DocumentFileWrapper docFileWrapper : docFileList) {
                    contentVersionPCDocument.put(docFileWrapper.contentVersion.Id, docFileWrapper.pcDocument.Id);
                }

                Set<Id> contentVersionIds = new Set<Id>();
                for (ContentVersion cv : contentVersionList) {
                    contentVersionIds.add(cv.Id);
                }

                for (ContentVersion cv : [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN:contentVersionIds]) {
                    contentDocumentContentVersion.put(cv.Id, cv.ContentDocumentId);
                }

                ContentDocumentLink cdl;
                for (Id contentVersionId : contentDocumentContentVersion.keySet()) {
                    cdl = new ContentDocumentLink();
                    cdl.ContentDocumentId = contentDocumentContentVersion.get(contentVersionId);
                    cdl.LinkedEntityId = contentVersionPCDocument.get(contentVersionId);
                    cdl.ShareType = PC_Constants.FILE_SHARE_TYPE_VIEWER;
                    contentDocumentLinkList.add(cdl);
                }
                system.debug('contentDocumentLinkList---' + contentDocumentLinkList);
                PC_Database.ins(contentDocumentLinkList);
            } else {
                for (DocumentFileWrapper docWrapper : docFileList) {
                    docWrapper.attachment.ParentId = docWrapper.pcDocument.Id;
                    attachmentList.add(docWrapper.attachment);
                }
                system.debug('attachmentList---' + attachmentList);
                PC_Database.ins(attachmentList);
            }
        } catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
    }


    /**
    * This method returns list of MailAttachment for all attachmentIds
    *
    * @param attachmentIds ids of all attachments as List<String>
    * @return List<MailAttachment>
    */
    public List<MailAttachment> getAttachedDocuments(List<String> attachmentIds) {
        List<MailAttachment> mailAttachments = new List<MailAttachment>();
        MailAttachment mailAttachment = new MailAttachment();

        //FLS Check
        List<String> docFields = new List<String>{'Id', 'Name', 'Body', 'Type', 'ContentType'};
        PC_Database.assertAccess('document', PC_Database.Operation.Reading, docFields);

        List<String> attachmentFields = new List<String>{'Name', 'Body', 'ContentType'};
        PC_Database.assertAccess('Attachment', PC_Database.Operation.Reading, attachmentFields);

        List<String> contentVersionFields = new List<String>{'Id', 'Title', 'VersionData', 'FileExtension', 'FileType', 'PathOnClient'};
        PC_Database.assertAccess('ContentVersion', PC_Database.Operation.Reading, contentVersionFields);

        for (Document document : [SELECT Id, Name, Body, Type, ContentType FROM document WHERE Id IN:attachmentIds]) {
            document.Name = (!(document.Name).contains('.') && String.isNotBlank(document.Type)) ? document.Name + '.' + document.Type : document.Name;
            mailAttachment = new MailAttachment(document);
            mailAttachments.add(mailAttachment);
        }
        for (Attachment attach : [SELECT Id, Name, Body, ContentType FROM Attachment WHERE Id IN:attachmentIds]) {
            mailAttachment = new MailAttachment(attach);
            mailAttachments.add(mailAttachment);
        }
        for (ContentVersion contentVersion : [SELECT Id, Title, VersionData, FileExtension, FileType, PathOnClient FROM ContentVersion WHERE Id IN:attachmentIds]) {
            mailAttachment = new MailAttachment(contentVersion);
            mailAttachments.add(mailAttachment);
        }
        return mailAttachments;
    }

    /**
    * DocumentFileWrapper is a wrapper object for associating an PC_Document__c with the outbound attachment(It can be files or attachment)
    */
    public inherited sharing class DocumentFileWrapper {
        public PC_Document__c pcDocument;
        public ContentVersion contentVersion;
        public Attachment attachment;

        public DocumentFileWrapper() {
            pcDocument = new PC_Document__c();
            contentVersion = new ContentVersion();
            attachment = new Attachment();
        }

        public DocumentFileWrapper(PC_Document__c doc, ContentVersion cVersion) {
            pcDocument = doc;
            contentVersion = cVersion;
        }

        public DocumentFileWrapper(PC_Document__c doc, Attachment attach) {
            pcDocument = doc;
            attachment = attach;
        }
    }

    /**
    * Wrapper for email attachment(document, files and attachments)
    */
    public inherited sharing class MailAttachment {
        public String fileName;
        public String type;
        public String contentType;
        public blob body;

        public MailAttachment() {
        }

        public MailAttachment(Document doc) {
            fileName = doc.Name;
            body = doc.Body;
            type = doc.Type;
            contentType = doc.ContentType;
        }

        public MailAttachment(Attachment att) {
            fileName = att.Name;
            body = att.Body;
            type = ((att.Name != null) ? (att.Name).substringAfterLast('.') : att.ContentType);
            contentType = att.ContentType;
        }

        public MailAttachment(ContentVersion conVer) {
            fileName = (conVer.PathOnClient != null) ? conVer.PathOnClient : conVer.Title;
            body = conVer.VersionData;
            type = conVer.FileExtension;
            contentType = conVer.FileType;
        }
    }
}