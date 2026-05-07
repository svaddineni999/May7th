/*********************************************************************************************************
Trigger Name    : PC_Interaction_Trigger
Description     : Trigger on PC_Interaction__c object. 
Created By      : Deloitte
Created Date    : Jan 22, 2018
Modification Log:
-------------------------------------------------------------------------------------------------------------- 
Developer                  Date                   Description
--------------------------------------------------------------------------------------------------------------            
Prachi Nandgaonkar       Jan 22, 2016            [PC-2649]Implemented trigger handler framework
****************************************************************************************************************/
trigger PC_Interaction_Trigger on PC_Interaction__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    new PC_TriggerHandlerDispatcher().executeTriggers();
}