/*********************************************************************************
Class Name      : PC_LaunchTaskActionComponent
Description     : Methods for Guided Task Management
Created By      : Vijay Kashikar
Created Date    : 09-Jul-20
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   	Description
-----------------------------------------------------------------------------------
Vijay Kashikar            09-Jul-2020              Initial Version
Satheesh Kumar            11-Nov-2020              [PC-6943] Added documentId property to TaskActionDetails class
Vijay Kashikar            21-Jan-21                [PC-7102] Added FLS Checks
Vijay Kashikar            21-Jan-2021              [PC-7102] Added sharing clause
Haritha Reddy             10-Oct-2022              [PC-9224] Added a condition to handle scenario when org namespace is empty
*********************************************************************************/

public with sharing class PC_LaunchTaskActionComponent {
    public inherited sharing class TaskActionDetails {
        @AuraEnabled public PC_HomeActivitiesController.TaskActionComponent actionComponent {get;set;}
        @AuraEnabled public String relatedToObject {get;set;}
        @AuraEnabled public String relatedToId {get;set;}
        @AuraEnabled public String documentId {get;set;}
        private String relatedToId_RecordTypeDevName {get;set;}
        private String relatedToId_RecordTypeNamespace {get;set;}
        private String relatedToProgramCode {get;set;}
        @AuraEnabled public String actionCenterAttributes {get;set;}

        public TaskActionDetails() {
            actionComponent = new PC_HomeActivitiesController.TaskActionComponent();
        }
    }

    @AuraEnabled
    public static TaskActionDetails getActionComponent(Id taskRecordId) {
        try {
            List<String> fields = new List<String>();
            fields.add(PC_Constants.getQualifiedAPIName('PC_ActionComponent__c'));
            fields.add('WhatId');
            fields.add(PC_Constants.getQualifiedAPIName('PC_Document__c'));
            PC_Database.assertAccess(PC_Constants.PC_TASK,PC_Database.Operation.Reading, fields);

            Task currentTask = [SELECT Id, WhatId, PC_Document__c, PC_ActionComponent__c FROM Task WHERE Id = :taskRecordId];

            if(currentTask != null) {
                List<PC_HomeActivitiesController.PicklistEntry> taskActionComponents =
                        PC_HomeActivitiesController.getActionComponentPicklistValues();
                TaskActionDetails actionDetails = new TaskActionDetails();
                if(String.isNotBlank(currentTask.PC_ActionComponent__c)) {
                    actionDetails.actionComponent = getActionComponentDetails(currentTask.PC_ActionComponent__c, taskActionComponents);
                    setRelatedInfo(actionDetails, currentTask);
                    actionDetails.actionCenterAttributes = getComponentAttributes(actionDetails);
                    return actionDetails;
                }
                else {
                    return null;
                }
            }
            else {
                return null;
            }
        }
        catch(Exception ex) {
            PC_Utility.createExceptionLog(ex);
            throw new AuraHandledException(ex.getMessage());
        }
    }
    private static void setRelatedInfo(TaskActionDetails actionDetails, Task currentTask) {
        if(currentTask.WhatId != null) {
            actionDetails.relatedToId = currentTask.WhatId;
            actionDetails.relatedToObject = currentTask.WhatId.getSObjectType().getDescribe().getName();
            if(actionDetails.relatedToObject.toLowerCase() == 'case') {
                List<String> caseFields = new List<String>();
                caseFields.add(PC_Constants.getQualifiedAPIName('PC_Engagement_Program__r') + '.' +
                    PC_Constants.getQualifiedAPIName('PC_Program_Code__c'));
                PC_Database.assertAccess(PC_Constants.PC_CASE, PC_Database.Operation.Reading, caseFields);
                Case relatedCase = [
                        SELECT ID, PC_Engagement_Program__r.PC_Program_Code__c, RecordType.DeveloperName, RecordType.NamespacePrefix
                        FROM Case
                        WHERE ID = :actionDetails.relatedToId
                ];
                actionDetails.relatedToProgramCode = relatedCase.PC_Engagement_Program__r.PC_Program_Code__c;
                actionDetails.relatedToId_RecordTypeDevName = relatedCase.RecordType.DeveloperName;
                actionDetails.relatedToId_RecordTypeNamespace = relatedCase.RecordType.NamespacePrefix;
            }
        }
        if(currentTask.PC_Document__c != null){
            actionDetails.documentId = currentTask.PC_Document__c;
        }
    }
    private static PC_HomeActivitiesController.TaskActionComponent
        getActionComponentDetails(String actionCmpAPIName, List<PC_HomeActivitiesController.PicklistEntry> taskActionComponents) {
        if(String.isNotBlank(actionCmpAPIName)) {
            actionCmpAPIName = actionCmpAPIName.toLowerCase();
            for (PC_HomeActivitiesController.PicklistEntry picklistEntry : taskActionComponents) {
                if (picklistEntry.value.toLowerCase() == actionCmpAPIName) {
                    PC_HomeActivitiesController.TaskActionComponent actionCmpDetails = new PC_HomeActivitiesController.TaskActionComponent();
                    actionCmpDetails.label = picklistEntry.label;
                    actionCmpDetails.apiName = replaceNamespace(picklistEntry.value);
                    return actionCmpDetails;
                }
            }
        }
        return null;
    }
    private static String replaceNamespace(String apiName) {
        if(String.isNotBlank(apiName)) {
            apiName = apiName.toLowerCase();
            String pcNamespace = PC_Constants.OrgNamespace.toLowerCase();
            if(String.isBlank(pcNamespace) && apiName.startsWithIgnoreCase('patientconnect__')) {
                apiName = apiName.replace('patientconnect__', 'c:');
            }
            else if(String.isNotBlank(pcNamespace) && apiName.startsWithIgnoreCase('patientconnect__')) {
                apiName = apiName.replace('patientconnect__', pcNamespace + ':');
            }
            else if(apiName.startsWithIgnoreCase('c__')) {
                apiName = apiName.replace('c__', 'c:');
            }
            else if(!apiName.contains('__')) {
                apiName = 'c:'+ apiName;
            }
            else {
                apiName = apiName.replace('__', ':');
            }
        }
        return apiName;
    }
    private static String getComponentAttributes(TaskActionDetails actionDetails) {
        String componentAttributes;
        if(String.isNotBlank(actionDetails.actionComponent.apiName) && String.isNotBlank(actionDetails.relatedToProgramCode)) {
            List<PC_Action_Center_Setting__mdt> allActionCenters = [
                    SELECT ID, PC_Action_Component_Attributes__c
                    FROM PC_Action_Center_Setting__mdt
                    WHERE PC_Active__c = true
                    AND PC_Action_Component__c = :actionDetails.actionComponent.apiName
                    AND
                    (PC_Engagement_Program_Code__c = :actionDetails.relatedToProgramCode OR
                    PC_Engagement_Program_Code__c = 'All')
                    AND PC_Case_Record_Type__c = 'All'

            ];
            List<PC_Action_Center_Setting__mdt> pcOtherActionCenters = [
                    SELECT ID, PC_Action_Component_Attributes__c
                    FROM PC_Action_Center_Setting__mdt
                    WHERE PC_Active__c = true
                    AND PC_Action_Component__c = :actionDetails.actionComponent.apiName
                    AND (PC_Engagement_Program_Code__c = :actionDetails.relatedToProgramCode OR
                    PC_Engagement_Program_Code__c = 'All')
                    AND
                    (PC_Case_Record_Type__c != 'Other' AND PC_Case_Record_Type__c != 'All' AND
                    PC_Case_Record_Type__c = :actionDetails.relatedToId_RecordTypeDevName)
            ];
            List<PC_Action_Center_Setting__mdt> nonPCOtherActionCenters = [
                    SELECT ID, PC_Action_Component_Attributes__c
                    FROM PC_Action_Center_Setting__mdt
                    WHERE PC_Active__c = true AND PC_Action_Component__c = :actionDetails.actionComponent.apiName
                    AND (PC_Engagement_Program_Code__c = :actionDetails.relatedToProgramCode OR
                    PC_Engagement_Program_Code__c = 'All')
                    AND
                    (PC_Case_Record_Type__c = 'Other' AND
                    PC_Other_Case_Record_Type__c = :actionDetails.relatedToId_RecordTypeDevName AND
                    PC_Case_Recordtype_Namespaceprefix__c = :actionDetails.relatedToId_RecordTypeNamespace)
            ];
            // Multiple queries written to avoid SOQL error - Disjunction not supported.

            List<PC_Action_Center_Setting__mdt> actionCenters = new List<PC_Action_Center_Setting__mdt>();
            actionCenters.addAll(allActionCenters);
            actionCenters.addAll(pcOtherActionCenters);
            actionCenters.addAll(nonPCOtherActionCenters);

            if(actionCenters != null && actionCenters.size() == 1) {
                componentAttributes = actionCenters[0].PC_Action_Component_Attributes__c;
            }
            else if (actionCenters != null && actionCenters.size() > 1) {
                ActionComponentException ex = new ActionComponentException();
                String exceptionMessage = Label.PC_TaskActionMultipleConfigError;
                List<String> arguments = new List<String>();
                arguments.add(actionDetails.actionComponent.apiName);
                arguments.add(actionDetails.relatedToProgramCode);
                exceptionMessage = String.format(exceptionMessage, arguments);
                ex.setMessage(exceptionMessage);
                throw ex;
            }
        }
        if(String.isBlank(componentAttributes)) {
            componentAttributes = '{}';
        }
        return componentAttributes;
    }
    public inherited sharing class ActionComponentException extends Exception {

    }
}