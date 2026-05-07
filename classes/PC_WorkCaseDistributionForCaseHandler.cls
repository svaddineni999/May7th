/*********************************************************************************************************
Class Name      : PC_WorkCaseDistributionForCaseHandler
Description     : trigger on Case object to process work case distribution
Created By      : Hitha Avalakki
Created Date    : June 21, 2019
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer                   Date                   	Description
--------------------------------------------------------------------------------------------------------------
Hitha Avalakki            	June 21, 2019           Initial Version
Hitha Avalakki              July 10, 2019           PC-5032: Added error handling scenarios for Work Case Distribution logic
Shishir Bansal        11-Dec-2019      [PC-5792] Avoid hardcoding of string variable
Hitha Avalakki              Mar 19, 2021            [PC-7533] Replaced constant CASE_PROGRAM_RECORD_TYPE_NAME to CASE_PROGRAM_TYPE
Hitha Avalakki              May 25, 2021            PC-7545: Removed 'with sharing' class level declaration since trigger handler code runs in system context.
Kishore Kanteti             Sept 3,2021             PC-8068 - Removed FLS Check on DML Operation
Satheesh Kumar              Nov 16, 2021            [PC-8213] Excluded FLS Check and added inherited sharing
Pavan Kumar                 Feb 16, 2022            [PC-8503] Added separate methods for synchronous and asynchronous operation of WCD
Pavan Kumar                 Mar 08, 2022            [PC-8568] Added logic to process creation of Association records synchronously & asynchronously
****************************************************************************************************************/

