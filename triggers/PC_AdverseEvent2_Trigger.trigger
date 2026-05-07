/*********************************************************************************************************
Trigger Name    : PC_AdverseEvent2_Trigger
Description     : Trigger on PC_AdverseEvent2__c object. 
Created By      : Tejas Patel
Created Date    : Jan 23, 2018
Modification Log:
-------------------------------------------------------------------------------------------------------------- 
Developer                  Date                   Description
--------------------------------------------------------------------------------------------------------------            
Tejas Patel                May 17, 2016             Initial Version
****************************************************************************************************************/

trigger PC_AdverseEvent2_Trigger on PC_AdverseEvent2__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    new PC_TriggerHandlerDispatcher().executeTriggers(); 
}