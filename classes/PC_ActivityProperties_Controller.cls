/*********************************************************************************************************
Class Name    	: PC_ActivityProperties_Controller
Description     : Control the right hand side activity properties panel on support plan builder screen
Created By      : Deloitte
Created Date    : Feb 22, 2018
Modification Log:
-------------------------------------------------------------------------------------------------------------- 
Developer          Log#         Date                   Description
--------------------------------------------------------------------------------------------------------------            
Sahil Garg         		       Feb 22, 2018           Initial Version
Tejas Patel					   March 15, 2018		  Get the fields from Object via FieldLabels
Tejas Patel					   March 28, 2018		  Making use of Wrapper Class
Tejas Patel					   March 29, 2018		  fetch acticvity data using fetchActivity
Tejas Patel					   March 29, 2018		  FLS and try catch block added
Tejas Patel                    April 09, 2018         Added PC_Utility.logAndThrowException(ex);
Tejas Patel                    April 09, 2018         Added Back PC_Utility.createExceptionLog(ex) with return statement
Tejas Patel					   May 	 17, 2018		  Save First Activity of Sequnce, by default
Tejas Patel					   Feb 	 20, 2019		  PC-4473 modified getReferenceDatePickistVal to get field API name w/o namespace
Tejas Patel					   Feb 	 20, 2019		  PC-4473 modified getReferenceDatePickistVal to get field API name w/o namespace
Tejas Patel                    Mar 19, 2019           [PC-4659] New field PC_GroupActivityExecution__c added
Tejas Patel                    24-Apr-2019            [PC-4748] Modified Id to PC_InternalActivityNumber__c
Tejas Patel                    04-Nov-2019            [PC-5695] Adding internalactivitynumber to fetchActivity, to resolve migration issue
Kishore Kanteti                09-Dec-2019            [PC-5795] Reduced fetchActivity ,determineSave methods Parameters..
Haritha Reddy                  11-Dec-2019            [PC-5791] Added Error handling for methods where it was missing
Kishore Kanteti                22-Mar-2020            Modified fetch activity method to get the fields map from user record field in support plan activity.
Tushar Arora                   12-Jun-2020            [PC-6205] Modified Logic for showing label of fields used in conditional builder to support translation.
Kishore Kanteti                29-Jun-2020            [PC-6450] Modified Logic for saving update record activity type in automation task json.
Kishore Kanteti                3-July-2020            [PC-6513] Allowed date time fields to appear in due date calculation.Modified on line 451
Kanteti Kishore                13 Apr 2021           [PC-7009] Made changes to support PC_AutomationTaskHelper.FieldMap wrapper for User Task Activities
Satheesh Kumar                 12 Oct 2022           [PC-9265] Added condition to avoid split when triggerEventObjectName doesn't have namespace
****************************************************************************************************************/


