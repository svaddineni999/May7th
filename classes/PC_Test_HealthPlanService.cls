/*********************************************************************************************************
Class Name      : PC_Test_HealthPlanService
Description     : Test class for PC_HealthPlanService
Created By      : Deloitte
Created Date    : Aug 9, 2017
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer          Log#         Date                   Description
--------------------------------------------------------------------------------------------------------------
Vijay Kashikar                Aug 9, 2017           Initial Version
Rohit Kapoor                  Nov 14, 2017          PC-2492 -Refactor the code
Vijay Kashikar                20 Aug, 2019          [PC-5326] - Replaced PC_Patient hardcoding with constant
****************************************************************************************************************/


@IsTest
private class PC_Test_HealthPlanService {
    public static final String getURL_part = '/services/apexrest/' + PC_Constants.OrgNamespace + '/1.0/healthPlan/';
    
    
    public static string createRequestJsonBody(id patientId, id healthPlanId)
    {
        
        map<string,Object> reqHealthPlantMap = new map<string, Object>();
        reqHealthPlantMap.put('cardholderName','testCardHolderName');
        if(patientId != null)
        {
            reqHealthPlantMap.put('patientId',patientId);
        }

        if(healthPlanId != null)
        {
            reqHealthPlantMap.put('id',healthPlanId);
        }
       
        
        return (JSON.serialize(reqHealthPlantMap));
    }

    @isTest static void testGETPostive() {
        User adminUser;

        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test');
        PC_Database.ins(adminUser);
        System.runAs(adminUser) {
            Test.StartTest();
            Account  patient = PC_Test_Setup.createEWPPatient('testpatient', '1988-05-30', 'Mr.' , PC_Constants.PATIENT_RECORD_TYPE);
            patient = (Account)PC_Database.ins(patient, false);

            PC_Health_Plan__c health_plan = PC_Test_Setup.createTestHealthPlan(patient.Id);
            health_plan = (PC_Health_Plan__c) PC_Database.ins(health_plan, false);


            RestRequest re = new RestRequest();
            RestResponse rp = new RestResponse();
            re.addHeader('httpMethod', 'GET');

            re.requestURI = getURL_part+health_plan.Id;

            RestContext.request = re;
            RestContext.response= rp;
            PC_HealthPlanService.doGet();
            if(rp.statusCode == 200) {
                System.assert(true, 'Success');
            }
            else {
                System.assert(false, 'Fail - Invalid response');
            }
            Test.stopTest();
        }
    }

    @isTest static void testGETNegative() {
        User adminUser;

        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test');
        PC_Database.ins(adminUser);
        System.runAs(adminUser) {
            Test.StartTest();
            Account  patient = PC_Test_Setup.createEWPPatient('testpatient', '1988-05-30', 'Mr.' , PC_Constants.PATIENT_RECORD_TYPE);
            patient = (Account)PC_Database.ins(patient, false);

            PC_Health_Plan__c health_plan = PC_Test_Setup.createTestHealthPlan(patient.Id);
            health_plan = (PC_Health_Plan__c) PC_Database.ins(health_plan, false);


            RestRequest re = new RestRequest();
            RestResponse rp = new RestResponse();
            re.addHeader('httpMethod', 'GET');

            re.requestURI = getURL_part;

            RestContext.request = re;
            RestContext.response= rp;
            PC_HealthPlanService.doGet();
            if(rp.statusCode == 200) {
                System.assert(false);
            }
            else {
                System.assert(true);
            }
            Test.stopTest();
        }
    }

    @isTest static void testPOST() {
        User adminUser;

        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test');
        PC_Database.ins(adminUser);
        System.runAs(adminUser) {
            Test.StartTest();
            Account  patient = PC_Test_Setup.createEWPPatient('testpatient', '1988-05-30', 'Mr.' , PC_Constants.PATIENT_RECORD_TYPE);
            patient = (Account)PC_Database.ins(patient, false);

            RestRequest re = new RestRequest();
            RestResponse rp = new RestResponse();
            re.addHeader('httpMethod', 'POST');

            string reqBodyInJSON = createRequestJsonBody(patient.id, null);
            system.debug('reqBodyInJSON--'+ reqBodyInJSON);

            re.requestBody = Blob.valueOf(reqBodyInJSON);
            re.requestURI = getURL_part;
            RestContext.request = re;
            RestContext.response= rp;
            PC_HealthPlanService.doPOST();
            if(rp.statusCode == 200) {
                System.assert(true);
            }
            else {
                System.assert(false);
            }
            Test.stopTest();
        }
    }

    @isTest static void testPUT() {
        User adminUser;

        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test');
        PC_Database.ins(adminUser);
        System.runAs(adminUser) {
            Test.StartTest();
            Account  patient = PC_Test_Setup.createEWPPatient('testpatient', '1988-05-30', 'Mr.' , PC_Constants.PATIENT_RECORD_TYPE);
            patient = (Account)PC_Database.ins(patient, false);

            PC_Health_Plan__c health_plan = PC_Test_Setup.createTestHealthPlan(patient.Id);
            health_plan = (PC_Health_Plan__c) PC_Database.ins(health_plan, false);

            RestRequest re = new RestRequest();
            RestResponse rp = new RestResponse();
            re.addHeader('httpMethod', 'PUT');

            string reqBodyInJSON = createRequestJsonBody(null, health_plan.id);
           
            re.requestBody = Blob.valueOf(reqBodyInJSON);
            re.requestURI = getURL_part;
            RestContext.request = re;
            RestContext.response= rp;
            PC_HealthPlanService.doPUT();
            system.debug('rp--' + rp.statusCode);
            if(rp.statusCode == 200) {
                System.assert(true);
            }
            else {
                System.assert(false);
            }
            Test.stopTest();
        }
    }
}