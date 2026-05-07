/******************************************************************************************************
Created by tusarora on 4/23/2020.
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------
Tushar Arora                27-Apr-2020            [PC-6038] Added logic for support plan activities fields updation as well as logging.
Tushar Arora                29-Apr-2020            [PC-6232] Modified logic for migration to take care of case sensitivity.
Tushar Arora                14-May-2020            [PC-6290] Modified logic for Conditional Logic field in Support Plan Activities migration would only work for Case and Task
Haritha Reddy         21-Jan-2021              [PC-7102] Force Reviewer scan issue fix. Updated Sharing declaration.
 *****************************************************************************************************/

/**
 * Batch Job to align Support Plan Activities with the enhanced Support Plan model.
 */
global class PC_UpdateSupportPlanActivities implements Database.Batchable<sObject>, Database.Stateful {

    private Document summaryLogDocument = new Document();
    private String summaryLogContent = '';
    private String batchLogContent = '';

    private static final String TXT_KEY = 'txt';
    private Set<String> standardFields ;
    private List<String> taskIgnoreFields = new List<String>();
    private List<String> caseIgnoreFields = new List<String>();
    private Integer i = 0;
    private Boolean anyChildBatchFailed = false;

    /**
     * Contructor will make list of TASK duplicate fields and List of CASE duplicate fields to be ignored.
     *
     * @param taskDuplicateFields List to capture task fields which would be having duplicate developer Name
     * @param caseDuplicateFields List to capture case fields which would be having duplicate developer Name
     */
    global PC_UpdateSupportPlanActivities (List<String> taskDuplicateFields, List<String> caseDuplicateFields) {
        if(taskDuplicateFields != null) {
            for(String taskString : taskDuplicateFields) {
                taskIgnoreFields.add(taskString.toUpperCase());
            }
        }
        if(caseDuplicateFields != null) {
            for(String caseString : caseDuplicateFields) {
                caseIgnoreFields.add(caseString.toUpperCase());
            }
        }
    }
    private PC_UpdateSupportPlanActivities() {

    }
    /**
    * Implements Database.Batchable method
    */
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query = '';
        try {
            createSummaryLogDocument();

            String intializeSummaryContent = 'Initiating alignment of Support Plan Activities... \n';
            intializeSummaryContent += '\nJob Id -> ' + bc.getJobId();

            summaryLogContent += '\nTask Ignored Fields Array : ' +taskIgnoreFields;
            summaryLogContent += '\nCase Ignored Fields Array : ' +caseIgnoreFields;

            Integer batchJobRecordsCount = [
                SELECT count()
                FROM PC_SupportPlanActivity__c
                WHERE PC_SupportPlan__c != null
            ];
            intializeSummaryContent += '\nNumber of Support Plan Activities considered in the batch job = ' + batchJobRecordsCount;

            updateAndSaveSummaryLogDocument(intializeSummaryContent);

            query = getQuery();
            Database.QueryLocator queryLocator = Database.getQueryLocator(query);

            return queryLocator;
        }
        catch(Exception ex) {
            summaryLogContent += ex.getMessage();
            summaryLogContent += '\n' + query;
            PC_Utility.publishErrorLog(ex, ex.getMessage() + '\n' + summaryLogContent);
        }
        return Database.getQueryLocator('SELECT ID FROM PC_SupportPlanActivity__c LIMIT 0');
    }
    /**
    * Implements Database.Batchable method
    */
    global void execute(Database.BatchableContext bc, List<PC_SupportPlanActivity__c> scope){
        List<Id> processedIds = new List<Id>();
        List<Id> unprocessedIds = new List<Id>();
        try {
            Document batchLog = createBatchDocument();
            batchLogContent = '';
            batchLogContent += '\nStart: Child Batch Job Id ' + bc.getChildJobId();
            PC_SupportPlanMigration supportPlanMigration = new PC_SupportPlanMigration();
            Map<id,PC_SupportPlanActivity__c> supportPlanActivitiesByIds = new Map<id,PC_SupportPlanActivity__c>();
            List<Id> processedIdsNeedAttention = new List<Id>();

            for (PC_SupportPlanActivity__c supportPlanActivity : scope) {
                supportPlanMigration = updateSupportPlanActivity(supportPlanActivity);
                if(supportPlanMigration.isSupportPlanPartiallyUpdated){
                    processedIdsNeedAttention.add(supportPlanActivity.Id);
                }
                if(supportPlanMigration.isSupportPlanUpdateAble){
                    processedIds.add(supportPlanActivity.Id);
                    supportPlanActivitiesByIds.put(supportPlanActivity.Id,supportPlanActivity);
                }
                else {
                    unprocessedIds.add(supportPlanActivity.Id);
                }
            }
            if(supportPlanActivitiesByIds != null && !supportPlanActivitiesByIds.keyset().isEmpty() ) {
                update supportPlanActivitiesByIds.values();
                batchLogContent += '\nAlignment Successfully completed for the following support plan activities.';
                batchLogContent += '\n' + String.join(processedIds, ', ');
            }

            summaryLogContent += '\nAligned ' + processedIds.size() + ' / ' + scope.size() + ' support plan activity(s) in child batch file ' + batchLog.Name;
            if(processedIdsNeedAttention.size() > 0) {
                batchLogContent += '\nFollowing support plan activities need your attention as they contain custom fields.';
                batchLogContent += '\n' + String.join(processedIdsNeedAttention, ', ');
                summaryLogContent += '\n' + processedIdsNeedAttention.size() + ' record(s) in child batch file ' + batchLog.Name + ' needs attention as they contain custom fields.';
            }

            if(processedIds.size() == 0 && processedIdsNeedAttention.size() == 0) {
                // nothing to align
                summaryLogContent += '\nAll records in batch file ' + batchLog.Name + ' are already aligned.';
            }
            /*if(unprocessedIds.size() >= 0) {
                batchLogContent += '\nFollowing support plan activities do not need any alignment.';
                batchLogContent += '\n' + String.join(unprocessedIds, ', ');
                summaryLogContent += '\nSkipped ' + unprocessedIds.size() + ' record(s) in child batch file ' + batchLog.Name + ' as there is no need of any alignment.';
            }*/
            batchLogContent += '\nEnd: Child Batch Job Id ' + bc.getChildJobId();
            updateAndSaveBatchLogDocument(batchLog, batchLogContent);

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
    private PC_SupportPlanMigration updateSupportPlanActivity(PC_SupportPlanActivity__c supportPlanActivity) {
        Boolean isSupportPlanActivityUpdateable = false;
        Boolean isSupportPlanActivityPartiallyUpdated = false;
        System.debug('supportPlanActivityId::::'+supportPlanActivity.id);
        PC_SupportPlanMigration supportPlanMigration = new PC_SupportPlanMigration();

        batchLogContent += '\n---- Support Plan Activity ---- ' + supportPlanActivity.id  + ' ---- processing start ---- ';

        if(supportPlanActivity.PC_UserTask_Fields__c != null){
            //isSupportPlanActivityUpdateable = true;
            Boolean isUserTaskFieldConditionsPartiallyUpdated = false;
            PC_ActivityProperties_Controller.RequiredFieldSetWrapper requiredFieldSetWrapper = new PC_ActivityProperties_Controller.RequiredFieldSetWrapper();
            requiredFieldSetWrapper = (PC_ActivityProperties_Controller.RequiredFieldSetWrapper) System.JSON.deserialize(supportPlanActivity.PC_UserTask_Fields__c, PC_ActivityProperties_Controller.RequiredFieldSetWrapper.class);
            Map<String,String> localAPINameToQualifiedAPINameForTask= new Map<String,String>();
            localAPINameToQualifiedAPINameForTask = getPCFieldsLocalAPINameToQualifiedAPINameMap(PC_Constants.PC_TASK);
            System.debug('localAPINameToQualifiedAPINameForTask::::'+localAPINameToQualifiedAPINameForTask);
            System.debug('standardFields::::'+standardFields);
            List<PC_ActivityProperties_Controller.RequiredFieldWrapper> taskFieldSetDetails= new List<PC_ActivityProperties_Controller.RequiredFieldWrapper>();
            if(!localAPINameToQualifiedAPINameForTask.keyset().isEmpty()) {
                for (PC_ActivityProperties_Controller.RequiredFieldWrapper taskfieldDetail : requiredFieldSetWrapper.requiredFieldSet) {
                    String taskFieldDetailApiNameWithUpperCase =  taskfieldDetail.apiName.toUpperCase();
                    if(!standardFields.isEmpty() && standardFields.contains(taskfieldDetail.apiName.toUpperCase())) {
                        batchLogContent += '\n\tSkipped field ' + taskfieldDetail.apiName + ' as it is a standard field in PC_UserTask_Fields__c field. ';
                    } else if(!taskIgnoreFields.isEmpty() && taskIgnoreFields.contains(taskfieldDetail.apiName.toUpperCase())) {
                        batchLogContent += '\n\tSkipped field ' + taskfieldDetail.apiName + ' as it was mentioned to be ignored in PC_UserTask_Fields__c field. ';
                    } else if(taskFieldDetailApiNameWithUpperCase.startsWith(PC_Constants.OrgNamespace.toUpperCase())){
                        batchLogContent += '\n\tSkipped field ' + taskfieldDetail.apiName + ' as it is already containing patient connect namespace in PC_UserTask_Fields__c field. ';
                    } else if(!taskFieldDetailApiNameWithUpperCase.startsWith(PC_Constants.OrgNamespace.toUpperCase()) && !localAPINameToQualifiedAPINameForTask.containsKey(taskfieldDetail.apiName.toUpperCase())){
                        batchLogContent += '\n\tSkipped field ' + taskfieldDetail.apiName + ' as it is not a Patient Connect field in PC_UserTask_Fields__c field for Support Plan Activity. ';
                        isUserTaskFieldConditionsPartiallyUpdated = true;
                    } else if(!taskFieldDetailApiNameWithUpperCase.startsWith(PC_Constants.OrgNamespace.toUpperCase()) && localAPINameToQualifiedAPINameForTask.containsKey(taskfieldDetail.apiName.toUpperCase())
                            && localAPINameToQualifiedAPINameForTask.get(taskfieldDetail.apiName.toUpperCase()) != null){
                        batchLogContent += '\n\t' + taskfieldDetail.apiName + ' field is updated as ' + '' + localAPINameToQualifiedAPINameForTask.get(taskfieldDetail.apiName.toUpperCase()) + ' in PC_UserTask_Fields__c field. ';
                        taskfieldDetail.apiName = localAPINameToQualifiedAPINameForTask.get(taskfieldDetail.apiName.toUpperCase()) ;
                        isSupportPlanActivityUpdateable = true;
                    } else {
                        batchLogContent += '\n\tSkipped field  ' + taskfieldDetail.apiName + ' is not updated and there is some other issue in PC_UserTask_Fields__c field. ';
                    }
                    taskFieldSetDetails.add(taskfieldDetail);
                }
            } else {
                batchLogContent += '\n\tNo updates done in PC_UserTask_Fields__c field ';
            }
            System.debug('taskFieldSetDetails::::'+taskFieldSetDetails);
            requiredFieldSetWrapper.requiredFieldSet.clear();
            requiredFieldSetWrapper.requiredFieldSet.addAll(taskFieldSetDetails);
            String userTaskLogic = System.JSON.serialize(requiredFieldSetWrapper);
            System.debug('userTaskLogic::::'+userTaskLogic);
            supportPlanActivity.PC_UserTask_Fields__c = userTaskLogic;
            if(isUserTaskFieldConditionsPartiallyUpdated) {
                batchLogContent += '\n\tPC_UserTask_Fields__c field is partially updated. Since custom fields are part of the conditions, request you to update these fields with namespace if necessary.';
                isSupportPlanActivityPartiallyUpdated = true;
            } else {
                //batchLogContent += '\n\tPC_UserTask_Fields__c field is updated successfully.';
            }
        }
        if(supportPlanActivity.PC_Conditional_Logic__c != null) {
            PC_ConditionBuilder supportPlanActivityCond = new PC_ConditionBuilder();
            supportPlanActivityCond = (PC_ConditionBuilder) System.JSON.deserialize(supportPlanActivity.PC_Conditional_Logic__c, PC_ConditionBuilder.class);
            if (String.valueof(supportPlanActivityCond.LstConditionsPerObject[0].ObjectType).toUpperCase() == PC_Constants.PC_CASE.toUpperCase() || String.valueOf(supportPlanActivityCond.LstConditionsPerObject[0].ObjectType).toUpperCase() == PC_Constants.PC_TASK.toUpperCase()) {
                //isSupportPlanActivityUpdateable = true;
                Boolean isConditionalLogicFieldConditionsPartiallyUpdated = false;
                Map<String, String> localAPINameToQualifiedAPIName = new Map<String, String>();

                localAPINameToQualifiedAPIName = getPCFieldsLocalAPINameToQualifiedAPINameMap(supportPlanActivityCond.LstConditionsPerObject[0].ObjectType);
                System.debug('localAPINameToQualifiedAPIName::::' + localAPINameToQualifiedAPIName);
                System.debug('standardFields::::' + standardFields);
                List<PC_ConditionBuilder.Conditions> supportPlanActivityConditions = new List<PC_ConditionBuilder.Conditions>();

                if (!localAPINameToQualifiedAPIName.keyset().isEmpty()) {
                    for (PC_ConditionBuilder.Conditions condition : supportPlanActivityCond.LstConditionsPerObject[0].Conditions) {
                        String conditionFieldAPINameWithUpperCase = condition.FieldApiName.toUpperCase();
                        if (!standardFields.isEmpty() && standardFields.contains(condition.FieldApiName.toUpperCase())) {
                            batchLogContent += '\n\tSkipped field ' + condition.FieldApiName + ' as it is a standard field in PC_Conditional_Logic__c field. ';
                        } else if (!caseIgnoreFields.isEmpty() && caseIgnoreFields.contains(condition.FieldApiName.toUpperCase())) {
                            batchLogContent += '\n\tSkipped Field ' + condition.FieldApiName + ' as it was mentioned to be ignored in PC_Conditional_Logic__c field.  ';
                        } else if (conditionFieldAPINameWithUpperCase.startsWith(PC_Constants.OrgNamespace.toUpperCase())) {
                            batchLogContent += '\n\tSkipped field  ' + condition.FieldApiName + ' is already containing patient connect namespace in PC_Conditional_Logic__c field.';
                        } else if (!conditionFieldAPINameWithUpperCase.startsWith(PC_Constants.OrgNamespace.toUpperCase()) && !localAPINameToQualifiedAPIName.containsKey(condition.FieldApiName.toUpperCase())) {
                            batchLogContent += '\n\tSkipped Field ' + condition.FieldApiName + ' as it is not a Patient Connect field in PC_Conditional_Logic__c field. ';
                            isConditionalLogicFieldConditionsPartiallyUpdated = true;
                        } else if (!conditionFieldAPINameWithUpperCase.startsWith(PC_Constants.OrgNamespace.toUpperCase()) && localAPINameToQualifiedAPIName.containsKey(condition.FieldApiName.toUpperCase())) {
                            batchLogContent += '\n\t' + condition.FieldApiName + ' field is updated as ' + '' + localAPINameToQualifiedAPIName.get(condition.FieldApiName.toUpperCase()) + ' in PC_Conditional_Logic__c field. ';
                            condition.FieldApiName = localAPINameToQualifiedAPIName.get(condition.FieldApiName.toUpperCase()) ;
                            isSupportPlanActivityUpdateable = true;
                        } else {
                            batchLogContent += '\n\tSkipped field  ' + condition.FieldApiName + ' is not updated and there is some other issue in PC_Conditional_Logic__c field. ';
                        }
                        supportPlanActivityConditions.add(condition);
                    }
                } else {
                    batchLogContent += '\n\tNo updates done in PC_Conditional_Logic__c field for Support Plan Activity ' + supportPlanActivity.id;
                }

                supportPlanActivityCond.LstConditionsPerObject[0].Conditions.clear();
                supportPlanActivityCond.LstConditionsPerObject[0].Conditions.addAll(supportPlanActivityConditions);
                String supportPlanActivityConditionLogic = System.JSON.serialize(supportPlanActivityCond);
                System.debug('supportPlanActivityConditionLogic::::' + supportPlanActivityConditionLogic);
                supportPlanActivity.PC_Conditional_Logic__c = supportPlanActivityConditionLogic;
                if (isConditionalLogicFieldConditionsPartiallyUpdated) {
                    batchLogContent += '\n\tPC_Conditional_Logic__c field is partially updated.' + ' Since custom fields are part of the conditions, ' +
                            'request you to update these fields with namespace if necessary';
                    isSupportPlanActivityPartiallyUpdated = true;
                } else {
                    //batchLogContent += '\n\tPC_Conditional_Logic__c field is updated successfully.';
                }
            }
        }
        if(supportPlanActivity.PC_ReferenceDate__c != null && supportPlanActivity.PC_ReferenceDate__c.toUpperCase() != (PC_Constants.PC_NONE).toUpperCase()) {
            //isSupportPlanActivityUpdateable = true;
            Map<String,String> localAPINameToQualifiedAPINameForCase= new Map<String,String>();
            localAPINameToQualifiedAPINameForCase = getPCFieldsLocalAPINameToQualifiedAPINameMap(PC_Constants.PC_CASE);
            System.debug('localAPINameToQualifiedAPINameForCase::::'+localAPINameToQualifiedAPINameForCase);
            System.debug('standardFields::::'+standardFields);
            String referenceDateFieldAPINameWithUpperCase = supportPlanActivity.PC_ReferenceDate__c.toUpperCase();
            if(!localAPINameToQualifiedAPINameForCase.keyset().isEmpty()) {
                if(!standardFields.isEmpty() && standardFields.contains(supportPlanActivity.PC_ReferenceDate__c.toUpperCase())) {
                    batchLogContent += '\n\tSkipped Field ' + supportPlanActivity.PC_ReferenceDate__c + ' as it is a standard field in supportPlanActivity.PC_ReferenceDate__c field. ';
                } else if(!caseIgnoreFields.isEmpty() && caseIgnoreFields.contains(supportPlanActivity.PC_ReferenceDate__c.toUpperCase())) {
                    batchLogContent += '\n\tSkipped Field ' + supportPlanActivity.PC_ReferenceDate__c + ' as it was mentioned to be ignored in PC_ReferenceDate__c field. ';
                } else if(referenceDateFieldAPINameWithUpperCase.startsWith(PC_Constants.OrgNamespace.toUpperCase())) {
                    batchLogContent += '\n\tSkipped Field ' + supportPlanActivity.PC_ReferenceDate__c + ' as it is already containing patient connect namespace in PC_ReferenceDate__c field. ';
                } else if(!referenceDateFieldAPINameWithUpperCase.startsWith(PC_Constants.OrgNamespace.toUpperCase()) && !localAPINameToQualifiedAPINameForCase.containsKey(supportPlanActivity.PC_ReferenceDate__c.toUpperCase())) {
                    batchLogContent += '\n\tSkipped Field ' + supportPlanActivity.PC_ReferenceDate__c + ' as it is not a Patient Connect field in PC_ReferenceDate__c field. ';
                } else if(!referenceDateFieldAPINameWithUpperCase.startsWith(PC_Constants.OrgNamespace.toUpperCase()) && localAPINameToQualifiedAPINameForCase.containsKey(supportPlanActivity.PC_ReferenceDate__c.toUpperCase())) {
                    batchLogContent += '\n\t' + supportPlanActivity.PC_ReferenceDate__c + ' field is updated as ' + '' + localAPINameToQualifiedAPINameForCase.get(supportPlanActivity.PC_ReferenceDate__c.toUpperCase()) + ' in PC_ReferenceDate__c field.';
                    supportPlanActivity.PC_ReferenceDate__c = localAPINameToQualifiedAPINameForCase.get(supportPlanActivity.PC_ReferenceDate__c.toUpperCase()) ;
                    isSupportPlanActivityUpdateable = true;
                } else {
                    batchLogContent += '\n\tSkipped field  ' + supportPlanActivity.PC_ReferenceDate__c + ' is not updated and there is some other issue in PC_ReferenceDate__c field. ';
                }
            } else {
                batchLogContent += '\n\tNo updates done in PC_ReferenceDate__c field ';
            }
            system.debug('supportPlanActivity.PC_ReferenceDate__c:::::'+supportPlanActivity.PC_ReferenceDate__c);
        }

        batchLogContent += '\n---- Support Plan Activity ---- ' + supportPlanActivity.id  + ' ---- processing end ---- ';

        supportPlanMigration.isSupportPlanUpdateAble = isSupportPlanActivityUpdateable;
        supportPlanMigration.isSupportPlanPartiallyUpdated = isSupportPlanActivityPartiallyUpdated;

        return supportPlanMigration;
    }

    private static String getQuery() {
        String oSupportPlanActivity = PC_Constants.getQualifiedAPIName('PC_SupportPlanActivity__c');
        String fUserTaskFields = PC_Constants.getQualifiedAPIName('PC_UserTask_Fields__c');
        String fReferenceDate = PC_Constants.getQualifiedAPIName('PC_ReferenceDate__c');
        String fConditionalLogic = PC_Constants.getQualifiedAPIName('PC_Conditional_Logic__c');
        String fSupportPlan = PC_Constants.getQualifiedAPIName('PC_SupportPlan__c');

        String query = 'Select Id, ' +
                fUserTaskFields + ', ' +
                fReferenceDate + ', ' +
                fConditionalLogic + ' ' +
                'FROM ' + oSupportPlanActivity + ' ' +
                'WHERE ' + fSupportPlan + ' != ' + 'NULL' ;
        system.debug(query);

        return query;
    }

    private void createSummaryLogDocument() {
        summaryLogDocument.Name = 'PC_SupportPlanActivity - SummaryLog - ' + String.valueOf(DateTime.now()) + PC_Constants.LOG_FORMAT;
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
        batchLog.Name = 'PC_SupportPlanActivity - BatchLog '+   ++i  + ' - '  + String.valueOf(DateTime.now()) + PC_Constants.LOG_FORMAT;
        batchLog.Type = TXT_KEY;
        batchLog.folderid = UserInfo.getUserId();
        Database.SaveResult result = Database.insert(batchLog);
        batchLog.Id = result.Id;
        return batchLog;
    }
    private void updateAndSaveBatchLogDocument(Document batchLog, String content) {
        String existingBodyContent = batchLog.Body == null ? '' : batchLog.Body.toString();
        batchLog.Body = Blob.valueOf(existingBodyContent + '\n' + content);
        if(batchLog != null) {
            update batchLog;
        }
    }

    private  Map<String,String> getPCFieldsLocalAPINameToQualifiedAPINameMap(String sObjectName) {
        standardFields = new Set<String>();
        Map<String,String> localAPINametoQualifiedAPIName = new Map<String,String>();
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
            System.debug('PC_Constants.OrgNamespace::::'+PC_Constants.OrgNamespace);
            if(String.valueof(selectedField.getName().toUpperCase()).startsWith(PC_Constants.OrgNamespace.toUpperCase()))
                localAPINametoQualifiedAPIName.put(String.valueof(selectedField.getlocalName().toUpperCase()),String.valueof(selectedField.getName()));
        }
        //System.debug('localAPINametoQualifiedAPIName::::'+localAPINametoQualifiedAPIName);
        return localAPINametoQualifiedAPIName;
    }

    private inherited sharing class PC_SupportPlanMigration {
        private Boolean isSupportPlanUpdateAble;
        private Boolean isSupportPlanPartiallyUpdated ;
    }
}