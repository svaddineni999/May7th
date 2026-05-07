/*********************************************************************************************************
Trigger Name    : PC_HealthPlan_Trigger
Description     : Trigger on PC_Health_Plan__c object. 
Created By      : Deloitte
Created Date    : May 17, 2016
Modification Log:
-------------------------------------------------------------------------------------------------------------- 
Developer                  Date                   Description
--------------------------------------------------------------------------------------------------------------            
Tetiana Danylyshyn        May 17, 2016             Initial Version
Prachi Nandgaonkar,       Nov 7, 2016              Implemented trigger handler framework PC-234
Shabda Bhujad
Mayuresh Patil            Aug 17,2017              PC-1898 added after insert and after update
Shabda Bhujad			  Sep 12,2017			   PC-2150 - Added all the contexts to make framework more flexible		
****************************************************************************************************************/
trigger PC_HealthPlan_Trigger on PC_Health_Plan__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    new PC_TriggerHandlerDispatcher().executeTriggers();
}