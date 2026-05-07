/*********************************************************************************************************
Class Name      : PC_Test_PayerService
Description     : Test class for PC_PayerService
Created By      : Deloitte
Created Date    : Aug 10, 2017
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer          Log#         Date                   Description
--------------------------------------------------------------------------------------------------------------
Vijay Kashikar                Aug 10, 2017           Initial Version
Rohit Kapoor                  Nov 14, 2017           PC-2492 -Refactor the code
Rohit Kapoor                  Nov 22, 2017           PC-2516 - Create a new GET payer service
Shishir Bansal                10-Dec-2019            [PC-5792] Avoid hardcoding of string variable

****************************************************************************************************************/


@IsTest
private class PC_Test_PayerService {
    public static final String getURL_part = '/services/apexrest/' + PC_Constants.OrgNamespace + '/1.0/payer/';

    @isTest static void testGETPositive_ByName() {
        User adminUser;
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test');
        PC_Database.ins(adminUser);
        System.runAs(adminUser) {
            Test.StartTest();


            List<Account>  payerAccounts = PC_Test_Setup.createAccounts('TestPayer',1,'Payer');
            payerAccounts[0].name = 'testpayer';
            payerAccounts[0].phone ='9182345456';
            Account payer = (Account) PC_Database.ins(payerAccounts[0], false);

            Id [] fixedSearchResults= new Id[1];
            fixedSearchResults[0] = payer.Id;
            Test.setFixedSearchResults(fixedSearchResults);
            /*************************************************************************/
            RestRequest re = new RestRequest();
            RestResponse rp = new RestResponse();

            re.addHeader('httpMethod', 'GET');
            re.requestURI = getURL_part;
            re.addParameter('findBy', 'name');
            re.addParameter('name', payer.name);
            re.addParameter('phone', payer.phone);

            RestContext.request = re;
            RestContext.response= rp;
            PC_PayerService.doGet();
            if(rp.statusCode == 200) {
                System.assert(true);
            }
            else {
                System.assert(false);
            }
           
            Test.stopTest();
        }
    }

