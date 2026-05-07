/**********************************************************************************************************
Created by vkashikar on 4/22/2020.
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------
Tushar Arora                27-Apr-2020            [PC-6038] Added logic for support plan fields updation as well as logging.
Tushar Arora                29-Apr-2020            [PC-6232] Modified logic for migration to take care of case sensitivity.
Tushar Arora                05-May-2020            [PC-6038] Added Logic if conditional logic field is null then we would be updating trigger event object with case by default.
 ***********************************************************************************************************/
/**
 * Batch Job to align Support Plan with the enhanced Support Plan model.
 */
global class PC_UpdateSupportPlans implements Database.Batchable<sObject>, Database.Stateful {

    private Document summaryLogDocument = new Document();
    private String summaryLogContent = '';
    private String batchLogContent = '';

    private static final String TXT_KEY = 'txt';
    private Set<String> standardFields ;
    private List<String> ignoreFields = new List<String>();
    private Integer i = 0;
    private Boolean anyChildBatchFailed = false;

    /** Contructor will make list of duplicate fields to be ignored.
     *
     *
     * @param duplicateFields List to capture fields which would be having duplicate developer Name
     */
    global PC_UpdateSupportPlans (List<String> duplicateFields) {
        if(duplicateFields != null) {
            for(String dupString : duplicateFields) {
                ignoreFields.add(dupString.toUpperCase());
            }
        }
    }
    private PC_UpdateSupportPlans() {

    }

    /**
    * Implements Database.Batchable method
    */
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query = '';
        try {

            createSummaryLogDocument();

            String intializeSummaryContent = 'Initiating alignment of Support Plans... \n';
            intializeSummaryContent += '\nJob Id -> ' + bc.getJobId();

            summaryLogContent += '\nIgnored Fields Array : ' +ignoreFields;
            Integer batchJobRecordsCount = [
                    SELECT count()
                    FROM PC_SupportPlan__c
                    WHERE PC_TriggerEventObject__c = null
            ];
            intializeSummaryContent += '\nNumber of Records to be aligned = ' + batchJobRecordsCount;

            updateAndSaveSummaryLogDocument(intializeSummaryContent);

            query = getQuery();
            System.debug('query::::'+query);
            Database.QueryLocator queryLocator = Database.getQueryLocator(query);

            return queryLocator;

        }
        catch(Exception ex) {
            summaryLogContent += ex.getMessage();
            summaryLogContent += '\n' + query;
            PC_Utility.publishErrorLog(ex, ex.getMessage() + '\n' + summaryLogContent);
        }
        return Database.getQueryLocator('SELECT ID FROM PC_SupportPlan__c LIMIT 0');

    }
    /**
     * Implements Database.Batchable method
     */
    global void execute(Database.BatchableContext bc, List<PC_SupportPlan__c> scope){
        List<Id> processedIds = new List<Id>();
        try {

            batchLogContent = '';
            batchLogContent += '\nStart: Child Batch Job Id ' + bc.getChildJobId();
            Boolean isSupportPlanNeedAttention = false;
            List<Id> processedIdsNeedAttention = new List<Id>();
            //Batch Name
            for (PC_SupportPlan__c supportPlan : scope) {
                isSupportPlanNeedAttention =  updateSupportPlan(supportPlan);
                if(isSupportPlanNeedAttention)
                    processedIdsNeedAttention.add(supportPlan.Id);
                processedIds.add(supportPlan.Id);
            }
            if(!processedIds.isEmpty() && scope != null) {
                update scope;
            }
            Document batchLog = createBatchDocument();

            batchLogContent += '\nAlignment Successfully completed for the following support plan activities:';
            batchLogContent += '\n' + String.join(processedIds, ', ');

            if(processedIdsNeedAttention.size() > 0){
                batchLogContent += '\nFollowing support plan activities need your attention as they contain custom fields:';
                batchLogContent += '\n' + String.join(processedIdsNeedAttention, ', ');

                summaryLogContent += '\n ' + processedIdsNeedAttention.size() + ' record(s) in child batch file ' + batchLog.Name + ' needs attention as they contain custom fields. ';
            }

            batchLogContent += '\nEnd: Child Batch Job Id ' + bc.getChildJobId();
            updateAndSaveBatchLogDocument(batchLog, batchLogContent);
            summaryLogContent += '\nProcessed ' + processedIds.size() + ' record(s) in child batch file ' + batchLog.Name;
        }
        catch(Exception ex) {
            summaryLogContent += '\nException occurred while processing child batch job with Id ' + bc.getChildJobId();
            summaryLogContent += ex.getMessage();
            if(anyChildBatchFailed == false) {
                anyChildBatchFailed = true;
            }
            PC_Utility.publishErrorLog(ex, ex.getMessage());
        }

    }
    /**
     * Implements Database.Batchable method
     */
    global void finish(Database.BatchableContext bc){
        if(anyChildBatchFailed == true) {
            summaryLogContent += 'One or more of the child jobs have failed.';
            summaryLogContent += ' Please look at logged exceptions either in this file or in the error log to take corrective action';
            summaryLogContent += ' Once done, re-run the batch job';
        }
        updateAndSaveSummaryLogDocument(summaryLogContent);
    }
    private Boolean updateSupportPlan(PC_SupportPlan__c supportPlan) {
        Boolean isConditionsPartiallyUpdated = false;
        //batchlog : Support Plan Id (ID) is being processed
        batchLogContent += '\n---- Support Plan ---- ' + supportPlan.id  + ' ---- processing starts ---- ';
        supportPlan.PC_TriggerEventConditionalBehavior__c = PC_Constants.PC_COND_BEHAVIOUR_NO_CONDITION;
        batchLogContent += '\n\t' + 'PC_TriggerEventConditionalBehavior__c ' + ' field is updated with ' + PC_Constants.PC_COND_BEHAVIOUR_NO_CONDITION ;
        supportPlan.PC_TriggerEventType__c = PC_Constants.PC_TRIGGER_EVENT_INSERTUPDATE;
        batchLogContent += '\n\t' + 'PC_TriggerEventType__c ' + ' field is updated with ' + PC_Constants.PC_TRIGGER_EVENT_INSERTUPDATE ;
        if(supportPlan.PC_Conditional_Logic__c != null) {
            PC_ConditionBuilder supportPlanCond = new PC_ConditionBuilder();
            supportPlanCond = (PC_ConditionBuilder) System.JSON.deserialize(supportPlan.PC_Conditional_Logic__c, PC_ConditionBuilder.class);
            supportPlan.PC_TriggerEventObject__c = supportPlanCond.LstConditionsPerObject[0].ObjectType;
            batchLogContent += '\n\t' + 'PC_TriggerEventObject__c ' + ' field is updated with ' + supportPlanCond.LstConditionsPerObject[0].ObjectType ;
            Map<String,String> localAPINameToQualifiedAPIName= new Map<String,String>();
            localAPINameToQualifiedAPIName = getPCFieldsLocalAPINameToQualifiedAPINameMap(supportPlanCond.LstConditionsPerObject[0].ObjectType);
            System.debug('localAPINameToQualifiedAPIName::::'+localAPINameToQualifiedAPIName);
            System.debug('localAPINameToQualifiedAPINameKeyset::::'+localAPINameToQualifiedAPIName.keyset());
            System.debug('standardFields::::'+standardFields);

            List<PC_ConditionBuilder.Conditions> supportPlanConditions= new List<PC_ConditionBuilder.Conditions>();
            if(!localAPINameToQualifiedAPIName.keyset().isEmpty()) {
                for(PC_ConditionBuilder.Conditions condition : supportPlanCond.LstConditionsPerObject[0].Conditions) {
                    String conditionFieldAPINameWithUpperCase =  condition.FieldApiName.toUpperCase();
                    if(!standardFields.isEmpty() && standardFields.contains(condition.FieldApiName.toUpperCase())) {
                        batchLogContent += '\n\tSkipped Field ' + condition.FieldApiName + ' as it is a standard field in Condition No. ' + condition.ConditionNo + ' in PC_Conditional_Logic__c field. ';
                    } else if(!ignoreFields.isEmpty() && ignoreFields.contains(condition.FieldApiName.toUpperCase())){
                        batchLogContent += '\n\tSkipped Field ' + condition.FieldApiName + ' as it was mentioned to be ignored in Condition No. ' + condition.ConditionNo + ' in PC_Conditional_Logic__c field. ';
                    } else if(conditionFieldAPINameWithUpperCase.startsWith(PC_Constants.OrgNamespace.toUpperCase())) {
                        batchLogContent += '\n\tSkipped field  ' + condition.FieldApiName + ' is already containing patient connect namespace in Condition No. '  +condition.ConditionNo + ' in PC_Conditional_Logic__c field. ';
                    } else if(!conditionFieldAPINameWithUpperCase.startsWith(PC_Constants.OrgNamespace.toUpperCase()) && !localAPINameToQualifiedAPIName.containsKey(condition.FieldApiName.toUpperCase())){
                        batchLogContent += '\n\tSkipped Field ' + condition.FieldApiName + ' as it is not a Patient Connect field in Condition No. ' + condition.ConditionNo + ' in PC_Conditional_Logic__c field. ';
                        isConditionsPartiallyUpdated = true;
                    } else if(!conditionFieldAPINameWithUpperCase.startsWith(PC_Constants.OrgNamespace.toUpperCase()) && localAPINameToQualifiedAPIName.containsKey(condition.FieldApiName.toUpperCase()) && localAPINameToQualifiedAPIName.get(condition.FieldApiName.toUpperCase()) != null ) {
                        batchLogContent += '\n\t' + condition.FieldApiName + ' field is updated with ' + localAPINameToQualifiedAPIName.get(condition.FieldApiName.toUpperCase()) + ' in Condition No. ' + condition.ConditionNo + ' in PC_Conditional_Logic__c field. ';
                        condition.FieldApiName = localAPINameToQualifiedAPIName.get(condition.FieldApiName.toUpperCase()) == null ?  condition.FieldApiName : localAPINameToQualifiedAPIName.get(condition.FieldApiName.toUpperCase());
                    } else {
                        batchLogContent += '\n\tSkipped field  ' + condition.FieldApiName + ' is not updated and there is some other issue in Condition No. ' + condition.ConditionNo +' in PC_Conditional_Logic__c field. ';
                    }
                    supportPlanConditions.add(condition);
                }
            } else {
                batchLogContent += '\n\tNo updates done in PC_Conditional_Logic__c field ';
            }
            supportPlanCond.LstConditionsPerObject[0].Conditions.clear();
            supportPlanCond.LstConditionsPerObject[0].Conditions.addAll(supportPlanConditions);
            String supportPlanConditionLogic = System.JSON.serialize(supportPlanCond);
            System.debug('supportPlanConditionLogic::::'+supportPlanConditionLogic);
            supportPlan.PC_Conditional_Logic__c = supportPlanConditionLogic;
            if(isConditionsPartiallyUpdated) {
                batchLogContent += '\n\tSupport Plan is partially updated.' + ' Since custom fields are part of the conditions, ' +
                        'request you to update these fields with namespace if necessary';
            } else {
                batchLogContent += '\n\tSupport Plan is updated successfully.';
            }
        } else {
            supportPlan.PC_TriggerEventObject__c = PC_Constants.PC_CASE;
            batchLogContent += '\n\t' + 'PC_TriggerEventObject__c ' + ' field is updated with ' + PC_Constants.PC_CASE;
            batchLogContent += '\n\tSupport Plan is updated successfully.';
        }
        batchLogContent += '\n---- Support Plan Id ---- ' + supportPlan.id  + ' ---- processing ends ---- ';
        return isConditionsPartiallyUpdated;
    }

    private static String getQuery() {
        String oSupportPlan = PC_Constants.getQualifiedAPIName('PC_SupportPlan__c');
        String fTriggerEventObject = PC_Constants.getQualifiedAPIName('PC_TriggerEventObject__c');
        String fTriggerEventCondition = PC_Constants.getQualifiedAPIName('PC_TriggerEventCondition__c');
        String fTriggerEventConditionalBehavior = PC_Constants.getQualifiedAPIName('PC_TriggerEventConditionalBehavior__c');
        String fTriggerEventConditionOption = PC_Constants.getQualifiedAPIName('PC_TriggerEventConditionOption__c');
        String fTriggerEventType = PC_Constants.getQualifiedAPIName('PC_TriggerEventType__c');
        String fConditionalLogic = PC_Constants.getQualifiedAPIName('PC_Conditional_Logic__c');

        String query = 'Select Id, ' +
                fTriggerEventObject + ', ' +
                fTriggerEventCondition + ', ' +
                fTriggerEventConditionalBehavior + ', ' +
                fTriggerEventConditionOption + ', ' +
                fTriggerEventType + ', ' +
                fConditionalLogic + ' ' +
                'FROM ' + oSupportPlan + ' ' +
                'WHERE ' + fTriggerEventObject + ' = ' + 'NULL' ;
        system.debug(query);

        return query;
    }

    private void createSummaryLogDocument() {
        summaryLogDocument.Name = 'PC_SupportPlan - SummaryLog - ' + String.valueOf(DateTime.now()) + PC_Constants.LOG_FORMAT;
        summaryLogDocument.Type = TXT_KEY;
        summaryLogDocument.folderid = UserInfo.getUserId();
        Database.SaveResult result = Database.insert(summaryLogDocument);
        summaryLogDocument.Id = result.id;
    }
    private void updateAndSaveSummaryLogDocument(String content) {
        String existingBodyContent = summaryLogDocument.Body == null ? '' : summaryLogDocument.Body.toString();
        summaryLogDocument.Body = Blob.valueOf(existingBodyContent + '\n' + content);
        if(summaryLogDocument != null){
            update summaryLogDocument;
        }
    }
    private Document createBatchDocument() {
        Document batchLog = new Document();
        batchLog.Name = 'PC_SupportPlan - BatchLog '+  ++i  + ' - ' + String.valueOf(DateTime.now()) + PC_Constants.LOG_FORMAT;
        batchLog.Type = TXT_KEY;
        batchLog.folderid = UserInfo.getUserId();
        Database.SaveResult result = Database.insert(batchLog);
        batchLog.Id = result.Id;
        return batchLog;
    }
    private void updateAndSaveBatchLogDocument(Document batchLog, String content) {
        String existingBodyContent = batchLog.Body == null ? '' : batchLog.Body.toString();
        batchLog.Body = Blob.valueOf(existingBodyContent + '\n' + content);
        if(batchLog != null){
            update batchLog;
        }
    }

   private Map<String,String> getPCFieldsLocalAPINameToQualifiedAPINameMap(String sObjectName) {
        Map<String,String> localAPINametoQualifiedAPIName = new Map<String,String>();
        standardFields = new Set<String>();
        SObjectType objToken = Schema.getGlobalDescribe().get(sObjectName);
        DescribeSObjectResult objDef = objToken.getDescribe();
        Map<String, SObjectField> fields = objDef.fields.getMap();
        Set<String> fieldSet = fields.keySet();
        for(String s:fieldSet)
        {
            SObjectField fieldToken = fields.get(s);
            DescribeFieldResult selectedField = fieldToken.getDescribe();
            if(!selectedField.isCustom()) {
                standardFields.add(String.valueof(selectedField.getName().toUpperCase()));
            }
            System.debug('standardFields::::'+standardFields);
            System.debug('PC_Constants.OrgNamespace::::'+PC_Constants.OrgNamespace);
            if(String.valueof(selectedField.getName()).startsWith(PC_Constants.OrgNamespace))
                localAPINametoQualifiedAPIName.put(String.valueof(selectedField.getlocalName().toUpperCase()),String.valueof(selectedField.getName()));
        }
        return localAPINametoQualifiedAPIName;
   }
}