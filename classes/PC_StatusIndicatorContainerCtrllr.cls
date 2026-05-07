/*Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer                  Date                   Description
Vijay Kashikar          21-Jan-2021              [PC-7102] Added sharing clause
****************************************************************************************************************/
/**
 * Created by vkashikar on 8/1/2018.
 */

public with sharing class PC_StatusIndicatorContainerCtrllr {
    public inherited sharing class InitData {
        @AuraEnabled public List<CustomMetadata> intelligentIndicators;

        public InitData() {
            intelligentIndicators = new List<CustomMetadata>();
        }
    }
    public inherited sharing class CustomMetaData /*implements Comparable*/{
        @AuraEnabled public String developerName;
        @AuraEnabled public String componentAPIName;
        @AuraEnabled public String title;
        @AuraEnabled public String content;
        @AuraEnabled public Integer order;
        @AuraEnabled public String programStatus;
        @AuraEnabled public String attributes;
        @AuraEnabled public Boolean isDebugMode;
        @AuraEnabled public String contentComponent;
        @AuraEnabled public String contentComponentAttributes;
    }

    @AuraEnabled
    public static InitData getInitData(String recordId) {
        InitData initData = new InitData();

        try {
            Case c = getCase(recordId);
            if(c != null) {

                initData.intelligentIndicators = getIntelligentIndicators(c);
                return initData;
            }
        }
        catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return initData;
    }
    public static Case getCase(String recordId) {
        List<String> fields = new List<String>();
        fields.add('Id');
        fields.add('Status');
        fields.add(PC_Constants.getQualifiedAPIName('PC_Engagement_Program__r') + '.' + PC_Constants.getQualifiedAPIName('PC_Program_Code__c'));
        PC_Database.assertAccess(PC_Constants.PC_CASE, PC_Database.Operation.Reading, fields);

        List<Case> cases = [
                Select
                        Id, Status, PC_Engagement_Program__r.PC_Program_Code__c,
                        RecordTypeId, RecordType.DeveloperName, RecordType.NamespacePrefix
                FROM Case
                WHERE id = :recordId
        ];

        if(cases != null && !cases.isEmpty()) {
            return cases[0];
        }
        return  null;
    }
    public static List<CustomMetadata> getIntelligentIndicators(Case c) {
        String programStatus = c.Status;
        String recordTypeDevName = c.RecordType.DeveloperName;
        String recordTypeNamespace = c.RecordType.NamespacePrefix;
        String engagementProgramCode = c.PC_Engagement_Program__r.PC_Program_Code__c;
        system.debug(programStatus + '-' + recordTypeDevName + '-' + recordTypeNamespace + '-' + engagementProgramCode);

        system.debug('reading metadata');
        List<PC_Program_Status_Indicator__mdt> validProgramStatusIndicators = new List<PC_Program_Status_Indicator__mdt>();
        String indicatorRecordType;
        String indicatorRecordTypeNamespace;

        // First, get all the valid indicators that have to be shown on case with specific status and record types
        for(PC_Program_Status_Indicator__mdt indicator : [
                SELECT DeveloperName,
                        PC_Status_Indicator__r.PC_Title__c, PC_Status_Indicator__r.PC_Content__c,
                        PC_Status_Indicator__r.PC_Order__c, PC_Program_Status__r.PC_Case_Status__c,
                        PC_Status_Indicator__r.PC_Component_Attributes__c,
                        PC_Status_Indicator__r.PC_Indicator_API_Name__c,
                        PC_Program_Status__c, PC_Program_Status__r.PC_RecordType__c,
                        PC_Program_Status__r.PC_RecordType_Namespaceprefix__c,
                        PC_Status_Indicator__r.PC_Content_Component__c, PC_Status_Indicator__r.PC_Content_Component_Attributes__c
                FROM PC_Program_Status_Indicator__mdt
                WHERE
                PC_Program_Status__r.PC_Case_Status__c = :programStatus
                AND
                PC_Program_Status__r.PC_Program_Code__c = :engagementProgramCode
                AND
                PC_Program_Status__r.PC_Active__c = TRUE
                AND
                PC_Status_Indicator__r.PC_Active__c = TRUE
                AND
                PC_Active__c = TRUE
        ])
        {
            indicatorRecordType = indicator.PC_Program_Status__r.PC_RecordType__c;
            indicatorRecordTypeNamespace = indicator.PC_Program_Status__r.PC_RecordType_Namespaceprefix__c;
            if (String.isNotBlank(indicatorRecordType) && indicatorRecordType.toLowerCase() == recordTypeDevName.toLowerCase()) {
                if (
                    (String.isBlank(recordTypeNamespace) && String.isBlank(indicatorRecordTypeNamespace))
                    ||
                    (String.isNotBlank(indicatorRecordTypeNamespace)
                            && indicatorRecordTypeNamespace.toLowerCase() == recordTypeNamespace.toLowerCase())
                    )
                {
                    validProgramStatusIndicators.add(indicator);
                }
            }
        }
        // Second, get indicators that have to be shown on all the cases.
        for(PC_Program_Status_Indicator__mdt indicator : [
                SELECT DeveloperName,
                        PC_Status_Indicator__r.PC_Title__c, PC_Status_Indicator__r.PC_Content__c,
                        PC_Status_Indicator__r.PC_Order__c, PC_Program_Status__r.PC_Case_Status__c,
                        PC_Status_Indicator__r.PC_Component_Attributes__c, PC_Status_Indicator__r.PC_Indicator_API_Name__c,
                        PC_Program_Status__c, PC_Program_Status__r.PC_RecordType__c,
                        PC_Program_Status__r.PC_RecordType_Namespaceprefix__c,
                        PC_Status_Indicator__r.PC_Content_Component__c, PC_Status_Indicator__r.PC_Content_Component_Attributes__c
                FROM PC_Program_Status_Indicator__mdt
                WHERE
                PC_Status_Indicator__r.PC_Active__c = TRUE AND PC_Program_Status__c = NULL AND
                PC_Active__c = TRUE
        ]) {
            validProgramStatusIndicators.add(indicator);
        }
        system.debug('reading metadata done');
        return convertIntelligentIndicators(validProgramStatusIndicators);
    }
    public static List<CustomMetadata> convertIntelligentIndicators(List<PC_Program_Status_Indicator__mdt> programStatusIndicators) {
        List<CustomMetadata> mdtList = new List<CustomMetaData>();
        CustomMetadata mdt;
        if(programStatusIndicators != null) {
            for(PC_Program_Status_Indicator__mdt i : programStatusIndicators) {
                mdt = new CustomMetaData();
                mdt.developerName = i.DeveloperName;
                mdt.componentAPIName = i.PC_Status_Indicator__r.PC_Indicator_API_Name__c;
                mdt.title = i.PC_Status_Indicator__r.PC_Title__c;
                mdt.content = i.PC_Status_Indicator__r.PC_Content__c;
                mdt.order = Integer.valueOf(i.PC_Status_Indicator__r.PC_Order__c);
                mdt.programStatus = i.PC_Program_Status__r.PC_Case_Status__c;
                mdt.attributes = i.PC_Status_Indicator__r.PC_Component_Attributes__c;
                mdt.contentComponent = i.PC_Status_Indicator__r.PC_Content_Component__c;
                mdt.contentComponentAttributes = i.PC_Status_Indicator__r.PC_Content_Component_Attributes__c;
                mdtList.add(mdt);
            }
        }
        return mdtList;
    }

}