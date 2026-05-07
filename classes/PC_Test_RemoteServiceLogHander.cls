/**
 * Created by vkashikar on 7/5/2018.
 */

@IsTest
private class PC_Test_RemoteServiceLogHander {
    public static final string getURL_part = '/services/apexrest/' + PC_Constants.OrgNamespace + '/1.0/ServiceCallback/';
    @isTest static void testBehavior() {

        User adminUser;
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test');
        PC_Database.ins(adminUser);
        System.runAs(adminUser){
            Test.startTest();
            testPositive();
            testPositive2();
            testNegative();
            Test.stopTest();
        }
    }

    static void testPositive() {
        RestRequest re = new  RestRequest();
        RestResponse rp = new  RestResponse();
        re.addHeader('httpMethod', 'POST');
        re.requestURI = getURL_part;// + '?name=CMM';
        re.addParameter('name','CMM');
        String requestBodyString = '{"request":{"memo":null,"api_id":"h3m7wpz1s3u8u85f9my4","is_stale":false,"associated_requests":{"appeals":[],"renewals":[],"request_being_appealed":null,"request_being_renewed":null},"attachments":[],"attachments_included":0,"id":"RTEYNA","form_id":"generic_alt_model_18526","original_form_id":null,"patient":{"address":{"street_1":"j","street_2":null,"city":null,"state":"NJ","zip":null},"date_of_birth":"07/01/2018","email":null,"first_name":"ePA","gender":null,"last_name":"CMM","medical_record_id_number":null,"member_id":null,"middle_name":null,"pbm_member_id":null,"person_code":"","phone_number":null,"relationship_code":"0"},"pharmacy":{"ncpdpid":null,"npi":null,"name":null,"phone_number":null,"fax_number":null,"address":{"street_1":null,"street_2":null,"city":null,"state":null,"zip":null}},"payer":{"form_search_text":null,"bin":null,"pcn":null,"group_id":null,"medical_benefit_name":"","drug_benefit_name":null,"info_source_id":null},"prescriber":{"address":{"street_1":null,"street_2":null,"city":null,"state":"0","zip":null},"clinic_name":null,"dea_number":null,"display_name":"","fax_number":null,"first_name":"","last_name":"","npi":null,"phone_number":null,"specialty":null},"prescription":{"date_of_service":null,"days_supply":"","dispense_as_written":null,"drug_id":"189579","frequency":null,"name":"Repatha SureClick 140MG/ML solutions","ndc":"55513076001","order_id":null,"prescription_reference":null,"quantity":"","quantity_unit_of_measure":null,"rationale":null,"refills":null,"strength":null},"enumerated_fields":{"icd9_0":null,"icd9_1":null,"icd9_2":null,"icd10_0":null,"icd10_1":null,"icd10_2":null,"failed_med_0":null,"failed_med_1":null,"failed_med_2":null,"failed_med_3":null,"failed_med_4":null,"failed_med_5":null,"failed_med_6":null,"failed_med_7":null,"failed_med_8":null,"failed_med_9":null},"is_epa":false,"href":"https://master-api.integration.covermymeds.com/requests/RTEYNA","plan_outcome":null,"authorization_period":{"effective_date":null,"expiration_date":null},"workflow_status":"New","thumbnail_urls":["https://master-api.integration.covermymeds.com/forms/pdf/thumbs/200/generic_alt_model_18526.jpg"],"pdf_url":"https://master-cmm.integration.covermymeds.com/request/send/RTEYNA","html_url":"https://master-cmm.integration.covermymeds.com/request/view/RTEYNA","created_at":"2018-07-05T11:22:50Z","state":"NJ","urgent":false,"response_code":null,"response_from_plan":null,"is_appeal":false,"is_renewal":false,"deadline_for_reply":null,"tokens":[{"id":"9ghlwvz44eh16mzqmp79","request_id":"RTEYNA","href":"https://master-api.integration.covermymeds.com/requests/tokens/9ghlwvz44eh16mzqmp79","html_url":"https://master-cmm.integration.covermymeds.com/request/view/RTEYNA?token_id=9ghlwvz44eh16mzqmp79","pdf_url":"https://master-cmm.integration.covermymeds.com/request/send/RTEYNA?token_id=9ghlwvz44eh16mzqmp79","thumbnail_url":"https://master-api.integration.covermymeds.com/forms/pdf/thumbs/200/generic_alt_model_18526.jpg"}],"events":[{"time":"2018-07-05T11:22:50Z","type":"REQUEST_CREATED","remote_user":{},"subtype":null}]}}';
        re.requestBody = Blob.valueOf(requestBodyString);
        RestContext.request = re;
        RestContext.response = rp;
        PC_RemoteServiceLogHandler.doPost();
        if(rp.statusCode == 201)
        {
            System.assert(true);
            //system.debug(rp.responseBody.toString());
        }
        else
        {
            system.debug(rp.responseBody.toString());
            System.assert(false);
        }
    }
    static void testPositive2() {
        RestRequest re = new  RestRequest();
        RestResponse rp = new  RestResponse();
        re.addHeader('httpMethod', 'POST');
        re.requestURI = getURL_part;// + '?name=CMM';
        re.addParameter('name','CMM');
        re.requestBody = Blob.valueOf('');
        RestContext.request = re;
        RestContext.response = rp;
        PC_RemoteServiceLogHandler.doPost();
        if(rp.statusCode == 201)
        {
            System.assert(true);
            //system.debug(rp.responseBody.toString());
        }
        else
        {
            system.debug(rp.responseBody.toString());
            System.assert(false);
        }
    }
    static void testNegative() {
        RestRequest re = new  RestRequest();
        RestResponse rp = new  RestResponse();
        re.addHeader('httpMethod', 'POST');
        re.requestURI = getURL_part;// + '?name=CMM';
        //re.addParameter('name','CMM');
        re.requestBody = Blob.valueOf('test');
        RestContext.request = re;
        RestContext.response = rp;
        PC_RemoteServiceLogHandler.doPost();
        if(rp.statusCode == 201)
        {
            System.assert(false);
            //system.debug(rp.responseBody.toString());
        }
        else
        {
            //system.debug(rp.responseBody.toString());
            System.assert(true);
        }
    }
}