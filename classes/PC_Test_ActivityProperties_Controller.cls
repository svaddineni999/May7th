/**************************************************************************************
Apex Class Name     : PC_Test_ActivityProperties_Controller
Description         : This class is used for testing PC_ActivityProperties_Controller;
CreatedBy           : Deloitte
Created Date        : 7 Mar 2018
Modification Log    :
-------------------------------------------------------------------------------------------------------------- 
Developer                   Date                   Description
----------------------------------------------------------------------------                 
Sahil Garg                 7 Mar 2018           Initial version
Tejas Patel				   21 Mar 2018			Removed Seq Testing and updated PC_Test_Setup function
Tejas Patel				   11 Jun 2018			Updated test class with new method calls
Kishore Kanteti            9 Dec 2019           [PC-5795]Updated the test methods to make it compatible with fetchActivity Method and determineSave Method
*************************************************************************************/

@isTest(seeAllData=False)
public with sharing class PC_Test_ActivityProperties_Controller {
    private static User objUser;
    private static PC_SupportPlan__c oSupPlan;
    private static STRING oSupPlanActy1;
    private static STRING oSupPlanActy2;
    private static STRING oSupPlanActy3;
    private static STRING oSupPlanActy4;
    private static STRING oSupPlanGroup1;
    private static STRING nextActivity;

    private static PC_SupportPlanBuilderController.SupportPlanActivityWrapper act1;
    private static PC_SupportPlanBuilderController.SupportPlanActivityWrapper act2;
    private static PC_SupportPlanBuilderController.SupportPlanActivityWrapper act3;
    private static PC_SupportPlanBuilderController.SupportPlanActivityWrapper act4;
    private static PC_SupportPlanBuilderController.SupportPlanActivityWrapper act5;
    private static PC_SupportPlanBuilderController.SupportPlanActivityWrapper act6;

    private static PC_SupportPlanActivity__c supportPlanAct1;
    private static PC_SupportPlanActivity__c supportPlanAct2;
    private static PC_SupportPlanActivity__c supportPlanAct3;
    private static PC_SupportPlanActivity__c supportPlanAct4;
    private static PC_SupportPlanActivity__c supportPlanAct5;
    private static PC_SupportPlanActivity__c supportPlanAct6;

    private static PC_SupportPlanBuilderController.SupportPlanActivityWrapper grp1;
    private static PC_SupportPlanBuilderController.SupportPlanActivityWrapper grp1act1;


    private static String taskJSON = '{"type":"updateChildRecords","order":"ASC","nullsOrder":"FIRST","orderBy":' +
            '[],"updateCriteria":"FIRST_RECORD",' +
            '"continueWhenNoUpdates":"TRUE","objectDetails":{"qualifiedApiName":"Case",' +
            '"relativeQualifiedApiPath":""},"LstConditionsPerObject":[{"ObjectType":"",' +
            '"Conditions":[{"ConditionNo":1,"FieldName":"","FieldApiName":"","Operator":"Equals","Type":"Picklist","Value":"Inactive"}],"Logic":""}],' +
            '"fieldMapping":[{"label":"","apiName":"","isDeleteAllowed":false,"type":"Picklist",' +
            '"value":"Inactive","isBoundValue":false}],"outcomeTaskDetails":{"create":true}}';

    private static void createTestData() {
        objUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@t1234.com', 'test1');
        PC_Database.ins(objUser);
        createObjects() ;
    }
    private static void createObjects() {
        system.runAs(objUser) {
            //Create Support Plan
            oSupPlan = PC_Test_Setup.createSupportPlan();
            PC_Database.ins(oSupPlan, false);
            //Create Activity Type "User Task"
            supportPlanAct1 = PC_Test_Setup.createSupportPlanActivity('Activity 1', 'User Task', oSupPlan.Id);
            PC_Database.ins(supportPlanAct1, false);
            supportPlanAct1.PC_InternalActivityNumber__c = supportPlanAct1.Id;
            PC_Database.upd(supportPlanAct1, false);
            supportPlanAct2 = PC_Test_Setup.createSupportPlanActivity('Activity 2', 'User Task', oSupPlan.Id);
            PC_Database.ins(supportPlanAct2, false);
            supportPlanAct2.PC_InternalActivityNumber__c = supportPlanAct2.Id;
            PC_Database.upd(supportPlanAct2, false);
            supportPlanAct3 = PC_Test_Setup.createSupportPlanActivity('Activity 3', 'User Task', oSupPlan.Id);
            PC_Database.ins(supportPlanAct3, false);
            supportPlanAct3.PC_InternalActivityNumber__c = supportPlanAct3.Id;
            PC_Database.upd(supportPlanAct3, false);
            supportPlanAct4 = PC_Test_Setup.createSupportPlanActivity('Activity 4', 'User Task', oSupPlan.Id);
            PC_Database.ins(supportPlanAct4, false);
            supportPlanAct4.PC_InternalActivityNumber__c = supportPlanAct4.Id;
            PC_Database.upd(supportPlanAct4, false);
            supportPlanAct5 = PC_Test_Setup.createSupportPlanActivity('Activity 5', 'User Task', oSupPlan.Id);
            supportPlanAct5.PC_ActivityType__c = 'Update Record';
            supportPlanAct5.PC_AutomationTaskJSON__c = taskJSON;
            PC_Database.ins(supportPlanAct5, false);
            supportPlanAct5.PC_InternalActivityNumber__c = supportPlanAct5.Id;
            PC_Database.upd(supportPlanAct5, false);
            supportPlanAct6 = PC_Test_Setup.createSupportPlanActivity('Activity 6', 'User Task', oSupPlan.Id);
            supportPlanAct6.PC_ActivityType__c = 'Create Record';
            supportPlanAct6.PC_AutomationTaskJSON__c = taskJSON;
            PC_Database.ins(supportPlanAct6, false);
            supportPlanAct6.PC_InternalActivityNumber__c = supportPlanAct6.Id;
            PC_Database.upd(supportPlanAct6, false);

            act1 = new PC_SupportPlanBuilderController.SupportPlanActivityWrapper(supportPlanAct1);
            act2 = new PC_SupportPlanBuilderController.SupportPlanActivityWrapper(supportPlanAct2);
            act3 = new PC_SupportPlanBuilderController.SupportPlanActivityWrapper(supportPlanAct3);
            act4 = new PC_SupportPlanBuilderController.SupportPlanActivityWrapper(supportPlanAct4);
            act5 = new PC_SupportPlanBuilderController.SupportPlanActivityWrapper(supportPlanAct5);
            act6 = new PC_SupportPlanBuilderController.SupportPlanActivityWrapper(supportPlanAct6);

            Map<String, String> activityMap = new Map<String, String>();
            activityMap.put('activityId', 'SupportPlan Group 1');
            activityMap.put('internalactivitynumber', 'SupportPlan Group 1');
            activityMap.put('activityName', 'SupportPlan Group 1');
            activityMap.put('internalactivitytype', PC_Constants.SUPPORTPLAN_ACTIVITY_TYPE_SEQUENCE);
            activityMap.put('supportPlanID', (String) oSupPlan.Id);
            system.debug(activityMap);
            //Create Support Plan Group 1
            grp1 = PC_ActivityProperties_Controller.fetchActivity(activityMap);

            oSupPlanActy1 = System.JSON.serialize(act1);
            oSupPlanActy2 = System.JSON.serialize(act2);
            oSupPlanActy3 = System.JSON.serialize(act3);
            oSupPlanActy4 = System.JSON.serialize(act4);
            oSupPlanGroup1 = System.JSON.serialize(grp1);
        }
    }

    @isTest static void testSaveRecord() {
        createTestData();
        system.runAs(objUser) {
            Test.StartTest();
            STRING prevJSON;
            STRING prevJSONString;
            //Add Activity 1
            Map<String, String> saveActivityMap = new Map<String, String>();
            saveActivityMap.put('activityId', 'Activity 1');
            saveActivityMap.put('supportPlanID', oSupPlan.Id);
            saveActivityMap.put('supActivityJSON', oSupPlanActy1);
            saveActivityMap.put('prevActivityJSON', prevJSONString);
            saveActivityMap.put('nextActivity', nextActivity);
            PC_ActivityProperties_Controller.determineSave(saveActivityMap);
            LIST<PC_SupportPlanActivity__c> activity1Test = [
                    SELECT Id, Name, PC_ActivitySequence__c, PC_ActivityType__c, PC_InternalActivityType__c, PC_AlternateActivity__c, PC_ApexCondition__c,
                            PC_Channel__c, PC_Conditional_Logic__c, PC_ConditionBehavior__c, PC_ConditionOption__c, PC_Description__c, PC_InitialSequenceActivity__c, PC_InternalActivityNumber__c,
                            PC_NextActivityNumber__c, PC_Priority__c, PC_ReferenceDate__c, PC_ReferenceOffset__c, PC_ReferenceOffsetUnit__c,PC_ActionClass__c,
                            PC_ReferenceType__c, PC_Subject__c, PC_SupportPlan__c, PC_Assign_To_Role__c, PC_UserTask_Fields__c,PC_SubType__c,PC_AutomationTaskJSON__c, PC_ClonedFrom__c, PC_GroupActivityExecution__c
                    FROM PC_SupportPlanActivity__c
                    WHERE PC_SupportPlan__c = :oSupPlan.Id
            ];

            PC_SupportPlan__c oSupPlanTest = [SELECT ID, Name, PC_InitialActivity__c FROM PC_SupportPlan__c WHERE ID = :oSupPlan.Id];
            System.assertEquals(activity1Test[0].PC_SupportPlan__c, oSupPlan.Id);
            // System.assertEquals(oSupPlanTest.PC_InitialActivity__c, activity1Test[0].Id);

            //Add Activity 2
            prevJSON = (STRING) (String.valueof(activity1Test[0].Id));
            Map<String, String> saveActivityMap2 = new Map<String, String>();
            saveActivityMap2.put('activityId', 'Activity 2');
            saveActivityMap2.put('supportPlanID', null);
            saveActivityMap2.put('supActivityJSON', oSupPlanActy2);
            saveActivityMap2.put('prevActivityJSON', prevJSON);
            saveActivityMap2.put('nextActivity', nextActivity);
            PC_ActivityProperties_Controller.determineSave(saveActivityMap2);
            LIST<PC_SupportPlanActivity__c> activity2Test = [
                    SELECT Id, Name,PC_ActivitySequence__c, PC_ActivityType__c, PC_InternalActivityType__c, PC_AlternateActivity__c, PC_ApexCondition__c,
                            PC_Channel__c, PC_Conditional_Logic__c, PC_ConditionBehavior__c, PC_ConditionOption__c, PC_Description__c, PC_InitialSequenceActivity__c, PC_InternalActivityNumber__c,
                            PC_NextActivityNumber__c, PC_Priority__c, PC_ReferenceDate__c, PC_ReferenceOffset__c, PC_ReferenceOffsetUnit__c,PC_ActionClass__c,
                            PC_ReferenceType__c, PC_Subject__c, PC_SupportPlan__c, PC_Assign_To_Role__c, PC_UserTask_Fields__c,PC_SubType__c,PC_AutomationTaskJSON__c, PC_ClonedFrom__c, PC_GroupActivityExecution__c
                    FROM PC_SupportPlanActivity__c
                    WHERE PC_SupportPlan__c = :oSupPlan.Id and Id != :activity1Test[0].Id
            ];
            System.assertEquals(activity2Test[0].PC_SupportPlan__c, oSupPlan.Id);

            //Add Activity 3
            prevJSON = (STRING) (String.valueof(activity2Test[0].Id));
            Map<String, String> saveActivityMap3 = new Map<String, String>();
            saveActivityMap3.put('activityId', 'Activity 3');
            saveActivityMap3.put('supportPlanID', null);
            saveActivityMap3.put('supActivityJSON', oSupPlanActy3);
            saveActivityMap3.put('prevActivityJSON', prevJSON);
            saveActivityMap3.put('nextActivity', nextActivity);
            PC_ActivityProperties_Controller.determineSave(saveActivityMap3);
            LIST<PC_SupportPlanActivity__c> activity3Test = [
                    SELECT Id, Name, PC_ActivitySequence__c, PC_ActivityType__c, PC_InternalActivityType__c, PC_AlternateActivity__c, PC_ApexCondition__c,
                            PC_Channel__c, PC_Conditional_Logic__c, PC_ConditionBehavior__c, PC_ConditionOption__c, PC_Description__c, PC_InitialSequenceActivity__c, PC_InternalActivityNumber__c,
                            PC_NextActivityNumber__c, PC_Priority__c, PC_ReferenceDate__c, PC_ReferenceOffset__c, PC_ReferenceOffsetUnit__c,PC_ActionClass__c,
                            PC_ReferenceType__c, PC_Subject__c, PC_SupportPlan__c, PC_Assign_To_Role__c, PC_UserTask_Fields__c,PC_SubType__c,PC_AutomationTaskJSON__c, PC_ClonedFrom__c, PC_GroupActivityExecution__c
                    FROM PC_SupportPlanActivity__c
                    WHERE PC_SupportPlan__c = :oSupPlan.Id and Id != :activity1Test[0].Id and Id != :activity2Test[0].Id
            ];

            System.assertEquals(activity3Test[0].PC_SupportPlan__c, oSupPlan.Id);

            //Add Activity 4
            prevJSON = (STRING) (String.valueof(activity3Test[0].Id));
            Map<String, String> saveActivityMap4 = new Map<String, String>();
            saveActivityMap4.put('activityId', 'Activity 4');
            saveActivityMap4.put('supportPlanID', null);
            saveActivityMap4.put('supActivityJSON', oSupPlanActy4);
            saveActivityMap4.put('prevActivityJSON', prevJSON);
            saveActivityMap4.put('nextActivity', nextActivity);
            PC_ActivityProperties_Controller.determineSave(saveActivityMap4);
            LIST<PC_SupportPlanActivity__c> activity4Test = [
                    SELECT Id, Name,PC_ActivitySequence__c, PC_ActivityType__c, PC_InternalActivityType__c, PC_AlternateActivity__c, PC_ApexCondition__c,
                            PC_Channel__c, PC_Conditional_Logic__c, PC_ConditionBehavior__c, PC_ConditionOption__c, PC_Description__c, PC_InitialSequenceActivity__c, PC_InternalActivityNumber__c,
                            PC_NextActivityNumber__c, PC_Priority__c, PC_ReferenceDate__c, PC_ReferenceOffset__c, PC_ReferenceOffsetUnit__c,PC_ActionClass__c,
                            PC_ReferenceType__c, PC_Subject__c, PC_SupportPlan__c, PC_Assign_To_Role__c, PC_UserTask_Fields__c,PC_SubType__c,PC_AutomationTaskJSON__c, PC_ClonedFrom__c, PC_GroupActivityExecution__c
                    FROM PC_SupportPlanActivity__c
                    WHERE PC_SupportPlan__c = :oSupPlan.Id and Id != :activity1Test[0].Id and Id != :activity2Test[0].Id and Id != :activity3Test[0].Id
            ];

            System.assertEquals(activity4Test[0].PC_SupportPlan__c, oSupPlan.Id);

            //Convert to Wrapper
            PC_SupportPlanBuilderController.SupportPlanActivityWrapper actEdit1;
            actEdit1 = new PC_SupportPlanBuilderController.SupportPlanActivityWrapper(activity1Test[0]);

            //Edit Activity 1
            String stringId = (String) actEdit1.Id;
            Map<String, String> saveActivityMap5 = new Map<String, String>();
            saveActivityMap5.put('activityId', stringId);
            saveActivityMap5.put('supportPlanID', null);
            saveActivityMap5.put('supActivityJSON', System.JSON.serialize(actEdit1));
            saveActivityMap5.put('prevActivityJSON', null);
            saveActivityMap5.put('nextActivity', null);
            PC_ActivityProperties_Controller.determineSave(saveActivityMap5);

            //Convert to Wrapper
            PC_SupportPlanBuilderController.SupportPlanActivityWrapper actEdit2;
            actEdit2 = new PC_SupportPlanBuilderController.SupportPlanActivityWrapper(activity2Test[0]);
            //Edit Activity 2
            stringId = (String) actEdit2.Id;
            Map<String, String> saveActivityMap6 = new Map<String, String>();
            saveActivityMap6.put('activityId', stringId);
            saveActivityMap6.put('supportPlanID', null);
            saveActivityMap6.put('supActivityJSON', System.JSON.serialize(actEdit2));
            saveActivityMap6.put('prevActivityJSON', null);
            saveActivityMap6.put('nextActivity', null);
            PC_ActivityProperties_Controller.determineSave(saveActivityMap6);

            //Delete Activity 3
            PC_ActivityProperties_Controller.deleteRecord(NULL, activity3Test[0].Id, stringId);

            //Delete Activity 1
            PC_ActivityProperties_Controller.deleteRecord(oSupPlan.Id, activity1Test[0].Id, prevJSONString);

            LIST<PC_SupportPlanActivity__c> activityTest = [SELECT Id FROM PC_SupportPlanActivity__c WHERE PC_SupportPlan__c = :oSupPlan.Id];
            System.assertEquals(activityTest.size(), 8);

            //Picklist
            Map<String, List<PC_PicklistFieldManager.PicklistEntryWrapper>> picklistEntryMap =
                    new Map<String, List<PC_PicklistFieldManager.PicklistEntryWrapper>>();
            picklistEntryMap = PC_ActivityProperties_Controller.getPicklistEntryMap();


            LIST<PC_SupportPlanActivity__c> oSupPlanActyTest = [
                    SELECT ID, Name, PC_ActivityType__c, PC_InternalActivityNumber__c, PC_SupportPlan__c
                    FROM PC_SupportPlanActivity__c
                    WHERE PC_SupportPlan__c = :oSupPlan.Id
            ];
            Test.StopTest();
        }
    }

    @isTest static void testSaveRecordGroup() {
        createTestData();
        system.runAs(objUser) {
            Test.StartTest();
            STRING prevJSON;
            STRING prevJSONString;
            //Add Group 1
            Map<String, String> saveActivityMap7 = new Map<String, String>();
            saveActivityMap7.put('activityId', 'Group 1');
            saveActivityMap7.put('supportPlanID', oSupPlan.Id);
            saveActivityMap7.put('supActivityJSON', oSupPlanGroup1);
            saveActivityMap7.put('prevActivityJSON', prevJSONString);
            saveActivityMap7.put('nextActivity', nextActivity);
            Boolean returnValue = PC_ActivityProperties_Controller.determineSave(saveActivityMap7);
            PC_SupportPlanActivity__c group1 = [
                    SELECT Id, Name, PC_ActivitySequence__c, PC_ActivityType__c, PC_InternalActivityType__c, PC_AlternateActivity__c, PC_ApexCondition__c,
                            PC_Channel__c, PC_Conditional_Logic__c, PC_ConditionBehavior__c, PC_ConditionOption__c, PC_Description__c, PC_InitialSequenceActivity__c, PC_InternalActivityNumber__c,
                            PC_NextActivityNumber__c, PC_Priority__c, PC_ReferenceDate__c, PC_ReferenceOffset__c, PC_ReferenceOffsetUnit__c,PC_ActionClass__c,
                            PC_ReferenceType__c, PC_Subject__c, PC_SupportPlan__c, PC_Assign_To_Role__c, PC_UserTask_Fields__c,PC_SubType__c,PC_AutomationTaskJSON__c, PC_ClonedFrom__c, PC_GroupActivityExecution__c
                    FROM PC_SupportPlanActivity__c
                    WHERE PC_SupportPlan__c = :oSupPlan.Id and PC_InternalActivityType__c = :PC_Constants.SUPPORTPLAN_ACTIVITY_TYPE_SEQUENCE
                    LIMIT 1
            ];
            System.assertEquals(group1.PC_GroupActivityExecution__c, 'In sequence');
            Test.StopTest();
        }
    }


    @isTest static void testGetReferenceDatePickList() {
        createTestData();
        system.runAs(objUser) {

            Test.startTest();
            PC_ActivityProperties_Controller.getReferenceDatePickistVal(PC_Constants.PC_ACCOUNT,PC_Constants.PC_ACCOUNT);
            PC_ActivityProperties_Controller.getFieldLabels();
            Test.stopTest();

        }
    }
    @isTest static void testGetConstantsWrapper() {
        createTestData();
        system.runAs(objUser) {

            Test.startTest();
            PC_ActivityProperties_Controller.getConstantsWrapper();
            Test.stopTest();

        }
    }
    @isTest static void testFetchActivity() {
        createTestData();
        system.runAs(objUser) {

            Test.startTest();
            Map<String, String> activityMap = new Map<String, String>();
            activityMap.put('activityId', act1.Id);
            activityMap.put('internalactivitynumber', act1.Id);
            activityMap.put('activityName', 'Activity 2');
            activityMap.put('internalactivitytype', 'User Task');
            activityMap.put('supportPlanID', 'Activity Support Id');

            PC_ActivityProperties_Controller.fetchActivity(activityMap);
            PC_ActivityProperties_Controller.getSupportPlanAutomationTaskData(oSupPlan.Id, 'Case');
            Test.stopTest();

        }
    }
    @isTest static void testFetchActivityUpdateRecord() {
        createTestData();
        system.runAs(objUser) {

            Test.startTest();
            Map<String, String> activityMap = new Map<String, String>();
            activityMap.put('activityId', act5.Id);
            activityMap.put('internalactivitynumber', act5.Id);
            activityMap.put('activityName', 'Activity 5');
            activityMap.put('internalactivitytype', 'User Task');
            activityMap.put('supportPlanID', 'Activity Support Id');

            PC_ActivityProperties_Controller.fetchActivity(activityMap);
            PC_ActivityProperties_Controller.getSupportPlanAutomationTaskData(oSupPlan.Id, 'Case');
            Test.stopTest();

        }
    }
    @isTest static void testFetchActivityCreateRecord() {
        createTestData();
        system.runAs(objUser) {

            Test.startTest();
            Map<String, String> activityMap = new Map<String, String>();
            activityMap.put('activityId', act6.Id);
            activityMap.put('internalactivitynumber', act6.Id);
            activityMap.put('activityName', 'Activity 6');
            activityMap.put('internalactivitytype', 'User Task');
            activityMap.put('supportPlanID', 'Activity Support Id');

            PC_ActivityProperties_Controller.fetchActivity(activityMap);
            PC_ActivityProperties_Controller.getSupportPlanAutomationTaskData(oSupPlan.Id, 'Case');
            Test.stopTest();

        }
    }
    @isTest static void testGetRequiredFields() {
        createTestData();
        act1.usertaskfields = '{"requiredFieldSet":[{"label":"Priority","value":"High","type":"PICKLIST","apiName":"Priority","isDeleteAllowed":false}]}';
        system.runAs(objUser) {

            Test.startTest();
            String result = PC_ActivityProperties_Controller.GetRequiredFields('Task', null, act1);
            System.assert(result != null);
            Test.stopTest();

        }
    }

    @isTest static void testCreateTask() {
        Task t = new Task();
        try {
            if (true) {
                //System.debug('##Task spActivity'+spActivity);
                String taskFields = '{"requiredFieldSet":[{"label":"Priority","value":"High","type":"PICKLIST","apiName":"Priority","isDeleteAllowed":false},' +
                        '{"label":"Channel","value":"Call","type":"PICKLIST","apiName":"PC_Channel__c","isDeleteAllowed":false},' +
                        '{"label":"Subject","value":"sub786","type":"COMBOBOX","apiName":"Subject","isDeleteAllowed":false},' +
                        '{"label":"Assign to Role","value":"Care Coordinator","type":"PICKLIST","apiName":"PC_Assign_to_Role__c","isDeleteAllowed":false}]}';
                PC_ActivityProperties_Controller.RequiredFieldSetWrapper fieldsWrapper = (PC_ActivityProperties_Controller.RequiredFieldSetWrapper) System.JSON.deserialize(taskFields, PC_ActivityProperties_Controller.RequiredFieldSetWrapper.class);
                for (PC_ActivityProperties_Controller.RequiredFieldWrapper row : fieldsWrapper.requiredFieldSet) {
                    //Class  aClass = MyObject.class
                    //Field field = t.getField(row.apiName);
                    //field.set(t, row.value);
                    t.put(row.apiName, row.value);
                }
                system.debug(t);
            }
            System.debug('##Task' + t);
        } catch (Exception ex) {
            PC_Utility.createExceptionLog(ex);
        }
        //return t;
    }

}