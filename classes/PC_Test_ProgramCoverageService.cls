/*********************************************************************************************************
Class Name      : PC_Test_ProgramCoverageService
Description     : Test class for PC_ProgramCoverageService
Created By      : Deloitte
Created Date    : Nov 16, 2017
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer          Log#         Date                   Description
--------------------------------------------------------------------------------------------------------------
Rohit Kapoor                  Nov 16, 2017           Initial Version
Rohit Kapoor                  Nov 19, 2017           PC-2499 -As an external system (mobile/web application), 
													 I want to retrieve a patient's benefit details
Vijay Kashikar                Aug 20, 2019           [PC-5326] - Replaced PC_Patient hardcoding with constant
****************************************************************************************************************/
@isTest
public class PC_Test_ProgramCoverageService
{
	public static final String getURL_part = '/services/apexrest/' + PC_Constants.OrgNamespace + '/1.0/programCoverage/';
    public static Account  patient;
    public static PC_Health_Plan__c healthPlan;
    public static List<Account> manufacturers = new list<Account>();
    public static PC_Engagement_Program__c engProg;
    public static Case program;
    public static PC_Program_Coverage__c programCoverage;

	public static string createRequestJSONBody(id programId, id programCoverageId)
    {
        
        map<string,Object> reqProgramCoverageMap = new map<string, Object>();
        if(programId != null)
        {
        	reqProgramCoverageMap.put('programId', programId);
        }
        if(programCoverageId != null)
        {
        	reqProgramCoverageMap.put('id', programCoverageId);
        }
        reqProgramCoverageMap.put('meetsQualification', 'true');
        reqProgramCoverageMap.put('isEligible', 'true');
        reqProgramCoverageMap.put('coverageType', 'Public Coverage');
        reqProgramCoverageMap.put('coverageStatus', 'Active');
        reqProgramCoverageMap.put('comments', 'Test Comments');

        return (JSON.serialize(reqProgramCoverageMap));
    }

    public static void testDataSetUp()
    {
    	patient = PC_Test_Setup.createEWPPatient('testpatient', '1988-05-30', 'Mr.' , PC_Constants.PATIENT_RECORD_TYPE);
        patient = (Account)PC_Database.ins(patient, false);

        healthPlan = PC_Test_Setup.createTestHealthPlan(patient.Id);
        healthPlan = (PC_Health_Plan__c)PC_Database.ins(healthPlan, false);

        manufacturers = PC_Test_Setup.createAccounts('pRootNameManufacturer', 1, 'Manufacturer');
        manufacturers = (List<Account>)PC_Database.ins(manufacturers, false);

        engProg = PC_Test_Setup.createEngagementProgram('RESTPRG', manufacturers[0].Id);
        engProg = (PC_Engagement_Program__c) PC_Database.ins(engProg, false);

        program = PC_Test_Setup.createProgram(patient); // createProgram does the insert

        programCoverage = PC_Test_Setup.createTestProgramCoverage(program.id, healthPlan.id);
        programCoverage = (PC_Program_Coverage__c)PC_Database.ins(programCoverage, false);
    }

	@isTest
	static void testGETPositive_ByProgramCaseId()
	{
		User adminUser;

        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test');
        PC_Database.ins(adminUser);
        System.runAs(adminUser) 
        {
            Test.StartTest();
            testDataSetUp();

            RestRequest re = new RestRequest();
            RestResponse rp = new RestResponse();
            re.addHeader('httpMethod', 'GET');

            re.requestURI = getURL_part + 'findbyProgramId/' + program.Id;

            RestContext.request = re;
            RestContext.response= rp;
            PC_ProgramCoverageService.doGet();
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


	@isTest
	static void testGETPositive_ByProgramCoverageId()
	{
		User adminUser;

        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test');
        PC_Database.ins(adminUser);
        System.runAs(adminUser) 
        {
            Test.StartTest();
            testDataSetUp();

            RestRequest re = new RestRequest();
            RestResponse rp = new RestResponse();
            re.addHeader('httpMethod', 'GET');
			re.requestURI = getURL_part + programCoverage.Id;

            RestContext.request = re;
            RestContext.response= rp;
            PC_ProgramCoverageService.doGet();
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

	@isTest
	static void testGETNegative_ByProgramCaseIdMissing()
	{
		User adminUser;

        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test');
        PC_Database.ins(adminUser);
        System.runAs(adminUser) 
        {
            Test.StartTest();
            testDataSetUp();

            RestRequest re = new RestRequest();
            RestResponse rp = new RestResponse();
            re.addHeader('httpMethod', 'GET');

            re.requestURI = getURL_part + 'findbyProgramId/';

            RestContext.request = re;
            RestContext.response= rp;
            PC_ProgramCoverageService.doGet();
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

	@isTest
	static void testGETNegative_ByMissingURI()
	{
		User adminUser;

        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test');
        PC_Database.ins(adminUser);
        System.runAs(adminUser) 
        {
            Test.StartTest();
            testDataSetUp();

            RestRequest re = new RestRequest();
            RestResponse rp = new RestResponse();
            re.addHeader('httpMethod', 'GET');

            re.requestURI = PC_Constants.EMPTY_STRING;

            RestContext.request = re;
            RestContext.response= rp;
            PC_ProgramCoverageService.doGet();
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

        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test');
        PC_Database.ins(adminUser);
        System.runAs(adminUser) 
        {
            Test.StartTest();
           
            testDataSetUp();

            RestRequest re = new RestRequest();
            RestResponse rp = new RestResponse();

            String reqBodyInJSON = createRequestJSONBody(program.id, null);

            system.debug('reqBodyInJSON--'+ reqBodyInJSON);
            
            re.requestBody = Blob.valueOf(reqBodyInJSON);
            re.requestURI = getURL_part;
            re.httpMethod = 'POST';
            RestContext.request = re;
            RestContext.response= rp;
            PC_ProgramCoverageService.doPOST();
            system.debug(JSON.serialize(rp.responseBody));
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

    @isTest static void testPUT() {
        User adminUser;

        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test');
        PC_Database.ins(adminUser);
        System.runAs(adminUser) {
            Test.StartTest();
            testDataSetUp();

            RestRequest re = new RestRequest();
            RestResponse rp = new RestResponse();
            re.addHeader('httpMethod', 'PUT');

            string reqBodyInJSON = createRequestJsonBody(null, programCoverage.id);
            system.debug('reqBodyInJSON--'+ reqBodyInJSON);

            re.requestBody = Blob.valueOf(reqBodyInJSON);
            re.requestURI = getURL_part;
            RestContext.request = re;
            RestContext.response= rp;
            PC_ProgramCoverageService.doPUT();
            system.debug(JSON.serialize(rp.responseBody));
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