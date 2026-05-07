/*********************************************************************************************************
Class Name      : PC_SurveyWorkflowController
Description     :
Created By      : Hitha Avalakki
Created Date    : May 28, 2021
Modification Log:
-----------------------------------------------------------------------------------------------------
Developer                   Date                           Description
-----------------------------------------------------------------------------------------------------
Hitha Avalakki              May 28,2021                    Initial Version
Hitha Avalakki              June 16,2021                   [PC-7459]: Code changes to fetch case record details such as engagement program for a case record.
Hitha Avalakki              June 24,2021                   [PC-7459]: Renamed wrapper class to reflect its generic for all sobjects.
                                                                      Added Id and Engagement program fields to be fetched for Account and Case records.
                                                                      Added exception to be thrown when any sobject is fetched other than account and case for pap surveys.
Hitha Avalakki              July 05,2021                   [PC-7870]: Added code to fetch only program cases for any account record for PAP workflow.
Hitha Avalakki              July 13,2021                   [PC-7917]: Added code to provide links for Case number and Engagement Program on survey workflow component.Updated the case and account fieldsets and their references to the renamed names.
Hitha Avalakki              July 21,2021                   [PC-7971]: Added code to provide links for 'Account Name' and tooltip values for 'Account Name','Case number' and 'Engagement Program' on survey workflow component.
*********************************************************************************************************/

