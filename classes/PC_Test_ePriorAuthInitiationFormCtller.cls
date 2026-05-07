/**
 * Class Name      : PC_Test_ePriorAuthInitiationFormCtller
 * Created By      : Vijay Kashikar
 * @Created Date   : May 19, 2018
 * Modification Log:
 * ----------------------------------------------------------------------------------
 * Developer              Date                   	Description
 * -----------------------------------------------------------------------------------
 * Vijay Kashikar	  25-May-2018			Initial Version
 * Shishir Bansal     24-Oct-2018           Created Test setup for adding sample data for the test class
 *                                          and getting the mock response
 * Shishir Bansal     05-Dec-2019           [PC-5787] Added null check before DML operation
 * Kanteti Kishore    13-Dec-2019           [PC-5795] Reduced parameters for PC_ePriorAuthInitiationFormController.submitPA method
 * Shishir Bansal        Dec-16-2019       [PC-5841] Catch blocks should not be empty.
 */
@IsTest
private class PC_Test_ePriorAuthInitiationFormCtller {
    private static User adminUser;
    private static final String engagementProgramName = 'engPgm';
    @isTest static void run() {
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test100');
        PC_Database.ins(adminUser);
        System.runAs(adminUser) {
            Id manufactureAccountRecordTypeId = PC_System.recordTypeId('Account', PC_Constants.MANUFACTURER_RECORD_TYPE);
            List<Account> manufacturers =[Select Id,Name,PC_First_Name__c, PC_Last_Name__c, Fax, AnnualRevenue,recordTypeId From Account where recordTypeId =:manufactureAccountRecordTypeId];
            system.assert(manufacturers.size()>0);
            Account manufacturer = manufacturers[0];

            Id patientAccountRecordTypeId = PC_SYSTEM.recordTypeId('Account', PC_Constants.PATIENT_RECORD_TYPE);
            Account patient = [Select Id, Name, PC_First_Name__c, PC_Last_Name__c, RecordTypeId From Account where RecordTypeId =: patientAccountRecordTypeId limit 1];
            system.assertNotEquals(patient.Id, null);

            Id physicianAccountRecordTypeId = PC_System.recordTypeId('Account', PC_Constants.PHYSICIAN_RECORD_TYPE);
            List<Account> physicians = [Select Id, Name, PC_First_Name__c, PC_Last_Name__c, Fax, AnnualRevenue, recordTypeId From Account where recordTypeId =: physicianAccountRecordTypeId];
            system.assertNotEquals(physicians[0].Id, null);

            PC_Engagement_Program__c engagementProgram = [Select Id,Name, PC_Manufacturer__c,PC_Program_Code__c from PC_Engagement_Program__c where PC_Manufacturer__c =: manufacturer.Id limit 1];
            system.assertNotEquals(engagementProgram.Id, Null);

            Product2 product = [Select Id, PC_NDC__c, ProductCode, PC_Manufacturer__c, Name from  Product2 where PC_Manufacturer__c=: manufacturer.Id limit 1];
            system.assertNotEquals(product.Id, Null);

            PC_Engagement_Program_Product__c engagement_program_product = [Select Id, PC_Product__c, PC_Engagement_Program__c from PC_Engagement_Program_Product__c where PC_Product__c =: product.id limit 1];
            system.assertNotEquals(engagement_program_product.Id, Null);


            Case programCase =[Select Id, AccountId, recordTypeId, PC_Physician__c, PC_Engagement_Program__c, PC_Program_Product__c from case where PC_Program_Product__c =:engagement_program_product.Id];
            system.assertNotEquals(programCase.Id, Null);

            Id patinetAccountRecordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.PC_HEALTH_PLAN, PC_Constants.HEALTH_PLAN_PHARMACY_PLAN_RECORD_TYPE);
            List<PC_Health_Plan__c> healthPlans = [Select Id, Patient__c, PC_Cardholder_Relationship_to_Patient__c, RecordTypeId, PC_Rx_Bin__c, PC_Rx_PCN__c from PC_Health_Plan__c where RecordTypeId =: patinetAccountRecordTypeId];
            system.assertNotEquals(healthPlans[0].Id, Null);


            PC_Prescription__c prescription =[Select Id, PC_Patient_Account__c, PC_Program_Case__c from PC_Prescription__c where PC_Program_Case__c =:programCase.Id limit 1];
            system.assertNotEquals(prescription.Id, Null);

            Id pharmacyAccountRecordTypeId = PC_SYSTEM.recordTypeId('Account', PC_Constants.PHARMACY_RECORD_TYPE);
            List<Account> pharmacies =[Select Id, Name, PC_First_Name__c, PC_Last_Name__c, Fax, AnnualRevenue, recordTypeId from Account where recordTypeId=:pharmacyAccountRecordTypeId];
            system.assertNotEquals(pharmacies[0].Id, Null);

            PC_Program_Coverage__c programCoverage = [Select id, Name, RecordTypeId, PC_Coverage_Status__c, PC_Prescription__c, PC_Program__c from PC_Program_Coverage__c limit 1 ];
            system.assertNotEquals(programCoverage.Id, Null);
            Test.StartTest();

            try {
                PC_ePriorAuthInitiationFormController.getData(programCase.Id, 'false');
                PC_ePriorAuthInitiationFormController.getData(programCase.Id, 'true');
            } catch (Exception ex) {
                system.assert(false);
            }
            try {
                Test.setMock(HttpCalloutMock.class, new PC_CMM_MockHttpResponseGenerator());
                PC_ePA.FormsResponse response = new PC_ePA.FormsResponse();
                response = PC_ePriorAuthInitiationFormController.searchPAForms(programCase.Id, healthPlans[0].id, product.Id);
                system.debug('response-->' + response.forms[0]);
                id programCoverageId = null;

                Map<String,String> ePADetails = new Map<String, String>();
                ePADetails.put('caseId',programCase.Id);
                ePADetails.put('pbmId',healthPlans[0].Id);
                ePADetails.put('prescriptionId',null);
                ePADetails.put('programCoverageId',programCoverage.Id);
                ePADetails.put('overridePrescriptionWithCoverage','true');
                ePADetails.put('formId',String.valueOf(response.forms[0].Id));

                PC_ePA.PAResponse  postProgramCoverageResponse= PC_ePriorAuthInitiationFormController.submitPA(ePADetails);
                system.debug('postProgramCoverageResponse -->'+postProgramCoverageResponse);

                Map<String,String> ePADetails1 = new Map<String, String>();
                ePADetails1.put('caseId',programCase.Id);
                ePADetails1.put('pbmId',healthPlans[0].Id);
                ePADetails1.put('prescriptionId',prescription.Id);
                ePADetails1.put('programCoverageId',null);
                ePADetails1.put('overridePrescriptionWithCoverage','false');
                ePADetails1.put('formId',String.valueOf(response.forms[0].Id));

                PC_ePA.PAResponse  postPrescriptionResponse= PC_ePriorAuthInitiationFormController.submitPA(ePADetails1);
                system.debug('postPrescriptionResponse -->'+postPrescriptionResponse);
            } catch (Exception ex) {
                PC_Utility.createExceptionLog(ex);
            }
           /* try {

                //PC_ePriorAuthInitiationFormController.submitPA(programCase.Id, healthPlans[0].id,prescription.Id,programCoverage--id will be here , false, formId);



            } catch (Exception ex) {
                //PC_Utility.logAndThrowException(ex);
            }*/
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

        /* creating test data and custom setting . Note the records created here won't be saved in salesforce */


        PC_System_Settings__c obj = new PC_System_Settings__c(PC_ePA_Class__c = 'PC_PriorAuthClient_CMM');
        if(obj !=null) {
            insert obj;
        }

        PC_Integration_Settings__c cmmSettings =  new PC_Integration_Settings__c();
        cmmSettings.Name = PC_Constants.CMM_CREDENTIALS;
        cmmSettings.endpoint_Url__c = 'https://master-api.integration.covermymeds.com';
        cmmSettings.password__c = 'mjpb9o62uryc5ibxz3w-39paz4ua2vnux6ie8hse';
        cmmSettings.username__c='h3m7wpz1s3u8u85f9my4';
        if(cmmSettings !=null) {
            insert cmmSettings;
        }

        List<Account> manufacturers = PC_Test_Setup.createAccounts('testManufacturer', 1, 'Manufacturer');
        manufacturers = (List<Account>) PC_Database.ups(manufacturers);


        Account patient = PC_Test_Setup.createPatient('testpatient');
        patient.PC_Date_of_Birth__c = Date.today();
        patient.PC_Gender__c = 'Male';
        patient = (Account) PC_Database.ins(patient, false);
        createAddress(patient.Id);


        List<Account> physicians = PC_Test_Setup.createAccounts('PHY', 1, PC_Constants.PHYSICIAN_RECORD_TYPE);
        physicians[0].PC_NPI__c = '1306200621';
        physicians = PC_Database.ins(physicians);
        createAddress(physicians[0].Id);



        PC_Engagement_Program__c engagementProgram = PC_Test_Setup.createEngagementProgram(engagementProgramName, manufacturers[0].Id);
        engagementProgram.PC_Program_Code__c = engagementProgramName;
        engagementProgram = (PC_Engagement_Program__c) PC_Database.ups(engagementProgram);

        Product2 product = new Product2();
        product.PC_NDC__c = '24542131';
        product.ProductCode = 'Ambien';
        product.PC_Manufacturer__c = manufacturers[0].Id;
        product.Name = 'Ambien 10mg Tablet';
        product = (Product2) PC_Database.ins(product);


        PC_Engagement_Program_Product__c engagement_program_product = new PC_Engagement_Program_Product__c();
        engagement_program_product.PC_Product__c = product.Id;
        engagement_program_product.PC_Engagement_Program__c = engagementProgram.Id;
        engagement_program_product = (PC_Engagement_Program_Product__c) PC_Database.ins(engagement_program_product);


        Case programCase = PC_Test_Setup.createProgram(patient);
        //programCase.AccountId = patient.Id;
        programCase.PC_Physician__c = physicians[0].Id;
        programCase.PC_Engagement_Program__c = engagementProgram.Id;
        programCase.PC_Program_Product__c = engagement_program_product.Id;
        programCase = (Case) PC_Database.ups(programCase);

        List<Account> patients = new List<Account>();
        patients.add(patient);


        List<PC_Health_Plan__c> healthPlans = PC_Test_Setup.createHealthPlans(patients, 1);
        healthPlans[0].Patient__c = patient.Id;
        healthPlans[0].RecordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.PC_HEALTH_PLAN, PC_Constants.HEALTH_PLAN_PHARMACY_PLAN_RECORD_TYPE);
        // insert all health plans
        healthPlans[0].PC_Rx_Bin__c ='610014';
        healthPlans[0].PC_Rx_PCN__c='A4';
        PC_Database.ins(healthPlans);


        PC_Prescription__c prescription = new PC_Prescription__c();
        prescription.PC_Patient_Account__c = patient.Id;
        prescription.PC_Program_Case__c = programCase.Id;
        PC_Database.ins(prescription);


        List<Account> pharmacies = PC_Test_Setup.createAccounts('pha', 1, PC_Constants.PHARMACY_RECORD_TYPE);
        pharmacies = PC_Database.ins(pharmacies);

        PC_Program_Coverage__c programCoverage = PC_Test_Setup.createProgramCoverage(programCase.id);
        programCoverage.RecordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.PC_PROGRAM_COVERAGE,  PC_Constants.PROGRAM_COVERAGE_PHARMACY_PLAN_RECORD_TYPE);

        programCoverage.PC_Coverage_Status__c = PC_Constants.ACTIVE;
        programCoverage.PC_Prescription__c = prescription.id;
        PC_Database.ins(programCoverage);




    }
}