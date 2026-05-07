/*********************************************************************************************************
Class Name      : PC_MarkAssociationInactive 
Description     : trigger on PC_Association__c object to Mark Associaltion as inactive 
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
Mayuresh Patil              Apr 22, 2019            PC-4752 - Duplication check should not block editing of association record
Satheesh Kumar              Nov 16, 2021            [PC-8213] Excluded FLS Check and added inherited sharing
****************************************************************************************************************/
public inherited sharing class PC_MarkAssociationInactiveHandler extends PC_TriggerHandler{
  	override public void beforeInsertUpdate() {
        markAssociationInactive((List<PC_Association__c>) newList);
    }

    /*
    * Method Name    : markAssociationInactive
    * Author         : Ajinkya Deshmukh
    * Description    : This method updates the Association status to
    *                   Inactive if the end date is less or equlas today.
    * Return Type    : void
    * Parameter      : List<PC_Association__c> newAssociations
    */
    private void markAssociationInactive(List<PC_Association__c> newAssociations) {
        for (PC_Association__c eachAssociation : newAssociations) {
            if (eachAssociation.PC_EndDate__c < System.today()) {
                eachAssociation.PC_AssociationStatus__c = PC_Constants.INACTIVE;
            }
        }
    }
}