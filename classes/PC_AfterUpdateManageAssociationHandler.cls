/*********************************************************************************************************
Class Name      : PC_AfterUpdateManageAssociationHandler
Description     : trigger on Case object to Manage Associations after Updation of case 
Created By      : Tejas Patel
Created Date    : Jan 4, 2018
Modification Log:
-------------------------------------------------------------------------------------------------------------- 
Developer                   Date                   	Description
--------------------------------------------------------------------------------------------------------------            
Tejas Patel            		Jan 4, 2018        		Initial Version
Xiukai Ning                 Feb 28, 2019            PC-3775 - Code review. FLS is NOT needed in Triggers, as they always run in System Mode.
                                                    Trigger delegate class (handler) that has with Sharing keyword however, will apply user sharing.
                                                    We are removing all FLS and With Sharing keywords in the handlers.
Tejas Patel            		Aug 5, 2019             PC-5251 - Stopping recursive case update
Hitha Avalakki              Mar 19, 2021            [PC-7533] Replaced constant CASE_PROGRAM_RECORD_TYPE_NAME to CASE_PROGRAM_TYPE
Kishore Kanteti             Aug 27,2021             PC-8068 - Removed FLS Check on DML Operation
Satheesh Kumar              Nov 16, 2021            [PC-8213] Excluded FLS Check and added inherited sharing
Vijay Kashikar              Dec 03, 2021            [PC-8365] Avoided a round of case updates when the new assocation members are same as the existing members.
****************************************************************************************************************/
public inherited sharing class PC_AfterUpdateManageAssociationHandler extends PC_TriggerHandler{
	public static boolean isExecuting = false;
    
    override public void afterUpdate() {
        PC_AfterUpdateManageAssociationHandler.isExecuting = false;
        system.debug('Trigger Handler ::: PC_AfterUpdateManageAssociationHandler');
        if ((PC_WorkCaseDistributionForCaseHandler.isProcessed == true || PC_WorkCaseDistributionForAssocHandler.isProcessed == true) && PC_ProcessNewAssociationHandler.isExecuting == true ) {
            PC_ProcessUpdateAssociationHandler.isExecuting = false;
            PC_ProcessNewAssociationHandler.isExecuting = false;
            return;
        }
        /*if(PC_ProcessUpdateAssociationHandler.isExecuting || PC_ProcessNewAssociationHandler.isExecuting) {
            // If Triggered from the Association triggers , the cases have already been updated
            return;
        }*/
        system.debug('Trigger Handler ::: PC_AfterUpdateManageAssociationHandler -> manageAssociations');
        manageAssociations((Map<Id, Case>) oldMap, (Map<Id, Case>) newMap);
    }
    
    /*
    * Method Name    : manageAssociations
    * Author         : Ajinkya Deshmukh
    * Description    : This method is used to create associations records for after update
    * Return Type    : void
    * Parameter      : Map<Id, Case> oldCaseMap, Map<Id, Case> newCaseMap
    */
    private void manageAssociations(Map<Id, Case> oldCaseMap, Map<Id, Case> newCaseMap) {
        System.debug('Entered and executed PC_AfterUpdateManageAssociationHandler');
        List<PC_Association__c> associationsToAdd = new List<PC_Association__c> ();

        Map<Id,List<PC_AssociationTriggerHelper.AssociationWrapper>> caseToAssociationWrapper = new Map<Id,List<PC_AssociationTriggerHelper.AssociationWrapper>>();


        Map<Id, List<PC_Association__c>> associationsByCaseIds = getAssociationsByCaseIds(newCaseMap.keySet());
        system.debug('****');
        system.debug(associationsByCaseIds);
        for (Id caseId : newCaseMap.keySet()) {
            List<PC_AssociationTriggerHelper.AssociationWrapper> associationWrapper = new List<PC_AssociationTriggerHelper.AssociationWrapper>();
            if(String.valueOf(newCaseMap.get(caseId).Type) == PC_Constants.CASE_PROGRAM_TYPE){
                List<Id> existingPhysicianIds = new List<Id>();
                List<Id> existingReimbursementSpIds = new List<Id>();
                List<Id> existingCareCoordinators = new List<Id>();
                if(associationsByCaseIds.containsKey(caseId)) {
                    List<PC_Association__c> existingAssociations = associationsByCaseIds.get(caseId);
                    for (PC_Association__c association : existingAssociations) {
                        if (association.PC_Role__c == PC_Constants.ROLE_TREATING_PHYSICIAN) {
                            existingPhysicianIds.add(association.PC_Account__c);
                        } else if (association.PC_Role__c == PC_Constants.PC_ROLE_REIMBURSEMENT_SPECIALIST) {
                            existingReimbursementSpIds.add(association.PC_Associated_User__c);
                        }
                        else if (association.PC_Role__c == PC_Constants.PC_ROLE_CARE_COORDINATOR) {
                            existingCareCoordinators.add(association.PC_Associated_User__c);
                        }
                    }
                }
                if (newCaseMap.get(caseId).PC_Physician__c != oldCaseMap.get(caseId).PC_Physician__c) {
                    if (newCaseMap.get(caseId).PC_Physician__c != null
                            && !existingPhysicianIds.contains(newCaseMap.get(caseId).PC_Physician__c))
                    {
                        associationsToAdd.add(
                            new PC_Association__c (
                                PC_Program__c = caseId,
                                PC_Account__c = newCaseMap.get(caseId).PC_Physician__c,
                                PC_AssociationStatus__c = PC_Constants.ACTIVE,
                                PC_Role__c = PC_Constants.ROLE_TREATING_PHYSICIAN
                            )
                        );
                    }else if(newCaseMap.get(caseId).PC_Physician__c == null && oldCaseMap.get(caseId).PC_Physician__c != null){
                        PC_AssociationTriggerHelper.AssociationWrapper association = new PC_AssociationTriggerHelper.AssociationWrapper();
                        association.accountUserId   = oldCaseMap.get(caseId).PC_Physician__c;
                        association.associationRole = PC_Constants.ROLE_TREATING_PHYSICIAN;
                        associationWrapper.add(association);
                    }
                }
                if (newCaseMap.get(caseId).PC_Reimbursment_Specialist__c != oldCaseMap.get(caseId).PC_Reimbursment_Specialist__c) {
                    if (newCaseMap.get(caseId).PC_Reimbursment_Specialist__c != null
                            && !existingReimbursementSpIds.contains(newCaseMap.get(caseId).PC_Reimbursment_Specialist__c))
                    {
                        associationsToAdd.add(
                            new PC_Association__c (
                                PC_Program__c = caseId,
                                PC_Associated_User__c = newCaseMap.get(caseId).PC_Reimbursment_Specialist__c,
                                PC_AssociationStatus__c = PC_Constants.ACTIVE,
                                PC_Role__c = PC_Constants.PC_ROLE_REIMBURSEMENT_SPECIALIST
                            )
                        );
                    }else if(newCaseMap.get(caseId).PC_Reimbursment_Specialist__c == null && oldCaseMap.get(caseId).PC_Reimbursment_Specialist__c != null){
                        PC_AssociationTriggerHelper.AssociationWrapper association = new PC_AssociationTriggerHelper.AssociationWrapper();
                        association.accountUserId   = oldCaseMap.get(caseId).PC_Reimbursment_Specialist__c;
                        association.associationRole = PC_Constants.PC_ROLE_REIMBURSEMENT_SPECIALIST;
                        associationWrapper.add(association);
                    }
                }
                if (newCaseMap.get(caseId).PC_Care_Coordinator__c != oldCaseMap.get(caseId).PC_Care_Coordinator__c) {
                    if (newCaseMap.get(caseId).PC_Care_Coordinator__c != null
                            && !existingCareCoordinators.contains(newCaseMap.get(caseId).PC_Care_Coordinator__c)) {
                        associationsToAdd.add(
                            new PC_Association__c (
                                PC_Program__c = caseId,
                                PC_Associated_User__c = newCaseMap.get(caseId).PC_Care_Coordinator__c,
                                PC_AssociationStatus__c = PC_Constants.ACTIVE,
                                PC_Role__c = PC_Constants.PC_ROLE_CARE_COORDINATOR
                            )
                        );
                    }else if(newCaseMap.get(caseId).PC_Care_Coordinator__c == null && oldCaseMap.get(caseId).PC_Care_Coordinator__c != null){
                        PC_AssociationTriggerHelper.AssociationWrapper association = new PC_AssociationTriggerHelper.AssociationWrapper();
                        association.accountUserId   = oldCaseMap.get(caseId).PC_Care_Coordinator__c;
                        association.associationRole = PC_Constants.PC_ROLE_CARE_COORDINATOR;
                        associationWrapper.add(association);
                    }
                }
            }
            caseToAssociationWrapper.put(caseId,associationWrapper);
        }

        System.debug('PC_AfterUpdateManageAssociationHandler : associationsToAdd: '+associationsToAdd);

        System.debug('PC_AfterUpdateManageAssociationHandler : caseToAssociationWrapper: '+caseToAssociationWrapper);
        if (!associationsToAdd.isEmpty()) {
            PC_AfterUpdateManageAssociationHandler.isExecuting = true;
            PC_Database.ins(associationsToAdd,false);
        }
        if(!caseToAssociationWrapper.isEmpty()){
            PC_AssociationTriggerHelper.deactivateAssociations(caseToAssociationWrapper);
        }
    }

    private static Map<Id, List<PC_Association__c>> getAssociationsByCaseIds(Set<Id> caseIds) {
        // FLS not needed as the code runs in system context
        List<PC_Association__c> allAssociationsOfCases = [
                SELECT ID, PC_Program__c, PC_Account__c, PC_AssociationStatus__c, PC_Associated_User__c, PC_Role__c
                FROM PC_Association__c
                WHERE PC_Program__c IN :caseIds AND PC_AssociationStatus__c = :PC_Constants.ACTIVE
                ORDER BY PC_Program__c
        ];

        Map<Id, List<PC_Association__c>> associationsByCaseId = new Map<Id, List<PC_Association__c>>();
        Id associationCaseId;
        List<PC_Association__c> existingAssociations;
        for(PC_Association__c association : allAssociationsOfCases) {
            associationCaseId = association.PC_Program__c;
            existingAssociations = new List<PC_Association__c>();
            if(associationsByCaseId.containsKey(associationCaseId)) {
                existingAssociations = associationsByCaseId.get(associationCaseId);
                existingAssociations.add(association);
            }
            else {
                existingAssociations.add(association);
            }
            associationsByCaseId.put(associationCaseId, existingAssociations);
        }
        return associationsByCaseId;

    }
}