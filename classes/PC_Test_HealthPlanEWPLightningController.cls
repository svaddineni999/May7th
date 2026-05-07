/**
 * Class Name      : PC_Test_HealthPlanEWPLightningController
 * Created By      : Ajinkya
 * @Created Date   : January 31, 2016
 * Modification Log:
 * ----------------------------------------------------------------------------------
 * Developer              Date                   	Description
 * -----------------------------------------------------------------------------------
 * Ajinkya		  10-January-2017			Initial Version
 * Shishir Bansal        10-Dec-2019      [PC-5792] Avoid hardcoding of string variable
 */
@isTest
public class PC_Test_HealthPlanEWPLightningController {
	public static final String APPLICANT_NAME = 'Test Applicant';
    private static User adminUser;
    
	@isTest static void testAll() {
		adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test100');
        PC_Database.ins(adminUser);
        System.runAs(adminUser) {
        	Test.StartTest();
            //Create Patient
            Account  patient = PC_Test_Setup.createPatient('testpatient');
        	patient = (Account)PC_Database.ins(patient, false);
            // check if patient is created
            system.assertNotEquals(patient.Id, null);

            //Create Payer
            List<Account> myAccounts = PC_Test_Setup.createAccounts('Test',1,PC_Constants.PAYER_RECORD_TYPE);
            myAccounts = (List<Account>)PC_Database.ins(myAccounts, false);
            // check if payer is created

            system.assertNotEquals(myAccounts[0].Id, null);

            //Set SOSL result
            List<ID> soslIDS = new List<ID>();
            soslIDS.add(myAccounts[0].Id);
            Test.setFixedSearchResults(soslIDS);

            //Manufacturer
            Account  manufacturer = PC_Test_Setup.createEWPPatient('testmanufacturer', '1988-05-30', 'Mr.' , 'Manufacturer');
            manufacturer = (Account)PC_Database.ins(manufacturer, false);

            //Engagment Program
            PC_Engagement_Program__c  engagement = PC_Test_Setup.createEngagementProgram('programA', manufacturer.Id);
            engagement = (PC_Engagement_Program__c)PC_Database.ins(engagement, false);

            //Enrollmet Case
            Case  enrollment = PC_Test_Setup.createEnrollment(engagement.Id);
            enrollment = (Case)PC_Database.ins(enrollment, false);

            //Create Applicant
            PC_Applicant__c  applicant = PC_Test_Setup.createApplicant('applicant', enrollment.Id);
            Id appRecordType = PC_SYSTEM.recordTypeId(PC_Constants.getQualifiedAPIName('PC_Applicant__c'),PC_Constants.APPLICANT_ONLINE_RECORD_TYPE);
            applicant.RecordTypeId = appRecordType;
            applicant.PC_HP_Payer_Name__c = myAccounts[0].Name;
            applicant = (PC_Applicant__c)PC_Database.ins(applicant, false);

            //Create HealthPLan
            PC_Health_Plan__c myHealthPlan = PC_Test_Setup.createTestHealthPlan(Patient.Id);
            myHealthPlan = (PC_Health_Plan__c)PC_Database.ins(myHealthPlan, false);
            // check if health plan is created
            system.assertNotEquals(myHealthPlan.Id, null);

            Map<String, PC_HealthPlanEWPLightningController.FieldWrapper> f = PC_HealthPlanEWPLightningController.getFieldLabel();
            system.assertNotEquals(f.size(),0);

            List<PC_HealthPlanEWPLightningController.healthPlanPageWrapper> h1 = PC_HealthPlanEWPLightningController.getHealthPlan(Patient.Id, PC_Constants.EMPTY_STRING);
            system.assertNotEquals(h1.size(),0);
            system.assertEquals(h1[0].healthPlanId,myHealthPlan.Id);

            List<PC_HealthPlanEWPLightningController.payerWrapper> p = PC_HealthPlanEWPLightningController.getPayer('Account Name 0');
            system.assertNotEquals(p.size(),0);

            List<PC_HealthPlanEWPLightningController.payerWrapper> p1 = PC_HealthPlanEWPLightningController.getPayer(PC_Constants.EMPTY_STRING);
            system.assertNotEquals(p1.size(),0);

            List<String> ignoreFields = new List<String>();
            List<PC_HealthPlanEWPLightningController.healthPlanPageWrapper> hp = PC_HealthPlanEWPLightningController.getApplicantHealthPlans((String) String.valueOf(enrollment.Id) ,
                    applicant.Id , ' ' ,ignoreFields , ' ', ' ');
        	Test.StopTest();
        }
	}
}