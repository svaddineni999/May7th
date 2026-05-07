/*********************************************************************************
Class Name      : PC_CreateOcrDocumentQueueHelper
Description     : Action methods for Queuing Document to OCR (Support Plan Automation Task)
Created By      : Deloitte
Created Date    : 20-Oct-21
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   	Description
-----------------------------------------------------------------------------------
Satheesh Kumar            20-Oct-2021              Initial Version (PC-8235)
*********************************************************************************/

public with sharing class PC_CreateOcrDocumentQueueHelper implements PC_SupportPlan.Action2 {
    public PC_SupportPlan.PerformActionResult performAction(PC_Automation_Task__e automationTask) {
        String sourceId = automationTask.PC_SourceId__c;
        String taskConfiguration = automationTask.PC_TaskConfiguration__c;
        String taskID = automationTask.PC_TaskId__c;

        PC_SupportPlan.PerformActionResult result = new PC_SupportPlan.PerformActionResult();
        result.actionStatus = PC_SupportPlan.ActionStatus.IN_PROGRESS;
        result.errorMessage = PC_Constants.EMPTY_STRING;
        PC_OcrQueueUtil.Response response = new PC_OcrQueueUtil.Response();
        PC_OcrQueueUtil.OcrAutomationTaskSetting queueOcrJSON = new PC_OcrQueueUtil.OcrAutomationTaskSetting();
        try {
            if(String.isNotBlank(taskConfiguration)) {
                queueOcrJSON = (PC_OcrQueueUtil.OcrAutomationTaskSetting) System.JSON.deserialize(taskConfiguration, PC_OcrQueueUtil.OcrAutomationTaskSetting.class);
            }
            PC_OcrQueueUtil.Request queueRequest = new PC_OcrQueueUtil.Request();

            String objType = String.valueOf((Id.valueOf(sourceId)).getSobjectType());
            if (objType == PC_Constants.DOCUMENT_OBJECT) {
                queueRequest.documentId = sourceId;
            }
            queueRequest.templateTypeId = PC_OcrQueueUtil.getTemplateId(queueOcrJSON.templateTypeName);
            queueRequest.notifyOnCompletion = queueOcrJSON.notifyOnCompletion;
            response = PC_OcrQueueUtil.createOcrQueue(queueRequest, automationTask.PC_RunningUser__c);
            if (response.status == PC_Constants.SUCCESS) {
                result.actionStatus = PC_SupportPlan.ActionStatus.COMPLETED_SUCCESS;
            } else {
                result.actionStatus = PC_SupportPlan.ActionStatus.COMPLETED_FAILED;
                result.errorMessage = response.errorMessage;
            }
        } catch (Exception ex) {
            result.actionStatus = PC_SupportPlan.ActionStatus.COMPLETED_FAILED;
            result.errorMessage = JSON.serialize(ex.getStackTraceString());
            PC_Utility.createExceptionLog(ex);
        }
        return result;
    }
}