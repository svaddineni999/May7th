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
Haritha Reddy           21-Jan-2021             [PC-7102] Added FLS Check
Satheesh Kumar          Nov 16, 2021             [PC-8213] Excluded FLS Check and added inherited sharing
****************************************************************************************************************/

public inherited sharing class PC_SetCaseSubject_Account extends PC_TriggerHandler {
    override public void afterUpdate() {
        updateRelatedCases((Map<Id, Account>) oldMap, (List<Account>) newList);
    }

    /**
     * @Description Fire an update DML on all related cases
     * @param oldMap Map of Accounts updated
     * @param newList List of Accounts updated
     * @return  NA
    */
    private void updateRelatedCases(Map<Id, Account> oldMap, List<Account> newList) {
        Set<Id> accountIdSet = new Set<Id>();
        List<Id> accountIds = new List<Id>();
        for(Account a : newList){
            if(oldMap.get(a.Id).PC_First_Name__c != a.PC_First_Name__c || oldMap.get(a.Id).PC_Last_Name__c != a.PC_Last_Name__c){
                accountIdSet.add(a.Id);
            }
        }
        accountIds.addAll(accountIdSet);
        //FLS is NOT needed in Triggers, as they always run in System Mode.
        /*//CRUD/FLS Check for case
        List<String> caseFields = new List<String>{'AccountId'};
        PC_Database.assertAccess(PC_Constants.PC_CASE,PC_Database.Operation.Reading, caseFields); */

        List<Case> relatedCases = [SELECT Id FROM Case WHERE AccountId IN :accountIds];
        if(!relatedCases.isEmpty()){
            PC_Database.upd(relatedCases, false);
        }
    }
}