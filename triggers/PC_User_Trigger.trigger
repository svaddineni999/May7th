/*********************************************************************************************************
Trigger Name    : PC_User_Trigger 
Description     : trigger on Userobject. 
Created By      : Deloitte
Created Date    : Apr 18, 2022
Modification Log:
-------------------------------------------------------------------------------------------------------------- 
Developer          Log#         Date                   Description
--------------------------------------------------------------------------------------------------------------            
Satheesh Kumar                 May 20, 2016          Initial Version
****************************************************************************************************************/
trigger PC_User_Trigger on User (before insert, before update, before delete, after insert, after update, after delete, after undelete) {    
   new PC_TriggerHandlerDispatcher().executeTriggers();
}