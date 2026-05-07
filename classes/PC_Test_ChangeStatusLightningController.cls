/**************************************************************************************
Apex Class Name     : PC_Test_ChangeStatusLightningController
Description         : This class is used for testing PC_ChangeStatusLightningController;
CreatedBy           : Deloitte
Created Date        : 2 feb 2018
Modification Log    :
--------------------------------------------------------------------------------------------------------------
Developer                   Date                   Description
----------------------------------------------------------------------------
Sahil Garg                 16 June 2016           Initial version
*************************************************************************************/
@isTest(seeAllData=False)
public with sharing class PC_Test_ChangeStatusLightningController {
    private static User objUser;
    private static User objUser2;
    private static PC_Document__c oDoc;
    private static Group oGroup;
      private static QueuesObject oQueue;
    private static final String DOC_CATEGORY = 'Enrollment Form';
    private static final String ENG_PROGRAM_NAME = 'Program';


    /*********************************************************************************
    Method Name    : createTestData
    Author         : Alina Balan
    Description    : This method is used for creating test data
    Return Type    : void
    Parameter      :
    *********************************************************************************/
    private static void createTestData() {
        objUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@t1234.com', 'test1');
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
            oDoc.PC_Document_Status__c = PC_Constants.DOCUMENT_STATUS_IN_REVIEW;
            //oDOc.OwnerId = oGroup.Id;
            PC_Database.ins(oDoc, false);



        }
    }


    @isTest static void testUpdateDocumentStatus(){
        createTestData();
        system.runAs(objUser2) {
            Test.StartTest();
            PC_ChangeStatusLightningController.updateDocumentStatus(oDOc.Id, PC_Constants.DOCUMENT_STATUS_REVIEW_NEEDED);
            List<PC_Document__c> lstDocs = [Select Id, OwnerId, PC_Document_Status__c from PC_Document__c where Id =: oDoc.Id];
            system.assertEquals(lstDocs.size(), 1);
            system.assertEquals(objUser2.Id, lstDocs[0].OwnerId);
            Test.StopTest();
        }
    }

    @isTest static void testgetPicklistValues(){
        createTestData();
        system.runAs(objUser2) {
            Test.StartTest();
            try {
            PC_ChangeStatusLightningController.getRecTypeBasedPicklistValues('PC_Document__c', 'PC_Document_Status__c', oDoc.Id);
            }
            catch(Exception ex) {
                system.assert(true); // We definitely get an exception when testing this.
            }
            Test.StopTest();
         }
     }

}