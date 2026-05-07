/**
 * Created by havalakki on 2/20/2018.
 */
/*Modification Log:
* ----------------------------------------------------------------------------------
* Developer              Date                   	Description
* -----------------------------------------------------------------------------------
* Initial Version
* Vijay Kashikar       Aug 20, 2019           PC-5326 - Replaced PC_Patient hardcoding with constant
* Shishir Bansal        10-Dec-2019      [PC-5792] Avoid hardcoding of string variable
*/


@isTest(seeAllData=False)
private class PC_Test_Doc_MngmntLinkDetailsController {

    private static User objUser;
    private static User objUser2;
    private static Account oPatient;
    private static PC_Document__c oDoc;
    private static Case programCase;
    private static PC_Program_Coverage__c oProgramCoverage;
    private static List<PC_DocumentLogLightningController.ProgramCoverageWrapper> lstCoverages;
    private static PC_AdverseEvent__c testAdverseEvent;
    private static PC_Interaction__c testInteraction;
    private static final String PATIENT_NAME = 'test patient name';
    private static final String DOC_CATEGORY = 'Enrollment Form';

    private static List<Case> relatedCases = new List<Case>();
    private static String engagementProgID;

    /*********************************************************************************
   Method Name    : createTestData
   Author         : Alina Balan
   Description    : This method is used for creating test data
   Return Type    : void
   Parameter      :
   *********************************************************************************/
    private static void createTestData() {
        objUser = PC_Test_Setup.createUser(PC_Test_Setup.CALL_CENTER_AGENT_PROFILE, 'user@test94.com', 'test94');
        PC_Database.ins(objUser, false);
        objUser2 = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test93.com', 'test93');
        PC_Database.ins(objUser2, false);

        oDoc = PC_Test_Setup.createDocument(PC_Constants.DOCUMENT_FAX_INBOUND_RECORD_TYPE, PC_Constants.DOCUMENT_STATUS_NEW);
        Id recordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.DOCUMENT_OBJECT, PC_Constants.DOCUMENT_FAX_INBOUND_RECORD_TYPE);
        oDoc.PC_Document_Category__c = DOC_CATEGORY;
        oDoc.RecordTypeId = recordTypeId;
        PC_Database.ins(oDoc, false);

        PC_Document__c createdDoc = [Select PC_Engagement_Program__c, PC_Engagement_Program__r.PC_Manufacturer__c from PC_Document__c where Id =: oDoc.Id];
        engagementProgID = createdDoc.PC_Engagement_Program__c;

        oPatient = PC_Test_Setup.createPatient(PATIENT_NAME);

        PC_Database.ins(oPatient, false);
        relatedCases = PC_Test_Setup.createEnrlCase(oPatient.Id, 2, PC_Constants.CASE_ENROLLMENT_RECORD_TYPE,engagementProgID);
        PC_Database.ins(relatedCases, false);
        relatedCases = [Select Id from Case where PC_Engagement_Program__c =:engagementProgID];
        programCase = PC_Test_Setup.newCase(oPatient.Id, PC_Constants.CASE_PROGRAM_RECORD_TYPE);
        PC_Database.ins(programCase, false);
        oProgramCoverage = new PC_Program_Coverage__c (PC_Program__c = programCase.Id);
        PC_Database.ins(oProgramCoverage, false);

        testAdverseEvent=new PC_AdverseEvent__c(PC_Patient__c=oPatient.Id,PC_Care_Program__c=programCase.Id);
        PC_Database.ins(testAdverseEvent, false);

        testInteraction = PC_Test_Setup.newInteraction(programCase.Id);
        PC_Database.ins(testInteraction);

