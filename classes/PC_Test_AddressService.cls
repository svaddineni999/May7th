/*********************************************************************************************************
Class Name      : PC_Test_AddressService
Description     : Test class for PC_AddressService
Created By      : Deloitte
Created Date    : Oct 29, 2017
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer          Log#         Date                   Description
--------------------------------------------------------------------------------------------------------------
Mayuresh Patil                Oct 29, 2017           Initial Version
Rohit Kapoor                  Nov 14, 2017           PC-2492 -Refactor the code
Vijay Kashikar                Aug 20, 2019           PC-5326 - Replaced PC_Patient hardcoding with constant
****************************************************************************************************************/


@isTest
public class PC_Test_AddressService {
	public static final String getURL_part = '/services/apexrest/' + PC_Constants.OrgNamespace + '/1.0/address/';
    
    public static string createRequestJSONBody(id patientId)
    {
        
        map<string,Object> reqPatientAddMap = new map<string, Object>();
        reqPatientAddMap.put('city','Bengaluru');
        reqPatientAddMap.put('address1', 'street1');

        if(patientId != null)
        {
            reqPatientAddMap.put('patientId', patientId);
        }
        
        return (JSON.serialize(reqPatientAddMap));
    }

    @isTest static void testGET() {
        User adminUser;
        
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test100');
        
        PC_Database.ins(adminUser);
        System.runAs(adminUser) 
        {
            Test.StartTest();
            Account  patient = PC_Test_Setup.createEWPPatient('testpatient', '1988-05-30', 'Mr.' , PC_Constants.PATIENT_RECORD_TYPE);
            patient = (Account)PC_Database.ins(patient, false);
         	
            PC_Address__c address = PC_Test_Setup.createAddress(patient.Id);
            address = (PC_Address__c) PC_Database.ins(address, false);
            
            RestRequest re = new RestRequest(); 
            RestResponse rp = new RestResponse();
            re.addHeader('httpMethod', 'GET');
        
            re.requestURI = getURL_part + address.Id;
            
            RestContext.request = re;
            RestContext.response= rp;
            PC_AddressService.doGet();
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
        
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test100');
        
        PC_Database.ins(adminUser);
        System.runAs(adminUser) 
        {
            Test.StartTest();
            Account  patient = PC_Test_Setup.createEWPPatient('testpatient', '1988-05-30', 'Mr.' , PC_Constants.PATIENT_RECORD_TYPE);
            patient = (Account)PC_Database.ins(patient, false);
            
            PC_Address__c address = PC_Test_Setup.createAddress(patient.Id);
            address = (PC_Address__c) PC_Database.ins(address, false);
            
            RestRequest re = new RestRequest(); 
            RestResponse rp = new RestResponse();
            re.addHeader('httpMethod', 'GET');
        
            re.requestURI = getURL_part ;
            
            RestContext.request = re;
            RestContext.response= rp;
            PC_AddressService.doGet();
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
    @isTest static void testPOST() {
        User adminUser;
        
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test100');
        PC_Database.ins(adminUser);
        System.runAs(adminUser) 
        {
            Test.StartTest();
            Account  patient = PC_Test_Setup.createEWPPatient('testpatient', '1988-05-30', 'Mr.' , PC_Constants.PATIENT_RECORD_TYPE);
            patient = (Account)PC_Database.ins(patient, false);
         
            PC_Address__c address = PC_Test_Setup.createAddress(patient.Id);
            address = (PC_Address__c) PC_Database.ins(address, false);
            
            RestRequest re = new RestRequest(); 
            RestResponse rp = new RestResponse();
        
            string reqBodyInJSON = createRequestJSONBody(patient.Id);
            system.debug('reqBodyInJSON--'+ reqBodyInJSON);

            re.requestBody = Blob.valueOf(reqBodyInJSON); 
            re.requestURI = getURL_part;
            re.httpMethod = 'POST';
            RestContext.request = re;
            RestContext.response= rp;
            PC_AddressService.doPOST();
            
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
}