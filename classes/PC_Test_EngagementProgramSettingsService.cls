/*********************************************************************************************************
Class Name      : PC_Test_EngagementProgramSettingsService
Description     : Test class for PC_Test_EngagementProgramSettingsService
Created By      : Haritha Reddy
Created Date    : Jun 10, 2021
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer          Log#         Date                   Description
--------------------------------------------------------------------------------------------------------------
Haritha Reddy                Jun 14, 2021          [PC-7388] Initial Version
****************************************************************************************************************/

@IsTest
public with sharing class PC_Test_EngagementProgramSettingsService {

    public static final String getURL_part = '/services/apexrest/' + PC_Constants.OrgNamespace + '/1.0/engagementProgramSettings/';

    @isTest static void testGetSelfServiceSettings() {
        User adminUser;
        String manufacturerName = 'TestManufacturer';
        String engagementProgramCode = 'restprg';
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test');
        PC_Database.ins(adminUser);
        System.runAs(adminUser)
        {
            Test.StartTest();

            List<Account>  manufacturers = PC_Test_Setup.createAccounts('TestManufacturer',1,'Manufacturer');
            manufacturers[0].name = manufacturerName;
            Account manufacturer = (Account) PC_Database.ins(manufacturers[0], false);

            PC_Engagement_Program__c engagementProgram = PC_Test_Setup.createEngagementProgram(engagementProgramCode,manufacturer.Id);
            engagementProgram = (PC_Engagement_Program__c) PC_Database.ins(engagementProgram);

            RestRequest re = new RestRequest();
            RestResponse rp = new RestResponse();
            re.addParameter('engagementProgramId',engagementProgram.id);
            re.addParameter('vendorName','Amazon Connect');
            re.addParameter('channel','CTI');
            re.addHeader('httpMethod', 'GET');
            re.requestURI = getURL_part;

            RestContext.request = re;
            RestContext.response= rp;
            PC_EngagementProgramSettingsService.doGet();
            if(rp.statusCode == 200) {
                System.assert(true);
            } else {
                System.assert(false);
            }
            Test.stopTest();
        }
    }

    @isTest static void testGetSelfServiceSettings_Negative() {
        User adminUser;
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test');
        PC_Database.ins(adminUser);
        System.runAs(adminUser)
        {
            Test.StartTest();
            RestRequest re = new RestRequest();
            RestResponse rp = new RestResponse();
            re.addHeader('httpMethod', 'GET');
            re.requestURI = getURL_part;

            RestContext.request = re;
            RestContext.response= rp;
            try {
                PC_EngagementProgramSettingsService.doGet();
            } catch(PC_RestException e) {
                system.assert(e.getMessage().contains(PC_RestAPIConstants.ERRORMESSAGE_QUERY_PARAMETERS_MISSING));
            }

            Test.stopTest();
        }
    }
}