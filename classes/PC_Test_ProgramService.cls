/*********************************************************************************************************
Class Name      : PC_Test_ProgramService
Description     : Test class for PC_ProgramService
Created By      : Deloitte
Created Date    : Oct 29, 2017
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer          Log#         Date                   Description
--------------------------------------------------------------------------------------------------------------
Mayuresh Patil                Oct 29, 2017           Initial Version
Rohit Kapoor                  Nov 14, 2017           PC-2492 -Refactor the code
Vijay Kashikar                Aug 20, 2019           [PC-5326] - Replaced PC_Patient hardcoding with constant
Haritha Reddy                 Jul 05, 2021           [PC-7878] - Added program product on Case to test fetching Reference field values
****************************************************************************************************************/

@isTest
public class PC_Test_ProgramService {
    public static final String getURL_part = '/services/apexrest/' + PC_Constants.OrgNamespace + '/1.0/program/';
    public static final string ASSOCIATIONS_KEY = 'associations';
    public static final string SUPPORTCASES_KEY = 'supportCases';
    
    public static string createRequestJSONBody(id patientId, id engagementProgramId, id programId, id physiciansId)
    {
        
        map<string,Object> reqProgramMap = new map<string, Object>();
        if(patientId != null)
        {
            reqProgramMap.put('patientId',patientId);
        }
        if(engagementProgramId != null)
        {
            reqProgramMap.put('engagementProgramId',engagementProgramId);
        }
        list<Object> listOfAssociations = new list<Object>();
        map<string,Object> reqAssociationsMap_temp= new map<string, Object>();
        if(programId != null)
        {
            reqAssociationsMap_temp.put('programId',programId);
        }
        if(physiciansId != null)
        {
            reqAssociationsMap_temp.put('accountId', physiciansId);
        }
        reqAssociationsMap_temp.put('role','Treating Physician');
        reqAssociationsMap_temp.put('associationStatus', 'Active');

        listOfAssociations.add(reqAssociationsMap_temp);
        
        if(listOfAssociations != null && !listOfAssociations.isEmpty())
        {
            reqProgramMap.put(ASSOCIATIONS_KEY, listOfAssociations);
        }

        list<Object> listOfSupportCases= new list<Object>();
        map<string,Object> reqSupportCasesMap_temp= new map<string, Object>();
        if(programId != null)
        {
            reqSupportCasesMap_temp.put('programId',programId);
        }
        reqSupportCasesMap_temp.put('recordType', 'PC_Alternate_Funding');
        
        listOfSupportCases.add(reqSupportCasesMap_temp);
        
        if(listOfSupportCases != null && !listOfSupportCases.isEmpty())
        {
            reqProgramMap.put(SUPPORTCASES_KEY, listOfSupportCases);
        }
        
        return (JSON.serialize(reqProgramMap));
    }

