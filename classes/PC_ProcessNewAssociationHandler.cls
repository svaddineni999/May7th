/*********************************************************************************************************
Class Name      : PC_ProcessNewAssociationHandler
Description     : Trigger on Association object to Manage Case Team Member and Update the Program Case
Created By      : Tejas Patel
Created Date    : Jan 4, 2018
Modification Log:
-------------------------------------------------------------------------------------------------------------- 
Developer                   Date                   	Description
--------------------------------------------------------------------------------------------------------------            
Tejas Patel            		Jan 4, 2018        		Initial Version
Mayuresh Patil              Feb 7,2019              PC-4341 - Ability to add non contact accounts as associations
Xiukai Ning                 Feb 28, 2019            PC-3775 - Code review. FLS is NOT needed in Triggers, as they always run in System Mode.
                                                    Trigger delegate class (handler) that has with Sharing keyword however, will apply user sharing.
                                                    We are removing all FLS and With Sharing keywords in the handlers.
Xiukai Ning                 Mar 8, 2019             PC-3404 - Provide readable error message if user is creating an Association whose role is not configured in CaseTeamRole
Mayruesh Patil              Apr 22, 2019            PC-4751 - Fixing condition flow for case team member roles.
Tejas Patel            		Aug 5, 2019             PC-5251 - Stopping recursive case update
Tejas Patel            		Aug 22, 2019            PC-5071 - If CaseTeamRole is not defined, only an association record is created, the error displayed has been removed
Kishore Kanteti             Aug 27,2021             PC-8068 - Removed FLS Check on DML Operation
Satheesh Kumar              Nov 16, 2021            [PC-8213] Excluded FLS Check and added inherited sharing
Hitha Avalakki              Dec 02, 2021            [PC-8372] Removed the multiple flag checks
****************************************************************************************************************/
public inherited sharing class PC_ProcessNewAssociationHandler extends PC_TriggerHandler{
 	public static boolean isExecuting = false;

    override public void afterInsert() {
        system.debug('Trigger Handler ::: PC_ProcessNewAssociationHandler');
        PC_ProcessNewAssociationHandler.isExecuting = false;
        processNewAssociation((List<PC_Association__c>) newList);
    }
    
    /*
    * Method Name    : processNewAssociation
    * Author         : Ajinkya Deshmukh
    * Description    : Helper method to handle after insert
    * Return Type    : void
    * Parameter      : Map<Id, PC_Association__c>
    */
    private void processNewAssociation (List<PC_Association__c> newAssociations) {
        Set<Id> casesToUpdate = new Set<Id>();
        List<CaseTeamMember> caseTeamMembersToInsert = new List<CaseTeamMember>();
        Map<String, CaseTeamRole> caseTeamRolesMap = PC_AssociationTriggerHelper.getCaseTeamRoles();
        Map<Id, String> mapAccountIdToContactId = new Map<Id, Id>();
        mapAccountIdToContactId = PC_AssociationTriggerHelper.formulateMapAccountToContact(newAssociations);
        for (PC_Association__c eachAssociation : newAssociations) {
            if (eachAssociation.PC_AssociationStatus__c == PC_Constants.ACTIVE ) {
                if(eachAssociation.PC_Role__c == PC_Constants.PC_ROLE_CARE_COORDINATOR || eachAssociation.PC_Role__c == PC_Constants.PC_ROLE_REIMBURSEMENT_SPECIALIST
                        || eachAssociation.PC_Role__c == PC_Constants.ROLE_TREATING_PHYSICIAN ){
                    casesToUpdate.add(eachAssociation.PC_Program__c);
                }
                    if ((mapAccountIdToContactId.get(eachAssociation.PC_Account__c) != null && eachAssociation.PC_Account__c != null) || eachAssociation.PC_Associated_User__c != null) {
                        if (caseTeamRolesMap.containsKey(eachAssociation.PC_Role__c)){
                        caseTeamMembersToInsert.add(
                                new CaseTeamMember(
                                        ParentId = eachAssociation.PC_Program__c,
                                        MemberId = eachAssociation.PC_Account__c != null ? mapAccountIdToContactId.get(eachAssociation.PC_Account__c) : eachAssociation.PC_Associated_User__c,
                                        TeamRoleId = caseTeamRolesMap.get(eachAssociation.PC_Role__c).Id
                                )
                        );
                        }
                    }
            }
        }

        if (!caseTeamMembersToInsert.isEmpty()) {
            PC_Database.ins(caseTeamMembersToInsert,false);
        }
        /*
        * Manage case updates
        */

        if(!casesToUpdate.isEmpty()){
            PC_ProcessNewAssociationHandler.isExecuting = true;
            PC_AssociationTriggerHelper.manageCaseUpdates(new List<Id>(casesToUpdate));
        }
    }
}