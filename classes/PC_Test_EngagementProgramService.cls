/*********************************************************************************************************
Class Name      : PC_Test_EngagementProgramService
Description     : Test class for PC_EngagementProgramService
Created By      : Deloitte
Created Date    : Aug 10, 2017
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer          Log#         Date                   Description
--------------------------------------------------------------------------------------------------------------
Vijay Kashikar                Aug 10, 2017           Initial Version
Rohit Kapoor                  Nov 14, 2017           PC-2492 - Refactor the code
****************************************************************************************************************/


@IsTest
private class PC_Test_EngagementProgramService {
    public static final String getURL_part = '/services/apexrest/' + PC_Constants.OrgNamespace + '/1.0/engagementProgram/';

    @isTest static void testGETPositive_ByEngagementProgramCode() {
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

            re.addHeader('httpMethod', 'GET');
            re.requestURI = getURL_part + '/findByCode/' + engagementProgramCode;

            RestContext.request = re;
            RestContext.response= rp;
            PC_EngagementProgramService.doGet();
            if(rp.statusCode == 200) 
            {
                System.assert(true);
            }
            else 
            {
                System.assert(false);
            }
            Test.stopTest();
        }
    }

    @isTest static void testGETNegative() {
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

            re.addHeader('httpMethod', 'GET');
            re.requestURI = getURL_part + '/findByCode/' ;

            RestContext.request = re;
            RestContext.response= rp;
            PC_EngagementProgramService.doGet();
            if(rp.statusCode == 200) 
            {
                System.assert(false);
            }
            else 
            {
                System.assert(true);
            }
            Test.stopTest();
        }
    }
}