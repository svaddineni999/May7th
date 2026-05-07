/*********************************************************************************************************
Class Name      : PC_WorkCaseDistributionForAssocHandler
Description     : trigger on Association object to process work case distribution
Created By      : Hitha Avalakki
Created Date    : July 03, 2019
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer                   Date                   	Description
--------------------------------------------------------------------------------------------------------------
Hitha Avalakki            	July 03, 2019           Initial Version
Hitha Avalakki              July 10, 2019           PC-5033: Added error handling scenarios for Work Case Distribution logic
Shishir Bansal              11-Dec-2019             [PC-5792] Avoid hardcoding of string variable
Hitha Avalakki              May 25, 2021            PC-7545: Removed 'with sharing' class level declaration since trigger handler code runs in system context.
Kishore Kanteti             Aug 27,2021             PC-8068 - Removed FLS Check on DML Operation
Pavan Kumar                 Feb 16, 2022            [PC-8503] Added separate methods for synchronous and asynchronous operation of WCD
Pavan Kumar                 Mar 08, 2022            [PC-8568] Added logic to process creation of Association records synchronously & asynchronously
Satheesh Kumar              Apr 01, 2022            [PC-8593] Added Error handling for Asynchronous WCD
****************************************************************************************************************/

/* PC-7545: 'with sharing' class level declaration is not required since trigger handler code runs in Trigger Context*/
public inherited sharing class PC_WorkCaseDistributionForAssocHandler extends PC_TriggerHandler {
    public static boolean isProcessed = false;
    public static boolean processedAsynchronously = false;
    public static Map<Id, PC_WorkCaseDistributionHelper.RecordIdWorkCaseDistDetailsWrapper> mapOfRecordIdWorkCaseDistDetailsWrapper = new Map<Id, PC_WorkCaseDistributionHelper.RecordIdWorkCaseDistDetailsWrapper>();

    public override void afterInsert() {
        if (isProcessed == false && !(PC_WorkCaseRedistributionForAccHandler.isProcessed == true || PC_WorkCaseRedistributionForAddrHandler.isProcessed == true || PC_WorkCaseRedistributionForUserHandler.isProcessed == true)) {
            system.debug('Trigger Handler ::: PC_WorkCaseDistributionForAssocHandler');
            processWorkCaseDistributionForAssociation((List<PC_Association__c>) newList);
        }
    }
    /**
     * This method is used to create Associate records
     *
     * @param newAssociationList - list of Associations
     */
    private static void processWorkCaseDistributionForAssociation(List<PC_Association__c> newAssociationList) {

        try {

            List<PC_Association__c> associationsToCreate = new List<PC_Association__c>();
            PC_WorkCaseDistributionHelper.WCDOutputWrapper wcdOutputWrapper = new PC_WorkCaseDistributionHelper.WCDOutputWrapper();
            String enableWorkCaseDistribution = PC_SYSTEM.getPatientConnectSetting(PC_Constants.PC_ENABLE_WORK_CASE_DISTRIBUTION, PC_Constants.FALSE_STRING);
            String enableAsynchronousWorkCaseDistribution = PC_WorkCaseDistributionHelper.getWCDMode();
            if (Test.isRunningTest()) {
                enableWorkCaseDistribution = PC_Constants.TRUE_STRING;
            }

            if (!String.isBlank(enableWorkCaseDistribution) && enableWorkCaseDistribution.equalsIgnoreCase(PC_Constants.TRUE_STRING)) {
                if ((!String.isBlank(enableAsynchronousWorkCaseDistribution) && enableAsynchronousWorkCaseDistribution.equalsIgnoreCase(PC_Constants.FALSE_STRING)) ||
                        ((!String.isBlank(enableAsynchronousWorkCaseDistribution) && enableAsynchronousWorkCaseDistribution.equalsIgnoreCase(PC_Constants.TRUE_STRING)) && PC_WorkCaseDistributionForCaseHandler.processedAsynchronously == true) ||
                        (processedAsynchronously == true) || enableAsynchronousWorkCaseDistribution == null) {

                    associationsToCreate = getAssociatonsToCreate(newAssociationList);
                    if (associationsToCreate != null && associationsToCreate.size() > 0 && !associationsToCreate.isEmpty()) {
                        isProcessed = true;
                        PC_Database.ins(associationsToCreate, false);
                        PC_Database.del(PC_WorkCaseDistributionHelper.programRegionHistoryDeleteList, false);
                        PC_Database.ins(PC_WorkCaseDistributionHelper.programRegionUserHistoryCreateList, false);
                    }

                } else if (!String.isBlank(enableAsynchronousWorkCaseDistribution) && enableAsynchronousWorkCaseDistribution.equalsIgnoreCase(PC_Constants.TRUE_STRING) &&
                        PC_WorkCaseDistributionForCaseHandler.processedAsynchronously == false && processedAsynchronously == false) {

                    associationsToCreate = getAssociatonsToCreate(newAssociationList);
                    if (associationsToCreate != null && associationsToCreate.size() != 0 && !associationsToCreate.isEmpty()) {
                        wcdOutputWrapper.associationListToCreate = associationsToCreate;
                        wcdOutputWrapper.recordIdWorkCaseDistDetailsWrapperMap = mapOfRecordIdWorkCaseDistDetailsWrapper;
                        wcdOutputWrapper.programRegionHistoryCreateList = PC_WorkCaseDistributionHelper.programRegionUserHistoryCreateList;
                        wcdOutputWrapper.programRegionHistoryDeleteList = PC_WorkCaseDistributionHelper.programRegionHistoryDeleteList;
                        PC_WorkCaseDistributionHelper.createAssociationsAsynchronously(wcdOutputWrapper, 'AssociationHandler');
                        /*createAssociatesAsynchronously(associationsToCreate);
                        PC_Database.del(PC_WorkCaseDistributionHelper.programRegionHistoryDeleteList, false);
                        PC_Database.ins(PC_WorkCaseDistributionHelper.programRegionUserHistoryCreateList, false);*/
                    }
                } else if (!String.isBlank(enableAsynchronousWorkCaseDistribution) && !enableAsynchronousWorkCaseDistribution.equalsIgnoreCase(PC_Constants.TRUE_STRING)
                        && !enableAsynchronousWorkCaseDistribution.equalsIgnoreCase(PC_Constants.FALSE_STRING) && enableAsynchronousWorkCaseDistribution != null) {
                    for (PC_Association__c newAssociationRec : newAssociationList) {
                        newAssociationRec.addError(Label.PC_InvalidPatientConnectSetting);
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
     * @param associationList
     *
     * @return - List of Associations
     */
    public static List<PC_Association__c> getAssociatonsToCreate(List<PC_Association__c> associationList) {
        List<PC_Association__c> associationsToBeCreated = new List<PC_Association__c>();
        Map<Id, PC_WorkCaseDistributionHelper.RecordIdWorkCaseDistDetailsWrapper> recordIdWorkCaseDistDetailsWrapperMap = new Map<Id, PC_WorkCaseDistributionHelper.RecordIdWorkCaseDistDetailsWrapper>();
        Set<Id> caseIdSet = new Set<Id>();
        Map<Id, Case> casesMap;
        for (PC_Association__c associationRecord : associationList) {
            caseIdSet.add(associationRecord.PC_Program__c);
        }

        if (caseIdSet != null && !caseIdSet.isEmpty()) {
            //FLS is NOT needed in Triggers, as they always run in System Mode.
            casesMap = new Map<Id, Case>([SELECT Id, PC_Engagement_Program__c FROM Case WHERE Id IN:caseIdSet]);
        }

        for (PC_Association__c associationRecord : associationList) {
            PC_WorkCaseDistributionHelper.RecordIdWorkCaseDistDetailsWrapper recordIdWorkCaseDistDetailsWrapper = new PC_WorkCaseDistributionHelper.RecordIdWorkCaseDistDetailsWrapper();
            recordIdWorkCaseDistDetailsWrapper.engagementProgramId = casesMap.get(associationRecord.PC_Program__c).PC_Engagement_Program__c;
            recordIdWorkCaseDistDetailsWrapper.accountId = associationRecord.PC_Account__c;
            recordIdWorkCaseDistDetailsWrapper.userId = associationRecord.PC_Associated_User__c;
            recordIdWorkCaseDistDetailsWrapper.caseId = associationRecord.PC_Program__c;
            recordIdWorkCaseDistDetailsWrapper.role = associationRecord.PC_Role__c;

            recordIdWorkCaseDistDetailsWrapperMap.put(associationRecord.Id, recordIdWorkCaseDistDetailsWrapper);
        }

        if (recordIdWorkCaseDistDetailsWrapperMap != null && !recordIdWorkCaseDistDetailsWrapperMap.isEmpty()) {
            associationsToBeCreated = returnAssociationsByProcessingWorkCaseDistribution(recordIdWorkCaseDistDetailsWrapperMap);
        }
        return associationsToBeCreated;
    }

    /**
     * This method is to process work case distribution and create Associate records
     * User-Story : PC-8436
     * @param recordIdWorkCaseDistDetailsWrapperMap - Map of case Id with case details wrapper
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
     * This method is used to fetch Zip Code details on creation of Association from Work Case Distribution table
     * User-Story : PC-4014
     * @param recordIdWorkCaseDistDetailsWrapperMap - Map of case Id with case details wrapper
     *
     * @return - Map of case Id with case details wrapper of zipcode value
     */
    public static Map<Id, PC_WorkCaseDistributionHelper.RecordIdWorkCaseDistDetailsWrapper> getWorkCaseDistributionDetails(Map<Id, PC_WorkCaseDistributionHelper.RecordIdWorkCaseDistDetailsWrapper> recordIdWorkCaseDistDetailsWrapperMap) {
        List<PC_WorkCaseDistributionConfig__c> workCaseDistributionConfigList = new List<PC_WorkCaseDistributionConfig__c>();
        Map<Id, Id> parentIdChildIdMap = new Map<Id, Id>();
        List<Id> engagementProgramIdList = new List<Id>();
        Map<Id, PC_WorkCaseDistributionConfig__c> associationWorkCaseDistRecordMap = new Map<Id, PC_WorkCaseDistributionConfig__c>();
        Map<Id, String> engProgIdAssignmentLookupFldMap = new Map<Id, String>();
        Set<String> zipCodeFieldNameOnAccountSet = new Set<String>();
        Set<String> zipCodeFieldNameOnUserSet = new Set<String>();
        String zipCodeFieldNameOnAccountString = PC_Constants.EMPTY_STRING;
        String zipCodeFieldNameOnUserString = PC_Constants.EMPTY_STRING;
        Set<Id> accountIdSet = new Set<Id>();
        Set<Id> userIdSet = new Set<Id>();
        Map<Id, String> recordIdZipCodeFieldNameMap = new Map<Id, String>();
        Map<Id, String> recordIdZipCodeMap = new Map<Id, String>();
        Map<Id, String> recordIdZipCodeForAccountMap = new Map<Id, String>();
        Map<Id, String> recordIdZipCodeForUserMap = new Map<Id, String>();

        /** Prepare a list of engagement programs and a map of association id to AccountId/ User Id, we would require 'caseIdAccountIdMap' to fill in the zip codes for
         * all association ids in 'recordIdWorkCaseDistDetailsWrapperMap' map **/
        for (Id recordId : recordIdWorkCaseDistDetailsWrapperMap.keySet()) {
            engagementProgramIdList.add(recordIdWorkCaseDistDetailsWrapperMap.get(recordId).engagementProgramId);

            if (recordIdWorkCaseDistDetailsWrapperMap.get(recordId).accountId != null) {
                parentIdChildIdMap.put(recordId, recordIdWorkCaseDistDetailsWrapperMap.get(recordId).accountId);
            } else if (recordIdWorkCaseDistDetailsWrapperMap.get(recordId).userId != null) {
                parentIdChildIdMap.put(recordId, recordIdWorkCaseDistDetailsWrapperMap.get(recordId).userId);
            }
        }

        if (engagementProgramIdList != null && !engagementProgramIdList.isEmpty()) {
            //FLS is NOT needed in Triggers, as they always run in System Mode.
            /** Fetch all PC_WorkCaseDistributionConfig__c records which have Assignment Type 'Association' **/
            workCaseDistributionConfigList = [
                    SELECT Id, PC_AssignmentLookupField__c, PC_EngagementProgram__c, PC_AssignmentType__c, PC_AssociationRole__c
                    FROM PC_WorkCaseDistributionConfig__c
                    WHERE PC_EngagementProgram__c IN:engagementProgramIdList AND PC_AssignmentType__c = :PC_Constants.PC_WCD_ASSOCIATION
            ];
        }

        if (workCaseDistributionConfigList != null && !workCaseDistributionConfigList.isEmpty()) {
            /** 1) associationWorkCaseDistRecordMap: Run through the WCD records and prepare a map of engagement program and WCD record of 'Association' assignment type
            *  2) engProgIdAssignmentLookupFldMap: Create a map of of engaement program and the corresponding zip code field name listed in the WCD record
            *  3) zipCodeFieldNameOnAccountSet: Set of all the zip code field names present on Account object
            *  4) zipCodeFieldNameOnUserSet: Set of all the zip code field names present on User object **/
            for (PC_WorkCaseDistributionConfig__c workCaseDistributionConfig : workCaseDistributionConfigList) {
                for (Id recordId : recordIdWorkCaseDistDetailsWrapperMap.keySet()) {

                    if (workCaseDistributionConfig.PC_AssociationRole__c == recordIdWorkCaseDistDetailsWrapperMap.get(recordId).role &&
                            (workCaseDistributionConfig.PC_EngagementProgram__c == recordIdWorkCaseDistDetailsWrapperMap.get(recordId).engagementProgramId)) {

                        associationWorkCaseDistRecordMap.put(workCaseDistributionConfig.PC_EngagementProgram__c, workCaseDistributionConfig);

                        if (!String.isBlank(workCaseDistributionConfig.PC_AssignmentLookupField__c)) {
                            String parentObjectName = workCaseDistributionConfig.PC_AssignmentLookupField__c.substringBefore('.');
                            String zipCodeFieldName = workCaseDistributionConfig.PC_AssignmentLookupField__c.substringAfter('.');
                            engProgIdAssignmentLookupFldMap.put(workCaseDistributionConfig.PC_EngagementProgram__c, zipCodeFieldName);

                            if (!String.isBlank(parentObjectName) && parentObjectName.equals(PC_Constants.PC_ACCOUNT)) {
                                zipCodeFieldNameOnAccountSet.add(zipCodeFieldName);
                            } else if (!String.isBlank(parentObjectName) && parentObjectName.equals(PC_Constants.PC_USER)) {
                                zipCodeFieldNameOnUserSet.add(zipCodeFieldName);
                            }
                        }
                    }
                }
            }

            if (associationWorkCaseDistRecordMap != null && !associationWorkCaseDistRecordMap.isEmpty()) {

                /* We would need to create a single string of comma separated 'Zip Code field names' so as we can include Patient Connect's fields and new custom fields
                 defined by clients for zip code **/
                /* For WCD record which have 'PC_AssignmentLookupField__c' value for 'Association' Assignment type and
                with Account's zip code field name in 'Assignment lookup field'*/
                zipCodeFieldNameOnAccountString = String.join(new List<String>(zipCodeFieldNameOnAccountSet), ',');

                /* For WCD record which have 'PC_AssignmentLookupField__c' value for 'Association' Assignment type and with User's zip code field and
                with User's zip code field name in 'Assignment lookup field'*/
                zipCodeFieldNameOnUserString = String.join(new List<String>(zipCodeFieldNameOnUserSet), ',');

                recordIdWorkCaseDistDetailsWrapperMap = PC_WorkCaseDistributionHelper.populateManufacturerIdForEngagementProg(engProgIdAssignmentLookupFldMap, recordIdWorkCaseDistDetailsWrapperMap);

                /** 1) We need a set of Account/User ids:'accountIdSet', 'userIdSet' and a map of Account/User ids and their zip code field names: 'recordIdZipCodeFieldNameMap'
                 *     in order to fetch their corresponding zip code values.
                    2) We need to check role as well in below condition since its possible that WCD has a record for the engagement program present in 'recordIdWorkCaseDistDetailsWrapperMap',
                       but that 'recordIdWorkCaseDistDetailsWrapperMap' record's role might be different than the one present in 'associationWorkCaseDistRecordMap' */
                for (Id recordId : recordIdWorkCaseDistDetailsWrapperMap.keySet()) {

                    if (associationWorkCaseDistRecordMap.containsKey(recordIdWorkCaseDistDetailsWrapperMap.get(recordId).engagementProgramId) &&
                            associationWorkCaseDistRecordMap.get(recordIdWorkCaseDistDetailsWrapperMap.get(recordId).engagementProgramId).PC_AssociationRole__c ==
                                    recordIdWorkCaseDistDetailsWrapperMap.get(recordId).role) {

                        if (recordIdWorkCaseDistDetailsWrapperMap.get(recordId).accountId != null) {
                            accountIdSet.add(recordIdWorkCaseDistDetailsWrapperMap.get(recordId).accountId);
                            recordIdZipCodeFieldNameMap.put(recordId, 'Account.'+engProgIdAssignmentLookupFldMap.get(recordIdWorkCaseDistDetailsWrapperMap.get(recordId).engagementProgramId));
                        } else if (recordIdWorkCaseDistDetailsWrapperMap.get(recordId).userId != null) {
                            userIdSet.add(recordIdWorkCaseDistDetailsWrapperMap.get(recordId).userId);
                            recordIdZipCodeFieldNameMap.put(recordId, engProgIdAssignmentLookupFldMap.get(recordIdWorkCaseDistDetailsWrapperMap.get(recordId).engagementProgramId));
                        }
                    }
                }

                /** Get zip code details from the zip code fields/fields listed on Account object **/
                if (!String.isBlank(zipCodeFieldNameOnAccountString)) {
                    recordIdZipCodeMap = PC_WorkCaseDistributionHelper.getZipCodeDetails(zipCodeFieldNameOnAccountString, PC_Constants.PC_ACCOUNT, accountIdSet, recordIdZipCodeFieldNameMap, parentIdChildIdMap, recordIdZipCodeMap);
                }

                /** Get zip code details from the zip code fields/fields listed on User object **/
                if (!String.isBlank(zipCodeFieldNameOnUserString)) {
                    recordIdZipCodeMap = PC_WorkCaseDistributionHelper.getZipCodeDetails(zipCodeFieldNameOnUserString, PC_Constants.PC_USER, userIdSet, recordIdZipCodeFieldNameMap, parentIdChildIdMap, recordIdZipCodeMap);
                }

                system.debug('recordIdZipCodeMap :::'+recordIdZipCodeMap);

                /** Populate the zip code values for all the association record ids which serve as key in main map:'recordIdWorkCaseDistDetailsWrapperMap' **/
                for (Id recordId : recordIdWorkCaseDistDetailsWrapperMap.keySet()) {
                    if (recordIdZipCodeMap.containsKey(recordId)) {
                        recordIdWorkCaseDistDetailsWrapperMap.get(recordId).zipCodeValue = recordIdZipCodeMap.get(recordId);
                    }
                }

            } else {
                /** PC-5033: Error handling scenarios **/
                List<String> listOfRoles = new List<String>();
                for (PC_WorkCaseDistributionConfig__c workCaseDistributionConfig : workCaseDistributionConfigList) {
                    listOfRoles.add(workCaseDistributionConfig.PC_AssociationRole__c);
                }
                String errorMessage = Label.PC_NoRolesFoundInWorkCaseDistForAssociation + listOfRoles;
                PC_WorkCaseDistributionHelper.PC_WorkCaseDistributionException workCaseDistException = new PC_WorkCaseDistributionHelper.PC_WorkCaseDistributionException();
                workCaseDistException.setMessage(errorMessage);
                throw workCaseDistException;
            }
        } else {
            /** PC-5033: Error handling scenarios **/
            String errorMessage = Label.PC_NoRecordsFoundInWorkCaseDistForAssociation;
            PC_WorkCaseDistributionHelper.PC_WorkCaseDistributionException workCaseDistException = new PC_WorkCaseDistributionHelper.PC_WorkCaseDistributionException();
            workCaseDistException.setMessage(errorMessage);
            throw workCaseDistException;
        }
        return recordIdWorkCaseDistDetailsWrapperMap;
    }
}