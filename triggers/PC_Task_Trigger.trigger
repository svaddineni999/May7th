/*********************************************************************************************************
Trigger Name    : PC_Task_Trigger 
Description     : trigger on Task object. 
Created By      : Deloitte
Created Date    : May 20, 2016
Modification Log:
-------------------------------------------------------------------------------------------------------------- 
Developer          Log#         Date                   Description
--------------------------------------------------------------------------------------------------------------            
Roxana Ivan                     May 20, 2016          Initial Version
Prachi Nandgaonkar,				Nov 3, 2016           Removed Task sub sub type
Shabda Bhujad
Prachi Nandgaonkar,       		Nov 7, 2016           Implemented trigger handler framework PC-234
Shabda Bhujad
Prachi Nandgaonkar,       		Nov 10, 2016          Renamed PC_Task_Type_Mapping__mdt to PC_Task_Channel_Mapping__mdt, Renamed PC_Task_Subtype__c to PC_Channel__c
Shabda Bhujad
Prachi Nandgaonkar              Feb 20, 2017          Added system debug statements for checking governor limits
Prachi Nandgaonkar              March 2, 2017         Refactored code to move it to PC_Trigger_Task. Removed unnecessary contexts.
Mayuresh Patil                  Apr 07, 2017          [PC-1369] Resolved blocker issue raised by force reviewer scanner tool. 
Shabda Bhujad                   Sep 12,2017            PC-2150 - Added all the contexts to make framework more flexible
Tushar Arora					Apr 20,2021			   PC-7375 - Moved code to handler class
****************************************************************************************************************/
trigger PC_Task_Trigger on Task (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    new PC_TriggerHandlerDispatcher().executeTriggers();
}