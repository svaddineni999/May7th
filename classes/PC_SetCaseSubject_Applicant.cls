/*********************************************************************************************************
Class Name      : PC_SetCaseSubject_Account
Description     : Fire update statement on all related cases to update the subject.
Created By      : Tejas Patel
Created Date    : Oct 20, 2020
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer                   Date                   	Description
--------------------------------------------------------------------------------------------------------------
Tejas Patel				    Oct 20, 2020			Initial version
Vijay Kashikar              21-Jan-21               [PC-7102] Added FLS Checks
Satheesh Kumar              Nov 16, 2021            [PC-8213] Excluded FLS Check and added inherited sharing
****************************************************************************************************************/

public inherited sharing class PC_SetCaseSubject_Applicant extends PC_TriggerHandler {
    override public void afterUpdate() {
        updateRelatedCases((Map<Id, PC_Applicant__c>) oldMap, (List<PC_Applicant__c>) newList);
    }

    /**
     * @Description Fire an update DML on all related cases
     * @param oldMap Map of Accounts updated
     * @param newList List of Accounts updated
     * @return  NA
    */
    private void updateRelatedCases(Map<Id, PC_Applicant__c> oldMap, List<PC_Applicant__c> newList) {
        Set<Id> applicantIdSet = new Set<Id>();
        List<Id> applicantIds = new List<Id>();
        for(PC_Applicant__c a : newList){
            if(oldMap.get(a.Id).PC_First_Name__c != a.PC_First_Name__c || oldMap.get(a.Id).PC_Last_Name__c != a.PC_Last_Name__c){
                applicantIdSet.add(a.Id);
            }
        }
        applicantIds.addAll(applicantIdSet);

        //FLS is NOT needed in Triggers, as they always run in System Mode.
        /*List<String> caseFields = new List<String>();
        caseFields.add(PC_Constants.getQualifiedAPIName('PC_AccountId__c'));
        caseFields.add(PC_Constants.getQualifiedAPIName('PC_ActiveApplicant__c'));
        PC_Database.assertAccess(PC_Constants.PC_CASE,PC_Database.Operation.Reading, caseFields); */

        List<Case> relatedCases = [SELECT Id, PC_AccountId__c FROM Case WHERE PC_ActiveApplicant__c IN :applicantIds];
        List<Case> toUpdateCases = new List<Case>();
        if(!relatedCases.isEmpty()){
            for(Case c : relatedCases){
                if(c.PC_AccountId__c == null){
                    toUpdateCases.add(c);
                }
            }
            PC_Database.upd(toUpdateCases, false);
        }
    }
}