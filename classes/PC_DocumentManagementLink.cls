/*********************************************************************************
Class Name      : PC_DocumentManagementLink
Description     : Controller class used for PC_Document_Management_Link (lightning)
Created By      : Deloitte
Created Date    : October 16, 2019
Modification Log:
----------------------------------------------------------------------------------
Developer              Date                   Description
-----------------------------------------------------------------------------------
Kishore Kanteti      October 04, 2019         [PC-5517] Initial Version(Picked it from PC_DocumentManagementLightningController)
Kishore Kanteti 	 October 16,2019		  [PC-5517] Optimised methods at field level to increase performance.
Shishir Bansal        Dec-06-2019            [PC-5792] Avoid hardcoding of string variable
Kishore Kanteti      Dec -11-2019            [PC-5795] Reduced the parameters in searchForPatient Method.
Haritha Reddy        Dec 13, 2019            [PC-5791] Added Error handling for methods where it was missing
Hitha Avalakki       Jan 27, 2020            [PC-5911] Added code to fetch Person Accounts and Business Accounts only ikf they have program cases associated in order to searched in Document Link
Chetna Mohapatra     Feb 17, 2020            [PC-5989] Commented the part that creates error logs in the catch block of searchForPatient method for document linking.
Haritha Reddy           21-Jan-2021          [PC-7102] Added FLS Check
Haritha Reddy          21-Jan-2021           [PC-7102] Force Reviewer scan issue fix. Updated Sharing declaration.
*********************************************************************************/
public with sharing class PC_DocumentManagementLink {

    private static List<RecordType> recTypeLabels = PC_SYSTEM.getAllRecordType(PC_Constants.PC_ACCOUNT);
    private static String recTypeLabel;

    /*********************************************************************************
    Method Name    : getDocRecord
    Description    : This method retrieve init data from the database.
    Return Type    : DocumentWrapper
    Parameter      : Id docId, Boolean bChangeDocOwnerToCurrentUser
    *********************************************************************************/
    @AuraEnabled
    public static DocumentWrapper getDocRecord(Id docId) {
        DocumentWrapper docWrapper = new DocumentWrapper();
        /*
         * FLS, additional fields to capture engagement program and manufacturer of the document
         * and contructor for docFieldWrapper updated for [PC-1598]
         */
        if (String.isBlank(docId)) return docWrapper;

        try {
            //Create a list of fields to check if user has field level security on PC_Document__c fields
            List<String> fields = new List<String>{
                    'Name', PC_Constants.getQualifiedAPIName('PC_Engagement_Program__c'), PC_Constants.getQualifiedAPIName('PC_EngagementProgramCode__c')
            };
            //Check if user has access to perform the READ operation
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Document__c'), PC_Database.Operation.Reading, fields);

            /*
            * FLS Check for PC_Engagement_Program__c
            */
            List<String> engagementProgFields = new List<String>{'Name', PC_Constants.getQualifiedAPIName('PC_Manufacturer__c')};
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Engagement_Program__c'), PC_Database.Operation.Reading, engagementProgFields);

            PC_Document__c oDoc = [
                    SELECT Id, Name,PC_Engagement_Program__c, PC_EngagementProgramCode__c,
                            PC_Engagement_Program__r.Name,PC_Engagement_Program__r.PC_Manufacturer__c
                    FROM PC_Document__c
                    WHERE Id = :docId
                    LIMIT 1
            ];


            if (oDoc != Null) {
                docWrapper.document = oDoc;
                docWrapper.docManufacturerId = oDoc.PC_Engagement_Program__r.PC_Manufacturer__c;
                docWrapper.docEngagementProgId = oDoc.PC_Engagement_Program__c;
            }


        } catch (Exception e) {
            PC_Utility.logAndThrowException(e);
        }
        return docWrapper;
    }


    /*********************************************************************************
    Method Name    : accountRecordTypes
    Author         : Ajinkya Deshmukh
    Description    : This method returns the account RT as a picklist
    Return Type    : List<RecordType>
    Parameter      :
    User Story     : PC-4763
    *********************************************************************************/
    @AuraEnabled
    public static List<RecordType> accountRecordTypes() {
        List<RecordType> validRecordTypeList = new List<RecordType>();
        try {
            //Fetch active 'Document Link Related Objects Setting' custom metadata records
            List <PC_Document_Link_Related_Object_Setting__mdt> activeDocLinkCustomMetadataRecList = PC_System.getActiveDocumentLinkCustomMetadataRecs();

            //Prepare a set of Account record type names from the above list
            Set<String> recordTypeDevNameSet = new Set<String>();
            for (PC_Document_Link_Related_Object_Setting__mdt activeDocLinkCustomMetadataRec : activeDocLinkCustomMetadataRecList) {
                recordTypeDevNameSet.add(activeDocLinkCustomMetadataRec.PC_Account_Record_Type__c);
            }

            //Fetch record type details from Account object as per the Set created above
            List<RecordType> recordTypeList = PC_SYSTEM.getSpecificAccountRecordTypeDetails(recordTypeDevNameSet);

            /* PC-5415: Match the namespaceprefix of the record types to the account record type namespace defined in the custom metadata record. This
        is required if there is a custom record type defined in the managed package org, and the org has a namespace defined.*/
            for (PC_Document_Link_Related_Object_Setting__mdt docLinkObject : activeDocLinkCustomMetadataRecList) {

                for (RecordType recordType : recordTypeList) {

                    if (!validRecordTypeList.contains(recordType)) {

                        if (recordType.DeveloperName.equals(docLinkObject.PC_Account_Record_Type__c)) {

                            if (docLinkObject.PC_Account_Record_Type_Namespace_Prefix__c == null && recordType.NamespacePrefix == null) {

                                validRecordTypeList.add(recordType);

                            } else if (docLinkObject.PC_Account_Record_Type_Namespace_Prefix__c == '' && recordType.NamespacePrefix == '') {

                                validRecordTypeList.add(recordType);

                            } else if (!String.isBlank(recordType.NamespacePrefix) && !String.isBlank(docLinkObject.PC_Account_Record_Type_Namespace_Prefix__c)
                                    && recordType.NamespacePrefix.toLowerCase().equals(docLinkObject.PC_Account_Record_Type_Namespace_Prefix__c.toLowerCase())) {

                                validRecordTypeList.add(recordType);
                            }
                        }
                    }
                }
            }
        } catch (Exception e) {
            PC_Utility.logAndThrowException(e);
        }

        return validRecordTypeList;
    }

    /*********************************************************************************
    Method Name    : getRecordTypeForAccount
    Author         : Ajinkya Deshmukh
    Description    : This method returns the account RT as string
    Return Type    : String recordType
    Parameter      : String accountId
    *********************************************************************************/
    @AuraEnabled
    public static String getRecordTypeForAccount(String accountId) {
        String recordType;
        try {
            List<Account> aAccount = [SELECT Id, RecordType.Name FROM Account WHERE Id = :accountId];
            if (aAccount.size() > 0) {
                recordType = aAccount[0].RecordType.Name;
            }
        } catch (Exception e) {
            PC_Utility.logAndThrowException(e);
        }
        return recordType;
    }


    /*********************************************************************************
    Method Name    : searchPatient
    Author         : Alina Balan
    Description    : Searches for the Patient records
    Return Type    : List<PatParticWrapper>
    Parameter      : String searchString
    *********************************************************************************/
    @AuraEnabled
    public static List<PatParticWrapper> searchForPatient(Map<String,String> patSearchDetails) {
        List<PatParticWrapper> sObjctWrapper = new List<PatParticWrapper> ();
        String masterPatient = PC_SYSTEM.getPatientConnectSetting(PC_Constants.PC_MASTER_PATIENT,'false').toLowerCase();
        try {
            String p_searchString = '';
            p_searchString = patSearchDetails.get('p_searchString');
            String p_recordTypeName = '';
            p_recordTypeName = patSearchDetails.get('p_recordTypeName');
            String docManufacturer = '';
            if(masterPatient == 'false'){
                docManufacturer = patSearchDetails.get('docManufacturer');
            }
            String docEngagementProg = '';
            if(masterPatient == 'false'){
                docEngagementProg = patSearchDetails.get('docEngagementProg');
            }
            String allRecordTypeList = '';
            allRecordTypeList = patSearchDetails.get('allRecordTypeList');

            List<Account> lstManuAccounts = new List<Account>();
            Map<ID,Account> mapPatients = new Map<ID,Account>();
            List<Case> casesofEngagementProgForAcc = new List<Case>();
            Map<ID,List<Case>> patientCases = new Map<ID,List<Case>>();
            List<Account> lstAccounts = new List<Account>();

            //check if the searched string is a valid date
            String originalSearchString = p_searchString;
            String searchString;
            searchString = '\'%' + String.escapeSingleQuotes(p_searchString) + '%\'';
            String soslSearchString = '{*' + String.escapeSingleQuotes(p_searchString) + '*}';
            DateTime searchDateTime;
            DateTime searchDate;
            String formatedDt;
            try {
                searchDateTime = DateTime.valueOf(originalSearchString);
            } catch (Exception e) {
               // PC_Utility.createExceptionLog(e);
            }
            try {
                searchDate = DateTime.valueOf(originalSearchString);
            } catch (Exception e) {
              //  PC_Utility.createExceptionLog(e);
            }

            if (searchDateTime != null) {
                formatedDt = searchDate.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
            }
            if (searchDate != null) {
                formatedDt = searchDate.format('yyyy-MM-dd');
            }

            /*
        * FLS Check for Account
        */
            List<String> fields = new List<String>{
                    'Name', PC_Constants.getQualifiedAPIName('PC_NPI__c'), PC_Constants.getQualifiedAPIName('PC_Status__c'),
                    PC_Constants.getQualifiedAPIName('PC_Primary_Address_1__c'), PC_Constants.getQualifiedAPIName('PC_Primary_Zip_Code__c'),
                    PC_Constants.getQualifiedAPIName('PC_Date_of_Birth__c'), PC_Constants.getQualifiedAPIName('PC_Primary_State__c'),
                    PC_Constants.getQualifiedAPIName('PC_Primary_City__c')
            };
            PC_Database.assertAccess('Account', PC_Database.Operation.Reading, fields);

            String sQuery = 'SELECT ID,Name,RecordType.Name,RecordType.DeveloperName,'
                    + PC_Constants.getQualifiedAPIName('PC_NPI__c') + ','
                    + PC_Constants.getQualifiedAPIName('PC_Status__c') + ','
                    + PC_Constants.getQualifiedAPIName('PC_Primary_Address_1__c') + ','
                    + PC_Constants.getQualifiedAPIName('PC_Primary_Zip_Code__c') + ','
                    + PC_Constants.getQualifiedAPIName('PC_Date_of_Birth__c') + ','
                    + PC_Constants.getQualifiedAPIName('PC_Primary_State__c') + ','
                    + PC_Constants.getQualifiedAPIName('PC_Primary_City__c')
                    + ' FROM Account';


            String sWhereClause = PC_Constants.EMPTY_STRING;
            List<Schema.FieldSetMember> lstFieldSetMembers = readFieldSet(PC_Constants.SEARCH_PATIENT_FIELDSET_OBJECT, PC_Constants.PATIENT_OBJECT);
            sQuery += ' WHERE ';
            if (p_recordTypeName != PC_Constants.PC_ALL) {
                sQuery += 'RecordType.DeveloperName =\'' + p_recordTypeName + '\'';
                sQuery += ' AND ';
            }

            if (lstFieldSetMembers.size() > 0) {
                sQuery += '(';
            }
            for (Schema.FieldSetMember fieldSetMember : lstFieldSetMembers) {
                system.debug('get type:' + fieldSetMember.getType());
                //check if the field is date or date/time
                if ((fieldSetMember.getType() == Schema.DisplayType.Date || fieldSetMember.getType() == Schema.DisplayType.DateTime) && !String.isBlank(formatedDt)) {
                    if (!String.isBlank(sWhereClause)) {
                        sWhereClause += ' OR ';
                    }
                    sWhereClause += fieldSetMember.getFieldPath() + ' = ' + formatedDt;
                    fields.add(fieldSetMember.getFieldPath());//Updated by mapatil to enforce CRUD/FLS
                } else if (fieldSetMember.getType() != Schema.DisplayType.Date && fieldSetMember.getType() != Schema.DisplayType.DateTime) {
                    if (!String.isBlank(sWhereClause)) {
                        sWhereClause += ' OR ';
                    }
                    sWhereClause += fieldSetMember.getFieldPath() + ' LIKE ' + searchString;
                    fields.add(fieldSetMember.getFieldPath());//Updated by mapatil to enforce CRUD/FLS
                }
            }
            if (!String.isBlank(sWhereClause)) {
                sQuery += sWhereClause + ')';
            }

            string accountType = PC_Constants.EMPTY_STRING;
            /*
         * [PC-1598]
         * Added logic to search records for the manufacturer that the Document is tagged with, if the tagging exists
		 */
            /*if(p_recordTypeName != 'All' && (docManufacturer=='' || docManufacturer == null)) {
            accountType = ' WHERE RecordType.DeveloperName =\'' + p_recordTypeName + '\'';
        } else if(p_recordTypeName != 'All' && docManufacturer!='' && docManufacturer!=null) {
            accountType = ' WHERE RecordType.DeveloperName =\'' + p_recordTypeName + '\' and ParentId =\'' + docManufacturer + '\'';
        }else if (p_recordTypeName == 'All' && docManufacturer!='' && docManufacturer!=null ) {
            accountType = ' WHERE ParentId =\'' + docManufacturer + '\'';
        }*/

            /*
        * [PC-3082]
        * Modified logic to search Patient records for the manufacturer that the Document is tagged with, if the tagging exists.
        * All non patient records based on query string should appear regardless of manufacturer that the Document is tagged with.
        * In case of no manufacturer all Patient and non patient records should appear based on query string.
         */
            //Build Where clause for Filtering Accounts of only configured record Types.
            List<String> recordTypesList = new List<String>();
            String recordTypeFilterCondition = PC_Constants.EMPTY_STRING;
            recordTypesList = allRecordTypeList.split(',');
            for (String recordType : recordTypesList) {
                recordTypeFilterCondition = recordTypeFilterCondition + ' RecordType.DeveloperName =\'' + recordType + '\' or';
            }
            recordTypeFilterCondition = recordTypeFilterCondition.removeEndIgnoreCase(' or');
            if (p_recordTypeName != PC_Constants.PC_ALL && (String.isBlank(docManufacturer) || docManufacturer == null)) {
                accountType = ' WHERE RecordType.DeveloperName =\'' + p_recordTypeName + '\'';
            } else if (p_recordTypeName != PC_Constants.PC_ALL && !String.isBlank(docManufacturer) && docManufacturer != null
                    && p_recordTypeName == PC_Constants.PATIENT_RECORD_TYPE) {
                accountType = ' WHERE RecordType.DeveloperName =\'' + p_recordTypeName + '\' and  (ParentId =\'' + docManufacturer + '\'' + +'OR PC_ParentManufacturer__c =\'' + docManufacturer + '\')';
            } else if (p_recordTypeName != PC_Constants.PC_ALL && !String.isBlank(docManufacturer) && docManufacturer != null) {
                accountType = ' WHERE RecordType.DeveloperName =\'' + p_recordTypeName + '\'';
            } else if (p_recordTypeName == PC_Constants.PC_ALL && !String.isBlank(docManufacturer) && docManufacturer != null) {
                accountType = ' WHERE  ((NOT RecordType.DeveloperName like \'' + PC_Constants.PATIENT_RECORD_TYPE + '\') ' +
                        'or ParentId =\'' + docManufacturer + '\' ' + 'or PC_ParentManufacturer__c =\'' + docManufacturer + '\')';
                if (recordTypeFilterCondition != '') {
                    accountType = accountType + ' and (' + recordTypeFilterCondition + ')';
                }
            } else if (p_recordTypeName == PC_Constants.PC_ALL && (String.isBlank(docManufacturer) || docManufacturer == null)) {
                if (recordTypeFilterCondition != '') {
                    accountType = ' WHERE ' + recordTypeFilterCondition;
                }
            }
            String soslQuery = 'FIND ' + soslSearchString + ' IN ALL FIELDS RETURNING Account'
                    + '(ID,Name,Type,RecordType.Name,RecordType.DeveloperName,'
                    + PC_Constants.getQualifiedAPIName('PC_NPI__c') + ','
                    + PC_Constants.getQualifiedAPIName('PC_Status__c') + ','
                    + PC_Constants.getQualifiedAPIName('PC_Primary_Address_1__c') + ','
                    + PC_Constants.getQualifiedAPIName('PC_Primary_Zip_Code__c') + ','
                    + PC_Constants.getQualifiedAPIName('PC_Date_of_Birth__c') + ','
                    + PC_Constants.getQualifiedAPIName('PC_Primary_State__c') + ','
                    + PC_Constants.getQualifiedAPIName('PC_Primary_City__c')
                    + accountType
                    + ' )';

            sQuery += ' LIMIT 1000';

            try {
                //Updated to check FLS on Account fields
                fields = new List<String>{
                        'Name', PC_Constants.getQualifiedAPIName('PC_Date_of_Birth__c')
                };
                PC_Database.assertAccess('Account', PC_Database.Operation.Reading, fields);
                List<List<sObject>> soslResults = search.query(soslQuery);
                lstManuAccounts = soslResults[0]; //PC-1598 Get all accounts for the Manufacturer
            } catch (Exception ex) {
                PC_Utility.logAndThrowException(ex);
            }
            Set<Id> pIdSet = new Set<Id>();
            List<Id> pIdList = new List<Id>();

            if (!lstManuAccounts.isEmpty() && !String.isBlank(docEngagementProg) && docEngagementProg != null) {
                for (Account account : lstManuAccounts) {
                    if (account.Type == PC_Constants.PATIENT_ACCOUNT_TYPE_VALUE) {
                        pIdSet.add(account.Id);
                        mapPatients.put(account.Id,account);
                    } else {
                        lstAccounts.add(account);
                    }
                }
                if(!pIdSet.isEmpty()){
                    pIdList.addAll(pIdSet);
                    patientCases = PC_DocumentManagementHelper.getProgramRecords(pIdList,docEngagementProg);
                    for(Id pId : patientCases.keySet()){
                        lstAccounts.add(mapPatients.get(pId));
                    }
                }
            } else {
                for (Account account : lstManuAccounts) {
                    lstAccounts.add(account);
                }
            }
            for (Account account : lstAccounts) {
                for (RecordType rec : recTypeLabels) {
                    if (rec.DeveloperName == account.RecordType.DeveloperName) {
                        recTypeLabel = rec.Name;
                    }
                }
                PatParticWrapper wrprObj = new PatParticWrapper(null, false);
                wrprObj.sPatientName = account.Name;
                wrprObj.sPatientBirthDate = String.valueOf(account.PC_Date_of_Birth__c);
                wrprObj.sPatientId = String.valueOf(account.Id);
                wrprObj.sAccountType = account.RecordType.Name;
                wrprObj.sAccountTypeLabel = recTypeLabel;
                wrprObj.sPhysicianNPI = account.PC_NPI__c;
                wrprObj.sAccStatus = account.PC_Status__c;
                wrprObj.sAccAddr = account.PC_Primary_Address_1__c;
                wrprObj.sAccCity = account.PC_Primary_City__c;
                wrprObj.sAccState = account.PC_Primary_State__c;
                wrprObj.sAccZipCode = account.PC_Primary_Zip_Code__c;

                sObjctWrapper.add(wrprObj);
            }
        } catch (Exception e) {
            PC_Utility.logAndThrowException(e);
        }
        return sObjctWrapper;
    }

    /*********************************************************************************
    Method Name    : readFieldSet
    Author         : Alina Balan
    Description    : Get all fields from a field set
    Return Type    : List<Schema.FieldSetMember>
    Parameter      : String fieldSetName, String ObjectName
    *********************************************************************************/
    public static List<Schema.FieldSetMember> readFieldSet(String fieldSetName, String ObjectName) {
        Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe();
        Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get(ObjectName);
        Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();
        Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(fieldSetName);
        return fieldSetObj.getFields();
    }

    /*********************************************************************************
    Class Name    : PatParticWrapper
    Author        : Alina Balan
    Description   : Wrapper class for patients
    *********************************************************************************/
    public inherited sharing class PatParticWrapper {
        @AuraEnabled public sObject objct { get; set; }
        @AuraEnabled public Boolean bIsChecked { get; set; }
        @AuraEnabled public String sPatientId { get; set; }
        @AuraEnabled public String sPatientName { get; set; }
        @AuraEnabled public String sPatientBirthDate { get; set; }
        @AuraEnabled public String sAccountType { get; set; }
        @AuraEnabled public String sAccountTypeLabel { get; set; }
        @AuraEnabled public String sPhysicianNPI { get; set; }
        @AuraEnabled public String sAccStatus { get; set; }
        @AuraEnabled public String sAccAddr { get; set; }
        @AuraEnabled public String sAccCity { get; set; }
        @AuraEnabled public String sAccState { get; set; }
        @AuraEnabled public String sAccZipCode { get; set; }

        @AuraEnabled public String onFocus {
            get {
                return 'LookupHoverDetail.getHover(\'' + sPatientId + '\', \'/' + sPatientId + '/m?retURL=%2F' + sPatientId + '&isAjaxRequest=1).show();';
            }
        }
        public PatParticWrapper(sObject pat, Boolean bisChkd) {
            objct = pat;
            bIsChecked = bisChkd;
            sAccountType = 'default';
        }
    }

    public inherited sharing class DocumentWrapper {
        @AuraEnabled public PC_Document__c document { get; set; }
        @AuraEnabled public String docManufacturerId { get; set; }
        @AuraEnabled public String docEngagementProgId { get; set; }

        public DocumentWrapper() {

        }
    }


}