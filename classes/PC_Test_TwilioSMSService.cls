/*********************************************************************************************************
Class Name      : PC_Test_TwilioSMSService
Description     : Test class for Twilio specific service class.
Created By      : Chetna Mohapatra
Created Date    : Nov 3, 2021
Modification Log:
-----------------------------------------------------------------------------------------------------
Developer                   Date                           Description
-----------------------------------------------------------------------------------------------------
Chetna Mohapatra          Nov 3, 2021                     Initial Version
*********************************************************************************************************/
 @isTest
 public class PC_Test_TwilioSMSService{
     private static User adminUser;
    @testSetup static void setup() {
        // Create Admin User
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'testAdminUser25@test.com', 'test25');
        PC_Database.ins(adminUser);

    }
    @isTest static void testCallout() {
        // Set mock callout class
        User adminUser25 = [Select Id from User WHERE username = 'testAdminUser25@test.com'];
        System.runAs(adminUser25) {
            Test.StartTest();
            Test.setMock(HttpCalloutMock.class, new PC_Twilio_MockHttpResponseGenerator());
            // Call method to test which causes a fake response to be sent from the class that implements HttpCalloutMock.
            PC_TwilioSMSService.CallOutParameters values = new PC_TwilioSMSService.CallOutParameters();
            values.toPhNumber = '919439594358';
            values.fromPhNumber = '17742737543';
            values.smsBody = 'MockTwilioCallout';
            values.accountSid = 'AC13769fb83bffeab7c25225b4c1371a99';
            Map<String, HttpResponse> responseMap = PC_TwilioSMSService.doCallOut(values);
            for (HttpResponse callOutResponse : responseMap.values()) {
                // Verify response received contains fake values
                String contentType = callOutResponse.getHeader('Content-Type');
                System.assert(contentType == 'application/json');
                String actualValue = callOutResponse.getBody();
                String expectedValue = '{"account_sid": "AC13769fb83bffeab7c25225b4c1371a99","to": "+919439594358","from": "+17742737543","body": "MockTwilioCallout","status": "queued","direction": "outbound-api"}';
                System.assertEquals(actualValue, expectedValue);
                System.assertEquals(200, callOutResponse.getStatusCode());

            }
            Test.stopTest();
        }

    }
    @isTest static void testSendViaTwilioSMSService(){
        User adminUser25 = [Select Id from User WHERE username = 'testAdminUser25@test.com'];
        System.runAs(adminUser25) {
            Test.StartTest();
            List<Account> patientAccounts = PC_Test_Setup.createAccounts('test', 200, PC_Constants.PATIENT_RECORD_TYPE);
            patientAccounts = (List<Account>) PC_Database.ins(patientAccounts, false);
            System.assertEquals(patientAccounts.size(), 200);

            List<Case> senderCases = PC_Test_Setup.createProgramCases(patientAccounts, 200);
            senderCases = (List<Case>) PC_Database.ins(senderCases, false);
            System.assertEquals(senderCases.size(), 200);

            List<PC_Message__c> outboundMessages = new List<PC_Message__c>();
            List<Id> messageIds= new List<Id>();
            PC_Message__c outboundMessage = new PC_Message__c();
            PC_SMS.SenderRequest request= new PC_SMS.SenderRequest();
            for (Case senderCase : senderCases) {
                outboundMessage = PC_Test_Setup.createMessage(senderCase);
                outboundMessage.PC_Type__c = PC_Constants.OUTBOUND;
                outboundMessage.PC_ReceiverAccount__c = senderCase.AccountId;
                outboundMessages.add(outboundMessage);
            }
            if (!outboundMessages.isEmpty() && outboundMessages != null) {
                PC_Database.ins(outboundMessages, true);//bulk-insert
                System.assertEquals(outboundMessages.size(), 200);

                for(PC_Message__c msg:outboundMessages){
                    messageIds.add(msg.Id);
                }
                request.messageIds= messageIds;
                PC_TwilioSMSService.send(request);

            }
            Test.stopTest();
        }
    }
     @isTest static void testSendViaTwilioBatchSMSService() {
         User adminUser25 = [Select Id from User WHERE username = 'testAdminUser25@test.com'];
         System.runAs(adminUser25) {
             Test.StartTest();
             List<Account> patientAccounts = PC_Test_Setup.createAccounts('test', 200, PC_Constants.PATIENT_RECORD_TYPE);
             patientAccounts = (List<Account>) PC_Database.ins(patientAccounts, false);
             System.assertEquals(patientAccounts.size(), 200);

             List<Case> senderCases = PC_Test_Setup.createProgramCases(patientAccounts, 200);
             senderCases = (List<Case>) PC_Database.ins(senderCases, false);
             System.assertEquals(senderCases.size(), 200);

             List<PC_Message__c> outboundMessages = new List<PC_Message__c>();
             PC_Message__c outboundMessage = new PC_Message__c();
             PC_SMS.BatchSenderRequest batchRequest = new PC_SMS.BatchSenderRequest();
             for (Case senderCase : senderCases) {
                 outboundMessage = PC_Test_Setup.createMessage(senderCase);
                 outboundMessage.PC_Type__c = PC_Constants.OUTBOUND;
                 outboundMessage.PC_Receiver__c = senderCase.AccountId;
                 outboundMessages.add(outboundMessage);
             }
             if (!outboundMessages.isEmpty() && outboundMessages != null) {
                 System.assertEquals(outboundMessages.size(), 200);
                 batchRequest.messageDetails = outboundMessages;
                 PC_TwilioBatchSMSService.send(batchRequest);

             }
             Test.stopTest();
         }
     }
     @isTest static void testTwilioStatusCallback(){
         User adminUser25 = [Select Id from User WHERE username = 'testAdminUser25@test.com'];
         System.runAs(adminUser25) {
             Test.StartTest();
             Account patient = PC_Test_Setup.createSampleAccount('test', PC_Constants.PATIENT_RECORD_TYPE);
             patient = (Account) PC_Database.ins(patient, false);

             Case senderCase = PC_Test_Setup.createCase(adminUser25, patient);
             senderCase = (Case) PC_Database.ins(senderCase, false);

             Map<String, String> messageIdStatusMap= new Map<String, String>();
             List<String> errorCodes= new List<String>();
             PC_Message__c outboundMessage1 = new PC_Message__c();
             outboundMessage1 = PC_Test_Setup.createMessage(senderCase);
             outboundMessage1.PC_Type__c = PC_Constants.OUTBOUND;
             outboundMessage1.PC_SenderAccount__c = senderCase.AccountId;
             outboundMessage1.PC_Message_Status__c= PC_SMS.PC_SMS_UNDELIVERED;
             outboundMessage1.PC_SMSId__c = 'SMc2e29581f58b4e64acbedfc2b35c6d71q';
             outboundMessage1.PC_SMSVendorName__c= PC_Constants.PC_TWILIO;
             outboundMessage1 = (PC_Message__c) PC_Database.ins(outboundMessage1, false);

             if (outboundMessage1 != null) {
                messageIdStatusMap.put(outboundMessage1.PC_SMSId__c, outboundMessage1.PC_Message_Status__c);
                errorCodes.add('30008');
                PC_TwilioSMSService.updateMessageStatusAndCreateActivity(messageIdStatusMap,errorCodes);
             }
             PC_Message__c outboundMessage2 = new PC_Message__c();
             outboundMessage2 = PC_Test_Setup.createMessage(senderCase);
             outboundMessage2.PC_Type__c = PC_Constants.OUTBOUND;
             outboundMessage2.PC_SenderAccount__c = senderCase.AccountId;
             outboundMessage2.PC_Message_Status__c= PC_SMS.PC_SMS_DELIVERED;
             outboundMessage2.PC_SMSId__c = 'SMc2e29581f58b4e64acbedfc2b35u2d80w';
             outboundMessage2.PC_SMSVendorName__c= PC_Constants.PC_TWILIO;
             outboundMessage2 = (PC_Message__c) PC_Database.ins(outboundMessage2, false);

             if (outboundMessage2 != null) {
                messageIdStatusMap.put(outboundMessage2.PC_SMSId__c, outboundMessage2.PC_Message_Status__c);
                PC_TwilioSMSService.updateMessageStatusAndCreateActivity(messageIdStatusMap,null);
             }
             Test.stopTest();
         }
     }
     @isTest static void testTwilioInboundSms() {
         User adminUser25 = [Select Id from User WHERE username = 'testAdminUser25@test.com'];
         System.runAs(adminUser25) {
             Test.StartTest();
             Account patient = PC_Test_Setup.createSampleAccount('test', PC_Constants.PATIENT_RECORD_TYPE);
             patient.phone= '19142923647';
             patient = (Account) PC_Database.ins(patient, false);

             Account manufacturer = PC_Test_Setup.createSampleAccount('manufacturerTest', PC_Constants.MANUFACTURER_RECORD_TYPE);
             manufacturer.phone='17742737543';
             manufacturer = (Account) PC_Database.ins(manufacturer, false);

             Case senderCase = PC_Test_Setup.createCase(adminUser25, patient);
             senderCase = (Case) PC_Database.ins(senderCase, false);


             String reqString = PC_Constants.EMPTY_STRING;
             String requestUrl = '/pccore/1.0/RemoteServiceLog//?serviceType=Inbound&ApiVersion=2010-04-01&SmsSid=SMc0514ee2fc6346d8cdf02f875d387e4e&SmsStatus=received&SmsMessageSid=SMc0514ee2fc6346d8cdf02f875d387e4e&NumSegments=1&ToState=NY&From=+17742737543&MessageSid=SMc0514ee2fc6346d8cdf02f875d387e4e&AccountSid=AC46ceefba998faab2b5b4a4efe62e32a9&ToCity=NEW YORK&FromCountry=US&ToZip=10011&FromCity=EASTON&name=twilio&To=+19142923647&FromZip=02375&ToCountry=US&Body=send out&NumMedia=0&FromState=MA';
             String serviceName = 'Twilio';
             PC_TwilioSMSService.handleTwilioRequest(reqString, requestUrl, serviceName);

             Test.stopTest();
         }
     }
 }