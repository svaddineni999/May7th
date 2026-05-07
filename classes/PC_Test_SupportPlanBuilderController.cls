/**************************************************************************************
Apex Class Name     : PC_Test_SupportPlanBuilderController
Description         : This class is used for testing PC_SupportPlanBuilderController;
CreatedBy           : Sahil Garg
Created Date        : 8 Mar 2018
Modification Log    :
-------------------------------------------------------------------------------------------------------------- 
Developer                   Date                   Description
----------------------------------------------------------------------------                 
Sahil Garg                 8 Mar 2018           Initial version
Tejas Patel				   15 Mar 2018			Added assert statements
*************************************************************************************/

@isTest(seeAllData=False)
public with sharing class PC_Test_SupportPlanBuilderController {
    private static User objUser;
    private static PC_SupportPlan__c oSupPlan;
    private static PC_SupportPlanActivity__c oSupPlanActy1;
    private static PC_SupportPlanActivity__c oSupPlanActy2;
    private static PC_SupportPlanActivity__c oSupPlanActy3;
    private static PC_SupportPlanActivity__c oSupPlanActy4;

    
    private static void createTestData() {
        objUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@t1234.com', 'test1');
        PC_Database.ins(objUser);
        createObjects() ;
    }
    
    
    private static void createObjects() {
        system.runAs(objUser) {
            oSupPlan = PC_Test_Setup.createSupportPlan();
            PC_Database.ins(oSupPlan, false);
            oSupPlanActy1 = PC_Test_Setup.createSupportPlanActivity('Activity 1', 'User Task', oSupPlan.Id);
            oSupPlanActy2 = PC_Test_Setup.createSupportPlanActivity('Activity 2', 'User Task', oSupPlan.Id);
            oSupPlanActy3 = PC_Test_Setup.createSupportPlanActivity('Activity 3', 'User Task', oSupPlan.Id);
            oSupPlanActy4 = PC_Test_Setup.createSupportPlanActivity('Activity 4', 'User Task', oSupPlan.Id);

            //Activity 1
            PC_Database.ins(oSupPlanActy1, false);
            oSupPlanActy1 = [SELECT ID, PC_InternalActivityNumber__c, PC_NextActivityNumber__c FROM PC_SupportPlanActivity__c
                             WHERE ID = :oSupPlanActy1.Id];

            //Support Plan
            oSupPlan = [SELECT ID, Name, PC_InitialActivity__c FROM PC_SupportPlan__c WHERE ID =: oSupPlan.Id];
            oSupPlan.PC_InitialActivity__c = oSupPlanActy1.PC_InternalActivityNumber__c;
            PC_Database.upd(oSupPlan, false);

            //Activity 2
            PC_Database.ins(oSupPlanActy2, false);
            oSupPlanActy2 = [SELECT ID, PC_InternalActivityNumber__c, PC_NextActivityNumber__c FROM PC_SupportPlanActivity__c
                                                       WHERE ID = :oSupPlanActy2.Id];

            oSupPlanActy1.PC_NextActivityNumber__c = oSupPlanActy2.PC_InternalActivityNumber__c;
            PC_Database.upd(oSupPlanActy1, false);

            //Activity 3
            PC_Database.ins(oSupPlanActy3, false);
            oSupPlanActy3 = [SELECT ID, PC_InternalActivityNumber__c, PC_NextActivityNumber__c FROM PC_SupportPlanActivity__c
                                                       WHERE ID = :oSupPlanActy3.Id];

            oSupPlanActy2.PC_NextActivityNumber__c = oSupPlanActy3.PC_InternalActivityNumber__c;
            PC_Database.upd(oSupPlanActy2, false);

            //Activity 4
            PC_Database.ins(oSupPlanActy4, false);
            oSupPlanActy4 = [SELECT ID, PC_InternalActivityNumber__c, PC_NextActivityNumber__c FROM PC_SupportPlanActivity__c
                                                       WHERE ID = :oSupPlanActy4.Id];

            oSupPlanActy3.PC_NextActivityNumber__c = oSupPlanActy4.PC_InternalActivityNumber__c;
            PC_Database.upd(oSupPlanActy3, false);
        }
    }
    @isTest static void testSaveReorder(){
        createTestData();
        system.runAs(objUser) {
            Test.StartTest();
            PC_SupportPlanBuilderController.saveSwap(oSupPlanActy2.Id, oSupPlanActy3.Id, oSupPlan.Id);
            PC_SupportPlanBuilderController.saveSwap(oSupPlanActy3.Id, oSupPlanActy2.Id, oSupPlan.Id);
            PC_SupportPlanBuilderController.saveSwap(oSupPlanActy2.Id, oSupPlanActy4.Id, oSupPlan.Id);
            PC_SupportPlanBuilderController.saveSwap(oSupPlanActy4.Id, oSupPlanActy2.Id, oSupPlan.Id);
            PC_SupportPlanBuilderController.saveSwap(oSupPlanActy1.Id, oSupPlanActy3.Id, oSupPlan.Id);
            PC_SupportPlanBuilderController.saveSwap(oSupPlanActy3.Id, oSupPlanActy1.Id, oSupPlan.Id);
            PC_SupportPlanBuilderController.saveSwap(oSupPlanActy2.Id, oSupPlanActy1.Id, oSupPlan.Id);
            PC_SupportPlanBuilderController.saveSwap(oSupPlanActy1.Id, oSupPlanActy2.Id, oSupPlan.Id);
            PC_SupportPlanBuilderController.saveSwap(oSupPlanActy1.Id, oSupPlanActy4.Id, oSupPlan.Id);


            PC_SupportPlanBuilderController.saveDropOnHead(oSupPlanActy2.Id, oSupPlanActy3.Id, oSupPlan.Id);
            PC_SupportPlanBuilderController.saveDropOnHead(oSupPlanActy3.Id, oSupPlanActy2.Id, oSupPlan.Id);
            PC_SupportPlanBuilderController.saveDropOnHead(oSupPlanActy2.Id, oSupPlanActy4.Id, oSupPlan.Id);
            PC_SupportPlanBuilderController.saveDropOnHead(oSupPlanActy4.Id, oSupPlanActy2.Id, oSupPlan.Id);
            PC_SupportPlanBuilderController.saveDropOnHead(oSupPlanActy1.Id, oSupPlanActy4.Id, oSupPlan.Id);
            PC_SupportPlanBuilderController.saveDropOnHead(oSupPlanActy1.Id, oSupPlanActy3.Id, oSupPlan.Id);
            Test.StopTest();
        }
    }

    @isTest static void testGetListView(){
        createTestData();
        system.runAs(objUser) {
            Test.StartTest();
            List<ListView> listView = PC_SupportPlanBuilderController.getListView();
            System.assertNotEquals(listView.size(), 0);
            Test.StopTest();
        }
    }

    @isTest static void testactivationStatus(){
        createTestData();
        system.runAs(objUser) {
            Test.StartTest();
            PC_SupportPlan__c supportPlan;
            PC_SupportPlanBuilderController.activationStatus(true,oSupPlan.Id);
            supportPlan = [SELECT Id, PC_IsActive__c FROM PC_SupportPlan__c WHERE Id =: oSupPlan.Id];
            System.assertEquals(supportPlan.PC_IsActive__c, true);
            
            PC_SupportPlanBuilderController.activationStatus(false,oSupPlan.Id);
            supportPlan = [SELECT Id, PC_IsActive__c FROM PC_SupportPlan__c WHERE Id =: oSupPlan.Id];
            System.assertEquals(supportPlan.PC_IsActive__c, false);
            Test.StopTest();
        }
    }

    @isTest static void testGetActivities(){
        createTestData();
        system.runAs(objUser) {
            Test.StartTest();
            PC_SupportPlanBuilderController.SupportPlanContentWrapper activities= PC_SupportPlanBuilderController.getActivities(oSupPlan.Id);
            System.assertEquals(activities.supportPlan.supportplanname, 'TestSupPlan');
            Test.StopTest();
        }
    }

    @isTest static void testIsValidFieldSet(){
        createTestData();
        system.runAs(objUser) {
            Test.StartTest();
            Boolean isValid = PC_SupportPlanBuilderController.isValidFieldSet('Task', PC_Constants.PC_TaskFieldSetNameForCaseObject);
            Boolean isValid2 = PC_SupportPlanBuilderController.isValidFieldSet('Task', 'Test');
            system.assertEquals(true,isValid);
            system.assertEquals(false,isValid2);
            Test.StopTest();
        }
    }
}