/*********************************************************************************
Class Name      : PC_Test_Enrollment_NewApplicant
Description     : Test class for PC_Enrollment_NewApplicant
Created By      : Ajinkya Deshmukh
Created Date    : 2/17/2017
Modification Log:
---------------------------------------------------------------------------------- 
Developer                   Date                   Description
-----------------------------------------------------------------------------------            
Ajinkya Deshmukh          2/17/2017              Initial Version
Prachi Nandgaonkar        3/17/2017              Updated createTestData() and createApplicantsWithSmartDocTest() to create a new online applicant [PC-1322]
Vijay Kashikar		      4/20/2017              Removed @isTest from createTestData() and commented out StartTest() and StopTest() in createTestData() as they were not needed.
Ajinkya Deshmukh		  4/25/2017			   [PC-1365] Updated class to associate engagement program to document
*********************************************************************************/
@isTest
private class PC_Test_Enrollment_NewApplicant {
    private static User adminUser;
    private static PC_Document__c parentDoc;
    private static PC_Document__c childDoc1;
    private static PC_Document__c childDoc2;
    private static Account patientAcc;
    private static Attachment parentAttachment;
    private static Attachment childAttachment1;
    private static Attachment childAttachment2;
    private static  PC_Engagement_Program__c engagementProgram;
    private static final String MANUFACTURER_NAME = 'Eng Prg';
    private static final String ENG_PROGRAM_NAME = 'program';
    
        
    /*********************************************************************************
    Method Name    : createTestData
    Author         : Ajinkya Deshmukh
    Description    : This method is used for creating test data
    Return Type    : void 
    Parameter      : 
    *********************************************************************************/
    
    private static void createTestData() {
        //Test.StartTest();

        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'userpctest@test2.com', 'pctest2');
        PC_Database.ins(adminUser, false);
        //create a parent Document
        parentDoc = PC_Test_Setup.createDocument(PC_Constants.DOCUMENT_SMARTFORM_RECORD_TYPE, PC_Constants.DOCUMENT_STATUS_REVIEW_NEEDED, ENG_PROGRAM_NAME + 'A');
        parentDoc.OwnerId = adminUser.Id;
        parentDoc.PC_Page_Count__c = 50;
        PC_Database.ins(parentDoc, false);
        
        //check document was created
        System.assertNotEquals(parentDoc.Id, null);
        //create an attachment on parent document
        parentAttachment = PC_Test_Setup.createAttachment(parentDoc.Id);
        PC_Database.ins(parentAttachment, false);
        //check attachment was created
        System.assertNotEquals(parentAttachment.Id, null);
        
        //create a parent Document
        childDoc1 = PC_Test_Setup.createDocument(PC_Constants.DOCUMENT_FAX_INBOUND_RECORD_TYPE, PC_Constants.DOCUMENT_STATUS_REVIEW_NEEDED, ENG_PROGRAM_NAME + 'B');
        childDoc1.OwnerId = adminUser.Id;
        childDoc1.PC_Page_Count__c = 3;
        childDoc1.PC_Sorted_Parent_Pg_Num__c = '1,2,3';
        childDoc1.PC_Parent_Document__c = parentDoc.Id;
        PC_Database.ins(childDoc1, false);
        //check document was created
        System.assertNotEquals(childDoc1.Id, null);
        
        //create a parent Document
        childDoc2 = PC_Test_Setup.createDocument(PC_Constants.DOCUMENT_EMAIL_INBOUND_RECORD_TYPE, PC_Constants.DOCUMENT_STATUS_REVIEW_NEEDED, ENG_PROGRAM_NAME + 'C');
        childDoc2.OwnerId = adminUser.Id;
        childDoc2.PC_Page_Count__c = 5;
        childDoc2.PC_Sorted_Parent_Pg_Num__c = '1,2,3,4,5';
        childDoc2.PC_Parent_Document__c = parentDoc.Id;
        PC_Database.ins(childDoc2, false);
        //check document was created
        System.assertNotEquals(childDoc2.Id, null);
		// create manufacturer account
        patientAcc = PC_Test_Setup.createTestAccount(PC_Constants.PATIENT_RECORD_TYPE);
        PC_Database.ins(patientAcc, false);  
        //check patient was created
        System.assertNotEquals(patientAcc.Id, null);
        // create manufacturer account
        Account manufacturerAcc = PC_Test_Setup.createTestAccount(PC_Constants.MANUFACTURER_RECORD_TYPE);
        PC_Database.ins(manufacturerAcc, false);
        //check manufacturer was created
        System.assertNotEquals(manufacturerAcc.Id, null);
        // create engagement program
        engagementProgram = PC_Test_Setup.createEngagementProgram(MANUFACTURER_NAME, manufacturerAcc.Id);
        PC_Database.ins(engagementProgram, false);
        //check engagement program was created
        System.assertNotEquals(engagementProgram.Id, null);

