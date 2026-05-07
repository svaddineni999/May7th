/**************************************************************************************
Apex Class Name     : PC_Test_PropertiesAndConditionsBuilder
Description         : This class is used for testing PC_PropertiesAndConditionsBuilder;
CreatedBy           : Deloitte
Created Date        : 30 Sept 2020
Modification Log    :
--------------------------------------------------------------------------------------------------------------
Developer                   Date                   Description
----------------------------------------------------------------------------
Kanteti Kishore            30 Sept 2020           Initial version
Kanteti Kishore            15 Oct 2020            PC-6813 Added server side logic evaluation test method.
Kanteti Kishore            1 Nov 2020            PC-6825 Added getAllFormulaOptions test method.
*****************************************************************************************/
@isTest
public with sharing class PC_Test_PropertiesAndConditionsBuilder{

    private static User adminUser;
    private static String eventObjectType = 'Data Object';
    private static String fieldName = 'PC_ParentManufacturer__c';
    private static String builderContext = 'ConditionalBuilder';
    private static String builderContextPropertyBuilder = 'PropertyBuilder';
    private static String objectName = 'Case';
    private static String logic = 'TRUE AND FALSE OR (TRUE AND FALSE)';

    private static void createTestData() {
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'userpctest@test2.com', 'test2');
        PC_Database.ins(adminUser);
    }

    @isTest static void testGetObjectFields(){
        createTestData();
        system.runAs(adminUser) {
            Test.startTest();
            List<PC_PropertiesAndConditionsBuilder.ObjectFieldsRequest> objectFieldsRequestList = new List<PC_PropertiesAndConditionsBuilder.ObjectFieldsRequest>();
            PC_PropertiesAndConditionsBuilder.ObjectFieldsRequest objectFieldsRequest = new PC_PropertiesAndConditionsBuilder.ObjectFieldsRequest();
            objectFieldsRequest.builderContext = builderContext;
            objectFieldsRequest.objectName = objectName;
            objectFieldsRequest.includeRecordTypeId = true;
            objectFieldsRequestList.add(objectFieldsRequest);

            List<PC_PropertiesAndConditionsBuilder.ObjectFieldsResponse> objectFieldsResponseList = new List<PC_PropertiesAndConditionsBuilder.ObjectFieldsResponse>();
            objectFieldsResponseList = PC_PropertiesAndConditionsBuilder.getObjectFields(objectFieldsRequestList);
            if (!objectFieldsResponseList.isEmpty()) {
                System.assert(true);
            } else {
                System.assert(false);
            }
            Test.stopTest();
        }
    }
    @isTest static void testGetObjectFieldsPropertyBuilder(){
        createTestData();
        system.runAs(adminUser) {
            Test.startTest();
            List<PC_PropertiesAndConditionsBuilder.ObjectFieldsRequest> objectFieldsRequestList = new List<PC_PropertiesAndConditionsBuilder.ObjectFieldsRequest>();
            PC_PropertiesAndConditionsBuilder.ObjectFieldsRequest objectFieldsRequest = new PC_PropertiesAndConditionsBuilder.ObjectFieldsRequest();
            objectFieldsRequest.builderContext = builderContextPropertyBuilder;
            objectFieldsRequest.objectName = objectName;
            objectFieldsRequest.includeRecordTypeId = true;
            objectFieldsRequestList.add(objectFieldsRequest);

            List<PC_PropertiesAndConditionsBuilder.ObjectFieldsResponse> objectFieldsResponseList = new List<PC_PropertiesAndConditionsBuilder.ObjectFieldsResponse>();
            objectFieldsResponseList = PC_PropertiesAndConditionsBuilder.getObjectFields(objectFieldsRequestList);
            if (!objectFieldsResponseList.isEmpty()) {
                System.assert(true);
            } else {
                System.assert(false);
            }
            Test.stopTest();
        }
    }
    @isTest static void testGetLogicEvaluationResult(){
        createTestData();
        system.runAs(adminUser) {
            Test.startTest();
            PC_PropertiesAndConditionsBuilder.getLogicEvaluationResult(logic);
            //System.assertEquals(result,true);
            Test.stopTest();
        }
    }
    @isTest static void tesGetFieldDropdownValues(){
        createTestData();
        system.runAs(adminUser) {
            Test.startTest();
            String recType = 'Case';
            String fieldApiName = 'Status';
            List<PC_PropertiesAndConditionsBuilder.DropdownValue> fieldPicklistValues = new List<PC_PropertiesAndConditionsBuilder.DropdownValue>();
            fieldPicklistValues = PC_PropertiesAndConditionsBuilder.getFieldDropdownValues(recType, fieldApiName);
            if (!fieldPicklistValues.isEmpty()){
                System.assert(true);
            } else {
                System.assert(false);
            }
            Test.stopTest();
        }
    }

    @isTest static void testGetTriggerObjectLookUpFields(){
        createTestData();
        system.runAs(adminUser) {
            Test.startTest();
            List<PC_PropertiesAndConditionsBuilder.DropdownValue> allDropdownValues = new List<PC_PropertiesAndConditionsBuilder.DropdownValue>();
            allDropdownValues = PC_PropertiesAndConditionsBuilder.getTriggerObjectLookupFields(PC_Constants.PC_ACCOUNT,eventObjectType,PC_Constants.PC_ACCOUNT,PC_Constants.getQualifiedAPIName(fieldName));
            if (!allDropdownValues.isEmpty()) {
                System.assert(true);
            } else {
                System.assert(false);
            }
            Test.stopTest();
        }
    }

    @isTest static void testGetUserLookUpFields(){
        createTestData();
        system.runAs(adminUser) {
            Test.startTest();
            List<PC_PropertiesAndConditionsBuilder.DropdownValue> allUserLookupValues = new List<PC_PropertiesAndConditionsBuilder.DropdownValue>();
            allUserLookupValues = PC_PropertiesAndConditionsBuilder.getUserLookUpValues(PC_Constants.PC_ACCOUNT);
            if (!allUserLookupValues.isEmpty()) {
                System.assert(true);
            } else {
                System.assert(false);
            }
            Test.stopTest();
        }
    }
    @isTest static void testGetAllFormulaOptions(){
        createTestData();
        system.runAs(adminUser) {
            Test.startTest();
            PC_PropertiesAndConditionsBuilder.DateAndDatetimeFormulaOptions allFormulaOptions = new PC_PropertiesAndConditionsBuilder.DateAndDatetimeFormulaOptions();
            allFormulaOptions = PC_PropertiesAndConditionsBuilder.getAllFormulaOptions(PC_Constants.PC_ACCOUNT);
            if (!allFormulaOptions.dateAndDatetimeFields.isEmpty()) {
                System.assert(true);
            } else {
                System.assert(false);
            }
            Test.stopTest();
        }
    }
}