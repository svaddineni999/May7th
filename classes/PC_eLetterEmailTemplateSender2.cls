/*********************************************************************************
  Class Name      : PC_eLetterEmailTemplateSender
  Description     :
  Created By      : Ajinkya Deshmukh
  Created Date    : March 10, 2016
  Modification Log:
  ----------------------------------------------------------------------------------
  Developer                   Date                   Description
  -----------------------------------------------------------------------------------
  Ajinkya Deshmukh          March 10, 2017              Initial Version
  Ajinkya Deshmukh			June 8, 2017				FLS Check Added for EmailTemplate
  Mayuresh Patil            June 30, 2017               PC-1862 Updated contenttype for the pdf document created
  Mayuresh Patil            July 26, 2017               Updated CRUD/FLS Checks
  Tejas Patel			    Nov 08, 2017				Created new Variable and custom label "sentEmailCopy"
  Tejas Patel               Mar 08, 2019                [PC-4570] updated the for loop to run on the list of contacts.
  Haritha Reddy             Jun 27, 2019                [PC-4946] Updated Logic to insert File or Attachment based on  PC_UseSalesforceFiles Setting
  Shishir Bansal            11-Dec-2019                 [PC-5792] Avoid hardcoding of string variable
  Satheesh Kumar            08-July-2020                [PC-6352] & [PC-6354] Added logic to create email attachment document and link it with outbound email document / link outbound document to trigger record
  Satheesh Kumar            16-July-2020                [PC-6551] Added logic for insert threadId in email subject/email body
  Satheesh Kumar            06-Aug-2020                 [PC-6642] Fix for Outbound Email Document(PDF) formatting
  Satheesh Kumar            15-Oct-2020                 [PC-6635] Added logic to send email to logged-in user when sendToCurrentUser is true
  Satheesh Kumar            16-Oct-2020                 [PC-6743] Fix for visual force e-letter templates when there is no HtmlBody given in template
  Hitha Avalakki            02-Dec-2020                 [PC-6751] Forcereviewer scan issues: Made changes to getAttachedDocuments() in order remove SOQL from inside for loop
  Satheesh Kumar            04-Jan-2021                 [PC-7159] Fix for invalid email address issue when accounts having multiple contacts.
  Haritha Reddy             21-Jan-2021                 [PC-7102] Force Reviewer scan issue fix. Updated Sharing declaration.
  *********************************************************************************/
