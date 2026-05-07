/*********************************************************************************************************
Class Name      : PC_AutomationTaskHelper
Description     : Helper Class for Automation Task Service Classes
Created By      : Haritha Reddy
Created Date    : Jun 22, 2020
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer                   Date                   	Description
--------------------------------------------------------------------------------------------------------------
Haritha Reddy          Jun 22, 2020            [PC-6453]Initial Version
Haritha Reddy          Jul 07, 2020            [PC-6455]Added new Methods assignFieldMappingToSObjectRecord, getAllOperatorMap
Haritha Reddy          Jul 30, 2020            [PC-6593] Made changes to support Time field
Haritha Reddy          Oct 06, 2020            [PC-6792] Modified Support Plan execution logic to stop executing in Recursive Scenario.
Haritha Reddy          Oct 13, 2020            [PC-6332] Modified code for fixing issues shown in Force reviewer scan report
Haritha Reddy          Nov 10, 2020            [PC-6893] Modified code to support formula calculations for date/dateTime fields
Haritha Reddy          Dec 12, 2020            [PC-7109] Modified code to get lastModifiedTime from first record when multiple records are updated as part of SP
Haritha Reddy          Jan 06, 2020            [PC-7187] Removed getAllOperatorMap method since it is not being used anywhere.
Hitha Avalakki         May 10, 2021            [PC-7666] Made method:calculateAndAssignFormulaValues() public in order to use it for Task creation logic
Kishore Kanteti        Sep 28, 2021            [PC-8177] Made changes so that additional comments are added to Task Description
Haritha Reddy          Oct 20, 2021            [PC-8237] Updated logic to convert value to string if isBoundValue is true in a field assignment.
Hitha Avalakki         Oct 20, 2021            [PC-8139] Added contructors for FieldMap and FormulaValue classes
Chetna Mohapatra       Feb 28, 2022           [PC-8529] Added logic to handle Outcome task creation for Trigger objects having activities disabled.
****************************************************************************************************************/
public with sharing class PC_AutomationTaskHelper {
    /*****************************************************************************************************
    Method Name    : createSupportPlanActivityLog
    Description    : This method creates Support Plan Activity Log
    Return Type    : void
    Parameter      : automationTask, result, taskId
    ******************************************************************************************************/
    public static void createSupportPlanActivityLog(PC_Automation_Task__e automationTask, PC_SupportPlan.PerformActionResult result, String taskId) {
        //Map corresponding Log Status to be Set
        Map<PC_SupportPlan.ActionStatus, String> actionStatusMap = new Map<PC_SupportPlan.ActionStatus, String>();
        actionStatusMap.put(PC_SupportPlan.ActionStatus.COMPLETED_SUCCESS, PC_Constants.PC_LOG_STATUS_COMPLETED);
        actionStatusMap.put(PC_SupportPlan.ActionStatus.IN_PROGRESS, PC_Constants.PC_LOG_STATUS_IN_PROGRESS);
        actionStatusMap.put(PC_SupportPlan.ActionStatus.COMPLETED_FAILED, PC_Constants.PC_LOG_STATUS_FAILED);

        PC_SupportPlanActivityLog__c log = new PC_SupportPlanActivityLog__c();
        String actionRecordId;
        if(String.isNotEmpty(result.actionRecordId)){
            actionRecordId = result.actionRecordId;
        }else if(String.isNotEmpty(taskId)){
            actionRecordId = taskId;
        }
        if (String.isNotEmpty(actionRecordId) ) {
            Id recordId;
            if(!actionRecordId.contains(',')){
                recordId = (Id) actionRecordId;
            }else{
                List<String> actionRecordIdList = actionRecordId.split(',');
                if(!actionRecordIdList.isEmpty()){
                    recordId = (Id) actionRecordIdList[0];
                }
            }
            DateTime actionRecordModifiedDate =
                    (DateTime) Database.query('select LastModifiedDate from ' + recordId.getSobjectType() + ' where id = :recordId')[0].get('LastModifiedDate');
            log.PC_ActionRecordModifiedTime__c = actionRecordModifiedDate;
        }
        log.PC_TransactionId__c = automationTask.PC_TransactionId__c;
        log.PC_LogDateTime__c = System.now();
        log.PC_TriggerRecordId__c = automationTask.PC_SourceId__c;
        log.PC_ActionRecordId__c = actionRecordId;
        log.PC_SupportPlanActivity__c = automationTask.PC_SupportPlanActivityId__c;
        log.PC_SupportPlanRuntime__c = automationTask.PC_SupportPlanRuntimeId__c;
        log.PC_Status__c = actionStatusMap.get(result.actionStatus);
        log.PC_RuntimeUser__c = automationTask.PC_RunningUser__c;

        PC_Database.ins(log,true);
    }

    /*********************************************************************************
    Method Name    : createOutcomeTask
    Description    : This method creates Task to be displayed in Activity timeline for Automation Task actions.
    Return Type    : Task
    Parameter      : automationTask, result
    *********************************************************************************/
    public static String createOutcomeTask(PC_Automation_Task__e automationTask, PC_SupportPlan.PerformActionResult result){
        try{
            AutomationTaskInfo automationTaskInfo =
                    (AutomationTaskInfo) System.JSON.deserialize(automationTask.PC_TaskConfiguration__c, AutomationTaskInfo.class);
            //Create Outcome Task if opted or the Action execution is failed
            if(automationTaskInfo.outcomeTaskDetails.create || result.actionStatus == PC_SupportPlan.ActionStatus.COMPLETED_FAILED){
                //Map corresponding Task Status to be Set
                Map<PC_SupportPlan.ActionStatus,String> actionStatusMap = new Map<PC_SupportPlan.ActionStatus,String>();
                actionStatusMap.put(PC_SupportPlan.ActionStatus.COMPLETED_SUCCESS,PC_Constants.PC_TASK_STATUS_COMPLETED);
                actionStatusMap.put(PC_SupportPlan.ActionStatus.IN_PROGRESS,PC_Constants.SUPPORTPLAN_TASK_STATUS_INPROGRESS);
                actionStatusMap.put(PC_SupportPlan.ActionStatus.COMPLETED_FAILED,PC_Constants.PC_TASK_STATUS_WAITING);

                Task t = new Task();
                String triggerObject= PC_Constants.EMPTY_STRING;
                triggerObject= automationTask.PC_Source__c;
                List<Schema.SObjectType> objectsWithActivitiesEnabled= new List<Schema.SObjectType>();
                if(String.isEmpty(String.valueOf(t.WhatId))) {
                    for (Schema.SObjectType whatIdObjectType : Task.WhatId.getDescribe().getReferenceTo()) {
                        objectsWithActivitiesEnabled.add(whatIdObjectType);
                        if (triggerObject == String.valueOf(whatIdObjectType)) {
                            t.WhatId = automationTask.PC_SourceId__c;
                            break;
                        }
                    }
                    //Error logging for any Trigger object that does not have activities enabled.
                    handleObjectsWithActivitiesDisabled(triggerObject, objectsWithActivitiesEnabled);
                }
                t.RecordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.PC_TASK, PC_Constants.PSP_TASK_RECORD_TYPE);
                t.ActivityDate = system.today();
                if(result.actionStatus == PC_SupportPlan.ActionStatus.COMPLETED_SUCCESS){
                    t.OwnerId = userInfo.getUserId();
                }else{
                    t.OwnerId = automationTask.PC_RunningUser__c;
                }
                t.Status = actionStatusMap.get(result.actionStatus);
                t.Priority = PC_Constants.PC_PRIORITY_NORMAL;
                t.PC_Channel__c = PC_Constants.PC_TASK;
                t.PC_SupportPlanActivity__c = automationTask.PC_SupportPlanActivityId__c;
                t.Description = result.errorMessage;
                if(automationTask.PC_SupportPlanActivityId__c != null) {
                    /*FLS Check for PC_SupportPlanActivity__c*/
                    List<String> supportPlanActivityFields = new List<String>{'Id','Name', PC_Constants.getQualifiedAPIName('PC_SupportPlan__r.Name')};
                    PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_SupportPlanActivity__c'), PC_Database.Operation.Reading, supportPlanActivityFields);

                    PC_SupportPlanActivity__c spActivity = [Select Id,Name,PC_SupportPlan__r.Name
                    FROM PC_SupportPlanActivity__c WHERE Id =: automationTask.PC_SupportPlanActivityId__c];
                    List<Object> formattingArguments = new List<Object>{
                            spActivity.PC_SupportPlan__r.Name,
                            spActivity.Name
                    };
                    if(result.actionStatus == PC_SupportPlan.ActionStatus.COMPLETED_SUCCESS){
                        t.Subject = String.format(Label.PC_SupportPlan_ActionSuccessMessage, formattingArguments);
                        if(String.isNotBlank(result.additionalComments)){
                            t.Description = String.isNotBlank(t.Description) ? t.Description + result.additionalComments : result.additionalComments;
                        }
                    } else{
                        t.Subject = String.format(Label.PC_SupportPlan_ActionErrorMessage, formattingArguments);
                    }
                }
                PC_Database.ins(t,true);
                System.debug('Outcome Task Id--'+t.Id);
                return t.Id;
            }
        }catch(Exception ex){
            PC_Utility.createExceptionLog(ex);
        }
        return null;
    }
    /*********************************************************************************
   Method Name    : handleObjectsWithActivitiesDisabled
   Description    : Initiates error log creation for any Trigger object that doesn't have activities enabled.
   Return Type    : void
   Parameter      : triggerObject(String), objectsWithActivitiesEnabled(List)
   *********************************************************************************/
    public static void handleObjectsWithActivitiesDisabled(String triggerObject, List<Schema.SObjectType> objectsWithActivitiesEnabled){
        SObjectType sObjType = ((SObject) Type.forName(triggerObject).newInstance()).getSObjectType();
        if(!objectsWithActivitiesEnabled.contains(sObjType)) {
            List<Object> formattingArguments = new List<Object>{
                    triggerObject
            };
            String errorDescription = String.format(Label.PC_SupportPlan_TaskWhatIdError, formattingArguments);
            PC_Utility.ErrorInfoWrapper errorInfoWrapper = new PC_Utility.ErrorInfoWrapper(null, errorDescription, 'PC_AutomationTaskHelper', 'createOutcomeTask', null, null, PC_Utility.ERROR_LOG_LEVEL.ERROR_LOG_LEVEL_WARN, null);
            PC_Utility.createExceptionLog(errorInfoWrapper);
        }
    }
    /*********************************************************************************
    Method Name    : mapFieldValuesForSObjectRecord
    Description    : This method returns SObject Record with the values assigned according to field mapping
    Return Type    : sObjectRecord
    Parameter      : triggerRecord, sObjectRecord, row, recordtypeIdMap
    *********************************************************************************/
    public static SObject mapFieldValuesForSObjectRecord(List<SObject> triggerRecord, SObject sObjectRecord, FieldMap row, Map<String, Id> recordtypeIdMap) {
        //Assign Record Type for record based on Record Type Name
        if(String.valueOf(row.apiName) == PC_Constants.PC_RecordTypeDeveloperName){
            if(recordtypeIdMap.containsKey(row.value)) {
                sObjectRecord.put(PC_Constants.PC_RECORD_TYPE_ID, recordtypeIdMap.get(row.value));
            }
        }else if(row.isBoundValue == PC_Constants.TRUE_BOOLEAN && row.value != PC_Constants.PC_NULL){
            //assign the referenced field value/formula value if isBoundValue is True
            if(row.value == PC_Constants.PC_FORMULA_VALUE){
                calculateAndAssignFormulaValues(triggerRecord,sObjectRecord,row);
            }else if(!triggerRecord.isEmpty() && triggerRecord[0].get(row.value) != null){
                sObjectRecord.put(row.apiName, String.valueOf(triggerRecord[0].get(row.value)));
            }
        }else{
            if (String.valueOf(row.type) == PC_Constants.PC_FIELD_TYPE_BOOLEAN) {
                sObjectRecord.put(row.apiName, Boolean.valueOf(row.value));
            } else if (String.valueOf(row.type) == PC_Constants.PC_FIELD_TYPE_DOUBLE
                    ||  String.valueOf(row.type) == PC_Constants.PC_FIELD_TYPE_PERCENT
                    ||  String.valueOf(row.type) == PC_Constants.PC_FIELD_TYPE_CURRENCY ) {
                sObjectRecord.put(row.apiName, Double.valueOf(row.value));
            } else if (String.valueOf(row.type) == PC_Constants.PC_FIELD_TYPE_DATE) {
                if(row.value == PC_Constants.PC_TODAY_VALUE){
                    sObjectRecord.put(row.apiName, date.today());
                }else {
                    sObjectRecord.put(row.apiName, Date.valueOf(row.value));
                }
            } else if (String.valueOf(row.type) == PC_Constants.PC_FIELD_TYPE_DATETIME) {
                if(row.value == PC_Constants.PC_NOW_VALUE){
                    sObjectRecord.put(row.apiName, DateTime.now());
                }else{
                    sObjectRecord.put(row.apiName, PC_Utility.parseDatetimeFromJSON(row.value));
                }
            } else if (String.valueOf(row.type) == PC_Constants.PC_FIELD_TYPE_REFERENCE) {
                if(row.value == PC_Constants.PC_NULL){
                    sObjectRecord.put(row.apiName, null);
                }else{
                    sObjectRecord.put(row.apiName, triggerRecord[0].get(row.value));
                }
            } else if (String.valueOf(row.type) == PC_Constants.PC_FIELD_TYPE_TIME) {
                sObjectRecord.put(row.apiName, PC_Utility.parseTimeFromJSONString(row.value));
            } else {
                sObjectRecord.put(row.apiName, row.value);
            }
        }
        return sObjectRecord;
    }

    /*********************************************************************************
    Method Name    : calculateAndAssignFormulaValues
    Description    : This method calculates formula value and assigns that to the corresponding field of Sobject that is mapped.
    Return Type    : void
    Parameter      : triggerRecord, sObjectRecord, row
    *********************************************************************************/
    public static void calculateAndAssignFormulaValues(List<SObject> triggerRecord, SObject sObjectRecord, FieldMap row) {
        Integer offsetValue;
        if(row.formulaValue.operation == String.valueOf(PC_Constants.FormulaOperators.Add)) {
            offsetValue = row.formulaValue.offsetValue;
        }else if(row.formulaValue.operation == String.valueOf(PC_Constants.FormulaOperators.Subtract)) {
            offsetValue = -row.formulaValue.offsetValue;
        }
        Object referenceFieldValue;
        if(!triggerRecord.isEmpty()) {
            referenceFieldValue = triggerRecord[0].get(row.formulaValue.referenceFieldApiName);
        }
        if (String.valueOf(row.type) == PC_Constants.PC_FIELD_TYPE_DATE && referenceFieldValue != null) {
            Date dateValue,dateFormulaValue;
            dateValue = Date.valueOf(referenceFieldValue);
            if(row.formulaValue.offsetType == String.valueOf(PC_Constants.OffsetType.Days)){
                dateFormulaValue = dateValue.addDays(offsetValue);
            }else if(row.formulaValue.offsetType == String.valueOf(PC_Constants.OffsetType.Months)){
                dateFormulaValue = dateValue.addMonths(offsetValue);
            }else if(row.formulaValue.offsetType == String.valueOf(PC_Constants.OffsetType.Years)){
                dateFormulaValue = dateValue.addYears(offsetValue);
            }
            sObjectRecord.put(row.apiName, dateFormulaValue);

        }else if (String.valueOf(row.type) == PC_Constants.PC_FIELD_TYPE_DATETIME && referenceFieldValue != null) {
            DateTime dateTimeValue,dateTimeFormulaValue;
            if(row.formulaValue.referenceFieldType == PC_Constants.PC_FIELD_TYPE_DATE){
                Date referenceDateValue = Date.valueOf(referenceFieldValue);
                dateTimeValue = DateTime.newInstanceGmt(referenceDateValue.year(), referenceDateValue.month(), referenceDateValue.day());
            }else{
                dateTimeValue = DateTime.valueOf(referenceFieldValue);
            }
            if(row.formulaValue.offsetType == String.valueOf(PC_Constants.OffsetType.Days)){
                dateTimeFormulaValue = dateTimeValue.addDays(offsetValue);
            }else if(row.formulaValue.offsetType == String.valueOf(PC_Constants.OffsetType.Months)){
                dateTimeFormulaValue = dateTimeValue.addMonths(offsetValue);
            }else if(row.formulaValue.offsetType == String.valueOf(PC_Constants.OffsetType.Years)){
                dateTimeFormulaValue = dateTimeValue.addYears(offsetValue);
            }
            sObjectRecord.put(row.apiName, dateTimeFormulaValue);
        }
    }

    /*********************************************************************************
    Method Name    : getSObjectRecordTypeMap
    Description    : This method returns Map of Record Type Developer Name and Record Type Id in a SObject
    Return Type    : Map<String, Id>
    Parameter      : sObjectName
    *********************************************************************************/
    public static Map<String, Id> getSObjectRecordTypeMap(String sObjectName) {
        Map<String, Id> recordTypeIdMap = new Map<String, Id>();
        List<RecordType> recordTypeList = new List<RecordType>();
        recordTypeList = [Select Id, DeveloperName, NamespacePrefix FROM RecordType WHERE SobjectType = :sObjectName AND isActive = true];
        if (recordTypeList != null && !recordTypeList.isEmpty()) {
            for (RecordType recordTypeDetailsObj : recordTypeList) {
                String recordTypeNameWithNamespace;
                if(String.isNotEmpty(recordTypeDetailsObj.NamespacePrefix)){
                    recordTypeNameWithNamespace = recordTypeDetailsObj.NamespacePrefix +'__'+ recordTypeDetailsObj.DeveloperName;
                }else{
                    recordTypeNameWithNamespace = recordTypeDetailsObj.DeveloperName;
                }
                recordTypeIdMap.put(recordTypeNameWithNamespace, recordTypeDetailsObj.Id);
            }
        }
        return recordTypeIdMap;
    }

    /**
     * Used to store and read the configuration for Automation Tasks
     */
    public inherited sharing class AutomationTaskInfo{
        /**
        * Stores Field Value Assignment
        */
        public List<FieldMap>  fieldMapping {get; set;}
        /**
         * Details of Object on which Action is performed
         */
        public SObjectInfo  objectDetails {get; set;}
        /**
         * Details of Task to be created when Action is executed successfully to track in Activity Timeline
         */
        public OutcomeTaskInfo  outcomeTaskDetails {get; set;}
        /**
         * Indicates update Type: value can be updateTriggerRecord,updateLookupRecord,updateChildRecords
         */
        public String  type {get; set;}
        /**
         * Information on sorting order
         */
        public List<SortOrderInfo>  sortOrderInfo {get; set;}
        /**
         * Indicates criteria for update: value can be ALL_RECORDS, FIRST_RECORD, ONLY_RECORD
         */
        public String  updateCriteria {get; set;}
        /**
         * Indicates whether to continue runtime execution if no records are found to update
         */
        public String  continueWhenNoUpdates {get; set;}
        /**
         * filter conditions for records on which action will be performed
         */
        public List<PC_SupportPlanEngine.ConditionLogic> LstConditionsPerObject {get; set;}
        public AutomationTaskInfo() {
            fieldMapping = new List<FieldMap>();
            objectDetails = new SObjectInfo();
            outcomeTaskDetails = new OutcomeTaskInfo();
            type = PC_Constants.EMPTY_STRING;
            sortOrderInfo = new List<SortOrderInfo>();
            updateCriteria = PC_Constants.EMPTY_STRING;
            continueWhenNoUpdates = PC_Constants.EMPTY_STRING;
            PC_SupportPlanEngine.ConditionLogic conditionLogic = new PC_SupportPlanEngine.ConditionLogic();
            List<PC_SupportPlanEngine.ConditionLogic> conditionalLogicList  = new List<PC_SupportPlanEngine.ConditionLogic>();
            conditionalLogicList.add(conditionLogic);
            LstConditionsPerObject = conditionalLogicList;
        }
    }
    /**
     * Used to store details of Sort Order
     */
    public inherited sharing class SortOrderInfo{
        /**
         * Order by Field to filter the records
         */
        public List<String>  orderBy {get; set;}
        /**
         * Order to be followed: ASC or DESC
         */
        public String  order {get; set;}
        /**
         * Determines if Nulls should come First/Last while sorting
         */
        public String nullsOrder {get; set;}

        public SortOrderInfo() {
            order = PC_Constants.EMPTY_STRING;
            nullsOrder = PC_Constants.EMPTY_STRING;
            orderBy = new List<String>();
        }
    }
    /**
    * Used to store and read Field Value Mapping given in Support Plan Activity
    */
    public inherited sharing class FieldMap{
        /**
         * field Label of the field that will be displayed on UI
         */
        public String  label {get; set;}
        /**
         * API Name of the field
         */
        public String  apiName {get; set;}
        /**
         * Indicates if delete operation is allowed
         */
        public Boolean  isDeleteAllowed {get; set;}
        /**
         * Data Type of the Field
         */
        public String  type {get; set;}
        /**
         * Value mapped to the field
         */
        public String  value {get; set;}
        /**
         * Properties related to formula calculations
         */
        public FormulaValue  formulaValue {get; set;}
        /**
         * Indicates if the field value is of reference type
         */
        public Boolean  isBoundValue {get; set;}

        public FieldMap() {
            label = PC_Constants.EMPTY_STRING;
            apiName = PC_Constants.EMPTY_STRING;
            type = PC_Constants.EMPTY_STRING;
            value = PC_Constants.EMPTY_STRING;
        }
        public FieldMap(String label,String apiName,Boolean isDeleteAllowed,String type,String value,FormulaValue formulaValue,Boolean isBoundValue){
            this.label = label;
            this.apiName = apiName;
            this.isDeleteAllowed = isDeleteAllowed;
            this.type = type;
            this.value = value;
            this.formulaValue = formulaValue;
            this.isBoundValue = isBoundValue;
        }
        /*In old wrapper(RequiredFieldWrapper) isDeleteAllowed was a String but in new wrapper(PC_AutomationTaskHelper.FieldMap)
         *it is Boolean to support the older wrapper properties that was used by clients already below conversion is done*/
        public FieldMap(PC_ActivityProperties_Controller.RequiredFieldWrapper oldFieldWrapper){
            label = oldFieldWrapper.label;
            apiName = oldFieldWrapper.apiName;
            type = String.valueOf(oldFieldWrapper.type);
            value = oldFieldWrapper.value;
            if(oldFieldWrapper.isDeleteAllowed != null && oldFieldWrapper.isDeleteAllowed.toLowerCase() == PC_Constants.TRUE_STRING){
                isDeleteAllowed = true;
            }else{
                isDeleteAllowed = false;
            }
        }
    }
    //Below method is added for backward compatibility purposes.(Added in 14th version).
    public static Set<FieldMap> convertOldFieldWrapperToNew(Set<PC_ActivityProperties_Controller.RequiredFieldWrapper> oldFieldWrappers){
        Set<FieldMap> allNewFieldWrappers  = new Set<FieldMap>();
        for(PC_ActivityProperties_Controller.RequiredFieldWrapper eachOldFieldWrapper : oldFieldWrappers){
            FieldMap eachFieldMap = new FieldMap(eachOldFieldWrapper);
            allNewFieldWrappers.add(eachFieldMap);
        }
        return allNewFieldWrappers;
    }

    /**
     * Used to store details of calculations related to formula
     */
    public inherited sharing class FormulaValue{
        /**
         * API Name of reference field
         */
        public String  referenceFieldApiName {get; set;}
        /**
         * Type of reference field Ex: Date/DateTime/Currency etc.,
         */
        public String  referenceFieldType {get; set;}
        /**
         * Type of operation to be performed Ex: Add/Subtract/Multiply/Divide
         */
        public String  operation {get; set;}
        /**
         * Unit in which offset is mentioned Ex: Days/Months/Years
         */
        public String  offsetType {get; set;}
        /**
         * Value of offset
         */
        public Integer  offsetValue {get; set;}

        public FormulaValue() {
            referenceFieldApiName = PC_Constants.EMPTY_STRING;
            referenceFieldType = PC_Constants.EMPTY_STRING;
            operation = PC_Constants.EMPTY_STRING;
            offsetType = PC_Constants.EMPTY_STRING;
            offsetValue = 0;
        }

        public FormulaValue(String referenceFieldApiName,String referenceFieldType,String operation,String offsetType,Integer offsetValue) {
            this.referenceFieldApiName = referenceFieldApiName;
            this.referenceFieldType = referenceFieldType;
            this.operation = operation;
            this.offsetType = offsetType;
            this.offsetValue = offsetValue;
        }
    }

    /**
     * Used to store details of SObject on which Action is performed
     */
    public inherited sharing class SObjectInfo{
        /**
         * Object API Name on which action is performed
         */
        public String  qualifiedApiName {get; set;}
        /**
         * Path to the Qualified API Name of Field or Child Object Relationship name from Trigger Object
         */
        public String  relativeQualifiedApiPath {get; set;}

        public SObjectInfo() {
            qualifiedApiName = PC_Constants.EMPTY_STRING;
            relativeQualifiedApiPath = PC_Constants.EMPTY_STRING;
        }
    }

    /**
    * Used to store details of Task to be created when Action is executed successfully to track in Activity Timeline
    */
    public inherited sharing class OutcomeTaskInfo{
        /**
         * Indicates if outcome task needs to be created or not
         */
        public boolean create;
    }
    /********************************************************************************
    Class Name           : AutomationTask_Exception
    Description          : Holds the exception related to AutomationTask
    *********************************************************************************/
    public inherited sharing class AutomationTask_Exception extends Exception{
    }
}