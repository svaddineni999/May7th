/*********************************************************************************************************
Trigger Name    : PC_SupportPlanActivity_Trigger
Description     : Trigger on Support Plan Activity custom object. 
Created By      : Prachi Nandgaonkar
Created Date    : March 6, 2018
Modification Log:
-------------------------------------------------------------------------------------------------------------- 
Developer                  Date                    Description
--------------------------------------------------------------------------------------------------------------            
Prachi Nandgaonkar        March 6, 2018            Initial version
****************************************************************************************************************/
trigger PC_SupportPlanActivity_Trigger on PC_SupportPlanActivity__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
	 new PC_TriggerHandlerDispatcher().executeTriggers(); 
}