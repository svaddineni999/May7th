/**********************************************************************************************************
Class Name      : PC_SurveyWorkflowHelper
Description     : This class will serve as a helper class for PAP workflow functionalities
Created By      : Hitha Avalakki
Created Date    : June 16,2021
Modification Log:
-----------------------------------------------------------------------------------------------------
Developer                   Date                           Description
-----------------------------------------------------------------------------------------------------
Hitha Avalakki              June 16,2021                    Initial Version
Hitha Avalakki              June 24,2021                    Added code to dynamically create the title for New PAP Eligibility Check Option screen for Account and Case records
*********************************************************************************************************/

public with sharing class PC_SurveyWorkflowHelper {

    /*****************************************************************************************************
    * Author       : Hitha Avalakki
    * Parameter    : Id recordIdValue
    * Method name  : getAccountCaseRecordDetails
    * Return Type  : AccountCaseEngProgramWrapper
    * Description  : This method is used to get case details for PAP survey
    *****************************************************************************************************/
    public static AccountCaseEngProgramWrapper getAccountCaseRecordDetails(String recordIdValue,String surveyContext) {
        Id accountRecordId;
        Id caseRecordId;
        Id engagementProgramId;
        String newSurveyEligibilityCheckTitle;
        String surveyContextLabel = '';

        AccountCaseEngProgramWrapper accountCaseEngProgramWrapper = new AccountCaseEngProgramWrapper();
        try
        {
            if (!String.isBlank(surveyContext) && surveyContext.equals('PC_PAP')) {
                surveyContextLabel = Label.PC_PAPTitle;
            } else if (!String.isBlank(surveyContext) && surveyContext.equals('PC_Copay')) {
                surveyContextLabel = Label.PC_CopayTitle;
            }

            if(!String.isBlank(recordIdValue) && recordIdValue!='null')
            {
                SObjectType sobjectTypeValue = Id.valueOf(recordIdValue).getSobjectType();

                if (Schema.Account.SObjectType == sobjectTypeValue) {
                    accountRecordId = recordIdValue;

                    //FLS check for Account fields
                    List<String> accountFields = new List<String>{'Id', 'Name'};
                    PC_Database.assertAccess(PC_Constants.PC_ACCOUNT,PC_Database.Operation.Reading, accountFields);

                    List<Account> accountRecords=[SELECT Id,Name FROM Account WHERE Id=:recordIdValue];
                    if(accountRecords!=null && !accountRecords.isEmpty()){
                        List<Object> formattingArguments = new List<Object>{surveyContextLabel,Label.PC_Account,accountRecords[0].Name};
                        newSurveyEligibilityCheckTitle = String.format(Label.PC_NewSurveyEligibilityCheck,formattingArguments);
                    }
                }
                else if(Schema.Case.SObjectType == sobjectTypeValue)
                {
                    caseRecordId = recordIdValue;

                    //FLS check for case fields
                    List<String> caseFields = new List<String>{'Id', 'AccountId','CaseNumber',PC_Constants.getQualifiedAPIName('PC_Engagement_Program__c')};
                    PC_Database.assertAccess(PC_Constants.PC_CASE,PC_Database.Operation.Reading, caseFields);

                    List<Case> caseRecords=[SELECT Id,AccountId,CaseNumber, PC_Engagement_Program__c  FROM Case WHERE Id=:recordIdValue];
                    if(caseRecords!=null && !caseRecords.isEmpty()){
                        engagementProgramId = caseRecords[0].PC_Engagement_Program__c;
                        accountRecordId = caseRecords[0].AccountId;

                        List<Object> formattingArguments = new List<Object>{surveyContextLabel,Label.PC_Case,caseRecords[0].CaseNumber};
                        newSurveyEligibilityCheckTitle = String.format(Label.PC_NewSurveyEligibilityCheck,formattingArguments);
                    }
                }
                accountCaseEngProgramWrapper = new AccountCaseEngProgramWrapper(caseRecordId,accountRecordId,engagementProgramId,newSurveyEligibilityCheckTitle);

            }
            else
            {
                List<Object> formattingArguments = new List<Object>{surveyContextLabel};
                newSurveyEligibilityCheckTitle = String.format(Label.PC_NewSurveyEligibilityCheckDefaultLabel,formattingArguments);
                accountCaseEngProgramWrapper.newSurveyEligibilityCheckTitle = newSurveyEligibilityCheckTitle;
                return accountCaseEngProgramWrapper;
            }
        }
        catch(Exception e){
            PC_Utility.logAndThrowException(e,LAbel.PC_CaseRecordDetailsError+recordIdValue);
        }

        return accountCaseEngProgramWrapper;
    }

    public class AccountCaseEngProgramWrapper{
        @AuraEnabled public Id caseId{get;set;}
        @AuraEnabled public Id accountId{get;set;}
        @AuraEnabled public Id engagementProgramId{get;set;}
        @AuraEnabled public String newSurveyEligibilityCheckTitle{get;set;}
        AccountCaseEngProgramWrapper(){
        }
        AccountCaseEngProgramWrapper(Id caseId,Id accountId, Id engagementProgramId, String newSurveyEligibilityCheckTitle){
            this.caseId = caseId;
            this.accountId = accountId;
            this.engagementProgramId = engagementProgramId;
            this.newSurveyEligibilityCheckTitle = newSurveyEligibilityCheckTitle;
        }
    }
}