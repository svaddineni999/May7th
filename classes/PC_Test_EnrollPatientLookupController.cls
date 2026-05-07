/**************************************************************************************
Apex Class Name     : PC_Test_EnrollPatientLookupController
Description         : This class is used for testing PC_Enrollment_PatientLookup_Controller
CreatedBy           : Deloitte
Created Date        : 10 February 2017
Modification Log    :
-------------------------------------------------------------------------------------------------------------- 
Developer                   Date                   Description
----------------------------------------------------------------------------                 
Mayuresh Patil	            16-Feb-2017            Initial version
Shabda Bhujad				17-Feb-2017 		   Added testgetExistingCase method, updated testgetPatients and createTestData for proper validations
Ajinkya Deshmukh 			12-Apr-2017			   Added assert statements 
Tejas Patel					13-Apr-2017			   Removed @isTest tag from the createTestData method, ForceReviwer error
Ajinkya Deshmukh			25 Apr 2017			   [PC-1365] Updated class to associate engagement program to document
Vijay Kashikar              20 Aug 2019            [PC-5326] - Replaced PC_Patient hardcoding with constant
Hitha Avalakki              26 Feb, 2021           [PC-7442] Replaced PC_System.recordTypeId('Case',PC_Constants.CASE_PROGRAM_RECORD_TYPE) with PC_System.getProgramCaseRecordTypeId()
Hitha Avalakki              04 Mar, 2021           [PC-7442] Replaced getProgramCaseRecordTypeId() with getDefaultProgramCaseRecordTypeId()
*************************************************************************************/
@isTest
private class PC_Test_EnrollPatientLookupController {
    private static User adminUser;
    private static Case reqPrgCase;
    private static Case reqEnrollCase;
    private static Account patient;
    private static PC_Applicant__c applicant;
    private static final String MANUFACTURER_NAME = 'Eng Prg';
    private static final String ENGAGEMENT_CODE = 'EngPrg';
    private static PC_Document__c oDoc;
    private static PC_Document__c oDoc1;
    private static  PC_Engagement_Program__c engPrgA;
    private static final String DOC_CATEGORY = 'Enrollment Form';
    private static String searchDetails = PC_Constants.EMPTY_STRING;
    private static String newSearchDetails = PC_Constants.EMPTY_STRING;
    
/*********************************************************************************
    Method Name    : createTestData
    Author         : Mayuresh Patil
    Description    : This method is used for creating cases of type Enrollment and Program
    Return Type    : void 
    Parameter      : 
    *********************************************************************************/
    private static void createTestData() {    
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'userpctest@test2.com', 'pctest2');
        PC_Database.ins(adminUser, false);
        // admin user created
        system.assertNotEquals(adminUser.Id, null);
        
        //Create the Manufacturer and Engagement Program for Enrollment Case
        Account manuAcc = PC_Test_Setup.createTestAccount(PC_Constants.MANUFACTURER_RECORD_TYPE); 
        PC_Database.ins(manuAcc, false);
        
        engPrgA= PC_Test_Setup.createEngagementProgram(ENGAGEMENT_CODE, manuAcc.Id);
        PC_Database.ins(engPrgA, false);
        engPrgA = [SELECT Id, Name, PC_Manufacturer__c, PC_Manufacturer__r.Name 
                   FROM PC_Engagement_Program__c
                   WHERE Id =: engPrgA.Id];
        // engagement program created
        system.assertNotEquals(engPrgA.Id, null);
		
        patient = PC_Test_Setup.createEWPPatient('testpatient', '1988-05-30', 'Mr.' , PC_Constants.PATIENT_RECORD_TYPE);
        patient.ParentId = manuAcc.Id;
        PC_Database.ins(patient, false);
        
        patient = [Select Id, Name, Phone, PC_Email__c, PC_First_Name__c, PC_Date_of_Birth__c, PC_Gender__c, PC_Last_Name__c, ParentId,
                   PC_Primary_Address_1__c, PC_Primary_City__c, PC_Primary_State__c, PC_Primary_Zip_Code__c 
                   FROM Account
                   WHERE Id =: patient.Id];
        // patient created
        system.assertNotEquals(patient.Id, null);
       
        //Create a Program case for the above patient
        //[PC-7442] Replaced PC_System.recordTypeId('Case',PC_Constants.CASE_PROGRAM_RECORD_TYPE) with PC_System.getProgramCaseRecordTypeId()
        reqPrgCase = new Case(
            Status = 'New',
            RecordTypeId = PC_System.getDefaultProgramCaseRecordTypeId(),
            PC_Engagement_Program__c = engPrgA.Id,
            AccountId=patient.Id
        );
        PC_Database.ins(reqPrgCase, false);
        reqPrgCase = [select Id, RecordType.Name, CaseNumber, Owner.Name, Status 
                              	FROM Case WHERE Id =: reqPrgCase.Id ];

