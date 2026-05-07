/*********************************************************************************************************
Class Name      : PC_TestProviderService
Description     : Test class for PC_ProviderService
Created By      : Deloitte
Created Date    : Aug 28, 2017
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer          Log#         Date                   Description
--------------------------------------------------------------------------------------------------------------
Vijay Kashikar                Aug 28, 2017           Initial Version
Rohit Kapoor                  Nov 14, 2017           PC-2492 -Refactor the code
Sourav Sharma                 Dec 08, 2017           PC-2556 - Changed PC_NPI__c field to hold only numeric value. 
Rohit Kapoor                  Dec 08, 2017           PC-2556 - Changed PC_NPI__c field to hold only numeric value. 
                                                     and modify PUT test methods
Vijay Kashikar                Aug 20, 2019           [PC-5326] - Replaced PC_Patient hardcoding with constant
****************************************************************************************************************/


@IsTest
private class PC_TestProviderService {
    public static final String getURL_part = '/services/apexrest/' + PC_Constants.OrgNamespace + '/1.0/physician/';
    public static final string ADDRESSES_KEY = 'addresses';
    
    public static string createRequestJsonBody(Account physician, PC_Address__c phyAddress)
    {
        
        map<integer, string> mapOfCities = new map<integer, string>{0 => 'Bengaluru'};
        
        map<string,Object> reqProviderMap = new map<string, Object>();
        if(physician != null)
        {
            reqProviderMap.put('id', physician.Id);
        }
        reqProviderMap.put('phone','9900123456');
        reqProviderMap.put('lastName','TestLastName');
        reqProviderMap.put('firstName','TestFirstName');
        reqProviderMap.put('name','providerService');
        reqProviderMap.put('npi','1992902043');
        list<Object> listOfProviderAdd = new list<Object>();
        for(integer i=0 ; i < mapOfCities.size(); i++)
        {
            map<string,Object> reqProviderAddressMap_temp= new map<string, Object>();
            if(phyAddress != null)
            {    
                reqProviderAddressMap_temp.put('id', phyAddress.id);
            }
            reqProviderAddressMap_temp.put('city',mapOfCities.get(i));
            reqProviderAddressMap_temp.put('address1', 'street'+i);
            
            listOfProviderAdd.add(reqProviderAddressMap_temp);
        }
        if(listOfProviderAdd != null && !listOfProviderAdd.isEmpty())
        {
            reqProviderMap.put(ADDRESSES_KEY, listOfProviderAdd);
        }               
        return (JSON.serialize(reqProviderMap));
    }

