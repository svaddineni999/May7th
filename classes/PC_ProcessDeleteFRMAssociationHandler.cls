/*********************************************************************************************************
Class Name      : PC_ProcessDeleteFRMAssociationHandler
Description     : trigger on PC_Association__c object to Process task reassignment for FRM Role after Delete Association
Created By      : Satheesh Kumar
Created Date    : May 2, 2022
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer                   Date                   	Description
--------------------------------------------------------------------------------------------------------------
Satheesh Kumar    		May 2, 2022        		Initial Version
Satheesh Kuamr          Sep 29, 2022           [PC-9236] Removed the dependency of Case lookup field for task Assignments and Reassignment
****************************************************************************************************************/

public inherited sharing class PC_ProcessDeleteFRMAssociationHandler extends PC_TriggerHandler {
    public static boolean isExecuting = false;

    override public void afterDelete() {
        processDeleteFRMAssociation((List<PC_Association__c>) oldList);
    }

    /**
     * This method is used to Processes Association, updates Assign To (OwnerId) of Task related to case
     * @param oldAssociationsList
     */
    private void processDeleteFRMAssociation(List<PC_Association__c> oldAssociationsList) {
        Map<Id, Map<String, String>> programCaseIdAndFRMRoleByValueMap = new Map<Id, Map<String, String>>();
        Set<Id> caseIdListNeedsTaskReassignment = new Set<Id>();
        List<Task> toBeUpdatedTaskList = new List<Task>();
        Map<ID, ID> mapCaseWiseDefaultOwner = new Map<ID, ID>();
        Map<Id, Id> taskProgramCaseMap = new Map<Id, Id> ();

        try {
            for (PC_Association__c assocRec : oldAssociationsList) {
                if (assocRec.PC_AssociationStatus__c == PC_Constants.ACTIVE && assocRec.PC_Role__c == PC_Constants.ROLE_FIELD_REIMBURSEMENT_MANAGER) {
                    caseIdListNeedsTaskReassignment.add(assocRec.PC_Program__c);
                    if (programCaseIdAndFRMRoleByValueMap.containsKey(assocRec.PC_Program__c)) {
                        Map<String, String> rolesByValueMap = programCaseIdAndFRMRoleByValueMap.get(assocRec.PC_Program__c);
                        if (!rolesByValueMap.containsKey(assocRec.PC_Role__c)) {
                            rolesByValueMap.put(assocRec.PC_Role__c, '');
                        }
                    } else {
                        Map<String, String> rolesByValueMap = new Map<String, String> ();
                        rolesByValueMap.put(assocRec.PC_Role__c, '');
                        programCaseIdAndFRMRoleByValueMap.put(assocRec.PC_Program__c, rolesByValueMap);
                    }
                }
            }

            if(caseIdListNeedsTaskReassignment.size() > 0) {
                /** Query service cases using program cases list. */
                //FLS is NOT needed in Triggers, as they always run in System Mode.
                Map<Id, Case> caseMap = new Map<Id, Case> ([Select Id, PC_Program__c, OwnerId, PC_Engagement_Program__r.PC_Program_Code__c from Case where Id IN :caseIdListNeedsTaskReassignment]);

                /** Find the default owner of Case based on task Triage setting*/
                if (!caseMap.isEmpty()) {
                    PC_TaskAssignmentHelper.findCaseWiseDefaultOwner(caseMap, mapCaseWiseDefaultOwner);
                }

                /** Fetch and store all tasks related to both program case and service cases. - Map of Case Id and list of related tasks */
                //FLS is NOT needed in Triggers, as they always run in System Mode.
                Map<Id, List<Task>> caseIdsAndTaskListMap = new Map<Id, List<Task>> ();
                List<Task> caseTaskList = [
                        SELECT Id, OwnerId, Status, WhatId, PC_Assign_to_Role__c
                        FROM Task
                        WHERE Status != :PC_Constants.PC_TASK_STATUS_COMPLETED AND PC_Assign_to_Role__c = :PC_Constants.ROLE_FIELD_REIMBURSEMENT_MANAGER
                        AND WhatId IN (SELECT Id FROM CASE where PC_Program__c IN: caseIdListNeedsTaskReassignment OR Id IN:caseIdListNeedsTaskReassignment)
                ];

                /** prepare Map of Task and ProgramCase */
                taskProgramCaseMap = PC_TaskAssignmentHelper.prepareTaskProgramCaseMap(caseTaskList);
                String programCaseId;

                /** Iterate caseTaskList and Create a map of Case Id and its Task and Service Case Task List*/
                if(!caseTaskList.isEmpty()) {
                    for (Task taskRec : caseTaskList) {
                        programCaseId = taskProgramCaseMap.get(taskRec.Id);
                        if (caseIdsAndTaskListMap.containsKey(programCaseId)) {
                            caseIdsAndTaskListMap.get(programCaseId).add(taskRec);
                        } else {
                            caseIdsAndTaskListMap.put(programCaseId, new List<Task>{taskRec});
                        }
                    }
                }

                /** Iterate the caseIdsAndTaskListMap */
                for (Id caseId : caseIdsAndTaskListMap.keySet()) {
                    for (Task task : caseIdsAndTaskListMap.get(caseId)) {
                        Map<String, String> programCaseRoleAndValueMap = programCaseIdAndFRMRoleByValueMap.get(caseId);
                        /** Iterate the map of role and its value */
                        for (String role : programCaseRoleAndValueMap.keySet()) {
                            if (role == PC_Constants.ROLE_FIELD_REIMBURSEMENT_MANAGER) {
                                task.OwnerId = String.isNotBlank(programCaseRoleAndValueMap.get(role)) ? programCaseRoleAndValueMap.get(role) : mapCaseWiseDefaultOwner.get(caseId);
                                toBeUpdatedTaskList.add(task);
                            }
                        }
                    }
                }
            }
            if(!toBeUpdatedTaskList.isEmpty()) {
                PC_Database.upd(toBeUpdatedTaskList, false);
            }
        } catch (Exception e) {
            PC_Utility.createExceptionLog(e);
        }
    }
}