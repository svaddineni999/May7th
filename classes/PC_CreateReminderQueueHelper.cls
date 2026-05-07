/*********************************************************************************************************
Class Name    	: PC_CreateReminderQueueHelper
Description     : Helper for Creating Queue Reminder during the Support Plan Runtime
Created By      : Deloitte
Created Date    : May 10, 2021
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer                   Date                   Description
--------------------------------------------------------------------------------------------------------------
Kishore Kanteti             May 10, 2021           Initial Version
Kishore Kanteti             Sep 30, 2021           [PC-8176] Changes to support Action2 Interface instead of Action
Kishore Kanteti             Oct 12, 2021           [PC-8178] Changes to support Multiple Queues Creation for a record id
****************************************************************************************************************/

public with sharing class PC_CreateReminderQueueHelper implements PC_SupportPlan.Action2{

    private static final String TakeNoAction = 'TAKE_NO_ACTION';

    public PC_SupportPlan.PerformActionResult performAction(PC_Automation_Task__e automationTask) {
        String SourceId = automationTask.PC_SourceId__c;
        String taskConfiguration = automationTask.PC_TaskConfiguration__c;
        String taskID = automationTask.PC_TaskId__c;
        PC_SupportPlan.PerformActionResult result = new PC_SupportPlan.PerformActionResult();
        result.actionStatus = PC_SupportPlan.ActionStatus.IN_PROGRESS;
        result.errorMessage = PC_Constants.EMPTY_STRING;
        try{
            PC_ReminderQueueUtility.QueueReminderSetting queueReminderJSON = (PC_ReminderQueueUtility.QueueReminderSetting) System.JSON.deserialize(taskConfiguration, PC_ReminderQueueUtility.QueueReminderSetting.class);
            PC_ReminderQueueUtility.Request queueRequest = new PC_ReminderQueueUtility.Request();
            queueRequest.reminderSettingName = queueReminderJSON.reminderSettingName;
            if(queueReminderJSON.handleExistingQueueCriteria == TakeNoAction){
                queueRequest.queueCriteria = PC_ReminderQueueUtility.HandleExistingQueueCriteria.TAKE_NO_ACTION;
            }else{
                queueRequest.queueCriteria = PC_ReminderQueueUtility.HandleExistingQueueCriteria.DEACTIVATE_AND_CREATE_NEW;
            }
            queueRequest.recordId = SourceId;
            PC_ReminderQueueUtility.Response response = PC_ReminderQueueUtility.queueReminder(queueRequest);
            if(response.status == PC_Constants.SUCCESS){
                if(!response.queueRecordIds.isEmpty()){
                    Task supportPlanTask = new Task();
                    List<PC_ReminderQueue__c> queuedRecords = new List<PC_ReminderQueue__c>();

                    //FLS Check for Task Fields
                    List<String> taskFields = new List<String>{'Id',PC_Constants.getQualifiedAPIName('PC_SupportPlanActivity__c')};
                    PC_Database.assertAccess(PC_Constants.PC_TASK, PC_Database.Operation.Reading, taskFields);

                    supportPlanTask = [SELECT Id, PC_SupportPlanActivity__c FROM Task WHERE Id =: taskId LIMIT 1];

                    queuedRecords = [SELECT Id, PC_SupportPlanActivity__c FROM PC_ReminderQueue__c WHERE Id IN: response.queueRecordIds];
                    for(PC_ReminderQueue__c queuedRecord : queuedRecords){
                        queuedRecord.PC_SupportPlanActivity__c = supportPlanTask != null ? supportPlanTask.PC_SupportPlanActivity__c : '';
                    }
                    PC_Database.upd(queuedRecords, true);
                }
                result.actionStatus = PC_SupportPlan.ActionStatus.COMPLETED_SUCCESS;
            }else{
                result.actionStatus = PC_SupportPlan.ActionStatus.COMPLETED_FAILED;
                result.errorMessage = response.errorMessage;
            }
        }catch(Exception ex){
            result.actionStatus = PC_SupportPlan.ActionStatus.COMPLETED_FAILED;
            result.errorMessage = JSON.serialize(ex.getStackTraceString());
            PC_Utility.createExceptionLog(ex);
        }
        return result;
    }
}