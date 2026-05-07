/*********************************************************************************************************
Trigger Name    : PC_Association_Trigger 
Description     : trigger on PC_Association object. 
Created By      : Deloitte
Created Date    : May 17, 2016
Modification Log:
-------------------------------------------------------------------------------------------------------------- 
Developer          Log#         Date                   Description
--------------------------------------------------------------------------------------------------------------            
Roxana Ivan                     May 17, 2016          Initial Version
Prachi Nandgaonkar,             Nov 7, 2016           Implemented trigger handler framework PC-234
Shabda Bhujad
Ajinkya Deshmukh				Jul 14, 2017		  Updated context variables
Shabda Bhujad			  		Sep 12,2017			  PC-2150 - Added all the contexts to make framework more flexible
****************************************************************************************************************/
trigger PC_Association_Trigger on PC_Association__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
     new PC_TriggerHandlerDispatcher().executeTriggers();
}