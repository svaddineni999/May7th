/*********************************************************************************
Class Name      : PC_Test_EmailWebService
Description     : Test class for PC_EmailServiceRequest
Created By      : Deloitte               
Created Date    : June 03, 2016
Modification Log:
---------------------------------------------------------------------------------- 
Developer              Date                   Description
-----------------------------------------------------------------------------------            
Roxana Ivan         June 03, 2016            Initial Version
Tetiana Danylyshyn  June 08, 2016            Finished the implementation
*********************************************************************************/
@isTest
private class PC_Test_EmailWebService {
    
    /*********************************************************************************
    Method Name    : testmtestWebService
    Description    : This method is used to create test data and to check if new 
                    attachment and document are created from API request
    Return Type    : Void 
    Parameter      : None             
    *********************************************************************************/
    static testmethod  void testmtestWebService() {
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        PC_EmailServiceRequest.EmailAttachement emailAttchment = new PC_EmailServiceRequest.EmailAttachement();
        emailAttchment.fileName = 'file1.txt';
        emailAttchment.body = 'Attach 1';
        List<PC_EmailServiceRequest.EmailAttachement> emailAttchments = new List<PC_EmailServiceRequest.EmailAttachement>();
        emailAttchments.add(emailAttchment);
        PC_EmailServiceRequest.EmailBody emailBody = new PC_EmailServiceRequest.EmailBody();
        emailBody.plainTextBody= 'Test Body';
        emailBody.textAttachments = emailAttchments;
        PC_EmailServiceRequest request = new PC_EmailServiceRequest();
        request.fromName = 'Roxana Ivan';
        request.fromAddress = 'testaddress@test.com';
        request.subject = 'Test Subj';
        request.body = emailBody;
        List<PC_EmailServiceRequest> requestBody = new List<PC_EmailServiceRequest>();
        requestBody.add(request);
        system.debug('requestBody'+requestBody);
        system.debug(JSON.serialize(requestBody));

        req.requestURI = 'https://'+URL.getSalesforceBaseUrl().getHost()+'/services/apexrest/Documents/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{"emails":'+JSON.serialize(requestBody)+'}');
        req.params.put('useSalesforceFiles','false');
        req.addHeader('Content-Type', 'application/json');
        RestContext.request = req;
        RestContext.response = res;
        system.debug('req--'+req);
        system.debug('res--'+res);


        PC_EmailWebService.createInboundRecord(requestBody);
        Test.StartTest();
            List<PC_Document__c> doc = [SELECT PC_From_Name__c, Id FROM PC_Document__c WHERE PC_From_Name__c =: request.fromName LIMIT 1];
            System.assertEquals(doc.size(), 1);
            List<Attachment> att = [SELECT Name, Id FROM Attachment WHERE Name =: emailAttchment.fileName LIMIT 1];
            System.assertEquals(att.size(), 1);

        Test.StopTest();
    }


    /*********************************************************************************
    Method Name    : testmtestWebService
    Description    : This method is used to create test data and to check if new
                    files and document are created from API request
    Return Type    : Void
    Parameter      : None
    *********************************************************************************/
    static testmethod  void filesTestWebService() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        PC_EmailServiceRequest.EmailAttachement emailAttchment = new PC_EmailServiceRequest.EmailAttachement();
        emailAttchment.fileName = 'file1.txt';
        emailAttchment.body = 'Attach 1';
        List<PC_EmailServiceRequest.EmailAttachement> emailAttchments = new List<PC_EmailServiceRequest.EmailAttachement>();
        emailAttchments.add(emailAttchment);
        PC_EmailServiceRequest.EmailBody emailBody = new PC_EmailServiceRequest.EmailBody();
        emailBody.plainTextBody= 'Test Body';
        emailBody.textAttachments = emailAttchments;
        PC_EmailServiceRequest request = new PC_EmailServiceRequest();
        request.fromName = 'Roxana Ivan';
        request.fromAddress = 'testaddress@test.com';
        request.subject = 'Test Subj';
        request.body = emailBody;
        List<PC_EmailServiceRequest> requestBody = new List<PC_EmailServiceRequest>();
        requestBody.add(request);
        system.debug('requestBody'+requestBody);
        system.debug(JSON.serialize(requestBody));

        req.requestURI = 'https://'+URL.getSalesforceBaseUrl().getHost()+'/services/apexrest/Documents/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{"emails":'+JSON.serialize(requestBody)+'}');
        req.params.put('useSalesforceFiles','true');
        req.addHeader('Content-Type', 'application/json');
        RestContext.request = req;
        RestContext.response = res;
        system.debug('req--'+req);
        system.debug('res--'+res);


        PC_EmailWebService.createInboundRecord(requestBody);
        PC_EmailWebService.createInboundRecord(requestBody);
        Test.StartTest();
            List<PC_Document__c> doc = [SELECT PC_From_Name__c, Id FROM PC_Document__c WHERE PC_From_Name__c =: request.fromName LIMIT 1];
            System.assertEquals(doc.size(), 1);

            List<ContentDocument> cDocument = [Select Id, Title From ContentDocument where Title=:emailAttchment.fileName];
            System.assertEquals(cDocument.size()>0, true);

        Test.StopTest();
    }
    
}