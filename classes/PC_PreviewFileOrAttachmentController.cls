/*********************************************************************************
Class Name          : PC_PreviewFileOrAttachmentController
Description         : Controller for PC_PreviewFileOrAttachment Component
Created By          : Haritha Reddy
Created Date        : 04-Jun-2019
Modification Log    :
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------
Haritha Reddy          07-Jul-2019              [PC-4947]Initial Version
Xiukai Ning            14-Nov-2019              [PC-5713] Added capability of Preview for html attachment
Satheesh Kumar         08-Aug-2020              [PC-6642] Added isHTMLType variable to differentiate text and html type document
Haritha Reddy          21-Jan-2021              [PC-7102] Force Reviewer scan issue fix. Updated Sharing declaration.
Satheesh Kumar         26-Mar-2021              [PC-7609] Added new property to get site Base Url
*********************************************************************************/

public with sharing class PC_PreviewFileOrAttachmentController {
    /*********************************************************************************
    Method Name    : getDocumentDetails
    Author         : Haritha Reddy
    Description    : This method is used to get all the required Document details for Preview
    Return Type    : DocumentDetailsWrapper
    Parameter      : String docId
    *********************************************************************************/
    @AuraEnabled
    public static DocumentDetailsWrapper getDocumentDetails(String docId) {
        Boolean useSalesforceFiles = PC_SYSTEM.useSalesforceFiles();
        Boolean useDocumentPreviewInStrictMode = PC_SYSTEM.useDocumentPreviewInStrictMode();
        Boolean previewFile =  false;
        DocumentDetailsWrapper documentDetailsWrapper = new DocumentDetailsWrapper();

        //FLS Check
        List<String> attachmentFields = new List<String>{'Name','Body','ContentType','ParentId'};
        PC_Database.assertAccess('Attachment',PC_Database.Operation.Reading, attachmentFields);

        List<String> cdlFields = new List<String>{'LinkedEntityId','ContentDocument'};
        PC_Database.assertAccess('ContentDocumentLink',PC_Database.Operation.Reading, cdlFields);

        List<String> contentDocFields = new List<String>{'LatestPublishedVersionId','ContentModifiedDate','Title'};
        PC_Database.assertAccess('ContentDocument',PC_Database.Operation.Reading, contentDocFields);

        List<String> docFields = new List<String>{'Id','Name',PC_Constants.getQualifiedAPIName('PC_Description__c'), PC_Constants.getQualifiedAPIName('PC_Parent_Document__c')};
        PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Document__c'),PC_Database.Operation.Reading, docFields);

        //Populate Attachment Details
        List<Attachment> lstAttachments = [SELECT Id, Name, Body, ContentType,lastModifiedDate FROM Attachment WHERE ParentId =: docId order by createdDate desc];

        if (lstAttachments.size() > 0) {
            try{
                if(lstAttachments[0] != null) {
                    documentDetailsWrapper.attachmentId = lstAttachments[0].Id;
                    if(String.isNotBlank(lstAttachments[0].ContentType) && lstAttachments[0].contentType.containsIgnoreCase('text')
                            ) {
                        documentDetailsWrapper.attachmentBody = (lstAttachments[0].body).toString();
                        documentDetailsWrapper.isTEXT = lstAttachments[0].contentType.containsIgnoreCase('text');
                        documentDetailsWrapper.isHTMLType = lstAttachments[0].contentType.containsIgnoreCase('html');
                    }
                }
            }
            catch(Exception e){
                documentDetailsWrapper.attachmentBody = Label.PC_Cannot_Display_Document;
            }
        }

        //Populate File Details
        List<ContentDocumentLink> lstContentDocs = [SELECT ContentDocumentId,ContentDocument.ContentModifiedDate
        FROM ContentDocumentLink WHERE LinkedEntityId =: docId order by ContentDocument.ContentModifiedDate desc];
        if (lstContentDocs.size() > 0) {
            documentDetailsWrapper.fileId = lstContentDocs[0].ContentDocumentId;
        }
        //Populate Preview Check Attributes
        if(((useSalesforceFiles == PC_Constants.TRUE_BOOLEAN) && lstContentDocs.size() > 0) ||
                ((useSalesforceFiles == PC_Constants.TRUE_BOOLEAN) && (useDocumentPreviewInStrictMode == PC_Constants.TRUE_BOOLEAN)) ||
                    ((useDocumentPreviewInStrictMode == PC_Constants.FALSE_BOOLEAN) && (useSalesforceFiles == PC_Constants.FALSE_BOOLEAN) && (lstContentDocs.size() > 0 && lstAttachments.size() == 0))){
            previewFile = true;
        }

        documentDetailsWrapper.previewFile = previewFile;
        return documentDetailsWrapper;
    }

    /*********************************************************************************
    Class Name    : DocumentDetailsWrapper
    Author        : Haritha Reddy
    Description   : Wrapper class for Document details
    *********************************************************************************/
    public inherited sharing class DocumentDetailsWrapper {
        //Set this to True if File should be previewed in a Document. Else, False.
        @AuraEnabled public Boolean previewFile {get; set;}

        //Used to store LatestPublishedVersionId of ContentDocument
        @AuraEnabled public Id fileId {get; set;}

        //Used to store salesforce Id of attachment
        @AuraEnabled public Id attachmentId {get; set;}

        //Used to store content of the attachment
        @AuraEnabled public String attachmentBody {get; set;}

        //Used to store type of the attachment
        @AuraEnabled public boolean isTEXT {get;Set;}

        //Used to store if its component is loaded on community/not
        @AuraEnabled public boolean isCommunity {get;Set;}

        //Used to store the site base Url
        @AuraEnabled public String siteBaseUrl {get;Set;}

        @AuraEnabled public boolean isHTMLType {get;Set;}

        //Used to store Attachment details of child Documents
        @AuraEnabled public List<PC_Document__c> lstDocuments {get; set;}
        public DocumentDetailsWrapper() {
            this.isTEXT = false;
            this.isHTMLType = false;
            lstDocuments = new List<PC_Document__c>();
            Id siteId = Site.getSiteId();
            if (siteId != null) {
                this.isCommunity = true;
            }else{
                this.isCommunity = false;
            }
            this.siteBaseUrl = Site.getBaseUrl();
        }
    }
}