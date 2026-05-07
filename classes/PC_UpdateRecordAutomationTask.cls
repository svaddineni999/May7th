/*********************************************************************************************************
Class Name      : PC_UpdateRecordAutomationTask
Description     : Service Class for Update Record action execution
Created By      : Haritha Reddy
Created Date    : Jun 19, 2020
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer                   Date                   	Description
--------------------------------------------------------------------------------------------------------------
Haritha Reddy          Jun 19, 2020            [PC-6453]Initial Version
Haritha Reddy          Nov 10, 2020            [PC-6893] Modified code to support formula calculations for date/dateTime fields
Haritha Reddy          Nov 30, 2020            [PC-7001] Made changes to support Custom logic in filter conditions of Update Child records Action
Haritha Reddy          Nov 30, 2020            [PC-7025] Modified logic to support Update child records without filter conditions
Haritha Reddy          Dec 12, 2020            [PC-7109] Added null check for child records before evaluating filter criteria
****************************************************************************************************************/
public with sharing class PC_UpdateRecordAutomationTask implements PC_SupportPlan.Action2{

    public PC_SupportPlan.PerformActionResult performAction(PC_Automation_Task__e automationTask) {
        PC_SupportPlan.PerformActionResult result = new PC_SupportPlan.PerformActionResult();
        result.actionStatus =   PC_SupportPlan.ActionStatus.IN_PROGRESS;
        result.errorMessage =   PC_Constants.EMPTY_STRING;
        result.actionRecordId = PC_Constants.EMPTY_STRING;
        try {
            List<SObject> updateRecordList = parseAutomationTaskJsonAsSobjects(automationTask);
            //Update Records
            PC_Database.upd(updateRecordList, true);
            List<String> actionRecordIdList = new List<String>();
            for(SObject updatedRecord:updateRecordList){
                actionRecordIdList.add(updatedRecord.Id);
            }
            String actionRecordIds = String.join(actionRecordIdList, ',');
            result.actionRecordId = actionRecordIds;
            result.actionStatus = PC_SupportPlan.ActionStatus.COMPLETED_SUCCESS;
            result.errorMessage = PC_Constants.EMPTY_STRING;
        }catch(PC_AutomationTaskHelper.AutomationTask_Exception ex){
            result.actionStatus = PC_SupportPlan.ActionStatus.COMPLETED_FAILED;
            result.errorMessage = JSON.serialize(ex.getMessage());
            PC_Utility.publishErrorLog(ex,JSON.serialize(automationTask));
        }catch(Exception ex){
            result.actionStatus = PC_SupportPlan.ActionStatus.COMPLETED_FAILED;
            result.errorMessage = JSON.serialize(ex.getMessage()+' '+ex.getStackTraceString());
            PC_Utility.publishErrorLog(ex,JSON.serialize(automationTask));
        }
        return result;
    }

    /*********************************************************************************
    Method Name    : parseAutomationTaskJsonAsSobjects
    Description    : This method parses Automation task JSON and populates SObject record fields
    Return Type    : List<SObject>
    Parameter      : automationTask
    *********************************************************************************/
    private static List<SObject> parseAutomationTaskJsonAsSobjects(PC_Automation_Task__e automationTask){
        PC_AutomationTaskHelper.AutomationTaskInfo automationTaskInfo =
                (PC_AutomationTaskHelper.AutomationTaskInfo) System.JSON.deserialize(automationTask.PC_TaskConfiguration__c, PC_AutomationTaskHelper.AutomationTaskInfo.class);

        //fetch the list of Trigger Object Reference fields that needs to be queried
        Set<String> fields = new Set<String>();
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
            PC_Database.assertAccess(sObjectName,PC_Database.Operation.Reading, fieldsList);
            String sObjectFields = String.join(fieldsList, ',');
            String recordsQuery = 'Select ' +sObjectFields +' from '+ sObjectName +' where Id =  \''+automationTask.PC_SourceId__c+'\'';
            sObjectList = Database.query(recordsQuery);
        }

        //Get the Map of RecordTypeName along with Namespace and Record type Id for all Record Types in Object
        Map<String, Id> recordTypeIdMap =  PC_AutomationTaskHelper.getSObjectRecordTypeMap(automationTaskInfo.objectDetails.qualifiedApiName);

        //fetch the record/s to be updated
        List<SObject> updateRecordList = getRecordsToBeUpdated(automationTask,automationTaskInfo);

        //Set the field Values of record to be updated
        for (PC_AutomationTaskHelper.FieldMap row : automationTaskInfo.fieldMapping) {
            if(!String.isEmpty(row.value) && row.value != null){
                for(SObject updateRecord: updateRecordList){
                    PC_AutomationTaskHelper.mapFieldValuesForSObjectRecord(sObjectList,updateRecord,row,recordTypeIdMap);
                }
            }
        }
        return updateRecordList;
    }

    /*********************************************************************************
    Method Name    : getRecordsToBeUpdated
    Description    : This method fetches the record/s that need to be updated
    Return Type    : List<SObject>
    Parameter      : automationTask
    *********************************************************************************/
    private static List<SObject> getRecordsToBeUpdated(PC_Automation_Task__e automationTask, PC_AutomationTaskHelper.AutomationTaskInfo automationTaskInfo){
        List<SObject> updateRecordList = new List<Sobject>();
        String triggerObjectName = automationTask.PC_Source__c;
        String triggerRecordId = automationTask.PC_SourceId__c;
        List<String> fieldsToQuery =  new List<String>();
        if(automationTaskInfo.type == PC_Constants.SUPPORTPLAN_UPDATE_TRIGGER_RECORD){
            //Field Access Check
            fieldsToQuery.add('Id');
            PC_Database.assertAccess(triggerObjectName,PC_Database.Operation.Reading, fieldsToQuery);
            //Query Trigger Record
            String recordsQuery = 'Select Id FROM '+triggerObjectName +' WHERE Id =  \''+triggerRecordId+'\'';
            updateRecordList = Database.query(recordsQuery);
        }
        else if(automationTaskInfo.type == PC_Constants.SUPPORTPLAN_UPDATE_LOOKUP_RECORD){
            updateRecordList = getLookupRecordToBeUpdated(triggerObjectName,triggerRecordId,automationTaskInfo);
        }
        else if(automationTaskInfo.type == PC_Constants.SUPPORTPLAN_UPDATE_CHILD_RECORDS){
            updateRecordList = getChildRecordsToBeUpdated(automationTask,automationTaskInfo);
        }
        return updateRecordList;
    }

    /*********************************************************************************
    Method Name    : getLookupRecordToBeUpdated
    Description    : This method fetches the Lookup record in trigger record that needs to be updated
    Return Type    : List<SObject>
    Parameter      : triggerObjectName, triggerRecordId, automationTask
    *********************************************************************************/
    private static List<SObject> getLookupRecordToBeUpdated(String triggerObjectName, String triggerRecordId, PC_AutomationTaskHelper.AutomationTaskInfo automationTaskInfo){
        List<SObject> lookupRecordToBeUpdated= new List<SObject>();
        String lookupObject = automationTaskInfo.objectDetails.qualifiedApiName;
        String lookupField = automationTaskInfo.objectDetails.relativeQualifiedApiPath;

        //Field Access Check
        List<String> fieldsToQuery =  new List<String>();
        fieldsToQuery.add(lookupField);
        PC_Database.assertAccess(triggerObjectName,PC_Database.Operation.Reading, fieldsToQuery);

        //Query Lookup Field value Id from Trigger Record
        String lookupFieldQuery = 'Select ' +lookupField +' FROM '+ triggerObjectName +' where Id =  \''+triggerRecordId+'\'';
        List<SObject> triggerRecWithLookupValue = Database.query(lookupFieldQuery);

        if(!triggerRecWithLookupValue.isEmpty()){
            String lookupRecordId = String.valueOf(triggerRecWithLookupValue[0].get(lookupField));
            String falseString = PC_Constants.FALSE_STRING;
            if(String.isNotEmpty(lookupRecordId) && lookupRecordId != null){
                //Query Lookup Record
                String lookupRecordQuery = 'Select Id FROM '+lookupObject +' WHERE Id =  \''+lookupRecordId+'\'';
                lookupRecordToBeUpdated = Database.query(lookupRecordQuery);
            }else if(automationTaskInfo.continueWhenNoUpdates == falseString){
                //stop runtime execution when lookup record is not found to update and continue is not opted
                PC_AutomationTaskHelper.AutomationTask_Exception automationTaskexception = new PC_AutomationTaskHelper.AutomationTask_Exception();
                automationTaskexception.setMessage(System.label.PC_SupportPlan_NoRecordsFoundMessage);
                throw automationTaskexception;
            }
        }
        return lookupRecordToBeUpdated;
    }

    /*********************************************************************************
    Method Name    : getChildRecordsToBeUpdated
    Description    : This method fetches the child record/s of trigger record that need to be updated
    Return Type    : List<SObject>
    Parameter      : automationTask, automationTaskInfo
    *********************************************************************************/
    private static List<SObject> getChildRecordsToBeUpdated(PC_Automation_Task__e automationTask, PC_AutomationTaskHelper.AutomationTaskInfo automationTaskInfo){
        //Build child records query
        String childRelationship = automationTaskInfo.objectDetails.relativeQualifiedApiPath;
        List<String> childFieldsList = new List<String>();
        Set<String> childFieldsSet = new Set<String>();
        String childQuery = 'Select Id ';
        if(!automationTaskInfo.LstConditionsPerObject.isEmpty() && !automationTaskInfo.LstConditionsPerObject[0].Conditions.isEmpty()){
            for(PC_SupportPlanEngine.Condition condition : automationTaskInfo.LstConditionsPerObject[0].Conditions) {
                if(condition.FieldApiName != PC_Constants.PC_RecordTypeDeveloperName){
                    childFieldsSet.add(condition.FieldApiName);
                }else{
                    childFieldsSet.add(PC_Constants.PC_RECORD_TYPE_ID);
                }
            }
            if(!childFieldsSet.isEmpty()){
                childFieldsList.addAll(childFieldsSet);
                childQuery = childQuery +',' +string.join(childFieldsList,',');
            }
        }
        childQuery = childQuery + ' FROM '+childRelationship;
        if(!automationTaskInfo.sortOrderInfo.isEmpty()){
            for(PC_AutomationTaskHelper.SortOrderInfo sortOrder: automationTaskInfo.sortOrderInfo){
                if(!sortOrder.orderBy.isEmpty()){
                    //Append Order by Clause
                    if(!childQuery.contains(' ORDER BY ')){
                        childQuery = childQuery + ' ORDER BY ';
                    }else{
                        childQuery = childQuery + ' , ';
                    }
                    for(String orderByField: sortOrder.orderBy) {
                        childQuery = childQuery + orderByField + ' ' + sortOrder.order +' ';
                        if(String.isNotEmpty(sortOrder.nullsOrder)){
                            childQuery = childQuery + ' NULLS ' +sortOrder.nullsOrder;
                        }
                        childQuery = childQuery + ' , ';
                    }
                    childQuery = childQuery.removeEnd(' , ');
                }
            }
        }
        //Field Access Check
        List<String> fieldsToQuery =  new List<String>();
        fieldsToQuery.add('Id');
        PC_Database.assertAccess(automationTask.PC_Source__c,PC_Database.Operation.Reading, fieldsToQuery);
        if(!childFieldsList.isEmpty()){
            childFieldsList.add('Id');
            PC_Database.assertAccess(automationTaskInfo.objectDetails.qualifiedApiName,PC_Database.Operation.Reading, childFieldsList);
        }
        //Query Child Records
        String relationshipQuery = 'Select Id, ' +'(' +childQuery+ ')' +' FROM '+automationTask.PC_Source__c +' WHERE Id = \''+automationTask.PC_SourceId__c+'\'';
        system.debug('relationshipQuery>>'+relationshipQuery);
        List<SObject> triggerRecordWithChildRecords= Database.query(relationshipQuery);
        List<SObject> allChildRecords= new List<SObject>();
        if(!triggerRecordWithChildRecords.isEmpty()){
            allChildRecords = (List<SObject>)triggerRecordWithChildRecords[0].getSObjects(childRelationship);
        }
        system.debug('allChildRecords>>'+allChildRecords);
        List<SObject> filteredChildSObjectList = new List<SObject>();
        if(allChildRecords != null && !allChildRecords.isEmpty()){
            if(!automationTaskInfo.LstConditionsPerObject.isEmpty() && !automationTaskInfo.LstConditionsPerObject[0].Conditions.isEmpty()){
                String conditionLogicJSON = JSON.serialize(automationTaskInfo);
                Map<String, Id> recordTypeIdMap =  PC_AutomationTaskHelper.getSObjectRecordTypeMap(automationTaskInfo.LstConditionsPerObject[0].ObjectType);
                for(SObject childRecord: allChildRecords){
                    if(PC_SupportPlanEngine.evaluateConditionLogic(conditionLogicJSON,childRecord,null,recordTypeIdMap,null,automationTask.PC_SupportPlanActivityId__c,automationTask.PC_RunningUser__c)){
                        filteredChildSObjectList.add(childRecord);
                    }
                }
            }else{
                //Add all records to list when there is no filter criteria
                filteredChildSObjectList.addAll(allChildRecords);
            }
        }
        List<SObject> childRecordsToBeUpdated= new List<SObject>();
        if(filteredChildSObjectList != null && !filteredChildSObjectList.isEmpty()){
            //add the records that need to be updated to a list based on selected update criteria
            if(automationTaskInfo.updateCriteria == PC_Constants.PC_UPDATE_ALL_RECORDS){
                childRecordsToBeUpdated.addAll(filteredChildSObjectList);
            }else if(automationTaskInfo.updateCriteria == PC_Constants.PC_UPDATE_FIRST_RECORD ||
                    (automationTaskInfo.updateCriteria == PC_Constants.PC_UPDATE_ONLY_RECORD && filteredChildSObjectList.size() == 1)){
                childRecordsToBeUpdated.add(filteredChildSObjectList[0]);
            }
        }
        List<SObject> childRecordsList = new List<Sobject>();
        if(!childRecordsToBeUpdated.isEmpty()){
            Set<Id> childRecordIdSet = (new Map<Id,SObject>(childRecordsToBeUpdated)).keySet();
            String recordsQuery = 'Select Id FROM ' + automationTaskInfo.objectDetails.qualifiedApiName + ' WHERE ID IN: childRecordIdSet';
            childRecordsList = Database.query(recordsQuery);
        }
        //stop runtime execution when no records are found to update and continue is not opted
        if(childRecordsList.isEmpty() && automationTaskInfo.continueWhenNoUpdates == PC_Constants.FALSE_STRING){
            PC_AutomationTaskHelper.AutomationTask_Exception automationTaskexception = new PC_AutomationTaskHelper.AutomationTask_Exception();
            if(filteredChildSObjectList != null && !filteredChildSObjectList.isEmpty() && filteredChildSObjectList.size() > 1 && automationTaskInfo.updateCriteria == PC_Constants.PC_UPDATE_ONLY_RECORD){
                automationTaskexception.setMessage(System.label.PC_SupportPlan_MultipleRecordsFoundMessage);
            }else{
                automationTaskexception.setMessage(System.label.PC_SupportPlan_NoRecordsFoundMessage);
            }
            throw automationTaskexception;
        }
        return childRecordsList;
    }
}