/*********************************************************************************
Class Name      : PC_Test_CMM
Description     : This test class for PC_ePA
Created By      : Deloitte
Created Date    : Jun 29, 2018
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------
Vijay Kashikar              29 Jun 2018             Initial Version
Shishir Bansal              23 Oct 2018             Created test setup and added all the relevant data needed for
                                                    Rest Mockup Services-Post and Get method

*********************************************************************************/
@IsTest
private class PC_Test_PriorAuthClient_CMM {
    private static final String engagementProgramName = 'engPgm';
    private static User adminUser;
    private static User integrationUser;
    @isTest static void run() {
        adminUser = PC_Test_Setup.createUser('System Administrator', 'pcuser@test100.com', 'test100');
        PC_Database.ins(adminUser);
        System.runAs(adminUser) {

            Test.StartTest();

            List<Account> manufacturers; //= PC_Test_Setup.createAccounts('testManufacturer', 1, 'Manufacturer');
            Id manufactureAccountRecordTypeId = PC_System.recordTypeId('Account', PC_Constants.MANUFACTURER_RECORD_TYPE);
            manufacturers =[Select Id,name,PC_First_Name__c, PC_Last_Name__c, Fax, AnnualRevenue, recordTypeId from Account where recordTypeId =: manufactureAccountRecordTypeId];
            Account manufacturer = manufacturers[0];
            system.assertNotEquals(manufacturers[0].Id, null);

            Id patientAccountRecordTypeId = PC_SYSTEM.recordTypeId('Account', PC_Constants.PATIENT_RECORD_TYPE);
            Account  patient = [Select Id, Name, PC_First_Name__c, PC_Last_Name__c, RecordTypeId from Account where RecordTypeId = :patientAccountRecordTypeId LIMIT 1];
            system.assertNotEquals(patient.Id, null);


            List<Account> physicians;
            Id physicianAccountRecordTypeId = PC_System.recordTypeId('Account', PC_Constants.PHYSICIAN_RECORD_TYPE);
            physicians= [Select Id, Name,PC_First_Name__c,PC_Last_Name__c, recordTypeId from Account where recordTypeId =: physicianAccountRecordTypeId];
            system.assertNotEquals(physicians[0].Id, null);


            // check if engagement program is created
            PC_Engagement_Program__c engagementProgram = [Select Id,Name, PC_Manufacturer__c, PC_Program_Code__c from PC_Engagement_Program__c where PC_Manufacturer__c=:manufacturer.Id limit 1];
            system.assertNotEquals(engagementProgram.Id, Null);

            Product2 product = [Select id,ProductCode, PC_Manufacturer__c,  Name, PC_NDC__c from Product2 where PC_Manufacturer__c =:manufacturer.Id limit 1];
            system.assertNotEquals(product.Id, Null);

            PC_Engagement_Program_Product__c engagement_program_product = [Select Id,PC_Product__c, PC_Engagement_Program__c from PC_Engagement_Program_Product__c where  PC_Product__c =:product.id limit 1];
            system.assertNotEquals(engagement_program_product.Id, Null);

            Case enrollmentCase= [Select id,AccountId, PC_Physician__c, PC_Program_Product__c from Case Limit 1];
            system.assertNotEquals(enrollmentCase.Id, Null);

            List<PC_Health_Plan__c> healthPlans = [Select Id, Patient__c, PC_Rx_Bin__c, PC_Group_name__c, RecordTypeId from PC_Health_Plan__c Limit 1];
            system.assertNotEquals(healthPlans[0].Id, Null);

            PC_ePA ePA = new PC_ePA();
            try {
                PC_ePA.getClientService();
            }
            catch (Exception ex) {
                system.debug(true);
            }

            Test.setMock(HttpCalloutMock.class, new PC_CMM_MockHttpResponseGenerator());

            try {

                PC_PriorAuthClient_CMM cmm = new PC_PriorAuthClient_CMM();
                PC_ePA.FormsRequest ret_FormsRequest = new PC_ePA.FormsRequest();
                PC_ePA.updateFormsRequest(enrollmentCase.Id, healthPlans[0].Id, product.Id, ret_FormsRequest);
                system.debug('ret_FormsRequest = ');
                system.debug(ret_FormsRequest);
                PC_ePA.FormsResponse formResponse = cmm.searchForms(ret_FormsRequest);
                system.debug('formResponse -->'+formResponse.forms);
                System.assertEquals('Express Scripts General Request Form',formResponse.forms[0].description,'The status code is not 200.');
                System.assertEquals(true,formResponse.forms[0].active,'The status code is not 200.');



                cmm.createSearchFormsRequest();
                cmm.submitPA();
                String createPAResponseJson = '{"request":{"memo":null,"api_id":"h3m7wpz1s3u8u85f9my4","is_stale":false,"associated_requests":{"appeals":[],"renewals":[],"request_being_appealed":null,"request_being_renewed":null},"attachments":[],"attachments_included":0,"id":"RTEYNA","form_id":"generic_alt_model_18526","original_form_id":null,"patient":{"address":{"street_1":"j","street_2":null,"city":null,"state":"NJ","zip":null},"date_of_birth":"07/01/2018","email":null,"first_name":"ePA","gender":null,"last_name":"CMM","medical_record_id_number":null,"member_id":null,"middle_name":null,"pbm_member_id":null,"person_code":"","phone_number":null,"relationship_code":"0"},"pharmacy":{"ncpdpid":null,"npi":null,"name":null,"phone_number":null,"fax_number":null,"address":{"street_1":null,"street_2":null,"city":null,"state":null,"zip":null}},"payer":{"form_search_text":null,"bin":null,"pcn":null,"group_id":null,"medical_benefit_name":"","drug_benefit_name":null,"info_source_id":null},"prescriber":{"address":{"street_1":null,"street_2":null,"city":null,"state":"0","zip":null},"clinic_name":null,"dea_number":null,"display_name":"","fax_number":null,"first_name":"","last_name":"","npi":null,"phone_number":null,"specialty":null},"prescription":{"date_of_service":null,"days_supply":"","dispense_as_written":null,"drug_id":"189579","frequency":null,"name":"Repatha SureClick 140MG/ML solutions","ndc":"55513076001","order_id":null,"prescription_reference":null,"quantity":"","quantity_unit_of_measure":null,"rationale":null,"refills":null,"strength":null},"enumerated_fields":{"icd9_0":null,"icd9_1":null,"icd9_2":null,"icd10_0":null,"icd10_1":null,"icd10_2":null,"failed_med_0":null,"failed_med_1":null,"failed_med_2":null,"failed_med_3":null,"failed_med_4":null,"failed_med_5":null,"failed_med_6":null,"failed_med_7":null,"failed_med_8":null,"failed_med_9":null},"is_epa":false,"href":"https://master-api.integration.covermymeds.com/requests/RTEYNA","plan_outcome":null,"authorization_period":{"effective_date":null,"expiration_date":null},"workflow_status":"New","thumbnail_urls":["https://master-api.integration.covermymeds.com/forms/pdf/thumbs/200/generic_alt_model_18526.jpg"],"pdf_url":"https://master-cmm.integration.covermymeds.com/request/send/RTEYNA","html_url":"https://master-cmm.integration.covermymeds.com/request/view/RTEYNA","created_at":"2018-07-05T11:22:50Z","state":"NJ","urgent":false,"response_code":null,"response_from_plan":null,"is_appeal":false,"is_renewal":false,"deadline_for_reply":null,"tokens":[{"id":"9ghlwvz44eh16mzqmp79","request_id":"RTEYNA","href":"https://master-api.integration.covermymeds.com/requests/tokens/9ghlwvz44eh16mzqmp79","html_url":"https://master-cmm.integration.covermymeds.com/request/view/RTEYNA?token_id=9ghlwvz44eh16mzqmp79","pdf_url":"https://master-cmm.integration.covermymeds.com/request/send/RTEYNA?token_id=9ghlwvz44eh16mzqmp79","thumbnail_url":"https://master-api.integration.covermymeds.com/forms/pdf/thumbs/200/generic_alt_model_18526.jpg"}],"events":[{"time":"2018-07-05T11:22:50Z","type":"REQUEST_CREATED","remote_user":{},"subtype":null}]}}';



                String formJson=		'{"forms":[{"id":31622,"href":"https://master-api.integration.covermymeds.com/forms/31622","name":"express_scripts_general_1","description":"Express Scripts General Request Form","directions":"Prior Authorization Form for General Medication Requests. This form can be used for Medicare and non-Medicare requests (Use for Members with an Express Scripts logo on their ID card)","request_form_id":"express_scripts_general_1_31622","thumbnail_url":"https://master-api.integration.covermymeds.com/forms/pdf/thumbs/90/express_scripts_general_1_31622.jpg","preview_url":"https://master-api.integration.covermymeds.com/forms/pdf/thumbs/270/express_scripts_general_1_31622.jpg","is_epa":false,"contact_name":"Express Scripts","contact_phone":"(800) 417-8164","contact_fax":"(800) 357-9577","score":14.0,"active":true,"is_enrollment":false}]}';
                PC_PriorAuthClient_CMM.FormsResponse formsResponse = (PC_PriorAuthClient_CMM.FormsResponse) JSON.deserialize(formJson, PC_PriorAuthClient_CMM.FormsResponse.Class);
                PC_ePA.FormsResponse eFormsResponse = PC_PriorAuthClient_CMM.convertFormsResponse(formsResponse);

                PC_PriorAuthClient_CMM.PAResponse createPAResponse = (PC_PriorAuthClient_CMM.PAResponse) JSON.deserialize(createPAResponseJson, PC_PriorAuthClient_CMM.PAResponse.Class);
                PC_ePA.PAResponse paResponse = PC_PriorAuthClient_CMM.convertCretePAResponse(createPAResponse);



            }
            catch(Exception ex) {
                System.debug(ex.getMessage());
                system.debug(ex.getStackTraceString());
                system.debug(ex.getLineNumber());

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


    @testSetup static void setup() {

        /* inserting custom settings and other records . The data created here won't be saved in salesforce and
        is for only test class*/

        PC_System_Settings__c cSetting = new PC_System_Settings__c();
        cSetting.Name = 'PC_PriorAuthClient_CMM';
        PC_Database.ins(cSetting);

        PC_Integration_Settings__c cIntegration_settings = new PC_Integration_Settings__c();
        cIntegration_settings.Name = 'PC_PriorAuthClient_CMM';
        cIntegration_settings.endpoint_Url__c = 'https://master-api.integration.covermymeds.com';
        cIntegration_settings.username__c = 'h3m7wpz1s3u8u85f9my4';
        cIntegration_settings.password__c = 'mjpb9o62uryc5ibxz3w-39paz4ua2vnux6ie8hse';
        PC_Database.ins(cIntegration_settings);




        List<Account> manufacturers = PC_Test_Setup.createAccounts('testManufacturer', 1, 'Manufacturer');
        manufacturers = (List<Account>) PC_Database.ups(manufacturers);



        List<Account> physicians = PC_Test_Setup.createAccounts('PHY',1,PC_Constants.PHYSICIAN_RECORD_TYPE);
        physicians[0].PC_NPI__c = '111111';
        physicians = PC_Database.ins(physicians);
        createAddress(physicians[0].Id);



        Account  patient = PC_Test_Setup.createPatient('testpatient');
        patient.PC_Date_of_Birth__c=Date.today() -365;
        patient.PC_Gender__c='Male';

        patient = (Account)PC_Database.ins(patient, false);
        createAddress(patient.Id);



        PC_Engagement_Program__c engagementProgram = PC_Test_Setup.createEngagementProgram(engagementProgramName, manufacturers[0].Id);
        engagementProgram.PC_Program_Code__c = engagementProgramName;
        engagementProgram = (PC_Engagement_Program__c) PC_Database.ups(engagementProgram);


        Product2 product = new Product2();
        //product.PC_NDC__c = 'ndc';
        product.ProductCode = 'pc';
        product.PC_Manufacturer__c = manufacturers[0].Id;
        product.Name = 'n';
        product.PC_NDC__c = 'NDC';
        product = (Product2) PC_Database.ins(product);


        PC_Engagement_Program_Product__c engagement_program_product = new PC_Engagement_Program_Product__c();
        engagement_program_product.PC_Product__c = product.Id;
        engagement_program_product.PC_Engagement_Program__c = engagementProgram.Id;
        engagement_program_product = (PC_Engagement_Program_Product__c) PC_Database.ins(engagement_program_product);

        Case enrollmentCase = PC_Test_Setup.createProgram(patient);
        enrollmentCase.PC_Engagement_Program__c = engagementProgram.Id;
        enrollmentCase.AccountId = patient.Id;
        enrollmentCase.PC_Physician__c = physicians[0].Id;
        enrollmentCase.PC_Program_Product__c = engagement_program_product.Id;
        enrollmentCase = (Case) PC_Database.ups(enrollmentCase);

        List<Account> patients = new List<Account>();
        patients.add(patient);



        List<PC_Health_Plan__c> healthPlans = PC_Test_Setup.createHealthPlans(patients, 1);
        healthPlans[0].Patient__c = patient.Id;
        healthPlans[0].PC_Rx_Bin__c = 'test';
        healthPlans[0].PC_Group_name__c = 'testGroup';
        healthPlans[0].RecordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.PC_HEALTH_PLAN, PC_Constants.HEALTH_PLAN_PHARMACY_PLAN_RECORD_TYPE);
        // insert all health plans
        SYSTEM.debug('healthPlans -->'+healthPlans[0]);
        PC_Database.ins(healthPlans);


    }
}