/*********************************************************************************
Class Name      : PC_Test_MockHttpMapAddressGenerator
Description     : Mock class HTTP Response.
Created By      : Roxana Ivan
Created Date    : 31-May-15
Modification Log:
---------------------------------------------------------------------------------- 
Developer                   Date                   Description
-----------------------------------------------------------------------------------            
Roxana Ivan               31-May-16              Initial Version
*********************************************************************************/
/**
 * Mock class to send location coordinates in map as Http response
 */
@isTest
global class PC_Test_MockHttpMapAddressGenerator implements HttpCalloutMock {

    // Implement this interface method
    global HTTPResponse respond(HTTPRequest req) {
    	System.assertEquals('POST', req.getMethod());
    
    	// Create a fake response
    	HttpResponse res = new HttpResponse();
    	//res.setHeader('Content-Type', 'application/json');
    	res.setStatus('OK');
    	res.setBody('{"results" : [{"geometry" : { "location" : {"lat" : 45.4618504,"lng" : -73.5891043}}}]}');
    	res.setStatusCode(200);
    	return res;
    }
}