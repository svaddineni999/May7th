/*********************************************************************************
Class Name      : PC_SupportPlanEngine
Description     : Implements Support Plan on an object
Created By      : Prachi Nandgaonkar
Created Date    : 22-Feb-2018
Modification Log:
---------------------------------------------------------------------------------- 
Developer                   Date                   Description
-----------------------------------------------------------------------------------            
Mayuresh Patil          22-Feb-2018              Initial Version
Mayuresh Patil          28-Mar-2018              Updated FLS checks and null checks
Mayuresh Patil          29-Mar-2018              PC-2940 End Active Support Plan when Last task is completed
Mayuresh Patil          03-Apr-2018              PC-2917 Added logic for "wait until true" condition behavior
Tejas Patel             04-Mar-2019              PC-4478 Running Group Activities All at once new feature
Tejas Patel             19-Apr-2019              PC-4748 Dynamic Query issue with OR condition introduced brackets.
Tejas Patel             11-Oct-2019              PC-5575 PC-5545 Multiple Support Plans and Previous Task completion
Tejas Patel             15-Oct-2019              PC-5607 SPRT name should not be dependent of User Input Field SP Name
Tejas Patel             31-Oct-2019              PC-5575 Multiple Support Plans, now supported.
Haritha Reddy           15-Apr-2020              PC-6033 Modified logic to support all Objects and new Actions "Create Record" & "Publish Platform Event".
                                                 Also, modified the way of processing Support Plans by using new Platform Event "Support Plan Info"
                                                 to avoid hitting governor limits
Haritha Reddy           04-Jun-2020              PC-6339 Updated logic to trigger next activity when current activity is closed with any of the closed Task Status
Haritha Reddy           11-Jun-2020              PC-6334 Updated logic to reuse evaluate method in SP for SPA Criteria evaluation.
                                                 Removed old method which was used for evaluating Support Plan Activity Criteria.
Haritha Reddy           18-Jun-2020              PC-6336 Updated logic to set Task Owner as Running User when the value is empty.
Haritha Reddy           23-Jun-2020              PC-6453 Moved parseDatetimeFromJSON() method to PC_Utility
Haritha Reddy           30-Jul-2020              PC-6593 Made changes to support Time field
Haritha Reddy           21-Aug-2020              PC-6719 Added new method for creating Error Task
Haritha Reddy           06-Oct-2020              PC-6792 Modified Support Plan execution logic to stop executing in Recursive Scenario.
Haritha Reddy           13-Oct-2020              PC-6332 Modified logic to evaluate custom Condition Logic
Haritha Reddy           23-Oct-2020              PC-6916 Removing namespace prefix as the sObject picklist values in trigger handler register doesn't contain namespace prefix.
Haritha Reddy           23-Oct-2020              PC-6912 Modified logic to run support plan once / multiple times based on the behavior opted.
Haritha Reddy           29-Oct-2020              PC-6935 Modified logic to evaluate 'To' value when 'Has changed' operator is used in Insert trigger event.
Haritha Reddy           03-Nov-2020              PC-6952 Modified logic to set default value of current activity status field in SP Runtime to 'In progress' from 'pending'
Haritha Reddy           03-Nov-2020              PC-6911 Updated logic to create error task when invalid number value is given in "Maximum Support Plan Recursions allowed" setting.
Haritha Reddy           04-Nov-2020              PC-6946 Modified logic to create Support Plan Activity log when recursion error task is created
Haritha Reddy           10-Nov-2020              PC-6893 Force reviewer scan issue fixes
Haritha Reddy           11-Nov-2020              PC-6938 Added logic to not run SP again if behaviour is set to 'RunEveryTimeIfNoPendingRuntime' & pending runtimes exist for that record.
Haritha Reddy           30-Nov-2020              PC-7001 Modified logic to sort Conditions of condition logic in descending order
Haritha Reddy           21-Jan-2021             [PC-7102] Added FLS Check
Haritha Reddy           09-Feb-2021              PC-7391 Modified logic to replace Runtime record in list instead of adding duplicate
Haritha Reddy           09-Feb-2021              PC-7397 Modified logic to not create new SupportPlanActivity Log with completed status when Task is reopened & closed again
Haritha Reddy           03-Mar-2021             [PC-7486] Made changes to populate Assign to role field during task creation
Haritha Reddy           16-Mar-2021             [PC-7530] Added record Id filter to Support plan runtime query during trigger condition evaluation
Haritha Reddy           05-Apr-2021             [PC-6629] Added new methods to evaluate Contains and does not contains condition
Haritha Reddy           09-Apr-2021             [PC-7618] Made changes related to exception handling
Kanteti Kishore         13 Apr 2021             [PC-7009] Made changes to createTask Method-Wrapper reference changed from RequiredFieldWrapper to FieldMap in PC_AutomationTaskHelper
Haritha Reddy           19-Apr-2021             [PC-6629] Made changes to support multiselect picklist field evaluation for all operators with out considering order of field values
Haritha Reddy           27-Apr-2021             [PC-7691] Made changes to evaluate condition on multiselect picklist field when null values are given
Haritha Reddy           28-Apr-2021             [PC-7722] Added support plan activity check while creating complted Support Plan Activity log for task
Haritha Reddy           05-May-2021             [PC-7736} Modified logic to not throw error when condition is not met for >, >=, <, <= operators
Hitha Avalakki          10-May-2021             [PC-7666] Added code to support formula date/datetime values for user task creation
Haritha Reddy           01-Jul-2021             [PC-7869] Modified Queries to avoid hitting non selective query issue.
Haritha Reddy           02-Aug-2021             [PC-8023] Made Changes related to Multiselect picklist field evaluation
Hitha Avalakki          19-Aug-2021             [PC-8079] Made changes related to decoupling the need of Task WhatId in BRE
Haritha Reddy           27-Aug-2021             [PC-8079] Made changes to assign task owner id based on related record instead of Trigger record if both are different.
Haritha Reddy           24-Nov-2021             [PC-8361] Updated Logic to fix the issue of duplicate tasks getting created when bulk case insert is done with multiple engagement programs.
Haritha Reddy           18-Jan-2022             [PC-8454] Updated Logic to handle SPA Criteria evaluation when Trigger Object and Previous Activity type object are same
Chetna Mohapatra        21-Feb-2022             [PC-8464] Added handleObjectsWithActivitiesDisabled() method to handle error logging for SP Trigger objects that
                                                          don't have activities enabled to process related User & Automation Task.
Satheesh Kumar          12-Oct-2022             [PC-9262] Added condition to avoid removing namespace prefix from sObject when sobject contains no namespace.
*********************************************************************************/