        //PC_Document_Log__c docLog2 = PC_Test_Setup.createDocumentLog(oDoc.Id, programCase.Id, 'Case', 'Case');
        PC_Document_Log__c docObj = new PC_Document_Log__c();
        docObj.PC_Document__c = oDoc.Id;
        docObj.PC_Program__c=programCase.Id;
        docObj.PC_Association_Type__c = 'Case';
        docObj.PC_Association_Record_Name__c = 'Case';
        PC_Database.ins(docObj, false);
    }

    /*********************************************************************************
    Method Name    : testgetAccountDetails
    Author         : Hitha Avalakki
    Description    : This method is used for testing "getAccountDetails"
    Return Type    : void
    Parameter      :
    *********************************************************************************/
    @isTest
    static void testGetAccountDetails(){
        createTestData();
        system.runAs(objUser2) {
            Test.StartTest();
            Account oAccount = new Account();
            oPatient = [SELECT Id,RecordType.DeveloperName,PC_Last_Name__c, PC_First_Name__c, Name, Type, PC_Date_of_Birth__c, PC_Status__c, PC_Primary_Address_1__c, PC_Primary_City__c, PC_Primary_State__c, PC_Primary_Zip_Code__c
            FROM Account WHERE Id =: oPatient.Id];
            PC_Doc_Management_LinkDetailsController.AccountWrapper oPatientAccWrapper = new PC_Doc_Management_LinkDetailsController.AccountWrapper(oPatient);
            PC_Doc_Management_LinkDetailsController.AccountWrapper oAccountWrapper = new PC_Doc_Management_LinkDetailsController.AccountWrapper(oAccount);
            oAccountWrapper = PC_Doc_Management_LinkDetailsController.getAccountDetails(oPatient.Id);
            system.assertEquals(oPatientAccWrapper.AccId,oAccountWrapper.AccId);
            system.assertEquals(oPatientAccWrapper.AccLastName,oAccountWrapper.AccLastName);
            system.assertEquals(oPatientAccWrapper.AccFirstName,oAccountWrapper.AccFirstName);
            system.assertEquals(oPatientAccWrapper.AccName,oAccountWrapper.AccName);
            system.assertEquals(oPatientAccWrapper.AccType,oAccountWrapper.AccType);
            system.assertEquals(oPatientAccWrapper.AccDoB,oAccountWrapper.AccDoB);
            system.assertEquals(oPatientAccWrapper.AccStatus,oAccountWrapper.AccStatus);
            system.assertEquals(oPatientAccWrapper.AccAddr,oAccountWrapper.AccAddr);
            system.assertEquals(oPatientAccWrapper.AccCity,oAccountWrapper.AccCity);
            system.assertEquals(oPatientAccWrapper.AccState,oAccountWrapper.AccState);
            system.assertEquals(oPatientAccWrapper.AccZipCode,oAccountWrapper.AccZipCode);
            system.assertEquals(oPatientAccWrapper.recordTypeDevName,oAccountWrapper.recordTypeDevName);

            Test.StopTest();
        }
    }

    /*********************************************************************************
    Method Name    : testgetAccountDetails
    Author         : Hitha Avalakki
    Description    : This method is used for testing "getAccountDetails"
    Return Type    : void
    Parameter      :
    *********************************************************************************/
    @isTest
    static void testGetCaseIds(){
        createTestData();
        system.runAs(objUser2) {
            Test.StartTest();

            PC_Doc_Management_LinkDetailsController.getCaseIds(oPatient.Id,engagementProgID);
            PC_Doc_Management_LinkDetailsController.getCaseIds(oPatient.Id,PC_Constants.EMPTY_STRING);

            Test.StopTest();
        }
    }

    /*********************************************************************************
    Method Name    : testGetApexFields
    Author         : Hitha Avalakki
    Description    : This method is used for testing "getAccountDetails"
    Return Type    : void
    Parameter      :
    *********************************************************************************/
    @isTest
    static void testGetApexFields(){
        createTestData();
        system.runAs(objUser2) {
            Test.StartTest();
            PC_Doc_Management_LinkDetailsController.getApexFields(oPatient.Id,engagementProgID,PC_Constants.PATIENT_RECORD_TYPE,oDoc.Id);
            PC_Doc_Management_LinkDetailsController.getApexFields(oPatient.Id,engagementProgID,'PC_Pat',oDoc.Id);
            Test.StopTest();
        }
    }

    /*********************************************************************************
    Method Name    : testSaveDocLogsServer
    Author         : Hitha Avalakki
    Description    : This method is used for testing "getAccountDetails"
    Return Type    : void
    Parameter      :
    *********************************************************************************/
    @isTest
    static void testSaveDocLogsServer(){
        createTestData();
        System.debug('testSaveDocLogsServer');
        system.runAs(objUser2) {
            Test.StartTest();
            String objectFieldsWrapperListString=PC_Doc_Management_LinkDetailsController.getApexFields(oPatient.Id,engagementProgID,PC_Constants.PATIENT_RECORD_TYPE,oDoc.Id);
            List<PC_Doc_Management_LinkDetailsController.ObjectFieldsWrapper> objectFieldsWrapperList=new List<PC_Doc_Management_LinkDetailsController.ObjectFieldsWrapper>();
            objectFieldsWrapperList=(List<PC_Doc_Management_LinkDetailsController.ObjectFieldsWrapper>)JSON.deserialize(objectFieldsWrapperListString,List<PC_Doc_Management_LinkDetailsController.ObjectFieldsWrapper>.class);


            for(PC_Doc_Management_LinkDetailsController.ObjectFieldsWrapper objectFieldsWrapper:objectFieldsWrapperList) {

                if ('Account'.equals(objectFieldsWrapper.objectName)){
                    List<PC_FieldSet.ObjectFieldsDocLinkedWrapper> listOfFieldsSetsForObject = objectFieldsWrapper.listOfObjectFieldsSetDocLinkedWrapper;

                    for (PC_FieldSet.ObjectFieldsDocLinkedWrapper fieldSetsForObject : listOfFieldsSetsForObject) {
                        fieldSetsForObject.isLinked=true;
                        fieldSetsForObject.persistedLinkedUnlinkedStatus=false;
                    }
                }
            }

            PC_Doc_Management_LinkDetailsController.saveUpdateDocLogsServer(oDoc.Id,JSON.serialize(objectFieldsWrapperList));

            Test.StopTest();
        }
    }


}