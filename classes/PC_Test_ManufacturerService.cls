/*********************************************************************************************************
Class Name      : PC_Test_ManufacturerService
Description     : Test class for PC_ManufacturerService
Created By      : Deloitte
Created Date    : Oct 29, 2017
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer          Log#         Date                   Description
--------------------------------------------------------------------------------------------------------------
Mayuresh Patil                Oct 29, 2017           Initial Version
Rohit Kapoor                  Nov 14, 2017           PC-2492 -Refactor the code
Vijay Kashikar                Aug 20, 2019           [PC-5326] - Replaced PC_Patient hardcoding with constant
****************************************************************************************************************/


@isTest
public class PC_Test_ManufacturerService {
	public static String getURL_part = '/services/apexrest/' + PC_Constants.OrgNamespace + '/1.0/manufacturer/';
    
    @isTest static void testGETPositive_ByRecordId() {
        User adminUser;
        String manufacturerName = 'TestManufacturer';
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test');

        PC_Database.ins(adminUser);
        System.runAs(adminUser) {
            Test.StartTest();
            
            Account  patient = PC_Test_Setup.createEWPPatient('testpatient', '1988-05-30', 'Mr.' , PC_Constants.PATIENT_RECORD_TYPE);
            patient = (Account)PC_Database.ins(patient, false);
            
            List<Account>  manufacturers = PC_Test_Setup.createAccounts('TestManufacturer',1,'Manufacturer');
            manufacturers[0].name = manufacturerName;
            Account manufacturer = (Account) PC_Database.ins(manufacturers[0], false);
            
            Id [] fixedSearchResults= new Id[1];
            fixedSearchResults[0] = manufacturer.Id;
            Test.setFixedSearchResults(fixedSearchResults);

            RestRequest re = new RestRequest(); 
            RestResponse rp = new RestResponse();
            re.addHeader('httpMethod', 'GET');
        	
            re.requestURI = getURL_part + manufacturer.Id;            
            RestContext.request = re;
            RestContext.response= rp;
            
            PC_ManufacturerService.doGet();
            if(rp.statusCode == 200) {
            	System.assert(true);
            }
            else {
                System.assert(false);
            }
            
            Test.stopTest();
        }
    }

    @isTest static void testGETPositive_ByName() {
        User adminUser;
        String manufacturerName = 'TestManufacturer';
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test');

        PC_Database.ins(adminUser);
        System.runAs(adminUser) 
        {
            Test.StartTest();
            
        Account  patient = PC_Test_Setup.createEWPPatient('testpatient', '1988-05-30', 'Mr.' , PC_Constants.PATIENT_RECORD_TYPE);
            patient = (Account)PC_Database.ins(patient, false);
            
            List<Account>  manufacturers = PC_Test_Setup.createAccounts('TestManufacturer',1,'Manufacturer');
            manufacturers[0].name = manufacturerName;
            Account manufacturer = (Account) PC_Database.ins(manufacturers[0], false);
            
            Id [] fixedSearchResults= new Id[1];
            fixedSearchResults[0] = manufacturer.Id;
            Test.setFixedSearchResults(fixedSearchResults);

            RestRequest re = new RestRequest(); 
            RestResponse rp = new RestResponse();
            re.addHeader('httpMethod', 'GET');
            re.requestURI = getURL_part + 'findByName/' + manufacturerName;

            RestContext.request = re;
            RestContext.response= rp;

            PC_ManufacturerService.doGet();
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
        String manufacturerName = 'TestManufacturer';
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test');

        PC_Database.ins(adminUser);
        System.runAs(adminUser) 
        {
            Test.StartTest();
            
            Account  patient = PC_Test_Setup.createEWPPatient('testpatient', '1988-05-30', 'Mr.' , PC_Constants.PATIENT_RECORD_TYPE);
            patient = (Account)PC_Database.ins(patient, false);
            
            List<Account>  manufacturers = PC_Test_Setup.createAccounts('TestManufacturer',1,'Manufacturer');
            manufacturers[0].name = manufacturerName;
            Account manufacturer = (Account) PC_Database.ins(manufacturers[0], false);
            
            Id [] fixedSearchResults= new Id[1];
            fixedSearchResults[0] = manufacturer.Id;
            Test.setFixedSearchResults(fixedSearchResults);

            RestRequest re = new RestRequest(); 
            RestResponse rp = new RestResponse();
            re.addHeader('httpMethod', 'GET');
            re.requestURI = getURL_part;

            RestContext.request = re;
            RestContext.response= rp;

            PC_ManufacturerService.doGet();
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