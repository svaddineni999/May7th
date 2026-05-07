/**
 * Class Name      : PC_Enrollment_PatientLookup_Controller
 * Created By      : Mayuresh Patil
 * @Created Date   : Feb 06, 2017
 * Modification Log:
 * ----------------------------------------------------------------------------------
 * Developer              Date                   	Description
 * -----------------------------------------------------------------------------------
 * Mayuresh Patil		  06-February-2017			Initial Version
 * Prachi Nandgaonkar     15-March-2017             [PC-1308] Added document record type field to the Doc Details wrapper for handling online form 
 * Prachi Nandgaonkar     16-March-2017             [PC-1306] Added an additional condition to SOSL in getPatients()to check if Applicant's Enrollment Case exists
 *                                                  to filter out applicants purely created due to online form submission 
 * Prachi Nandgaonkar     17-March-2017             [PC-1323] Added onlineApplicantID field to docDetails wrapper and updated getDocDetails() to handle online form
 * Prachi Nandgaonkar     26-March-2017             [PC-1509] Updated getPatients() to filter for active applicants
 * Ajinkya Deshmukh		  21-June-2017				FLS Check Added (Code Merge)
 * Shabda Bhujad 		  26-June-2017 				Added the logic to look up case based on Type instead of Record Type [PC-1701]
 * Mayuresh Patil         07-Sep-2017               PC-2193 FLS Check updated to new PC303 code
 * Hitha Avalakki         05-Dec-2018               PC-3243 Logic added to configure fieldset components for search and display criteria on
 *                                                  Pre-Enrollment wizard screen.
 * Tejas Patel           15-Dec-2018                PC-3902 Bug Fixes
 * Tejas Patel           22-Jan-2019                PC-4211 Bug Fix, created a new method to curate the SOSL records.
 * Haritha Reddy         08-Feb-2019               [PC-4261] Code improvement by adding dynamically adding filter criteria to where clause of SOSL Query.
 * Tejas Patel			  25-Feb-2019               PC-4479 getExistingCase() method upadted
 * Haritha Reddy		 08-Mar-2019               [PC-4516] Bug Fix - Added Error Handling for empty Applicant in Document
 * Tejas Patel           15-Apr-2019                [PC-4737] Remiving Applicant dependancy
 * Chetna Mohapatra     03-Apr-2020                [PC-6125]The fsFieldVal object will now be sourcing the field value from castFieldValueAsString method.
 * Chetna Mohapatra     15-June-2020               [PC-6152]Added the logic for fieldset error handling in getFieldSetName() and getDisplayFieldSetFields().
 * Chetna Mohapatra     13-July-2020               [PC-6480] The fsFieldVal in getFSValues method will source it value based on castFieldValueBasedOnType method
 * Satheesh Kumar       29-Sep-2020                [PC-6828] Bug Fix - Enrollment Search issue
 * Satheesh Kumar       29-Sep-2020                [PC-6830] Fix for data missing in Enrollment Case Exists Popup issue
 * Satheesh Kumar       05-Feb-2021                [PC-7358] Added logic to escape SOSL Reserved Keywords in the search String
 * Hitha Avalakki       19-Mar-2021                [PC-7533] Replaced constant CASE_PROGRAM_RECORD_TYPE_NAME to CASE_PROGRAM_TYPE
 * Vijay Kashikar       21-Jun-2021                [PC-7782] Avoided coversion of Double to scientific notation while searching.
 * Tejas Patel          20-Sept-2022               [PC-9192] Removed sorting on Account Name field and moved the sorting to JS.
 * */


