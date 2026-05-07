/**************************************************************************************
Apex Class Name     : PC_Test_ExistingCaseSummaryController
Description         : This class is used for testing PC_ExistingCaseSummary_Controller
CreatedBy           : Deloitte
Created Date        : 10 February 2017
Modification Log    :
-------------------------------------------------------------------------------------------------------------- 
Developer                   Date                   Description
----------------------------------------------------------------------------                 
Shabda Bhujad	            10-Feb-2017            Initial version
Prachi Nandgaonkar          20-Apr-2017            [PC-1433]Added test data to increased coverage in PC_DocumentToEnrollCaseLinkHelper
Ajinkya Deshmukh			25 Apr 2017			   [PC-1365] Updated class to associate engagement program to document
Shabda Bhujad				28-Jun-2017			   [PC-1701] Added Type to test cases along with RecordType
Hitha Avalakki              26 Feb, 2021           [PC-7442] Replaced PC_System.recordTypeId('Case',PC_Constants.CASE_PROGRAM_RECORD_TYPE) with PC_System.getProgramCaseRecordTypeId()
Hitha Avalakki              04-Mar-2021            [PC-7442] Replaced getProgramCaseRecordTypeId() with getDefaultProgramCaseRecordTypeId()
Hitha Avalakki              19-Mar-2021            [PC-7533] Replaced constant CASE_PROGRAM_RECORD_TYPE_NAME to CASE_PROGRAM_TYPE
*************************************************************************************/
@isTest
public class PC_Test_ExistingCaseSummaryController {
    private static User adminUser;
    private static Case reqPrgCase;
    private static Case reqEnrollCase;
    private static final String MANUFACTURER_NAME = 'EngPrg87';
    private static PC_Document__c oDoc;
    private static PC_Document__c oDoc1;
    private static final String DOC_CATEGORY = 'Enrollment Form';
    private static PC_Applicant__c onlineApplicant1;
    private static PC_Applicant__c onlineApplicant2;
    
    /*********************************************************************************
    Method Name    : createTestData
    Author         : Shabda Bhujad
    Description    : This method is used for creating cases of type Enrollment and Program
    Return Type    : void 
    Parameter      : 
    *********************************************************************************/
    private static void createTestData() {
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'userpctest@test2.com', 'pctest2');
        PC_Database.ins(adminUser, false);
        
        //Create the Manufacturer and Engagement Program for Enrollment Case
        Account manuAcc = PC_Test_Setup.createTestAccount(PC_Constants.MANUFACTURER_RECORD_TYPE); 
        PC_Database.ins(manuAcc, false);
        PC_Engagement_Program__c engPrgA= PC_Test_Setup.createEngagementProgram(MANUFACTURER_NAME, manuAcc.Id);
        PC_Database.ins(engPrgA, false);
        
        //Create a Program case
        //[PC-7442] Replaced PC_System.recordTypeId('Case',PC_Constants.CASE_PROGRAM_RECORD_TYPE) with PC_System.getProgramCaseRecordTypeId()
        reqPrgCase = new Case(
            Status = 'New',
            RecordTypeId = PC_System.getDefaultProgramCaseRecordTypeId(),
            Type = PC_Constants.CASE_PROGRAM_TYPE,
            PC_Engagement_Program__c = engPrgA.Id
        );
        PC_Database.ins(reqPrgCase, false);
        reqPrgCase = [select Id, RecordType.Name, Type, CaseNumber, Owner.Name, Status 
                              	FROM Case WHERE Id =: reqPrgCase.Id ];

       //Create the Enrollment Case
        reqEnrollCase = new Case(
            Status = 'Open', 
            Origin='Web',
            RecordTypeId = PC_SYSTEM.recordTypeId('Case', PC_Constants.CASE_ENROLLMENT_RECORD_TYPE), 
            Type = PC_Constants.CASE_ENROLLMENT_RECORD_TYPE_NAME,
            PC_Engagement_Program__c = engPrgA.Id
        );
        PC_Database.ins(reqEnrollCase, false);  
        reqEnrollCase = [select Id, RecordType.Name,Type, CaseNumber, Owner.Name, Status,PC_ActiveApplicant__c 
                              	FROM Case WHERE Id =: reqEnrollCase.Id ];
        
