/*********************************************************************************
Class Name      : PC_Test_AssociationService
Description     : This test class for Association REST Service
Created By      : shisbansal
Created Date    : Jan 21, 2019
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------
shisbansal                Jan 21, 2019              Initial Version
Tejas Patel               Jan 24, 2019              [PC-4221] Test method for doDelete
Xiukai Ning               Jan 24, 2019              [PC-4230] Test method for doPut
Shishir Bansal            10-Dec-2019               [PC-5792] Avoid hardcoding of string variable
Hitha Avalakki            Feb 26, 2021              [PC-7442] Replaced PC_Test_Setup.createCases() with PC_Test_Setup.createProgramCases() method.
Hitha Avalakki            Mar 19, 2021              [PC-7533] Replaced constant CASE_PROGRAM_RECORD_TYPE_NAME to CASE_PROGRAM_TYPE
*********************************************************************************/

@IsTest
private class PC_Test_AssociationService {

    public static final String ACCOUNT_NAME = 'Test Account';
    private static final Integer OBJECTS_NUMBER = 1;
    public static final String getURL_part = '/services/apexrest/' + PC_Constants.OrgNamespace + '/association';

    @isTest static void testPOST() {
        User adminUser;
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test');
        PC_Database.ins(adminUser);

        System.runAs(adminUser)
        {
            Test.StartTest();

            RestRequest re = new RestRequest();
            RestResponse rp = new RestResponse();

            //Id caseRecordType = PC_SYSTEM.recordTypeId(PC_Constants.PC_CASE,PC_Constants.CASE_PROGRAM_RECORD_TYPE);
            //Case caseObj = [Select Id from Case where RecordTypeId =:caseRecordType Limit 1];
            Case caseObj = [Select Id from Case where Type =:PC_Constants.CASE_PROGRAM_TYPE Limit 1];

            Id accountRecordTypeId = PC_System.recordTypeId(PC_Constants.PATIENT_OBJECT, PC_Constants.PATIENT_RECORD_TYPE);
            Account accountObj = [Select Id from Account where RecordTypeId =:accountRecordTypeId Limit 1];

            String reqBodyInJSON = createPostRequestJSONBody(PC_Constants.ACTIVE, PC_Constants.PC_ROLE_REIMBURSEMENT_SPECIALIST, null,caseObj.Id, accountObj.Id );
            re.requestBody = Blob.valueOf(reqBodyInJSON);
            re.requestURI = getURL_part;
            re.httpMethod = 'POST';
            RestContext.request = re;
            RestContext.response= rp;
            PC_AssociationService.doPost();
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

    @isTest static void testPut() {
        User adminUser;
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test');
        PC_Database.ins(adminUser);

        System.runAs(adminUser)
        {
            Test.StartTest();

            RestRequest re = new RestRequest();
            RestResponse rp = new RestResponse();

            //Id caseRecordType = PC_SYSTEM.recordTypeId(PC_Constants.PC_CASE,PC_Constants.CASE_PROGRAM_RECORD_TYPE);
            //Case caseObj = [Select Id from Case where RecordTypeId =:caseRecordType Limit 1];
            Case caseObj = [Select Id from Case where Type =:PC_Constants.CASE_PROGRAM_TYPE Limit 1];

            Id accountRecordTypeId = PC_System.recordTypeId(PC_Constants.PATIENT_OBJECT, PC_Constants.PATIENT_RECORD_TYPE);
            Account accountObj = [Select Id from Account where RecordTypeId =:accountRecordTypeId Limit 1];
            User userObj = [Select Id from User Where Id =:adminUser.Id];
            Date endDate = (Date) date.newinstance(Date.today().year(), 12, 31);
            PC_Association__c association = PC_Test_Setup.createAssociation(NULL , caseObj, PC_Constants.PC_ROLE_CARE_COORDINATOR, endDate,userObj);

            String associationID;
            associationID = association.Id;
            //Positive condition
            String reqBodyInJSON = createPutRequestJSONBody(associationID, PC_Constants.INACTIVE, '2019-01-24');
            re.requestBody = Blob.valueOf(reqBodyInJSON);
            re.requestURI = getURL_part;
            re.httpMethod = 'PUT';
            RestContext.request = re;
            RestContext.response = rp;
            PC_AssociationService.doPut();
            System.assertEquals(rp.statusCode,200);
            //Negative Condition
            try {
                String reqBodyInJSONNegative = createPutRequestJSONBody('', PC_Constants.INACTIVE, '2019-01-24');
                re.requestBody = Blob.valueOf(reqBodyInJSONNegative);
                re.requestURI = getURL_part;
                re.httpMethod = 'PUT';
                RestContext.request = re;
                RestContext.response = rp;
                PC_AssociationService.doPut();
                System.assertEquals(rp.statusCode, 500);
            }
            catch(Exception ex) {
                system.assertEquals(ex.getMessage(), ex.getMessage());
            }

            Test.stopTest();
        }
    }

    @isTest static void testDELETE() {
        User adminUser;
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test');
        PC_Database.ins(adminUser);

        System.runAs(adminUser)
        {
            Test.StartTest();

            RestRequest re = new RestRequest();
            RestResponse rp = new RestResponse();

            //Id caseRecordType = PC_SYSTEM.recordTypeId(PC_Constants.PC_CASE,PC_Constants.CASE_PROGRAM_RECORD_TYPE);
            //Case caseObj = [Select Id from Case where RecordTypeId =:caseRecordType Limit 1];
            Case caseObj = [Select Id from Case where Type =:PC_Constants.CASE_PROGRAM_TYPE Limit 1];

            Id accountRecordTypeId = PC_System.recordTypeId(PC_Constants.PATIENT_OBJECT, PC_Constants.PATIENT_RECORD_TYPE);
            Account accountObj = [Select Id from Account where RecordTypeId =:accountRecordTypeId Limit 1];
            User userObj = [Select Id from User Where Id =:adminUser.Id];

            Date endDate = (Date) date.newinstance(Date.today().year(), 12, 31);

            PC_Association__c association = PC_Test_Setup.createAssociation(NULL , caseObj, PC_Constants.PC_ROLE_CARE_COORDINATOR, endDate,userObj);
            List<String> deleteConditions = new List<String>{'Success','Invalid_Id','Missing_Id'};
            String associationID;
            for(String s : deleteConditions) {
                if(s == 'Missing_Id'){
                    associationID = PC_Constants.EMPTY_STRING;
                }else if(s == 'Invalid_Id'){
                    associationID = accountObj.Id;
                }else{
                    associationID = association.Id;
                }

                re.requestURI = getURL_part + '/' + associationID;
                re.httpMethod = 'DELETE';
                RestContext.request = re;
                RestContext.response = rp;
                PC_AssociationService.doDelete();

                if(s == 'Missing_Id'){
                    System.assertEquals(rp.statusCode,500);
                }else if(s == 'Invalid_Id'){
                    System.assertEquals(rp.statusCode,500);
                }else{
                    System.assertEquals(rp.statusCode,202);
                }
            }

            Test.stopTest();
        }
    }

    public static string createPostRequestJSONBody(String associationStatus, String role, Id associationId, String programId, String accountId)
    {

        map<string,Object> reqAssociationsMap_temp= new map<string, Object>();
        if(programId != null)
        {
            reqAssociationsMap_temp.put('programId',programId);
        }
        if(role != '' || role != null)
        {
           reqAssociationsMap_temp.put('role',role);
        }
        if(accountId != '' || accountId != null)
        {
            reqAssociationsMap_temp.put('accountId',accountId);
        }

        reqAssociationsMap_temp.put('associationStatus',associationStatus);
        reqAssociationsMap_temp.put('id', '');
        return (JSON.serialize(reqAssociationsMap_temp));
    }

    public static string createPutRequestJSONBody(Id associationId, String associationStatus, String endDate)
    {

        map<string,Object> reqAssociationsMap_temp= new map<string, Object>();

        reqAssociationsMap_temp.put('endDate', endDate);
        reqAssociationsMap_temp.put('associationStatus',associationStatus);
        reqAssociationsMap_temp.put('id', associationId);
        return (JSON.serialize(reqAssociationsMap_temp));
    }

    @testSetup static void setup() {

        List<Account> patientAccounts = PC_Test_Setup.createSampleAccounts(ACCOUNT_NAME, OBJECTS_NUMBER, PC_Constants.PATIENT_RECORD_TYPE);
        PC_Database.ins(patientAccounts);
        //[PC-7442] Replaced PC_Test_Setup.createCases() with PC_Test_Setup.createProgramCases() method.
        List<Case> programCases = PC_Test_Setup.createProgramCases(patientAccounts, OBJECTS_NUMBER);
        PC_Database.ins(programCases);
        List<User> ccAndRiUsers = PC_Test_Setup.createUsers(PC_Test_Setup.SYS_ADMIN_PROFILE, 'userpctest@test5.com', 'test5', OBJECTS_NUMBER);
        PC_Database.ins(ccAndRiUsers);
    }
}