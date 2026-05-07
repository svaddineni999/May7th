/**
 * Class Name      : PC_Test_EnrollPatientWZLightningCtlr
 * Created By      : Vijay Kashikar
 * @Created Date   : Apr 14, 2016
 * Modification Log:
 * ----------------------------------------------------------------------------------
 * Developer              Date                   	Description
 * -----------------------------------------------------------------------------------
 * Vijay Kashikar		  14-Apr-2017				Initial version
 * Ajinkya Deshmukh		  25 Apr 2017			    [PC-1365] Updated class to associate engagement program to document
 * Shabda Bhujad		  27-Jun-2017				[PC-1701] Change from record type to Type for case object
 * Vijay Kashikar         20-Aug-2019               [PC-5326] - Replaced PC_Patient hardcoding with constant
 * Hitha Avalakki         26-Feb-2021               [PC-7442] Replaced PC_System.recordTypeId('Case',PC_Constants.CASE_PROGRAM_RECORD_TYPE) with PC_System.getProgramCaseRecordTypeId()
 * Hitha Avalakki         04-Mar-2021               [PC-7442] Replaced getProgramCaseRecordTypeId() with getDefaultProgramCaseRecordTypeId()
 * Hitha Avalakki         19-Mar-2021               [PC-7533] Replaced constant CASE_PROGRAM_RECORD_TYPE_NAME to CASE_PROGRAM_TYPE
 */

/**
 * Method to get Case type to display the enroll button only if the case is of type enrollment.  
 */
@isTest
public class PC_Test_EnrollPatientWZLightningCtlr {
	private static User adminUser;
    private static Case reqPrgCase;
    private static Case reqEnrollCase;
    private static Account patient;
    private static PC_Applicant__c applicant;
    private static final String MANUFACTURER_NAME = 'Eng Prg';
    
    private static  PC_Engagement_Program__c engPrgA;
    
    
    private static void createTestData() {    
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'userpctest@test2.com', 'pctest2');
        PC_Database.ins(adminUser, false);
        // admin user created
        system.assertNotEquals(adminUser.Id, null);
        
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
            Type = PC_Constants.CASE_PROGRAM_TYPE,
            PC_Engagement_Program__c = engPrgA.Id,
            AccountId=patient.Id
        );
        PC_Database.ins(reqPrgCase, false);
        reqPrgCase = [select Id, RecordType.Name, Type, CaseNumber, Owner.Name, Status 
                              	FROM Case WHERE Id =: reqPrgCase.Id ];

       //Create the Enrollment Case for the applicant
        reqEnrollCase = new Case(
            Status = 'Open', 
            Origin = 'Web',
            RecordTypeId = PC_SYSTEM.recordTypeId('Case', PC_Constants.CASE_ENROLLMENT_RECORD_TYPE), 
            Type = PC_Constants.CASE_ENROLLMENT_RECORD_TYPE_NAME,
            PC_Engagement_Program__c = engPrgA.Id
        );
        PC_Database.ins(reqEnrollCase, false);  
        reqEnrollCase = [select Id, RecordType.Name,Type, CaseNumber, Owner.Name, Status 
                              	FROM Case WHERE Id =: reqEnrollCase.Id ];
        
        
    }
 	
     @isTest static void testgetCaseType(){
        createTestData();
        system.runAs(adminUser) {
            Test.StartTest();

            String caseType = PC_EnrollPatientWZLightningController.getCaseType(reqEnrollCase.Id);
            System.assertNotEquals(caseType, null);

            Test.StopTest();
        }
     }
}