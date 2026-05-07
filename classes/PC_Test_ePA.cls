/*********************************************************************************
Class Name      : PC_Test_ePA
Description     : This test class for PC_ePA
Created By      : Deloitte
Created Date    : Jun 29, 2018
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------
Vijay Kashikar              29 Jun 2018             Initial Version
Kanteti Kishore             13-Dec-2019             [PC-5795] Reduced parameters for PC_ePA.updatePARequest method
Shishir Bansal              23-Dec-2019            Catch blocks should not be empty.
*********************************************************************************/
@isTest
public class PC_Test_ePA {
    private static final String engagementProgramName = 'engPgm';
    private static User adminUser;
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

            PC_ePA ePA = new PC_ePA();
            try {
                PC_ePA.getClientService();
            }
            catch (Exception ex) {
                PC_Utility.createExceptionLog(ex);
            }
            Case c = PC_ePA.getCase(enrollmentCase.Id);
            List<PC_ePA.HealthPlan> ret_healthPlans = PC_ePA.getHealthPlansByCaseId(enrollmentCase.Id);
            PC_Health_Plan__c ret_sHp = PC_ePA.getHealthPlan(healthPlans[0].Id);
           // PC_ePA.Drug ret_drug = PC_ePA.getDrugByCaseId(enrollmentCase.Id);
            Product2 ret_sProduct2 = PC_ePA.getProductByCaseId(enrollmentCase.Id);
            PC_ePA.Patient ret_patient = PC_ePA.getPatientByCaseId(enrollmentCase.Id);
            ret_sProduct2 = PC_ePA.getProduct(product.Id);
            PC_ePA.FormLabel ret_formLabel = PC_ePA.getFormLabels();
            ret_healthPlans =  PC_ePA.getHealthPlansByCaseId(enrollmentCase.Id);

            PC_ePA.HealthPlan ret_healthPlanLabels = PC_ePA.getHealthPlanLabels();
            Account ret_sAccount = PC_ePA.getAccount(patient.Id);
            //ret_drug = PC_ePA.convertDrug(ret_sProduct2);
            PC_ePA.HealthPlan ret_healthPlan = PC_ePA.convertHealthPlan(ret_sHp);
            PC_ePA.Patient ret_pPatient = PC_ePA.convertAccount(ret_sAccount);
            //PC_ePA.Drug ret_drugLabels = PC_ePA.getDrugLabels();

            PC_ePA.updateFormsRequest(enrollmentCase.Id, healthPlans[0].Id, ret_sProduct2.Id, new PC_ePA.FormsRequest());

            List<PC_ePA.Prescription> ret_Prescriptions = PC_ePA.getPrescriptionsByCaseId(enrollmentCase.Id);
            PC_ePA.Patient ret_patientLabels = PC_ePA.getPatientLabels();
            PC_ePA.Prescription ret_PrescriptionLabels = PC_ePA.getPrescriptionLabels();

            PC_Prescription__c prescription = PC_Test_Setup.newPrescription(ret_sProduct2.Id);
            prescription = (PC_Prescription__c) PC_Database.ins(prescription);
            // creating program coverage to cover the
            PC_Program_Coverage__c program =PC_Test_Setup.createTestProgramCoverage( enrollmentCase.Id,healthPlans[0].Id);
            program.RecordTypeId =PC_SYSTEM.recordTypeId(PC_Constants.PC_PROGRAM_COVERAGE, PC_Constants.PROGRAM_COVERAGE_PHARMACY_PLAN_RECORD_TYPE);
            program.PC_Coverage_Status__c = 'Active';
            program.PC_Coverage_Type__c = 'Pharmacy Plan Coverage';
            program.PC_Prescription__c = prescription.Id;
            program.PC_hasActivePA__c = false;
            program =(PC_Program_Coverage__c) PC_Database.ups(program);
            PC_ePA.ProgramCoverage pCoverage= PC_ePA.getProgramCoverageLabels();
            List<PC_ePA.ProgramCoverage> programCoverageList= PC_ePA.getProgramCoveragesByCaseId(enrollmentCase.Id);

            Map<String,String> ePADetails = new Map<String, String>();
            ePADetails.put('caseId',enrollmentCase.Id);
            ePADetails.put('pbmId',healthPlans[0].Id);
            ePADetails.put('prescriptionId',prescription.Id);
            ePADetails.put('programCoverageId',programCoverageList[0].Id);
            ePADetails.put('overridePrescriptionWithCoverage','true');
            ePADetails.put('formId','testformId');
            PC_ePA.updatePARequest(ePADetails, new PC_ePA.PARequest());
            //PC_ePA.updatePARequest(enrollmentCase.Id, healthPlans[0].Id, prescription.Id, programCoverageList[0].Id,'false', 'testformId', new PC_ePA.PARequest());
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