/**************************************************************************************
Apex Class Name     : PC_Test_DocumentModificationLog
Description         : This class is used for testing PC_DocumentModificationLog;
CreatedBy           : Deloitte
Created Date        : 11 October 2019
Modification Log    :
--------------------------------------------------------------------------------------------------------------
Developer                   Date                   Description
----------------------------------------------------------------------------
Kanteti Kishore        11 October 2019           Initial version
*************************************************************************************/
@isTest(seeAllData=False)
public class PC_Test_DocumentModificationLog {
    private static User objUser2;
    private static PC_Document__c oDoc;
    private static final String DOC_CATEGORY = 'Enrollment Form';
    private static final String ACC_NAME = 'Account Name';
    private static final String ENG_PROGRAM_NAME = 'Program';
    private static final String ASSOCIATION_TYPE = 'Program Case';
    private static final String ASSOCIATION_NAME = 'Case';


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
            Id accRecordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.PATIENT_OBJECT, PC_Constants.PC_BUSINESSACCOUNT_PATIENT_RECORD_TYPE);
            Account acc = PC_Test_Setup.createAccount(ACC_NAME,accRecordTypeId);
            PC_Database.ins(acc, false);
            Case program  = PC_Test_Setup.createProgram(acc);
            PC_Program_Coverage__c programCoverage = PC_Test_Setup.createProgramCoverage(program.Id);
            PC_Database.ins(programCoverage, false);
            oDoc = PC_Test_Setup.createDocument(PC_Constants.DOCUMENT_FAX_INBOUND_RECORD_TYPE, PC_Constants.DOCUMENT_STATUS_REVIEW_NEEDED, ENG_PROGRAM_NAME + 'A');
            Id recordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.DOCUMENT_OBJECT, PC_Constants.DOCUMENT_FAX_INBOUND_RECORD_TYPE);
            oDoc.PC_Document_Category__c = DOC_CATEGORY;
            oDoc.RecordTypeId = recordTypeId;
            PC_Database.ins(oDoc, false);
            PC_Document_Log__c docLog = PC_Test_Setup.createDocumentLog( oDoc.Id,programCoverage.Id,ASSOCIATION_TYPE,ASSOCIATION_NAME);
            docLog.PC_Association_Record_Id__c = acc.Id;
            PC_Database.ins(docLog, false);

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

            PC_DocumentModificationLog.DocLogAndDescWrapper docLogAndDescWrapper = PC_DocumentModificationLog.getModificationLogs(oDoc.Id);
            system.assertnotEquals(0,docLogAndDescWrapper.documentLogWrapperList.size());
            system.assertnotEquals(null,docLogAndDescWrapper.showDocumentLogFieldVal);

            Test.StopTest();
        }
    }
}