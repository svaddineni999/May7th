/*********************************************************************************
Class Name      : PC_DocInboundEmailLightningController
Description     : Controller class used for PC_Document_InboundEmail.cmp (lightning)
Created By      : Deloitte               
Created Date    : June 08, 2016
Modification Log:
---------------------------------------------------------------------------------- 
Developer              Date                   Description
-----------------------------------------------------------------------------------            
Alina Balan           June 16, 2016           Initial Version
Ajinkya Deshmukh		June 08, 2017			FLS Check Added
Shabda Bhujad		  June 22, 2017			  [PC-1813] Added addtional logic to accomodate pdf attachment for outbound email
Mayuresh Patil          July 25, 2017           Additional FLS/CRUD check Added
Mayuresh Patil         April 29,2019          [PC-4767] Added logic to bypass contentType for nontext content types.
Haritha Reddy          May 05,2020            [PC-6249] Added limit to the inner SOQL query
Satheesh Kumar         Aug 08,2020            [PC-6642] Added isHTMLType variable to differentiate text and html type document
Haritha Reddy         21-Jan-2021            [PC-7102] Force Reviewer scan issue fix. Updated Sharing declaration.
*********************************************************************************/

public with sharing class PC_DocInboundEmailLightningController {
    
    /*********************************************************************************
    Method Name    : getAttachmentId
    Author         : Alina Balan
    Description    : This method is used to get all the emails details
    Return Type    : EmailDetailsWrapper
    Parameter      : String docId
    *********************************************************************************/
    @AuraEnabled 
    public static EmailDetailsWrapper getAttachmentId(String docId) {
        EmailDetailsWrapper emailDetailsWrapper = new EmailDetailsWrapper();

        /*
        * FLS Check for Attachment
        */
        List<String> fields = new List<String>{'Name','Body','ContentType','ParentId'};
        PC_Database.assertAccess('Attachment',PC_Database.Operation.Reading, fields);
        /*
        * FLS Check for PC_Document__c
        */
        fields = new List<String>{'Name',PC_Constants.getQualifiedAPIName('PC_Description__c'), PC_Constants.getQualifiedAPIName('PC_Parent_Document__c')};
        PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Document__c'),PC_Database.Operation.Reading, fields);
        
        List<Attachment> lstAttachments = [SELECT Id, Name, Body, ContentType FROM Attachment WHERE ParentId =: docId order by CreatedDate desc];
        List<PC_Document__c> contRecords = [SELECT PC_Description__c, RecordType.DeveloperName, Name, (SELECT Id, Name FROM Attachments LIMIT 2000)
                                            FROM PC_Document__c WHERE PC_Parent_Document__c =: docId];
        if (lstAttachments.size() > 0) {
            try{
                /*
                 * [PC-1813] Added addtional logic to accomodate pdf attachment for outbound email and to typecast it to string
				 */
                if(lstAttachments[0] != null) {
                    emailDetailsWrapper.attachmentId = lstAttachments[0].Id;
                    if(String.isNotBlank(lstAttachments[0].ContentType) && lstAttachments[0].contentType.containsIgnoreCase('text')) {
                        emailDetailsWrapper.attachmentBody = (lstAttachments[0].body).toString();
                        emailDetailsWrapper.isTEXT = lstAttachments[0].contentType.containsIgnoreCase('text');
                        emailDetailsWrapper.isHTMLType = lstAttachments[0].contentType.containsIgnoreCase('html');
                    }
                }                                
            }
            catch(Exception e){
                emailDetailsWrapper.attachmentBody = Label.PC_Cannot_Display_Document;
            }
        }

        emailDetailsWrapper.lstDocuments = contRecords;
        return emailDetailsWrapper; 
    }
    
    /*********************************************************************************
    Class Name    : EmailDetailsWrapper
    Author        : Alina Balan
    Description   : Wrapper class for email details
    *********************************************************************************/
    public inherited sharing class EmailDetailsWrapper {
        @AuraEnabled public Id attachmentId {get; set;}
        @AuraEnabled public String attachmentBody {get; set;}
        @AuraEnabled public boolean isTEXT {get;Set;}//PC-1813
        @AuraEnabled public boolean isHTMLType {get;Set;}//PC-6642
        @AuraEnabled public List<PC_Document__c> lstDocuments {get; set;}
        public EmailDetailsWrapper() {
            this.isTEXT = false; //PC-1813
            this.isHTMLType = false; //PC-6642
            lstDocuments = new List<PC_Document__c>();
        }
    }
}