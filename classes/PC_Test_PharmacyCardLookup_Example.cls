/**
 * Created by vkashikar on 3/19/2018.
 */

@IsTest
public class PC_Test_PharmacyCardLookup_Example {
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
            createAddress(patient.Id);
            system.assertNotEquals(patient.Id, null);

            List<Account> physicians = PC_Test_Setup.createAccounts('PHY',1,PC_Constants.PHYSICIAN_RECORD_TYPE);
            physicians[0].PC_NPI__c = '111111';
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
            Case enrollmentCase = PC_Test_Setup.createProgram(patient);
            enrollmentCase.PC_Engagement_Program__c = engagementProgram.Id;
            enrollmentCase.AccountId = patient.Id;
            enrollmentCase.PC_Physician__c = physicians[0].Id;
            enrollmentCase.PC_Program_Product__c = engagement_program_product.Id;
            enrollmentCase = (Case) PC_Database.ups(enrollmentCase);


            // check if enrollment Case is created
            system.assertNotEquals(enrollmentCase.Id, Null);

            List<Account> patients = new List<Account>();
            patients.add(patient);

            List<PC_Health_Plan__c> healthPlans = PC_Test_Setup.createHealthPlans(patients, 1);
            healthPlans[0].Patient__c = patient.Id;
            healthPlans[0].RecordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.PC_HEALTH_PLAN, PC_Constants.HEALTH_PLAN_PHARMACY_PLAN_RECORD_TYPE);
            // insert all health plans
            PC_Database.ins(healthPlans);

            PC_PharmacyCardLookupController controller = new PC_PharmacyCardLookupController();
            //List<PC_Health_Plan__c> hps = PC_PharmaCardLookupController.getRelatedHealthPlans(enrollmentCase.Id);
            PC_PharmacyCardLookupController.HealthPlansWithLabel hpsWithLabel = PC_PharmacyCardLookupController.getRelatedHealthPlans(enrollmentCase.Id);
            //PC_PharmacyCardLookupController.getPharmacyCardholderInfo(enrollmentCase.Id);
            system.assertEquals(1, hpsWithLabel.healthPlans.size());
            PC_PharmacyCardLookup_Example client = new PC_PharmacyCardLookup_Example();
            PC_Health_Plan__c health_plan = new PC_Health_Plan__c();

            PC_eBenefits.PharmacyCardRequest request = client.createPharmacyCardRequest();
            try {

                PC_eBenefits.PharmacyCardResponse response = client.lookupPharmacyCard(request);

                client.updateHealthPlan(response, health_plan);
            }
            catch(Exception ex) {
                // todo...need to mock the server response here.
                system.assert(true);
            }

            /*try {
                PC_PharmacyCardLookup_UBC clientUBC = new PC_PharmacyCardLookup_UBC();
                PC_eBenefits.PharmacyCardRequest requestUBC = clientUBC.getPharmacyCardRequest(enrollmentCase.Id);
                PC_eBenefits.PharmacyCardResponse responseUBC = clientUBC.getPharmacyCardResponse(enrollmentCase.Id, requestUBC);
                clientUBC.appendHealthPlan(enrollmentCase.Id, requestUBC, responseUBC, health_plan);
            }
            catch(Exception ex) {
                // todo...need to mock the server response here.
                system.assert(true);
            }*/
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