/**
 * Class Name      : PC_Test_PatientInfo2WithAddressProcessor
 * Created By      : Kishore Kanteti
 * @Created Date   : 01-Dec-2021
 * Modification Log:
 * ----------------------------------------------------------------------------------
 * Developer              Date                      Description
 * -----------------------------------------------------------------------------------
 * Kishore Kanteti      01-Dec-2021               Initial Version
 */

@IsTest
public class PC_Test_PatientInfo2WithAddressProcessor{
    private static final String engagementProgramName = 'PCPCP';

    @isTest static void runPatientInfo2WithAddressProcessor() {
        User adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'userpctest@testpc.com','UserName');
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

            //creating pageState as desired by the processor
            Map<String, Object> pageState = new Map<String, Object>();
            List<Map<String, Object>> addresses = new List<Map<String, Object>>();
            Map<String, Object> patientAddress1 = new Map<String, Object>();
            patientAddress1.put(PC_Constants.getQualifiedAPIName('PC_Address_1__c'), 'Address 1');
            patientAddress1.put(PC_Constants.getQualifiedAPIName('PC_Address_2__c'), 'Address 2');
            patientAddress1.put(PC_Constants.getQualifiedAPIName('PC_City__c'), 'Hyd');

            Map<String, Object> patientAddress2 = new Map<String, Object>();
            patientAddress2.put(PC_Constants.getQualifiedAPIName('PC_Address_1__c'), 'Address 11');
            patientAddress2.put(PC_Constants.getQualifiedAPIName('PC_Address_2__c'), 'Address 12');
            patientAddress2.put(PC_Constants.getQualifiedAPIName('PC_City__c'), 'Bang');
            addresses.add(patientAddress1);
            addresses.add(patientAddress2);
            pageState.put('addressInfo',addresses);

            Map<String, Object> patientInfo = new Map<String, Object>();
            patientInfo.put(PC_Constants.getQualifiedAPIName('PC_First_Name__c'),'TestProcessorFirstName');
            patientInfo.put(PC_Constants.getQualifiedAPIName('PC_Last_Name__c'),'TestProcessorLastName');
            patientInfo.put(PC_Constants.getQualifiedAPIName('PC_Caregiver_First_Name__c'), 'TestProcessorCGFirstName');
            pageState.put('patientInfo',patientInfo);

            PC_PatientInfo2WithAddressEWPProcessor patientInfo2WithAddressEWPProcessor = new PC_PatientInfo2WithAddressEWPProcessor();
            patientInfo2WithAddressEWPProcessor.processEnrollment(enrollmentCase, pageState);

            Id x = enrollmentCase.Id;
            Case updatedCase = [Select Id, AccountId, PC_Program__c from Case where Id = :x];
            Id accId = updatedCase.AccountId;
            Account testAcc = [Select Id,PC_First_Name__c,PC_Last_Name__c From Account where Id = :accId];
            system.assertEquals(testAcc.PC_First_Name__c, 'TestProcessorFirstName', 'Success');
            Test.stopTest();
        }
    }
}