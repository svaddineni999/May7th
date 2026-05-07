/*********************************************************************************************************
Trigger Name    : PC_Applicant_Trigger
Description     : Trigger on PC_Applicant__c object. 
Created By      : Tetiana Danylyshyn
Created Date    : June 1, 2016
Modification Log:
-------------------------------------------------------------------------------------------------------------- 
Developer                  Date                   Description
--------------------------------------------------------------------------------------------------------------            
Tetiana Danylyshyn      June 1, 2016             Initial Version
Prachi Nandgaonkar,     Nov 7, 2016              Implemented trigger handler framework PC-234
Shabda Bhujad
Prachi Nandgaonkar      Mar 16, 2017             Added 'before Insert' context [PC-1313]
Shabda Bhujad			Sep 12,2017			   	 PC-2150 - Added all the contexts to make framework more flexible
****************************************************************************************************************/
trigger PC_Applicant_Trigger on PC_Applicant__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    //new PC_Trigger_CandidatePatient().execute('PC_Applicant__c');
    new PC_TriggerHandlerDispatcher().executeTriggers(); 
}