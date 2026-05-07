/*********************************************************************************************************
Class Name      : PC_ProcessDeleteAssociation 
Description     : trigger on PC_Association__c object to Process Association after Delete
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
Vijay Kashikar              21-Jan-21               [PC-7102] Added FLS Checks
Kishore Kanteti           27-Aug-2021               [PC-8068] Commented FLS Check
Satheesh Kumar            Nov 16, 2021              [PC-8213] Excluded FLS Check and added inherited sharing
****************************************************************************************************************/
public inherited sharing class PC_ProcessDeleteAssociationHandler extends PC_TriggerHandler{
	public static boolean isExecuting = false;
    
    override public void afterDelete() {
        PC_ProcessDeleteAssociationHandler.isExecuting = false;
        processDeleteAssociation((List<PC_Association__c>) oldList);
    }
    
    /*
    * Method Name    : processDeleteAssociation
    * Author         : Ajinkya Deshmukh
    * Description    : Helper method to handle after delete
    * Return Type    : void
    * Parameter      : List<PC_Association__c>
    */
    private void processDeleteAssociation(List<PC_Association__c> oldAssociationsList) {
        /*
        * Variable declaration
        */
        List<Id> parentIds = new List<Id>();
        List<Id> memberIds = new List<Id>();
        List<String> associationRole = new List<String>();
        Set<Id> casesToUpdate = new Set<Id>();
        Map<Id, String> mapAccountIdToContactId = new Map<Id, Id>();
        List<CaseTeamMember> caseTeamRecordsToDelete = new List<CaseTeamMember>();

        mapAccountIdToContactId = PC_AssociationTriggerHelper.formulateMapAccountToContact(oldAssociationsList);

        /*
        * formulate list of parentIds and memberIds
        */
        for (PC_Association__c eachAssociation : oldAssociationsList) {
            if (eachAssociation.PC_AssociationStatus__c == PC_Constants.ACTIVE) {
                if(eachAssociation.PC_Role__c == PC_Constants.PC_ROLE_CARE_COORDINATOR || eachAssociation.PC_Role__c == PC_Constants.PC_ROLE_REIMBURSEMENT_SPECIALIST
                        || eachAssociation.PC_Role__c == PC_Constants.ROLE_TREATING_PHYSICIAN ){
                    casesToUpdate.add(eachAssociation.PC_Program__c);
                }

                parentIds.add(eachAssociation.PC_Program__c);
                associationRole.add(eachAssociation.PC_Role__c);
                memberIds.add(
                        eachAssociation.PC_Associated_User__c != null ?
                                (String) eachAssociation.PC_Associated_User__c :
                                (String) mapAccountIdToContactId.get(eachAssociation.PC_Account__c)
                );
            }
        }
        /*List<String> teamMemberFields = new List<String>();
        teamMemberFields.add('Id');
        teamMemberFields.add('ParentId');
        teamMemberFields.add('MemberId');
        PC_Database.assertAccess('CaseTeamMember', PC_Database.Operation.Reading, teamMemberFields);*/

        List<CaseTeamMember> teamMembers = [SELECT Id
        FROM CaseTeamMember
        WHERE ParentId
                IN : parentIds
        AND MemberId
                IN: memberIds];
        /*
        * Check if the case has any other associations of the same role
        */
        /*List<String> associationFields = new List<String>();
        associationFields.add('Id');
        associationFields.add(PC_Constants.getQualifiedAPIName('PC_Program__c'));
        associationFields.add(PC_Constants.getQualifiedAPIName('PC_Role__c'));
        PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Association__c'), PC_Database.Operation.Reading, associationFields);
        */
        for (PC_Association__c existingAssociation : [SELECT Id, PC_Program__c
        FROM PC_Association__c
        WHERE PC_Program__c
                IN : parentIds
        AND PC_Role__c
                IN : associationRole]) {
            casesToUpdate.add(existingAssociation.PC_Program__c);
        }
        /*
        * delete case Team Members
        */
        if(!teamMembers.isEmpty()) {
            PC_Database.del(teamMembers,false);
        }
        /*
        * Manage case updates
        */
        PC_AssociationTriggerHelper.manageCaseUpdates(new List<Id>(casesToUpdate));
    }
}