       //Create the Enrollment Case for the applicant
        reqEnrollCase = new Case(
            Status = 'Open', 
            Origin = 'Web',
            RecordTypeId = PC_SYSTEM.recordTypeId('Case', PC_Constants.CASE_ENROLLMENT_RECORD_TYPE), 
            PC_Engagement_Program__c = engPrgA.Id
        );
        PC_Database.ins(reqEnrollCase, false);  
        reqEnrollCase = [select Id, RecordType.Name,CaseNumber, Owner.Name, Status 
                              	FROM Case WHERE Id =: reqEnrollCase.Id ];

        applicant = PC_Test_Setup.createApplicant('testpatient', reqEnrollCase.Id);
        applicant.PC_Date_of_Birth__c = Date.valueof(String.valueof('1988-05-30'));
        PC_Database.ins(applicant, false);
        
        applicant = [Select Id, Name, PC_Account__c, PC_First_Name__c, PC_Last_Name__c, PC_Gender__c, PC_Engagement_Program__c, PC_Engagement_Program__r.Name, 
                     PC_Engagement_Program__r.PC_Manufacturer__c, PC_Enrollment_Case__c, PC_Enrollment_Case__r.Status, PC_Enrollment_Case__r.Owner.Name, 
                     PC_Date_of_Birth__c, PC_Patient_Email__c, PC_Phone__c, PC_Zip_Code__c, 
                     PC_State__c, 
                     PC_Address_1__c, PC_City__c 
                     FROM PC_Applicant__c
                     WHERE Id =: applicant.Id];
        reqEnrollCase.PC_ActiveApplicant__c=applicant.Id;
        PC_Database.upd(reqEnrollCase);
        //Create a document
        oDoc = PC_Test_Setup.createDocument(PC_Constants.DOCUMENT_FAX_INBOUND_RECORD_TYPE, PC_Constants.DOCUMENT_STATUS_REVIEW_NEEDED, ENGAGEMENT_CODE + 'A');
        Id recordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.DOCUMENT_OBJECT, PC_Constants.DOCUMENT_FAX_INBOUND_RECORD_TYPE);
        oDoc.PC_Document_Category__c = DOC_CATEGORY;
        oDoc.RecordTypeId = recordTypeId;
        oDoc.PC_Engagement_Program__c = engPrgA.Id;
        PC_Database.ins(oDoc, false);
        
        //Create a document which is undergoing splitting
        oDoc1 = PC_Test_Setup.createDocument(PC_Constants.DOCUMENT_FAX_INBOUND_RECORD_TYPE, PC_Constants.DOCUMENT_STATUS_SPLIT_IN_PROGRESS, ENGAGEMENT_CODE + 'B');
        Id recordTypeId1 = PC_SYSTEM.recordTypeId(PC_Constants.DOCUMENT_OBJECT, PC_Constants.DOCUMENT_FAX_INBOUND_RECORD_TYPE);
        oDoc1.PC_Document_Category__c = DOC_CATEGORY;
        oDoc1.RecordTypeId = recordTypeId1;
        PC_Database.ins(oDoc1, false);
        
        searchDetails = '{"patientFirstName":"test","patientLastName":"testpatient","patientDob":"1988-05-30","engagementProgram":"Test Eng Prg","engagementProgramId":"'+engPrgA.id+'","manufacturerId":"'+manuAcc.Id+'"}';
        Map<String,String> fsFields=new Map<String, String>();
        String fsName= PC_Enrollment_PatientLookup_Controller.getFieldSetName(ENGAGEMENT_CODE);
        system.debug('@@'+fsName);
        List<String> fsFieldAPINamesList=PC_FieldSetController.getFieldsByName('Account', fsName);
        system.debug('@@'+fsFieldAPINamesList);
        newSearchDetails='{"' + fsFieldAPINamesList[0] +':"test,"' + fsFieldAPINamesList[1] + ':"testpatient",'+fsFieldAPINamesList[2] + ':"1988-05-30",' + '"masterPatient:false"' + '"manufacturerId":"'+manuAcc.Id+'"}';
        fsFields.put(fsFieldAPINamesList[0],'test');
        fsFields.put(fsFieldAPINamesList[1],'testpatient');
        fsFields.put(fsFieldAPINamesList[2],'1988-05-30');
        WrapperClass wrapperClass=new WrapperClass();
        wrapperClass.fsFields=fsFields;
        wrapperClass.manufacturerId=manuAcc.Id;
        wrapperClass.masterPatient='false';
        newSearchDetails=JSON.serialize(wrapperClass);
        //newSearchDetails.ma
        //"patientDob":"1988-05-30",
    }
    
    /*********************************************************************************
    Method Name    : testgetDocDetails
    Author         : Mayuresh Patil
    Description    : This method is used for testing "getDocDetails"
    Return Type    : void
    Parameter      : 
    *********************************************************************************/
    @isTest static void testgetDocDetails(){
        createTestData();
        system.runAs(adminUser) {
            Test.StartTest();

            oDoc.PC_Applicant__c=applicant.Id;
            PC_Database.upd(oDoc);
            PC_Document__c doc = [select Id, PC_Document_Category__c, PC_Engagement_Program__c, PC_Engagement_Program__r.Name, PC_Engagement_Program__r.PC_Manufacturer__c,
                                    PC_Engagement_Program__r.PC_Program_Code__c FROM PC_Document__c Where Id =: oDoc.Id];
            
            //Test a Program Case
            PC_Enrollment_PatientLookup_Controller.DocWrapper docDetailsWrapper= PC_Enrollment_PatientLookup_Controller.getDocDetails(String.valueOf(doc.Id));
            system.assertEquals(doc.Id,docDetailsWrapper.docId);
            system.assertEquals(doc.PC_Engagement_Program__c,docDetailsWrapper.engagementProgramId);
            system.assertEquals(doc.PC_Engagement_Program__r.Name,docDetailsWrapper.engagementProgramName);
            system.assertEquals(doc.PC_Engagement_Program__r.PC_Manufacturer__c,docDetailsWrapper.manufacturer);
            system.assertEquals(doc.PC_Document_Category__c,docDetailsWrapper.docCategory);
            
            Test.StopTest();
        }
    }
    
    /*********************************************************************************
    Method Name    : testgetPatients
    Author         : Mayuresh Patil
    Description    : This method is used for testing "getPatients"
    Return Type    : void
    Parameter      : 
    *********************************************************************************/
    @isTest static void testgetPatients(){
        createTestData();
        system.runAs(adminUser) {
            Test.StartTest();
            
            system.debug(searchDetails);
            //Test a Program Case
            
            Id [] fixedSearchResults= new Id[2];
            fixedSearchResults[0] = patient.Id;
            fixedSearchResults[1] = applicant.Id;
            Test.setFixedSearchResults(fixedSearchResults);
            PC_Enrollment_PatientLookup_Controller.AccountAppDetailsWrapper lstPatientWrapper= PC_Enrollment_PatientLookup_Controller.getPatients(newSearchDetails);
            //Changed the condition to check if more than one records are found
            System.assertNotEquals(null,lstPatientWrapper);
            Test.StopTest();
        }
    }    
    
    /*********************************************************************************
    Method Name    : testgetExistingCase()
    Author         : Shabda Bhujad
    Description    : This method is used for testing "getExistingCase"
    Return Type    : void
    Parameter      : 
    *********************************************************************************/
    @isTest static void testgetExistingCase(){
        createTestData();
        system.runAs(adminUser) {
            Test.StartTest();  
            //Test for Account
            PC_Enrollment_PatientLookup_Controller.PatientsWrapper patientWrapper_Account = new PC_Enrollment_PatientLookup_Controller.PatientsWrapper (patient);
            String existingCaseId = PC_Enrollment_PatientLookup_Controller.getExistingCase(patientWrapper_Account.patientId, engPrgA.Id, patientWrapper_Account.accountType);
            System.assertEquals(reqPrgCase.Id , existingCaseId);
            
            //Test for Applicant
            PC_Enrollment_PatientLookup_Controller.PatientsWrapper patientWrapper_Applicant = new PC_Enrollment_PatientLookup_Controller.PatientsWrapper (applicant);
            existingCaseId = PC_Enrollment_PatientLookup_Controller.getExistingCase(patientWrapper_Applicant.patientId, engPrgA.Id, patientWrapper_Applicant.accountType);
            System.assertEquals(reqEnrollCase.Id, existingCaseId);
            
            Test.StopTest();            
        }
    }

    /*********************************************************************************
    Method Name    : testgetPatientsNew
    Author         : Mayuresh Patil
    Description    : This method is used for testing "getPatients"
    Return Type    : void
    Parameter      :
    *********************************************************************************/
    @isTest static void testgetPatientsNew(){
        createTestData();
        system.runAs(adminUser) {
            Test.StartTest();
            system.debug(searchDetails);
            //Test a Program Case

            Id [] fixedSearchResults= new Id[2];
            fixedSearchResults[0] = patient.Id;
            fixedSearchResults[1] = applicant.Id;
            Test.setFixedSearchResults(fixedSearchResults);
            PC_Enrollment_PatientLookup_Controller.AccountAppDetailsWrapper lstPatientWrapper= PC_Enrollment_PatientLookup_Controller.getPatients(newSearchDetails);
            PC_Enrollment_PatientLookup_Controller.getFieldSetFields('Account', ENGAGEMENT_CODE);
            PC_Enrollment_PatientLookup_Controller.initialiseFieldSetFieldsMap(new Account(), ENGAGEMENT_CODE);
            System.assertNotEquals(null,lstPatientWrapper);
            Test.StopTest();
        }
    }

    public class WrapperClass{
    Map<String,String> fsFields {get;set;}
    Id manufacturerId {get;set;}
    String masterPatient {get; set;}
        WrapperClass(){
            fsFields=new Map<String, String>();
        }
    }
}