/**
 * Created by tejapatel on 11/20/2018.
 *
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------
Haritha Reddy             21-Jan-2021                 [PC-7102] Force Reviewer scan issue fix. Updated Sharing declaration.
Satheesh Kumar            29-Apr-2021                 [PC-7701] Added logic to send email or fax or both based on eletter category.
*********************************************************************************/

public with sharing class PC_SendAutoEletterHelper implements PC_SupportPlan.Action {
    public PC_SupportPlan.PerformActionResult performAction(STRING Source, STRING SourceId, STRING taskConfiguration, STRING taskID) {
        PC_SupportPlan.PerformActionResult result = new PC_SupportPlan.PerformActionResult();
        result.actionStatus =   PC_SupportPlan.ActionStatus.IN_PROGRESS;
        result.errorMessage =   PC_Constants.EMPTY_STRING;

        LIST<eLetterTaskWrapper> eLetterWrappers = new LIST<eLetterTaskWrapper>();
        MAP<STRING,BOOLEAN> spTargetRecepients = new MAP<STRING,BOOLEAN>();
        List<PC_eLetter_Recipient> finalRecepientList = new List<PC_eLetter_Recipient>();
        STRING returnMSG;

        try {
            PC_SupportPlan_eLetterController.eLettres eLetter = (PC_SupportPlan_eLetterController.eLettres) System.JSON.deserialize(taskConfiguration, PC_SupportPlan_eLetterController.eLettres.class);
            eLetterTaskWrapper eLetterWrapper = new eLetterTaskWrapper();
            eLetterWrapper.eLetterId = eLetter.eLetterID;
            eLetterWrapper.caseId = (ID) ID.valueOf(SourceId);

            for (PC_SupportPlan_eLetterController.targetRecepient t : eLetter.targetRecepient) {
                spTargetRecepients.put(t.recepient, t.selected);
            }

            PC_eLetter__c eLetterObj = PC_eLetterService.getELetter(eLetter.eLetterID);
            List<String> eLetterCategoryList = (eLetterObj.PC_Category__c)?.split(';');

            List<PC_eLetter_Recipient> allRecepient = PC_eLetter2Controller.getRecipients(eLetter.eLetterID, (ID) ID.valueOf(SourceId));
            for (PC_eLetter_Recipient r : allRecepient) {
                if(r.recipient.type != PC_eLetter.RecipientType.PRE_CONFIGURED_EMAIL.name() && eLetterCategoryList != null) {
                    if (eLetterCategoryList.contains(PC_Constants.PC_ELETTER_CATEGORY_AUTOMATED_EMAIL)) {
                        r.sendEmail = spTargetRecepients.get(r.recipientRole) == null ? false : (spTargetRecepients.get(r.recipientRole) && r.hasContactEmail);
                    }
                    if (eLetterCategoryList.contains(PC_Constants.PC_ELETTER_CATEGORY_AUTOMATED_FAX)) {
                        r.sendFax = spTargetRecepients.get(r.recipientRole) == null ? false : (spTargetRecepients.get(r.recipientRole) && r.hasContactFax);
                    }
                    finalRecepientList.add(r);
                }
            }
            eLetterWrapper.recepient = System.JSON.serialize(finalRecepientList);
            eLetterWrappers.add(eLetterWrapper);
            for (eLetterTaskWrapper e : eLetterWrappers) {
                if(finalRecepientList.size() == 0){
                    returnMSG = System.Label.PC_No_Recipients_Available;
                    break;
                }
                PC_eLetter2Controller.SendLetterRequest eLetterRequest = new PC_eLetter2Controller.SendLetterRequest();
                eLetterRequest.recordId = e.caseId;
                eLetterRequest.eletterId = e.eLetterId;
                String eLetterRequestJSONString = System.JSON.serialize(eLetterRequest);
                returnMSG = PC_eLetter2Controller.sendOutboundDocuments(eLetterRequestJSONString, e.recepient);
            }
            if (String.isBlank(returnMSG) || returnMSG == System.Label.PC_No_Recipients_Available || returnMSG == System.Label.PC_Eletter2_NoRecipientSelectedMessage) {
                result.actionStatus = PC_SupportPlan.ActionStatus.COMPLETED_FAILED;
                result.errorMessage = returnMSG;
            } else {
                result.actionStatus = PC_SupportPlan.ActionStatus.COMPLETED_SUCCESS;
            }
        }catch(Exception ex) {
            result.actionStatus = PC_SupportPlan.ActionStatus.COMPLETED_FAILED;
            result.errorMessage = JSON.serialize(ex.getStackTraceString());
            PC_Utility.logAndThrowException(ex);
        }
        return result;
    }

    public inherited sharing class eLetterTaskWrapper{
        public String   eLetterId {get; set;}
        public Id       caseId {get; set;}
        public String   recepient {get; set;}

        public eLetterTaskWrapper() {
        }
    }

}