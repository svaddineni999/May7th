/*********************************************************************************************************
Class Name      : PC_UpdateCloseDateOnTaskHandler
Description     : trigger on Task object.
Created By      : Deloitte
Created Date    : November 18, 2021
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer          Log#         Date                   Description
--------------------------------------------------------------------------------------------------------------
Hitha Avalakki                 18-Nov-2021           [PC-7950] Added method setProgramCaseOnTask() whenever a task record status is updated to 'Completed'
Hitha Avalakki                 22-Nov-2021           [PC-7950] Changed the reference from Datetime.now to System.now
****************************************************************************************************************/
public inherited sharing class PC_UpdateCloseDateOnTaskHandler extends PC_TriggerHandler {

    override public void beforeInsert() {
        setCloseDateOnTask((List< Task>) newList, (Map<Id, Task>) oldMap);
    }

    override public void beforeUpdate() {
        setCloseDateOnTask((List< Task>) newList, (Map<Id, Task>) oldMap);
    }

    /**************************************************************************************
    *   @Description : The method would set the close date of task record
    *   @Param       : newTaskList. Trigger new task list
    *   @Param       : oldCaseMap. Trigger old task map
    *   @Return      : Void
    ***************************************************************************************/
    private static void setCloseDateOnTask(List<Task> newTaskList, Map<Id, Task> oldTaskMap){
        try {
            for(Task task : newTaskList) {

                if (task.Status == PC_CONSTANTS.COMPLETED && oldTaskMap != null && oldTaskMap.get(task.Id).Status != PC_CONSTANTS.COMPLETED) {
                    task.PC_Close_Date__c = System.now();
                }
            }

        }
        catch (Exception e) {
            PC_Utility.createExceptionLog(e);
        }
    }
}