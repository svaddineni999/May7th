/*********************************************************************************************************
Trigger Name    : PC_Account_Trigger
Description     : Trigger on Account object. 
Created By      : Deloitte
Created Date    : May 17, 2016
Modification Log:
-------------------------------------------------------------------------------------------------------------- 
Developer                  Date                   Description
--------------------------------------------------------------------------------------------------------------            
Tetiana Danylyshyn        May 17, 2016             Initial Version
Prachi Nandgaonkar,       Oct 25, 2016             Implemented trigger handler framework PC-234
Shabda Bhujad
Prachi Nandgaonkar        Feb 20, 2017            Added system debug statements for checking governor limits
Shabda Bhujad			  Sep 12,2017			   PC-2150 - Added all the contexts to make framework more flexible	
****************************************************************************************************************/
trigger PC_Account_Trigger on Account (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    new PC_TriggerHandlerDispatcher().executeTriggers();
}