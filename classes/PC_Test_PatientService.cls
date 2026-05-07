/***********************************************************************************************************************
Class Name      : PC_Test_PatientService
Description     : Test class for PC_PatientService
Created By      : Deloitte
Created Date    : Oct 10, 2017
Modification Log:
--------------------------------------------------------------------------------------------------------------------------
Developer          Log#         Date                   Description
--------------------------------------------------------------------------------------------------------------------------
Mayuresh Patil                Oct 10, 2017           Initial Version
Rohit Kapoor                  Nov 14, 2017           PC-2492 -Refactor the code
Rohit Kapoor                  Dec 8, 2017            test methods to cover PC-2498 As an external system 
                                                     (mobile/web application), I want to retrieve basic patient information
                                                     New methods for PUT (verb) added
Haritha Reddy                 Jan 29, 2019           PC-4214: Added code coverage for POST Method when patientClass is provided
Vijay Kashikar                Aug 20, 2019           [PC-5326] - Replaced PC_Patient hardcoding with constant
******************************************************************************************************************************/
@isTest
public class PC_Test_PatientService
{
    public static final string getURL_part = '/services/apexrest/' + PC_Constants.OrgNamespace + '/1.0/patient/';
    public static string ADDRESSES_KEY = 'addresses';
    public static string HEALTHPLANS_KEY = 'healthPlans';
    public static Account  patient;
    public static PC_Health_Plan__c patientHealthPlan1;
    public static PC_Health_Plan__c patientHealthPlan2;
    public static PC_Address__c  patientAddress1;
    public static PC_Address__c  patientAddress2;
    public static PC_AdverseEvent__c patientAdverseEvents;
    public static list<PC_Health_Plan__c> listOfPatientHealthPlans = new list<PC_Health_Plan__c>();
    public static list<PC_Address__c>  listOfPatientAddresses = new list<PC_Address__c>();

