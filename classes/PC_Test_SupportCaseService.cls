/*********************************************************************************************************
Class Name      : PC_Test_SupportCaseService
Description     : Test class for PC_SupportCaseService
Created By      : Deloitte
Created Date    : Oct 29, 2017
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer          Log#         Date                   Description
--------------------------------------------------------------------------------------------------------------
Mayuresh Patil                Oct 29, 2017           Initial Version
Rohit Kapoor                  Nov 14, 2017           PC-2492 - Refactor the code
Vijay Kashikar                Aug 20, 2019           [PC-5326] - Replaced PC_Patient hardcoding with constant
****************************************************************************************************************/

@isTest
public class PC_Test_SupportCaseService {
    public static final String getURL_part = '/services/apexrest/' + PC_Constants.OrgNamespace + '/1.0/supportCase/';
    
    public static string createRequestJSONBody(id programId)
    {
        
        map<string,Object> reqSupportCasestMap = new map<string, Object>();
        if(programId != null)
        {
            reqSupportCasestMap.put('programId', programId);
        }
        reqSupportCasestMap.put('recordType','PC_Alternate_Funding');
        
        return (JSON.serialize(reqSupportCasestMap));
    }

    @isTest static void testGETPositive_ByProgramId() {
        User adminUser;
        
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test');
        PC_Database.ins(adminUser);
        System.runAs(adminUser) 
        {
            Test.StartTest();
            Account  patient = PC_Test_Setup.createEWPPatient('testpatient', '1988-05-30', 'Mr.' , PC_Constants.PATIENT_RECORD_TYPE);
            patient = (Account)PC_Database.ins(patient, false);
            
            Case program = PC_Test_Setup.createProgram(patient); // createProgram does the insert
         	
            RestRequest re = new RestRequest(); 
            RestResponse rp = new RestResponse();
            re.addHeader('httpMethod', 'GET');
            re.requestURI = getURL_part + 'findByProgramId/' + program.Id;
            
            RestContext.request = re;
            RestContext.response= rp;
            PC_SupportCaseService.doGet();
            if(rp.statusCode == 200) 
            {
            	System.assert(true);
            }
            else 
            {
                system.debug(rp.responseBody.toString());
                System.assert(false);
            }
            Test.stopTest();
        }
    }

    @isTest static void testGETNegative() {
        User adminUser;
        
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test');
        PC_Database.ins(adminUser);
        System.runAs(adminUser) 
        {
            Test.StartTest();
            Account  patient = PC_Test_Setup.createEWPPatient('testpatient', '1988-05-30', 'Mr.' , PC_Constants.PATIENT_RECORD_TYPE);
            patient = (Account)PC_Database.ins(patient, false);
            
            Case program = PC_Test_Setup.createProgram(patient); // createProgram does the insert
            
            RestRequest re = new RestRequest(); 
            RestResponse rp = new RestResponse();
            re.addHeader('httpMethod', 'GET');
            re.requestURI = getURL_part + 'findByProgramId/';
            
            RestContext.request = re;
            RestContext.response= rp;
            PC_SupportCaseService.doGet();
            if(rp.statusCode == 200) 
            {
                System.assert(false);
            }
            else 
            {
                system.debug(rp.responseBody.toString());
                System.assert(true);
            }
            Test.stopTest();
        }
    }
    @isTest static void testPOST() {
        User adminUser;
        
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test');
        PC_Database.ins(adminUser);
        System.runAs(adminUser) 
        {
            Test.StartTest();
            Account  patient = PC_Test_Setup.createEWPPatient('testpatient', '1988-05-30', 'Mr.' , PC_Constants.PATIENT_RECORD_TYPE);
            patient = (Account)PC_Database.ins(patient, false);
            
            List<Account> manufacturers = PC_Test_Setup.createAccounts('pRootNameManufacturer', 1, 'Manufacturer');
            manufacturers = (List<Account>)PC_Database.ins(manufacturers, false);
            
            PC_Engagement_Program__c engProg = PC_Test_Setup.createEngagementProgram('RESTPRG', manufacturers[0].Id);
            engProg = (PC_Engagement_Program__c) PC_Database.ins(engProg, false);
         
            Case program = PC_Test_Setup.createProgram(patient); // createProgram does the insert
            
            RestRequest re = new RestRequest(); 
            RestResponse rp = new RestResponse();
            re.addHeader('httpMethod', 'POST');
        
            string reqBodyInJSON = createRequestJSONBody(program.id);
            system.debug('reqBodyInJSON--'+ reqBodyInJSON);

            Map<String, String> requestBody = new Map<String, String>();
            
            re.requestBody = Blob.valueOf(reqBodyInJSON); 
            re.requestURI = getURL_part;
            re.httpMethod = 'POST';
            RestContext.request = re;
            RestContext.response= rp;
            PC_SupportCaseService.doPOST();
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