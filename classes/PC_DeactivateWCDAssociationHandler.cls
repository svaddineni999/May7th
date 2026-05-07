/*********************************************************************************************************
Class Name      : PC_DeactivateWCDAssociationHandler
Description     : beforeInsert trigger on PC_Association__c object to Deactivate all existing active association when new associations is created via WCD or WCR
Created By      : Satheesh Kumar
Created Date    : Jul 28, 2022
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer                   Date                   	Description
--------------------------------------------------------------------------------------------------------------
Satheesh Kumar    		Jul 28, 2022        		Initial Version
****************************************************************************************************************/

public inherited sharing class PC_DeactivateWCDAssociationHandler extends PC_TriggerHandler {
    override public void beforeInsert() {
        system.debug('Trigger Handler ::: PC_DeactivateWCDAssociationHandler');
        if (PC_WorkCaseDistributionForCaseHandler.isProcessed == true || PC_WorkCaseDistributionForAssocHandler.isProcessed == true ||
                PC_WorkCaseRedistributionForAccHandler.isProcessed == true || PC_WorkCaseRedistributionForAddrHandler.isProcessed == true ||
                PC_WorkCaseRedistributionForUserHandler.isProcessed == true) {
            deactivateOldWCDAssociations((List<PC_Association__c>) newList);
        }
    }

    /**
     * This method is used to deactivate all active associations created via WCD
     * @param newAssociations
     */
    private void deactivateOldWCDAssociations (List<PC_Association__c> newAssociations) {
        Set<Id> programCaseIds = new Set<Id>();
        List<PC_Association__c> associationsToExpire = new List<PC_Association__c>();

        for(PC_Association__c eachAssociation : newAssociations) {
            if(eachAssociation.PC_AssociationStatus__c == PC_Constants.ACTIVE && eachAssociation.PC_IsCreatedViaWCD__c) {
                programCaseIds.add(eachAssociation.PC_Program__c);
            }
        }
        if(!programCaseIds.isEmpty()){
            associationsToExpire = getAllActiveAssociations(programCaseIds);

            if (!associationsToExpire.isEmpty()) {
                PC_Database.upd(associationsToExpire, false);
            }
        }
    }

    /**
      * This method is used to get all active associations created via WCD
      * @param programCaseIds
      */
    private List<PC_Association__c> getAllActiveAssociations(Set<Id> programCaseIds) {
        List<PC_Association__c> oldAssociations = new List<PC_Association__c>();
        List<PC_Association__c> associationsToExpire = new List<PC_Association__c>();

        //FLS is NOT needed in Triggers, as they always run in System Mode.
        oldAssociations = [
                SELECT Id, PC_Program__c
                FROM PC_Association__c
                WHERE PC_Program__c IN :programCaseIds AND PC_AssociationStatus__c = :PC_Constants.ACTIVE
                AND PC_IsCreatedViaWCD__c = :PC_Constants.TRUE_BOOLEAN
        ];

        for (PC_Association__c oldA : oldAssociations) {
            oldA.PC_AssociationStatus__c = PC_Constants.INACTIVE;
            oldA.PC_EndDate__c = (Date) System.today();
            associationsToExpire.add(oldA);
        }
        return associationsToExpire;
    }
}