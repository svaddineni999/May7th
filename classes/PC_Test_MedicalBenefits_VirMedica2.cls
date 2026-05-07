/**
 * Created by vkashikar on 4/23/2019.
 * Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------
Hitha Avalakki            Feb 26, 2021           [PC-7442] Replaced recordTypeId with Type in SOQL query for program case record
Hitha Avalakki            Mar 19, 2021           [PC-7533] Replaced constant CASE_PROGRAM_RECORD_TYPE_NAME to CASE_PROGRAM_TYPE
 */

@IsTest
private class PC_Test_MedicalBenefits_VirMedica2 {
    private static final String engagementProgramName = 'HPEWP';
    private static Id medicalHealthPlanRecTypeId = (Id) PC_SYSTEM.recordTypeId(PC_Constants.PC_HEALTH_PLAN, PC_Constants.HEALTH_PLAN_MEDICAL_RECORD_TYPE);


    @isTest static void testCreateMedicalBenefitRequest() {

        User adminUser = PC_Test_Setup.createUser('System Administrator', 'userpctest@testpc.com', 'UserName');
        PC_Database.ins(adminUser);
        System.runAs(adminUser) {

            Test.StartTest();
            PC_eBenefits.MedicalBenefitsRequest request = new PC_eBenefits.MedicalBenefitsRequest();
            PC_MedicalBenefits_VirMedica2 vmi = new PC_MedicalBenefits_VirMedica2();
            request = vmi.createMedicalBenefitRequest();
            system.assert(request != null);
            Test.stopTest();
        }
    }


    @isTest static void testLookupMedicalBenefits() {

        User adminUser = PC_Test_Setup.createUser('System Administrator', 'userpctest@testpc.com', 'UserName');
        PC_Database.ins(adminUser);
        System.runAs(adminUser) {

            Test.StartTest();
            PC_eBenefits.MedicalBenefitsRequest request = new PC_eBenefits.MedicalBenefitsRequest();

            PC_MedicalBenefits_VirMedica2 vmi = new PC_MedicalBenefits_VirMedica2();


            //[PC-7442] Replaced recordTypeId with Type in SOQL query for program case record
            Case programCase = [Select Id,AccountId from Case where Type =:PC_Constants.CASE_PROGRAM_TYPE LIMIT 1];
            system.debug('programCase' + programCase);


            Id patientRecordId = PC_SYSTEM.recordTypeId('Account', PC_Constants.PATIENT_RECORD_TYPE);


            Account patient = [Select Id from Account where RecordTypeId = :patientRecordId LIMIT 1];

            system.debug('programCase' + patient);


            PC_Health_Plan__c primaryHealthPlan = [
                    Select Id
                    from PC_Health_Plan__c
                    where Patient__c = :programCase.AccountId
                    AND
                    PC_Plan_Type__c = :PC_Constants.HEALTH_PLAN_TYPE_PRIMARY
                    LIMIT 1
            ];

            PC_Health_Plan__c secondaryHealthPlan = [
                    Select Id
                    from PC_Health_Plan__c
                    where Patient__c = :programCase.AccountId
                    AND
                    PC_Plan_Type__c = :PC_Constants.HEALTH_PLAN_TYPE_SECONDARY
                    LIMIT 1
            ];


            PC_Health_Plan__c tertiaryHealthPlan = [
                    Select Id
                    from PC_Health_Plan__c
                    where Patient__c = :programCase.AccountId
                    AND
                    PC_Plan_Type__c = :PC_Constants.HEALTH_PLAN_TYPE_TERTIARY
                    LIMIT 1
            ];


            PC_Prescription__c prescription = [
                    SELECT Id, PC_PrimaryDiagnosis__c
                    from PC_Prescription__c
                    where PC_PrimaryDiagnosis__c = 'M81.0'
                    LIMIT 1
            ];


            system.debug('prescription' + prescription);


            Id hcoRecordTypeId = (Id) PC_SYSTEM.recordTypeId(PC_Constants.PATIENT_OBJECT, PC_Constants.HCO_RecordType);


            Account clinic = [Select id from Account where RecordTypeId = :hcoRecordTypeId];
            system.debug('clinic' + clinic);

            List<String>adminCodes = new List<String>();
            adminCodes.add('96372');

            PC_eBenefits.MedicalBenefitsResponse response = new PC_eBenefits.MedicalBenefitsResponse();


            Test.setMock(HttpCalloutMock.class, new PC_Test_VirMedica_MockHttpResponse());
            PC_eBenefits_Utility.updateMedicalBenefitRequest(programCase.id, primaryHealthPlan.id,
                    secondaryHealthPlan.id, tertiaryHealthPlan.id, prescription.id, clinic.id,
                    patient.Id, adminCodes, request);

            request.patient.firstName = 'Patient#200';
            response = vmi.lookupMedicalBenefits(request);
            PC_eBenefits.sCoverageDetail sCoverage = new PC_eBenefits.sCoverageDetail();
            vmi.updateCoverage(response, sCoverage);
            system.assert(sCoverage != null);
            Test.stopTest();
        }
    }

