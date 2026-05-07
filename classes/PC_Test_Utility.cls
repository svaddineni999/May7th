/**************************************************************************************
Apex Class Name     : PC_Test_Utility
Description         : This class is used for testing PC_Utility;
CreatedBy           : Deloitte
Created Date        : 01 August 2016
Modification Log    :
----------------------------------------------------------------------------
Developer                   Date                   Description
----------------------------------------------------------------------------                 
Alina Balan                 01 August 2016          Initial version
Mayuresh Patil              Apr 07, 2017            [PC-1369] Resolved blocker issue raised by force reviewer scanner tool.
Ajinkya Deshmukh			Apr-11-2017				PC-1420 updated testcreateExceptionLog to accomodate error log changes future method changes.
Ajinkya Deshmukh			Jun-27-2017				Updated test method to accomodate createExceptionForFutureCallout() in PC_Utility
Shabda Bhujad				Aug-29-2017				[PC-2166] Removed the hardcoded page reference to Exception page, which is not included in the package
Tejas Patel                 Apr 05, 2018            Getting the Code Coverage Up
Vijay Kashikar              Apr 16, 2018            [PC-2695] tested logAndThrowException methods
Mike Klumpenaar             Feb 20, 2019            [PC-4475] Renamed a few PC_Utility methods.
Xiukai Ning                 Jun 24, 2019            [PC-5002] Test methods for new error handling methods for Core
Tushar Arora                Oct 18, 2019            [PC-5508] Test methods for new Document RecordType Grouping Method methods for Core
Haritha Reddy               Oct 13, 2020            [PC-6332] Added Test method for evaluate Condition Logic method
Haritha Reddy               Nov 20, 2020            [PC-6332] Added logic to test 'Not' Condition evaluation
*************************************************************************************/
@isTest(seeAllData=False) 
public class PC_Test_Utility { 
    
    private static PC_Document__c oDoc;

    /*********************************************************************************
    Method Name    : testcreateExceptionLog
    Author         : Alina Balan
    Description    : This method is used for testing a "createExceptionLog"
    Return Type    : void 
    Parameter      : 
    *********************************************************************************/
    @isTest static void testcreateExceptionLog(){
        Test.StartTest();
        String errorMessage = 'test error message';
        String className = 'TestClass';
        String methodName ='TestMethod';
        String additionalInfo = 'need some information';
        Integer lineNum = 999;
        List<Id> accountIdList = new List<Id>();
        List<Account> accountTestList = new List<Account>();

        List<Account> patientAccounts = PC_Test_Setup.createAccounts('Patient', 3, PC_Constants.PATIENT_RECORD_TYPE);
        accountTestList = PC_Database.ins(patientAccounts);

        try {
            throw new TestException(errorMessage);
        } catch(Exception ex) {
            //PageReference pageRef = Page.Exception;
            //system.Test.setCurrentPage(pageRef);
            PC_Utility.createExceptionLog(ex, errorMessage);
            PC_Utility.createExceptionLog(ex, PC_Utility.DISPLAY_WARNING);
            PC_Utility.createExceptionLog(ex, PC_Utility.DISPLAY_INFO);
            PC_Utility.createExceptionLog(ex, PC_Utility.DISPLAY_ERROR);
            PC_Utility.createErrorLog(errorMessage);
            PC_Utility.createErrorLog(errorMessage, additionalInfo);
            PC_Utility.publishErrorLog(ex, errorMessage);

            //new methods for Core
            PC_Utility.createExceptionLog(new PC_Utility.ErrorInfoWrapper(ex, errorMessage,
                    className, methodName, 999, patientAccounts, PC_Utility.ERROR_LOG_LEVEL.ERROR_LOG_LEVEL_DEBUG, additionalInfo));
            PC_Utility.createExceptionLog(new PC_Utility.ErrorInfoWrapper(ex, errorMessage,
                    className, methodName, 999, patientAccounts, PC_Utility.ERROR_LOG_LEVEL.ERROR_LOG_LEVEL_INFO, additionalInfo));
            PC_Utility.createExceptionLog(new PC_Utility.ErrorInfoWrapper(ex, errorMessage,
                    className, methodName, 999, patientAccounts, PC_Utility.ERROR_LOG_LEVEL.ERROR_LOG_LEVEL_ERROR, additionalInfo));
            PC_Utility.createExceptionLog(new PC_Utility.ErrorInfoWrapper(ex, errorMessage,
                    className, methodName, 999, patientAccounts, PC_Utility.ERROR_LOG_LEVEL.ERROR_LOG_LEVEL_WARN, additionalInfo));
            PC_Utility.createExceptionLog(new PC_Utility.ErrorInfoWrapper(ex, errorMessage,
                    className, methodName, 999, patientAccounts, null, additionalInfo));
        }

        try {
            PC_Utility.throwAuraHandledException(errorMessage);
        }
        catch(Exception e) {

        }
        try {
            TestException te = new TestException(errorMessage);
            PC_Utility.logAndThrowException(te);
        }
        catch (Exception e) {

        }
        try {
            TestException te = new TestException(errorMessage);
            PC_Utility.publishAndThrowException(te, additionalInfo);//deprecated method. Improving coverage only.
        }
        catch (Exception e) {

        }
        try {
            TestException te = new TestException(errorMessage);
            PC_Utility.logAndThrowException(new PC_Utility.ErrorInfoWrapper(te, errorMessage,
                    className, methodName, 999, accountTestList, PC_Utility.ERROR_LOG_LEVEL.ERROR_LOG_LEVEL_DEBUG, additionalInfo));
        }
        catch (Exception e){

        }
        try {
            TestException te = new TestException(errorMessage);
            PC_Utility.logAndThrowException(new PC_Utility.ErrorInfoWrapper(te, errorMessage,
                    className, methodName, 999, null, PC_Utility.ERROR_LOG_LEVEL.ERROR_LOG_LEVEL_DEBUG, additionalInfo));
        }
        catch (Exception e){

        }
        Test.StopTest();
        List<PC_Error_Log__c> lstErrorLogs = [SELECT Id FROM PC_Error_Log__c LIMIT 1000];
        system.assertEquals(lstErrorLogs.size() > 0, true);
     }

