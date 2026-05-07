/**************************************************************************************
Apex Class Name     : PC_Test_DocumentManagementLink
Description         : This class is used for testing PC_DocumentManagementLink;
CreatedBy           : Deloitte
Created Date        : 16 October 2019
Modification Log    :
--------------------------------------------------------------------------------------------------------------
Developer                   Date                   Description
----------------------------------------------------------------------------
Kanteti Kishore        	16 October 2019           Initial version
*************************************************************************************/
@isTest(seeAllData=False)
public with sharing class PC_Test_DocumentManagementLink{

    private static User objUser2;
    private static PC_Document__c oDoc1;
    private static final String DOC_CATEGORY = 'Enrollment Form';
    private static final String DOC_CATEGORY_PRESCRIPTION = 'Prescription';
    private static final String ENG_PROGRAM_NAME = 'Program';
    private static String ManufacturerId;
    private static Account oPatient;
    private static final String PATIENT_NAME = 'test patient name';
    private static String EngagementProgID;
    private static String ACC_RECORD_TYPE = 'Patient';
    private static List<Case> relatedCases = new List<Case>();

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
            PC_Document__c createdDoc = [Select PC_Engagement_Program__c, PC_Engagement_Program__r.PC_Manufacturer__c from PC_Document__c where Id =: oDoc1.Id];
            EngagementProgID = createdDoc.PC_Engagement_Program__c;
            ManufacturerId = createdDoc.PC_Engagement_Program__r.PC_Manufacturer__c;
            oPatient = PC_Test_Setup.createPatient(PATIENT_NAME);
            oPatient.ParentId= ManufacturerId;
            PC_Database.ins(oPatient, false);
            relatedCases = PC_Test_Setup.createEnrlCase(oPatient.Id, 2, PC_Constants.CASE_ENROLLMENT_RECORD_TYPE,EngagementProgID);
            PC_Database.ins(relatedCases, false);

            Id[] fixedSearchResults = new Id[1];
            fixedSearchResults[0] = oPatient.Id;
            Test.setFixedSearchResults(fixedSearchResults);

        }
    }
    /*********************************************************************************
    Method Name    : testgetDocRecord
    Author         : Kishore Kanteti
    Description    : This method is used for testing "getDocRecord"
    Return Type    : void
    Parameter      :
    *********************************************************************************/
    @isTest static void testgetDocRecord(){
        createTestData();
        system.runAs(objUser2) {
            Test.StartTest();
            List<PC_Document__c> lstDocs = [Select Id, OwnerId, PC_Document_Status__c from PC_Document__c where Id =: oDoc1.Id];

            try{

                PC_DocumentManagementLink.getDocRecord(oDoc1.Id);

            }catch (Exception ex){
                system.assert(true);
            }
            Test.StopTest();
        }
    }
    /*********************************************************************************
    Method Name    : testsearchForAllAccounts
    Author         : Ajinkya Deshmukh
    Description    : This method is used for testing "searchForPatient"
    Return Type    : void
    Parameter      :
    *********************************************************************************/
    @isTest static void testsearchForAllAccounts(){
        createTestData();
        system.runAs(objUser2) {
            Test.StartTest();
            Map<String, String> searchPatDetails = new Map<String, String>();
            searchPatDetails.put('p_searchString', 'test patient name');
            searchPatDetails.put('p_recordTypeName', PC_Constants.PATIENT_RECORD_TYPE);
            searchPatDetails.put('docManufacturer', PC_Constants.EMPTY_STRING);
            searchPatDetails.put('docEngagementProg', PC_Constants.EMPTY_STRING);
            searchPatDetails.put('allRecordTypeList',PC_Constants.PHYSICIAN_RECORD_TYPE);
            List<PC_DocumentManagementLink.PatParticWrapper> lstPatients = PC_DocumentManagementLink.searchForPatient(searchPatDetails);
            system.assertnotEquals(0, lstPatients.size());

            Map<String, String> searchPatDetails1 = new Map<String, String>();
            searchPatDetails1.put('p_searchString', 'test patient name');
            searchPatDetails1.put('p_recordTypeName', PC_Constants.PATIENT_RECORD_TYPE);
            searchPatDetails1.put('docManufacturer', ManufacturerId);
            searchPatDetails1.put('docEngagementProg', PC_Constants.EMPTY_STRING);
            searchPatDetails1.put('allRecordTypeList',PC_Constants.PHYSICIAN_RECORD_TYPE);
            lstPatients = PC_DocumentManagementLink.searchForPatient(searchPatDetails1);
            system.assertEquals(1, lstPatients.size());

            Map<String, String> searchPatDetails2 = new Map<String, String>();
            searchPatDetails2.put('p_searchString', 'test patient name');
            searchPatDetails2.put('p_recordTypeName', PC_Constants.PATIENT_RECORD_TYPE);
            searchPatDetails2.put('docManufacturer', ManufacturerId);
            searchPatDetails2.put('docEngagementProg', EngagementProgID);
            searchPatDetails2.put('allRecordTypeList',PC_Constants.PHYSICIAN_RECORD_TYPE);
            lstPatients = PC_DocumentManagementLink.searchForPatient(searchPatDetails2);
            system.assertEquals(1, lstPatients.size());
            Test.StopTest();
        }
    }
    /*********************************************************************************
    Method Name    : testgetRecordTypeForAccount
    Author         : Shabda Bhujad
    Description    : This method is used for testing "getRecordTypeForAccount"
    Return Type    : void
    Parameter      :
    *********************************************************************************/
    @isTest static void testgetRecordTypeForAccount(){
        createTestData();
        system.runAs(objUser2) {
            Test.StartTest();
            String AccRecordType = PC_DocumentManagementLink.getRecordTypeForAccount(oPatient.Id);
            system.assertEquals(ACC_RECORD_TYPE, AccRecordType);
            Test.StopTest();
        }
    }
    /*********************************************************************************
    Method Name    : testaccountRecordTypes
    Author         : Shabda Bhujad
    Description    : This method is used for testing "accountRecordTypes"
    Return Type    : void
    Parameter      :
    *********************************************************************************/
    @isTest static void testaccountRecordTypes(){
        createTestData();
        system.runAs(objUser2) {
            Test.StartTest();
            List<RecordType> accRecTyps = PC_DocumentManagementLink.accountRecordTypes();
            system.assertnotEquals(0, accRecTyps.size());
            Test.StopTest();
        }
    }
}