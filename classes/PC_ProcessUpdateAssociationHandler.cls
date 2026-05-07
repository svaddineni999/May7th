/*********************************************************************************************************
Class Name      : PC_ProcessUpdateAssociationHandler
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
Mayruesh Patil              Apr 22, 2019            PC-4751 - Fixing condition flow for case team member roles.
Tejas Patel            		Aug 5, 2019             PC-5251 - Stopping recursive case update
Tejas Patel            		Aug 22, 2019            PC-5071 - If CaseTeamRole is not defined, only an association record is created, the error displayed has been removed
Kishore Kanteti             Aug 27,2021             PC-8068 - Removed FLS Check on DML Operations
Satheesh Kumar              Nov 16, 2021            [PC-8213] Excluded FLS Check and added inherited sharing
****************************************************************************************************************/
public inherited sharing class PC_ProcessUpdateAssociationHandler extends PC_TriggerHandler{
    public static boolean isExecuting = false;
    
   	override public void afterUpdate() {
        system.debug('Trigger Handler ::: PC_ProcessUpdateAssociationHandler');
        PC_ProcessUpdateAssociationHandler.isExecuting = false;
        processUpdateAssociation((Map<Id, PC_Association__c>) oldMap, (Map<Id, PC_Association__c>) newMap);
    }
    
    /*
    * Method Name    : processUpdateAssociation
    * Author         : Ajinkya Deshmukh
    * Description    : Helper method to handle after update
    * Return Type    : void
    * Parameter      : Map<Id, PC_Association__c>, Map<Id, PC_Association__c>
    */
    private void processUpdateAssociation (Map<Id, PC_Association__c> oldAssociationMap, Map<Id, PC_Association__c> newAssociationMap) {
        System.debug('Entered PC_ProcessUpdateAssociationHandler.processUpdateAssociation');

        List<Id> casesToUpdate = new List<Id>();
        List<Id> parentIds = new List<Id>();
        List<Id> memberIds = new List<Id>();
        List<CaseTeamMember> caseTeamMembersToInsert = new List<CaseTeamMember>();
        List<CaseTeamMember> caseTeamMembersToDelete = new List<CaseTeamMember>();
        Map<Id, PC_Association__c> updatedStatusAssociations = new Map<Id, PC_Association__c>();
        Map<String, CaseTeamRole> caseTeamRolesMap = PC_AssociationTriggerHelper.getCaseTeamRoles();
        Map<Id, String> mapAccountIdToContactId = new Map<Id, Id>();
        mapAccountIdToContactId = PC_AssociationTriggerHelper.formulateMapAccountToContact(newAssociationMap.values());

        for (Id eachAssociationId : newAssociationMap.keySet()) {
            if (newAssociationMap.get(eachAssociationId).PC_AssociationStatus__c
                    != oldAssociationMap.get(eachAssociationId).PC_AssociationStatus__c) {
                updatedStatusAssociations.put(eachAssociationId, newAssociationMap.get(eachAssociationId));
            }
        }

        for (Id eachAssociationId : updatedStatusAssociations.keySet()) {
            if(updatedStatusAssociations.get(eachAssociationId).PC_Role__c == PC_Constants.PC_ROLE_CARE_COORDINATOR || updatedStatusAssociations.get(eachAssociationId).PC_Role__c == PC_Constants.PC_ROLE_REIMBURSEMENT_SPECIALIST
                    || updatedStatusAssociations.get(eachAssociationId).PC_Role__c == PC_Constants.ROLE_TREATING_PHYSICIAN ){
                casesToUpdate.add(updatedStatusAssociations.get(eachAssociationId).PC_Program__c);
            }
            if((updatedStatusAssociations.get(eachAssociationId).PC_Account__c != null && mapAccountIdToContactId.get(updatedStatusAssociations.get(eachAssociationId).PC_Account__c) != null) || updatedStatusAssociations.get(eachAssociationId).PC_Associated_User__c != null) {
                if (updatedStatusAssociations.get(eachAssociationId).PC_AssociationStatus__c == PC_Constants.ACTIVE) {
                    if (caseTeamRolesMap.containsKey(updatedStatusAssociations.get(eachAssociationId).PC_Role__c)){
                        caseTeamMembersToInsert.add(
                            new CaseTeamMember(
                                    ParentId = updatedStatusAssociations.get(eachAssociationId).PC_Program__c,
                                    MemberId = updatedStatusAssociations.get(eachAssociationId).PC_Account__c != null ? mapAccountIdToContactId.get(updatedStatusAssociations.get(eachAssociationId).PC_Account__c) : updatedStatusAssociations.get(eachAssociationId).PC_Associated_User__c,
                                    TeamRoleId = caseTeamRolesMap.get(updatedStatusAssociations.get(eachAssociationId).PC_Role__c).Id
                            )
                    );
                    }
                } else {
                        parentIds.add(updatedStatusAssociations.get(eachAssociationId).PC_Program__c);
                        memberIds.add(updatedStatusAssociations.get(eachAssociationId).PC_Account__c != null ? mapAccountIdToContactId.get(updatedStatusAssociations.get(eachAssociationId).PC_Account__c) : updatedStatusAssociations.get(eachAssociationId).PC_Associated_User__c);
                }
            }
        }

        if (!parentIds.isEmpty() && !memberIds.isEmpty()) {
            caseTeamMembersToDelete =  [SELECT Id
            FROM CaseTeamMember
            WHERE ParentId
                    IN : parentIds
            AND MemberId
                    IN : memberIds];
        }
        if (!caseTeamMembersToInsert.isEmpty()) {
            PC_Database.ins(caseTeamMembersToInsert,false);
        }
        if (!caseTeamMembersToDelete.isEmpty()) {
            PC_Database.del(caseTeamMembersToDelete,false);
        }
        /*
        * Manage case updates
        * Cases will get updated only after deactivation of old Associations when WCD is triggered from Associations
        */
        if(!casesToUpdate.isEmpty() && ((PC_AfterInsertManageAssociationsHandler.isExecuting == false && PC_AfterUpdateManageAssociationHandler.isExecuting == false) || PC_WorkCaseDistributionForAssocHandler.isProcessed == true)){
            PC_ProcessUpdateAssociationHandler.isExecuting = true;
            //PC_WorkCaseDistributionForAssocHandler.isProcessed = false;  // Commenting this line. Since WCD is going into recursion if the new association record has valid WCD config.
            PC_AssociationTriggerHelper.manageCaseUpdates(new List<Id>(casesToUpdate));
        }
    }
}