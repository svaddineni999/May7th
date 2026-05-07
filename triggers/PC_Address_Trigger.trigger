/*********************************************************************************************************
Trigger Name    : PC_Address_Trigger
Description     : Trigger on PC_Address__c object. 
Created By      : Deloitte
Created Date    : May 17, 2016
Modification Log:
-------------------------------------------------------------------------------------------------------------- 
Developer	               Date                   Description
--------------------------------------------------------------------------------------------------------------            
Tetiana Danylyshyn        May 17, 2016             Initial Version
Alina Balan               July 11, 2016            Added "before insert"
Prachi Nandgaonkar,       Nov 7, 2016             Implemented trigger handler framework PC-234
Shabda Bhujad
Shabda Bhujad			  Sep 12,2017			   PC-2150 - Added all the contexts to make framework more flexible
****************************************************************************************************************/

trigger PC_Address_Trigger on PC_Address__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
	//new PC_Trigger_Address().execute('PC_Address__c');
	new PC_TriggerHandlerDispatcher().executeTriggers(); 
}