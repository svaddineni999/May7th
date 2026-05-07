/*********************************************************************************************************
Class Name      : PC_AssignToAllRolesTaskHandler
Description     : trigger on Task object
Created By      : Satheesh Kumar
Created Date    : July 7, 2022
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer                   Date                   	Description
--------------------------------------------------------------------------------------------------------------
Satheesh Kumar    		July 7, 2022        		Initial Version
Satheesh Kumar          Aug 02, 2022                [PC-9109] Added condition to avoid assigning task to 'Automated Process User' when task created via SP on a program case with no Care Team members
Satheesh Kuamr          Sep 29, 2022                [PC-9236] Removed the dependency of Case lookup field for task Assignments and Reassignment
****************************************************************************************************************/

public inherited sharing class PC_AssignToAllRolesTaskHandler extends PC_TriggerHandler {
    static Boolean isInsert = false;
    override public void beforeInsert() {
        isInsert = true;
        processAssignToRole((List< Task>) newList, (Map<Id, Task>) oldMap);
    }

    override public void beforeUpdate() {
        isInsert = false;
        processAssignToRole((List< Task>) newList, (Map<Id, Task>) oldMap);
    }

    /**************************************************************************************
    *   @Description : Processes Task, changes and updates Assign To (OwnerId) of Task
    *   @Param       : newTaskList. Trigger new task list
    *   @Param       : oldCaseMap. Trigger old task map
    *   @Return      : Void
    ***************************************************************************************/
    private void processAssignToRole(List<Task> newTaskList, Map<Id, Task> oldTaskMap) {
        List<Task> filteredTasks = new List<Task>();
        Set<Id> relatedRecordIdSet = new Set<Id>();
        Map<Id, Id> taskProgramCaseMap = new Map<Id, Id>();
        MAP<ID, ID> mapCaseWiseDefaultOwner = new MAP<ID, ID>();
        Id programCaseId;

        try {


            //Process only new task or if Assign to Role field in task is updated
            for (Task task : newTaskList) {
                if (((oldTaskMap != null && task.PC_Assign_to_Role__c != oldTaskMap.get(task.Id).PC_Assign_to_Role__c) || (oldTaskMap == null)) && String.isNotBlank(task.PC_Assign_to_Role__c)) {
                    if(String.isNotBlank(task.WhatId) && (task.WhatId).getSObjectType().getDescribe().getName() == 'Case') {
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
                                    WHERE PC_AssociationStatus__c = :PC_Constants.ACTIVE
                                    AND PC_Associated_User__c != null
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
                    Id AutomatedProcessId = [SELECT Id,Username FROM User WHERE Username = :automatedProcessUsername].Id;
                    String taskRelatedToId;

                    for (Task task : filteredTasks) {
                        taskRelatedToId = taskProgramCaseMap.get(task.Id);
                        if (caseMap.containsKey(taskRelatedToId)) {
                            Case relatedCase = caseMap.get(taskRelatedToId);
                            if (relatedCase != null) {
                                List<PC_Association__c> associationList = relatedCase.Associations__r;
                                Id taskOwnerId;
                                //Set task owner to associated FRM user in Care team if available
                                if (associationList != null && !associationList.isEmpty()) {
                                    for (PC_Association__c association : associationList) {
                                        if (task.PC_Assign_to_Role__c == association.PC_Role__c && association.PC_Associated_User__c != AutomatedProcessId) {
                                            taskOwnerId = association.PC_Associated_User__c;
                                            break;
                                        }
                                    }
                                    if (isInsert && String.isNotBlank(task.PC_SupportPlanActivity__c)) {
                                        // Do not throw error as Support Plan is the one creating the task
                                    } else {
                                        if (task.OwnerId != null && taskOwnerId != null && task.OwnerId != taskOwnerId) {
                                            task.addError(String.format(System.Label.PC_AssignToRoleTaskError, new List<Object>{task.PC_Assign_to_Role__c}));
                                        }
                                    }
                                }
                                if (taskOwnerId == null) {
                                    taskOwnerId = mapCaseWiseDefaultOwner.get(taskRelatedToId);
                                    if (taskOwnerId == AutomatedProcessId && task.OwnerId != null) {
                                        taskOwnerId = task.OwnerId;
                                    }
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
            PC_Utility.createExceptionLog(e);
        }
    }
}