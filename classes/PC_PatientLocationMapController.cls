/*********************************************************************************
Class Name      : PC_PatientLocationMapController
Description     : This class is used for retrieving all the nearby clinic locations related to a patient.
Created By      : Roxana Ivan
Created Date    : 27-May-15
Modification Log:
---------------------------------------------------------------------------------- 
Developer                   Date                    Description
-----------------------------------------------------------------------------------            
Roxana Ivan                 27-May-16               Initial Version
Shabda Bhujad,              Nov 3, 2016             Removed references to 'Full Type' - annotated by @@RemoveFullType
Prachi Nandgaonkar
Shabda Bhujad               Dec 06, 2016            Added FLS check to PC_PatientLocationMapController, getPatientInfo, retrieveNearbyAccounts methods
Ajinkya Deshmukh			June 08, 2017			FLS Check Added
Tejas Patel                 July 31, 2017           [PC-1984] Translation Issue
Mayuresh Patil              July 26, 2017           Updated CRUD/FLS Checks
Mike Klumpenaar             2017-08-10              [PC-2007] Remove dependency on PC_Services.picklistFieldMap and call
                                                    PC_PicklistFieldManager instead
Tejas Patel                 Sept 5, 2017            [PC-2014] Added retrieveNearbySP() to fetch pharmacies for a product's Limited Distribution Network
Prachi Nandgaonkar          Sept 6, 2017            [PC-2014] Modified retrieveNearbySP()
Prachi Nandgaonkar          Sept 15, 2017           [PC-2217]Updated retrieveNearbySP() with updated Distribution Network object name
Ramtej Juloori              Sept 28, 2017           [PC-2265] Pharmacies are not showing up in Referral Map
Tejas Patel					Nov 08, 2017			Created new custom label PC_Map_Display_Pharmacy_Types
Tejas Patel					Nov 11, 2017			[PC-2301] updated getClinicImagesL to dynamically display legends depending on selections
Vijay Kashikar				Nov 21, 2017			PC-2497 Changes related to using Salesforce geocoding
Tejas Patel                 Apr 17,2018             PC-2674 No Patient Account associated to Case
Mayuresh Patil             APr 29, 2019            [PC-4766] consider radius from system setting when calculating nearby Accounts and Clinics
Haritha Reddy              Dec 17, 2019            [PC-5791] Added error handling for Methods where it was missing
Haritha Reddy         21-Jan-2021              [PC-7102] Force Reviewer scan issue fix. Updated Sharing declaration.
*********************************************************************************/

