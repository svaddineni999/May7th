/*********************************************************************************************************
Class Name      : PC_CheckExistingAssociationHandler
Description     : trigger on PC_Association__c object to check for existing Associations
Created By      : Tejas Patel
Created Date    : Jan 4, 2018
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer                   Date                   	Description
--------------------------------------------------------------------------------------------------------------
Tejas Patel            		July 16, 2019        		Initial Version
Haritha Reddy             21-Jan-2021              [PC-7102] Added FLS Check
Hitha Avalakki            25-May-2021               [PC-7545]: Removed 'with sharing' class level declaration since trigger handler code runs in system context
Kishore Kanteti           27-Aug-2021               [PC-8068] Commented FLS Check
Satheesh Kumar            Nov 16, 2021              [PC-8213] Excluded FLS Check and added inherited sharing
****************************************************************************************************************/

/* PC-7545: 'with sharing' class level declaration is not required since trigger handler code runs in Trigger Context*/
public inherited sharing class PC_CheckExistingAssociationHandler extends PC_TriggerHandler{
    override public void beforeInsertUpdate() {
        system.debug('Trigger Handler ::: PC_CheckExistingAssociationHandler');
        checkExistingAssociations((List<PC_Association__c>) newList);
    }

    /*
    * Method Name    : checkExistingAssociations
    * Author         : Tejas Patel
    * Description    : This is a helper method to check if active
    *                  Association exist for the same lookup
    * Return Type    : void
    * Parameter      : List<Id> newAssociations
    */
    private void checkExistingAssociations (List<PC_Association__c> newAssociations) {
        Set<Id> caseIds = new Set<Id>();
        Set<Id> associationIds = new Set<Id>();
        for (PC_Association__c eachAssociation : newAssociations) {
            caseIds.add(eachAssociation.PC_Program__c);
            associationIds.add(eachAssociation.Id);
        }
        /*
            List<String> fields = new List<String>{PC_Constants.getQualifiedAPIName('PC_Program__c'),
                    PC_Constants.getQualifiedAPIName('PC_Account__c'),
                    PC_Constants.getQualifiedAPIName('PC_Associated_User__c'),
                    PC_Constants.getQualifiedAPIName('PC_Role__c')
            };
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Association__c'), PC_Database.Operation.Reading, fields);
        */
        List<PC_Association__c> oldAssociations =  [SELECT Id, PC_Role__c, PC_Account__c, PC_Associated_User__c, PC_Program__c
        FROM PC_Association__c
        WHERE PC_Program__c
                IN : caseIds
        AND PC_AssociationStatus__c
                =: PC_Constants.ACTIVE
        AND ID NOT IN :associationIds];
        for (PC_Association__c newAssociation : newAssociations) {
            if (newAssociation.PC_AssociationStatus__c == PC_Constants.ACTIVE) {
                for (PC_Association__c oldAssociation : oldAssociations) {
                    if (newAssociation.id != oldAssociation.id) {
                        if (newAssociation.PC_Program__c == oldAssociation.PC_Program__c
                                && (newAssociation.PC_Role__c == oldAssociation.PC_Role__c) &&
                                (
                                    ((newAssociation.PC_Account__c == oldAssociation.PC_Account__c) && newAssociation.PC_Account__c != null)
                                        ||
                                    ((newAssociation.PC_Associated_User__c == oldAssociation.PC_Associated_User__c) && newAssociation.PC_Associated_User__c != null)
                                )
                                ) {
                            newAssociation.addError(Label.PC_ExisitingAssociation);
                        }
                    }
                }
            }
        }
    }
}