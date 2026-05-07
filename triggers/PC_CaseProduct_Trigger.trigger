/*********************************************************************************************************
Trigger Name    : PC_CaseProduct_Trigger
Description     : Trigger on PC_CaseProduct__c object. 
Created By      : Chetna Mohapatra
Created Date    : April 13, 2022
Modification Log:
-------------------------------------------------------------------------------------------------------------- 
Developer                  Date                   Description
--------------------------------------------------------------------------------------------------------------            
Chetna Mohapatra        April 13, 2022         Trigger handler framework for PC_CaseProduct__c
****************************************************************************************************************/
trigger PC_CaseProduct_Trigger on PC_CaseProduct__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    new PC_TriggerHandlerDispatcher().executeTriggers();
}