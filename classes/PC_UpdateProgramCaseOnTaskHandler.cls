/*********************************************************************************************************
Class Name      : PC_UpdateProgramCaseOnTaskHandler
Description     : trigger on Task object.
Created By      : Deloitte
Created Date    : November 18, 2021
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer          Log#         Date                   Description
--------------------------------------------------------------------------------------------------------------
Hitha Avalakki                 18-Nov-2021           [PC-7950] Added method setCloseDateOnTask() whenever a task record 'Related To' field is updated
****************************************************************************************************************/

public with sharing class PC_UpdateProgramCaseOnTaskHandler extends PC_TriggerHandler {

    override public void beforeInsert() {
        setProgramCaseOnTask((List< Task>) newList, (Map<Id, Task>) oldMap);
    }

    override public void beforeUpdate() {
        setProgramCaseOnTask((List< Task>) newList, (Map<Id, Task>) oldMap);
    }

    /**************************************************************************************
    *   @Description : The method would set the program case on task record
    *   @Param       : newTaskList. Trigger new task list
    *   @Param       : oldCaseMap. Trigger old task map
    *   @Return      : Void
    ***************************************************************************************/
    private static void setProgramCaseOnTask(List<Task> newTaskList, Map<Id, Task> oldTaskMap){
        Set<Id> lstRelatedObjects = new Set<Id>();

        try {
            for(Task task : newTaskList) {
                if (!lstRelatedObjects.contains(task.WhatId)) {
                    lstRelatedObjects.add(task.WhatId);
                }
            }

            //FLS is NOT needed in Triggers, as they always run in System Mode.
            /* List<String> caseFields = new List<String>();
            caseFields.add(PC_Constants.getQualifiedAPIName('PC_Program__c'));
            PC_Database.assertAccess(PC_Constants.PC_CASE, PC_Database.Operation.Reading, caseFields); */
            Map<Id, Case> mapCases = new Map<Id, Case>([Select Id, Type, PC_Program__c
            FROM Case WHERE Id in: lstRelatedObjects]);
            for(Task task : newTaskList) {
                if(mapCases.containsKey(task.WhatId)) {
                    Case relatedCase = mapCases.get(task.WhatId);
                    task.PC_Program__c = relatedCase.Type == PC_Constants.CASE_PROGRAM_TYPE ? relatedCase.Id : relatedCase.PC_Program__c ;
                }
            }
        }
        catch (Exception e) {
            PC_Utility.createExceptionLog(e);
        }
    }
}