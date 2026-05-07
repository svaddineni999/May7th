/*********************************************************************************************************
Class Name      : PC_CheckDuplicates_ProcessChange 
Description     : trigger on Case object to Process the changes on Case and Check for Duplicate Associations. 
Created By      : Tejas Patel
Created Date    : Jan 4, 2018
Modification Log:
-------------------------------------------------------------------------------------------------------------- 
Developer                   Date                    Description
--------------------------------------------------------------------------------------------------------------            
Tejas Patel                 Jan 4, 2018             Initial Version
Vijay Kashikar              Sep 17, 2018            [PC-3572] Added conditional FLS check based on the trigger state
Vijay Kashikar              Sep 18, 2018            [PC-3567] Added condition to update only those cases which have Type='Program'
Vijay Kashikar              Sep 20, 2018            [PC-3567] FLS check removed from all the places since triggers are deemed to run in system context.
Xiukai Ning                 Feb 28, 2019            PC-3775 - Code review. FLS is NOT needed in Triggers, as they always run in System Mode.
                                                    Trigger delegate class (handler) that has with Sharing keyword however, will apply user sharing.
                                                    We are removing all FLS and With Sharing keywords in the handlers.
Tushar Arora                Jun 26, 2019            [PC-4894] Stop referencing Case.PC_Is_Program_Case__c and Account.PC_IsIndividual__c from code
Shishir Bansal              Dec-06-2019             [PC-5792] Avoid hardcoding of string variable
Vijay kashikar              Dec-06-2019             [PC-5998] During update, Enrolled date will be set to current date only when the Enrolled date is null.
Vijay Kashikar              21-Jan-21               [PC-7102] Added FLS Checks
Hitha Avalakki              Mar 19, 2021            [PC-7533] Replaced constant CASE_PROGRAM_RECORD_TYPE_NAME to CASE_PROGRAM_TYPE
Satheesh Kumar              Nov 16, 2021            [PC-8213] Excluded FLS Check and added inherited sharing
****************************************************************************************************************/
public inherited sharing class PC_CheckDuplicates_ProcessChangeHandler extends PC_TriggerHandler {

    override public void beforeInsertUpdate() {
        processCaseChanges((List< Case>) newList, (Map<Id, Case>) oldMap);
        checkForDuplicateUser((List< Case>) newList);
    }
    
    /**************************************************************************************
    *   @Description : Process Case changes and update Program case
    *   @Param       : newCaseMap. Trigger new case map
    *   @Param       : oldCaseMap. Trigger old case map
    *   @Return      : Void
    ***************************************************************************************/
    private void processCaseChanges(List<Case> newCaseList, Map<Id, Case> oldCaseMap ) {
        Set<Id> lstParentCasses = new Set<Id>();
        Set<Id> programCoverageIds = new Set<Id>();

        for(Case caseObj : newCaseList) {
            if(caseObj.Id != null && (oldCaseMap != null && oldCaseMap.containsKey(caseObj.Id) && caseObj.Type == PC_Constants.CASE_PROGRAM_TYPE)) {
                Case oldCaseObj = oldCaseMap.get(caseObj.Id);
                //Treatment Cycles functionality
                if (caseObj.Status == PC_Constants.PROGRAM_STATUS.get(PC_Constants.PROGRAM_STATUS_ENROLLED) &&
                        oldCaseObj.Status != PC_Constants.PROGRAM_STATUS.get(PC_Constants.PROGRAM_STATUS_ENROLLED) &&
                        oldCaseObj.PC_Enrollment_Date__c == null) {
                    caseObj.PC_Enrollment_Date__c = Date.today();
                }
                if ((caseObj.Status == PC_Constants.PROGRAM_STATUS.get(PC_Constants.PROGRAM_STATUS_ON_HOLD) &&
                        oldCaseObj.Status != PC_Constants.PROGRAM_STATUS.get(PC_Constants.PROGRAM_STATUS_ON_HOLD) &&
                        oldCaseObj.Status != PC_Constants.PROGRAM_STATUS.get(PC_Constants.PROGRAM_STATUS_WITHDRAWN)) || (caseObj.Status == PC_Constants.PROGRAM_STATUS.get(PC_Constants.PROGRAM_STATUS_WITHDRAWN) &&
                        oldCaseObj.Status != PC_Constants.PROGRAM_STATUS.get(PC_Constants.PROGRAM_STATUS_ON_HOLD) && oldCaseObj.Status != PC_Constants.PROGRAM_STATUS.get(PC_Constants.PROGRAM_STATUS_WITHDRAWN))) {
                    caseObj.PC_Previous_Status__c = oldCaseObj.Status;
                }
                if (caseObj.Status != PC_Constants.PROGRAM_STATUS.get(PC_Constants.PROGRAM_STATUS_ON_HOLD) && caseObj.Status !=  PC_Constants.PROGRAM_STATUS.get(PC_Constants.PROGRAM_STATUS_WITHDRAWN)) {
                    caseObj.PC_Previous_Status__c = PC_Constants.EMPTY_STRING;
                }
                if (oldCaseObj.Status != PC_Constants.PROGRAM_STATUS.get(PC_Constants.PROGRAM_STATUS_WITHDRAWN) && caseObj.Status ==  PC_Constants.PROGRAM_STATUS.get(PC_Constants.PROGRAM_STATUS_WITHDRAWN)) {
                    caseObj.PC_Withdrawal_Date__c = System.today();
                }
                if (oldCaseObj.Status ==  PC_Constants.PROGRAM_STATUS.get(PC_Constants.PROGRAM_STATUS_WITHDRAWN) && caseObj.Status !=  PC_Constants.PROGRAM_STATUS.get(PC_Constants.PROGRAM_STATUS_WITHDRAWN)) {
                    caseObj.PC_Reason_for_Withdrawal__c = null;
                    caseObj.PC_Withdrawal_Date__c = null;
                }
            }
            if(caseObj.Type == PC_Constants.CASE_PROGRAM_TYPE
                    && (oldCaseMap == null || oldCaseMap.get(caseObj.Id).ParentId != caseObj.ParentId)
                    && !lstParentCasses.contains(caseObj.ParentId)) {
                lstParentCasses.add(caseObj.ParentId);
            }
        }

        if (!lstParentCasses.isEmpty()) {
            //FLS is NOT needed in Triggers, as they always run in System Mode.
            /*List<String> caseFields = new List<String>();
            caseFields.add(PC_Constants.getQualifiedAPIName('PC_Program__c'));
            caseFields.add('AccountId');
            caseFields.add('Type');
            PC_Database.assertAccess(PC_Constants.PC_CASE,PC_Database.Operation.Reading, caseFields);*/

            Map<Id, Case> mapParrentCasses = new Map<Id, Case>([Select Id, PC_Program__c, PC_Program__r.AccountId, AccountId, Type
                                                                FROM Case
                                                                WHERE Id in: lstParentCasses]);
            for(Case caseObj : newCaseList) {
                //Check and set the related program case
                if(mapParrentCasses.containsKey(caseObj.ParentId)) {
                    Case parentCase = mapParrentCasses.get(caseObj.ParentId);
                    caseObj.PC_Program__c = (caseObj.Type == PC_Constants.CASE_PROGRAM_TYPE ? parentCase.Id: parentCase.PC_Program__c);
                    caseObj.AccountId = (caseObj.Type == PC_Constants.CASE_PROGRAM_TYPE ? parentCase.AccountId: parentCase.PC_Program__r.AccountId);
                }
            }
        }
    }
    
    /*
    * Method Name    : checkForCaseTeam
    * Author         : Ajinkya Deshmukh
    * Description    : This method is used to create associations records for after insert
    * Return Type    : void
    * Parameter      : List<Case> newCaseList
    */
    private void checkForDuplicateUser(List<Case> newCaseList) {
        for (Case eachCase : newCaseList) {
            if (eachCase.Type == PC_Constants.CASE_PROGRAM_TYPE
                    && (eachCase.PC_Care_Coordinator__c == eachCase.PC_Reimbursment_Specialist__c)
                    && eachCase.PC_Care_Coordinator__c != null) {
                eachCase.addError(Label.PC_SameUserOnCase);
            }
        }
    }
}