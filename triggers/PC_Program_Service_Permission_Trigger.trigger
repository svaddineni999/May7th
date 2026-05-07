/*********************************************************************************************************
Trigger Name    : PC_Program_Service_Permission_Trigger
Description     : Trigger on PC_Program_Service_Permission__c object. 
Created By      : Tejas Patel
Created Date    : May 23, 2017
Modification Log:
-------------------------------------------------------------------------------------------------------------- 
Developer                  Date                   Description
--------------------------------------------------------------------------------------------------------------            
Tejas Patel      		  May 23, 2017             Initial Version
Shabda Bhujad			  Sep 12,2017			   PC-2150 - Added all the contexts to make framework more flexible
****************************************************************************************************************/
trigger PC_Program_Service_Permission_Trigger on PC_Program_Service_Permission__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
	new PC_TriggerHandlerDispatcher().executeTriggers(); 
}