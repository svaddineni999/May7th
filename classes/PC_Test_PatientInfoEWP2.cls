/**
 * Class Name      : PC_Test_PatientInfoEWP2
 * Created By      : Kishore Kanteti
 * Modification Log:
 * ----------------------------------------------------------------------------------
 * Developer              Date                   	Description
 * -----------------------------------------------------------------------------------
 * Kishore Kanteti	   27-Oct-2021			    Initial Version
 */

@isTest
public class PC_Test_PatientInfoEWP2 {
    public static final String APPLICANT_NAME = 'Test Applicant';
    private static User adminUser;

    @isTest static void testGetAccountOrApplicant() {
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test100');
        PC_Database.ins(adminUser);
        System.runAs(adminUser) {
            Test.StartTest();
            Account  patient = PC_Test_Setup.createEWPPatient('testpatient', '1988-05-30', 'Mr.' , PC_Constants.PATIENT_RECORD_TYPE);
            patient = (Account)PC_Database.ins(patient, false);

            Account  manufacturer = PC_Test_Setup.createEWPPatient('testmanufacturer', '1988-05-30', 'Mr.' , 'Manufacturer');
            manufacturer = (Account)PC_Database.ins(manufacturer, false);

            PC_Engagement_Program__c  engagement = PC_Test_Setup.createEngagementProgram('programA', manufacturer.Id);
            engagement = (PC_Engagement_Program__c)PC_Database.ins(engagement, false);

            Case  enrollment = PC_Test_Setup.createEnrollment(engagement.Id);
            enrollment = (Case)PC_Database.ins(enrollment, false);

            PC_Applicant__c  applicant = PC_Test_Setup.createApplicant('applicant', enrollment.Id);
            applicant = (PC_Applicant__c)PC_Database.ins(applicant, false);

            enrollment.PC_ActiveApplicant__c = applicant.Id;
            enrollment = (Case)PC_Database.ups(enrollment);

            Map<String,String> enrollDetails = new Map<String, String>();
            enrollDetails.put('patientId',patient.Id);
            enrollDetails.put('enrollmentId',enrollment.Id);
            enrollDetails.put('activeApplicantId',applicant.Id);
            enrollDetails.put('fieldSetNames',PC_Constants.getQualifiedAPIName('PC_Patient_Information')+','+PC_Constants.getQualifiedAPIName('PC_Communication_Preference'));
            Map<String,Object> account =  PC_PatientInfoEWP2.getAccountOrApplicant(enrollDetails);

            System.assertEquals(account.get(PC_Constants.getQualifiedAPIName('PC_Salutation__c')), 'Mr.');
            System.assertEquals(account.get(PC_Constants.getQualifiedAPIName('PC_First_Name__c')), 'testpatient');
            System.assertEquals(account.get(PC_Constants.getQualifiedAPIName('PC_Last_Name__c')), 'testpatient');
            System.assertEquals(account.get(PC_Constants.getQualifiedAPIName('PC_Date_of_Birth__c')), '1988-05-30');

            Map<String,String> enrollDetails1 = new Map<String, String>();
            enrollDetails1.put('patientId',null);
            enrollDetails1.put('enrollmentId',enrollment.Id);
            enrollDetails1.put('activeApplicantId',applicant.Id);
            enrollDetails1.put('fieldSetNames',PC_Constants.getQualifiedAPIName('PC_Patient_Information')+','+PC_Constants.getQualifiedAPIName('PC_Communication_Preference'));
            Map<String,Object> convertedApplicant =  PC_PatientInfoEWP2.getAccountOrApplicant(enrollDetails1);
            System.assertEquals(convertedApplicant.get(PC_Constants.getQualifiedAPIName('PC_First_Name__c')), 'Test First Name');
            System.assertEquals(convertedApplicant.get(PC_Constants.getQualifiedAPIName('PC_Last_Name__c')), 'applicant');
            Test.StopTest();
        }
    }
}