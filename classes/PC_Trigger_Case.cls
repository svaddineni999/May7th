/*********************************************************************************************************
Class Name      : PC_Trigger_Case 
Description     : trigger on Case object. 
Created By      : Ajinkya Deshmukh
Created Date    : July 12, 2017
Modification Log:
-------------------------------------------------------------------------------------------------------------- 
Developer                   Date                   	Description
--------------------------------------------------------------------------------------------------------------            
Ajinkya Deshmukh            July 12, 2017        	Initial Version
Mayuresh Patil              Aug 28, 2017            PC-2128 PC303 FLS/CRUD Check for managed package and removed unwanted debugs
Shabda Bhujad				Sept 05, 2017			[PC-2138] Restricted the logic for adding and updating the associations for case type - PC_Constants.CASE_PROGRAM_RECORD_TYPE_NAME
Shabda Bhujad               Nov 14, 2017            PC-2485 Removing the reference to trigger state
Xiukai Ning                 Feb 28, 2019            PC-3775 - Code review. FLS is NOT needed in Triggers, as they always run in System Mode.
                                                    Trigger delegate class (handler) that has with Sharing keyword however, will apply user sharing.
                                                    We are removing all FLS and With Sharing keywords in the handlers.
Tushar Arora                Jun 26, 2019            [PC-4894] Stop referencing Case.PC_Is_Program_Case__c and Account.PC_IsIndividual__c from code
Hitha Avalakki              Mar 19, 2021            [PC-7533] Replaced constant CASE_PROGRAM_RECORD_TYPE_NAME to CASE_PROGRAM_TYPE
Satheesh Kumar              Nov 16, 2021            [PC-8213] Excluded FLS Check and added inherited sharing
****************************************************************************************************************/
public inherited sharing class PC_Trigger_Case extends PC_TriggerHandler {
    public static boolean isExecuting = false;

    override public void beforeInsertUpdate() {
        processCaseChanges((List< Case>) newList, (Map<Id, Case>) oldMap);
        checkForDuplicateUser((List< Case>) newList);
    }

    override public void afterInsert() {
        if( PC_Trigger_Association.isExecuting) {
            // if was executed during the same context avoid recursion
            return;
        }
        PC_Trigger_Case.isExecuting = true;
        manageAssociations((List<Case>) newList);
    }

    override public void afterUpdate() {
        if( PC_Trigger_Association.isExecuting) {
            // if was executed during the same context avoid recursion
            return;
        }
        PC_Trigger_Case.isExecuting = true;
        manageAssociations((Map<Id, Case>) oldMap, (Map<Id, Case>) newMap);
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
            if ((eachCase.PC_Care_Coordinator__c == eachCase.PC_Reimbursment_Specialist__c)
                    && eachCase.PC_Care_Coordinator__c != null) {
                eachCase.addError(Label.PC_SameUserOnCase);
            }
        }
    }

    /*
    * Method Name    : manageAssociations
    * Author         : Ajinkya Deshmukh
    * Description    : This method is used to create associations records for after insert
    * Return Type    : void
    * Parameter      : List<Case> newCaseList
    */
    private void manageAssociations(List<Case> newCaseList) {
        List<PC_Association__c> associationsToAdd = new List<PC_Association__c> ();
        
        for (Case eachCase : newCaseList) {
            if (eachCase.PC_Physician__c != null && (String.valueOf(eachCase.Type) == PC_Constants.CASE_PROGRAM_TYPE)) {
                associationsToAdd.add(
                        new PC_Association__c (
                                PC_Program__c = eachCase.Id,
                                PC_Account__c = eachCase.PC_Physician__c,
                                PC_AssociationStatus__c = PC_Constants.ACTIVE,
                                PC_Role__c = PC_Constants.ROLE_TREATING_PHYSICIAN
                        )
                );
            }
            if (eachCase.PC_Reimbursment_Specialist__c != null && (String.valueOf(eachCase.Type) == PC_Constants.CASE_PROGRAM_TYPE)) {
                associationsToAdd.add(
                        new PC_Association__c (
                                PC_Program__c = eachCase.Id,
                                PC_Associated_User__c = eachCase.PC_Reimbursment_Specialist__c,
                                PC_AssociationStatus__c = PC_Constants.ACTIVE,
                                PC_Role__c = PC_Constants.PC_ROLE_REIMBURSEMENT_SPECIALIST
                        )
                );
            }
            if (eachCase.PC_Care_Coordinator__c != null && (String.valueOf(eachCase.Type) == PC_Constants.CASE_PROGRAM_TYPE)) {
                associationsToAdd.add(
                        new PC_Association__c (
                                PC_Program__c = eachCase.Id,
                                PC_Associated_User__c = eachCase.PC_Care_Coordinator__c,
                                PC_AssociationStatus__c = PC_Constants.ACTIVE,
                                PC_Role__c = PC_Constants.PC_ROLE_CARE_COORDINATOR
                        )
                );
            }
        }
        PC_Database.ins(associationsToAdd, false);
    }

    /*
    * Method Name    : manageAssociations
    * Author         : Ajinkya Deshmukh
    * Description    : This method is used to create associations records for after update
    * Return Type    : void
    * Parameter      : Map<Id, Case> oldCaseMap, Map<Id, Case> newCaseMap
    */
    private void manageAssociations(Map<Id, Case> oldCaseMap, Map<Id, Case> newCaseMap) {
        List<PC_Association__c> associationsToAdd = new List<PC_Association__c> ();
        List<PC_Association__c> associationsSetToExpire = new List<PC_Association__c> ();
        Map<Id, String> mapCaseIdToPhysicianId = new Map<Id, String>();
        Map<Id, String> mapCaseIdToReimbursementSpId = new Map<Id, String>();
        Map<Id, String> mapCaseIdToCareCordId = new Map<Id, String>();
        for (Id caseId : newCaseMap.keySet()) {
            if(String.valueOf(newCaseMap.get(caseId).Type) == PC_Constants.CASE_PROGRAM_TYPE){
                if (newCaseMap.get(caseId).PC_Physician__c != oldCaseMap.get(caseId).PC_Physician__c) {
                    if (oldCaseMap.get(caseId).PC_Physician__c != null) {
                        mapCaseIdToPhysicianId.put(caseId, oldCaseMap.get(caseId).PC_Physician__c);
                    }
                    if (newCaseMap.get(caseId).PC_Physician__c != null) {
                        associationsToAdd.add(
                            new PC_Association__c (
                                PC_Program__c = caseId,
                                PC_Account__c = newCaseMap.get(caseId).PC_Physician__c,
                                PC_AssociationStatus__c = PC_Constants.ACTIVE,
                                PC_Role__c = PC_Constants.ROLE_TREATING_PHYSICIAN
                            )
                        );
                    }
                }
                if (newCaseMap.get(caseId).PC_Reimbursment_Specialist__c != oldCaseMap.get(caseId).PC_Reimbursment_Specialist__c) {
                    if (oldCaseMap.get(caseId).PC_Reimbursment_Specialist__c != null) {
                        mapCaseIdToReimbursementSpId.put(caseId, oldCaseMap.get(caseId).PC_Reimbursment_Specialist__c);
                    }
                    if (newCaseMap.get(caseId).PC_Reimbursment_Specialist__c != null) {
                        associationsToAdd.add(
                            new PC_Association__c (
                                PC_Program__c = caseId,
                                PC_Associated_User__c = newCaseMap.get(caseId).PC_Reimbursment_Specialist__c,
                                PC_AssociationStatus__c = PC_Constants.ACTIVE,
                                PC_Role__c = PC_Constants.PC_ROLE_REIMBURSEMENT_SPECIALIST
                            )
                        );
                    }
                }
                if (newCaseMap.get(caseId).PC_Care_Coordinator__c != oldCaseMap.get(caseId).PC_Care_Coordinator__c) {
                    if (oldCaseMap.get(caseId).PC_Care_Coordinator__c != null) {
                        mapCaseIdToCareCordId.put(caseId, oldCaseMap.get(caseId).PC_Care_Coordinator__c);
                    }
                    if (newCaseMap.get(caseId).PC_Care_Coordinator__c != null) {
                        associationsToAdd.add(
                            new PC_Association__c (
                                PC_Program__c = caseId,
                                PC_Associated_User__c = newCaseMap.get(caseId).PC_Care_Coordinator__c,
                                PC_AssociationStatus__c = PC_Constants.ACTIVE,
                                PC_Role__c = PC_Constants.PC_ROLE_CARE_COORDINATOR
                            )
                        );
                    }
                }
            }
        }
        
        List<PC_Association__c> physicianAssociationsToExpire = [
                SELECT Id
                FROM PC_Association__c
                WHERE PC_Program__c IN : mapCaseIdToPhysicianId.keySet()
                AND PC_Account__c IN : mapCaseIdToPhysicianId.values()
                AND PC_Role__c =: PC_Constants.ROLE_TREATING_PHYSICIAN
                AND PC_AssociationStatus__c =: PC_Constants.ACTIVE
        ];
        if (!physicianAssociationsToExpire.isEmpty()) {
            associationsSetToExpire.addAll(physicianAssociationsToExpire);
        }
        List<PC_Association__c> reimbursementSpecialistAssociationsToExpire = [
                SELECT Id
                FROM PC_Association__c
                WHERE PC_Program__c IN : mapCaseIdToReimbursementSpId.keySet()
                AND PC_Associated_User__c IN : mapCaseIdToReimbursementSpId.values()
                AND PC_Role__c =: PC_Constants.PC_ROLE_REIMBURSEMENT_SPECIALIST
                AND PC_AssociationStatus__c =: PC_Constants.ACTIVE
        ];
        if (!reimbursementSpecialistAssociationsToExpire.isEmpty()) {
            associationsSetToExpire.addAll(reimbursementSpecialistAssociationsToExpire);
        }
        List<PC_Association__c> careCoordinatorAssociationsToExpire = [
                SELECT Id
                FROM PC_Association__c
                WHERE PC_Program__c IN : mapCaseIdToCareCordId.keySet()
                AND PC_Associated_User__c IN : mapCaseIdToCareCordId.values()
                AND PC_Role__c =: PC_Constants.PC_ROLE_CARE_COORDINATOR
                AND PC_AssociationStatus__c =: PC_Constants.ACTIVE
        ];
        if (!careCoordinatorAssociationsToExpire.isEmpty()) {
            associationsSetToExpire.addAll(careCoordinatorAssociationsToExpire);
        }

        for (PC_Association__c eachAssociation : associationsSetToExpire) {
            eachAssociation.PC_AssociationStatus__c = PC_Constants.INACTIVE;
            eachAssociation.PC_EndDate__c = System.today();
        }

        if (!associationsSetToExpire.isEmpty()) {
            PC_Database.upd(associationsSetToExpire, false);
        }
        if (!associationsToAdd.isEmpty()) {
            PC_Database.ins(associationsToAdd, false);
        }
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
            if(caseObj.Id != null && (oldCaseMap != null && oldCaseMap.containsKey(caseObj.Id))) {
                Case oldCaseObj = oldCaseMap.get(caseObj.Id);
                //Treatment Cycles functionality
                if (caseObj.Status == System.Label.PC_Enrolled && oldCaseObj.Status != System.Label.PC_Enrolled) {
                    caseObj.PC_Enrollment_Date__c = Date.today();
                }

                if ((caseObj.Status == System.Label.PC_On_Hold && oldCaseObj.Status != System.Label.PC_On_Hold && oldCaseObj.Status != System.Label.PC_Withdrawn) || (caseObj.Status == System.Label.PC_Withdrawn && oldCaseObj.Status != System.Label.PC_On_Hold && oldCaseObj.Status != System.Label.PC_Withdrawn)) {
                    caseObj.PC_Previous_Status__c = oldCaseObj.Status;
                }
                if (caseObj.Status != System.Label.PC_On_Hold && caseObj.Status !=  System.Label.PC_Withdrawn) {
                    caseObj.PC_Previous_Status__c = PC_Constants.EMPTY_STRING;
                }
                if (oldCaseObj.Status != System.Label.PC_Withdrawn && caseObj.Status ==  System.Label.PC_Withdrawn) {
                    caseObj.PC_Withdrawal_Date__c = System.today();
                }
                if (oldCaseObj.Status ==  System.Label.PC_Withdrawn && caseObj.Status !=  System.Label.PC_Withdrawn) {
                    caseObj.PC_Reason_for_Withdrawal__c = null;
                    caseObj.PC_Withdrawal_Date__c = null;
                }
            }
            if(caseObj.Type != PC_Constants.CASE_PROGRAM_TYPE
                    && (oldCaseMap == null || oldCaseMap.get(caseObj.Id).ParentId != caseObj.ParentId)
                    && !lstParentCasses.contains(caseObj.ParentId)) {
                lstParentCasses.add(caseObj.ParentId);
            }
        }

        Map<Id, PC_Program_Coverage__c> mapProgramCoverage = new Map<Id, PC_Program_Coverage__c>();

        if (!programCoverageIds.isEmpty()) {
            mapProgramCoverage = new Map<Id, PC_Program_Coverage__c>([SELECT Id, PC_Program__c, PC_Program__r.AccountId
                                                                      FROM PC_Program_Coverage__c
                                                                      WHERE Id in: programCoverageIds]);
        }
        if (!lstParentCasses.isEmpty()) {
            Map<Id, Case> mapParentCases = new Map<Id, Case>([Select Id, PC_Program__c, PC_Program__r.AccountId, AccountId
                                                                FROM Case
                                                                WHERE Id in: lstParentCasses]);
            for(Case caseObj : newCaseList) {
                //Check and set the related program case
                if(caseObj.Type != PC_Constants.CASE_PROGRAM_TYPE && mapParentCases.containsKey(caseObj.ParentId)) {
                    Case parentCase = mapParentCases.get(caseObj.ParentId);
                    caseObj.PC_Program__c = (parentCase.Type == PC_Constants.CASE_PROGRAM_TYPE ? parentCase.Id: parentCase.PC_Program__c);
                    caseObj.AccountId = (parentCase.Type == PC_Constants.CASE_PROGRAM_TYPE ? parentCase.AccountId: parentCase.PC_Program__r.AccountId);
                }
            }
        }

    }
}