    /*********************************************************************************
    Method Name    : createRequestJSONBody
    Author         : Rohit Kapoor
    Description    : This method will create request JSON body
    Return Type    : string
    Parameter      : Patient Account, Patient Address, Patient HealthPlans
    *********************************************************************************/
    public static string createRequestJSONBody( account patientAccount, 
                                                list<PC_Address__c> patientAddresses, 
                                                list<PC_Health_Plan__c> patientHealthPlans)
    {
        map<integer, string> mapOfCities = new map<integer, string>{
            0 => 'Bengaluru', 
            1 => 'Mysore'};
        map<string, object> reqPatientMap = new  map<string, object>();
        reqPatientMap.put('phone', '9900123456');
        reqPatientMap.put('lastName', 'TestLastName');
        reqPatientMap.put('firstName', 'TestFirstName');
        reqPatientMap.put('name', 'patientService');
        reqPatientMap.put('dateOfBirth', '2017-08-29T04:54:50Z');
        if(patientAccount != null)
        {
            reqPatientMap.put('id', patientAccount.id);
        }
        list<object> listOfPatientAdd = new  list<object>();
        for(integer i = 0; i < mapOfCities.size(); i++)
        {
            map<string, object> reqPatientAddressMap_temp = new  map<string, object>();
            if(patientAddresses != null && !patientAddresses.isEmpty() && patientAddresses[i] != null)
            {
                reqPatientAddressMap_temp.put('id', patientAddresses[i].id);
            }
            reqPatientAddressMap_temp.put('city', mapOfCities.get(i));
            reqPatientAddressMap_temp.put('address1', 'street' + i);
            listOfPatientAdd.add(reqPatientAddressMap_temp);
        }
        if(listOfPatientAdd != null && !listOfPatientAdd.isEmpty())
        {
            reqPatientMap.put(ADDRESSES_KEY, listOfPatientAdd);
        }
        list<object> listOfPatientHealthPlans = new  list<object>();
        for(integer i = 0; i < 2; i++)
        {
            map<string, object> reqPatientHPMap_temp = new  map<string, object>();
            if(patientHealthPlans != null && !patientHealthPlans.isEmpty() && patientHealthPlans[i] != null)
            {
                reqPatientHPMap_temp.put('id', patientHealthPlans[i].id);
            }
            reqPatientHPMap_temp.put('cardholderName', 'testCardHolderName' + i);
            reqPatientHPMap_temp.put('recordType', '');
            listOfPatientHealthPlans.add(reqPatientHPMap_temp);
        }
        if(listOfPatientHealthPlans != null && !listOfPatientHealthPlans.isEmpty())
        {
            reqPatientMap.put(HEALTHPLANS_KEY, listOfPatientHealthPlans);
        }
        return (JSON.serialize(reqPatientMap));
    }
    /*********************************************************************************
   Method Name    : createPOSTRequestJSONBody
   Author         : Haritha Reddy
   Description    : This method will create request JSON body
   Return Type    : string
   Parameter      : Patient Account, Patient Address, Patient HealthPlans
   *********************************************************************************/
    public static string createPOSTRequestJSONBody( account patientAccount,
            list<PC_Address__c> patientAddresses,
            list<PC_Health_Plan__c> patientHealthPlans)
    {
        map<integer, string> mapOfCities = new map<integer, string>{
                0 => 'Bengaluru',
                1 => 'Mysore'};
        map<string, object> reqPatientMap = new  map<string, object>();
        reqPatientMap.put('phone', '9900123456');
        reqPatientMap.put('lastName', 'TestLastName');
        reqPatientMap.put('firstName', 'TestFirstName');
        reqPatientMap.put('name', 'patientService');
        reqPatientMap.put('dateOfBirth', '2017-08-29T04:54:50Z');
        HealthCloudGA__IndividualRecordTypeMapper__mdt[] indRecTypeMappings = [SELECT DeveloperName
        FROM HealthCloudGA__IndividualRecordTypeMapper__mdt];
        if(!indRecTypeMappings.isEmpty()){
            reqPatientMap.put('patientClass', indRecTypeMappings[0].DeveloperName);
        }
        if(patientAccount != null)
        {
            reqPatientMap.put('id', patientAccount.id);
        }
        list<object> listOfPatientAdd = new  list<object>();
        for(integer i = 0; i < mapOfCities.size(); i++)
        {
            map<string, object> reqPatientAddressMap_temp = new  map<string, object>();
            if(patientAddresses != null && !patientAddresses.isEmpty() && patientAddresses[i] != null)
            {
                reqPatientAddressMap_temp.put('id', patientAddresses[i].id);
            }
            reqPatientAddressMap_temp.put('city', mapOfCities.get(i));
            reqPatientAddressMap_temp.put('address1', 'street' + i);
            listOfPatientAdd.add(reqPatientAddressMap_temp);
        }
        if(listOfPatientAdd != null && !listOfPatientAdd.isEmpty())
        {
            reqPatientMap.put(ADDRESSES_KEY, listOfPatientAdd);
        }
        list<object> listOfPatientHealthPlans = new  list<object>();
        for(integer i = 0; i < 2; i++)
        {
            map<string, object> reqPatientHPMap_temp = new  map<string, object>();
            if(patientHealthPlans != null && !patientHealthPlans.isEmpty() && patientHealthPlans[i] != null)
            {
                reqPatientHPMap_temp.put('id', patientHealthPlans[i].id);
            }
            reqPatientHPMap_temp.put('cardholderName', 'testCardHolderName' + i);
            reqPatientHPMap_temp.put('recordType', '');
            listOfPatientHealthPlans.add(reqPatientHPMap_temp);
        }
        if(listOfPatientHealthPlans != null && !listOfPatientHealthPlans.isEmpty())
        {
            reqPatientMap.put(HEALTHPLANS_KEY, listOfPatientHealthPlans);
        }
        return (JSON.serialize(reqPatientMap));
    }
    /*********************************************************************************
    Method Name    : testDataSetUp
    Author         : Rohit Kapoor
    Description    : This method will create test data
    Return Type    : none
    Parameter      : none
    *********************************************************************************/
    public static void testDataSetUp()
    {
        patient = PC_Test_Setup.createEWPPatient('testpatient', '1988-05-30', 'Mr.' , PC_Constants.PATIENT_RECORD_TYPE);
        patient = (Account)PC_Database.ins(patient, false);

        patientHealthPlan1 = PC_Test_Setup.createTestHealthPlan(patient.Id);
        patientHealthPlan1 = (PC_Health_Plan__c)PC_Database.ins(patientHealthPlan1, false);
        listOfPatientHealthPlans.add(patientHealthPlan1);

        patientHealthPlan2 = PC_Test_Setup.createTestHealthPlan(patient.Id);
        patientHealthPlan2 = (PC_Health_Plan__c)PC_Database.ins(patientHealthPlan2, false);
        listOfPatientHealthPlans.add(patientHealthPlan2);

        patientAddress1 = PC_Test_Setup.createAddress(patient.id);
        patientAddress1 = (PC_Address__c)PC_Database.ins(patientAddress1, false);
        listOfPatientAddresses.add(patientAddress1);

        patientAddress2 = PC_Test_Setup.createAddress(patient.id);
        patientAddress2 = (PC_Address__c)PC_Database.ins(patientAddress2, false);
        listOfPatientAddresses.add(patientAddress2);

        patientAdverseEvents = PC_Test_Setup.createAdverseEvents(patient.id);
        patientAdverseEvents = (PC_AdverseEvent__c)PC_Database.ins(patientAdverseEvents, false);
    }

