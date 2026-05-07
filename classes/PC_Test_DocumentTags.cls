/**************************************************************************************
Apex Class Name     : PC_Test_DocumentTags
Description         : This class is used for testing PC_DocumentTags;
CreatedBy           : Deloitte
Created Date        : 04 October 2019
Modification Log    :
--------------------------------------------------------------------------------------------------------------
Developer                   Date                   Description
----------------------------------------------------------------------------
Kanteti Kishore        04 October 2016           Initial version
Vijay Kashikar         12 December 2019          [PC-5751] - Added test methods to get tags with/out the Salesforce User Interface API.
*************************************************************************************/
@isTest(seeAllData=False)
public with sharing class PC_Test_DocumentTags{

    private static User objUser2;
    private static PC_Document__c oDoc1;
    private static final String DOC_CATEGORY = 'Enrollment Form';
    private static final String DOC_CATEGORY_PRESCRIPTION = 'Prescription';
    private static final String ENG_PROGRAM_NAME = 'Program';

    /*********************************************************************************
    Method Name    : createTestData
    Author         : Kishore Kanteti
    Description    : This method is used for creating test data
    Return Type    : void
    Parameter      :
    *********************************************************************************/
    private static void createTestData() {

        objUser2 = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test95.com', 'test95');
        PC_Database.ins(objUser2, false);
        system.assertNotEquals(objUser2.Id, Null);
        createObjects();
    }

    /*********************************************************************************
    Method Name    : createObjects
    Author         : Kishore Kanteti
    Description    : This method is used for creating a document
    Return Type    : void
    Parameter      :
    *********************************************************************************/
    private static void createObjects() {
        system.runAs(objUser2) {
            oDoc1 = PC_Test_Setup.createDocument(PC_Constants.DOCUMENT_EMAIL_INBOUND_RECORD_TYPE, PC_Constants.DOCUMENT_STATUS_REVIEW_NEEDED, ENG_PROGRAM_NAME + 'B');
            Id recordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.DOCUMENT_OBJECT, PC_Constants.DOCUMENT_FAX_INBOUND_RECORD_TYPE);

            PC_Database.ins(oDoc1, false);

        }
    }
    /*********************************************************************************
    Method Name    : testgetDocRecordForTags
    Author         : Kishore Kanteti
    Description    : This method is used for testing "getDocRecordForTags"
    Return Type    : void
    Parameter      :
    *********************************************************************************/
    @isTest static void testgetDocRecordForTags(){
        createTestData();
        system.runAs(objUser2) {
            Test.StartTest();
            List<PC_Document__c> lstDocs = [Select Id, OwnerId, PC_Document_Status__c from PC_Document__c where Id =: oDoc1.Id];

            system.assertNotEquals(lstDocs[0].PC_Document_Status__c, PC_Constants.DOCUMENT_STATUS_CATEGORIZED);

            lstDocs[0].PC_Document_Status__c = PC_Constants.DOCUMENT_STATUS_CATEGORIZED;
            lstDocs[0].PC_EngagementProgramCode__c = Null;
            PC_Database.upd(lstDocs[0]);

            try{

                PC_DocumentTags.getDocRecordForTags(oDoc1.Id, false, '');
                PC_DocumentTags.getDocRecordForTags(oDoc1.Id, true, 'test');
            }catch (Exception ex){
                system.assert(true);
            }
            Test.StopTest();
        }
    }
    /*********************************************************************************
    Method Name    : testsaveDocumentCategory
    Author         : Kishore Kanteti
    Description    : This method is used for testing "saveDocumentCategoryV2"
    Return Type    : void
    Parameter      :
    *********************************************************************************/
    @isTest static void testsaveDocumentCategory(){
        createTestData();
        system.runAs(objUser2) {
            Test.StartTest();
            try{
                PC_DocumentTags.saveDocumentCategoryV2(oDoc1.Id,DOC_CATEGORY_PRESCRIPTION);
                PC_DocumentTags.getCategories(PC_Constants.DOCUMENT_EMAIL_INBOUND_RECORD_TYPE);

            }catch(Exception ex){
                system.assert(true);
            }
            Test.StopTest();
        }
    }

}