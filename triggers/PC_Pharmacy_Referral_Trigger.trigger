/*********************************************************************************************************
Trigger Name    : PC_Pharmacy_Referral_Trigger
Description     : Trigger on Pharmacy Referral object. 
Created By      : Deloitte
Created Date    : Aug 8, 2017
Modification Log:
-------------------------------------------------------------------------------------------------------------- 
Developer                  Date                   Description
--------------------------------------------------------------------------------------------------------------            
Prachi Nandgaonkar        Aug 8, 2017            Initial version
Shabda Bhujad			 Sep 12,2017			PC-2150 - Added all the contexts to make framework more flexible
****************************************************************************************************************/
trigger PC_Pharmacy_Referral_Trigger on PC_Pharmacy_Referral__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
	 new PC_TriggerHandlerDispatcher().executeTriggers(); 
}