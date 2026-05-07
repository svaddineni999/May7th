/***********************************************************************************************************************
Class Name      : PC_Test_AccountService
Description     : Test class for PC_AccountService
Created By      : Deloitte
Created Date    : Jun 08, 2021
Modification Log:
--------------------------------------------------------------------------------------------------------------------------
Developer          Log#         Date                   Description
--------------------------------------------------------------------------------------------------------------------------
Haritha Reddy                 Jun 08, 2021           [PC-7683] Initial Version
******************************************************************************************************************************/
@isTest
public with sharing class PC_Test_AccountService {

    public static final string getURL_part = '/services/apexrest/' + PC_Constants.OrgNamespace + '/1.0/account/';

    @isTest static void testGETPositive_FindByPhone() {
        User adminUser;
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test');
        PC_Database.ins(adminUser);
        System.runAs(adminUser){
            Test.startTest();
            Account patient = PC_Test_Setup.createEWPPatient('testpatient', '1988-05-30', 'Mr.', PC_Constants.PATIENT_RECORD_TYPE);
            patient.Phone = '9134589900';
            patient = (Account)PC_Database.ins(patient, false);

            RestRequest re = new  RestRequest();
            RestResponse rp = new  RestResponse();
            re.addHeader('httpMethod', 'GET');
            re.requestURI = getURL_part;
            re.addParameter('phone', '9134589900');
            RestContext.request = re;
            RestContext.response = rp;
            PC_AccountService.doGet();
            if(rp.statusCode == 200) {
                System.assert(true);
                String responseBodyString = rp.responseBody.toString();
                List<Map<string, string>> accountList = (List<Map<string, string>>)JSON.deserialize(responseBodyString, List<Map<string, string>>.class);
                System.assertEquals(accountList.size(), 1);
                System.assertEquals(accountList[0].get('id'), patient.id);
            }else {
                System.assert(false);
            }
            Test.stopTest();
        }
    }

    @isTest static void testGETNegative_FindByPhone() {
        User adminUser;
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test');
        PC_Database.ins(adminUser);
        System.runAs(adminUser){
            Test.startTest();
            RestRequest re = new  RestRequest();
            RestResponse rp = new  RestResponse();
            re.addHeader('httpMethod', 'GET');
            re.requestURI = getURL_part;
            re.addParameter('phone', '9134589900');
            RestContext.request = re;
            RestContext.response = rp;
            PC_AccountService.doGet();
            if(rp.statusCode == 200) {
                System.assert(true);
                String responseBodyString = rp.responseBody.toString();
                List<Map<string, string>> accountList = (List<Map<string, string>>)JSON.deserialize(responseBodyString, List<Map<string, string>>.class);
                System.assertEquals(accountList.size(), 0);
            }else {
                System.assert(false);
            }
            Test.stopTest();
        }
    }

    @isTest static void testGetAccountsNegative() {
        User adminUser;
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test');
        PC_Database.ins(adminUser);
        System.runAs(adminUser){
            Test.startTest();
            RestRequest re = new  RestRequest();
            RestResponse rp = new  RestResponse();
            re.addHeader('httpMethod', 'GET');
            re.requestURI = getURL_part;
            RestContext.request = re;
            RestContext.response = rp;
            try {
                PC_AccountService.doGet();
            } catch(PC_RestException e) {
                system.assert(e.getMessage().contains(PC_RestAPIConstants.ERRORMESSAGE_ACCOUNT_FILTERS_MISSING));
            }
            Test.stopTest();
        }
    }
}