public with sharing class PC_ActivityProperties_Controller {
    public static final String SEQUENCE = 'Sequence';
    public static final String GROUP_ACTIVITY = 'Group Activity';
    public static final String SEQUENCE_TASK = 'Sequence Task';
    public static final String AUTOMATION_TASK = 'Automation Task';
    public static final String UPDATE_RECORD = 'Update Record';

    @AuraEnabled
    public static String fieldSetName { get; set; }

    @AuraEnabled
    public static PC_SupportPlanBuilderController.SupportPlanActivityWrapper fetchActivity(Map<String, String> activityMap) {
        PC_SupportPlanBuilderController.SupportPlanActivityWrapper activity;
        ID checkActivityId;
        Boolean activateFunction = false;

        try {
            checkActivityId = (ID) activityMap.get('activityId');
        } catch (Exception ex) {
            activateFunction = true;
        }
        try {
            if (activateFunction) {
                PC_SupportPlanActivity__c newActivity = new PC_SupportPlanActivity__c();
                newActivity.Name = activityMap.get('activityName');
                newActivity.PC_InternalActivityType__c = activityMap.get('internalactivitytype');
                newActivity.PC_SupportPlan__c = Id.valueOf(activityMap.get('supportPlanID'));
                newActivity.PC_ReferenceOffset__c = PC_Constants.PC_ZERO;
                newActivity.PC_ReferenceDate__c = PC_Constants.PC_NONE;
                newActivity.PC_ConditionBehavior__c = PC_Constants.PC_COND_BEHAVIOUR_NO_CONDITION;
                newActivity.PC_ReferenceOffsetUnit__c = PC_Constants.PC_DAYS;
                newActivity.PC_ReferenceType__c = PC_Constants.PC_AFTER_COMPLETION_OF_PREVIOUS_ACTIVITY;
                newActivity.PC_UserTask_Fields__c = PC_Constants.EMPTY_STRING;
                newActivity.PC_SubType__c = PC_Constants.EMPTY_STRING;
                newActivity.PC_ActionClass__c = PC_Constants.EMPTY_STRING;
                newActivity.PC_GroupActivityExecution__c = PC_Constants.PC_IN_SEQUENCE;
                activity = new PC_SupportPlanBuilderController.SupportPlanActivityWrapper(newActivity);
            } else {
                //FLS Check
                //Activity
                List<String> actListFields = new List<String>{
                        'Name', PC_Constants.getQualifiedAPIName('PC_ActivitySequence__c'), PC_Constants.getQualifiedAPIName('PC_ActivityType__c'),
                        PC_Constants.getQualifiedAPIName('PC_InternalActivityType__c'), PC_Constants.getQualifiedAPIName('PC_AlternateActivity__c'), PC_Constants.getQualifiedAPIName('PC_ApexCondition__c'),
                        PC_Constants.getQualifiedAPIName('PC_Channel__c'), PC_Constants.getQualifiedAPIName('PC_Conditional_Logic__c'), PC_Constants.getQualifiedAPIName('PC_ConditionBehavior__c'), PC_Constants.getQualifiedAPIName('PC_Description__c'),
                        PC_Constants.getQualifiedAPIName('PC_InitialSequenceActivity__c'), PC_Constants.getQualifiedAPIName('PC_InternalActivityNumber__c'), PC_Constants.getQualifiedAPIName('PC_NextActivityNumber__c'),
                        PC_Constants.getQualifiedAPIName('PC_Priority__c'), PC_Constants.getQualifiedAPIName('PC_ReferenceDate__c'), PC_Constants.getQualifiedAPIName('PC_ReferenceOffset__c'),
                        PC_Constants.getQualifiedAPIName('PC_ReferenceOffsetUnit__c'), PC_Constants.getQualifiedAPIName('PC_ReferenceType__c'),
                        PC_Constants.getQualifiedAPIName('PC_Subject__c'), PC_Constants.getQualifiedAPIName('PC_SupportPlan__c'), PC_Constants.getQualifiedAPIName('PC_Assign_To_Role__c'), PC_Constants.getQualifiedAPIName('PC_UserTask_Fields__c')
                };

                PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_SupportPlanActivity__c'), PC_Database.Operation.Reading, actListFields);

                PC_SupportPlanActivity__c supportActivity = [
                        SELECT Id, Name, PC_ActivitySequence__c, PC_ActivityType__c, PC_InternalActivityType__c, PC_AlternateActivity__c, PC_ApexCondition__c,
                                PC_Channel__c, PC_Conditional_Logic__c, PC_ConditionBehavior__c, PC_ConditionOption__c, PC_Description__c, PC_InitialSequenceActivity__c, PC_InternalActivityNumber__c,
                                PC_NextActivityNumber__c, PC_Priority__c, PC_ReferenceDate__c, PC_ReferenceOffset__c, PC_ReferenceOffsetUnit__c,PC_SubType__c,PC_ActionClass__c,
                                PC_ReferenceType__c, PC_Subject__c, PC_SupportPlan__c, PC_Assign_To_Role__c, PC_UserTask_Fields__c, PC_AutomationTaskJSON__c, PC_ClonedFrom__c, PC_GroupActivityExecution__c
                        FROM PC_SupportPlanActivity__c
                        WHERE PC_InternalActivityNumber__c = :activityMap.get('internalactivitynumber')
                ];
                activity = new PC_SupportPlanBuilderController.SupportPlanActivityWrapper(supportActivity);
                if(activity.conditionallogic != null && activity.conditionallogic != ''){
                    activity.conditionallogic = processLabelChangeInJSONString(activity.conditionallogic);
                }
            }
            if (activity.objectFieldsMap != null && activity.objectFieldsMap != PC_Constants.EMPTY_STRING && activity.activitytype != UPDATE_RECORD) {
                PC_AutomationTaskHelper.AutomationTaskInfo automationRecordInfo = new PC_AutomationTaskHelper.AutomationTaskInfo();
                automationRecordInfo = (PC_AutomationTaskHelper.AutomationTaskInfo) System.JSON.deserialize(activity.objectFieldsMap,PC_AutomationTaskHelper.AutomationTaskInfo.class);
                activity.fieldMapping = JSON.serialize(automationRecordInfo.fieldMapping);
                EntityDefinition objectEntityDefinition = new EntityDefinition();
                objectEntityDefinition = [SELECT Id, QualifiedApiName, NamespacePrefix, DeveloperName, Label, MasterLabel, PluralLabel, IsProcessEnabled FROM EntityDefinition where QualifiedApiName =: automationRecordInfo.objectDetails.QualifiedApiName];
                PC_EntityDefinitionUtility.EntityDefinitionDetailWrapper entityWrapper = new PC_EntityDefinitionUtility.EntityDefinitionDetailWrapper(objectEntityDefinition);
                activity.objectDetails = JSON.serialize(entityWrapper);
                activity.outcomeTaskDetails = JSON.serialize(automationRecordInfo.outcomeTaskDetails);
            }
            if(activity.objectFieldsMap != null && activity.objectFieldsMap != PC_Constants.EMPTY_STRING && activity.activitytype == UPDATE_RECORD){
                PC_AutomationTaskHelper.AutomationTaskInfo updateAutomationRecordInfo = new PC_AutomationTaskHelper.AutomationTaskInfo();
                updateAutomationRecordInfo = (PC_AutomationTaskHelper.AutomationTaskInfo) System.JSON.deserialize(activity.objectFieldsMap,PC_AutomationTaskHelper.AutomationTaskInfo.class);
                activity.objectFieldsMap = JSON.serialize(updateAutomationRecordInfo);
            }
            if (fieldSetName != null && activity.internalactivitytype != SEQUENCE) {
                activity.usertaskfields = getRequiredFields(PC_Constants.PC_TASK, PC_Constants.getQualifiedAPIName(fieldSetName), activity);
            }
        } catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return activity;
    }


    @AuraEnabled
    public static PC_SupportPlanBuilderController.SupportPlanActivityWrapper fetchActivity(STRING fieldSetNm, Map<String, String> activityMap) {
        fieldSetName = fieldSetNm;
        return fetchActivity(activityMap);
    }

    private static PC_SupportPlanActivity__c checkPrevActivity(STRING prevActivityJSON) {
        PC_SupportPlanActivity__c prevActivity;

        if (STRING.isNotEmpty(prevActivityJSON)) {
            ID prevActivityId = (ID) prevActivityJSON;
            //FLS Check
            //Activity
            List<String> actListFields = new List<String>{
                    PC_Constants.getQualifiedAPIName('PC_InternalActivityType__c'), PC_Constants.getQualifiedAPIName('PC_NextActivityNumber__c'),
                    PC_Constants.getQualifiedAPIName('PC_InternalActivityNumber__c')
            };

            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_SupportPlanActivity__c'), PC_Database.Operation.Reading, actListFields);

            prevActivity = [
                    SELECT Id, PC_InternalActivityType__c, PC_NextActivityNumber__c, PC_ActivitySequence__c, PC_InitialSequenceActivity__c,PC_InternalActivityNumber__c
                    FROM PC_SupportPlanActivity__c
                    WHERE PC_InternalActivityNumber__c = :prevActivityId
            ];
        }
        return prevActivity;
    }

    private static void updPrevActivity(String ActivityId, PC_SupportPlanActivity__c prevActivity) {
        PC_SupportPlanActivity__c toUpdPrevActivity = prevActivity;
        toUpdPrevActivity.PC_NextActivityNumber__c = ActivityId;
        PC_Database.upd(toUpdPrevActivity, true);
    }

    private static void updPrevSeq(String ActivityId, PC_SupportPlanActivity__c prevActivity) {
        PC_SupportPlanActivity__c toUpdPrevSeq = prevActivity;
        toUpdPrevSeq.PC_InitialSequenceActivity__c = ActivityId;
        PC_Database.upd(toUpdPrevSeq, true);
    }

    private static void updSupportPlan(ID supportPlanID, String supActivityId) {
        if (supportPlanID != NULL) {
            //FLS CHECK
            //Support Plan
            List<String> supportPlanFields = new List<String>{
                    PC_Constants.getQualifiedAPIName('PC_InitialActivity__c')
            };

            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_SupportPlan__c'), PC_Database.Operation.Reading, supportPlanFields);

            PC_SupportPlan__c supportPlan = [SELECT ID, PC_InitialActivity__c FROM PC_SupportPlan__c WHERE ID = :supportPlanID];
            supportPlan.PC_InitialActivity__c = supActivityId;
            PC_Database.upd(supportPlan, true);
        }
    }

    @AuraEnabled
    public static Boolean determineSave(Map<String, String> saveActivityMap) {
        ID checkActivityId;
        Boolean result;
        try {
            checkActivityId = (ID) saveActivityMap.get('activityId');
            result = editRecord(saveActivityMap.get('supActivityJSON'));
        } catch (Exception ex) {
            Id supportPlanID = (ID) saveActivityMap.get('supportPlanID');
            String supActivityJSON = saveActivityMap.get('supActivityJSON');
            String prevActivityJSON = saveActivityMap.get('prevActivityJSON');
            String nextActivity = saveActivityMap.get('nextActivity');
            result = saveRecord(supportPlanID, supActivityJSON, prevActivityJSON, nextActivity);
        }
        return result;
    }

    private static Boolean saveRecord(ID supportPlanID, STRING supActivityJSON, STRING prevActivityJSON, STRING nextActivity) {
        try {
            PC_SupportPlanActivity__c prevActivity = checkPrevActivity(prevActivityJSON);

            PC_SupportPlanBuilderController.SupportPlanActivityWrapper supActivity = (PC_SupportPlanBuilderController.SupportPlanActivityWrapper) System.JSON.deserialize(supActivityJSON, PC_SupportPlanBuilderController.SupportPlanActivityWrapper.class);
            PC_SupportPlanActivity__c supPlanActivity = new PC_SupportPlanActivity__c();

            supPlanActivity.Name = supActivity.activityname;
            if (prevActivity != null) {
                if (supActivity.internalactivitytype == SEQUENCE_TASK) {
                    if (prevActivity.PC_InternalActivityType__c == SEQUENCE) {
                        supPlanActivity.PC_ActivitySequence__c = prevActivity.PC_InternalActivityNumber__c;
                    } else {
                        supPlanActivity.PC_ActivitySequence__c = prevActivity.PC_ActivitySequence__c;
                    }
                }
            }
            supPlanActivity.PC_ActivityType__c = supActivity.activitytype;
            supPlanActivity.PC_InternalActivityType__c = supActivity.internalactivitytype;
            supPlanActivity.PC_AlternateActivity__c = supActivity.alternateactivity;
            supPlanActivity.PC_ApexCondition__c = supActivity.apexcondition;
            supPlanActivity.PC_Channel__c = supActivity.channel;
            supPlanActivity.PC_ConditionBehavior__c = supActivity.conditionbehavior;
            supPlanActivity.PC_Description__c = supActivity.description;
            supPlanActivity.PC_InitialSequenceActivity__c = supActivity.initialsequenceactivity;
            if (supActivity.internalactivitytype == SEQUENCE) {
                supPlanActivity.PC_GroupActivityExecution__c = supActivity.groupactivityexecution;
            }
            if (supActivity.activitytype == AUTOMATION_TASK) {
                supPlanActivity.PC_SubType__c = supActivity.subType;
                supPlanActivity.PC_ActionClass__c = supActivity.actionClass;
                supPlanActivity.PC_AutomationTaskJSON__c = supActivity.automationtaskjson;
            }else{
                supPlanActivity.PC_AutomationTaskJSON__c = supActivity.automationtaskjson;
            }
            if (STRING.isNotEmpty(nextActivity)) {
                ID nextActivityId = (ID) nextActivity;
                supPlanActivity.PC_NextActivityNumber__c = nextActivityId;
            }
            supPlanActivity.PC_Priority__c = supActivity.priority;
            supPlanActivity.PC_ReferenceDate__c = supActivity.referencedate;
            supPlanActivity.PC_ReferenceOffset__c = supActivity.referenceoffset;
            supPlanActivity.PC_ReferenceOffsetUnit__c = supActivity.referenceoffsetunit;

            supPlanActivity.PC_ReferenceType__c = supActivity.referencetype;
            supPlanActivity.PC_Subject__c = supActivity.subject;
            supPlanActivity.PC_SupportPlan__c = Id.valueOf(supActivity.supportplan);
            supPlanActivity.PC_ConditionOption__c = supActivity.conditionoption;
            supPlanActivity.PC_Conditional_Logic__c = supActivity.conditionallogic;
            supPlanActivity.PC_Assign_To_Role__c = supActivity.assigntorole;
            supPlanActivity.PC_UserTask_Fields__c = supActivity.usertaskfields;
            supPlanActivity = (PC_SupportPlanActivity__c) PC_Database.ins(supPlanActivity, true);
            supPlanActivity = [
                    SELECT PC_InternalActivityNumber__c, PC_InternalActivityType__c, PC_NextActivityNumber__c, PC_ActivitySequence__c,PC_SupportPlan__c
                    from PC_SupportPlanActivity__c
                    where PC_InternalActivityNumber__c = :supPlanActivity.Id
            ];
            if (prevActivity != null) {
                if (supPlanActivity.PC_InternalActivityType__c == SEQUENCE_TASK && prevActivity.PC_InternalActivityType__c == SEQUENCE) {
                    updPrevSeq(supPlanActivity.PC_InternalActivityNumber__c, prevActivity);
                } else {
                    updPrevActivity(supPlanActivity.PC_InternalActivityNumber__c, prevActivity);
                }
            }
            updSupportPlan(supportPlanID, supPlanActivity.PC_InternalActivityNumber__c);
            return true;
        } catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
            return false;
        }

    }

    private static Boolean editRecord(STRING supActivityJSON) {

        try {
            PC_SupportPlanBuilderController.SupportPlanActivityWrapper supActivity = (PC_SupportPlanBuilderController.SupportPlanActivityWrapper) System.JSON.deserialize(supActivityJSON, PC_SupportPlanBuilderController.SupportPlanActivityWrapper.class);
            PC_SupportPlanActivity__c toUpdActivity = new PC_SupportPlanActivity__c();
            toUpdActivity.Id = supActivity.Id;
            toUpdActivity.Name = supActivity.activityname;
            toUpdActivity.PC_ActivitySequence__c = supActivity.activitysequence;
            toUpdActivity.PC_ActivityType__c = supActivity.activitytype;
            toUpdActivity.PC_InternalActivityType__c = supActivity.internalactivitytype;
            toUpdActivity.PC_AlternateActivity__c = supActivity.alternateactivity;
            toUpdActivity.PC_ApexCondition__c = supActivity.apexcondition;
            toUpdActivity.PC_Channel__c = supActivity.channel;
            toUpdActivity.PC_ConditionBehavior__c = supActivity.conditionbehavior;
            toUpdActivity.PC_Description__c = supActivity.description;
            toUpdActivity.PC_InitialSequenceActivity__c = supActivity.initialsequenceactivity;
            toUpdActivity.PC_NextActivityNumber__c = supActivity.nextactivitynumber;
            toUpdActivity.PC_Priority__c = supActivity.priority;
            toUpdActivity.PC_ReferenceDate__c = supActivity.referencedate;
            toUpdActivity.PC_ReferenceOffset__c = String.valueOf(supActivity.referenceoffset);
            toUpdActivity.PC_ReferenceOffsetUnit__c = supActivity.referenceoffsetunit;

            toUpdActivity.PC_ReferenceType__c = supActivity.referencetype;
            toUpdActivity.PC_Subject__c = supActivity.subject;
            toUpdActivity.PC_SupportPlan__c = supActivity.supportplan;
            toUpdActivity.PC_ConditionOption__c = supActivity.conditionoption;
            toUpdActivity.PC_Conditional_Logic__c = supActivity.conditionallogic;
            toUpdActivity.PC_Assign_To_Role__c = supActivity.assigntorole;
            toUpdActivity.PC_UserTask_Fields__c = supActivity.usertaskfields;
            if(supActivity.activitytype == AUTOMATION_TASK){
                toUpdActivity.PC_SubType__c = supActivity.subType;
            }
            toUpdActivity.PC_ActionClass__c = supActivity.actionClass;
            toUpdActivity.PC_AutomationTaskJSON__c = supActivity.automationtaskjson;
            if (supActivity.internalactivitytype == SEQUENCE) {
                toUpdActivity.PC_GroupActivityExecution__c = supActivity.groupactivityexecution;
            }

            PC_Database.upd(toUpdActivity, true);
            return true;
        } catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
            return false;
        }

    }

    @AuraEnabled
    public static Boolean deleteRecord(ID supportPlanID, Id activityId, STRING prevActivityJSON) {
        try {
            List<PC_SupportPlanActivity__c> toDelete = new List<PC_SupportPlanActivity__c>();
            List<PC_SupportPlanActivity__c> toDeleteSeqActivities = new List<PC_SupportPlanActivity__c>();
            PC_SupportPlanActivity__c prevActivity = checkPrevActivity(prevActivityJSON);

            //FLS Check
            //Activity
            List<String> actListFields = new List<String>{
                    'Name', PC_Constants.getQualifiedAPIName('PC_NextActivityNumber__c')
            };

            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_SupportPlanActivity__c'), PC_Database.Operation.Reading, actListFields);

            PC_SupportPlanActivity__c toDeleteActivity = [Select Id, Name, PC_InternalActivityType__c,PC_NextActivityNumber__c from PC_SupportPlanActivity__c where PC_InternalActivityNumber__c = :activityId] ;
            String toDeleteActivity_NextActivity = toDeleteActivity.PC_NextActivityNumber__c;
            if (toDeleteActivity.PC_InternalActivityType__c == SEQUENCE) {
                toDeleteSeqActivities = [Select Id from PC_SupportPlanActivity__c where PC_ActivitySequence__c = :activityId];
            }
            toDelete.addAll(toDeleteSeqActivities);
            toDelete.add(toDeleteActivity);
            PC_Database.del(toDelete, true);
            if (prevActivity != null) {
                if (toDeleteActivity.PC_InternalActivityType__c == SEQUENCE_TASK && prevActivity.PC_InternalActivityType__c == SEQUENCE) {
                    updPrevSeq(toDeleteActivity_NextActivity, prevActivity);
                } else {
                    updPrevActivity(toDeleteActivity_NextActivity, prevActivity);
                }
            }
            updSupportPlan(supportPlanID, toDeleteActivity_NextActivity);
            return true;

        } catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
            return false;
        }

    }

    @AuraEnabled
    public static Map<String, List<PC_PicklistFieldManager.PicklistEntryWrapper>> getPicklistEntryMap() {
        Map<String, List<PC_PicklistFieldManager.PicklistEntryWrapper>> picklistEntryMap =
                new Map<String, List<PC_PicklistFieldManager.PicklistEntryWrapper>>();
        try {
            PC_PicklistFieldManager.PicklistEntryWrapper firstEntryWrapper = new PC_PicklistFieldManager.PicklistEntryWrapper('__none', System.Label.PC_Picklist_None);
            PC_PicklistFieldManager.PicklistEntryWrapper firstEntryWrapperWithBlankVal = new PC_PicklistFieldManager.PicklistEntryWrapper(PC_Constants.EMPTY_STRING, System.Label.PC_Picklist_None);

            picklistEntryMap.put('activityType', PC_PicklistFieldManager.getPicklistEntryWrappers(PC_SupportPlanActivity__c.PC_ActivityType__c));
            picklistEntryMap.put('priority', PC_PicklistFieldManager.getPicklistEntryWrappers(PC_SupportPlanActivity__c.PC_Priority__c));
            picklistEntryMap.put('channel', PC_PicklistFieldManager.getPicklistEntryWrappers(PC_SupportPlanActivity__c.PC_Channel__c));
            picklistEntryMap.put('behaviorList', PC_PicklistFieldManager.getPicklistEntryWrappers(PC_SupportPlanActivity__c.PC_ConditionBehavior__c));
            picklistEntryMap.put('refOffsetUnit', PC_PicklistFieldManager.getPicklistEntryWrappers(PC_SupportPlanActivity__c.PC_ReferenceOffsetUnit__c));
            picklistEntryMap.put('assigntorole', PC_PicklistFieldManager.getPicklistEntryWrappers(Task.PC_Assign_to_Role__c));
            picklistEntryMap.put('groupAtivityExecution', PC_PicklistFieldManager.getPicklistEntryWrappers(PC_SupportPlanActivity__c.PC_GroupActivityExecution__c));

            List<PC_PicklistFieldManager.PicklistEntryWrapper> finalReferenceTypeList = new List<PC_PicklistFieldManager.PicklistEntryWrapper>();
            finalReferenceTypeList.add(firstEntryWrapper);
            finalReferenceTypeList.addAll(PC_PicklistFieldManager.getPicklistEntryWrappers(PC_SupportPlanActivity__c.PC_ReferenceType__c));
            picklistEntryMap.put('referenceType', finalReferenceTypeList);

            List<PC_PicklistFieldManager.PicklistEntryWrapper> finalSetConditionList = new List<PC_PicklistFieldManager.PicklistEntryWrapper>();
            finalSetConditionList.add(firstEntryWrapperWithBlankVal);
            finalSetConditionList.addAll(PC_PicklistFieldManager.getPicklistEntryWrappers(PC_SupportPlanActivity__c.PC_ConditionOption__c));
            picklistEntryMap.put('setCondition', finalSetConditionList);
        }catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return picklistEntryMap;
    }

    @AuraEnabled
    public static FieldLabels getFieldLabels() {
        FieldLabels fieldlabels = new FieldLabels();
        try {
            fieldlabels.activityName = PC_SupportPlanActivity__c.Name.getDescribe().getLabel();
            fieldlabels.activityType = PC_SupportPlanActivity__c.PC_ActivityType__c.getDescribe().getLabel();
            fieldlabels.subject = PC_SupportPlanActivity__c.PC_Subject__c.getDescribe().getLabel();
            fieldlabels.priority = PC_SupportPlanActivity__c.PC_Priority__c.getDescribe().getLabel();

            fieldlabels.channel = PC_SupportPlanActivity__c.PC_Channel__c.getDescribe().getLabel();

            fieldlabels.conditionBehavior = PC_SupportPlanActivity__c.PC_ConditionBehavior__c.getDescribe().getLabel();
            fieldlabels.conditionType = PC_SupportPlanActivity__c.PC_ConditionOption__c.getDescribe().getLabel();

            fieldlabels.className = PC_SupportPlanActivity__c.PC_ApexCondition__c.getDescribe().getLabel();
            fieldlabels.referenceDate = PC_SupportPlanActivity__c.PC_ReferenceDate__c.getDescribe().getLabel();
            fieldlabels.referenceOffset = PC_SupportPlanActivity__c.PC_ReferenceOffset__c.getDescribe().getLabel();
            fieldlabels.referenceType = PC_SupportPlanActivity__c.PC_ReferenceType__c.getDescribe().getLabel();
            fieldlabels.assignToRole = PC_SupportPlanActivity__c.PC_Assign_To_Role__c.getDescribe().getLabel();
            fieldlabels.subType = PC_SupportPlanActivity__c.PC_SubType__c.getDescribe().getLabel();
            fieldlabels.groupAtivityExecution = PC_SupportPlanActivity__c.PC_GroupActivityExecution__c.getDescribe().getLabel();
        }catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return fieldlabels;
    }

    @AuraEnabled
    @TestVisible
    public static String getReferenceDatePickistVal(String triggerEventObjectLabel,String triggerEventObjectApiName) {

        List<RefDateLableValWrapper> refDateValWrapperList = new List<RefDateLableValWrapper>();
        try {
            RefDateLableValWrapper firstRefDateValWrapperObj = new RefDateLableValWrapper();
            firstRefDateValWrapperObj.label = System.Label.PC_Picklist_None;
            firstRefDateValWrapperObj.value = PC_Constants.PC_NONE;
            refDateValWrapperList.add(firstRefDateValWrapperObj);

            RefDateLableValWrapper refDateValWrapperObj;

            String type = triggerEventObjectApiName;

            Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();

            Schema.SObjectType objSchema = schemaMap.get(type);

            Map<String, Schema.SObjectField> fieldMap = objSchema.getDescribe().fields.getMap();

            for (String fieldName : fieldMap.keySet()) {

                String fieldLabel = fieldMap.get(fieldName).getDescribe().getLabel();

                Schema.DisplayType fielddataType = fieldMap.get(fieldName).getDescribe().getType();

                if (Schema.DisplayType.DATE.equals(fielddataType) || Schema.DisplayType.DATETIME.equals(fielddataType)) {

                    refDateValWrapperObj = new RefDateLableValWrapper();

                    refDateValWrapperObj.label = fieldLabel;
                    refDateValWrapperObj.value = fieldMap.get(fieldName).getDescribe().getName();
                    refDateValWrapperList.add(refDateValWrapperObj);
                }

            }
        }catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return JSON.serialize(refDateValWrapperList);

    }

    /*********************************************************************************
     Method Name    : getSupportPlanAutomationTaskData
     Author         : Shishir Bansal
     Description    : This method returns the name of the Lightning Component to be
                      displayed when Automation Task is selected
     Return Type    : String
     Parameter      : Support Plan Salesforce Id
    *********************************************************************************/

    @AuraEnabled
    public static List<supportPlanAutomationTaskMetadataWrapper> getSupportPlanAutomationTaskData( Id supportPlanID,String triggerEventObjectName) {
        List<supportPlanAutomationTaskMetadataWrapper> AutomationWrapper = new List<supportPlanAutomationTaskMetadataWrapper> ();
        try {
            List<PC_Support_Plan_Automation_Task__mdt> supportPlanActions;
            //String genericMetadata = PC_Constants.SUPPORTPLAN_METADATA_ALL_SP;
            List<String> objectNameSplitStrings = new List<String>();
            if(String.isNotBlank(triggerEventObjectName)){
                //Added condition to avoid split when triggerEventObjectName doesn't have namespace
                if(triggerEventObjectName.contains('__') && triggerEventObjectName.countMatches('__') == 2){
                    objectNameSplitStrings = triggerEventObjectName.split('__', 2);
                }
                if (objectNameSplitStrings.size() > 1) {
                    String namespace = objectNameSplitStrings[0] ;
                    String objectName = objectNameSplitStrings[1];
                    supportPlanActions = [
                            Select Id, PC_Active__c, PC_LightningComponent__c, PC_Type__c, PC_ActionClass__c
                            FROM PC_Support_Plan_Automation_Task__mdt
                            WHERE PC_Active__c = true AND ((PC_SourceObjectAPIName__c = :objectName OR PC_SourceObjectAPIName__c = :PC_Constants.EMPTY_STRING) AND (PC_SourceObjectNamespace__c = :namespace OR PC_SourceObjectNamespace__c = :PC_Constants.EMPTY_STRING))
                    ];
                } else {
                    supportPlanActions = [
                            Select Id, PC_Active__c, PC_LightningComponent__c, PC_Type__c, PC_ActionClass__c
                            FROM PC_Support_Plan_Automation_Task__mdt
                            WHERE PC_Active__c = true AND (PC_SourceObjectAPIName__c = :triggerEventObjectName OR PC_SourceObjectAPIName__c = :PC_Constants.EMPTY_STRING)
                    ];
                }
            }
            if (supportPlanActions != null) {
                for (PC_Support_Plan_Automation_Task__mdt a : supportPlanActions) {
                    supportPlanAutomationTaskMetadataWrapper obj = new supportPlanAutomationTaskMetadataWrapper(a);
                    AutomationWrapper.add(obj) ;
                }
            }
        }catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return AutomationWrapper;
    }

    /*********************************************************************************
      Method Name    : getFieldPickListValues
      Author         : Vivek Kumar Mishra
      Description    : This method returns a List of RequiredFieldWrapper objects which
                       holds the details related to the required field
      Return Type    : List<RequiredFieldWrapper>
      Parameter      : SObjects Name and SObjects Field Set Name
     *********************************************************************************/
    @AuraEnabled
    public static String getRequiredFields(String objectTypeName, String fieldSetName, PC_SupportPlanBuilderController.SupportPlanActivityWrapper activity) {
        String taskProperties ='';
        Set<PC_AutomationTaskHelper.FieldMap> requiredFieldWrapperSet = new Set<PC_AutomationTaskHelper.FieldMap>();
        Set<RequiredFieldWrapper> requiredFieldOldWrappers = new Set<RequiredFieldWrapper>();
        try {
            Set<String> allFieldApiNames = new Set<String>();
            if (activity.usertaskfields != null && activity.usertaskfields != PC_Constants.EMPTY_STRING){
                /*Below code is added for backward compatibility purposes.(Added in 14th version).
                *In old wrapper(RequiredFieldWrapper) isDeleteAllowed was a String but in new wrapper(PC_AutomationTaskHelper.FieldMap)
                *it is Boolean to support the older wrapper properties that was used by clients already below try catch is used*/
                try{
                    NewRequiredFieldSetWrapper allNewFieldsWrapper = (NewRequiredFieldSetWrapper) System.JSON.deserialize(activity.usertaskfields, NewRequiredFieldSetWrapper.class);
                    requiredFieldWrapperSet.addAll(allNewFieldsWrapper.requiredFieldSet);
                }catch(Exception e){
                    RequiredFieldSetWrapper fieldsWrapper = (RequiredFieldSetWrapper) System.JSON.deserialize(activity.usertaskfields, RequiredFieldSetWrapper.class);
                    requiredFieldOldWrappers.addAll(fieldsWrapper.requiredFieldSet);
                    requiredFieldWrapperSet.addAll(PC_AutomationTaskHelper.convertOldFieldWrapperToNew(requiredFieldOldWrappers));
                }
                for(PC_AutomationTaskHelper.FieldMap eachFieldMap : requiredFieldWrapperSet){
                    allFieldApiNames.add(eachFieldMap.apiName);
                }
            }
            if(fieldSetName != null ) {
                PC_AutomationTaskHelper.FieldMap requiredFieldWrapperObj;
                objectTypeName = PC_Constants.getQualifiedAPIName(objectTypeName);
                Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
                Schema.SObjectType leadSchema = schemaMap.get(objectTypeName);
                Schema.FieldSet fieldSetObj = leadSchema.getDescribe().FieldSets.getMap().get(fieldSetName);

                //Get All fields Map
                Map<String, Schema.SObjectType> objectsMap = Schema.getGlobalDescribe();
                Schema.SObjectType myObject = objectsMap.get(objectTypeName);
                Map<String, Schema.SObjectField> fieldMap = (Map<String, SObjectField>) myObject.getDescribe().fields.getMap();

                for (Schema.FieldSetMember field : fieldSetObj.fields) {
                    requiredFieldWrapperObj = new PC_AutomationTaskHelper.FieldMap();
                    requiredFieldWrapperObj.apiName = fieldMap.get(field.getFieldPath()).getDescribe().getName();
                    requiredFieldWrapperObj.label = field.getLabel();
                    requiredFieldWrapperObj.type = String.valueOf(field.getType());
                    requiredFieldWrapperObj.value = PC_Constants.EMPTY_STRING;
                    requiredFieldWrapperObj.isDeleteAllowed = PC_Constants.FALSE_BOOLEAN;
                    if(!allFieldApiNames.contains(requiredFieldWrapperObj.apiName)){
                        allFieldApiNames.add(requiredFieldWrapperObj.apiName);
                        requiredFieldWrapperSet.add(requiredFieldWrapperObj);
                    }
                }
            }
            taskProperties = JSON.serialize(requiredFieldWrapperSet);
        } catch (Exception e) {
            PC_Utility.logAndThrowException(e);
        }
        return taskProperties;
    }
    /*Till 14th release for Activity types User Task and Automation Task below wrapper was used.
    * Later on PC_AutomationTaskHelper.FieldMap is used as enhanced builder(PC_PropertiesAndConditionsBuilder)
    * replaced PC_UserTask_Properties builder.
    * In Below Wrapper
    * label - Stores Field Label
    * apiName - Stores Field Api Name
    * value - Stores Field value
    * isDeleteAllowed - Stores whether the field is mandatory or not
    * type - Stores Field type*/
    public class RequiredFieldWrapper {
        public String label { get; set; }
        public String value { get; set; }
        public Schema.DisplayType type { get; set; }
        public String apiName { get; set; }
        public String isDeleteAllowed { get; set; }


        RequiredFieldWrapper() {
            //this.isDeleteAllowed = 'true';
        }

        public Boolean equals(Object obj) {
            if (obj instanceof RequiredFieldWrapper) {
                if (this.apiName != null && ((RequiredFieldWrapper) obj).apiName != null) {
                    if (this.apiName == ((RequiredFieldWrapper) obj).apiName) {
                        return true;
                    } else {
                        return false;
                    }
                }
            }
            return false;
        }

        public Integer hashCode() {
            return 1;
        }
    }
    /*Below wrapper class was used for PC_UserTask_Properties component which got deprecated in
    * 14th release of the package.*/
    public class RequiredFieldSetWrapper {
        public Set<RequiredFieldWrapper> requiredFieldSet { get; set; }
        public RequiredFieldSetWrapper() {
        }
    }
    /*Below wrapper class is used for PC_PropertiesAndConditionalBuilder component with Activity type as User Task
    * or Automation Task from 14th release*/
    public class NewRequiredFieldSetWrapper{
        public Set<PC_AutomationTaskHelper.FieldMap> requiredFieldSet { get; set; }
        public NewRequiredFieldSetWrapper(){
        }
    }

    public class RefDateLableValWrapper {
        public String label { get; set; }
        public String value { get; set; }

        public RefDateLableValWrapper() {

        }
    }

    public class FieldLabels {
        //Activity Fields
        @AuraEnabled public String activityName { get; set; }
        @AuraEnabled public String activityType { get; set; }
        @AuraEnabled public String subject { get; set; }
        @AuraEnabled public String priority { get; set; }
        @AuraEnabled public String channel { get; set; }
        @AuraEnabled public String conditionBehavior { get; set; }
        @AuraEnabled public String conditionType { get; set; }
        @AuraEnabled public String className { get; set; }
        @AuraEnabled public String referenceDate { get; set; }
        @AuraEnabled public String referenceOffset { get; set; }
        @AuraEnabled public String referenceType { get; set; }
        @AuraEnabled public String assignToRole { get; set; }
        @AuraEnabled public String subType { get; set; }
        @AuraEnabled public String groupAtivityExecution { get; set; }

        public FieldLabels() {
        }
    }

    @AuraEnabled
    public static ConstantsFieldsWrapper getConstantsWrapper() {

        ConstantsFieldsWrapper constantsFieldsWrapper = new ConstantsFieldsWrapper();
        return constantsFieldsWrapper;

    }

    public class ConstantsFieldsWrapper {
        @AuraEnabled public String noneStr { get; set; }
        @AuraEnabled public String beforeRefDate { get; set; }
        @AuraEnabled public String afterRefDate { get; set; }
        @AuraEnabled public String afterCompletionOfPrevActivity { get; set; }
        @AuraEnabled public String activityCreationDate { get; set; }
        @AuraEnabled public String condOptionApex { get; set; }
        @AuraEnabled public String condOptionCondBuilder { get; set; }
        @AuraEnabled public String condBehavNoCond { get; set; }
        @AuraEnabled public String condOperatorEquals { get; set; }
        @AuraEnabled public String condOperatorDoesNotEquals { get; set; }
        @AuraEnabled public String condOperatorIsNotNull { get; set; }
        @AuraEnabled public String condOperatorIsNull { get; set; }
        @AuraEnabled public String condOperatorhasNotChanged { get; set; }
        @AuraEnabled public String condOperatorhasChanged { get; set; }
        @AuraEnabled public String condOperatorContains { get; set; }
        @AuraEnabled public String condOperatorDoesNotContains { get; set; }

        public ConstantsFieldsWrapper() {
            noneStr = PC_Constants.PC_NONE;
            beforeRefDate = PC_Constants.PC_BEFORE_REFERENCE_DATE;
            afterRefDate = PC_Constants.PC_AFTER_REFERENCE_DATE;
            afterCompletionOfPrevActivity = PC_Constants.PC_AFTER_COMPLETION_OF_PREVIOUS_ACTIVITY;
            activityCreationDate = PC_Constants.PC_ACTIVITY_CREATION_DATE;
            condOptionApex = PC_Constants.PC_COND_OPTION_APEX_CLASS;
            condBehavNoCond = PC_Constants.PC_COND_BEHAVIOUR_NO_CONDITION;
            condOptionCondBuilder = PC_Constants.PC_COND_OPTION_CONDITIONAL_BUILDER;
            condOperatorEquals = PC_Constants.PC_Operator_Equals;
            condOperatorDoesNotEquals = PC_Constants.PC_Operator_Does_Not_Equals;
            condOperatorIsNotNull = PC_Constants.PC_IS_NOT_NULL;
            condOperatorIsNull = PC_Constants.PC_IS_NULL;
            condOperatorhasNotChanged = PC_Constants.PC_HAS_NOT_CHANGED;
            condOperatorhasChanged = PC_Constants.PC_HAS_CHANGED;
            condOperatorContains = PC_Constants.PC_CONTAINS;
            condOperatorDoesNotContains = PC_Constants.PC_DOES_NOT_CONTAINS;
        }
    }


    public class supportPlanAutomationTaskMetadataWrapper {
        @AuraEnabled public Boolean automationTaskActive { get; set; }
        @AuraEnabled public String automationTaskLightningComponent { get; set; }
        @AuraEnabled public String actionLabel { get; set; }
        @AuraEnabled public String actionClass { get; set; }
        @AuraEnabled public String subTypePicklist { get; set; }


        public supportPlanAutomationTaskMetadataWrapper(PC_Support_Plan_Automation_Task__mdt a) {
            automationTaskActive = a.PC_Active__c;
            if (String.isBlank(a.PC_LightningComponent__c)) {
                automationTaskLightningComponent = PC_Constants.OrgNamespace + ':' + PC_Constants.DEFAULT_AUTOMATION_TASK;
            } else {
                automationTaskLightningComponent = (a.PC_LightningComponent__c.contains(':')) ? a.PC_LightningComponent__c : 'c:' + a.PC_LightningComponent__c;
            }
            subTypePicklist = a.PC_Type__c;
            actionClass = a.PC_ActionClass__c;
        }
    }

    /*********************************************************************************
    Method Name    : processLabelChangeInJSONString
    Author         : Tushar Arora
    Description    : This method will process conditional builder JSON
    Return Type    : String
    Parameter      : strJSON , sObjectName
    *********************************************************************************/
    private static String processLabelChangeInJSONString (String strJSON){
        String returnJSONString = '';
        PC_ConditionBuilder supportPlanCondBuilder = new PC_ConditionBuilder();
        supportPlanCondBuilder = (PC_ConditionBuilder) System.JSON.deserialize(strJSON, PC_ConditionBuilder.class);
        Map<String,String> fieldLabelToFieldAPIMap= new Map<String,String>();
        String fieldLabel = '';
        fieldLabelToFieldAPIMap = getsObjectFieldLabelAPIMap(supportPlanCondBuilder.LstConditionsPerObject[0].ObjectType);
        List<PC_ConditionBuilder.Conditions> supportPlanConditions = new List<PC_ConditionBuilder.Conditions>();
        for (PC_ConditionBuilder.Conditions condition : supportPlanCondBuilder.LstConditionsPerObject[0].Conditions){
            if(condition.FieldApiName != null && condition.FieldApiName != ''){
                fieldLabel = fieldLabelToFieldAPIMap.get(condition.FieldApiName.toUpperCase());
                if(fieldLabel != null && fieldLabel != ''){
                    condition.FieldName = fieldLabel;
                }
            }
            supportPlanConditions.add(condition);
        }
        supportPlanCondBuilder.LstConditionsPerObject[0].Conditions.clear();
        supportPlanCondBuilder.LstConditionsPerObject[0].Conditions.addAll(supportPlanConditions);
        returnJSONString = System.JSON.serialize(supportPlanCondBuilder);
        return returnJSONString;
    }
    /*********************************************************************************
    Method Name    : getsObjectFieldLabelAPIMap
    Author         : Tushar Arora
    Description    : This method  will return API Name with Label Map of sObject Fields
    Return Type    : Map<String, String>
    Parameter      : sObjectName
    *********************************************************************************/
    private static Map<String, String> getsObjectFieldLabelAPIMap (String sObjectName){
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType leadSchema = schemaMap.get(sObjectName);
        Map<String, Schema.SObjectField> fieldMap = (Map<String, SObjectField>) leadSchema.getDescribe().fields.getMap();
        Map<String, String> fieldsMap = new Map<String, String>();
        for (String fieldName : fieldMap.keySet()) {
            fieldsMap.put(fieldMap.get(fieldName).getDescribe().getName().toUpperCase(),fieldMap.get(fieldName).getDescribe().getLabel());
        }
        System.debug('fieldsMap::::'+fieldsMap);
        return fieldsMap;
    }

}