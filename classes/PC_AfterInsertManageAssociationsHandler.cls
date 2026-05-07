/*********************************************************************************************************
Class Name      : PC_AfterInsertManageAssociations 
Description     : trigger on Case object to Manage Associations after Insertion of new case 
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
****************************************************************************************************************/
public inherited sharing class PC_AfterInsertManageAssociationsHandler extends PC_TriggerHandler {
	public static boolean isExecuting = false;
	
	override public void afterInsert() {
        system.debug('Trigger Handler ::: PC_AfterInsertManageAssociationsHandler');
        PC_AfterInsertManageAssociationsHandler.isExecuting = false;
        if(PC_ProcessUpdateAssociationHandler.isExecuting || PC_ProcessNewAssociationHandler.isExecuting) {
            // If Triggered from the Association triggers , the cases have already been updated
            return;
        }
        system.debug('Trigger Handler ::: PC_AfterInsertManageAssociationsHandler -> manageAssociations');
        manageAssociations((List<Case>) newList);
    }

	/*
    * Method Name    : manageAssociations
    * Author         : Ajinkya Deshmukh
    * Description    : This method is used to create associations records for after insert
    * Return Type    : void
    * Parameter      : List<Case> newCaseList
    */
    private void manageAssociations(List<Case> newCaseList) {
        List<PC_Association__c> associationsToAdd = new List<PC_Association__c> ();
        
        for (Case eachCase : newCaseList) {
            if (eachCase.PC_Physician__c != null && (String.valueOf(eachCase.Type) == PC_Constants.CASE_PROGRAM_TYPE)) {
                associationsToAdd.add(
                        new PC_Association__c (
                                PC_Program__c = eachCase.Id,
                                PC_Account__c = eachCase.PC_Physician__c,
                                PC_AssociationStatus__c = PC_Constants.ACTIVE,
                                PC_Role__c = PC_Constants.ROLE_TREATING_PHYSICIAN
                        )
                );

            }
            if (eachCase.PC_Reimbursment_Specialist__c != null && (String.valueOf(eachCase.Type) == PC_Constants.CASE_PROGRAM_TYPE)) {
                associationsToAdd.add(
                        new PC_Association__c (
                                PC_Program__c = eachCase.Id,
                                PC_Associated_User__c = eachCase.PC_Reimbursment_Specialist__c,
                                PC_AssociationStatus__c = PC_Constants.ACTIVE,
                                PC_Role__c = PC_Constants.PC_ROLE_REIMBURSEMENT_SPECIALIST
                        )

                );

            }
            if (eachCase.PC_Care_Coordinator__c != null && (String.valueOf(eachCase.Type) == PC_Constants.CASE_PROGRAM_TYPE)) {
                associationsToAdd.add(
                        new PC_Association__c (
                                PC_Program__c = eachCase.Id,
                                PC_Associated_User__c = eachCase.PC_Care_Coordinator__c,
                                PC_AssociationStatus__c = PC_Constants.ACTIVE,
                                PC_Role__c = PC_Constants.PC_ROLE_CARE_COORDINATOR
                        )
                );
            }
        }
        if(!associationsToAdd.isEmpty()){
            PC_AfterInsertManageAssociationsHandler.isExecuting = true;
            PC_Database.ins(associationsToAdd,false);
        }
    }    
}