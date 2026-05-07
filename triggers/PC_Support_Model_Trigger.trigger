/*********************************************************************************************************
Trigger Name    : PC_Support_Model_Trigger
Description     : Trigger on PC_Support_Model__c object. 
Created By      : Deloitte
Created Date    : Jan 22, 2018
Modification Log:
-------------------------------------------------------------------------------------------------------------- 
Developer                  Date                   Description
--------------------------------------------------------------------------------------------------------------            
Tejas Patel       		   Jan 22, 2016           [PC-2649]Implemented trigger handler framework
****************************************************************************************************************/
trigger PC_Support_Model_Trigger on PC_Support_Model__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    new PC_TriggerHandlerDispatcher().executeTriggers();
}