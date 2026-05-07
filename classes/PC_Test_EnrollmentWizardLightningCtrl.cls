/**
 * Class Name      : PC_Test_EnrollmentWizardLightningCtrl
 * Created By      : Ajinkya
 * @Created Date   : January 31, 2016
 * Modification Log:
 * ----------------------------------------------------------------------------------
 * Developer              Date                   	Description
 * -----------------------------------------------------------------------------------
 * Ajinkya		   	10-January-2017			Initial Version
 * Shabda Bhujad   	10-April-2017			Added logic to create an applicant realted to the enrollment case for coverage of online applicant
 * Tejas Patel	   	12-April-2017		    Modified DML Update to PC_Database.upd with fls check true
 * Ajinkya		   	25-April-2017			[PC-1365] Updated class to associate engagement program to document	
 * Shabda Bhujad	06-July-2017   			[PC-1876] - Modified code to remove the not null assert, retrieve the result of case created in an object and check its attribute
 * Tejas Patel      05-April-2018           Getting the Test coverage up
 */
@isTest
public class PC_Test_EnrollmentWizardLightningCtrl {
	public static final String APPLICANT_NAME = 'TestApplicant';
    private static User adminUser;
    
	@isTest static void testMethodCreate() {	
    adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test100');
        PC_Database.ins(adminUser);
        PC_Test_Setup.assignHealthCloudPermissionSet(adminUser.Id);
        System.runAs(adminUser) {
        	Test.StartTest();
            Account manAccount = PC_Test_Setup.createSampleAccount('', 'Manufacturer');
            manAccount = (Account)PC_Database.ins(manAccount, false);
			// check if manufacturer is created
			system.assertNotEquals(manAccount.Id, null);
			            
            PC_Engagement_Program__c engagementProgram = PC_Test_Setup.createEngagementProgram('PRP', manAccount.Id);
            engagementProgram = (PC_Engagement_Program__c)PC_Database.ins(engagementProgram, false);
            // check if engagement program is created
			system.assertNotEquals(engagementProgram.Id, null);
            
            Case enrollmentCase = PC_Test_Setup.createEnrollment(engagementProgram.Id);
            enrollmentCase = (Case)PC_Database.ins(enrollmentCase, false);
            // check if enrollment case is created
			system.assertNotEquals(enrollmentCase.Id, null);

			PC_Applicant__c applicant = PC_Test_Setup.createApplicant(APPLICANT_NAME, enrollmentCase.Id);
            applicant=(PC_Applicant__c)PC_Database.ins(applicant, false);
            
            PC_EnrollmentWizardLightningController.setupEnrollmentWizard(enrollmentCase.Id);
            // check if enrollment case is created in enrollmentWizardWrapper
            system.assertNotEquals(PC_EnrollmentWizardLightningController.setupEnrollmentWizard(enrollmentCase.Id).enrollmentCase, null);
            /* [PC-1876] - Modified code to remove the not null assert retrieve the result of case created in an object and check its attribute*/

            //PC_EnrollmentWizardLightningController.saveWizardState
            String wizardState = '{"Patient_Information_PRP":{"persistentAccount":{"addrs":[],"applicantId":"a031I000008lh7eQAA","caregiverFirstName":"","caregiverLastName":"","caregiverRelation":"__none","caregiverSalutation":"__none","communicationLanguage":"__none","dob":"1988-06-20","email":"","fax":"","firstName":"Ellen","fsFields":{},"gender":"__none","lastModifiedDate":"2017-12-07T06:21:29.000Z","lastName":"John","name":"","phone":"","preferredCommunicationChannel":"__none","salutation":"__none","status":""},"persistentAddress":[]},"HCO_PRP":{"selectedHCOIds":[]},"Health_Plan_PRP":{"lstHealthPlan":[]},"Physician_Information_PRP":{"selectedResult":null}}';
            PC_EnrollmentWizardLightningController.saveWizardState(enrollmentCase.Id, wizardState);

            PC_EnrollmentWizardLightningController.EnrollmentProcessingResult processedEnrollment = PC_EnrollmentWizardLightningController.processEnrollment(enrollmentCase.Id);
            // check if its success in EnrollmentProcessingResult 
            system.assertEquals(processedEnrollment.success, true);
            PC_EnrollmentWizardLightningController.saveWizardState(enrollmentCase.Id, '');
        	Test.StopTest();
        }
	}
}