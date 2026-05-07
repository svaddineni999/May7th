/*********************************************************************************************************
Trigger Name    : PC_Order_Trigger
Description     : Trigger on Order object. 
Created By      : Tejas Patel
Created Date    : July 09, 2020
Modification Log:
-------------------------------------------------------------------------------------------------------------- 
Developer                  Date                   Description
--------------------------------------------------------------------------------------------------------------            
Tejas Patel        May 17, 2016             Initial Version
****************************************************************************************************************/
trigger PC_Order_Trigger on PC_Order__c(before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    new PC_TriggerHandlerDispatcher().executeTriggers();
}