/*********************************************************************************************************
Class Name      : PC_AssignToRoleCaseHandler
Description     : trigger on Case object.
Created By      : Deloitte
Created Date    : July 6, 2018
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer          Date                   Description
--------------------------------------------------------------------------------------------------------------
Tejas Patel        July 06, 2016          Initial Version
Tejas Patel        Feb 13, 2019           Updated the If condition to select the Set of Case ids
Xiukai Ning        Feb 28, 2019           PC-3775 - Code review. FLS is NOT needed in Triggers, as they always run in System Mode.
                                          Trigger delegate class (handler) that has with Sharing keyword however, will apply user sharing.
                                          We are removing all FLS and With Sharing keywords in the handlers.
Xiukai Ning        May 20, 2019           PC-4794/PC-3515 - Populate Assign To field based on the parent Program Case; Check consistency of user-specified Assign To Role and Assign To fields
Vijay Kashikar     21-Jan-21              [PC-7102] Added FLS Checks
Haritha Reddy      Sep 14, 2021           [PC-8151] Updated logic to declare & initialize relatedTasks variable for each Case.
                                            This will ensure only corresponding tasks are mapped to a Case record. Updated usage of list to set.
Satheesh Kumar     Nov 16, 2021           [PC-8213] Excluded FLS Check and added inherited sharing
Tejas Patel        Apr 04, 2022           [PC-8637] Default task owner is set to Case Owner.
Tejas Patel        May 02, 2022           [PC-8595] Default task owner made configurable.
Satheesh Kuamr     Sep 29, 2022           [PC-9236] Removed the dependency of Case lookup field for task Assignments and Reassignment
***************************************************************************************************************/

public inherited sharing class PC_AssignToRoleCaseHandler extends PC_TriggerHandler {
    override public void afterUpdate() {
        processAssignToRole((List< Case>) newList, (Map<Id, Case>) oldMap);
    }

    /**************************************************************************************
	*   @Description : Processes Case, changes and updates Assign To (OwnerId) of Task
	*   @Param       : newCaseList. Trigger new Case list
	*   @Param       : oldCaseMap. Trigger old Case map
	*   @Return      : Void
	***************************************************************************************/
    private void processAssignToRole(List<Case> newCaseList, Map<Id, Case> oldCaseMap ) {
        SET<Id> lstRelatedTasks = new SET<Id>();
        SET<Id> lstCaseId = new SET<Id>();
        SET<Task> toUpdateTasks = new SET<Task>();
        MAP<ID, SET<Task>> mapCaseRelatedTasks = new MAP<ID, SET<Task>>();
        MAP<ID, ID> mapCaseWiseDefaultOwner = new MAP<ID, ID>();
        Map<Id, Case> mapCases = new Map<Id, Case>();
        Map<Id, Id> taskProgramCaseMap = new Map<Id, Id>();

        try{
            for(Case c : newCaseList) {
                if ((c.PC_Care_Coordinator__c != oldCaseMap.get(c.Id).PC_Care_Coordinator__c) || (c.PC_Reimbursment_Specialist__c != oldCaseMap.get(c.Id).PC_Reimbursment_Specialist__c)) {
                    lstCaseId.add(c.Id);
                }
            }

            LIST<Task> listTasks = new LIST<Task>();
            if(!lstCaseId.isEmpty()) {
                //FLS is NOT needed in Triggers, as they always run in System Mode.
                listTasks = [
                        Select Id, WhatId, PC_Assign_to_Role__c, OwnerId
                        FROM Task
                        WHERE Status != :PC_Constants.PC_TASK_STATUS_COMPLETED
                        AND WhatId IN (SELECT Id FROM CASE where PC_Program__c IN:lstCaseId OR Id IN:lstCaseId)
                ];

                mapCases = new Map<Id, Case>([
                        Select Id,PC_Care_Coordinator__c, PC_Reimbursment_Specialist__c, PC_Engagement_Program__r.PC_Program_Code__c, OwnerId
                        FROM Case
                        WHERE Id in:lstCaseId
                ]);


                /** Find the default owner of Case based on task Triage setting*/
                if (!mapCases.isEmpty()) {
                    PC_TaskAssignmentHelper.findCaseWiseDefaultOwner(mapCases, mapCaseWiseDefaultOwner);
                }

                /** prepare Map of Task and ProgramCase */
                taskProgramCaseMap = PC_TaskAssignmentHelper.prepareTaskProgramCaseMap(listTasks);
                Id programCaseId;

                /** Iterate listTasks and Create a map of Program Case Id and its Task and Service Case Task List*/
                if (!listTasks.isEmpty()) {
                    for (Task taskRec : listTasks) {
                        programCaseId = taskProgramCaseMap.get(taskRec.Id);
                        if (mapCaseRelatedTasks.containsKey(programCaseId)) {
                            mapCaseRelatedTasks.get(programCaseId).add(taskRec);
                        } else {
                            mapCaseRelatedTasks.put(programCaseId, new Set<Task>{taskRec});
                        }
                    }
                }

                if (!mapCaseRelatedTasks.isEmpty()) {
                    for (ID caseId : mapCaseRelatedTasks.keySet()) {
                        for (Task caseTask : mapCaseRelatedTasks.get(caseId)) {
                            if (caseTask.PC_Assign_to_Role__c == PC_Constants.PC_ROLE_CARE_COORDINATOR) {
                                //NOT checking if Assign To and Assign To Role fields are consistent on related Tasks, since Case will drive these field update.
                                caseTask.OwnerId = (mapCases.get(caseId).PC_Care_Coordinator__c != null) ?
                                        (ID) mapCases.get(caseId).PC_Care_Coordinator__c : mapCaseWiseDefaultOwner.get(caseId);

                                toUpdateTasks.add(caseTask);
                            } else if (caseTask.PC_Assign_to_Role__c == PC_Constants.PC_ROLE_REIMBURSEMENT_SPECIALIST) {
                                caseTask.OwnerId = (mapCases.get(caseId).PC_Reimbursment_Specialist__c != null) ?
                                        (ID) mapCases.get(caseId).PC_Reimbursment_Specialist__c : mapCaseWiseDefaultOwner.get(caseId);

                                toUpdateTasks.add(caseTask);
                            }
                        }
                    }
                }
            }
            List<Task> toBeUpdatedTaskList = new List<Task>();
            toBeUpdatedTaskList.addAll(toUpdateTasks);
            if (!toBeUpdatedTaskList.isEmpty()) {
                PC_Database.upd(toBeUpdatedTaskList, false);
            }
        } catch(Exception e){
            PC_Utility.createExceptionLog(e);
        }
    }
}