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
Satheesh Kumar          Nov 16, 2021            [PC-8213] Excluded FLS Check and added inherited sharing
****************************************************************************************************************/

public inherited sharing class PC_SetCaseSubject_Engagement extends PC_TriggerHandler {
    override public void afterUpdate() {
        updateRelatedCases((Map<Id, PC_Engagement_Program__c>) oldMap, (List<PC_Engagement_Program__c>) newList);
    }

    /**
     * @Description Fire an update DML on all related cases
     * @param oldMap Map of Accounts updated
     * @param newList List of Accounts updated
     * @return  NA
    */
    private void updateRelatedCases(Map<Id, PC_Engagement_Program__c> oldMap, List<PC_Engagement_Program__c> newList) {
        Set<Id> engagementIdSet = new Set<Id>();
        List<Id> engagementIds = new List<Id>();
        for(PC_Engagement_Program__c a : newList){
            if(oldMap.get(a.Id).Name != a.Name){
                engagementIdSet.add(a.Id);
            }
        }
        engagementIds.addAll(engagementIdSet);

        //FLS is NOT needed in Triggers, as they always run in System Mode.
        /*List<String> fields = new List<String>{PC_Constants.getQualifiedAPIName('PC_Engagement_Program__c')};
        PC_Database.assertAccess('Case',PC_Database.Operation.Reading, fields); */

        List<Case> relatedCases = [SELECT Id FROM Case WHERE PC_Engagement_Program__c IN :engagementIds];
        if(!relatedCases.isEmpty()){
            PC_Database.upd(relatedCases, false);
        }
    }
}