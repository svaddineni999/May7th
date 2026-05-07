/*********************************************************************************************************
Class Name      : PC_NextSupportPlanActivityHandler
Description     : Trigger handler on Support Plan Activity Log object to evaluate next activity criteria
                  and execute it if conditions are met
Created By      : Haritha Reddy
Created Date    : Mar 24, 2020
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer                   Date                   	Description
--------------------------------------------------------------------------------------------------------------
Haritha Reddy          Mar 24, 2020            Initial Version
Satheesh Kumar         Nov 16, 2021            [PC-8213] Excluded FLS Check and added inherited sharing
****************************************************************************************************************/

public inherited sharing class PC_NextSupportPlanActivityHandler extends PC_TriggerHandler{
    override public void afterInsertUpdate() {
        PC_SupportPlanEngine.processNextSupportPlanActivity((List<PC_SupportPlanActivityLog__c>) newList);
    }
}