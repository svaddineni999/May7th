/*********************************************************************************
Class Name      : PC_eLetterPreviewController
Description     : Methods for eLetter Preview lightning component
Created By      : Hitha Avalakki
Created Date    : 10-April-19
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   	Description
-----------------------------------------------------------------------------------
Hitha Avalakki				10-April-19				Inital Version
Shishir Bansal              11-Dec-2019            [PC-5792] Avoid hardcoding of string variable
Haritha Reddy               17-Dec-2019            [PC-5791] Added error handling for previewEletterContent method
Kishore Kanteti             May 5,2020             [PC-5940] Modified previewEletterContent method to support Adverse event objects
Vijay Kashikar              21-Jan-21              [PC-7102] Added FLS Checks
Vijay Kashikar              21-Jan-2021            [PC-7102] Added sharing clause
*********************************************************************************/

public with sharing class PC_eLetterPreviewController {

    public PC_eLetterPreviewController() {

    }
    /*********************************************************************************
    Method Name    : previewEletterContent
    Description    : Get eLetter content for preview
    Return Type    : PreviewResponse
    User Story	   : PC-2604
    Author		   : Hitha Avalakki
    *********************************************************************************/
    @AuraEnabled
    public static PreviewResponse previewEletterContent(String letterId, Id sObjectRecordId) {
        PreviewResponse previewResponse=new PreviewResponse();

        try {

            PreviewRequest previewRequest = new PreviewRequest();

            String objectType = String.valueOf(sObjectRecordId.getSobjectType());
            Messaging.SingleEmailMessage email;

            //Add the object record id that triggered eletter functionality
            previewRequest.whatId = String.valueOf(sObjectRecordId);
            Case currentCase = new Case();
            if (objectType != null && objectType.equals(PC_Constants.PC_CASE)) {
                //FLS check
                List<String> caseFields = new List<String>{
                        'Id', 'AccountId'
                };
                PC_Database.assertAccess(PC_Constants.PC_CASE, PC_Database.Operation.Reading, caseFields);

                //Add the account id of object record that triggered eletter functionality
                currentCase = [Select Id, AccountId from Case where id = :sObjectRecordId];
                String accountId ;
                if (currentCase != null) {
                    previewRequest.accountId = currentCase.AccountId;
                }
            }
            if (objectType != null) {
                if (letterId != null && String.valueof(letterId) != Label.PC_None) {

                    //FLS check
                    List<String> contactFields = new List<String>{
                            'Id', 'AccountId'
                    };
                    PC_Database.assertAccess(PC_Constants.CONTACT, PC_Database.Operation.Reading, contactFields);

                    //Add the contact record id of account record
                    List<Contact> contactList = new List<Contact>();
                    if(String.isNotBlank(currentCase.AccountId)){
                        contactList = [SELECT Id FROM Contact WHERE AccountId = :currentCase.AccountId];
                    }else if(objectType == PC_Constants.getQualifiedApiName(PC_Constants.PC_AdverseEvent_Object)){
                        List<String> adverseEventFields = new List<String>{
                                PC_Constants.getQualifiedAPIName('PC_Patient__c')
                        };
                        PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_AdverseEvent__c'), PC_Database.Operation.Reading, adverseEventFields);
                        PC_AdverseEvent__c currentAdverseEvent = [Select Id, PC_Patient__c from PC_AdverseEvent__c where id = :sObjectRecordId];
                        if(currentAdverseEvent.PC_Patient__c != null) {
                            contactList = [SELECT Id FROM Contact WHERE AccountId = :currentAdverseEvent.PC_Patient__c];
                        }
                        previewRequest.whoId = currentAdverseEvent.PC_Patient__c;
                        previewRequest.accountId = currentAdverseEvent.PC_Patient__c;
                    }else if(objectType == PC_Constants.getQualifiedApiName(PC_Constants.PC_AdverseEvent2_Object)){
                        List<String> adverseEvent2Fields = new List<String>{
                                PC_Constants.getQualifiedAPIName('PC_Patient__c')
                        };
                        PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_AdverseEvent2__c'), PC_Database.Operation.Reading, adverseEvent2Fields);

                        PC_AdverseEvent2__c currentAdverseEvent2 = [Select Id, PC_Patient__c from PC_AdverseEvent2__c where id = :sObjectRecordId];
                        if(currentAdverseEvent2.PC_Patient__c != null) {
                            List<String> contactStrings = new List<String>{
                                    'Id', 'AccountId'
                            };
                            PC_Database.assertAccess(PC_Constants.CONTACT, PC_Database.Operation.Reading, contactStrings);
                            contactList = [SELECT Id FROM Contact WHERE AccountId = :currentAdverseEvent2.PC_Patient__c];
                        }
                        previewRequest.whoId = currentAdverseEvent2.PC_Patient__c;
                        previewRequest.accountId = currentAdverseEvent2.PC_Patient__c;
                    }

                    if(contactList.size() > 0){
                        previewRequest.whoId = contactList[0].Id;
                    }
                    PC_eLetter__c eletterRecord = PC_eLetterService.getELetter(Id.valueOf(letterId));

                    //FLS check
                    List<String> emailTemplateFields = new List<String>{
                            'Id', 'Name', 'Body', 'HtmlValue', 'DeveloperName'
                    };
                    PC_Database.assertAccess(PC_Constants.PC_EMAIL_TEMPLATE, PC_Database.Operation.Reading, emailTemplateFields);

                    //Get Email template details
                    EmailTemplate emailTemplate = PC_SYSTEM.getEmailTemplateDetails(eletterRecord.PC_Template_Name__c);

                    if (emailTemplate.Id != null) {

                        //Add the email template id of for eletter record
                        previewRequest.templateId = emailTemplate.Id;

                        //Get eLetter content for preview
                        Messaging.SingleEmailMessage singleEmailMessage = PC_eLetterService.geteLetterPreview(previewRequest);

                        if (singleEmailMessage != null) {
                            previewResponse.eLetterPreviewData = singleEmailMessage.getPlainTextBody();
                        } else {
                            previewResponse.eLetterPreviewData = PC_Constants.EMPTY_STRING;
                        }
                    }
                }
            }
        }catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }

        return previewResponse;
    }

    /*********************************************************************************
    Class Name     : PreviewResponse
    Description    : Wrapper class for preview response
    User Story	   : PC-2604
    Author		   : Hitha Avalakki
    *********************************************************************************/
    public inherited sharing class PreviewResponse {
        @AuraEnabled
        public String eLetterPreviewData;

        public PreviewResponse() {
            eLetterPreviewData=PC_Constants.EMPTY_STRING;
        }

    }

    /*********************************************************************************
    Class Name     : PreviewRequest
    Description    : Wrapper class for preview request
    User Story	   : PC-2604
    Author		   : Hitha Avalakki
    *********************************************************************************/
    public inherited sharing class PreviewRequest {

        public String recordId{get;set;}
        public String whatId{get;set;}
        public String accountId{get;set;}
        public String templateId{get;set;}
        public String whoId{get;set;}

        public PreviewRequest(){

        }

    }

}