    @isTest static void testGETPositive_ByRecordId() {
        User adminUser;
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test');
        PC_Database.ins(adminUser);
        System.runAs(adminUser) {
            Test.StartTest();


            List<Account>  payerAccounts = PC_Test_Setup.createAccounts('TestPayer',1,'Payer');
            payerAccounts[0].name = 'testpayer';
            Account payer = (Account) PC_Database.ins(payerAccounts[0], false);

            Id [] fixedSearchResults= new Id[1];
            fixedSearchResults[0] = payer.Id;
            Test.setFixedSearchResults(fixedSearchResults);

            RestRequest re = new RestRequest();
            RestResponse rp = new RestResponse();

            re.addHeader('httpMethod', 'GET');
            re.requestURI = getURL_part + payer.Id;

            RestContext.request = re;
            RestContext.response= rp;
            PC_PayerService.doGet();
            if(rp.statusCode == 200) {
                System.assert(true);
            }
            else {
                System.assert(false);
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


            List<Account>  payerAccounts = PC_Test_Setup.createAccounts('TestPayer',1,'Payer');
            payerAccounts[0].name = 'testpayer';
            Account payer = (Account) PC_Database.ins(payerAccounts[0], false);

            Id [] fixedSearchResults= new Id[1];
            fixedSearchResults[0] = payer.Id;
            Test.setFixedSearchResults(fixedSearchResults);


            RestRequest re = new RestRequest();
            RestResponse rp = new RestResponse();

            re.addHeader('httpMethod', 'GET');
            re.requestURI = getURL_part;

            RestContext.request = re;
            RestContext.response= rp;
            PC_PayerService.doGet();
            if(rp.statusCode == 200) {
                System.assert(true);
            }
            else {
                System.assert(false);
            }

            Test.stopTest();
        }
    }

    @isTest static void testGETNegative_ByBlankName() {
        User adminUser;
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test');
        PC_Database.ins(adminUser);
        System.runAs(adminUser) {
            Test.StartTest();


            List<Account>  payerAccounts = PC_Test_Setup.createAccounts('TestPayer',1,'Payer');
            payerAccounts[0].name = 'testpayer';
            Account payer = (Account) PC_Database.ins(payerAccounts[0], false);

            Id [] fixedSearchResults= new Id[1];
            fixedSearchResults[0] = payer.Id;
            Test.setFixedSearchResults(fixedSearchResults);

            RestRequest re = new RestRequest();
            RestResponse rp = new RestResponse();

            re.addHeader('httpMethod', 'GET');
            re.requestURI = getURL_part + '?findBy=name';

            RestContext.request = re;
            RestContext.response= rp;
            PC_PayerService.doGet();
            if(rp.statusCode == 200) {
                System.assert(false);
            }
            else {
                System.assert(true);
            }

            Test.stopTest();
        }
    }

    @isTest static void testGETNegative_ByNameLessThan3Char() {
        User adminUser;
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test');
        PC_Database.ins(adminUser);
        System.runAs(adminUser) {
            Test.StartTest();


            List<Account>  payerAccounts = PC_Test_Setup.createAccounts('TestPayer',1,'Payer');
            payerAccounts[0].name = 'testpayer';
            Account payer = (Account) PC_Database.ins(payerAccounts[0], false);

            Id [] fixedSearchResults= new Id[1];
            fixedSearchResults[0] = payer.Id;
            Test.setFixedSearchResults(fixedSearchResults);
            
            RestRequest re = new RestRequest();
            RestResponse rp = new RestResponse();

            re.addHeader('httpMethod', 'GET');
            re.requestURI = getURL_part;
            re.addParameter('findBy', 'name');
            re.addParameter('name', 'te');
            
            RestContext.request = re;
            RestContext.response= rp;
            PC_PayerService.doGet();
            if(rp.statusCode == 200) {
                System.assert(false);
            }
            else {
                System.assert(true);
            }
           
            Test.stopTest();
        }
    }

    @isTest static void testGETNegative_ByNoValueToFindByParam() {
        User adminUser;
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test');
        PC_Database.ins(adminUser);
        System.runAs(adminUser) {
            Test.StartTest();


            List<Account>  payerAccounts = PC_Test_Setup.createAccounts('TestPayer',1,'Payer');
            payerAccounts[0].name = 'testpayer';
            Account payer = (Account) PC_Database.ins(payerAccounts[0], false);

            Id [] fixedSearchResults= new Id[1];
            fixedSearchResults[0] = payer.Id;
            Test.setFixedSearchResults(fixedSearchResults);
            
            RestRequest re = new RestRequest();
            RestResponse rp = new RestResponse();

            re.addHeader('httpMethod', 'GET');
            re.requestURI = getURL_part;
            re.addParameter('findBy',PC_Constants.EMPTY_STRING);
            
            RestContext.request = re;
            RestContext.response= rp;
            PC_PayerService.doGet();
            if(rp.statusCode == 200) {
                System.assert(false);
            }
            else {
                System.assert(true);
            }
           
            Test.stopTest();
        }
    }

    @isTest static void testGETNegative_ByBlankNameParam() {
        User adminUser;
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test');
        PC_Database.ins(adminUser);
        System.runAs(adminUser) {
            Test.StartTest();


            List<Account>  payerAccounts = PC_Test_Setup.createAccounts('TestPayer',1,'Payer');
            payerAccounts[0].name = 'testpayer';
            Account payer = (Account) PC_Database.ins(payerAccounts[0], false);

            Id [] fixedSearchResults= new Id[1];
            fixedSearchResults[0] = payer.Id;
            Test.setFixedSearchResults(fixedSearchResults);
            
            RestRequest re = new RestRequest();
            RestResponse rp = new RestResponse();

            re.addHeader('httpMethod', 'GET');
            re.requestURI = getURL_part;
            re.addParameter('findBy','name');
            re.addParameter('name',PC_Constants.EMPTY_STRING);
            
            RestContext.request = re;
            RestContext.response= rp;
            PC_PayerService.doGet();
            if(rp.statusCode == 200) {
                System.assert(false);
            }
            else {
                System.assert(true);
            }
           
            Test.stopTest();
        }
    }

    @isTest static void testGETNegative_ByNameStartingWithAsterisk() {
        User adminUser;
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test');
        PC_Database.ins(adminUser);
        System.runAs(adminUser) {
            Test.StartTest();


            List<Account>  payerAccounts = PC_Test_Setup.createAccounts('TestPayer',1,'Payer');
            payerAccounts[0].name = 'testpayer';
            Account payer = (Account) PC_Database.ins(payerAccounts[0], false);

            Id [] fixedSearchResults= new Id[1];
            fixedSearchResults[0] = payer.Id;
            Test.setFixedSearchResults(fixedSearchResults);
            
            RestRequest re = new RestRequest();
            RestResponse rp = new RestResponse();

            re.addHeader('httpMethod', 'GET');
            re.requestURI = getURL_part;
            re.addParameter('findBy','name');
            re.addParameter('name','*'+payer.name);
            
            RestContext.request = re;
            RestContext.response= rp;
            PC_PayerService.doGet();
            if(rp.statusCode == 200) {
                System.assert(false);
            }
            else {
                System.assert(true);
            }
           
            Test.stopTest();
        }
    }

}