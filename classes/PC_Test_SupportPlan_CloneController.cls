/**************************************************************************************
Apex Class Name     : PC_Test_SupportPlan_CloneController
Description         : This class is used for testing PC_SupportPlan_CloneController;
CreatedBy           : Tejas Patel
Created Date        : 19 Feb 2019
Modification Log    :
--------------------------------------------------------------------------------------------------------------
Developer                   Date                   Description
----------------------------------------------------------------------------
Tejas Patel                19 Feb 2019           Initial version
*************************************************************************************/

@isTest(seeAllData=False)

public with sharing class PC_Test_SupportPlan_CloneController {
    private static User objUser;
    private static PC_SupportPlan__c oSupPlan;
    private static PC_SupportPlanActivity__c oSupPlanActy1;
    private static PC_SupportPlanActivity__c oSupPlanActy2;
    private static PC_SupportPlanActivity__c oSupPlanActy3;
    private static PC_SupportPlanActivity__c oSupPlanActy4;
    private static final String USER_ALIAS = 'test1';


    @testSetup static void createTestData() {
        objUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@t1234.com', USER_ALIAS);
        objUser = (User) PC_Database.ins(objUser);
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

    @isTest static void testcloneSupportPlan(){
        objUser = [Select Id from User where Alias = :USER_ALIAS];
        system.runAs(objUser) {
            Test.StartTest();
            oSupPlan = [Select Id, Name, PC_InitialActivity__c From PC_SupportPlan__c where Name = :PC_Test_Setup.SUPPORTPLAN_NAME];
            PC_SupportPlan_CloneController.cloneSupportPlanResponse clonedSP = PC_SupportPlan_CloneController.cloneSupportPlan(oSupPlan.Id,(System.Label.PC_ClonePrefix+oSupPlan.Name));

            PC_SupportPlan__c supportPlan = [SELECT Id, Name, PC_ConditionBehavior__c, PC_Description__c, PC_InitialActivity__c, PC_IsActive__c, PC_StartCondition__c,
                    PC_Version__c, PC_Conditional_Logic__c, PC_Condition_Option__c FROM PC_SupportPlan__c WHERE Id =: clonedSP.clonedSupportPlanId];
            System.assertEquals(supportPlan.Name, System.Label.PC_ClonePrefix+ oSupPlan.Name);
            System.assertEquals(supportPlan.PC_IsActive__c, false);
            System.assertNotEquals(supportPlan.PC_InitialActivity__c, oSupPlan.PC_InitialActivity__c);
            PC_SupportPlan_CloneController.cloneSupportPlanResponse clonedSPagain = PC_SupportPlan_CloneController.cloneSupportPlan(oSupPlan.Id,(System.Label.PC_ClonePrefix+oSupPlan.Name));
            System.assertEquals(clonedSPagain.exceptionFlag, true);
            Test.StopTest();
        }
    }

    @isTest static void testfieldLabels(){
        objUser = [Select Id from User where Alias = :USER_ALIAS];
        system.runAs(objUser) {
            Test.StartTest();
            PC_SupportPlan_CloneController.FieldLabels fieldLabels = PC_SupportPlan_CloneController.getFieldLabels();
            System.assertNotEquals(fieldLabels, Null);
            Test.StopTest();
        }
    }

}