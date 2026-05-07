/*********************************************************************************************************
Class Name      : PC_Twilio_MockHttpResponseGenerator
Description     : Mock Response Generator Class for Twilio's Callout.
Created By      : Chetna Mohapatra
Created Date    : Nov 3, 2021
Modification Log:
-----------------------------------------------------------------------------------------------------
Developer                   Date                           Description
-----------------------------------------------------------------------------------------------------
Chetna Mohapatra          Nov 3, 2021                     Initial Version
*********************************************************************************************************/
 @isTest
 public class PC_Twilio_MockHttpResponseGenerator implements HttpCalloutMock {
     // Implement this interface method
     public HTTPResponse respond(HTTPRequest req) {
         //send a mock response for a specific endpoint and method.
         System.assertEquals('POST', req.getMethod());
         // Create a fake response
         HttpResponse res = new HttpResponse();
         res.setHeader('Content-Type', 'application/json');
         String endPoint = req.getEndpoint();
         if(endpoint.containsIgnoreCase('PC_Twilio') && req.getMethod() == 'POST'){
             String responseString = '{"account_sid": "AC13769fb83bffeab7c25225b4c1371a99","to": "+919439594358","from": "+17742737543","body": "MockTwilioCallout","status": "queued","direction": "outbound-api"}';
             res.setBody(responseString);
             res.setStatusCode(200);
         }
         return res;
     }
 }