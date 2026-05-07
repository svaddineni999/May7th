/*********************************************************************************************************
Class Name      : PC_processTaskChangeHandler 
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
Shabda Bhujad,                 Nov 1, 2016           Removed Support Model references annotated by @@RemoveSupportModel  
Prachi Nandgaonkar
Shabda Bhujad,                 Nov 3, 2016           Removed General StartDate, Overdue Activities, Pending Activities, Support Model - Generate All, Parent Task  references annotated by @@RemoveGeneralStartDate, @@RemoveOverduePendingActivity, @@RemoveRecType, @@RemoveSupportModel, @@RemoveParentTask
Prachi Nandgaonkar
Prachi Nandgaonkar,            Nov 10, 2016          Renamed PC_Task_Subtype__c to PC_Channel__c
Shabda Bhujad
Prachi Nandgaonkar             Feb 20, 2017          Added system debug statements for checking governor limits
Prachi Nandgaonkar             March 2, 2017         Added updateIconsforTimeline() method to updated Task-SubType field used in activity timeline
Mayuresh Patil                 Apr 07, 2017          [PC-1369] Resolved blocker issue raised by force reviewer scanner tool. 
Shabda Bhujad                  June 02, 2017         [PC-1645] Added the null check for subcategory when Channel is null
Ajinkya Deshmukh               June 23, 2017         FLS Check Added (Code Merge), Removed unwarranted fields from soql
Mayuresh Patil                 Jul 26, 2017          Updated CRUD/FLS checks
Mayuresh Patil                 Aug 30, 2017          PC-2128 Resolved Merge issues FLS/CRUD
Shabda Bhujad                  Nov 14, 2017          PC-2485 Removing the reference to trigger state
Mike Klumpenaar                Nov 27, 2017          PC-2537 Fix null reference during insertion of completed task
Tejas Patel                    Dec 12, 2017          PC-2617 Check for Subject to be NULL before updating
Xiukai Ning                    Feb 28, 2019          PC-3775 - Code review. FLS is NOT needed in Triggers, as they always run in System Mode.
                                                     Trigger delegate class (handler) that has with Sharing keyword however, will apply user sharing.
                                                     We are removing all FLS and With Sharing keywords in the handlers.
Tushar Arora                   Jun 26, 2019          [PC-4894] Stop referencing Case.PC_Is_Program_Case__c and Account.PC_IsIndividual__c from code
Vijay Kashikar                 21-Jan-21             [PC-7102] Added FLS Checks
Hitha Avalakki                 19-Mar-2021           [PC-7533] Replaced constant CASE_PROGRAM_RECORD_TYPE_NAME to CASE_PROGRAM_TYPE
Vijay Kashikar                 16-Jul-2021           [PC-7792] Avoided overwriting of the task subject.
                                                     Updated subject concatenation logic when either/both channel & sub-category exists.
Satheesh Kumar                 Nov 16, 2021          [PC-8213] Excluded FLS Check and added inherited sharing
Hitha Avalakki                 18-Nov-2021           [PC-7950] Split the functionality of processTaskChanges() into three separate methods:setCloseDateOnTask() which has been moved to handler class:PC_UpdateCloseDateOnTaskHandler
                                                                current class handles: setSubjectLine() and setProgramCaseOnTask() has been defined in PC_UpdateProgramCaseOnTaskHandler class
****************************************************************************************************************/
public inherited sharing class PC_ProcessTaskChangeHandler extends PC_TriggerHandler {
    public static final String SUBJECT_KEY = 'Subject';

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
        try {

            /* Set the subject line on task record using category, sub-category and channel values */
            setSubjectLine(newTaskList,oldTaskMap);
        } 
        catch (Exception e) {
            PC_Utility.createExceptionLog(e);
        }
    }

    /**************************************************************************************
    *   @Description : The method would set the subject line of task record
    *   @Param       : newTaskList. Trigger new task list
    *   @Param       : oldCaseMap. Trigger old task map
    *   @Return      : Void
    ***************************************************************************************/
    private static void setSubjectLine(List<Task> newTaskList, Map<Id, Task> oldTaskMap){
        try {
            for(Task task : newTaskList) {

            //generate the task subject by concatenating the category and
            //if we have a taks category and if the old subject is null(insert) or the old category or subcategory differ from the new(update)
            //we can not have a subcategory without a category so the subject is either the concatenation of both of the category by itself
                if (task.PC_Category__c != null && (oldTaskMap == null || oldTaskMap.get(task.Id).PC_Category__c != task.PC_Category__c || oldTaskMap.get(task.Id).PC_Sub_Category__c != task.PC_Sub_Category__c)) {
                    if (task.PC_Sub_Category__c != null && task.PC_Channel__c != null) {
                        task.Subject = task.PC_Category__c + ' ' + task.PC_Sub_Category__c + ' ' + task.PC_Channel__c;
                    }
                    else if (task.PC_Channel__c == null && task.PC_Sub_Category__c != null) {
                        task.Subject = task.PC_Category__c + ' ' + task.PC_Sub_Category__c;
                    }
                    else if (task.PC_Channel__c != null && task.PC_Sub_Category__c == null) {
                        task.Subject = task.PC_Category__c + ' ' + task.PC_Channel__c;
                    }
                    else {
                        task.Subject = task.PC_Category__c;
                    }
                }
            }
        }
        catch (Exception e) {
            PC_Utility.createExceptionLog(e);
        }
    }

    /************************************************************************************** 
    *   @Description : Updates TaskSubType field on task based on PC_Task_Channel_Mapping__mdt
    *   @Param       : newTaskList. Trigger new task list 
    *   @Return      : Void 
    ***************************************************************************************/
    /*private void updateIconsforTimeline(List<Task> newTaskList) {
        Map<string,PC_Task_Channel_Mapping__mdt> taskTypeMappings = getTaskTypeMappings(); 
        String taskSubType;

        for(Task t : newTaskList) {
            taskSubType = t.PC_Channel__c;
            if(taskSubType != null && (taskTypeMappings != null && taskTypeMappings.size() > 0 && taskTypeMappings.containsKey(taskSubType))) {
                PC_Task_Channel_Mapping__mdt taskTypeMap = taskTypeMappings.get(taskSubType);
                t.PC_Channel__c = taskSubType;
            }
        }
    }*/
    
    /************************************************************************************** 
    *   @Description : Gets Task mapping from custom metadata PC_Task_Channel_Mapping__mdt that maps various channels to different task subtypes
    *   @Param       :  
    *   @Return      : Void 
    ***************************************************************************************/
    /*private static Map<string,PC_Task_Channel_Mapping__mdt> getTaskTypeMappings() {
        List<PC_Task_Channel_Mapping__mdt> mappingsList = [select ID, FROM__c, SUB__c, TO__c from PC_Task_Channel_Mapping__mdt LIMIT 1000];
        Map<string,PC_Task_Channel_Mapping__mdt> mappings = new Map<string,PC_Task_Channel_Mapping__mdt>();
        for(PC_Task_Channel_Mapping__mdt mapping : mappingsList) {
            mappings.put(mapping.FROM__c, mapping);
        }
        return mappings;
    }*/
}