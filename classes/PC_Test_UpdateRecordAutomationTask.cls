/**************************************************************************************
Apex Class Name     : PC_Test_UpdateRecordAutomationTask
Description         : This class is used for testing PC_UpdateRecordAutomationTask;
CreatedBy           : Haritha Reddy
Created Date        : 25 Jun, 2020
Modification Log    :
--------------------------------------------------------------------------------------------------------------
Developer                   Date                   Description
----------------------------------------------------------------------------
Haritha Reddy            25 Jun, 2020          Initial version
Haritha Reddy            07 Jul, 2020          [PC-6455] Added test method for Update record Scenario 3
Haritha Reddy            30 Nov, 2020          [PC-7001] Made changes to test Custom logic in filter conditions of Update Child records Action
*************************************************************************************/
@isTest(seeAllData=false)
public with sharing class PC_Test_UpdateRecordAutomationTask {
    private static User adminUser;
    private static User careCoordinator;
    private static Case programCase;
    private static PC_Program_Coverage__c programCoverage1,programCoverage2;
    private static Account patient;
    private static Account  manufacturer;
    private static PC_SupportPlan__c supportPlan1;
    private static PC_SupportPlanActivity__c supPlanActy1;
    private static PC_Engagement_Program__c engagementProgram;
    private static PC_EngagementProgram_SupportPlan__c engagementProgramSupportPlan;
    private static Task outcomeTask;
    /*********************************************************************************
    Method Name    : createTestData
    Author         : Haritha Reddy
    Description    : This method is used for creating test data
    Return Type    : void
    *********************************************************************************/
    private static void createTestData() {
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user1pctest@email.com', 'test1');
        PC_Database.ins(adminUser, false);

        //Create Care Coordinator
        careCoordinator = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user2pctest@email.com', 'test2');
        careCoordinator = (User) PC_Database.ins(careCoordinator);

        patient = PC_Test_Setup.createSampleAccount('', PC_Constants.PATIENT_RECORD_TYPE);
        patient.PC_Date_of_Birth__c = date.today().addDays(-100);
        patient = (Account)PC_Database.ins(patient, false);
        // check if patient is created
        system.assertNotEquals(patient.Id, null);

        //Create Manufacturer
        List<Account>  manufacturers = PC_Test_Setup.createAccounts('testmanufacturer', 1, PC_Constants.MANUFACTURER_RECORD_TYPE);
        manufacturer = (Account)PC_Database.ins(manufacturers[0], false);

        //Create Engagement Program
        engagementProgram= PC_Test_Setup.createEngagementProgram('TestPrgm',manufacturer.Id );
        engagementProgram.PC_Program_Code__c = 'TestPrgm';
        engagementProgram = (PC_Engagement_Program__c) PC_Database.ins(engagementProgram, false);

        programCase = PC_Test_Setup.createCase(adminUser, patient);
        programCase.PC_Engagement_Program__c = engagementProgram.Id;
        programCase.PC_Care_Coordinator__c      =   careCoordinator.Id;
        programCase.PC_Enrollment_Date__c = date.today().addDays(-10);
        programCase.PC_Treatment_Start_Date__c = date.today();
        programCase.IsEscalated = false;
        programCase.HealthCloudGA__FinancialValue__c = 10;
        programCase = (Case)PC_Database.ins(programCase, false);
        // check if program Case is created
        system.assertNotEquals(programCase.Id, null);

        //Create Support Plan
        supportPlan1= PC_Test_Setup.createSupportPlan();
        supportPlan1.PC_IsActive__c=true;
        supportPlan1.PC_TriggerEventObject__c='Case';
        supportPlan1.PC_TriggerEventType__c='Insert/Update';
        supportPlan1.PC_TriggerEventConditionalBehavior__c = PC_Constants.SUPPORTPLAN_CONDBEHAVIOR_STATUS_WAIT;
        supportPlan1.PC_TriggerEventConditionOption__c = PC_Constants.PC_COND_OPTION_CONDITIONAL_BUILDER;
        supportPlan1.PC_TriggerEventCondition__c = '{"LstConditionsPerObject":[{"Conditions":[{"ConditionNo":1,"FieldName":"Status",'+
                '"FieldApiName":"Status","Operator":"Does not equals","Type":"Picklist","Value":"In Treatment"}],"Logic":""}]}';
        supportPlan1.PC_ConditionBehavior__c = PC_Constants.SUPPORTPLAN_CONDBEHAVIOR_STATUS_NONE;
        supportPlan1 = (PC_SupportPlan__c) PC_Database.ins(supportPlan1, false);

        //Create Support Plan Activity1
        supPlanActy1= PC_Test_Setup.createUpdateRecordSupportPlanActivity('Activity 1: Update Case');
        supPlanActy1.PC_SupportPlan__c = supportPlan1.Id;
        supPlanActy1 = (PC_SupportPlanActivity__c) PC_Database.ins(supPlanActy1, false);

        //Create Engagement Program Support Plan Junction Object
        engagementProgramSupportPlan= PC_Test_Setup.createEnggmtPgmSupPlan();
        engagementProgramSupportPlan.PC_EngagementProgram__c=engagementProgram.Id;
        engagementProgramSupportPlan.PC_SupportPlan__c=supportPlan1.Id;
        engagementProgramSupportPlan = (PC_EngagementProgram_SupportPlan__c)PC_Database.ins(engagementProgramSupportPlan, false);
    }

    @isTest static void testUpdateTriggerRecord() {
        try{
            createTestData();
            supportPlan1.PC_InitialActivity__c = supPlanActy1.Id;
            supportPlan1 = (PC_SupportPlan__c) PC_Database.upd(supportPlan1, false);

            Test.StartTest();
            system.runAs(adminUser) {
                programCase.Status = 'Enrolled';
                PC_Database.upd(programCase, false);
            }
            //Deliver the Support Plan Info Platform event with context "ExecuteActions"
            Test.getEventBus().deliver();
            //Deliver the Support Plan Info Platform event with context "ProcessSupportPlanRuntimes"
            Test.getEventBus().deliver();
            Test.StopTest();

            Case updatedCase  = [SELECT ID,Status FROM Case WHERE ID =:programCase.Id Limit 1];
            system.assertEquals('In Treatment',updatedCase.Status,'update Record failed');

            //Query the Outcome Task
            outcomeTask  = [SELECT ID,WhatId,Status,PC_SupportPlanActivity__c,Description FROM Task
            WHERE WhatId =:programCase.Id AND PC_SupportPlanActivity__c =:supPlanActy1.Id];
            system.assertNotEquals(outcomeTask, null,'outcomeTask creation failed');

            //Query the Log
            PC_SupportPlanActivityLog__c log  = [SELECT ID,PC_TriggerRecordId__c,PC_ActionRecordId__c,PC_SupportPlanActivity__c,PC_Status__c
            FROM PC_SupportPlanActivityLog__c WHERE PC_TriggerRecordId__c =:programCase.Id AND PC_SupportPlanActivity__c =:supPlanActy1.Id];

            system.assertNotEquals(log.PC_ActionRecordId__c, null);
            system.assertEquals(log.PC_Status__c, PC_Constants.PC_LOG_STATUS_COMPLETED);

        }catch(Exception ex){
            system.debug('exception>>'+ex.getMessage());
            system.assert(false,ex.getMessage()+' : '+ex.getStackTraceString() + ' : '+ ex.getLineNumber());
        }
    }


    @isTest static void testUpdateLookupRecord() {
        try{
            createTestData();
            supportPlan1.PC_InitialActivity__c = supPlanActy1.Id;
            supportPlan1 = (PC_SupportPlan__c) PC_Database.upd(supportPlan1, false);

            supPlanActy1.PC_AutomationTaskJSON__c = '{"type":"updateLookupRecord","orderBy":[],"continueWhenNoUpdates":"TRUE",'+
                    '"objectDetails":{"qualifiedApiName":"Account","relativeQualifiedApiPath":"AccountId"},"LstConditionsPerObject":[],'+
                    '"fieldMapping":[{"label":"Gender","apiName":"'+PC_Constants.getQualifiedAPIName('PC_Gender__c')+
                    '","isDeleteAllowed":false,"type":"Picklist","value":"Male","isBoundValue":false}],"outcomeTaskDetails":{"create":true}}';
            supPlanActy1 = (PC_SupportPlanActivity__c) PC_Database.upd(supPlanActy1, false);

            Test.StartTest();
            system.runAs(adminUser) {
                programCase.Status = 'Enrolled';
                PC_Database.upd(programCase, false);
            }
            //Deliver the Support Plan Info Platform event with context "ExecuteActions"
            Test.getEventBus().deliver();
            //Deliver the Support Plan Info Platform event with context "ProcessSupportPlanRuntimes"
            Test.getEventBus().deliver();
            Test.StopTest();

            Case updatedCase  = [SELECT ID,Account.PC_Gender__c FROM Case WHERE ID =:programCase.Id Limit 1];
            system.assertEquals('Male',updatedCase.Account.PC_Gender__c,'update Record failed');

            //Query the Outcome Task
            outcomeTask  = [SELECT ID,WhatId,Status,PC_SupportPlanActivity__c,Description FROM Task
            WHERE WhatId =:programCase.Id AND PC_SupportPlanActivity__c =:supPlanActy1.Id];
            system.assertNotEquals(outcomeTask, null,'outcomeTask creation failed');

            //Query the Log
            PC_SupportPlanActivityLog__c log  = [SELECT ID,PC_TriggerRecordId__c,PC_ActionRecordId__c,PC_SupportPlanActivity__c,PC_Status__c
            FROM PC_SupportPlanActivityLog__c WHERE PC_TriggerRecordId__c =:programCase.Id AND PC_SupportPlanActivity__c =:supPlanActy1.Id];

            system.assertNotEquals(log.PC_ActionRecordId__c, null);
            system.assertEquals(log.PC_Status__c, PC_Constants.PC_LOG_STATUS_COMPLETED);

        }catch(Exception ex){
            system.debug('exception>>'+ex.getMessage());
            system.assert(false,ex.getMessage()+' : '+ex.getStackTraceString() + ' : '+ ex.getLineNumber());
        }
    }

    @isTest static void testUpdateChildRecords() {
        try{
            createTestData();

            Id medicalCoverageRecordTypeId = PC_System.recordTypeId(PC_Constants.PC_PROGRAM_COVERAGE, PC_Constants.PROGRAM_COVERAGE_MEDICAL_RECORD_TYPE);
            programCoverage1 = PC_Test_Setup.createProgramCoverage(programCase.Id);
            programCoverage1.RecordTypeId = medicalCoverageRecordTypeId;
            programCoverage1.PC_Coverage_Percentage__c = 30;
            programCoverage1.PC_Coverage_Status__c = 'Active';
            programCoverage1.PC_Copay_Amount__c = 500;
            programCoverage1.PC_Eligible__c = true;
            programCoverage1.PC_Alt_Fund_Decision_Date_1__c = Date.valueOf('2020-07-04');
            programCoverage1 = (PC_Program_Coverage__c)PC_Database.ins(programCoverage1, false);
            system.assertNotEquals(programCoverage1.Id, null);

            programCoverage2 = PC_Test_Setup.createProgramCoverage(programCase.Id);
            programCoverage2.RecordTypeId = medicalCoverageRecordTypeId;
            programCoverage2.PC_Coverage_Percentage__c = 20;
            programCoverage2.PC_Coverage_Status__c = 'Active';
            programCoverage2.PC_Copay_Amount__c = 100;
            programCoverage2.PC_Eligible__c = true;
            programCoverage2.PC_Alt_Fund_Decision_Date_1__c = Date.valueOf('2020-07-04');
            programCoverage2 = (PC_Program_Coverage__c)PC_Database.ins(programCoverage2, false);
            system.assertNotEquals(programCoverage2.Id, null);

            supportPlan1.PC_InitialActivity__c = supPlanActy1.Id;
            supportPlan1 = (PC_SupportPlan__c) PC_Database.upd(supportPlan1, false);

            supPlanActy1.PC_AutomationTaskJSON__c = '{"type":"updateChildRecords","sortOrderInfo": [{"orderBy": ["'+PC_Constants.getQualifiedAPIName('PC_Coverage_Percentage__c')+'"],"order": "DESC","nullsOrder": "Last"}],'+
                    '"updateCriteria":"FIRST_RECORD","continueWhenNoUpdates":"FALSE","objectDetails":'+
                    '{"qualifiedApiName":"'+PC_Constants.PC_PROGRAM_COVERAGE+'","relativeQualifiedApiPath":"'+PC_Constants.getQualifiedAPIName('Program_Coverages__r')+'"},'+
                    '"LstConditionsPerObject":[{"ObjectType":"'+PC_Constants.getQualifiedAPIName('PC_Program_Coverage__c')+'","Conditions":['+
                    '{"ConditionNo":1,"FieldName":"Record Type Name","FieldApiName":"RecordType","Operator":"Equals","Type":"Picklist","Value":"'+PC_Constants.getQualifiedAPIName('PC_Medical_Coverage')+'"},'+
                    '{"ConditionNo":2,"FieldName":"Coverage %","FieldApiName":"'+PC_Constants.getQualifiedAPIName('PC_Coverage_Percentage__c')+'","Operator":"Is not null","Type":"Percent","Value":""},'+
                    '{"ConditionNo":3,"FieldName":"Coverage %","FieldApiName":"'+PC_Constants.getQualifiedAPIName('PC_Coverage_Percentage__c')+'","Operator":"Less than or equal","Type":"Percent","Value":"40"},'+
                    '{"ConditionNo":4,"FieldName":"Comments","FieldApiName":"'+PC_Constants.getQualifiedAPIName('PC_Comments__c')+'","Operator":"Is null","Type":"Textarea","Value":""},'+
                    '{"ConditionNo":5,"FieldName":"Record Type Name","FieldApiName":"RecordType","Operator":"Is not null","Type":"Picklist","Value":""},'+
                    '{"ConditionNo":6,"FieldName":"Coverage Status","FieldApiName":"'+PC_Constants.getQualifiedAPIName('PC_Coverage_Status__c')+'","Operator":"Equals","Type":"Picklist","Value":"Active"},'+
                    '{"ConditionNo":7,"FieldName":"Copay Amount","FieldApiName":"'+PC_Constants.getQualifiedAPIName('PC_Copay_Amount__c')+'","Operator":"Less than","Type":"Currency","Value":"50000"},'+
                    '{"ConditionNo":8,"FieldName":"Eligible","FieldApiName":"'+PC_Constants.getQualifiedAPIName('PC_Eligible__c')+'","Operator":"Equals","Type":"Boolean","Value":"True"},'+
                    '{"ConditionNo":9,"FieldName":"Comments","FieldApiName":"'+PC_Constants.getQualifiedAPIName('PC_Comments__c')+'","Operator":"Does not equals","Type":"Textarea","Value":"test"},'+
                    '{"ConditionNo":10,"FieldName":"Decision Date 1","FieldApiName":"'+PC_Constants.getQualifiedAPIName('PC_Alt_Fund_Decision_Date_1__c')+'","Operator":"Equals","Type":"Date","Value":"2020-07-04"}],'+
                    '"Logic":"1 AND ((2 OR 3) OR NOT(4 AND 5)) AND 6 AND 7 OR 8 AND 9 AND 10"}],"fieldMapping":['+
                    '{"label":"Coverage %","apiName":"'+PC_Constants.getQualifiedAPIName('PC_Coverage_Percentage__c')+'","isDeleteAllowed":false,"type":"Percent","value":"100","isBoundValue":false},'+
                    '{"label":"Comments","apiName":"'+PC_Constants.getQualifiedAPIName('PC_Comments__c')+'","isDeleteAllowed":false,"type":"Textarea","value":"Updated through SP","isBoundValue":false}],'+
                    '"outcomeTaskDetails":{"create":true}}';
            supPlanActy1 = (PC_SupportPlanActivity__c) PC_Database.upd(supPlanActy1, false);

            Test.StartTest();
            system.runAs(adminUser) {
                programCase.Status = 'Enrolled';
                PC_Database.upd(programCase, false);
            }
            //Deliver the Support Plan Info Platform event with context "ExecuteActions"
            Test.getEventBus().deliver();
            //Deliver the Support Plan Info Platform event with context "ProcessSupportPlanRuntimes"
            Test.getEventBus().deliver();
            Test.StopTest();

            List<PC_Program_Coverage__c> updatedPC  = [SELECT ID,PC_Coverage_Percentage__c FROM PC_Program_Coverage__c WHERE Id =:programCoverage1.Id];
            system.assertEquals(100,updatedPC[0].PC_Coverage_Percentage__c,'update child Records failed');

            //Query the Outcome Task
            outcomeTask  = [SELECT ID,WhatId,Status,PC_SupportPlanActivity__c,Description FROM Task
            WHERE WhatId =:programCase.Id AND PC_SupportPlanActivity__c =:supPlanActy1.Id];
            system.assertNotEquals(outcomeTask, null,'outcomeTask creation failed');

            //Query the Log
            PC_SupportPlanActivityLog__c log  = [SELECT ID,PC_TriggerRecordId__c,PC_ActionRecordId__c,PC_SupportPlanActivity__c,PC_Status__c
            FROM PC_SupportPlanActivityLog__c WHERE PC_TriggerRecordId__c =:programCase.Id AND PC_SupportPlanActivity__c =:supPlanActy1.Id];

            system.assertNotEquals(log.PC_ActionRecordId__c, null);
            system.assertEquals(log.PC_Status__c, PC_Constants.PC_LOG_STATUS_COMPLETED);

        }catch(Exception ex){
            system.debug('exception>>'+ex.getMessage());
            system.assert(false,ex.getMessage()+' : '+ex.getStackTraceString() + ' : '+ ex.getLineNumber());
        }
    }
}