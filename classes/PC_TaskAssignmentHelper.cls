/*********************************************************************************************************
Class Name      : PC_TaskAssignmentHelper
Description     : Helper class for task assignment
Created By      : Satheesh Kumar
Created Date    : July 11, 2022
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer                   Date                   	Description
--------------------------------------------------------------------------------------------------------------
Satheesh Kumar           July 11, 2022             Initial Version
Satheesh Kuamr           Sep 29, 2022              [PC-9236] Created new methods for removing the dependency of Case lookup field on task Assignments/reassignment triggers
****************************************************************************************************************/
public with sharing class PC_TaskAssignmentHelper {

    /**
     * This method is used to find the default owner for case using PC_UnassignedTaskTriage Patient Connect Setting
     * @param caseMap - Map of case (Map<Id, Case>)
     * @param mapCaseWiseDefaultOwner - map of Case with default owner (Map<Id, Id>)
     *
     */
    public static void findCaseWiseDefaultOwner(Map<Id, Case> caseMap, Map<Id, Id> mapCaseWiseDefaultOwner) {
        Map<String, PC_SYSTEM.taskTriageWrapper> engagementCodeWiseDefaultOwner = new Map<String, PC_SYSTEM.taskTriageWrapper>();
        SET<String> engagementProgramCode = new SET<String>();
        Map<String, String> engagementCodeWiseSetting = new Map<String, String>();
        Map<Id, String> userNames = new Map<Id, String>();
        Map<Id, String> queueNames = new Map<Id, String>();
        String defaultString = '{"type" : "CaseOwner"}';

        for (Case c : caseMap.values()) {
            if (String.isNotBlank(c.PC_Engagement_Program__r.PC_Program_Code__c)) {
                engagementProgramCode.add(c.PC_Engagement_Program__r.PC_Program_Code__c);
            }
        }

        if (!engagementProgramCode.isEmpty()) {
            engagementCodeWiseSetting = PC_SYSTEM.getSettingByEngagementProgram(engagementProgramCode, PC_Constants.PC_UNASSIGNED_TASK_TRIAGE, PC_Constants.SETTINGS_TYPE.PATIENT_CONNECT_SETTING, defaultString);
            for (String engagementCode : engagementCodeWiseSetting.keySet()) {
                String s = engagementCodeWiseSetting.get(engagementCode);
                PC_SYSTEM.taskTriageWrapper ttw = new PC_SYSTEM.taskTriageWrapper();
                ttw = (PC_SYSTEM.taskTriageWrapper) JSON.deserialize(s, PC_SYSTEM.taskTriageWrapper.class);
                engagementCodeWiseDefaultOwner.put(engagementCode, ttw);
            }
        }

        for (Case cs : caseMap.values()) {
            if (!engagementCodeWiseDefaultOwner.isEmpty() && !engagementCodeWiseDefaultOwner.values().isEmpty()) {
                if (engagementCodeWiseDefaultOwner.get(cs.PC_Engagement_Program__r.PC_Program_Code__c).type.toLowerCase() == 'caseowner') {
                    mapCaseWiseDefaultOwner.put(cs.Id, cs.OwnerId);
                } else if (engagementCodeWiseDefaultOwner.get(cs.PC_Engagement_Program__r.PC_Program_Code__c).type.toLowerCase() == 'loggedinuser') {
                    mapCaseWiseDefaultOwner.put(cs.Id, UserInfo.getUserId());
                } else if (engagementCodeWiseDefaultOwner.get(cs.PC_Engagement_Program__r.PC_Program_Code__c).type.toLowerCase() == 'user') {
                    userNames.put(cs.Id, engagementCodeWiseDefaultOwner.get(cs.PC_Engagement_Program__r.PC_Program_Code__c).value);
                } else if (engagementCodeWiseDefaultOwner.get(cs.PC_Engagement_Program__r.PC_Program_Code__c).type.toLowerCase() == 'queue') {
                    queueNames.put(cs.Id, engagementCodeWiseDefaultOwner.get(cs.PC_Engagement_Program__r.PC_Program_Code__c).value);
                }
            }
        }

        if (!userNames.isEmpty()) {
            Map<Id, User> userMap = new Map<Id, User>([Select Id, Username From User Where Username IN :userNames.values()]);
            Map<String, Id> userNameMap = new Map<String, Id>();
            for (Id uId : userMap.keySet()) {
                userNameMap.put(userMap.get(uId).Username, uId);
            }

            for (Id cId : userNames.keySet()) {
                if (String.isNotBlank(userNameMap.get(userNames.get(cId)))) {
                    mapCaseWiseDefaultOwner.put(cId, userNameMap.get(userNames.get(cId)));
                }
            }
        }
        if (!queueNames.isEmpty()) {
            Map<Id, Group> groupMap = new Map<Id, Group>([Select Id, DeveloperName From Group Where DeveloperName IN :queueNames.values() and Type = 'Queue']);
            Map<String, Id> groupNameMap = new Map<String, Id>();
            for (Id uId : groupMap.keySet()) {
                groupNameMap.put(groupMap.get(uId).DeveloperName, uId);
            }

            for (Id cId : queueNames.keySet()) {
                if (String.isNotBlank(groupNameMap.get(queueNames.get(cId)))) {
                    mapCaseWiseDefaultOwner.put(cId, groupNameMap.get(queueNames.get(cId)));
                }
            }
        }
    }

    /**
     * This method is used to prepare and returns the map of task and program case
     * @Param       : newTaskList. Trigger new task list
     * @Return      : Map<Id, Id>
     */
    public static Map<Id, Id> prepareTaskProgramCaseMap(List<Task> newTaskList) {
        Map<Id, Id> taskProgramCaseMap = new Map<Id, Id>();
        Set<Id> lstRelatedObjects = new Set<Id>();
        for (Task task : newTaskList) {
            if (String.isNotBlank(task.WhatId) && (task.WhatId).getSObjectType().getDescribe().getName() == 'Case') {
                lstRelatedObjects.add(task.WhatId);
            }
        }
        Map<Id, Case> mapCases = new Map<Id, Case>([Select Id, Type, PC_Program__c FROM Case WHERE Id in: lstRelatedObjects]);

        String programCaseId;
        for(Task task : newTaskList) {
            if(mapCases.containsKey(task.WhatId)) {
                Case caseRec = mapCases.get(task.WhatId);
                programCaseId = caseRec.Type == PC_Constants.CASE_PROGRAM_TYPE ? caseRec.Id : caseRec.PC_Program__c ;
                taskProgramCaseMap.put(task.Id, programCaseId);
            }
        }
        return taskProgramCaseMap;
    }
}