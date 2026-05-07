/*********************************************************************************************************
Trigger Name    : PC_OcrResult_Trigger
Description     : trigger on PC_OcrResult__c object.
Created By      : Deloitte
Created Date    : Nov 18, 2021
Modification Log:
-------------------------------------------------------------------------------------------------------------- 
Developer          Log#         Date                   Description
--------------------------------------------------------------------------------------------------------------            
Satheesh Kumar                Nov 18, 2021          Initial Version
****************************************************************************************************************/
trigger PC_OcrResult_Trigger on PC_OcrResult__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {    
   new PC_TriggerHandlerDispatcher().executeTriggers();
}