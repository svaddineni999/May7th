/*********************************************************************************************************
Class Name      : PC_Infinitus_MockHttpResponseGenerator
Description     : Mock Response Generator Class for Infinitus Http Request
Created By      : Chetna Mohapatra
Created Date    : April 21, 2021
Modification Log:
-----------------------------------------------------------------------------------------------------
Developer                   Date                           Description
-----------------------------------------------------------------------------------------------------
Chetna Mohapatra         April 21, 2021                  Initial Version
*********************************************************************************************************/
@isTest
public class PC_Infinitus_MockHttpResponseGenerator implements HttpCalloutMock {
    // Implement this interface method
    public HTTPResponse respond(HTTPRequest req) {
        //send a mock response for a specific endpoint and method.
        System.debug('Endpoint--' +req.getEndpoint());
        System.assertEquals('POST', req.getMethod());
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        String endPoint = req.getEndpoint();
        if(endpoint.containsIgnoreCase('Infinitus') && req.getMethod() == 'POST'){
            String responseString = '{"data":[{"customerId":"a1P2E000009TEkEUAW","error":null,"programId":"","taskId":"8efb778e-0efe-4fe5-a3f0-b2f35687d090"}]}';
            res.setBody(responseString);
            res.setStatusCode(200);
        }
        return res;
    }
}