/*********************************************************************************
----------------------------------------------------------------------------------
Developer                   Date                   Description
----------------------------------------------------------------------------------
Shishir Bansal         May 22, 2019                 Initial Version
Shishir Bansal         May 26, 2019                 [PC-4622] Implementing test Get service to fetch Adverse event
                                                    details for a patientId.
Shishir Bansal         May 26, 2019                 [PC-4622] Implementing test Post service to create Adverse event for
                                                    a patient record id.
Shishir Bansal         May 26, 2019                 [PC-4622] Implementing test Update service to update Adverse event
                                                    for a patient record id.
Shsihir Bansal         May 29,2019                  Code Refactoring, adding comments to the methods and
                                                    removing system.debug statements
Vijay Kashikar         Aug 20, 2019                 [PC-5326] - Replaced PC_Patient hardcoding with constant
*********************************************************************************/
@IsTest
private class PC_Test_AdverseEvent2Service {

    public static final String getURL_part = '/services/apexrest/' + PC_Constants.OrgNamespace + '/1.0/adverseEvent/';
    static final String SUSPECT_PRODUCTS_KEY = 'suspectProducts';
    static final String ADVERSE_EVENTS_KEY = 'adverseEvents';

    /**
    * testing postive get response in JSON format of all the related  adverseEvent and related suspectPrescription records
    * @param  setting patientId in the URL
    */
    @isTest static void testGETPostive() {
        User adminUser;

        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test');
        PC_Database.ins(adminUser);
        System.runAs(adminUser) {
            Test.StartTest();

            Id RecordTypeId = PC_SYSTEM.recordTypeId('Account', PC_Constants.PATIENT_RECORD_TYPE);

            Account patient = [Select Id from Account where RecordTypeId =:RecordTypeId Limit 1];
            RestRequest re = new RestRequest();
            RestResponse rp = new RestResponse();
            re.addHeader('httpMethod', 'GET');
            system.debug('getURL_part-'+ getURL_part);
            re.requestURI = getURL_part + 'findByPatientId/' + patient.Id;
            RestContext.request = re;
            RestContext.response= rp;

            PC_AdverseEvent2Service.doGet();
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
    /**
    * testing negative get response in JSON format of all the related  adverseEvent and related suspectPrescription records
    * @param  setting  null patientId in the URL
    */
    @isTest static void testGETNegative() {
        User adminUser;

        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test');
        PC_Database.ins(adminUser);
        System.runAs(adminUser) {
            Test.StartTest();
            RestRequest re = new RestRequest();
            RestResponse rp = new RestResponse();
            re.addHeader('httpMethod', 'GET');
            system.debug('getURL_part-'+ getURL_part);
            re.requestURI = getURL_part + 'findByPatientId/';
            RestContext.request = re;
            RestContext.response= rp;
            PC_AdverseEvent2Service.doGet();
            if(rp.statusCode != 200)
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


    /**
    * testing positive post response in JSON format of all the related  adverseEvent and related suspectPrescription records
    * @param  passing JSON in the request body
    */
    @isTest static void testPOST() {
        User adminUser;

        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test');
        PC_Database.ins(adminUser);
        System.runAs(adminUser) {
            Test.StartTest();
            RestRequest re = new RestRequest();
            RestResponse rp = new RestResponse();

            Id RecordTypeId = PC_SYSTEM.recordTypeId('Account', PC_Constants.PATIENT_RECORD_TYPE);

            Account patient = [Select Id from Account where RecordTypeId =:RecordTypeId Limit 1];


            String reqBodyInJSON = createRequestJSONBody(patient.id, 'POST');
            system.debug('reqBodyInJSON--'+ reqBodyInJSON);

            re.requestBody = Blob.valueOf(reqBodyInJSON);
            re.requestURI = getURL_part;
            re.httpMethod = 'POST';
            RestContext.request = re;
            RestContext.response= rp;
            PC_AdverseEvent2Service.doPOST();
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


    /**
    * testing positive put response in JSON format of all the related  adverseEvent and related suspectPrescription records
    * @param  passing JSON in the request body
    */
    @isTest static void testPUT() {
        User adminUser;

        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test');
        PC_Database.ins(adminUser);
        System.runAs(adminUser) {
            Test.StartTest();
            RestRequest re = new RestRequest();
            RestResponse rp = new RestResponse();

            Id RecordTypeId = PC_SYSTEM.recordTypeId('Account', PC_Constants.PATIENT_RECORD_TYPE);

            Account patient = [Select Id from Account where RecordTypeId =:RecordTypeId Limit 1];


            String reqBodyInJSON = createRequestJSONBody(patient.id, 'PUT');
            re.requestBody = Blob.valueOf(reqBodyInJSON);
            re.requestURI = getURL_part;
            re.httpMethod = 'PUT';
            RestContext.request = re;
            RestContext.response= rp;
            PC_AdverseEvent2Service.doPut();
            system.debug('rp.responseBody-->'+JSON.serialize(rp.responseBody));
            system.debug('rp.statusCode-->'+rp.statusCode);

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


    /**
    * Method to create dummy JSON object for post and put request testing
    * @param  passing patientId
    */
    public static string createRequestJSONBody(id patientId, String operation){

        map<string,Object> reqAdverseEventMap = new map<string, Object>();
        if(patientId != null)
        {
            List<PC_AdverseEvent2__c> adverseEventList = new List<PC_AdverseEvent2__c>();
            adverseEventList = PC_RestAPIUtilities.getAdverseEvents2(patientId);
            // List<Map<string, object>> adverseEvent_trans = PC_RestAPIUtilities.transformSobjectAdverseEvents(adverseEventList);
            List<PC_Suspect_Prescription__c> suspectProducts = new List<PC_Suspect_Prescription__c>();
            List<Map<String, Object>> suspectProducts_map;
            Map<String, Object> adverseEvent_map = new  Map<String, Object>();
            //Map<String, Object> adverseEvents_map = new  Map<String, Object>();
            List<PC_Suspect_Prescription__c> suspectPrescriptions;
            List<Map<String, Object>> suspectPrescriptions_map;
            List<Object> progs = new  List<Object>();
            String adverseEventId;
            for(PC_AdverseEvent2__c adverseEvent: adverseEventList){


                adverseEvent_map = PC_RestAPIUtilities.transformSobject(adverseEvent.getPopulatedFieldsAsMap(),
                        PC_RestAPIConstants.REST_OBJECT_NAME_ADVERSE_EVENT);



                adverseEvent_map.remove('name');

                if(operation.equalsIgnoreCase('PUT')){
                    adverseEvent_map.remove('patientId');
                }
                adverseEventId = adverseEvent.Id;
                suspectPrescriptions = PC_RestAPIUtilities.getAdverseEvent2SuspectPrescriptions(adverseEventId);
                suspectPrescriptions_map = PC_RestAPIUtilities.transformSobjectSuspectPrescriptions(suspectPrescriptions);
                adverseEvent_map.put(SUSPECT_PRODUCTS_KEY, suspectPrescriptions_map);
                progs.add(adverseEvent_map);


            }

            String adverseEventMapVal =  JSON.serialize(progs);

            adverseEventMapVal =adverseEventMapVal.substring(1,adverseEventMapVal.length()-1 );
            return adverseEventMapVal;
        }
        return null;
    }


    /**
    * Method to create dummy salesforce data for testing purposes
    * Records will not be saved into database
    */
    @testSetup static void setup() {

        Account  patient = PC_Test_Setup.createEWPPatient('testpatient', '1988-05-30', 'Mr.' , PC_Constants.PATIENT_RECORD_TYPE);
        patient = (Account)PC_Database.ins(patient, false);


        PC_AdverseEvent2__c adverseEvent = PC_Test_Setup.newAdverseEvent2(patient.Id);
        adverseEvent = (PC_AdverseEvent2__c)PC_Database.ins(adverseEvent, false);


        List<PC_Suspect_Prescription__c> suspectPrescriptions= PC_Test_Setup.createSuspectPrescriptions2(adverseEvent.Id, 4);
        suspectPrescriptions = (List<PC_Suspect_Prescription__c> )PC_Database.ins(suspectPrescriptions, false);

    }
}