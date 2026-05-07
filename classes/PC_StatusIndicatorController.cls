/*********************************************************************************
Class Name      : PC_StatusIndicatorController
Description     : Controller for Intelligent Indicator Component
Created By      : Vijay Kashikar
Created Date    : 08-Mar-2018
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   	Description
-----------------------------------------------------------------------------------
Vijay Kashikar            08-Mar-2018              Initial Version
Satheesh Kumar            16-Sep-2020              PC-6752 - Added logic to fix indicator status translation issue
Haritha Reddy             21-Jan-2021                 [PC-7102] Force Reviewer scan issue fix. Updated Sharing declaration.
*********************************************************************************/

public with sharing class PC_StatusIndicatorController {
    public inherited sharing class InitData {
        @AuraEnabled public Attributes attributes;
        @AuraEnabled public String intelligentIndicatorStatus;
        @AuraEnabled public String intelligentIndicatorStatusIcon;
        @AuraEnabled public String intelligentIndicatorStatusIconVariant;
        @AuraEnabled public String intelligentIndicatorStatusIconSize;
        @AuraEnabled public String intelligentIndicatorStatusAltText;
        @AuraEnabled public Boolean isError = false;
        @AuraEnabled public String errorMessage = PC_Constants.EMPTY_STRING;

        public InitData() {
            attributes = new Attributes();
        }
    }

    public inherited sharing class Attributes {
        @AuraEnabled public status[] statuses;
        @AuraEnabled public Boolean isError = false;
        @AuraEnabled public String errorMessage = PC_Constants.EMPTY_STRING;
        @AuraEnabled public String statusFieldAPIName = PC_Constants.EMPTY_STRING;
        @AuraEnabled public Boolean isDebugMode = false;
        @AuraEnabled public String moreInfoComponent = PC_Constants.EMPTY_STRING;
    }
    public inherited sharing class status {
        @AuraEnabled public String icon = PC_Constants.EMPTY_STRING;
        @AuraEnabled public String name = PC_Constants.EMPTY_STRING;
        @AuraEnabled public String variant = PC_Constants.EMPTY_STRING;
        @AuraEnabled public String size = PC_Constants.EMPTY_STRING;
    }

    @AuraEnabled
    public static InitData getInitData(String caseId, String attributes) {
        InitData initData = new InitData();
        try {
            initData.attributes = convertAttributes(attributes);
            system.debug(initData);
            if (initData.attributes.isError) {
                initData.isError = true;
                initData.errorMessage = initData.attributes.errorMessage;
            } else {
                initData.intelligentIndicatorStatus = getStatus(caseId, initData.attributes.statusFieldAPIName);
                initData.intelligentIndicatorStatusIcon = getIcon(initData.attributes, initData.intelligentIndicatorStatus);
                initData.intelligentIndicatorStatusIconSize = getSize(initData.attributes, initData.intelligentIndicatorStatus);
                initData.intelligentIndicatorStatusIconVariant = getVariant(initData.attributes, initData.intelligentIndicatorStatus);
                // PC-6752 - fix for indicator status translation issue
                initData.intelligentIndicatorStatus = getTranslatedStatus(initData.attributes.statusFieldAPIName, initData.intelligentIndicatorStatus);
            }
        }
        catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return initData;
    }

    /**
    * Retrieves translated label for picklist value
    *
    * @param fieldApiName       API name of the picklist field
    * @param indicatorStatus    picklist value which needs to be translated
    * @return String            translated picklist value
    */
    public static String getTranslatedStatus(String fieldApiName, String indicatorStatus){
        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(PC_Constants.PC_CASE);
        Schema.DescribeSObjectResult sObjectResult = objectType.getDescribe();
        Map<String, Schema.SObjectField> fields = sObjectResult.fields.getMap();
        Schema.DescribeFieldResult fieldResult = fields.get(fieldApiName).getDescribe();
        return (PC_PicklistFieldManager.getPicklistLabelValue(fieldResult)).get(indicatorStatus);
    }

    public static String getIcon(Attributes attributes, String status) {
        String newStatus = PC_Constants.EMPTY_STRING;
        if(attributes != null && attributes.statuses != null) {
            for(status s : attributes.statuses) {
                newStatus = status == null ? PC_Constants.EMPTY_STRING : status;
                if(s.name != null && newStatus != null && s.name.toLowerCase() == newStatus.toLowerCase()) {
                    system.debug('status = ' + s.name);
                    return s.icon;
                }
            }
        }
        return 'action:freeze_user';
    }
    public static String getSize(Attributes attributes, String status) {
        String newStatus = PC_Constants.EMPTY_STRING;
        if(attributes != null && attributes.statuses != null) {
            for(status s : attributes.statuses) {
                newStatus = status == null ? PC_Constants.EMPTY_STRING : status;
                if(s.name != null && newStatus != null && s.name.toLowerCase() == newStatus.toLowerCase()) {
                    system.debug('size = ' + s.size);
                    return s.size;
                }
            }
        }
        return null;
    }
    public static String getVariant(Attributes attributes, String status) {
        String newStatus = PC_Constants.EMPTY_STRING;
        if(attributes != null && attributes.statuses != null) {
            for(status s : attributes.statuses) {
                newStatus = status == null ? PC_Constants.EMPTY_STRING : status;
                if(s.name != null && newStatus != null && s.name.toLowerCase() == newStatus.toLowerCase()) {
                    system.debug('variant = ' + s.variant);
                    return s.variant;
                }
            }
        }
        return null;
    }
    public static Attributes convertAttributes(String attributes) {
        Attributes attrObj = new Attributes();
        if(String.isBlank(attributes)) {
            return attrObj;
        }
        else {
            try {
                attrObj = (Attributes) JSON.deserialize(attributes, Attributes.class);
                attrObj.isError = false;
            }
            catch(Exception ex) {
                attrObj.isError = true;
                attrObj.errorMessage = ex.getMessage() + '\\n' +  ex.getStackTraceString();
            }
        }
        return attrObj;

    }
    public static String getStatus(String caseId, String fieldName) {
        if(checkIfFieldExists(fieldName)) {
            if(String.isNotBlank(caseId)){
                caseId = String.escapeSingleQuotes(caseId);
            }
            if(String.isNotBlank(fieldName)){
                fieldName = String.escapeSingleQuotes(fieldName);
            }
            String soql = ' SELECT ' + fieldName  +
                    ' FROM Case ' +
                    ' WHERE id = ' + '\'' + caseId + '\'';
            List<Case> cases = (List<Case>) Database.query(soql);
            system.debug(soql);
            if(cases != null && !cases.isEmpty()) {
                return (String) cases[0].get(fieldName);
            }
        }
        else {
            PC_Utility.throwAuraHandledException('Field not found - ' + fieldName);
        }
        return null;
    }
    public static Boolean checkIfFieldExists(String fieldName) {
        if(String.isNotBlank(fieldName)) {
            Set<String> objectFields = Schema.SObjectType.Case.fields.getMap().keySet();
            for(String x : objectFields) {
                system.debug(x);
            }
            system.debug(objectFields);
            if (objectFields.contains(fieldName.toLowerCase())) {
                return true;
            }
        }
        return false;
    }
}