/**
 * Created by mapatil on 8/7/2017.
 */
/*********************************************************************************
Class Name      : PC_ActionCenterLightningController
Description        : <Purpose of the class and do’s and don’t’s, if any. Components using this class >
Created By        : mapatil
Created Date     : 8/7/2017
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------           
mapatil                   07-Aug-17                  Initial Version
Tejas Patel               21-Sep-17                  [PC-2202] caseDetails and taskRecordTypes new variables added for Dynamic Record Type ID
Shabda Bhujad			  02-Oct-17					 [PC-2336] Added a flag to indicate if metadata settings exist for the selected case recordtype
Tejas Patel	              10-Nov-17					 Use SOQL as Conditional argument in for loop "PC_SYSTEM.getAllRecordType('Task')"
Vijay Kashikar            27-May-18                 [PC-3183] Provisioned for reading component attributes
Mayuresh Patil            13-Dec-18                 [PC-4126] Ability to add action center to custom record types
Tejas Patel               17-Sep-19                 [PC-5287] Ease of setting up Action Center Icons, All value added to PC_Case_Record_Type__c,
                                                    PC_Engagement_Program_Code__c and PC_Other_Case_Record_Type__c can be set to All
Haritha Reddy             10-Dec-19                 [PC-5791] Removed getCaseDetails method which is not in use
Vijay Kashikar            21-Jan-21                 [PC-7102] Added FLS Checks
Vijay Kashikar            21-Jan-21                 [PC-7102] Added sharing clause
*********************************************************************************/