public with sharing class PC_eLetterEmailTemplateSender2 implements PC_eLetter.Sender2 {
    static String sentEmailCopy = System.Label.PC_Sent_Email_Copy;
    static Id OUTBOUND_EMAIL_RECORD_TYPE = PC_SYSTEM.recordTypeId(PC_Constants.DOCUMENT_OBJECT, 'PC_Email_Outbound');
    static Id EMAIL_ATTACHMENT_RECORD_TYPE = PC_SYSTEM.recordTypeId(PC_Constants.DOCUMENT_OBJECT, 'PC_Email_Attachment');
    static STRING currentUserType;
    static STRING PC_AutomatedTaskEmail;
    static ID OrgWideEmailAddressId;
    private static final String PC_ContentType = 'application/pdf' ;

    public void sendLetter(Id objectId, List<PC_eLetter.DocumentWrapper> documentRecipients, PC_eLetter__c eLetter, Boolean sendToCurrentUser, Boolean isEmailSecure, PC_eLetter.EmailContent emailContent) {
        try {
            String subject = emailContent.subject;
            List<String> attachmentIds = emailContent.attachmentIds;
            if(eLetter == null){
                throw new PC_eLetter.SenderException(System.Label.PC_Eletter2_EletterTemplateMissingError);
            }
            String templateName     = eLetter.PC_Template_Name__c;
            currentUserType           = UserInfo.getUserType();
            Boolean useSalesforceFiles = PC_SYSTEM.useSalesforceFiles();
            String threadIdSettingValue = PC_SYSTEM.getPatientConnectSetting(PC_Constants.PC_ELETTER_INSERT_THREAD_ID_IN_SUBJECT, PC_Constants.INACTIVE);
            Boolean isThreadIdSettingActive = threadIdSettingValue.equalsIgnoreCase(PC_Constants.INACTIVE) ? PC_Constants.FALSE_BOOLEAN : PC_Constants.TRUE_BOOLEAN;
            Boolean insertThreadIdInSubject = Boolean.valueOf(PC_SYSTEM.getPatientConnectSetting(PC_Constants.PC_ELETTER_INSERT_THREAD_ID_IN_SUBJECT, PC_Constants.TRUE_STRING));
            PC_AutomatedTaskEmail  = PC_SYSTEM.getPatientConnectSetting(PC_Constants.PC_AUTOMATED_TASK_EMAIL,'');
            if(currentUserType == PC_Constants.PC_AUTOMATED_PROCESS_USERTYPE){
                if(String.isBlank(PC_AutomatedTaskEmail)){
                    throw new PC_eLetter.SenderException(System.Label.PC_NoOrgWideAddressConfigured);
                }else{
                    OrgWideEmailAddress o = [SELECT ID FROM OrgWideEmailAddress WHERE Address =: PC_AutomatedTaskEmail];
                    OrgWideEmailAddressId = o.Id;
                }
            }
            /*
	        * FLS Check for EmailTemplate
	        */
            List<String> fields = new List<String>{'Body', 'DeveloperName', 'TemplateType'};
            PC_Database.assertAccess(PC_Constants.PC_EMAIL_TEMPLATE,PC_Database.Operation.Reading, fields);

            List<EmailTemplate> emailTemplate = [SELECT Id, Body, TemplateType  FROM EmailTemplate WHERE DeveloperName =: templateName];
            String templateId = emailTemplate[0].Id;
            String templateType = emailTemplate[0].TemplateType;
            List<Messaging.SingleEmailMessage> listEmailsToSend = new List<Messaging.SingleEmailMessage>();
            List<Attachment> attachmentList = new List<Attachment>();

            List<PC_eLetter.RecipientWrapper> recipients = new List<PC_eLetter.RecipientWrapper>();
            Map<Id, PC_eLetter.DocumentWrapper> accountIdToDocumentWrapper = new Map<Id, PC_eLetter.DocumentWrapper>();
            Set<Id> accIds  = new Set<Id>();

            List<PC_Document_Log__c> pcDocumentLogs = new List<PC_Document_Log__c>();
            PC_Document_Log__c pcDocumentLog;
            String objType = String.valueOf(objectId.getSobjectType());
            Map<String, Schema.SObjectType> sObjectMap = Schema.getGlobalDescribe();
            String objLabel = PC_Constants.EMPTY_STRING;
            system.debug('objLabel---->'+objLabel);
            Case caseObj;
            if (objType == PC_Constants.PC_CASE) {
                objLabel = sObjectMap.get(PC_Constants.PC_CASE).getDescribe().getLabel();
                //FLS check for case
                List<String> caseFields = new List<String>{'Id', 'AccountId', 'Type', 'CaseNumber'};
                PC_Database.assertAccess(PC_Constants.PC_CASE, PC_Database.Operation.Reading, caseFields);
                caseObj = [SELECT Id, AccountId, Type, CaseNumber FROM Case WHERE Id = :objectId];
            }

            for(PC_eLetter.DocumentWrapper docWrapper : documentRecipients){
                accountIdToDocumentWrapper.put(docWrapper.recipient2.Id, docWrapper);
                if(docWrapper.recipient2.type == PC_eLetter.RecipientType.ACCOUNT.name()){
                    accIds.add(docWrapper.recipient2.Id);
                }else if(docWrapper.recipient2.type == PC_eLetter.RecipientType.USER.name()){
                    recipients.add(docWrapper.recipient2);
                }else if(docWrapper.recipient2.type == PC_eLetter.RecipientType.PRE_CONFIGURED_EMAIL.name()){
                    recipients.add(docWrapper.recipient2);
                }

                //create document link log for all outbound PC_Documents with case
                if(objType == PC_Constants.PC_CASE && caseObj != null){
                    pcDocumentLog = new PC_Document_Log__c();
                    pcDocumentLog.PC_Document__c = docWrapper.doc.id;
                    pcDocumentLog.PC_Program__c = objectId;
                    //pcDocumentLog.PC_Account__c = ((caseObj != null && caseObj.AccountId != null) ? caseObj.AccountId : null);
                    pcDocumentLog.PC_Association_Record_ID__c = objectId;
                    pcDocumentLog.PC_Association_Record_Name__c = ((caseObj.CaseNumber != null) ? caseObj.CaseNumber : null);
                    pcDocumentLog.PC_Association_Type__c = ((caseObj.Type != null) ? (String.isNotBlank(objLabel) ? (objLabel + ': ' + caseObj.Type) : caseObj.Type) : null);
                    pcDocumentLogs.add(pcDocumentLog);
                }
            }
            if(pcDocumentLogs != null && !pcDocumentLogs.isEmpty()) {
                PC_Database.ins(pcDocumentLogs);
            }

            // Fetch primary contact of accounts
            //FLS check for Account
            List<String> accountFields = new List<String>{'Id', 'HealthCloudGA__PrimaryContact__c'};
            PC_Database.assertAccess(PC_Constants.PC_ACCOUNT, PC_Database.Operation.Reading, accountFields);
            //FLS check for Contact
            List<String> contactFields = new List<String>{'Id', 'AccountId', 'Name', 'Fax', 'Email', 'HealthCloudGA__PrimaryLanguage__c'};
            PC_Database.assertAccess(PC_Constants.CONTACT, PC_Database.Operation.Reading, contactFields);

            List<Account> recipientAccounts = [
                    SELECT Id, HealthCloudGA__PrimaryContact__r.AccountId, HealthCloudGA__PrimaryContact__r.Email, HealthCloudGA__PrimaryContact__r.Fax, HealthCloudGA__PrimaryContact__r.Name, HealthCloudGA__PrimaryContact__r.HealthCloudGA__PrimaryLanguage__c
                    FROM Account
                    WHERE Id in :accIds and HealthCloudGA__PrimaryContact__c != null
            ];

            Map<Id, Contact> recipientContact = new Map<Id, Contact>();
            for (Account acc : recipientAccounts) {
                recipientContact.put(acc.HealthCloudGA__PrimaryContact__c, acc.HealthCloudGA__PrimaryContact__r);
                PC_eLetter.RecipientWrapper recipientWrapper = new PC_eLetter.RecipientWrapper(acc.HealthCloudGA__PrimaryContact__r);
                recipients.add(recipientWrapper);
            }

            ContentVersion contentVersion;
            Attachment attach;
            List<ContentVersion> contentVersionList = new List<ContentVersion>();
            List<ContentDocumentLink> contentDocumentLinkList = new List<ContentDocumentLink>();
            Map<Id,ContentVersion> fileToDocMap = new Map<Id,ContentVersion>();

            // Get Email Service Address ID for setting setReplyTo
            String emailServiceAddressId = getEmailServiceAddressId();

            for (PC_eLetter.RecipientWrapper recipient : recipients) {
                //Preview
                List<String> toAddresses = new List<String>();
                PC_eLetterPreviewController.PreviewRequest previewRequest = new PC_eLetterPreviewController.PreviewRequest();
                previewRequest.whatId                           = String.valueOf(objectId);
                previewRequest.whoId                            = recipient.Id;
                previewRequest.templateId                       = templateId;
                Messaging.SingleEmailMessage singleEmailMessage = PC_eLetterService.geteLetterPreview(previewRequest);

                Messaging.SingleEmailMessage aEmail = new Messaging.SingleEmailMessage();
                aEmail.setTemplateId(templateId);

                //SetReplyTo if inbound emailId Presents
                if(String.isNotBlank(emailServiceAddressId)){
                    aEmail.setReplyTo(emailServiceAddressId);
                }
                if(String.isNotBlank(String.valueOf(OrgWideEmailAddressId))){
                    aEmail.setOrgWideEmailAddressId(OrgWideEmailAddressId);
                }
                //Get the key to fetch doc wrapper and set the parameters for sending email to Users
                Id docWrapperKey;
                if(recipient.type == PC_eLetter.RecipientType.USER.name()){
                    docWrapperKey =  recipient.Id;
                    aEmail.setSaveAsActivity(false);
                }else if(recipient.type == PC_eLetter.RecipientType.CONTACT.name()){
                    docWrapperKey =  recipientContact.get(recipient.Id).AccountId;
                    aEmail.setWhatId(objectId);
                }
                if (recipient.Id != null && !sendToCurrentUser) {
                    aEmail.setTargetObjectId(recipient.Id);
                } else if (recipient.Id != null && sendToCurrentUser) {
                    aEmail.setTargetObjectId(UserInfo.getUserId());
                    aEmail.setSaveAsActivity(false);
                } else {
                    toAddresses.add(recipient.email);
                    aEmail.setToAddresses(toAddresses);
                }

                // Adding ThreadId and [Secure] tag to Subject
                String threadId = PC_Utility.getThreadId(new List<String>{objectId, accountIdToDocumentWrapper.get(docWrapperKey).doc.Id});
                String secureTag = (isEmailSecure != null && isEmailSecure) ? ' ' + System.Label.PC_EmailSecureTag + ' ' : ' ';
                if (String.isNotBlank(subject)) {
                    aEmail.setSubject(subject + secureTag + ((insertThreadIdInSubject && isThreadIdSettingActive) ? threadId : ''));
                } else {
                    aEmail.setSubject(singleEmailMessage.getSubject() + secureTag + ((insertThreadIdInSubject && isThreadIdSettingActive) ? threadId : ''));
                }
                aEmail.setEntityAttachments(attachmentIds);  // This line is for adding attachments to email
                aEmail.setPlainTextBody(singleEmailMessage.getPlainTextBody() + ((!insertThreadIdInSubject && isThreadIdSettingActive) ? '\n' + threadId : ''));
                // PC-6743 - Fix for visual force e-letter templates when there is no HtmlBody given in template
                if(String.isNotBlank(singleEmailMessage.getHtmlBody())) {
                    aEmail.setHtmlBody((!insertThreadIdInSubject && !(templateType.equalsIgnoreCase('text')) && isThreadIdSettingActive) ? singleEmailMessage.getHtmlBody() + '\n' + threadId : singleEmailMessage.getHtmlBody());
                }
                string pdfBody = singleEmailMessage.getPlainTextBody(); //aEmail.getHtmlBody();
                // Enclose the emailBody with <pre> tag to get pre formatted text in PDF document
                pdfBody = PC_Utility.encloseStringWithPreTag(new List<String>{pdfBody});
                blob body = blob.toPDF(pdfBody);
                listEmailsToSend.add(aEmail);

                if(useSalesforceFiles){
                    contentVersion = new ContentVersion();
                    contentVersion.title = sentEmailCopy + PC_Constants.PDF_FORMAT;
                    contentVersion.PathOnClient = sentEmailCopy + PC_Constants.PDF_FORMAT;
                    contentVersion.versiondata = body;
                    contentVersion.SharingOption = PC_Constants.FILE_SHARING_OPTION_ALLOWED;
                    contentVersionList.add(contentVersion);
                    fileToDocMap.put(accountIdToDocumentWrapper.get(docWrapperKey).doc.Id,contentVersion);

                }else {
                    attach = new Attachment();
                    attach.Body = body;
                    attach.Name = sentEmailCopy + PC_Constants.PDF_FORMAT;
                    attach.ContentType = PC_ContentType;
                    attach.IsPrivate = false;
                    attach.ParentId = accountIdToDocumentWrapper.get(docWrapperKey).doc.Id;
                    attachmentList.add(attach);
                }
                system.debug('docId-->'+accountIdToDocumentWrapper.get(docWrapperKey).doc.Id);
            }
            if(useSalesforceFiles){
                PC_Database.ins(contentVersionList);
                Set<Id> contentVerIds = new Set<Id>();
                for(ContentVersion cv: contentVersionList){
                    contentVerIds.add(cv.Id);
                }

                List<ContentVersion> newCVList=[SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN:contentVerIds];
                ContentDocumentLink cdl;
                for(Id docId: fileToDocMap.keySet()){
                    for(ContentVersion cv: newCVList){
                        if(cv.Id == fileToDocMap.get(docId).Id){
                            cdl = new ContentDocumentLink();
                            cdl.ContentDocumentId = cv.ContentDocumentId;
                            cdl.LinkedEntityId =docId;
                            cdl.ShareType = PC_Constants.FILE_SHARE_TYPE_VIEWER;
                            contentDocumentLinkList.add(cdl);
                        }
                    }
                }
                PC_Database.ins(contentDocumentLinkList);
            }else{
                PC_Database.ins(attachmentList);
            }

            // create Email Attachment Document if email has any attachments attached
            if (attachmentIds != null && !attachmentIds.isEmpty()) {
                createMailAttachmentDocument(attachmentIds, documentRecipients, useSalesforceFiles);
            }
            Messaging.sendEmail(listEmailsToSend);
        } catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
    }

    /**
    * Returns Email Service Address Id
    * @return String    returns the Email Service Address ID
    */
    public String getEmailServiceAddressId() {
        String emailServiceAddressId = PC_Constants.EMPTY_STRING;
        String emailServiceName = PC_SYSTEM.getPatientConnectSetting(PC_Constants.PC_INBOUND_EMAIL_SERVICE_NAME, PC_Constants.EMPTY_STRING);
        String emailAddressName = PC_SYSTEM.getPatientConnectSetting(PC_Constants.PC_INBOUND_EMAIL_ADDRESS_NAME, PC_Constants.EMPTY_STRING);
        if (String.isNotBlank(emailServiceName) && String.isNotBlank(emailAddressName)) {
            for (EmailServicesAddress emailServicesAddress : [SELECT Id, Function.FunctionName, LocalPart,DeveloperName, EmailDomainName FROM EmailServicesAddress WHERE Function.FunctionName = :emailServiceName and DeveloperName = :emailAddressName]) {
                emailServiceAddressId = emailServicesAddress.LocalPart + '@' + emailServicesAddress.EmailDomainName;
            }
            if (String.isBlank(emailServiceAddressId)) {
                throw new AuraHandledException(System.Label.PC_EmailServiceAddress_Error);
            }
        }
        return emailServiceAddressId;
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
    public void createMailAttachmentDocument(List<String> attachmentIds, List<PC_eLetter.DocumentWrapper> documentRecipients, Boolean useSalesforceFiles) {
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

        try {
            for (PC_eLetter.DocumentWrapper docWrapper : documentRecipients) {
                for (MailAttachment mailAttachment : mailAttachments) {
                    PC_Document__c doc = new PC_Document__c(
                            RecordTypeId = EMAIL_ATTACHMENT_RECORD_TYPE,
                            PC_Document_Status__c = PC_Constants.PC_NEW,
                            PC_Parent_Document__c = docWrapper.doc.Id,
                            PC_Engagement_Program__c = docWrapper.doc.PC_Engagement_Program__c,
                            PC_Description__c = mailAttachment.fileName,
                            PC_To_Email_Address__c = docWrapper.recipient2.email
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

                PC_Database.ins(contentDocumentLinkList);
            } else {
                for (DocumentFileWrapper docWrapper : docFileList) {
                    docWrapper.attachment.ParentId = docWrapper.pcDocument.Id;
                    attachmentList.add(docWrapper.attachment);
                }

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
        List<Id> documentIdList = new List<Id>();
        List<Id> attachmentIdList = new List<Id>();
        List<Id> contentVersionIdList = new List<Id>();
        List<MailAttachment> mailAttachmentFinalList = new List<MailAttachment>();

        //FLS Check
        List<String> docFields = new List<String>{'Id', 'Name', 'Body', 'Type', 'ContentType'};
        PC_Database.assertAccess('document', PC_Database.Operation.Reading, docFields);

        List<String> attachmentFields = new List<String>{'Name', 'Body', 'ContentType'};
        PC_Database.assertAccess('Attachment', PC_Database.Operation.Reading, attachmentFields);

        List<String> contentVersionFields = new List<String>{'Id', 'Title', 'VersionData', 'FileExtension', 'FileType', 'PathOnClient'};
        PC_Database.assertAccess('ContentVersion', PC_Database.Operation.Reading, contentVersionFields);

        //Prepare lists of document ids, attachment ids, contentVersion ids
        for (Id attachmentId : attachmentIds) {
            SObjectType sObjectType = attachmentId.getSobjectType();
            if (sObjectType == Document.sObjectType) {
                documentIdList.add(attachmentId);
            } else if (sObjectType == Attachment.sObjectType) {
                attachmentIdList.add(attachmentId);
            } else if (sObjectType == ContentVersion.sObjectType) {
                contentVersionIdList.add(attachmentId);
            }
        }

        //Gets details of document ids, attachment ids, contentVersion ids
        List<Document> documentList = [SELECT Id, Name, Body, Type, ContentType FROM document WHERE Id IN :documentIdList];
        List<Attachment> attachList = [SELECT Id, Name, Body, ContentType FROM Attachment WHERE Id IN :attachmentIdList];
        List<ContentVersion> contentVersionList = [SELECT Id, Title, VersionData, FileExtension, FileType, PathOnClient FROM ContentVersion WHERE Id IN:contentVersionIdList];

        //Prepare mailattachments using the above details of documents, attachments and contentVersions
        for(Document doc: documentList){
            mailAttachment = new MailAttachment(doc);
            mailAttachments.add(mailAttachment);
        }
        for(Attachment attach: attachList){
            mailAttachment = new MailAttachment(attach);
            mailAttachments.add(mailAttachment);
        }
        for(ContentVersion contentVersion: contentVersionList){
            mailAttachment = new MailAttachment(contentVersion);
            mailAttachments.add(mailAttachment);
        }

        /************************************/
        return mailAttachments;
    }

    /**
    * DocumentFileWrapper is a wrapper object for associating an PC_Document__c with the outbound attachment(It can be files or attachment)
    */
    public  inherited sharing class DocumentFileWrapper {
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