public with sharing class PC_Enrollment_PatientLookup_Controller {
    //Author:Hitha: Below two variables have been added as a part of PC-3243
    public static Map<String,String> accountApplicantFieldsMapping=new Map<String, String>();
    public static Map<String,String> accntToApplntFieldNameMappingForDisplayFields=new Map<String, String>();

    /**
     * Method to get document details and engagement program list. 
     */ 
    @AuraEnabled
    public static DocWrapper getDocDetails(String docId) {
        DocWrapper docDetailsWrapper = new DocWrapper();
        String engagementProgramCode = 'NULL';
        
        try {
            if(!String.isBlank(docId)) {
                List<String> docFields = new List<String> {'Name',PC_Constants.getQualifiedAPIName('PC_Document_Category__c'),PC_Constants.getQualifiedAPIName('PC_Engagement_Program__c'), PC_Constants.getQualifiedAPIName('PC_Applicant__c')};
                PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Document__c'), PC_Database.Operation.Reading, docFields);
                List<String> engProgramFields = new List<String> {'Name',PC_Constants.getQualifiedAPIName('PC_Manufacturer__c')};
                PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Engagement_Program__c'), PC_Database.Operation.Reading, engProgramFields);
                List<String> applicantFields = new List<String> {PC_Constants.getQualifiedAPIName('PC_First_Name__c'),PC_Constants.getQualifiedAPIName('PC_Last_Name__c'),PC_Constants.getQualifiedAPIName('PC_Date_of_Birth__c')};
                PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Applicant__c'), PC_Database.Operation.Reading, applicantFields);

                List<PC_Document__c> doc = [SELECT Id, Name, RecordType.Name, PC_Document_Category__c, PC_Engagement_Program__c, 
                                      PC_Engagement_Program__r.Name, PC_Engagement_Program__r.PC_Program_Code__c, PC_Engagement_Program__r.PC_Manufacturer__c, PC_Applicant__c,
                                      PC_Applicant__r.PC_First_Name__c,PC_Applicant__r.PC_Last_Name__c, PC_Applicant__r.PC_Date_of_Birth__c
                                      FROM PC_Document__c
                                      WHERE Id=:docId LIMIT 1];

                if (doc.size() > 0 && doc[0].PC_Applicant__c != null) {
                    List<String> fsList = new List<String>();
                    if(doc[0].PC_Engagement_Program__r.PC_Program_Code__c != null){
                        engagementProgramCode   = doc[0].PC_Engagement_Program__r.PC_Program_Code__c;
                    }

                    String fieldSetName = getFieldSetName(engagementProgramCode);
                    if(String.isNotBlank(fieldSetName)) {
                        fsList = PC_FieldSetController.getFieldsByName(PC_Constants.PC_ACCOUNT, fieldSetName);
                }

                Map<String,String> accountAppFieldNamesMapping=new Map<String, String>();
                accountAppFieldNamesMapping=PC_Utility.AccountToApplicantMapping(fsList);
                List<String> appFieldSetNamesList=new List<String>(accountAppFieldNamesMapping.values());

                String query = PC_Constants.EMPTY_STRING + String.join(appFieldSetNamesList, ', ');
                query = 'SELECT ' + query + ' ' + 'FROM ' +' PC_Applicant__c'+
                        ' WHERE Id' + '=' + '\'' + doc[0].PC_Applicant__c + '\'' + ' Limit 1';

                List<PC_Applicant__c> a = PC_Database.queryWithAccess(query, appFieldSetNamesList);

                    Map<String, Object> fsFields = new Map<String, Object>();
                    Object fsFieldVal;
                    for(String fieldName : fsList) {
                        String applicantFieldName;
                        try {
                            applicantFieldName=accountAppFieldNamesMapping.get(fieldName);
                            fsFieldVal = PC_FieldSetController.castFieldValueBasedOnType(applicantFieldName, a[0].get(applicantFieldName), a[0]);
                        }
                        catch(Exception e) {
                            fsFieldVal = '';
                        }
                        fsFields.put(fieldName, fsFieldVal);
                    }
                    docDetailsWrapper = new DocWrapper(doc[0]);
                    docDetailsWrapper.fsFields = fsFields;
                    docDetailsWrapper.lstEngagementProgram = getEngagementPrograms();
                }
                else if(doc.size() > 0 && doc[0].PC_Applicant__c == null){
                    docDetailsWrapper = new DocWrapper(doc[0]);
                    Map<String, Object> fsFieldsWithEmptyValMap = new Map<String, Object>();
                    if(doc[0].PC_Engagement_Program__r.PC_Program_Code__c != null){
                        engagementProgramCode   = doc[0].PC_Engagement_Program__r.PC_Program_Code__c;
                    }
                    fsFieldsWithEmptyValMap=initialiseFieldSetFieldsMap(new Account(), engagementProgramCode);
                    docDetailsWrapper.fsFields = fsFieldsWithEmptyValMap;
                    docDetailsWrapper.lstEngagementProgram = getEngagementPrograms();
                }
            }
            else{
                docDetailsWrapper = new DocWrapper();
                docDetailsWrapper.lstEngagementProgram = getEngagementPrograms();
                engagementProgramCode = docDetailsWrapper.lstEngagementProgram[0].engagementProgramCode;
                Map<String, Object> fsFieldsWithEmptyValMap = new Map<String, Object>();
                fsFieldsWithEmptyValMap=initialiseFieldSetFieldsMap(new Account(), engagementProgramCode); //To Do
                docDetailsWrapper.fsFields = fsFieldsWithEmptyValMap;

            }
        }catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);           
        }
        return docDetailsWrapper;
    }

    /**
     * Method to get document details and engagement program list.
     */
    @AuraEnabled
    public static DocWrapper getfsFieldsForEngagementProgram(String engagementProgramCode) {
        DocWrapper docDetailsWrapper = new DocWrapper();
        Map<String, Object> fsFieldsWithEmptyValMap = new Map<String, Object>();
        fsFieldsWithEmptyValMap=initialiseFieldSetFieldsMap(new Account(), engagementProgramCode); //To Do
        docDetailsWrapper.fsFields = fsFieldsWithEmptyValMap;
        return docDetailsWrapper;
    }
    
    /**
     * Method to get exisitng case for the patient or applicant. 
     */ 
    @AuraEnabled
    public static String getExistingCase(Id patientId, Id programId, String accountType) {
        String existingCaseId = null;
        try {
            if(patientId != null && programId != null && string.isnotBlank(accountType)) {
                //For Patient Accounts fetch existing enrollment or program case for the selected Patient Id
                if (accountType == PC_Constants.PC_ACCOUNT) {
                	/*
			        * FLS Check for Case
			        * PC-1701 - Changing the lookup to Type instead of Record type
			        */
			    	List<String> fields = new List<String>{'Id','AccountId','Type','Status',PC_Constants.getQualifiedAPIName('PC_Engagement_Program__c')};
			        PC_Database.assertAccess(PC_Constants.PC_CASE, PC_Database.Operation.Reading, fields);
                    List<String> closedCaseStatus = PC_Utility.getClosedCaseStatus();
                    List<Case> existingCase = [SELECT Id  FROM Case
                                               WHERE AccountId=:patientId AND PC_Engagement_Program__c =:programId 
                                               AND ((Type =: PC_Constants.CASE_ENROLLMENT_RECORD_TYPE_NAME 
                                                     	AND Status != :PC_Constants.COMPLETED
                                                    )
                                                    	OR (Type =: PC_Constants.CASE_PROGRAM_TYPE AND Status NOT in :closedCaseStatus))
                                               LIMIT 1];
                    if (existingCase.size() > 0) {
                        existingCaseId = existingCase[0].Id;
                    }
                }
                if (accountType == PC_Constants.PC_APPLICANT) {
                	/*
			        * FLS Check for PC_Applicant__c
			        */
			    	List<String> fields = new List<String>{PC_Constants.getQualifiedAPIName('PC_Enrollment_Case__c'),PC_Constants.getQualifiedAPIName('PC_Engagement_Program__c')};
			        PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Applicant__c'), PC_Database.Operation.Reading, fields);
                    fields = new List<String>{'Status',PC_Constants.getQualifiedAPIName('PC_Program__c')};
                    PC_Database.assertAccess(PC_Constants.PC_CASE, PC_Database.Operation.Reading, fields);
                    //Fetch applicant detail for the selected applicant Id
                    List<PC_Applicant__c> existingApplicant = [SELECT PC_Enrollment_Case__c, PC_Enrollment_Case__r.Status, PC_Enrollment_Case__r.PC_Program__c, PC_Engagement_Program__c  
                                                    FROM PC_Applicant__c
                                                    WHERE Id=:patientId 
                                                    LIMIT 1];                      
                    if (existingApplicant .size() > 0) {
                        //Check if the engagement Program matches the user selected engagement Program
                        if (existingApplicant[0].PC_Engagement_Program__c == programId) {
                            //Check if the enrollment case Status equals completed then return program case id
                            if (existingApplicant[0].PC_Enrollment_Case__r.Status == PC_Constants.COMPLETED) {
                                existingCaseId = existingApplicant[0].PC_Enrollment_Case__r.PC_Program__c;
                            }else {
                                //if enrollment case is not completed then return enrollment case id                                
                                 existingCaseId = existingApplicant[0].PC_Enrollment_Case__c;
                            }
                        }
                        //if engagement program doesnot matches then null case id is returned. 
                        //That means the existing applicant is for a differnt engagement program.  
                    }    
                }
            }
        }catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);           
        }        
        return existingCaseId;
    }

    
    @AuraEnabled
    public static LIST<EngProgramWrapper> getEngagementPrograms() {
        LIST<EngProgramWrapper> lstEngProgram = new LIST<EngProgramWrapper>(); 
        List<String> epFields = new List<String> {'Name',PC_Constants.getQualifiedAPIName('PC_Manufacturer__c'),PC_Constants.getQualifiedAPIName('PC_Active__c')};
        PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Engagement_Program__c'), PC_Database.Operation.Reading, epFields);
        List<String> accountFields = new List<String> {'Name'};
        PC_Database.assertAccess(PC_Constants.PC_ACCOUNT, PC_Database.Operation.Reading, accountFields);
        List<PC_Engagement_Program__c> lstEp = [SELECT Id, PC_Manufacturer__c, PC_Manufacturer__r.Name, Name, PC_Program_Code__c
                                                FROM PC_Engagement_Program__c
                                                WHERE PC_Active__c = true LIMIT 100];
        if(lstEp != null && lstEp.size() > 0) {
            for(PC_Engagement_Program__c a : lstEp) {  
                lstEngProgram.add(new EngProgramWrapper(a));
            }
        }        
        return lstEngProgram;
    }

    /*****************************************************************************************************
     * Author       : Hitha Avalakki
     * User Story   : PC-3243
     * Parameter    : String
     * Return Type  : AccountAppDetailsWrapper
     * Description  : Method to search patients and find matching accounts and applications.
     *****************************************************************************************************/
    @AuraEnabled
    public static AccountAppDetailsWrapper getPatients(String searchDetails) {
        SearchWrapper searchFields = new SearchWrapper();
        searchFields = (SearchWrapper) JSON.deserialize(searchDetails, SearchWrapper.class);
        LIST<PatientsWrapper> lstPatientWrapper = new LIST<PatientsWrapper>();
        AccountAppDetailsWrapper accAppDetailsWrapper=new AccountAppDetailsWrapper();
        List<List<String>> accountAppDetailsList=new List<List<String>>();
        Map<String, List<String>> childAccAppDetailsMap;
        Map<Id,Map<String,Object>> fsFieldsMaptoDisplay;
        Map<Id,AccountDetailsWrapper> mapOfPatientsWrapper=new Map<Id,AccountDetailsWrapper>();
        List<String> mandatoryApplicantFieldsList=new List<String>{PC_Constants.getQualifiedAPIName('PC_Engagement_Program__c'),
        PC_Constants.getQualifiedAPIName('PC_Enrollment_Case__r.Status') ,PC_Constants.getQualifiedAPIName('PC_Enrollment_Case__r.Owner.Name') ,PC_Constants.getQualifiedAPIName('PC_Enrollment_Case__c')};
        String masterPatient = searchFields.masterPatient;

        try {
            String searchString = PC_Constants.EMPTY_STRING;

            String manuId = searchFields.manufacturerId;
            String caseStatusComplete = PC_Constants.COMPLETED;
            String patientRecordType = PC_Constants.PATIENT_RECORD_TYPE;
            String pcApplicant = PC_Constants.CANDIDATE_PATIENT_OBJECT;

            /*** FLS Check for PC_Applicant__c ***/
            List<String> fields = new List<String>{
                    PC_Constants.getQualifiedAPIName('PC_Engagement_Program__c'), PC_Constants.getQualifiedAPIName('PC_Enrollment_Case__c')
            };
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Applicant__c'), PC_Database.Operation.Reading, fields);

            /*** FLS Check for Engagement Program ***/
            fields = new List<String>{
                    'Name', PC_Constants.getQualifiedAPIName('PC_Manufacturer__c')
            };
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Engagement_Program__c'), PC_Database.Operation.Reading, fields);

            /**** Get the search criteria field values entered on Pre-Enrollment Screen *****/
            Map<String, String> fsFieldsMapwithWhiteSpace = searchFields.fsFields;
            Map<String, String> fsFieldsMap = new Map<String, String>();
            for(String k : fsFieldsMapwithWhiteSpace.keySet()){
                if(fsFieldsMapwithWhiteSpace.get(k) == null){
                    fsFieldsMap.put(k,fsFieldsMapwithWhiteSpace.get(k));
                }else{
                    fsFieldsMap.put(k,fsFieldsMapwithWhiteSpace.get(k).trim());
                }
            }

            List<String> searchFieldNamesList=new List<String>(fsFieldsMap.keySet());

            accountApplicantFieldsMapping=PC_Utility.AccountToApplicantMapping(searchFieldNamesList);

            /************************************************************************************************************************
             * ConditionFieldDetailWrapper object holds the below maps:
             * 1) conditionFieldNamesMap     : The fields which are to be used in 'WHERE' clause of SOSL query.
             * 2) fieldNameFieldTypeMap      : The data types of all the fields to be used in 'WHERE' clause
             * 3) fieldSetValFormattedValMap : The fieldset's field values formatted as per their respective datatypes
             ************************************************************************************************************************/
            /*** For Account --- START ***/
            ConditionFieldDetailWrapper conditionFieldDetailWrapper=new ConditionFieldDetailWrapper();
            Map<String, String> whereClauseConditionFieldNameMap =new Map<String, String>();
            Map<String,Object> fsFieldValuesFormattedMap=new Map<String, Object>();
            Account accountObj=new Account();

            conditionFieldDetailWrapper=getWhereClauseCondFields(fsFieldsMap,accountObj);
            /*** Below is the map of fields which are to be used in 'WHERE' clause of SOSL query ***/
            whereClauseConditionFieldNameMap=conditionFieldDetailWrapper.conditionFieldNamesMap;
            /*** Below is the map of field set field values formatted as per their datatypes  ***/
            fsFieldValuesFormattedMap=conditionFieldDetailWrapper.fieldSetValFormattedValMap;
            /*** For Account --- END ***/

             /*** For Applicant --- START ***/
            ConditionFieldDetailWrapper conditionFieldDetailWrapperApplicant=new ConditionFieldDetailWrapper();
            Map<String, String> whereClauseConditionFieldNameAppMap =new Map<String, String>();
            Map<String,Object> fsFieldValuesFormattedAppMap=new Map<String, Object>();
            PC_Applicant__c applicantObj=new PC_Applicant__c();

            conditionFieldDetailWrapperApplicant=getWhereClauseCondFields(fsFieldsMap,applicantObj);
            whereClauseConditionFieldNameAppMap=conditionFieldDetailWrapperApplicant.conditionFieldNamesMap;
            fsFieldValuesFormattedAppMap=conditionFieldDetailWrapperApplicant.fieldSetValFormattedValMap;
            /*** For Applicant --- END ***/

            /*** Create a single string consisting of quoted text values separated by comma --- START ***/
            List<String> listOfFields = new List<String>();
            List<String> searchCritFieldSetFieldVal = new List<String>();

            for (String fieldName : fsFieldsMap.keySet()) {
                if ((whereClauseConditionFieldNameMap==null)||
                        (whereClauseConditionFieldNameMap != null && whereClauseConditionFieldNameMap.isEmpty())||
                        (whereClauseConditionFieldNameMap != null && !whereClauseConditionFieldNameMap.isEmpty() &&
                        !whereClauseConditionFieldNameMap.containsKey(fieldName))) {
                    if(!String.isEmpty(fsFieldsMap.get(fieldName))){
                        searchCritFieldSetFieldVal.add(fsFieldsMap.get(fieldName));
                    }
                }
            }

            if (searchCritFieldSetFieldVal != null & !searchCritFieldSetFieldVal.isEmpty()) {
                for (String val : searchCritFieldSetFieldVal) {
                    if (!val.equals(',') && !(String.isEmpty(val))) {
                        String escapedText = PC_Utility.escapeSoslSearchText(val);
                        String quotedVal = escapedText + '*';
                        listOfFields.add(quotedVal);
                    }
                }
            }

            searchString = '\'' + String.join(listOfFields, ' AND ') + '\'';
            /*** Create a single string consisting of quoted text values separated by comma --- END ***/

            String accountAppRecordSearchQuery = PC_Constants.EMPTY_STRING;
            FieldSetLabelsFieldPathWrapper fieldSetLabelsFieldPathWrapper = new FieldSetLabelsFieldPathWrapper();

            /***** Get the display fieldSet fields to display account and applicant information *****/
            fieldSetLabelsFieldPathWrapper = getDisplayFieldSetFields(searchFields.engagementProgramCode);
            List<String> listOfDisplayFieldSetMembrs = fieldSetLabelsFieldPathWrapper.fieldPathList;

            /* Following mapping is required since the result display section on UI has column labels of fields present in
            * 'PC_PreEnrollmentWizardDisplay' fieldset on Account object.
            * If one display field of Account is not having a corresponding field on Applicant then we would have to keep
            * the corresponding column as blank in the display results on the UI.*/
            accntToApplntFieldNameMappingForDisplayFields=PC_Utility.AccountToApplicantMapping(listOfDisplayFieldSetMembrs);

            List<String> listOfAppFieldNamesForDisplayFieldSetMembrs = accntToApplntFieldNameMappingForDisplayFields.values();

            String fsFieldVal;
            accAppDetailsWrapper.colLabelsList = fieldSetLabelsFieldPathWrapper.fieldSetLabelsList;

            /******** Creation of dynamic SOSL query string to fetch Account and Applicant records --- START *******/

            Map<string,string> accountEncryptedFieldMap = new Map<string,string>();
            Map<string,string> applicantEncryptedFieldMap = new Map<string,string>();
            if (listOfDisplayFieldSetMembrs != null && !listOfDisplayFieldSetMembrs.isEmpty()) {
                /******Get the filter Criteria and Map of Encrypted Fields and their corresponding search values --- START */
                String accountFilterCriteria,applicantFilterCriteria;
                FilterCriteriaEncryptedFieldsWrapper accountFilterMap = getFilterCriteriaAndEncryptedFields(fsFieldsMap,accountObj);
                accountFilterCriteria = accountFilterMap.filterCriteria;
                accountEncryptedFieldMap = accountFilterMap.encryptedFieldsAndValues;

                FilterCriteriaEncryptedFieldsWrapper applicantFilterMap = getFilterCriteriaAndEncryptedFields(fsFieldsMap,applicantObj);
                applicantFilterCriteria = applicantFilterMap.filterCriteria;
                applicantEncryptedFieldMap = applicantFilterMap.encryptedFieldsAndValues;
                /******Get the filter Criteria and Map of Encrypted Fields and their corresponding search values --- END */
                accountAppRecordSearchQuery = 'FIND ' + searchString + ' IN ALL FIELDS RETURNING Account(Id,';

                if (listOfDisplayFieldSetMembrs != null && !listOfDisplayFieldSetMembrs.isEmpty()) {
                    accountAppRecordSearchQuery = appendFieldSetMembersToQueryString(accountAppRecordSearchQuery, listOfDisplayFieldSetMembrs,whereClauseConditionFieldNameMap);
                }

                String patientWhereClause = ' WHERE RecordType.DeveloperName =:patientRecordType AND (ParentId =:manuId OR PC_ParentManufacturer__c =: manuId)';
                String applicantWhereClause = PC_Constants.getQualifiedAPIName('PC_Engagement_Program__r') + '.' + PC_Constants.getQualifiedAPIName('PC_Manufacturer__c') + ' =:manuId AND ';

                if(masterPatient.toLowerCase() == 'true'){
                    patientWhereClause = ' WHERE RecordType.DeveloperName =:patientRecordType';
                    applicantWhereClause = PC_Constants.EMPTY_STRING;
                }

                accountAppRecordSearchQuery = accountAppRecordSearchQuery + patientWhereClause + accountFilterCriteria +' LIMIT 100),' +
                        pcApplicant + '(Id,' +
                        PC_Constants.getQualifiedAPIName('PC_Engagement_Program__c') + ', ' +
                        PC_Constants.getQualifiedAPIName('PC_Enrollment_Case__r.Status') + ', ' +
                        PC_Constants.getQualifiedAPIName('PC_Enrollment_Case__r.Owner.Name') + ', ' +
                        PC_Constants.getQualifiedAPIName('PC_Enrollment_Case__c') + ', ';

                if (listOfAppFieldNamesForDisplayFieldSetMembrs != null && !listOfAppFieldNamesForDisplayFieldSetMembrs.isEmpty()) {
                    accountAppRecordSearchQuery = appendFieldSetMembersToQueryString(accountAppRecordSearchQuery, listOfAppFieldNamesForDisplayFieldSetMembrs,whereClauseConditionFieldNameAppMap);
                }

                accountAppRecordSearchQuery = accountAppRecordSearchQuery + ' WHERE ' +
                        applicantWhereClause +
                        PC_Constants.getQualifiedAPIName('PC_Enrollment_Case__r.Status') + ' !=:caseStatusComplete AND ' +
                        PC_Constants.getQualifiedAPIName('PC_Enrollment_Case__r.Id') + ' != null AND ' +
                        PC_Constants.getQualifiedAPIName('PC_Enrollment_Case__r.AccountId') + ' = null '+applicantFilterCriteria+' LIMIT 100)';
            }

            /********* Creation of dynamic SOSL query string to fetch Account and Applicant records --- END ********/

            /***** Fetch the list of Account and Applicant records using the dynamic SOSL query --- START *****/
            LIST<LIST <sObject>> lstPatients1 = search.query(accountAppRecordSearchQuery);
            //LIST<Account> lstAccount1 = ((List<Account>) lstPatients1[0]);
            //LIST<PC_Applicant__c> lstApplicant1 = ((List<PC_Applicant__c>) lstPatients1[1]);
            //LIST<Account> lstAccount1 = (LIST<Account>) recordCuration(lstPatients1[0], fsFieldsMap, false);
            //LIST<PC_Applicant__c> lstApplicant1 = (LIST<PC_Applicant__c>)recordCuration(lstPatients1[1],fsFieldsMap,true);
            LIST<Account> lstAccount1 = (LIST<Account>) recordCuration(lstPatients1[0], accountEncryptedFieldMap, false);
            LIST<PC_Applicant__c> lstApplicant1 = (LIST<PC_Applicant__c>)recordCuration(lstPatients1[1],applicantEncryptedFieldMap,true);
            /***** Fetch the list of Account and Applicant records using the dynamic SOSL query --- END *****/

            /*** Distinguish amongst the Applicant IDs fetched from above SOSL query which are active on any Case --- START ***/
            LIST<PC_Applicant__c> activeApplicants1 = [SELECT Id  FROM PC_Applicant__c
                                                       WHERE Id IN (
                                                            Select PC_ActiveApplicant__c
                                                            FROM Case
                                                            WHERE PC_ActiveApplicant__c IN :lstApplicant1)
                                                      ];

            Set<Id> activeApplicantIdSet = (new Map<Id, PC_Applicant__c>(activeApplicants1)).keySet();
            /*** Distinguish amongst the Applicant IDs fetched from above SOSL query which are active on any Case --- END ***/

            /***** Logic to form the map of Account/Applicant Id and display fieldset members' values --- START *****/
            Set<SObject> setOfSelectedAccounts=new Set<SObject>();
            Set<SObject> setOfSelectedApplicants=new Set<SObject>();

            if (lstAccount1 != null && lstAccount1.size() > 0) {
                for (Account a : lstAccount1) {
                    if (whereClauseConditionFieldNameMap != null && !whereClauseConditionFieldNameMap.isEmpty()){
                        for (String unsearchableField : whereClauseConditionFieldNameMap.keySet()) {
                            if (a.get(unsearchableField) == fsFieldValuesFormattedMap.get(unsearchableField)) {
                                mapOfPatientsWrapper.put(a.Id, new AccountDetailsWrapper(a));
                                setOfSelectedAccounts.add(a);
                            }
                        }
                    }else{
                        mapOfPatientsWrapper.put(a.Id, new AccountDetailsWrapper(a));
                        setOfSelectedAccounts.add(a);
                    }
                }
            }

            Map<String, List<String>> accountFieldValMap= new Map<String, List<String>>();
            accountFieldValMap      = getDisplayFieldSetValues(setOfSelectedAccounts,listOfDisplayFieldSetMembrs);
            /***** Get the search fieldSet fields *****/
            FieldSetLabelsFieldPathWrapper searchFieldPathWrapper = new FieldSetLabelsFieldPathWrapper();
            searchFieldPathWrapper = getDisplayFieldSetFields(searchFields.engagementProgramCode);
            List<String> listOfSearchFieldSetMembrs = searchFieldPathWrapper.fieldPathList;
            Map<Id,Map<String,Object>> fsFieldsMapAcc   = new Map<Id,Map<String,Object>>();
            fsFieldsMapAcc          = getFSValues(setOfSelectedAccounts,listOfSearchFieldSetMembrs);
            childAccAppDetailsMap   = new Map<String,List<String>>(accountFieldValMap);
            fsFieldsMaptoDisplay    = new Map<Id,Map<String,Object>>(fsFieldsMapAcc);

            if (!activeApplicantIdSet.isEmpty()) {
                for (PC_Applicant__c a : lstApplicant1) {
                    if (activeApplicantIdSet.contains(a.Id)) {
                        if (whereClauseConditionFieldNameAppMap != null && !whereClauseConditionFieldNameAppMap.isEmpty()){
                            for (String unsearchableField : whereClauseConditionFieldNameAppMap.keySet()) {
                                if (a.get(unsearchableField) == fsFieldValuesFormattedAppMap.get(unsearchableField)) {
                                    mapOfPatientsWrapper.put(a.Id, new AccountDetailsWrapper(a));
                                    setOfSelectedApplicants.add(a);
                                }
                            }
                        }
                        else{
                            mapOfPatientsWrapper.put(a.Id, new AccountDetailsWrapper(a));
                            setOfSelectedApplicants.add(a);
                        }
                    }
                }
            }

            Map<String, List<String>> applicantFieldValMap  = new Map<String, List<String>>();
            applicantFieldValMap                            = getDisplayFieldSetValues(setOfSelectedApplicants,listOfDisplayFieldSetMembrs);
            Map<Id,Map<String,Object>> fsFieldsMapApp       = new Map<Id,Map<String,Object>>();
            fsFieldsMapApp                                  = getFSValues(setOfSelectedApplicants,listOfSearchFieldSetMembrs);

            for(String fieldValKey:applicantFieldValMap.keySet()){
                childAccAppDetailsMap.put(fieldValKey,applicantFieldValMap.get(fieldValKey));
            }

            for(String fieldValKey : fsFieldsMapApp.keySet()){
                fsFieldsMaptoDisplay.put(fieldValKey,fsFieldsMapApp.get(fieldValKey));
            }
            /***** Logic to form the map of Account/Applicant Id and display fieldset members' values --- END *****/

            accAppDetailsWrapper.childAccAppDetailsMap  = childAccAppDetailsMap;
            accAppDetailsWrapper.mapOfPatientsWrapper   = mapOfPatientsWrapper;
            accAppDetailsWrapper.fsFieldsMap            = fsFieldsMaptoDisplay;

        }catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return accAppDetailsWrapper;
    }

    /*****************************************************************************************************
    * Author       : Tejas Patel
    * User Story   : PC-3243
    * Parameter    : String
    * Method name  : recordCuration
    * Return Type  : List sObject
    * Description  : Method remove reocrds that dont match the search criteria fields.
    *****************************************************************************************************/
    private static List<sObject> recordCuration(List<sObject> obj_temp, Map<String, String> fsFieldsMap, Boolean isApplicant) {
        if(!fsFieldsMap.isEmpty()){
            List<sObject> objList = new List<sObject>();
            Set<sObject> objSet = new Set<sObject>();
            Map<String,Object> objMap = new Map<String,Object>();
            if(isApplicant){
                for(String fsFieldsMapKey : fsFieldsMap.keySet()){
                    String fsFieldsMapNewKey = accountApplicantFieldsMapping.get(fsFieldsMapKey);
                    if(String.isNotBlank(fsFieldsMapNewKey)){
                        fsFieldsMap.put(fsFieldsMapNewKey,fsFieldsMap.remove(fsFieldsMapKey));
                    }
                }
            }
            for(sObject obj : obj_temp) {
                objMap = obj.getPopulatedFieldsAsMap();
                Integer mismactch = 0;
                for (String fieldAPI : fsFieldsMap.keySet()) {
                    Object fieldValue = objMap.get(fieldAPI);
                    if(String.isNotBlank(fsFieldsMap.get(fieldAPI)) && String.isNotBlank(String.valueOf(objMap.get(fieldAPI))) && mismactch == 0) {
                        if (String.valueOf(objMap.get(fieldAPI)).containsIgnoreCase(fsFieldsMap.get(fieldAPI))) {
                            objSet.add(obj);
                        }else{
                            objSet.remove(obj);
                            mismactch = 1;
                        }
                    }
                }
            }
            objList.addAll(objSet);
            return objList;
        }else{
            return obj_temp;
        }


    }

    /*****************************************************************************************************
    * Author       : Hitha Avalakki
    * User Story   : PC-3243
    * Parameter    : String
    * Method name  : getFieldSetFields
    * Return Type  : FieldSetDetailsWrapper
    * Description  : Method to get the fieldset members to be used for the search criteria.
    *****************************************************************************************************/
    @AuraEnabled
    public static FieldSetDetailsWrapper getFieldSetFields(String typeName, String engagementProgramCode) {
        FieldSetDetailsWrapper fieldSetDetailsWrapper;
        try {
            String fsNameVal = getFieldSetName(engagementProgramCode);
            List<PC_FieldSetController.FieldSetMember> listFieldSetMembers = PC_FieldSetController.getFields(typeName, fsNameVal);
            fieldSetDetailsWrapper = new FieldSetDetailsWrapper(listFieldSetMembers, fsNameVal);
        }catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return fieldSetDetailsWrapper;
    }

    /*****************************************************************************************************
    * Author       : Hitha Avalakki
    * User Story   : PC-3243
    * Parameter    :
    * Method name  : getFieldSetName
    * Return Type  : String
    * Description  : Method to get the fieldset name for fields required for search criteria.
    *****************************************************************************************************/
    @AuraEnabled
    public static String getFieldSetName(String engagementProgramCode) {
        String fieldSetName;
        try {
            fieldSetName = PC_SYSTEM.getSettingByEngagementProgram(engagementProgramCode, PC_Constants.PC_PRE_ENROLLMENT_SEARCH,PC_Constants.SETTINGS_TYPE.PATIENT_CONNECT_SETTING,PC_Constants.getQualifiedAPIName('PC_PreEnrollmentWizardSearch'));
            Boolean isValid= PC_Utility.isValidFieldSet('Account', fieldSetName);
            if(!isValid){
                throw new AuraHandledException(Label.PC_Enrollment_Fieldset_ErrorMessage);
             }
        }catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return fieldSetName;
    }

    /*****************************************************************************************************
    * Author       : Hitha Avalakki
    * User Story   : PC-3243
    * Parameter    : None
    * Method name  : getDisplayFieldSetFields
    * Return Type  : FieldSetLabelsFieldPathWrapper
    * Description  : Method to get the fieldset members to be used for displaying results.
    *****************************************************************************************************/
    @AuraEnabled
    public static FieldSetLabelsFieldPathWrapper getDisplayFieldSetFields(String engagementProgramCode) {
        FieldSetLabelsFieldPathWrapper fieldSetLabelsFieldPathWrapper=new FieldSetLabelsFieldPathWrapper();
        try {
            String fieldSetName = PC_SYSTEM.getSettingByEngagementProgram(engagementProgramCode, PC_Constants.PC_PRE_ENROLLMENT_DISPLAY,PC_Constants.SETTINGS_TYPE.PATIENT_CONNECT_SETTING,PC_Constants.getQualifiedAPIName('PC_PreEnrollmentWizardDisplay'));
            Boolean isValid= PC_Utility.isValidFieldSet('Account', fieldSetName);
            if(!isValid) {
                throw new AuraHandledException(Label.PC_Enrollment_Fieldset_ErrorMessage);
            }
            else {
                fieldSetLabelsFieldPathWrapper.fieldPathList = PC_FieldSetController.getFieldsByName('Account', fieldSetName);
                fieldSetLabelsFieldPathWrapper.fieldSetLabelsList = PC_FieldSetController.getFieldLabels('Account', fieldSetName);
            }
        }catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return fieldSetLabelsFieldPathWrapper;
    }

    /*****************************************************************************************************
    * Author       : Tejas Patel
    * User Story   : Bug Fix
    * Parameter    : None
    * Method name  : getDisplayFieldSetFields
    * Return Type  : FieldSetLabelsFieldPathWrapper
    * Description  : Method to get the fieldset members to be used for displaying results.
    *****************************************************************************************************/
    @AuraEnabled
    public static FieldSetLabelsFieldPathWrapper getSearchFieldSetFields(String engagementProgramCode) {

        FieldSetLabelsFieldPathWrapper fieldSetLabelsFieldPathWrapper=new FieldSetLabelsFieldPathWrapper();
        try {
            String fieldSetName = PC_SYSTEM.getSettingByEngagementProgram(engagementProgramCode,PC_Constants.PC_PRE_ENROLLMENT_SEARCH,PC_Constants.SETTINGS_TYPE.PATIENT_CONNECT_SETTING,PC_Constants.getQualifiedAPIName('PC_PreEnrollmentWizardSearch'));
            fieldSetLabelsFieldPathWrapper.fieldPathList = PC_FieldSetController.getFieldsByName('Account', fieldSetName);
            fieldSetLabelsFieldPathWrapper.fieldSetLabelsList = PC_FieldSetController.getFieldLabels('Account', fieldSetName);
        }catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return fieldSetLabelsFieldPathWrapper;
    }

    /*****************************************************************************************************
    * Author       : Hitha Avalakki
    * User Story   : PC-3243
    * Parameter    : SObject sobj
    * Method name  : initialiseFieldSetFieldsMap
    * Return Type  : Map<String, Object>
    * Description  : Method to initialise Map of search criteria fieldset member values to empty values.
    *****************************************************************************************************/
    @AuraEnabled
    public static Map<String, Object> initialiseFieldSetFieldsMap(SObject sobj, String engagementProgramCode) {
        SObjectType sObjType=sobj.getSObjectType();
        Map<String, Object> fsFields = new Map<String, Object>();
        List<String> fsList = new List<String>();
        String fieldSetName = getFieldSetName(engagementProgramCode);
        if(String.isNotBlank(fieldSetName)) {
            fsList = PC_FieldSetController.getFieldsByName(PC_Constants.PC_ACCOUNT, fieldSetName);
        }
        for(String fieldName: fsList){
            Schema.DisplayType fieldType = sObjType.getDescribe().fields.getMap().get(fieldName).getDescribe().getType();

            if(fieldType == Schema.DisplayType.STRING || fieldType == Schema.DisplayType.EMAIL || fieldType == Schema.DisplayType.PICKLIST||
                    fieldType == Schema.DisplayType.PHONE || fieldType == Schema.DisplayType.TEXTAREA) {
                fsFields.put(fieldName, PC_Constants.EMPTY_STRING);
            }
            else if(fieldType == Schema.DisplayType.DATE || fieldType == Schema.DisplayType.DATETIME || fieldType == Schema.DisplayType.BOOLEAN ||
                    fieldType == Schema.DisplayType.DOUBLE) {
                    fsFields.put(fieldName, PC_Constants.EMPTY_STRING);
            }
            else {
                fsFields.put(fieldName, PC_Constants.EMPTY_STRING);
            }

        }
        return fsFields;
    }
     /**
	  * EngProgramWrapper definition   
	  */
        public class EngProgramWrapper {
            @AuraEnabled public Id programId {get;set;}
            @AuraEnabled public String programName {get; set;}
            @AuraEnabled public String engagementProgramCode {get; set;}
            @AuraEnabled public String manufacturerId {get; set;}
            @AuraEnabled public String manuProgramName {get; set;}
            
            public EngProgramWrapper(PC_Engagement_Program__c c) {
                programId = c.Id;
                programName = c.Name;
                engagementProgramCode = c.PC_Program_Code__c;
                manufacturerId = c.PC_Manufacturer__c;
                manuProgramName = c.PC_Manufacturer__r.Name + ' : ' + c.Name;
            }
        }

    /*****************************************************************************************************
    * Author       : Hitha Avalakki
    * User Story   : PC-3243
    * Class name   : AccountAppDetailsWrapper
    * Description  : Wrapper class to hold list of column labels and list of data for Account and Applicant for display purpose.
    *****************************************************************************************************/
    public class AccountAppDetailsWrapper {
        @AuraEnabled public List<String> colLabelsList {get;set;}
        @AuraEnabled public Map<String, List<String>> childAccAppDetailsMap {get;set;}
        @AuraEnabled public Map<Id,AccountDetailsWrapper> mapOfPatientsWrapper {get;set;}
        @AuraEnabled public Map<Id,Map<String,Object>> fsFieldsMap {get;set;}

        public AccountAppDetailsWrapper() {
            colLabelsList=new List<String>();
            childAccAppDetailsMap   = new Map<String, List<String>>();
            mapOfPatientsWrapper    = new Map<Id,AccountDetailsWrapper>();
            fsFieldsMap             = new Map<Id,Map<String,Object>>();
        }
    }

    /*****************************************************************************************************
    * Author       : Hitha Avalakki
    * User Story   : PC-3243
    * Class name   : FieldSetLabelsFieldPathWrapper
    * Description  : Wrapper class to hold list of labels and list of data for Account and Applicant.
    *****************************************************************************************************/
    public class FieldSetLabelsFieldPathWrapper {
        @AuraEnabled public List<String> fieldSetLabelsList {get;set;}
        @AuraEnabled public List<String> fieldPathList {get; set;}

        public FieldSetLabelsFieldPathWrapper() {
            fieldSetLabelsList=new List<String>();
            fieldPathList=new List<String>();
        }
    }

    /**
	  * SearchWrapper definition   
	  */
        public class SearchWrapper {
            @AuraEnabled public String patientFirstName {get;set;}
            @AuraEnabled public String patientLastName {get; set;}
            @AuraEnabled public String patientDob {get; set;}
            @AuraEnabled public String engagementProgram {get; set;}
            @AuraEnabled public String engagementProgramId {get; set;}
            @AuraEnabled public String engagementProgramCode {get; set;}
            @AuraEnabled public String manufacturerId {get; set;}
            @AuraEnabled public Map<String,String> fsFields{get; set;}
            @AuraEnabled public String masterPatient {get; set;}

            public SearchWrapper() {
                patientFirstName = PC_Constants.EMPTY_STRING;
                patientLastName = PC_Constants.EMPTY_STRING;
                patientDob = PC_Constants.EMPTY_STRING;
                engagementProgram = PC_Constants.EMPTY_STRING;
                engagementProgramId = PC_Constants.EMPTY_STRING;
                engagementProgramCode = PC_Constants.EMPTY_STRING;
                manufacturerId = PC_Constants.EMPTY_STRING;
                masterPatient  = 'false';
            }
        }
        
    /**
     * patientsWrapper definition   
     */
    public class PatientsWrapper {
        @AuraEnabled public Id patientId {get;set;}
        @AuraEnabled public String patientName {get; set;}
        @AuraEnabled public String patientFirstName {get; set;}
        @AuraEnabled public String patientLastName {get; set;}
        @AuraEnabled public String accountType {get; set;}
        @AuraEnabled public String patientGender {get; set;}
        @AuraEnabled public Date patientDob {get; set;}
        @AuraEnabled public String patientEmail {get; set;}
        @AuraEnabled public String patientPhone {get; set;}
        @AuraEnabled public String patientAddress {get; set;}
        @AuraEnabled public String patientCity {get; set;}
        @AuraEnabled public String patientState {get; set;}
        @AuraEnabled public String patientZipcode {get; set;}
        @AuraEnabled public String accSelected {get; set;}
        @AuraEnabled public String enrollmentCase {get; set;}
        @AuraEnabled public String enrollmentCaseOwner {get; set;}
        @AuraEnabled public String enrollmentCaseStatus {get; set;}
        @AuraEnabled public String engagementProgramName {get; set;}
        @AuraEnabled public String engagementProgram {get; set;}
        
        public PatientsWrapper(Account c) {
            patientId = c.Id; 			
            patientName = c.Name;
            patientFirstName = c.PC_First_Name__c;
            patientLastName = c.PC_Last_Name__c;
            accountType = PC_Constants.PC_ACCOUNT;
            patientGender = c.PC_Gender__c;
            patientDob = c.PC_Date_of_Birth__c;
            patientEmail = c.PC_Email__c;
            patientPhone = c.Phone;
            patientAddress = c.PC_Primary_Address_1__c;
            patientCity = c.PC_Primary_City__c;
            patientState = c.PC_Primary_State__c;
            patientZipcode = c.PC_Primary_Zip_Code__c;
            accSelected = PC_Constants.FALSE_STRING;
        }
        
        public PatientsWrapper(PC_Applicant__c c) {
            patientId = c.Id; 			
            //patientName = c.PC_Patient_Name__c;
            patientFirstName = c.PC_First_Name__c;
            patientLastName = c.PC_Last_Name__c;
            patientName = c.PC_Last_Name__c + ',' + c.PC_First_Name__c;
            accountType = PC_Constants.PC_APPLICANT;
            patientGender = c.PC_Gender__c;
            patientDob = c.PC_Date_of_Birth__c;
            patientEmail = c.PC_Patient_Email__c;
            patientPhone = c.PC_Phone__c;
            patientAddress = c.PC_Address_1__c;
            patientCity = c.PC_City__c;
            patientState = c.PC_State__c;
            patientZipcode = c.PC_Zip_Code__c;
            accSelected = PC_Constants.FALSE_STRING;
            enrollmentCase = c.PC_Enrollment_Case__c;
            enrollmentCaseOwner = c.PC_Enrollment_Case__r.Owner.Name;
            enrollmentCaseStatus = c.PC_Enrollment_Case__r.Status; 
            engagementProgramName = c.PC_Engagement_Program__r.Name;
            engagementProgram = c.PC_Engagement_Program__c;
        }
    }

    public class AccountDetailsWrapper{
        @AuraEnabled public Id patientId {get;set;}
        @AuraEnabled public String accountType {get; set;}
        @AuraEnabled public String enrollmentCaseStatus {get; set;}
        @AuraEnabled public String engagementProgram {get; set;}
        @AuraEnabled public String enrollmentCaseOwner {get; set;}
        @AuraEnabled public String enrollmentCase {get; set;}

        public AccountDetailsWrapper(Account c) {
            patientId = c.Id;
            accountType = PC_Constants.PC_ACCOUNT;
        }

        public AccountDetailsWrapper(PC_Applicant__c c) {
            patientId = c.Id;
            accountType = PC_Constants.PC_APPLICANT;
            enrollmentCaseStatus = c.PC_Enrollment_Case__r.Status;
            engagementProgram = c.PC_Engagement_Program__c;
            enrollmentCaseOwner = c.PC_Enrollment_Case__r.Owner.Name;
            enrollmentCase = c.PC_Enrollment_Case__c;
        }
    }
    
    /**
     * DocWrapper definition   
     */
    public class DocWrapper {
        @AuraEnabled public Id docId {get;set;}
        @AuraEnabled public List<EngProgramWrapper> lstEngagementProgram {get; set;}
        @AuraEnabled public String engagementProgramId {get; set;}
        @AuraEnabled public String engagementProgramName {get; set;}
        @AuraEnabled public String engagementProgramCode {get; set;}
        @AuraEnabled public String manufacturer {get; set;}
        @AuraEnabled public String docCategory {get; set;}
        @AuraEnabled public Boolean isOnlineForm {get; set;}
        @AuraEnabled public String onlineApplicantId {get; set;}
        @AuraEnabled public String applicantFirstName {get; set;}
        @AuraEnabled public String applicantLastName {get; set;}
        @AuraEnabled public Date applicantDob {get; set;}
        @AuraEnabled public Map<String,Object> fsFields{get; set;}
        @AuraEnabled public String masterPatient {get; set;}
        
                                             
        public DocWrapper(PC_Document__c c) {
            docId = c.Id;
            engagementProgramId = c.PC_Engagement_Program__c;
            engagementProgramName = c.PC_Engagement_Program__r.Name;
            engagementProgramCode = c.PC_Engagement_Program__r.PC_Program_Code__c;
            manufacturer = c.PC_Engagement_Program__r.PC_Manufacturer__c;
            docCategory = c.PC_Document_Category__c;
            isOnlineForm = (c.RecordType.Name.equalsIgnoreCase(PC_Constants.DOCUMENT_SMARTFORM_RECORD_TYPE_NAME)) ? true : false;
            onlineApplicantId = c.PC_Applicant__c;
            applicantFirstName = c.PC_Applicant__r.PC_First_Name__c;
            applicantLastName = c.PC_Applicant__r.PC_Last_Name__c;
            applicantDob = c.PC_Applicant__r.PC_Date_of_Birth__c;
            masterPatient = PC_SYSTEM.getPatientConnectSetting(PC_Constants.PC_MASTER_PATIENT,'false').toLowerCase();
        }

        public DocWrapper() {
            lstEngagementProgram = new List<EngProgramWrapper>();
            masterPatient = PC_SYSTEM.getPatientConnectSetting(PC_Constants.PC_MASTER_PATIENT,'false').toLowerCase();
        }        
    }

    /*****************************************************************************************************
    * Author       : Hitha Avalakki
    * User Story   : PC-3243
    * Method name   : FieldSetDetailsWrapper
    * Description  : Wrapper class to hold search criteria fieldset name and its fieldset members.
    *****************************************************************************************************/
    public class FieldSetDetailsWrapper{
        @AuraEnabled public String fieldSetName {get;set;}
        @AuraEnabled public List<PC_FieldSetController.FieldSetMember> listFieldSetMembers{get; set;}

        public FieldSetDetailsWrapper(List<PC_FieldSetController.FieldSetMember> fieldSetMembersList , String fsName) {
            fieldSetName = fsName;
            listFieldSetMembers = fieldSetMembersList;
        }

        public FieldSetDetailsWrapper() {
            fieldSetName=PC_Constants.EMPTY_STRING;
            listFieldSetMembers = new List<PC_FieldSetController.FieldSetMember>();
        }
    }

    /*****************************************************************************************************
    * Author       : Hitha Avalakki
    * User Story   : PC-3243
    * Method name  : ConditionFieldDetailWrapper
    * Description  : Wrapper class to hold maps related to fieldset members to be used in the WHERE clause of SOSL query to search patients records
    *****************************************************************************************************/
    public class ConditionFieldDetailWrapper{
        @AuraEnabled public Map<String, String> conditionFieldNamesMap {get;set;}
        @AuraEnabled public Map<String, Object> fieldSetValFormattedValMap{get; set;}

        public ConditionFieldDetailWrapper(Map<String, String> fieldNamesMap ,Map<String, Object> fsFieldValueMap) {
            conditionFieldNamesMap=new Map<String, String>(fieldNamesMap);
            fieldSetValFormattedValMap=new Map<String, Object>(fsFieldValueMap);
        }

        public ConditionFieldDetailWrapper() {
            conditionFieldNamesMap = new Map<String, String>();
            fieldSetValFormattedValMap=new Map<String, Object>();
        }
    }

    /*****************************************************************************************************
    * Author       : Hitha Avalakki
    * User Story   : PC-3243
    * Parameter    : Map<String,String> fsFieldsMap
    * Method name  : getWhereClauseCondFields
    * Return Type  : Map<String, String>
    * Description  : This method is used to get a list of those Account and Applicant fields which cannot be used in the search string of SOSL query.
    *****************************************************************************************************/
    public static ConditionFieldDetailWrapper getWhereClauseCondFields(Map<String,String> fsFieldsMap,SObject sObj) {

        ConditionFieldDetailWrapper conditionFieldDetailWrapper;
        Map<String, String> whereClauseCondFieldNameMap = new Map<String, String>();
        Map<String, Object> fsFieldFormattedValuesMap = new Map<String, Object>();
        Map<String, Schema.DisplayType> fieldNameFieldTypeMap = new Map<String, Schema.DisplayType>();
        Schema.SObjectType sObjType = sObj.getSObjectType();
        Map<String, Schema.SObjectField> fieldDetailsMap = new Map<String, SObjectField>();
        fieldDetailsMap = sObjType.getDescribe().fields.getMap();

        try {
            /*** Run through fieldDetailsMap and create a map fieldName is the key, i.e. field API name is key and field's DescribeFieldResult object is the value ***/
            for (String fieldDetailKey : fieldDetailsMap.keySet()) {
                Schema.SObjectField fieldDetail = fieldDetailsMap.get(fieldDetailKey);
                fieldNameFieldTypeMap.put(fieldDetailKey.toUpperCase(), fieldDetail.getDescribe().getType());
            }

            /*** Run through the fsFieldsMap and create a list of those field API names which are to be included in WHERE clause of SOSL query ***/
            for (String accountFieldName : fsFieldsMap.keySet()) {
                 String fieldsMapKey = accountFieldName;

                 //Following check is required if any of the fieldSet field has been left blank, so as we don't include them in the where clause our SOSL query
                 if (!String.isEmpty(fsFieldsMap.get(fieldsMapKey))) {

                     if (sObjType == PC_Applicant__c.getSObjectType()) {
                         fieldsMapKey = accountApplicantFieldsMapping.get(accountFieldName);
                     }

                     //Following check is needed when the Sobject type is Applicant and we are unable to find any Applicant fieldname for an Account fieldname
                     if(!String.isEmpty(fieldsMapKey)){

                         if (fieldNameFieldTypeMap.get(fieldsMapKey.toUpperCase()) == Schema.DisplayType.DATE) {
                             whereClauseCondFieldNameMap.put(fieldsMapKey, fieldsMapKey);
                             fsFieldFormattedValuesMap.put(fieldsMapKey, Date.valueOf(fsFieldsMap.get(accountFieldName)));

                         } else if (fieldNameFieldTypeMap.get(fieldsMapKey.toUpperCase()) == Schema.DisplayType.DATETIME) {
                             whereClauseCondFieldNameMap.put(fieldsMapKey, fieldsMapKey);

                             String dateString = fsFieldsMap.get(accountFieldName);
                             String formattedFieldValue = dateString.replace('T', ' ');
                             formattedFieldValue = formattedFieldValue.substringBeforeLast('.');
                             Datetime parsedFieldValue = Datetime.valueOf(formattedFieldValue);
                             fsFieldFormattedValuesMap.put(fieldsMapKey, parsedFieldValue);

                         } else if (fieldNameFieldTypeMap.get(fieldsMapKey.toUpperCase()) == Schema.DisplayType.BOOLEAN) {
                             whereClauseCondFieldNameMap.put(fieldsMapKey, fieldsMapKey);
                             fsFieldFormattedValuesMap.put(fieldsMapKey, Boolean.valueOf(fsFieldsMap.get(accountFieldName)));

                         } else if (fieldNameFieldTypeMap.get(fieldsMapKey.toUpperCase()) == Schema.DisplayType.PICKLIST) {
                             whereClauseCondFieldNameMap.put(fieldsMapKey, fieldsMapKey);
                             fsFieldFormattedValuesMap.put(fieldsMapKey, String.valueOf(fsFieldsMap.get(accountFieldName)));

                         } else if (fieldNameFieldTypeMap.get(fieldsMapKey.toUpperCase()) == Schema.DisplayType.MULTIPICKLIST) {
                             whereClauseCondFieldNameMap.put(fieldsMapKey, fieldsMapKey);
                             fsFieldFormattedValuesMap.put(fieldsMapKey, String.valueOf(fsFieldsMap.get(accountFieldName)));

                         } else if (fieldNameFieldTypeMap.get(fieldsMapKey.toUpperCase()) == Schema.DisplayType.INTEGER) {
                             whereClauseCondFieldNameMap.put(fieldsMapKey, fieldsMapKey);
                             fsFieldFormattedValuesMap.put(fieldsMapKey, Integer.valueOf(fsFieldsMap.get(accountFieldName)));

                         } else if (fieldNameFieldTypeMap.get(fieldsMapKey.toUpperCase()) == Schema.DisplayType.LONG) {
                             whereClauseCondFieldNameMap.put(fieldsMapKey, fieldsMapKey);
                             fsFieldFormattedValuesMap.put(fieldsMapKey, Long.valueOf(fsFieldsMap.get(accountFieldName)));

                         } else if (fieldNameFieldTypeMap.get(fieldsMapKey.toUpperCase()) == Schema.DisplayType.DOUBLE) {
                             whereClauseCondFieldNameMap.put(fieldsMapKey, fieldsMapKey);
                             fsFieldFormattedValuesMap.put(fieldsMapKey, Decimal.valueOf(fsFieldsMap.get(accountFieldName)));

                         }
                    }
                }
            }

            conditionFieldDetailWrapper=new conditionFieldDetailWrapper(whereClauseCondFieldNameMap,fsFieldFormattedValuesMap);

        }catch(Exception ex){
            PC_Utility.logAndThrowException(ex);
        }
        return conditionFieldDetailWrapper;
    }

    /*****************************************************************************************************
    * Author       : Hitha Avalakki
    * User Story   : PC-3243
    * Parameter    : String queryString, List<String> displayFieldSetMembersList
    * Method name  : appendFieldSetMembersToQueryString
    * Return Type  : String
    * Description  : This method is used to create a dynamic query using the list of fieldset members
    *****************************************************************************************************/
    public static String appendFieldSetMembersToQueryString(String queryString, List<String> displayFieldSetMembersList,Map<String, String> whereClauseConditionFieldNameMap) {
        Boolean addComma=false;
        try {
            for (Integer i = 0; i < displayFieldSetMembersList.size(); i++) {
                if (i != displayFieldSetMembersList.size() - 1) {
                    queryString = queryString + displayFieldSetMembersList[i] + ', ';
                } else {
                    queryString = queryString + displayFieldSetMembersList[i];
                }
            }

            if (whereClauseConditionFieldNameMap != null && !whereClauseConditionFieldNameMap.isEmpty()) {
                List<String> whereClauseCondFieldNamesList = whereClauseConditionFieldNameMap.values();

                for (Integer j = 0; j < whereClauseCondFieldNamesList.size(); j++) {
                    if (!displayFieldSetMembersList.contains(whereClauseCondFieldNamesList[j])) {
                        addComma=true;
                    }
                }

                if((addComma) && (queryString.lastIndexOf(',')!=queryString.length()-1)){
                    queryString = queryString + ', ';
                }


                for (Integer j = 0; j < whereClauseCondFieldNamesList.size(); j++) {
                    /*** Here we check if listOfDisplayFieldSetMembrs contains any of the elements present in whereClauseConditionFieldNameMap
                    in order to avoid adding duplicate field members to the SOSL query ****/
                    if (!displayFieldSetMembersList.contains(whereClauseCondFieldNamesList[j])) {

                        if (j != whereClauseCondFieldNamesList.size() - 1) {
                            queryString = queryString + whereClauseCondFieldNamesList[j] + ', ';
                        } else {
                            queryString = queryString + whereClauseCondFieldNamesList[j];
                        }
                    }
                }
                // PC-6828 - Fix for Enrollment Search issue. Removing extra comma if it occurs at the end of the queryString.
                queryString = queryString.removeEnd(', ');
            }

        }catch (Exception ex){
            PC_Utility.logAndThrowException(ex);
        }
        return queryString;
    }

    /*****************************************************************************************************
    * Author       : Hitha Avalakki
    * User Story   : PC-3243
    * Parameter    : String queryString, List<String> displayFieldSetMembersList
    * Method name  : getDisplayFieldSetValues
    * Return Type  : Map<String, List<String>>
    * Description  : This method is used to create a dynamic query using the list of fieldset members
    *****************************************************************************************************/
    public static Map<String, List<String>> getDisplayFieldSetValues(Set<SObject> sobjectList, List<String> displayFieldSetMembersList) {

        Map<String, List<String>> childAccAppDetailsMap=new Map<String, List<String>>();
        try {
            for (SObject selectedSobject: sobjectList) {
                List<String> fieldValList = new List<String>();

                for (String fieldName : displayFieldSetMembersList) {
                    String fsFieldVal;
                    try {
                        if(selectedSobject.getSObjectType()==PC_Applicant__c.getSObjectType()){
                            fieldName=accntToApplntFieldNameMappingForDisplayFields.get(fieldName);
                        }

                        fsFieldVal = String.valueOf(PC_FieldSetController.castFieldValueAsString(fieldName, selectedSobject.get(fieldName), selectedSobject));
                        if (fsFieldVal == null) {
                            fsFieldVal = PC_Constants.EMPTY_STRING;
                        }
                    } catch (Exception e) {
                        fsFieldVal = PC_Constants.EMPTY_STRING;
                    }
                    fieldValList.add(fsFieldVal);
                }
                childAccAppDetailsMap.put(selectedSobject.Id, fieldValList);
            }

        }catch (Exception ex){
            PC_Utility.logAndThrowException(ex);
        }
        return childAccAppDetailsMap;
    }

    /*****************************************************************************************************
    * Author       : Tejas Patel
    * User Story   : Bug Fix
    * Parameter    : Set sobjectList, List<String> displayFieldSetMembersList
    * Method name  : getFSValues
    * Return Type  : Map<String, List<String>>
    * Description  : This method is used to create a dynamic query using the list of fieldset members
    *****************************************************************************************************/
    public static Map<Id,Map<String,Object>> getFSValues(Set<SObject> sobjectList, List<String> displayFieldSetMembersList) {

        Map<Id,Map<String,Object>> fsFieldsMap=new Map<Id,Map<String,Object>>();
        try {
            for (SObject selectedSobject: sobjectList) {
                Map<String, Object> fsFields = new Map<String, Object>();

                for (String fieldName : displayFieldSetMembersList) {
                    // PC-6830 - Fix for Data Missing in Enrollment Case Exists Popup Issue. Use Account fieldName as key instead of changing applicant fieldName when sObject is of type applicant.
                    String fsFieldName = fieldName;
                    Object fsFieldVal;
                    try {
                        if(selectedSobject.getSObjectType()==PC_Applicant__c.getSObjectType()){
                            fieldName=accntToApplntFieldNameMappingForDisplayFields.get(fieldName);
                        }

                        fsFieldVal = PC_FieldSetController.castFieldValueBasedOnType(fieldName, selectedSobject.get(fieldName), selectedSobject);
                        if (fsFieldVal == null) {
                            fsFieldVal = PC_Constants.EMPTY_STRING;
                        }
                    } catch (Exception e) {
                        fsFieldVal = PC_Constants.EMPTY_STRING;
                    }
                    fsFields.put(fsFieldName,fsFieldVal);
                }
                fsFieldsMap.put(selectedSobject.Id, fsFields);
            }

        }catch (Exception ex){
            PC_Utility.logAndThrowException(ex);
        }
        return fsFieldsMap;
    }

    /*****************************************************************************************************
    * Author       : Haritha Reddy
    * User Story   : PC-4261
    * Parameter    : Map<String,String> fsFieldsMap,SObject sObj
    * Method name  : getFilterCriteriaAndEncryptedFields
    * Return Type  : Map<String, String>
    * Description  : This method is used to get Where Clause String used in SOSL and a
    *                Map of Encrypted Fields and corresponding search values in Account and Applicant Objects
    *****************************************************************************************************/
    public static FilterCriteriaEncryptedFieldsWrapper getFilterCriteriaAndEncryptedFields(Map<String,String> fsFieldsMap,SObject sObj) {
        Map<String, String> encryptedSearchFieldMap = new Map<String, String>();
        String filterCriteriaWhereClause = PC_Constants.EMPTY_STRING;
        Map<String, Schema.DisplayType> fieldNameFieldTypeMap = new Map<String, Schema.DisplayType>();
        Schema.SObjectType sObjType = sObj.getSObjectType();
        Map<String, Schema.SObjectField> fieldDetailsMap = sObjType.getDescribe().fields.getMap();

        try {
            /*** Run through fieldDetailsMap and create a map fieldName is the key, i.e. field API name is key and field's DescribeFieldResult object is the value ***/
            for (String fieldDetailKey : fieldDetailsMap.keySet()) {
                Schema.SObjectField fieldDetail = fieldDetailsMap.get(fieldDetailKey);
                fieldNameFieldTypeMap.put(fieldDetailKey.toUpperCase(), fieldDetail.getDescribe().getType());
            }

            /*** Run through the fsFieldsMap and create a list of those field API names which are to be included in WHERE clause of SOSL query ***/
            for (String fieldName : fsFieldsMap.keySet()) {
                String fieldsMapKey = fieldName;

                //Following check is required if any of the fieldSet field has been left blank, so as we don't include them in the where clause our SOSL query
                if (!String.isEmpty(fsFieldsMap.get(fieldsMapKey)) || fieldNameFieldTypeMap.get(fieldsMapKey.toUpperCase()) == Schema.DisplayType.BOOLEAN) {

                    if (sObjType == PC_Applicant__c.getSObjectType()) {
                        fieldsMapKey = accountApplicantFieldsMapping.get(fieldName);
                    }
                    system.debug(fieldsMapKey+'>> type>> '+fieldNameFieldTypeMap.get(fieldsMapKey.toUpperCase())+' Value>>'+fsFieldsMap.get(fieldName));
                    Boolean isFieldEncrypted = Schema.getGlobalDescribe().get(String.valueOf(sObjType)).getDescribe().fields.getMap().get(fieldsMapKey).getDescribe().isEncrypted();
                    //Following check is needed when the Sobject type is Applicant and we are unable to find any Applicant fieldname for an Account fieldname

                    // PC-6828 - Changed from fsFieldsMap.get(fieldsMapKey) to fsFieldsMap.get(fieldName) in all the below statements to get correct value in where condition for applicant type because fsFieldsMap holds only account fields as key.
                    if(!String.isEmpty(fieldsMapKey)){
                        if(isFieldEncrypted) {
                            encryptedSearchFieldMap.put(fieldsMapKey,fsFieldsMap.get(fieldName));
                        }
                        else if(fieldNameFieldTypeMap.get(fieldsMapKey.toUpperCase()) == Schema.DisplayType.STRING){
                            filterCriteriaWhereClause += ' AND ' + fieldsMapKey + ' LIKE \'%' + String.escapeSingleQuotes(fsFieldsMap.get(fieldName)) + '%\'';
                        }
                        else if (fieldNameFieldTypeMap.get(fieldsMapKey.toUpperCase()) == Schema.DisplayType.DATE ||
                                fieldNameFieldTypeMap.get(fieldsMapKey.toUpperCase()) == Schema.DisplayType.DATETIME) {
                            filterCriteriaWhereClause += ' AND ' + fieldsMapKey + ' = ' + fsFieldsMap.get(fieldName);
                        }
                        else if (fieldNameFieldTypeMap.get(fieldsMapKey.toUpperCase()) == Schema.DisplayType.BOOLEAN) {
                            filterCriteriaWhereClause += ' AND ' + fieldsMapKey + ' = ' + Boolean.valueOf(fsFieldsMap.get(fieldName));
                        }
                        else if (fieldNameFieldTypeMap.get(fieldsMapKey.toUpperCase()) == Schema.DisplayType.MULTIPICKLIST) {
                            filterCriteriaWhereClause += ' AND ' + fieldsMapKey + ' INCLUDES (\'' + String.valueOf(fsFieldsMap.get(fieldName))+'\')';
                        }
                        else if (fieldNameFieldTypeMap.get(fieldsMapKey.toUpperCase()) == Schema.DisplayType.INTEGER) {
                            filterCriteriaWhereClause += ' AND ' + fieldsMapKey + ' = ' + Integer.valueOf(fsFieldsMap.get(fieldName));
                        }
                        else if (fieldNameFieldTypeMap.get(fieldsMapKey.toUpperCase()) == Schema.DisplayType.LONG) {
                            filterCriteriaWhereClause += ' AND ' + fieldsMapKey + ' = ' + Long.valueOf(fsFieldsMap.get(fieldName));
                        }
                        else if (fieldNameFieldTypeMap.get(fieldsMapKey.toUpperCase()) == Schema.DisplayType.DOUBLE) {
                            filterCriteriaWhereClause += ' AND ' + fieldsMapKey + ' = ' + Decimal.valueOf(fsFieldsMap.get(fieldName));
                        }
                        else {
                            filterCriteriaWhereClause += ' AND ' + fieldsMapKey + ' = \'' + String.valueOf(fsFieldsMap.get(fieldName))+'\'';
                        }
                    }
                }
            }

        }catch(Exception ex){
            PC_Utility.logAndThrowException(ex);
        }
        FilterCriteriaEncryptedFieldsWrapper wrapperObj = new FilterCriteriaEncryptedFieldsWrapper();
        wrapperObj.filterCriteria = filterCriteriaWhereClause;
        wrapperObj.encryptedFieldsAndValues = encryptedSearchFieldMap;
        return wrapperObj;
    }

    /*****************************************************************************************************
    * Author       : Haritha Reddy
    * User Story   : PC-3243
    * Method name  : FilterCriteriaEncryptedFieldsWrapper
    * Description  : Wrapper class to hold filter Criteria String that is used in the WHERE clause of SOSL query to search patients records
                     and map of Encrypted Fields & their corresponding search values
    *****************************************************************************************************/
    public class FilterCriteriaEncryptedFieldsWrapper{
        @AuraEnabled public String filterCriteria {get;set;}
        @AuraEnabled public Map<String, String> encryptedFieldsAndValues{get; set;}

        public FilterCriteriaEncryptedFieldsWrapper(String filterCriteria ,Map<String, String> encryptedFieldsAndValues) {
            filterCriteria = filterCriteria;
            encryptedFieldsAndValues = encryptedFieldsAndValues;
        }
        public FilterCriteriaEncryptedFieldsWrapper() {
        }
    }

}