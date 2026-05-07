/*********************************************************************************************************
Class Name      : PC_Test_AssignToFRMRoleTaskHandler
Description     : Test class for PC_AssignToFRMRoleTaskHandler
Created Date    : Mar 02, 2021
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer          Date                   Description
--------------------------------------------------------------------------------------------------------------
Haritha Reddy      Mar 02, 2021         [PC-7471] Initial Version
***************************************************************************************************************/
@isTest
public class PC_Test_AssignToRoleTaskHandler {
    private static User adminUser, frmUser, careCoordinatorUser;
    public static Account patientAccount;
    public static Case programCase;
    private static PC_SupportPlan__c supportPlan1;
    private static PC_SupportPlanActivity__c supPlanActy1;
    private static PC_Engagement_Program__c enmtProgram;
    private static PC_EngagementProgram_SupportPlan__c enmtPgmSupPlan;

    @testSetup static void setup() {
        // Create Admin User
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'test_adminUser1@test.com', 'test1');
        PC_Database.ins(adminUser);
        // Create FRM User
        frmUser = PC_Test_Setup.createUser(PC_Test_Setup.FRM_PROFILE, 'test_FRMUser1@test.com', 'test2');
        PC_Database.ins(frmUser);
        // Create Care Coordinator User
        careCoordinatorUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'test_CCUser1@test.com', 'test3');
        PC_Database.ins(careCoordinatorUser);
        // Create Patient Account
        patientAccount = PC_Test_Setup.createPatient('Test Patient 1');
        patientAccount.PC_Date_of_Birth__c = Date.today();
        patientAccount.PC_Gender__c = 'Male';
        patientAccount = (Account) PC_Database.ins(patientAccount, false);

        List<Account> manufacturers = PC_Test_Setup.createAccounts('testManufacturer', 1, 'Manufacturer');
        manufacturers = (List<Account>) PC_Database.ups(manufacturers);

        PC_Engagement_Program__c ep1 = PC_Test_Setup.createEngagementProgram('EP1',manufacturers[0].Id);
        ep1 = (PC_Engagement_Program__c) PC_Database.ins(ep1);

        // Create Program case
        programCase = PC_Test_Setup.createProgram(patientAccount);
        programCase.PC_Engagement_Program__c = ep1.Id;
        programCase = (Case) PC_Database.ups(programCase);
    }
    
    /**
    * This methods verifies if old FRM association is getting deactivated if new association is inserted with same role
    */
    @isTest static void testAssociationDeactivation() {
        Case caseRecord = [Select Id from Case  LIMIT 1];
        User frmUser1 = [Select Id from User WHERE username = 'test_FRMUser1@test.com'];
        User adminUser1 = [Select Id from User WHERE username = 'test_adminUser1@test.com'];
        // Create FRM User
        User frmUser2 = PC_Test_Setup.createUser(PC_Test_Setup.FRM_PROFILE, 'testFRMUser3@test.com', 'test3');
        frmUser2 = (User)PC_Database.ins(frmUser2);

        System.runAs(adminUser1) {
            Test.StartTest();
            //Create FRM Association
            PC_Association__c frmAssociation1 = PC_Test_Setup.createAssociations(caseRecord.Id, null, frmUser1.Id, PC_Constants.ROLE_FIELD_REIMBURSEMENT_MANAGER);
            frmAssociation1 = (PC_Association__c) PC_Database.ins(frmAssociation1);

            PC_Association__c frmAssociation2 = PC_Test_Setup.createAssociations(caseRecord.Id, null, frmUser2.Id, PC_Constants.ROLE_FIELD_REIMBURSEMENT_MANAGER);
            frmAssociation2 = (PC_Association__c) PC_Database.ins(frmAssociation2);

            frmAssociation1 = [Select Id,PC_AssociationStatus__c from PC_Association__c WHERE Id =: frmAssociation1.Id];
            frmAssociation2 = [Select Id,PC_AssociationStatus__c from PC_Association__c WHERE Id =: frmAssociation2.Id];

            System.assertEquals(frmAssociation1.PC_AssociationStatus__c, PC_Constants.INACTIVE);
            System.assertEquals(frmAssociation2.PC_AssociationStatus__c, PC_Constants.ACTIVE);
            Test.stopTest();
        }
    }

    /**
    * This methods verifies if Task owner is set to FRM role user on Case association when bulk task insert is done
    */
    @isTest static void testFRMRoleAssignmentForBulkTaskInsert() {
        Case caseRecord = [Select Id from Case  LIMIT 1];
        User frmUser1 = [Select Id from User WHERE username = 'test_FRMUser1@test.com'];
        User adminUser1 = [Select Id from User WHERE username = 'test_adminUser1@test.com'];
        User ccUser1 = [Select Id from User WHERE username = 'test_CCUser1@test.com'];
        System.runAs(adminUser1) {
            Test.StartTest();
            //Create FRM Association
            PC_Association__c frmAssociation = PC_Test_Setup.createAssociations(caseRecord.Id, null, frmUser1.Id, PC_Constants.ROLE_FIELD_REIMBURSEMENT_MANAGER);
            frmAssociation = (PC_Association__c) PC_Database.ins(frmAssociation);

            List<Task> taskList = PC_Test_Setup.createTasks(caseRecord, 200);
            for(integer i = 0; i<200 ;i++){
                taskList[i].PC_Assign_to_Role__c = PC_Constants.ROLE_FIELD_REIMBURSEMENT_MANAGER;
                taskList[i].OwnerId = frmUser1.Id;
            }
            taskList = (List<Task>)PC_Database.ins(taskList, false);
            System.assertEquals(taskList.size(), 200);

            Set<Id> taskIds = (new Map<Id,SObject>(taskList)).keySet();
            taskList = [Select Id,OwnerId from task where Id IN: taskIds];
            //Verify if FRM Role User is assigned as task Owner
            for(Task task: taskList){
                System.assertEquals(task.OwnerId, frmUser1.Id);
            }
            Test.stopTest();
        }
    }

    /**
    * This methods verifies if Task owner is set to FRM role user on Case association when bulk task update is done
    */
    @isTest static void testFRMRoleAssignmentForBulkTaskUpdate() {
        Case caseRecord = [Select Id from Case  LIMIT 1];
        User frmUser1 = [Select Id from User WHERE username = 'test_FRMUser1@test.com'];
        User adminUser1 = [Select Id from User WHERE username = 'test_adminUser1@test.com'];
        User ccUser1 = [Select Id from User WHERE username = 'test_CCUser1@test.com'];
        System.runAs(adminUser1) {
            Test.StartTest();
            //Add Care Coordinator on Case
            caseRecord.PC_Care_Coordinator__c = ccUser1.Id;
            caseRecord = (Case)PC_Database.upd(caseRecord);

            List<Task> taskList = PC_Test_Setup.createTasks(caseRecord, 200);
            taskList = (List<Task>)PC_Database.ins(taskList, false);
            System.assertEquals(taskList.size(), 200);

            for (integer i = 0; i < 200; i++) {
                taskList[i].PC_Assign_to_Role__c = PC_Constants.ROLE_FIELD_REIMBURSEMENT_MANAGER;
                taskList[i].OwnerId = adminUser1.Id;
            }
            taskList = (List<Task>)PC_Database.upd(taskList);

            //Create FRM Association
            PC_Association__c frmAssociation = PC_Test_Setup.createAssociations(caseRecord.Id, null, frmUser1.Id, PC_Constants.ROLE_FIELD_REIMBURSEMENT_MANAGER);
            frmAssociation = (PC_Association__c) PC_Database.ins(frmAssociation);

            Set<Id> taskIds = (new Map<Id,SObject>(taskList)).keySet();
            taskList = [Select Id,OwnerId from task where Id IN: taskIds];
            //Verify if FRM Role User is assigned as task Owner
            for(Task task: taskList){
                System.assertEquals(task.OwnerId, frmUser1.Id);
            }
            Test.stopTest();
        }
    }

    /**
    * This methods verifies if Task owner is set to FRM role user on Case association
    */
    @isTest static void testFRMRoleAssignment() {
        Case caseRecord = [Select Id from Case  LIMIT 1];
        User frmUser1 = [Select Id from User WHERE username = 'test_FRMUser1@test.com'];
        User adminUser1 = [Select Id from User WHERE username = 'test_adminUser1@test.com'];
        User ccUser1 = [Select Id from User WHERE username = 'test_CCUser1@test.com'];
        System.runAs(adminUser1) {
            Test.StartTest();
            List<Task> taskList = PC_Test_Setup.createTasks(caseRecord, 3);
            taskList[0].PC_Assign_to_Role__c = PC_Constants.ROLE_FIELD_REIMBURSEMENT_MANAGER;
            taskList = (List<Task>)PC_Database.ins(taskList, false);
            System.assertEquals(taskList.size(), 3);

            Task task1 = [Select Id,OwnerId from task where Id =: taskList[0].Id];
            //Verify if current logged in user is assigned as task Owner
            System.assertEquals(task1.OwnerId, UserInfo.getUserId());

            //Add Care Coordinator on Case
            caseRecord.PC_Care_Coordinator__c = ccUser1.Id;
            caseRecord = (Case)PC_Database.upd(caseRecord);
            try{
                taskList[1].PC_Assign_to_Role__c = PC_Constants.ROLE_FIELD_REIMBURSEMENT_MANAGER;
                taskList[1] = (Task)PC_Database.upd(taskList[1]);
            }catch(Exception e){
                Boolean expectedExceptionThrown =  e.getMessage().contains(System.Label.PC_AssignToRole_FRMNotAvailableError) ? true : false;
                System.AssertEquals(expectedExceptionThrown, true);
            }

            taskList[1].PC_Assign_to_Role__c = PC_Constants.ROLE_FIELD_REIMBURSEMENT_MANAGER;
            taskList[1].OwnerId = ccUser1.Id;
            taskList[1] = (Task)PC_Database.upd(taskList[1]);

            Task task2 = [Select Id,OwnerId from task where Id =: taskList[1].Id];
            //Verify if Care Coordinator Role User is assigned as task Owner
            System.assertEquals(task2.OwnerId, ccUser1.Id);

            //Create FRM Association
            PC_Association__c frmAssociation = PC_Test_Setup.createAssociations(caseRecord.Id, null, frmUser1.Id, PC_Constants.ROLE_FIELD_REIMBURSEMENT_MANAGER);
            frmAssociation = (PC_Association__c) PC_Database.ins(frmAssociation);

            try{
                taskList[2].PC_Assign_to_Role__c = PC_Constants.ROLE_FIELD_REIMBURSEMENT_MANAGER;
                taskList[2] = (Task)PC_Database.upd(taskList[2]);
            }catch(Exception e){
                Boolean expectedExceptionThrown =  e.getMessage().contains(System.Label.PC_AssignToRole_FRM_Error) ? true : false;
                System.AssertEquals(expectedExceptionThrown, true);
            }
            taskList[2].PC_Assign_to_Role__c = PC_Constants.ROLE_FIELD_REIMBURSEMENT_MANAGER;
            taskList[2].OwnerId = frmUser1.Id;
            taskList[2] = (Task)PC_Database.upd(taskList[2]);

            Task task3 = [Select Id,OwnerId from task where Id =: taskList[2].Id];
            //Verify if FRM Role User is assigned as task Owner
            System.assertEquals(task3.OwnerId, frmUser1.Id);
            Test.stopTest();
        }
    }

    /**
    * This methods verifies if Task owner is set to FRM role user on Case association for Task created through Support Plan
    */
    @isTest static void testFRMRoleAssignmentForSupportPlanTask() {
        User frmUser1 = [Select Id from User WHERE username = 'test_FRMUser1@test.com'];
        User adminUser1 = [Select Id from User WHERE username = 'test_adminUser1@test.com'];
        User ccUser1 = [Select Id from User WHERE username = 'test_CCUser1@test.com'];
        patientAccount = [Select Id from Account  LIMIT 1];
        programCase = [Select Id, OwnerId from Case  LIMIT 1];
        programCase.PC_Care_Coordinator__c = ccUser1.Id;
        programCase = (Case) PC_Database.upd(programCase, false);
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
                '{"value":"Field Reimbursement Manager","type":"PICKLIST","label":"Assign to Role","isDeleteAllowed":"false","apiName":"'+PC_Constants.getQualifiedAPIName('PC_Assign_to_Role__c')+
                '"},{"value":"2020-04-23T08:30:00.000Z","type":"DATETIME","label":"Close Date","isDeleteAllowed":"true","apiName":"'+PC_Constants.getQualifiedAPIName('PC_Close_Date__c')+'"}]}';

        supPlanActy1 = (PC_SupportPlanActivity__c) PC_Database.ins(supPlanActy1, false);

        supportPlan1.PC_InitialActivity__c = supPlanActy1.Id;
        supportPlan1 = (PC_SupportPlan__c) PC_Database.upd(supportPlan1, false);

        //Create Manufacturer
        List<Account>  manufacturers = PC_Test_Setup.createAccounts('testmanufacturer', 1, PC_Constants.MANUFACTURER_RECORD_TYPE);
        Account manufacturer = (Account)PC_Database.ins(manufacturers[0], false);

        //Create Engagement Program
        enmtProgram= PC_Test_Setup.createEngagementProgram('TestPgm',manufacturer.Id );
        enmtProgram.PC_Program_Code__c = 'TestPgm';
        enmtProgram = (PC_Engagement_Program__c) PC_Database.ins(enmtProgram, false);

        //Create Engagement Program Support Plan Junction Object
        enmtPgmSupPlan= PC_Test_Setup.createEnggmtPgmSupPlan();
        enmtPgmSupPlan.PC_EngagementProgram__c=enmtProgram.Id;
        enmtPgmSupPlan.PC_SupportPlan__c=supportPlan1.Id;
        enmtPgmSupPlan = (PC_EngagementProgram_SupportPlan__c)PC_Database.ins(enmtPgmSupPlan, false);

        System.runAs(adminUser1) {
            Test.StartTest();
            // Create Program case
            Case programCase1 = PC_Test_Setup.createProgram(patientAccount);
            programCase1.PC_Engagement_Program__c = enmtProgram.Id;
            programCase1 = (Case) PC_Database.upd(programCase1);
            programCase1 = [Select Id, PC_Engagement_Program__c, OwnerId from Case where Id = :programCase1.Id LIMIT 1];
            //Deliver the Support Plan Info Platform event with context "ExecuteActions"
            Test.getEventBus().deliver();
            //Deliver the Support Plan Info Platform event with context "ProcessSupportPlanRuntimes"
            Test.getEventBus().deliver();

            system.debug('adminUser1-->'+adminUser1);
            system.debug('programCase1.OwnerId-->'+programCase1.OwnerId);
            system.debug('programCase.OwnerId-->'+programCase.OwnerId);
            system.debug('programCase Owner User Name-->'+[Select Username from User where Id=:programCase.OwnerId].Username);

            Task frmTask1 = [SELECT Id,OwnerId,whatId FROM Task WHERE whatId = :programCase1.Id];
            system.debug('frmTask1.OwnerId-->'+frmTask1.OwnerId);
            System.assertEquals(frmTask1.OwnerId, programCase1.OwnerId);

            //Update the case with new owner
            programCase.PC_Engagement_Program__c = enmtProgram.Id;
            programCase.OwnerId = adminUser1.Id;
            programCase = (Case) PC_Database.upd(programCase);

            //Deliver the Support Plan Info Platform event with context "ExecuteActions"
            Test.getEventBus().deliver();
            //Deliver the Support Plan Info Platform event with context "ProcessSupportPlanRuntimes"
            Test.getEventBus().deliver();

            //Create FRM Association
            PC_Association__c frmAssociation = PC_Test_Setup.createAssociations(programCase.Id, null, frmUser1.Id, PC_Constants.ROLE_FIELD_REIMBURSEMENT_MANAGER);
            frmAssociation = (PC_Association__c) PC_Database.ins(frmAssociation);

            programCase.Status = 'In Treatment';
            programCase = (Case) PC_Database.upd(programCase);

            //Deliver the Support Plan Info Platform event with context "ExecuteActions"
            Test.getEventBus().deliver();
            //Deliver the Support Plan Info Platform event with context "ProcessSupportPlanRuntimes"
            Test.getEventBus().deliver();

            List<Task> frmTaskList = [SELECT Id,OwnerId FROM Task WHERE OwnerId = :frmUser1.Id];
            //Verify if FRM Role User is assigned as task Owner
            System.assertEquals(frmTaskList.size(), 2); // Expecting 2 because PC_AssignToFRMRoleAssociationHandler will update all existing tasks on creation of FRM association records.

            Test.stopTest();
        }
    }
}