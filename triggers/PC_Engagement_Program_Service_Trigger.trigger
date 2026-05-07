/*********************************************************************************************************
Trigger Name    : PC_Engagement_Program_Service_Trigger
Description     : Trigger on PC_Engagement_Program_Service__c object. 
Created By      : Tejas Patel
Created Date    : Jan 23, 2018
Modification Log:
-------------------------------------------------------------------------------------------------------------- 
Developer	               Date                   Description
--------------------------------------------------------------------------------------------------------------            
Tejas Patel			       May 17, 2016             Initial Version
****************************************************************************************************************/

trigger PC_Engagement_Program_Service_Trigger on PC_Engagement_Program_Service__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
	new PC_TriggerHandlerDispatcher().executeTriggers(); 
}