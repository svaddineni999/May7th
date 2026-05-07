@isTest
global class ACLS_SMSHttpCalloutMock implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest request) {
        // Create a fake response
        HttpResponse response = new HttpResponse();
         response.setHeader('Content-Type', 'application/json');
        response.setBody('{"access_token":"myAccessToken"}');
        response.setStatusCode(200);
        return response; 
    }
}