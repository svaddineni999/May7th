/*********************************************************************************
Class Name      : PC_Test_SMSSenderController
Description     : Test class for PC_SMSSenderController
Created By      : Tetiana Danylyshyn
Created Date    : 01-August-16
Modification Log:
---------------------------------------------------------------------------------- 
Developer                   Date                   Description
-----------------------------------------------------------------------------------            
Tetiana Danylyshyn        01-August-16              Initial Version
*********************************************************************************/
@isTest
private class PC_Test_SMSSenderController {
    private static User objUser;
    private static Account oPatient;
    private static PC_Message__c message;
    private static Case programCase;
    private static final String PATIENT_NAME = 'test patient name';

    /*********************************************************************************
    Method Name    : createTestData
    Author         : Tetiana Danylyshyn
    Description    : This method is used for creating test data
    Return Type    : void  
    *********************************************************************************/
    private static void createTestData() {
        objUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test78.com', 'test78');
        PC_Database.ins(objUser, false);
        oPatient = PC_Test_Setup.createPatient(PATIENT_NAME);
        PC_Database.ins(oPatient, false);
        programCase = PC_Test_Setup.newCase(oPatient.Id, PC_Constants.CASE_PROGRAM_RECORD_TYPE);
        programCase.OwnerId = objUser.Id;
        PC_Database.ins(programCase, false);
        message = PC_Test_Setup.createMessage(programCase);
        PC_Database.ins(message, false);
    }

    /*********************************************************************************
    Method Name    : testGetCaseMessages
    Author         : Tetiana Danylyshyn
    Description    : This method is used for testing "getCaseMessages"
    Return Type    : void 
    *********************************************************************************/
    @isTest static void testGetCaseMessages(){
        createTestData();
        system.runAs(objUser) {
            Test.StartTest();
                List<PC_Message__c>  messages = PC_SMSSenderController.getCaseMessages(programCase.Id);
                System.assertEquals(messages.size(), 1);
            Test.StopTest();
         }
     }

    /*********************************************************************************
    Method Name    : testSendMessage
    Author         : Tetiana Danylyshyn
    Description    : This method is used for testing "sendMessage"
    Return Type    : void 
    *********************************************************************************/
    @isTest static void testSendMessage(){
        createTestData();
        Test.StartTest();
        List<Case> lstCurrentCases = [select Id, CaseNumber, Account.Name, PC_Care_Coordinator__r.Name from Case where Id = :programCase.Id];
        System.assertEquals(lstCurrentCases.size(), 1);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(programCase);
        PC_SMSSenderController smsSenderCntrl = new PC_SMSSenderController(sc);
        System.assertEquals(smsSenderCntrl.currentCase.Id, programCase.Id);
        
        Boolean isSent = PC_SMSSenderController.sendMessage('test text message', programCase.Id);
        System.assertEquals(isSent, true);           
        
        isSent = PC_SMSSenderController.sendMessage('Test Tejas' , programCase.Id);
        System.assertEquals(isSent , true);
        Test.StopTest();
     }
}