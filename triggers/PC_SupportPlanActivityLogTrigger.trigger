/*********************************************************************************************************
Trigger Name    : PC_SupportPlanActivityLog_Trigger
Description     : Trigger on PC_SupportPlanActivityLog__c Object.
Created By      : Haritha Reddy
Created Date    : Mar 27, 2020
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer                  Date                   Description
--------------------------------------------------------------------------------------------------------------
Haritha Reddy               Mar 27, 2020           Initial Version
****************************************************************************************************************/
trigger PC_SupportPlanActivityLogTrigger on PC_SupportPlanActivityLog__c (after insert, after update) {
    new PC_TriggerHandlerDispatcher().executeTriggers();
}