    @isTest static void testGetGroups(){
        oDoc = PC_Test_Setup.createDocument(PC_Constants.DOCUMENT_EMAIL_INBOUND_RECORD_TYPE, PC_Constants.DOCUMENT_STATUS_NEW);
        PC_Database.ins(oDoc);

        PC_Document__c tempDoc = [SELECT RecordType.DeveloperName,RecordType.NamespacePrefix from PC_Document__c where Id =:oDoc.Id];

        String qualifiedRecordTypeName = tempDoc.RecordType.NamespacePrefix + '__' + tempDoc.RecordType.DeveloperName;
        String sObjectQualifiedAPIName = ((Id)oDoc.id).getSobjectType().getDescribe().getName();
        String sObjectDeveloperName = ((Id)oDoc.id).getSobjectType().getDescribe().getLocalName();
        String isNamespacePresent = sObjectQualifiedAPIName.removeEndIgnoreCase(sObjectDeveloperName);
        String sObjectNamespace = isNamespacePresent == null ? '' : isNamespacePresent.removeEndIgnoreCase('__');



        CustomMetadataWrapper.GroupWrapper groupDetail = new CustomMetadataWrapper.GroupWrapper();
        groupDetail.objectAPIName = sObjectDeveloperName;
        groupDetail.objectNamespace = sObjectNamespace;
        groupDetail.fieldAPIName = PC_Constants.PC_RecordTypeDeveloperName;
        groupDetail.fieldNamespace = '';
        groupDetail.fieldValue = qualifiedRecordTypeName;

        PC_Utility.getGroups(groupDetail);

      }

