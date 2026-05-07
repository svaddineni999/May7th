/*********************************************************************************************************
Trigger Name    : PC_Service_Trigger
Description     : Trigger on PC_Service__c object. 
Created By      : Deloitte
Created Date    : Jan 22, 2018
Modification Log:
-------------------------------------------------------------------------------------------------------------- 
Developer                  Date                   Description
--------------------------------------------------------------------------------------------------------------            
Tejas Patel       		   Jan 22, 2016           [PC-2649]Implemented trigger handler framework
****************************************************************************************************************/
trigger PC_Service_Trigger on PC_Service__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    new PC_TriggerHandlerDispatcher().executeTriggers();
}