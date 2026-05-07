/*********************************************************************************************************
Class Name      : PC_Trigger_Task 
Description     : trigger on Case object. 
Created By      : Deloitte
Created Date    : May 20, 2016
Modification Log:
-------------------------------------------------------------------------------------------------------------- 
Developer          Log#         Date                   Description
--------------------------------------------------------------------------------------------------------------            
Roxana Ivan                    May 20, 2016          Initial Version
Ajinkya Deshmukh               June 24, 2016         Added calculateTaskAcitivies method to update Task count on Cases
Vijay Kashikar                 June 29, 2016         Added methods to assign and set task subtype values based on custom metadata
Shabda Bhujad,                 Nov 1, 2016			 Removed Support Model references annotated by @@RemoveSupportModel  
Prachi Nandgaonkar
Shabda Bhujad,                 Nov 3, 2016			 Removed General StartDate, Overdue Activities, Pending Activities, Support Model - Generate All, Parent Task  references annotated by @@RemoveGeneralStartDate, @@RemoveOverduePendingActivity, @@RemoveRecType, @@RemoveSupportModel, @@RemoveParentTask
Prachi Nandgaonkar
Prachi Nandgaonkar,       	   Nov 10, 2016          Renamed PC_Task_Subtype__c to PC_Channel__c
Shabda Bhujad
Prachi Nandgaonkar             Feb 20, 2017          Added system debug statements for checking governor limits
Prachi Nandgaonkar             March 2, 2017         Added updateIconsforTimeline() method to updated Task-SubType field used in activity timeline
Mayuresh Patil                 Apr 07, 2017          [PC-1369] Resolved blocker issue raised by force reviewer scanner tool. 
Shabda Bhujad				   June 02, 2017		 [PC-1645] Added the null check for subcategory when Channel is null
Ajinkya Deshmukh			   June 23, 2017		 FLS Check Added (Code Merge), Removed unwarranted fields from soql
Mayuresh Patil                 Jul 26, 2017          Updated CRUD/FLS checks
Mayuresh Patil                 Aug 30, 2017          PC-2128 Resolved Merge issues FLS/CRUD
Shabda Bhujad                  Nov 14, 2017          PC-2485 Removing the reference to trigger state
Mike Klumpenaar                Nov 27, 2017          PC-2537 Fix null reference during insertion of completed task
Tejas Patel                    Dec 12, 2017          PC-2617 Check for Subject to be NULL before updating
Xiukai Ning                    Feb 28, 2019          PC-3775 - Code review. FLS is NOT needed in Triggers, as they always run in System Mode.
                                                     Trigger delegate class (handler) that has with Sharing keyword however, will apply user sharing.
                                                     We are removing all FLS and With Sharing keywords in the handlers.
Tushar Arora                   Jun 26, 2019          [PC-4894] Stop referencing Case.PC_Is_Program_Case__c and Account.PC_IsIndividual__c from code
Hitha Avalakki                 Mar 19, 2021          [PC-7533] Replaced constant CASE_PROGRAM_RECORD_TYPE_NAME to CASE_PROGRAM_TYPE
Satheesh Kumar                 Nov 16, 2021          [PC-8213] Excluded FLS Check and added inherited sharing
****************************************************************************************************************/
public inherited sharing class PC_Trigger_Task extends PC_TriggerHandler {

    override public void beforeInsert() {
        processTaskChanges((List< Task>) newList, (Map<Id, Task>) oldMap);
    }
    
    override public void beforeUpdate() {
        processTaskChanges((List< Task>) newList, (Map<Id, Task>) oldMap);
    }
    

	/************************************************************************************** 
	*   @Description : Process Task changes and update Program case
	*   @Param       : newTaskList. Trigger new task list 
	*   @Param       : oldCaseMap. Trigger old task map
	*   @Return      : Void 
	***************************************************************************************/
    private void processTaskChanges(List<Task> newTaskList, Map<Id, Task> oldTaskMap ) {
        Set<Id> lstRelatedObjects = new Set<Id>();
        try {
            for(Task task : newTaskList) {
                if (!lstRelatedObjects.contains(task.WhatId)) {
                    lstRelatedObjects.add(task.WhatId);
                }

                if (task.Status == PC_CONSTANTS.COMPLETED && oldTaskMap != null && oldTaskMap.get(task.Id).Status != PC_CONSTANTS.COMPLETED) {
                    task.PC_Close_Date__c = Datetime.now();
                }
                //generate the task subject by concatenating the category and 
                //if we have a taks category and if the old subject is null(insert) or the old category or subcategory differ from the new(update)
                //we can not have a subcategory without a category so the subject is either the concatenation of both of the category by itself
                if (task.PC_Category__c != null && task.Subject == null && (oldTaskMap == null || oldTaskMap.get(task.Id).PC_Category__c != task.PC_Category__c || oldTaskMap.get(task.Id).PC_Sub_Category__c != task.PC_Sub_Category__c)) {
                    if (task.PC_Category__c != null && task.PC_Sub_Category__c != null && task.PC_Channel__c != null) {
                        task.Subject = task.PC_Category__c + ' ' + task.PC_Sub_Category__c + ' ' + task.PC_Channel__c;
                    } else if (task.PC_Channel__c == null && task.PC_Sub_Category__c != null) { //[PC-1645] 
                        task.Subject = task.PC_Category__c + ' ' + task.PC_Sub_Category__c;
                    } else {
                        task.Subject = task.PC_Category__c;
                    }
                }
            } 

            Map<Id, Case> mapCases = new Map<Id, Case>([Select Id, PC_Program__c
                                      FROM Case WHERE Id in: lstRelatedObjects]);
            for(Task task : newTaskList) {
                if(mapCases.containsKey(task.WhatId)) {
                    Case relatedCase = mapCases.get(task.WhatId);
                    task.PC_Program__c = (relatedCase.Type == PC_Constants.CASE_PROGRAM_TYPE ? relatedCase.Id : relatedCase.PC_Program__c) ;
                }
            }
        } 
        catch (Exception e) {
            PC_Utility.createExceptionLog(e);
        }
    }
}