public with sharing class PC_SurveyWorkflowController {
    private static final String ACCOUNT_SURVEY_WORKFLOW_FIELDSET = PC_Constants.getQualifiedAPIName('PC_AccountSurveyWorkflowFieldset');
    private static final String CASE_SURVEY_WORKFLOW_FIELDSET = PC_Constants.getQualifiedAPIName('PC_CaseSurveyWorkflowFieldset');

    @AuraEnabled
    public static SobjectDataWrapper getAccountCaseRecordDetails(String accountRecordId,String accountFieldSetAPIName,String caseFieldSetAPIName) {

        SobjectDataWrapper sobjectDataWrapper = new SobjectDataWrapper();
        RecordFieldDataWrapper recordFieldDataWrapper = new RecordFieldDataWrapper();

        try {

        //Fetch Account record details
        recordFieldDataWrapper = getSobjectRecordDetails(accountRecordId, PC_Constants.PC_ACCOUNT, accountFieldSetAPIName);
        sobjectDataWrapper.accountColumnsWrapper = recordFieldDataWrapper.columnsWrapper;
        sobjectDataWrapper.accountsList = recordFieldDataWrapper.objectList;

        //Fetch Case records' details
        recordFieldDataWrapper = getSobjectRecordDetails(accountRecordId, PC_Constants.PC_CASE, caseFieldSetAPIName);
        sobjectDataWrapper.caseColumnsWrapper = recordFieldDataWrapper.columnsWrapper;
        sobjectDataWrapper.casesList = recordFieldDataWrapper.objectList;
        }
        catch(Exception e){
            PC_Utility.logAndThrowException(e,Label.PC_AccountAndRelatedCasesError+accountRecordId);
        }
        return sobjectDataWrapper;
    }

    /*****************************************************************************************************
    * Author       : Hitha Avalakki
    * Parameter    : String accountRecordId,String sObjectName, String fieldSetAPIName
    * Method name  : getSobjectRecordDetails
    * Return Type  : RecordFieldDataWrapper
    * Description  : This method is used to get fieldset members of the respective sobject
    *****************************************************************************************************/
    private static RecordFieldDataWrapper getSobjectRecordDetails(String accountRecordId,String sObjectName, String fieldSetAPIName) {
        String queryString = 'SELECT ';
        String fieldsString = '';
        Set<String> fieldAPINamesSet=  new Set<String>();
        List<PC_FieldSetController.FieldSetMember> members;
        List<SObject> accountRecordList=new List<SObject>();
        List<FieldsetColumnsWrapper> fieldsetColumnsWrapperList = new List<FieldsetColumnsWrapper>();
        RecordFieldDataWrapper recordFieldDataWrapper= new RecordFieldDataWrapper();
        List<SObject> objectList= new List<SObject>();
        List<Case> caseList =  new List<Case>();
        List<Account> accountList =  new List<Account>();
        fieldAPINamesSet.add('Id');

        /*If the user has not provided any fieldset details in the design panel of Search Page then we need to provide our default fieldset name to fetch account/case details*/
        if(PC_Constants.PC_ACCOUNT.equals(sObjectName) && String.isBlank(fieldSetAPIName)){
            fieldSetAPIName = ACCOUNT_SURVEY_WORKFLOW_FIELDSET;
            fieldAPINamesSet.add('Name');
        }
        else if(PC_Constants.PC_CASE.equals(sObjectName) && String.isBlank(fieldSetAPIName)){
            fieldSetAPIName = CASE_SURVEY_WORKFLOW_FIELDSET;
            fieldAPINamesSet.add(PC_Constants.getQualifiedAPIName('PC_Engagement_Program__c'));
            fieldAPINamesSet.add('CaseNumber');
            fieldAPINamesSet.add(PC_Constants.getQualifiedAPIName('PC_EngagementProgramName__c'));
        }

        /* We make use of common private method to fetch the fieldset members for Account/Case object*/
        members = getFieldSetMembers(sObjectName, fieldSetAPIName);

        /* We a make list of field API names to be used to fetch data from Account/Case object */
        if(members!=null && !members.isEmpty()) {
            for (PC_FieldSetController.FieldSetMember member : members) {
                FieldsetColumnsWrapper accountColumn = new FieldsetColumnsWrapper(member.label,member.fieldPath,member.type);
                fieldsetColumnsWrapperList.add(accountColumn);
                fieldAPINamesSet.add(member.fieldPath);
                System.debug('type of fiedset member: '+member.Type);
            }
        }

        fieldsString = String.join(new List<String>(fieldAPINamesSet),',');

        queryString = queryString + fieldsString + ' FROM ' + sObjectName;

            if (PC_Constants.PC_ACCOUNT.equals(sObjectName)) {
                /* Fetch fieldset member values from Account record */
                queryString = queryString + ' WHERE Id= \'' + accountRecordId + '\'';
            } else if (PC_Constants.PC_CASE.equals(sObjectName)) {
                /* Fetch fieldset member values from Case record */
                queryString = queryString + ' WHERE AccountId= \'' + accountRecordId + '\''+ ' and Type =\''+PC_Constants.CASE_PROGRAM_TYPE+'\'';
            }
            else{
                SurveyException surveyException = new SurveyException();
                surveyException.setMessage(Label.PC_SurveyExecutionError);
                PC_Utility.logAndThrowException(surveyException);
            }

        objectList = PC_Database.queryWithAccess(queryString, true);

        /*[PC-7917]: Added code to provide links for Case number and Engagement Program on survey workflow component.Updated the case and account fieldsets and their references to the renamed names.*/
        if(PC_Constants.PC_CASE.equals(sObjectName)){
            caseList =(List<Case>) PC_Database.queryWithAccess(queryString, true);
        }

        if(caseList!=null && !caseList.isEmpty()){
            for(Case caseObj:caseList){
                for(FieldsetColumnsWrapper fieldsetColumn: fieldsetColumnsWrapperList){
                    if(fieldsetColumn.fieldName ==  'CaseNumber'){
                        fieldsetColumn.fieldName='caseUrl';
                        fieldsetColumn.type='url';
                        fieldsetColumn.typeAttributes= JSON.deserializeUntyped('{"label": {"fieldName" :"CaseNumber"},"tooltip":{"fieldName" : "CaseNumber"}}');
                    }
                    if(fieldsetColumn.fieldName == PC_Constants.getQualifiedAPIName('PC_Engagement_Program__c')){
                        fieldsetColumn.fieldName='engagementProgramUrl';
                        fieldsetColumn.type='url';
                        fieldsetColumn.typeAttributes= JSON.deserializeUntyped('{"label": {"fieldName" :"'+PC_Constants.getQualifiedAPIName('PC_EngagementProgramName__c')+'"},"tooltip":{"fieldName" : "'+PC_Constants.getQualifiedAPIName('PC_EngagementProgramName__c')+'"}}');
                    }
                }
            }
        }

        if(PC_Constants.PC_ACCOUNT.equals(sObjectName)){
            accountList =(List<Account>) PC_Database.queryWithAccess(queryString, true);
        }

        if(accountList!=null && !accountList.isEmpty()){
            for(Account accountObj:accountList){
                for(FieldsetColumnsWrapper fieldsetColumn: fieldsetColumnsWrapperList){
                    if(fieldsetColumn.fieldName ==  'Name'){
                        fieldsetColumn.fieldName='accountUrl';
                        fieldsetColumn.type='url';
                        fieldsetColumn.typeAttributes= JSON.deserializeUntyped('{"label": {"fieldName" :"Name"},"tooltip":{"fieldName" : "Name"}}');
                    }
                }
            }
        }
        /*[PC-7917]: End */

        recordFieldDataWrapper = new RecordFieldDataWrapper(fieldsetColumnsWrapperList, objectList);

        return recordFieldDataWrapper;
    }

    /*****************************************************************************************************
    * Author       : Hitha Avalakki
    * Parameter    : String sobjectAPIName,String fieldSetAPIName
    * Method name  : getFieldSetMembers
    * Return Type  : List<PC_FieldSetController.FieldSetMember>
    * Description  : This method is used to get fieldset members of the respective sobject
    *****************************************************************************************************/
    private static List<PC_FieldSetController.FieldSetMember> getFieldSetMembers(String sobjectAPIName,String fieldSetAPIName) {
        List<PC_FieldSetController.FieldSetMember> members;

        if (String.isNotBlank(sobjectAPIName) && String.isNotBlank(fieldSetAPIName)) {
            Schema.SObjectType targetType = Schema.getGlobalDescribe().get(sobjectAPIName);
            Schema.DescribeSObjectResult describe = targetType.getDescribe();

            members = PC_FieldSetController.getFields(sobjectAPIName, fieldSetAPIName);
        }

        return members;
    }

    public class FieldsetColumnsWrapper{
        @AuraEnabled public String label{get;set;}
        @AuraEnabled public String fieldName{get;set;}
        @AuraEnabled public String type{get;set;}
        @auraenabled public Object typeAttributes{get;set;}

        FieldsetColumnsWrapper(String label,String fieldName,String type){
            this.label = label;
            this.fieldName = fieldName;
            this.type = type;
        }
        FieldsetColumnsWrapper(){
            this.label = '';
            this.fieldName = '';
            this.type = '';
        }
    }

    public class SobjectDataWrapper{
        @AuraEnabled public List<FieldsetColumnsWrapper> accountColumnsWrapper{get;set;}
        @AuraEnabled public List<FieldsetColumnsWrapper> caseColumnsWrapper{get;set;}
        @AuraEnabled public List<SObject> accountsList{get;set;}
        @AuraEnabled public List<SObject> casesList{get;set;}

        SobjectDataWrapper(List<FieldsetColumnsWrapper> accountColumnsWrapper,List<FieldsetColumnsWrapper> caseColumnsWrapper,List<SObject> accountsList,List<SObject> casesList){
            this.accountColumnsWrapper = accountColumnsWrapper;
            this.caseColumnsWrapper = caseColumnsWrapper;
            this.accountsList = accountsList;
            this.casesList = casesList;
        }
        SobjectDataWrapper(){}
    }
    public class RecordFieldDataWrapper{
        @AuraEnabled public List<FieldsetColumnsWrapper> columnsWrapper{get;set;}
        @AuraEnabled public List<SObject> objectList{get;set;}

        RecordFieldDataWrapper(List<FieldsetColumnsWrapper> columnsWrapper,List<SObject> objectList){
            this.columnsWrapper = columnsWrapper;
            this.objectList = objectList;
        }
        RecordFieldDataWrapper(){}
    }
    public class SurveyException extends Exception {}
}