public with sharing class PC_ActionCenterLightningController {

    @AuraEnabled
    public static ActionCenterWrapper setupActionCenter(Id caseId) {
        ActionCenterWrapper actionCenterWrapper = new ActionCenterWrapper();
        try {
            Case selectedCase = getSelectedCase(caseId);
            for(RecordType rt : PC_SYSTEM.getAllRecordType(PC_Constants.PC_TASK)){
                actionCenterWrapper.taskRecordTypes.add((RecordType) rt);
            }
            List<PC_Action_Center_Setting__mdt> lstAllActions = new List<PC_Action_Center_Setting__mdt> ();

            List<PC_Action_Center_Setting__mdt> allActions = [Select Id, PC_Action_Component__c, PC_Action_Icon__c, PC_Action_Label__c, PC_Action_Ordinal__c, PC_Action_Type__c,PC_Case_Record_Type__c, PC_Action_Component_Attributes__c,
                    PC_Engagement_Program_Code__c, PC_Other_Case_Record_Type__c, PC_Case_Recordtype_Namespaceprefix__c
                                                        FROM PC_Action_Center_Setting__mdt
                                                        WHERE   PC_Active__c = true
                                                        ORDER BY PC_Action_Type__c, PC_Action_Ordinal__c];

            if(Test.isRunningTest()){
                allActions = PC_Test_ActionCenterLightningController.createActionCenterSetting();
            }

            for(PC_Action_Center_Setting__mdt a : allActions){
                if(a.PC_Case_Record_Type__c.toLowerCase() == PC_Constants.PC_ALL.toLowerCase() && a.PC_Engagement_Program_Code__c.toLowerCase() == PC_Constants.PC_ALL.toLowerCase()){
                    lstAllActions.add(a);
                }else if(a.PC_Case_Record_Type__c.toLowerCase() == PC_Constants.PC_ALL.toLowerCase() && a.PC_Engagement_Program_Code__c.toLowerCase() != PC_Constants.PC_ALL.toLowerCase()){
                    if(a.PC_Engagement_Program_Code__c == selectedCase.PC_Engagement_Program__r.PC_Program_Code__c){
                        lstAllActions.add(a);
                    }
                }else if(a.PC_Case_Record_Type__c.toLowerCase() == PC_Constants.CASE_OTHER_RECORD_TYPE.toLowerCase()){
                    if(a.PC_Other_Case_Record_Type__c.toLowerCase() == PC_Constants.PC_ALL.toLowerCase() && a.PC_Engagement_Program_Code__c.toLowerCase() == PC_Constants.PC_ALL.toLowerCase()){
                        lstAllActions.add(a);
                    }else if(a.PC_Other_Case_Record_Type__c.toLowerCase() == PC_Constants.PC_ALL.toLowerCase() && a.PC_Engagement_Program_Code__c.toLowerCase() != PC_Constants.PC_ALL.toLowerCase()){
                        if(a.PC_Engagement_Program_Code__c == selectedCase.PC_Engagement_Program__r.PC_Program_Code__c){
                            lstAllActions.add(a);
                        }
                    }else if(a.PC_Other_Case_Record_Type__c.toLowerCase() != PC_Constants.PC_ALL.toLowerCase() && a.PC_Engagement_Program_Code__c.toLowerCase() == PC_Constants.PC_ALL.toLowerCase()){
                        if(a.PC_Other_Case_Record_Type__c == selectedCase.RecordType.DeveloperName && a.PC_Case_Recordtype_Namespaceprefix__c == selectedCase.RecordType.NamespacePrefix){
                            lstAllActions.add(a);
                        }
                    }else if(a.PC_Other_Case_Record_Type__c.toLowerCase() != PC_Constants.PC_ALL.toLowerCase() && a.PC_Engagement_Program_Code__c.toLowerCase() != PC_Constants.PC_ALL.toLowerCase()){
                        if(a.PC_Other_Case_Record_Type__c == selectedCase.RecordType.DeveloperName && a.PC_Case_Recordtype_Namespaceprefix__c == selectedCase.RecordType.NamespacePrefix
                                && a.PC_Engagement_Program_Code__c == selectedCase.PC_Engagement_Program__r.PC_Program_Code__c){
                            lstAllActions.add(a);
                        }
                    }
                }else if(a.PC_Case_Record_Type__c.toLowerCase() != PC_Constants.PC_ALL.toLowerCase() && a.PC_Engagement_Program_Code__c.toLowerCase() == PC_Constants.PC_ALL.toLowerCase()){
                    if(a.PC_Case_Record_Type__c == selectedCase.RecordType.DeveloperName && a.PC_Case_Recordtype_Namespaceprefix__c == selectedCase.RecordType.NamespacePrefix){
                        lstAllActions.add(a);
                    }
                }else if(a.PC_Case_Record_Type__c.toLowerCase() != PC_Constants.PC_ALL.toLowerCase() && a.PC_Engagement_Program_Code__c.toLowerCase() != PC_Constants.PC_ALL.toLowerCase()){
                    if(a.PC_Case_Record_Type__c == selectedCase.RecordType.DeveloperName && a.PC_Case_Recordtype_Namespaceprefix__c == selectedCase.RecordType.NamespacePrefix &&
                            a.PC_Engagement_Program_Code__c == selectedCase.PC_Engagement_Program__r.PC_Program_Code__c){
                        lstAllActions.add(a);
                    }
                }
            }

            if (!lstAllActions.isEmpty()) {
                actionCenterWrapper.actionCenterConfigExists = TRUE;
                for (PC_Action_Center_Setting__mdt actionMetadata : lstAllActions){
                    if (actionMetadata.PC_Action_Type__C == PC_Constants.ACTION_METADATA_COMMUNICATIONS) {
                        actionCenterWrapper.lstCommunicationsMetadata.add(new ActionTypeWrapper(actionMetadata));
                    } else if (actionMetadata.PC_Action_Type__C == PC_Constants.ACTION_METADATA_WORKFLOWS){
                        actionCenterWrapper.lstWorkflowsMetadata.add(new ActionTypeWrapper(actionMetadata));
                    } else if (actionMetadata.PC_Action_Type__C == PC_Constants.ACTION_METADATA_TOOLS){
                        actionCenterWrapper.lstToolsMetadata.add(new ActionTypeWrapper(actionMetadata));
                    }
                }
                actionCenterWrapper.caseDetails.add((Case) selectedCase);
            }
        } catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return actionCenterWrapper;
    }

    /**
     * Returns the case for the case ID provided.
     *
     * @param   CaseId    The Id of the enrollment case to retrieve.
     */
    private static Case getSelectedCase(Id caseId) {
    	/*
        * FLS Check for Case
        */
        List<String> fields = new List<String>{'CaseNumber', 'Status', 'ClosedDate' , 'AccountId', PC_Constants.getQualifiedAPIName('PC_Document__c'),
                PC_Constants.getQualifiedAPIName('PC_Program__c'), PC_Constants.getQualifiedAPIName('PC_EnrollmentWizardState__c'),
                PC_Constants.getQualifiedAPIName('PC_ActiveApplicant__c'), PC_Constants.getQualifiedAPIName('PC_Engagement_Program__c')};
        PC_Database.assertAccess(PC_Constants.PC_CASE, PC_Database.Operation.Reading, fields);
        /*
        * FLS Check for PC_Engagement_Program__c
        */
        fields = new List<String>{PC_Constants.getQualifiedAPIName('PC_Program_Code__c'), PC_Constants.getQualifiedAPIName('PC_Manufacturer__c')};
        PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Engagement_Program__c'), PC_Database.Operation.Reading, fields);

        List<String> caseFields = new List<String>();
        caseFields.add('AccountId');
        caseFields.add('Type');
        PC_Database.assertAccess(PC_Constants.PC_CASE, PC_Database.Operation.Reading, caseFields);

        return [SELECT Id, AccountId,PC_Program__c, Type, RecordType.DeveloperName ,RecordType.NamespacePrefix, PC_Engagement_Program__r.Name, PC_Engagement_Program__r.PC_Program_Code__c, PC_Engagement_Program__r.PC_Manufacturer__c
        FROM Case
        WHERE Id =: caseId LIMIT 1];
    }

    /**
     * Wrapper for the action center setup. Includes all information needed to initialize the
     * action center.
     */
    public inherited sharing class ActionTypeWrapper {
        @AuraEnabled public String actionComponent {get; set;}
        @AuraEnabled public String actionComponentAttributes {get; set;}
        @AuraEnabled public String actionIcon {get; set;}
        @AuraEnabled public String actionLabel {get; set;}
        @AuraEnabled public Decimal actionOrdinal {get; set;}
        @AuraEnabled public String actionType {get; set;}

        public ActionTypeWrapper(PC_Action_Center_Setting__mdt a) {
            actionComponent = a.PC_Action_Component__c;
            actionIcon = a.PC_Action_Icon__c;
            actionLabel = a.PC_Action_Label__c;
            actionOrdinal = a.PC_Action_Ordinal__c;
            actionType = a.PC_Action_Type__c;
            actionComponentAttributes = a.PC_Action_Component_Attributes__c;
        }
    }

    /**
     * Wrapper for the action center setup. Includes all information needed to initialize the
     * action center.
     */
    public inherited sharing class ActionCenterWrapper {
        @AuraEnabled public List<ActionTypeWrapper> lstCommunicationsMetadata {get; set;}
        @AuraEnabled public List<ActionTypeWrapper> lstWorkflowsMetadata {get; set;}
        @AuraEnabled public List<ActionTypeWrapper> lstToolsMetadata {get; set;}
        @AuraEnabled public LIST<Case> caseDetails {get; set;}
        @AuraEnabled public LIST<RecordType> taskRecordTypes {get; set;}
        @AuraEnabled public boolean actionCenterConfigExists {get; set;}

        public ActionCenterWrapper() {
            actionCenterConfigExists = FALSE;
            lstCommunicationsMetadata = new List<ActionTypeWrapper>();
            lstWorkflowsMetadata = new List<ActionTypeWrapper>();
            lstToolsMetadata = new List<ActionTypeWrapper>();
            caseDetails      = new LIST<Case>();
            taskRecordTypes      = new LIST<RecordType>();
        }
    }

}