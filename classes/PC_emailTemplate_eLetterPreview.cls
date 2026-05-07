/*********************************************************************************
  Class Name      : PC_emailTemplate_eLetterPreview
  Description     : Methods for eLetter service
  Created By      : Hitha Avalakki
  Created Date    : 10-April-19
  Modification Log:
  ----------------------------------------------------------------------------------
  Developer                   Date                   Description
  -----------------------------------------------------------------------------------
  Hitha Avalakki            10-April-19             Initial Version
  *********************************************************************************/
public with sharing class PC_emailTemplate_eLetterPreview{

    /*********************************************************************************
      Method Name    : getEletterPreview
      Description    : Method to pull classic email template details of selected eLetter
      Return Type    : PC_eLetter.PreviewResponse
      Parameter      : PC_eLetter.PreviewRequest previewRequest
      User Story     : PC-2064
    *********************************************************************************/
    public static Messaging.SingleEmailMessage getEletterPreview(PC_eLetterPreviewController.PreviewRequest previewRequest){
        Messaging.SingleEmailMessage email;
        try {
            if(previewRequest.templateId!=null){
                email=Messaging.renderStoredEmailTemplate(previewRequest.templateId, previewRequest.whoId,previewRequest.whatId);
            }

        } catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }

        return email;
    }
}