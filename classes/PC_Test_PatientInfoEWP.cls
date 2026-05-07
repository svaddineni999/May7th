/**
 * Class Name      : PC_Test_PatientInfoEWP
 * Created By      : Ajinkya
 * @Created Date   : January 31, 2016
 * Modification Log:
 * ----------------------------------------------------------------------------------
 * Developer              Date                   	Description
 * -----------------------------------------------------------------------------------
 * Ajinkya		   10-January-2017			Initial Version
 * Shabda Bhujad   10-April-2017			Added logic to pull the data for address through the applicant object 
 * Ajinkya Deshmukh 12-April-2017			Added asserts 	
 * Vijay Kashikar	20-Apr-2017				Changes made owing to updated method signature of PC_PatientInfoEWP.getAccountorApplicant
 * Ajinkya 			25 Apr 2017			    [PC-1365] Updated class to associate engagement program to document
 * Vijay Kashikar	31-May-2017				Changes made owing to updated method signature of PC_PatientInfoEWP.getAccountorApplicant
 * Vijay Kashikar   20-Aug-2019             [PC-5326] - Replaced PC_Patient hardcoding with constant
 * Kanteti Kishore  12-Dec-2019				[PC-5975] - Updated method signature of PC_PatientInfoEWP.getAccountorApplicant
 */

@isTest
public class PC_Test_PatientInfoEWP {
    public static final String APPLICANT_NAME = 'Test Applicant';
    private static User adminUser;

    @isTest static void testMethodCreate() {
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
                                  
            Map<String, List<PC_PicklistFieldManager.PicklistEntryWrapper>> pickList;
            PC_PatientInfoEWP.FieldLabels fieldList;
            PC_PatientInfoEWP.AccountRecord acc;
            PC_PatientInfoEWP.AccountRecord app;
            List<PC_PatientInfoEWP.AddressRecord> addr;
            pickList = PC_PatientInfoEWP.getPicklistEntryMap();
            fieldList = PC_PatientInfoEWP.getFieldLabels();
            Map<String,String> enrollDetails = new Map<String, String>();
            enrollDetails.put('patientId',patient.Id);
            enrollDetails.put('enrollmentId',enrollment.Id);
            enrollDetails.put('activeApplicantId',applicant.Id);
            enrollDetails.put('fieldSetName',null);
            enrollDetails.put('replaceTarget','');
            enrollDetails.put('replaceText','');
            acc =  PC_PatientInfoEWP.getAccountorApplicant(enrollDetails, new List<String>());
            addr = acc.addrs;

            System.assertEquals(acc.salutation, 'Mr.');
            System.assertEquals(acc.firstName, 'testpatient');
            System.assertEquals(acc.lastName, 'testpatient');
            System.assertEquals(String.valueof(acc.dob), '1988-05-30');
            Map<String,String> enrollDetails1 = new Map<String, String>();
            enrollDetails1.put('patientId',null);
            enrollDetails1.put('enrollmentId',enrollment.Id);
            enrollDetails1.put('activeApplicantId',applicant.Id);
            enrollDetails1.put('fieldSetName',null);
            enrollDetails1.put('replaceTarget','');
            enrollDetails1.put('replaceText','');
            app =  PC_PatientInfoEWP.getAccountorApplicant(enrollDetails1, new List<String>());

            System.assertEquals(app.firstName, 'Test First Name');
            System.assertEquals(app.lastName, 'applicant');

            for (PC_PatientInfoEWP.AddressRecord a : addr){
                System.assertEquals(a.address1, 'test address line 1');
                System.assertEquals(a.address2, 'test address line 2');
                System.assertEquals(a.city, 'test City');
                //System.assertEquals(a.state, 'test State');
                System.assertEquals(a.zipCode, '123321');
                System.assertEquals(a.primary, true);
            }
            String noneVal=PC_PatientInfoEWP.getPickListValueNone();
            System.assertNotEquals(noneVal,null);
            Test.StopTest(); 
        }
    }
}