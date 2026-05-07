/*********************************************************************************************************
Class Name      : PC_Test_ApplicantService
Description     : Test class for PC_ApplicantService
Created By      : Deloitte
Created Date    : Aug 24, 2017
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer          Log#         Date                   Description
--------------------------------------------------------------------------------------------------------------
Vijay Kashikar                Aug 24, 2017           Initial Version
Rohit Kapoor                  Nov 14, 2017           PC-2492 -Refactor the code
Shishir Bansal                10-Dec-2019           [PC-5792] Avoid hardcoding of string variable
****************************************************************************************************************/

 
@IsTest
public with sharing class PC_Test_ApplicantService {
    public static final String getURL_part = '/services/apexrest/' + PC_Constants.OrgNamespace + '/1.0/applicant/';
    
    public static final string ADDRESSES_KEY = 'addresses';
    public static final string HEALTHPLANS_KEY = 'healthPlans';

    public static string createRequestJSONBody()
    {
        
        map<integer, string> mapOfCities = new map<integer, string>{0 => 'Bengaluru', 1 => 'Mysore'};
        
        map<string,Object> reqPatientMap = new map<string, Object>();
        reqPatientMap.put('phone','9900123456');
        reqPatientMap.put('lastName','TestLastName');
        reqPatientMap.put('firstName','TestFirstName');
        reqPatientMap.put('dateOfBirth','2017-08-29T04:54:50Z'); 


        list<Object> listOfPatientAdd = new list<Object>();
        for(integer i=0 ; i < mapOfCities.size(); i++)
        {
            map<string,Object> reqPatientAddressMap_temp= new map<string, Object>();
            reqPatientAddressMap_temp.put('city',mapOfCities.get(i));
            reqPatientAddressMap_temp.put('address1', 'street'+i);
            
            listOfPatientAdd.add(reqPatientAddressMap_temp);
        }
        if(listOfPatientAdd != null && !listOfPatientAdd.isEmpty())
        {
            reqPatientMap.put(ADDRESSES_KEY, listOfPatientAdd);
        }

        list<Object> listOfPatientHealthPlans = new list<Object>();
        for(integer i=0 ; i < 2; i++)
        {
            map<string,Object> reqPatientHPMap_temp= new map<string, Object>();
            reqPatientHPMap_temp.put('cardholderName','testCardHolderName'+i);
            reqPatientHPMap_temp.put('recordType', '');
            
            listOfPatientHealthPlans.add(reqPatientHPMap_temp);
        }
        if(listOfPatientHealthPlans != null && !listOfPatientHealthPlans.isEmpty())
        {
            reqPatientMap.put(HEALTHPLANS_KEY, listOfPatientHealthPlans);
        }
        
        return (JSON.serialize(reqPatientMap));
    }

    @isTest static void testPOSTPositive() {
        User adminUser;

        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test');
        PC_Database.ins(adminUser);
        System.runAs(adminUser) {
            Test.StartTest();

            RestRequest re = new RestRequest();
            RestResponse rp = new RestResponse();
            re.addHeader('httpMethod', 'POST');

            string reqBodyInJSON = createRequestJSONBody();
            system.debug('reqBodyInJSON--'+ reqBodyInJSON);
            
            re.requestBody = Blob.valueOf(reqBodyInJSON);
            re.requestURI = getURL_part;
            RestContext.request = re;
            RestContext.response= rp;
            PC_ApplicantService.doPOST();
           
            if(rp.statusCode == 200) {
                System.assert(true);
            }
            else {
                System.debug(rp.responseBody.toString());
                System.assert(false);
            }
            Test.stopTest();
        }
    }

    @isTest static void testPOSTNegative() {
        User adminUser;

        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test');
        PC_Database.ins(adminUser);
        System.runAs(adminUser) {
            Test.StartTest();

            RestRequest re = new RestRequest();
            RestResponse rp = new RestResponse();
            re.addHeader('httpMethod', 'POST');

            string reqBodyInJSON = PC_Constants.EMPTY_STRING;
            system.debug('reqBodyInJSON--'+ reqBodyInJSON);
            
            re.requestBody = Blob.valueOf(reqBodyInJSON);
            re.requestURI = getURL_part;
            RestContext.request = re;
            RestContext.response= rp;
            PC_ApplicantService.doPOST();
           
            if(rp.statusCode == 200) {
                System.assert(false);
            }
            else {
                System.debug(rp.responseBody.toString());
                System.assert(true);
            }
            Test.stopTest();
        }
    }
}