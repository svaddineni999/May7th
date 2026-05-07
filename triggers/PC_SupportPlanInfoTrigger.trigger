/*********************************************************************************************************
Trigger Name    : PC_SupportPlanInfo_Trigger
Description     : Trigger on PC_SupportPlanInfo__e Platform Event.
Created By      : Haritha Reddy
Created Date    : Mar 17, 2020
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer                  Date                   Description
--------------------------------------------------------------------------------------------------------------
Haritha Reddy               Mar 17, 2020           Initial Version
Haritha Reddy               Aug 21, 2020           [PC-6719] Enhanced Error handling and Platform Event processing
Haritha Reddy               Oct 06, 2020           [PC-6792] Modified Support Plan execution logic to stop executing in Recursive Scenario.
Haritha Reddy               Oct 13, 2020           [PC-6792] Modified code for fixing issues shown in Force reviewer scan report
Haritha Reddy               Nov 04, 2020           [PC-6946] Passing new parameter to insert error task
Haritha Reddy               Nov 13, 2020           [PC-6822] Moved the logic to trigger handler
Haritha Reddy              Mar 21, 2021            [PC-7010] Made changes to process PC_SupportPlanInfo__e only if the corresponding handler
                                                   is active in Trigger handler register. Moved process logic that is in handler back to trigger
                                                   since Retryable Exception method is not working when processing logic is in separate handler.
****************************************************************************************************************/
trigger PC_SupportPlanInfoTrigger on PC_SupportPlanInfo__e (after insert) {

    List<PC_TriggerHandlerRegister__mdt> trigglerHandlerList = PC_SYSTEM.getTriggerHandlerRegisters(PC_Constants.PC_SUPPORT_PLAN_INFO_HANDLER,PC_Constants.PC_SUPPORT_PLAN_INFO,null);

    if(!trigglerHandlerList.isEmpty() && trigglerHandlerList != null && trigglerHandlerList.size()>0) {
        List<PC_SupportPlanInfo__e> allSupportPlanInfoList = Trigger.New;
        String whatId = null;
        String runningUserId = null;
        String context = null;
        String supportPlanOrRuntimeIds = null;
        try {
            Integer counter = 0;
            List<PC_SupportPlanInfo__e> supportPlanInfosToEvaluateRuleCriteria = new List<PC_SupportPlanInfo__e>();
            List<PC_SupportPlanInfo__e> supportPlanInfosToExecuteActions = new List<PC_SupportPlanInfo__e>();
            List<PC_SupportPlanInfo__e> supportPlanInfosToProcessSPRTs = new List<PC_SupportPlanInfo__e>();
            for (PC_SupportPlanInfo__e supportPlanEvent : allSupportPlanInfoList) {//This is added for debugging
                system.debug('supportPlanEvent>> ' + supportPlanEvent);
            }

            for (PC_SupportPlanInfo__e supportPlanEvent : allSupportPlanInfoList) {

                //Execute one Platform Event at a time using Counter
                if (counter > 0) {
                    // Resume after the last successfully processed event message after the trigger stops running. Exit for loop.
                    system.debug('recordId >> ' + supportPlanEvent.PC_RecordId__c);
                    system.debug('supportPlan/RuntimeId >> ' + supportPlanEvent.PC_SupportPlanOrRuntimeIds__c);
                    break;
                }
                // Set Replay ID after which to resume event processing in new trigger execution.
                EventBus.TriggerContext.currentContext().setResumeCheckpoint(supportPlanEvent.ReplayId);
                system.debug('Resume checkpoint is done**');

                whatId = supportPlanEvent.PC_RecordId__c;
                runningUserId = supportPlanEvent.PC_RuntimeUserId__c;
                context = supportPlanEvent.PC_Context__c;
                supportPlanOrRuntimeIds = supportPlanEvent.PC_SupportPlanOrRuntimeIds__c;
                system.debug('supportPlanEvent>> ' + supportPlanEvent);

                // Process Support Plan Info
                if (supportPlanEvent.PC_Context__c == String.valueOf(PC_Constants.SupportPlanInfoContext.EvaluateRuleCriteria)) {
                    supportPlanInfosToEvaluateRuleCriteria.add(supportPlanEvent);
                } else if (supportPlanEvent.PC_Context__c == String.valueOf(PC_Constants.SupportPlanInfoContext.ExecuteActions)) {
                    supportPlanInfosToExecuteActions.add(supportPlanEvent);
                } else if (supportPlanEvent.PC_Context__c == String.valueOf(PC_Constants.SupportPlanInfoContext.ProcessSupportPlanRuntimes)) {
                    supportPlanInfosToProcessSPRTs.add(supportPlanEvent);
                }
                // Increase batch counter.
                counter++;
            }
            // Process Support Plan Info
            if (!supportPlanInfosToEvaluateRuleCriteria.isEmpty() && PC_SupportPlanEngine.isSupportPlanInitiationHandlerActive(supportPlanInfosToEvaluateRuleCriteria[0])) {
                List<PC_SupportPlanEngine.SupportPlanInfo> supportPlanInfoList = PC_SupportPlanEngine.getRecordsMatchingSupportPlanCriteria(supportPlanInfosToEvaluateRuleCriteria);
                if (!supportPlanInfoList.isEmpty()) {
                    PC_SupportPlanEngine.publishSupportPlanPlatformEvent(supportPlanInfoList);
                    system.debug('Publishing Platform Event for executing Actions**');
                }
            }
            if (!supportPlanInfosToExecuteActions.isEmpty() && PC_SupportPlanEngine.isSupportPlanInitiationHandlerActive(supportPlanInfosToExecuteActions[0])) {
                Map<Id, PC_SupportPlanInfo__e> newSupportPlanRuntimeMap = PC_SupportPlanEngine.createSupportPlanRuntimes(supportPlanInfosToExecuteActions);
                if (!newSupportPlanRuntimeMap.isEmpty()) {
                    PC_SupportPlanEngine.processSupportPlanRuntimes(newSupportPlanRuntimeMap);
                    system.debug('Executing Actions**');
                }
            }
            if (!supportPlanInfosToProcessSPRTs.isEmpty() && PC_SupportPlanEngine.isSupportPlanInitiationHandlerActive(supportPlanInfosToProcessSPRTs[0])) {
                Map<Id, PC_SupportPlanInfo__e> supportPlanRuntimeMap = new Map<Id, PC_SupportPlanInfo__e>();
                for (PC_SupportPlanInfo__e supportPlanInfo : supportPlanInfosToProcessSPRTs) {
                    supportPlanRuntimeMap.put(supportPlanInfo.PC_SupportPlanOrRuntimeIds__c, supportPlanInfo);
                }
                if (!supportPlanRuntimeMap.isEmpty()) {
                    PC_SupportPlanEngine.processSupportPlanRuntimes(supportPlanRuntimeMap);
                    system.debug('Processing Support Plan Runtimes: Next/Pending**');
                }
            }
        } catch (Exception ex) {
            system.debug('Error>>  ' + ex.getMessage());
            List<Object> formattingArguments = new List<Object>{
                    context, supportPlanOrRuntimeIds
            };
            String additionalInfo = String.format(Label.PC_SPInfo_ErrorAdditionalInfo, formattingArguments);

            //Create Error Log with error details
            PC_Utility.publishErrorLog(ex, additionalInfo);

            //Create error task and assign it to Running User to take further action
            String errorDescription = additionalInfo + ' ' + Label.PC_SupportPlan_ErrorMessageTitle + ' ' + ex.getMessage() + ' ' + ex.getStackTraceString();
            PC_SupportPlanEngine.createErrorTask(true, whatId, runningUserId, errorDescription, null);
        }
    }else{
        System.debug('Trigger Handler Register not found for sObject '+PC_Constants.PC_SUPPORT_PLAN_INFO);
    }
}