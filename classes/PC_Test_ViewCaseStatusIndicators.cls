/**************************************************************************************
Apex Class Name     : PC_Test_ViewCaseStatusIndicators
Description         : This class is used for testing PC_ViewCaseStatusIndicators;
CreatedBy           : Deloitte
Created Date        : 27 June 2016
Modification Log    :
-------------------------------------------------------------------------------------------------------------- 
Developer                   Date                   Description
----------------------------------------------------------------------------                 
Cameron Reid              27-June-2016               Initial version
Mayuresh Patil            06-July-2017               PC-1854 Updated test class to add logic for extracting program status metadata
Ajinkya Deshmukh          14-July-2017               PC-1897 Added boolean check- isTriggerActive
Ajinkya Deshmukh          07-July-2017               PC-1897 updated the issue with boolean check
Tejas Patel               11-Nov-2017                PC-2065 used label System.Label.PC_On_Hold
*************************************************************************************/
@isTest 
private class PC_Test_ViewCaseStatusIndicators {
    private static User objUser;
    private static User objUser2;
    private static PC_Document__c oDoc;
    private static Attachment oAttachment;
    private static Case oCase;
    private static Account oPatient;
    private static  PC_Engagement_Program__c engPrgA;
    private static final String MANUFACTURER_NAME = 'PRGA';
    public static Boolean isTriggerActive = True;
    //private static final String DOC_CATEGORY = 'Enrollment Form';
    
    /*********************************************************************************
    Method Name    : createTestData
    Author         : Alina Balan
    Description    : This method is used for creating test data
    Return Type    : void 
    Parameter      : 
    *********************************************************************************/
    private static void createTestData(Boolean bWithAttachments) {
        objUser2 = PC_Test_Setup.createUser(PC_Test_Setup.CALL_CENTER_AGENT_PROFILE, 'user@test60.com', 'test660');
        PC_Database.ins(objUser2);
        objUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test615.com', 'test651');
        PC_Database.ins(objUser);
        oPatient = PC_Test_Setup.createPatient('test patient name');
        oPatient.OwnerId = objUser.Id; 
        PC_Database.ins(oPatient);
        
        system.runAs(objUser) {
            oDoc = PC_Test_Setup.createDocument(PC_Constants.DOCUMENT_FAX_INBOUND_RECORD_TYPE, PC_Constants.DOCUMENT_STATUS_NEW);
            PC_Database.ins(oDoc);
            if (bWithAttachments) {
                oAttachment = PC_Test_Setup.createAttachment(oDoc.Id);
                PC_Database.ins(oAttachment);
            }

            //Create the Manufacturer and Engagement Program for Enrollment Case
            Account manuAcc = PC_Test_Setup.createTestAccount(PC_Constants.MANUFACTURER_RECORD_TYPE);
            PC_Database.ins(manuAcc, false);

            engPrgA= PC_Test_Setup.createEngagementProgram(MANUFACTURER_NAME, manuAcc.Id);
            PC_Database.ins(engPrgA, false);
            engPrgA = [SELECT Id, Name, PC_Manufacturer__c, PC_Manufacturer__r.Name
            FROM PC_Engagement_Program__c
            WHERE Id =: engPrgA.Id];
            // engagement program created
            system.assertNotEquals(engPrgA.Id, null);

            oCase = PC_Test_Setup.createCase(objUser, oPatient);
            oCase.PC_Appeal_No__c = 'test';
            oCase.Subject = 'test';
            oCase.status = 'In Treatment';
            oCase.PC_Engagement_Program__c = engPrgA.Id;
            //oCase.status = 'On Hold';
            PC_Database.ins(oCase);
            
        }
    }
    
    /*********************************************************************************
    Method Name    : testgetStatusTypesWithID
    Author         : Cameron Reid
    Description    : This method is used for testing getting stages with a valid ID 
    Return Type    : void 
    Parameter      : 
    *********************************************************************************/
    @isTest static void testgetStatusTypesWithID(){
        createTestData(true);
        //system.runAs(objUser) {
            Test.StartTest();
            system.assertNotEquals(oDoc.Id, null);
            system.assertNotEquals(oAttachment.Id, null);
            system.assertNotEquals(oCase.ID, null);
           
            List<PC_ViewCaseStatusIndicators.stageWrapper> lstStages = PC_ViewCaseStatusIndicators.getStages(oCase.ID);
            system.assertNotEquals(lstStages, null);
            
            oCase.status = 'On Hold';
            PC_Database.upd(oCase);
            lstStages = PC_ViewCaseStatusIndicators.getStages(oCase.ID);
            system.assertNotEquals(lstStages, null);
            
            Test.StopTest();
       //  }
     }
     
    /*********************************************************************************
    Method Name    : testgetStatusTypesWithNoID
    Author         : Cameron Reid
    Description    : This method is used for testing getting stages with out a valid ID 
    Return Type    : void 
    Parameter      : 
    *********************************************************************************/
    @isTest static void testgetStatusTypesWithNoID(){
        createTestData(true);
        system.runAs(objUser) {
            Test.StartTest();
           
            List<PC_ViewCaseStatusIndicators.stageWrapper> lstStages = PC_ViewCaseStatusIndicators.getStages('123abc');
            system.assertNotEquals(lstStages, null);
            system.assert(lstStages.size() == 0);
           
            Test.StopTest();
         }
     }
    
    /*********************************************************************************
    Method Name    : testGetPreviousStage
    Author         : Ajinkya Deshmukh
    Description    : This method is used for testing getting the previous step
    Return Type    : void 
    Parameter      : 
    *********************************************************************************/
    @isTest static void testGetPreviousStage(){
        if(isTriggerActive) {
            createTestData(true);
            Test.startTest();
            system.assertNotEquals(oDoc.Id, null);
            system.assertNotEquals(oAttachment.Id, null);
            system.assertNotEquals(oCase.ID, null);

            Boolean hasPreviousStage = PC_ViewCaseStatusIndicators.hasPreviousStage(oCase.ID);
            system.assertEquals(hasPreviousStage, false);

            oCase.status = System.Label.PC_On_Hold;
            PC_Database.upd(oCase);
            Case testCase = [select ID, PC_Previous_Status__c from Case where ID = :oCase.ID limit 1];
            hasPreviousStage = PC_ViewCaseStatusIndicators.hasPreviousStage(testCase.ID);
            system.assertEquals(hasPreviousStage, true);

            Test.StopTest();
        }
    }
 }