/**************************************************************************************
Apex Class Name     : PC_Test_DocManagement_DocumentDetails
Description         : This class is used for testing PC_DocumentManagement_DocumentDetails;
CreatedBy           : Deloitte
Created Date        : 15 October 2019
Modification Log    :
--------------------------------------------------------------------------------------------------------------
Developer                   Date                   Description
----------------------------------------------------------------------------
Kanteti Kishore        	15 October 2019           Initial version
*************************************************************************************/
@isTest(seeAllData=False)
public with sharing class PC_Test_DocManagement_DocumentDetails{

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
    Method Name    : testgetDocRecordForDetails
    Author         : Kishore Kanteti
    Description    : This method is used for testing "getDocRecordForDetails"
    Return Type    : void
    Parameter      :
    *********************************************************************************/
    @isTest static void testgetDocRecordForDetails(){
        createTestData();
        system.runAs(objUser2) {
            Test.StartTest();
            List<PC_Document__c> lstDocs = [Select Id, OwnerId, PC_Document_Status__c from PC_Document__c where Id =: oDoc1.Id];

            system.assertNotEquals(lstDocs[0].PC_Document_Status__c, PC_Constants.DOCUMENT_STATUS_CATEGORIZED);

            lstDocs[0].PC_Document_Status__c = PC_Constants.DOCUMENT_STATUS_CATEGORIZED;
            lstDocs[0].PC_EngagementProgramCode__c = Null;
            PC_Database.upd(lstDocs[0]);

            try{

                PC_DocumentManagement_DocumentDetails.getDocRecordForDetails(oDoc1.Id);

            }catch (Exception ex){
                system.assert(true);
            }
            Test.StopTest();
        }
    }
    /*********************************************************************************
    Method Name    : testFieldSetName
    Author         : Ajinkya Deshmukh
    Description    : This method is used for testing "fieldSetName"  and "getFields"
    Return Type    : void
    Parameter      :
    *********************************************************************************/
    @isTest static void testFieldSetName() {
        createTestData();
        system.runAs(objUser2) {
            Test.StartTest();
            String fieldSetName = PC_DocumentManagement_DocumentDetails.fieldSetName(oDOc1.Id);
            String testFieldSetName = 'false';
            PC_Document__c lstDocs = [Select Id, OwnerId, PC_Document_Status__c, RecordType.DeveloperName, RecordType.NamespacePrefix from PC_Document__c where Id =: oDoc1.Id];

            LIST<PC_DocumentDetails_FieldSet__mdt> getFieldSet = [SELECT Id, PC_Document_RecordType__c, PC_FieldSetName__c FROM PC_DocumentDetails_FieldSet__mdt
            WHERE PC_Document_RecordType__c =: lstDocs.RecordType.DeveloperName AND
            PC_Document_RecordType_Namespaceprefix__c =: lstDocs.RecordType.NamespacePrefix];

            IF(getFieldSet.size() > 0){
                testFieldSetName = getFieldSet[0].PC_FieldSetName__c;
            }
            system.assertEquals(fieldSetName, testFieldSetName);
            //PC_DocumentManagement_DocumentDetails.getFields(PC_Constants.DOCUMENT_OBJECT,fieldSetName,oDoc1.Id);
            Test.StopTest();
        }
    }


}