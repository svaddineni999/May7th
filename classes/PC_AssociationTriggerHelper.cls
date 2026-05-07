/*********************************************************************************************************
Class Name      : PC_AssociationTriggerHelper 
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
Haritha Reddy         21-Jan-2021              [PC-7102] Added FLS Check
Haritha Reddy         04-Mar-2021              [PC-7497] Added new filter to query old associations with FRM Role : To deactivate old association with same role
Kishore Kanteti           27-Aug-2021               [PC-8068] Commented FLS Check
Hitha Avalakki              Dec 2,2021             [PC-8372] Added code logic to update a case only if the Physician or Care coordinator or Reimbursement Specialist is changed in the care team association records.
****************************************************************************************************************/
/**
*   'with sharing' class level declaration is not required since trigger helper code runs in Trigger Context
*/
public inherited sharing class PC_AssociationTriggerHelper {
    
    /*
    * Method Name    : getCaseTeamRoles
    * Author         : Ajinkya Deshmukh
    * Description    : This is a helper method which returns a map
    *                  by role Name with all the case team defined roles
    * Return Type    : Map<String, CaseTeamRole>
    * Parameter      :
    */
    public static Map<String, CaseTeamRole> getCaseTeamRoles() {
        Map<String, CaseTeamRole> caseTeamRolesMap = new Map<String, CaseTeamRole>();

        for(CaseTeamRole teamRole : [SELECT Id, Name,AccessLevel FROM CaseTeamRole LIMIT 1000]) {
            caseTeamRolesMap.put(teamRole.Name, teamRole);
        }
        return caseTeamRolesMap;
    }
    
	/*
    * Method Name    : formulateMapAccountToContact
    * Author         : Ajinkya Deshmukh
    * Description    : This is a helper method which returns a map
    *                  of AccountId to ContactId
    * Return Type    : Map<Id, Id>
    * Parameter      : List<PC_Association__c>
    */
    public static Map<Id, Id> formulateMapAccountToContact (List<PC_Association__c> associations) {
        Map<Id, String> mapAccountIdToContactId = new Map<Id, Id>();
        /*
        * formulate accountToContact map
        */
        for (PC_Association__c eachAssociation : associations) {
            if (eachAssociation.PC_Account__c != null) {
                mapAccountIdToContactId.put(eachAssociation.PC_Account__c, null);
            }
        }
        /*
        //FLS check
        List<String> contactFields = new List<String>{'AccountId'};
        PC_Database.assertAccess(PC_Constants.CONTACT, PC_Database.Operation.Reading, contactFields);
        */
        for (Contact eachContact : [SELECT Id, AccountId FROM Contact WHERE AccountId IN : mapAccountIdToContactId.keySet()]) {
            mapAccountIdToContactId.put(eachContact.AccountId, eachContact.Id);
        }
        return mapAccountIdToContactId;
    }
    
    /*
    * Method Name    : manageCaseUpdates
    * Author         : Ajinkya Deshmukh
    * Description    : This is a helper method which updates
    *                   case records
    * Return Type    : Map<String, CaseTeamRole>
    * Parameter      : List<Id> caseIds
    */
    public static void manageCaseUpdates (List<Id> caseIds) {
        Map<Id, List<PC_Association__c>> mapCaseIdToAssociations = new Map<Id, List<PC_Association__c>>();

        /*List<String> fields = new List<String>{PC_Constants.getQualifiedAPIName('PC_Program__c'),
                PC_Constants.getQualifiedAPIName('PC_Account__c'),
                PC_Constants.getQualifiedAPIName('PC_Associated_User__c'),
                PC_Constants.getQualifiedAPIName('PC_Role__c')
        };
        PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Association__c'), PC_Database.Operation.Reading, fields);*/

        for (PC_Association__c eachAssociation : [SELECT Id, Name, PC_Role__c, PC_Account__c, PC_Associated_User__c, PC_Program__c
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
        /*List<String> caseFields = new List<String>{PC_Constants.getQualifiedAPIName('PC_Physician__c'),
                PC_Constants.getQualifiedAPIName('PC_Reimbursment_Specialist__c'),
                PC_Constants.getQualifiedAPIName('PC_Care_Coordinator__c')
        };
        PC_Database.assertAccess(PC_Constants.PC_CASE,PC_Database.Operation.Reading, caseFields);*/

        Map<Id, Case> mapIdToCase = new Map<Id, Case>([SELECT Id, PC_Physician__c, PC_Reimbursment_Specialist__c, PC_Care_Coordinator__c FROM Case WHERE Id IN : caseIds]);
        List<Case> listOfCasesToBeUpdated = new List<Case>();

        for (Id eachCaseId : caseIds) {
            Id existingPhyId,existingReimbursementSpId, existingCCId;
            Id physicianId,reimbursementSpId,careCoordinatorId;
            existingPhyId = mapIdToCase.get(eachCaseId).PC_Physician__c;
            existingReimbursementSpId = mapIdToCase.get(eachCaseId).PC_Reimbursment_Specialist__c;
            existingCCId = mapIdToCase.get(eachCaseId).PC_Care_Coordinator__c;
            if (mapCaseIdToAssociations.containsKey(eachCaseId)) {
                for (PC_Association__c eachAssociation : mapCaseIdToAssociations.get(eachCaseId)) {
                    if(eachAssociation.PC_Account__c != null && eachAssociation.PC_Role__c == PC_Constants.ROLE_TREATING_PHYSICIAN){
                        physicianId = eachAssociation.PC_Account__c;
                    }
                    if(eachAssociation.PC_Associated_User__c != null && eachAssociation.PC_Role__c == PC_Constants.PC_ROLE_REIMBURSEMENT_SPECIALIST){
                        reimbursementSpId = eachAssociation.PC_Associated_User__c;
                    }
                    if(eachAssociation.PC_Associated_User__c != null && eachAssociation.PC_Role__c == PC_Constants.PC_ROLE_CARE_COORDINATOR){
                        careCoordinatorId = eachAssociation.PC_Associated_User__c;
                    }
                }
            }

            Boolean isCaseUpdated=false;

            if(existingPhyId != physicianId){
                mapIdToCase.get(eachCaseId).PC_Physician__c = physicianId;
                isCaseUpdated = true;
            }
            if(existingReimbursementSpId != reimbursementSpId){
                mapIdToCase.get(eachCaseId).PC_Reimbursment_Specialist__c = reimbursementSpId;
                isCaseUpdated = true;
            }
            if(existingCCId != careCoordinatorId){
                mapIdToCase.get(eachCaseId).PC_Care_Coordinator__c = careCoordinatorId;
                isCaseUpdated = true;
            }

            if(isCaseUpdated){
                listOfCasesToBeUpdated.add(mapIdToCase.get(eachCaseId));
            }
        }

        if(listOfCasesToBeUpdated!=null && !listOfCasesToBeUpdated.isEmpty()){
            PC_Database.upd(listOfCasesToBeUpdated,false);
        }
    }
    /*
    * Method Name    : deactivateOldAssociations
    * Author         : Tejas Patel
    * Description    : This is a helper method which deactivates the old Associations
    * Return Type    : Map<Id, PC_Association__c>
    * Parameter      :
    */
    public static void deactivateOldAssociations(List<PC_Association__c> newAssociations) {
        List<PC_Association__c> oldAssociations = new List<PC_Association__c>();
        List<PC_Association__c> associationsToExpire = new List<PC_Association__c>();
        Set<Id> associationIds = new Set<Id>();
        Set<Id> programCaseIds = new Set<Id>();
        Set<Id> accountOrUserIds = new Set<Id>();

        for(PC_Association__c a : newAssociations){
            associationIds.add(a.Id);
            programCaseIds.add(a.PC_Program__c);
            Id tempId = (ID) a.PC_Account__c != null ? a.PC_Account__c : a.PC_Associated_User__c != null ? a.PC_Associated_User__c : null;
            accountOrUserIds.add(tempId);
        }

        /*List<String> fields = new List<String>{PC_Constants.getQualifiedAPIName('PC_Program__c'),
                PC_Constants.getQualifiedAPIName('PC_Account__c'),
                PC_Constants.getQualifiedAPIName('PC_Associated_User__c'),
                PC_Constants.getQualifiedAPIName('PC_Role__c')
        };
        PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Association__c'), PC_Database.Operation.Reading, fields);*/

        oldAssociations = [
                SELECT Id, PC_Program__c, PC_Account__c, PC_Associated_User__c, PC_Role__c
                FROM PC_Association__c
                WHERE PC_Program__c IN : programCaseIds
                //AND (PC_Account__c IN : accountOrUserIds OR PC_Associated_User__c IN : accountOrUserIds)
                AND (PC_Role__c =: PC_Constants.ROLE_TREATING_PHYSICIAN OR PC_Role__c =: PC_Constants.PC_ROLE_REIMBURSEMENT_SPECIALIST
                OR PC_Role__c =: PC_Constants.PC_ROLE_CARE_COORDINATOR OR PC_Role__c =: PC_Constants.ROLE_FIELD_REIMBURSEMENT_MANAGER )
                AND PC_AssociationStatus__c =: PC_Constants.ACTIVE
                AND ID NOT IN : associationIds
        ];

        for(PC_Association__c oldA : oldAssociations){
            for(PC_Association__c newA : newAssociations){
                if(oldA.PC_Program__c == newA.PC_Program__c && oldA.PC_Role__c == newA.PC_Role__c){
                    oldA.PC_AssociationStatus__c = PC_Constants.INACTIVE;
                    oldA.PC_EndDate__c = (Date) System.today();
                    associationsToExpire.add(oldA);
                    break;
                }
            }
        }

        if (!associationsToExpire.isEmpty()) {
            PC_Database.upd(associationsToExpire,false);
        }
    }

    /*
    * Method Name    : deactivateAssociations
    * Author         : Tejas Patel
    * Description    : This is a helper method which deactivates the old Associations
    * Return Type    : void
    * Parameter      :
    */
    public static void deactivateAssociations(Map<Id,List<AssociationWrapper>> caseToAssociationWrapper) {
        List<PC_Association__c> oldAssociations = new List<PC_Association__c>();
        List<PC_Association__c> associationsToExpire = new List<PC_Association__c>();
        Set<Id> programCaseIds = new Set<Id>();
        Set<Id> accountOrUserIds = new Set<Id>();

        for(Id caseId : caseToAssociationWrapper.keySet()){
            programCaseIds.add(caseId);
                for(AssociationWrapper association : caseToAssociationWrapper.get(caseId)){
                    accountOrUserIds.add(association.accountUserId);
                }
        }
        /*List<String> fields = new List<String>{PC_Constants.getQualifiedAPIName('PC_Program__c'),
                PC_Constants.getQualifiedAPIName('PC_Account__c'),
                PC_Constants.getQualifiedAPIName('PC_Associated_User__c'),
                PC_Constants.getQualifiedAPIName('PC_Role__c')
        };
        PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Association__c'), PC_Database.Operation.Reading, fields);*/


        oldAssociations = [
                SELECT Id, PC_Program__c, PC_Account__c, PC_Associated_User__c, PC_Role__c
                FROM PC_Association__c
                WHERE PC_Program__c IN : programCaseIds
                AND (PC_Account__c IN : accountOrUserIds OR PC_Associated_User__c IN : accountOrUserIds)
                AND (PC_Role__c =: PC_Constants.ROLE_TREATING_PHYSICIAN OR PC_Role__c =: PC_Constants.PC_ROLE_REIMBURSEMENT_SPECIALIST
                OR PC_Role__c =: PC_Constants.PC_ROLE_CARE_COORDINATOR OR PC_Role__c =: PC_Constants.ROLE_FIELD_REIMBURSEMENT_MANAGER )
                AND PC_AssociationStatus__c =: PC_Constants.ACTIVE
        ];

        for(PC_Association__c oldA : oldAssociations){
            for(AssociationWrapper association : caseToAssociationWrapper.get(oldA.PC_Program__c)){
                if((oldA.PC_Account__c == association.accountUserId || oldA.PC_Associated_User__c == association.accountUserId) &&
                        oldA.PC_Role__c == association.associationRole){
                    oldA.PC_AssociationStatus__c = PC_Constants.INACTIVE;
                    oldA.PC_EndDate__c = (Date) System.today();
                    associationsToExpire.add(oldA);
                    break;
                }
            }
        }

        if (!associationsToExpire.isEmpty()) {
            PC_Database.upd(associationsToExpire,false);
        }
    }

    public class AssociationWrapper{
        public ID accountUserId {get; set;}
        public String associationRole {get; set;}

        public AssociationWrapper(){
        }
    }
}