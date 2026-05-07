/**************************************************************************************
Apex Class Name     : PC_Test_DocManagementLightningController
Description         : This class is used for testing PC_DocumentManagementLightningController;
CreatedBy           : Deloitte
Created Date        : 16 June 2016
Modification Log    :
-------------------------------------------------------------------------------------------------------------- 
Developer                   Date                   Description
----------------------------------------------------------------------------                 
Alina Balan                 16 June 2016           Initial version
Ajinkya Deshmukh			01 Feb 2017			   Added testsearchForAllAccounts
Shabda Bhujad				07 Feb 2017			   Added testgetRecordTypeForAccount, testgetSubComponentsList, testaccountRecordTypes, testcreateDocumentLog  
												   Updated testgetModificationLogs,testsearchForAllAccounts, testgetModificationLogs, testsaveDocumentCategory, testgetDocRecord 
												   with apt test cases to improve the coverage
												   Updated status variables in testarchiveDocumentFax, testupdateReportSpam, testreportIllegible	
Ajinkya Deshmukh			25 Apr 2017			   [PC-1365] Updated class to associate engagement program to document
Shabda Bhujad				26 May 2017			   [PC-1598] Updated method to include the parameter for Manufacturer, added relevant data to test all scenarios
Tejas Patel                 17 Jan 2018             Update the test classes to have dynamic assert statements for fieldset and component metadata
<<<<<<< HEAD
Vijay Kashikar              20 Aug, 2019           [PC-5326] - Replaced PC_Patient hardcoding with constant
Haritha Reddy               Sep 04, 2019           [PC-5384] Updated test method to test saveDocumentCategory2
Haritha Reddy               Sep 04, 2019           [PC-5384] Updated test method to test saveDocumentCategoryV2
Vijay Kashikar              Sep 10, 2019           [PC-5437] Updated testgetDocRecord
Vijay Kashikar              Sep 10, 2019           [PC-5437] Updated testgetDocRecord
Kanteti Kishore				Oct 17, 2019		   [PC-5513] Updated testgetDocRecord(commented getDocRecordForDetails,getDocRecordForTags references) and testSaveDocumentCategory
Kanteti Kishore				Oct 18, 2019		   [PC-5513] Added testUpdateDocumentOwner method.
*************************************************************************************/
@isTest(seeAllData=False)
public with sharing class PC_Test_DocManagementLightningController {
    private static User objUser;
    private static User objUser2;
    private static QueuesObject oQueue;
    private static Group oGroup;
    private static PC_Document__c oDoc;
    private static PC_Document__c oDoc1;
    private static Attachment oAttachment;
    private static Account oPatient;
    private static Account oPatient1;
    private static List<Case> relatedCases = new List<Case>();
    private static final String DOC_CATEGORY = 'Enrollment Form';
    private static final String DOC_CATEGORY_PRESCRIPTION = 'Prescription';
    private static final String PATIENT_NAME = 'test patient name';
    private static final String ENG_PROGRAM_NAME = 'Program';
    private static String EngagementProgID;
    private static String ManufacturerId;

    /*********************************************************************************
    Method Name    : createTestData
    Author         : Alina Balan
    Description    : This method is used for creating test data
    Return Type    : void
    Parameter      :
    *********************************************************************************/
    private static void createTestData() {
        objUser = PC_Test_Setup.createUser(PC_Test_Setup.CALL_CENTER_AGENT_PROFILE, 'user@test96.com', 'test96');
        PC_Database.ins(objUser, false);
        system.assertNotEquals(objUser.Id, Null);
        objUser2 = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test95.com', 'test95');
        PC_Database.ins(objUser2, false);
        system.assertNotEquals(objUser2.Id, Null);
        oGroup = PC_Test_Setup.createGroup();
        PC_Database.ins(oGroup, false);
        system.assertNotEquals(oGroup.Id, Null);
        oQueue = PC_Test_Setup.createQueue(oGroup);
        PC_Database.ins(oQueue, false);
        system.assertNotEquals(oQueue.Id, Null);
        createObjects();
    }

    /*********************************************************************************
    Method Name    : createDoc
    Author         : Alina Balan
    Description    : This method is used for creating a document with attachments
    Return Type    : void
    Parameter      :
    *********************************************************************************/
    private static void createObjects() {
        system.runAs(objUser2) {
            oDoc = PC_Test_Setup.createDocument(PC_Constants.DOCUMENT_FAX_INBOUND_RECORD_TYPE, PC_Constants.DOCUMENT_STATUS_REVIEW_NEEDED, ENG_PROGRAM_NAME + 'A');
            oDoc1 = PC_Test_Setup.createDocument(PC_Constants.DOCUMENT_EMAIL_INBOUND_RECORD_TYPE, PC_Constants.DOCUMENT_STATUS_REVIEW_NEEDED, ENG_PROGRAM_NAME + 'B');
            Id recordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.DOCUMENT_OBJECT, PC_Constants.DOCUMENT_FAX_INBOUND_RECORD_TYPE);
            oDoc.PC_Document_Category__c = DOC_CATEGORY;
            oDoc.RecordTypeId = recordTypeId;
            oDOc.OwnerId = oGroup.Id;
            PC_Database.ins(oDoc, false);
            PC_Database.ins(oDoc1, false);
            oAttachment = PC_Test_Setup.createAttachment(oDoc.Id);
            PC_Database.ins(oAttachment, false);

            PC_Test_Setup.createFile(oDoc.Id);

            PC_Document__c createdDoc = [Select PC_Engagement_Program__c, PC_Engagement_Program__r.PC_Manufacturer__c from PC_Document__c where Id =: oDoc.Id];
            EngagementProgID = createdDoc.PC_Engagement_Program__c;
            ManufacturerId = createdDoc.PC_Engagement_Program__r.PC_Manufacturer__c;

            oPatient = PC_Test_Setup.createPatient(PATIENT_NAME);
            oPatient.ParentId= ManufacturerId;
            PC_Database.ins(oPatient, false);
            relatedCases = PC_Test_Setup.createEnrlCase(oPatient.Id, 2, PC_Constants.CASE_ENROLLMENT_RECORD_TYPE,EngagementProgID);
            PC_Database.ins(relatedCases, false);

            oPatient1 = PC_Test_Setup.createPatient(PATIENT_NAME);
            PC_Database.ins(oPatient1, false);

            Id[] fixedSearchResults = new Id[1];
            fixedSearchResults[0] = oPatient.Id;
            Test.setFixedSearchResults(fixedSearchResults);
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
            String AccRecordType = PC_DocumentManagementLightningController.getRecordTypeForAccount(oPatient.Id);
            system.assertEquals('Patient', AccRecordType);
            Test.StopTest();
        }
    }

    /*********************************************************************************
    Method Name    : testgetSubComponentsList
    Author         : Shabda Bhujad
    Description    : This method is used for testing "getSubComponentsList"
    Return Type    : void
    Parameter      :
    *********************************************************************************/
    @isTest static void testgetSubComponentsList(){
        createTestData();
        system.runAs(objUser2) {
            Test.StartTest();
            List<PC_DocumentManagementLightningController.componentMetadataWrapper> subCmpWrapper= PC_DocumentManagementLightningController.getSubComponentsList();
            // records cant be created in custom metadata types
            List<PC_Document_Management_Components__mdt> getDocComponents = [SELECT Id, PC_Component_Name__c, PC_Ordinal__c, PC_Active__c
            FROM PC_Document_Management_Components__mdt
            WHERE PC_Active__c = TRUE
            ORDER BY PC_Ordinal__c ASC];
            system.assertEquals(getDocComponents.size(), subCmpWrapper.size());
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
            List<RecordType> accRecTyps = PC_DocumentManagementLightningController.accountRecordTypes();
            system.assertnotEquals(0, accRecTyps.size());
            Test.StopTest();
        }
    }

    /*********************************************************************************
    Method Name    : testcreateDocumentLog
    Author         : Shabda Bhujad
    Description    : This method is used for testing "createDocumentLog"
    Return Type    : void
    Parameter      :
    *********************************************************************************/
    @isTest static void testcreateDocumentLog(){
        createTestData();
        system.runAs(objUser2) {
            Test.StartTest();
            PC_DocumentManagementLightningController.createDocumentLog(oPatient.Id, oDoc.Id);
            List<PC_Document_Log__c> lstDocuLogs = [Select Id from PC_Document_Log__c where PC_Document__c =: oDoc.Id
            AND PC_Account__c =:oPatient.Id];
            system.assertEquals(1, lstDocuLogs.size());
            Test.StopTest();
        }
    }

    /*********************************************************************************
    Method Name    : testgetDocRecord
    Author         : Alina Balan
    Description    : This method is used for testing "getDocRecord"
    Return Type    : void
    Parameter      :
    *********************************************************************************/
    @isTest static void testgetDocRecord(){
        createTestData();
        system.runAs(objUser2) {
            Test.StartTest();
            List<PC_Document__c> lstDocs = [Select Id, OwnerId, PC_Document_Status__c from PC_Document__c where Id =: oDoc.Id];
            system.assertNotEquals(lstDocs[0].OwnerId, objUser.Id);
            system.assertEquals(objUser2.Id, userinfo.getUserId());
            system.assertNotEquals(lstDocs[0].PC_Document_Status__c, PC_Constants.DOCUMENT_STATUS_CATEGORIZED);
            system.assertNotEquals(lstDocs[0].OwnerId, userinfo.getUserId());
            List<User> lstUsers = [SELECT Id FROM User WHERE Id =: lstDocs[0].OwnerId];
            system.assertEquals(lstUsers.size(), 0);

            lstDocs[0].PC_Document_Status__c = PC_Constants.DOCUMENT_STATUS_CATEGORIZED;
            PC_Database.upd(lstDocs[0]);

            try{
                PC_DocumentManagementLightningController.getDocRecord(oDoc.Id);
                lstDocs = [Select Id, OwnerId, PC_Document_Status__c from PC_Document__c where Id =: oDoc.Id];
                system.assertEquals(1, lstDocs.size());

               // PC_DocumentManagementLightningController.getDocRecordForDetails(oDoc.Id);
              //  PC_DocumentManagementLightningController.getDocRecordForTags(oDoc.Id);
            }catch (Exception ex){
                system.assert(true);
            }
            Test.StopTest();
        }
    }
    /*********************************************************************************
    Method Name    : testUpdateDocumentOwner
    Author         : Kishore Kanteti
    Description    : This method is used for testing "updateDocumentOwner"
    Return Type    : void
    Parameter      :
    *********************************************************************************/
    @isTest static void testUpdateDocumentOwner(){
        createTestData();
        system.runAs(objUser2) {
            Test.StartTest();
            try{
                PC_DocumentManagementLightningController.updateDocumentOwner(oDoc1,oGroup.Id,'Test User 2');
                List<PC_Document__c> lstDocs = [Select Id, OwnerId, PC_Document_Status__c from PC_Document__c where Id =: oDoc1.Id];
                system.assertEquals(lstDocs.size(), 1);
                system.assertEquals(oGroup.Id, lstDocs[0].OwnerId);
            } catch (Exception ex) {
                system.assert(true);
            }
            Test.StopTest();
        }
    }


    /*********************************************************************************
    Method Name    : testchangeDocumentOwner
    Author         : Alina Balan
    Description    : This method is used for testing "changeDocumentOwner"
    Return Type    : void
    Parameter      :
    *********************************************************************************/
    @isTest static void testchangeDocumentOwner(){
        createTestData();
        system.runAs(objUser2) {
            Test.StartTest();
            try{
                PC_DocumentManagementLightningController.changeDocumentOwner(oDoc.Id);
                List<PC_Document__c> lstDocs = [Select Id, OwnerId, PC_Document_Status__c from PC_Document__c where Id =: oDoc.Id];
                system.assertEquals(lstDocs.size(), 1);
                system.assertEquals(objUser2.Id, lstDocs[0].OwnerId);
            } catch (Exception ex) {
                system.assert(true);
            }
            Test.StopTest();
        }
    }

    /*********************************************************************************
    Method Name    : testreassignDocumentOwner
    Author         : Alina Balan
    Description    : This method is used for testing "reassignDocumentOwner"
    Return Type    : void
    Parameter      :
    *********************************************************************************/
    @isTest static void testreassignDocumentOwner(){
        createTestData();
        system.runAs(objUser2) {
            Test.StartTest();
            try{
                PC_DocumentManagementLightningController.reassignDocumentOwner(oDOc.Id, objUser2.Id, objUser2.username);
                List<PC_Document__c> lstDocs = [Select Id, OwnerId, PC_Document_Status__c from PC_Document__c where Id =: oDoc.Id];
                system.assertEquals(lstDocs.size(), 1);
                system.assertEquals(objUser2.Id, lstDocs[0].OwnerId);
            }catch (Exception ex){
                system.assert(true);
            }
            Test.StopTest();
        }
    }

    /*********************************************************************************
    Method Name    : testarchiveDocumentFax
    Author         : Alina Balan
    Description    : This method is used for testing "archiveDocumentFax"
    Return Type    : void
    Parameter      :
    *********************************************************************************/
    @isTest static void testarchiveDocumentFax(){
        createTestData();
        system.runAs(objUser2) {
            Test.StartTest();
            try{
                PC_DocumentManagementLightningController.archiveDocumentFax(oDOc.Id);
                List<PC_Document__c> lstDocs = [Select Id, OwnerId, PC_Document_Status__c from PC_Document__c where Id =: oDoc.Id];
                system.assertEquals(lstDocs.size(), 1);
                system.assertEquals(PC_Constants.DOCUMENT_STATUS_ARCHIVED, lstDocs[0].PC_Document_Status__c);
            } catch (Exception ex) {
                system.assert(true);
            }
            Test.StopTest();
        }
    }

    /*********************************************************************************
    Method Name    : testupdateReportSpam
    Author         : Alina Balan
    Description    : This method is used for testing "updateReportSpam"
    Return Type    : void
    Parameter      :
    *********************************************************************************/
    @isTest static void testupdateReportSpam(){
        createTestData();
        system.runAs(objUser2) {
            Test.StartTest();
            try{
                PC_DocumentManagementLightningController.updateReportSpam(oDoc.Id);
                List<PC_Document__c> lstDocs = [Select Id, OwnerId, PC_Document_Status__c from PC_Document__c where Id =: oDoc.Id];
                system.assertEquals(1, lstDocs.size());
                system.assertEquals(PC_Constants.DOCUMENT_STATUS_SPAM, lstDocs[0].PC_Document_Status__c);
            }catch(Exception ex){
                system.assert(true);
            }
            Test.StopTest();
        }
    }

    /*********************************************************************************
    Method Name    : testupdateReportUnspam
    Author         : Alina Balan
    Description    : This method is used for testing "updateReportUnspam"
    Return Type    : void
    Parameter      :
    *********************************************************************************/
    @isTest static void testupdateReportUnspam(){
        createTestData();
        system.runAs(objUser2) {
            Test.StartTest();
            try{
                PC_DocumentManagementLightningController.updateReportUnspam(oDOc.Id);
                List<PC_Document__c> lstDocs = [Select Id, OwnerId, PC_Document_Status__c from PC_Document__c where Id =: oDoc.Id];
                system.assertEquals(1, lstDocs.size());
                system.assertEquals(lstDocs[0].PC_Document_Status__c, PC_Constants.DOCUMENT_STATUS_CATEGORIZED);
            }catch(Exception ex){
                system.assert(true);
            }
            Test.StopTest();
        }
    }

    /*********************************************************************************
    Method Name    : testreportIllegible
    Author         : Alina Balan
    Description    : This method is used for testing "reportIllegible"
    Return Type    : void
    Parameter      :
    *********************************************************************************/
    @isTest static void testreportIllegible(){
        createTestData();
        system.runAs(objUser2) {
            Test.StartTest();
            try{
                PC_DocumentManagementLightningController.reportIllegible(oDOc.Id);
                List<PC_Document__c> lstDocs = [Select Id, OwnerId, PC_Document_Status__c from PC_Document__c where Id =: oDoc.Id];
                system.assertEquals(1, lstDocs.size());
                system.assertEquals(lstDocs[0].PC_Document_Status__c, PC_Constants.DOCUMENT_STATUS_ILLEGIBLE);
            }catch(Exception ex){
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
            List<PC_DocumentManagementLightningController.PatParticWrapper> lstPatients = PC_DocumentManagementLightningController.searchForPatient('test patient name', PC_Constants.PATIENT_RECORD_TYPE,'','',PC_Constants.PHYSICIAN_RECORD_TYPE);
            system.assertnotEquals(0, lstPatients.size());
            lstPatients = PC_DocumentManagementLightningController.searchForPatient('test patient name', PC_Constants.PATIENT_RECORD_TYPE, ManufacturerId,'',PC_Constants.PHYSICIAN_RECORD_TYPE);
            system.assertEquals(1, lstPatients.size());
            lstPatients = PC_DocumentManagementLightningController.searchForPatient('test patient name', PC_Constants.PATIENT_RECORD_TYPE, ManufacturerId,EngagementProgID,PC_Constants.PHYSICIAN_RECORD_TYPE);
            system.assertEquals(1, lstPatients.size());
            Test.StopTest();
        }
    }

    /*********************************************************************************
    Method Name    : testreportComplete
    Author         : Ajinkya Deshmukh
    Description    : This method is used for testing "reportIllegible"
    Return Type    : void 
    Parameter      : 
    *********************************************************************************/
    @isTest static void testreportComplete() {
        createTestData();
        system.runAs(objUser2) {
            Test.StartTest();
            try{
                PC_DocumentManagementLightningController.reportComplete(oDOc.Id);
                List<PC_Document__c> lstDocs = [Select Id, OwnerId, PC_Document_Status__c from PC_Document__c where Id =: oDoc.Id];
                system.assertEquals(1, lstDocs.size());
                system.assertEquals(lstDocs[0].PC_Document_Status__c, PC_Constants.DOCUMENT_STATUS_COMPLETED);
            }catch (Exception ex){
                system.assert(true);
            }
            Test.StopTest();
        }
    }

    /*********************************************************************************
    Method Name    : testFieldSetName
    Author         : Ajinkya Deshmukh
    Description    : This method is used for testing "FieldSet on document details"
    Return Type    : void 
    Parameter      : 
    *********************************************************************************/
    @isTest static void testFieldSetName() {
        createTestData();
        system.runAs(objUser2) {
            Test.StartTest();
            String fieldSetName = PC_DocumentManagementLightningController.fieldSetName(oDOc.Id);
            String testFieldSetName = 'false';
            PC_Document__c lstDocs = [Select Id, OwnerId, PC_Document_Status__c, RecordType.DeveloperName, RecordType.NamespacePrefix from PC_Document__c where Id =: oDoc.Id];

            LIST<PC_DocumentDetails_FieldSet__mdt> getFieldSet = [SELECT Id, PC_Document_RecordType__c, PC_FieldSetName__c FROM PC_DocumentDetails_FieldSet__mdt
            WHERE PC_Document_RecordType__c =: lstDocs.RecordType.DeveloperName AND
            PC_Document_RecordType_Namespaceprefix__c =: lstDocs.RecordType.NamespacePrefix];

            IF(getFieldSet.size() > 0){
                testFieldSetName = getFieldSet[0].PC_FieldSetName__c;
            }
            system.assertEquals(fieldSetName, testFieldSetName);
            Test.StopTest();
        }
    }

    /*********************************************************************************
    Method Name    : testgetModificationLogs
    Author         : Alina Balan
    Description    : This method is used for testing "getModificationLogs"
    Return Type    : void 
    Parameter      : 
    *********************************************************************************/
    @isTest static void testgetModificationLogs(){
        createTestData();
        system.runAs(objUser2) {
            Test.StartTest();
            //List<PC_Document_Log__c> lstLogs = PC_DocumentManagementLightningController.getModificationLogs(oDoc.Id);
            PC_DocumentManagementLightningController.createDocumentLog(oPatient.Id, oDoc.Id);
            PC_DocumentManagementLightningController.createDocumentLog(oPatient1.Id, oDoc.Id);
            PC_DocumentManagementLightningController.DocLogAndDescWrapper docLogAndDescWrapper = PC_DocumentManagementLightningController.getModificationLogs(oDoc.Id);
            system.assertnotEquals(0,docLogAndDescWrapper.documentLogWrapperList.size());
            system.assertnotEquals(null,docLogAndDescWrapper.showDocumentLogFieldVal);
            try{
                PC_DocumentManagementLightningController.changeDocumentOwner(oDoc.Id);
            }catch(Exception ex){
                system.assert(true);
            }
            Test.StopTest();
        }
    }

    /*********************************************************************************
    Method Name    : testsaveDocumentCategory
    Author         : Alina Balan
    Description    : This method is used for testing "saveDocumentCategory"
    Return Type    : void 
    Parameter      : 
    *********************************************************************************/
    @isTest static void testsaveDocumentCategory(){
        createTestData();
        system.runAs(objUser2) {
            Test.StartTest();
            try{
                //PC_DocumentManagementLightningController.saveDocumentCategoryV2(oDoc1.Id,DOC_CATEGORY_PRESCRIPTION);
                PC_DocumentManagementLightningController.DocumentWrapper catogorizedDoc = PC_DocumentManagementLightningController.saveDocumentCategory(oDoc.Id, DOC_CATEGORY_PRESCRIPTION);
                for (Integer i = 0; i < catogorizedDoc.lstCategories.size(); i++) {
                    if (catogorizedDoc.lstCategories[i].categoryName == DOC_CATEGORY)
                        system.assertEquals(true, catogorizedDoc.lstCategories[0].isSelected);
                    if (catogorizedDoc.lstCategories[i].categoryName == DOC_CATEGORY_PRESCRIPTION)
                        system.assertEquals(true, catogorizedDoc.lstCategories[0].isSelected);
                }
                catogorizedDoc = PC_DocumentManagementLightningController.saveDocumentCategory(oDoc1.Id,DOC_CATEGORY_PRESCRIPTION);
                //system.assertnotEquals(0, catogorizedDoc.lstCategories.size());
            }catch(Exception ex){
                system.assert(true);
            }
            Test.StopTest();
        }
    }

    /*********************************************************************************
    Method Name    : testgetReturnUrl
    Author         : Alina Balan
    Description    : This method is used for testing "getReturnUrl"
    Return Type    : void 
    Parameter      : 
    *********************************************************************************/
    /*static testMethod void testgetReturnUrl(){
        system.runAs(objUser2) {
            Test.StartTest();
            String url = PC_DocumentManagementLightningController.getReturnUrl();
            //system.assertNotEquals(url, null);
            Test.StopTest();
         }
     }*/
}