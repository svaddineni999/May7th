/**
 * Class Name      : PC_Test_Case_ShowPatientAge_ExtC
 * Created By      : Vijay kashikar
 * @Created Date   : Apr 14, 2016
 * Modification Log:
 * ----------------------------------------------------------------------------------
 * Developer              Date                   	Description
 * -----------------------------------------------------------------------------------
 * Vijay Kashikar	  14-Apr-2017			Initial Version
 * Vijay Kashikar     Aug 20, 2019          PC-5326 - Replaced PC_Patient hardcoding with constant
 */
@isTest
public class PC_Test_Case_ShowPatientAge_ExtC {
	public static final String APPLICANT_NAME = 'Test App';
    private static User adminUser;
    
	@isTest static void run() {
		adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@pcTestCaseShowPatientAgeExtC.com', 'userpc');
        PC_Database.ins(adminUser);
        System.runAs(adminUser) {
        	Test.StartTest();
            Account  patient = PC_Test_Setup.createEWPPatient('testpatient', '1980-12-31', 'Mr.' , PC_Constants.PATIENT_RECORD_TYPE);
            patient = (Account)PC_Database.ins(patient, false);
            
            Case c = PC_Test_Setup.createCase(adminUser, patient);
            c = (Case) PC_Database.ins(c, false);
            
            ApexPages.StandardController sc = new ApexPages.StandardController(c);
            PC_Case_ShowPatientAge_ExtController extC = new PC_Case_ShowPatientAge_ExtController(sc);
            
            String x = extC.getAge();
            system.debug('age -> '+x);            
            if(x == '-1' || x=='-2') {
                // failure case       
                system.assert(false);
            }
            else {
                // success case
                system.assert(true);
            }
            
        	Test.StopTest();
        	
        }
	}
}