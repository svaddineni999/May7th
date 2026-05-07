/*********************************************************************************
Class Name      : PC_eLetterPreviewButtonController
Description     : Methods for eLetter Preview Button lightning component
Created By      : Hitha Avalakki
Created Date    : 10-April-19
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   	Description
-----------------------------------------------------------------------------------
Hitha Avalakki				10-April-19				Inital Version
Haritha Reddy               17-Dec-2019            [PC-5791] Added error handling for previewEletterDetails method
Haritha Reddy             21-Jan-2021                 [PC-7102] Force Reviewer scan issue fix. Updated Sharing declaration.
*********************************************************************************/

public with sharing class PC_eLetterPreviewButtonController {

    /*********************************************************************************
    Method Name    : previewEletterDetails
    Description    : Get eLetter review details
    Return Type    : EletterPreviewDetails
    User Story	   : PC-2604
    Author		   : Hitha Avalakki
    *********************************************************************************/
    @AuraEnabled
    public static EletterPreviewDetails previewEletterDetails(String letterId) {
        EletterPreviewDetails eletterPreviewDetails=new EletterPreviewDetails();
        try {
            if (letterId != null && String.valueof(letterId) != Label.PC_None) {

                //Get eLetter record details
                PC_eLetter__c eletterRecord = PC_eLetterService.getELetter(Id.valueOf(letterId));

                //Get Email template details
                List<String> fields = new List<String>{
                        'Id', 'Name', 'Body', 'HtmlValue', 'DeveloperName'
                };
                PC_Database.assertAccess(PC_Constants.PC_EMAIL_TEMPLATE, PC_Database.Operation.Reading, fields);

                EmailTemplate emailTemplate = PC_SYSTEM.getEmailTemplateDetails(eletterRecord.PC_Template_Name__c);

                if (emailTemplate.Id != null) {
                    //Create eletter template title
                    List<Object> formattingArguments = new List<Object>{
                            emailTemplate.Name
                    };
                    eletterPreviewDetails.eLetterPreviewTitle = String.format(Label.PC_eLetterTemplateLabel, formattingArguments);
                }
            }

            //Check if the custom metadata contains an eletter preview component name, if it exists choose it else default component name is returned
            eletterPreviewDetails.previewComponentName = PC_SYSTEM.getPatientConnectSetting(PC_Constants.PC_ELETTER_PREVIEW_COMPONENT_NAME, PC_Constants.PC_DEFAULT_EMAIL_TEMPLATE_PREVIEW_COMPONENT);
        }catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return eletterPreviewDetails;
    }

    /*********************************************************************************
    Class Name     : EletterPreviewDetails
    Description    : Wrapper class for preview response
    User Story	   : PC-2604
    Author		   : Hitha Avalakki
    *********************************************************************************/
    public inherited sharing class EletterPreviewDetails {

        @AuraEnabled
        public String previewComponentName;
        @AuraEnabled
        public String eLetterPreviewTitle;

        public EletterPreviewDetails() {}

    }
}