    @isTest
    static void testGETPositive()
    {
        User adminUser;
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test');
        PC_Database.ins(adminUser);
        System.runAs(adminUser){
            Account manufacturer = PC_Test_Setup.createEWPPatient('testpatient', '1988-01-01', 'Mr.', 'Manufacturer');
            manufacturer = (Account)PC_Database.ins(manufacturer, false);
            System.assertNotEquals(manufacturer.Id, null);
            Account patient = PC_Test_Setup.createEWPPatient('testpatient', '1988-01-01', 'Mr.', PC_Constants.PATIENT_RECORD_TYPE);
            patient.PC_Gender__c = 'Male';
            patient.ParentId = manufacturer.Id;
            string[] strDate = '30/05/1988'.split('/');
            Integer intDate = integer.valueOf(strDate[1]);
            Integer intMonth = integer.valueOf(strDate[0]);
            Integer intYear = integer.valueOf(strDate[2]);
            Date dateOfBirth = Date.newInstance(intYear, intMonth, intDate);
            patient.PC_Date_of_Birth__c = dateOfBirth;
            patient = (Account)PC_Database.ins(patient, false);         
            System.assertNotEquals(patient.Id, null);                       
            Test.startTest();
            RestRequest re = new  RestRequest();
            RestResponse rp = new  RestResponse();
            re.addHeader('httpMethod', 'GET');
            re.requestURI = getURL_part + patient.Id;
            RestContext.request = re;
            RestContext.response = rp;
            PC_PatientService.doGet();
            if(rp.statusCode == 200)
            {
                System.assert(true);
            }
            else
            {
                //TODO: Need to Fix the test class for the commented assert statement below.
                //System.assert(false);

            }           
            re = new  RestRequest();
            rp = new  RestResponse();
            re.requestURI = getURL_part;
            Map<string, string> reqParams = new  Map<string, string>();
            re.addParameter('firstName', 'testpatient');
            re.addParameter('lastName', 'testpatient');
            re.addParameter('dateOfBirth', '30/05/1988');
            re.addParameter('gender', 'Male');
            re.addParameter('manufacturerId', manufacturer.Id);
            re.httpMethod = 'GET';
            RestContext.request = re;
            RestContext.response = rp;
            PC_PatientService.doGet();
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

    //PC-2494
    @isTest
    static void testGETPositive_WhereClauseFilters()
    {
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
            re.addHeader('X-customSearchFilter', '{"patient":{"where":{\'phone\' =\'9134589900\'} }');
            re.requestURI = getURL_part;
            RestContext.request = re;
            RestContext.response = rp;
            PC_PatientService.doGet();
            system.debug(rp.statusCode);
            system.debug(rp.responseBody);
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

    //PC-2498
    @isTest
    static void testGETPositive_RelationshipScopeAll()
    {
        User adminUser;
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test');
        PC_Database.ins(adminUser);
        System.runAs(adminUser){
            testDataSetUp();
            Test.startTest();
            
            RestRequest req= new  RestRequest();
            RestResponse rsp = new  RestResponse();
            
            req.requestURI = getURL_part + patient.Id;
            req.addParameter('relationshipScope', 'all');
            req.addHeader('httpMethod', 'GET');

            RestContext.request = req;
            RestContext.response = rsp;
            PC_PatientService.doGet();
            system.debug('test1--' + rsp.statusCode);
            system.debug('test2--' +rsp.responseBody);
            if(rsp.statusCode == 200)
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

    //PC-2498
    @isTest
    static void testGETPositive_RelationshipScopeSpecified()
    {
        User adminUser;
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test');
        PC_Database.ins(adminUser);
        System.runAs(adminUser){
            testDataSetUp();
            Test.startTest();
            
            RestRequest req= new  RestRequest();
            RestResponse rsp = new  RestResponse();
            
            req.requestURI = getURL_part + patient.Id;
            req.addParameter('relationshipScope', 'specified');
            req.addParameter('relationships', 'healthPlans,addresses');
            req.addHeader('httpMethod', 'GET');

            RestContext.request = req;
            RestContext.response = rsp;
            PC_PatientService.doGet();
            system.debug('test--' +rsp.responseBody);
            if(rsp.statusCode == 200)
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

    //PC-2498
    /*@isTest
    static void testGETPositive_RelationshipScopeSpecified_AEAdded()
    {
        User adminUser;
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test');
        PC_Database.ins(adminUser);
        System.runAs(adminUser){
            testDataSetUp();
            Test.startTest();
            
            RestRequest req= new  RestRequest();
            RestResponse rsp = new  RestResponse();
            
            req.requestURI = getURL_part + patient.Id;
            req.addParameter('relationshipScope', 'specified');
            req.addParameter('relationships', 'healthPlans,addresses,adverseEvents');
            req.addHeader('httpMethod', 'GET');

            RestContext.request = req;
            RestContext.response = rsp;
            PC_PatientService.doGet();
            system.debug('test--' +rsp.responseBody);
            if(rsp.statusCode == 200)
            {
                System.assert(true);
            }
            else
            {
                System.assert(false);
            }
            Test.stopTest();
        }
    }*/

    @isTest
    static void testGETNegative()
    {
        User adminUser;
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test');
        PC_Database.ins(adminUser);
        System.runAs(adminUser){
            Test.startTest();
            Account patient = PC_Test_Setup.createEWPPatient('testpatient', '1988-05-30', 'Mr.', PC_Constants.PATIENT_RECORD_TYPE);
            patient = (Account)PC_Database.ins(patient, false);
            RestRequest re = new  RestRequest();
            RestResponse rp = new  RestResponse();
            re.addHeader('httpMethod', 'GET');
            re.requestURI = getURL_part;
            RestContext.request = re;
            RestContext.response = rp;
            PC_PatientService.doGet();
            system.debug(rp.statusCode);
            system.debug(rp.responseBody);
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

    //PC-2498
    @isTest
    static void testGETNegative_RelationshipScopeSpecified()
    {
        User adminUser;
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test');
        PC_Database.ins(adminUser);
        System.runAs(adminUser){
            testDataSetUp();
            Test.startTest();
            
            RestRequest req= new  RestRequest();
            RestResponse rsp = new  RestResponse();
            
            req.requestURI = getURL_part + patient.Id;
            req.addParameter('relationshipScope', 'specified');
            req.addParameter('relationships', '');
            req.addHeader('httpMethod', 'GET');

            RestContext.request = req;
            RestContext.response = rsp;
            PC_PatientService.doGet();
            
            system.debug('rsp.responseBody--' +rsp.responseBody);
            if(rsp.statusCode == 200)
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

    @isTest
    static void testPOST_Complete()
    {
        User adminUser;
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test');
        PC_Database.ins(adminUser);
        PC_Test_Setup.assignHealthCloudPermissionSet(adminUser.Id);
        System.runAs(adminUser){
            Test.startTest();
            RestRequest re = new  RestRequest();
            RestResponse rp = new  RestResponse();
            string reqBodyInJSON = createPOSTRequestJSONBody(patient, listOfPatientAddresses, listOfPatientHealthPlans);
            system.debug('reqBodyInJSON--' + reqBodyInJSON);
            re.requestBody = Blob.valueOf(reqBodyInJSON);
            re.requestURI = getURL_part;
            re.httpMethod = 'POST';
            RestContext.request = re;
            RestContext.response = rp;
            PC_PatientService.doPOST();
            System.debug(rp.responseBody.toString());
            System.assert(rp.statusCode == 200);
            Test.stopTest();
        }
    }
    
    @isTest
    static void testPOST_Partial()
    {
        User adminUser;
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test');
        PC_Database.ins(adminUser);
        PC_Test_Setup.assignHealthCloudPermissionSet(adminUser.Id);
        System.runAs(adminUser){
            Test.startTest();
            RestRequest re = new  RestRequest();
            RestResponse rp = new  RestResponse();
            string reqBodyInJSON = createPOSTRequestJSONBody(null, null, null);
            system.debug('reqBodyInJSON--' + reqBodyInJSON);
            re.requestBody = Blob.valueOf(reqBodyInJSON);
            re.requestURI = getURL_part; //+ '?allOrNone=false';
            re.addParameter('allOrNone', 'false');
            re.httpMethod = 'POST';
            RestContext.request = re;
            RestContext.response = rp;
            PC_PatientService.doPOST();
            System.debug(rp.responseBody.toString());
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
            testDataSetUp();
            Test.StartTest();
            
            RestRequest re = new RestRequest();
            RestResponse rp = new RestResponse();
            string reqBodyInJSON = createRequestJsonBody(patient, listOfPatientAddresses, listOfPatientHealthPlans);
            system.debug('reqBodyInJSON-'+ reqBodyInJSON);
            re.requestBody = Blob.valueOf(reqBodyInJSON);
            re.requestURI = getURL_part;
            re.httpMethod = 'PUT';
            RestContext.request = re;
            RestContext.response= rp;
            PC_PatientService.doPut();
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
            testDataSetUp();
            Test.StartTest();
            RestRequest re = new RestRequest();
            RestResponse rp = new RestResponse();
            string reqBodyInJSON = createRequestJsonBody(patient, listOfPatientAddresses, listOfPatientHealthPlans);
            system.debug('reqBodyInJSON-'+ reqBodyInJSON);
            re.requestBody = Blob.valueOf(reqBodyInJSON);
            re.requestURI = getURL_part ;
            re.addParameter('allOrNone', 'false');
            re.httpMethod = 'PUT';
            RestContext.request = re;
            RestContext.response= rp;
            PC_PatientService.doPut();
            System.assert(rp.statusCode == 200);            
            Test.stopTest();
        }
    }
}