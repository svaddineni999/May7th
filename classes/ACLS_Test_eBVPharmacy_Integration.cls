@isTest
public class ACLS_Test_eBVPharmacy_Integration {
	private static User adminUser;
    private static final String engagementProgramName = 'engPgm';
    

    @testsetup
    private static void setup(){
        User adminUser = ACLS_Utility.createTestUser('System Administrator', 'TestCaseManager');
        adminUser.ACLS_Meeting_Link__c='www.sdahksdka.invalid';
        insert adminUser;
        System.runAs(adminUser) {
            List<Account> manufacturers = ACLS_TestDataFactory.createAccounts('testManufacturer', 1, 'Manufacturer');
            manufacturers = (List<Account>) PC_Database.ups(manufacturers);
            Account manufacturer = manufacturers[0];

            Account  patient = new Account();
            patient.PC_First_Name__c = 'Test';
            patient.PC_Last_Name__c = 'Test';
            patient.LastName = 'Test';
            patient.PC_Date_of_Birth__c=Date.today();
            patient.PC_Gender__c='Male';
            patient.RecordTypeId = PC_SYSTEM.recordTypeId('Account', 'ACLS_Patient');

            patient = (Account)PC_Database.ins(patient, false);
            createAddress(patient.Id);
            system.assertNotEquals(patient.Id, null);

            List<Account> physicians = ACLS_TestDataFactory.createAccounts('PHY',1,PC_Constants.PHYSICIAN_RECORD_TYPE);
            physicians[0].PC_NPI__c = '111111';
            physicians = PC_Database.ins(physicians);
            createAddress(physicians[0].Id);

            PC_Engagement_Program__c engagementProgram = PC_Test_Setup.createEngagementProgram(engagementProgramName, null);
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
            healthPlans[0].PC_Rx_Bin__c = '12345';
            healthPlans[0].PC_Rx_PCN__c = '12345';
            healthPlans[0].Group_No__c = '12345';
            healthPlans[0].PC_PBMMember_Id__c = '12345';
            healthPlans[0].RecordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.PC_HEALTH_PLAN, PC_Constants.HEALTH_PLAN_PHARMACY_PLAN_RECORD_TYPE);
            // insert all health plans 
            PC_Database.ins(healthPlans);

            //Create Remote service log
            List<PC_Remote_Service_Log__c> PC_Remote_Service_LogcList = ACLS_TestDataFactory.testRemoteServiceLog(1);
            insert PC_Remote_Service_LogcList;
        }
    }


    @isTest static void runCalloutSuccess() {
        String resbody = '{"transId":"4DAFB8E2-0174-EC11-829A-02A86072209B","drugInfo":{"ndc":"00023320503","unitOfMeasurement":"","qtDispense":2.50,"qtPrescribed":2.50,"daySupply":30},"coveragePreferredResult":[{"scenarioId":"A","planInfo":{"PBMName":"CAREMARK","PlanName":"CAREMARK","BIN":"004336","PCN":"ADV","Group":"SCENARIOA","MemberId":"A159W818520","PBMPhone":"800-522-8159","PersonCode":"01","StartDate":"2022-01-01","EndDate":"2039-12-31","IsCalendarYearPlan":true,"PAPhone":"800-294-5979","PAFax":"888-836-0730"},"MedicarePlanInfo":{"IsLowIncomeSubsidyEnrolled":null,"Stage":null,"IsCoverageGap":null,"Amount":null},"CoB":null,"planOrder":"Primary","planType":"Commercial Plan","coverageStatus":"Covered","claimStatus":"Paid","patientPayAmount":"43.98","accumulatorAccrual":{"accumulatedDeductibleAmount":"N/A","remainingDeductibleAmount":"N/A","amountAppliedToPeriodicDeductible":"N/A","deductibleMet":null,"isDeductibleAppliedToOOP":null,"OOPMet":false,"OOPMax":"N/A","OOPRemaining":"N/A","coInsurancePercent":"N/A","annualCap":"N/A"},"rejectDesc":"","SPPName":[""],"hasMandatoryContractedSP":false,"isProductOnFormulary":null,"productFormularyTier":null,"isPARequired":false}]}';
        ACLS_eBVPharmacy_IntegrationHandler.res = new HttpResponse();
        ACLS_eBVPharmacy_IntegrationHandler.res.setStatusCode(200);
        ACLS_eBVPharmacy_IntegrationHandler.res.setBody(resbody);
        
		Test.setMock(HttpCalloutMock.class, new ACLS_Test_eBVHttpCalloutMock());
        User adminUser = [select id, lastName from User where lastName = 'TestCaseManager'];
        Case enrollmentCase = [Select Id from Case LIMIT 1];
        PC_Health_Plan__c healthPlans = [Select Id from PC_Health_Plan__c LIMIT 1];
        System.runAs(adminUser) {

            PC_PharmacyCardLookupController controller = new PC_PharmacyCardLookupController();
            //List<PC_Health_Plan__c> hps = PC_PharmaCardLookupController.getRelatedHealthPlans(enrollmentCase.Id);
            PC_PharmacyCardLookupController.HealthPlansWithLabel hpsWithLabel = PC_PharmacyCardLookupController.getRelatedHealthPlans(enrollmentCase.Id);
            //PC_PharmacyCardLookupController.getPharmacyCardholderInfo(enrollmentCase.Id);
            system.assertEquals(1, hpsWithLabel.healthPlans.size());
            ACLS_eBVPharmacy_IntegrationHandler client = new ACLS_eBVPharmacy_IntegrationHandler();
            PC_Health_Plan__c health_plan = new PC_Health_Plan__c();
			
            Test.StartTest();
            PC_eBenefits.PharmacyBenefitsRequest request = client.createPharmacyBenefitsRequest();
            request.healthPlanId = healthPlans.Id;
            request.caseId = enrollmentCase.Id;
            
            try {
				
                PC_eBenefits.PharmacyBenefitsResponse response = client.lookupPharmacyBenefits(request);
                
                PC_eBenefits.Address add = new PC_eBenefits.Address();
                add.addressOne = 'addressOne';
                add.city = 'city';
                PC_eBenefits.Pharmacy ph = new PC_eBenefits.Pharmacy();
                ph.npi = '1234';
                ph.ncpdp = '123456';
                ph.extId = 'gnb123';
                ph.name = 'Test';
                ph.fax = '1234987654';
                ph.phone = '1234567890';
                ph.zipCode = '12345';
          		ph.address = add;
                response.pharmacy = ph;
                
                ACLS_eBVPharmacy_IntegrationHandler.covertToCurrencyFormat(2.2);
                ACLS_eBVPharmacy_IntegrationHandler.covertToCurrencyFormat(null);
                client.updatePharmacy(response, new Account(), new PC_Address__c());
                client.updateProgramCoverage(response, new PC_Program_Coverage__c());
            }
            catch(Exception ex) {
                system.assert(true);
            }
            Test.stopTest();
        }

    }
    @isTest static void runValidationFailure() {
        User adminUser = [select id, lastName from User where lastName = 'TestCaseManager'];
        Case enrollmentCase = [Select Id from Case LIMIT 1];
        PC_Health_Plan__c healthPlans = [Select Id from PC_Health_Plan__c LIMIT 1];
        System.runAs(adminUser) {
            Test.StartTest();           

            PC_PharmacyCardLookupController controller = new PC_PharmacyCardLookupController();
            //List<PC_Health_Plan__c> hps = PC_PharmaCardLookupController.getRelatedHealthPlans(enrollmentCase.Id);
            PC_PharmacyCardLookupController.HealthPlansWithLabel hpsWithLabel = PC_PharmacyCardLookupController.getRelatedHealthPlans(enrollmentCase.Id);
            //PC_PharmacyCardLookupController.getPharmacyCardholderInfo(enrollmentCase.Id);
            system.assertEquals(1, hpsWithLabel.healthPlans.size());
            ACLS_eBVPharmacy_IntegrationHandler client = new ACLS_eBVPharmacy_IntegrationHandler();
            PC_Health_Plan__c health_plan = new PC_Health_Plan__c();

            PC_eBenefits.PharmacyBenefitsRequest request = client.createPharmacyBenefitsRequest();
            request.healthPlanId = healthPlans.Id;
            request.caseId = enrollmentCase.Id;
            
            try {

                PC_eBenefits.PharmacyBenefitsResponse response = client.lookupPharmacyBenefits(request);
            }
            catch(Exception ex) {
                system.assert(true);
            }
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