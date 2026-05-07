/*********************************************************************************
Class Name      : PC_Test_AddressInfoEWPProcessor
Description     : Tests the Creation of Address records
Created By      : Kishore Kanteti
Created Date    : 22-Nov-21
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------
Kishore Kanteti 	       22-Nov-21              Initial Version
*********************************************************************************/
@IsTest
private class PC_Test_AddressInfoEWPProcessor{
    private static final String engagementProgramName = 'PCPCP';

    @IsTest static void testAddressInfoEWPProcessor(){

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
            caseAcc = (Account) PC_Database.ups(caseAcc);

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
            pageState.put('persistentAddress', addresses);
            Account testAcc = [Select Id,PC_First_Name__c,PC_Last_Name__c From Account where Id = :caseAcc.Id];
            PC_EnrollmentWizard.recordsCreated = new List<SObject>();
            PC_EnrollmentWizard.recordsCreated.add((sObject)testAcc);

            PC_AddressInfoEWPProcessor addressInfoEWPProcessor = new PC_AddressInfoEWPProcessor();
            addressInfoEWPProcessor.processEnrollment(enrollmentCase, pageState);


            Case updatedCase = [Select Id, AccountId, PC_Program__c from Case where Id =: enrollmentCase.Id];

            PC_Address__c[] savedAddresses = new List<PC_Address__c>([SELECT Id,PC_Address_1__c,PC_Address_2__c FROM PC_Address__c WHERE PC_Account__c =: updatedCase.AccountId]);
            System.assertEquals(savedAddresses.isEmpty(), false);
            Test.stopTest();
        }
    }
}