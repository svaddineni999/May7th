/*********************************************************************************************************
Class Name      : PC_Trigger_Association 
Description     : trigger on PC_Association object. 
Created By      : Ajinkya Deshmukh
Created Date    : July 12, 2017
Modification Log:
-------------------------------------------------------------------------------------------------------------- 
Developer                        Date                   Description
--------------------------------------------------------------------------------------------------------------            
Ajinkya Deshmukh                 July 12, 2017          Initial Version
Mayuresh Patil                   Aug 28, 2017           PC-2128 PC303 FLS/CRUD Check for managed package and removed unwanted debugs
Mayuresh Patil                   Oct 17, 2017           PC-2069 Fixed HCO role expception
Shabda Bhujad                    Nov 14, 2017           PC-2485 Removing the reference to trigger state
Shabda Bhujad                    Jan 17, 2018           PC-2684 - Association Error for HCO account with no contact
Xiukai Ning                      Feb 28, 2019           PC-3775 - Code review. FLS is NOT needed in Triggers, as they always run in System Mode.
                                                        Trigger delegate class (handler) that has with Sharing keyword however, will apply user sharing.
                                                        We are removing all FLS and With Sharing keywords in the handlers.
Kishore Kanteti                 Aug 27,2021             PC-8068 - Removed FLS Check on DML Operations
Satheesh Kumar                  Nov 16, 2021            [PC-8213] Excluded FLS Check and added inherited sharing
****************************************************************************************************************/
public inherited sharing class PC_Trigger_Association extends PC_TriggerHandler {
    public static boolean isExecuting = false;

    override public void beforeInsertUpdate() {
        markAssociationInactive((List<PC_Association__c>) newList);
        checkExisitingAssociations((List<PC_Association__c>) newList);
    }

    override public void afterUpdate() {
        PC_Trigger_Association.isExecuting = true;
        processUpdateAssociation((Map<Id, PC_Association__c>) oldMap, (Map<Id, PC_Association__c>) newMap);
    }

    override public void afterInsert() {
        PC_Trigger_Association.isExecuting = true;
        processNewAssociation((List<PC_Association__c>) newList);
    }

    override public void afterDelete() {
        PC_Trigger_Association.isExecuting = true;
        processDeleteAssociation((List<PC_Association__c>) oldList);
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
            if (eachAssociation.PC_EndDate__c <= System.today()) {
                eachAssociation.PC_AssociationStatus__c = PC_Constants.INACTIVE;
            }
        }
    }

    /*
    * Method Name    : formulateMapAccountToContact
    * Author         : Ajinkya Deshmukh
    * Description    : This is a helper method which returns a map
    *                   of AccountId to ContactId
    * Return Type    : Map<Id, Id>
    * Parameter      : List<PC_Association__c>
    */
    private Map<Id, Id> formulateMapAccountToContact (List<PC_Association__c> associations) {
        Map<Id, String> mapAccountIdToContactId = new Map<Id, Id>();
        /*
        * formulate accountToContact map
        */
        for (PC_Association__c eachAssociation : associations) {
            if (eachAssociation.PC_Account__c != null) {
                mapAccountIdToContactId.put(eachAssociation.PC_Account__c, null);
            }
        }

        for (Contact eachContact : [SELECT Id, AccountId FROM Contact WHERE AccountId IN : mapAccountIdToContactId.keySet()]) {
            mapAccountIdToContactId.put(eachContact.AccountId, eachContact.Id);
        }
        return mapAccountIdToContactId;
    }

    /*
    * Method Name    : getCaseTeamRoles
    * Author         : Ajinkya Deshmukh
    * Description    : This is a helper method which returns a map
    *                   by role Name with all the case team defined roles
    * Return Type    : Map<String, CaseTeamRole>
    * Parameter      :
    */
    private static Map<String, CaseTeamRole> getCaseTeamRoles() {
        Map<String, CaseTeamRole> caseTeamRolesMap = new Map<String, CaseTeamRole>();
        for(CaseTeamRole teamRole : [SELECT Id, Name,AccessLevel FROM CaseTeamRole LIMIT 1000]) {
            caseTeamRolesMap.put(teamRole.Name, teamRole);
        }
        return caseTeamRolesMap;
    }

    /*
    * Method Name    : checkExisitingAssociations
    * Author         : Ajinkya Deshmukh
    * Description    : This is a helper method to check if active
    *                  Association exist for the same lookup
    * Return Type    : void
    * Parameter      : List<Id> caseIds
    */
    private void checkExisitingAssociations (List<PC_Association__c> newAssociations) {
        Set<Id> caseIds = new Set<Id>();
        for (PC_Association__c eachAssociation : newAssociations) {
            caseIds.add(eachAssociation.PC_Program__c);
        }
        List<PC_Association__c> oldAssociations =  [SELECT Id, PC_Role__c, PC_Account__c, PC_Associated_User__c, PC_Program__c
                                                    FROM PC_Association__c
                                                    WHERE PC_Program__c
                                                            IN : caseIds
                                                    AND PC_AssociationStatus__c
                                                            =: PC_Constants.ACTIVE];
        for (PC_Association__c newAssociation : newAssociations) {
            if (newAssociation.PC_AssociationStatus__c == PC_Constants.ACTIVE) {
                for (PC_Association__c oldAssociation : oldAssociations) {
                    if (newAssociation.PC_Program__c == oldAssociation.PC_Program__c
                            &&
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

    /*
    * Method Name    : manageCaseUpdates
    * Author         : Ajinkya Deshmukh
    * Description    : This is a helper method which updates
    *                   case records
    * Return Type    : Map<String, CaseTeamRole>
    * Parameter      : List<Id> caseIds
    */
    private void manageCaseUpdates (List<Id> caseIds) {

        if( PC_Trigger_Case.isExecuting) {
            // if was executed during the same context avoid recursion
            return;
        }

        Map<Id, List<PC_Association__c>> mapCaseIdToAssociations = new Map<Id, List<PC_Association__c>>();
        for (PC_Association__c eachAssociation : [SELECT Id, PC_Role__c, PC_Account__c, PC_Associated_User__c, PC_Program__c
                                                    FROM PC_Association__c
                                                    WHERE PC_Program__c
                                                            IN : caseIds
                                                    AND PC_AssociationStatus__c =: PC_Constants.ACTIVE]) {

            if (mapCaseIdToAssociations.containsKey(eachAssociation.PC_Program__c)) {
                List<PC_Association__c> getAssociations = mapCaseIdToAssociations.get(eachAssociation.PC_Program__c);
                getAssociations.add(eachAssociation);
                mapCaseIdToAssociations.put(eachAssociation.PC_Program__c, getAssociations);
            } else {
                mapCaseIdToAssociations.put(eachAssociation.PC_Program__c, new List<PC_Association__c> {eachAssociation});
            }
        }

        Map<Id, Case> mapIdToCase = new Map<Id, Case>([SELECT Id, PC_Physician__c, PC_Reimbursment_Specialist__c, PC_Care_Coordinator__c FROM Case WHERE Id IN : caseIds]);

        for (Id eachCaseId : caseIds) {
            Id physicianId = null;
            Id reimbursementSpId = null;
            Id careCoordinatorId = null;
            if (mapCaseIdToAssociations.containsKey(eachCaseId)) {
                for (PC_Association__c eachAssociation : mapCaseIdToAssociations.get(eachCaseId)) {
                    physicianId = (eachAssociation.PC_Account__c != null && eachAssociation.PC_Role__c == PC_Constants.ROLE_TREATING_PHYSICIAN) ? eachAssociation.PC_Account__c : (physicianId != null ? physicianId : null);
                    reimbursementSpId = (eachAssociation.PC_Associated_User__c != null && eachAssociation.PC_Role__c == PC_Constants.PC_ROLE_REIMBURSEMENT_SPECIALIST) ? eachAssociation.PC_Associated_User__c : (reimbursementSpId != null ? reimbursementSpId : null);
                    careCoordinatorId = (eachAssociation.PC_Associated_User__c != null && eachAssociation.PC_Role__c == PC_Constants.PC_ROLE_CARE_COORDINATOR) ? eachAssociation.PC_Associated_User__c : (careCoordinatorId != null ? careCoordinatorId : null);
                }
            }

            mapIdToCase.get(eachCaseId).PC_Physician__c = physicianId;
            mapIdToCase.get(eachCaseId).PC_Reimbursment_Specialist__c = reimbursementSpId;
            mapIdToCase.get(eachCaseId).PC_Care_Coordinator__c = careCoordinatorId;
        }
        PC_Database.upd(mapIdToCase.values(),false);
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
        * Varible declaration
        */
        List<Id> parentIds = new List<Id>();
        List<Id> memberIds = new List<Id>();
        List<String> associationRole = new List<String>();
        Set<Id> casesToUpdate = new Set<Id>();
        Map<Id, String> mapAccountIdToContactId = new Map<Id, Id>();
        List<CaseTeamMember> caseTeamRecordsToDelete = new List<CaseTeamMember>();

        mapAccountIdToContactId = formulateMapAccountToContact(oldAssociationsList);

        /*
        * formulate list of parentIds and memberIds
        */
        for (PC_Association__c eachAssociation : oldAssociationsList) {
            if (eachAssociation.PC_AssociationStatus__c == PC_Constants.ACTIVE) {
                casesToUpdate.add(eachAssociation.PC_Program__c);
                parentIds.add(eachAssociation.PC_Program__c);
                associationRole.add(eachAssociation.PC_Role__c);
                memberIds.add(
                        eachAssociation.PC_Associated_User__c != null ?
                                (String) eachAssociation.PC_Associated_User__c :
                                (String) mapAccountIdToContactId.get(eachAssociation.PC_Account__c)
                );
            }
        }

        List<CaseTeamMember> teamMembers = [SELECT Id
        FROM CaseTeamMember
        WHERE ParentId
                IN : parentIds
        AND MemberId
                IN: memberIds];

        /*
        * Check if the case has any other associations of the same role
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
        manageCaseUpdates(new List<Id>(casesToUpdate));
    }

    /*
    * Method Name    : processUpdateAssociation
    * Author         : Ajinkya Deshmukh
    * Description    : Helper method to handle after update
    * Return Type    : void
    * Parameter      : Map<Id, PC_Association__c>, Map<Id, PC_Association__c>
    */
    private void processUpdateAssociation (Map<Id, PC_Association__c> oldAssociationMap, Map<Id, PC_Association__c> newAssociationMap) {
        List<Id> casesToUpdate = new List<Id>();
        List<Id> parentIds = new List<Id>();
        List<Id> memberIds = new List<Id>();
        List<CaseTeamMember> caseTeamMembersToInsert = new List<CaseTeamMember>();
        List<CaseTeamMember> caseTeamMembersToDelete = new List<CaseTeamMember>();
        Map<Id, PC_Association__c> updatedStatusAssociations = new Map<Id, PC_Association__c>();
        Map<String, CaseTeamRole> caseTeamRolesMap = getCaseTeamRoles();
        Map<Id, String> mapAccountIdToContactId = new Map<Id, Id>();
        mapAccountIdToContactId = formulateMapAccountToContact(newAssociationMap.values());

        for (Id eachAssociationId : newAssociationMap.keySet()) {
            if (newAssociationMap.get(eachAssociationId).PC_AssociationStatus__c
                    != oldAssociationMap.get(eachAssociationId).PC_AssociationStatus__c) {
                updatedStatusAssociations.put(eachAssociationId, newAssociationMap.get(eachAssociationId));
            }
        }

        for (Id eachAssociationId : updatedStatusAssociations.keySet()) {
            casesToUpdate.add(updatedStatusAssociations.get(eachAssociationId).PC_Program__c);
            if (updatedStatusAssociations.get(eachAssociationId).PC_AssociationStatus__c == PC_Constants.ACTIVE) {
                //PC-2684 - Association Error for HCO account with no contact
                Id memberId = updatedStatusAssociations.get(eachAssociationId).PC_Account__c!=null?mapAccountIdToContactId.get(updatedStatusAssociations.get(eachAssociationId).PC_Account__c) : updatedStatusAssociations.get(eachAssociationId).PC_Associated_User__c;
                if(memberId !=null) {
                    caseTeamMembersToInsert.add(
                    new CaseTeamMember(
                    ParentId = updatedStatusAssociations.get(eachAssociationId).PC_Program__c,
                    MemberId = memberId,
                    TeamRoleId = caseTeamRolesMap.get(updatedStatusAssociations.get(eachAssociationId).PC_Role__c).Id
                    ));
                }
            } else {
                parentIds.add(updatedStatusAssociations.get(eachAssociationId).PC_Program__c);
                memberIds.add(updatedStatusAssociations.get(eachAssociationId).PC_Account__c != null ?  mapAccountIdToContactId.get(updatedStatusAssociations.get(eachAssociationId).PC_Account__c) : updatedStatusAssociations.get(eachAssociationId).PC_Associated_User__c);
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
        System.debug('@@ caseTeamMembersToInsert '+caseTeamMembersToInsert);
        if (!caseTeamMembersToInsert.isEmpty()) {
            PC_Database.ins(caseTeamMembersToInsert,false);
        }
        if (!caseTeamMembersToDelete.isEmpty()) {
            PC_Database.del(caseTeamMembersToDelete,false);
        }
        /*
        * Manage case updates
        */
        manageCaseUpdates(new List<Id>(casesToUpdate));
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
        Map<String, CaseTeamRole> caseTeamRolesMap = getCaseTeamRoles();
        Map<Id, String> mapAccountIdToContactId = new Map<Id, Id>();
        mapAccountIdToContactId = formulateMapAccountToContact(newAssociations);

        for (PC_Association__c eachAssociation : newAssociations) {
            if (eachAssociation.PC_AssociationStatus__c == PC_Constants.ACTIVE) {
                casesToUpdate.add(eachAssociation.PC_Program__c);
                //PC-2684 - Association Error for HCO account with no contact
                Id memberId = eachAssociation.PC_Account__c != null ? mapAccountIdToContactId.get(eachAssociation.PC_Account__c) : eachAssociation.PC_Associated_User__c;
                if(memberId !=null) {
                    caseTeamMembersToInsert.add(
                            new CaseTeamMember(
                                    ParentId = eachAssociation.PC_Program__c,
                                    MemberId = memberId,
                                    TeamRoleId = caseTeamRolesMap.get(eachAssociation.PC_Role__c).Id
                            )
                    );
                }
            }
        }
        if (!caseTeamMembersToInsert.isEmpty()) {
            PC_Database.ins(caseTeamMembersToInsert,false);
        }
        /*
        * Manage case updates
        */
        manageCaseUpdates(new List<Id>(casesToUpdate));
    }
}