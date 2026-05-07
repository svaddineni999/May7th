@isTest
public class ACLS_Test_SMS_GetSMSStatusBatch {
	@testsetup
    private static void setup(){
        User usr = ACLS_Utility.createTestUser('ACLS Base Profile', 'TestCaseManager');
        usr.ACLS_Meeting_Link__c='www.sdahksdka.invalid';
        insert usr; 
        // Assigning Required Permission set to Test user
        List<PermissionSetAssignment> lstPsAssignment = new List<PermissionSetAssignment>();
        PermissionSetAssignment psAssignment = ACLS_Utility.assignPermissions(usr.Id, 'ACLS_Base_RW_Permissions');
        PermissionSetAssignment psAssignment1 = ACLS_Utility.assignPermissions(usr.Id, 'ACLS_Base_Permissions');
        lstPsAssignment.add(psAssignment);
        lstPsAssignment.add(psAssignment1);
        insert lstPsAssignment;
        System.runAs(usr) {
            EmailTemplate OptOuttemplate1 = new EmailTemplate(Name='Opt Out Message1', DeveloperName='ACLS_Opt_Out_Message1', Body='Hey you have opted out successfully',TemplateType ='text1',folderId =userInfo.getUserId());
            EmailTemplate OptOuttemplate = new EmailTemplate(Name='Opt Out Message', DeveloperName='ACLS_Opt_Out_Message', Body='Hey you have opted out',TemplateType ='text',folderId =userInfo.getUserId());
        //Creating test eletter
        	List<PC_eLetter__c> lsteLetter = ACLS_TestDataFactory.createTesteLetter(1);
            lsteLetter[0].PC_Template_Name__c='ACLS_Opt_Out_Message';
        	insert lsteLetter;
            List<PC_eLetter__c> lsteLetter1 = ACLS_TestDataFactory.createTesteLetter(1);
            lsteLetter1[0].PC_Template_Name__c='ACLS_Opt_Out_Message1';
        	insert lsteLetter1;
        //Creating Engagement Program
        	List<PC_Engagement_Program__c> lstEngageProgram = ACLS_TestDataFactory.createEngagmentProgram(1);
            lstEngageProgram[0].PC_Program_Code__c = 'ASHF';
            insert lstEngageProgram;
        //Creating Engagement Program eLetter
        List<PC_Engagement_Program_Eletter__c> epLetterlst = new List<PC_Engagement_Program_Eletter__c>();
            PC_Engagement_Program_Eletter__c epLetter = new PC_Engagement_Program_Eletter__c();
            epLetter.PC_Engagement_Program__c = lstEngageProgram[0].id;
            epLetter.PC_eLetter__c = lsteLetter[0].id;
            epLetterlst.add(epLetter);
            
            PC_Engagement_Program_Eletter__c epLetter2 = new PC_Engagement_Program_Eletter__c();
            epLetter2.PC_Engagement_Program__c = lstEngageProgram[0].id;
            epLetter2.PC_eLetter__c = lsteLetter1[0].id;
            epLetterlst.add(epLetter2);
            
            insert epLetterlst;
            
            
        //Create account
            Map<String, Id> mapAccRecordTypes = ACLS_Utility.getMapOfRecordtype(ACLS_Constants.ACCOUNT);
            List<Account> lstAcct = ACLS_TestDataFactory.createAccount(2);
            lstAcct[0].recordtypeId = mapAccRecordTypes.get(ACLS_Constants.ACCOUNT_MANUFACTURER_RT);
            lstAcct[1].recordtypeId = mapAccRecordTypes.get(ACLS_Constants.ACCOUNT_MANUFACTURER_RT);
            insert lstAcct;
        //Creating Program case
        	List<Case> lstProgramCase = ACLS_TestDataFactory.createProgramCase(1, lstAcct[1].Id);
            lstProgramCase[0].PC_Engagement_Program__c = lstEngageProgram[0].Id;
            
            lstProgramCase[0].OwnerId = UserInfo.getUserId();
            lstProgramCase[0].Subject='Test Subject';
            System.debug('lstProgramCase!@#$ '+lstProgramCase);
           
            insert lstProgramCase;
         
        //Create Remote service log
         List<PC_Remote_Service_Log__c> PC_Remote_Service_LogcList = ACLS_TestDataFactory.testRemoteServiceLog(1);
            insert PC_Remote_Service_LogcList;
            
        //create psp record
        	List<PC_Program_Service_Permission__c> lstpsp = ACLS_TestDataFactory.PC_Program_Service_PermissioncTestDataMethod(1);
            lstpsp[0].PC_ProgramCase__c = lstProgramCase[0].id;
        	lstpsp[0].ACLS_Engagement_Program_Code__c='ASHF';
            lstpsp[0].PC_HCP_Response__c='Signed';
           
        	insert lstpsp;
            
            PC_Interaction__c interaction = new PC_Interaction__c();
            interaction.PC_Patient_Program__c = lstProgramCase[0].id;
            interaction.PC_Participants__c = 'HCO; Care Coordinator';
            interaction.PC_Status__c = 'Requested';
            interaction = (PC_Interaction__c)PC_Database.ins(interaction, false);
            system.debug('interaction'+interaction.id);

        	List<PC_Message__c> lstMessage = ACLS_TestDataFactory.createMessage(10);
        	lstMessage[0].ACLS_Program_Service_Permission__c = lstpsp[0].id;
        	lstMessage[0].PC_SMSELetter__c = epLetterlst[0].id;
        	lstMessage[0].PC_Case__c = lstProgramCase[0].id;
        	lstMessage[0].PC_ExternalRecipientNumber__c='1234567890';
            lstMessage[0].ACLS_SMS_Operation__c=ACLS_Constants.SMS_OPERATION_OPTIN;
            lstMessage[0].PC_Message_Status__c = 'Queued';
             lstMessage[0].PC_Type__c = 'Outbound';
            
            lstMessage[1].ACLS_Program_Service_Permission__c = lstpsp[0].id;
        	lstMessage[1].PC_SMSELetter__c = epLetterlst[0].id;
        	lstMessage[1].PC_Case__c = lstProgramCase[0].id;
        	lstMessage[1].PC_ExternalRecipientNumber__c='1234567891';
            lstMessage[1].ACLS_SMS_Operation__c= ACLS_Constants.SMS_OPERATION_OPTOUT;
            lstMessage[1].PC_Message_Status__c = 'Queued';
            lstMessage[1].PC_Type__c = 'Outbound';
            
            lstMessage[2].ACLS_Program_Service_Permission__c = lstpsp[0].id;
        	lstMessage[2].PC_SMSELetter__c = epLetterlst[1].id;
        	lstMessage[2].PC_Case__c = lstProgramCase[0].id;
        	lstMessage[2].PC_ExternalRecipientNumber__c='1234567892';
            lstMessage[2].PC_Message_Status__c = 'Queued';
            lstMessage[2].ACLS_SMS_Operation__c=ACLS_Constants.SMS_OPERATION_SEND_SMS;
            lstMessage[2].PC_Type__c = 'Outbound';
            lstMessage[2].ACLS_Interaction__c=interaction.id;
            
            lstMessage[3].ACLS_Program_Service_Permission__c = lstpsp[0].id;
        	lstMessage[3].PC_SMSELetter__c = epLetterlst[0].id;
        	lstMessage[3].PC_Case__c = lstProgramCase[0].id;
        	lstMessage[3].PC_ExternalRecipientNumber__c='1234';
            lstMessage[3].ACLS_SMS_Operation__c='';
            lstMessage[3].PC_Message_Status__c = 'Queued';
            lstMessage[3].PC_Type__c = 'Outbound';
            
            lstMessage[4].ACLS_Program_Service_Permission__c = lstpsp[0].id;
        	lstMessage[4].PC_SMSELetter__c = epLetterlst[0].id;
        	lstMessage[4].PC_Case__c = lstProgramCase[0].id;
        	lstMessage[4].PC_ExternalRecipientNumber__c='1234567891';
            lstMessage[4].ACLS_SMS_Operation__c=ACLS_Constants.SMS_OPERATION_OPTIN;
            lstMessage[4].PC_Message_Status__c = 'Sending';
            lstMessage[4].PC_Type__c = 'Outbound';
            lstMessage[4].PC_TransactionId__c = null;
            
            lstMessage[5].ACLS_Program_Service_Permission__c = lstpsp[0].id;
        	lstMessage[5].PC_SMSELetter__c = epLetterlst[0].id;
        	lstMessage[5].PC_Case__c = lstProgramCase[0].id;
        	lstMessage[5].PC_ExternalRecipientNumber__c=null;
            lstMessage[5].ACLS_SMS_Operation__c='';
            lstMessage[5].PC_Message_Status__c = 'Queued';
            lstMessage[5].PC_Type__c = 'Outbound';
            
            lstMessage[6].ACLS_Program_Service_Permission__c = lstpsp[0].id;
        	lstMessage[6].PC_SMSELetter__c = epLetterlst[0].id;
        	lstMessage[6].PC_Case__c = lstProgramCase[0].id;
        	lstMessage[6].PC_ExternalRecipientNumber__c='12345';
            lstMessage[6].ACLS_SMS_Operation__c=ACLS_Constants.SMS_OPERATION_OPTIN;
            lstMessage[6].PC_Message_Status__c = 'Queued';
            lstMessage[6].PC_Type__c = 'Outbound';
            
            lstMessage[7].ACLS_Program_Service_Permission__c = lstpsp[0].id;
        	lstMessage[7].PC_SMSELetter__c = epLetterlst[0].id;
        	lstMessage[7].PC_Case__c = lstProgramCase[0].id;
        	lstMessage[7].PC_ExternalRecipientNumber__c='1234567890';
            lstMessage[7].ACLS_SMS_Operation__c=ACLS_Constants.SMS_OPERATION_OPTOUT;
            lstMessage[7].PC_Message_Status__c = 'Sending'; 
            lstMessage[7].PC_Type__c = 'Outbound';
            lstMessage[7].PC_TransactionId__c = null;
            
            lstMessage[8].ACLS_Program_Service_Permission__c = lstpsp[0].id;
        	lstMessage[8].PC_SMSELetter__c = epLetterlst[0].id;
        	lstMessage[8].PC_Case__c = lstProgramCase[0].id;
        	lstMessage[8].PC_ExternalRecipientNumber__c='1234567890';
            lstMessage[8].PC_Message_Status__c = 'Sending';
            lstMessage[8].ACLS_SMS_Operation__c=ACLS_Constants.SMS_OPERATION_SEND_SMS;
            lstMessage[8].PC_Type__c = 'Outbound';
            lstMessage[8].PC_TransactionId__c = null;
            
            lstMessage[9].ACLS_Program_Service_Permission__c = lstpsp[0].id;
        	lstMessage[9].PC_SMSELetter__c = epLetterlst[0].id;
        	lstMessage[9].PC_Case__c = lstProgramCase[0].id;
        	lstMessage[9].PC_ExternalRecipientNumber__c='9876543210';
            lstMessage[9].ACLS_SMS_Operation__c=ACLS_Constants.SMS_OPERATION_OPTOUT;
            lstMessage[9].PC_Message_Status__c = 'Sending'; 
            lstMessage[9].PC_Type__c = 'Outbound';
            lstMessage[9].PC_TransactionId__c = '018793a3-7216-ebcb-9cce-e246cb0ae8e6';
        	insert lstMessage;

            
        	List<EmailTemplate> templates = new List<EmailTemplate>();
        	EmailTemplate template1 = new EmailTemplate(Name='Template 1', DeveloperName='Template_1', Body='Test Body 1',TemplateType ='text',folderId =userInfo.getUserId());
        	EmailTemplate template2 = new EmailTemplate(Name='Template 2', DeveloperName='ACLS_Help_Message', Body='Test Body 2',TemplateType ='text',folderId =userInfo.getUserId());
        	templates.add(template1);
        	templates.add(template2);
        	insert templates;
        }
    }
    
