/*********************************************************************************************************
Class Name      : PC_CMM_MockHttpResponseGenerator
Description     : Mock Implementation class to test CMM related functionality
Created By      : Vijay Kashikar
Created Date    : July 02, 2018
Modification Log:
-----------------------------------------------------------------------------------------------------
Developer                   Date                           Description
-----------------------------------------------------------------------------------------------------
Vijay Kashikar               Jul 02, 2018              Initial Version
Shishir Bansal               Oct 22,2018               Created method for POST to submit the form to CMM
*********************************************************************************************************/


@IsTest
public class PC_CMM_MockHttpResponseGenerator implements HttpCalloutMock{
    public HTTPResponse respond(HTTPRequest req) {
        system.debug('req-->'+req);
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(500);
        String endPoint = req.getEndpoint();
        system.debug('end point = ' + endPoint);
        PC_UBC_Utility utility = new PC_UBC_Utility();
        if((endPoint.containsIgnoreCase('forms?v=1')) && req.getMethod() == 'GET') {
            String responseString = '{"forms":[{"id":31622,"href":"https://master-api.integration.covermymeds.com/forms/31622","name":"express_scripts_general_1","description":"Express Scripts General Request Form","directions":"Prior Authorization Form for General Medication Requests. This form can be used for Medicare and non-Medicare requests (Use for Members with an Express Scripts logo on their ID card)","request_form_id":"express_scripts_general_1_31622","thumbnail_url":"https://master-api.integration.covermymeds.com/forms/pdf/thumbs/90/express_scripts_general_1_31622.jpg","preview_url":"https://master-api.integration.covermymeds.com/forms/pdf/thumbs/270/express_scripts_general_1_31622.jpg","is_epa":false,"contact_name":"Express Scripts","contact_phone":"(800) 417-8164","contact_fax":"(800) 357-9577","score":14.0,"active":true,"is_enrollment":false}]}';
            res.setBody(responseString);
            res.setStatusCode(200);
        }

            
        else if( (endPoint.containsIgnoreCase('forms?v=1')) && req.getMethod() == 'POST'){
            String responseString = '{"request":{"memo":null,"api_id":"h3m7wpz1s3u8u85f9my4","is_stale":false,"associated_requests":{"appeals":[],"renewals":[],"request_being_appealed":null,"request_being_renewed":null},"attachments":[],"attachments_included":0,"id":"X4LRJ2","form_id":"express_scripts_general_1_31622","original_form_id":null,"patient":{"address":{"street_1":"street1","street_2":"stree2","city":"New Jersey","state":"MA","zip":"07039"},"date_of_birth":"12/25/1986","email":"test@test.com","first_name":"Prachi","gender":"f","last_name":"Nandgaonkar","medical_record_id_number":null,"member_id":null,"middle_name":null,"pbm_member_id":null,"person_code":"","phone_number":"99999999","relationship_code":"0"},"pharmacy":{"ncpdpid":null,"npi":null,"name":null,"phone_number":null,"fax_number":null,"address":{"street_1":null,"street_2":null,"city":null,"state":null,"zip":null}},"payer":{"form_search_text":"610014 A4 9XS000001486019","bin":"610014","pcn":"A4","group_id":"9XS000001486019","medical_benefit_name":"","drug_benefit_name":"EXPRESS SCRIPTS","info_source_id":null},"prescriber":{"address":{"street_1":"23","street_2":"24","city":"EDWARDSVILLE","state":"MA","zip":"62025"},"clinic_name":null,"dea_number":null,"display_name":"Parkas Wendy","fax_number":null,"first_name":"Parkas","last_name":"Wendy","npi":"1306200621","phone_number":"9999999999","specialty":null},"prescription":{"date_of_service":null,"days_supply":"","dispense_as_written":null,"drug_id":"184000","frequency":"12","name":"Entyvio 300MG solutions","ndc":"64764030020","order_id":null,"prescription_reference":null,"quantity":"20","quantity_unit_of_measure":"C48480","rationale":null,"refills":null,"strength":null},"enumerated_fields":{"icd9_0":null,"icd9_1":null,"icd9_2":null,"icd10_0":null,"icd10_1":null,"icd10_2":null,"failed_med_0":null,"failed_med_1":null,"failed_med_2":null,"failed_med_3":null,"failed_med_4":null,"failed_med_5":null,"failed_med_6":null,"failed_med_7":null,"failed_med_8":null,"failed_med_9":null},"is_epa":false,"href":"https://master-api.integration.covermymeds.com/requests/X4LRJ2","plan_outcome":null,"authorization_period":{"effective_date":null,"expiration_date":null},"workflow_status":"New","thumbnail_urls":["https://master-api.integration.covermymeds.com/forms/pdf/thumbs/200/express_scripts_general_1_31622.jpg"],"pdf_url":"https://master-cmm.integration.covermymeds.com/request/send/X4LRJ2","html_url":"https://master-cmm.integration.covermymeds.com/request/view/X4LRJ2","created_at":"2018-10-23T04:17:27Z","state":"MA","urgent":false,"response_code":null,"response_from_plan":null,"is_appeal":false,"is_renewal":false,"deadline_for_reply":null,"tokens":[{"id":"6dsqw6jlww48amamhaz6","request_id":"X4LRJ2","href":"https://master-api.integration.covermymeds.com/requests/tokens/6dsqw6jlww48amamhaz6","html_url":"https://master-cmm.integration.covermymeds.com/request/view/X4LRJ2?token_id=6dsqw6jlww48amamhaz6","pdf_url":"https://master-cmm.integration.covermymeds.com/request/send/X4LRJ2?token_id=6dsqw6jlww48amamhaz6","thumbnail_url":"https://master-api.integration.covermymeds.com/forms/pdf/thumbs/200/express_scripts_general_1_31622.jpg"}],"events":[{"time":"2018-10-23T08:17:27Z","type":"REQUEST_CREATED","remote_user":{},"subtype":null}]}}';
            res.setBody(responseString);
            res.setStatusCode(201);
        }
        system.debug('res-->'+res);
        return res;
    }
}