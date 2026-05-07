/*********************************************************************************
Class Name      : PC_Custom_SupportPlanController
Description     : Handles existing Support Plans
Created By      : Hitha Avalakki
Created Date    : 11-Oct-2018
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------
Hitha Avalakki              11-Oct-18              Initial Version
Shishir Bansal              Dec-06-2019            [PC-5792] Avoid hardcoding of string variable
Haritha Reddy               11-Dec-2019            [PC-5791] Added Error handling for methods where it was missing
                                                    and removed getListViews method which is not being used
Tushar Arora                03-Mar-2020            [PC-6040] Added Trigger Event Related Information for Support Plan Enhanced UI
Tushar Arora                18-Mar-2020            [PC-6022] Added logic for getting list of sObjects from TriggerHandlerRegister.
Tushar Arora                19-Mar-2020            [PC-6127] Added logic to select Trigger Event sobject for Trigger Event  as well as Custom Support Plan for Conditional Builder
Tushar Arora                01-Apr-2020            [PC-6040] Added Trigger Event Type List with None value as well.
Tushar Arora                01-Apr-2020            [PC-6041][PC-6042] Added logic for saving/Editing enhanced support plan.
Tushar Arora                10-Apr-2020            [PC-6046] Added Operator constants in ConstantsFieldsWrapper
Tushar Arora                16-Apr-2020            [PC-6147] Added Error handling Conditions while launching and saving a support plan
Tushar Arora                16-Apr-2020            [PC-6040] Added code review changes.
Tushar Arora                12-Jun-2020            [PC-6205] Modified Logic for showing label of fields used in conditional builder to support translation.
Kishore Kanteti             23-Oct-2020            [PC-6913] Added getDefaultSupportPlanBehavior method for support plan behavior and done relevant changes to save and edit.
Vijay Kashikar              21-Jan-21              [PC-7102] Added sharing clause
*********************************************************************************/
public with sharing class PC_Custom_SupportPlanController {

    /*********************************************************************************
    Method Name    : fetchInformation
    Author         : Tushar Arora
    Description    : This method will fetch all the information
    Return Type    : Map<String,Object>
    Parameter      : recordId
    *********************************************************************************/
    @AuraEnabled
    public static List<SupportPlan> fetchInformation(Id recordId){
        List<SupportPlan> supportPlanList 	= new List<SupportPlan>();
        try {
            SupportPlan supportPlan = new SupportPlan();
            BaseSupportPlan baseSupportPlan = new BaseSupportPlan();
            ConstantsFieldsWrapper constantsFieldsWrapper=new ConstantsFieldsWrapper();
            Map<String, List<PC_PicklistFieldManager.PicklistEntryWrapper>> picklistEntryWrapperMap= new Map<String, List<PC_PicklistFieldManager.PicklistEntryWrapper>>();
            FieldLabelsWrapper fieldlabels = new FieldLabelsWrapper();
            baseSupportPlan = fetchSupportPlan(recordId);
            if(baseSupportPlan != null){
                supportPlan.baseSupportPlan = baseSupportPlan;
                if(supportPlan.baseSupportPlan.triggerEventObject != null && supportPlan.baseSupportPlan.triggerEventObject != ''){
                    if(supportPlan.baseSupportPlan.conditionallogic != null && supportPlan.baseSupportPlan.conditionallogic != '') {
                        supportPlan.baseSupportPlan.conditionallogic = processLabelChangeInJSONString(supportPlan.baseSupportPlan.conditionallogic, supportPlan.baseSupportPlan.triggerEventObject);
                    }
                    if(supportPlan.baseSupportPlan.triggerEventCondition != null && supportPlan.baseSupportPlan.triggerEventCondition != '') {
                        supportPlan.baseSupportPlan.triggerEventCondition = processLabelChangeInJSONString(supportPlan.baseSupportPlan.triggerEventCondition, supportPlan.baseSupportPlan.triggerEventObject);
                    }
                }
            }
            supportPlan.constantsWrapper = constantsFieldsWrapper;
            picklistEntryWrapperMap = getPicklistEntryMap();
            if(!picklistEntryWrapperMap.keySet().IsEmpty()){
                supportPlan.picklistEntryWrapperMap = picklistEntryWrapperMap;
            }
            fieldlabels = getConditionFieldLabels();
            if(fieldlabels != null){
                supportPlan.fieldLabelsWrapper = fieldlabels;
            }
            supportPlanList.add(supportPlan);
        }catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }

        return supportPlanList;
    }
    /*********************************************************************************
   Method Name    : getTriggerEventObject
   Author         : Tushar Arora
   Description    : This method  will fetch all the trigger event object list from PC_TriggerHandlerRegister__mdt which have apex class named PC_SupportPlanInitiationHandler
   Return Type    : List<PC_PicklistFieldManager.PicklistEntryWrapper>
   Parameter      : N/A
   *********************************************************************************/
    @AuraEnabled
    public static List<PC_PicklistFieldManager.PicklistEntryWrapper> getTriggerEventObject(){
        List<PC_PicklistFieldManager.PicklistEntryWrapper> picklistEntryWrappers  = new List<PC_PicklistFieldManager.PicklistEntryWrapper>();
        //try {
            List<PC_TriggerHandlerRegister__mdt>  triggerHandlerRegisterList = new List<PC_TriggerHandlerRegister__mdt>();
            triggerHandlerRegisterList = [SELECT Id,  PC_Active__c, PC_ApexClass__c, PC_OtherObject__c, PC_sObject__c
                                            FROM PC_TriggerHandlerRegister__mdt
                                            Where PC_ApexClass__c = : PC_Constants.SUPPORTPLAN_INITIATIONHANDLER_CLASSNAME AND PC_Active__c = true];
            for(PC_TriggerHandlerRegister__mdt tr : triggerHandlerRegisterList){
                if(tr.PC_sObject__c != null){
                    if(tr.PC_sObject__c != PC_Constants.SUPPORTPLAN_OTHER_SOBJECT){
                        getsObjectValidated(String.valueof(tr.PC_sObject__c));
                        if(!tr.PC_sObject__c.contains('__')){
                            picklistEntryWrappers.add(new PC_PicklistFieldManager.PicklistEntryWrapper(tr.PC_sObject__c, Schema.getGlobalDescribe().get(String.valueof(tr.PC_sObject__c)).getDescribe().getLabel()));
                        } else {
                            picklistEntryWrappers.add(new PC_PicklistFieldManager.PicklistEntryWrapper(PC_Constants.getQualifiedAPIName(String.valueof(tr.PC_sObject__c)), Schema.getGlobalDescribe().get(PC_Constants.getQualifiedAPIName(String.valueof(tr.PC_sObject__c))).getDescribe().getLabel()));
                        }
                    } else {
                        getsObjectValidated(String.valueof(tr.PC_OtherObject__c));
                        picklistEntryWrappers.add(new PC_PicklistFieldManager.PicklistEntryWrapper(tr.PC_OtherObject__c, Schema.getGlobalDescribe().get(String.valueof(tr.PC_OtherObject__c)).getDescribe().getLabel()));
                    }
                }
            }
        return picklistEntryWrappers;
    }

    /*********************************************************************************
    Method Name    : fetchSupportPlan
    Author         : Hitha Avalakki
    Description    : This method  fetches the details of existing support plan else returns an empty support plan object
    Return Type    : PC_SupportPlan__c
    Parameter      : recordId
    *********************************************************************************/
    @AuraEnabled
    public static BaseSupportPlan fetchSupportPlan(Id recordId){

        BaseSupportPlan baseSupportPlan=new BaseSupportPlan();
        PC_SupportPlan__c supportPlanObj = new PC_SupportPlan__c();
        if (recordId != null) {
            //FLS Check for PC_SupportPlan__c
            List<String> supportPlanFields = new List<String>{'Id','Name' ,PC_Constants.getQualifiedAPIName('PC_Conditional_Logic__c'),
                    PC_Constants.getQualifiedAPIName('PC_Description__c'),PC_Constants.getQualifiedAPIName('PC_InitialActivity__c'),
                    PC_Constants.getQualifiedAPIName('PC_IsActive__c'),PC_Constants.getQualifiedAPIName('PC_TriggerEventConditionalBehavior__c'),
                    PC_Constants.getQualifiedAPIName('PC_TriggerEventConditionOption__c'),PC_Constants.getQualifiedAPIName('PC_TriggerEventType__c'),
                    PC_Constants.getQualifiedAPIName('PC_TriggerEventCondition__c'),PC_Constants.getQualifiedAPIName('PC_TriggerEventObject__c'),
                    PC_Constants.getQualifiedAPIName('PC_Version__c'),PC_Constants.getQualifiedAPIName('PC_ConditionBehavior__c'),
                    PC_Constants.getQualifiedAPIName('PC_Condition_Option__c'),PC_Constants.getQualifiedAPIName('PC_StartCondition__c'),
                    PC_Constants.getQualifiedAPIName('PC_SupportPlan_Behavior__c')
            };
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_SupportPlan__c'), PC_Database.Operation.Reading, supportPlanFields);

            List<PC_SupportPlan__c> supportPlanList = [
                    SELECT Id, Name, PC_ConditionBehavior__c, PC_Description__c,PC_InitialActivity__c, PC_IsActive__c,PC_TriggerEventConditionalBehavior__c,PC_TriggerEventConditionOption__c,
                            PC_TriggerEventType__c,PC_SupportPlan_Behavior__c, PC_TriggerEventCondition__c, PC_StartCondition__c, PC_TriggerEventObject__c, PC_Version__c, PC_Conditional_Logic__c, PC_Condition_Option__c
                    from PC_SupportPlan__c
                    where Id = :recordId
            ];
            supportPlanObj = supportPlanList[0];
        } else {
            supportPlanObj.Name = PC_Constants.EMPTY_STRING;
            supportPlanObj.PC_ConditionBehavior__c = PC_Constants.PC_COND_BEHAVIOUR_NO_CONDITION;
            supportPlanObj.PC_Description__c = PC_Constants.EMPTY_STRING;
            supportPlanObj.PC_Conditional_Logic__c = null;
            supportPlanObj.PC_SupportPlan_Behavior__c = getDefaultSupportPlanBehavior();
            supportPlanObj.PC_IsActive__c = false;
            supportPlanObj.PC_TriggerEventObject__c =  null;
            supportPlanObj.PC_TriggerEventType__c =  null;
            supportPlanObj.PC_TriggerEventCondition__c =  null;

        }

        BaseSupportPlan = new BaseSupportPlan(supportPlanObj);
        return baseSupportPlan;
    }

    /*********************************************************************************
    Method Name    : getDefaultSupportPlanBehavior
    @@author       : kanteti kishore
    @@description  : This method returns default value of support plan behavior
    @@return       : String
    *********************************************************************************/
    public static String getDefaultSupportPlanBehavior(){
        String defaultValue;
        Schema.DescribeFieldResult fieldResult = PC_SupportPlan__c.PC_SupportPlan_Behavior__c.getDescribe();
        List <Schema.PicklistEntry> pickVals = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry pv: pickVals) {
            if (pv.isDefaultValue()) {
                defaultValue = pv.getValue();
            }
        }
        if(String.isBlank(defaultValue)){
            defaultValue = String.valueOf(PC_Constants.SupportPlanBehaviour.RunEveryTimeRuleMatches);
        }
        return defaultValue;
    }

    /*********************************************************************************
    Method Name    : determineSave
    Author         : Tejas Patel
    Description    : This method updates the details of existing support plan or creates a new one
    Return Type    : PC_SupportPlan__c
    Parameter      : recordId, JSON
    *********************************************************************************/
    @AuraEnabled
    public static ID determineSave(Id spId, String supJSON){
        try{
            BaseSupportPlan baseSupportPlan	=   (BaseSupportPlan)System.JSON.deserialize(supJSON, BaseSupportPlan.class);
            PC_SupportPlan__c supportPlan           =   new PC_SupportPlan__c();
            supportPlan.Name                    =   baseSupportPlan.spname;
            supportPlan.PC_Description__c       =   baseSupportPlan.description;
            supportPlan.PC_ConditionBehavior__c =   baseSupportPlan.conditionbehavior;
            supportPlan.PC_StartCondition__c    =   baseSupportPlan.startcondition;
            supportPlan.PC_Condition_Option__c  =   baseSupportPlan.conditionoption;
            supportPlan.PC_Conditional_Logic__c =   baseSupportPlan.conditionallogic;
            supportPlan.PC_IsActive__c          =   baseSupportPlan.isactive;
            supportPlan.PC_TriggerEventObject__c =   baseSupportPlan.triggerEventObject;
            supportPlan.PC_TriggerEventType__c  =   baseSupportPlan.triggerEventType;
            supportPlan.PC_TriggerEventCondition__c  =  baseSupportPlan.triggerEventCondition;
            supportPlan.PC_SupportPlan_Behavior__c  =   baseSupportPlan.supportPlanBehavior;


            if(baseSupportPlan.triggerEventCondition != null && baseSupportPlan.triggerEventCondition != ''){
                supportPlan.PC_TriggerEventConditionalBehavior__c = PC_Constants.SUPPORTPLAN_CONDBEHAVIOR_STATUS_WAIT;
                supportPlan.PC_TriggerEventConditionOption__c = PC_Constants.PC_COND_OPTION_CONDITIONAL_BUILDER;
            } else {
                supportPlan.PC_TriggerEventConditionalBehavior__c = PC_Constants.PC_COND_BEHAVIOUR_NO_CONDITION;
                supportPlan.PC_TriggerEventConditionOption__c = '';
            }

            if(spId != null){
                supportPlan.Id  =   spId;
                supportPlan     = (PC_SupportPlan__c)PC_Database.upd(supportPlan,true);
            }else{
                supportPlan = (PC_SupportPlan__c)PC_Database.ins(supportPlan,true);
            }
            return supportPlan.Id;
        }catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return null;
    }

    /*********************************************************************************
    Method Name    : getFieldLabels
    Author         : Prachi Nandgaonkar
    Description    : This method  displays column headers for referral list view
    Return Type    : FieldLabels
    Parameter      : void
    *********************************************************************************/
    @AuraEnabled
    public static FieldLabelsWrapper getConditionFieldLabels(){
        FieldLabelsWrapper fieldlabels 	= new FieldLabelsWrapper();
        fieldlabels.supportPlanName = PC_SupportPlan__c.Name.getDescribe().getLabel();
        fieldlabels.conditionBehaviour = PC_SupportPlan__c.PC_ConditionBehavior__c.getDescribe().getLabel();
        fieldlabels.descriptionStr = PC_SupportPlan__c.PC_Description__c.getDescribe().getLabel();
        fieldlabels.conditionType = PC_SupportPlan__c.PC_Condition_Option__c.getDescribe().getLabel();
        fieldlabels.className = PC_SupportPlan__c.PC_StartCondition__c.getDescribe().getLabel();
        fieldlabels.triggerEventType = PC_SupportPlan__c.PC_TriggerEventType__c.getDescribe().getLabel();
        fieldlabels.triggerEventCondition = PC_SupportPlan__c.PC_TriggerEventConditionalBehavior__c.getDescribe().getLabel();
        fieldlabels.triggerEventObject = PC_SupportPlan__c.PC_TriggerEventObject__c.getDescribe().getLabel();
        fieldlabels.supportPlanBehavior = PC_SupportPlan__c.PC_SupportPlan_Behavior__c.getDescribe().getInlineHelpText();
        fieldlabels.supportPlanBehaviorSectionHeader = PC_SupportPlan__c.PC_SupportPlan_Behavior__c.getDescribe().getLabel();
        return fieldlabels;
    }

    /* Wrapper for column titles */
    public inherited sharing class FieldLabelsWrapper{
        @AuraEnabled public String conditionBehaviour { get; set; }
        @AuraEnabled public String supportPlanName { get; set; }
        @AuraEnabled public String descriptionStr { get; set; }
        @AuraEnabled public String conditionType { get; set; }
        @AuraEnabled public String className { get; set; }
        @AuraEnabled public String triggerEventType { get; set; }
        @AuraEnabled public String triggerEventCondition { get; set; }
        @AuraEnabled public String triggerEventObject { get; set; }
        @AuraEnabled public String supportPlanBehavior { get; set; }
        @AuraEnabled public String supportPlanBehaviorSectionHeader { get; set; }

        public FieldLabelsWrapper() {
        }
    }

    @AuraEnabled
    public static ConstantsFieldsWrapper getConstantsWrapper(){

        ConstantsFieldsWrapper constantsFieldsWrapper=new ConstantsFieldsWrapper();
        return constantsFieldsWrapper;

    }

    public inherited sharing class ConstantsFieldsWrapper {
        @AuraEnabled public String noneStr { get; set; }
        @AuraEnabled public String beforeRefDate { get; set; }
        @AuraEnabled public String afterRefDate{ get; set; }
        @AuraEnabled public String afterCompletionOfPrevActivity { get; set; }
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
            noneStr=System.Label.PC_Picklist_None;
            beforeRefDate=PC_Constants.PC_BEFORE_REFERENCE_DATE;
            afterRefDate=PC_Constants.PC_AFTER_REFERENCE_DATE;
            afterCompletionOfPrevActivity=PC_Constants.PC_AFTER_COMPLETION_OF_PREVIOUS_ACTIVITY;
            condOptionApex=PC_Constants.PC_COND_OPTION_APEX_CLASS;
            condBehavNoCond=PC_Constants.PC_COND_BEHAVIOUR_NO_CONDITION;
            condOptionCondBuilder=PC_Constants.PC_COND_OPTION_CONDITIONAL_BUILDER;
            condOperatorEquals=PC_Constants.PC_Operator_Equals;
            condOperatorDoesNotEquals=PC_Constants.PC_Operator_Does_Not_Equals;
            condOperatorIsNotNull = PC_Constants.PC_IS_NOT_NULL;
            condOperatorIsNull = PC_Constants.PC_IS_NULL;
            condOperatorhasNotChanged = PC_Constants.PC_HAS_NOT_CHANGED;
            condOperatorhasChanged = PC_Constants.PC_HAS_CHANGED;
            condOperatorContains = PC_Constants.PC_CONTAINS;
            condOperatorDoesNotContains = PC_Constants.PC_DOES_NOT_CONTAINS;
        }
    }

    @AuraEnabled
    public static Map<String, List<PC_PicklistFieldManager.PicklistEntryWrapper>> getPicklistEntryMap() {
        Map<String, List<PC_PicklistFieldManager.PicklistEntryWrapper>> picklistEntryMap = new Map<String, List<PC_PicklistFieldManager.PicklistEntryWrapper>>();
            PC_PicklistFieldManager.PicklistEntryWrapper firstEntryWrapperWithBlankVal = new PC_PicklistFieldManager.PicklistEntryWrapper('', System.Label.PC_Picklist_None);

            picklistEntryMap.put('behaviorList', PC_PicklistFieldManager.getPicklistEntryWrappers(PC_SupportPlan__c.PC_ConditionBehavior__c));
            picklistEntryMap.put('supportPlanBehaviorList', PC_PicklistFieldManager.getPicklistEntryWrappers(PC_SupportPlan__c.PC_SupportPlan_Behavior__c));

            List<PC_PicklistFieldManager.PicklistEntryWrapper> finalSetConditionList = new List<PC_PicklistFieldManager.PicklistEntryWrapper>();
            finalSetConditionList.add(firstEntryWrapperWithBlankVal);
            finalSetConditionList.addAll(PC_PicklistFieldManager.getPicklistEntryWrappers(PC_SupportPlan__c.PC_Condition_Option__c));
            picklistEntryMap.put('setCondition', finalSetConditionList);

            picklistEntryMap.put('triggerEventConditionList', PC_PicklistFieldManager.getPicklistEntryWrappers(PC_SupportPlan__c.PC_TriggerEventConditionalBehavior__c));
            picklistEntryMap.put('triggerEventConditionOptionList', PC_PicklistFieldManager.getPicklistEntryWrappers(PC_SupportPlan__c.PC_TriggerEventConditionOption__c));

            List<PC_PicklistFieldManager.PicklistEntryWrapper> finalSetEventTypeList = new List<PC_PicklistFieldManager.PicklistEntryWrapper>();
            finalSetEventTypeList.add(firstEntryWrapperWithBlankVal);
            finalSetEventTypeList.addAll(PC_PicklistFieldManager.getPicklistEntryWrappers(PC_SupportPlan__c.PC_TriggerEventType__c));
            picklistEntryMap.put('eventTypeList', finalSetEventTypeList);
            List<PC_PicklistFieldManager.PicklistEntryWrapper> finalSetObjectList = new List<PC_PicklistFieldManager.PicklistEntryWrapper>();
            finalSetObjectList.add(firstEntryWrapperWithBlankVal);
            finalSetObjectList.addAll(getTriggerEventObject());
            picklistEntryMap.put('eventObjectList',finalSetObjectList);
        return picklistEntryMap;
    }
    public inherited sharing class SupportPlan {
        @AuraEnabled public BaseSupportPlan baseSupportPlan {get;set;}
        @AuraEnabled public ConstantsFieldsWrapper constantsWrapper {get;set;}
        @AuraEnabled public Map<String, List<PC_PicklistFieldManager.PicklistEntryWrapper>> picklistEntryWrapperMap {get;set;}
        @AuraEnabled public FieldLabelsWrapper fieldLabelsWrapper {get;set;}
        public SupportPlan(){ }
    }
    public inherited sharing class BaseSupportPlan {
        @AuraEnabled public STRING description {get;set;}
        @AuraEnabled public STRING spname {get;set;}
        @AuraEnabled public STRING conditionbehavior {get;set;}
        @AuraEnabled public STRING startcondition  {get;set;}
        @AuraEnabled public STRING conditionoption  {get;set;}
        @AuraEnabled public STRING triggerEventObject  {get;set;}
        @AuraEnabled public STRING triggerEventType  {get;set;}
        @AuraEnabled public STRING triggerEventCondition {get;set;}
        @AuraEnabled public STRING conditionallogic {get; set;}
        @AuraEnabled public STRING existingSupportPlanLabel {get;set;}
        @AuraEnabled public BOOLEAN isactive {get;set;}
        @AuraEnabled public String supportPlanBehavior {get;set;}

        public BaseSupportPlan(){ }

        public BaseSupportPlan(PC_SupportPlan__c supportPlanObj){
            spname              =   supportPlanObj.Name;
            if(supportPlanObj.Name!=null && !String.isBlank(supportPlanObj.Name)){
                existingSupportPlanLabel=Label.PC_Edit_Button+' '+supportPlanObj.Name;
            }
            description         =   supportPlanObj.PC_Description__c;
            conditionbehavior   =   supportPlanObj.PC_ConditionBehavior__c;
            startcondition      =   supportPlanObj.PC_StartCondition__c;
            conditionoption     =   supportPlanObj.PC_Condition_Option__c;
            conditionallogic    =   supportPlanObj.PC_Conditional_Logic__c;
            triggerEventObject  =   supportPlanObj.PC_TriggerEventObject__c;
            triggerEventType    =   supportPlanObj.PC_TriggerEventType__c;
            triggerEventCondition =  supportPlanObj.PC_TriggerEventCondition__c;
            isactive            =   supportPlanObj.PC_IsActive__c;
            supportPlanBehavior =   supportPlanObj.PC_SupportPlan_Behavior__c;
            if(String.isBlank(supportPlanBehavior)){
                supportPlanBehavior = String.valueOf(PC_Constants.SupportPlanBehaviour.RunEveryTimeRuleMatches);
            }
        }
    }
    /*********************************************************************************
    Method Name    : getsObjectValidate
    Author         : Tushar Arora
    Description    : This method  displays column headers for referral list view
    Return Type    : void
    Parameter      : void
    *********************************************************************************/
    private static void getsObjectValidated(String sObjectName){
        List<String> strList = new List<String>();
        strList.add(sObjectName);
        try{
            List<Schema.DescribeSobjectResult> results = Schema.describeSObjects(strList);
        }catch(Exception ex){
            if(ex != null ){
                throw new CustomSupportPlanSObjectException('Object: '+ sObjectName +' Configured in Trigger Handler Register with ClassName ' + PC_Constants.SUPPORTPLAN_INITIATIONHANDLER_CLASSNAME +
                        ' is not a valid sObject. ');
            }
        }
    }
    /*********************************************************************************
    Method Name    : processLabelChangeInJSONString
    Author         : Tushar Arora
    Description    : This method will process conditional builder JSON
    Return Type    : String
    Parameter      : strJSON , sObjectName
    *********************************************************************************/
    private static String processLabelChangeInJSONString (String strJSON, String sObjectName){
        String returnJSONString = '';
        PC_ConditionBuilder supportPlanCondBuilder = new PC_ConditionBuilder();
        supportPlanCondBuilder = (PC_ConditionBuilder) System.JSON.deserialize(strJSON, PC_ConditionBuilder.class);
        Map<String,String> fieldLabelToFieldAPIMap= new Map<String,String>();
        fieldLabelToFieldAPIMap = getsObjectFieldLabelAPIMap(sObjectName);
        String fieldLabel = '';
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
    /**
     * Define custom exceptions
     * @author Tushar Arora
     */
    public inherited sharing class CustomSupportPlanSObjectException extends Exception {}
}