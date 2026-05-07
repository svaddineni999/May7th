/*********************************************************************************************************
Trigger Name    : PC_SupportPlanRuntime_Trigger
Description     : Trigger on PC_SupportPlanRuntime__c object. 
Created By      : Deloitte
Created Date    : March 2, 2018
Modification Log:
-------------------------------------------------------------------------------------------------------------- 
Developer                           Date                    Description
--------------------------------------------------------------------------------------------------------------            
Prachi Nandgaonkar      		   Jan 22, 2016           
****************************************************************************************************************/
trigger PC_SupportPlanRuntime_Trigger on PC_SupportPlanRuntime__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    new PC_TriggerHandlerDispatcher().executeTriggers();
}