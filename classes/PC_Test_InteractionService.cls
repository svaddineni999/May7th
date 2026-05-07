/*********************************************************************************************************
Class Name      : PC_Test_InteractionService
Description     : Test class for PC_InteractionService
Created By      : Haritha Reddy
Created Date    : Jun 15, 2021
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer          Log#         Date                   Description
--------------------------------------------------------------------------------------------------------------
Haritha Reddy                Jun 15, 2021          [PC-7387] Initial Version
Haritha Reddy                Jul 06, 2021          [PC-7879] Added a method to test Put request changes
****************************************************************************************************************/

@isTest
public with sharing class PC_Test_InteractionService {

    public static final String getURL_part = '/services/apexrest/' + PC_Constants.OrgNamespace + '/1.0/interaction/';
    public static Account  patient;
    public static PC_Engagement_Program__c engProg;
    public static Case program;
    public static PC_Interaction__c interaction;

    public static void testDataSetUp() {
        patient = PC_Test_Setup.createEWPPatient('testpatient', '1988-05-30', 'Mr.' , PC_Constants.PATIENT_RECORD_TYPE);
        patient = (Account)PC_Database.ins(patient, false);

        List<Account> manufacturers = PC_Test_Setup.createAccounts('pRootNameManufacturer', 1, 'Manufacturer');
        manufacturers = (List<Account>)PC_Database.ins(manufacturers, false);

        engProg = PC_Test_Setup.createEngagementProgram('RESTPRG', manufacturers[0].Id);
        engProg = (PC_Engagement_Program__c) PC_Database.ins(engProg, false);

        program = PC_Test_Setup.createProgram(patient);
        program.PC_Engagement_Program__c = engProg.Id;
        program = (Case)PC_Database.upd(program, false);

        interaction = new PC_Interaction__c();
        interaction.PC_Status__c = 'Confirmed';
        interaction.PC_Patient_Program__c = program.Id;
        interaction.PC_Start__c = System.now().addDays(1);
        interaction = (PC_Interaction__c)PC_Database.ins(interaction, false);
    }

    @isTest static void testGetInteractionsByEngProgramId() {
        User adminUser;
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test');
        PC_Database.ins(adminUser);
        System.runAs(adminUser) {
            Test.StartTest();
            testDataSetUp();

            RestRequest re = new RestRequest();
            RestResponse rp = new RestResponse();
            re.addParameter('patientId',patient.id);
            re.addParameter('engagementProgramId',engProg.id);
            re.addParameter('limit','5');
            re.addHeader('httpMethod', 'GET');
            re.requestURI = getURL_part+'findByEngagementProgramId/';

            RestContext.request = re;
            RestContext.response= rp;
            PC_InteractionService.doGet();
            if(rp.statusCode == 200) {
                System.assert(true);
                String responseBodyString = rp.responseBody.toString();
                List<Map<string, string>> interactionList = (List<Map<string, string>>)JSON.deserialize(responseBodyString, List<Map<string, string>>.class);
                System.assertEquals(interactionList.size(), 1);
            } else {
                System.assert(false);
            }
            Test.stopTest();
        }
    }

    @isTest static void testGetInteractionsByPatientId() {
        User adminUser;
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test');
        PC_Database.ins(adminUser);
        System.runAs(adminUser) {
            Test.StartTest();
            testDataSetUp();

            RestRequest re = new RestRequest();
            RestResponse rp = new RestResponse();
            re.addParameter('patientId',patient.id);
            re.addParameter('limit','5');
            re.addHeader('httpMethod', 'GET');
            re.requestURI = getURL_part+'findByPatientId/';

            RestContext.request = re;
            RestContext.response= rp;
            PC_InteractionService.doGet();
            if(rp.statusCode == 200) {
                System.assert(true);
                String responseBodyString = rp.responseBody.toString();
                List<Map<string, string>> interactionList = (List<Map<string, string>>)JSON.deserialize(responseBodyString, List<Map<string, string>>.class);
                System.assertEquals(interactionList.size(), 1);
            } else {
                System.assert(false);
            }
            Test.stopTest();
        }
    }

    @isTest static void testGetInteractionsNegative() {
        User adminUser;
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test');
        PC_Database.ins(adminUser);
        System.runAs(adminUser) {
            Test.StartTest();
            testDataSetUp();

            RestRequest re = new RestRequest();
            RestResponse rp = new RestResponse();
            re.addHeader('httpMethod', 'GET');
            re.requestURI = getURL_part+'findByPatientId/';

            RestContext.request = re;
            RestContext.response= rp;
            try {
                PC_InteractionService.doGet();
            } catch(PC_RestException e) {
                system.assert(e.getMessage().contains(PC_RestAPIConstants.ERRORMESSAGE_QUERY_PARAMETERS_MISSING));
            }
            Test.stopTest();
        }
    }

    public static string createRequestJSONBody(id interactionId) {
        map<string,Object> reqInteractionMap = new map<string, Object>();
        if(interactionId != null) {
            reqInteractionMap.put('id', interactionId);
        }
        reqInteractionMap.put('status', 'Cancelled');
        return (JSON.serialize(reqInteractionMap));
    }

    @isTest static void testInteractionPut() {
        User adminUser;
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test');
        PC_Database.ins(adminUser);
        System.runAs(adminUser) {
            Test.StartTest();
            testDataSetUp();

            RestRequest re = new RestRequest();
            RestResponse rp = new RestResponse();
            re.addHeader('httpMethod', 'PUT');

            string reqBodyInJSON = createRequestJsonBody(interaction.id);
            system.debug('reqBodyInJSON--'+ reqBodyInJSON);

            re.requestBody = Blob.valueOf(reqBodyInJSON);
            re.requestURI = getURL_part;
            RestContext.request = re;
            RestContext.response= rp;
            PC_InteractionService.doPUT();
            system.debug(JSON.serialize(rp.responseBody));
            if(rp.statusCode == 200) {
                System.assert(true);
            }
            else {
                System.assert(false);
            }
            Test.stopTest();
        }
    }

    @isTest static void testInteractionPutNegative() {
        User adminUser;
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test');
        PC_Database.ins(adminUser);
        System.runAs(adminUser) {
            Test.StartTest();
            testDataSetUp();

            RestRequest re = new RestRequest();
            RestResponse rp = new RestResponse();
            re.addHeader('httpMethod', 'PUT');

            string reqBodyInJSON = createRequestJsonBody(null);
            system.debug('reqBodyInJSON--'+ reqBodyInJSON);

            re.requestBody = Blob.valueOf(reqBodyInJSON);
            re.requestURI = getURL_part;
            RestContext.request = re;
            RestContext.response= rp;

            try {
                PC_InteractionService.doPUT();
            } catch(Exception e) {
                system.assertEquals(rp.statusCode,500);
            }
            Test.stopTest();
        }
    }
}