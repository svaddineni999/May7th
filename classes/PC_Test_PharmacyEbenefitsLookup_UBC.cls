/*********************************************************************************************************
Class Name      : PC_Test_PharmacyEbenefitsLookup_UBC
Description     : Test class for PC_PharmacyEbenefitsLookup_UBC
Created By      : Vijay Kashikar
Created Date    : March 26, 2018
Modification Log:
-----------------------------------------------------------------------------------------------------
Developer                   Date                           Description
-----------------------------------------------------------------------------------------------------
Vijay Kashikar               March 26, 2018              Initial Version
*********************************************************************************************************/

@isTest
public with sharing class PC_Test_PharmacyEbenefitsLookup_UBC {
    private static User adminUser;
    private static final String engagementProgramName = 'engPgm';
    @isTest static void run() {
        adminUser = PC_Test_Setup.createUser('System Administrator', 'user@test100.com', 'test100');
        PC_Database.ins(adminUser);
        System.runAs(adminUser) {


            List<Account> manufacturers = PC_Test_Setup.createAccounts('testManufacturer', 1, 'Manufacturer');
            manufacturers = (List<Account>) PC_Database.ups(manufacturers);
            Account manufacturer = manufacturers[0];

            Account  patient = PC_Test_Setup.createPatient('testpatient');
            patient = (Account)PC_Database.ins(patient, false);
            createAddress(patient.Id);
            system.assertNotEquals(patient.Id, null);

            List<Account> physicians = PC_Test_Setup.createAccounts('PHY',1,PC_Constants.PHYSICIAN_RECORD_TYPE);
            physicians[0].PC_NPI__c='1306200621';

            physicians = PC_Database.ins(physicians);
            createAddress(physicians[0].Id);

            List<Account> pharmacies = PC_Test_Setup.createAccounts('testPharmacy',1,PC_Constants.PHARMACY_RECORD_TYPE);
            pharmacies = (List<Account>) PC_Database.ups(pharmacies);
            Account pharmacy = pharmacies[0];

            PC_Engagement_Program__c engagementProgram = PC_Test_Setup.createEngagementProgram(engagementProgramName, manufacturer.Id);
            engagementProgram.PC_Program_Code__c = engagementProgramName;
            engagementProgram = (PC_Engagement_Program__c) PC_Database.ups(engagementProgram);
            // check if engagement program is created
            system.assertNotEquals(engagementProgram.Id, Null);

            Product2 product = new Product2();
            //product.PC_NDC__c = '1234';
            product.PC_Manufacturer__c = manufacturer.Id;
            product.Name = 'testProduct';
            product = (Product2) PC_Database.ins(product);

            PC_Engagement_Program_Product__c programProduct = new PC_Engagement_Program_Product__c();
            programProduct.PC_Engagement_Program__c = engagementProgram.Id;
            programProduct.PC_Product__c = product.Id;
            programProduct = (PC_Engagement_Program_Product__c) PC_Database.ins(programProduct);

            //Case enrollmentCase = PC_Test_Setup.createEnrollment(engagementProgram.Id);
            Case programCase = PC_Test_Setup.createProgram(patient);
            programCase.PC_Engagement_Program__c = engagementProgram.Id;
            programCase.PC_Program_Product__c = programProduct.Id;
            //enrollmentCase.AccountId = patient.Id;
            programCase = (Case) PC_Database.ups(programCase);


            // check if enrollment Case is created
            system.assertNotEquals(programCase.Id, Null);

            List<Account> patients = new List<Account>();
            patients.add(patient);

            List<PC_Health_Plan__c> healthPlans = PC_Test_Setup.createHealthPlans(patients, 1);
            healthPlans[0].Patient__c = patient.Id;
            healthPlans[0].PC_Card_Holder_First_Name__c = '1';
            healthPlans[0].PC_Card_Holder_Last_Name__c = '2';
            healthPlans[0].PC_Cardholder_s_Date_of_Birth__c = Date.today();
            healthPlans[0].PC_Card_Holder_Gender__c = 'Male';
            healthPlans[0].RecordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.PC_HEALTH_PLAN, PC_Constants.HEALTH_PLAN_PHARMACY_PLAN_RECORD_TYPE);
            // insert all health plans
            PC_Database.ins(healthPlans);

            PC_Prescription__c prescription = new PC_Prescription__c();
            prescription.PC_Patient_Account__c = patient.Id;
            prescription.PC_Program_Case__c = programCase.Id;
            prescription.PC_Physician_Account__c = physicians[0].id;
            prescription.PC_Product__c = product.Id;
            PC_Database.ins(prescription);

            Test.StartTest();

            Test.setMock(HttpCalloutMock.class, new PC_UBC_MockHttpResponseGenerator());

            PC_PharmacyEbenefitsLookup_UBC client = new PC_PharmacyEbenefitsLookup_UBC();
            PC_eBenefits.PharmacyBenefitsOptions pharmacyEbenefitsOptions = PC_eBenefits_Utility.getPharmacyBenefitsOptions(programCase.Id);
            PC_eBenefits.PharmacyCardRequest pharmacyCardRequest = PC_eBenefits_Utility.getPharmacyCardholderInfo(programCase.Id);
            PC_eBenefits.PharmacyBenefitsRequest pharmacyEbenefitsRequest = client.createPharmacyBenefitsRequest();

            PC_UBC_Utility ubcUtility = new PC_UBC_Utility();
            PC_UBC.PharmacyCoverageServiceInput pharmacyCoverageServiceInput = ubcUtility.getServiceInput(pharmacyEbenefitsRequest);
            PC_eBenefits_Utility.updatePharmacyRequest(programCase.Id, healthPlans[0].Id, prescription.Id, pharmacy.Id,false, 30, 1, 1, pharmacyEbenefitsRequest);

            //PC_eBenefits.PharmacyBenefitsRequest pharmacyEbenefitsRequest = PC_PharmacyEbenefitsLookupController.getPharmacyBenefitInfo(programCase.Id, healthPlans[0].Id, prescription.Id, pharmacy.Id, 30, 1, 1);

            PC_eBenefits.PharmacyBenefitsResponse pharmacyEbenefitsResponse =
                    client.lookupPharmacyBenefits(pharmacyEbenefitsRequest);

            system.assertEquals(true, pharmacyEbenefitsResponse!=null);

            PC_UBC_Utility  eBenefitsServiceClient = new PC_UBC_Utility();
            PC_UBC.PharmacyCoverageServiceInput eBenefitsServiceInput =
                    eBenefitsServiceClient.getServiceInput(programCase.Id, healthPlans[0].Id, pharmacy.Id, prescription.Id, '30', '1');
            PC_UBC.PharmacyCoverageServiceResponse eBenefitsServiceResponse = eBenefitsServiceClient.checkPharmacyCoverageBenefits(eBenefitsServiceInput);
            system.assertEquals(true, eBenefitsServiceResponse!=null);

            Boolean isExtPharmacy = PC_eBenefits_Utility.isExternalPharmacy(pharmacy.id);
            system.assert(!isExtPharmacy);
            Boolean isExtPharmacy2 = PC_eBenefits_Utility.isExternalPharmacy('11');
            system.assert(isExtPharmacy2);

            String id = PC_eBenefits_Utility.getPharmacyIdBy_Id_Or_ExtId(pharmacy.id);

            PC_UBC_Utility.getUnitOfMeasureCode('entyvio', null);
            PC_UBC_Utility.getUnitOfMeasureCode('CLOMIPRAMINE', null);
            PC_UBC_Utility.getUnitOfMeasureCode('', null);

            Test.stopTest();
        }
    }
    public static void createAddress(Id accounId){

        PC_Address__c address = new PC_Address__c();
        address.PC_Account__c = accounId;
        address.PC_Address_1__c = 'test address line 1';
        address.PC_Address_2__c = 'test address line 2';
        address.PC_City__c = 'EDWARDSVILLE';
        address.PC_State__c = 'MA';
        address.PC_Zip_Code__c = '62025';
        //@@RemoveAddressPhone: address.PC_Phone__c = '0727555957';
        address.PC_Primary_Address__c = true;

        address = (PC_Address__c)PC_Database.ins(address, false);
    }
}