/**************************************************************************************************************************************************************************
Class Name      : PC_SPPharmacyBenefitsInvestigation
Description     : This is the SP Automation Task Action Class For Pharmacy BI.
Created By      : Satheesh Kumar & Chetna Mohapatra
Created Date    : 01-Mar-2022
Modification Log:
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Developer                   Date                  Description
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Chetna Mohapatra
& Satheesh Kumar        01-Mar-2022             Initial Version
Satheesh Kumar          12-Oct-2022             [PC-9262] Added condition to avoid removing namespace prefix from sObject when sobject contains no namespace.
 **********************************************************************************************************************************************************************/
public with sharing class PC_SPPharmacyBenefitsInvestigation implements PC_SupportPlan.Action2 {
    private static PC_SupportPlan.PerformActionResult result = new PC_SupportPlan.PerformActionResult();

    public PC_SupportPlan.PerformActionResult performAction(PC_Automation_Task__e automationTask) {
        String source = automationTask.PC_Source__c;
        //remove namespace prefix from sObject when sobject contains namespace
        source = source.contains('__') ? (source.countMatches('__') == 2 ? source.substringAfter('__') : source): source;
        String sourceId = automationTask.PC_SourceId__c;
        String taskConfiguration = automationTask.PC_TaskConfiguration__c;
        String taskID = automationTask.PC_TaskId__c;
        try {
            result.actionStatus = PC_SupportPlan.ActionStatus.IN_PROGRESS;
            result.errorMessage = PC_Constants.EMPTY_STRING;
            if (source.equalsIgnoreCase(PC_Constants.PC_CASE) || source.equalsIgnoreCase(PC_Constants.PC_ACCOUNT) || source.equalsIgnoreCase(PC_Constants.PC_CASEPRODUCT) && sourceId != null) {
                doPharmacyEbenefitsCallout(sourceId, taskID);//Callout
            }
        } catch (Exception ex) {
            result.actionStatus = PC_SupportPlan.ActionStatus.COMPLETED_FAILED;
            result.errorMessage = JSON.serialize(ex.getStackTraceString());
            PC_Utility.createExceptionLog(ex);
        }
        return result;
    }

    @future(callout=true)
    public static void doPharmacyEbenefitsCallout(String sourceId, String taskID) {
        try {
            List<PC_eBenefits2.PharmacyBenefitsResponse> response = new List<PC_eBenefits2.PharmacyBenefitsResponse>();
            PC_eBenefits2.PharmacyBenefits instance = PC_eBenefits2.getPharmacyBenefitsService();
            PC_eBenefits2.PharmacyBenefitsRequest pharmacyRequest = new PC_eBenefits2.PharmacyBenefitsRequest();
            pharmacyRequest.sourceRecordId = sourceId;
            response = instance.lookupPharmacyBenefits(pharmacyRequest);
            Task automationTask= [SELECT Id,WhatId,OwnerId, Status,PC_Program__c
                                  FROM Task
                                  WHERE Id=: taskID
                                  WITH SECURITY_ENFORCED
                                  LIMIT 1];
            //If Program field in Automation Task is null, Check source object type, query & set case id to Program field.
            if(automationTask.PC_Program__c == null){
                String objType = String.valueOf(Id.valueOf(sourceId).getSobjectType());
                if(objType== PC_Constants.PC_ACCOUNT){
                    Account account=  [SELECT (SELECT Id FROM Account.Cases WHERE Type =: PC_Constants.CASE_PROGRAM_TYPE LIMIT 1)
                                      FROM Account
                                      WHERE Id=:sourceId
                                      WITH SECURITY_ENFORCED
                    ];
                    automationTask.PC_Program__c = account.Cases[0].Id;
                automationTask= (Task) PC_Database.ups(automationTask);//update the Automation task
                }
            }
            List<PC_RecordIdentifier__c> recordIdentiferList= new List<PC_RecordIdentifier__c>();
            List<Task> pharmacyBIResponseTaskList= new List<Task>();
            Map<String,Task> relatedRecordsAndTaskIdMap= new Map<String,Task>();
            if(response!=null && !response.isEmpty()) {
                for (PC_eBenefits2.PharmacyBenefitsResponse pharmacyBenefitsResponse : response) {
                    if (pharmacyBenefitsResponse.isSuccess) {
                        Task t = getPharmacyBIResponseTask(pharmacyBenefitsResponse, automationTask);
                        pharmacyBIResponseTaskList.add(t);
                        String key = pharmacyBenefitsResponse.relatedRecordId + '-' + automationTask.PC_Program__c;
                        relatedRecordsAndTaskIdMap.put(key, t);
                        recordIdentiferList.add(getRecordIdentifierForExternalTask(pharmacyBenefitsResponse, automationTask));
                    } else {
                        Task t = getPharmacyBIResponseTask(pharmacyBenefitsResponse, automationTask);
                        pharmacyBIResponseTaskList.add(t);
                        String key = pharmacyBenefitsResponse.relatedRecordId + '-' + automationTask.PC_Program__c;
                        relatedRecordsAndTaskIdMap.put(key, t);
                    }
                }
            }
            automationTask.Status=PC_Constants.PC_TASK_STATUS_COMPLETED;
            automationTask= (Task) PC_Database.ups(automationTask);//update the Automation task
            if(pharmacyBIResponseTaskList!=null && !pharmacyBIResponseTaskList.isEmpty()) {
                PC_Database.ins(pharmacyBIResponseTaskList, false);//Bulk-insert of related tasks
            }
            if(relatedRecordsAndTaskIdMap!= null && !relatedRecordsAndTaskIdMap.isEmpty()) {
                for (String key : relatedRecordsAndTaskIdMap.keySet()) {
                    Task t = relatedRecordsAndTaskIdMap.get(key);
                    String internalTaskId = t.Id;
                    recordIdentiferList.add(getRecordIdentifierForInternalTask(internalTaskId, key));
                }
            }
            if(recordIdentiferList!=null && !recordIdentiferList.isEmpty()) {
                PC_Database.ins(recordIdentiferList, false);//Bulk-insert of both external & internal task related record identifiers
            }
        } catch (Exception ex) {
            Task currentActivity = [SELECT Status, id, Description FROM Task WHERE id = :taskID  WITH SECURITY_ENFORCED LIMIT 1];
            currentActivity.Description = ex.getMessage();
            currentActivity.Status = PC_Constants.PC_TASK_STATUS_WAITING;
            currentActivity = (Task) PC_Database.ups(currentActivity);
            PC_Utility.createExceptionLog(ex);
        }
    }
    public static PC_RecordIdentifier__c getRecordIdentifierForExternalTask(PC_eBenefits2.PharmacyBenefitsResponse pharmacyBenefitsResponse,Task relatedTask){
        PC_RecordIdentifier__c record = new PC_RecordIdentifier__c();
        Id taskRelatedToRecordId= pharmacyBenefitsResponse.relatedRecordId;
        record.PC_RecordId__c= pharmacyBenefitsResponse.relatedRecordId+'-'+relatedTask.PC_Program__c;
        record.PC_Type__c=PC_Constants.INFINITUS;
        record.PC_Value__c= pharmacyBenefitsResponse.externalId;
        record.PC_Assigner__c= PC_Constants.INFINITUS;
        return record;
    }

    public static PC_RecordIdentifier__c getRecordIdentifierForInternalTask(String internalTaskId,String relatedRecordsKey){
        PC_RecordIdentifier__c record = new PC_RecordIdentifier__c();
        List<String> relatedIdList= relatedRecordsKey.split('-');
        Id healthPlanId= relatedIdList[0];
        record.PC_RecordId__c= relatedRecordsKey;
        record.PC_Type__c=PC_Constants.INTERNAL_TASK;
        record.PC_Value__c= internalTaskId;
        record.PC_Assigner__c= PC_Constants.PATIENT_CONNECT;
        return record;
    }

    public static task getPharmacyBIResponseTask(PC_eBenefits2.PharmacyBenefitsResponse pharmacyBenefitsResponse,Task automationTask) {
        Task task = new Task();
        task.WhatId= automationTask.PC_Program__c;
        task.PC_Program__c= automationTask.PC_Program__c;
        task.OwnerId = automationTask.OwnerId;
        task.RecordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.PC_TASK, PC_Constants.PSP_TASK_RECORD_TYPE);
        task.PC_Direction__c = PC_Constants.OUTBOUND;
        task.PC_Channel__c = PC_Constants.PC_TASK;
        if(pharmacyBenefitsResponse.errorMessage== null || String.isBlank(pharmacyBenefitsResponse.errorMessage)) {
            task.Subject=System.Label.PC_PharmacyBISuccessTaskSubject ;
            task.Description = String.format(System.Label.PC_BISuccessTaskDescription, new List<Object>{pharmacyBenefitsResponse.externalId, pharmacyBenefitsResponse.remoteServiceLogId});
            task.Status = PC_Constants.PC_LOG_STATUS_IN_PROGRESS;
        }else if(pharmacyBenefitsResponse.errorMessage!= null || String.isNotBlank(pharmacyBenefitsResponse.errorMessage)){
            task.Subject = System.Label.PC_PharmacyBIErrorTaskSubject ;
            task.Description =pharmacyBenefitsResponse.errorMessage ;
            task.Status = PC_Constants.PC_TASK_STATUS_WAITING;
        }
        task.Priority = PC_Constants.PC_PRIORITY_NORMAL;
        task.ActivityDate = System.today();
        return task;

    }
}