/**
 * Class Name      : PC_Test_PhysicianEWPController
 * Created By      : Prachi Nandgaonkar
 * @Created Date   : January 31, 2016
 * Modification Log:
 * ----------------------------------------------------------------------------------
 * Developer              Date                   	Description
 * -----------------------------------------------------------------------------------
 * Prachi Nandgaonkar	  31-January-2017			Initial Version
 * Vijay Kashikar		  14-Apr-2017				Add test coverage for PC_PhysicianEWPController.getApplicantPhysician &  PC_PhysicianEWPController.searchRecords
 * Prachi Nandgaonkar     19-April-2017             [PC-1379] Updated definition of getApplicantPhysician() to query applicant object with activeApplicant 
 * 											        input parameter to handle multiple applicants on same enrollment case
 * Shabda Bhujad		  10-July-2017			    [PC-1886] Removed unnecessary assignments from method createAccounts with 'Record Type' as parameter
 * Ajinkya Deshmukh		  13-July-2017				[PC-1897] removed the unnecessary encollmentCase update.
 */
@isTest
public class PC_Test_PhysicianEWPController {
	public static final String APPLICANT_NAME = 'Test Applicant';
    private static User adminUser;
    private static final String engagementProgramName = 'PCPCP';
    
	@isTest static void testMethodCreate() {
		adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test100');
        PC_Database.ins(adminUser);
        System.runAs(adminUser) {
        	Test.StartTest();
            
            List<Account> manufacturers = PC_Test_Setup.createAccounts('testManufacturer', 1, 'Manufacturer');
            manufacturers = (List<Account>) PC_Database.ups(manufacturers);
            Account manufacturer = manufacturers[0];

            PC_Engagement_Program__c engagementProgram = PC_Test_Setup.createEngagementProgram(engagementProgramName, manufacturer.Id);
            engagementProgram.PC_Program_Code__c = engagementProgramName;
            engagementProgram = (PC_Engagement_Program__c) PC_Database.ups(engagementProgram);

            Case enrollmentCase = PC_Test_Setup.createEnrollment(engagementProgram.Id);
            enrollmentCase = (Case) PC_Database.ups(enrollmentCase);
            
           
            Account caseAcc = PC_Test_Setup.createPatient('sName');
            caseAcc = (Account)  PC_Database.ups(caseAcc);
            
            enrollmentCase.AccountId = caseAcc.Id;
            enrollmentCase = (Case) PC_Database.ups(enrollmentCase);
            
            
            
            List<Account> myAccounts = PC_Test_Setup.newAccounts('Test',1);/*Changed method PC-1886*/
            myAccounts = (List<Account>)PC_Database.ins(myAccounts, false);
            
            PC_Applicant__c applicant = PC_Test_Setup.createApplicant('lastName', enrollmentCase.Id);
            applicant.PC_Enrollment_Case__c = enrollmentCase.Id;
            applicant = (PC_Applicant__c) PC_Database.ups(applicant);            
            
            Id [] fixedSearchResults= new Id[1];

       		fixedSearchResults[0] = myAccounts[0].Id;

       		Test.setFixedSearchResults(fixedSearchResults);

            
            PC_PhysicianEWPController.PhysicianRecord fields =  PC_PhysicianEWPController.getFields();
            List<PC_PhysicianEWPController.PhysicianRecord> applicantPhysicians =  PC_PhysicianEWPController.getApplicantPhysician(enrollmentCase.Id, applicant.Id);
            system.debug('vj->' + applicantPhysicians.size());
            system.assert(!applicantPhysicians.isEmpty());
                
            List<PC_PhysicianEWPController.PhysicianRecord> searchrecord = PC_PhysicianEWPController.searchRecords('Test');
            system.debug('searchrecord : ' + searchrecord);
            for (PC_PhysicianEWPController.PhysicianRecord a : searchrecord){
                System.assertEquals(a.Name, 'Physician Name 0'); /*PC-1886*/
                System.assertEquals(a.specialistType, 'Cardiologist');
                System.assertEquals(a.type, 'Specialist');
            }
        	Test.StopTest();
        	
        }
	}
}