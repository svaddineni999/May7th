/**************************************************************************************
Apex Class Name     : PC_Test_DocumentLogLightningController
Description         : This class is used for testing PC_DocumentLogLightningController;
CreatedBy           : Deloitte
Created Date        : 16 June 2016
Modification Log    :
-------------------------------------------------------------------------------------------------------------- 
Developer                   Date                   Description
----------------------------------------------------------------------------                 
Alina Balan                 16 June 2016           Initial version
Shabda Bhujad 				07 Feb 2017			   Modified the testsave method with check for account, Added a method for checking account details
Shabda Bhujad				15 Feb 2017			   Updated the testgetAccountDetails to get the wrapper post insert so that assertion is checked accurately
Shabda Bhujad				31 May 2017            Updated methods to get additional parameter for engagement program
Shabda Bhujad				02 June 2017		   Added additional test data for the updated methods PC-1598
Shishir Bansal              10-Dec-2019            [PC-5792] Avoid hardcoding of string variable
*************************************************************************************/
@isTest(seeAllData=False) 
public with sharing class PC_Test_DocumentLogLightningController {
    private static User objUser;
    private static User objUser2;
    private static Account oPatient;
    private static PC_Document__c oDoc;
    private static Case programCase;
    private static PC_Program_Coverage__c oProgramCoverage;
    private static List<PC_DocumentLogLightningController.ProgramCoverageWrapper> lstCoverages;
    private static PC_AdverseEvent__c adverseEvent;
    private static PC_AdverseEvent2__c adverseEvent2;
    private static PC_Interaction__c testInteraction;
    private static final String PATIENT_NAME = 'test patient name';
    private static final String DOC_CATEGORY = 'Enrollment Form';
    
    private static List<Case> relatedCases = new List<Case>();  
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
        objUser = PC_Test_Setup.createUser(PC_Test_Setup.CALL_CENTER_AGENT_PROFILE, 'user@test94.com', 'test94');
        PC_Database.ins(objUser, false);
        objUser2 = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test93.com', 'test93');
        PC_Database.ins(objUser2, false);
        
        oDoc = PC_Test_Setup.createDocument(PC_Constants.DOCUMENT_FAX_INBOUND_RECORD_TYPE, PC_Constants.DOCUMENT_STATUS_NEW);
        Id recordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.DOCUMENT_OBJECT, PC_Constants.DOCUMENT_FAX_INBOUND_RECORD_TYPE);
        oDoc.PC_Document_Category__c = DOC_CATEGORY;
        oDoc.RecordTypeId = recordTypeId;
        PC_Database.ins(oDoc, false);
        
        /*
         * Additional objects added for PC-1598
	     */
        PC_Document__c createdDoc = [Select PC_Engagement_Program__c, PC_Engagement_Program__r.PC_Manufacturer__c from PC_Document__c where Id =: oDoc.Id];
        EngagementProgID = createdDoc.PC_Engagement_Program__c;
        ManufacturerId = createdDoc.PC_Engagement_Program__r.PC_Manufacturer__c;
        
        oPatient = PC_Test_Setup.createPatient(PATIENT_NAME);
        oPatient.ParentId= ManufacturerId;
        PC_Database.ins(oPatient, false);
        relatedCases = PC_Test_Setup.createEnrlCase(oPatient.Id, 2, PC_Constants.CASE_ENROLLMENT_RECORD_TYPE,EngagementProgID);
        PC_Database.ins(relatedCases, false);
        relatedCases = [Select Id from Case where PC_Engagement_Program__c =:EngagementProgID];
        programCase = PC_Test_Setup.newCase(oPatient.Id, PC_Constants.CASE_PROGRAM_RECORD_TYPE);
        programCase.PC_Engagement_Program__c = EngagementProgID;
        PC_Database.ins(programCase, false);
        oProgramCoverage = new PC_Program_Coverage__c (PC_Program__c = programCase.Id);
        PC_Database.ins(oProgramCoverage, false);
        
            
        
        adverseEvent = PC_Test_Setup.newAdverseEvent(oPatient.Id);
        adverseEvent.PC_Care_Program__c=programCase.Id;
        PC_Database.ins(adverseEvent);

        adverseEvent2 = PC_Test_Setup.newAdverseEvent2(oPatient.Id);
        adverseEvent2.PC_Care_Program__c=programCase.Id;
        PC_Database.ins(adverseEvent2);
        
        testInteraction = PC_Test_Setup.newInteraction(programCase.Id);
        PC_Database.ins(testInteraction); 
    }
    
    /*********************************************************************************
    Method Name    : testgetProgramRecords
    Author         : Alina Balan
    Description    : This method is used for testing "getProgramRecords"
    Return Type    : void 
    Parameter      : 
    *********************************************************************************/
    @isTest static void testgetProgramRecords(){
        createTestData();
        system.runAs(objUser2) {
            Test.StartTest();
            List<Case> lstCases = PC_DocumentLogLightningController.getProgramRecords(oPatient.Id,PC_Constants.EMPTY_STRING);
            system.assertEquals(lstCases.size(), 3);
            lstCases = PC_DocumentLogLightningController.getProgramRecords(oPatient.Id,EngagementProgID);
            system.assertEquals(lstCases.size(), 3);
            lstCases = PC_DocumentLogLightningController.getProgramRecords(null,EngagementProgID);
            Test.StopTest();
         }
     }
     
    /*********************************************************************************
    Method Name    : testgetAccountDetails
    Author         : Shabda Bhujad
    Description    : This method is used for testing "getAccountDetails"
    Return Type    : void 
    Parameter      : 
    *********************************************************************************/
    @isTest static void testgetAccountDetails(){
        createTestData();
        system.runAs(objUser2) {
            Test.StartTest();
            Account oAccount = new Account();
            oPatient = [SELECT Id,PC_Last_Name__c, PC_First_Name__c, Name, Type, PC_Date_of_Birth__c, PC_Status__c, PC_Primary_Address_1__c, PC_Primary_City__c, PC_Primary_State__c, PC_Primary_Zip_Code__c 
                        FROM Account WHERE Id =: oPatient.Id];
            PC_DocumentLogLightningController.AccountWrapper oPatientAccWrapper = new PC_DocumentLogLightningController.AccountWrapper(oPatient);
            PC_DocumentLogLightningController.AccountWrapper oAccountWrapper = new PC_DocumentLogLightningController.AccountWrapper(oAccount);
            oAccountWrapper = PC_DocumentLogLightningController.getAccountDetails(oPatient.Id);
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
            
            Test.StopTest();
         }
     }
     
    /*********************************************************************************
    Method Name    : testfetchTrainingRecords
    Author         : Alina Balan
    Description    : This method is used for testing "fetchTrainingRecords"
    Return Type    : void 
    Parameter      : 
    *********************************************************************************/
    @isTest static void testfetchTrainingRecords(){
        createTestData();
        List<String> caseIdList = new List<String>();
        caseIdList.add(programCase.Id);
        system.runAs(objUser2) {
            Test.StartTest();
            lstCoverages = PC_DocumentLogLightningController.fetchTrainingRecords(caseIdList);
            system.assertEquals(lstCoverages.size(), 1);
            Test.StopTest();
         }
     }
    
    /*********************************************************************************
    Method Name    : testGetAdversEventsRecords
    Author         : Tetiana Danylyshyn
    Description    : This method is used for testing "getAdversEventsRecords"
    Return Type    : void 
    *********************************************************************************/
    @isTest static void testGetAdversEventsRecords(){
        createTestData();
        system.runAs(objUser2) {
            Test.StartTest();
            List<sObject> lstAdverseEvents = PC_DocumentLogLightningController.getAdversEventsRecords(oPatient.Id, PC_Constants.EMPTY_STRING);
            system.assertEquals(1, lstAdverseEvents.size());
            lstAdverseEvents = PC_DocumentLogLightningController.getAdversEventsRecords(oPatient.Id, EngagementProgID);
            system.assertEquals(1, lstAdverseEvents.size());
            Test.StopTest();
         }
     }

    /*********************************************************************************
    Method Name    : testGetAdversEventsRecords
    Author         : Tetiana Danylyshyn
    Description    : This method is used for testing "getAdversEventsRecords"
    Return Type    : void
    *********************************************************************************/
    @isTest static void testGetAdversEvents2Records(){
        createTestData();
        system.runAs(objUser2) {
            Test.StartTest();
            List<sObject> lstAdverseEvents = PC_DocumentManagementHelper.getAdverseEvents2Records(oPatient.Id);
            system.assertEquals(1, lstAdverseEvents.size());
            lstAdverseEvents = PC_DocumentManagementHelper.getAdverseEvents2Records(oPatient.Id, EngagementProgID);
            system.assertEquals(1, lstAdverseEvents.size());
            Test.StopTest();
        }
    }

    /*********************************************************************************
    Method Name    : testGetInteractionRecords
    Author         : Tetiana Danylyshyn
    Description    : This method is used for testing "getInteractionRecords"
    Return Type    : void 
    *********************************************************************************/
    @isTest static void testGetInteractionRecords(){
        createTestData();
        system.runAs(objUser2) {
            Test.StartTest();
            List<PC_Interaction__c> lstInteractions = PC_DocumentLogLightningController.getInteractionRecords(oPatient.Id, PC_Constants.EMPTY_STRING);
            system.assertEquals(1, lstInteractions.size());
            lstInteractions = PC_DocumentLogLightningController.getInteractionRecords(oPatient.Id, EngagementProgID);
            system.assertEquals(1, lstInteractions.size());
            Test.StopTest();
         }
     }
    
    /*********************************************************************************
    Method Name    : testSave
    Author         : Alina Balan
    Description    : This method is used for testing "Save"
    Return Type    : void 
    Parameter      : 
    *********************************************************************************/
    @isTest static void testSave(){
        createTestData();
        system.runAs(objUser2) {
            Test.StartTest();
            PC_DocumentLogLightningController.save(oDoc.Id, oPatient.Id, new List<String>{String.valueOf(programCase.Id)},'[]', new List<String>{String.valueOf(adverseEvent.Id)}, new List<String>{String.valueOf(adverseEvent2.Id)}, new List<String>{String.valueOf(testInteraction.Id)}, new List<String>{String.valueOf(oPatient.Id)});
            List<PC_Document_Log__c>  lstLogs = [SELECT Id FROM PC_Document_Log__c WHERE PC_Document__c =: oDoc.Id];
            system.assertEquals(lstLogs.size(), 5);
            Test.StopTest();
         }
     }
}