/* PC-7545: 'with sharing' class level declaration is not required since trigger handler code runs in Trigger Context*/
public inherited sharing class PC_WorkCaseDistributionForCaseHandler extends PC_TriggerHandler {

    public static boolean isProcessed = false;
    public static boolean processedAsynchronously = false;
    public static Map<Id, PC_WorkCaseDistributionHelper.RecordIdWorkCaseDistDetailsWrapper> mapOfRecordIdWorkCaseDistDetailsWrapper = new Map<Id, PC_WorkCaseDistributionHelper.RecordIdWorkCaseDistDetailsWrapper>();
    public override void afterInsert() {
        if (isProcessed == false) {
            system.debug('Trigger Handler ::: PC_WorkCaseDistributionForCaseHandler');
            processWorkCaseDistributionForCase((List<Case>) newList);
        }
    }
    /**
     * This method is used to create Associate records
     *
     * @param newCaseList - List of cases
     */
    private static void processWorkCaseDistributionForCase(List<Case> newCaseList) {
        /** Please note 'WCD' is the abbreviation for 'Work Case Distribution Table' and
            'PRUM' abbreviation for 'Program Region User Mapping' in comments below **/

        try {
            List<PC_Association__c> associationListToCreate = new List<PC_Association__c>();
            PC_WorkCaseDistributionHelper.WCDOutputWrapper wcdOutputWrapper = new PC_WorkCaseDistributionHelper.WCDOutputWrapper();
            String enableWorkCaseDistribution = PC_SYSTEM.getPatientConnectSetting(PC_Constants.PC_ENABLE_WORK_CASE_DISTRIBUTION, PC_Constants.FALSE_STRING);
            String enableAsynchronousWorkCaseDistribution = PC_WorkCaseDistributionHelper.getWCDMode();
            if (Test.isRunningTest()) {
                enableWorkCaseDistribution = PC_Constants.TRUE_STRING;
            }

            if (!String.isBlank(enableWorkCaseDistribution) && enableWorkCaseDistribution.equalsIgnoreCase(PC_Constants.TRUE_STRING)) {
                if ((!String.isBlank(enableAsynchronousWorkCaseDistribution) && enableAsynchronousWorkCaseDistribution.equalsIgnoreCase(PC_Constants.FALSE_STRING)) ||
                        enableAsynchronousWorkCaseDistribution == null) {

                    associationListToCreate = getAssociatonsToCreate(newCaseList);
                    if (associationListToCreate != null && associationListToCreate.size() > 0 && !associationListToCreate.isEmpty()) {
                        if (associationListToCreate.size() > 200) {
                            wcdOutputWrapper.associationListToCreate = associationListToCreate;
                            wcdOutputWrapper.recordIdWorkCaseDistDetailsWrapperMap = mapOfRecordIdWorkCaseDistDetailsWrapper;
                            wcdOutputWrapper.programRegionHistoryCreateList = PC_WorkCaseDistributionHelper.programRegionUserHistoryCreateList;
                            wcdOutputWrapper.programRegionHistoryDeleteList = PC_WorkCaseDistributionHelper.programRegionHistoryDeleteList;
                            PC_WorkCaseDistributionHelper.createAssociationsAsynchronously(wcdOutputWrapper, 'CaseHandler');
                        } else {
                            isProcessed = true;
                            PC_Database.ins(associationListToCreate, false);
                            PC_Database.del(PC_WorkCaseDistributionHelper.programRegionHistoryDeleteList, false);
                            PC_Database.ins(PC_WorkCaseDistributionHelper.programRegionUserHistoryCreateList, false);
                        }
                    }

                } else if (!String.isBlank(enableAsynchronousWorkCaseDistribution) && enableAsynchronousWorkCaseDistribution.equalsIgnoreCase(PC_Constants.TRUE_STRING)) {
                    associationListToCreate = getAssociatonsToCreate(newCaseList);
                    if (associationListToCreate != null && associationListToCreate.size() != 0 && !associationListToCreate.isEmpty()) {
                        wcdOutputWrapper.associationListToCreate = associationListToCreate;
                        wcdOutputWrapper.recordIdWorkCaseDistDetailsWrapperMap = mapOfRecordIdWorkCaseDistDetailsWrapper;
                        wcdOutputWrapper.programRegionHistoryCreateList = PC_WorkCaseDistributionHelper.programRegionUserHistoryCreateList;
                        wcdOutputWrapper.programRegionHistoryDeleteList = PC_WorkCaseDistributionHelper.programRegionHistoryDeleteList;
                        PC_WorkCaseDistributionHelper.createAssociationsAsynchronously(wcdOutputWrapper, 'CaseHandler');
                    }
                } else if (!String.isBlank(enableAsynchronousWorkCaseDistribution) && !enableAsynchronousWorkCaseDistribution.equalsIgnoreCase(PC_Constants.TRUE_STRING)
                        && !enableAsynchronousWorkCaseDistribution.equalsIgnoreCase(PC_Constants.FALSE_STRING) && enableAsynchronousWorkCaseDistribution != null) {
                    for (Case newCaseRec : newCaseList) {
                        newCaseRec.addError(Label.PC_InvalidPatientConnectSetting);
                    }
                }
            }

        } catch (Exception ex) {
            PC_Utility.publishErrorLog(ex, ex.getMessage());
        }
    }


    /**
     * This method is used to get Associations by calling method that process WCD
     * User-Story: PC-8503
     * @param caseList
     *
     * @return - List of Associations
     */
    public static List<PC_Association__c> getAssociatonsToCreate(List<Case> caseList) {
        List<PC_Association__c> associationListToCreate = new List<PC_Association__c>();
        Map<Id, Id> caseIdEngagementProgramIdMap = new Map<Id, Id>();
        Map<Id, PC_WorkCaseDistributionHelper.RecordIdWorkCaseDistDetailsWrapper> recordIdWorkCaseDistDetailsWrapperMap = new Map<Id, PC_WorkCaseDistributionHelper.RecordIdWorkCaseDistDetailsWrapper>();

        /** Prepare a Map where program case record ids act as keys and their engagement program record ids act as value **/
        for (Case newCaseRec : caseList) {

            if (newCaseRec.Type == PC_Constants.CASE_PROGRAM_TYPE && newCaseRec.PC_Engagement_Program__c != null) {
                caseIdEngagementProgramIdMap.put(newCaseRec.Id, newCaseRec.PC_Engagement_Program__c);
                PC_WorkCaseDistributionHelper.RecordIdWorkCaseDistDetailsWrapper recordIdWorkCaseDistDetailsWrapper = new PC_WorkCaseDistributionHelper.RecordIdWorkCaseDistDetailsWrapper();
                recordIdWorkCaseDistDetailsWrapper.engagementProgramId = newCaseRec.PC_Engagement_Program__c;
                recordIdWorkCaseDistDetailsWrapper.accountId = newCaseRec.AccountId;
                recordIdWorkCaseDistDetailsWrapper.caseId = newCaseRec.Id;

                recordIdWorkCaseDistDetailsWrapperMap.put(newCaseRec.Id, recordIdWorkCaseDistDetailsWrapper);
            }
        }

        if (caseIdEngagementProgramIdMap != null && !caseIdEngagementProgramIdMap.isEmpty()) {
            associationListToCreate = returnAssociationsByProcessingWorkCaseDistribution(recordIdWorkCaseDistDetailsWrapperMap);
        }
        return associationListToCreate;
    }

    /**
     * This method is to process work case distribution and return Associate records to create
     * User-Story : PC-8436
     * @param recordIdWorkCaseDistDetailsWrapperMap - Map of case Id with case details wrapper
     *
     * @return - List of Associations
     */
    public static List<PC_Association__c> returnAssociationsByProcessingWorkCaseDistribution(Map<Id, PC_WorkCaseDistributionHelper.RecordIdWorkCaseDistDetailsWrapper> recordIdWorkCaseDistDetailsWrapperMap) {

        List<PC_Association__c> careTeamAssociationList = new List<PC_Association__c>();

        /* *********************************** STEP 1 ***********************************************
        * getWorkCaseDistributionDetails: This method is used to fetch zip code from WCD table for the program cases that have been created
        * ************************************************************************************ */
        recordIdWorkCaseDistDetailsWrapperMap = getWorkCaseDistributionDetails(recordIdWorkCaseDistDetailsWrapperMap);

        /* *********************************** STEP 2 ***********************************************
        * getRegionZipCodeAndRegionDetails: Get Details from 'Region Zip Code' and 'Region' tables in order to fetch the correct region id and corresponding manufacturer record id
        * *************************************************************************************/
        recordIdWorkCaseDistDetailsWrapperMap = PC_WorkCaseDistributionHelper.getRegionZipCodeAndRegionDetails(recordIdWorkCaseDistDetailsWrapperMap);

        /* *********************************** STEP 3 ****************************************************************************************
        * getCareTeamAssociationRecords: Query 'Program Region User Mapping' table and get details to create Care Team Association Records.
        ***********************************************************************************************************************************/
        careTeamAssociationList = PC_WorkCaseDistributionHelper.getCareTeamAssociationRecords(recordIdWorkCaseDistDetailsWrapperMap);
        mapOfRecordIdWorkCaseDistDetailsWrapper = recordIdWorkCaseDistDetailsWrapperMap;

        return careTeamAssociationList;
    }

    /**
     * This method is used to fetch Zip Code details on creation of Program Cases from Work Case Distribution table
     * User-Story : PC-4014
     * @param recordIdWorkCaseDistDetailsWrapperMap - Map of case Id with case details wrapper
     *
     * @return - Map of case Id with case details wrapper of zipcode value
     */
    public static Map<Id, PC_WorkCaseDistributionHelper.RecordIdWorkCaseDistDetailsWrapper> getWorkCaseDistributionDetails(Map<Id, PC_WorkCaseDistributionHelper.RecordIdWorkCaseDistDetailsWrapper> recordIdWorkCaseDistDetailsWrapperMap) {
        PC_WorkCaseDistributionHelper.RecordIdWorkCaseDistDetailsWrapper recordIdWorkCaseDistDetailsWrapper = new PC_WorkCaseDistributionHelper.RecordIdWorkCaseDistDetailsWrapper();

        Map<Id, String> engProgIdAssignmentLookupFldMap = new Map<Id, String>();
        Map<Id, Id> caseIdAccountIdMap = new Map<Id, Id>();
        Set<Id> caseIdSet = new Set<Id>();
        Set<Id> accountIdSet = new Set<Id>();
        Map<Id, PC_WorkCaseDistributionConfig__c> programCaseWorkCaseDistRecordMap = new Map<Id, PC_WorkCaseDistributionConfig__c>();
        Map<Id, PC_WorkCaseDistributionConfig__c> patientWorkCaseDistRecordMap = new Map<Id, PC_WorkCaseDistributionConfig__c>();
        List<PC_WorkCaseDistributionConfig__c> workCaseDistributionConfigList = new List<PC_WorkCaseDistributionConfig__c>();
        Set<String> zipCodeFieldNameOnCaseSet = new Set<String>();
        Set<String> zipCodeFieldNameOnAccountSet = new Set<String>();
        String zipCodeFieldNameOnCaseString = PC_Constants.EMPTY_STRING;
        String zipCodeFieldNameOnAccountString = PC_Constants.EMPTY_STRING;
        Map<Id, String> recordIdZipCodeFieldNameMap = new Map<Id, String>();
        Map<Id, String> recordIdZipCodeMap = new Map<Id, String>();
        Map<Id, String> recordIdZipCodeForAccountMap = new Map<Id, String>();
        List<Id> engagementProgramIdList = new List<Id>();

        /** Prepare a list of engagement programs and a map of caseId to AccountId, we would require 'caseIdAccountIdMap' to fill in the zip codes for
         * all cased ids in 'recordIdWorkCaseDistDetailsWrapperMap' map **/
        for (Id recordId : recordIdWorkCaseDistDetailsWrapperMap.keySet()) {
            engagementProgramIdList.add(recordIdWorkCaseDistDetailsWrapperMap.get(recordId).engagementProgramId);
            caseIdAccountIdMap.put(recordId, recordIdWorkCaseDistDetailsWrapperMap.get(recordId).accountId);
        }

        if (engagementProgramIdList != null && !engagementProgramIdList.isEmpty()) {
            //FLS is NOT needed in Triggers, as they always run in System Mode.
            /** Fetch all PC_WorkCaseDistributionConfig__c records which have Assignment Type 'Program Case' / 'Patient' **/
            workCaseDistributionConfigList = [
                    SELECT Id,PC_AssignmentLookupField__c,PC_EngagementProgram__c, PC_AssignmentType__c
                    FROM PC_WorkCaseDistributionConfig__c
                    WHERE PC_EngagementProgram__c IN:engagementProgramIdList AND
                    (PC_AssignmentType__c = :PC_Constants.PC_WCD_PROGRAM_CASE OR PC_AssignmentType__c = :PC_Constants.PC_WCD_PATIENT)
            ];
        }

        if (workCaseDistributionConfigList != null && !workCaseDistributionConfigList.isEmpty()) {

            /** 1) Run through WCD records and get list of 'Program Case' assignment type and another list of
            * WCD records of 'Patient' assignment type.
            *
            * 2) We require separate lists since 'Account' assignment type's WCD record has 'Parent Object.Zip Code Field Name' and
            * 'Program Case' assignment type's WCD record has 'Zip Code Field Name'.
            */
            for (PC_WorkCaseDistributionConfig__c workCaseDistributionConfig : workCaseDistributionConfigList) {

                if (PC_Constants.PC_WCD_PROGRAM_CASE.equals(workCaseDistributionConfig.PC_AssignmentType__c)) {
                    programCaseWorkCaseDistRecordMap.put(workCaseDistributionConfig.PC_EngagementProgram__c, workCaseDistributionConfig);

                    if (!String.isBlank(workCaseDistributionConfig.PC_AssignmentLookupField__c)) {
                        engProgIdAssignmentLookupFldMap.put(workCaseDistributionConfig.PC_EngagementProgram__c, workCaseDistributionConfig.PC_AssignmentLookupField__c);
                        zipCodeFieldNameOnCaseSet.add(workCaseDistributionConfig.PC_AssignmentLookupField__c);
                    }
                } else if (PC_Constants.PC_WCD_PATIENT.equals(workCaseDistributionConfig.PC_AssignmentType__c)) {
                    patientWorkCaseDistRecordMap.put(workCaseDistributionConfig.PC_EngagementProgram__c, workCaseDistributionConfig);

                    if (!String.isBlank(workCaseDistributionConfig.PC_AssignmentLookupField__c)) {
                        engProgIdAssignmentLookupFldMap.put(workCaseDistributionConfig.PC_EngagementProgram__c, workCaseDistributionConfig.PC_AssignmentLookupField__c);
                        zipCodeFieldNameOnAccountSet.add(workCaseDistributionConfig.PC_AssignmentLookupField__c);
                    }
                }
            }

            /* We would need to create a single string of comma separated 'Zip Code field names' so as we can include Patient Connect's fields and new custom fields
             defined by clients for zip code **/
            /* For WCD record which have 'PC_AssignmentLookupField__c' value for 'Program Case' Assignment type */
            zipCodeFieldNameOnCaseString = String.join(new List<String>(zipCodeFieldNameOnCaseSet), ',');

            /* For WCD record which have 'PC_AssignmentLookupField__c' value for 'Patient' Assignment type */
            zipCodeFieldNameOnAccountString = String.join(new List<String>(zipCodeFieldNameOnAccountSet), ',');

            /** Populate the manufacturer id for the engagement program for a cased id entry in 'recordIdWorkCaseDistDetailsWrapperMap' main map**/
            recordIdWorkCaseDistDetailsWrapperMap = PC_WorkCaseDistributionHelper.populateManufacturerIdForEngagementProg(engProgIdAssignmentLookupFldMap, recordIdWorkCaseDistDetailsWrapperMap);

            /** We need a set of Case/Account ids and a map of case/account ids and their zip code field names
             *  in order to fetch their corresponding zip code values  **/
            for (Id recordId : recordIdWorkCaseDistDetailsWrapperMap.keySet()) {
                if (programCaseWorkCaseDistRecordMap.containsKey(recordIdWorkCaseDistDetailsWrapperMap.get(recordId).engagementProgramId)) {
                    caseIdSet.add(recordId);
                    recordIdZipCodeFieldNameMap.put(recordId, engProgIdAssignmentLookupFldMap.get(recordIdWorkCaseDistDetailsWrapperMap.get(recordId).engagementProgramId));
                } else if (patientWorkCaseDistRecordMap.containsKey(recordIdWorkCaseDistDetailsWrapperMap.get(recordId).engagementProgramId)) {
                    accountIdSet.add(recordIdWorkCaseDistDetailsWrapperMap.get(recordId).accountId);
                    recordIdZipCodeFieldNameMap.put(recordId, 'Account.'+engProgIdAssignmentLookupFldMap.get(recordIdWorkCaseDistDetailsWrapperMap.get(recordId).engagementProgramId));
                }
            }

            /** Get zip code details from the zip code fields/fields listed on Case object **/
            if (!String.isBlank(zipCodeFieldNameOnCaseString)) {
                recordIdZipCodeMap = PC_WorkCaseDistributionHelper.getZipCodeDetails(zipCodeFieldNameOnCaseString, PC_Constants.PC_CASE, caseIdSet, recordIdZipCodeFieldNameMap, caseIdAccountIdMap, recordIdZipCodeMap);
            }

            /** Get zip code details from the zip code fields/fields listed on Account object **/
            if (!String.isBlank(zipCodeFieldNameOnAccountString)) {
                recordIdZipCodeMap = PC_WorkCaseDistributionHelper.getZipCodeDetails(zipCodeFieldNameOnAccountString, PC_Constants.PC_ACCOUNT, accountIdSet, recordIdZipCodeFieldNameMap, caseIdAccountIdMap, recordIdZipCodeMap);
            }

            system.debug('recordIdZipCodeMap :::'+recordIdZipCodeMap);

            /** Populate the zip code values for all the case record ids which serve as key in main map:'recordIdWorkCaseDistDetailsWrapperMap' **/
            for (Id caseId : recordIdWorkCaseDistDetailsWrapperMap.keySet()) {
                if (recordIdZipCodeMap.containsKey(caseId)) {
                    recordIdWorkCaseDistDetailsWrapperMap.get(caseId).zipCodeValue = recordIdZipCodeMap.get(caseId);
                }
            }
        } else {
            /** PC-5032: Error handling scenarios **/
            String errorMessage = Label.PC_NoRecordsFoundInWorkCaseDistForCase;
            PC_WorkCaseDistributionHelper.PC_WorkCaseDistributionException workCaseDistException = new PC_WorkCaseDistributionHelper.PC_WorkCaseDistributionException();
            workCaseDistException.setMessage(errorMessage);
            throw workCaseDistException;
        }

        return recordIdWorkCaseDistDetailsWrapperMap;
    }
}