    @isTest
    public static void getSMSStatusTest(){
 String resBody = '{ "access_token" : "eyJraWQiOiI2NzYzZjQzMy03N2RlLTQwMjQtODBiZi1hODkyZTBiMzdjZGIiLCJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJzdWIiOiJBalB2c01LSGV6djIwOFNZR0JYeWhseWFaR21kTU14TyIsInZlciI6MSwiY2xpZW50SWQiOiJBalB2c01LSGV6djIwOFNZR0JYeWhseWFaR21kTU14TyIsInJvbGVzIjpbIklWUl9TTVMiXSwiaXNzIjoiaHR0cHM6XC9cL2FwaS5wcm9kLnVzLmZpdmU5Lm5ldCIsInR5cGUiOiJBY2Nlc3NUb2tlbiIsImV4cCI6MTY4MDg3MDc5MSwiaWF0IjoxNjgwODY3MTkxLCJvcmdJZCI6IjEzNjQyNyIsImRvbWFpbklkIjoiMTM2NDI3IiwianRpIjoiZDczYWM2ZjUtN2E1MC00MWY2LTllODMtZjQ2MGZmNTgyYThjIn0.hJ_cWYLDIPhcvoyOLI1UlCAjfY09nZCNZqWk6obM93NZ6tZPegdOINiAB3SgkYpHJxW8q6ifZM9SwqpCuYNMJrQjhw3aZq18c734eLy3QCLEvZm8iEtNSUWHwLqR0oqbBXZ5BLExL-fV7Hn02eudGWtPXqC5lIK6XAS6taDrk-WLTgVYfXICnuH4dTAtJEeKwERQfZYFeDtm8dTOL5I2_-bmhkbmUU_LqIOYQWFbVuof99fqpA9XL45PFPR0FcsVnx1K35bnqdqj-IQck0su0Gb7u3ZLaY_Zdnz7o6a0G-AqH_H-NYeyJpQziKdenMSci2U8wQ7Wuiep3VBoClVu1g","expires_in":3600, "token_type" : "Bearer" }';
 ACLS_SMSIntegrationHandler.res1 = new HttpResponse();
 ACLS_SMSIntegrationHandler.res1.setStatusCode(200);
 ACLS_SMSIntegrationHandler.res1.setBody(resBody);
 
 ACLS_SMSIntegrationHandler.res2 = new HttpResponse();
 ACLS_SMSIntegrationHandler.res2.setStatusCode(200);
 ACLS_SMSIntegrationHandler.res2.setBody(resBody);
 
 ACLS_SMSIntegrationHandler.res3 = new HttpResponse();
 ACLS_SMSIntegrationHandler.res3.setStatusCode(200);
 ACLS_SMSIntegrationHandler.res3.setBody(resBody);
 
 ACLS_SMSIntegrationHandler.res4 = new HttpResponse();
 ACLS_SMSIntegrationHandler.res4.setStatusCode(200);
 ACLS_SMSIntegrationHandler.res4.setBody(resBody);
        
      	User usr1 = [select id, lastName from User where lastName = 'TestCaseManager'];
        
        System.runAs(usr1) {   
            try{ 
            Test.startTest();
            List<EmailTemplate> lstTemp = [Select Id, DeveloperName from EmailTemplate where DeveloperName = 'ACLS_Help_Message'];
            List<PC_Message__c> lstMessage = [Select Id, PC_ExternalRecipientNumber__c,ACLS_SMS_Operation__c, PC_Message_Status__c, PC_TransactionId__c from PC_Message__c];
                System.debug('lstMessageVG'+lstMessage);
                System.assertEquals(10,lstMessage.size(),'10 message records should be returned');
                String mockResponse = '{"access_token" : "eyJraWQiOiI2NzYzZjQzMy03N2RlLTQwMjQtODBiZi1hODkyZTBiMzdjZGIiLCJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJzdWIiOiJBalB2c01LSGV6djIwOFNZR0JYeWhseWFaR21kTU14TyIsInZlciI6MSwiY2xpZW50SWQiOiJBalB2c01LSGV6djIwOFNZR0JYeWhseWFaR21kTU14TyIsInJvbGVzIjpbIklWUl9TTVMiXSwiaXNzIjoiaHR0cHM6XC9cL2FwaS5wcm9kLnVzLmZpdmU5Lm5ldCIsInR5cGUiOiJBY2Nlc3NUb2tlbiIsImV4cCI6MTY4MDg3MDc5MSwiaWF0IjoxNjgwODY3MTkxLCJvcmdJZCI6IjEzNjQyNyIsImRvbWFpbklkIjoiMTM2NDI3IiwianRpIjoiZDczYWM2ZjUtN2E1MC00MWY2LTllODMtZjQ2MGZmNTgyYThjIn0.hJ_cWYLDIPhcvoyOLI1UlCAjfY09nZCNZqWk6obM93NZ6tZPegdOINiAB3SgkYpHJxW8q6ifZM9SwqpCuYNMJrQjhw3aZq18c734eLy3QCLEvZm8iEtNSUWHwLqR0oqbBXZ5BLExL-fV7Hn02eudGWtPXqC5lIK6XAS6taDrk-WLTgVYfXICnuH4dTAtJEeKwERQfZYFeDtm8dTOL5I2_-bmhkbmUU_LqIOYQWFbVuof99fqpA9XL45PFPR0FcsVnx1K35bnqdqj-IQck0su0Gb7u3ZLaY_Zdnz7o6a0G-AqH_H-NYeyJpQziKdenMSci2U8wQ7Wuiep3VBoClVu1g" ,"expires_in" : 3600,"token_type" : "Bearer"}';
                String mockResponse1 = '{"sendSmsTaskId":"01875b7d-eded-7099-2673-ea7303454013","uri":"/send-sms-svc/v1/domains/136427/send-sms-tasks/01875b7d-eded-7099-2673-ea7303454013"}';
                String mockResponse2 = '{"createdOn": "2023-04-18T14:12:38.202Z", "createdBy": "136427", "lastModifiedOn": "2023-04-18T14:13:38.694Z", "lastModifiedBy": "136427", "campaignName": "CC_US_SMS_OB",  "dispositionName": null, "message": "Welcome to RareAssistRx! We have received your RareAssistRx enrollment form for salafaxine. Reply HELP for help, STOP to cancel.",  "scheduledTime": null, "attributes": {}, "name": "a1bDT000001lYFpYAM","sendSmsTaskId": "018793a3-7216-ebcb-9cce-e246cb0ae8e6",  "status": "FAILED",    "taskProgress": [ { "count": 1, "status": "DELIVERED" }]}';

                Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse, 200));
                Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse1, 200));
                Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse2, 200));
        		//Test.setMock(HttpCalloutMock.class, new ACLS_Test_SMSSendHttpCalloutMock());
                ACLS_SMS_GetSMSStatusBatch batch = new ACLS_SMS_GetSMSStatusBatch('');
				Database.executeBatch(batch, 40);
                
                Test.setMock(HttpCalloutMock.class, new ACLS_Test_SMSSendHttpCalloutMock());
                ACLS_SMS_SendSMSBatch batch1 = new ACLS_SMS_SendSMSBatch();
				Database.executeBatch(batch1, 40); 
                
                ACLS_SMS_SendSMSBatch batch2 = new ACLS_SMS_SendSMSBatch('');
				Database.executeBatch(batch2, 40);            
           
        	Test.stopTest();
            }
             catch(Exception ex){
                ACLS_Utility.createINTErrorLogs(ex, null, null, null, null, ACLS_Constants.CLASS_BATCH_GETSMSSTATUS, ACLS_Constants.METHOD_BATCH_SENDSMS_EXECUTE, '');

            }
        }
    }
    
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        private String mockResponse;
        private Integer mockStatus;
        
        public MockHttpResponseGenerator(String mockResponse, Integer mockStatus) {
            this.mockResponse = mockResponse;
            this.mockStatus = mockStatus;
        }
        
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(mockResponse);
            res.setStatusCode(mockStatus);
            return res;
        }
    }
    
    @isTest
    public static void getSMSStatusNegativeTest(){
        String resBody = '{"access_token" : "eyJraWQiOiI2NzYzZjQzMy03N2RlLTQwMjQtODBiZi1hODkyZTBiMzdjZGIiLCJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJzdWIiOiJBalB2c01LSGV6djIwOFNZR0JYeWhseWFaR21kTU14TyIsInZlciI6MSwiY2xpZW50SWQiOiJBalB2c01LSGV6djIwOFNZR0JYeWhseWFaR21kTU14TyIsInJvbGVzIjpbIklWUl9TTVMiXSwiaXNzIjoiaHR0cHM6XC9cL2FwaS5wcm9kLnVzLmZpdmU5Lm5ldCIsInR5cGUiOiJBY2Nlc3NUb2tlbiIsImV4cCI6MTY4MDg3MDc5MSwiaWF0IjoxNjgwODY3MTkxLCJvcmdJZCI6IjEzNjQyNyIsImRvbWFpbklkIjoiMTM2NDI3IiwianRpIjoiZDczYWM2ZjUtN2E1MC00MWY2LTllODMtZjQ2MGZmNTgyYThjIn0.hJ_cWYLDIPhcvoyOLI1UlCAjfY09nZCNZqWk6obM93NZ6tZPegdOINiAB3SgkYpHJxW8q6ifZM9SwqpCuYNMJrQjhw3aZq18c734eLy3QCLEvZm8iEtNSUWHwLqR0oqbBXZ5BLExL-fV7Hn02eudGWtPXqC5lIK6XAS6taDrk-WLTgVYfXICnuH4dTAtJEeKwERQfZYFeDtm8dTOL5I2_-bmhkbmUU_LqIOYQWFbVuof99fqpA9XL45PFPR0FcsVnx1K35bnqdqj-IQck0su0Gb7u3ZLaY_Zdnz7o6a0G-AqH_H-NYeyJpQziKdenMSci2U8wQ7Wuiep3VBoClVu1g","expires_in" : 3600,"token_type" : "Bearer"}';
        ACLS_SMSIntegrationHandler.res1 = new HttpResponse();
        ACLS_SMSIntegrationHandler.res1.setStatusCode(200);
        ACLS_SMSIntegrationHandler.res1.setBody(resBody);

        ACLS_SMSIntegrationHandler.res2 = new HttpResponse();
        ACLS_SMSIntegrationHandler.res2.setStatusCode(200);
        ACLS_SMSIntegrationHandler.res2.setBody(resBody);
        
        ACLS_SMSIntegrationHandler.res3 = new HttpResponse();
        ACLS_SMSIntegrationHandler.res3.setStatusCode(200);
        ACLS_SMSIntegrationHandler.res3.setBody(resBody);
        
        ACLS_SMSIntegrationHandler.res4 = new HttpResponse();
        ACLS_SMSIntegrationHandler.res4.setStatusCode(200);
        ACLS_SMSIntegrationHandler.res4.setBody(resBody);
        User usr1 = [select id, lastName from User where lastName = 'TestCaseManager'];
        
        System.runAs(usr1) {   
            try{ 

                ACLS_SMS_IntegrationWrapper.SMS_OptIn_Request smWrapper = new ACLS_SMS_IntegrationWrapper.SMS_OptIn_Request(null,null,null);
                ACLS_SMS_IntegrationWrapper.SendSMS_Request srWrapper = new ACLS_SMS_IntegrationWrapper.SendSMS_Request(null,null,null,null);
                ACLS_SMS_IntegrationWrapper.Recipients recipeientWrapper = new ACLS_SMS_IntegrationWrapper.Recipients(null);

                ACLS_Http_RequestResponse_Util.handleHTTPCallouts(null,null,null,null,0,null);

                Test.startTest();
                List<EmailTemplate> lstTemp = [Select Id, DeveloperName from EmailTemplate where DeveloperName = 'ACLS_Help_Message'];
                List<PC_Message__c> lstMessage = [Select Id, PC_ExternalRecipientNumber__c,ACLS_SMS_Operation__c,PC_Message_Status__c, PC_TransactionId__c  from PC_Message__c];
                    
                System.assertEquals(10,lstMessage.size(),'10 message records should be returned');
                String mockResponse1 = '{"sendSmsTaskId":"01875b7d-eded-7099-2673-ea7303454013","uri":"/send-sms-svc/v1/domains/136427/send-sms-tasks/01875b7d-eded-7099-2673-ea7303454013"}';
                String mockResponse2 = '{"createdOn": "2023-04-18T14:12:38.202Z", "createdBy": "136427", "lastModifiedOn": "2023-04-18T14:13:38.694Z", "lastModifiedBy": "136427", "campaignName": "CC_US_SMS_OB",  "dispositionName": null, "message": "Welcome to RareAssistRx! We have received your RareAssistRx enrollment form for salafaxine. Reply HELP for help, STOP to cancel.",  "scheduledTime": null, "attributes": {}, "name": "a1bDT000001lYFpYAM","sendSmsTaskId": "018793a3-7216-ebcb-9cce-e246cb0ae8e6",  "status": "FAILED",    "taskProgress": [ { "count": 1, "status": "DELIVERED" }]}';

                Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse1, 200));
                Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse2, 200));

                //Test.setMock(HttpCalloutMock.class, new ACLS_Test_SMSHttpCalloutMock());                
                ACLS_SMS_SendSMSBatch batch3 = new ACLS_SMS_SendSMSBatch('');
                Database.executeBatch(batch3, 40);  
            
                Test.stopTest();
            }
             catch(Exception ex){
				System.debug('in test exception'+ex.getMessage());
            }
        }
    }
}