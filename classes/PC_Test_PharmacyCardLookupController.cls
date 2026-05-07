@isTest
public with sharing class PC_Test_PharmacyCardLookupController  {
    private static User adminUser;
    private static final String engagementProgramName = 'engPgm';
    @isTest static void run() {
        adminUser = PC_Test_Setup.createUser('System Administrator', 'user@test100.com', 'test100');
        PC_Database.ins(adminUser);
        System.runAs(adminUser) {
            Test.StartTest();

            List<Account> manufacturers = PC_Test_Setup.createAccounts('testManufacturer', 1, 'Manufacturer');
            manufacturers = (List<Account>) PC_Database.ups(manufacturers);
            Account manufacturer = manufacturers[0];

            Account  patient = PC_Test_Setup.createPatient('testpatient');
            patient.PC_Date_of_Birth__c=Date.today();
            patient.PC_Gender__c='Male';

            patient = (Account)PC_Database.ins(patient, false);
            system.assertNotEquals(patient.Id, null);
            createAddress(patient.Id);

            List<Account> physicians = PC_Test_Setup.createAccounts('PHY',1,PC_Constants.PHYSICIAN_RECORD_TYPE);
            physicians[0].PC_NPI__c='1306200621';
            physicians = PC_Database.ins(physicians);
            createAddress(physicians[0].Id);

            PC_Engagement_Program__c engagementProgram = PC_Test_Setup.createEngagementProgram(engagementProgramName, manufacturer.Id);
            engagementProgram.PC_Program_Code__c = engagementProgramName;
            engagementProgram = (PC_Engagement_Program__c) PC_Database.ups(engagementProgram);
            // check if engagement program is created
            system.assertNotEquals(engagementProgram.Id, Null);

            Product2 product = new Product2();
            //product.PC_NDC__c = 'ndc';
            product.ProductCode = 'pc';
            product.PC_Manufacturer__c = manufacturer.Id;
            product.Name = 'n';
            product = (Product2) PC_Database.ins(product);

            PC_Engagement_Program_Product__c engagement_program_product = new PC_Engagement_Program_Product__c();
            engagement_program_product.PC_Product__c = product.Id;
            engagement_program_product.PC_Engagement_Program__c = engagementProgram.Id;
            engagement_program_product = (PC_Engagement_Program_Product__c) PC_Database.ins(engagement_program_product);


            //Case enrollmentCase = PC_Test_Setup.createEnrollment(engagementProgram.Id);
            Case programCase = PC_Test_Setup.createProgram(patient);
            programCase.PC_Engagement_Program__c = engagementProgram.Id;
            programCase.AccountId = patient.Id;
            programCase.PC_Program_Product__c = engagement_program_product.Id;
            programCase.PC_Physician__c = physicians[0].Id;
            programCase = (Case) PC_Database.ups(programCase);


            // check if enrollment Case is created
            system.assertNotEquals(programCase.Id, Null);

            List<Account> patients = new List<Account>();
            patients.add(patient);

            List<PC_Health_Plan__c> healthPlans = PC_Test_Setup.createHealthPlans(patients, 1);
            healthPlans[0].Patient__c = patient.Id;
            healthPlans[0].RecordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.PC_HEALTH_PLAN, PC_Constants.HEALTH_PLAN_PHARMACY_PLAN_RECORD_TYPE);
            // insert all health plans
            PC_Database.ins(healthPlans);

            PC_PharmacyCardLookupController controller = new PC_PharmacyCardLookupController();
            PC_PharmacyCardLookupController.HealthPlansWithLabel hpsWithLabel = PC_PharmacyCardLookupController.getRelatedHealthPlans(programCase.Id);
            //List<PC_Health_Plan__c> hps = PC_PharmaCardLookupController.getRelatedHealthPlans(enrollmentCase.Id);
            PC_PharmacyCardLookupController.getPharmacyCardholderInfo(programCase.Id);
            system.assertEquals(1, hpsWithLabel.healthPlans.size());
            PC_eBenefits.PharmacyCardRequest request = PC_PharmacyCardLookupController.getPharmacyCardholderInfo(programCase.Id);
            try {
                PC_eBenefits.PharmacyCardResponse response = PC_PharmacyCardLookupController.getPharmacyCardLookupResponse(programCase.Id, JSON.serializePretty(request));
                PC_PharmacyCardLookupController.savePharmaCard(programCase.Id, JSON.serialize(request), JSON.serialize(response));
            }
            catch(Exception ex) {
                // todo...need to mock the server response here.
              //sahgarg commenting for now  system.assert(false);

                PC_Utility.logAndThrowException(ex);

            }


            /*
            PC_PharmaCardLookupRequest.Patient patient = new PC_PharmaCardLookupRequest.Patient();
            patient.birthdate = '';
            patient.firstName = '';
            patient.gender = '';
            patient.id = '';
            patient.lastName = '';
            patient.middleName = '';
            patient.prefix = '';
            patient.suffix = '';
            request.patient = patient;

			PC_PharmaCardLookupRequest.Physician physician = new PC_PharmaCardLookupRequest.Physician();
            physician.birthdate = '';
            physician.firstName = '';
            physician.gender = '';
            physician.id = '';
            physician.lastName = '';
            physician.middleName = '';
            physician.npi = '';
            physician.prefix = '';
            physician.suffix = '';
            request.physician = physician;

            PC_PharmaCardLookupRequest.Product product = new PC_PharmaCardLookupRequest.Product();
            product.id = '';
            product.label = '';
            product.ndc = '';
            request.product = product;
            system.assert(true);*/
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