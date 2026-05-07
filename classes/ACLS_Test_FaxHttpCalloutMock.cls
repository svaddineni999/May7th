@isTest
global with sharing class ACLS_Test_FaxHttpCalloutMock implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest request) {
        // Create a fake response
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');  
        
        if(request.getEndpoint().contains('/tokens')){
           	response.setBody('{"access_token":"myAccessToken"}');
            response.setStatusCode(200);
        }else if(request.getEndpoint().contains('https://api.securedocex.com/faxes/test')){
            response.setBody(getFaxStatusResponse());
            response.setStatusCode(200);
        }else if(request.getEndpoint().contains('/faxes')){
           	response.setBody('[{"fax_id":"test","destination_fax_number":"18777845679"}]');
            response.setStatusCode(201);
        }
        
        return response; 
    }    
    
    public String getFaxStatusResponse(){
        
        ACLS_Fax_IntegrationWrapper.Transmission_data td = new ACLS_Fax_IntegrationWrapper.Transmission_data();
        td.transmission_status = 'COMPLETE';
        td.error_message = 'ERROR';
            
        ACLS_Fax_IntegrationWrapper.FaxGetStatusResponse fsr = new ACLS_Fax_IntegrationWrapper.FaxGetStatusResponse();
        fsr.fax_id = 'test';
        fsr.transmission_data = td;
        
        return json.serialize(fsr);
    }
}