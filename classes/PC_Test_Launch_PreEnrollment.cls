/*********************************************************************************
Class Name      : PC_Test_Launch_PreEnrollment
Description     : Test Class for PC_Launch_PreEnrollment
Created By      : TEJAS PATEL
Created Date    : 27-Apr-2017

Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------           
TEJAS PATEL		         27-Apr-2017	              Initial Version
TEJAS PATEL		         27-Apr-2017	              Check Conditin where no Account or Applicant is associated with the documnet.
Shabda Bhujad			 28-Jun-2017				  PC-1701 Adding type to test cases along with record type
Mayuresh Patil           14-Aug-2018                  PC-3442 Removing test data creation for program case as it is not needed for this test class.
Roopsai / Ventkat        20-Aug-2018                  PC-2524 Placeholder button to initiate client custom workflow
*********************************************************************************/

@isTest
public class PC_Test_Launch_PreEnrollment {
    private static User adminUser;
    private static Case reqPrgCase;
    private static Case reqEnrollCase;
    private static Case reqEnrollCase1;
    private static Case reqEnrollCase2;
    private static final String MANUFACTURER_NAME = 'EngPrg87';
    private static PC_Document__c oDoc;
    private static PC_Document__c oDoc1;
    private static PC_Document__c oDoc2;
    private static PC_Document_Log__c docLog;
    private static PC_Document_Log__c docLog1;
    private static PC_Document_Log__c docLog2;
    private static final String DOC_CATEGORY = 'Enrollment Form';
    private static PC_Applicant__c onlineApplicant1;
    private static Account onlineAccount1;
    
    /*********************************************************************************
	Method Name    : createTestData
	Author         : Tejas Patel
	Description    : This method is used for creating test data
	Return Type    : void 
	Parameter      : 
	*********************************************************************************/
    
    private static void createTestData() {
        //Create User
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'userpctest@test2.com', 'pctest2');
        PC_Database.ins(adminUser, false);
        
        //Create the Manufacturer and Engagement Program for Enrollment Case
        Account manuAcc = PC_Test_Setup.createTestAccount(PC_Constants.MANUFACTURER_RECORD_TYPE); 
        PC_Database.ins(manuAcc, false);
        PC_Engagement_Program__c engPrgA= PC_Test_Setup.createEngagementProgram(MANUFACTURER_NAME, manuAcc.Id);
        PC_Database.ins(engPrgA, false);
        
        //Create Applicant
        onlineApplicant1 = PC_Test_Setup.createApplicant('Patel');
        PC_Database.ins(onlineApplicant1, false);
        
        //Create Account
        onlineAccount1 = PC_Test_Setup.newAccount('TejasTest, PatelTest');
        PC_Database.ins(onlineAccount1, false);
        
        //Create a Program case 
        /*reqPrgCase = new Case(
            Status = 'New',
            RecordTypeId = PC_System.recordTypeId('Case', PC_Constants.CASE_PROGRAM_RECORD_TYPE),
            Type = PC_Constants.CASE_PROGRAM_RECORD_TYPE_NAME,
            PC_Engagement_Program__c = engPrgA.Id
        );
        PC_Database.ins(reqPrgCase, false);
        reqPrgCase = [select Id, RecordType.Name, Type, CaseNumber, Owner.Name, Status 
                              	FROM Case WHERE Id =: reqPrgCase.Id ];
        */

       //Create the Enrollment Case with Applicant
        reqEnrollCase = new Case(
            Status 	= 'Open', 
            Origin = 'Web',
            RecordTypeId = PC_SYSTEM.recordTypeId('Case', PC_Constants.CASE_ENROLLMENT_RECORD_TYPE), 
            Type = PC_Constants.CASE_ENROLLMENT_RECORD_TYPE_NAME,
            PC_Engagement_Program__c = engPrgA.Id,
            OwnerId					 = adminUser.Id,
            PC_ActiveApplicant__c	 = onlineApplicant1.Id
        );
        PC_Database.ins(reqEnrollCase, false);  
        reqEnrollCase = [select Id, RecordType.Name, Type, CaseNumber, Owner.Name, Status,PC_ActiveApplicant__c, AccountId 
                              	FROM Case WHERE Id =: reqEnrollCase.Id ];
        
