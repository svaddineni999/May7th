/*********************************************************************************************************
Trigger Name    : PC_Document_Trigger
Description     : Trigger on PC_Document__c object. 
Created By      : Ajinkya Deshmukh
Created Date    : Jan 30, 2017
Modification Log:
-------------------------------------------------------------------------------------------------------------- 
Developer                  Date                   Description
--------------------------------------------------------------------------------------------------------------            
Ajinkya Deshmukh      		Jan 30, 2017			Initial Version
Ajinkya Deshmukh			Mar 30, 2017			Added after delete, after insert (PC-1053, PC-1345)
Shabda Bhujad			  	Sep 12,2017			   	PC-2150 - Added all the contexts to make framework more flexible
****************************************************************************************************************/
trigger PC_Document_Trigger on PC_Document__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    new PC_TriggerHandlerDispatcher().executeTriggers();
}