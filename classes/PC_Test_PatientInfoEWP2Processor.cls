/**
 * Class Name      : PC_Test_PatientInfoEWP2Processor
 * Created By      : Kishore Kanteti
 * @Created Date   : 28-Oct-2021
 * Modification Log:
 * ----------------------------------------------------------------------------------
 * Developer              Date                      Description
 * -----------------------------------------------------------------------------------
 * Kishore Kanteti      28-Oct-2021               Initial Version
 */
@isTest
public class PC_Test_PatientInfoEWP2Processor {
    private static final String engagementProgramName = 'PCPCP';

    @isTest static void runPatientInfoEWP2Processor() {
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

            //List<Account> caseAccounts = PC_Test_Setup.createAccounts('caseAcc', 1, 'caseAcc');

            //caseAccounts = (List<Account>) PC_Database.ups(caseAccounts);
            Account caseAcc = PC_Test_Setup.createPatient('sName');
            caseAcc = (Account)  PC_Database.ups(caseAcc);

            enrollmentCase.AccountId = caseAcc.Id;
            enrollmentCase = (Case) PC_Database.ups(enrollmentCase);

            //creating pageState as desired by the processor
            Map<String, Object> pageState = new Map<String, Object>();
            Map<String, Object> patientInfo = new Map<String, Object>();
            patientInfo.put(PC_Constants.getQualifiedAPIName('PC_First_Name__c'),'TestProcessorFirstName');
            patientInfo.put(PC_Constants.getQualifiedAPIName('PC_Last_Name__c'),'TestProcessorLastName');
            patientInfo.put(PC_Constants.getQualifiedAPIName('PC_Caregiver_First_Name__c'), 'TestProcessorCGFirstName');
            pageState.put('persistentAccount',patientInfo);
            PC_PatientInfoEWP2Processor patientInfoEWP2Processor = new PC_PatientInfoEWP2Processor();
            patientInfoEWP2Processor.processEnrollment(enrollmentCase, pageState);

            Id x = enrollmentCase.Id;
            Case updatedCase = [Select Id, AccountId, PC_Program__c from Case where Id = :x];
            Id accId = updatedCase.AccountId;
            Account testAcc = [Select Id,PC_First_Name__c,PC_Last_Name__c From Account where Id = :accId];
            system.assertEquals(testAcc.PC_First_Name__c, 'TestProcessorFirstName', 'Success');
            Test.stopTest();
        }
    }
}