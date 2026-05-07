/*********************************************************************************************************
Class Name      : PC_SurveyEligibilityCheckController
Description     :
Created By      : Hitha Avalakki
Created Date    : June 04,2021
Modification Log:
-----------------------------------------------------------------------------------------------------
Developer                   Date                           Description
-----------------------------------------------------------------------------------------------------
Hitha Avalakki              June 04,2021                    Initial Version
*********************************************************************************************************/
public with sharing class PC_SurveyEligibilityCheckController {

    @AuraEnabled
    public static PC_SurveyWorkflowHelper.AccountCaseEngProgramWrapper getAccountCaseDetails(String recordIdValue,String surveyContext) {
        PC_SurveyWorkflowHelper.AccountCaseEngProgramWrapper accountCaseEngProgramWrapper;
        try
        {
            //PC-7459:Fetch Account and case details
            accountCaseEngProgramWrapper = PC_SurveyWorkflowHelper.getAccountCaseRecordDetails(recordIdValue,surveyContext);
        }
        catch(Exception e){
            PC_Utility.logAndThrowException(e,Label.PC_SobjectTypeError+recordIdValue);
        }

        return accountCaseEngProgramWrapper;
    }

}