    @isTest static void testGETPositive_ByNPI() {
        User adminUser;

        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test');
        PC_Database.ins(adminUser);
        System.runAs(adminUser) 
        {
            Test.StartTest();
            Account  patient = PC_Test_Setup.createEWPPatient('testpatient', '1988-05-30', 'Mr.' , PC_Constants.PATIENT_RECORD_TYPE);
            patient = (Account)PC_Database.ins(patient, false);
            List<Account> physicians = PC_Test_Setup.createAccounts('testPhysician',1,PC_Constants.PHYSICIAN_RECORD_TYPE);
            Account physician = (Account) physicians[0];
            physician.PC_NPI__c = '1992902043';
            physician = (Account) PC_Database.ins(physician, false);
            RestRequest re = new RestRequest();
            RestResponse rp = new RestResponse();
            re.addHeader('httpMethod', 'GET');
            re.requestURI = getURL_part+'/findByNPI/' + physician.PC_NPI__c;
            RestContext.request = re;
            RestContext.response= rp;
            PC_ProviderService.doGet();
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

     @isTest static void testGETPositive_ByPhysicianId() {
        User adminUser;

        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test');
        PC_Database.ins(adminUser);
        System.runAs(adminUser) 
        {
            Test.StartTest();
            Account  patient = PC_Test_Setup.createEWPPatient('testpatient', '1988-05-30', 'Mr.' , PC_Constants.PATIENT_RECORD_TYPE);
            patient = (Account)PC_Database.ins(patient, false);
            List<Account> physicians = PC_Test_Setup.createAccounts('testPhysician',1,PC_Constants.PHYSICIAN_RECORD_TYPE);
            Account physician = (Account) physicians[0];
            physician.PC_NPI__c = '1992902043';
            physician = (Account) PC_Database.ins(physician, false);
            RestRequest re = new RestRequest();
            RestResponse rp = new RestResponse();
            re.addHeader('httpMethod', 'GET');
            re.requestURI = getURL_part+ '/'+ physician.Id;
            RestContext.request = re;
            RestContext.response= rp;
            PC_ProviderService.doGet();
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
    
    @isTest static void testGETNegative_NonExistingNPI() {
        User adminUser;

        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test');
        PC_Database.ins(adminUser);
        System.runAs(adminUser) 
        {
            Test.StartTest();
            RestRequest re = new RestRequest();
            RestResponse rp = new RestResponse();
            re.addHeader('httpMethod', 'GET');            
            re.requestURI = getURL_part+'/findByNPI/' + 'nonExistingPhy';
            RestContext.request = re;
            RestContext.response= rp;
            PC_ProviderService.doGet();
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

    @isTest static void testGETNegative_NonExistingPhysician() {
        User adminUser;

        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test');
        PC_Database.ins(adminUser);
        System.runAs(adminUser) 
        {
            Test.StartTest();
            RestRequest re = new RestRequest();
            RestResponse rp = new RestResponse();
            re.addHeader('httpMethod', 'GET');
            re.requestURI = getURL_part+ '/'+ 'nonExistent';            
            RestContext.request = re;
            RestContext.response= rp;
            PC_ProviderService.doGet();
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
    
    @isTest static void testPOST_Complete() {
        User adminUser;

        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test');
        PC_Database.ins(adminUser);
        PC_Test_Setup.assignHealthCloudPermissionSet(adminUser.Id);
        System.runAs(adminUser) 
        {
            Test.StartTest();            
            RestRequest re = new RestRequest();
            RestResponse rp = new RestResponse();
            string reqBodyInJSON = createRequestJsonBody(null, null);
            re.requestBody = Blob.valueOf(reqBodyInJSON);
            re.requestURI = getURL_part;
            re.httpMethod = 'POST';
            RestContext.request = re;
            RestContext.response= rp;
            PC_ProviderService.doPOST();
            System.assert(rp.statusCode == 200);
            Test.stopTest();
        }
    }
    
    @isTest static void testPOST_Partial() {
        User adminUser;

        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test');
        PC_Database.ins(adminUser);
        PC_Test_Setup.assignHealthCloudPermissionSet(adminUser.Id);
        System.runAs(adminUser) 
        {
            Test.StartTest();            
            RestRequest re = new RestRequest();
            RestResponse rp = new RestResponse();            
            string reqBodyInJSON = createRequestJsonBody(null, null);
            re.requestBody = Blob.valueOf(reqBodyInJSON);
            re.requestURI = getURL_part + '/?allOrNone=false';
            re.httpMethod = 'POST';
            RestContext.request = re;
            RestContext.response= rp;
            PC_ProviderService.doPOST();
            System.assert(rp.statusCode == 200);            
            Test.stopTest();
        } 
    } 
    
    @isTest static void testPUT_Complete() {
        User adminUser;

        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test');
        PC_Database.ins(adminUser);
        PC_Test_Setup.assignHealthCloudPermissionSet(adminUser.Id);
        System.runAs(adminUser) 
        {
            Test.StartTest();
            List<Account> physicians = PC_Test_Setup.createAccounts('testPhysician',1,PC_Constants.PHYSICIAN_RECORD_TYPE);
            Account physician = (Account) physicians[0];
            physician.PC_NPI__c = '1992902043';
            physician = (Account) PC_Database.ins(physician, false);
            PC_Address__c address = PC_Test_Setup.createAddress(physician.Id);
            address = (PC_Address__c) PC_Database.ins(address, false);
            RestRequest re = new RestRequest();
            RestResponse rp = new RestResponse();
            string reqBodyInJSON = createRequestJsonBody(physician, address);
            re.requestBody = Blob.valueOf(reqBodyInJSON);
            re.requestURI = getURL_part;
            re.httpMethod = 'PUT';
            RestContext.request = re;
            RestContext.response= rp;
            PC_ProviderService.doPut();
            System.assert(rp.statusCode == 200);            
            Test.stopTest();
        }
    }

     @isTest static void testPUT_Partial() {
        User adminUser;

        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test');
        PC_Database.ins(adminUser);
         PC_Test_Setup.assignHealthCloudPermissionSet(adminUser.Id);
        System.runAs(adminUser) 
        {
            Test.StartTest();
            List<Account> physicians = PC_Test_Setup.createAccounts('testPhysician',1,PC_Constants.PHYSICIAN_RECORD_TYPE);
            Account physician = (Account) physicians[0];
            physician.PC_NPI__c = '1992902043';
            physician = (Account) PC_Database.ins(physician, false);
            PC_Address__c address = PC_Test_Setup.createAddress(physician.Id);
            address = (PC_Address__c) PC_Database.ins(address, false);
            RestRequest re = new RestRequest();
            RestResponse rp = new RestResponse();
            string reqBodyInJSON = createRequestJsonBody(physician, address);
            re.requestBody = Blob.valueOf(reqBodyInJSON);
            re.requestURI = getURL_part ;//+ '/?allOrNone=false';
            re.addParameter('allOrNone', 'false');
            re.httpMethod = 'PUT';
            RestContext.request = re;
            RestContext.response= rp;
            PC_ProviderService.doPut();
            System.assert(rp.statusCode == 200);            
            Test.stopTest();
        }
    }
}