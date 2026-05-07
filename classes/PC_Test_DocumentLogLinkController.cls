/**************************************************************************************
Apex Class Name     : PC_Test_DocumentLogLinkController
Description         : This class is used for testing PC_DocumentLogLinkController;
CreatedBy           : Deloitte
Created Date        : 01 August 2016
Modification Log    :
----------------------------------------------------------------------------
Developer                   Date                   Description
----------------------------------------------------------------------------                 
Alina Balan                 01 August 2016           Initial version
Shabda Bhujad               Nov 14, 2016             Removed references to PC_Brand__c from createTestData method
Hitha Avalakki              Dec 02, 2020            [PC-6751] Forcereviewer scan issue: Commenting the class code as the main class is no longer in use.
*************************************************************************************/
@isTest(seeAllData=False)
public class PC_Test_DocumentLogLinkController {
    /*private static User objUser2;
    private static Account patient;
    private static Case programCase;
    private static PC_Program_Coverage__c programCoverage;
    //private static PC_Document_Log__c docLog1;
    private static PC_Document_Log__c docLog2;
    private static PC_Document__c oDoc;*/

    /*********************************************************************************
    Method Name    : createTestData
    Author         : Alina Balan
    Description    : This method is used for creating test data
    Return Type    : void
    Parameter      :
    *********************************************************************************/
    /*public static void createTestData() {
        objUser2 = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test93.com', 'test93');
        PC_Database.ins(objUser2, false);
        patient = PC_Test_Setup.createPatient(PC_Test_Setup.PATIENT_NAME);
        PC_Database.ins(patient, false);
        oDoc = PC_Test_Setup.createDocument(PC_Constants.DOCUMENT_FAX_INBOUND_RECORD_TYPE, PC_Constants.DOCUMENT_STATUS_NEW);
        PC_Database.ins(oDoc, false);
        programCase = PC_Test_Setup.newCase(patient.Id, PC_Constants.CASE_PROGRAM_RECORD_TYPE);
        //programCase.PC_Brand__c = PC_Test_Setup.BRAND;
        PC_Database.ins(programCase, false);
        programCoverage = PC_Test_Setup.createProgramCoverage(programCase.Id);
        PC_Database.ins(programCoverage, false);
        docLog2 = PC_Test_Setup.createDocumentLog(oDoc.Id, programCoverage.Id, 'Coverage', 'Coverage');
        PC_Database.ins(docLog2, false);
    }*/

    /*********************************************************************************
    Method Name    : testfetchTrainingRecords
    Author         : Alina Balan
    Description    : This method is used for testing "fetchTrainingRecords" method
    Return Type    : void
    Parameter      :
    *********************************************************************************/
    /*static testMethod void testfetchTrainingRecords(){
        createTestData();
        system.runAs(objUser2) {
            Test.StartTest();
            ApexPages.currentPage().getParameters().put('inputs', programCase.Id);
            ApexPages.currentPage().getParameters().put('PatientId', patient.Id);
            ApexPages.currentPage().getParameters().put('DocumentId', oDoc.Id);
            PC_DocumentLogLinkController controller = new PC_DocumentLogLinkController();
            controller.fetchTrainingRecords();
            System.assertEquals(controller.coverageList.size() > 0, true);
            Test.StopTest();
         }
     }*/

     /*********************************************************************************
    Method Name    : testSave
    Author         : Alina Balan
    Description    : This method is used for testing "save" method
    Return Type    : void
    Parameter      :
    *********************************************************************************/
    /*static testMethod void testSave(){
        createTestData();
        system.runAs(objUser2) {
            Test.StartTest();
            ApexPages.currentPage().getParameters().put('inputs', programCase.Id);
            ApexPages.currentPage().getParameters().put('PatientId', patient.Id);
            ApexPages.currentPage().getParameters().put('DocumentId', oDoc.Id);
            ApexPages.currentPage().getParameters().put('LogName', docLog2.Id);
            ApexPages.currentPage().getParameters().put('CategoryValues', 'test');
            PC_DocumentLogLinkController controller = new PC_DocumentLogLinkController();
            controller.fetchTrainingRecords();
            List<PC_DocumentLogLinkController.coverageWrapper> lstCoverageWrappers = new List<PC_DocumentLogLinkController.coverageWrapper>();
            for (PC_DocumentLogLinkController.coverageWrapper wrapper : controller.coverageList) {
                wrapper.ischecked = true;
                lstCoverageWrappers.add(wrapper);
            }
            controller.coverageList = lstCoverageWrappers;
            controller.save();
            List<PC_Document_Log__c> lstDocumentLogs = [SELECT Id FROM PC_Document_Log__c WHERE PC_Document__c =: oDoc.Id];
            System.assertEquals(lstDocumentLogs.size() > 0, true);
            Test.StopTest();
         }
     }*/
}