        //Test.StopTest();
	}
    

    /*********************************************************************************
    Method Name    : createApplicantsWithoutDocumentTest
    Author         : Ajinkya Deshmukh
    Description    : 
    Return Type    : void 
    Parameter      : 
    *********************************************************************************/
    
    @isTest static void createApplicantsWithoutDocumentTest() {
        createTestData();
        system.runAs(adminUser) {
            Test.StartTest();                      
            Map<String, Object> fsFieldsWithEmptyValMap = new Map<String, Object>();
            fsFieldsWithEmptyValMap=PC_Enrollment_PatientLookup_Controller.initialiseFieldSetFieldsMap(new Account(), ENG_PROGRAM_NAME);
            PC_Enrollment_NewApplicant.createApplicants(fsFieldsWithEmptyValMap, (String)engagementProgram.Id, '', '',patientAcc.Id);            
            //check if enrollment case is created
            List<Case> enrollmentCase = [SELECT Id, RecordType.Name FROM Case LIMIT 1000];
            system.assert(enrollmentCase.size() > 0, 'The enrollment case has been created');
            //check if applicant is created
            List<PC_Applicant__c> applicantInfo = [SELECT Id, PC_Enrollment_Case__c FROM PC_Applicant__c LIMIT 1000];
            system.assert(applicantInfo.size() > 0, 'The applicant has been created');
            // check if engagement program has been assigned to applicant
            system.assertEquals(applicantInfo[0].PC_Enrollment_Case__c , enrollmentCase[0].Id);            
            Test.stopTest();
        }       
    }
   

    /*********************************************************************************
    Method Name    : createApplicantsWithSmartDocTest
    Author         : Ajinkya Deshmukh
    Description    : 
    Return Type    : void 
    Parameter      : 
    *********************************************************************************/
    
    @isTest static void createApplicantsWithSmartDocTest() {
        createTestData();
        PC_Applicant__c onlineApplicant;
        
        system.runAs(adminUser) {
            Test.StartTest();
            //create online applicant
            onlineApplicant = PC_Test_Setup.createApplicant('lastName');
            PC_Database.ins(onlineApplicant, false);
            //check online applicant was created
            System.assertNotEquals(onlineApplicant.Id, null);
            
            Map<String, Object> fsFieldsWithEmptyValMap = new Map<String, Object>();
            fsFieldsWithEmptyValMap=PC_Enrollment_PatientLookup_Controller.initialiseFieldSetFieldsMap(new Account(), ENG_PROGRAM_NAME);
            PC_Enrollment_NewApplicant.createApplicants(fsFieldsWithEmptyValMap, (String)engagementProgram.Id, (String)parentDoc.Id,onlineApplicant.Id, '');
            //check if enrollment case is created
            List<Case> enrollmentCase = [SELECT Id, RecordType.Name FROM Case LIMIT 1000];
            system.assert(enrollmentCase.size() > 0, 'The enrollment case has been created');
            //check if no new applicant is created
            List<PC_Applicant__c> applicantList = [SELECT Id FROM PC_Applicant__c LIMIT 1000];
            system.assertEquals(applicantList.size(), 1);
            
            List<PC_Applicant__c> applicantInfo = [SELECT Id, PC_Enrollment_Case__c FROM PC_Applicant__c WHERE Id =: onlineApplicant.Id ];
            // check if engagement program has been assigned to existing applicant
            system.assertEquals(applicantInfo[0].PC_Enrollment_Case__c , enrollmentCase[0].Id);           
        	Test.stopTest(); 
        }       
    }
    

    /*********************************************************************************
    Method Name    : createApplicantsWithFaxDocTest
    Author         : Ajinkya Deshmukh
    Description    : 
    Return Type    : void 
    Parameter      : 
    *********************************************************************************/
    
    @isTest static void createApplicantsWithFaxDocTest() {
        createTestData();
        system.runAs(adminUser) {
			Test.StartTest();
            Map<String, Object> fsFieldsWithEmptyValMap = new Map<String, Object>();
            fsFieldsWithEmptyValMap=PC_Enrollment_PatientLookup_Controller.initialiseFieldSetFieldsMap(new Account(), ENG_PROGRAM_NAME);
				PC_Enrollment_NewApplicant.createApplicants(fsFieldsWithEmptyValMap, (String)engagementProgram.Id, (String)childDoc1.Id, '', patientAcc.Id);
            	//check if enrollment case is created
            	List<Case> enrollmentCase = [SELECT Id, RecordType.Name FROM Case LIMIT 1000];
             system.debug('Enrollment Case:' + enrollmentCase);	
            	system.assert(enrollmentCase.size() > 0, 'The enrollment case has been created');
            	//check if applicant is created
            	List<PC_Applicant__c> applicantInfo = [SELECT Id, PC_Enrollment_Case__c FROM PC_Applicant__c LIMIT 1000];
            system.debug('Applicant Info:' + applicantInfo);	
            system.assert(applicantInfo.size() > 0, 'The applicant has been created');
            	// check if engagement program has been assigned to applicant
            	 system.debug('@@PN:' + applicantInfo[0].PC_Enrollment_Case__c);	
            system.debug('@@PN:' + enrollmentCase[0].Id);
            	system.assertEquals(applicantInfo[0].PC_Enrollment_Case__c , enrollmentCase[0].Id);            
        	Test.stopTest();
        }       
    }
    

    /*********************************************************************************
    Method Name    : createApplicantsWithEMailDocTest
    Author         : Ajinkya Deshmukh
    Description    : 
    Return Type    : void 
    Parameter      : 
    *********************************************************************************/
    
    @isTest static void createApplicantsWithEMailDocTest() {
        createTestData();
        system.runAs(adminUser) {
            Test.StartTest();
            	PC_Document__c emailDoc = [SELECT Id, RecordType.DeveloperName FROM PC_Document__c WHERE Id =: childDoc1.Id];
			Map<String, Object> fsFieldsWithEmptyValMap = new Map<String, Object>();
            fsFieldsWithEmptyValMap=PC_Enrollment_PatientLookup_Controller.initialiseFieldSetFieldsMap(new Account(), ENG_PROGRAM_NAME);
            PC_Enrollment_NewApplicant.createApplicants(fsFieldsWithEmptyValMap, (String)engagementProgram.Id, (String)childDoc1.Id,'', '');
            	//check if enrollment case is created
            	List<Case> enrollmentCase = [SELECT Id, RecordType.Name FROM Case LIMIT 1000];
            	system.assert(enrollmentCase.size() > 0, 'The enrollment case has been created');
            	//check if applicant is created
            	List<PC_Applicant__c> applicantInfo = [SELECT Id, PC_Enrollment_Case__c FROM PC_Applicant__c LIMIT 1000];
            	system.assert(applicantInfo.size() > 0, 'The applicant has been created');
            	// check if engagement program has been assigned to applicant
            	system.assertEquals(applicantInfo[0].PC_Enrollment_Case__c , enrollmentCase[0].Id);
            	PC_Enrollment_NewApplicant.linkDocToCase(enrollmentCase[0].Id, childDoc1.Id);
        	Test.stopTest(); 
        }       
    }

    /*********************************************************************************
    Method Name    : createApplicantsWithEMailDocTest
    Author         : Ajinkya Deshmukh
    Description    :
    Return Type    : void
    Parameter      :
    *********************************************************************************/

    @isTest static void testGetFieldSetFields() {
        createTestData();
        system.runAs(adminUser) {
            Test.StartTest();
            PC_Enrollment_NewApplicant.getFieldSetName(ENG_PROGRAM_NAME);
            String fieldSetName = PC_SYSTEM.getPatientConnectSetting(PC_Constants.PC_PRE_ENROLLMENT_FORM_FIELDSET,PC_Constants.getQualifiedAPIName('PC_PreEnrollmentWizardSearch'));
            PC_Enrollment_NewApplicant.getFieldSetFields('Account', ENG_PROGRAM_NAME);
            Test.stopTest();
        }
    }
}