/*********************************************************************************************************
Class Name      : PC_AssignToCustomRoleAssociationHandler
Description     : trigger on PC_Association__c object to Process task reassignment on creation and updation of Custom Role(Association)
Created By      : Satheesh Kumar
Created Date    : July 26, 2022
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer                   Date                     Description
--------------------------------------------------------------------------------------------------------------
Satheesh Kumar          July 26, 2022              Initial Version
Satheesh Kuamr          Sep 29, 2022               [PC-9236] Removed the dependency of Case lookup field for task Assignments and Reassignment
****************************************************************************************************************/

public inherited sharing class PC_AssignToCustomRoleAssociationHandler extends PC_TriggerHandler {
    public static boolean isExecuting = false;

    override public void afterInsert() {
        processAssignToCustomRole((List<PC_Association__c>) newList, (Map<Id, PC_Association__c>) oldMap);
    }

    override public void afterUpdate() {
        processAssignToCustomRole((List<PC_Association__c>) newList, (Map<Id, PC_Association__c>) oldMap);
    }

    /**
     * This method is used to Processes FRM Association, updates Assign To (OwnerId) of Task related to case
     * @param newAssociationList - New Association List
     * @param oldAssociationMap - Old Association Map
     */
    private void processAssignToCustomRole(List<PC_Association__c> newAssociationList, Map<Id, PC_Association__c> oldAssociationMap) {
        Boolean roleInactivated = false; // Else the role and its user will always exist.
        Map<Id, Map<String, String>> programCaseIdAndCustomRoleByValueMap = new Map<Id, Map<String, String>>();
        List<Task> toBeUpdatedTaskList = new List<Task>();
        List<String> rolesNotConsidered = new List<String>{PC_Constants.PC_ROLE_CARE_COORDINATOR, PC_Constants.PC_ROLE_REIMBURSEMENT_SPECIALIST, PC_Constants.ROLE_FIELD_REIMBURSEMENT_MANAGER};
        MAP<ID, ID> mapCaseWiseDefaultOwner = new MAP<ID, ID>();
        Map<Id, Id> taskProgramCaseMap = new Map<Id, Id> ();

        try {
            /** Iterate all Custom role associations and Create a map of program case Id and Map <Role, Value> */
            for (PC_Association__c assocRec : newAssociationList) {
                if ((oldAssociationMap == null || (oldAssociationMap != null && (assocRec.PC_AssociationStatus__c != oldAssociationMap.get(assocRec.Id).PC_AssociationStatus__c)))
                        && !(rolesNotConsidered.contains(assocRec.PC_Role__c))
                        && assocRec.PC_AssociationStatus__c == PC_Constants.ACTIVE) {  // Handles After insert and After Update of Association from Inactive to Active
                    if (programCaseIdAndCustomRoleByValueMap.containsKey(assocRec.PC_Program__c)) {
                        Map<String, String> rolesByValueMap = programCaseIdAndCustomRoleByValueMap.get(assocRec.PC_Program__c);
                        if (!rolesByValueMap.containsKey(assocRec.PC_Role__c)) {
                            if (String.isNotBlank(assocRec.PC_Associated_User__c)) {
                                rolesByValueMap.put(assocRec.PC_Role__c, assocRec.PC_Associated_User__c);
                            }
                        }
                    } else {
                        Map<String, String> rolesByValueMap = new Map<String, String> ();
                        if (String.isNotBlank(assocRec.PC_Associated_User__c)) {
                            rolesByValueMap.put(assocRec.PC_Role__c, assocRec.PC_Associated_User__c);
                            programCaseIdAndCustomRoleByValueMap.put(assocRec.PC_Program__c, rolesByValueMap);
                        }
                    }
                } else if ((oldAssociationMap != null && (assocRec.PC_AssociationStatus__c != oldAssociationMap.get(assocRec.Id).PC_AssociationStatus__c))
                        && !(rolesNotConsidered.contains(assocRec.PC_Role__c))
                        && assocRec.PC_AssociationStatus__c == PC_Constants.INACTIVE) {   // Handles After Update of Association from active to Inactive
                    if (programCaseIdAndCustomRoleByValueMap.containsKey(assocRec.PC_Program__c)) {
                        Map<String, String> rolesByValueMap = programCaseIdAndCustomRoleByValueMap.get(assocRec.PC_Program__c);
                        if (!rolesByValueMap.containsKey(assocRec.PC_Role__c)) {
                            if (String.isNotBlank(assocRec.PC_Associated_User__c)) {
                                rolesByValueMap.put(assocRec.PC_Role__c, '');
                            }
                        }
                    } else {
                        Map<String, String> rolesByValueMap = new Map<String, String> ();
                        if (String.isNotBlank(assocRec.PC_Associated_User__c)) {
                            rolesByValueMap.put(assocRec.PC_Role__c, '');
                            programCaseIdAndCustomRoleByValueMap.put(assocRec.PC_Program__c, rolesByValueMap);
                        }
                    }
                    roleInactivated = true;
                }
            }

            if (programCaseIdAndCustomRoleByValueMap != null && !programCaseIdAndCustomRoleByValueMap.isEmpty()) {
                /** Query cases using program cases list. */
                //FLS is NOT needed in Triggers, as they always run in System Mode.
                Map<Id, Case> caseMap = new Map<Id, Case> ([Select Id, PC_Program__c, OwnerId, PC_Engagement_Program__r.PC_Program_Code__c from Case where Id IN :programCaseIdAndCustomRoleByValueMap.keySet()]);

                /** Find the default owner of Case based on task Triage setting*/
                if (roleInactivated && caseMap != null && !caseMap.isEmpty()) {
                    PC_TaskAssignmentHelper.findCaseWiseDefaultOwner(caseMap, mapCaseWiseDefaultOwner);
                }

                /** Fetch and store all tasks related to both program case and service cases. - Map of Case Id and list of related tasks */
                //FLS is NOT needed in Triggers, as they always run in System Mode.
                Map<Id, List<Task>> caseIdsAndTaskListMap = new Map<Id, List<Task>> ();
                List<Task> caseTaskList = [
                        SELECT Id, OwnerId, Status, WhatId, PC_Assign_to_Role__c
                        FROM Task
                        WHERE Status != :PC_Constants.PC_TASK_STATUS_COMPLETED AND PC_Assign_to_Role__c != null AND PC_Assign_to_Role__c NOT IN :rolesNotConsidered
                        AND WhatId IN (SELECT Id FROM CASE where PC_Program__c IN:programCaseIdAndCustomRoleByValueMap.keySet() OR Id IN:programCaseIdAndCustomRoleByValueMap.keySet())
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
                        Map<String, String> programCaseRoleAndValueMap = programCaseIdAndCustomRoleByValueMap.get(caseId);
                        /** Iterate the map of role and its value */
                        for (String role : programCaseRoleAndValueMap.keySet()) {
                            if (role == task.PC_Assign_to_Role__c) {
                                task.OwnerId = String.isNotBlank(programCaseRoleAndValueMap.get(role)) ? programCaseRoleAndValueMap.get(role) : mapCaseWiseDefaultOwner.get(caseId);
                                toBeUpdatedTaskList.add(task);
                            }
                        }
                    }
                }
            }

            if (!toBeUpdatedTaskList.isEmpty()) {
                PC_Database.upd(toBeUpdatedTaskList, false);
            }
        } catch (Exception e) {
            PC_Utility.createExceptionLog(e);
        }
    }
}