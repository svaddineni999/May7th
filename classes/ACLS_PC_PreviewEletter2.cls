/*********************************************************************************
Class Name      : ACLS_PC_PreviewEletter2
Description     : Methods for eLetter2 Preview component
Created By      : Ronak Bansal
Created Date    : 20-Mar-2023
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   	Description
-----------------------------------------------------------------------------------
Ronak Bansal            20-Mar-2023              Initial Version
*********************************************************************************/

public with sharing class ACLS_PC_PreviewEletter2 {

    /**
    * Retrieves rendered email template for recipient.
    *
    * @param eLetterId      id of the selected eletter
    * @param recordId       whatId for rendering email template
    * @param recipientsId   whoId for rendering email template
    * @return RenderedMailTemplate  - Rendered email template object
    */
    @AuraEnabled
    public static PC_eLetter2Controller.RenderedMailTemplate getTemplatePreviewForRecipients(String eLetterId, String recordId, String recipientId) {
        PC_eLetter2Controller.RenderedMailTemplate renderedMailTemplate = new PC_eLetter2Controller.RenderedMailTemplate();
        PC_eLetterPreviewController.PreviewRequest previewRequest = new PC_eLetterPreviewController.PreviewRequest();
        Messaging.SingleEmailMessage singleEmailMessage;
        String recipientType;
        try {
            if (String.isNotBlank(recipientId)) {
                recipientType = String.valueOf(Id.valueOf(recipientId).getSobjectType());
                if (recipientType == PC_Constants.PC_ACCOUNT) {
                    //FLS check for Contact
                    List<String> accountFields = new List<String>{
                            'Id', 'HealthCloudGA__PrimaryContact__c'
                    };
                    PC_Database.assertAccess(PC_Constants.PC_ACCOUNT, PC_Database.Operation.Reading, accountFields);
                    List<Account> accList = new List <Account> ();
                    if(Schema.sObjectType.Account.isAccessible()){
                        accList = [
                                Select Id, HealthCloudGA__PrimaryContact__c
                                From Account
                                where id =:recipientId and HealthCloudGA__PrimaryContact__c != null
                        ];
                    }
                    if(accList.size()>0) {
                        recipientId = accList[0].HealthCloudGA__PrimaryContact__c;
                    }else{
                        recipientId = null;
                    }
                }
                previewRequest.whoId = recipientId;
            }

            if (String.isNotBlank(recordId)) {
                recordId = PC_eLetter2Controller.getCaseId(recordId);
                previewRequest.whatId = recordId;
            }

            if (eLetterId != null) {
                EmailTemplate emailTemplate = new emailTemplate();
                PC_eLetter__c eLetter = PC_eLetterService.getELetter(eLetterId);
                if (eLetter != null && eLetter.PC_Template_Name__c != null) {
                    emailTemplate = PC_SYSTEM.getEmailTemplateDetails(eLetter.PC_Template_Name__c);
                    previewRequest.templateId = emailTemplate.Id;
                }
                singleEmailMessage = PC_eLetterService.geteLetterPreview(previewRequest);

                if (singleEmailMessage != null) {
                    renderedMailTemplate = new PC_eLetter2Controller.RenderedMailTemplate(
                            singleEmailMessage.getTemplateName(),
                            singleEmailMessage.getSubject(),
                            emailTemplate.TemplateType,
                            singleEmailMessage.getPlainTextBody(),
                            singleEmailMessage.getHtmlBody()
                    );
                } else {
                    renderedMailTemplate = new PC_eLetter2Controller.RenderedMailTemplate();
                }
            }
            /* Commented below piece of code because we are planning to do updatePreviewInfo in future release
            String eLetterPreviewClass = 'PC_eLetter2_PreviewRenderController';
            if (String.isNotBlank(eLetterPreviewClass)) {
                Type t = Type.forName(eLetterPreviewClass);
                if (t != null) {
                    Object o = t.newInstance();

                    if (o instanceof PC_PreviewEletter2.ELetterPreviewInfoProcessor) {
                        PC_PreviewEletter2.ELetterPreviewInfoProcessor previewInfo = (PC_PreviewEletter2.ELetterPreviewInfoProcessor) o;
                        previewInfo.updatePreviewInfo(eLetterId, recordId, recipientId, renderedMailTemplate);
                    } else {
                        throw new PreviewException('Registered '+ eLetterPreviewClass +' does not implement required interface.');
                    }
                }
            }*/
        } catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return renderedMailTemplate;
    }

    /*********************************************************************************
    Method Name    : getDocgenJobStatus
    Description    : query the Omnistudio Document generation process Job record.
    Parameter      : Strung jobId
    *********************************************************************************/
    @AuraEnabled
    public static DocumentGenerationProcess getDocgenJobStatus(String jobId){
        List <DocumentGenerationProcess> docJobRecord = new List <DocumentGenerationProcess>();
        if(Schema.sObjectType.DocumentGenerationProcess.isAccessible()){
        docJobRecord = [select id, ResponseText, Status from DocumentGenerationProcess where id =:jobId limit 1];
        }
        return (docJobRecord.size()>0)? docJobRecord[0] : null;
    }

    /*********************************************************************************
    Method Name    : getContentDocumentID
    Description    : query the contentDocumentId from the contentversionId
    Parameter      : String contentVersionId
    *********************************************************************************/
    @AuraEnabled
    public static String getContentDocumentID(String contentVersionId){
        List<ContentVersion> contentVersionRecord = new List <ContentVersion> ();
        if(Schema.sObjectType.ContentVersion.isAccessible()){
        contentVersionRecord = [select id,ContentDocumentId from ContentVersion where id = :contentVersionId];
        }
        return (contentVersionRecord.size()>0)? contentVersionRecord[0].ContentDocumentId : null;
    }

    /**
     * Exception to indicated that the <code>Sender</code> was unable to send an eLetter.
     */
    public inherited sharing class PreviewException extends Exception {}

    public interface ELetterPreviewInfoProcessor {
        /**
         * Update the EletterPreviewInfo on the response returned from the service.
         * @param eLetterId Adverse Event object that is to be saved.
         * @param recordId  recordId of the object
         * @param recipientId  id of the selected recipient
         * @param renderedMailTemplate Holds values received for updating EletterPreviewInfo.
         */
        void updatePreviewInfo(String eLetterId, String recordId, String recipientId, PC_eLetter2Controller.RenderedMailTemplate renderedMailTemplate);
    }
}