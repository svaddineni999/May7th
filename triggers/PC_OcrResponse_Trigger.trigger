/*********************************************************************************************************
Trigger Name    : PC_OcrResponse_Trigger
Description     : trigger on PC_OcrResponse__c object. 
Created By      : Deloitte
Created Date    : May 03, 2020
Modification Log:
-------------------------------------------------------------------------------------------------------------- 
Developer          Log#         Date                   Description
--------------------------------------------------------------------------------------------------------------            
Satheesh Kumar                May 03, 2020          Initial Version
****************************************************************************************************************/
trigger PC_OcrResponse_Trigger on PC_OcrResponse__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {    
   new PC_TriggerHandlerDispatcher().executeTriggers();
}