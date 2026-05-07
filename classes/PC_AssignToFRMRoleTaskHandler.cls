/*********************************************************************************************************
Class Name      : PC_AssignToFRMRoleTaskHandler
Description     : Trigger on Task object to assign corresponding FRM Care team member as Task Owner
Created Date    : Mar 01, 2021
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer          Date                   Description
--------------------------------------------------------------------------------------------------------------
Haritha Reddy      Mar 01, 2021         [PC-7471] Initial Version
Satheesh Kumar     Nov 16, 2021         [PC-8213] Excluded FLS Check and added inherited sharing
Satheesh Kumar     May 23, 2022         [PC-8827] Added condition to stop executing the code unnecessarily
Satheesh Kuamr     Sep 29, 2022         [PC-9236] Removed the dependency of Case lookup field for task Assignments and Reassignment
***************************************************************************************************************/

public inherited sharing class PC_AssignToFRMRoleTaskHandler extends PC_TriggerHandler{
    static Boolean isInsert = false;
    override public void beforeInsert() {
        isInsert = true;
        assignToFRMRoleUser((List< Task>) newList, (Map<Id, Task>) oldMap);
    }

    override public void beforeUpdate() {
        isInsert = false;
        assignToFRMRoleUser((List< Task>) newList, (Map<Id, Task>) oldMap);
    }

    /**************************************************************************************
	*   @Description : Processes Task, changes and updates Assign To (OwnerId) of Task
	*   @Param       : newTaskList. Trigger new task list
	*   @Param       : oldCaseMap. Trigger old task map
	*   @Return      : Void
	***************************************************************************************/
    private void assignToFRMRoleUser(List<Task> newTaskList, Map<Id, Task> oldTaskMap ) {
        Set<Id> relatedRecordIdSet = new Set<Id>();
        MAP<ID, ID> mapCaseWiseDefaultOwner = new MAP<ID, ID>();
        List<Task> filteredTasks = new List<Task>();
        Map<Id, Id> taskProgramCaseMap = new Map<Id, Id>();

        try {
            //Process only new task or if Assign to Role field in task is updated
            for (Task task : newTaskList) {
                if (((oldTaskMap != null && task.PC_Assign_to_Role__c != oldTaskMap.get(task.Id).PC_Assign_to_Role__c) || (oldTaskMap == null && String.isNotBlank(task.PC_Assign_to_Role__c))) && task.PC_Assign_to_Role__c == PC_Constants.ROLE_FIELD_REIMBURSEMENT_MANAGER) {
                    if (String.isNotBlank(task.WhatId) && (task.WhatId).getSObjectType().getDescribe().getName() == 'Case') {
                        filteredTasks.add(task);
                    }
                }
            }

            if (filteredTasks.size() > 0) {
                /** prepare Map of Task and ProgramCase */
                taskProgramCaseMap = PC_TaskAssignmentHelper.prepareTaskProgramCaseMap(filteredTasks);
                relatedRecordIdSet.addAll(taskProgramCaseMap.values());

                if (relatedRecordIdSet != null && !relatedRecordIdSet.isEmpty()) {
                    //Query the case and related associations details
                    //FLS is NOT needed in Triggers, as they always run in System Mode.
                    //Trigger delegate class (handler) that has with Sharing keyword however, will apply user sharing.
                    Map<Id, Case> caseMap = new Map<Id, Case>([
                            SELECT Id, PC_Care_Coordinator__c, OwnerId, CreatedById,LastModifiedById, PC_Engagement_Program__r.PC_Program_Code__c, (
                                    SELECT Id,PC_Program__c, PC_Associated_User__c, PC_Role__c
                                    FROM Associations__r
                                    WHERE PC_AssociationStatus__c = :PC_Constants.ACTIVE AND PC_Role__c = :PC_Constants.ROLE_FIELD_REIMBURSEMENT_MANAGER
                                    ORDER BY CreatedDate DESC
                            )
                            FROM case
                            where Id IN :relatedRecordIdSet
                    ]);

                    /** Find the default owner of Case based on task Triage setting*/
                    if (!caseMap.isEmpty()) {
                        PC_TaskAssignmentHelper.findCaseWiseDefaultOwner(caseMap, mapCaseWiseDefaultOwner);
                    }

                    String automatedProcessUsername = 'autoproc@' + UserInfo.getOrganizationId();
                    Id AutomatedProcessId = [SELECT Id, Username FROM User WHERE Username = :automatedProcessUsername].Id;
                    String taskRelatedToId;

                    for (Task task : filteredTasks) {
                        taskRelatedToId = taskProgramCaseMap.get(task.Id);
                        if (caseMap.containsKey(taskRelatedToId)) {
                            Case relatedCase = caseMap.get(taskRelatedToId);
                            if (task.PC_Assign_to_Role__c == PC_Constants.ROLE_FIELD_REIMBURSEMENT_MANAGER && relatedCase != null) {
                                List<PC_Association__c> associationList = relatedCase.Associations__r;
                                Id taskOwnerId;
                                //Set task owner to associated FRM user in Care team if available
                                if (associationList != null && !associationList.isEmpty()) {
                                    for (PC_Association__c association : associationList) {
                                        if (association.PC_Associated_User__c != null && association.PC_Associated_User__c != AutomatedProcessId) {
                                            taskOwnerId = association.PC_Associated_User__c;
                                            break;
                                        }
                                    }
                                    if (isInsert && String.isNotBlank(task.PC_SupportPlanActivity__c)) {
                                        // Do not throw error as Support Plan is the one creating the task
                                    } else {
                                        if (task.OwnerId != null && taskOwnerId != null && task.OwnerId != taskOwnerId) {
                                            task.addError(System.Label.PC_AssignToRole_FRM_Error);
                                        }
                                    }

                                }
                                if (taskOwnerId == null) {
                                    taskOwnerId = mapCaseWiseDefaultOwner.get(taskRelatedToId);
                                    if (taskOwnerId == AutomatedProcessId && task.OwnerId != null) {
                                        taskOwnerId = task.OwnerId;
                                    }
                                    /*if (UserInfo.getUserId() != AutomatedProcessId && task.OwnerId != null && taskOwnerId != null && task.OwnerId != taskOwnerId ){
                                        task.addError(System.Label.PC_AssignToRole_FRMNotAvailableError);
                                    }*/
                                }
                                //Set the Owner field only if there is a change in owner
                                if ((oldTaskMap != null && String.isNotBlank(taskOwnerId) && taskOwnerId != oldTaskMap.get(task.Id).OwnerId) || (oldTaskMap == null)) {
                                    task.OwnerId = taskOwnerId;
                                }
                            }
                        }
                    }
                }
            }
        } catch (Exception e) {
            PC_Utility.logAndThrowException(e);
        }
    }
}