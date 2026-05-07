/*********************************************************************************************************
Trigger Name    : PC_Request_Form_Trigger
Description     : Trigger on PC_Request_Form__c object. 
Created By      : Deloitte
Created Date    : Jan 22, 2018
Modification Log:
-------------------------------------------------------------------------------------------------------------- 
Developer                  Date                   Description
--------------------------------------------------------------------------------------------------------------            
Tejas Patel       		   Jan 22, 2016           [PC-2649]Implemented trigger handler framework
****************************************************************************************************************/
trigger PC_Request_Form_Trigger on PC_Request_Form__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    new PC_TriggerHandlerDispatcher().executeTriggers();
}