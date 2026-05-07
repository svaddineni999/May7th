/**
 * Created by vkashikar on 7/7/2021.
 */

public with sharing class PC_ShowSurveyInvitationResult {
    @auraenabled
    public static SurveyInvitationResult getInvitationResult(String engagementProgramId, String accountId, String caseId, String workflowContext) {
        SurveyInvitationResult result = new SurveyInvitationResult();
        try {
            if(String.isBlank(workflowContext)) {
                throw new PC_ShowSurveyInvitationResultException('Cannot continue without workflowSurveyContext URL param');
                // no need of label as this will come up only when the cmp is added on a wrong flexipage.
            }
            if (String.isNotBlank(caseId) && String.isBlank(accountId)) {
                Case c = [SELECT AccountId FROM Case WHERE Id = :caseId WITH SECURITY_ENFORCED];
                accountId = c.AccountId;
            }
            List<PC_SurveyInvitationRelatedObjects__c> relatedObjects = getResultCases(engagementProgramId, accountId, caseId, workflowContext);
            List<Column> columns = getDisplayColumns();

            result = new SurveyInvitationResult();
            result.columns = columns;
            result.rows = convertSobjects(relatedObjects);

        }
        catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return result;
    }
    private static List<PC_SurveyInvitationRelatedObjects__c> getResultCases(String engagementProgramId, String accountId, String caseId, String workflowContext) {
        String whereClause = '';
        List<PC_SurveyInvitationRelatedObjects__c> relatedObjects ;
        // FLS check not needed as we are using WITH SECURITY_ENFORCED
        system.debug('engagementProgramId -> ' + engagementProgramId);
        system.debug('accountId -> ' + accountId);
        system.debug('caseId -> ' + caseId);
        relatedObjects = [
                SELECT Id, PC_Account__c, PC_Case__c, PC_EngagementProgram__c,
                        PC_ResultingCase__c, LastModifiedDate,
                        PC_ResultingCase__r.CaseNumber, PC_ResultingCase__r.Subject,
                        PC_ResultingCase__r.CreatedDate, PC_ResultingCase__r.RecordType.Name
                FROM PC_SurveyInvitationRelatedObjects__c
                WHERE
                PC_Account__c = :accountId
                AND PC_EngagementProgram__c = :engagementProgramId
                AND PC_Case__c = :caseId
                AND PC_SurveyCategory__c =:workflowContext
                AND PC_ResultingCase__c != NULL
                WITH SECURITY_ENFORCED ORDER BY LastModifiedDate DESC LIMIT 10
        ];
        return relatedObjects;

    }
    private static List<Column> getDisplayColumns() {
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();

        SObjectType surveyInvRelatedObjectType = schemaMap.get(PC_Constants.PC_SURVEY_INVITATION_RELATED_OBJECT);
        Map<String, Schema.SObjectField> surveyInvRelatedObjectFieldsByStrings = surveyInvRelatedObjectType.getDescribe().fields.getMap();

        /*SObjectType engProgObjectType = schemaMap.get(PC_ENGAGEMENT_PROGRAM);
        Map<String, Schema.SObjectField> engProgobjectFieldsByStrings = engProgObjectType.getDescribe().fields.getMap();
        */

        SObjectType caseObjectType = schemaMap.get('Case');
        Map<String, Schema.SObjectField> caseFieldsByStrings = caseObjectType.getDescribe().fields.getMap();

        List<Column> columns = new List<Column>();

        Column caseNameColumn = new Column();
        /*caseNameColumn.label = surveyInvRelatedObjectType.getDescribe().getLabel() + ' ' + caseFieldsByStrings.get('Subject').getDescribe().label;
        caseNameColumn.type = caseFieldsByStrings.get('Subject').getDescribe().type.name();
        caseNameColumn.fieldName = 'pccore__PC_ResultingCase__r.Subject';
        columns.add(caseNameColumn);*/

        /*Column idColumn = new Column();
        idColumn.label = surveyInvRelatedObjectFieldsByStrings.get('Id').getDescribe().label;
        idColumn.type = surveyInvRelatedObjectFieldsByStrings.get('Id').getDescribe().type.name();
        idColumn.fieldName = 'Id';
        columns.add(idColumn);*/

        Column resultingCaseColumn = new Column();
        String resultingCaseFieldApiName = PC_Constants.getQualifiedAPIName('PC_ResultingCase__c');
        resultingCaseColumn.label = surveyInvRelatedObjectFieldsByStrings.get(resultingCaseFieldApiName).getDescribe().label;
        //resultingCaseColumn.type = surveyInvRelatedObjectFieldsByStrings.get(resultingCaseFieldApiName).getDescribe().type.name();
        resultingCaseColumn.type = 'url';
        resultingCaseColumn.fieldName = 'resultCaseNumberLink';
        resultingCaseColumn.typeAttributes= JSON.deserializeUntyped('{"label": {"fieldName" : "resultCaseNumber"},"tooltip":{"fieldName" : "resultCaseSubject"}}');
        columns.add(resultingCaseColumn);

        Column lastModifieldColumn = new Column();
        lastModifieldColumn.label = surveyInvRelatedObjectFieldsByStrings.get('LastModifiedDate').getDescribe().label;
        lastModifieldColumn.type = surveyInvRelatedObjectFieldsByStrings.get('LastModifiedDate').getDescribe().type.name();
        lastModifieldColumn.fieldName = 'resultCaseCreatedDateString';
        columns.add(lastModifieldColumn);

        return columns;
    }

    public class SurveyInvitationResult {
        @auraenabled
        public List<Column> columns;
        @auraenabled
        public List<Row> rows;
    }
    public class Column {
        @auraenabled
        public String label;
        @auraenabled
        public String fieldName;
        @auraenabled
        public String type;
        @auraenabled
        public Object typeAttributes;
    }
    public class Row {
        @auraenabled
        public String resultCaseId;
        @auraenabled
        public String resultCaseSubject;
        @auraenabled
        public String resultCaseNumber;
        @auraenabled
        public String resultCaseNumberLink;
        @auraenabled
        public String resultCaseRecordType;
        @auraenabled
        public Datetime resultCaseCreatedDate;
        @auraenabled
        public String resultCaseCreatedDateString;
        @auraenabled
        public String id;

        public Row(PC_SurveyInvitationRelatedObjects__c record) {
            id = record.Id;
            resultCaseId = record.PC_ResultingCase__c;
            resultCaseNumber = record.PC_ResultingCase__r.CaseNumber;
            resultCaseSubject = record.PC_ResultingCase__r.Subject;
            resultCaseNumberLink = '/'  + record.PC_ResultingCase__c;
            resultCaseCreatedDate = record.PC_ResultingCase__r.CreatedDate;
            resultCaseRecordType = record.PC_ResultingCase__r.RecordType.Name;
            resultCaseCreatedDateString = record.PC_ResultingCase__r.CreatedDate.format();
        }
    }
    private static List<Row> convertSobjects(List<PC_SurveyInvitationRelatedObjects__c> relatedObjects) {
        List<Row> rows = new List<Row>();
        for(PC_SurveyInvitationRelatedObjects__c obj : relatedObjects) {
            Row r = new Row(obj);
            rows.add(r);
        }
        return rows;
    }
    private class PC_ShowSurveyInvitationResultException extends Exception {
    }
}