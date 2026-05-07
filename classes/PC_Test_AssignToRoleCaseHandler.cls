/*********************************************************************************************************
Class Name      : PC_Test_AssignToRoleCaseHandler
Description     : Test class for PC_AssignToRoleCaseHandler
Created Date    : Sep 14, 2021
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer          Date                   Description
--------------------------------------------------------------------------------------------------------------
Haritha Reddy      Sep 14, 2021         [PC-8151] Initial Version
***************************************************************************************************************/
@isTest
public class PC_Test_AssignToRoleCaseHandler {
    private static User adminUser, careCoordinatorUser1,ReimbursmentUser2,careCoordinatorUser3,taskDefaultUser;

    @testSetup static void setup() {
        // Create Admin User
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'testAdminUser1@test.com', 'test1');
        PC_Database.ins(adminUser);

        taskDefaultUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'taskdefaultuser@test.com', 'testD1');
        PC_Database.ins(taskDefaultUser);

        // Create Care Coordinator User 1
        careCoordinatorUser1 = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'testCCUser1@test.com', 'cctest1');
        PC_Database.ins(careCoordinatorUser1);

        // Create Reimbursment User 2
        ReimbursmentUser2 = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'testCCUser2@test.com', 'cctest2');
        PC_Database.ins(ReimbursmentUser2);

        // Create Care Coordinator User 3
        careCoordinatorUser3 = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'testCCUser3@test.com', 'cctest3');
        PC_Database.ins(careCoordinatorUser3);

        List<Account> patientAccounts = PC_Test_Setup.createAccounts('test', 5, PC_Constants.PATIENT_RECORD_TYPE);
        PC_Database.ins(patientAccounts);

        List<Account> manufacturers = PC_Test_Setup.createAccounts('testManufacturer', 1, 'Manufacturer');
        manufacturers = (List<Account>) PC_Database.ups(manufacturers);

        List<Case> programCases = PC_Test_Setup.createProgramCases(patientAccounts, 4);

        PC_Engagement_Program__c ep1 = PC_Test_Setup.createEngagementProgram('EP1',manufacturers[0].Id);
        PC_Engagement_Program__c ep2 = PC_Test_Setup.createEngagementProgram('EP2',manufacturers[0].Id);
        PC_Engagement_Program__c ep3 = PC_Test_Setup.createEngagementProgram('EP3',manufacturers[0].Id);
        PC_Engagement_Program__c ep4 = PC_Test_Setup.createEngagementProgram('EP4',manufacturers[0].Id);
        List<PC_Engagement_Program__c> ep = new List<PC_Engagement_Program__c>();
        ep.add(ep1);ep.add(ep2);ep.add(ep3);ep.add(ep4);
        ep = (List<PC_Engagement_Program__c>) PC_Database.ins(ep);
        for(integer i = 0; i<4; i++){
            programCases[i].PC_Engagement_Program__c =  ep[i].Id;
        }
        PC_Database.ins(programCases);

    }

    @isTest static void testBulkTaskUpdate() {
        Case case1 = [Select Id, PC_Care_Coordinator__c, PC_Reimbursment_Specialist__c, OwnerId, Owner.Email from Case Where PC_Engagement_Program__r.PC_Program_Code__c = 'EP1' ];
        Case case2 = [Select Id, PC_Care_Coordinator__c, PC_Reimbursment_Specialist__c, OwnerId, Owner.Email from Case Where PC_Engagement_Program__r.PC_Program_Code__c = 'EP2' ];
        Case case3 = [Select Id, PC_Care_Coordinator__c, PC_Reimbursment_Specialist__c, OwnerId, Owner.Email from Case Where PC_Engagement_Program__r.PC_Program_Code__c = 'EP3' ];
        Case case4 = [Select Id, PC_Care_Coordinator__c, PC_Reimbursment_Specialist__c, OwnerId, Owner.Email from Case Where PC_Engagement_Program__r.PC_Program_Code__c = 'EP4' ];

        User adminUser1 = [Select Id from User WHERE username = 'testAdminUser1@test.com'];
        User ccUser1 = [Select Id from User WHERE username = 'testCCUser1@test.com'];
        User rrUser2 = [Select Id from User WHERE username = 'testCCUser2@test.com'];
        User ccUser3 = [Select Id from User WHERE username = 'testCCUser3@test.com'];

        Group Taskgroup = PC_Test_Setup.createGroup();
        Taskgroup = (Group) PC_Database.ins(Taskgroup);

        QueuesObject taskQueue = PC_Test_Setup.createQueue(Taskgroup, PC_Constants.PC_TASK);
        taskQueue = (QueuesObject) PC_Database.ins(taskQueue);

        System.runAs(adminUser1) {
            Test.StartTest();
            //Add related tasks for programCase1
            List<Task> taskList = PC_Test_Setup.createTasks(case1, 5);
            for(integer i = 0; i<5 ;i++){
                taskList[i].PC_Assign_to_Role__c = PC_Constants.PC_ROLE_CARE_COORDINATOR;
            }
            taskList = (List<Task>)PC_Database.ins(taskList, false);
            System.assertEquals(taskList.size(), 5);

            Set<Id> taskIds = (new Map<Id,SObject>(taskList)).keySet();
            taskList = [Select Id, WhatId, OwnerId, Owner.Email from task where Id IN: taskIds];

            //Since Program case does not have CC assigned should default to case owner
            for(Task t : taskList){
                system.assertEquals(case1.PC_Care_Coordinator__c,null);
                system.assertEquals(adminUser1.Id,t.OwnerId);
            }


            //Add related tasks for programCase2
            List<Task> taskList1 = PC_Test_Setup.createTasks(case2, 10);
            for(integer i = 0; i<10 ;i++){
                taskList1[i].PC_Assign_to_Role__c = PC_Constants.PC_ROLE_REIMBURSEMENT_SPECIALIST;
            }
            taskList1 = (List<Task>)PC_Database.ins(taskList1, false);

            System.assertEquals(taskList1.size(), 10);

            Set<Id> taskIds1 = (new Map<Id,SObject>(taskList1)).keySet();
            taskList1 = [Select Id, WhatId, OwnerId from task where Id IN: taskIds1];

            //Since Program case does not have RR assigned should default to case owner
            for(Task t : taskList1){
                system.assertEquals(case2.PC_Reimbursment_Specialist__c,null);
                system.assertEquals(case2.OwnerId,t.OwnerId);
            }

            //Add related tasks for programCase3
            List<Task> taskList2 = PC_Test_Setup.createTasks(case3, 10);
            for(integer i = 0; i<10 ;i++){
                taskList2[i].PC_Assign_to_Role__c = PC_Constants.PC_ROLE_CARE_COORDINATOR;
            }
            taskList2 = (List<Task>)PC_Database.ins(taskList2, false);
            System.assertEquals(taskList2.size(), 10);

            Set<Id> taskIds2 = (new Map<Id,SObject>(taskList2)).keySet();
            taskList2 = [Select Id, WhatId, OwnerId from task where Id IN: taskIds2];
            Group groupName = [Select Id, DeveloperName From Group Where DeveloperName = 'TestGroup' and Type = 'Queue' LIMIT 1];
            //Since Program case does not have CC assigned should default to case owner
            for(Task t : taskList2){
                system.assertEquals(case3.PC_Care_Coordinator__c,null);
                system.assertEquals(groupName.Id,t.OwnerId);
            }

            //Add related tasks for programCase4
            List<Task> taskList3 = PC_Test_Setup.createTasks(case4, 10);
            for(integer i = 0; i<10 ;i++){
                taskList3[i].PC_Assign_to_Role__c = PC_Constants.PC_ROLE_CARE_COORDINATOR;
            }
            taskList3 = (List<Task>)PC_Database.ins(taskList3, false);
            System.assertEquals(taskList3.size(), 10);

            Set<Id> taskIds3 = (new Map<Id,SObject>(taskList3)).keySet();
            taskList3 = [Select Id, WhatId, OwnerId from task where Id IN: taskIds3];
            User u = [Select Id, Username From User Where Username = 'taskdefaultuser@test.com'  LIMIT 1];
            //Since Program case does not have CC assigned should default to case owner
            for(Task t : taskList3){
                system.assertEquals(case4.PC_Care_Coordinator__c,null);
                system.assertEquals(u.Id,t.OwnerId);
            }

            Id caseListId0 = case1.Id;
            Id caseListId1 = case2.Id;
            Id caseListId2 = case3.Id;
            case1.PC_Care_Coordinator__c = ccUser1.Id;
            case2.PC_Reimbursment_Specialist__c = rrUser2.Id;
            case3.PC_Care_Coordinator__c = ccUser3.Id;
            case3.PC_Reimbursment_Specialist__c = rrUser2.Id;
            List<Case> caseList = new List<Case>();
            caseList.add(case1);caseList.add(case2);caseList.add(case3);
            caseList = (List<Case>)PC_Database.upd(caseList);

            Case caseList0 = [Select Id, PC_Care_Coordinator__c, PC_Reimbursment_Specialist__c from Case  where Id = :caseListId0];
            Case caseList1 = [Select Id, PC_Care_Coordinator__c, PC_Reimbursment_Specialist__c from Case  where Id = :caseListId1];
            Case caseList2 = [Select Id, PC_Care_Coordinator__c, PC_Reimbursment_Specialist__c, OwnerId from Case  where Id = :caseListId2];

            //Set<Id> taskIds = (new Map<Id,SObject>(taskList)).keySet();
            taskList = [Select Id, WhatId, OwnerId from task where Id IN: taskIds];
            //Ensure correct Care coordinator1 is assigned as task owner
            for(Task task: taskList){
                system.assertEquals(caseList0.Id,task.WhatId);
                system.assertEquals(caseList0.PC_Care_Coordinator__c,ccUser1.Id);
                System.assertEquals(task.OwnerId, ccUser1.Id);
                System.assertEquals(task.OwnerId, caseList0.PC_Care_Coordinator__c);
            }

            //Set<Id> taskIds1 = (new Map<Id,SObject>(taskList1)).keySet();
            taskList1 = [Select Id, WhatId, OwnerId from task where Id IN: taskIds1];
            //Ensure correct Reimbursment_Specialist is assigned as task owner
            for(Task task: taskList1){
                system.assertEquals(caseList1.Id,task.WhatId);
                system.assertEquals(caseList1.PC_Reimbursment_Specialist__c,rrUser2.Id);
                System.assertEquals(task.OwnerId, rrUser2.Id);
                System.assertEquals(task.OwnerId, caseList1.PC_Reimbursment_Specialist__c);
            }

            //Set<Id> taskIds2 = (new Map<Id,SObject>(taskList2)).keySet();
            taskList2 = [Select Id, WhatId, OwnerId, PC_Assign_to_Role__c from task where Id IN: taskIds2];
            //Ensure correct Care coordinator3 is assigned as task owner
            for(Task task: taskList2){
                system.assertEquals(caseList2.Id,task.WhatId);
                system.assertEquals(caseList2.PC_Care_Coordinator__c,ccUser3.Id);
                System.assertEquals(task.OwnerId, ccUser3.Id);
                System.assertEquals(task.OwnerId, caseList2.PC_Care_Coordinator__c);
            }

            for (Task t : taskList2){
                t.PC_Assign_to_Role__c = PC_Constants.PC_ROLE_REIMBURSEMENT_SPECIALIST;
            }

            try{
                taskList2 = (List<Task>)PC_Database.upd(taskList2, false); //Changing just the role is not allowed
            }catch(Exception ex){
                system.debug('Should Occur'+ex.getMessage());
                system.debug('Should Occur'+System.Label.PC_AssignToRole_ReimbursementSpecialist_Error);
            }

            taskList2 = [Select Id, WhatId, OwnerId, PC_Assign_to_Role__c from task where Id IN: taskIds2];
            for (Task t : taskList2){
                t.OwnerId = caseList2.OwnerId; //Changing just the owner is allowed
            }
            try{
                taskList2 = (List<Task>)PC_Database.upd(taskList2, false);
                taskList2 = [Select Id, WhatId, OwnerId, PC_Assign_to_Role__c from task where Id IN: taskIds2];
                for(Task task: taskList2){
                    system.assertEquals(caseList2.Id,task.WhatId);
                    system.assertEquals(caseList2.PC_Care_Coordinator__c,ccUser3.Id);
                    System.assertEquals(task.OwnerId, caseList2.OwnerId);
                }
            }catch(Exception ex){
                system.debug('Should Not Occur'+ex.getMessage());
                system.debug('Should Not Occur'+System.Label.PC_AssignToRole_ReimbursementSpecialist_Error);
            }

            Test.stopTest();
        }
    }

    @isTest static void testSupportPlan(){
        PC_SupportPlanActivity__c supPlanActy1;
        PC_SupportPlan__c supportPlan1;
        PC_Engagement_Program__c enmtProgram;
        PC_EngagementProgram_SupportPlan__c enmtPgmSupPlan;
        //Create Support Plan
        supportPlan1= PC_Test_Setup.createSupportPlan();
        supportPlan1.PC_IsActive__c=true;
        supportPlan1.PC_TriggerEventObject__c='Case';
        supportPlan1.PC_TriggerEventType__c='Update';
        supportPlan1.PC_TriggerEventConditionalBehavior__c = PC_Constants.SUPPORTPLAN_CONDBEHAVIOR_STATUS_NONE;
        supportPlan1.PC_ConditionBehavior__c = PC_Constants.SUPPORTPLAN_CONDBEHAVIOR_STATUS_NONE;
        supportPlan1.PC_SupportPlan_Behavior__c=String.valueOf(PC_Constants.SupportPlanBehaviour.RunEveryTimeRuleMatches);
        supportPlan1 = (PC_SupportPlan__c) PC_Database.ins(supportPlan1, false);

        //Create Support Plan Activity1
        supPlanActy1= PC_Test_Setup.createSupportPlanActivity('Activity 1: Task - Log a Call');
        supPlanActy1.PC_SupportPlan__c = supportPlan1.Id;
        supPlanActy1.PC_UserTask_Fields__c='{"requiredFieldSet":[{"value":"Normal","type":"PICKLIST","label":"Priority","isDeleteAllowed":"false","apiName":"Priority"},' +
                '{"value":"Call","type":"PICKLIST","label":"Channel","isDeleteAllowed":"false","apiName":"'+PC_Constants.getQualifiedAPIName('PC_Channel__c')+'"},' +
                '{"value":"Test ","type":"STRING","label":"Subject","isDeleteAllowed":"false","apiName":"Subject"},' +
                '{"value":"Care Coordinator","type":"PICKLIST","label":"Assign to Role","isDeleteAllowed":"false","apiName":"'+PC_Constants.getQualifiedAPIName('PC_Assign_to_Role__c')+
                '"},{"value":"2020-04-23T08:30:00.000Z","type":"DATETIME","label":"Close Date","isDeleteAllowed":"true","apiName":"'+PC_Constants.getQualifiedAPIName('PC_Close_Date__c')+'"}]}';

        supPlanActy1 = (PC_SupportPlanActivity__c) PC_Database.ins(supPlanActy1, false);

        supportPlan1.PC_InitialActivity__c = supPlanActy1.Id;
        supportPlan1 = (PC_SupportPlan__c) PC_Database.upd(supportPlan1, false);

        //Create Engagement Program
        enmtProgram = [Select Id from PC_Engagement_Program__c Where PC_Program_Code__c = 'EP2' LIMIT 1];

        //Create Engagement Program Support Plan Junction Object
        enmtPgmSupPlan= PC_Test_Setup.createEnggmtPgmSupPlan();
        enmtPgmSupPlan.PC_EngagementProgram__c=enmtProgram.Id;
        enmtPgmSupPlan.PC_SupportPlan__c=supportPlan1.Id;
        enmtPgmSupPlan = (PC_EngagementProgram_SupportPlan__c)PC_Database.ins(enmtPgmSupPlan, false);

        User adminUser1 = [Select Id from User WHERE username = 'testAdminUser1@test.com'];
        User ccUser1 = [Select Id from User WHERE username = 'testCCUser1@test.com'];

        System.runAs(adminUser1) {
            Test.StartTest();
            // Create Program case
            Case programCase = [Select Id, PC_Care_Coordinator__c, PC_Reimbursment_Specialist__c, OwnerId, Owner.Email from Case Where PC_Engagement_Program__r.PC_Program_Code__c = 'EP2' ];
            programCase.PC_Engagement_Program__c = enmtProgram.Id;
            programCase = (Case) PC_Database.upd(programCase);
            programCase = [Select Id, PC_Care_Coordinator__c, PC_Reimbursment_Specialist__c, OwnerId, Owner.Email from Case where Id = :programCase.Id LIMIT 1];
            //Deliver the Support Plan Info Platform event with context "ExecuteActions"
            Test.getEventBus().deliver();
            //Deliver the Support Plan Info Platform event with context "ProcessSupportPlanRuntimes"
            Test.getEventBus().deliver();
            Task ccTask = [SELECT Id,OwnerId,Owner.Email,whatId FROM Task WHERE whatId = :programCase.Id];
            System.assertEquals(ccTask.OwnerId, programCase.OwnerId);

            // Create case with Care Coordinator
            programCase.PC_Care_Coordinator__c = ccUser1.Id;
            programCase = (Case) PC_Database.upd(programCase);

            //Deliver the Support Plan Info Platform event with context "ExecuteActions"
            Test.getEventBus().deliver();
            //Deliver the Support Plan Info Platform event with context "ProcessSupportPlanRuntimes"
            Test.getEventBus().deliver();

            List<Task> ccTaskList = [SELECT Id,OwnerId FROM Task WHERE whatId = :programCase.Id];
            //Verify if Care Coordinator Role User is assigned as task Owner
            System.assertEquals(ccTaskList[0].OwnerId, ccUser1.Id);
            System.assertEquals(ccTaskList[1].OwnerId, ccUser1.Id);

            Test.stopTest();
        }
    }
}