public with sharing class PC_SupportPlanEngine{
    /**
    * This method will fetch Support Plans that matches Support Plan Rule criteria for a record
    * @param supportPlanEventList  The list of Support Plan Info Platform Events that will be considered for evaluating records
    */
    public static List<SupportPlanInfo> getRecordsMatchingSupportPlanCriteria(List<PC_SupportPlanInfo__e> supportPlanEventList) {
        List<SupportPlanInfo> filteredSupportPlanInfoList = new List<SupportPlanInfo>();
        List<String> supportPlanIdList = new List<String>();
        List<String> recordIdList = new List<String>();
        //populate Trigger object RecordId, Support Plan Id List that need to be queried.
        for(PC_SupportPlanInfo__e supportPlanEvent:supportPlanEventList){
            supportPlanIdList = supportPlanEvent.PC_SupportPlanOrRuntimeIds__c.split(',');
            recordIdList.add(supportPlanEvent.PC_RecordId__c);
        }
        //FLS Check for PC_SupportPlan__c
        List<String> supportPlanFields = new List<String>{'Id','Name',PC_Constants.getQualifiedAPIName('PC_Conditional_Logic__c'),
                PC_Constants.getQualifiedAPIName('PC_ConditionBehavior__c'),PC_Constants.getQualifiedAPIName('PC_Condition_Option__c'),
                PC_Constants.getQualifiedAPIName('PC_StartCondition__c')
        };
        PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_SupportPlan__c'), PC_Database.Operation.Reading, supportPlanFields);
        Map<ID, PC_SupportPlan__c> supportPlanMap = new Map<ID, PC_SupportPlan__c>([Select Id, Name,
                PC_Conditional_Logic__c,PC_ConditionBehavior__c,PC_Condition_Option__c,PC_StartCondition__c
        FROM PC_SupportPlan__c WHERE PC_IsActive__c = true  AND Id IN: supportPlanIdList]);

        if(supportPlanMap != null && !supportPlanMap.isEmpty()){
            //Fetch Fields to be queried from SObject record without any duplicates
            List<String> fieldsList = getSObjectFieldsToQuery(supportPlanMap.values());
            //Query Records to be evaluated
            List<SObject> sObjectList = new List<SObject>();
            String sObjectName;
            if(!recordIdList.isEmpty()){
                sObjectName = ((Id)recordIdList[0]).getSobjectType().getDescribe().getName();
            }
            if(!fieldsList.isEmpty()){
                PC_Database.assertAccess(sObjectName, PC_Database.Operation.Reading, fieldsList);
                String sObjectFields = String.join(fieldsList, ',');
                String recordsQuery = 'Select Id,' +sObjectFields +' from '+ sObjectName +' where Id IN:recordIdList';
                sObjectList = Database.query (recordsQuery);
            }
            Map<String, Id> recordTypeIdMap =  PC_AutomationTaskHelper.getSObjectRecordTypeMap(sObjectName);
            //For each support plan, evaluate record and add it to the list to be returned, if Rule criteria is satisfied
            for(PC_SupportPlanInfo__e supportPlanInfo: supportPlanEventList){
                SObject record;
                if(!sObjectList.isEmpty()){
                    for(SObject sObjectRec: sObjectList){
                        if(sObjectRec.Id == supportPlanInfo.PC_RecordId__c){
                            record = sObjectRec;
                        }
                    }
                }
                for(String supportPlanId: supportPlanInfo.PC_SupportPlanOrRuntimeIds__c.split(',')){
                    PC_SupportPlan__c supportPlanToEvaluate = supportPlanMap.get(supportPlanId);
                    if(supportPlanToEvaluate != null){
                        if(supportPlanToEvaluate.PC_ConditionBehavior__c == PC_Constants.SUPPORTPLAN_CONDBEHAVIOR_STATUS_NONE
                                || evaluateSupportPlanCriteria(supportPlanToEvaluate, record, recordTypeIdMap,supportPlanInfo) == true) {
                            List<String> filteredSupportPlanIdList = new List<String>();
                            filteredSupportPlanIdList.add(supportPlanId);
                            SupportPlanInfo filteredSupportPlanInfo = new SupportPlanInfo();
                            filteredSupportPlanInfo.supportPlanIdList = filteredSupportPlanIdList;
                            filteredSupportPlanInfo.recordId = supportPlanInfo.PC_RecordId__c;
                            filteredSupportPlanInfo.runtimeUserId = supportPlanInfo.PC_RuntimeUserId__c;
                            filteredSupportPlanInfo.context = PC_Constants.SupportPlanInfoContext.ExecuteActions;
                            filteredSupportPlanInfo.triggerRecordModifiedTime = supportPlanInfo.PC_TriggerRecordModifiedTime__c;
                            system.debug('lastDate2>>'+supportPlanInfo.PC_TriggerRecordModifiedTime__c);
                            filteredSupportPlanInfoList.add(filteredSupportPlanInfo);
                        }
                    }
                }
            }
        }

        return filteredSupportPlanInfoList;
    }

    /*********************************************************************************
    Method Name    : evaluateSupportPlanCriteria
    Author         : Haritha Reddy
    Description    : This method evaluates Support Plan Rule criteria
    Return Type    : Boolean
    Parameter      : supportPlan, record, recordTypeIdMap, supportPlanInfo
    *********************************************************************************/
    private static Boolean evaluateSupportPlanCriteria(PC_SupportPlan__c supportPlan, SObject record, Map<String, Id> recordTypeIdMap, PC_SupportPlanInfo__e supportPlanInfo) {
        Boolean isSupportPlanCriteriaSatisfied;
        if(supportPlan.PC_Condition_Option__c ==  PC_Constants.PC_COND_OPTION_APEX_CLASS){
            isSupportPlanCriteriaSatisfied = evaluateApexCondition(supportPlan.PC_StartCondition__c, supportPlanInfo.PC_RecordId__c);
        }else if(supportPlan.PC_Condition_Option__c ==  PC_Constants.PC_COND_OPTION_CONDITIONAL_BUILDER){
            isSupportPlanCriteriaSatisfied = evaluateConditionLogic(supportPlan.PC_Conditional_Logic__c, record, null, recordTypeIdMap,supportPlan.Name, null,supportPlanInfo.PC_RuntimeUserId__c);
        }
        return isSupportPlanCriteriaSatisfied;
    }

    /*********************************************************************************
    Method Name    : getSObjectFieldsToQuery
    Author         : Haritha Reddy
    Description    : This method reads Condition Logic JSON and returns list of fields in SObject that need to be queried
    Return Type    : fieldsList
    Parameter      : PC_SupportPlanActivity__c, CaseId
    *********************************************************************************/
    private static List<String> getSObjectFieldsToQuery(List<PC_SupportPlan__c> supportPlanList) {
        Set<String> fieldsSet = new Set<String>();
        for(PC_SupportPlan__c supportPlan : supportPlanList){
            if(supportPlan.PC_Condition_Option__c == PC_Constants.PC_COND_OPTION_CONDITIONAL_BUILDER){
                if(String.isNotEmpty(supportPlan.PC_Conditional_Logic__c)){
                    ConditionLogicList conditionLogicList = new ConditionLogicList();
                    conditionLogicList = (ConditionLogicList) System.JSON.deserialize(supportPlan.PC_Conditional_Logic__c,ConditionLogicList.class);
                    List<ConditionLogic> LstConditionsPerObject = conditionLogicList.LstConditionsPerObject;
                    List<Condition> conditionList = new List<Condition>();
                    String objectType,logic;

                    for(ConditionLogic lstCondition : LstConditionsPerObject){
                        objectType  = lstCondition.ObjectType;
                        conditionList  = lstCondition.Conditions;
                        logic       = lstCondition.Logic;
                    }
                    for (Condition condition : conditionList) {
                        if(condition.FieldApiName != PC_Constants.PC_RecordTypeDeveloperName){
                            fieldsSet.add(condition.FieldApiName);
                        }else{
                            fieldsSet.add(PC_Constants.PC_RECORD_TYPE_ID);
                        }
                    }
                }
            }
        }
        List<String> fieldsList = new List<String>();
        fieldsList.addAll(fieldsSet);
        return fieldsList;
    }

    /**
    * This method publishes Support Plan Info platform event for each Record that matches Support Plan Criteria
    * @param supportPlanInfoList  Support Plan Info Wrapper List for which platform event is published for
    *                             each record and corresponding Support Plan Ids or Runtime ids with context
    */
    public static void publishSupportPlanPlatformEvent(List<SupportPlanInfo> supportPlanInfoList) {
        List<PC_SupportPlanInfo__e> supportPlanInfoEventList = new List<PC_SupportPlanInfo__e>();
        if(supportPlanInfoList != null && !supportPlanInfoList.isEmpty()){
            for(SupportPlanInfo supportPlanInfo : supportPlanInfoList){
                String supportPlanIdList;
                if(!supportPlanInfo.supportPlanIdList.isEmpty()){
                    for(String supportPlanId: supportPlanInfo.supportPlanIdList){
                        if(String.isNotEmpty(supportPlanIdList)){
                            supportPlanIdList = supportPlanIdList+','+supportPlanId;
                        }else{
                            supportPlanIdList = supportPlanId;
                        }
                    }
                }
                PC_SupportPlanInfo__e supportPlanInfoEvent = new PC_SupportPlanInfo__e(
                        PC_RecordId__c                    = supportPlanInfo.recordId,
                        PC_TriggerRecordModifiedTime__c   = supportPlanInfo.triggerRecordModifiedTime,
                        PC_TransactionId__c               = supportPlanInfo.transactionId,
                        PC_Context__c                     = String.valueOf(supportPlanInfo.context),
                        PC_RuntimeUserId__c               = supportPlanInfo.runtimeUserId
                );
                if(String.isNotEmpty(supportPlanIdList)){
                    supportPlanInfoEvent.PC_SupportPlanOrRuntimeIds__c = supportPlanIdList;
                }else if(String.isNotEmpty(supportPlanInfo.runtimeId)){
                    supportPlanInfoEvent.PC_SupportPlanOrRuntimeIds__c = supportPlanInfo.runtimeId;
                }
                supportPlanInfoEventList.add(supportPlanInfoEvent);
            }
        }
        List<Database.SaveResult> resultList = new List<Database.SaveResult>();
        if(supportPlanInfoEventList.size() > 0) {
            resultList = EventBus.publish(supportPlanInfoEventList);
        }
        for (Database.SaveResult result : resultList) {
            if (result.isSuccess()) {
                System.debug('Platform Event published');
            } else {
                for(Database.Error err : result.getErrors()) {
                    System.debug('Error returned: ' +err.getStatusCode() +' - ' +err.getMessage());
                }
            }
        }

    }

    /**
    * This method returns Map of Record and corresponding Support Plans whose Trigger Event Conditions are met
    * @param newRecordList  updated record List
    * @param oldRecordMap  Map of Id and old records with previous values before getting updated
    * @param eventType  any event from insert, update, upsert
    * @param objectType API Name of Object along with namespace
    */
    public static List<SupportPlanInfo> getRecordsMatchingSupportPlanTriggerCriteria(List<SObject> newRecordList, Map<Id, SObject> oldRecordMap,PC_Constants.ObjectOperation eventType,String objectType){
        List<SupportPlanInfo> recordsMatchingSupportPlanCriteria = new List<SupportPlanInfo>();
        /*FLS Check for PC_SupportPlan__c*/
        List<String> supportPlanFields = new List<String>{'Id','Name',
                PC_Constants.getQualifiedAPIName('PC_TriggerEventType__c'),
                PC_Constants.getQualifiedAPIName('PC_TriggerEventObject__c'),
                PC_Constants.getQualifiedAPIName('PC_TriggerEventConditionalBehavior__c'),
                PC_Constants.getQualifiedAPIName('PC_TriggerEventCondition__c'),
                PC_Constants.getQualifiedAPIName('PC_IsActive__c'),
                PC_Constants.getQualifiedAPIName('PC_SupportPlan_Behavior__c')
        };
        PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_SupportPlan__c'), PC_Database.Operation.Reading, supportPlanFields);

        String triggerEvent;
        if(eventType == PC_Constants.ObjectOperation.oINSERT){
            triggerEvent = '%' + PC_Constants.PC_TRIGGER_EVENT_INSERT + '%';
        }else if(eventType == PC_Constants.ObjectOperation.oUPDATE){
            triggerEvent = '%' +PC_Constants.PC_TRIGGER_EVENT_UPDATE + '%';
        }

        List<PC_SupportPlan__c> supportPlansMatchingTriggerEvent = new List<PC_SupportPlan__c>();
        supportPlansMatchingTriggerEvent = [Select Id,Name,PC_TriggerEventType__c,PC_TriggerEventObject__c,PC_TriggerEventConditionalBehavior__c,
                PC_TriggerEventCondition__c,PC_SupportPlan_Behavior__c FROM PC_SupportPlan__c
                WHERE PC_IsActive__c = true AND PC_TriggerEventObject__c =:objectType AND PC_TriggerEventType__c Like: triggerEvent];

        List<PC_SupportPlan__c> filteredSupportPlansMatchingTriggerEvent = new List<PC_SupportPlan__c>();
        Set<Id> supportPlanIdsToNotRun = new Set<Id>();
        if(eventType != PC_Constants.ObjectOperation.oINSERT){
            /* FLS Check for PC_SupportPlanRuntime__c*/
            List<String> supportPlanRuntimeFields = new List<String>{'Id',PC_Constants.getQualifiedAPIName('PC_SupportPlan__c'),
                    PC_Constants.getQualifiedAPIName('PC_SupportPlanCase__c'), PC_Constants.getQualifiedAPIName('PC_RecordId__c'),
                    PC_Constants.getQualifiedAPIName('PC_CurrentActivityStatus__c'),
                    PC_Constants.getQualifiedAPIName('PC_SupportPlan__r')+'.'+PC_Constants.getQualifiedAPIName('PC_SupportPlan_Behavior__c')};
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_SupportPlanRuntime__c'), PC_Database.Operation.Reading, supportPlanRuntimeFields);

            //fetch existing Support Plan Runtimes
            Set<Id> recordIds = (new Map<Id,SObject>(newRecordList)).keySet();
            Set<Id> supportPlanIds = (new Map<Id,SObject>(supportPlansMatchingTriggerEvent)).keySet();
            List<PC_SupportPlanRuntime__c> supportPlanRuntimes = [SELECT Id, PC_SupportPlanCase__c, PC_RecordId__c, PC_SupportPlan__c,PC_CurrentActivityStatus__c,
                    PC_SupportPlan__r.PC_SupportPlan_Behavior__c FROM PC_SupportPlanRuntime__c
                    WHERE PC_SupportPlan__c IN: supportPlanIds AND (PC_SupportPlanCase__c IN: recordIds OR PC_RecordId__c IN: recordIds)];

            if(supportPlanRuntimes != null && !supportPlanRuntimes.isEmpty()){
                for(SObject record: newRecordList){
                    for(PC_SupportPlanRuntime__c runtime: supportPlanRuntimes){
                        if(runtime.PC_SupportPlan__r.PC_SupportPlan_Behavior__c	 == String.valueOf(PC_Constants.SupportPlanBehaviour.RunOncePerRecord) &&
                                (record.Id == runtime.PC_SupportPlanCase__c || record.Id == runtime.PC_RecordId__c)){
                            //add the support plan Id to list if runtime exists already with same support plan and record id
                            supportPlanIdsToNotRun.add(runtime.PC_SupportPlan__c);
                        }else if(runtime.PC_CurrentActivityStatus__c != PC_Constants.SUPPORTPLANRT_ACTIVITY_STATUS_COMPLETED &&
                                runtime.PC_SupportPlan__r.PC_SupportPlan_Behavior__c == String.valueOf(PC_Constants.SupportPlanBehaviour.RunEveryTimeIfNoPendingRuntime) &&
                                (record.Id == runtime.PC_SupportPlanCase__c || record.Id == runtime.PC_RecordId__c)){
                            //add the support plan Id to list if pending runtime exists already with same support plan and record id
                            supportPlanIdsToNotRun.add(runtime.PC_SupportPlan__c);
                        }
                    }
                }
            }
        }
        for(PC_SupportPlan__c supportPlan:supportPlansMatchingTriggerEvent){
            if(!supportPlanIdsToNotRun.contains(supportPlan.Id)){
                filteredSupportPlansMatchingTriggerEvent.add(supportPlan);
            }
        }
        Map<SObject,List<PC_SupportPlan__c>> supportPlansMatchingTriggerEventAndEP = new Map<SObject,List<PC_SupportPlan__c>>();
        if(!filteredSupportPlansMatchingTriggerEvent.isEmpty()){
            //Engagement Program Check
            supportPlansMatchingTriggerEventAndEP = getSupportPlansMatchingEngagementProgram(filteredSupportPlansMatchingTriggerEvent,newRecordList,objectType);
        }
        if(!supportPlansMatchingTriggerEventAndEP.isEmpty()){
            //Trigger Condition Check
            recordsMatchingSupportPlanCriteria = getRecordsMatchingSupportPlanTriggerCondition(supportPlansMatchingTriggerEventAndEP, objectType, oldRecordMap);
        }
        system.debug('recordsMatchingSupportPlanCriteria>>'+recordsMatchingSupportPlanCriteria);
        return recordsMatchingSupportPlanCriteria;
    }

    /*********************************************************************************
    Method Name    : getSupportPlansMatchingEngagementProgram
    Description    : This method returns List of Support Plans that matches the Engagement Program on the Record
    Return Type    : Boolean
    Parameter      : supportPlansMatchingTriggerEvent, newRecordList, objectType
    *********************************************************************************/
    private static Map<SObject, List<PC_SupportPlan__c>> getSupportPlansMatchingEngagementProgram(List<PC_SupportPlan__c> supportPlansMatchingTriggerEvent,List<SObject> newRecordList, String objectType) {
        Map<SObject, List<PC_SupportPlan__c>> recordToSupportPlansMatchingEPMap = new Map<SObject, List<PC_SupportPlan__c>>();
        if(objectType == PC_Constants.PC_CASE) {
            Set<Id> engagementProgramIds = new Set<Id>();
            List<Case> caseList = (List<Case>) newRecordList;
            for (Case caseRec : caseList) {
                engagementProgramIds.add(caseRec.PC_Engagement_Program__c);
            }
            List<PC_EngagementProgram_SupportPlan__c> engagementSupportPlanList = new List<PC_EngagementProgram_SupportPlan__c>();
            if (!engagementProgramIds.isEmpty()) {
                /*FLS Check for PC_EngagementProgram_SupportPlan__c*/
                List<String> supportPlanEPFields = new List<String>{'Id',
                        PC_Constants.getQualifiedAPIName('PC_EngagementProgram__c'),
                        PC_Constants.getQualifiedAPIName('PC_SupportPlan__c')
                };
                PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_EngagementProgram_SupportPlan__c'), PC_Database.Operation.Reading, supportPlanEPFields);

                engagementSupportPlanList = [SELECT Id, PC_EngagementProgram__c, PC_SupportPlan__c FROM PC_EngagementProgram_SupportPlan__c
                WHERE PC_EngagementProgram__c IN :engagementProgramIds AND PC_SupportPlan__c IN: supportPlansMatchingTriggerEvent];
            }
            Map<Id, PC_SupportPlan__c> supportPlanMap = new Map<Id, PC_SupportPlan__c>(supportPlansMatchingTriggerEvent);
            for (Case caseRec : caseList) {
                Set<PC_SupportPlan__c> filteredSPSet = new Set<PC_SupportPlan__c>();
                List<PC_SupportPlan__c> supportPlansMatchingEP = new List<PC_SupportPlan__c>();
                for(PC_EngagementProgram_SupportPlan__c engagementSupportPlan : engagementSupportPlanList) {
                    if(engagementSupportPlan.PC_EngagementProgram__c == caseRec.PC_Engagement_Program__c){
                        filteredSPSet.add(supportPlanMap.get(engagementSupportPlan.PC_SupportPlan__c));
                    }
                }
                system.debug('caseRec>>'+caseRec.caseNumber);
                system.debug('filteredSPSet>>'+filteredSPSet);
                supportPlansMatchingEP.addAll(filteredSPSet);
                recordToSupportPlansMatchingEPMap.put((SObject)caseRec, supportPlansMatchingEP);
            }
        }else{
            for(SObject sObjectRecord : newRecordList) {
                recordToSupportPlansMatchingEPMap.put(sObjectRecord, supportPlansMatchingTriggerEvent);
            }
        }
        system.debug('recordToSupportPlansMatchingEPMap>>'+recordToSupportPlansMatchingEPMap);
        return recordToSupportPlansMatchingEPMap;
    }

    /*********************************************************************************
    Method Name    : getRecordsMatchingSupportPlanTriggerCondition
    Description    : This method returns Records that matches Trigger Condition in Support Plans
    Return Type    : List<SupportPlanInfo>
    Parameter      : supportPlansMatchingTriggerEventAndEP, objectType, oldRecordMap
    *********************************************************************************/
    private static List<SupportPlanInfo> getRecordsMatchingSupportPlanTriggerCondition(Map<SObject, List<PC_SupportPlan__c>> supportPlansMatchingTriggerEventAndEP, String objectType, Map<Id, SObject> oldRecordMap) {
        List<SupportPlanInfo> supportPlanInfoList = new List<SupportPlanInfo>();
        Map<String, Id> recordTypeIdMap =  PC_AutomationTaskHelper.getSObjectRecordTypeMap(objectType);

        for(SObject newRecord: supportPlansMatchingTriggerEventAndEP.keySet()){
            List<String> supportPlanList = new List<String>();
            for(PC_SupportPlan__c supportPlan: supportPlansMatchingTriggerEventAndEP.get(newRecord)){
                system.debug('Evaluating Trigger condition for supportPlan: >>'+supportPlan.Id);
                if(supportPlan.PC_TriggerEventConditionalBehavior__c == PC_Constants.SUPPORTPLAN_CONDBEHAVIOR_STATUS_WAIT) {
                    SObject oldRecord;
                    if(oldRecordMap != null){
                        oldRecord = oldRecordMap.get(newRecord.Id);
                    }
                    //evaluate Trigger Event Condition and add it to the List if satisfied
                    if(evaluateConditionLogic(supportPlan.PC_TriggerEventCondition__c,newRecord,oldRecord, recordTypeIdMap,supportPlan.Name,null,userInfo.getUserId()) == true){
                        supportPlanList.add(supportPlan.Id);
                    }
                }else{
                    supportPlanList.add(supportPlan.Id);
                }
            }
            if(!supportPlanList.isEmpty()){
                SupportPlanInfo supportPlanInfo = new SupportPlanInfo();
                supportPlanInfo.recordId = newRecord.Id;
                supportPlanInfo.runtimeUserId = userInfo.getUserId();
                supportPlanInfo.supportPlanIdList = supportPlanList;
                supportPlanInfo.context = PC_Constants.SupportPlanInfoContext.EvaluateRuleCriteria;
                supportPlanInfo.triggerRecordModifiedTime = DateTime.valueOf(newRecord.get('LastModifiedDate'));
                system.debug('LastModifiedDate>>'+supportPlanInfo.triggerRecordModifiedTime);
                supportPlanInfoList.add(supportPlanInfo);
            }
        }
        return supportPlanInfoList;
    }

    /*********************************************************************************
    Method Name    : evaluateConditionLogic
    Description    : This method evaluates Condition Logic and returns true if record matches condition Logic. Else, false.
    Return Type    : Boolean
    Parameter      : condition, newRecord, oldRecord, recordTypeIdMap, supportPlanName, supportPlanActivityId, runningUserId
    *********************************************************************************/
    public static Boolean evaluateConditionLogic(String conditionLogicJSON, SObject newRecord, SObject oldRecord, Map<String, Id> recordTypeIdMap,String supportPlanName,Id supportPlanActivityId, Id runningUserId){
        Boolean isConditionSatisfied = false;
        try{
            if(string.isNotEmpty(conditionLogicJSON)){
                ConditionLogicList conditionLogicList = new ConditionLogicList();
                conditionLogicList = (ConditionLogicList) System.JSON.deserialize(conditionLogicJSON,ConditionLogicList.class);
                List<ConditionLogic> LstConditionsPerObject = conditionLogicList.LstConditionsPerObject;
                List<Condition> conditionList = new List<Condition>();
                String objectType,logic;

                for(ConditionLogic lstCondition : LstConditionsPerObject){
                    objectType  = lstCondition.ObjectType;
                    conditionList  = lstCondition.Conditions;
                    logic       = lstCondition.Logic;
                }
                String customLogicExepression = logic;
                conditionList.sort();
                for (Condition condition : conditionList) {
                    system.debug('condition>>'+condition);
                    isConditionSatisfied = false;
                    if(String.isNotEmpty(condition.FieldApiName)) {
                        if (condition.Operator == PC_Constants.PC_HAS_CHANGED) {
                            isConditionSatisfied = evaluateHasChangedCondition(condition, newRecord, oldRecord, recordTypeIdMap);
                        } else if (condition.Operator == PC_Constants.PC_HAS_NOT_CHANGED) {
                            isConditionSatisfied = evaluateHasNotChangedCondition(condition, newRecord, oldRecord, recordTypeIdMap);
                        } else if (condition.Operator == PC_Constants.PC_IS_NOT_NULL) {
                            isConditionSatisfied = evaluateIsNotNullCondition(condition, newRecord, recordTypeIdMap);
                        } else if (condition.Operator == PC_Constants.PC_IS_NULL) {
                            isConditionSatisfied = evaluateIsNullCondition(condition, newRecord, recordTypeIdMap);
                        } else if (condition.Operator == PC_Constants.PC_EQUALS) {
                            isConditionSatisfied = evaluateEqualsCondition(condition, newRecord, recordTypeIdMap);
                        } else if (condition.Operator == PC_Constants.PC_DOESNOT_EQUALS) {
                            isConditionSatisfied = evaluateNotEqualsCondition(condition, newRecord, recordTypeIdMap);
                        } else if (condition.Operator == PC_Constants.PC_GREATER_THAN) {
                            isConditionSatisfied = evaluateGreaterThanCondition(condition, newRecord);
                        } else if (condition.Operator == PC_Constants.PC_GREATER_THAN_OR_EQUALS) {
                            isConditionSatisfied = evaluateGreaterThanOrEqualsCondition(condition, newRecord);
                        } else if (condition.Operator == PC_Constants.PC_LESS_THAN) {
                            isConditionSatisfied = evaluateLessThanCondition(condition, newRecord);
                        } else if (condition.Operator == PC_Constants.PC_LESS_THAN_OR_EQUALS) {
                            isConditionSatisfied = evaluateLessThanOrEqualsCondition(condition, newRecord);
                        } else if (condition.Operator == PC_Constants.PC_CONTAINS) {
                            isConditionSatisfied = evaluateContainsCondition(condition, newRecord);
                        } else if (condition.Operator == PC_Constants.PC_DOES_NOT_CONTAINS) {
                            isConditionSatisfied = evaluateDoesNotContainsCondition(condition, newRecord);
                        }else{
                            //Throw error for unsupported operators
                            PC_SupportPlanEngine.SupportPlan_Exception supportPlanException = new PC_SupportPlanEngine.SupportPlan_Exception();
                            List<Object> formattingArguments = new List<Object>{condition.Operator};
                            supportPlanException.setMessage(String.format(Label.PC_SupportPlan_UnsupportedOperator, formattingArguments));
                            throw supportPlanException;
                        }
                    }else{
                        //Ignore the condition if field API Name is empty
                        isConditionSatisfied = true;
                    }
                    system.debug('isConditionSatisfied>>'+isConditionSatisfied);
                    if(!(logic.contains('(') || logic.contains(')') || logic.contains('NOT') || (logic.contains('OR') && logic.contains('AND')))){
                        //If Logic contains only OR, exit the loop when at least one condition is satisfied
                        if (isConditionSatisfied && logic.contains('OR')) {
                            break;
                        }
                        //If Logic contains only AND, exit the loop when at least one condition is not satisfied
                        if (!isConditionSatisfied && logic.contains('AND')) {
                            break;
                        }
                    }else if(String.isNotEmpty(customLogicExepression)){
                        system.debug('customLogicExepression1>>'+customLogicExepression);
                        customLogicExepression = customLogicExepression.replace(String.valueOf(condition.ConditionNo),String.valueOf(isConditionSatisfied));
                    }
                }
                if(logic.contains('(') || logic.contains(')') || logic.contains('NOT') || (logic.contains('OR') && logic.contains('AND'))){
                    //evaluate Custom Logic
                    isConditionSatisfied = PC_Utility.evaluateCustomLogic(customLogicExepression);
                }
            }else{
                isConditionSatisfied = true;
            }
        }catch(Exception ex){
            isConditionSatisfied = false;
            String errorDescription = ex.getMessage()+ ' ' + Label.PC_SupportPlan +' '+supportPlanName;
            ex.setMessage(errorDescription);
            PC_Utility.ErrorInfoWrapper errorInfoWrapper = new PC_Utility.ErrorInfoWrapper(null,errorDescription,'PC_SupportPlanEngine','evaluateConditionLogic',ex.getLineNumber(),null,PC_Utility.ERROR_LOG_LEVEL.ERROR_LOG_LEVEL_ERROR,ex.getStackTraceString());
            PC_Utility.createExceptionLog(errorInfoWrapper);
            throw ex;
        }
        return isConditionSatisfied;
    }

    /*********************************************************************************
    Method Name    : getValueBasedOnDataType
    Description    : This method returns Field value based on data type
    Return Type    : Boolean
    Parameter      : fieldValue, FieldDataType
    *********************************************************************************/
    private static Object getValueBasedOnDataType(String value, String dataType) {
        if(String.isBlank(value)) {
            return null;
        }else{
            if (dataType == PC_Constants.PC_FIELD_TYPE_DATE) {
                return Date.valueOf(value);
            }else if (dataType == PC_Constants.PC_FIELD_TYPE_DATETIME) {
                return PC_Utility.parseDatetimeFromJSON(value);
            }else if (dataType == PC_Constants.PC_FIELD_TYPE_BOOLEAN) {
                return Boolean.valueOf(value);
            }else if (dataType == PC_Constants.PC_FIELD_TYPE_DOUBLE || dataType == PC_Constants.PC_FIELD_TYPE_PERCENT
                    || dataType == PC_Constants.PC_FIELD_TYPE_CURRENCY) {
                return Double.valueOf(value);
            }else if (dataType == PC_Constants.PC_FIELD_TYPE_INTEGER) {
                return Integer.valueOf(value);
            }else if (dataType == PC_Constants.PC_FIELD_TYPE_TIME) {
                return PC_Utility.parseTimeFromJSONString(value);
            }else {
                return value;
            }
        }
    }
    /*********************************************************************************
    Method Name    : evaluateHasChangedCondition
    Description    : This method returns true if record matches 'has changed' condition. Else, false.
    Return Type    : Boolean
    Parameter      : condition, newRecord, oldRecord, recordTypeIdMap
    *********************************************************************************/
    private static Boolean evaluateHasChangedCondition(Condition condition, SObject newRecord, SObject oldRecord, Map<String,Id> recordTypeIdMap) {
        Boolean isConditionSatisfied = false;
        if(oldRecord != null){
            if(condition.Value == PC_Constants.PC_ANY_VALUE && condition.changeToValue == PC_Constants.PC_ANY_VALUE){
                if(condition.FieldApiName != PC_Constants.PC_RecordTypeDeveloperName){
                    if(condition.Type == PC_Constants.PC_MULTIPICKLIST){
                        //Verify if multi picklist selections in old field value are not same as values given in new field value
                        String oldValue = String.valueOf(oldRecord.get(condition.FieldApiName));
                        String newValue = String.valueOf(newRecord.get(condition.FieldApiName));
                        if(doesNotEqualsMultipicklistValues(newValue,oldValue)){
                            isConditionSatisfied = true;
                        }
                    }else if(newRecord.get(condition.FieldApiName) != oldRecord.get(condition.FieldApiName)) {
                        isConditionSatisfied = true;
                    }
                }else if(newRecord.get(PC_Constants.PC_RECORD_TYPE_ID) != oldRecord.get(PC_Constants.PC_RECORD_TYPE_ID)) {
                        isConditionSatisfied = true;
                }
            }else if(condition.Value == PC_Constants.PC_ANY_VALUE && condition.changeToValue != PC_Constants.PC_ANY_VALUE){
                if(condition.FieldApiName != PC_Constants.PC_RecordTypeDeveloperName) {
                    if(condition.Type == PC_Constants.PC_MULTIPICKLIST){
                        //Verify if multi picklist selections in old field value are not same as values given in new field value
                        // and new value is same as the value give in condition
                        String oldValue = String.valueOf(oldRecord.get(condition.FieldApiName));
                        String newValue = String.valueOf(newRecord.get(condition.FieldApiName));
                        String toValue = String.valueOf(getValueBasedOnDataType(condition.changeToValue, condition.Type));
                        if(equalsMultipicklistValues(toValue,newValue) && doesNotEqualsMultipicklistValues(newValue,oldValue)){
                            isConditionSatisfied = true;
                        }
                    }else if(newRecord.get(condition.FieldApiName) == getValueBasedOnDataType(condition.changeToValue, condition.Type)
                            && newRecord.get(condition.FieldApiName) != oldRecord.get(condition.FieldApiName)) {
                        isConditionSatisfied = true;
                    }
                }else if(newRecord.get(PC_Constants.PC_RECORD_TYPE_ID) == recordtypeIdMap.get(condition.changeToValue)
                        && newRecord.get(PC_Constants.PC_RECORD_TYPE_ID) != oldRecord.get(PC_Constants.PC_RECORD_TYPE_ID)) {
                    isConditionSatisfied = true;
                }
            }else if(condition.Value != PC_Constants.PC_ANY_VALUE && condition.changeToValue == PC_Constants.PC_ANY_VALUE){
                if(condition.FieldApiName != PC_Constants.PC_RecordTypeDeveloperName) {
                    if(condition.Type == PC_Constants.PC_MULTIPICKLIST){
                        //Verify if multi picklist selections in old field value are not same as values given in new field value
                        // and old value is same as the value give in condition
                        String oldValue = String.valueOf(oldRecord.get(condition.FieldApiName));
                        String newValue = String.valueOf(newRecord.get(condition.FieldApiName));
                        String fromValue = String.valueOf(getValueBasedOnDataType(condition.Value, condition.Type));
                        if(equalsMultipicklistValues(fromValue,oldValue) && doesNotEqualsMultipicklistValues(newValue,oldValue)){
                            isConditionSatisfied = true;
                        }
                    }else if(oldRecord.get(condition.FieldApiName) == getValueBasedOnDataType(condition.Value, condition.Type)
                            && newRecord.get(condition.FieldApiName) != oldRecord.get(condition.FieldApiName)) {
                        isConditionSatisfied = true;
                    }
                } else if(oldRecord.get(PC_Constants.PC_RECORD_TYPE_ID) == recordtypeIdMap.get(condition.Value)
                        && newRecord.get(PC_Constants.PC_RECORD_TYPE_ID) != oldRecord.get(PC_Constants.PC_RECORD_TYPE_ID)) {
                    isConditionSatisfied = true;
                }
            }else if(condition.Value != PC_Constants.PC_ANY_VALUE && condition.changeToValue != PC_Constants.PC_ANY_VALUE){
                if(condition.FieldApiName != PC_Constants.PC_RecordTypeDeveloperName) {
                    if(condition.Type == PC_Constants.PC_MULTIPICKLIST){
                        //Verify if multi picklist selections in old field value are not same as values given in new field value,
                        //old value is same as the value give in condition and new value is same as the value give in condition
                        String oldValue = String.valueOf(oldRecord.get(condition.FieldApiName));
                        String newValue = String.valueOf(newRecord.get(condition.FieldApiName));
                        String fromValue = String.valueOf(getValueBasedOnDataType(condition.Value, condition.Type));
                        String toValue = String.valueOf(getValueBasedOnDataType(condition.changeToValue, condition.Type));
                        if(equalsMultipicklistValues(fromValue,oldValue) && equalsMultipicklistValues(toValue,newValue)
                                && doesNotEqualsMultipicklistValues(newValue,oldValue)){
                            isConditionSatisfied = true;
                        }
                    }else if(newRecord.get(condition.FieldApiName) == getValueBasedOnDataType(condition.changeToValue, condition.Type)
                            && oldRecord.get(condition.FieldApiName) == getValueBasedOnDataType(condition.Value, condition.Type)
                            && newRecord.get(condition.FieldApiName) != oldRecord.get(condition.FieldApiName)) {
                        isConditionSatisfied = true;
                    }
                } else if(newRecord.get(PC_Constants.PC_RECORD_TYPE_ID) == recordtypeIdMap.get(condition.changeToValue)
                        && oldRecord.get(PC_Constants.PC_RECORD_TYPE_ID) == recordtypeIdMap.get(condition.Value)
                        && newRecord.get(PC_Constants.PC_RECORD_TYPE_ID) != oldRecord.get(PC_Constants.PC_RECORD_TYPE_ID)) {
                    isConditionSatisfied = true;
                }
            }
        }else{
            if(condition.changeToValue == PC_Constants.PC_ANY_VALUE) {
                isConditionSatisfied = true;
            }else{
                if(condition.FieldApiName != PC_Constants.PC_RecordTypeDeveloperName){
                    if(newRecord.get(condition.FieldApiName) == getValueBasedOnDataType(condition.changeToValue, condition.Type)) {
                        isConditionSatisfied = true;
                    }
                }else if(newRecord.get(PC_Constants.PC_RECORD_TYPE_ID) == recordtypeIdMap.get(condition.changeToValue)) {
                    isConditionSatisfied = true;
                }
            }
        }
        return isConditionSatisfied;
    }
    /*********************************************************************************
    Method Name    : evaluateHasNotChangedCondition
    Description    : This method returns true if record matches 'has not changed' condition. Else, false.
    Return Type    : Boolean
    Parameter      : condition, newRecord, oldRecord, recordTypeIdMap
    *********************************************************************************/
    private static Boolean evaluateHasNotChangedCondition(Condition condition, SObject newRecord, SObject oldRecord, Map<String,Id> recordTypeIdMap) {
        Boolean isConditionSatisfied = false;
        if(oldRecord != null) {
            if (condition.FieldApiName != PC_Constants.PC_RecordTypeDeveloperName) {
                if(condition.Type == PC_Constants.PC_MULTIPICKLIST){
                    //Verify if multi picklist selections in old field value are same as values given in new field value
                    String oldValue = String.valueOf(newRecord.get(condition.FieldApiName));
                    String newValue = String.valueOf(oldRecord.get(condition.FieldApiName));
                    if(equalsMultipicklistValues(oldValue,newValue)){
                        isConditionSatisfied = true;
                    }
                }else if (newRecord.get(condition.FieldApiName) == oldRecord.get(condition.FieldApiName)) {
                    isConditionSatisfied = true;
                }
            } else if (newRecord.get(PC_Constants.PC_RECORD_TYPE_ID) == oldRecord.get(PC_Constants.PC_RECORD_TYPE_ID)) {
                isConditionSatisfied = true;
            }
        }else{
            //Ignore the has changed condition in case of Insert Event
            isConditionSatisfied = true;
        }
        return isConditionSatisfied;
    }

    /*********************************************************************************
    Method Name    : evaluateIsNullCondition
    Description    : This method returns true if record matches 'Is null' condition. Else, false.
    Return Type    : Boolean
    Parameter      : condition, newRecord, recordTypeIdMap
    *********************************************************************************/
    private static Boolean evaluateIsNullCondition(Condition condition, SObject newRecord, Map<String,Id> recordTypeIdMap) {
        Boolean isConditionSatisfied = false;
        if(condition.FieldApiName != PC_Constants.PC_RecordTypeDeveloperName){
            if(newRecord.get(condition.FieldApiName) == null) {
                isConditionSatisfied = true;
            }
        }else{
            if(newRecord.get(PC_Constants.PC_RECORD_TYPE_ID) == null) {
                isConditionSatisfied = true;
            }
        }
        return isConditionSatisfied;
    }

    /*********************************************************************************
    Method Name    : evaluateIsNullCondition
    Description    : This method returns true if record matches 'Is not null' condition. Else, false.
    Return Type    : Boolean
    Parameter      : condition, newRecord, recordTypeIdMap
    *********************************************************************************/
    private static Boolean evaluateIsNotNullCondition(Condition condition, SObject newRecord, Map<String,Id> recordTypeIdMap) {
        Boolean isConditionSatisfied = false;
        if(condition.FieldApiName != PC_Constants.PC_RecordTypeDeveloperName){
            if(newRecord.get(condition.FieldApiName) != null) {
                isConditionSatisfied = true;
            }
        }else{
            if(newRecord.get(PC_Constants.PC_RECORD_TYPE_ID) != null) {
                isConditionSatisfied = true;
            }
        }
        return isConditionSatisfied;
    }

    /*********************************************************************************
    Method Name    : evaluateEqualsCondition
    Description    : This method returns true if record matches 'Equals' condition. Else, false.
    Return Type    : Boolean
    Parameter      : condition, newRecord
    *********************************************************************************/
    private static Boolean evaluateEqualsCondition(Condition condition, SObject newRecord, Map<String,Id> recordTypeIdMap) {
        Boolean isConditionSatisfied = false;
        if(condition.FieldApiName != PC_Constants.PC_RecordTypeDeveloperName){
            if(condition.Type == PC_Constants.PC_MULTIPICKLIST){
                //Verify if multi picklist field values in record are same as values given in condition
                String recordFieldValue = String.valueOf(newRecord.get(condition.FieldApiName));
                String conditionFieldValue = String.valueOf(getValueBasedOnDatatype(condition.Value, condition.Type));
                if(equalsMultipicklistValues(conditionFieldValue,recordFieldValue)){
                    isConditionSatisfied = true;
                }
            }else if (newRecord.get(condition.FieldApiName) == getValueBasedOnDatatype(condition.Value, condition.Type)) {
                isConditionSatisfied = true;
            }
        }else if(recordtypeIdMap.containsKey(condition.value) && recordtypeIdMap.get(condition.value) == newRecord.get(PC_Constants.PC_RECORD_TYPE_ID)) {
            isConditionSatisfied = true;
        }
        return isConditionSatisfied;
    }

    /*********************************************************************************
   Method Name    : evaluateNotEqualsCondition
   Description    : This method returns true if record matches 'Not equals' condition. Else, false.
   Return Type    : Boolean
   Parameter      : condition, newRecord, recordTypeIdMap
   *********************************************************************************/
    private static Boolean evaluateNotEqualsCondition(Condition condition, SObject newRecord, Map<String,Id> recordTypeIdMap) {
        Boolean isConditionSatisfied = false;
        if(condition.FieldApiName != PC_Constants.PC_RecordTypeDeveloperName){
            if(condition.Type == PC_Constants.PC_MULTIPICKLIST){
                //Verify if multi picklist field value in record are not same as values given in condition
                String recordFieldValue = String.valueOf(newRecord.get(condition.FieldApiName));
                String conditionFieldValue = String.valueOf(getValueBasedOnDatatype(condition.Value, condition.Type));
                if(doesNotEqualsMultipicklistValues(conditionFieldValue,recordFieldValue)){
                    isConditionSatisfied = true;
                }
            }else if (newRecord.get(condition.FieldApiName) != getValueBasedOnDatatype(condition.Value, condition.Type)) {
                isConditionSatisfied = true;
            }
        }else if(recordtypeIdMap.containsKey(condition.value) && recordtypeIdMap.get(condition.value) != newRecord.get(PC_Constants.PC_RECORD_TYPE_ID)) {
            isConditionSatisfied = true;
        }
        return isConditionSatisfied;
    }

    /*********************************************************************************
   Method Name    : evaluateGreaterThanCondition
   Description    : This method returns true if record matches 'Greater Than' condition. Else, false.
   Return Type    : Boolean
   Parameter      : condition, newRecord
   *********************************************************************************/
    private static Boolean evaluateGreaterThanCondition(Condition condition, SObject newRecord) {
        Boolean isConditionSatisfied = false;
        if (condition.Type == PC_Constants.PC_FIELD_TYPE_DATE) {
            if(Date.valueOf(newRecord.get(condition.FieldApiName)) > Date.valueOf(condition.Value)){
                isConditionSatisfied = true;
            }
        } else if (condition.Type == PC_Constants.PC_FIELD_TYPE_INTEGER) {
            if(Integer.valueOf(newRecord.get(condition.FieldApiName)) > Integer.valueOf(condition.Value)){
                isConditionSatisfied = true;
            }
        } else if (condition.Type == PC_Constants.PC_FIELD_TYPE_DATETIME ) {
            if(DateTime.valueOf(newRecord.get(condition.FieldApiName)) > PC_Utility.parseDatetimeFromJSON(condition.Value)){
                isConditionSatisfied = true;
            }
        } else if (condition.Type == PC_Constants.PC_FIELD_TYPE_DOUBLE || condition.Type == PC_Constants.PC_FIELD_TYPE_PERCENT
                || condition.Type == PC_Constants.PC_FIELD_TYPE_CURRENCY) {
            if(Double.valueOf(newRecord.get(condition.FieldApiName)) > Double.valueOf(condition.Value)){
                isConditionSatisfied = true;
            }
        }else{
            //Throw error for unsupported field types
            PC_SupportPlanEngine.SupportPlan_Exception supportPlanException = new PC_SupportPlanEngine.SupportPlan_Exception();
            List<Object> formattingArguments = new List<Object>{condition.Operator,condition.Type};
            supportPlanException.setMessage(String.format(Label.PC_UnsupportedOperatorForFieldType, formattingArguments));
            throw supportPlanException;
        }
        return isConditionSatisfied;
    }

    /*********************************************************************************
      Method Name    : evaluateGreaterThanOrEqualsCondition
      Description    : This method returns true if record matches 'Greater than or equals' condition. Else, false.
      Return Type    : Boolean
      Parameter      : condition, newRecord
      *********************************************************************************/
    private static Boolean evaluateGreaterThanOrEqualsCondition(Condition condition, SObject newRecord) {
        Boolean isConditionSatisfied = false;
        if (condition.Type == PC_Constants.PC_FIELD_TYPE_DATE) {
            if(Date.valueOf(newRecord.get(condition.FieldApiName)) >= Date.valueOf(condition.Value)){
                isConditionSatisfied = true;
            }
        } else if (condition.Type == PC_Constants.PC_FIELD_TYPE_INTEGER) {
            if(Integer.valueOf(newRecord.get(condition.FieldApiName)) >= Integer.valueOf(condition.Value)){
                isConditionSatisfied = true;
            }
        } else if (condition.Type == PC_Constants.PC_FIELD_TYPE_DATETIME ) {
            if(DateTime.valueOf(newRecord.get(condition.FieldApiName)) >= PC_Utility.parseDatetimeFromJSON(condition.Value)){
                isConditionSatisfied = true;
            }
        } else if (condition.Type == PC_Constants.PC_FIELD_TYPE_DOUBLE || condition.Type == PC_Constants.PC_FIELD_TYPE_PERCENT
                || condition.Type == PC_Constants.PC_FIELD_TYPE_CURRENCY) {
            if(Double.valueOf(newRecord.get(condition.FieldApiName)) >= Double.valueOf(condition.Value)){
                isConditionSatisfied = true;
            }
        }else{
            //Throw error for unsupported field types
            PC_SupportPlanEngine.SupportPlan_Exception supportPlanException = new PC_SupportPlanEngine.SupportPlan_Exception();
            List<Object> formattingArguments = new List<Object>{condition.Operator,condition.Type};
            supportPlanException.setMessage(String.format(Label.PC_UnsupportedOperatorForFieldType, formattingArguments));
            throw supportPlanException;
        }

        return isConditionSatisfied;
    }

    /*********************************************************************************
   Method Name    : evaluateLessThanCondition
   Description    : This method returns true if record matches 'Less Than' condition. Else, false.
   Return Type    : Boolean
   Parameter      : condition, newRecord
   *********************************************************************************/
    private static Boolean evaluateLessThanCondition(Condition condition, SObject newRecord) {
        Boolean isConditionSatisfied = false;
        if (condition.Type == PC_Constants.PC_FIELD_TYPE_DATE) {
            if(Date.valueOf(newRecord.get(condition.FieldApiName)) < Date.valueOf(condition.Value)){
                isConditionSatisfied = true;
            }
        } else if (condition.Type == PC_Constants.PC_FIELD_TYPE_INTEGER) {
            if(Integer.valueOf(newRecord.get(condition.FieldApiName)) < Integer.valueOf(condition.Value)){
                isConditionSatisfied = true;
            }
        } else if (condition.Type == PC_Constants.PC_FIELD_TYPE_DATETIME ) {
            if(DateTime.valueOf(newRecord.get(condition.FieldApiName)) < PC_Utility.parseDatetimeFromJSON(condition.Value)){
                isConditionSatisfied = true;
            }
        } else if (condition.Type == PC_Constants.PC_FIELD_TYPE_DOUBLE || condition.Type == PC_Constants.PC_FIELD_TYPE_PERCENT
                || condition.Type == PC_Constants.PC_FIELD_TYPE_CURRENCY) {
            if(Double.valueOf(newRecord.get(condition.FieldApiName)) < Double.valueOf(condition.Value)){
                isConditionSatisfied = true;
            }
        }else{
            //Throw error for unsupported field types
            PC_SupportPlanEngine.SupportPlan_Exception supportPlanException = new PC_SupportPlanEngine.SupportPlan_Exception();
            List<Object> formattingArguments = new List<Object>{condition.Operator,condition.Type};
            supportPlanException.setMessage(String.format(Label.PC_UnsupportedOperatorForFieldType, formattingArguments));
            throw supportPlanException;
        }

        return isConditionSatisfied;
    }

    /*********************************************************************************
   Method Name    : evaluateLessThanOrEqualsCondition
   Description    : This method returns true if record matches 'Less than or equals' condition. Else, false.
   Return Type    : Boolean
   Parameter      : condition, newRecord
   *********************************************************************************/
    private static Boolean evaluateLessThanOrEqualsCondition(Condition condition, SObject newRecord) {
        Boolean isConditionSatisfied = false;
        if (condition.Type == PC_Constants.PC_FIELD_TYPE_DATE) {
            if(Date.valueOf(newRecord.get(condition.FieldApiName)) <= Date.valueOf(condition.Value)){
                isConditionSatisfied = true;
            }
        } else if (condition.Type == PC_Constants.PC_FIELD_TYPE_INTEGER) {
            if(Integer.valueOf(newRecord.get(condition.FieldApiName)) <= Integer.valueOf(condition.Value)){
                isConditionSatisfied = true;
            }
        } else if (condition.Type == PC_Constants.PC_FIELD_TYPE_DATETIME ) {
            if(DateTime.valueOf(newRecord.get(condition.FieldApiName)) <= PC_Utility.parseDatetimeFromJSON(condition.Value)){
                isConditionSatisfied = true;
            }
        } else if (condition.Type == PC_Constants.PC_FIELD_TYPE_DOUBLE || condition.Type == PC_Constants.PC_FIELD_TYPE_PERCENT
                || condition.Type == PC_Constants.PC_FIELD_TYPE_CURRENCY) {
            if(Double.valueOf(newRecord.get(condition.FieldApiName)) <= Double.valueOf(condition.Value)){
                isConditionSatisfied = true;
            }
        }else{
            //Throw error for unsupported field types
            PC_SupportPlanEngine.SupportPlan_Exception supportPlanException = new PC_SupportPlanEngine.SupportPlan_Exception();
            List<Object> formattingArguments = new List<Object>{condition.Operator,condition.Type};
            supportPlanException.setMessage(String.format(Label.PC_UnsupportedOperatorForFieldType, formattingArguments));
            throw supportPlanException;
        }

        return isConditionSatisfied;
    }

    /*********************************************************************************
    Method Name    : evaluateContainsCondition
    Description    : This method returns true if record matches 'Contains' condition. Else, false.
    Return Type    : Boolean
    Parameter      : condition, newRecord
    *********************************************************************************/
    private static Boolean evaluateContainsCondition(Condition condition, SObject newRecord) {
        Boolean isConditionSatisfied = false;
        //evaluate contains operator only for String, Text Area, URL, Email, Phone, Multipicklist, Formula(Text) data type, encryptedString
        if(condition.FieldApiName != PC_Constants.PC_RecordTypeDeveloperName &&
            (condition.Type == PC_Constants.PC_FIELD_TYPE_STRING || condition.Type == PC_Constants.PC_FIELD_TYPE_EMAIL
                || condition.Type == PC_Constants.PC_FIELD_TYPE_URL || condition.Type == PC_Constants.PC_FIELD_TYPE_PHONE
                || condition.Type == PC_Constants.PC_MULTIPICKLIST || condition.Type == PC_Constants.PC_ENCRYPTEDSTRING
                    || condition.Type == PC_Constants.PC_TEXTAREA )){
            String recordFieldValue = String.valueOf(newRecord.get(condition.FieldApiName));
            String conditionFieldValue = String.valueOf(getValueBasedOnDatatype(condition.Value, condition.Type));
            if(condition.Type == PC_Constants.PC_MULTIPICKLIST && String.isNotEmpty(recordFieldValue) && String.isNotEmpty(conditionFieldValue) ){
                //Verify if multi picklist field value in record contains all values given in condition
                if(containsMultipicklistValues(conditionFieldValue,recordFieldValue)){
                    isConditionSatisfied = true;
                }
            }else if (String.isNotEmpty(recordFieldValue) && String.isNotEmpty(conditionFieldValue) && recordFieldValue.contains(conditionFieldValue)) {
                isConditionSatisfied = true;
            }
        }else{
            //Throw error for unsupported field types
            PC_SupportPlanEngine.SupportPlan_Exception supportPlanException = new PC_SupportPlanEngine.SupportPlan_Exception();
            List<Object> formattingArguments = new List<Object>{condition.Operator,condition.Type};
            supportPlanException.setMessage(String.format(Label.PC_UnsupportedOperatorForFieldType, formattingArguments));
            throw supportPlanException;
        }
        return isConditionSatisfied;
    }

    /*********************************************************************************
    Method Name    : evaluateDoesNotContainsCondition
    Description    : This method returns true if record matches 'Does not contains' condition. Else, false.
    Return Type    : Boolean
    Parameter      : condition, newRecord
    *********************************************************************************/
    private static Boolean evaluateDoesNotContainsCondition(Condition condition, SObject newRecord) {
        Boolean isConditionSatisfied = false;
        //evaluate contains operator only for String, Text Area, URL, Email, Phone, Multipicklist, Formula(Text) data type, encryptedString
        if(condition.FieldApiName != PC_Constants.PC_RecordTypeDeveloperName &&
                (condition.Type == PC_Constants.PC_FIELD_TYPE_STRING || condition.Type == PC_Constants.PC_FIELD_TYPE_EMAIL
                        || condition.Type == PC_Constants.PC_FIELD_TYPE_URL || condition.Type == PC_Constants.PC_FIELD_TYPE_PHONE
                        || condition.Type == PC_Constants.PC_MULTIPICKLIST || condition.Type == PC_Constants.PC_ENCRYPTEDSTRING
                        || condition.Type == PC_Constants.PC_TEXTAREA)){
            String recordFieldValue = String.valueOf(newRecord.get(condition.FieldApiName));
            String conditionFieldValue = String.valueOf(getValueBasedOnDatatype(condition.Value, condition.Type));
            if(condition.Type == PC_Constants.PC_MULTIPICKLIST){
                //Verify if multi picklist field value in record does not contain all values given in condition
                if(doesNotContainMultipicklistValues(conditionFieldValue,recordFieldValue)){
                    isConditionSatisfied = true;
                }
            }else if (String.isNotEmpty(recordFieldValue) && String.isNotEmpty(conditionFieldValue) && !recordFieldValue.contains(conditionFieldValue)) {
                isConditionSatisfied = true;
            }
        }else{
            //Throw error for unsupported field types
            PC_SupportPlanEngine.SupportPlan_Exception supportPlanException = new PC_SupportPlanEngine.SupportPlan_Exception();
            List<Object> formattingArguments = new List<Object>{condition.Operator,condition.Type};
            supportPlanException.setMessage(String.format(Label.PC_UnsupportedOperatorForFieldType, formattingArguments));
            throw supportPlanException;
        }
        return isConditionSatisfied;
    }

    /*********************************************************************************
    Method Name    : containsMultipicklistValues
    Description    : This method returns true if recordFieldValue contains all the values in conditionFieldValue. Else, false.
    Return Type    : Boolean
    Parameter      : conditionFieldValue, recordFieldValue
    *********************************************************************************/
    public static Boolean containsMultipicklistValues(String conditionFieldValue, String recordFieldValue) {
        Boolean containsConditionValues = false;
        Boolean recordContainsValue = false;
        if(recordFieldValue != null && conditionFieldValue != null){
            List<String> conditionMultipicklistValues = conditionFieldValue.split(';');
            List<String> recordMultipicklistValues = recordFieldValue.split(';');
            containsConditionValues = true;
            for(String conditionValue: conditionMultipicklistValues){
                recordContainsValue = false;
                for(String recordValue: recordMultipicklistValues) {
                    if (recordValue == conditionValue) {
                        recordContainsValue = true;
                        break;
                    }
                }
                if(!recordContainsValue){
                    containsConditionValues = false;
                    break;
                }
            }
        }
        return containsConditionValues;
    }

    /*********************************************************************************
    Method Name    : doesNotContainMultipicklistValues
    Description    : This method returns true if recordFieldValue does not contain all the values in conditionFieldValue. Else, false.
    Return Type    : Boolean
    Parameter      : conditionFieldValue, recordFieldValue
    *********************************************************************************/
    public static Boolean doesNotContainMultipicklistValues(String conditionFieldValue, String recordFieldValue) {
        Boolean doesNotContainConditionValues = false;
            if(!containsMultipicklistValues(conditionFieldValue,recordFieldValue)){
                doesNotContainConditionValues = true;
            }
        return doesNotContainConditionValues;
    }

    /*********************************************************************************
    Method Name    : equalsMultipicklistValues
    Description    : This method returns true if recordFieldValue equals the conditionFieldValue values. Else, false.
    Return Type    : Boolean
    Parameter      : conditionFieldValue, recordFieldValue
    *********************************************************************************/
    public static Boolean equalsMultipicklistValues(String conditionFieldValue, String recordFieldValue) {
        Boolean equalsMultipicklistValues = false;
        if((conditionFieldValue == null && recordFieldValue == null)
                || (conditionFieldValue != null && recordFieldValue != null && containsMultipicklistValues(conditionFieldValue,recordFieldValue)
                && conditionFieldValue.split(';').size() == recordFieldValue.split(';').size())){
            equalsMultipicklistValues = true;
        }
        return equalsMultipicklistValues;
    }

    /*********************************************************************************
    Method Name    : doesNotEqualsMultipicklistValues
    Description    : This method returns true if recordFieldValue does not equals the conditionFieldValue values. Else, false.
    Return Type    : Boolean
    Parameter      : conditionFieldValue, recordFieldValue
    *********************************************************************************/
    public static Boolean doesNotEqualsMultipicklistValues(String conditionFieldValue, String recordFieldValue) {
        Boolean doesNotEqualsMultipicklistValues = false;
        if(!equalsMultipicklistValues(conditionFieldValue,recordFieldValue)){
            doesNotEqualsMultipicklistValues = true;
        }
        return doesNotEqualsMultipicklistValues;
    }

    /**
    * Creates Support Plan Activity Log with status as 'Completed', if Task is in Closed status.
    * @param updatedTaskMap  updated record Map of Tasks
    */
    public static void createLogForCompletedTask(Map<Id, Task> updatedTaskMap){
        Set<Id> spaIds = new Set<Id>();
        for(Task taskRecord : updatedTaskMap.values()){
            spaIds.add(taskRecord.PC_SupportPlanActivity__c);
        }
        /*FLS Check for Support Plan Activity Log*/
        List<String> logFields = new List<String>{'Id' ,PC_Constants.getQualifiedAPIName('PC_ActionRecordId__c'),
                PC_Constants.getQualifiedAPIName('PC_SupportPlanRuntime__c'),PC_Constants.getQualifiedAPIName('PC_TransactionId__c'),
                PC_Constants.getQualifiedAPIName('PC_ActionRecordModifiedTime__c'),PC_Constants.getQualifiedAPIName('PC_Status__c'),
                PC_Constants.getQualifiedAPIName('PC_SupportPlanActivity__c')};
        PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_SupportPlanActivityLog__c'), PC_Database.Operation.Reading, logFields);

        List<PC_SupportPlanActivityLog__c> allSupportPlanActivityLogList = new List<PC_SupportPlanActivityLog__c>();

        allSupportPlanActivityLogList = [Select Id, PC_ActionRecordId__c,PC_SupportPlanRuntime__c,PC_TransactionId__c, PC_ActionRecordModifiedTime__c,
                PC_Status__c, PC_SupportPlanActivity__c,PC_TriggerRecordId__c FROM PC_SupportPlanActivityLog__c
        Where PC_SupportPlanActivity__c IN: spaIds AND PC_ActionRecordId__c IN: updatedTaskMap.keySet() ];

        List<PC_SupportPlanActivityLog__c> supportPlanActivityLogList = new List<PC_SupportPlanActivityLog__c>();
        for(Task taskRecord : updatedTaskMap.values()){
            for(PC_SupportPlanActivityLog__c log : allSupportPlanActivityLogList){
                if(taskRecord.Id == log.PC_ActionRecordId__c && taskRecord.PC_SupportPlanActivity__c == log.PC_SupportPlanActivity__c){
                    supportPlanActivityLogList.add(log);
                }
            }
        }

        List<PC_SupportPlanActivityLog__c> newSupportPlanActivityLogList = new List<PC_SupportPlanActivityLog__c>();

        if(!supportPlanActivityLogList.isEmpty()) {
            /*FLS Check for TaskStatus*/
            List<String> taskStatusFields = new List<String>{'MasterLabel'};
            PC_Database.assertAccess('TaskStatus', PC_Database.Operation.Reading, taskStatusFields);

            Set<String> closedTaskStatusSet = PC_SYSTEM.getStatusAttribute('TaskStatus', false, true);
            for (Task task : updatedTaskMap.values()) {
                Boolean isTaskClosed = false;
                //Check if Task status is any of the closed Status and set the flag
                for(String closedStatus : closedTaskStatusSet){
                    if(task.status == closedStatus){
                        isTaskClosed =  true;
                        break;
                    }
                }
                //Check if there is already a support plan activity log with completed status for the task
                Boolean isCompletedLogAvailable = false;
                for(PC_SupportPlanActivityLog__c spaLog: supportPlanActivityLogList) {
                    if (task.Id == spaLog.PC_ActionRecordId__c && spaLog.PC_Status__c == PC_Constants.PC_LOG_STATUS_COMPLETED
                            && task.PC_SupportPlanActivity__c == spaLog.PC_SupportPlanActivity__c) {
                        isCompletedLogAvailable = true;
                    }
                }
                //Create a new log with completed status only if task is closed and if next activity in SP sequence is not already triggered
                if (isTaskClosed && !isCompletedLogAvailable) {
                    PC_SupportPlanActivityLog__c newSPAlog = new PC_SupportPlanActivityLog__c();
                    newSPAlog.PC_Status__c = PC_Constants.PC_LOG_STATUS_COMPLETED;
                    newSPAlog.PC_SupportPlanActivity__c = task.PC_SupportPlanActivity__c;
                    newSPAlog.PC_ActionRecordId__c = task.Id;
                    newSPAlog.PC_LogDateTime__c = system.now();
                    newSPAlog.PC_RuntimeUser__c = UserInfo.getUserId();
                    for(PC_SupportPlanActivityLog__c spaLog: supportPlanActivityLogList){
                        if(newSPAlog.PC_ActionRecordId__c == spaLog.PC_ActionRecordId__c && spaLog.PC_Status__c != PC_Constants.PC_LOG_STATUS_COMPLETED){
                            newSPAlog.PC_SupportPlanRuntime__c = spaLog.PC_SupportPlanRuntime__c;
                            newSPAlog.PC_TransactionId__c = spaLog.PC_TransactionId__c;
                            newSPAlog.PC_TriggerRecordId__c = spaLog.PC_TriggerRecordId__c;
                            newSPAlog.PC_ActionRecordModifiedTime__c = spaLog.PC_ActionRecordModifiedTime__c;
                        }
                    }
                    newSupportPlanActivityLogList.add(newSPAlog);
                }
            }
        }
        PC_Database.ins(newSupportPlanActivityLogList,false);
    }

    /**
    * Processes next Support Plan Activity in sequence if log status of Runtime Current Activity is completed
    * @param supportPlanActivityLogs  Support Plan Activity Log list that are created/updated
    */
    public static void processNextSupportPlanActivity(List<PC_SupportPlanActivityLog__c> supportPlanActivityLogs){
        if(!supportPlanActivityLogs.isEmpty()) {
            Map<Id,PC_SupportPlanActivityLog__c> mapSupportPlanRuntimeToCompletedLog = new Map<Id,PC_SupportPlanActivityLog__c>();
            Map<Id,PC_SupportPlanActivityLog__c> mapSupportPlanRuntimeToModifiedLog = new Map<Id,PC_SupportPlanActivityLog__c>();
            Set<Id> supportPlanActivityInternalIds = new Set<Id>();
            Set<Id> triggerRecordIds = new Set<Id>();
            Set<Id> completedActivityLogIds = new Set<Id>();
            Set<Id> supportPlanRuntimeIds = new Set<Id>();

            for (PC_SupportPlanActivityLog__c activityLog : supportPlanActivityLogs) {
                if (activityLog.PC_Status__c == PC_Constants.PC_LOG_STATUS_COMPLETED) {
                    triggerRecordIds.add(activityLog.PC_TriggerRecordId__c);
                    supportPlanRuntimeIds.add(activityLog.PC_SupportPlanRuntime__c);
                    completedActivityLogIds.add(activityLog.Id);
                }
            }

            List<PC_SupportPlanActivityLog__c> completedActivityLogDetails = new List<PC_SupportPlanActivityLog__c>();
            if(completedActivityLogIds != null && completedActivityLogIds.size()>0 ){
                /*FLS Check for Support Plan Activity Log*/
                List<String> logFields = new List<String>{
                        'Id', PC_Constants.getQualifiedAPIName('PC_ActionRecordId__c'), PC_Constants.getQualifiedAPIName('PC_TransactionId__c'),
                        PC_Constants.getQualifiedAPIName('PC_Status__c'), PC_Constants.getQualifiedAPIName('PC_SupportPlanActivity__c'),
                        PC_Constants.getQualifiedAPIName('PC_LogDateTime__c'), PC_Constants.getQualifiedAPIName('PC_TriggerRecordId__c'),
                        PC_Constants.getQualifiedAPIName('PC_SupportPlanActivity__r') + '.' + PC_Constants.getQualifiedAPIName('PC_InternalActivityNumber__c')
                };
                PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_SupportPlanActivityLog__c'), PC_Database.Operation.Reading, logFields);

                completedActivityLogDetails = [SELECT Id, PC_ActionRecordId__c, PC_Status__c, PC_LogDateTime__c,
                        PC_SupportPlanActivity__c,PC_SupportPlanActivity__r.PC_InternalActivityNumber__c,PC_TriggerRecordId__c, PC_TransactionId__c
                        FROM PC_SupportPlanActivityLog__c
                        WHERE Id IN :completedActivityLogIds
                ];
            }

            if (completedActivityLogDetails != null && !completedActivityLogDetails.isEmpty()) {
                for (PC_SupportPlanActivityLog__c completedLog : completedActivityLogDetails) {
                    supportPlanActivityInternalIds.add(completedLog.PC_SupportPlanActivity__r.PC_InternalActivityNumber__c);
                }
            }

            List<PC_SupportPlanRuntime__c> supportPlanRuntimesToUpdate = new List<PC_SupportPlanRunTime__c>();
            List<PC_SupportPlanRuntime__c> supportPlanRuntimesToProcess = new List<PC_SupportPlanRunTime__c>();
            If (supportPlanActivityInternalIds.size() > 0) {
                /* FLS Check for PC_SupportPlanRuntime__c*/
                List<String> supportPlanRuntimeFields = new List<String>{
                        PC_Constants.getQualifiedAPIName('PC_SupportPlan__c'),
                        PC_Constants.getQualifiedAPIName('PC_CurrentActivity__c'), PC_Constants.getQualifiedAPIName('PC_EndTime__c'),
                        PC_Constants.getQualifiedAPIName('PC_SupportPlanCase__c'), PC_Constants.getQualifiedAPIName('PC_RecordId__c'),
                        PC_Constants.getQualifiedAPIName('PC_Completed_Activity__c'), PC_Constants.getQualifiedAPIName('PC_Completed_Activity_Date__c'),
                        PC_Constants.getQualifiedAPIName('PC_Current_Group__c'), PC_Constants.getQualifiedAPIName('PC_Current_Group_Next_Activity__c'),
                        PC_Constants.getQualifiedAPIName('PC_Current_Group_Status__c'), PC_Constants.getQualifiedAPIName('PC_CurrentGroupAllActivities__c'),
                        PC_Constants.getQualifiedAPIName('PC_CurrentActivityStatus__c')
                };
                PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_SupportPlanRuntime__c'), PC_Database.Operation.Reading, supportPlanRuntimeFields);

                List<PC_SupportPlanRuntime__c> supportPlanRuntimes = [
                        SELECT ID,PC_SupportPlan__c,PC_SupportPlanCase__c,PC_EndTime__c,PC_RecordId__c,
                                PC_CurrentActivity__c,PC_CurrentActivityStatus__c, PC_Completed_Activity__c,PC_Completed_Activity_Date__c,PC_SupportPlan__r.PC_IsActive__c,
                                PC_Current_Group__c,PC_Current_Group_Next_Activity__c,PC_Current_Group_Status__c,PC_CurrentGroupAllActivities__c
                        FROM PC_SupportPlanRuntime__c
                        WHERE Id IN:supportPlanRuntimeIds AND PC_EndTime__c = null AND PC_SupportPlan__r.PC_IsActive__c = TRUE
                ];

                for (PC_SupportPlanActivityLog__c completedLog : completedActivityLogDetails) {
                    if (supportPlanRuntimes != null && !supportPlanRuntimes.isEmpty()) {
                        for (PC_SupportPlanRuntime__c supportPlanRuntime : supportPlanRuntimes) {
                            Set<String> currentActivityIds = new Set<String>();
                            Set<String> currentGroupActivityIds = new Set<String>();
                            if (supportPlanRunTime.PC_CurrentActivity__c != null) {
                                currentActivityIds = (Set<String>) (System.JSON.deserialize(supportPlanRunTime.PC_CurrentActivity__c, Set<String>.class));
                            }
                            if (supportPlanRunTime.PC_CurrentGroupAllActivities__c != null) {
                                currentGroupActivityIds = (Set<String>) (System.JSON.deserialize(supportPlanRunTime.PC_CurrentGroupAllActivities__c, Set<String>.class));
                            }

                            if ((currentActivityIds.contains(completedLog.PC_SupportPlanActivity__r.PC_InternalActivityNumber__c) || currentGroupActivityIds.contains(completedLog.PC_SupportPlanActivity__r.PC_InternalActivityNumber__c))
                                    && (supportPlanRuntime.PC_SupportPlanCase__c == completedLog.PC_TriggerRecordId__c || supportPlanRuntime.PC_RecordId__c == completedLog.PC_TriggerRecordId__c)) {
                                mapSupportPlanRuntimeToCompletedLog.put(supportPlanRuntime.Id, completedLog);
                            } else if (supportPlanRuntime.PC_Completed_Activity__c == (String) String.valueOf(completedLog.PC_ActionRecordId__c)) {
                                mapSupportPlanRuntimeToModifiedLog.put(supportPlanRuntime.Id, completedLog);
                            }
                        }
                    }
                }

                /*FLS Check for PC_SupportPlanActivity*/
                List<String> supportPlanActivityFields = new List<String>{
                        'Id', 'Name', PC_Constants.getQualifiedAPIName('PC_InternalActivityNumber__c'),
                        PC_Constants.getQualifiedAPIName('PC_ActivitySequence__c'), PC_Constants.getQualifiedAPIName('PC_NextActivityNumber__c')
                };
                PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_SupportPlanActivity__c'), PC_Database.Operation.Reading, supportPlanActivityFields);

                List<PC_SupportPlanActivity__c> completedSupportPlanActivities = [
                        SELECT Id, Name, PC_InternalActivityNumber__c,
                                PC_ActivitySequence__c,PC_NextActivityNumber__c
                        FROM PC_SupportPlanActivity__c
                        WHERE PC_InternalActivityNumber__c IN :supportPlanActivityInternalIds
                ];

                if (!supportPlanRuntimes.isEmpty()) {
                    for (PC_SupportPlanRuntime__c supportPlanRuntime : supportPlanRuntimes) {
                        PC_SupportPlanActivityLog__c completedLog = mapSupportPlanRuntimeToModifiedLog.get(supportPlanRuntime.Id);
                        String checkCompletedLogId = PC_Constants.EMPTY_STRING;
                        if (completedLog != null) {
                            checkCompletedLogId = (String) String.valueOf(completedLog.PC_ActionRecordId__c);
                        }
                        Set<String> currentActivityIds = new Set<String>();
                        Set<String> currentGroupActivityIds = new Set<String>();
                        if (supportPlanRunTime.PC_CurrentActivity__c != null) {
                            currentActivityIds = (Set<String>) (System.JSON.deserialize(supportPlanRunTime.PC_CurrentActivity__c, Set<String>.class));
                        }
                        if (supportPlanRunTime.PC_CurrentGroupAllActivities__c != null) {
                            currentGroupActivityIds = (Set<String>) (System.JSON.deserialize(supportPlanRunTime.PC_CurrentGroupAllActivities__c, Set<String>.class));
                        }
                        for (PC_SupportPlanActivity__c completedSupportPlanActivity : completedSupportPlanActivities) {
                            if (currentActivityIds.contains(completedSupportPlanActivity.PC_InternalActivityNumber__c) || currentGroupActivityIds.contains(completedSupportPlanActivity.PC_InternalActivityNumber__c)) {
                                PC_SupportPlanRuntime__c supportPlanRuntimeToUpdate = returnUpdatedSupportPlanRunTime(supportPlanRuntime, completedSupportPlanActivity, mapSupportPlanRuntimeToCompletedLog.get(supportPlanRuntime.Id));
                                //Add Runtime record to list only if it doesn't exist already.
                                //Replace the runtime record with latest one if it already exists in list.
                                if (supportPlanRuntimeToUpdate.PC_CurrentActivityStatus__c == PC_Constants.SUPPORTPLANRT_ACTIVITY_STATUS_COMPLETED) {
                                    if (supportPlanRuntimesToUpdate.contains(supportPlanRuntimeToUpdate)) {
                                        supportPlanRuntimesToUpdate.remove(supportPlanRuntimesToUpdate.indexOf(supportPlanRuntimeToUpdate));
                                    }
                                    supportPlanRuntimesToUpdate.add(supportPlanRuntimeToUpdate);
                                } else {
                                    if (supportPlanRuntimesToUpdate.contains(supportPlanRuntimeToUpdate)) {
                                        supportPlanRuntimesToUpdate.remove(supportPlanRuntimesToUpdate.indexOf(supportPlanRuntimeToUpdate));
                                    }
                                    supportPlanRuntimesToUpdate.add(supportPlanRuntimeToUpdate);
                                    if (supportPlanRuntimesToProcess.contains(supportPlanRuntimeToUpdate)) {
                                        supportPlanRuntimesToProcess.remove(supportPlanRuntimesToUpdate.indexOf(supportPlanRuntimeToUpdate));
                                    }
                                    supportPlanRuntimesToProcess.add(supportPlanRuntimeToUpdate);
                                }
                            } else if (supportPlanRuntime.PC_Completed_Activity__c == checkCompletedLogId) {
                                if (supportPlanRuntimesToProcess.contains(supportPlanRuntime)) {
                                    supportPlanRuntimesToProcess.remove(supportPlanRuntimesToProcess.indexOf(supportPlanRuntime));
                                }
                                supportPlanRuntimesToProcess.add(supportPlanRuntime);
                            }
                        }
                    }
                }
            }
            if (supportPlanRuntimesToUpdate.size() > 0) {
                PC_Database.upd(supportPlanRuntimesToUpdate);
            }
            if (supportPlanRuntimesToProcess.size() > 0) {
                List<SupportPlanInfo> supportPlanInfoList = new List<SupportPlanInfo>();
                for (PC_SupportPlanRuntime__c runtime : supportPlanRuntimesToProcess) {
                    SupportPlanInfo supportPlanInfo = new SupportPlanInfo();
                    supportPlanInfo.runtimeId = runtime.Id;
                    supportPlanInfo.context = PC_Constants.SupportPlanInfoContext.ProcessSupportPlanRuntimes;
                    if (mapSupportPlanRuntimeToCompletedLog.get(runtime.Id) != null) {
                        supportPlanInfo.transactionId = mapSupportPlanRuntimeToCompletedLog.get(runtime.Id).PC_TransactionId__c;
                    }
                    supportPlanInfoList.add(supportPlanInfo);
                }
                publishSupportPlanPlatformEvent(supportPlanInfoList);
            }
        }
    }

    /*********************************************************************************
    Method Name    : returnUpdatedSupportPlanRunTime
    Description    : Returns the updated Support Plan Runtime with next Activity details
    Return Type    : Support Plan RunTime
    Parameter      : supportPlanRuntime, completedSupportPlanActivity
    *********************************************************************************/
    private static PC_SupportPlanRuntime__c returnUpdatedSupportPlanRunTime(PC_SupportPlanRuntime__c supportPlanRuntime, PC_SupportPlanActivity__c completedSupportPlanActivity, PC_SupportPlanActivityLog__c completedLog) {
        PC_SupportPlanRuntime__c supportPlanRuntimeToUpdate = supportPlanRuntime;
        Set<String> AllActivityIds = new Set<String>();
        if(supportPlanRunTime.PC_CurrentGroupAllActivities__c != null){
            AllActivityIds = (Set<String>) (System.JSON.deserialize(supportPlanRunTime.PC_CurrentGroupAllActivities__c,Set<String>.class));
        }
        if(!AllActivityIds.isEmpty()){
            if(AllActivityIds.contains(completedSupportPlanActivity.PC_InternalActivityNumber__c)){
                AllActivityIds.remove(completedSupportPlanActivity.PC_InternalActivityNumber__c);
                if(AllActivityIds.isEmpty()){
                    if (completedSupportPlanActivity.PC_ActivitySequence__c == supportPlanRuntime.PC_Current_Group__c &&
                            (string.isNotBlank(supportPlanRuntime.PC_Current_Group_Next_Activity__c))){
                        SET<Id> nextActivityIds = new SET<Id>();
                        nextActivityIds.add(supportPlanRuntime.PC_Current_Group_Next_Activity__c);
                        MAP<ID,InitialActivityWrapper> nextActivities = processInitialActivities(nextActivityIds);
                        InitialActivityWrapper nextActivity = nextActivities.get(supportPlanRuntime.PC_Current_Group_Next_Activity__c);

                        supportPlanRuntimeToUpdate.PC_CurrentActivity__c                =   nextActivity.currentactivity;
                        supportPlanRuntimeToUpdate.PC_CurrentActivityStatus__c          =   nextActivity.currentactivitystatus;

                        supportPlanRuntimeToUpdate.PC_Current_Group__c                  =   nextActivity.currentgroup;
                        supportPlanRuntimeToUpdate.PC_Current_Group_Status__c           =   nextActivity.currentgroupstatus;
                        supportPlanRuntimeToUpdate.PC_Current_Group_Next_Activity__c    =   nextActivity.currentgroupnextactivity;
                        supportPlanRuntimeToUpdate.PC_CurrentGroupAllActivities__c      =   nextActivity.currentgroupallactivities;
                    }else {
                        supportPlanRuntimeToUpdate.PC_Current_Group__c                  =   null;
                        supportPlanRuntimeToUpdate.PC_Current_Group_Status__c           =   null;
                        supportPlanRuntimeToUpdate.PC_Current_Group_Next_Activity__c    =   null;
                        supportPlanRuntimeToUpdate.PC_EndTime__c                        = system.now();
                        supportPlanRuntimeToUpdate.PC_CurrentActivityStatus__c          = PC_Constants.SUPPORTPLANRT_ACTIVITY_STATUS_COMPLETED;
                        supportPlanRuntimeToUpdate.PC_CurrentGroupAllActivities__c      = System.JSON.serialize(new Set<String>());
                        supportPlanRuntimeToUpdate.PC_CurrentActivity__c                = System.JSON.serialize(new Set<String>());
                    }
                }else{
                    supportPlanRuntimeToUpdate.PC_CurrentGroupAllActivities__c  =  System.JSON.serialize(AllActivityIds);
                }
            }
        }
        else if(string.isNotBlank(completedSupportPlanActivity.PC_NextActivityNumber__c)){
            SET<Id> nextActivityIds = new SET<Id>();
            nextActivityIds.add(completedSupportPlanActivity.PC_NextActivityNumber__c);
            MAP<ID,InitialActivityWrapper> nextActivities = processInitialActivities(nextActivityIds);
            InitialActivityWrapper nextActivity = nextActivities.get(completedSupportPlanActivity.PC_NextActivityNumber__c);

            supportPlanRuntimeToUpdate.PC_CurrentActivity__c                =   nextActivity.currentactivity;
            supportPlanRuntimeToUpdate.PC_CurrentActivityStatus__c          =   nextActivity.currentactivitystatus;

            supportPlanRuntimeToUpdate.PC_Current_Group__c                  =   nextActivity.currentgroup;
            supportPlanRuntimeToUpdate.PC_Current_Group_Status__c           =   nextActivity.currentgroupstatus;
            supportPlanRuntimeToUpdate.PC_CurrentGroupAllActivities__c      =   nextActivity.currentgroupallactivities;
            if(nextActivity.currentgroupnextactivity == PC_Constants.SUPPORTPLAN_OVERRIDE_PREVIOUS){
                supportPlanRuntimeToUpdate.PC_Current_Group_Next_Activity__c    =   supportPlanRuntime.PC_Current_Group_Next_Activity__c;
            }else{
                supportPlanRuntimeToUpdate.PC_Current_Group_Next_Activity__c    =   nextActivity.currentgroupnextactivity;
            }
        }else if (completedSupportPlanActivity.PC_ActivitySequence__c == supportPlanRuntime.PC_Current_Group__c &&
                (string.isNotBlank(supportPlanRuntime.PC_Current_Group_Next_Activity__c))){
            SET<Id> nextActivityIds = new SET<Id>();
            nextActivityIds.add(supportPlanRuntime.PC_Current_Group_Next_Activity__c);
            MAP<ID,InitialActivityWrapper> nextActivities = processInitialActivities(nextActivityIds);
            InitialActivityWrapper nextActivity = nextActivities.get(supportPlanRuntime.PC_Current_Group_Next_Activity__c);

            supportPlanRuntimeToUpdate.PC_CurrentActivity__c                =   nextActivity.currentactivity;
            supportPlanRuntimeToUpdate.PC_CurrentActivityStatus__c          =   nextActivity.currentactivitystatus;

            supportPlanRuntimeToUpdate.PC_Current_Group__c                  =   nextActivity.currentgroup;
            supportPlanRuntimeToUpdate.PC_Current_Group_Status__c           =   nextActivity.currentgroupstatus;
            supportPlanRuntimeToUpdate.PC_Current_Group_Next_Activity__c    =   nextActivity.currentgroupnextactivity;
            supportPlanRuntimeToUpdate.PC_CurrentGroupAllActivities__c      =   nextActivity.currentgroupallactivities;
        }else {
            supportPlanRuntimeToUpdate.PC_Current_Group__c                  =   null;
            supportPlanRuntimeToUpdate.PC_Current_Group_Status__c           =   null;
            supportPlanRuntimeToUpdate.PC_Current_Group_Next_Activity__c    =   null;
            supportPlanRuntimeToUpdate.PC_EndTime__c                        = system.now();
            supportPlanRuntimeToUpdate.PC_CurrentActivityStatus__c          = PC_Constants.SUPPORTPLANRT_ACTIVITY_STATUS_COMPLETED;
            supportPlanRuntimeToUpdate.PC_CurrentGroupAllActivities__c      = System.JSON.serialize(new Set<String>());
        }
        supportPlanRuntimeToUpdate.PC_Completed_Activity__c                 = completedLog.PC_ActionRecordId__c;
        supportPlanRuntimeToUpdate.PC_Completed_Activity_Date__c            = completedLog.PC_LogDateTime__c;

        return supportPlanRuntimeToUpdate;
    }

    /**
    * Processes Support Plan Runtimes with Pending Condition
    * @param recordIds  RecordIds for which Pending Runtimes need to be processes
    */
    public static void processSupportPlanActivity(Set<Id> recordIds){
        /* FLS Check for PC_SupportPlanRuntime__c*/
        List<String> supportPlanRuntimeFields = new List<String>{'Id',PC_Constants.getQualifiedAPIName('PC_SupportPlan__c'),
                PC_Constants.getQualifiedAPIName('PC_CurrentActivity__c'), PC_Constants.getQualifiedAPIName('PC_EndTime__c'),
                PC_Constants.getQualifiedAPIName('PC_SupportPlanCase__c'), PC_Constants.getQualifiedAPIName('PC_RecordId__c'),
                PC_Constants.getQualifiedAPIName('PC_Completed_Activity__c'), PC_Constants.getQualifiedAPIName('PC_Completed_Activity_Date__c'),
                PC_Constants.getQualifiedAPIName('PC_Current_Group__c'), PC_Constants.getQualifiedAPIName('PC_Current_Group_Next_Activity__c'),
                PC_Constants.getQualifiedAPIName('PC_Current_Group_Status__c'), PC_Constants.getQualifiedAPIName('PC_CurrentGroupAllActivities__c'),
                PC_Constants.getQualifiedAPIName('PC_CurrentActivityStatus__c')};
        PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_SupportPlanRuntime__c'), PC_Database.Operation.Reading, supportPlanRuntimeFields);
        //fetch pending Support Plan Runtimes
        List<PC_SupportPlanRuntime__c> supportPlanRuntimesWithPendingCondition = [SELECT Id,PC_SupportPlanCase__c, PC_RecordId__c, PC_EndTime__c,
                PC_CurrentActivity__c, PC_CurrentActivityStatus__c, PC_Current_Group__c, PC_Current_Group_Status__c, PC_CurrentGroupAllActivities__c,
                PC_Current_Group_Next_Activity__c, PC_Completed_Activity__c, PC_Completed_Activity_Date__c,PC_SupportPlan__r.PC_IsActive__c
        FROM PC_SupportPlanRuntime__c
        WHERE (PC_SupportPlanCase__c IN :recordIds OR PC_RecordId__c IN :recordIds) AND PC_EndTime__c = NULL
        AND PC_CurrentActivityStatus__c =: PC_Constants.SUPPORTPLANRT_ACTIVITY_STATUS_PENDINGCONDITION AND PC_SupportPlan__r.PC_IsActive__c = TRUE];

        if(supportPlanRuntimesWithPendingCondition.size() > 0) {
            List<SupportPlanInfo> supportPlanInfoList = new List<SupportPlanInfo>();
            for(PC_SupportPlanRuntime__c runtime: supportPlanRuntimesWithPendingCondition){
                SupportPlanInfo supportPlanInfo = new SupportPlanInfo();
                supportPlanInfo.runtimeId = runtime.Id;
                supportPlanInfo.context = PC_Constants.SupportPlanInfoContext.ProcessSupportPlanRuntimes;
                supportPlanInfoList.add(supportPlanInfo);
            }
            publishSupportPlanPlatformEvent(supportPlanInfoList);
        }

    }

    /**
    * creates Support Plan Runtime for each Support Plan and Record Pair in Platform Event
    * @param supportPlanInfoList  Support Plan Info Platform Events
    */
    public static Map<Id,PC_SupportPlanInfo__e> createSupportPlanRuntimes(List<PC_SupportPlanInfo__e> supportPlanInfoList){
        Map<Id,PC_SupportPlanInfo__e> newSupportPlanRuntimesMap = new Map<Id,PC_SupportPlanInfo__e>();
        List<PC_SupportPlanRuntime__C> newSupportPlanRuntimes = new List<PC_SupportPlanRuntime__C>();
        List<String> supportPlanIds = new List<String>();
        List<String> recordIds = new List<String>();
        for(PC_SupportPlanInfo__e supportPlanInfo : supportPlanInfoList) {
            supportPlanIds.add(supportPlanInfo.PC_SupportPlanOrRuntimeIds__c);
            recordIds.add(supportPlanInfo.PC_RecordId__c);
        }
        Map<Id, String> triggerRecNameMap = getRecordNames(recordIds);
        /* FLS Check for PC_SupportPlan__c */
        List<String> supportPlanFields = new List<String>{'Id', PC_Constants.getQualifiedAPIName('PC_InitialActivity__c')};
        PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_SupportPlan__c'), PC_Database.Operation.Reading, supportPlanFields);
        List<PC_SupportPlan__c> supportPlanList = new List<PC_SupportPlan__c>();
        if(!supportPlanIds.isEmpty()) {
            supportPlanList = [SELECT Id, PC_InitialActivity__c FROM PC_SupportPlan__c WHERE Id IN :supportPlanIds AND PC_IsActive__c = TRUE];
        }

        Set<Id> initialActivityIds = new Set<Id>();
        if(!supportPlanList.isEmpty()) {
            for (PC_SupportPlan__c supportPlan : supportPlanList) {
                initialActivityIds.add(supportPlan.PC_InitialActivity__c);
            }
        }
        MAP<ID, InitialActivityWrapper> initialActivities = new MAP<ID, InitialActivityWrapper>();
        if(!initialActivityIds.isEmpty()) {
            initialActivities = processInitialActivities(initialActivityIds);
        }
        system.debug('supportPlanList>>'+supportPlanList);
        if(!supportPlanList.isEmpty()){
            Integer sprtCount = 0;
            for(PC_SupportPlanInfo__e supportPlanInfo : supportPlanInfoList){
                sprtCount   = sprtCount + 1;
                InitialActivityWrapper initialActivity = new InitialActivityWrapper();
                for(PC_SupportPlan__c supportPlan : supportPlanList){
                    if(supportPlan.Id == supportPlanInfo.PC_SupportPlanOrRuntimeIds__c){
                        initialActivity = initialActivities.get(supportPlan.PC_InitialActivity__c);
                    }
                }
                PC_SupportPlanRuntime__c sprt = new PC_SupportPlanRuntime__c();
                sprt.PC_StartTime__c = System.now();
                sprt.PC_SupportPlan__c = supportPlanInfo.PC_SupportPlanOrRuntimeIds__c;
                sprt.OwnerId = supportPlanInfo.PC_RuntimeUserId__c;
                if(initialActivity != null) {
                    if (initialActivity.currentGroup != null) {
                        sprt.PC_Current_Group__c = initialActivity.currentgroup;
                        sprt.PC_Current_Group_Status__c = initialActivity.currentgroupstatus;
                        sprt.PC_Current_Group_Next_Activity__c = initialActivity.currentgroupnextactivity;
                        sprt.PC_CurrentGroupAllActivities__c = initialActivity.currentgroupallactivities;
                    }
                    if (initialActivity.currentactivity != null) {
                        sprt.PC_CurrentActivity__c = initialActivity.currentactivity;
                        sprt.PC_CurrentActivityStatus__c = initialActivity.currentactivitystatus;
                        sprt.PC_Completed_Activity__c = initialActivity.completedactivity;
                        sprt.PC_Completed_Activity_Date__c = initialActivity.completedactivitydate;
                    }
                }

                String recordId = supportPlanInfo.PC_RecordId__c;
                String objectType = ((Id)recordId).getSobjectType().getDescribe().getName();

                String triggerRecName = triggerRecNameMap.get(recordId);
                sprt.Name = triggerRecName+ '-'+ 'SPRT-'  + sprtCount +'-'+ System.now();

                if(objectType == PC_Constants.PC_CASE){
                    sprt.PC_SupportPlanCase__c = recordId;
                }else{
                    sprt.PC_RecordId__c = recordId;
                }
                newSupportPlanRuntimes.add(sprt);
            }
        }
        if(newSupportPlanRuntimes.size() > 0){
            PC_Database.ins(newSupportPlanRuntimes);
            for(PC_SupportPlanRuntime__c runtime : newSupportPlanRuntimes){
                for(PC_SupportPlanInfo__e supportPlanInfo : supportPlanInfoList) {
                    if(runtime.PC_SupportPlan__c == supportPlanInfo.PC_SupportPlanOrRuntimeIds__c &&
                            (supportPlanInfo.PC_RecordId__c == runtime.PC_RecordId__c || supportPlanInfo.PC_RecordId__c == runtime.PC_SupportPlanCase__c)){
                        newSupportPlanRuntimesMap.put(runtime.Id,supportPlanInfo);
                    }
                }
            }
        }

        return newSupportPlanRuntimesMap;
    }

    /*********************************************************************************
    Method Name    : getRecordNames
    Description    : This method fetches the Name Field value of record, if it is available.
                     If not, it will get the value of first Auto number field in a particular SObject.
    Return Type    : Map<Id,String>
    Parameter      : recordIds
    *********************************************************************************/
    private static Map<Id,String> getRecordNames(List<String> recordIds){
        Map<Id,String> recordNameMap = new Map<Id,String>();
        if(!recordIds.isEmpty()){
            String objectName = ((Id)recordIds[0]).getSobjectType().getDescribe().getName();
            String nameField = 'Name';
            Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();
            Set<String> objectFields = fieldMap.keySet();
            if(!objectFields.contains(nameField)) {
                for(Schema.sObjectField fld:fieldMap.values()){
                    Schema.DescribeFieldResult flsResult =  fld.getDescribe();
                    Schema.DisplayType flsType = flsResult.type;
                    if(flsResult.isNameField()) {
                        nameField = flsResult.name;
                        break;
                    }
                }
            }
            Set<Id> recordIdSet = new Set<Id>();
            recordIdSet.addAll((Set<Id>) JSON.deserialize(JSON.serialize(recordIds), Set<Id>.class));
            List<String> nameFieldList = new List<String>{nameField};
            PC_Database.assertAccess(objectName, PC_Database.Operation.Reading, nameFieldList);
            String queryString = 'Select Id,' + nameField + ' FROM ' + objectName + ' WHERE Id IN :recordIdSet';
            List<String> fieldList =  new List<String>();
            fieldList.add('Id');
            fieldList.add(nameField);
            List<sObject> recordList = Database.query(queryString);
            for(sObject record: recordList){
                recordNameMap.put(record.Id, String.valueOf(record.get(nameField)));
            }
        }
        return recordNameMap;
    }

    /**
    * Executes the current Activity of SPR if criteria is met and updates SPR with next Activity details.
    * @param supportPlanRuntimeMap  Map of Support Plan Runtime Id and its corresponding Support Plan Info Platform Event to process
    */
    public static void processSupportPlanRuntimes(Map<Id,PC_SupportPlanInfo__e> supportPlanRuntimeMap){
        LIST<PC_SupportPlanRuntime__c> toProcessSPRT = new LIST<PC_SupportPlanRuntime__c>();
        LIST<PC_SupportPlanRuntime__c> toProcessSPRTwithAllGrpAct = new LIST<PC_SupportPlanRuntime__c>();
        Set<Id> runtimeIdList = supportPlanRuntimeMap.keySet();
        /* FLS Check for PC_SupportPlanRuntime__c */
        List<String> supportPlanRuntimeFields = new List<String>{'Id','ownerId', PC_Constants.getQualifiedAPIName('PC_EndTime__c'),
                PC_Constants.getQualifiedAPIName('PC_SupportPlanCase__c'), PC_Constants.getQualifiedAPIName('PC_RecordId__c'),
                PC_Constants.getQualifiedAPIName('PC_Current_Group__c'), PC_Constants.getQualifiedAPIName('PC_Current_Group_Status__c'),
                PC_Constants.getQualifiedAPIName('PC_Completed_Activity__c'), PC_Constants.getQualifiedAPIName('PC_Completed_Activity_Date__c'),
                PC_Constants.getQualifiedAPIName('PC_CurrentGroupAllActivities__c'), PC_Constants.getQualifiedAPIName('PC_Current_Group_Next_Activity__c'),
                PC_Constants.getQualifiedAPIName('PC_CurrentActivityStatus__c'), PC_Constants.getQualifiedAPIName('PC_CurrentActivity__c'),
                PC_Constants.getQualifiedAPIName('PC_StartTime__c'),PC_Constants.getQualifiedAPIName('PC_SupportPlan__r.Name'),
                PC_Constants.getQualifiedAPIName('PC_SupportPlan__r')+'.'+PC_Constants.getQualifiedAPIName('PC_IsActive__c')};
        PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_SupportPlanRuntime__c'), PC_Database.Operation.Reading, supportPlanRuntimeFields);

        List<PC_SupportPlanRuntime__c> runtimeList = [SELECT Id, ownerId, PC_SupportPlanCase__c, PC_RecordId__c, PC_EndTime__c, PC_CurrentActivity__c,PC_StartTime__c,
                PC_CurrentActivityStatus__c, PC_Current_Group__c, PC_Current_Group_Status__c, PC_CurrentGroupAllActivities__c,PC_SupportPlan__r.Name,
                PC_Current_Group_Next_Activity__c, PC_Completed_Activity__c, PC_Completed_Activity_Date__c,PC_SupportPlan__r.PC_IsActive__c
        FROM PC_SupportPlanRuntime__c
        WHERE Id IN: runtimeIdList AND PC_SupportPlan__r.PC_IsActive__c = TRUE];

        for (PC_SupportPlanRuntime__c supportPlanRunTime : runtimeList) {
            if(supportPlanRunTime.PC_EndTime__c == null){
                Set<String> allGroupActivityIds = new Set<String>();
                if(String.isNotEmpty(supportPlanRunTime.PC_CurrentGroupAllActivities__c)){
                    allGroupActivityIds = (Set<String>) (System.JSON.deserialize(supportPlanRunTime.PC_CurrentGroupAllActivities__c,Set<String>.class));
                }
                if(allGroupActivityIds.isEmpty()){
                    toProcessSPRT.add(supportPlanRunTime);
                }else if(!allGroupActivityIds.isEmpty() && supportPlanRunTime.PC_Current_Group_Status__c != PC_Constants.SUPPORTPLANRT_ACTIVITY_STATUS_INPROGRESS){
                    toProcessSPRTwithAllGrpAct.add(supportPlanRunTime);
                }
            }
        }
        List<Task> userTaskList = new List<Task>();
        List<Task> tasksForAutomationTaskList = new List<Task>();
        List<PC_Automation_Task__e> automationTaskList = new List<PC_Automation_Task__e>();
        List<PC_SupportPlanActivityLog__c> spaLogListForTasks = new List<PC_SupportPlanActivityLog__c>();

        String maxSPRecursiveExecutionsAllowed = PC_SYSTEM.getPatientConnectSetting(PC_Constants.PC_MAX_SP_RECURSIVE_EXECUTIONS_ALLOWED, '10');

        if(toProcessSPRT.size() > 0) {
            MAP<ID, PC_SupportPlanActivity__c> supportPlanActivitiesToCreate = returnSupportPlanActivities(toProcessSPRT,supportPlanRuntimeMap);
            If (!supportPlanActivitiesToCreate.isEmpty()) {
                for (PC_SupportPlanRuntime__c supportPlanRunTime : toProcessSPRT) {
                    Set<String> currentActivityId = new Set<String>();
                    if(supportPlanRunTime.PC_CurrentActivity__c != null){
                        currentActivityId = (Set<String>) (System.JSON.deserialize(supportPlanRunTime.PC_CurrentActivity__c,Set<String>.class));
                    }
                    PC_SupportPlanActivity__c activityToProcess = supportPlanActivitiesToCreate.get(supportPlanRunTime.Id);
                    String activityInternalId  = PC_Constants.EMPTY_STRING;
                    if(activityToProcess != null){
                        activityInternalId =   activityToProcess.PC_InternalActivityNumber__c;
                    }
                    Id runtimeUserId = supportPlanRunTime.ownerId;
                    Id triggerRecordId;
                    if(String.isNotEmpty(supportPlanRunTime.PC_RecordId__c)){
                        triggerRecordId = (Id)supportPlanRunTime.PC_RecordId__c;
                    }else{
                        triggerRecordId = supportPlanRunTime.PC_SupportPlanCase__c;
                    }
                    //Stop Recursion of Support Plan Execution if the count of logs with same transaction id exceeds maximum limit that is set
                    TransactionInfo transactioninfo = getTransactionDetails(activityToProcess.Id,runtimeUserId,triggerRecordId,supportPlanRuntimeMap.get(supportPlanRunTime.Id));
                    //Don't stop execution in scenarios: Running user is manual user OR
                    //SP initially triggered by another SP or other Salesforce Automated process like Process builder OR
                    //Running user is Automated process and recursive log count is less than maximum limit set
                    if((userInfo.getUserId() != runtimeUserId)
                            || (userInfo.getUserId() == runtimeUserId && transactioninfo.isInitiatedBySupportPlan)
                            || (userInfo.getUserId() == runtimeUserId && !transactioninfo.isInitiatedBySupportPlan
                                && transactioninfo.logCount != null && maxSPRecursiveExecutionsAllowed.isNumeric()
                                && transactioninfo.logCount < Integer.valueOf(maxSPRecursiveExecutionsAllowed))){
                        if (currentActivityId.contains(activityInternalId)) {
                            String objectType = ((Id)triggerRecordId).getSobjectType().getDescribe().getName();
                            if(activityToProcess.PC_ActivityType__c == PC_Constants.SUPPORTPLAN_ACTIVITY_TYPE_MANUAL_TASK){
                                userTaskList.add(createTask(triggerRecordId, activityToProcess, supportPlanRunTime));
                                spaLogListForTasks.add(createSupportPlanActivityLog(PC_Constants.PC_LOG_STATUS_IN_PROGRESS,transactioninfo.transactionId,triggerRecordId,supportPlanRunTime.Id,activityToProcess.Id,runtimeUserId));
                            }else{
                                PC_Automation_Task__e autoTask = new PC_Automation_Task__e(
                                        PC_RunningUser__c = runtimeUserId,
                                        PC_Source__c = objectType,
                                        PC_SourceId__c = triggerRecordId,
                                        PC_TaskConfiguration__c = activityToProcess.PC_AutomationTaskJSON__c,
                                        PC_SupportPlanActivityId__c = activityToProcess.Id,
                                        PC_SupportPlanRuntimeId__c = supportPlanRunTime.Id,
                                        PC_TransactionId__c = transactioninfo.transactionId
                                );
                                if(activityToProcess.PC_ActivityType__c == PC_Constants.SUPPORTPLAN_ACTIVITY_TYPE_AUTOMATED_TASK){
                                    autoTask.PC_AutomationTaskType__c = activityToProcess.PC_SubType__c;
                                    autoTask.PC_ActionClass__c = activityToProcess.PC_ActionClass__c;
                                    tasksForAutomationTaskList.add(createTask(triggerRecordId, activityToProcess, supportPlanRunTime));
                                }
                                else if(activityToProcess.PC_ActivityType__c == PC_Constants.SUPPORTPLAN_ACTIVITY_TYPE_CREATE_RECORD
                                        || activityToProcess.PC_ActivityType__c == PC_Constants.SUPPORTPLAN_ACTIVITY_TYPE_PUBLISH_PLATFORM_EVENT){
                                    autoTask.PC_ActionClass__c = PC_Constants.PC_CREATE_RECORD_ACTION_CLASS;
                                    autoTask.PC_AutomationTaskType__c = activityToProcess.PC_ActivityType__c;
                                }
                                else if(activityToProcess.PC_ActivityType__c == PC_Constants.SUPPORTPLAN_ACTIVITY_TYPE_UPDATE_RECORD){
                                    autoTask.PC_ActionClass__c = PC_Constants.PC_UPDATE_RECORD_ACTION_CLASS;
                                    autoTask.PC_AutomationTaskType__c = activityToProcess.PC_ActivityType__c;
                                }
                                automationTaskList.add(autoTask);
                            }
                        }
                    }else{
                        //Create Error task and assign it to the User who initiated the support Plan
                        Id runningUserId = getRunningUserId(transactionInfo.transactionId);

                        List<Object> formattingArguments = new List<Object>{supportPlanRunTime.PC_SupportPlan__r.Name};
                        String errorDescription;
                        if(!maxSPRecursiveExecutionsAllowed.isNumeric()){
                            errorDescription = Label.PC_SupportPlan_MaxRecursionsSettingErrorMessage;
                        }else{
                            errorDescription = String.format(Label.PC_SupportPlan_RecursionErrorMessage, formattingArguments);
                        }
                        userTaskList.add(createErrorTask(false,triggerRecordId, runningUserId, errorDescription, activityToProcess.Id));
                        spaLogListForTasks.add(createSupportPlanActivityLog(PC_Constants.PC_LOG_STATUS_FAILED, transactioninfo.transactionId,triggerRecordId, supportPlanRunTime.Id, activityToProcess.Id, runtimeUserId));

                        //Throw Support Plan Exception to create error log
                        SupportPlan_Exception supportPlanException = new SupportPlan_Exception();
                        supportPlanException.setMessage(errorDescription);
                        PC_Utility.createExceptionLog(supportPlanException);
                    }
                }
            }
        }

        if(toProcessSPRTwithAllGrpAct.size() > 0) {
            MAP<ID, List<PC_SupportPlanActivity__c>> supportPlanActivitiesToCreate = returnAllSupportPlanActivities(toProcessSPRTwithAllGrpAct,supportPlanRuntimeMap);
            If (!supportPlanActivitiesToCreate.isEmpty()) {
                for (PC_SupportPlanRuntime__c supportPlanRunTime : toProcessSPRTwithAllGrpAct) {
                    List<PC_SupportPlanActivity__c> supportPlanRunTimeAllGroupActivities = supportPlanActivitiesToCreate.get(supportPlanRunTime.Id);
                    Set<String> currentActivityIds = new Set<String>();
                    if(supportPlanRunTime.PC_CurrentGroupAllActivities__c != null){
                        currentActivityIds = (Set<String>) (System.JSON.deserialize(supportPlanRunTime.PC_CurrentGroupAllActivities__c, Set<String>.class));
                    }
                    for (PC_SupportPlanActivity__c spAct : supportPlanRunTimeAllGroupActivities) {
                        Id runtimeUserId = supportPlanRunTime.ownerId;
                        Id triggerRecordId;
                        if (String.isNotEmpty(supportPlanRunTime.PC_RecordId__c)) {
                            triggerRecordId = (Id) supportPlanRunTime.PC_RecordId__c;
                        } else {
                            triggerRecordId = supportPlanRunTime.PC_SupportPlanCase__c;
                        }
                        String transactionId;
                        //Stop Recursion of Support Plan Execution if the count of logs with same transaction id exceeds maximum limit that is set
                        TransactionInfo transactioninfo = getTransactionDetails(spAct.Id,runtimeUserId,triggerRecordId,supportPlanRuntimeMap.get(supportPlanRunTime.Id));

                        if((userInfo.getUserId() != runtimeUserId)
                                || (userInfo.getUserId() == runtimeUserId && transactioninfo.isInitiatedBySupportPlan)
                                || (userInfo.getUserId() == runtimeUserId && !transactioninfo.isInitiatedBySupportPlan
                                && transactioninfo.logCount != null && maxSPRecursiveExecutionsAllowed.isNumeric()
                                && transactioninfo.logCount < Integer.valueOf(maxSPRecursiveExecutionsAllowed))){

                            if (currentActivityIds.contains(spAct.PC_InternalActivityNumber__c)) {
                                String objectType = ((Id) triggerRecordId).getSobjectType().getDescribe().getName();

                                if (spAct.PC_ActivityType__c == PC_Constants.SUPPORTPLAN_ACTIVITY_TYPE_MANUAL_TASK) {
                                    userTaskList.add(createTask(triggerRecordId, spAct, supportPlanRunTime));
                                    spaLogListForTasks.add(createSupportPlanActivityLog(PC_Constants.PC_LOG_STATUS_IN_PROGRESS, transactioninfo.transactionId,triggerRecordId, supportPlanRunTime.Id, spAct.Id, runtimeUserId));
                                } else {
                                    PC_Automation_Task__e autoTask = new PC_Automation_Task__e(
                                            PC_RunningUser__c = runtimeUserId,
                                            PC_Source__c = objectType,
                                            PC_SourceId__c = triggerRecordId,
                                            PC_TaskConfiguration__c = spAct.PC_AutomationTaskJSON__c,
                                            PC_SupportPlanActivityId__c = spAct.Id,
                                            PC_SupportPlanRuntimeId__c = supportPlanRunTime.Id,
                                            PC_TransactionId__c = transactioninfo.transactionId
                                    );
                                    if (spAct.PC_ActivityType__c == PC_Constants.SUPPORTPLAN_ACTIVITY_TYPE_AUTOMATED_TASK) {
                                        autoTask.PC_ActionClass__c = spAct.PC_ActionClass__c;
                                        autoTask.PC_AutomationTaskType__c = spAct.PC_SubType__c;
                                        tasksForAutomationTaskList.add(createTask(triggerRecordId, spAct, supportPlanRunTime));
                                    } else if (spAct.PC_ActivityType__c == PC_Constants.SUPPORTPLAN_ACTIVITY_TYPE_CREATE_RECORD
                                            || spAct.PC_ActivityType__c == PC_Constants.SUPPORTPLAN_ACTIVITY_TYPE_PUBLISH_PLATFORM_EVENT) {
                                        autoTask.PC_ActionClass__c = PC_Constants.PC_CREATE_RECORD_ACTION_CLASS;
                                        autoTask.PC_AutomationTaskType__c = spAct.PC_ActivityType__c;
                                    } else if (spAct.PC_ActivityType__c == PC_Constants.SUPPORTPLAN_ACTIVITY_TYPE_UPDATE_RECORD) {
                                        autoTask.PC_ActionClass__c = PC_Constants.PC_UPDATE_RECORD_ACTION_CLASS;
                                        autoTask.PC_AutomationTaskType__c = spAct.PC_ActivityType__c;
                                    }
                                    //else
                                    automationTaskList.add(autoTask);
                                }
                            }
                        }else{
                            //Create Error task and assign it to the User who initiated the support Plan
                            Id runningUserId = getRunningUserId(transactionInfo.transactionId);

                            List<Object> formattingArguments = new List<Object>{supportPlanRunTime.PC_SupportPlan__r.Name};
                            String errorDescription;
                            if(!maxSPRecursiveExecutionsAllowed.isNumeric()){
                                errorDescription = Label.PC_SupportPlan_MaxRecursionsSettingErrorMessage;
                            }else{
                                errorDescription = String.format(Label.PC_SupportPlan_RecursionErrorMessage, formattingArguments);
                            }
                            userTaskList.add(createErrorTask(false,triggerRecordId, runningUserId, errorDescription, spAct.Id));
                            spaLogListForTasks.add(createSupportPlanActivityLog(PC_Constants.PC_LOG_STATUS_FAILED, transactioninfo.transactionId,triggerRecordId, supportPlanRunTime.Id, spAct.Id, runtimeUserId));

                            //Throw Support Plan Exception to create error log
                            SupportPlan_Exception supportPlanException = new SupportPlan_Exception();
                            supportPlanException.setMessage(errorDescription);
                            PC_Utility.createExceptionLog(supportPlanException);
                        }
                    }
                }
            }
        }
        //Insert Tasks
        if(userTaskList.size() > 0) {
            userTaskList = (List<Task>) PC_Database.ins(userTaskList);
        }
        //Insert Tasks for Automation Tasks
        if(tasksForAutomationTaskList.size() > 0) {
            tasksForAutomationTaskList = (List<Task>) PC_Database.ins(tasksForAutomationTaskList);
        }
        //Assign Task Id for Automation Tasks
        if(automationTaskList.size() > 0 && tasksForAutomationTaskList.size() > 0) {
            for(PC_Automation_Task__e automationTask: automationTaskList){
                for(Task task: tasksForAutomationTaskList){
                    if(task.PC_SupportPlanActivity__r.PC_ActivityType__c == PC_Constants.SUPPORTPLAN_ACTIVITY_TYPE_AUTOMATED_TASK
                            && automationTask.PC_SupportPlanActivityId__c == task.PC_SupportPlanActivity__c){
                        automationTask.PC_TaskId__c = task.Id;
                    }
                }
            }
        }
        //Publish Automation Task Platform events
        if(automationTaskList.size() > 0) {
            LIST<Database.SaveResult> result = EventBus.publish(automationTaskList);
        }
        //Assign Action Record Id for task Support Plan Activity Logs
        if(spaLogListForTasks.size() > 0) {
            Set<Id> taskIds = (new Map<Id,SObject>(userTaskList)).keySet();
            List<String> taskfields = new List<String>{'Id', 'LastModifiedDate', PC_Constants.getQualifiedAPIName('PC_SupportPlanActivity__c')};
            PC_Database.assertAccess(PC_Constants.PC_TASK, PC_Database.Operation.Reading, taskfields);
            List<Task> tasksWithLastModifiedDate = [Select Id, LastModifiedDate,PC_SupportPlanActivity__c FROM Task WHERE ID IN: taskIds];
            for (PC_SupportPlanActivityLog__c spaLog : spaLogListForTasks) {
                for (Task task : tasksWithLastModifiedDate) {
                    if(task.PC_SupportPlanActivity__c == spalog.PC_SupportPlanActivity__c){
                        spaLog.PC_ActionRecordId__c = task.Id;
                        system.debug('task.LastModifiedDate>> '+task.LastModifiedDate);
                        spaLog.PC_ActionRecordModifiedTime__c = task.LastModifiedDate;
                    }
                }
            }
        }
        if(spaLogListForTasks.size() > 0) {
            spaLogListForTasks = (List<PC_SupportPlanActivityLog__c>) PC_Database.ins(spaLogListForTasks);
        }
    }
    /*********************************************************************************
    Method Name    : getRunningUserId
    Description    : This method fetches the Id of User who triggered the Support plan initially based on transaction Id
    Return Type    : Id
    Parameter      : transactionId
    *********************************************************************************/
    private static Id getRunningUserId(String transactionId) {
        /*FLS Check for Support Plan Activity Log*/
        List<String> logFields = new List<String>{PC_Constants.getQualifiedAPIName('PC_RuntimeUser__c'),PC_Constants.getQualifiedAPIName('PC_TransactionId__c')};
        PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_SupportPlanActivityLog__c'), PC_Database.Operation.Reading, logFields);

        List<PC_SupportPlanActivityLog__c> logListForTransaction = [Select PC_RuntimeUser__c FROM PC_SupportPlanActivityLog__c
        WHERE PC_RuntimeUser__c !=: UserInfo.getUserId() AND PC_TransactionId__c =: transactionId ];

        Id runningUserId;
        if(!logListForTransaction.isEmpty()){
            runningUserId = logListForTransaction[0].PC_RuntimeUser__c;
        }
        return runningUserId;
    }

    /*********************************************************************************
    Method Name    : createTask
    Description    : This method pre-poulates activity fields based on Support Plan Activity template
    Return Type    : Task
    Parameter      : recordId, supportPlanActivity, previousActivityClosedDate
    *********************************************************************************/
    private static Task createTask(Id recordId, PC_SupportPlanActivity__c spActivity, PC_SupportPlanRuntime__c supportPlanRuntime){
        Task t = new Task();
        String ownerRole;
        String selectField;
        if(spActivity != null) {
            String taskFields = spActivity.PC_UserTask_Fields__c;
            Set<PC_AutomationTaskHelper.FieldMap> requiredFieldWrapperSet = new Set<PC_AutomationTaskHelper.FieldMap>();
            Set<PC_ActivityProperties_Controller.RequiredFieldWrapper> requiredFieldOldWrappers = new Set<PC_ActivityProperties_Controller.RequiredFieldWrapper>();
            /*Below code is added for backward compatibility purposes.(Added in 14th version).
            *In old wrapper(RequiredFieldWrapper) isDeleteAllowed was a String but in new wrapper(PC_AutomationTaskHelper.FieldMap)
            *it is Boolean to support the older wrapper properties that was used by clients already below try catch is used*/
            try{
                PC_ActivityProperties_Controller.NewRequiredFieldSetWrapper allNewFieldsWrapper =
                        (PC_ActivityProperties_Controller.NewRequiredFieldSetWrapper) System.JSON.deserialize(taskFields, PC_ActivityProperties_Controller.NewRequiredFieldSetWrapper.class);
                requiredFieldWrapperSet.addAll(allNewFieldsWrapper.requiredFieldSet);
            }catch(Exception e){
                PC_ActivityProperties_Controller.RequiredFieldSetWrapper fieldsWrapper = (PC_ActivityProperties_Controller.RequiredFieldSetWrapper) System.JSON.deserialize(taskFields, PC_ActivityProperties_Controller.RequiredFieldSetWrapper.class);
                requiredFieldOldWrappers.addAll(fieldsWrapper.requiredFieldSet);
                requiredFieldWrapperSet.addAll(PC_AutomationTaskHelper.convertOldFieldWrapperToNew(requiredFieldOldWrappers));
            }
            String objectType = recordId.getSobjectType().getDescribe().getName();

            Set<String> referenceFields = new Set<String>();
            for (PC_AutomationTaskHelper.FieldMap row : requiredFieldWrapperSet) {
                if (String.valueOf(row.type) == PC_Constants.PC_FIELD_TYPE_REFERENCE) {
                    referenceFields.add(row.value);
                }
                /*** PC-7666: Check if the date/datetime field on the to be created task record is of Formula type.
                If it is then add the corresponding reference field api name to 'referenceFields' set, so to fetch its value from the trigger record ***/
                if((String.valueOf(row.type) == PC_Constants.PC_FIELD_TYPE_DATETIME || String.valueOf(row.type) == PC_Constants.PC_FIELD_TYPE_DATE) &&
                        (String.valueOf(row.value) == PC_Constants.PC_FORMULA_VALUE) && (String.valueOf(row.formulaValue.referenceFieldApiName)!=null)){
                    referenceFields.add(row.formulaValue.referenceFieldApiName);
                }
            }
            if(objectType == PC_Constants.PC_CASE){
                referenceFields.add(PC_Constants.getQualifiedAPIName('PC_Care_Coordinator__c'));
                referenceFields.add(PC_Constants.getQualifiedAPIName('PC_Reimbursment_Specialist__c'));
                referenceFields.add(PC_Constants.getQualifiedAPIName('PC_Physician__c'));
            }
            List<String> fieldsList = new List<String>();
            fieldsList.addAll(referenceFields);
            List<SObject> sObjectList = new List<SObject>();
            String recordsQuery = 'Select ';
            if(!fieldsList.isEmpty()){
                //FLS Check for Trigger Object Fields
                PC_Database.assertAccess(objectType, PC_Database.Operation.Reading, fieldsList);
                String sObjectFields = String.join(fieldsList, ',');
                recordsQuery = recordsQuery + sObjectFields;
            }
            Case relatedRecord;
            if(!fieldsList.isEmpty() || objectType == PC_Constants.PC_CASE){
                recordsQuery = recordsQuery+' from '+ objectType +' where Id = :recordId';
                sObjectList = Database.query(recordsQuery);
                //get related record Id on task
                Id taskWhatId;
                for (PC_AutomationTaskHelper.FieldMap row : requiredFieldWrapperSet) {
                    if(row.apiName.equalsIgnoreCase('whatId') && !sObjectList.isEmpty()){
                        taskWhatId = (Id)(sObjectList[0].get(row.value));
                        break;
                    }
                }
                //use relatedRecord only to assign task owner based on the role and if related record is of Sobject type Case
                if(String.isNotEmpty(taskWhatId) && taskWhatId != recordId){
                    String relatedSobjectName = taskWhatId.getSobjectType().getDescribe().getName();
                    if(relatedSobjectName == PC_Constants.PC_CASE){
                        //FLS Check for related Case fields
                        List<String> relatedCaseFields = new List<String>{PC_Constants.getQualifiedAPIName('PC_Care_Coordinator__c'),
                                PC_Constants.getQualifiedAPIName('PC_Reimbursment_Specialist__c'),
                                PC_Constants.getQualifiedAPIName('PC_Physician__c')};
                        PC_Database.assertAccess(PC_Constants.PC_CASE,PC_Database.Operation.Reading, relatedCaseFields);
                        relatedRecord =  [Select Id,PC_Care_Coordinator__c,PC_Reimbursment_Specialist__c,PC_Physician__c from Case where Id =: taskWhatId];
                    }
                }
            }
            //Set Default Task Record Type to PSP Task
            t.RecordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.PC_TASK, PC_Constants.PSP_TASK_RECORD_TYPE);
            //Get the Map of RecordTypeName along with Namespace and Record type Id for all Record Types in Task Object
            Map<String, Id> recordTypeIdMap =  PC_AutomationTaskHelper.getSObjectRecordTypeMap(PC_Constants.PC_TASK);
            for (PC_AutomationTaskHelper.FieldMap row : requiredFieldWrapperSet) {
                //Set Task RecordTypeId based on specified Record Type Name if any
                if(String.valueOf(row.apiName) == PC_Constants.PC_RecordTypeDeveloperName){
                    if(recordtypeIdMap.containsKey(row.value)) {
                        t.put(PC_Constants.PC_RECORD_TYPE_ID, recordtypeIdMap.get(row.value));
                    }
                }else{
                    if(row.apiName == PC_Constants.getQualifiedAPIName('PC_Assign_to_Role__c')){
                        t.put(row.apiName, row.value);
                        /*ownerRole = row.value;
                        if(!String.isEmpty(ownerRole) && objectType == PC_Constants.PC_CASE) {
                            selectField = (ownerRole == PC_Constants.PC_ROLE_CARE_COORDINATOR) ? PC_Constants.getQualifiedAPIName('PC_Care_Coordinator__c') :
                                    (ownerRole == PC_Constants.PC_ROLE_REIMBURSEMENT_SPECIALIST) ? PC_Constants.getQualifiedAPIName('PC_Reimbursment_Specialist__c') :
                                            (ownerRole == PC_Constants.ROLE_TREATING_PHYSICIAN) ? PC_Constants.getQualifiedAPIName('PC_Physician__c') : null;
                            Id ownerID;
                            //Assign task to user based on corresponding role value on related case record of Task
                            //This is needed in order to avoid getting validation error on PC_AssignToRoleTaskHandler that is thrown when
                            //task owner Id is not same as the corresponding role user on task related record.
                            if(relatedRecord != null && selectField != null){
                                //Without this, task will get assigned to user on Trigger record and not related record on Task if both are different
                                ownerID  =  (Id) relatedRecord.get(selectField);
                            }else if(selectField != null && sObjectList[0].get(selectField) != null){
                                //Assign task to user based on corresponding role value on Trigger case record
                                ownerID  =  (Id) sObjectList[0].get(selectField);
                            }
                            if(ownerID != null) {
                                t.OwnerId = ownerID;
                            }
                        }*/
                    }else if (String.valueOf(row.type) == PC_Constants.PC_FIELD_TYPE_BOOLEAN) {
                        t.put(row.apiName, Boolean.valueOf(row.value));
                    } else if (String.valueOf(row.type) == PC_Constants.PC_FIELD_TYPE_DATE) {
                        if(row.value == PC_Constants.PC_TODAY_VALUE){
                            t.put(row.apiName, date.today());
                        }else if(row.value == PC_Constants.PC_FORMULA_VALUE) {
                            /** PC-7666: Populate task record's date/datetime field values from the formula field value of trigger record -- START**/

                            PC_AutomationTaskHelper.calculateAndAssignFormulaValues(sObjectList,t,row);

                            /** PC-7666: Populate task record's date/datetime field values from the formula field value of trigger record -- END**/
                        }
                        else{
                            t.put(row.apiName, Date.valueOf(row.value));
                        }
                    } else if (String.valueOf(row.type) == PC_Constants.PC_FIELD_TYPE_DATETIME) {
                        if(row.value == PC_Constants.PC_NOW_VALUE){
                            t.put(row.apiName, DateTime.now());
                        }else if(row.value == PC_Constants.PC_FORMULA_VALUE) {
                            /** PC-7666: Populate task record's date/datetime field values from the formula field value of trigger record -- START**/

                            PC_AutomationTaskHelper.calculateAndAssignFormulaValues(sObjectList,t,row);

                            /** PC-7666: Populate task record's date/datetime field values from the formula field value of trigger record -- END**/
                        }

                        else{
                            //Converting into expected DateTime format
                            String strDate = (row.value).replace('T', ' ').replace('Z', '');
                            t.put(row.apiName, DateTime.valueOfGmt(strDate));
                        }
                    } else if (String.valueOf(row.type) == PC_Constants.PC_FIELD_TYPE_DOUBLE
                            ||  String.valueOf(row.type) == PC_Constants.PC_FIELD_TYPE_PERCENT
                            ||  String.valueOf(row.type) == PC_Constants.PC_FIELD_TYPE_CURRENCY ) {
                        t.put(row.apiName, Double.valueOf(row.value));
                    } else if (String.valueOf(row.type) == PC_Constants.PC_FIELD_TYPE_REFERENCE) {
                        t.put(row.apiName, sObjectList[0].get(row.value));
                    } else if (String.valueOf(row.type) == PC_Constants.PC_FIELD_TYPE_TIME) {
                        t.put(row.apiName, PC_Utility.parseTimeFromJSONString(row.value));
                    } else {
                        t.put(row.apiName, row.value);
                    }
                }
            }

            Date dueDate = taskDueDateCalculator(supportPlanRuntime.PC_Completed_Activity_Date__c, recordId, objectType, spActivity);
            t.ActivityDate = dueDate;
            t.PC_Original_Due_Date__c = dueDate;
            t.PC_SupportPlanActivity__c = spActivity.Id;
            t.PC_SupportPlanActivity__r = spActivity;
            if(String.isEmpty(String.valueOf(t.WhatId))){
                //Activities are not supported for all object types. Below check ensures that task is mapped to a record of object for which Activities is enabled.
                try {
                    List<Schema.SObjectType> objectsWithActivitiesEnabled= new List<Schema.SObjectType>();
                    for (Schema.SObjectType whatIdObjectType : Task.WhatId.getDescribe().getReferenceTo()) {
                        objectsWithActivitiesEnabled.add(whatIdObjectType);
                        if (objectType == String.valueOf(whatIdObjectType)) {
                            t.WhatId = recordId;
                            break;
                        }
                    }
                    //Error logging for any Trigger object that does not have activities enabled.
                    handleObjectsWithActivitiesDisabled(objectType, objectsWithActivitiesEnabled);
                }catch (Exception ex){
                    String errorDescription = ex.getMessage();
                    ex.setMessage(errorDescription);
                    PC_Utility.ErrorInfoWrapper errorInfoWrapper = new PC_Utility.ErrorInfoWrapper(null,errorDescription,'PC_SupportPlanEngine','createTask',ex.getLineNumber(),null,PC_Utility.ERROR_LOG_LEVEL.ERROR_LOG_LEVEL_WARN,ex.getStackTraceString());
                    PC_Utility.createExceptionLog(errorInfoWrapper);
                }
            }
            //set Task Owner as Running User if value is empty
            if(String.isEmpty(String.valueOf(t.ownerId))){
                t.ownerId = supportPlanRuntime.OwnerId;
            }
        }
        system.debug('@@task in SP'+t.OwnerId);
        return t;
    }
    /*********************************************************************************
    Method Name    : handleObjectsWithActivitiesDisabled
    Description    : Throws a custom exception for any Trigger object that doesn't have activities enabled.
    Return Type    : void
    Parameter      : objectType(String), objectsWithActivitiesEnabled(List)
    *********************************************************************************/
    public static void handleObjectsWithActivitiesDisabled(String objectType, List<Schema.SObjectType> objectsWithActivitiesEnabled){
        SObjectType sObjType = ((SObject) Type.forName(objectType).newInstance()).getSObjectType();
        if(!objectsWithActivitiesEnabled.contains(sObjType)){
            PC_SupportPlanEngine.SupportPlan_Exception supportPlanException = new PC_SupportPlanEngine.SupportPlan_Exception();
            List<Object> formattingArguments = new List<Object>{objectType};
            supportPlanException.setMessage(String.format(Label.PC_SupportPlan_TaskWhatIdError, formattingArguments));
            throw supportPlanException;
        }
    }
    /*********************************************************************************
    Method Name    : taskDueDateCalculator
    Description    : Calculates Due Date for Task based on the setup
    Return Type    : Date
    Parameter      : previousActivityCompletionDate, recordId, spActivity
    *********************************************************************************/
    public static Date taskDueDateCalculator(Datetime previousActivityCompletionDate, Id recordId, String objectName, PC_SupportPlanActivity__c spActivity){

        Date dueDate = Date.today();
        String noneStr=PC_Constants.PC_NONE;
        String referenceDateField = spActivity.PC_ReferenceDate__c;
        Integer noOfDays = (spActivity.PC_ReferenceOffset__c == null || string.isBlank(spActivity.PC_ReferenceOffset__c) ? 0 : Integer.valueOf(spActivity.PC_ReferenceOffset__c));
        String referenceType = spActivity.PC_ReferenceType__c;
        String referenceOffSetUnit = spActivity.PC_ReferenceOffsetUnit__c;

        if (string.isNotBlank(referenceType) && string.isNotBlank(referenceOffSetUnit)) {
            if (string.isNotBlank(referenceDateField) && !noneStr.equals(referenceDateField)) {
                /* FLS Check */
                List<String> triggerObjectFields = new List<String>{referenceDateField};
                PC_Database.assertAccess(objectName, PC_Database.Operation.Reading, triggerObjectFields);

                String queryString = 'select ' + referenceDateField + ' from ' + objectName + ' where Id =\'' + recordId + '\'';

                List<sObject> sObjectList = PC_Database.queryWithAccess(queryString, true);
                String referenceDateFieldValue = String.valueOf(sObjectList[0].get(referenceDateField));

                if (string.isNotBlank(referenceDateFieldValue)) {
                    dueDate = getDueDate(Date.valueOf(referenceDateFieldValue), referenceType, referenceOffSetUnit, noOfDays);
                } else if (null != previousActivityCompletionDate){
                    dueDate = getDueDate(Date.valueOf(previousActivityCompletionDate), referenceType, referenceOffSetUnit, noOfDays);
                } else{
                    dueDate = getDueDate(Date.today(), referenceType, referenceOffSetUnit, 0); // Passing noOfDays=0 since we want immediate attention of the user.
                }
            } else if (noneStr.equals(referenceDateField)){
                if(referenceType == PC_Constants.PC_ACTIVITY_CREATION_DATE){
                    dueDate = getDueDate(dueDate, referenceType, referenceOffSetUnit, noOfDays);
                }
                else if(null != previousActivityCompletionDate && referenceType == PC_Constants.SUPPORTPLANTASK_REFERENCETYPE_AFTERPREVACTIVITY) {
                    dueDate = getDueDate(Date.valueOf(previousActivityCompletionDate), referenceType, referenceOffSetUnit, noOfDays);
                }
                else {
                    dueDate = getDueDate(Date.today(), referenceType, referenceOffSetUnit, 0); // Passing noOfDays=0 since we want immediate attention of the user.
                }
            }
        }
        return dueDate;

    }

    /*****************************************************************************************************
    Method Name    : getDueDate
    Description    : This method calculates the due date for Support Plan Activity
    Return Type    : Date
    Parameter      : Date referenceDate,String referenceType,String referenceOffSetUnit,Integer noOfDays
    ******************************************************************************************************/
    private static Date getDueDate(Date referenceDate,String referenceType,String referenceOffSetUnit,Integer noOfDays){
        Date calculatedDueDate;

        if(referenceType == PC_Constants.SUPPORTPLANTASK_REFERENCETYPE_BEFOREREFDATE){

            If(referenceOffSetUnit== PC_Constants.SUPPORTPLANTASK_REFERENCEUNIT_DAYS){
                calculatedDueDate=(Date.valueOf(referenceDate)).addDays(-noOfDays);
            }
        }
        else if((referenceType == PC_Constants.SUPPORTPLANTASK_REFERENCETYPE_AFTERREFDATE)||
                referenceType == PC_Constants.SUPPORTPLANTASK_REFERENCETYPE_AFTERPREVACTIVITY){

            If(referenceOffSetUnit == PC_Constants.SUPPORTPLANTASK_REFERENCEUNIT_DAYS){
                calculatedDueDate=(Date.valueOf(referenceDate)).addDays(noOfDays);
            }
        }
        else if((referenceType == PC_Constants.PC_ACTIVITY_CREATION_DATE)){

            If(referenceOffSetUnit == PC_Constants.SUPPORTPLANTASK_REFERENCEUNIT_DAYS){
                calculatedDueDate=((referenceDate).addDays(noOfDays));
            }
        }
        return calculatedDueDate;
    }
    /*****************************************************************************************************
    Method Name    : createSupportPlanActivityLog
    Description    : This method creates Support Plan Activity Log
    Return Type    : void
    Parameter      : transactionId, triggerRecordId, supportPlanRunTimeId, spActivityId, RuntimeUserId
    ******************************************************************************************************/
    private static PC_SupportPlanActivityLog__c createSupportPlanActivityLog(String status, String transactionId,String triggerRecordId, Id supportPlanRunTimeId, Id spActivityId, Id RuntimeUserId){

        PC_SupportPlanActivityLog__c log =  new PC_SupportPlanActivityLog__c();
        log.PC_LogDateTime__c = System.now();
        log.PC_TriggerRecordId__c = triggerRecordId;
        log.PC_SupportPlanActivity__c = spActivityId;
        log.PC_RuntimeUser__c = RuntimeUserId;
        log.PC_SupportPlanRuntime__c = supportPlanRunTimeId;
        log.PC_TransactionId__c = transactionId;
        log.PC_Status__c = status;
        return log;
    }

    /*********************************************************************************
    Method Name    : returnSupportPlanActivities
    Description    : For each SPRT in the list, evaluates the condition on group and activities to return the activity to be created.
                     Also, updates the relevant SPRT.
    Return Type    : MAP<ID, PC_SupportPlanActivity__c>
    Parameter      : LIST<PC_SupportPlanRuntime__c>, Map<Id,PC_SupportPlanInfo__e>
    *********************************************************************************/
    private static MAP<ID, PC_SupportPlanActivity__c> returnSupportPlanActivities(LIST<PC_SupportPlanRuntime__c> supportPlanRuntimes, Map<Id,PC_SupportPlanInfo__e> supportPlanRuntimeMap) {
        MAP<ID, PC_SupportPlanActivity__c> supportPlanActivitiesToCreate = new MAP<ID, PC_SupportPlanActivity__c>();
        Set<String> currrentActivityInternalId = new Set<String>();
        Set<String> currrentGroupInternalId = new Set<String>();
        LIST<PC_SupportPlanRuntime__c> supportPlanRuntimesToUpdate = new LIST<PC_SupportPlanRuntime__c>();
        LIST<PC_SupportPlanRuntime__c> supportPlanRuntimesToProcess = new LIST<PC_SupportPlanRuntime__c>();
        If (!supportPlanRuntimes.isEmpty()) {
            for (PC_SupportPlanRuntime__c supportPlanRuntime : supportPlanRuntimes) {
                Set<String> AllActivityIds = new Set<String>();
                if(supportPlanRunTime.PC_CurrentActivity__c != null){
                    AllActivityIds = (Set<String>) (System.JSON.deserialize(supportPlanRunTime.PC_CurrentActivity__c,Set<String>.class));
                }
                if(string.isBlank(supportPlanRuntime.PC_Current_Group__c)) {
                    currrentActivityInternalId.addAll(AllActivityIds);
                }else if(supportPlanRuntime.PC_Current_Group_Status__c == PC_Constants.SUPPORTPLANRT_ACTIVITY_STATUS_PENDINGCONDITION){
                    currrentGroupInternalId.add(supportPlanRuntime.PC_Current_Group__c);
                }else if(supportPlanRuntime.PC_Current_Group_Status__c == PC_Constants.SUPPORTPLANRT_ACTIVITY_STATUS_INPROGRESS){
                    currrentActivityInternalId.addAll(AllActivityIds);
                }
            }
        }
        /*FLS Check for PC_SupportPlanActivity__c*/
        List<String> supportPlanActivityFields = new List<String>{'Name', PC_Constants.getQualifiedAPIName('PC_InternalActivityNumber__c'), PC_Constants.getQualifiedAPIName('PC_Description__c')
                , PC_Constants.getQualifiedAPIName('PC_ActivityType__c'), PC_Constants.getQualifiedAPIName('PC_ApexCondition__c'), PC_Constants.getQualifiedAPIName('PC_ConditionBehavior__c')
                , PC_Constants.getQualifiedAPIName('PC_ReferenceDate__c'), PC_Constants.getQualifiedAPIName('PC_ReferenceOffset__c'), PC_Constants.getQualifiedAPIName('PC_ReferenceOffsetUnit__c')
                , PC_Constants.getQualifiedAPIName('PC_ReferenceType__c'), PC_Constants.getQualifiedAPIName('PC_NextActivityNumber__c'), PC_Constants.getQualifiedAPIName('PC_AlternateActivity__c')
                , PC_Constants.getQualifiedAPIName('PC_ActivitySequence__c'), PC_Constants.getQualifiedAPIName('PC_ConditionOption__c'), PC_Constants.getQualifiedAPIName('PC_Subject__c')
                , PC_Constants.getQualifiedAPIName('PC_InitialSequenceActivity__c'), PC_Constants.getQualifiedAPIName('PC_SupportPlan__c'), PC_Constants.getQualifiedAPIName('PC_Channel__c')
                , PC_Constants.getQualifiedAPIName('PC_Priority__c'), PC_Constants.getQualifiedAPIName('PC_Conditional_Logic__c'), PC_Constants.getQualifiedAPIName('PC_Assign_To_Role__c')
                , PC_Constants.getQualifiedAPIName('PC_UserTask_Fields__c'), PC_Constants.getQualifiedAPIName('PC_SupportPlan__r.Name')};
        PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_SupportPlanActivity__c'), PC_Database.Operation.Reading, supportPlanActivityFields);
        If(currrentGroupInternalId.size() > 0) {
            List<PC_SupportPlanActivity__c> supportPlanGroups = [
                    SELECT Id, Name, PC_InternalActivityNumber__c, PC_Description__c, PC_ActivityType__c,
                            PC_ApexCondition__c, PC_ConditionBehavior__c, PC_ReferenceDate__c, PC_ReferenceOffset__c,
                            PC_ReferenceOffsetUnit__c, PC_ReferenceType__c, PC_NextActivityNumber__c, PC_AlternateActivity__c,
                            PC_ActivitySequence__c, PC_ConditionOption__c, PC_Subject__c, PC_InitialSequenceActivity__c, PC_SupportPlan__c,
                            PC_SupportPlan__r.Id, PC_Channel__c, PC_Priority__c, PC_Conditional_Logic__c, PC_Assign_To_Role__c, PC_UserTask_Fields__c,
                            PC_SubType__c, PC_AutomationTaskJSON__c,PC_ActionClass__c, PC_GroupActivityExecution__c,PC_SupportPlan__r.Name
                    FROM PC_SupportPlanActivity__c
                    WHERE PC_InternalActivityNumber__c IN :currrentGroupInternalId
            ];

            for (PC_SupportPlanRuntime__c supportPlanRunTime : supportPlanRuntimes) {
                Id triggerRecordId;
                if(String.isNotEmpty(supportPlanRunTime.PC_RecordId__c)){
                    triggerRecordId = (Id)supportPlanRunTime.PC_RecordId__c;
                }else{
                    triggerRecordId = supportPlanRunTime.PC_SupportPlanCase__c;
                }
                for (PC_SupportPlanActivity__c supportPlanGroup : supportPlanGroups) {
                    If (supportPlanRunTime.PC_Current_Group__c == supportPlanGroup.PC_InternalActivityNumber__c) {
                        If(supportPlanGroup.PC_ConditionBehavior__c == PC_Constants.SUPPORTPLAN_CONDBEHAVIOR_STATUS_NONE){
                            currrentActivityInternalId.add(supportPlanGroup.PC_InitialSequenceActivity__c);
                            supportPlanRunTime.PC_Current_Group_Status__c = PC_Constants.SUPPORTPLANRT_ACTIVITY_STATUS_INPROGRESS;

                        }else If (supportPlanGroup.PC_ConditionBehavior__c == PC_Constants.SUPPORTPLAN_CONDBEHAVIOR_STATUS_WAIT) {
                            if(evaluateCondition(supportPlanGroup, triggerRecordId, supportPlanRunTime)) {
                                currrentActivityInternalId.add(supportPlanGroup.PC_InitialSequenceActivity__c);
                                supportPlanRunTime.PC_Current_Group_Status__c = PC_Constants.SUPPORTPLANRT_ACTIVITY_STATUS_INPROGRESS;
                            }else{
                                supportPlanRunTime.PC_Current_Group_Status__c = PC_Constants.SUPPORTPLANRT_ACTIVITY_STATUS_PENDINGCONDITION;
                            }
                        }else if(supportPlanGroup.PC_ConditionBehavior__c == PC_Constants.SUPPORTPLAN_CONDBEHAVIOR_STATUS_SKIPFALSE){
                            if(evaluateCondition(supportPlanGroup, triggerRecordId, supportPlanRunTime)) {
                                currrentActivityInternalId.add(supportPlanGroup.PC_InitialSequenceActivity__c);
                                supportPlanRunTime.PC_Current_Group_Status__c = PC_Constants.SUPPORTPLANRT_ACTIVITY_STATUS_INPROGRESS;
                            }else{
                                supportPlanRunTime.PC_Current_Group__c  = null;
                                supportPlanRunTime.PC_Current_Group_Status__c = null;
                                supportPlanRunTime = updateSupportPlanRuntime(supportPlanRunTime,supportPlanGroup);
                                supportPlanRuntimesToProcess.add(supportPlanRunTime);
                            }
                        }
                    }
                }
                supportPlanRuntimesToUpdate.add(supportPlanRunTime);
            }

            if(supportPlanRuntimesToUpdate.size() > 0){
                PC_Database.upd(supportPlanRuntimesToUpdate);
            }
        }
        supportPlanRuntimesToUpdate = new LIST<PC_SupportPlanRuntime__c>();
        List<PC_SupportPlanActivity__c> supportPlanActivities = new List<PC_SupportPlanActivity__c>();
        If(currrentActivityInternalId.size() > 0) {
            /*FLS Check for PC_SupportPlanActivity__c*/
            List<String> spaFields = new List<String>{'Name', PC_Constants.getQualifiedAPIName('PC_InternalActivityNumber__c'), PC_Constants.getQualifiedAPIName('PC_Description__c')
                    , PC_Constants.getQualifiedAPIName('PC_ActivityType__c'), PC_Constants.getQualifiedAPIName('PC_ApexCondition__c'), PC_Constants.getQualifiedAPIName('PC_ConditionBehavior__c')
                    , PC_Constants.getQualifiedAPIName('PC_ReferenceDate__c'), PC_Constants.getQualifiedAPIName('PC_ReferenceOffset__c'), PC_Constants.getQualifiedAPIName('PC_ReferenceOffsetUnit__c')
                    , PC_Constants.getQualifiedAPIName('PC_ReferenceType__c'), PC_Constants.getQualifiedAPIName('PC_NextActivityNumber__c'), PC_Constants.getQualifiedAPIName('PC_AlternateActivity__c')
                    , PC_Constants.getQualifiedAPIName('PC_ActivitySequence__c'), PC_Constants.getQualifiedAPIName('PC_ConditionOption__c'), PC_Constants.getQualifiedAPIName('PC_Subject__c')
                    , PC_Constants.getQualifiedAPIName('PC_InitialSequenceActivity__c'), PC_Constants.getQualifiedAPIName('PC_SupportPlan__c'), PC_Constants.getQualifiedAPIName('PC_Channel__c')
                    , PC_Constants.getQualifiedAPIName('PC_Priority__c'), PC_Constants.getQualifiedAPIName('PC_Conditional_Logic__c'), PC_Constants.getQualifiedAPIName('PC_Assign_To_Role__c')
                    , PC_Constants.getQualifiedAPIName('PC_UserTask_Fields__c'), PC_Constants.getQualifiedAPIName('PC_SupportPlan__r.Name')};
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_SupportPlanActivity__c'), PC_Database.Operation.Reading, spaFields);

            supportPlanActivities = [
                    SELECT Id, Name, PC_InternalActivityNumber__c, PC_Description__c, PC_ActivityType__c,
                            PC_ApexCondition__c, PC_ConditionBehavior__c, PC_ReferenceDate__c, PC_ReferenceOffset__c,
                            PC_ReferenceOffsetUnit__c, PC_ReferenceType__c, PC_NextActivityNumber__c, PC_AlternateActivity__c,
                            PC_ActivitySequence__c, PC_ConditionOption__c, PC_Subject__c, PC_InitialSequenceActivity__c, PC_SupportPlan__c,
                            PC_SupportPlan__r.Id, PC_Channel__c, PC_Priority__c, PC_Conditional_Logic__c, PC_Assign_To_Role__c, PC_UserTask_Fields__c,
                            PC_SubType__c, PC_AutomationTaskJSON__c,PC_ActionClass__c, PC_GroupActivityExecution__c,PC_SupportPlan__r.Name
                    FROM PC_SupportPlanActivity__c
                    WHERE PC_InternalActivityNumber__c IN :currrentActivityInternalId
            ];
            for (PC_SupportPlanRuntime__c supportPlanRunTime : supportPlanRuntimes) {
                Id triggerRecordId;
                if(String.isNotEmpty(supportPlanRunTime.PC_RecordId__c)){
                    triggerRecordId = (Id)supportPlanRunTime.PC_RecordId__c;
                }else{
                    triggerRecordId = supportPlanRunTime.PC_SupportPlanCase__c;
                }
                for (PC_SupportPlanActivity__c supportPlanActivity : supportPlanActivities) {
                    Set<String> currentActivityId = new Set<String>();
                    if(supportPlanRunTime.PC_CurrentActivity__c != null){
                        currentActivityId = (Set<String>) (System.JSON.deserialize(supportPlanRunTime.PC_CurrentActivity__c,Set<String>.class));
                    }
                    If (currentActivityId.contains(supportPlanActivity.PC_InternalActivityNumber__c)) {
                        If(supportPlanActivity.PC_ConditionBehavior__c == PC_Constants.SUPPORTPLAN_CONDBEHAVIOR_STATUS_NONE){
                            supportPlanActivitiesToCreate.put(supportPlanRunTime.Id, supportPlanActivity);
                            supportPlanRunTime.PC_CurrentActivityStatus__c = PC_Constants.SUPPORTPLANRT_ACTIVITY_STATUS_INPROGRESS;

                        }else If (supportPlanActivity.PC_ConditionBehavior__c == PC_Constants.SUPPORTPLAN_CONDBEHAVIOR_STATUS_WAIT) {
                            if(evaluateCondition(supportPlanActivity, triggerRecordId, supportPlanRunTime)) {
                                supportPlanActivitiesToCreate.put(supportPlanRunTime.Id, supportPlanActivity);
                                supportPlanRunTime.PC_CurrentActivityStatus__c = PC_Constants.SUPPORTPLANRT_ACTIVITY_STATUS_INPROGRESS;
                            }else{
                                supportPlanRunTime.PC_CurrentActivityStatus__c = PC_Constants.SUPPORTPLANRT_ACTIVITY_STATUS_PENDINGCONDITION;
                            }
                        }else if(supportPlanActivity.PC_ConditionBehavior__c == PC_Constants.SUPPORTPLAN_CONDBEHAVIOR_STATUS_SKIPFALSE){
                            if(evaluateCondition(supportPlanActivity, triggerRecordId, supportPlanRunTime)) {
                                supportPlanActivitiesToCreate.put(supportPlanRunTime.Id, supportPlanActivity);
                                supportPlanRunTime.PC_CurrentActivityStatus__c = PC_Constants.SUPPORTPLANRT_ACTIVITY_STATUS_INPROGRESS;
                            }else{
                                supportPlanRunTime = updateSupportPlanRuntime(supportPlanRunTime,supportPlanActivity);
                                supportPlanRuntimesToProcess.add(supportPlanRunTime);
                            }
                        }
                    }
                }
                supportPlanRuntimesToUpdate.add(supportPlanRunTime);
            }
        }
        if(supportPlanRuntimesToUpdate.size() > 0){
            PC_Database.upd(supportPlanRuntimesToUpdate);
        }
        if(supportPlanRuntimesToProcess.size() > 0){
            List<SupportPlanInfo> supportPlanInfoList = new List<SupportPlanInfo>();
            for(PC_SupportPlanRuntime__c runtime: supportPlanRuntimesToProcess){
                SupportPlanInfo supportPlanInfo = new SupportPlanInfo();
                supportPlanInfo.runtimeId = runtime.Id;
                supportPlanInfo.context = PC_Constants.SupportPlanInfoContext.ProcessSupportPlanRuntimes;
                supportPlanInfo.triggerRecordModifiedTime = supportPlanRuntimeMap.get(runtime.Id).PC_TriggerRecordModifiedTime__c;
                supportPlanInfoList.add(supportPlanInfo);
            }
            publishSupportPlanPlatformEvent(supportPlanInfoList);
        }
        return supportPlanActivitiesToCreate;
    }

    /*********************************************************************************
    Method Name    : returnAllSupportPlanActivities
    Description    : For each SPRT in the list, evaluate the condition on the group and activities,
                    to return the activity to be created and update the relevant SPRT.
    Return Type    : MAP<ID, List<PC_SupportPlanActivity__c>>
    Parameter      : LIST<PC_SupportPlanRuntime__c>, Map<Id,PC_SupportPlanInfo__e>
    *********************************************************************************/
    private static MAP<ID, List<PC_SupportPlanActivity__c>> returnAllSupportPlanActivities(LIST<PC_SupportPlanRuntime__c> supportPlanRuntimes, Map<Id,PC_SupportPlanInfo__e> supportPlanRuntimeMap) {
        MAP<ID, List<PC_SupportPlanActivity__c>> supportPlanActivitiesToCreate = new MAP<ID, List<PC_SupportPlanActivity__c>>();
        Set<String> currrentActivityInternalId = new Set<String>();
        Set<String> currrentGroupInternalId = new Set<String>();
        LIST<PC_SupportPlanRuntime__c> supportPlanRuntimesToUpdate = new LIST<PC_SupportPlanRuntime__c>();
        LIST<PC_SupportPlanRuntime__c> supportPlanRuntimesToProcess = new LIST<PC_SupportPlanRuntime__c>();
        If (!supportPlanRuntimes.isEmpty()) {
            for (PC_SupportPlanRuntime__c supportPlanRuntime : supportPlanRuntimes) {
                /*if(string.isBlank(supportPlanRuntime.PC_Current_Group__c)) {
                    //This wont be possible, due to earlier conditions
                    //currrentActivityInternalId.add(supportPlanRuntime.PC_CurrentGroupAllActivities__c);
                }else */if(supportPlanRuntime.PC_Current_Group_Status__c == PC_Constants.SUPPORTPLANRT_ACTIVITY_STATUS_PENDINGCONDITION){
                    currrentGroupInternalId.add(supportPlanRuntime.PC_Current_Group__c);
                }/*else if(supportPlanRuntime.PC_Current_Group_Status__c == PC_Constants.SUPPORTPLANRT_ACTIVITY_STATUS_INPROGRESS){
                    //Check the set of Activity ids in PC_CurrentGroupAllActivities__c
                    //currrentActivityInternalId.add(supportPlanRuntime.PC_CurrentGroupAllActivities__c);
                }*/
            }
        }

        If(currrentGroupInternalId.size() > 0) {
            /*FLS Check for PC_SupportPlan__c*/
            List<String> supportPlanActivityFields = new List<String>{'Name', PC_Constants.getQualifiedAPIName('PC_InternalActivityNumber__c'), PC_Constants.getQualifiedAPIName('PC_Description__c')
                    , PC_Constants.getQualifiedAPIName('PC_ActivityType__c'), PC_Constants.getQualifiedAPIName('PC_ApexCondition__c'), PC_Constants.getQualifiedAPIName('PC_ConditionBehavior__c')
                    , PC_Constants.getQualifiedAPIName('PC_ReferenceDate__c'), PC_Constants.getQualifiedAPIName('PC_ReferenceOffset__c'), PC_Constants.getQualifiedAPIName('PC_ReferenceOffsetUnit__c')
                    , PC_Constants.getQualifiedAPIName('PC_ReferenceType__c'), PC_Constants.getQualifiedAPIName('PC_NextActivityNumber__c'), PC_Constants.getQualifiedAPIName('PC_AlternateActivity__c')
                    , PC_Constants.getQualifiedAPIName('PC_ActivitySequence__c'), PC_Constants.getQualifiedAPIName('PC_ConditionOption__c'), PC_Constants.getQualifiedAPIName('PC_Subject__c')
                    , PC_Constants.getQualifiedAPIName('PC_InitialSequenceActivity__c'), PC_Constants.getQualifiedAPIName('PC_SupportPlan__c'), PC_Constants.getQualifiedAPIName('PC_Channel__c')
                    , PC_Constants.getQualifiedAPIName('PC_Priority__c'), PC_Constants.getQualifiedAPIName('PC_Conditional_Logic__c'), PC_Constants.getQualifiedAPIName('PC_Assign_To_Role__c')
                    , PC_Constants.getQualifiedAPIName('PC_UserTask_Fields__c'), PC_Constants.getQualifiedAPIName('PC_SupportPlan__r.Name')};
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_SupportPlanActivity__c'), PC_Database.Operation.Reading, supportPlanActivityFields);

            List<PC_SupportPlanActivity__c> supportPlanGroups = [
                    SELECT Id, Name, PC_InternalActivityNumber__c, PC_Description__c, PC_ActivityType__c,
                            PC_ApexCondition__c, PC_ConditionBehavior__c, PC_ReferenceDate__c, PC_ReferenceOffset__c,
                            PC_ReferenceOffsetUnit__c, PC_ReferenceType__c, PC_NextActivityNumber__c, PC_AlternateActivity__c,
                            PC_ActivitySequence__c, PC_ConditionOption__c, PC_Subject__c, PC_InitialSequenceActivity__c, PC_SupportPlan__c,
                            PC_SupportPlan__r.Id, PC_Channel__c, PC_Priority__c, PC_Conditional_Logic__c, PC_Assign_To_Role__c, PC_UserTask_Fields__c,
                            PC_SubType__c, PC_AutomationTaskJSON__c,PC_ActionClass__c, PC_GroupActivityExecution__c,PC_SupportPlan__r.Name
                    FROM PC_SupportPlanActivity__c
                    WHERE PC_InternalActivityNumber__c IN :currrentGroupInternalId
            ];

            for (PC_SupportPlanRuntime__c supportPlanRunTime : supportPlanRuntimes) {
                Id triggerRecordId;
                if(String.isNotEmpty(supportPlanRunTime.PC_RecordId__c)){
                    triggerRecordId = (Id)supportPlanRunTime.PC_RecordId__c;
                }else{
                    triggerRecordId = supportPlanRunTime.PC_SupportPlanCase__c;
                }
                for (PC_SupportPlanActivity__c supportPlanGroup : supportPlanGroups) {
                    If (supportPlanRunTime.PC_Current_Group__c == supportPlanGroup.PC_InternalActivityNumber__c) {
                        Set<String> allGroupActivityIds = new Set<String>();
                        if(supportPlanRunTime.PC_CurrentGroupAllActivities__c != null){
                            allGroupActivityIds = (Set<String>) (System.JSON.deserialize(supportPlanRunTime.PC_CurrentGroupAllActivities__c,Set<String>.class));
                        }
                        If(supportPlanGroup.PC_ConditionBehavior__c == PC_Constants.SUPPORTPLAN_CONDBEHAVIOR_STATUS_NONE){
                            currrentActivityInternalId.addAll(allGroupActivityIds);
                            supportPlanRunTime.PC_Current_Group_Status__c = PC_Constants.SUPPORTPLANRT_ACTIVITY_STATUS_INPROGRESS;

                        }else If (supportPlanGroup.PC_ConditionBehavior__c == PC_Constants.SUPPORTPLAN_CONDBEHAVIOR_STATUS_WAIT) {
                            if(evaluateCondition(supportPlanGroup, triggerRecordId, supportPlanRunTime)) {
                                currrentActivityInternalId.addAll(allGroupActivityIds);
                                supportPlanRunTime.PC_Current_Group_Status__c = PC_Constants.SUPPORTPLANRT_ACTIVITY_STATUS_INPROGRESS;
                            }else{
                                supportPlanRunTime.PC_Current_Group_Status__c = PC_Constants.SUPPORTPLANRT_ACTIVITY_STATUS_PENDINGCONDITION;
                            }
                        }else if(supportPlanGroup.PC_ConditionBehavior__c == PC_Constants.SUPPORTPLAN_CONDBEHAVIOR_STATUS_SKIPFALSE){
                            if(evaluateCondition(supportPlanGroup, triggerRecordId, supportPlanRunTime)) {
                                currrentActivityInternalId.addAll(allGroupActivityIds);
                                supportPlanRunTime.PC_Current_Group_Status__c = PC_Constants.SUPPORTPLANRT_ACTIVITY_STATUS_INPROGRESS;
                            }else{
                                supportPlanRunTime.PC_Current_Group__c  = null;
                                supportPlanRunTime.PC_Current_Group_Status__c = null;
                                supportPlanRunTime = updateSupportPlanRuntime(supportPlanRunTime,supportPlanGroup);
                                supportPlanRuntimesToProcess.add(supportPlanRunTime);
                            }
                        }
                    }
                }
                supportPlanRuntimesToUpdate.add(supportPlanRunTime);
            }
            List<PC_SupportPlanActivity__c> supportPlanActivities =  new List<PC_SupportPlanActivity__c> ();
            If(currrentActivityInternalId.size() > 0) {
                /*FLS Check for PC_SupportPlan__c*/
                List<String> spaFields = new List<String>{'Name', PC_Constants.getQualifiedAPIName('PC_InternalActivityNumber__c'), PC_Constants.getQualifiedAPIName('PC_Description__c')
                        , PC_Constants.getQualifiedAPIName('PC_ActivityType__c'), PC_Constants.getQualifiedAPIName('PC_ApexCondition__c'), PC_Constants.getQualifiedAPIName('PC_ConditionBehavior__c')
                        , PC_Constants.getQualifiedAPIName('PC_ReferenceDate__c'), PC_Constants.getQualifiedAPIName('PC_ReferenceOffset__c'), PC_Constants.getQualifiedAPIName('PC_ReferenceOffsetUnit__c')
                        , PC_Constants.getQualifiedAPIName('PC_ReferenceType__c'), PC_Constants.getQualifiedAPIName('PC_NextActivityNumber__c'), PC_Constants.getQualifiedAPIName('PC_AlternateActivity__c')
                        , PC_Constants.getQualifiedAPIName('PC_ActivitySequence__c'), PC_Constants.getQualifiedAPIName('PC_ConditionOption__c'), PC_Constants.getQualifiedAPIName('PC_Subject__c')
                        , PC_Constants.getQualifiedAPIName('PC_InitialSequenceActivity__c'), PC_Constants.getQualifiedAPIName('PC_SupportPlan__c'), PC_Constants.getQualifiedAPIName('PC_Channel__c')
                        , PC_Constants.getQualifiedAPIName('PC_Priority__c'), PC_Constants.getQualifiedAPIName('PC_Conditional_Logic__c'), PC_Constants.getQualifiedAPIName('PC_Assign_To_Role__c')
                        , PC_Constants.getQualifiedAPIName('PC_UserTask_Fields__c')};
                PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_SupportPlanActivity__c'), PC_Database.Operation.Reading, spaFields);

                supportPlanActivities = [
                        SELECT Id, Name, PC_InternalActivityNumber__c, PC_Description__c, PC_ActivityType__c,
                                PC_ApexCondition__c, PC_ConditionBehavior__c, PC_ReferenceDate__c, PC_ReferenceOffset__c,
                                PC_ReferenceOffsetUnit__c, PC_ReferenceType__c, PC_NextActivityNumber__c, PC_AlternateActivity__c,
                                PC_ActivitySequence__c, PC_ConditionOption__c, PC_Subject__c, PC_InitialSequenceActivity__c, PC_SupportPlan__c,
                                PC_SupportPlan__r.Id, PC_Channel__c, PC_Priority__c, PC_Conditional_Logic__c, PC_Assign_To_Role__c, PC_UserTask_Fields__c,
                                PC_SubType__c, PC_AutomationTaskJSON__c,PC_ActionClass__c, PC_GroupActivityExecution__c
                        FROM PC_SupportPlanActivity__c
                        WHERE PC_InternalActivityNumber__c IN :currrentActivityInternalId
                ];
            }

            for (PC_SupportPlanRuntime__c supportPlanRunTime : supportPlanRuntimes) {
                List<PC_SupportPlanActivity__c> temp = new List<PC_SupportPlanActivity__c>();
                for (PC_SupportPlanActivity__c supportPlanActivity : supportPlanActivities) {
                    If (supportPlanRunTime.PC_Current_Group__c == supportPlanActivity.PC_ActivitySequence__c) {
                        temp.add(supportPlanActivity);
                    }
                }
                supportPlanActivitiesToCreate.put(supportPlanRunTime.Id,temp);
            }

            if(supportPlanRuntimesToUpdate.size() > 0){
                PC_Database.upd(supportPlanRuntimesToUpdate);
            }

            if(supportPlanRuntimesToProcess.size() > 0){
                List<SupportPlanInfo> supportPlanInfoList = new List<SupportPlanInfo>();
                for(PC_SupportPlanRuntime__c runtime: supportPlanRuntimesToProcess){
                    SupportPlanInfo supportPlanInfo = new SupportPlanInfo();
                    supportPlanInfo.runtimeId = runtime.Id;
                    supportPlanInfo.context = PC_Constants.SupportPlanInfoContext.ProcessSupportPlanRuntimes;
                    supportPlanInfo.triggerRecordModifiedTime = supportPlanRuntimeMap.get(runtime.Id).PC_TriggerRecordModifiedTime__c;
                    supportPlanInfoList.add(supportPlanInfo);
                }
                publishSupportPlanPlatformEvent(supportPlanInfoList);
            }
        }
        return supportPlanActivitiesToCreate;
    }
    /*********************************************************************************
     Method Name    : updateSupportPlanRuntime
     Description    : This method updates Support Plan Runtime Current Activity fields with details of next activity that is in sequence
     Return Type    : PC_SupportPlanrunTime__c
     Parameter      : PC_SupportPlanRunTime__c, supportPlanActivity
     *********************************************************************************/
    private static PC_SupportPlanRunTime__c updateSupportPlanRuntime(PC_SupportPlanRunTime__c supportPlanRuntime,PC_SupportPlanActivity__c supportPlanActivity){
        if(string.isNotBlank(supportPlanActivity.PC_NextActivityNumber__c)){
            SET<Id> nextActivityIds = new SET<Id>();
            nextActivityIds.add(supportPlanActivity.PC_NextActivityNumber__c);
            MAP<ID,InitialActivityWrapper> nextActivities = processInitialActivities(nextActivityIds);
            InitialActivityWrapper nextActivity = nextActivities.get(supportPlanActivity.PC_NextActivityNumber__c);

            supportPlanRuntime.PC_CurrentActivity__c                =   nextActivity.currentactivity;
            supportPlanRuntime.PC_CurrentActivityStatus__c          =   nextActivity.currentactivitystatus;

            supportPlanRuntime.PC_Current_Group__c                  =   nextActivity.currentgroup;
            supportPlanRuntime.PC_Current_Group_Status__c           =   nextActivity.currentgroupstatus;
            supportPlanRuntime.PC_Current_Group_Next_Activity__c    =   nextActivity.currentgroupnextactivity;
            supportPlanRuntime.PC_CurrentGroupAllActivities__c      =   nextActivity.currentgroupallactivities;
        }else{
            supportPlanRuntime.PC_EndTime__c                        = system.now();
            supportPlanRuntime.PC_CurrentActivityStatus__c          = PC_Constants.SUPPORTPLANRT_ACTIVITY_STATUS_COMPLETED;
        }
        return supportPlanRuntime;
    }

    /*********************************************************************************
    Method Name    : processInitialActivities
    Description    : Pass Support Plan Initial Activities
    Return Type    : Map <ID, intialActivityWrapper>
    Parameter      : Set<Id> initialActivityIds
    *********************************************************************************/
    private static MAP<ID, InitialActivityWrapper> processInitialActivities(Set<Id> initialActivityIds) {
        MAP<ID, InitialActivityWrapper> initialActivityMap = new MAP<ID, InitialActivityWrapper>();
        Set<Id> groupActivityIds = new Set<Id>();
        Map<Id,Set<String>> supportPlanGroupsActivityMap= new Map<Id,Set<String>>();
        /*FLS Check for PC_SupportPlanActivity__c*/
        List<String> supportPlanActivityFields = new List<String>{'Name', PC_Constants.getQualifiedAPIName('PC_InternalActivityNumber__c'), PC_Constants.getQualifiedAPIName('PC_Description__c')
                , PC_Constants.getQualifiedAPIName('PC_ActivityType__c'), PC_Constants.getQualifiedAPIName('PC_ApexCondition__c'), PC_Constants.getQualifiedAPIName('PC_ConditionBehavior__c')
                , PC_Constants.getQualifiedAPIName('PC_ReferenceDate__c'), PC_Constants.getQualifiedAPIName('PC_ReferenceOffset__c'), PC_Constants.getQualifiedAPIName('PC_ReferenceOffsetUnit__c')
                , PC_Constants.getQualifiedAPIName('PC_ReferenceType__c'), PC_Constants.getQualifiedAPIName('PC_NextActivityNumber__c'), PC_Constants.getQualifiedAPIName('PC_AlternateActivity__c')
                , PC_Constants.getQualifiedAPIName('PC_ActivitySequence__c'), PC_Constants.getQualifiedAPIName('PC_ConditionOption__c'), PC_Constants.getQualifiedAPIName('PC_GroupActivityExecution__c')
                , PC_Constants.getQualifiedAPIName('PC_InitialSequenceActivity__c'), PC_Constants.getQualifiedAPIName('PC_SupportPlan__c'), PC_Constants.getQualifiedAPIName('PC_Conditional_Logic__c')
                , PC_Constants.getQualifiedAPIName('PC_UserTask_Fields__c')};
        PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_SupportPlanActivity__c'), PC_Database.Operation.Reading, supportPlanActivityFields);

        List<PC_SupportPlanActivity__c> initialActivities = [SELECT Id, Name, PC_InternalActivityNumber__c, PC_ActivityType__c, PC_InternalActivityType__c,
                PC_NextActivityNumber__c, PC_AlternateActivity__c, PC_ActivitySequence__c, PC_InitialSequenceActivity__c,PC_SupportPlan__c, PC_GroupActivityExecution__c
        FROM PC_SupportPlanActivity__c
        WHERE PC_InternalActivityNumber__c IN :initialActivityIds];

        for(PC_SupportPlanActivity__c i : initialActivities){
            if(i.PC_InternalActivityType__c == PC_Constants.SUPPORTPLAN_ACTIVITY_TYPE_SEQUENCE && i.PC_GroupActivityExecution__c == PC_Constants.PC_ALL_AT_ONCE){
                groupActivityIds.add(i.PC_InternalActivityNumber__c);
            }
        }
        List<PC_SupportPlanActivity__c> AllGroupActivities = new List<PC_SupportPlanActivity__c>();
        if(groupActivityIds.size() > 0) {
            AllGroupActivities = [
                    SELECT Id, Name, PC_InternalActivityNumber__c, PC_ActivityType__c, PC_InternalActivityType__c,
                            PC_NextActivityNumber__c, PC_AlternateActivity__c, PC_ActivitySequence__c, PC_InitialSequenceActivity__c,PC_SupportPlan__c, PC_GroupActivityExecution__c
                    FROM PC_SupportPlanActivity__c
                    WHERE PC_ActivitySequence__c IN :groupActivityIds
            ];
        }

        for(Id spGrpIds : groupActivityIds){
            Set<String> tempAct = new Set<String>();
            for(PC_SupportPlanActivity__c spGrpAct : AllGroupActivities){
                if(spGrpAct.PC_ActivitySequence__c == spGrpIds){
                    tempAct.add(spGrpAct.PC_InternalActivityNumber__c);
                }
            }
            supportPlanGroupsActivityMap.put(spGrpIds,tempAct);
        }

        for(PC_SupportPlanActivity__c initialActivity : initialActivities){
            Set<String> temp = new Set<String>();
            if(supportPlanGroupsActivityMap.get(initialActivity.PC_InternalActivityNumber__c) != null){
                temp = supportPlanGroupsActivityMap.get(initialActivity.PC_InternalActivityNumber__c);
            }
            InitialActivityWrapper activityWrapper = new InitialActivityWrapper(initialActivity,temp);
            initialActivityMap.put(initialActivity.PC_InternalActivityNumber__c,activityWrapper);
        }
        return initialActivityMap;
    }

    /*********************************************************************************
    Method Name    : evaluateCondition
    Description    : This method evaluates the condition on Support Plan Activity
    Return Type    : Boolean
    Parameter      : PC_SupportPlanActivity__c, triggerRecordId, runtime
    *********************************************************************************/
    private static Boolean evaluateCondition(PC_SupportPlanActivity__c supportPlanActivity, Id triggerRecordId, PC_SupportPlanRuntime__c runtime) {
        Boolean returnValue;
        if(supportPlanActivity.PC_ConditionOption__c ==  PC_Constants.PC_COND_OPTION_APEX_CLASS){
            returnValue = evaluateApexCondition(supportPlanActivity.PC_ApexCondition__c, triggerRecordId);
        }else if(supportPlanActivity.PC_ConditionOption__c ==  PC_Constants.PC_COND_OPTION_CONDITIONAL_BUILDER){
            returnValue = evaluateSPAConditionBuilder(supportPlanActivity, triggerRecordId, runtime);
        }
        return returnValue;
    }

    /*********************************************************************************
    Method Name    : evaluateApexCondition
    Description    : This method evaluates Apex condition on Support Plan Activity
    Return Type    : Boolean
    Parameter      : conditionClassName, triggerRecordId
    *********************************************************************************/
    private static Boolean evaluateApexCondition(String conditionClassName, Id triggerRecordId) {
        Boolean result = false; //Default return value unless SupportPlanActivity condition is met
        if (conditionClassName != null && string.isNotBlank(conditionClassName)) {
            Type t = Type.forName(conditionClassName);
            if (t != null)
            {
                Object o = t.newInstance();
                if (o instanceof PC_SupportPlan.Condition){
                    PC_SupportPlan.Condition conditionClass = (PC_SupportPlan.Condition) o;
                    result = conditionClass.evaluate(triggerRecordId);
                }
            }
        } else {
            result = true;
        }
        return result;
    }

    /*********************************************************************************
    Method Name    : evaluateSPAConditionBuilder
    Description    : This method evaluates Conditional Builder condition on Support Plan Activity
    Return Type    : Boolean
    Parameter      : conditionClassName, triggerRecordId, runtime
    *********************************************************************************/
    private static Boolean evaluateSPAConditionBuilder(PC_SupportPlanActivity__c supportPlanActivity, Id triggerRecordId, PC_SupportPlanRuntime__c runtime) {
        //get the list of fields in condition logic to be queried from record
        ConditionLogicList lstConditions = new ConditionLogicList();
        lstConditions = (ConditionLogicList) System.JSON.deserialize(supportPlanActivity.PC_Conditional_Logic__c,ConditionLogicList.class);
        List<ConditionLogic> LstConditionsPerObject = lstConditions.LstConditionsPerObject;
        STRING ObjectType, recordValue;
        List<Condition> Conditions;
        for(ConditionLogic lstCondition : LstConditionsPerObject){
            ObjectType  = lstCondition.ObjectType;
            Conditions  = lstCondition.Conditions;
            recordValue = lstCondition.RecordValue;
        }
        Set<String> fieldAPINameSet =  new Set<String>();
        for(Condition condition : Conditions) {
            if(condition.FieldApiName != PC_Constants.PC_RecordTypeDeveloperName){
                fieldAPINameSet.add(condition.FieldApiName);
            }else{
                fieldAPINameSet.add(PC_Constants.PC_RECORD_TYPE_ID);
            }
        }
        SObject sObjRecord;
        Id completedActionRecordId = runtime.PC_Completed_Activity__c;
        Boolean isConditionSatisfied = false;
        //Query Record Fields to be evaluated
        if(!fieldAPINameSet.isEmpty()){
            List<String> fieldsList =  new List<String>();
            fieldsList.addAll(fieldAPINameSet);
            PC_Database.assertAccess(ObjectType, PC_Database.Operation.Reading, fieldsList);
            String sObjectFields = String.join(fieldsList, ',');
            String recordQuery = 'Select Id,' +sObjectFields +' from '+ ObjectType ;
            system.debug('recordValue>>'+recordValue);
            String triggerObjectType = ((Id) triggerRecordId).getSobjectType().getDescribe().getName();

            if((String.isNotEmpty(recordValue) && recordValue == PC_Constants.SUPPORTPLAN_PREVIOUS_ACTIVITY_KEY)
                    || (String.isEmpty(recordValue) && ObjectType == PC_Constants.PC_TASK && triggerObjectType != PC_Constants.PC_TASK)){
                recordQuery = recordQuery + ' where Id =:completedActionRecordId';
            }else{
                recordQuery = recordQuery +' where Id =:triggerRecordId';
            }
            system.debug('recordQuery>>'+recordQuery);
            if(String.isNotEmpty(recordQuery)){
                sObjRecord = Database.query (recordQuery);
                Map<String, Id> recordTypeIdMap =  PC_AutomationTaskHelper.getSObjectRecordTypeMap(ObjectType);
                isConditionSatisfied = evaluateConditionLogic(supportPlanActivity.PC_Conditional_Logic__c,sObjRecord,null,recordTypeIdMap,supportPlanActivity.PC_SupportPlan__r.Name,supportPlanActivity.Id,runtime.OwnerId);
            }
        }
        return isConditionSatisfied;
    }

    /*********************************************************************************
    Method Name    : createErrorTask
    Description    : This method is used to create Error task
    Parameter      : whatId, runningUserId, errorDescription
    *********************************************************************************/
    public static Task createErrorTask(Boolean insertTask, String whatId, String runningUserId, String errorDescription, String supportPlanActivityId){
        Task t = new Task();
        t.RecordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.PC_TASK, PC_Constants.PSP_TASK_RECORD_TYPE);
        t.ActivityDate = system.today();
        t.Status = PC_Constants.PC_TASK_STATUS_WAITING;
        t.Priority = PC_Constants.PC_PRIORITY_HIGH;
        t.PC_Channel__c = PC_Constants.PC_TASK;
        t.Subject = System.label.PC_ClientSideErrorMessage;
        t.Description = errorDescription;
        if(String.isNotEmpty(supportPlanActivityId)){
            t.PC_SupportPlanActivity__c = supportPlanActivityId;
        }
        if(String.isNotEmpty(whatId)){
            t.WhatId = whatId;
        }
        if(String.isNotEmpty(runningUserId)){
            t.OwnerId = runningUserId;
        }
        if(insertTask){
            PC_Database.ins(t,true);
        }
        return t;
    }
    /*********************************************************************************
    Method Name    : isSupportPlanInitiationHandlerActive
    Description    : This method fetches Trigger handler register Custom metadata record having Apex class "PC_SupportPlanInitiationHandler"
                      configured for sObject type based on Record Id in Support Plan Info Platform Event
    Parameter      : supportPlanEvent
    returnType     : Boolean
    *********************************************************************************/
    public static Boolean isSupportPlanInitiationHandlerActive(PC_SupportPlanInfo__e supportPlanEvent){
        Boolean isSPInitiationHandlerActive = false;
        if(supportPlanEvent != null){
            String recordId;
            if(String.isNotEmpty(supportPlanEvent.PC_RecordId__c)){
                recordId = supportPlanEvent.PC_RecordId__c;
            }else if(String.isNotEmpty(supportPlanEvent.PC_SupportPlanOrRuntimeIds__c)){
                /* FLS Check for PC_SupportPlanRuntime__c*/
                List<String> supportPlanRuntimeFields = new List<String>{'Id',PC_Constants.getQualifiedAPIName('PC_SupportPlanCase__c'),
                        PC_Constants.getQualifiedAPIName('PC_RecordId__c')};
                PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_SupportPlanRuntime__c'), PC_Database.Operation.Reading, supportPlanRuntimeFields);

                List<PC_SupportPlanRuntime__c> supportPlanRuntimes = [SELECT ID,PC_SupportPlanCase__c,PC_RecordId__c
                FROM PC_SupportPlanRuntime__c WHERE Id =: supportPlanEvent.PC_SupportPlanOrRuntimeIds__c];

                if(supportPlanRuntimes != null && !supportPlanRuntimes.isEmpty()){
                    if(String.isNotEmpty(supportPlanRuntimes[0].PC_SupportPlanCase__c)){
                        recordId = supportPlanRuntimes[0].PC_SupportPlanCase__c;
                    }else if(String.isNotEmpty(supportPlanRuntimes[0].PC_RecordId__c)){
                        recordId = supportPlanRuntimes[0].PC_RecordId__c;
                    }
                }
            }
            if(String.isNotEmpty(recordId)){
                String sObjectName = ((Id)recordId).getSobjectType().getDescribe().getName();
                system.debug('sObjectName>>'+sObjectName);

                List<PC_TriggerHandlerRegister__mdt> trigglerHandlerList = [SELECT PC_ApexClass__c,PC_Active__c,PC_OtherObject__c,PC_sObject__c
                    FROM PC_TriggerHandlerRegister__mdt
                    WHERE PC_sObject__c =: PC_Constants.TriggerHandler_sObject AND PC_OtherObject__c =: sObjectName
                    AND PC_Active__c = true AND PC_ApexClass__c =: PC_Constants.SUPPORTPLAN_INITIATIONHANDLER_CLASSNAME];

                if(trigglerHandlerList.isEmpty()){
                    //remove namespace prefix as the sObject picklist values in trigger handler register doesn't contain namespace prefix.
                    sObjectName = sObjectName.contains('__') ? (sObjectName.countMatches('__') == 2 ? sObjectName.substringAfter('__') : sObjectName): sObjectName;
                    trigglerHandlerList = [SELECT PC_ApexClass__c,PC_Active__c,PC_OtherObject__c,PC_sObject__c FROM PC_TriggerHandlerRegister__mdt
                    WHERE PC_sObject__c =: sObjectName AND PC_Active__c = true AND PC_ApexClass__c =: PC_Constants.SUPPORTPLAN_INITIATIONHANDLER_CLASSNAME];
                }
                system.debug('trigglerHandlerList>>'+trigglerHandlerList);
                if(!trigglerHandlerList.isEmpty() && trigglerHandlerList != null && trigglerHandlerList.size()>0){
                    isSPInitiationHandlerActive = true;
                }
            }
        }
        return isSPInitiationHandlerActive;
    }

    /*******************************************************************************
    Method Name    : getTransactionDetails
    Description    : This method fetches details related to Support Plan Transaction
    Return Type    : TransactionInfo
    Parameter      : supportPlanActivityId, runtimeUserId, triggerRecordId, supportPlanInfo
    *********************************************************************************/
    private static TransactionInfo getTransactionDetails(Id supportPlanActivityId, Id runtimeUserId, Id triggerRecordId, PC_SupportPlanInfo__e supportPlanInfo) {
        Integer logCount;
        TransactionInfo transactionInfo = new TransactionInfo();
        String transactionId = supportPlanInfo.PC_TransactionId__c;
        DateTime triggerRecordModifiedTime = supportPlanInfo.PC_TriggerRecordModifiedTime__c;
        //if runtimeUserId is of Automated Process, it is considered either the current Support Plan is getting executed recursively
        // or Support Plan is triggered through Platform event or another support Plan
        if(userInfo.getUserId() == runtimeUserId || String.isNotEmpty(transactionId)){
            /*FLS Check for Support Plan Activity Log*/
            List<String> logFields = new List<String>{PC_Constants.getQualifiedAPIName('PC_TransactionId__c')};
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_SupportPlanActivityLog__c'), PC_Database.Operation.Reading, logFields);
            system.debug('triggerRecordModifiedTime query>>'+triggerRecordModifiedTime);

            List<PC_SupportPlanActivityLog__c> logList = new List<PC_SupportPlanActivityLog__c>();
            if(String.isEmpty(transactionId)){
                logList = [Select PC_TransactionId__c FROM PC_SupportPlanActivityLog__c
                WHERE PC_ActionRecordModifiedTime__c != null AND PC_ActionRecordModifiedTime__c =: triggerRecordModifiedTime
                AND PC_ActionRecordId__c =: triggerRecordId];
            }

            if(!logList.isEmpty() || String.isNotEmpty(transactionId)){
                if(!logList.isEmpty()){
                    transactionId = logList[0].PC_TransactionId__c;
                }
                if(String.isNotEmpty(transactionId)){
                    logCount = [Select Count() FROM PC_SupportPlanActivityLog__c WHERE PC_RuntimeUser__c =:userInfo.getUserId()
                    AND PC_TransactionId__c =: transactionId AND PC_SupportPlanActivity__c =: supportPlanActivityId];
                }
            }else{
                transactionInfo.isInitiatedBySupportPlan = true;
                transactionId = PC_Utility.generateTransactionId(PC_Constants.SUPPORTPLAN_TRANSACTION_ID_KEY);
            }
        }else{
            transactionId = PC_Utility.generateTransactionId(PC_Constants.SUPPORTPLAN_TRANSACTION_ID_KEY);
        }
        transactionInfo.logCount = logCount;
        transactionInfo.transactionId = transactionId;
        return transactionInfo;
    }
    /**
     * Used to store details related to Support Plan Transaction
     */
    public inherited sharing class TransactionInfo{
        /**
         * Unique Id generated for each transaction of support plan execution
         */
        public String  transactionId {get; set;}
        /**
         * Total count of Support Plan Activity Logs that come under same transaction in last minute
         */
        public Integer  logCount {get; set;}
        /**
         * Indicates if the current support plan execution is initiated by some action done as part of another Support Plan
         */
        public Boolean  isInitiatedBySupportPlan {get; set;}

        public TransactionInfo() {
            transactionId = PC_Constants.EMPTY_STRING;
            isInitiatedBySupportPlan = false;
            logCount = 0;
        }
    }

    public inherited sharing class InitialActivityWrapper{
        public STRING 	currentgroup {get; set;}
        public STRING 	currentgroupstatus {get; set;}
        public STRING 	currentactivity {get; set;}
        public STRING 	currentactivitystatus {get; set;}
        public STRING 	currentgroupnextactivity {get; set;}
        public STRING 	currentgroupallactivities {get; set;}
        public STRING 	completedactivity {get; set;}
        public DATE 	completedactivitydate {get; set;}


        public InitialActivityWrapper() {}

        public InitialActivityWrapper(PC_SupportPlanActivity__c initialAct, Set<String> allGroupActivity){
            Set<String> currentactivityIdSet = new Set<String>();

            if(initialAct.PC_InternalActivityType__c == PC_Constants.SUPPORTPLAN_ACTIVITY_TYPE_SEQUENCE) {
                currentactivityIdSet.add(initialAct.PC_InitialSequenceActivity__c);
                currentgroup                = initialAct.PC_InternalActivityNumber__c;
                currentgroupstatus          = PC_Constants.SUPPORTPLANRT_ACTIVITY_STATUS_PENDINGCONDITION;
                currentactivity             = System.JSON.serialize(currentactivityIdSet);
                currentactivitystatus       = PC_Constants.SUPPORTPLANRT_ACTIVITY_STATUS_INPROGRESS;
                currentgroupnextactivity    = initialAct.PC_NextActivityNumber__c;
                completedactivity           = null;
                completedactivitydate       = null;
                currentgroupallactivities   = System.JSON.serialize(allGroupActivity);
                if(initialAct.PC_GroupActivityExecution__c == PC_Constants.PC_ALL_AT_ONCE){
                    currentactivityIdSet.clear();
                    currentactivity             = System.JSON.serialize(currentactivityIdSet);
                    currentgroupallactivities   = System.JSON.serialize(allGroupActivity);
                }
            }else if (initialAct.PC_InternalActivityType__c == PC_Constants.SUPPORTPLAN_ACTIVITY_TYPE_SEQUENCE_TASK){
                currentactivityIdSet.add(initialAct.PC_InternalActivityNumber__c);
                currentgroup                = initialAct.PC_ActivitySequence__c;
                currentgroupstatus          = PC_Constants.SUPPORTPLANRT_ACTIVITY_STATUS_INPROGRESS;
                currentactivity             = System.JSON.serialize(currentactivityIdSet);
                currentactivitystatus       = PC_Constants.SUPPORTPLANRT_ACTIVITY_STATUS_INPROGRESS;
                currentgroupnextactivity    = PC_Constants.SUPPORTPLAN_OVERRIDE_PREVIOUS;
                completedactivity           = null;
                completedactivitydate       = null;
                currentgroupallactivities   = System.JSON.serialize(allGroupActivity);
            } else if (initialAct.PC_InternalActivityType__c == PC_Constants.SUPPORTPLAN_ACTIVITY_TYPE_MANUAL_TASK){
                currentactivityIdSet.add(initialAct.PC_InternalActivityNumber__c);
                currentgroup                = null;
                currentgroupstatus          = null;
                currentactivity             = System.JSON.serialize(currentactivityIdSet);
                currentactivitystatus       = PC_Constants.SUPPORTPLANRT_ACTIVITY_STATUS_INPROGRESS;
                currentgroupnextactivity    = null;
                completedactivity           = null;
                completedactivitydate       = null;
                currentgroupallactivities   = System.JSON.serialize(allGroupActivity);
            }
        }

    }

    public  inherited sharing class ConditionLogicList{
        public List<ConditionLogic> LstConditionsPerObject {get; set;}

        public ConditionLogicList(){
            ConditionLogic conditionLogic = new ConditionLogic();
            List<ConditionLogic> conditionalLogicList  = new List<ConditionLogic>();
            conditionalLogicList.add(conditionLogic);
            LstConditionsPerObject = conditionalLogicList;
        }
    }

    public inherited sharing class ConditionLogic{
        public List<Condition>  Conditions {get; set;}
        public String           ObjectType {get; set;}
        public String           RecordValue {get; set;}
        public String           Logic {get; set;}
        public ConditionLogic(){
            Condition condition = new Condition();
            LIST<Condition> conditionList = new LIST<Condition>();
            conditionList.add(condition);
            Conditions         =   conditionList;
            ObjectType         =   PC_Constants.EMPTY_STRING;
            Logic              =   PC_Constants.EMPTY_STRING;
            RecordValue        =   PC_Constants.EMPTY_STRING;
        }
    }

    public inherited sharing class Condition implements Comparable {
        public INTEGER ConditionNo {get; set;}
        public String  FieldName {get; set;}
        public String  FieldApiName {get; set;}
        public String  Operator {get; set;}
        public String  Type {get; set;}
        public String  Value {get; set;}
        public String  changeToValue {get; set;}

        public Condition() {
            ConditionNo     =   1;
            FieldName       =   PC_Constants.EMPTY_STRING;
            FieldApiName    =   PC_Constants.EMPTY_STRING;
            Operator        =   PC_Constants.EMPTY_STRING;
            Type            =   PC_Constants.EMPTY_STRING;
            Value           =   PC_Constants.EMPTY_STRING;
            changeToValue   =   PC_Constants.EMPTY_STRING;
        }
        // Compare conditions based on condition No.
        public Integer compareTo(Object compareTo) {
            Condition compareToCondition = (Condition)compareTo;
            // The return value of 0 indicates that both elements are equal.
            Integer returnValue = 0;
            if (ConditionNo < compareToCondition.ConditionNo) {
                // Set return value to a positive value.
                returnValue = 1;
            } else if (ConditionNo > compareToCondition.ConditionNo) {
                // Set return value to a negative value.
                returnValue = -1;
            }
            return returnValue;
        }
    }

    public inherited sharing class SupportPlanInfo{
        public String  recordId {get; set;}
        public DateTime  triggerRecordModifiedTime {get; set;}
        public String  transactionId {get; set;}
        public String  runtimeUserId {get; set;}
        public String  runtimeId {get; set;}
        public PC_Constants.SupportPlanInfoContext  context {get; set;}
        public List<String>  supportPlanIdList {get; set;}

        public SupportPlanInfo() {
            recordId = PC_Constants.EMPTY_STRING;
            supportPlanIdList = new List<String>();
            runtimeUserId = PC_Constants.EMPTY_STRING;
            runtimeId = PC_Constants.EMPTY_STRING;
            transactionId = PC_Constants.EMPTY_STRING;
        }
    }

    /********************************************************************************
    Class Name     : SupportPlan_Exception
    Description    : Holds the exception related to Support Plan
    *********************************************************************************/
    public inherited sharing class SupportPlan_Exception extends Exception{
    }
}