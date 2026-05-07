/**
 * Created by vkashikar on 3/22/2018.
 */
@isTest
public class PC_Test_PharmacyCardLookup_UBC {
    private static User adminUser;
    private static final String engagementProgramName = 'engPgm';
    @isTest static void run() {
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test100');
        PC_Database.ins(adminUser);
        System.runAs(adminUser) {


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
            physicians[0].PC_NPI__c='1306200621';

            physicians = PC_Database.ins(physicians);
            createAddress(physicians[0].Id);

            PC_Engagement_Program__c engagementProgram = PC_Test_Setup.createEngagementProgram(engagementProgramName, manufacturer.Id);
            engagementProgram.PC_Program_Code__c = engagementProgramName;
            engagementProgram = (PC_Engagement_Program__c) PC_Database.ups(engagementProgram);
            // check if engagement program is created
            system.assertNotEquals(engagementProgram.Id, Null);

            //Case enrollmentCase = PC_Test_Setup.createEnrollment(engagementProgram.Id);
            Case programCase = PC_Test_Setup.createProgram(patient);
            programCase.PC_Engagement_Program__c = engagementProgram.Id;
            programCase.PC_Physician__c = physicians[0].Id;
            //enrollmentCase.AccountId = patient.Id;
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

            Test.StartTest();

            Test.setMock(HttpCalloutMock.class, new PC_UBC_MockHttpResponseGenerator());
            PC_PharmacyCardLookup_UBC client = new PC_PharmacyCardLookup_UBC();
            PC_UBC_Utility utility = new PC_UBC_Utility();
            boolean token = utility.authenticateViaNamedCreds();
            system.debug(token);
            system.assert(token);

            PC_eBenefits.PharmacyCardRequest cardRequest = client.createPharmacyCardRequest();
            PC_eBenefits_Utility.updatePharmacyCardRequest(programCase.Id, cardRequest);

            PC_eBenefits.PharmacyCardResponse cardResponse = client.lookupPharmacyCard(cardRequest);

            client.updateHealthPlan(cardResponse, healthPlans[0]);
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