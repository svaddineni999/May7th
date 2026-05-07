/*********************************************************************************************************
Class Name      : PC_SetEngagementProgramOnCaseHandler
Description     : Auto-populates Engagement Program on Service Case with the engagement Program on related program case
Created By      : Haritha Reddy
Created Date    : Feb 08, 2019
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer                   Date                   	Description
--------------------------------------------------------------------------------------------------------------
Haritha Reddy				Feb 08, 2019			PC-4383: Initial version
Xiukai Ning                 Feb 28, 2019            PC-3775 - Code review. FLS is NOT needed in Triggers, as they always run in System Mode.
                                                    Trigger delegate class (handler) that has with Sharing keyword however, will apply user sharing.
                                                    We are removing all FLS and With Sharing keywords in the handlers.
Tejas Patel                 Oct 21, 2020            Optimizing the class by eliminating for loops.
Haritha Reddy           21-Jan-2021             [PC-7102] Added FLS Check
Satheesh Kumar          Nov 16, 2021            [PC-8213] Excluded FLS Check and added inherited sharing
****************************************************************************************************************/

public inherited sharing class PC_SetEngagementProgramOnCaseHandler extends PC_TriggerHandler {
    override public void beforeInsert() {
        checkEngagementProgram((List< Case>) newList);
    }
    override public void beforeUpdate() {
        checkEngagementProgram((List< Case>) newList);
    }
    /**
     * @Description Auto-populates Engagement Program on Service Case with the engagement Program on related program case
     * @param newCaseList List of new Cases to be created
     * @return  NA
    */
    private void checkEngagementProgram(List< Case> newList) {
        Set<Id> programCaseIds = new Set<Id>();
        List<Case> serviceCaseToUpdate = new List<Case>();
        for (Case caseRecord:newList) {
            if(string.isNotBlank(caseRecord.PC_Program__c) && string.isBlank(caseRecord.PC_Engagement_Program__c)){
                programCaseIds.add(caseRecord.PC_Program__c);
                serviceCaseToUpdate.add(caseRecord);
            }
        }

        newList = serviceCaseToUpdate;

        Map<Id,Case> programCaseMap = new Map<Id,Case>();
        if(programCaseIds.size() > 0 ){
            //FLS is NOT needed in Triggers, as they always run in System Mode.
            /*//CRUD/FLS Check for case
            List<String> caseFields = new List<String>{PC_Constants.getQualifiedAPIName('PC_Engagement_Program__c')};
            PC_Database.assertAccess(PC_Constants.PC_CASE,PC_Database.Operation.Reading, caseFields);*/

            programCaseMap = new Map<Id,Case>([SELECT Id, PC_Engagement_Program__c FROM Case WHERE Id IN:programCaseIds]);
        }

        if(programCaseMap.size() > 0){
            for(Case serviceCaseObj : newList){
                serviceCaseObj.PC_Engagement_Program__c = programCaseMap.get(serviceCaseObj.PC_Program__c).PC_Engagement_Program__c;
            }
        }
    }
}