/*********************************************************************************
Class Name      : PC_Test_AddressInfoEWP
Description     : Test Address records and Fields method of PC_AddressInfoEWP
Created By      : Kishore Kanteti
Created Date    : 22-Nov-21
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------
Kishore Kanteti 	       22-Nov-21              Initial Version
*********************************************************************************/

@IsTest
public class PC_Test_AddressInfoEWP{
    public static final String APPLICANT_NAME = 'Test Applicant';
    private static User adminUser;

    @isTest static void testAddressFieldsAndRecords(){
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test100');
        PC_Database.ins(adminUser);
        System.runAs(adminUser) {
            Test.StartTest();
            Account  patient = PC_Test_Setup.createEWPPatient('testpatient', '1988-05-30', 'Mr.' , PC_Constants.PATIENT_RECORD_TYPE);
            patient = (Account)PC_Database.ins(patient, false);

            PC_Address__c  patAddress = PC_Test_Setup.createAddress(patient.Id);
            patAddress = (PC_Address__c)PC_Database.ins(patAddress, false);

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
            enrollDetails.put('activeApplicantId',applicant.Id);
            enrollDetails.put('displayFieldSetName',PC_Constants.getQualifiedAPIName('PC_AddressInformation'));

            PC_AddressInfoEWP.AddressDetails addressDetails = new PC_AddressInfoEWP.AddressDetails();
            addressDetails =  PC_AddressInfoEWP.getAddressFieldsAndRecords(enrollDetails);


            System.assertEquals(addressDetails.patientAddresses != null, true);
            System.assertEquals(addressDetails.addressFields != null, true);

            Map<String,String> enrollDetails1 = new Map<String, String>();
            enrollDetails1.put('patientId',null);
            enrollDetails1.put('activeApplicantId',applicant.Id);
            enrollDetails1.put('displayFieldSetName',PC_Constants.getQualifiedAPIName('PC_AddressInformation'));

            PC_AddressInfoEWP.AddressDetails addressDetails1 = new PC_AddressInfoEWP.AddressDetails();
            addressDetails1 =  PC_AddressInfoEWP.getAddressFieldsAndRecords(enrollDetails1);

            System.assertEquals(addressDetails.patientAddresses != null, true);
            System.assertEquals(addressDetails.addressFields != null, true);

            Test.StopTest();
        }
    }
}