public with sharing class PC_PatientLocationMapController{
    public static final String RECORDTYPE_ACCOUNT = 'Account';
    public static final String RECORDTYPE_PHARMACY = 'Pharmacy';

    private static List<PC_PicklistFieldManager.PicklistEntryWrapper> accSubTypes = PC_PicklistFieldManager.getPicklistEntryWrappers(Account.PC_Sub_Type__c);
    private static String accSubType;

    public static string clinicType {
        get{
            return clinicType;
        }
        set{
            clinicType = String.escapeSingleQuotes(value);
        }
    }
    public Account patient{ set; get; }
    public Map<String, String> clinicImages { set; get; }
    public List<SelectOption> clinics {set; get; }

    public static boolean productrealtedCheck = false; // [PC-2265] boolean check to retrieve inclusion of pharmacies within and out of ditribution network

    /*********************************************************************************
	Method Name    : productAccountBooleanSet
	Description    : This method sets the boolean check to retrieve inclusion of pharmacies within and out of ditribution network
	Return Type    : void
	Parameter      : boolean
	*********************************************************************************/
    @auraEnabled
    public static void productAccountBooleanSet(boolean check){
        productrealtedCheck = check;
    }
    
    //constructor
    public PC_PatientLocationMapController(ApexPages.StandardController controller) {
        try {
            Case case1 = (Case)controller.getRecord();
            List<String> fields = new List<String>{'AccountId'};
                PC_Database.assertAccess(PC_Constants.PC_CASE,PC_Database.Operation.Reading, fields);
            Case myCase = [SELECT AccountId FROM Case where Id =: case1.Id ];
            fields = new List<String>{'Name', PC_Constants.getQualifiedAPIName('PC_Sub_Type__c'), PC_Constants.getQualifiedAPIName('PC_Primary_Address__c'), 'Phone',PC_Constants.getQualifiedAPIName('PC_Geolocation__c')};
            PC_Database.assertAccess(PC_Constants.PC_ACCOUNT,PC_Database.Operation.Reading, fields);
            fields = new List<String>{PC_Constants.getQualifiedAPIName('PC_Address_1__c'), PC_Constants.getQualifiedAPIName('PC_City__c')};
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Address__c'),PC_Database.Operation.Reading, fields);
            patient = [SELECT Id, Name, RecordType.Name, PC_Sub_Type__c, PC_Primary_Address__r.PC_Address_1__c, PC_Primary_Address__r.PC_City__c, Phone,
                            BillingLatitude, BillingLongitude FROM Account where Id =: myCase.AccountId ];
            clinicImages = new Map<String, String>();
            clinics = new List<SelectOption>();
            clinics.add(new SelectOption(Label.PC_All, Label.PC_All));
            integer radius = integer.valueof(PC_System_Settings__c.getInstance().PC_Google_Map_Location_Radius__c);
            for(Account acc : retrieveNearbyAccounts(patient.Id, patient.BillingLatitude, patient.BillingLongitude , Label.PC_All, radius)) {
                if(!clinicImages.containsKey(acc.PC_Sub_Type__c)) {
                    clinics.add(new SelectOption(acc.PC_Sub_Type__c, acc.PC_Sub_Type__c));
                    clinicImages.put(acc.PC_Sub_Type__c, acc.PC_Map_Image__c);
                }
            }
        } catch (exception e) {
            PC_Utility.logAndThrowException(e);
        }
    } 

    /*********************************************************************************
	Method Name    : getClinics
	Description    : This method displays the different clinic types in vf page
	Return Type    : List<SelectOption> - list of clinc types
	Parameter      : None
	*********************************************************************************/
    @AuraEnabled
    public static List<PC_LightningMap> getClinicImagesL(Account patient, Integer radius, Boolean genericMap , Id recordId, String clincType) {
        system.debug(' Account '+patient+' radius '+radius);
        Set<String> clinicSet = new Set<String>();
        List<PC_LightningMap> options = new List<PC_LightningMap>();
        LIST<Account> retriveAccounts;
        try {
            if (genericMap == true) {
                retriveAccounts = retrieveNearbyAccounts(patient.Id, (Decimal) patient.BillingLatitude, (Decimal) patient.BillingLongitude, clincType, radius);
            } else {
                retriveAccounts = retrieveNearbySP(patient.Id, (Decimal) patient.BillingLatitude, (Decimal) patient.BillingLongitude, clincType, recordId, radius);
            }
            for (Account acc : retriveAccounts) {
                if (!clinicSet.contains(acc.PC_Sub_Type__c)) {
                    clinicSet.add(acc.PC_Sub_Type__c);
                    for (PC_PicklistFieldManager.PicklistEntryWrapper st : accSubTypes) {
                        if (acc.PC_Sub_Type__c == st.value) {
                            options.add(new PC_LightningMap(st.label, '/resource/' + PC_Constants.getQualifiedAPIName('PC_Resources') + '/PC_Resources/Images/MapImages/' + acc.PC_Map_Image__c));
                        }
                    }
                }
            }
        } catch (exception e) {
            PC_Utility.logAndThrowException(e);
        }
        return options;
    }

    /*********************************************************************************
	Method Name    : getClinics
	Description    : This method displays the different clinic types in vf page
	Return Type    : List<SelectOption> - list of clinc types
	Parameter      : None
	*********************************************************************************/
    @AuraEnabled
    public static List<PC_LightningMap> getMapClinics(Account patient, Boolean genericMap) {
        List<PC_LightningMap> options = new List<PC_LightningMap>();
        try {
            String mapDisplay;
            List<string> mapDisplayList = new List<String>();
            if (genericMap == true) {
                mapDisplay = System.Label.PC_Map_Display_Account_Types;
                for (string str : mapDisplay.split(',')) {
                    mapDisplayList.add(str.trim());
                }
            } else {
                mapDisplay = System.Label.PC_Map_Display_Pharmacy_Types;
                mapDisplayList.add(mapDisplay);
            }

            Map<String, List<PC_PicklistFieldManager.PicklistEntryWrapper>> picklistFieldMap = PC_PicklistFieldManager.picklistFieldMap(Account.Type, Account.PC_Sub_Type__c);
            options.add(new PC_LightningMap(Label.PC_All, Label.PC_All));
            //PC-2302 Display proper options in picklist when map is launched from pharmacy regerral or book an appointment
            //for(String type: picklistFieldMap.keySet()) {
            for (string str : mapDisplayList) {
                for (PC_PicklistFieldManager.PicklistEntryWrapper subtype : picklistFieldMap.get(str)) {
                    if (Label.PC_Map_Display_Account_Types.contains(str)) {
                        options.add(new PC_LightningMap(subtype.label, subtype.value));
                    }
                }
            }
        } catch (exception e) {
            PC_Utility.logAndThrowException(e);
        }

        //}
        return options;
    }
    /*********************************************************************************
	Method Name    : getPatientInfo
	Description    : Retrieve patient info
	Return Type    : Account
	Parameter      : String caseId   - current case Id
	*********************************************************************************/
    @AuraEnabled
    public static Account getPatientInfo(Account p_patient, String caseId) {
        try {
            List<String> fields = new List<String>{'AccountId'};
                PC_Database.assertAccess(PC_Constants.PC_CASE,PC_Database.Operation.Reading, fields);
            Case currentCase = [SELECT AccountId FROM Case WHERE ID =: caseId LIMIT 1];
            fields = new List<String>{'Name','BillingLatitude', 'BillingLongitude', PC_Constants.getQualifiedAPIName('PC_Primary_Address__c')};
            PC_Database.assertAccess(PC_Constants.PC_ACCOUNT,PC_Database.Operation.Reading, fields);
            fields = new List<String>{PC_Constants.getQualifiedAPIName('PC_Complete_Address__c')};
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Address__c'),PC_Database.Operation.Reading, fields);
            Account patient = NULL;
            if(currentCase.AccountId != NULL) {
                patient = [
                        Select Id, Name, RecordType.Name, BillingLatitude, BillingLongitude, PC_Primary_Address__r.PC_Complete_Address__c
                        from Account
                        where Id = :currentCase.AccountId
                        LIMIT 1
                ];
            }
            return patient;
        } catch (exception e) {
            PC_Utility.logAndThrowException(e);
            return null;
        }
    }
    /*********************************************************************************
	Method Name    : getNearbyClinics
	Description    : This retrieves the nearby clinic locations
	Return Type    : List<Account> - list of clinc records
	Parameter      : 1. Latitude - Latitude of the patient
	2. Longitude - Longitude of the patient record
	*********************************************************************************/
    @AuraEnabled
    public static List<Account> getNearbyClinics(Account patient, string clincType, Boolean genericMap, ID recordId, Integer radius) {
        try {
            radius = integer.valueof(PC_System_Settings__c.getInstance().PC_Google_Map_Location_Radius__c);
            if (genericMap == true) {
                return retrieveNearbyAccounts(patient.Id, (Decimal) patient.BillingLatitude, (Decimal) patient.BillingLongitude, clincType, radius);
            } else {
                return retrieveNearbySP(patient.Id, (Decimal) patient.BillingLatitude, (Decimal) patient.BillingLongitude, clincType, recordId, radius);
            }
        } catch (exception e) {
            PC_Utility.logAndThrowException(e);
            return null;
        }
    }
    /*********************************************************************************
	Method Name    : isDistanceInKM
	Description    : Use km as distance unit?
	Return Type    : Boolean
	Parameter      :
    *********************************************************************************/
    @AuraEnabled
    public static Boolean isDistanceInKM() {
        return PC_System_Settings__c.getInstance().PC_Google_Map_Radius_Is_KM__c;
    } 

    /*********************************************************************************
	Method Name    : getNearbyAccounts
	Description    : This retrieves the nearby clinic locations
	Return Type    : List<Account> - list of clinc records
	Parameter      : 1. Latitude - Latitude of the patient
					 2. Longitude -Longitude of the patient record
	*********************************************************************************/
    @RemoteAction
    public static List<Account> getNearbyAccounts(Id patientId, Decimal latitude, Decimal longitude, String clincType) {
        integer radius = integer.valueof(PC_System_Settings__c.getInstance().PC_Google_Map_Location_Radius__c);
        return retrieveNearbyAccounts(patientId, latitude, longitude, clincType, radius);   
    }
    /*********************************************************************************
	Method Name    : retrieveNearbyAccounts
	Description    : common method for retrieveing nearby clinic locations
	Return Type    : List<Account> - list of clinc records
    Parameter      : 1. Latitude - Latitude of the patient
					 2. Longitude -Longitude of the patient record
	*********************************************************************************/
    public static List<Account> retrieveNearbyAccounts(Id patientId, Decimal latitude, Decimal longitude, String clincType, Integer radius) {
        String distanceUnit = (PC_System_Settings__c.getInstance().PC_Google_Map_Radius_Is_KM__c) ? PC_Constants.PC_KM :PC_Constants.PC_MI;
        radius = integer.valueof(PC_System_Settings__c.getInstance().PC_Google_Map_Location_Radius__c);
        String sQuery = 'SELECT Id, Name, RecordType.Name, RecordTypeId, Phone, '
            + PC_Constants.getQualifiedAPIName('PC_Hours__c')
            + ', ' + PC_Constants.getQualifiedAPIName('PC_Sub_Type__c')
            + ', ' + PC_Constants.getQualifiedAPIName('PC_Features__c')
            + ', ' + PC_Constants.getQualifiedAPIName('PC_Map_Image__c')
            + ', ' + PC_Constants.getQualifiedAPIName('PC_Primary_Address__r') + '.' + PC_Constants.getQualifiedAPIName('PC_Complete_Address__c')
            + ', ' + ' BillingLatitude '
            + ', ' + ' BillingLongitude '
            + ' FROM Account '
            + 'WHERE Id != \'' + patientId +'\' AND '
            + PC_Constants.getQualifiedAPIName('PC_Display_on_Map__c') + ' = TRUE AND '
            //+ 'DISTANCE' + '(' + PC_Constants.getQualifiedAPIName('PC_Geolocation__c') + ', GEOLOCATION( '
            + 'DISTANCE' + '(' +  'BillingAddress' +  ', GEOLOCATION( '
            + String.valueOf(latitude) + ', ' + String.valueOf(longitude)
            + ' ), \'' + distanceUnit + '\') <' + radius;

        if(clincType != null && clincType != '' && clincType != Label.PC_All){
            sQuery += ' AND ' + PC_Constants.getQualifiedAPIName('PC_Sub_Type__c') +  '= \'' + String.escapeSingleQuotes(clincType) + '\' ';
        }

        List<Account> accounts = new List<Account>();
        try {
            //Replace with Qualified field names            
            List<String> fields = new List<String>{'Name','Phone','BillingAddress',PC_Constants.getQualifiedAPIName('PC_Hours__c'),PC_Constants.getQualifiedAPIName('PC_Sub_Type__c'),PC_Constants.getQualifiedAPIName('PC_Features__c'),PC_Constants.getQualifiedAPIName('PC_Map_Image__c'),PC_Constants.getQualifiedAPIName('PC_Primary_Address__c'), PC_Constants.getQualifiedAPIName('PC_Display_on_Map__c')};
            accounts = PC_Database.queryWithAccess(sQuery , fields);
        } catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }               
        
        return accounts;
    }

    //PC-2014
    /*********************************************************************************
	Method Name    : retrieveNearbySP
	Description    : common method for retrieveing nearby clinic locations
	Return Type    : List<Account> - list of pharmacy records
	Parameter      : 1. Patient Id
					 2. Latitude - Latitude of the patient
					 3. Longitude -Longitude of the patient record
					 4. clincType -Type of Account
                     5. RecordId - Program Case Id
                     6. Radius - Radius of search
	*********************************************************************************/
    public static List<Account> retrieveNearbySP(Id patientId, Decimal latitude, Decimal longitude, String clincType, ID recordId, Integer radius) {
        //FLS check before querying
        try {
            List<String> fields = new List<String>{PC_Constants.getQualifiedAPIName('PC_Program_Product__c')};
         	//FLS check access before SOQL
            PC_Database.assertAccess(PC_Constants.PC_CASE,PC_Database.Operation.Reading, fields);

            //Fetch Pharmacy accounts from Distribution Network where product id = product id from program case of referral
            //Fetch Engagement Program Product Id from program case
            Case engProduct = [SELECT PC_Program_Product__r.PC_Product__c FROM Case WHERE Id =: recordId];
            //Fetch Product Id from Engagement Program Product
            ID product = engProduct.PC_Program_Product__r.PC_Product__c;

            //FLS check before SOQL
            fields = new List<String>{PC_Constants.getQualifiedAPIName('PC_Pharmacy__c'), PC_Constants.getQualifiedAPIName('PC_Product__c')};
            //FLS check access before SOQL
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Distributor__c'),PC_Database.Operation.Reading, fields);
            //Fetch list of Account Ids for pharmacy accounts in Drug's Distribution Network
            Map<ID,Account> spAccounts = new MAP<Id,Account>([SELECT ID FROM Account WHERE ID In
                                                              (SELECT PC_Pharmacy__c
                                                               FROM PC_Distributor__c
                                                               WHERE PC_Product__c =: product)
                                                             ]);
            //Create a key set of account ids to be used in dynamic SOQL as a variable
            Set<ID> keys = spAccounts.keyset();
        } catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }

        String distanceUnit = (PC_System_Settings__c.getInstance().PC_Google_Map_Radius_Is_KM__c) ? PC_Constants.PC_KM :PC_Constants.PC_MI;
        radius = integer.valueof(PC_System_Settings__c.getInstance().PC_Google_Map_Location_Radius__c);
        //Dynamic SOQL to fetch Account location details for pharmacy accounts in Distribution Network and within 100 miles of patient's address
        string rtypeId = [SELECT Id FROM RecordType WHERE SobjectType =: RECORDTYPE_ACCOUNT AND Name =: RECORDTYPE_PHARMACY].Id;
        String sQuery = 'SELECT Id, Name, RecordType.Name, RecordTypeId, Phone, '
            + PC_Constants.getQualifiedAPIName('PC_Hours__c')
            + ', ' + PC_Constants.getQualifiedAPIName('PC_Sub_Type__c')
            + ', ' + PC_Constants.getQualifiedAPIName('PC_Features__c')
            + ', ' + PC_Constants.getQualifiedAPIName('PC_Map_Image__c')
            + ', ' + PC_Constants.getQualifiedAPIName('PC_Primary_Address__r') + '.' + PC_Constants.getQualifiedAPIName('PC_Complete_Address__c')
            + ', ' + PC_Constants.getQualifiedAPIName('PC_Geolocation__Latitude__s')
            + ', ' + PC_Constants.getQualifiedAPIName('PC_Geolocation__Longitude__s')
            + ' FROM Account '
            + 'WHERE Id != \'' + patientId +'\' AND Id IN :keys AND '
            + PC_Constants.getQualifiedAPIName('PC_Display_on_Map__c') + ' = TRUE AND '
            + 'DISTANCE' + '(' + PC_Constants.getQualifiedAPIName('PC_Geolocation__c') + ', GEOLOCATION( '
            + String.valueOf(latitude) + ', ' + String.valueOf(longitude)
            + ' ), \'' + distanceUnit + '\') <' + radius
            + 'AND RecordTypeId = \''+rtypeId+'\'';


        /*if(clincType != null && clincType != '' && clincType != Label.PC_All){
            sQuery += ' AND ' + PC_Constants.getQualifiedAPIName('PC_Sub_Type__c') +  '= \'' + String.escapeSingleQuotes(clincType) + '\' ';
        }*/ // [PC-2265] moving subtype filter to later part of logic
        //System.debug('@@Query: '+ sQuery );


        List<Account> accounts = new List<Account>();
        try {
            //FLS Check
            List<String> fields = new List<String>{'Name','Phone',PC_Constants.getQualifiedAPIName('PC_Hours__c'),PC_Constants.getQualifiedAPIName('PC_Sub_Type__c'),
                									PC_Constants.getQualifiedAPIName('PC_Features__c'),PC_Constants.getQualifiedAPIName('PC_Map_Image__c'),
                									PC_Constants.getQualifiedAPIName('PC_Primary_Address__c'),PC_Constants.getQualifiedAPIName('PC_Geolocation__c')};

            if(PC_Database.chkAccess(PC_Constants.PC_ACCOUNT, PC_Database.Operation.Reading, fields))
            {
        	    accounts = Database.query(sQuery);    //Cannot use PC_Database.queryWithAccess() because passing a variable :keys in above dynamic SOQL.
			}
        } catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        if(productrealtedCheck){
            List<Account> tempAccounts = retrieveNearbyAccounts( patientId, latitude, longitude, Label.PC_All, radius);
            //accounts.addAll(tempAccounts);
            for(Account acc :tempAccounts){
                if(acc.RecordTypeId == rtypeId){
                    accounts.add(acc);
                }
            }
        }
        else{
            if(accounts.isEmpty() || accounts == null || accounts.size() == 0){
                List<Account> tempAccounts =  retrieveNearbyAccounts( patientId, latitude, longitude, Label.PC_All, radius);
                for(Account acc :tempAccounts){
                    if(acc.RecordTypeId == rtypeId){
                        accounts.add(acc);
                    }
                }
            }
        }
        if(clincType == null || clincType == PC_Constants.EMPTY_STRING || clincType == Label.PC_All){
            return accounts;
        }
        else{
            List<Account> retAccList = new List<Account>();
            for(Account acc :accounts){
                if(acc.PC_Sub_Type__c == clincType){
                    retAccList.add(acc);
                }
            }
            return retAccList;
        }
    }
    
    @AuraEnabled
    public static FieldLabel getFieldLabels(){
        FieldLabel fl = new FieldLabel();
        try {
            fl.address = Label.PC_MapPopUp_Address;
            fl.phone = Label.PC_MapPopUp_Phone;
            fl.openhours = Label.PC_MapPopUp_OpenHour;
            fl.feature = Label.PC_MapPopUp_Feature;
            fl.distance = Label.PC_MapPopUp_Distance;
            fl.button = Label.PC_MapPopUp_Button;
        }catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return fl;

    }

    public inherited sharing class FieldLabel{
        @AuraEnabled public String address { get; set; }
        @AuraEnabled public String phone { get; set; }
        @AuraEnabled public String openhours { get; set; }
        @AuraEnabled public String feature { get; set; }
        @AuraEnabled public String distance { get; set; }
        @AuraEnabled public String button { get; set; }

        public FieldLabel() {
        }
    }
}