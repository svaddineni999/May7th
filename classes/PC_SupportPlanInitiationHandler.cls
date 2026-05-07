/*********************************************************************************************************
Class Name      : PC_SupportPlanInitiationHandler 
Description     : Trigger handler on Case object to implement Support Plan if defined for the case
Created By      : Prachi Nandgaonkar
Created Date    : Feb 22, 2018
Modification Log:
-------------------------------------------------------------------------------------------------------------- 
Developer                   Date                   	Description
--------------------------------------------------------------------------------------------------------------            
Prachi Nandgaonkar          Feb 22, 2018            Initial Version
Xiukai Ning                 Feb 28, 2019            PC-3775 - Code review. FLS is NOT needed in Triggers, as they always run in System Mode.
                                                    Trigger delegate class (handler) that has with Sharing keyword however, will apply user sharing.
                                                    We are removing all FLS and With Sharing keywords in the handlers.
Haritha Reddy               Mar 30, 2020            Upgraded logic to support all Objects for Support Plan and also evaluate Trigger Criteria
Haritha Reddy               Oct 06, 2020            [PC-6792] Modified Support Plan execution logic to stop executing in Recursive Scenario.
Haritha Reddy               Nov 10, 2020            PC-6893 Force reviewer scan issue fix - declared class as with sharing
Haritha Reddy               Apr 07, 2021            PC-6629 Removed error handling since Trigger handler framework will handle that.
Hitha Avalakki              May 25, 2021            PC-7545: Removed 'with sharing' class level declaration since trigger handler code runs in system context.
Satheesh Kumar              Nov 16, 2021            [PC-8213] Excluded FLS Check and added inherited sharing
****************************************************************************************************************/
/* PC-7545: 'with sharing' class level declaration is not required since trigger handler code runs in Trigger Context*/
public inherited sharing class PC_SupportPlanInitiationHandler extends PC_TriggerHandler{

    override public void afterInsert() {
        initiateSupportPlansProcessing((Map<Id, SObject>) newMap, (Map<Id, SObject>) oldMap, PC_Constants.ObjectOperation.oINSERT);
    }
    override public void afterUpdate() {
        initiateSupportPlansProcessing((Map<Id, SObject>) newMap, (Map<Id, SObject>) oldMap, PC_Constants.ObjectOperation.oUPDATE);
    }
    /*********************************************************************************
    Method Name    : initiateSupportPlansProcessing
    Author         : Haritha Reddy
    Description    : Initiates Processing of Support Plans
    Return Type    : void
    Parameter      : newMap, oldMap
    *********************************************************************************/
    private void initiateSupportPlansProcessing(Map<Id, SObject> newMap, Map<Id, SObject> oldMap, PC_Constants.ObjectOperation eventType){
        if(!newMap.isEmpty()){
            /* Process Records with support plan runtimes having pending condition Status*/
            PC_SupportPlanEngine.processSupportPlanActivity(newMap.keySet());
            /*Create and Process Support Plan Runtimes*/
            String objectType = ((Id)newMap.values()[0].Id).getSobjectType().getDescribe().getName();
            List<PC_SupportPlanEngine.SupportPlanInfo> supportPlanInfoList =
                    PC_SupportPlanEngine.getRecordsMatchingSupportPlanTriggerCriteria(newMap.values(),oldMap,eventType,objectType);
            PC_SupportPlanEngine.publishSupportPlanPlatformEvent(supportPlanInfoList);
        }

    }
}