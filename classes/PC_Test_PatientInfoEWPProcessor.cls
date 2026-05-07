/**
 * Class Name      : PC_Test_PatientInfoProcessor
 * Created By      : Vijay Kashikar
 * @Created Date   : Feb 15, 2016
 * Modification Log:
 * ----------------------------------------------------------------------------------
 * Developer              Date                      Description
 * -----------------------------------------------------------------------------------
 * Vijay Kashikar        15-Feb-2017           Initial Version
 * Vijay Kashikar       14-Apr-2017           Updated to handle new scenarios owing to handling of online applicant data
 * Prachi Nandgaonkar   1-May-2017            [PC-1467] Added code coverage for case origin field
 * Prachi Nandgaonkar   16-May-2017           [PC-1544] Rolled back PC-1467 that added code coverage for case origin field
 */
@isTest
public class PC_Test_PatientInfoEWPProcessor {
    private static final String engagementProgramName = 'PCPCP';

    @isTest static void runPatientInfoEWPProcessor() {
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
            List<object> address = new List<object>();
            Map<String, Object> addressInfo = new Map<String, Object>();
            patientInfo.put('firstName','TestProcessorFirstName');
            patientInfo.put('lastName','TestProcessorLastName');
            patientInfo.put('caregiverFirstName', 'TestProcessorCGFirstName');
            addressInfo.put('address1','TestProcessorAddress1');
            addressInfo.put('city','TestProcessorCity');
            addressInfo.put('primary',true);
            address.add(addressInfo);
            pageState.put('persistentAccount',patientInfo);
            pageState.put('persistentAddress',address);
            system.debug('***PageState :***' + pageState);
            PC_PatientInfoEWPProcessor.processEnrollment(enrollmentCase, pageState);

            Id x = enrollmentCase.Id;
            Case updatedCase = [Select Id, AccountId, PC_Program__c from Case where Id = :x];
            Id accId = updatedCase.AccountId;
            Account testAcc 	= [Select Id,PC_First_Name__c,PC_Last_Name__c From Account where Id = :accId];
            PC_Address__c testAddr 	= [Select Id,PC_Address_1__c,PC_City__c From PC_Address__c where PC_Account__c = :accId];
            system.debug('***testAcc :***' + testAcc);
            system.debug('***testAcc :***' + testAddr);
            system.assertEquals(testAcc.PC_First_Name__c, 'TestProcessorFirstName', 'Success');
            system.assertEquals(testAddr.PC_Address_1__c, 'TestProcessorAddress1', 'Success');

            
            Test.stopTest();
        }
    }

}