    @isTest static void testgetGroupName(){
        Account manufacturer = PC_Test_Setup.createTestAccount(PC_Constants.MANUFACTURER_RECORD_TYPE);
        manufacturer = (Account) PC_Database.ins( manufacturer);

        Account patient = PC_Test_Setup.createPatient('TestPatient');
        patient = (Account) PC_Database.ins(patient);

        Case program = PC_Test_Setup.createProgram(patient);

        PC_Prescription__c newPrescription;
        Product2 product;
        product = PC_Test_Setup.newProduct('TestProduct', 'P1', manufacturer.Id);
        product.PC_NDC__c = '24542131';
        product.PC_Strength__c = '50';
        product = (Product2) PC_Database.ins( product);

        newPrescription = PC_Test_Setup.newPrescription(product.Id);
        newPrescription = (PC_Prescription__c) PC_Database.ins( newPrescription);

        PC_Order__c orderObj = new PC_Order__c();
        orderObj.PC_Prescription__c = newPrescription.Id;
        orderObj.PC_ShipTo__c   = patient.Id;
        orderObj.PC_ProgramCase__c = program.Id;
        orderObj = (PC_Order__c) PC_Database.ins(orderObj);

        List<Id> ordIds = new List<Id>();
        ordIds.add(orderObj.Id);

        List<Id> pIds = new List<Id>();
        pIds.add(patient.Id);

        Test.StartTest();
        PC_Utility.GroupInfo groupInformation1 = new PC_Utility.GroupInfo();
        groupInformation1.groupName         = 'OrderGroup1';
        groupInformation1.groupLabel        = 'OrderGroup1';
        groupInformation1.groupDescription  = 'Test Group for OrderGroup1';
        groupInformation1.isActive          = true;

        PC_Utility.GroupInfo groupInformation2 = new PC_Utility.GroupInfo();
        groupInformation2.groupName         = 'OrderGroup2';
        groupInformation2.groupLabel        = 'OrderGroup2';
        groupInformation2.groupDescription  = 'Test Group for OrderGroup2';
        groupInformation2.isActive          = true;

        Map<Id,Set<PC_Utility.GroupInfo>> groupInfoOrder = PC_Utility.getGroupInfoByIds(ordIds);
        for(PC_Utility.GroupInfo g : groupInfoOrder.get(orderObj.Id)){
            System.assert(g.groupName == groupInformation1.groupName || g.groupName == groupInformation2.groupName ? true : false);
            System.assert(g.groupLabel == groupInformation1.groupLabel || g.groupLabel == groupInformation2.groupLabel ? true : false);
            System.assert(g.isActive == groupInformation1.isActive || g.isActive == groupInformation2.isActive ? true : false);
        }

        Map<Id,Set<PC_Utility.GroupInfo>> groupInfoPatient = PC_Utility.getGroupInfoByIds(pIds);
        for(PC_Utility.GroupInfo g : groupInfoPatient.get(patient.Id)){
            System.assert(g.groupName == groupInformation1.groupName || g.groupName == groupInformation2.groupName ? true : false);
            System.assert(g.groupLabel == groupInformation1.groupLabel || g.groupLabel == groupInformation2.groupLabel ? true : false);
            System.assert(g.isActive == groupInformation1.isActive || g.isActive == groupInformation2.isActive ? true : false);
        }
        Test.StopTest();

    }

