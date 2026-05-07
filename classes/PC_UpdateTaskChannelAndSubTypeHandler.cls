/*********************************************************************************************************
Class Name      : PC_UpdateTaskChannelAndSubTypeHandler
Description     : trigger on Task object to update Task Channel field and Task Sub-Type
Created By      : Tushar Arora
Created Date    : Apr 20, 2021
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer                   Date                    Description
--------------------------------------------------------------------------------------------------------------
Tushar Arora                Apr 20, 2021            Initial Version
Satheesh Kumar              Nov 16, 2021            [PC-8213] Excluded FLS Check and added inherited sharing
****************************************************************************************************************/
public inherited sharing class PC_UpdateTaskChannelAndSubTypeHandler extends PC_TriggerHandler {
    /******************************************************************************
    * With Sharing is not needed here as this code runs under Trigger Context
    * ****************************************************************************/
    override public void beforeInsert(){
        updateTaskChannelAndSubType((List<Task>) newList);
    }

    /**************************************************************************************
    *   @Description : Updates TaskSubType field on task based on PC_Task_Channel_Mapping__mdt
    *   @Param       : newTaskList. Trigger new task list
    *   @Return      : Void
    ***************************************************************************************/
    private void updateTaskChannelAndSubType(List<Task> newTaskList) {
        Map<string,PC_Task_Channel_Mapping__mdt> taskTypeMappings = getTaskTypeMappings();
        String taskSubType;
        for(Task t : newTaskList) {
            taskSubType = t.PC_Channel__c;
            if(taskSubType != null && (taskTypeMappings != null && taskTypeMappings.size() > 0 && taskTypeMappings.containsKey(taskSubType))) {
                PC_Task_Channel_Mapping__mdt taskTypeMap = taskTypeMappings.get(taskSubType);
                t.PC_Channel__c = taskSubType;
                t.TaskSubtype = taskTypeMap.TO__c;
            }
        }
    }

    /**************************************************************************************
    *   @Description : Gets Task mapping from custom metadata PC_Task_Channel_Mapping__mdt that maps various channels to different task subtypes
    *   @Param       :
    *   @Return      : Void
    ***************************************************************************************/
    private static Map<string,PC_Task_Channel_Mapping__mdt> getTaskTypeMappings() {
        List<PC_Task_Channel_Mapping__mdt> mappingsList = [select ID, FROM__c, SUB__c, TO__c from PC_Task_Channel_Mapping__mdt LIMIT 1000];
        Map<string,PC_Task_Channel_Mapping__mdt> mappings = new Map<string,PC_Task_Channel_Mapping__mdt>();
        for(PC_Task_Channel_Mapping__mdt mapping : mappingsList) {
            mappings.put(mapping.FROM__c, mapping);
        }
        return mappings;
    }
}