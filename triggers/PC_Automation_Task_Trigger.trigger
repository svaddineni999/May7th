/*********************************************************************************************************
Trigger Name    : PC_Automation_Task_Trigger
Description     : Trigger on PC_Automation_Task__e Platform Event.
Created By      : Deloitte
Created Date    : Nov 23, 2018
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer                  Date                   Description
--------------------------------------------------------------------------------------------------------------
Tejas Patel                Nov 23, 2018           Initial Version
Tejas Patel                Oct 9, 2019            PC-5497 Retrying failed platform event only 9 times before logging an error
Haritha Reddy              Apr 10, 2020           PC-6033 Added logic for Create Record and Publish Platform event Actions
Haritha Reddy              Aug 21, 2020           [PC-6719] Enhanced Error handling and Platform Event processing
Haritha Reddy              Nov 04, 2020           [PC-6946] Passing new parameter to insert error task
Haritha Reddy              Mar 21, 2021           [PC-7010] Made changes to process PC_Automation_Task only if the corresponding handler
                                                  is active in Trigger handler register
Kishore Kanteti            Sep 17, 2021           [PC-8127] Made changes so that Action2 interface is supported for Automation Task
                                                  custom components
Kishore Kanteti            Sep 28, 2021           [PC-8177] Made changes so that additional comments are added to Task Description
****************************************************************************************************************/
trigger PC_Automation_Task_Trigger on PC_Automation_Task__e (after insert) {
    List<PC_TriggerHandlerRegister__mdt> trigglerHandlerList = PC_SYSTEM.getTriggerHandlerRegisters(PC_Constants.PC_AUTOMATION_TASK_HANDLER,PC_Constants.PC_AUTOMATION_TASK,null);

    if(!trigglerHandlerList.isEmpty() && trigglerHandlerList != null && trigglerHandlerList.size()>0) {
        List<PC_Automation_Task__e> allPlatformEvents = Trigger.New;
        List<Task> toUpdateTaskList = new List<Task>();
        Map<Id, PC_SupportPlan.PerformActionResult> returnedTaskMap = new Map<Id, PC_SupportPlan.PerformActionResult>();
        String whatId = null;
        String runningUserId = null;
        String automationTaskJSON = null;
        String supportPlanActivityId = null;
        try {
            Integer counter = 0;
            for (PC_Automation_Task__e a : allPlatformEvents) {
                system.debug('Automation Task >> ' + a);
                //Execute one Platform Event at a time using Counter
                if (counter > 0) {
                    // Resume after the last successfully processed event message after the trigger stops running. Exit for loop.
                    break;
                }
                // Set Replay ID after which to resume event processing in new trigger execution.
                EventBus.TriggerContext.currentContext().setResumeCheckpoint(a.ReplayId);

                whatId = a.PC_SourceId__c;
                runningUserId = a.PC_RunningUser__c;
                automationTaskJSON = a.PC_TaskConfiguration__c;
                supportPlanActivityId = a.PC_SupportPlanActivityId__c;

                // Process Automation Task
                PC_SupportPlan.PerformActionResult result = new PC_SupportPlan.PerformActionResult();
                String actionClassName = a.PC_ActionClass__c;

                if (String.isNotBlank(actionClassName)) {
                    Type t = Type.forName(actionClassName);
                    if (t != null) {
                        Object o = t.newInstance();
                        if (o instanceof PC_SupportPlan.Action2) {
                            try {
                                PC_SupportPlan.Action2 actionClass = (PC_SupportPlan.Action2) o;
                                result = actionClass.performAction(a);
                            } catch (Exception ex) {
                                result.actionStatus = PC_SupportPlan.ActionStatus.COMPLETED_FAILED;
                                result.errorMessage = JSON.serialize(ex.getMessage() + ' ' + ex.getStackTraceString());
                                //Not logging the error here as we are already doing it in PC_CreateRecordAutomationTask
                            }
                            if (a.PC_AutomationTaskType__c == PC_Constants.SUPPORTPLAN_ACTIVITY_TYPE_CREATE_RECORD ||
                                    a.PC_AutomationTaskType__c == PC_Constants.SUPPORTPLAN_ACTIVITY_TYPE_PUBLISH_PLATFORM_EVENT ||
                                    a.PC_AutomationTaskType__c == PC_Constants.SUPPORTPLAN_ACTIVITY_TYPE_UPDATE_RECORD) {
                                String taskId = PC_AutomationTaskHelper.createOutcomeTask(a, result);
                                PC_AutomationTaskHelper.createSupportPlanActivityLog(a, result, taskId);
                            }else{
                                returnedTaskMap.put((Id) Id.valueOf(a.PC_TaskId__c), result);
                                PC_AutomationTaskHelper.createSupportPlanActivityLog(a, result, a.PC_TaskId__c);
                            }
                        }else if(o instanceof PC_SupportPlan.Action) {
                            try {
                                PC_SupportPlan.Action actionClass = (PC_SupportPlan.Action) o;
                                result = actionClass.performAction(a.PC_Source__c, a.PC_SourceId__c, a.PC_TaskConfiguration__c, a.PC_TaskId__c);
                            } catch (Exception ex) {
                                result.actionStatus = PC_SupportPlan.ActionStatus.COMPLETED_FAILED;
                                result.errorMessage = JSON.serialize(ex.getMessage() + ' ' + ex.getStackTraceString());
                                PC_Utility.createExceptionLog(ex);
                            }
                            returnedTaskMap.put((Id) Id.valueOf(a.PC_TaskId__c), result);
                            PC_AutomationTaskHelper.createSupportPlanActivityLog(a, result, a.PC_TaskId__c);
                        }else{
                            PC_AutomationTaskHelper.AutomationTask_Exception automationTaskException = new PC_AutomationTaskHelper.AutomationTask_Exception();
                            automationTaskException.setMessage(Label.PC_SupportPlan_ActionClassErrorMessage);
                            throw automationTaskException;
                        }
                    }
                }
                // Increase batch counter.
                counter++;
            }

            // Process Automation Task
            if (!returnedTaskMap.isEmpty()) {
                Map<Id, Task> returnedTaskList = new Map<Id, Task>([SELECT Id, Status, Description FROM Task WHERE Id IN :returnedTaskMap.keySet()]);
                if (!returnedTaskList.isEmpty()) {
                    for (Id t : returnedTaskMap.keySet()) {
                        Task ts = returnedTaskList.get(t);
                        if (returnedTaskMap.get(t).actionStatus == PC_SupportPlan.ActionStatus.COMPLETED_SUCCESS) {
                            ts.Status = PC_Constants.PC_STATUS_COMPLETED;
                        } else if (returnedTaskMap.get(t).actionStatus == PC_SupportPlan.ActionStatus.COMPLETED_FAILED) {
                            ts.Status = PC_Constants.PC_TASK_STATUS_WAITING;
                            ts.Description = returnedTaskMap.get(t).errorMessage;
                        } else if (returnedTaskMap.get(t).actionStatus == PC_SupportPlan.ActionStatus.IN_PROGRESS) {
                            ts.Status = PC_Constants.SUPPORTPLAN_TASK_STATUS_INPROGRESS;
                        }
                        if(String.isNotBlank(returnedTaskMap.get(t).additionalComments)){
                            ts.Description = String.isNotBlank(ts.Description) ? ts.Description + returnedTaskMap.get(t).additionalComments : returnedTaskMap.get(t).additionalComments;
                        }
                        toUpdateTaskList.add(ts);
                    }

                    if (toUpdateTaskList.size() > 0) {
                        PC_Database.upd(toUpdateTaskList);
                    }
                }
            }
        } catch (Exception ex) {
            List<Object> formattingArguments = new List<Object>{
                    automationTaskJSON
            };
            String errorDescription = String.format(Label.PC_AutomationTask_ErrorInfo, formattingArguments) + ' ' + Label.PC_SupportPlan_ErrorMessageTitle + ' ' + ex.getMessage() + ' ' + ex.getStackTraceString();
            //Create Error Log with error details
            PC_Utility.publishErrorLog(ex, errorDescription);
            //Create error task and assign it to Running User to take further action
            PC_SupportPlanEngine.createErrorTask(true, whatId, runningUserId, errorDescription, supportPlanActivityId);
        }
    }else{
        System.debug('Trigger Handler Register not found for sObject '+PC_Constants.PC_AUTOMATION_TASK);
    }
}