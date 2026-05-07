/*********************************************************************************************************
Class Name      : PC_Batch_GeolocationCalloutV2
Description     : This class will process Google map HTTP Callouts in batch.
Created By      : Roxana Ivan
Created Date    : 31-May-16
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer                   Date                       Description
--------------------------------------------------------------------------------------------------------------
Roxana Ivan                 May 31, 2016                Initial Version
Shabda Bhujad               Dec 05, 2016        Added FLS check to makeCallouts method
Ajinkya Deshmukh            Jun 20, 2017        FLS Check Added (Code Merge)
Kanteti Kishore            Aug 26,2018        	[PC-5351]Fetching api key from protected api setting(Line 93)
Vijay Kashikar             21-Jan-21            [PC-7102] Added sharing clause
Hitha Avalakki             11-May-21            [PC-7654] Added null check for PC_ProtectedApiValue__c value to prevent null pointer exception
****************************************************************************************************************/
public with sharing class PC_Batch_GeolocationCalloutV2 implements Database.Batchable<String>, Database.AllowsCallouts {
    private static Integer RequestTimeout = 60000;
    List<String> lstBatchIds;

    /*********************************************************************************
    Method Name    : GIL_Batch_GeolocationCallout
    Description    : Constructor
    Return Type    : void
    Parameter      : 1. lstIds: list of ids for google map HTTP Callouts
    *********************************************************************************/

    public PC_Batch_GeolocationCalloutV2 (List<String> lstIds) {
        lstBatchIds = lstIds;
    }
    /*********************************************************************************
    Method Name    : start
    Description    : Start method to fetch the URLs
    Return Type    : Iterable<String>
    Parameter      : 1. BC : Context for the batch
    *********************************************************************************/

    public Iterable<String> start(Database.BatchableContext BC) {
        return lstBatchIds;
    }
    /*********************************************************************************
    Method Name    : execute
    Description    : Execute method to process the list
    Return Type    : void
    Parameter      : 1. BC : Context for the batch
                     2. lstIds : List of patient/participant Ids
    *********************************************************************************/
    public void execute(Database.BatchableContext BC,  List<String> lstIds) {
        if(lstIds != null && lstIds.size()> 0)
            makeCallouts(lstIds);
    }
    /*********************************************************************************
    Method Name    : finish
    Description    : finish method
    Return Type    : void
    Parameter      : 1. BC : Context for the batch
    *********************************************************************************/
    public void finish(Database.BatchableContext BC)
    {
    }

    /*********************************************************************************
    Method Name    : makeCallouts
    Description    : This method gets the geolocation value for a address and inserts the value into respective record
    Return Type    : void
    Parameter      : List<Id>  -  Context for the batch
    *********************************************************************************/
    public void makeCallouts(List<Id> Ids) {
        List<Account> accountsToUpdate = new List<Account> ();
        try {
            list<Account> lstSobject;
            //The Free version of Google Geolocation API supports quering only one address in one callout
            String sAddress;
            String url;
            Http httpGetRequest;
            HttpRequest httpReq;
            HttpResponse httpResponseAddress;
            JSONParser parser;
            GeolocationResponse response;
            GeolocationLocation location;

            /** PC-7654: Added null check for PC_ProtectedApiValue__c value to prevent null pointer exception. If the required value is present only then further logic would get executed**/
            if (PC_ProtectedApiSettings__c.getInstance(PC_Constants.PC_GEOCODE_API_NAME) != null) {
               /*
              * FLS Check for Account
              */
                List<String> fields = new List<String>{PC_Constants.getQualifiedAPIName('PC_Primary_Address_1__c'), PC_Constants.getQualifiedAPIName('PC_Primary_City__c'),
                        PC_Constants.getQualifiedAPIName('PC_Primary_State__c'), PC_Constants.getQualifiedAPIName('PC_Primary_Zip_Code__c')};
                PC_Database.assertAccess('Account',PC_Database.Operation.Reading, fields);

                // List<String> fields1 = new List<String>{PC_Constants.getQualifiedAPIName('PC_Geolocation__Latitude__s'), PC_Constants.getQualifiedAPIName('PC_Geolocation__Longitude__s')};
                //PC_Database.assertAccess('Account',PC_Database.Operation.Creating, fields1);

                /** PC-7654: Moved the code related to fetching Patient Connect Setting data out side below for loop**/
                String templateUrl = PC_SYSTEM.getPatientConnectSetting(PC_Constants.PC_GEOCODE_API_ENDPOINT_URL_SETTING_NAME, PC_Constants.PC_GEOCODE_API_ENDPOINT_URL_DEFAULT_VALUE);

                for (Account account : [SELECT PC_Primary_Address_1__c, PC_Primary_City__c, PC_Primary_State__c, PC_Primary_Zip_Code__c FROM Account WHERE Id IN :Ids]) {
                    sAddress = account.PC_Primary_Address_1__c + ',' + account.PC_Primary_City__c + ',' + account.PC_Primary_State__c + ',' + account.PC_Primary_Zip_Code__c;
                    sAddress = sAddress.replace(' ', '+');
                    List<Object> parameters = new List<Object> {sAddress, PC_ProtectedApiSettings__c.getInstance(PC_Constants.PC_GEOCODE_API_NAME).PC_ProtectedApiValue__c};
                    url = String.format(templateUrl, parameters);
                    httpGetRequest = new Http();
                    httpReq = new HttpRequest();
                    httpReq.setHeader('Content-type', 'application/x-www-form-urlencoded');
                    httpReq.setHeader('Content-length', '0');
                    httpReq.setEndpoint(url);
                    httpReq.setMethod('POST');
                    httpReq.setTimeout(RequestTimeout);
                    httpResponseAddress = httpGetRequest.send(httpReq);
                    parser = JSON.createParser(httpResponseAddress.getBody());
                    response = (GeolocationResponse) JSON.deserialize(httpResponseAddress.getBody(), GeolocationResponse.class);
                    System.debug(response);
                    if (response != null && response.results.size() > 0) {

                        location = response.results[0].geometry.location;
                        //account.PC_Geolocation__Latitude__s = location.lat;
                        account.BillingLatitude = location.lat;
                        //account.PC_Geolocation__Longitude__s =  location.lng;
                        account.BillingLongitude = location.lng;
                        accountsToUpdate.add(account);
                    }
                }
            }
            else{
                PC_Utility.createErrorLog(System.Label.PC_ProtectedApiSettingsMissingData);
            }
            if(!accountsToUpdate.isEmpty()) {
                PC_Database.upd(accountsToUpdate,false);
            }

        }
        catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
    }
    /*********************************************************************************
    Class Name      : GeolocationResponse
    Description     : Wrapper for Geolocation response
    *********************************************************************************/
    public inherited sharing class GeolocationResponse {
        List<GeolocationResponseResult> results {get;set;}
    }

    public inherited sharing class GeolocationResponseResult {
        public GeolocationResponseGeometry geometry {get; set;}
    }

    public inherited sharing class GeolocationResponseGeometry {
        public GeolocationLocation location {get; set;}
    }

    public inherited sharing class GeolocationLocation {
        public Decimal lat {get; set;}
        public Decimal lng {get; set;}
    }
}