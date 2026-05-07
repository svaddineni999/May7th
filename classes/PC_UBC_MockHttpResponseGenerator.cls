/*********************************************************************************************************
Class Name      : PC_UBC_MockHttpResponseGenerator
Description     : Mock Implementation class to test UBC related functionality
Created By      : Vijay Kashikar
Created Date    : March 23, 2018
Modification Log:
-----------------------------------------------------------------------------------------------------
Developer                   Date                           Description
-----------------------------------------------------------------------------------------------------
Vijay Kashikar               March 23, 2018              Initial Version
*********************************************************************************************************/

@IsTest
public class PC_UBC_MockHttpResponseGenerator implements HttpCalloutMock{
    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(200);
        String endPoint = req.getEndpoint();
        system.debug('end point = ' + endPoint);
        PC_UBC_Utility utility = new PC_UBC_Utility();
        if((endPoint.containsIgnoreCase('callout') && endPoint.containsIgnoreCase(PC_eBenefits.getEbenefitsNamedCredential(PC_Constants.PC_eBENEFITS_TOKEN_SERVICE_TYPE)))) {
            Map<String, String> responseMap = new Map<String, String>();
            responseMap.put('access_token', 'sampleToken');
            res.setBody(JSON.serialize(responseMap));
        }
        else if(endPoint.containsIgnoreCase('callout') && endPoint.containsIgnoreCase(PC_eBenefits.getEbenefitsNamedCredential(PC_Constants.PC_eBENEFITS_PHARMACY_CARD_SERVICE_TYPE))) {
            String responString = '{  "isError": false,  "message": "Successful",  "patient": {    "firstName": "Ronald",    "gender": "Male",    "lastName": "Lacy",    "birthdate": "1972-03-15T00:00:00Z",    "address": {      "type": "None",      "postalCode": "62025"    },    "authority": "",    "issuedId": ""  },  "physician": {    "npi": "1497827612",    "firstName": "Daniel",    "address": {"addressOne": "",      "type": "None",      "city": "",      "state": "",      "postalCode": ""    },    "lastName": "Freitas",    "authority": "",    "issuedId": ""  },  "product": {    "label": "Entyvio",    "ndc": "64764030020",    "authority": "",    "issuedId": ""  },  "requestDate": "2017-10-17T21:46:03.837982Z",  "pbms": [    {      "name": "ESI1",      "pbmStatusMessage": "Success",      "plans": [        {          "memberInfo": {            "memberId": "332425055AG020%9383998188%001",            "relationship": "Self",            "changeFlag": true,            "firstName": "RONALD",            "gender": "Male",            "lastName": "LACY",            "birthdate": "1972-03-15T00:00:00Z",            "address": {              "addressOne": "7032 ALSTON CT",              "type": "None",              "city": "EDWARDSVILLE",              "state": "IL",              "postalCode": "62025",              "id": "a433262f-69ca-48b7-b733-a80f0166ba57"            },            "id": "19d1a6c2-b67a-4da4-bbba-a80f0166ba57"          },          "insurance": {            "policyId": "9383998188",            "participantId": "P00000000001001",            "isEsi": true,            "familyUnitNumber": "001",            "bin": "000000",            "group": {              "groupId": "332425055AG020",              "name": "MO - STL-NON UNION",              "id": "15212828-bdea-44fa-b69c-a80f0166ba53"            },            "id": "64ae383c-530a-48ed-877d-a80f0166ba53"          },          "isPriorAuthorizationRequired": true,          "coverage": [            {              "pharmacyType": "RetailPharmacy",              "isCovered": true,              "id": "385cb03e-ed86-42e2-8ec2-a80f0166ba57"            },            {              "pharmacyType": "MailOrderPharmacy",              "isCovered": true,              "id": "380cf04e-deae-4311-b7ba-a80f0166ba57"            }          ],          "outOfPocketRanges": [],          "id": "fa0f1d5d-72e1-46b7-b207-a80f0166ba53"        }      ],      "id": "8ba9606f-3ca9-429e-9012-a80f0166ba44"    }  ],  "id": "0d20c462-d81e-40ee-ad2e-a80f0166ba16"}';
            //Map<String, Object> responseMap = JSON.deserializeUntyped(responString);
            res.setBody(responString);
        }
        else if(endPoint.containsIgnoreCase('callout') && endPoint.containsIgnoreCase(PC_eBenefits.getEbenefitsNamedCredential(PC_Constants.PC_eBENEFITS_PLAN_SERVICE_TYPE))) {
            List<Object> responseList = new List<Object>();
            String resString = '[{"Name":"PBMF","AbbreviatedName":"PBMF","Phone":"7035551233","Url":null,"Description":null,"LogoUri":null,"PayerID":"T00000000021633","ServiceLevel":"CIMessage CIEvent ePA MedicationAdherence HighRiskMedication MissingMedication PDC PatMedBenefitCheck","AdditionalIds":[],"Id":"a1305ec0-de89-4bc5-9c4a-2cff52f39b74"}]';
            res.setBody(resString);
        }
        else if((endPoint.containsIgnoreCase('callout') && endPoint.containsIgnoreCase(PC_eBenefits.getEbenefitsNamedCredential(PC_Constants.PC_eBENEFITS_PHARMACY_COVERAGE_SERVICE_TYPE)))) {
            PC_UBC.PharmacyCoverageServiceResponse serviceResponse;
            serviceResponse = utility.example2();
            res.setBody(JSON.serialize(serviceResponse));

        }
        else if((endPoint.containsIgnoreCase('callout') && endPoint.containsIgnoreCase(PC_eBenefits.getEbenefitsNamedCredential(PC_Constants.PC_eBENEFITS_PHARMACY_FINDER_SERVICE_TYPE)))) {
            String responString = '[{"additionalIds":[],"addresses":[{"latitude":42.32593,"longitude":-71.14965,"precise":true,"addressOne":"850 Boylston Street","description":"BWH Outpatient Pharmacy - Boylston Address","type":"None","city":"Chestnut Hill","state":"MA","country":"USA","postalCode":"02467","id":"4703c21b-a016-44ec-824d-870327662141"}],"fax":"6177329063","name":"Bwh Outpatient Pharmacy - Boylston","ncpdp":"9100328","npi":"1790717650","phone":"6177329040","type":"None","serviceLevel":"New","specialtyType":"Retail","deaNumber":"AA9297145","id":"44b9e769-4b7b-4823-b2c8-dd2853c42347"},{"additionalIds":[],"addresses":[{"latitude":42.336212,"longitude":-71.108055,"precise":true,"addressOne":"75 Francis St","description":"BWH Outpatient Pharmacy 75 Francis Address","type":"None","city":"Boston","state":"MA","country":"USA","postalCode":"02115","id":"0ce079fb-3f66-4221-9636-8443df7ac24a"}],"fax":"6177324205","name":"Bwh Outpatient Pharmacy 75 Francis","ncpdp":"2227622","npi":"1790717650","phone":"6177326225","type":"None","serviceLevel":"New~Refill","specialtyType":"Retail","id":"4c1ca28e-72e6-4fd6-8067-c361726aa22a"},{"additionalIds":[],"addresses":[{"latitude":42.09439,"longitude":-71.26578,"precise":true,"addressOne":"20 Patriot Place","description":"BWH Outpatient Pharmacy - Foxboro Address","type":"None","city":"Foxboro","state":"MA","country":"USA","postalCode":"02035","id":"d5104488-3402-41b9-94c8-e8254ddc7f19"}],"fax":"5087184021","name":"Bwh Outpatient Pharmacy - Foxboro","ncpdp":"9100316","npi":"1790717650","phone":"5087184020","type":"None","serviceLevel":"New","specialtyType":"Retail","deaNumber":"AA9297145","id":"89de1d4d-f895-4502-9c74-a1383c57b3ac"}]';
            //Map<String, Object> responseMap = JSON.deserializeUntyped(responString);
            res.setBody(responString);
        }

        return res;
    }
}