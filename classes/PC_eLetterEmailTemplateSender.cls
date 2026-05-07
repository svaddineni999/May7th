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
  Shishir Bansal            11-Dec-2019                  [PC-5792] Avoid hardcoding of string variable
  *********************************************************************************/
public with sharing class PC_eLetterEmailTemplateSender implements PC_eLetter.Sender {
    static String sentEmailCopy = System.Label.PC_Sent_Email_Copy;
    static Id OUTBOUND_EMAIL_RECORD_TYPE = PC_SYSTEM.recordTypeId(PC_Constants.DOCUMENT_OBJECT, 'PC_Email_Outbound');
    static STRING curreUserType;
    static STRING PC_AutomatedTaskEmail;
    static ID OrgWideEmailAddressId;
    private static final String PC_ContentType = 'application/pdf' ;

    public void sendLetter(Id objectId, List<PC_eLetter.DocumentWrapper> documentRecipients, PC_eLetter__c eLetter, Boolean sendToCurrentUser) {
        try {
            String templateName     = eLetter.PC_Template_Name__c;
            curreUserType           = UserInfo.getUserType();
            Boolean useSalesforceFiles = PC_SYSTEM.useSalesforceFiles();
            PC_AutomatedTaskEmail  = PC_SYSTEM.getPatientConnectSetting(PC_Constants.PC_AUTOMATED_TASK_EMAIL,'');
            if(curreUserType == PC_Constants.PC_AUTOMATED_PROCESS_USERTYPE){
                if(String.isBlank(PC_AutomatedTaskEmail)){
                    throw new PC_eLetter.SenderException('Organisation Wide Email address has not been configured in Patient Connect Settings');
                }else{
                    OrgWideEmailAddress o = [SELECT ID FROM OrgWideEmailAddress WHERE Address =: PC_AutomatedTaskEmail];
                    OrgWideEmailAddressId = o.Id;
                }
            }
            /*
	        * FLS Check for EmailTemplate
	        */
	    	List<String> fields = new List<String>{'Body', 'DeveloperName'};
	        PC_Database.assertAccess(PC_Constants.PC_EMAIL_TEMPLATE,PC_Database.Operation.Reading, fields);

            List<EmailTemplate> emailTemplate = [SELECT Id, Body FROM EmailTemplate WHERE DeveloperName =: templateName];
            String templateId = emailTemplate[0].Id;
            List<Messaging.SingleEmailMessage> listEmailsToSend = new List<Messaging.SingleEmailMessage>();
            List<Attachment> attachmentList = new List<Attachment>();

            List<PC_eLetter.RecipientWrapper> recipients = new List<PC_eLetter.RecipientWrapper>();
            Map<Id, PC_eLetter.DocumentWrapper> accountIdToDocumentWrapper = new Map<Id, PC_eLetter.DocumentWrapper>();
            Set<Id> accIds  = new Set<Id>();
            for(PC_eLetter.DocumentWrapper docWrapper : documentRecipients){
                accountIdToDocumentWrapper.put(docWrapper.recipient2.Id, docWrapper);
                if(docWrapper.recipient2.type == PC_eLetter.RecipientType.ACCOUNT.name()){
                    accIds.add(docWrapper.recipient2.Id);
                }else if(docWrapper.recipient2.type == PC_eLetter.RecipientType.USER.name()){
                    recipients.add(docWrapper.recipient2);
                }else if(docWrapper.recipient2.type == PC_eLetter.RecipientType.PRE_CONFIGURED_EMAIL.name()){
                    recipients.add(docWrapper.recipient2);
                }
            }

            //List<Account> recipientContact = [Select ID ,(Select ID, Email, Fax, Name From Contacts) From Account Where Id in :accIds];
            Map<Id,Contact> recipientContact = new Map<Id,Contact>([Select Id, AccountId, Email, Fax, Name, HealthCloudGA__PrimaryLanguage__c From Contact
                                            where AccountId in :accIds and Account.HealthCloudGA__PrimaryContact__c !=null]);
            for(Id cId : recipientContact.keySet()){
                PC_eLetter.RecipientWrapper recipientWrapper = new PC_eLetter.RecipientWrapper(recipientContact.get(cId));
                recipients.add(recipientWrapper);
            }

            ContentVersion contentVersion;
            Attachment attach;
            List<ContentVersion> contentVersionList = new List<ContentVersion>();
            List<ContentDocumentLink> contentDocumentLinkList = new List<ContentDocumentLink>();
            Map<Id,ContentVersion> fileToDocMap = new Map<Id,ContentVersion>();

            for (PC_eLetter.RecipientWrapper recipient : recipients) {
                //Preview
                List<String> toAddresses = new List<String>();
                PC_eLetterPreviewController.PreviewRequest previewRequest = new PC_eLetterPreviewController.PreviewRequest();
                previewRequest.whatId                           = String.valueOf(objectId);
                previewRequest.whoId                            = recipient.Id;
                previewRequest.templateId                       = templateId;
                Messaging.SingleEmailMessage singleEmailMessage = PC_eLetterService.geteLetterPreview(previewRequest);
                ////////////////////
                Messaging.SingleEmailMessage aEmail = new Messaging.SingleEmailMessage();
                aEmail.setTemplateId(templateId);
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
                if(recipient.Id != null) {
                    aEmail.setTargetObjectId(recipient.Id);
                }else{
                    toAddresses.add(recipient.email);
                    aEmail.setToAddresses(toAddresses);
                }
                aEmail.setSubject(singleEmailMessage.getSubject());
                aEmail.setPlainTextBody(singleEmailMessage.getPlainTextBody());
                aEmail.setHtmlBody(singleEmailMessage.getHtmlBody());
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
            Messaging.sendEmail(listEmailsToSend);
        } catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
    }
}