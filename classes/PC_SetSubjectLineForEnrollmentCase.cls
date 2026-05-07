/**************************************************************************************
Apex Class Name     : PC_SetSubjectLineForEnrollmentCase
Description         : This class is used for updating the subject line of enrollment case;
CreatedBy           : Tejas Patel
Created Date        : 27 Jun 2019
Modification Log    :
--------------------------------------------------------------------------------------------------------------
Developer                   Date                   Description
----------------------------------------------------------------------------
Tejas Patel                27 Jun 2019            Initial version
Tejas Patel                30 July 2020           replacing the toLabel in SOQL with a function call and map.
Haritha Reddy           21-Jan-2021             [PC-7102] Added FLS Check
Hitha Avalakki            25 May 2021            [PC-7545] Removed 'with sharing' class level declaration since trigger handler code runs in system context.
Satheesh Kumar            Nov 16, 2021           [PC-8213] Excluded FLS Check and added inherited sharing
*************************************************************************************/
/* PC-7545: 'with sharing' class level declaration is not required since trigger handler code runs in Trigger Context*/
public inherited sharing class PC_SetSubjectLineForEnrollmentCase extends PC_TriggerHandler{
    override public void afterUpdate(){
        updateSubjectLine((Map<Id, Case>) oldMap, (List<Case>) newList);
    }

    /*********************************************************************************
    Method Name    : updateSubjectLine
    Author         : Tejas Patel
    Description    : Update the subject line when engagement program, account or applicant updated
    Return Type    : void
    Parameter      : oldMap, newList
    *********************************************************************************/
    private void updateSubjectLine(Map<Id, Case> oldMap, List<Case> newList){
        String patientName              = PC_Constants.EMPTY_STRING;
        String recordType               = PC_Constants.EMPTY_STRING;
        String engagementProgramName    = PC_Constants.EMPTY_STRING;

        Set<Id> caseIds                 = new Set<Id>();
        List<Case> caseList             = new List<Case>();
        List<Case> casesToUpdate        = new List<Case>();


        try {
            for (Case c : newList) {
                if (c.Type == PC_Constants.CASE_ENROLLMENT_RECORD_TYPE_NAME) {
                //Only Engagement Program Changed
                    if (c.PC_Engagement_Program__c != null && c.PC_Engagement_Program__c != oldMap.get(c.Id).PC_Engagement_Program__c
                        && c.AccountId == oldMap.get(c.Id).AccountId && c.PC_ActiveApplicant__c == oldMap.get(c.Id).PC_ActiveApplicant__c) {
                        caseIds.add(c.Id);
                    }
                //Only Account or Account and Engagement Program both Changed
                    if (c.AccountId != null && c.AccountId != oldMap.get(c.Id).AccountId) {
                        caseIds.add(c.Id);
                    } else if (c.AccountId == null && c.PC_ActiveApplicant__c != null && c.PC_ActiveApplicant__c != oldMap.get(c.Id).PC_ActiveApplicant__c) {
                        caseIds.add(c.Id);
                    }
                }
            }

            if(!caseIds.isEmpty()){

                //FLS is NOT needed in Triggers, as they always run in System Mode.
                /*List<String> caseFields = new List<String>{'Subject', 'AccountId','Type',
                        PC_Constants.getQualifiedAPIName('PC_Engagement_Program__c'),
                        PC_Constants.getQualifiedAPIName('PC_ActiveApplicant__c')};
                PC_Database.assertAccess(PC_Constants.PC_CASE,PC_Database.Operation.Reading, caseFields);

                List<String> engProgramFields = new List<String> {'Name'};
                PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Engagement_Program__c'), PC_Database.Operation.Reading, engProgramFields);

                List<String> accountFields = new List<String>{PC_Constants.getQualifiedAPIName('PC_First_Name__c'),PC_Constants.getQualifiedAPIName('PC_Last_Name__c')};
                PC_Database.assertAccess(PC_Constants.PC_ACCOUNT,PC_Database.Operation.Reading, accountFields);

                List<String> applicantFields = new List<String> {PC_Constants.getQualifiedAPIName('PC_First_Name__c'),PC_Constants.getQualifiedAPIName('PC_Last_Name__c')};
                PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Applicant__c'), PC_Database.Operation.Reading, applicantFields); */


                caseList   = [SELECT Id, Subject, PC_Engagement_Program__c, PC_Engagement_Program__r.Name, AccountId, PC_ActiveApplicant__c, Account.PC_Last_Name__c, Account.PC_First_Name__c,
                        PC_ActiveApplicant__r.PC_Last_Name__c, PC_ActiveApplicant__r.PC_First_Name__c, Type FROM Case WHERE Id IN :caseIds];

                Map<String,String> caseTypePicklistMap = PC_PicklistFieldManager.getPicklistLabelValue(Case.Type.getDescribe());

                for(Case c : caseList){
                    if(c.PC_Engagement_Program__c != null){
                        engagementProgramName   = c.PC_Engagement_Program__r.Name + ' - ';
                    }
                    if(c.AccountId != null){
                        if(c.Account.PC_Last_Name__c !=null && c.Account.PC_First_Name__c !=null){
                            patientName             = c.Account.PC_Last_Name__c + ', ' + c.Account.PC_First_Name__c + ' - ';
                        }else if(c.Account.PC_Last_Name__c ==null && c.Account.PC_First_Name__c !=null){
                            patientName         = c.Account.PC_First_Name__c + ' - ';
                        }else if(c.Account.PC_Last_Name__c !=null && c.Account.PC_First_Name__c ==null) {
                            patientName = c.Account.PC_Last_Name__c + ' - ';
                        }
                    }else if(c.AccountId == null && c.PC_ActiveApplicant__c != null){
                        if(c.PC_ActiveApplicant__r.PC_Last_Name__c !=null && c.PC_ActiveApplicant__r.PC_First_Name__c !=null){
                            patientName         = c.PC_ActiveApplicant__r.PC_Last_Name__c + ', ' + c.PC_ActiveApplicant__r.PC_First_Name__c + ' - ';
                        }else if(c.PC_ActiveApplicant__r.PC_Last_Name__c ==null && c.PC_ActiveApplicant__r.PC_First_Name__c !=null){
                            patientName         = c.PC_ActiveApplicant__r.PC_First_Name__c + ' - ';
                        }else if(c.PC_ActiveApplicant__r.PC_Last_Name__c !=null && c.PC_ActiveApplicant__r.PC_First_Name__c ==null){
                            patientName         = c.PC_ActiveApplicant__r.PC_Last_Name__c + ' - ';
                        }
                    }
                    if(c.Type != null){
                        recordType              = caseTypePicklistMap.get(c.Type);
                    }
                    c.Subject = patientName + engagementProgramName + recordType;
                    casesToUpdate.add(c);
                }
            }
            if(!casesToUpdate.isEmpty()){
                casesToUpdate = (List<Case>) PC_Database.upd(casesToUpdate, false);
            }
        } catch(Exception ex) {
            PC_Utility.createExceptionLog(ex);
        }
    }
}