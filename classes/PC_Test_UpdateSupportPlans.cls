/**
 * Created by tusarora on 4/23/2020.
 */

@IsTest
private class PC_Test_UpdateSupportPlans {
    @testSetup
    static void setup() {
        createTestData();
    }
    private static User adminUser;
    private static PC_SupportPlan__c supportPlan1;
    /*********************************************************************************
    Method Name    : createTestData
    Author         : Tushar Arora
    Description    : This method is used for creating test data
    Return Type    : void
    *********************************************************************************/

    private static void createTestData() {
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'userpctest@email.com', 'pctest');
        PC_Database.ins(adminUser, false);

        PC_ConditionBuilder conditionBuilder = new PC_ConditionBuilder();
        List<PC_ConditionBuilder.Conditions> conditions = new List<PC_ConditionBuilder.Conditions>();
        PC_ConditionBuilder.Conditions  condition= new PC_ConditionBuilder.Conditions();
        condition.ConditionNo = 1;
        condition.FieldName = 'ADHERENCE';
        condition.FieldApiName = 'PC_Status_Indicator_4__c';
        condition.Operator = 'Equals';
        condition.Type = 'Picklist';
        condition.Value = 'In Progress';
        conditions.add(condition);

        List<PC_ConditionBuilder.LstConditionsPerObject> lstConditions = new List<PC_ConditionBuilder.LstConditionsPerObject>();
        PC_ConditionBuilder.LstConditionsPerObject lstConditionsPerObject= new PC_ConditionBuilder.LstConditionsPerObject();
        lstConditionsPerObject.ObjectType = PC_Constants.PC_CASE;
        lstConditionsPerObject.Conditions = new List<PC_ConditionBuilder.Conditions> ();
        lstConditionsPerObject.Conditions.addAll(conditions);
        lstConditionsPerObject.Logic = '';
        lstConditions.add(lstConditionsPerObject);

        conditionBuilder.LstConditionsPerObject = new List<PC_ConditionBuilder.LstConditionsPerObject>();
        conditionBuilder.LstConditionsPerObject.addAll(lstConditions);
        String supportPlanConditions = System.JSON.serialize(conditionBuilder);


        //Create Support Plan
        supportPlan1= PC_Test_Setup.createSupportPlan();
        supportPlan1.PC_IsActive__c=true;
        supportPlan1.PC_TriggerEventObject__c= null;
        supportPlan1.PC_TriggerEventType__c='Insert/Update';
        supportPlan1.PC_ConditionBehavior__c = PC_Constants.SUPPORTPLAN_CONDBEHAVIOR_STATUS_WAIT;
        supportPlan1.PC_Condition_Option__c = PC_Constants.PC_COND_OPTION_CONDITIONAL_BUILDER;
        supportPlan1.PC_Conditional_Logic__c = supportPlanConditions;
        supportPlan1 = (PC_SupportPlan__c) PC_Database.ins(supportPlan1, false);

    }
    @isTest static void testUpdateSupportPlanInfo() {
        try {
            Test.startTest();
            PC_UpdateSupportPlans batchJob = new PC_UpdateSupportPlans(null);
            Id batchId = Database.executeBatch(batchJob);
            Test.stopTest();
        }
        catch(Exception ex) {
            system.debug(ex.getMessage());
            system.assert(false);
        }

    }
}