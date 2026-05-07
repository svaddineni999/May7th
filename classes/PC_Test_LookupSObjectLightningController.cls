/**************************************************************************************
Apex Class Name     : PC_Test_LookupSObjectLightningController
Description         : This class is used for testing PC_LookupSObjectLightningController;
CreatedBy           : Deloitte
Created Date        : 16 June 2016
Modification Log    :
-------------------------------------------------------------------------------------------------------------- 
Developer                   Date                   Description
----------------------------------------------------------------------------                 
Alina Balan                 16 June 2016           Initial version
Tejas Patel                 Nov 14, 2019           PC-5725 Updated signature of reassignDocumentOwner
Shishir Bansal              10-Dec-2019            [PC-5792] Avoid hardcoding of string variable
*************************************************************************************/
@isTest(seeAllData=False)
public with sharing class PC_Test_LookupSObjectLightningController {
    private static User objUser;
    private static User objUser2;
    private static QueuesObject oQueue;
    private static PC_Document__c oDoc;
    private static Group oGroup;
    private static final String DOC_CATEGORY = 'Enrollment Form';
    private static final String ENG_PROGRAM_NAME = 'Program';
    private static Attachment oAttachment;
    /*********************************************************************************
    Method Name    : createTestData
    Author         : Alina Balan
    Description    : This method is used for creating test data
    Return Type    : void
    Parameter      :
    *********************************************************************************/
    private static void createTestData() {
        objUser = PC_Test_Setup.createUser(PC_Test_Setup.CALL_CENTER_AGENT_PROFILE, 'user@t1234.com', 'test1');
        PC_Database.ins(objUser);
        objUser2 = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@t12345.com', 'test2');
        PC_Database.ins(objUser2);
        oGroup = PC_Test_Setup.createGroup();
        PC_Database.ins(oGroup, false);
        oQueue = PC_Test_Setup.createQueue(oGroup);
        PC_Database.ins(oQueue, false);
        createObjects();
    }

    private static void createObjects() {
        system.runAs(objUser2) {
            oDoc = PC_Test_Setup.createDocument(PC_Constants.DOCUMENT_FAX_INBOUND_RECORD_TYPE, PC_Constants.DOCUMENT_STATUS_REVIEW_NEEDED, ENG_PROGRAM_NAME + 'A');
            // oDoc1 = PC_Test_Setup.createDocument(PC_Constants.DOCUMENT_EMAIL_INBOUND_RECORD_TYPE, PC_Constants.DOCUMENT_STATUS_REVIEW_NEEDED, ENG_PROGRAM_NAME + 'B');
            Id recordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.DOCUMENT_OBJECT, PC_Constants.DOCUMENT_FAX_INBOUND_RECORD_TYPE);
            oDoc.PC_Document_Category__c = DOC_CATEGORY;
            oDoc.RecordTypeId = recordTypeId;
            oDOc.OwnerId = oGroup.Id;
            PC_Database.ins(oDoc, false);

            oAttachment=PC_Test_Setup.createAttachment(oDoc.Id);
            PC_Database.ins(oAttachment);

            PC_Test_Setup.createFile(oDoc.Id);

        }
    }

    /*********************************************************************************
    Method Name    : testlookup
    Author         : Alina Balan
    Description    : This method is used for testing "lookup"
    Return Type    : void
    Parameter      :
    *********************************************************************************/
    @isTest static void testlookup(){
        createTestData();
        system.runAs(objUser2) {
            Test.StartTest();
            PC_LookupSObjectLightningController.Result[] results = PC_LookupSObjectLightningController.lookup('Testing', PC_Constants.EMPTY_STRING);
            //system.assertEquals(results.size(), 0);
            String objectApiName = 'User';
            PC_LookupSObjectLightningController.Result[] results2 = PC_LookupSObjectLightningController.lookup('t1234', objectApiName);
            Test.StopTest();
        }
    }

    @isTest static void testreassignDocumentOwner(){
        createTestData();
        system.runAs(objUser2) {
            Test.StartTest();
            PC_LookupSObjectLightningController.reassignDocumentOwner(oDOc.Id, objUser2.Id, objUser2.username, PC_Constants.PC_USER);
            List<PC_Document__c> lstDocs = [Select Id, OwnerId, PC_Document_Status__c from PC_Document__c where Id =: oDoc.Id];
            system.assertEquals(lstDocs.size(), 1);
            system.assertEquals(objUser2.Id, lstDocs[0].OwnerId);
            Test.StopTest();
        }
    }

    @isTest static void testResult(){
        createTestData();
        system.runAs(objUser2) {
            Test.StartTest();
            PC_LookupSObjectLightningController.Result resultObj=new PC_LookupSObjectLightningController.Result('sObjectTestLabel',oDoc.Id);
            Test.StopTest();
        }
    }

    /*********************************************************************************
    Method Name    : testlookup
    Author         : Alina Balan
    Description    : This method is used for testing "lookup"
    Return Type    : void
    Parameter      :
    *********************************************************************************/
    @isTest static void testlookupUserOrGroup(){
        createTestData();
        system.runAs(objUser2) {
            Test.StartTest();
            PC_LookupSObjectLightningController.Result[] results = PC_LookupSObjectLightningController.lookupUserOrGroup('t1234', 'User');
            system.assertEquals(results.size(), 0);
            String objectApiName1 = 'User';
            PC_LookupSObjectLightningController.Result[] results2 = PC_LookupSObjectLightningController.lookupUserOrGroup('t1234', objectApiName1);
            String objectApiName2 = 'Group';
            PC_LookupSObjectLightningController.Result[] results3 = PC_LookupSObjectLightningController.lookupUserOrGroup('test group', objectApiName2);
            Test.StopTest();
        }
    }
}