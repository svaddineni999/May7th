/*********************************************************************************************************
Class Name      : PC_DeactivateOldAssociationHandler
Description     : trigger on PC_Association__c object to deactivate the old Association when new Association for same role created
Created By      : Tejas Patel
Created Date    : Jan 4, 2018
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer                   Date                   	Description
--------------------------------------------------------------------------------------------------------------
Tejas Patel            		July 16, 2019        		Initial Version
Tejas Patel                 Aug 30, 2019                PC-5101 Only new associations with active status deactivate the old associations
Hitha Avalakki              May 25, 2021                [PC-7545]: Removed 'with sharing' class level declaration since trigger handler code runs in system context.
Satheesh Kumar              Nov 16, 2021                [PC-8213] Excluded FLS Check and added inherited sharing
****************************************************************************************************************/
/* PC-7545: 'with sharing' class level declaration is not required since trigger handler code runs in Trigger Context*/
public inherited sharing class PC_DeactivateOldAssociationHandler extends PC_TriggerHandler{
    override public void afterInsert() {
        system.debug('Trigger Handler ::: PC_DeactivateOldAssociationHandler');
        deactivateOldAssociations((List<PC_Association__c>) newList);
    }

    /*
    * Method Name    : deactivateOldAssociations
    * Author         : Tejas Patel
    * Description    : This is a helper deactivate the old Association when new Association for same role created
    * Return Type    : void
    * Parameter      : List<Id> newAssociations
    */
    private void deactivateOldAssociations (List<PC_Association__c> newAssociations) {
        List<PC_Association__c> deactivateAssociations = new List<PC_Association__c>();

        for(PC_Association__c eachAssociation : newAssociations) {
            if (eachAssociation.PC_AssociationStatus__c == PC_Constants.ACTIVE ) {
                deactivateAssociations.add(eachAssociation);
            }
        }
        if(!deactivateAssociations.isEmpty()){
            PC_AssociationTriggerHelper.deactivateOldAssociations(deactivateAssociations);
        }
    }
}