/*********************************************************************************************************
Class Name      : PC_CreateRecordAutomationTask
Description     : Utility Class for Create Record and Publish Platform event actions execution
Created By      : Haritha Reddy
Created Date    : Apr 08, 2020
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer                   Date                   	Description
--------------------------------------------------------------------------------------------------------------
Haritha Reddy          Apr 08, 2020            Initial Version
Haritha Reddy          Jun 05, 2020            [PC-6196]Updated logic to set Outcome Task owner as automated process in case of SP Action Success
Haritha Reddy          Jun 18, 2020            [PC-6335]Updated logic to set Owner as running user if Owner field exists and is empty
Haritha Reddy          Jun 23, 2020            [PC-6453]Moved reusable methods to create log and outcome task to helper method
Haritha Reddy          Jul 07, 2020            [PC-6455]Moved reusable code for assigning record field mapping to helper method
Haritha Reddy          Nov 10, 2020            [PC-6893]Modified code to support formula calculations for date/dateTime fields
****************************************************************************************************************/

public with sharing class PC_CreateRecordAutomationTask implements PC_SupportPlan.Action2 {

    private static PC_SupportPlan.PerformActionResult result = new PC_SupportPlan.PerformActionResult();

    public PC_SupportPlan.PerformActionResult performAction(PC_Automation_Task__e automationTask) {
        result.actionStatus =   PC_SupportPlan.ActionStatus.IN_PROGRESS;
        result.errorMessage =   PC_Constants.EMPTY_STRING;
        result.actionRecordId = PC_Constants.EMPTY_STRING;
        PC_SupportPlan.PerformActionResult result = new PC_SupportPlan.PerformActionResult();
        try {
            SObject newRecord = createRecord(automationTask);
            if(automationTask.PC_AutomationTaskType__c == PC_Constants.SUPPORTPLAN_ACTIVITY_TYPE_CREATE_RECORD) {
                //Insert new Record
                PC_Database.ins(newRecord, true);
                result.actionRecordId = newRecord.Id;
                result.actionStatus = PC_SupportPlan.ActionStatus.COMPLETED_SUCCESS;
                result.errorMessage = PC_Constants.EMPTY_STRING;
            }else if(automationTask.PC_AutomationTaskType__c == PC_Constants.SUPPORTPLAN_ACTIVITY_TYPE_PUBLISH_PLATFORM_EVENT){
                //Publish Platform Event
                Database.SaveResult publishingResult = EventBus.publish(newRecord);
                if (publishingResult.isSuccess()) {
                    result.actionStatus = PC_SupportPlan.ActionStatus.COMPLETED_SUCCESS;
                    result.errorMessage = PC_Constants.EMPTY_STRING;
                } else {
                    String errorMessage = '';
                    for(Database.Error err : publishingResult.getErrors()) {
                        errorMessage = errorMessage + ' \n' +err.getMessage();
                    }
                    PC_AutomationTaskHelper.AutomationTask_Exception automationTaskexception = new PC_AutomationTaskHelper.AutomationTask_Exception();
                    automationTaskexception.setMessage(errorMessage);
                    throw automationTaskexception;
                }
            }
        }catch(Exception ex){
            result.actionStatus = PC_SupportPlan.ActionStatus.COMPLETED_FAILED;
            result.errorMessage = JSON.serialize(ex.getMessage()+' '+ex.getStackTraceString());
            PC_Utility.publishErrorLog(ex,JSON.serialize(automationTask));
        }
        return result;
    }

    /*********************************************************************************
    Method Name    : createRecord
    Description    : This method populates SObject record fields based on Support Plan Activity template
    Return Type    : SObject
    Parameter      : automationTask
    *********************************************************************************/
    private static SObject createRecord(PC_Automation_Task__e automationTask){
        PC_AutomationTaskHelper.AutomationTaskInfo automationTaskInfo =
                (PC_AutomationTaskHelper.AutomationTaskInfo) System.JSON.deserialize(automationTask.PC_TaskConfiguration__c, PC_AutomationTaskHelper.AutomationTaskInfo.class);

        String actionRecordId;
        String newRecordSObjectType = automationTaskInfo.objectDetails.qualifiedApiName;
        SObject newRecord = Schema.getGlobalDescribe().get(newRecordSObjectType).newSObject() ;
        Set<String> fields = new Set<String>();
        //fetch the list of Trigger Object Reference fields that needs to be queried
        for (PC_AutomationTaskHelper.FieldMap row : automationTaskInfo.fieldMapping) {
            if ((String.valueOf(row.type) == PC_Constants.PC_FIELD_TYPE_REFERENCE || row.isBoundValue == PC_Constants.TRUE_BOOLEAN)
                    && row.value != PC_Constants.PC_NULL && row.value != PC_Constants.PC_FORMULA_VALUE) {
                fields.add(row.value);
            }else if(row.isBoundValue == PC_Constants.TRUE_BOOLEAN && row.value == PC_Constants.PC_FORMULA_VALUE){
                fields.add(row.formulaValue.referenceFieldApiName);
            }
        }
        List<String> fieldsList = new List<String>();
        fieldsList.addAll(fields);
        //Query reference Fields from the Trigger Records
        List<SObject> sObjectList = new List<SObject>();
        String sObjectName = automationTask.PC_Source__c;
        if(!fields.isEmpty()){
            String sObjectFields = String.join(fieldsList, ',');
            String recordsQuery = 'Select ' +sObjectFields +' from '+ sObjectName +' where Id =  \''+automationTask.PC_SourceId__c+'\'';
            sObjectList = Database.query(recordsQuery);
        }
        //Get the Map of RecordTypeName along with Namespace and Record type Id for all Record Types in Object
        Map<String, Id> recordTypeIdMap =  PC_AutomationTaskHelper.getSObjectRecordTypeMap(automationTaskInfo.objectDetails.qualifiedApiName);
        for (PC_AutomationTaskHelper.FieldMap row : automationTaskInfo.fieldMapping) {
            if(!String.isEmpty(row.value) && row.value != null){
                PC_AutomationTaskHelper.mapFieldValuesForSObjectRecord(sObjectList,newRecord,row,recordTypeIdMap);
            }
        }
        String ownerFieldName = PC_Constants.OWNER_ID_PARAM;
        Boolean ownerFieldExists = Schema.getGlobalDescribe().get(newRecordSObjectType).getDescribe().fields.getMap().keySet().contains(ownerFieldName.toLowerCase());
        if(ownerFieldExists && String.isEmpty(String.valueOf(newRecord.get(ownerFieldName)))){
            newRecord.put(ownerFieldName, automationTask.PC_RunningUser__c);
        }
        return newRecord;
    }
}