/**
 * Created by tejapatel on 2/28/2019.
 *  * Modification Log:
 * Shishir Bansal     07 March , 2019    Exception handling and adding the error in Automation task cn comment
 *                                       field
 *
 */

public with sharing class PC_PharmacyLookupAutomatedTask implements PC_SupportPlan.Action {
    private static PC_SupportPlan.PerformActionResult result = new PC_SupportPlan.PerformActionResult();

    public PC_SupportPlan.PerformActionResult performAction(STRING Source, STRING SourceId, STRING taskConfiguration, STRING taskID) {
        result.actionStatus =   PC_SupportPlan.ActionStatus.IN_PROGRESS;
        result.errorMessage =   PC_Constants.EMPTY_STRING;

        PC_SupportPlan.PerformActionResult result = new PC_SupportPlan.PerformActionResult();


        try {
            result.actionStatus = PC_SupportPlan.ActionStatus.IN_PROGRESS;
            result.errorMessage = PC_Constants.EMPTY_STRING;
            if (Source.equalsIgnoreCase(PC_Constants.PC_CASE) && SourceId != null) {
                doPharmacyCardCallout(SourceId, taskID);
            }

        }catch(Exception ex){
            result.actionStatus = PC_SupportPlan.ActionStatus.COMPLETED_FAILED;
            result.errorMessage = JSON.serialize(ex.getStackTraceString());
            PC_Utility.createExceptionLog(ex);

        }
        return result;
    }

    @future (callout=true)
    public static void doPharmacyCardCallout( STRING SourceId, STRING taskID) {
      try {
            PC_eBenefits.PharmacyCard handler = PC_eBenefits.getPharmacyCardService();
            PC_eBenefits.PharmacyCardRequest request = handler.createPharmacyCardRequest();
            PC_eBenefits_Utility.updatePharmacyCardRequest(SourceId, request);
            PC_eBenefits.PharmacyCardResponse response = handler.lookupPharmacyCard(request);
            PC_Health_Plan__c healthPlan = new PC_Health_Plan__c();

            List<String> fields = new List<String>();
            fields.add('AccountId');
            PC_Database.assertAccess(PC_Constants.PC_CASE, PC_Database.Operation.Reading, fields);
            Case currentCase = [Select AccountId from Case where id = :SourceId];
            healthPlan.Patient__c = currentCase.AccountId;
            handler.updateHealthPlan(response, healthPlan);
            PC_Health_Plan__c insertedHealthPlan = (PC_Health_Plan__c)PC_Database.ins(healthPlan, true);

            if (insertedHealthPlan != null) {
                List<String> taskfields = new List<String>();
                taskfields.add('Status');
                taskfields.add('id');
                PC_Database.assertAccess(PC_Constants.PC_TASK, PC_Database.Operation.Reading, taskfields);
                Task currentActivity = [SELECT Status, id FROM Task WHERE id = :taskID LIMIT 1];
                if (currentActivity != null) {
                    currentActivity.Status = PC_Constants.PC_STATUS_COMPLETED;
                    PC_Database.upd(currentActivity);
                }
            }
        }catch(Exception ex) {

          List<String> taskfields = new List<String>();
          taskfields.add('Status');
          taskfields.add('id');
          taskfields.add('Description');
          PC_Database.assertAccess(PC_Constants.PC_TASK, PC_Database.Operation.Reading, taskfields);
          Task currentActivity = [SELECT Status, id, Description FROM Task WHERE id = :taskID LIMIT 1];
          currentActivity.Description =ex.getMessage();
          currentActivity.Status   = 'Waiting on someone else';
          currentActivity = (Task) PC_Database.ups(currentActivity);

        }
    }

}