     public static void createAddress(Id accounId) {

        PC_Address__c address = new PC_Address__c();
        address.PC_Account__c = accounId;
        address.PC_Address_1__c = 'test address line 1';
        address.PC_Address_2__c = 'test address line 2';
        address.PC_City__c = 'EDWARDSVILLE';
        address.PC_State__c = 'MA';
        address.PC_Zip_Code__c = '62025';
        //@@RemoveAddressPhone: address.PC_Phone__c = '0727555957';
        address.PC_Primary_Address__c = true;

        address = (PC_Address__c) PC_Database.ins(address, false);
    }


    @testSetup static void setup() {

        Account patient = PC_Test_Setup.createPatient('testpatient');
        patient.PC_Date_of_Birth__c = Date.today();
        patient.PC_Gender__c = 'Male';
        patient = (Account) PC_Database.ins(patient, false);
        createAddress(patient.Id);

        Id payerRecordTypeId = (Id) PC_SYSTEM.recordTypeId(PC_Constants.PATIENT_OBJECT, PC_Constants.PAYER_RECORD_TYPE);
        Account payerAccount = PC_Test_Setup.createAccount('testPayer123', payerRecordTypeId);
        payerAccount = (Account) PC_Database.ins(payerAccount);

        Id hcoRecordTypeId = (Id) PC_SYSTEM.recordTypeId(PC_Constants.PATIENT_OBJECT, PC_Constants.HCO_RecordType);
        Account hcoAccount = PC_Test_Setup.createAccount('testHCO', hcoRecordTypeId);
        hcoAccount.PC_NPI__c = '111';
        hcoAccount = (Account) PC_Database.ups(hcoAccount);

        Contact contact = PC_Test_Setup.createContact(hcoAccount.Id);
        PC_Database.ins(contact);

        List<Account> manufacturers = PC_Test_Setup.createAccounts('testManufacturer', 1, 'Manufacturer');

        manufacturers = (List<Account>) PC_Database.ups(manufacturers);
        createAddress(manufacturers[0].Id);

        List<Account> physicians = PC_Test_Setup.createAccounts('PHY', 1, PC_Constants.PHYSICIAN_RECORD_TYPE);
        physicians[0].PC_NPI__c = '1306200621';
        physicians = PC_Database.ins(physicians);
        createAddress(physicians[0].Id);


        PC_Engagement_Program__c engagementProgram = PC_Test_Setup.createEngagementProgram(engagementProgramName, manufacturers[0].Id);
        engagementProgram.PC_Program_Code__c = engagementProgramName;
        engagementProgram.PC_Manufacturer__c = manufacturers[0].Id;
        engagementProgram = (PC_Engagement_Program__c) PC_Database.ups(engagementProgram);

        Product2 product = new Product2();
        product.PC_NDC__c = '24542131';
        product.ProductCode = 'Ambien';
        product.PC_Strength__c = '50';
        product.PC_Manufacturer__c = manufacturers[0].Id;
        product.Name = 'Ambien 10mg Tablet';
        product = (Product2) PC_Database.ins(product);


        PC_Engagement_Program_Product__c engagement_program_product = new PC_Engagement_Program_Product__c();
        engagement_program_product.PC_Product__c = product.Id;
        engagement_program_product.PC_Engagement_Program__c = engagementProgram.Id;
        engagement_program_product = (PC_Engagement_Program_Product__c) PC_Database.ins(engagement_program_product);


        List<Account> patientAccList = new List<Account>();
        patientAccList.add(patient);

        List<PC_Health_Plan__c> healthPlanList = PC_Test_Setup.createHealthPlans(patientAccList, 3);
        Id medicalHealthPlanRecTypeId = (Id) PC_SYSTEM.recordTypeId(PC_Constants.PC_HEALTH_PLAN,
                PC_Constants.HEALTH_PLAN_MEDICAL_RECORD_TYPE);


        healthPlanList[0].PC_Plan_Type__c = PC_Constants.HEALTH_PLAN_TYPE_PRIMARY;
        healthPlanList[0].PC_PBMMember_Id__c = '1234';
        healthPlanList[0].PC_Plan_Status__c = PC_Constants.ACTIVE;
        healthPlanList[0].RecordTypeId = medicalHealthPlanRecTypeId;
        healthPlanList[0].PC_Payer__c = payerAccount.id;
        healthPlanList[0].ID_Policy_No__c = '12345';
        healthPlanList[0].PC_Cardholder_Relationship_to_Patient__c = PC_Constants.SELF;

        healthPlanList[1].PC_Plan_Type__c = PC_Constants.HEALTH_PLAN_TYPE_SECONDARY;
        healthPlanList[1].PC_PBMMember_Id__c = '1234';
        healthPlanList[1].PC_Plan_Status__c = PC_Constants.ACTIVE;
        healthPlanList[1].RecordTypeId = medicalHealthPlanRecTypeId;
        healthPlanList[1].PC_Payer__c = payerAccount.id;
        healthPlanList[1].ID_Policy_No__c = '12345';
        healthPlanList[1].PC_Cardholder_Relationship_to_Patient__c = PC_Constants.SELF;

        healthPlanList[2].PC_Plan_Type__c = PC_Constants.HEALTH_PLAN_TYPE_TERTIARY;
        healthPlanList[2].PC_PBMMember_Id__c = '1234';
        healthPlanList[2].PC_Plan_Status__c = PC_Constants.ACTIVE;
        healthPlanList[2].RecordTypeId = medicalHealthPlanRecTypeId;
        healthPlanList[2].PC_Payer__c = payerAccount.id;
        healthPlanList[2].ID_Policy_No__c = '12345';
        healthPlanList[2].PC_Cardholder_Relationship_to_Patient__c = PC_Constants.SELF;
        healthPlanList = PC_Database.ups(healthPlanList);


        Case programCase = PC_Test_Setup.createProgram(patient);
        //programCase.AccountId = patient.Id;
        programCase.PC_Physician__c = physicians[0].Id;
        programCase.PC_Engagement_Program__c = engagementProgram.Id;
        programCase.PC_Program_Product__c = engagement_program_product.Id;
        //programCase.PC_PA_Prescription__c = prescription.Id;
        programCase = (Case) PC_Database.ups(programCase);


        PC_Prescription__c prescription = PC_Test_Setup.newPrescription(product.Id);
        prescription.PC_Rx_Start_Date__c = date.today().addDays(-10);
        prescription.PC_Rx_End_Date__c = date.today().addDays(10);
        prescription.PC_Physician_Account__c = physicians[0].id;
        prescription.PC_PrimaryDiagnosis__c = 'M81.0';
        //prescription.PC_SecondaryDiagnosis__c='M81.0';
        prescription.PC_Rx_Status__c = PC_Constants.TRUE_BOOLEAN;
        prescription.PC_PlaceOfService__c = '22';
        prescription.PC_Program_Case__c = programCase.Id;

        prescription.PC_Product__c = product.id;


        PC_Database.ins(prescription, true);


        PC_Account_Identifier__c patientAccount_identifier = PC_Test_Setup.createAccountIdentifier(patient.id,
                PC_Constants.ACCOUNT_IDENTIFIER_TYPE_SSN, PC_Constants.ACCOUNT_IDENTIFIER_ASSIGNER_US_SSN);
        PC_Database.ins(patientAccount_identifier);

        PC_Account_Identifier__c payerAccount_identifier = PC_Test_Setup.createAccountIdentifier(payerAccount.id,
                PC_Constants.ACCOUNT_IDENTIFIER_TYPE_PAYER_ID, PC_Constants.ACCOUNT_IDENTIFIER_ASSIGNER_VMI);
        PC_Database.ins(payerAccount_identifier);

        PC_Association__c associationList = PC_Test_Setup.createAssociations(programCase.Id, hcoAccount.Id,
                null, PC_Constants.ACCOUNT_ROLE);
        PC_Database.ins(associationList);


        PC_Integration_Settings__c setting = new PC_Integration_Settings__c();

        setting.endpoint_Url__c = 'https://api-amgen-2.virmedica.com/?q=200';
        setting.password__c = 'anystring';
        setting.username__c = '200';
        setting.Name = 'PC_VMI_MedicalBenefits';

        PC_Database.ins(setting);

    }


}