/*********************************************************************************************************
Trigger Name    : PC_Case_Trigger 
Description     : trigger on Case object. 
Created By      : Deloitte
Created Date    : May 20, 2016
Modification Log:
-------------------------------------------------------------------------------------------------------------- 
Developer          Log#         Date                   Description
--------------------------------------------------------------------------------------------------------------            
Roxana Ivan                     May 20, 2016          Initial Version
Prachi Nandgaonkar,             Nov 7, 2016           Implemented trigger handler framework PC-234
Shabda Bhujad
Prachi Nandgaonkar              Feb 20, 2017          Added system debug statements for checking governor limits
Prachi Nandgaonkar              April 24, 2017        Cleaned up debug statements
Ajinkya Deshmukh				July 12, 2017		  context variable updated
Shabda Bhujad			  		Sep 12,2017			  PC-2150 - Added all the contexts to make framework more flexible
****************************************************************************************************************/
trigger PC_Case_Trigger on Case (before insert, before update, before delete, after insert, after update, after delete, after undelete) {    
 	new PC_TriggerHandlerDispatcher().executeTriggers();
}