/*********************************************************************************
Created by havalakki on 10/17/2018.
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------
Tushar Arora                03-Mar-2020            [PC-6040] Added testFetchInformation Method to cover fetchinformation method
                                                                            and its related information of PC_Custom_SupportPlanController.
*********************************************************************************/

@IsTest
private class PC_Test_Custom_SupportPlanCntrl {
    private static User objUser;
    private static PC_SupportPlan__c oSupPlan;
    /*********************************************************************************
    Method Name    : createTestData
    Author         : Alina Balan
    Description    : This method is used for creating test data
    Return Type    : void
    Parameter      :
    *********************************************************************************/
    public static void createTestData() {
        objUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test93.com', 'test93');
        PC_Database.ins(objUser, false);
        oSupPlan = PC_Test_Setup.createSupportPlan();
        PC_Database.ins(oSupPlan, false);
        System.debug('Support Plan Id: '+oSupPlan.Id);
    }
    @isTest static void testFetchInformation() {
        createTestData();
        system.runAs(objUser) {
            Test.startTest();
            //PC_Custom_SupportPlanController.BaseSupportPlan supportPlanWrapper1= PC_Custom_SupportPlanController.fetchSupportPlan(oSupPlan.Id);
            //PC_Custom_SupportPlanController.BaseSupportPlan supportPlanWrapper2=PC_Custom_SupportPlanController.fetchSupportPlan(null);
            List<PC_Custom_SupportPlanController.SupportPlan> supportPlans = new List<PC_Custom_SupportPlanController.SupportPlan> ();
            supportPlans = PC_Custom_SupportPlanController.fetchInformation(oSupPlan.Id);
            System.assert(supportPlans!=null);
            Test.stopTest();
        }
    }

    @isTest static void testFetchSupportPlan() {
        createTestData();
        system.runAs(objUser) {
            Test.startTest();
            PC_Custom_SupportPlanController.BaseSupportPlan supportPlanWrapper1= PC_Custom_SupportPlanController.fetchSupportPlan(oSupPlan.Id);
            PC_Custom_SupportPlanController.BaseSupportPlan supportPlanWrapper2=PC_Custom_SupportPlanController.fetchSupportPlan(null);
            System.assert(supportPlanWrapper1!=null);
            System.assert(supportPlanWrapper2!=null);
            Test.stopTest();
        }
    }

    @isTest static void testGetConditionFieldLabels() {
        createTestData();
        system.runAs(objUser) {
            Test.startTest();
            PC_Custom_SupportPlanController.FieldLabelsWrapper fieldLabelsWrapper= PC_Custom_SupportPlanController.getConditionFieldLabels();
            System.assert(fieldLabelsWrapper.supportPlanName!=null);
            Test.stopTest();
        }
    }

    @isTest static void testGetConstantsWrapper() {
        createTestData();
        system.runAs(objUser) {
            Test.startTest();
            PC_Custom_SupportPlanController.ConstantsFieldsWrapper constantsFieldsWrapper= PC_Custom_SupportPlanController.getConstantsWrapper();
            System.assert(constantsFieldsWrapper.condOptionApex.equals(PC_Constants.PC_COND_OPTION_APEX_CLASS));
            Test.stopTest();
        }
    }

    @isTest static void testGetPicklistEntryMap() {
        createTestData();
        system.runAs(objUser) {
            Test.startTest();
            Map<String, List<PC_PicklistFieldManager.PicklistEntryWrapper>> picklistEntryMap= PC_Custom_SupportPlanController.getPicklistEntryMap();
            System.assert(picklistEntryMap.get('setCondition')!=null && !picklistEntryMap.get('setCondition').isEmpty());
            Test.stopTest();
        }
    }

    @isTest static void testDetermineSave() {
        objUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test93.com', 'test93');
        PC_Database.ins(objUser, false);

        system.runAs(objUser) {
            PC_SupportPlan__c objSupPlan = new PC_SupportPlan__c();
            objSupPlan.Name	                    = 'TestSupPlan1234';
            objSupPlan.PC_IsActive__c           = false;
            objSupPlan.PC_Description__c        = 'New Test Support Plan';
            objSupPlan.PC_ConditionBehavior__c  = 'Wait until True';
            objSupPlan.PC_Condition_Option__c   = 'Apex Class';
            objSupPlan.PC_StartCondition__c     = 'PC_TEST_CLASS_1';
            objSupPlan = (PC_SupportPlan__c) PC_Database.ins(objSupPlan);
            Test.startTest();

            System.debug('@@Tejas Test: '+ objSupPlan);

            objSupPlan.PC_Description__c = 'Updated Test Support Plan';

            PC_Custom_SupportPlanController.BaseSupportPlan supportPlanWrapper= new PC_Custom_SupportPlanController.BaseSupportPlan(objSupPlan);

            String supportPlanStr=JSON.serialize(supportPlanWrapper);

            PC_Custom_SupportPlanController.determineSave(objSupPlan.Id, supportPlanStr);

            System.debug('@@Tejas: '+ objSupPlan);

            System.assert(objSupPlan!=null && objSupPlan.PC_Description__c.equals('Updated Test Support Plan'));
            Test.stopTest();
        }
    }
}