    public static List<PC_GroupMember__mdt> getGroupMembersForTest(String objectAPI, String objectNamespace){
        LIST<PC_GroupMember__mdt> groupMembers = new LIST<PC_GroupMember__mdt>();
        LIST<PC_GroupMember__mdt> groupMembersToReturn = new LIST<PC_GroupMember__mdt>();
        PC_GroupMember__mdt groupMembersItems1 = new PC_GroupMember__mdt();
        PC_Group__mdt groupItems1 = new PC_Group__mdt();
        groupItems1.DeveloperName        = 'OrderGroup1';
        groupItems1.MasterLabel          = 'OrderGroup1';
        groupItems1.PC_Description__c    = 'Test Group for OrderGroup1';
        groupItems1.PC_Active__c         = true;

        PC_Group__mdt groupItems2 = new PC_Group__mdt();
        groupItems2.DeveloperName        = 'OrderGroup2';
        groupItems2.MasterLabel          = 'OrderGroup2';
        groupItems2.PC_Description__c    = 'Test Group for OrderGroup2';
        groupItems2.PC_Active__c         = true;

        groupMembersItems1.PC_ObjectName__c          = 'PC_Order__c';
        groupMembersItems1.PC_Object_Namespace__c    = PC_Constants.OrgNamespace;
        groupMembersItems1.PC_FieldName__c           = 'PC_ShipTo__c';
        groupMembersItems1.PC_Field_Namespace__c     = PC_Constants.OrgNamespace;
        groupMembersItems1.PC_FieldValue__c          = '24542131';
        groupMembersItems1.PC_Group__r               = groupItems1;

        groupMembers.add(groupMembersItems1);

        PC_GroupMember__mdt groupMembersItems2 = new PC_GroupMember__mdt();
        groupMembersItems2.PC_ObjectName__c          = 'PC_Order__c';
        groupMembersItems2.PC_Object_Namespace__c    = PC_Constants.OrgNamespace;
        groupMembersItems2.PC_FieldName__c           = 'PC_ProgramCase__r.AccountId';
        groupMembersItems2.PC_Field_Namespace__c     = PC_Constants.OrgNamespace;
        groupMembersItems2.PC_FieldValue__c          = '24542131';
        groupMembersItems2.PC_Group__r               = groupItems1;

        groupMembers.add(groupMembersItems2);

        PC_GroupMember__mdt groupMembersItems3 = new PC_GroupMember__mdt();
        groupMembersItems3.PC_ObjectName__c          = 'PC_Order__c';
        groupMembersItems3.PC_Object_Namespace__c    = PC_Constants.OrgNamespace;
        groupMembersItems3.PC_FieldName__c           = 'PC_ProgramCase__r.Account.Name';
        groupMembersItems3.PC_Field_Namespace__c     = PC_Constants.OrgNamespace;
        groupMembersItems3.PC_FieldValue__c          = 'TestPatient, TestPatient';
        groupMembersItems3.PC_Group__r               = groupItems1;

        groupMembers.add(groupMembersItems3);

        PC_GroupMember__mdt groupMembersItems4 = new PC_GroupMember__mdt();
        groupMembersItems4.PC_ObjectName__c          = 'PC_Order__c';
        groupMembersItems4.PC_Object_Namespace__c    = PC_Constants.OrgNamespace;
        groupMembersItems4.PC_FieldName__c           = 'PC_ProgramCase__r.Account.RecordType.DeveloperName';
        groupMembersItems4.PC_Field_Namespace__c     = PC_Constants.OrgNamespace;
        groupMembersItems4.PC_FieldValue__c          = 'PC_Patient';
        groupMembersItems4.PC_Group__r               = groupItems2;

        groupMembers.add(groupMembersItems4);

        PC_GroupMember__mdt groupMembersItems5 = new PC_GroupMember__mdt();
        groupMembersItems5.PC_ObjectName__c          = 'Account';
        groupMembersItems5.PC_FieldName__c           = 'Name';
        groupMembersItems5.PC_FieldValue__c          = 'TestPatient, TestPatient';
        groupMembersItems5.PC_Group__r               = groupItems2;

        groupMembers.add(groupMembersItems5);

        for(PC_GroupMember__mdt gm : groupMembers){
            if(gm.PC_ObjectName__c == objectAPI && gm.PC_Object_Namespace__c == objectNamespace){
                groupMembersToReturn.add(gm);
            }
        }

        return groupMembersToReturn;
    }
    public inherited sharing class TestException extends Exception{}

    @isTest static void testEvaluateCustomLogic() {
        System.assert(PC_Utility.evaluateCustomLogic('TRUE'));
        System.assert(PC_Utility.evaluateCustomLogic('TRUE OR FALSE'));
        System.assert(PC_Utility.evaluateCustomLogic('TRUE OR TRUE'));
        System.assert(PC_Utility.evaluateCustomLogic('TRUE OR (TRUE AND FALSE)'));
        System.assert(PC_Utility.evaluateCustomLogic('TRUE OR (TRUE AND FALSE AND TRUE OR TRUE)'));
        System.assert(PC_Utility.evaluateCustomLogic('TRUE OR ( TRUE   AND FALSE AND (TRUE OR   FALSE) )'));
        System.assert(PC_Utility.evaluateCustomLogic('TRUE OR (TRUE OR (NOT(FALSE) AND (TRUE OR FALSE)))'));
        System.assert(PC_Utility.evaluateCustomLogic('(FALSE OR ((TRUE OR FALSE) AND (TRUE OR FALSE)))'));

        System.assert(!PC_Utility.evaluateCustomLogic('FALSE'));
        System.assert(!PC_Utility.evaluateCustomLogic('TRUE AND FALSE'));
        System.assert(!PC_Utility.evaluateCustomLogic('FALSE AND FALSE'));
        System.assert(!PC_Utility.evaluateCustomLogic('TRUE AND (TRUE AND FALSE)'));
        System.assert(!PC_Utility.evaluateCustomLogic('FALSE AND (TRUE AND FALSE AND TRUE OR TRUE)'));
        System.assert(!PC_Utility.evaluateCustomLogic('TRUE AND (  TRUE AND   FALSE AND ( TRUE OR FALSE ) )'));
        System.assert(!PC_Utility.evaluateCustomLogic('TRUE AND (TRUE AND (FALSE AND (TRUE OR FALSE)))'));
        System.assert(!PC_Utility.evaluateCustomLogic('Not ((TRUE OR ( Not ((TRUE OR FALSE) AND (TRUE OR FALSE)))))'));
    }
}