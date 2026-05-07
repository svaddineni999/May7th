/*********************************************************************************************************
Trigger Name    : PC_ReminderLog_Trigger
Description     : trigger on PC_ReminderLog__c object.
Created By      : Deloitte
Created Date    : June 18, 2021
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer          Log#         Date                   Description
--------------------------------------------------------------------------------------------------------------
Kanteti Kishore               June 18, 2021          Initial Version
***********************************************************************************************************/

trigger PC_ReminderLog_Trigger on PC_ReminderLog__c (before insert, before update, before delete, after insert, after update, after delete, after undelete){
    new PC_TriggerHandlerDispatcher().executeTriggers();
}