        //Create the Enrollment Case with Applicant and Account
        reqEnrollCase1 = new Case(
            Status 	= 'Open', 
            Origin = 'Web',
            RecordTypeId = PC_SYSTEM.recordTypeId('Case', PC_Constants.CASE_ENROLLMENT_RECORD_TYPE), 
            Type = PC_Constants.CASE_ENROLLMENT_RECORD_TYPE_NAME,            
            PC_Engagement_Program__c = engPrgA.Id,
            OwnerId					 = adminUser.Id,
            PC_ActiveApplicant__c	 = onlineApplicant1.Id,
            AccountId				 = onlineAccount1.Id
        );
        PC_Database.ins(reqEnrollCase1, false);  
        reqEnrollCase1 = [select Id, RecordType.Name, Type, CaseNumber, Owner.Name, Status,PC_ActiveApplicant__c, AccountId 
                              	FROM Case WHERE Id =: reqEnrollCase1.Id ];
        
        //Create the Enrollment Case with no Applicant and Account
        reqEnrollCase2 = new Case(
            Status 	= 'Open', 
            Origin = 'Web',
            RecordTypeId = PC_SYSTEM.recordTypeId('Case', PC_Constants.CASE_ENROLLMENT_RECORD_TYPE), 
            Type = PC_Constants.CASE_ENROLLMENT_RECORD_TYPE_NAME,            
            PC_Engagement_Program__c = engPrgA.Id,
            OwnerId					 = adminUser.Id
        );
        PC_Database.ins(reqEnrollCase2, false);  
        reqEnrollCase2 = [select Id, RecordType.Name,Type, CaseNumber, Owner.Name, Status 
                              	FROM Case WHERE Id =: reqEnrollCase2.Id ];
        