        //Create a document
        oDoc = PC_Test_Setup.createDocument(PC_Constants.DOCUMENT_FAX_INBOUND_RECORD_TYPE, PC_Constants.DOCUMENT_STATUS_REVIEW_NEEDED, MANUFACTURER_NAME + 'D');
        Id recordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.DOCUMENT_OBJECT, PC_Constants.DOCUMENT_SMARTFORM_RECORD_TYPE);
        oDoc.PC_Document_Category__c = DOC_CATEGORY;
        oDoc.RecordTypeId = recordTypeId;
        PC_Database.ins(oDoc, false);
        
        //Create a document which is undergoing splitting
        oDoc1 = PC_Test_Setup.createDocument(PC_Constants.DOCUMENT_FAX_INBOUND_RECORD_TYPE, PC_Constants.DOCUMENT_STATUS_SPLIT_IN_PROGRESS, MANUFACTURER_NAME + 'E');
        Id recordTypeId1 = PC_SYSTEM.recordTypeId(PC_Constants.DOCUMENT_OBJECT, PC_Constants.DOCUMENT_FAX_INBOUND_RECORD_TYPE);
        oDoc1.PC_Document_Category__c = DOC_CATEGORY;
        oDoc1.RecordTypeId = recordTypeId1;
        oDoc1.PC_Engagement_Program__c = engPrgA.Id;
        PC_Database.ins(oDoc1, false);
        
        
    }
    
    /*********************************************************************************
    Method Name    : testgetCaseDetails
    Author         : Shabda Bhujad
    Description    : This method is used for testing "getCaseDetails"
    Return Type    : void
    Parameter      : 
    *********************************************************************************/
    @isTest static void testgetCaseDetails(){
        createTestData();
        system.runAs(adminUser) {
            Test.StartTest();
            
            //Test a Program Case
            PC_ExistingCaseSummary_Controller.CaseWrapper caseDetailsWrapper= PC_ExistingCaseSummary_Controller.getCaseDetails(reqPrgCase.Id);
            system.assertEquals(PC_Constants.CASE_PROGRAM_TYPE,caseDetailsWrapper.caseType);
            system.assertEquals(MANUFACTURER_NAME,caseDetailsWrapper.engagementProgramName);
            system.assertEquals(reqPrgCase.Status,caseDetailsWrapper.caseStatus);
            system.assertEquals(reqPrgCase.CaseNumber,caseDetailsWrapper.caseNumber);
            system.assertEquals(reqPrgCase.Owner.Name,caseDetailsWrapper.caseOwner);
            
            //Test an Enrollment Case
            caseDetailsWrapper= PC_ExistingCaseSummary_Controller.getCaseDetails(reqEnrollCase.Id);
            system.assertEquals(PC_Constants.CASE_ENROLLMENT_RECORD_TYPE_NAME,caseDetailsWrapper.caseType);
            system.assertEquals(MANUFACTURER_NAME,caseDetailsWrapper.engagementProgramName);
            system.assertEquals(reqEnrollCase.Status,caseDetailsWrapper.caseStatus);
            system.assertEquals(reqEnrollCase.CaseNumber,caseDetailsWrapper.caseNumber);
            system.assertEquals(reqEnrollCase.Owner.Name,caseDetailsWrapper.caseOwner);
            
            Test.StopTest();
        }
    }
    
    /*********************************************************************************
    Method Name    : testlinkDocToCase
    Author         : Prachi Nandgaonkar
    Description    : This method is used for testing "linkDocToCase" for positive test scenarios
    Return Type    : void 
    Parameter      : Id enrollmentCaseId, String documentId
    *********************************************************************************/
    @isTest static void testlinkDocToCase(){
        createTestData();
        system.runAs(adminUser) {
            Test.StartTest();
            
            //create first online applicant
            onlineApplicant1 = PC_Test_Setup.createApplicant('lastName');
            PC_Database.ins(onlineApplicant1, false);
            //check online applicant was created
            System.assertNotEquals(onlineApplicant1.Id, null);
            //Fetch applicant
            PC_Applicant__c applicant1 = [SELECT Id, PC_Enrollment_Case__c FROM PC_Applicant__c WHERE Id =: onlineApplicant1.Id ];
            reqEnrollCase.PC_ActiveApplicant__c = applicant1.Id;
            PC_Database.upd(reqEnrollCase);
            
            //create second online applicant
            onlineApplicant2 = PC_Test_Setup.createApplicant('lastName');
            PC_Database.ins(onlineApplicant2, false);
            //check online applicant was created
            System.assertNotEquals(onlineApplicant2.Id, null);
            //Fetch applicant
            PC_Applicant__c applicant2 = [SELECT Id, PC_Enrollment_Case__c FROM PC_Applicant__c WHERE Id =: onlineApplicant2.Id ];
                        
            
            //Link applicant2 to document
            PC_Document__c doc = [select id, PC_Document_Status__c 
                                        FROM PC_Document__c 
                                        Where Id =: oDoc.Id];
            doc.PC_Applicant__c = applicant2.Id;
            PC_Database.upd(doc);
            
            //Test linkDoctoCase() method
            PC_ExistingCaseSummary_Controller.linkDocToCase(reqEnrollCase.Id, oDoc.Id);
            
            //check if Active applicant on Enrollment case was updated
            reqEnrollCase = [select Id, RecordType.Name,CaseNumber, Owner.Name, Status,PC_ActiveApplicant__c  
                              	FROM Case WHERE Id =: reqEnrollCase.Id ];
            System.assertEquals(applicant2.Id, reqEnrollCase.PC_ActiveApplicant__c);
            
            //check if Enrollment case on applicant was updated
            PC_Applicant__c applicant = [SELECT Id, PC_Enrollment_Case__c FROM PC_Applicant__c WHERE Id =: onlineApplicant2.Id ];
            System.assertEquals(applicant.PC_Enrollment_Case__c, reqEnrollCase.Id);
            
            
            //Query Document Log to see if records were created
            List<PC_Document_Log__c>  lstLogs = [SELECT Id FROM PC_Document_Log__c WHERE PC_Document__c =: oDoc.Id];
            System.assertEquals(lstLogs.size(), 1);
            
            //Query document to check status
            doc = [select id, PC_Document_Status__c 
                                        FROM PC_Document__c 
                                        Where Id =: oDoc.Id];
            
            //check if document status was changed to 'Complete and Ready for Use'
            System.assertEquals(PC_Constants.DOCUMENT_STATUS_COMPLETE, doc.PC_Document_Status__c);
            
            Test.StopTest();
         }
     }
     
    /*********************************************************************************
    Method Name    : testlinkDocToCaseDocStatus
    Author         : Prachi Nandgaonkar
    Description    : This method is used for testing "linkDocToCase" with splitting related status
    Return Type    : void 
    Parameter      : Id enrollmentCaseId, String documentId
    *********************************************************************************/
    @isTest static void testlinkDocToCaseDocStatus(){
        createTestData();
        system.runAs(adminUser) {
            Test.StartTest();
            
            //Test linkDoctoCase() method
            PC_ExistingCaseSummary_Controller.linkDocToCase(reqEnrollCase.Id, oDoc1.Id);
            
            //Query Document Log to see if records were created
            List<PC_Document_Log__c>  lstLogs = [SELECT Id FROM PC_Document_Log__c WHERE PC_Document__c =: oDoc1.Id];
            System.assertEquals(lstLogs.size(), 1);
            
            //Query document to check status
            PC_Document__c doc = [select id, PC_Document_Status__c 
                                        FROM PC_Document__c 
                                        Where Id =: oDoc1.Id];
            
            //check if document status was retained as the splitting status
            System.assertNotEquals(PC_Constants.DOCUMENT_STATUS_COMPLETE, doc.PC_Document_Status__c); 
            System.assertEquals(PC_Constants.DOCUMENT_STATUS_SPLIT_IN_PROGRESS, doc.PC_Document_Status__c);  
            PC_ExistingCaseSummary_Controller.FieldSetDetailsWrapper fieldSetwrapper = new PC_ExistingCaseSummary_Controller.FieldSetDetailsWrapper();
            PC_ExistingCaseSummary_Controller.lstDocumentWorkflowSettingWrapper lstDocwrapper = new PC_ExistingCaseSummary_Controller.lstDocumentWorkflowSettingWrapper();
            lstDocwrapper = PC_ExistingCaseSummary_Controller.CheckMetadata(String.valueOf(reqEnrollCase.Id));
            PC_ExistingCaseSummary_Controller.CheckMetadata(String.valueOf(reqEnrollCase.Id));
            PC_ExistingCaseSummary_Controller.getFieldSetFields('Account',MANUFACTURER_NAME);
            Test.StopTest();
         }
     }

    /*********************************************************************************
    Method Name    : testDocumentWorflowSettingWrapper
    Author         : Hitha Avalakki
    Description    : This method is used for testing "DocumentWorflowSettingWrapper"
    Return Type    : void
    Parameter      : PC_Document_Custom_Workflow_Setting__mdt
    *********************************************************************************/
    @isTest static void testDocumentWorflowSettingWrapper(){
        createTestData();
        system.runAs(adminUser) {
            Test.StartTest();

            PC_Document_Custom_Workflow_Setting__mdt customMetadata=new PC_Document_Custom_Workflow_Setting__mdt();
            customMetadata.PC_Component__c='PC_eLetter__c';
            PC_ExistingCaseSummary_Controller.lstDocumentWorkflowSettingWrapper wrapperObj=new PC_ExistingCaseSummary_Controller.lstDocumentWorkflowSettingWrapper(customMetadata,new PC_ExistingCaseSummary_Controller.CaseWrapper(), new PC_ExistingCaseSummary_Controller.FieldSetDetailsWrapper ());

            Test.StopTest();
        }
    }

}