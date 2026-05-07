/*********************************************************************************************************
Trigger Name    : PC_Trigger_Pharmacy_Referral
Description     : Trigger handler class on Pharmacy Referral object to create a task on program case on referral creation (after insert). 
Created By      : Deloitte
Created Date    : Aug 8, 2017
Modification Log:
-------------------------------------------------------------------------------------------------------------- 
Developer                       Date                   Description
--------------------------------------------------------------------------------------------------------------            
Prachi Nandgaonkar              Aug 8, 2017            [PC-1730] Initial Version
Prachi Nandgaonkar              Aug 17, 2017           [PC-2061] Added specific record type for referral task creation
Prachi Nandgaonkar              Sept 1, 2017           [PC-2180] Changed task record type from Template to PSP
Ramtej Juloori                  Sept 19,2017           [PC-2174] Pharmacy Referral is allowing the user to create more than one active Referra
Ramtej Juloori                  Sept 21,2017           [PC-2174] Pharmacy Referral active code moved to PC_Trigger_Referral_ActiveCheck
Tejas Patel						Nov 8, 2017			   new custom label created System.Label.PC_Referral_Task_Subject;
Shabda Bhujad                   Nov 14, 2017           PC-2485 Removing the reference to trigger state
Xiukai Ning                     Feb 28, 2019           PC-3775 - Code review. FLS is NOT needed in Triggers, as they always run in System Mode.
                                                       Trigger delegate class (handler) that has with Sharing keyword however, will apply user sharing.
                                                       We are removing all FLS and With Sharing keywords in the handlers.
Satheesh Kumar                  Nov 16, 2021           [PC-8213] Excluded FLS Check and added inherited sharing
****************************************************************************************************************/
public inherited sharing class PC_Trigger_Referral_Task extends PC_TriggerHandler {

    override public void afterInsert(){
        createTask((List<PC_Pharmacy_Referral__c>)newList);
    }

    /*********************************************************************************
    Method Name    : createTask
    Author         : Prachi Nandgaonkar 
    Description    : This method  generates an activity on program case activity timeline about referral creation 
    Return Type    : void
    Parameter      : List of incoming Pharmacy Referral records - Trigger.new              
    *********************************************************************************/
    private void createTask(List<PC_Pharmacy_Referral__c> referrals) {
        String taskSubject = System.Label.PC_Referral_Task_Subject;
        List<Task> tasks  = new List<Task>();
        try {
            if(!referrals.isEmpty()){
                for(PC_Pharmacy_Referral__c eachReferral: referrals){
                    { 
                        Task t = new Task();
                        t.RecordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.PC_TASK, PC_Constants.PSP_TASK_RECORD_TYPE); //PC-2061 Creating a specific record type
                        t.WhatId = eachReferral.PC_Program__c; //create task on program case
                        t.PC_Pharmacy_Referral__c = eachReferral.Id;  //link the task to referral
                        t.Subject = taskSubject;
                        t.Status = PC_Constants.PC_STATUS_COMPLETED;  //Mark task as Completed
                        t.PC_Channel__c = PC_Constants.PC_TASK;
                        t.Priority = PC_Constants.PC_PRIORITY_NORMAL;
                        t.PC_Category__c = PC_Constants.PC_TASK_REF_CATEGORY;
                        t.PC_Sub_Category__c = PC_Constants.PC_TASK_SUBCATEGORY;
                        t.OwnerId = eachReferral.OwnerId; //Owner of referral
                        t.ActivityDate = Date.today();  //Date of referral creation
                        
                        tasks.add(t); 
                    } 
                    PC_Database.ins(tasks, false);  
                    
                }
            } 
        }catch(Exception ex) {
                PC_Utility.createExceptionLog(ex);
        }
    }

}