        //Create document1
        oDoc = PC_Test_Setup.createDocument(PC_Constants.DOCUMENT_SMARTFORM_RECORD_TYPE, PC_Constants.DOCUMENT_STATUS_REVIEW_NEEDED, MANUFACTURER_NAME + 'D');
        Id recordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.DOCUMENT_OBJECT, PC_Constants.DOCUMENT_SMARTFORM_RECORD_TYPE);
        oDoc.PC_Document_Category__c = DOC_CATEGORY;
        oDoc.RecordTypeId = recordTypeId;
        PC_Database.ins(oDoc, false);
        
        //Create document2
        oDoc1 = PC_Test_Setup.createDocument(PC_Constants.DOCUMENT_SMARTFORM_RECORD_TYPE, PC_Constants.DOCUMENT_STATUS_REVIEW_NEEDED, MANUFACTURER_NAME + 'A');
        oDoc1.PC_Document_Category__c = DOC_CATEGORY;
        oDoc1.RecordTypeId = recordTypeId;
        oDoc1.PC_Engagement_Program__c = engPrgA.Id;
        PC_Database.ins(oDoc1, false);
        
        //Create document3
        oDoc2 = PC_Test_Setup.createDocument(PC_Constants.DOCUMENT_SMARTFORM_RECORD_TYPE, PC_Constants.DOCUMENT_STATUS_REVIEW_NEEDED, MANUFACTURER_NAME + 'B');
        oDoc2.PC_Document_Category__c = DOC_CATEGORY;
        oDoc2.RecordTypeId = recordTypeId;
        PC_Database.ins(oDoc2, false);
        
        //Create a Documnet Log
        docLog = createDocumentLog(oDoc.Id, reqEnrollCase.Id);
        PC_Database.ins(docLog, false);
        
        //Create a Documnet Log with associated Account
        docLog1 = createDocumentLog(oDoc1.Id, reqEnrollCase1.Id);
        PC_Database.ins(docLog1, false);
        
        //Create a Documnet Log with no associated Account or Applicant
        docLog2 = createDocumentLog(oDoc2.Id, reqEnrollCase2.Id);
        PC_Database.ins(docLog2, false);
      
    }
    
    /*********************************************************************************
	Method Name    : createDocumentLog
	Author         : Tejas Patel
	Description    : This method is used for creating PC_Document__c object
	Return Type    : void 
	Parameter      : Id Doc, Id Enrollment Case
	*********************************************************************************/
    public static PC_Document_Log__c createDocumentLog(Id documentId, Id program) {
        PC_Document_Log__c docObj = new PC_Document_Log__c();
        docObj.PC_Document__c = documentId;
        docObj.PC_Program__c = program;
        return docObj;            
    }
    
    /*********************************************************************************
    Method Name    : testPC_Launch_PreEnrollment
    Author         : Tejas Patel
    Description    : This method is used for testing "checkEnrollment" 
    Return Type    : void 
    Parameter      : Id oDoc
    *********************************************************************************/
    @isTest
    static void testPC_Launch_PreEnrollment(){
        createTestData();
        system.runAs(adminUser) {
            Test.StartTest();
            
            //Test checkEnrollment() method
            PC_Launch_PreEnrollment.CaseDetails casedetails = new PC_Launch_PreEnrollment.CaseDetails();
            PC_Launch_PreEnrollment.CaseDetails casedetails1 = new PC_Launch_PreEnrollment.CaseDetails();
            PC_Launch_PreEnrollment.CaseDetails casedetails3 = new PC_Launch_PreEnrollment.CaseDetails();
            PC_Launch_PreEnrollment.CaseDetails casedetails4 = new PC_Launch_PreEnrollment.CaseDetails();
            PC_Launch_PreEnrollment.lstDocumentWorkflowSettingWrapper lstDocwrapper = new PC_Launch_PreEnrollment.lstDocumentWorkflowSettingWrapper();

            
            //Test When Doc has Enrollment Case with Applicant
            casedetails = PC_Launch_PreEnrollment.checkEnrollment(oDoc.Id);
            system.assertEquals(casedetails.casenumber, reqEnrollCase.CaseNumber);
            system.assertEquals(casedetails.name, onlineApplicant1.PC_Last_Name__c + ', ' +onlineApplicant1.PC_First_Name__c);
            system.assertEquals(casedetails.casestatus, reqEnrollCase.Status);
            
            //Test When Doc has Enrollment Case with Applicant and Account
            casedetails1 = PC_Launch_PreEnrollment.checkEnrollment(oDoc1.Id);
            system.assertEquals(casedetails1.casenumber, reqEnrollCase1.CaseNumber);
            system.assertEquals(casedetails1.name, onlineAccount1.Name);
            system.assertEquals(casedetails1.casestatus, reqEnrollCase.Status);
            
            //Test When no Doc is available, launched from Home page
            casedetails3 = PC_Launch_PreEnrollment.checkEnrollment(null);
            system.assertEquals(casedetails3, NULL);
            
            
            //Test When Doc has Enrollment Case with Applicant and Account
            casedetails4 = PC_Launch_PreEnrollment.checkEnrollment(oDoc2.Id);
            system.assertEquals(casedetails4.casenumber, reqEnrollCase2.CaseNumber);
            system.assertEquals(casedetails4.name, 'Not Assigned');
            system.assertEquals(casedetails4.casestatus, reqEnrollCase.Status);
          
            List<PC_Document_Custom_Workflow_Setting__mdt> custworkflow = new List<PC_Document_Custom_Workflow_Setting__mdt>();
            lstDocwrapper = PC_Launch_PreEnrollment.CheckMetadata(oDoc1.Id);
            Test.stopTest();
        }
    }
}