/**
 * Created by tusarora on 4/23/2020.
 */

@IsTest
private class PC_Test_UpdateSupportPlanActivities {
    @testSetup
    static void setup() {
        createTestData();
    }
    private static User adminUser;
    private static PC_SupportPlan__c supportPlan1;
    private static PC_SupportPlanActivity__c supPlanActy1,supPlanActy2,supPlanActy3;

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
        String conditionBuilderCondition = System.JSON.serialize(conditionBuilder);


        //Create Support Plan
        supportPlan1= PC_Test_Setup.createSupportPlan();
        supportPlan1.PC_IsActive__c=true;
        supportPlan1.PC_TriggerEventObject__c= PC_Constants.PC_CASE;
        supportPlan1.PC_TriggerEventType__c='Insert/Update';
        supportPlan1.PC_ConditionBehavior__c = PC_Constants.SUPPORTPLAN_CONDBEHAVIOR_STATUS_WAIT;
        supportPlan1.PC_Condition_Option__c = PC_Constants.PC_COND_OPTION_CONDITIONAL_BUILDER;
        supportPlan1.PC_Conditional_Logic__c = conditionBuilderCondition;
        supportPlan1 = (PC_SupportPlan__c) PC_Database.ins(supportPlan1, false);

        //Create Support Plan Activity1 Linked to the Support Plan
        supPlanActy1= PC_Test_Setup.createSupportPlanActivity('Activity 1: Task 1');
        supPlanActy1.PC_UserTask_Fields__c = '{"requiredFieldSet":[{"value":"Normal","type":"PICKLIST","label":"Priority","isDeleteAllowed":"false","apiName":"Priority"},' +
                '{"value":"Call","type":"PICKLIST","label":"Channel","isDeleteAllowed":"false","apiName":"PC_Channel__c"},' +
                '{"value":"Test ","type":"STRING","label":"Subject","isDeleteAllowed":"false","apiName":"Subject"},' +
                '{"value":"Test ","type":"STRING","label":"Subject","isDeleteAllowed":"false","apiName":"PC_Assign_to_Role__c"},' +
                '{"value":"2020-04-23T08:30:00.000Z","type":"DATETIME","label":"Close Date","isDeleteAllowed":"true","apiName": "PC_Close_Date__c"}]}';
        supPlanActy1.PC_ReferenceDate__c = 'PC_Approval_Denial_Date__c';
        supPlanActy1.PC_Conditional_Logic__c = conditionBuilderCondition;
        supPlanActy1.PC_SupportPlan__c = supportPlan1.Id;
        supPlanActy1 = (PC_SupportPlanActivity__c) PC_Database.ins(supPlanActy1, false);

    }

    @isTest static void testUpdateSupportPlanActivityConditions() {
        try {
            Test.startTest();
            PC_UpdateSupportPlanActivities batchJob = new PC_UpdateSupportPlanActivities(null,null);
            Id batchId = Database.executeBatch(batchJob);
            Test.stopTest();
        }
        catch(Exception ex) {
            system.debug(ex.getMessage());
            system.assert(false);
        }

    }

    @isTest static void testUpdateSPActivityConditionsTaskFieldsNotEmpty() {
        try {
            Test.startTest();
            List<String> taskIgnoreFields = new List<String>();
            taskIgnoreFields.add('PC_Test');
            List<String> caseIgnoreFields = new List<String>();
            caseIgnoreFields.add('Origin');
            PC_UpdateSupportPlanActivities batchJob = new PC_UpdateSupportPlanActivities(taskIgnoreFields,caseIgnoreFields);
            Id batchId = Database.executeBatch(batchJob);
            Test.stopTest();
        }
        catch(Exception ex) {
            system.debug(ex.getMessage());
            system.assert(false);
        }

    }
}