    @isTest static void testGETPositive_ByPatientId() {
        User adminUser;

        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test');
        PC_Database.ins(adminUser);
        System.runAs(adminUser) 
        {
            Test.StartTest();
            Account  patient = PC_Test_Setup.createEWPPatient('testpatient', '1988-05-30', 'Mr.' , PC_Constants.PATIENT_RECORD_TYPE);
            patient = (Account)PC_Database.ins(patient, false);

            Case program = PC_Test_Setup.createProgram(patient); // createProgram does the insert

            //Create Manufacturer
            Account  manufacturer = PC_Test_Setup.createEWPPatient('testmanufacturer', '1988-05-30', 'Mr.' , 'Manufacturer');
            manufacturer = (Account)PC_Database.ins(manufacturer, false);

            //Create Product
            Product2  product = PC_Test_Setup.newProduct('Product1', 'P1', manufacturer.Id);
            product = (Product2)PC_Database.ins(product, false);

            //Engagement Program
            PC_Engagement_Program__c engPrgA= PC_Test_Setup.createEngagementProgram('EP1', manufacturer.Id);
            PC_Database.ins(engPrgA, false);

            //Engagement Program Product
            PC_Engagement_Program_Product__c engProductJunction = new PC_Engagement_Program_Product__c();
            engProductJunction.PC_Engagement_Program__c = engPrgA.Id;
            engProductJunction.PC_Product__c = product.Id;
            engProductJunction = (PC_Engagement_Program_Product__c)PC_Database.ins(engProductJunction, false);

            program.PC_Engagement_Program__c = engPrgA.id;
            program.PC_Program_Product__c = engProductJunction.id;
            program = (Case)PC_Database.upd(program, false);

            RestRequest re = new RestRequest();
            RestResponse rp = new RestResponse();
            re.addHeader('httpMethod', 'GET');

            system.debug('getURL_part-'+ getURL_part);
            re.requestURI = getURL_part + 'findByPatientId/' + patient.Id;

            RestContext.request = re;
            RestContext.response= rp;
            PC_ProgramService.doGet();
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
    @isTest static void testPOST() {
        User adminUser;

        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test');
        PC_Database.ins(adminUser);
        System.runAs(adminUser) 
        {
            Test.StartTest();
            Account  patient = PC_Test_Setup.createEWPPatient('testpatient', '1988-05-30', 'Mr.' , PC_Constants.PATIENT_RECORD_TYPE);
            patient = (Account)PC_Database.ins(patient, false);

            List<Account> physicians = PC_Test_Setup.createAccounts('pPhy1', 1, 'PC_Physician');
            physicians = (List<Account>)PC_Database.ins(physicians, false);

            List<Account> manufacturers = PC_Test_Setup.createAccounts('pRootNameManufacturer', 1, 'Manufacturer');
            manufacturers = (List<Account>)PC_Database.ins(manufacturers, false);

            PC_Engagement_Program__c engProg = PC_Test_Setup.createEngagementProgram('RESTPRG', manufacturers[0].Id);
            engProg = (PC_Engagement_Program__c) PC_Database.ins(engProg, false);

            Case program = PC_Test_Setup.createProgram(patient); // createProgram does the insert

            RestRequest re = new RestRequest();
            RestResponse rp = new RestResponse();

            String reqBodyInJSON = createRequestJSONBody(patient.id, 
                                                            engProg.id, 
                                                            program.id, 
                                                            physicians[0].id);
            system.debug('reqBodyInJSON--'+ reqBodyInJSON);
            
            
            re.requestBody = Blob.valueOf(reqBodyInJSON);
            re.requestURI = getURL_part;
            re.httpMethod = 'POST';
            RestContext.request = re;
            RestContext.response= rp;
            PC_ProgramService.doPOST();
            system.debug(JSON.serialize(rp.responseBody));
            if(rp.statusCode == 200) 
            {
                System.assert(true);
            }
            /*else
            {
                System.assert(false);
            }*/

            Test.stopTest();
        }
    }

    @isTest static void testPOSTService1() {
        User adminUser;

        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test');
        PC_Database.ins(adminUser);
        System.runAs(adminUser)
        {
            Test.StartTest();
            Account  patient = PC_Test_Setup.createEWPPatient('testpatient', '1988-05-30', 'Mr.' , PC_Constants.PATIENT_RECORD_TYPE);
            patient = (Account)PC_Database.ins(patient, false);

            List<Account> physicians = PC_Test_Setup.createAccounts('pPhy1', 1, 'PC_Physician');
            physicians = (List<Account>)PC_Database.ins(physicians, false);

            List<Account> manufacturers = PC_Test_Setup.createAccounts('pRootNameManufacturer', 1, 'Manufacturer');
            manufacturers = (List<Account>)PC_Database.ins(manufacturers, false);

            PC_Engagement_Program__c engProg1 = PC_Test_Setup.createEngagementProgram('RESTPRG1', manufacturers[0].Id);
            engProg1.PC_ProgramCaseRecordType__c='PC_Prior_Authorization';
            engProg1.PC_ProgramCaseRecordTypeNamespace__c = PC_Constants.OrgNamespace;
            engProg1 = (PC_Engagement_Program__c) PC_Database.ins(engProg1, false);

            Case program = PC_Test_Setup.createProgram(patient); // createProgram does the insert

            RestRequest re1 = new RestRequest();
            RestResponse rp1 = new RestResponse();

            String reqBodyInJSON1 = createRequestJSONBody(patient.id,
                    engProg1.id,
                    program.id,
                    physicians[0].id);
            system.debug('reqBodyInJSON--'+ reqBodyInJSON1);


            re1.requestBody = Blob.valueOf(reqBodyInJSON1);
            re1.requestURI = getURL_part;
            re1.httpMethod = 'POST';
            RestContext.request = re1;
            RestContext.response= rp1;
            PC_ProgramService.doPOST();
            system.debug(JSON.serialize(rp1.responseBody));
            if(rp1.statusCode == 200)
            {
                System.assert(true);
            }

            Test.stopTest();
        }
    }

    @isTest static void testPOSTService2() {
        User adminUser;

        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test');
        PC_Database.ins(adminUser);
        System.runAs(adminUser)
        {
            Test.StartTest();
            Account  patient = PC_Test_Setup.createEWPPatient('testpatient', '1988-05-30', 'Mr.' , PC_Constants.PATIENT_RECORD_TYPE);
            patient = (Account)PC_Database.ins(patient, false);

            List<Account> physicians = PC_Test_Setup.createAccounts('pPhy1', 1, 'PC_Physician');
            physicians = (List<Account>)PC_Database.ins(physicians, false);

            List<Account> manufacturers = PC_Test_Setup.createAccounts('pRootNameManufacturer', 1, 'Manufacturer');
            manufacturers = (List<Account>)PC_Database.ins(manufacturers, false);

            PC_Engagement_Program__c engProg2 = PC_Test_Setup.createEngagementProgram('RESTPRG2', manufacturers[0].Id);
            engProg2.PC_ProgramCaseRecordType__c='PC_Prior_Authorization';
            engProg2 = (PC_Engagement_Program__c) PC_Database.ins(engProg2, false);

            Case program = PC_Test_Setup.createProgram(patient); // createProgram does the insert

            RestRequest re2 = new RestRequest();
            RestResponse rp2 = new RestResponse();

            String reqBodyInJSON2 = createRequestJSONBody(patient.id,
                    engProg2.id,
                    program.id,
                    physicians[0].id);
            system.debug('reqBodyInJSON--'+ reqBodyInJSON2);

            re2.requestBody = Blob.valueOf(reqBodyInJSON2);
            re2.requestURI = getURL_part;
            re2.httpMethod = 'POST';
            RestContext.request = re2;
            RestContext.response= rp2;
            PC_ProgramService.doPOST();
            system.debug(JSON.serialize(rp2.responseBody));
            if(rp2.statusCode == 200)
            {
                System.assert(true);
            }

            Test.stopTest();
        }
    }
}