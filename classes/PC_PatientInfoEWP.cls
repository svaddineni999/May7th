/**
 * Class Name      : PC_PatientInfoEWP
 * Created By      :
 * Created Date   :
 * Modification Log:
 * ----------------------------------------------------------------------------------
 * Developer              Date                   	Description
 * -----------------------------------------------------------------------------------
 * Tejas Patel        					        	Initial Version
 * Shabda Bhujad		  17-March-2017 			Updated method getApplicant() to select applicants of type Internal only
 * Shabda Bhujad 		  23-March-2017				Added 'dataChk' flag to Address wrapper and Field Labels wrapper
 * Prachi Nandgaonkar     29-March-2017             [PC-1376] Initialized Account fields to empty string to persist data in Enrollment Wizard
 *                                                  with locker services on
 * Shabda Bhujad		  30-March-2017				[PC-1384] Implemented FLS check for select query and removed the separate chk for querying access to fields
 * Shabda Bhujad		  31-March-2017				[PC-1402] Added applicant fields to get online applicant information when available
 * Shabda Bhujad 		  08-April-2017				[PC-1412] Added logic to get multiple addresses for applicant
 * Shabda Bhujad 		  10-April-2017				[PC-1408] Removed the method SaveAccount as it was not used anywhere.
 * Shabda Bhujad 		  10-April-2017				[PC-1403] Added logic to getApplicant method to get online application information for Patient Info and address.
 * 													[PC-1413] Refactored the class to get the address as a patient of Account record
 * Prachi Nandgaonkar     14-April-2017             [PC-1379] Updated getApplicant() to query applicant object with activeApplicant input parameter to handle multiple applicants on same enrollment case
 * Prachi Nandgaonkar     18-April-2017             [PC-1457] Updated getExistingAddress() to loop through multiple addresses on existing Account
 * Vijay Kashikar	      03-May-2017            	Fixed an issue w.r.t casting the field value.
 * Shabda Bhujad		  03-May-2017				[PC-1513]Added logic to set applicantSourceId on address as relevant.
 * Vijay Kashikar		  31-May-2017			 	[PC-1525] Ensure Wizard can handle online forms with custom fields & wizards with custom pages
 * Vijay Kashikar		  20-Jun-2017				[PC-1773]Fixed - For fields in the "ignoreFields":[] section in the Config, exception msg  is shown instead of blank value on the fields.
 * Ajinkya Deshmukh		  22-Jun-2017				FLS Check Added (Code Merge)
 * Tejas Patel            27-Jun-2017               [PC-1774] Remove AccountNumber from FLS as it is not being used in SOQL
 * Mike Klumpenaar        12-July-2017              [PC-1885] Added support for translation
 * Mayuresh Patil         07-Sep-2017               PC-2193 FLS Check updated to new PC303 code
 * Tejas Patel			  08-Nov-2017				Removed unsed varaible private static String FIELDSET_KEY = 'fieldSet';
 * Vijay Kashikar		  17-Jan-2018				PC-2672 Modified getAccount and getApplicant to query with access with fields that do not have duplicates;
 * Vijay Kashikar		  18-Jan-2018				PC-2672 Added namespace qualifier in getApplicant() method to all the fields.;
 * Kishore Kanteti        12-Dec-2019               PC-5975 Reduced parameters in getAccountorApplicant and getApplicant Methods.
 * Haritha Reddy          17-Dec-2019              [PC-5791] Added error handling for Methods where it was missing
 * Xiukai Ning            9-July-2020               [PC-5724] Read Address Auto Complete custom metadata
 * Vijay Kashikar         21-Jan-2021               [PC-7102] Added sharing clause
 * Kishore Kanteti        27-Aug-2021               [PC-8007] Changed the source of online form addresses to record type.
*/
public with sharing class PC_PatientInfoEWP {

    @AuraEnabled
    public static Map<String, List<PC_PicklistFieldManager.PicklistEntryWrapper>> getPicklistEntryMap() {
        Map<String, List<PC_PicklistFieldManager.PicklistEntryWrapper>> picklistEntryMap =
                new Map<String, List<PC_PicklistFieldManager.PicklistEntryWrapper>>();
        try {

            picklistEntryMap.put('salutation', PC_PicklistFieldManager.getPicklistEntryWrappers(Account.PC_Salutation__c));
            picklistEntryMap.put('communicationLanguage', PC_PicklistFieldManager.getPicklistEntryWrappers(Account.PC_Communication_Language__c));
            picklistEntryMap.put('relationToPatient', PC_PicklistFieldManager.getPicklistEntryWrappers(Account.PC_Caregiver_Relationship_to_Patient__c));
            picklistEntryMap.put('caregiverSalutation', PC_PicklistFieldManager.getPicklistEntryWrappers(Account.PC_Caregiver_Salutation__c));
            picklistEntryMap.put('communicationChannel', PC_PicklistFieldManager.getPicklistEntryWrappers(Account.PC_Preferred__c));
            picklistEntryMap.put('status', PC_PicklistFieldManager.getPicklistEntryWrappers(Account.PC_Status__c));
            picklistEntryMap.put('gender', PC_PicklistFieldManager.getPicklistEntryWrappers(Account.PC_Gender__c));
            picklistEntryMap.put('addrType', PC_PicklistFieldManager.getPicklistEntryWrappers(PC_Address__c.PC_Address_Description__c));
            picklistEntryMap.put('addrStatus', PC_PicklistFieldManager.getPicklistEntryWrappers(PC_Address__c.PC_Status__c));
            picklistEntryMap.put('countries', PC_PicklistFieldManager.getPicklistEntryWrappers(PC_Address__c.PC_Country__c));
        }catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }

        return picklistEntryMap;
    }

    @AuraEnabled
    public static FieldLabels getFieldLabels(){
        FieldLabels fieldlabels 					= new FieldLabels();
        try {
            fieldlabels.account = PC_Address__c.PC_Account__c.getDescribe().getLabel();
            fieldlabels.address = PC_Address__c.Name.getDescribe().getLabel();
            fieldlabels.address1 = PC_Address__c.PC_Address_1__c.getDescribe().getLabel();
            fieldlabels.address2 = PC_Address__c.PC_Address_2__c.getDescribe().getLabel();
            fieldlabels.address3 = PC_Address__c.PC_Address_3__c.getDescribe().getLabel();
            fieldlabels.addressType = PC_Address__c.PC_Address_Description__c.getDescribe().getLabel();
            fieldlabels.city = PC_Address__c.PC_City__c.getDescribe().getLabel();
            fieldlabels.country = PC_Address__c.PC_Country__c.getDescribe().getLabel();
            fieldlabels.state = PC_Address__c.PC_State__c.getDescribe().getLabel();
            fieldlabels.addrstatus = PC_Address__c.PC_Status__c.getDescribe().getLabel();
            fieldlabels.zipCode = PC_Address__c.PC_Zip_Code__c.getDescribe().getLabel();
            fieldlabels.primary = PC_Address__c.PC_Primary_Address__c.getDescribe().getLabel();
            fieldlabels.addrlastModifiedDate = PC_Address__c.LastModifiedDate.getDescribe().getLabel();
            fieldlabels.source = Label.PC_Address_Source;
            fieldlabels.flag = 'Flag';

            fieldlabels.firstName = Account.PC_First_Name__c.getDescribe().getLabel();
            fieldlabels.lastName = Account.PC_Last_Name__c.getDescribe().getLabel();
            fieldlabels.salutation = Account.PC_Salutation__c.getDescribe().getLabel();
            fieldlabels.email = Account.PC_Email__c.getDescribe().getLabel();
            fieldlabels.phone = Account.Phone.getDescribe().getLabel();
            fieldlabels.fax = Account.Fax.getDescribe().getLabel();
            fieldlabels.name = Account.Name.getDescribe().getLabel();
            fieldlabels.communicationLanguage = Account.PC_Communication_Language__c.getDescribe().getLabel();
            fieldlabels.preferredCommunicationChannel = Account.PC_Preferred__c.getDescribe().getLabel();
            fieldlabels.accstatus = Account.PC_Status__c.getDescribe().getLabel();
            fieldlabels.caregiverSalutation = Account.PC_Caregiver_Salutation__c.getDescribe().getLabel();
            fieldlabels.caregiverRelation = Account.PC_Caregiver_Relationship_to_Patient__c.getDescribe().getLabel();
            fieldlabels.caregiverFirstName = Account.PC_Caregiver_First_Name__c.getDescribe().getLabel();
            fieldlabels.caregiverLastName = Account.PC_Caregiver_Last_Name__c.getDescribe().getLabel();
            fieldlabels.dob = Account.PC_Date_of_Birth__c.getDescribe().getLabel();
            fieldlabels.gender = Account.PC_Gender__c.getDescribe().getLabel();
            fieldlabels.acclastModifiedDate = Account.LastModifiedDate.getDescribe().getLabel();
        }catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }

        return fieldlabels;
    }

    @AuraEnabled
    public static String getAddressAutoCompleteSetting() {
        String addressAutoComplete;
        try {
            addressAutoComplete = PC_SYSTEM.getPatientConnectSetting(PC_Constants.PC_AUTOCOMPLETE_ADDRESS,null);
        }catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return addressAutoComplete;
    }

    @AuraEnabled
    public static list<AddressRecord> getExistingAddress(Id patientId){
        List<AddressRecord> address = new List<AddressRecord>();
        try {
            List<String> fields = new List<String>{'Name','LastModifiedDate',PC_Constants.getQualifiedAPIName('PC_Account__c'),PC_Constants.getQualifiedAPIName('PC_Address_1__c'),
                    PC_Constants.getQualifiedAPIName('PC_Address_2__c'),PC_Constants.getQualifiedAPIName('PC_Address_3__c'),PC_Constants.getQualifiedAPIName('PC_Address_Description__c'),
                    PC_Constants.getQualifiedAPIName('PC_City__c'),
                    PC_Constants.getQualifiedAPIName('PC_Country__c'),
                    PC_Constants.getQualifiedAPIName('PC_State__c'),PC_Constants.getQualifiedAPIName('PC_Status__c'),
                    PC_Constants.getQualifiedAPIName('PC_Zip_Code__c'),PC_Constants.getQualifiedAPIName('PC_Primary_Address__c')
            };
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Address__c'),PC_Database.Operation.Reading, fields);

            //[PC-1457] Get multiple addresses from existing account
            for(PC_Address__c a : [Select Id,PC_Account__c,Name,PC_Address_1__c,PC_Address_2__c,PC_Address_3__c,PC_Address_Description__c,
                    PC_City__c, PC_Country__c,PC_State__c, PC_Status__c,PC_Zip_Code__c,PC_Primary_Address__c,LastModifiedDate
            from PC_Address__c where PC_Account__c =:patientId]) {
                address.add(new AddressRecord(a));
            }


        }catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return address;
    }

    @AuraEnabled
    public static AccountRecord getAccountorApplicant(Map<String,String> enrollDetails, String[] ignoreFields){
        try {
            Id patientId = (Id) enrollDetails.get('patientId');
            String fieldSetName = '';
            fieldSetName = enrollDetails.get('fieldSetName');
            if (patientId == null) {
                return getApplicant (enrollDetails, ignoreFields);
            } else {
                return getAccount (patientId, fieldSetName);
            }
        }catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return null;
    }

    public static AccountRecord getApplicant(Map<String,String> enrollDetails, String[] ignoreFields) {
        Id patientId = (Id) enrollDetails.get('patientId');
        Id enrollmentId = (Id) enrollDetails.get('enrollmentId');
        Id activeApplicantId = (Id) enrollDetails.get('activeApplicantId');
        String fieldSetName = '';
        fieldSetName = enrollDetails.get('fieldSetName');
        String replaceTarget = '';
        replaceTarget = enrollDetails.get('replaceTarget');
        String replaceText = '';
        replaceText = enrollDetails.get('replaceText');
        AccountRecord account = new AccountRecord();
        try {
            /*
             * Logic for FieldSet; Get the FieldSet fields
             */
            List<String> fsList = new List<String>();
            if(String.isNotBlank(fieldSetName)) {
                fsList = PC_FieldSetController.getFieldsByName(PC_Constants.PC_ACCOUNT, fieldSetName);
            }

            List<String> fields= new List<String>{'Id','LastModifiedDate','toLabel(RecordType.Name)',
                    PC_Constants.getQualifiedAPIName('PC_First_Name__c'),
                    PC_Constants.getQualifiedAPIName('PC_Last_Name__c'),
                    PC_Constants.getQualifiedAPIName('PC_Date_of_Birth__c'),
                    PC_Constants.getQualifiedAPIName('PC_Gender__c'),
                    PC_Constants.getQualifiedAPIName('PC_Salutation__c'),
                    PC_Constants.getQualifiedAPIName('PC_Communication__c'),
                    PC_Constants.getQualifiedAPIName('PC_Phone__c'),
                    PC_Constants.getQualifiedAPIName('PC_Patient_Email__c'),
                    PC_Constants.getQualifiedAPIName('PC_Preferred_Channel__c'),
                    PC_Constants.getQualifiedAPIName('PC_Address_1__c'),
                    PC_Constants.getQualifiedAPIName('PC_Address_2__c'),
                    PC_Constants.getQualifiedAPIName('PC_Address_Description__c'),
                    PC_Constants.getQualifiedAPIName('PC_Zip_Code__c'),
                    PC_Constants.getQualifiedAPIName('PC_City__c'),
                    PC_Constants.getQualifiedAPIName('PC_Country__c'),
                    PC_Constants.getQualifiedAPIName('PC_State__c'),
                    PC_Constants.getQualifiedAPIName('PC_Primary_Address__c'),
                    PC_Constants.getQualifiedAPIName('PC_Address1_1__c'),
                    PC_Constants.getQualifiedAPIName('PC_Address1_2__c'),
                    PC_Constants.getQualifiedAPIName('PC_Address1_Description__c'),
                    PC_Constants.getQualifiedAPIName('PC_Zip_Code1__c'),
                    PC_Constants.getQualifiedAPIName('PC_City1__c'),
                    PC_Constants.getQualifiedAPIName('PC_Country1__c'),
                    PC_Constants.getQualifiedAPIName('PC_State1__c'),
                    PC_Constants.getQualifiedAPIName('PC_Primary_Address1__c'),
                    PC_Constants.getQualifiedAPIName('PC_Caregiver_Salutation__c'),
                    PC_Constants.getQualifiedAPIName('PC_Caregiver_Relationship_to_Patient__c'),
                    PC_Constants.getQualifiedAPIName('PC_Caregiver_First_Name__c'),
                    PC_Constants.getQualifiedAPIName('PC_Caregiver_Last_Name__c')
            };

            List<String> fsListOfApplicant = new List<String>();
            Map<String, String> fsListMapOfApplicant = new Map<String, String>();
            if(fsList != null && fsList.size() > 0) {
                String newFieldName;
                for(String f : fsList) {
                    newFieldName = f.replace(replaceTarget, replaceText);
                    system.debug('New Field Name ' + newFieldName);
                    fsListOfApplicant.add(newFieldName);
                    fsListMapOfApplicant.put(f, newFieldName);
                }
                fields.addAll(fsListOfApplicant);
            }
            Set<String> fieldsAsSet = new Set<String>();
            List<String> fieldsWithoutDuplicates = new List<String>();
            fieldsAsSet.addAll(fields);

            List<String> ignoreFieldsOfApplicant = new List<String>();
            for(String f : ignoreFields) {
                ignoreFieldsOfApplicant.add(f.replace(replaceTarget, replaceText));
            }
            fieldsAsSet.removeAll(ignoreFieldsOfApplicant);

            fieldsWithoutDuplicates.addAll(fieldsAsSet);


            String query = PC_Constants.EMPTY_STRING + String.join(fieldsWithoutDuplicates, ', ');
            query = 'SELECT ' + query + ' ' + 'FROM ' +' PC_Applicant__c'+
                    ' WHERE Id' + '=' + '\'' + activeApplicantId + '\'' + ' Limit 1';
            system.debug(query);
            List<PC_Applicant__c> temp = PC_Database.queryWithAccess(query, fieldsWithoutDuplicates);

            /*
             * Populate the address from online form in wrapper
             */
            String fieldIndex;
            List<AddressRecord> applicantAddrs = new List<AddressRecord> ();
            AddressRecord applicantAddr;
            if (temp != null && !temp.isEmpty()) {
                //account = new AccountRecord(temp[0], fsList);
                account = new AccountRecord(temp[0], fsListMapOfApplicant);
                for(integer i=0; i<=1; i++) {
                    applicantAddr = new AddressRecord();
                    fieldIndex = (i==0) ? PC_Constants.EMPTY_STRING: PC_Constants.EMPTY_STRING+i;
                    applicantAddr.address=PC_Constants.NA;
                    applicantAddr.address1 = (String)temp[0].get(PC_Constants.getQualifiedAPIName('PC_Address'+fieldIndex+'_1__c'));
                    applicantAddr.address2 = (String)temp[0].get(PC_Constants.getQualifiedAPIName('PC_Address'+fieldIndex+'_2__c'));
                    applicantAddr.addressType = (String)temp[0].get(PC_Constants.getQualifiedAPIName('PC_Address'+ fieldIndex +'_Description__c'));
                    applicantAddr.city = (String)temp[0].get(PC_Constants.getQualifiedAPIName('PC_City'+fieldIndex + '__c'));
                    applicantAddr.country = (String)temp[0].get(PC_Constants.getQualifiedAPIName('PC_Country'+fieldIndex + '__c'));
                    applicantAddr.state = (String)temp[0].get(PC_Constants.getQualifiedAPIName('PC_State'+fieldIndex + '__c'));
                    applicantAddr.zipCode = (String)temp[0].get(PC_Constants.getQualifiedAPIName('PC_Zip_Code'+fieldIndex + '__c'));
                    applicantAddr.primary = (Boolean)temp[0].get(PC_Constants.getQualifiedAPIName('PC_Primary_Address'+fieldIndex +'__c'));
                    applicantAddr.lastModifiedDate = (DateTime)temp[0].get('LastModifiedDate');
                    applicantAddr.source = temp[0].RecordType.Name;//Label.PC_Address_SourceApplicant;
                    applicantAddr.flag = PC_Constants.PC_NEW;
                    applicantAddr.isAddressSelected = false;
                    applicantAddr.dataChk = false;
                    applicantAddr.applicantSourceId = (i==0) ? PC_Constants.PC_ZERO: PC_Constants.EMPTY_STRING+i;
                    if (applicantAddr.address1 != null ||applicantAddr.address2 != null || applicantAddr.city != null
                            || applicantAddr.country != null|| applicantAddr.state != null|| applicantAddr.zipCode != null) {
                        applicantAddrs.add(applicantAddr);
                    }
                }
                account.addrs = applicantAddrs;
            } else {
                return null;
            }
        }catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return account;
    }

    public static AccountRecord getAccount(Id patientId, String fieldSetName) {
        AccountRecord account = new AccountRecord();
        try {
            List<String> fields = new List<String>{
                    'Name','Phone','Fax','LastModifiedDate', PC_Constants.getQualifiedAPIName('PC_Salutation__c'),
                    PC_Constants.getQualifiedAPIName('PC_Status__c'),PC_Constants.getQualifiedAPIName('PC_First_Name__c'),PC_Constants.getQualifiedAPIName('PC_Last_Name__c'),
                    PC_Constants.getQualifiedAPIName('PC_Date_of_Birth__c'),PC_Constants.getQualifiedAPIName('PC_Gender__c'),
                    PC_Constants.getQualifiedAPIName('PC_Communication_Language__c'),PC_Constants.getQualifiedAPIName('PC_Email__c'), PC_Constants.getQualifiedAPIName('PC_Preferred__c'),
                    PC_Constants.getQualifiedAPIName('PC_Caregiver_Salutation__c'),PC_Constants.getQualifiedAPIName('PC_Caregiver_Relationship_to_Patient__c'),
                    PC_Constants.getQualifiedAPIName('PC_Caregiver_First_Name__c'),PC_Constants.getQualifiedAPIName('PC_Caregiver_Last_Name__c')
            };
            PC_Database.assertAccess(PC_Constants.PC_ACCOUNT,PC_Database.Operation.Reading, fields);
            /*
             * Logic for FieldSet - Get the FieldSet fields
             */
            List<String> fsList = new List<String>();
            if(String.isNotBlank(fieldSetName)) {
                fsList = PC_FieldSetController.getFieldsByName(PC_Constants.PC_ACCOUNT,fieldSetName);
            }
            if(fsList != null && fsList.size() > 0) {
                fields.addAll(fsList);
            }

            Set<String> fieldsAsSet = new Set<String>();
            List<String> fieldsWithoutDuplicates = new List<String>();
            fieldsAsSet.addAll(fields);
            fieldsWithoutDuplicates.addAll(fieldsAsSet);

            String query = PC_Constants.EMPTY_STRING + String.join(fieldsWithoutDuplicates, ', ');
            query = 'SELECT ' + query + ' ' + 'FROM ' + ' Account WHERE Id = \'' + patientId + '\' Limit 1';

            List<Account> temp = PC_Database.queryWithAccess(query, fieldsWithoutDuplicates);

            if (temp != null && !temp.isEmpty()) {
                account = new AccountRecord(temp[0], fsList);
                account.addrs = getExistingAddress (account.Id);
            } else {
                return null;
            }
        }catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return account;
    }

    public inherited sharing class AddressRecord {
        @AuraEnabled public Id Id { get; set; }
        @AuraEnabled public String account { get; set; }
        @AuraEnabled public String address { get; set; }
        @AuraEnabled public String address1 { get; set; }
        @AuraEnabled public String address2 { get; set; }
        @AuraEnabled public String address3 { get; set; }
        @AuraEnabled public String addressType { get; set; }
        @AuraEnabled public String city { get; set; }
        @AuraEnabled public String country { get; set; }
        @AuraEnabled public String countryLabel { get; set; }
        @AuraEnabled public String state { get; set; }
        @AuraEnabled public String stateLabel { get; set; }
        @AuraEnabled public String status { get; set; }
        @AuraEnabled public String statusLabel { get; set; }
        @AuraEnabled public String zipCode { get; set; }
        @AuraEnabled public Boolean primary { get; set; }
        @AuraEnabled public DateTime lastModifiedDate { get; set; }
        @AuraEnabled public String 	source { get; set; }
        @AuraEnabled public String flag { get; set; }
        @AuraEnabled public Boolean dataChk { get; set; }
        @AuraEnabled public String applicantSourceId {get; set;}
        @AuraEnabled public Boolean isAddressSelected { get; set; }

        public AddressRecord() {
        }

        public AddressRecord(PC_Address__c a) {
            Id 					= a.Id;
            account 			= a.PC_Account__c;
            address 			= a.Name;
            address1 			= a.PC_Address_1__c;
            address2 			= a.PC_Address_2__c;
            address3 			= a.PC_Address_3__c;
            addressType 		= a.PC_Address_Description__c;
            city 				= a.PC_City__c;
            country 			= a.PC_Country__c;
            state 				= a.PC_State__c;
            status 				= a.PC_Status__c;
            zipCode 			= a.PC_Zip_Code__c;
            primary 			= a.PC_Primary_Address__c;
            lastModifiedDate 	= a.LastModifiedDate;
            source				= Label.PC_Address_SourceExisting;
            flag				= 'No Update';
            dataChk				= true;
        }
    }

    //Account
    public inherited sharing class AccountRecord {
        @AuraEnabled public Id 		Id { get; set; }
        @AuraEnabled public Id 		applicantId { get; set; }
        @AuraEnabled public String 	firstName { get; set; }
        @AuraEnabled public String 	lastName { get; set; }
        @AuraEnabled public String 	salutation { get; set; }
        @AuraEnabled public String 	email { get; set; }
        @AuraEnabled public String 	phone { get; set; }
        @AuraEnabled public String 	fax { get; set; }
        @AuraEnabled public String 	name { get; set; }
        @AuraEnabled public String 	communicationLanguage { get; set; }
        @AuraEnabled public String 	preferredCommunicationChannel { get; set; }
        @AuraEnabled public String 	status { get; set; }
        @AuraEnabled public String 	caregiverSalutation { get; set; }
        @AuraEnabled public String 	caregiverRelation { get; set; }
        @AuraEnabled public String 	caregiverFirstName { get; set; }
        @AuraEnabled public String 	caregiverLastName { get; set; }
        @AuraEnabled public Date 	dob { get; set; }
        @AuraEnabled public String 	gender { get; set; }
        @AuraEnabled public Datetime lastModifiedDate { get; set; }
        @AuraEnabled public Map<String,Object> fsFields{get; set;}
        @AuraEnabled public List<AddressRecord> addrs {get; set;}

        public AccountRecord() {
        }

        public AccountRecord(Account a, List<String> fsList) {
            Id 								= a.Id;
            applicantId						= null;
            firstName 						= (a.PC_First_Name__c == null? PC_Constants.EMPTY_STRING : a.PC_First_Name__c);
            lastName 						= a.PC_Last_Name__c;
            salutation 						= (a.PC_Salutation__c == null? PC_Constants.EMPTY_STRING : a.PC_Salutation__c);
            email 							= (a.PC_Email__c == null? PC_Constants.EMPTY_STRING : a.PC_Email__c);
            phone 							= (a.Phone == null? PC_Constants.EMPTY_STRING : a.Phone);
            fax 							= (a.Fax == null? PC_Constants.EMPTY_STRING : a.Fax);
            name 							= a.Name;
            communicationLanguage 			= (a.PC_Communication_Language__c == null? PC_Constants.EMPTY_STRING : a.PC_Communication_Language__c);
            preferredCommunicationChannel	= (a.PC_Preferred__c == null? PC_Constants.EMPTY_STRING : a.PC_Preferred__c);
            status							= a.PC_Status__c;
            caregiverSalutation 			= (a.PC_Caregiver_Salutation__c == null? PC_Constants.EMPTY_STRING : a.PC_Caregiver_Salutation__c);
            caregiverRelation 				= (a.PC_Caregiver_Relationship_to_Patient__c == null? PC_Constants.EMPTY_STRING : a.PC_Caregiver_Relationship_to_Patient__c);
            caregiverFirstName 				= (a.PC_Caregiver_First_Name__c == null? PC_Constants.EMPTY_STRING : a.PC_Caregiver_First_Name__c);
            caregiverLastName 				= (a.PC_Caregiver_Last_Name__c == null? PC_Constants.EMPTY_STRING : a.PC_Caregiver_Last_Name__c);
            dob 							= a.PC_Date_of_Birth__c;
            gender 							= (a.PC_Gender__c == null? PC_Constants.EMPTY_STRING : a.PC_Gender__c);
            lastModifiedDate 				= a.LastModifiedDate;
            fsFields = new Map<String, Object>();
            Object fsFieldVal;
            for(String fieldName : fsList) {
                try {
                    fsFieldVal = PC_FieldSetController.castFieldValueBasedOnType(fieldName, a.get(fieldName), a);
                }
                catch(Exception e) {
                    fsFieldVal = PC_Constants.EMPTY_STRING;
                }
                fsFields.put(fieldName, fsFieldVal);
            }
        }

        public AccountRecord(PC_Applicant__c a, Map<String, String> fsListMap) {
            Id 								= null;
            applicantId						= a.Id;
            firstName 						= a.PC_First_Name__c == null? PC_Constants.EMPTY_STRING : a.PC_First_Name__c;
            lastName 						= a.PC_Last_Name__c  == null? PC_Constants.EMPTY_STRING :  a.PC_Last_Name__c;
            salutation 						= a.PC_Salutation__c == null? PC_Constants.EMPTY_STRING : a.PC_Salutation__c;
            email 							= a.PC_Patient_Email__c == null? PC_Constants.EMPTY_STRING : a.PC_Patient_Email__c;
            phone 							= a.PC_Phone__c == null? PC_Constants.EMPTY_STRING : a.PC_Phone__c;
            fax 							= PC_Constants.EMPTY_STRING;
            name 							= PC_Constants.EMPTY_STRING;
            communicationLanguage 			= a.PC_Communication__c == null? PC_Constants.EMPTY_STRING : a.PC_Communication__c;
            preferredCommunicationChannel	= a.PC_Preferred_Channel__c == null? PC_Constants.EMPTY_STRING : a.PC_Preferred_Channel__c;
            status							= PC_Constants.EMPTY_STRING;
            caregiverSalutation 			= a.PC_Caregiver_Salutation__c == null? PC_Constants.EMPTY_STRING : a.PC_Caregiver_Salutation__c;
            caregiverRelation 				= a.PC_Caregiver_Relationship_to_Patient__c == null? PC_Constants.EMPTY_STRING : a.PC_Caregiver_Relationship_to_Patient__c;
            caregiverFirstName 				= a.PC_Caregiver_First_Name__c == null? PC_Constants.EMPTY_STRING : a.PC_Caregiver_First_Name__c;
            caregiverLastName 				= a.PC_Caregiver_Last_Name__c == null? PC_Constants.EMPTY_STRING : a.PC_Caregiver_Last_Name__c;
            dob 							= a.PC_Date_of_Birth__c;
            gender 							= a.PC_Gender__c == null? PC_Constants.EMPTY_STRING : a.PC_Gender__c;
            lastModifiedDate 				= a.LastModifiedDate;
            fsFields = new Map<String, Object>();
            Object fsFieldVal;
            String fieldNameOfApplicant;
            for ( String fieldName : fsListMap.keySet() ){
                system.debug(fsListMap.get(fieldName));
                fieldNameOfApplicant = fsListMap.get(fieldName);
                try {
                    fsFieldVal = PC_FieldSetController.castFieldValueBasedOnType(fieldName, a.get(fieldNameOfApplicant), a);
                }
                catch(Exception e) {
                    fsFieldVal = PC_Constants.EMPTY_STRING;
                }
                fsFields.put(fieldName, fsFieldVal);
            }
        }
        public AccountRecord(PC_Applicant__c a, List<String> fsList) {
            Id 								= null;
            applicantId						= a.Id;
            firstName 						= a.PC_First_Name__c == null? PC_Constants.EMPTY_STRING : a.PC_First_Name__c;
            lastName 						= a.PC_Last_Name__c  == null? PC_Constants.EMPTY_STRING :  a.PC_Last_Name__c;
            salutation 						= a.PC_Salutation__c == null? PC_Constants.EMPTY_STRING : a.PC_Salutation__c;
            email 							= a.PC_Patient_Email__c == null? PC_Constants.EMPTY_STRING : a.PC_Patient_Email__c;
            phone 							= a.PC_Phone__c == null? PC_Constants.EMPTY_STRING : a.PC_Phone__c;
            fax 							= PC_Constants.EMPTY_STRING;
            name 							= PC_Constants.EMPTY_STRING;
            communicationLanguage 			= a.PC_Communication__c == null? PC_Constants.EMPTY_STRING : a.PC_Communication__c;
            preferredCommunicationChannel	= a.PC_Preferred_Channel__c == null? PC_Constants.EMPTY_STRING : a.PC_Preferred_Channel__c;
            status							= PC_Constants.EMPTY_STRING;
            caregiverSalutation 			= a.PC_Caregiver_Salutation__c == null? PC_Constants.EMPTY_STRING : a.PC_Caregiver_Salutation__c;
            caregiverRelation 				= a.PC_Caregiver_Relationship_to_Patient__c == null? PC_Constants.EMPTY_STRING : a.PC_Caregiver_Relationship_to_Patient__c;
            caregiverFirstName 				= a.PC_Caregiver_First_Name__c == null? PC_Constants.EMPTY_STRING : a.PC_Caregiver_First_Name__c;
            caregiverLastName 				= a.PC_Caregiver_Last_Name__c == null? PC_Constants.EMPTY_STRING : a.PC_Caregiver_Last_Name__c;
            dob 							= a.PC_Date_of_Birth__c;
            gender 							= a.PC_Gender__c == null? PC_Constants.EMPTY_STRING : a.PC_Gender__c;
            lastModifiedDate 				= a.LastModifiedDate;
            fsFields = new Map<String, Object>();
            Object fsFieldVal;
            for(String fieldName : fsList) {
                try {
                    fsFieldVal = PC_FieldSetController.castFieldValueBasedOnType(fieldName, a.get(fieldName), a);
                }
                catch(Exception e) {
                    fsFieldVal = PC_Constants.EMPTY_STRING;
                }
                fsFields.put(fieldName, fsFieldVal);
            }
        }
    }

    public inherited sharing class FieldLabels {
        //Address Fields
        @AuraEnabled public String account { get; set; }
        @AuraEnabled public String address { get; set; }
        @AuraEnabled public String address1 { get; set; }
        @AuraEnabled public String address2 { get; set; }
        @AuraEnabled public String address3 { get; set; }
        @AuraEnabled public String addressType { get; set; }
        @AuraEnabled public String city { get; set; }
        @AuraEnabled public String country { get; set; }
        @AuraEnabled public String state { get; set; }
        @AuraEnabled public String addrstatus { get; set; }
        @AuraEnabled public String zipCode { get; set; }
        @AuraEnabled public String primary { get; set; }
        @AuraEnabled public String addrlastModifiedDate { get; set; }
        @AuraEnabled public String source { get; set; }
        @AuraEnabled public String flag { get; set; }
        @AuraEnabled public String dataChk { get; set; }
        //Account Fields
        @AuraEnabled public String firstName { get; set; }
        @AuraEnabled public String lastName { get; set; }
        @AuraEnabled public String salutation { get; set; }
        @AuraEnabled public String email { get; set; }
        @AuraEnabled public String phone { get; set; }
        @AuraEnabled public String fax { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String communicationLanguage { get; set; }
        @AuraEnabled public String preferredCommunicationChannel { get; set; }
        @AuraEnabled public String accstatus { get; set; }
        @AuraEnabled public String caregiverSalutation { get; set; }
        @AuraEnabled public String caregiverRelation { get; set; }
        @AuraEnabled public String caregiverFirstName { get; set; }
        @AuraEnabled public String caregiverLastName { get; set; }
        @AuraEnabled public String dob { get; set; }
        @AuraEnabled public String gender { get; set; }
        @AuraEnabled public String acclastModifiedDate { get; set; }

        @AuraEnabled public String picklistNone { get; set; }

        public FieldLabels() {
        }
    }

    @AuraEnabled
    public static List<PC_FieldSetController.FieldSetMember> getFieldSetFields(String typeName, String fsName) {
        return PC_FieldSetController.getFields(typeName, fsName);
    }

    @AuraEnabled
    public static Map<String, List<PC_PicklistFieldManager.PicklistEntryWrapper>> getDependentOptionsImpl(){
        return PC_PicklistFieldManager.picklistFieldMap(PC_Address__c.PC_Country__c, PC_Address__c.PC_State__c);
    }

    @AuraEnabled
    public static String getPickListValueNone(){
        return PC_Constants.PICKLIST_NONE;
    }
}