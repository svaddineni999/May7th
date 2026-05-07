/*********************************************************************************************************
Class Name      : PC_SupportPlanActivityNextTaskHandler 
Description     : Trigger handler on Task object to evaluate next activity and create it on case 
                  if conditions are met
Created By      : Prachi Nandgaonkar
Created Date    : March 2, 2018
Modification Log:
-------------------------------------------------------------------------------------------------------------- 
Developer                   Date                   	Description
--------------------------------------------------------------------------------------------------------------            
Prachi Nandgaonkar          March 5, 2018           Initial Version
Tejas Patel					March 21, 2018			Remove field PC_IsMilestone__c and MilestoneName
Xiukai Ning                 Feb 28, 2019            PC-3775 - Code review. FLS is NOT needed in Triggers, as they always run in System Mode.
                                                    Trigger delegate class (handler) that has with Sharing keyword however, will apply user sharing.
                                                    We are removing all FLS and With Sharing keywords in the handlers.
Haritha Reddy				March 25, 2020			[PC-6059] replaced processNextSupportPlanActivity method call with createLogForCompletedTask
Satheesh Kumar              Nov 16, 2021            [PC-8213] Excluded FLS Check and added inherited sharing
****************************************************************************************************************/
public inherited sharing class PC_SupportPlanActivityNextTaskHandler extends PC_TriggerHandler{
    
	override public void afterUpdate() {
        PC_SupportPlanEngine.createLogForCompletedTask((Map<Id, Task>) newMap);
    }
}