/*********************************************************************************************************
Class Name      : PC_Test_CreateOrUpdateAutomationTask
Description     : Class to test PC_CreateOrUpdateAutomationTask
Created By      : Kishore Kanteti
Created Date    : July 8, 2020
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer                   Date                   Description
--------------------------------------------------------------------------------------------------------------
Kishore Kanteti           Jul 8,2020             Initial Version
************************************************************************************************************/
@IsTest
private class PC_Test_CreateOrUpdateAutomationTask {
    @isTest static void testGetObjects() {
        Test.startTest();
        PC_CreateOrUpdateAutomationTask.objects objects = PC_CreateOrUpdateAutomationTask.getObjects(PC_Constants.PC_CASE);
        Boolean objectsListEmpty = true;
        if (objects.triggerEventLookupObjects.size() != 0 || objects.triggerEventChildObjects.size() != 0) {
            objectsListEmpty = false;
        }
        System.assertEquals(objectsListEmpty, false);
        Test.stopTest();
    }
    @isTest static void testGetChildUpdatePicklistValues() {
        Test.startTest();
        PC_CreateOrUpdateAutomationTask.childUpdateOptions childUpdateValues = PC_CreateOrUpdateAutomationTask.getChildUpdateOptions(PC_Constants.PC_CASE);
        Boolean valuesListEmpty = true;
        if (childUpdateValues.orderByFields.size() != 0 || childUpdateValues.orderOptions.size() != 0 || childUpdateValues.criteriaOptions.size() != 0) {
            valuesListEmpty = false;
        }
        System.assertEquals(valuesListEmpty, false);
        Test.stopTest();
    }
    @isTest static void testGetObjectsAndChildUpdateOptions() {
        Test.startTest();
        PC_CreateOrUpdateAutomationTask.ObjectsAndChildUpdateOptions objectsAndOptions = PC_CreateOrUpdateAutomationTask.getObjectsAndChildUpdateOptions(PC_Constants.PC_CASE,PC_Constants.PC_CASE);
        Boolean valuesListEmpty = true;
        if (objectsAndOptions.childUpdateOptions.orderByFields.size() != 0 || objectsAndOptions.childUpdateOptions.orderOptions.size() != 0 || objectsAndOptions.childUpdateOptions.criteriaOptions.size() != 0) {
            valuesListEmpty = false;
        }
        if (objectsAndOptions.lookupAndChildObjects.triggerEventLookupObjects.size() != 0 || objectsAndOptions.lookupAndChildObjects.triggerEventChildObjects.size() != 0) {
            valuesListEmpty = false;
        }
        System.assertEquals(valuesListEmpty, false);
        Test.stopTest();
    }
}