/*********************************************************************************************************
Trigger Name    : PC_OcrQueue_Trigger 
Description     : trigger on PC_OcrQueue__c object. 
Created By      : Deloitte
Created Date    : Apr 30, 2020
Modification Log:
-------------------------------------------------------------------------------------------------------------- 
Developer          Log#         Date                   Description
--------------------------------------------------------------------------------------------------------------            
Satheesh Kumar                Apr 30, 2020          Initial Version
****************************************************************************************************************/
trigger PC_OcrQueue_Trigger on PC_OcrQueue__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {    
   new PC_TriggerHandlerDispatcher().executeTriggers();
}