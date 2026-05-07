/*********************************************************************************************************
Class Name      : PC_WorkCaseRedistributionForUserHandler
Description     : trigger on Account object to process Work Case Redistribution
Created By      : Satheesh Kumar
Created Date    : April 06, 2022
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer                   Date                   	Description
--------------------------------------------------------------------------------------------------------------
Satheesh Kumar          April 06, 2022           Initial Version
****************************************************************************************************************/

public inherited sharing class PC_WorkCaseRedistributionForAccHandler extends PC_TriggerHandler {
    public static boolean isProcessed = false;
    public static Map<Id, PC_WorkCaseDistributionHelper.RecordIdWorkCaseDistDetailsWrapper> mapOfRecordIdWorkCaseDistDetailsWrapper = new Map<Id, PC_WorkCaseDistributionHelper.RecordIdWorkCaseDistDetailsWrapper>();

    override public void afterUpdate() {
        if (isProcessed == false) {
            system.debug('Trigger Handler ::: PC_WorkCaseRedistributionForAccHandler');
            processWorkCaseRedistributionForAccount((Map<Id, Account>) oldMap, (Map<Id, Account>) newMap);
        }
    }

    /**
     * This method is used to create Association records
     *
     * @param oldAccountMap - Map of Old Accounts
     * @param newAccountMap - Map of New Accounts
     */
    private static void processWorkCaseRedistributionForAccount(Map<Id, Account> oldAccountMap, Map<Id, Account> newAccountMap) {
        try {
            System.debug('Entered PC_WorkCaseRedistributionForAccHandler.processWorkCaseRedistributionForAccount');
            List<PC_Association__c> associationListToCreate = new List<PC_Association__c>();
            Map<Id, Account> updatedAddressAccountMap = new Map<Id, Account>();
            Map<Id, Account> updatedAddressOldAccountMap = new Map<Id, Account>();
            PC_WorkCaseDistributionHelper.WCDOutputWrapper wcdOutputWrapper = new PC_WorkCaseDistributionHelper.WCDOutputWrapper();
            String enableWorkCaseDistribution = PC_SYSTEM.getPatientConnectSetting(PC_Constants.PC_ENABLE_WORK_CASE_DISTRIBUTION, PC_Constants.FALSE_STRING);
            String enableWorkCaseRedistribution = PC_SYSTEM.getPatientConnectSetting(PC_Constants.PC_ENABLE_WORK_CASE_REDISTRIBUTION, PC_Constants.FALSE_STRING);
            String enableAsynchronousWorkCaseDistribution = PC_WorkCaseDistributionHelper.getWCDMode();
            if (Test.isRunningTest()) {
                enableWorkCaseDistribution = PC_Constants.TRUE_STRING;
                enableWorkCaseRedistribution = PC_Constants.TRUE_STRING;
            }

            if (!String.isBlank(enableWorkCaseDistribution) && !String.isBlank(enableWorkCaseRedistribution) && enableWorkCaseDistribution.equalsIgnoreCase(PC_Constants.TRUE_STRING) && enableWorkCaseRedistribution.equalsIgnoreCase(PC_Constants.TRUE_STRING)) {
                for (Id eachAccId : newAccountMap.keySet()) {
                    if (String.isNotBlank(newAccountMap.get(eachAccId).PC_Primary_Address__c) && newAccountMap.get(eachAccId).PC_Primary_Address__c != oldAccountMap.get(eachAccId).PC_Primary_Address__c) {
                        updatedAddressAccountMap.put(eachAccId, newAccountMap.get(eachAccId));
                        updatedAddressOldAccountMap.put(eachAccId, oldAccountMap.get(eachAccId));
                    }
                }

                if ((!String.isBlank(enableAsynchronousWorkCaseDistribution) && enableAsynchronousWorkCaseDistribution.equalsIgnoreCase(PC_Constants.FALSE_STRING)) || enableAsynchronousWorkCaseDistribution == null) {
                    associationListToCreate = getAssociationsToCreateOnAccountUpdate(updatedAddressAccountMap, updatedAddressOldAccountMap);
                    if (associationListToCreate != null && associationListToCreate.size() > 0 && !associationListToCreate.isEmpty()) {
                        if (associationListToCreate.size() > 200) {
                            isProcessed = true;
                            wcdOutputWrapper.associationListToCreate = associationListToCreate;
                            wcdOutputWrapper.recordIdWorkCaseDistDetailsWrapperMap = mapOfRecordIdWorkCaseDistDetailsWrapper;
                            wcdOutputWrapper.programRegionHistoryCreateList = PC_WorkCaseDistributionHelper.programRegionUserHistoryCreateList;
                            wcdOutputWrapper.programRegionHistoryDeleteList = PC_WorkCaseDistributionHelper.programRegionHistoryDeleteList;
                            PC_WorkCaseDistributionHelper.createAssociationsAsynchronously(wcdOutputWrapper, 'AccountHandler');
                        } else {
                            isProcessed = true;
                            PC_Database.ins(associationListToCreate, false);
                            PC_Database.del(PC_WorkCaseDistributionHelper.programRegionHistoryDeleteList, false);
                            PC_Database.ins(PC_WorkCaseDistributionHelper.programRegionUserHistoryCreateList, false);
                        }
                    }

                } else if (!String.isBlank(enableAsynchronousWorkCaseDistribution) && enableAsynchronousWorkCaseDistribution.equalsIgnoreCase(PC_Constants.TRUE_STRING)) {
                    associationListToCreate = getAssociationsToCreateOnAccountUpdate(updatedAddressAccountMap, updatedAddressOldAccountMap);
                    if (associationListToCreate != null && associationListToCreate.size() != 0 && !associationListToCreate.isEmpty()) {
                        isProcessed = true;
                        wcdOutputWrapper.associationListToCreate = associationListToCreate;
                        wcdOutputWrapper.recordIdWorkCaseDistDetailsWrapperMap = mapOfRecordIdWorkCaseDistDetailsWrapper;
                        wcdOutputWrapper.programRegionHistoryCreateList = PC_WorkCaseDistributionHelper.programRegionUserHistoryCreateList;
                        wcdOutputWrapper.programRegionHistoryDeleteList = PC_WorkCaseDistributionHelper.programRegionHistoryDeleteList;
                        PC_WorkCaseDistributionHelper.createAssociationsAsynchronously(wcdOutputWrapper, 'AccountHandler');
                    }
                } else if (!String.isBlank(enableAsynchronousWorkCaseDistribution) && !enableAsynchronousWorkCaseDistribution.equalsIgnoreCase(PC_Constants.TRUE_STRING)
                        && !enableAsynchronousWorkCaseDistribution.equalsIgnoreCase(PC_Constants.FALSE_STRING) && enableAsynchronousWorkCaseDistribution != null) {
                    for (Account newAccountRec : newAccountMap.values()) {
                        newAccountRec.addError(Label.PC_InvalidPatientConnectSetting);
                    }
                }
            }
        } catch (Exception ex) {
            PC_Utility.publishErrorLog(ex, ex.getMessage());
        }
    }

    public static List<PC_Association__c> getAssociationsToCreateOnAccountUpdate(Map<Id, Account> MapOfNewAccountsByIds, Map<Id, Account> MapOfOldAccountsByIds)
    {
        List<PC_Association__c> associationListToCreate = new List<PC_Association__c>();
        Set<Id> patientAccIds = new Set<Id>();
        Set<Id> associationAccIds = new Set<Id>();
        List<Case> programCaseList = new List<Case>();
        List<PC_Association__c> associationList = new List<PC_Association__c>();
        Map<Id, PC_WorkCaseDistributionHelper.RecordIdWorkCaseDistDetailsWrapper> recordIdWorkCaseDistDetailsWrapperMap = new Map<Id, PC_WorkCaseDistributionHelper.RecordIdWorkCaseDistDetailsWrapper>();
        Map<Id, PC_WorkCaseDistributionHelper.RecordIdWorkCaseDistDetailsWrapper> recordIdWorkCaseDistDetailsWrapperMap2 = new Map<Id, PC_WorkCaseDistributionHelper.RecordIdWorkCaseDistDetailsWrapper>();

        for (Id accountId : MapOfNewAccountsByIds.keySet()) {
            if (MapOfNewAccountsByIds.get(accountId).Type == PC_Constants.PATIENT_ACCOUNT_TYPE_VALUE) {
                patientAccIds.add(accountId);
            } else {
                associationAccIds.add(accountId);
            }
        }

        if(patientAccIds.size() > 0){
            /** Fetch all Program Case records which have Type 'Program' **/
            //FLS is NOT needed in Triggers, as they always run in System Mode.
            programCaseList = [Select Id, accountId, PC_Engagement_Program__c, Type from Case where AccountId IN:patientAccIds AND Type = :PC_Constants.CASE_PROGRAM_TYPE AND PC_Engagement_Program__c != NULL];

            if(programCaseList.size() > 0){
                recordIdWorkCaseDistDetailsWrapperMap = getWorkCaseDistributionDetailsForPatient(programCaseList);
            }
        }

        if (associationAccIds.size() > 0) {
            /** Fetch all association records for the accounts **/
            //FLS is NOT needed in Triggers, as they always run in System Mode.
            associationList = [
                    SELECT Id, PC_Role__c, PC_Program__c, PC_Program__r.PC_Engagement_Program__c, PC_Account__c, PC_Associated_User__c, PC_AssociationStatus__c
                    FROM PC_Association__c
                    WHERE PC_Account__c IN :associationAccIds and PC_AssociationStatus__c = :PC_Constants.ACTIVE and PC_Program__r.PC_Engagement_Program__c != NULL
            ];
            if (associationList.size() > 0) {
                recordIdWorkCaseDistDetailsWrapperMap2 = getWorkCaseDistributionDetailsForOtherRoles(associationList);
                recordIdWorkCaseDistDetailsWrapperMap.putAll(recordIdWorkCaseDistDetailsWrapperMap2);
            }
        }

        if (recordIdWorkCaseDistDetailsWrapperMap != null && !recordIdWorkCaseDistDetailsWrapperMap.isEmpty()) {
            associationListToCreate = returnAssociationsByProcessingWorkCaseRedistribution(recordIdWorkCaseDistDetailsWrapperMap);
        }
        if (associationListToCreate != null && associationListToCreate.size() > 0) {
            associationListToCreate = PC_WorkCaseDistributionHelper.removeAssociationIfAlreadyExists(associationListToCreate);
        }
        return associationListToCreate;
    }


    public static Map<Id, PC_WorkCaseDistributionHelper.RecordIdWorkCaseDistDetailsWrapper> getWorkCaseDistributionDetailsForPatient(List<Case> programCaseList) {
        Map<Id, Id> caseIdEngagementProgramIdMap = new Map<Id, Id>();
        Map<Id, PC_WorkCaseDistributionHelper.RecordIdWorkCaseDistDetailsWrapper> recordIdWorkCaseDistDetailsWrapperMap = new Map<Id, PC_WorkCaseDistributionHelper.RecordIdWorkCaseDistDetailsWrapper>();
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

        /** Prepare a Map where program case record ids act as keys and their engagement program record ids act as value,
        map of caseId to AccountId - we would require 'caseIdAccountIdMap' to fill in the zip codes for all cased ids in 'recordIdWorkCaseDistDetailsWrapperMap' map,
        list of engagement programs **/
        for (Case caseRec : programCaseList) {
            PC_WorkCaseDistributionHelper.RecordIdWorkCaseDistDetailsWrapper recordIdWorkCaseDistDetailsWrapper = new PC_WorkCaseDistributionHelper.RecordIdWorkCaseDistDetailsWrapper();
            recordIdWorkCaseDistDetailsWrapper.engagementProgramId = caseRec.PC_Engagement_Program__c;
            recordIdWorkCaseDistDetailsWrapper.accountId = caseRec.AccountId;
            recordIdWorkCaseDistDetailsWrapper.caseId = caseRec.Id;

            recordIdWorkCaseDistDetailsWrapperMap.put(caseRec.Id, recordIdWorkCaseDistDetailsWrapper);
            caseIdEngagementProgramIdMap.put(caseRec.Id, caseRec.PC_Engagement_Program__c);
            caseIdAccountIdMap.put(caseRec.Id, caseRec.AccountId);
            engagementProgramIdList.add(caseRec.PC_Engagement_Program__c);
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

    public static Map<Id, PC_WorkCaseDistributionHelper.RecordIdWorkCaseDistDetailsWrapper> getWorkCaseDistributionDetailsForOtherRoles(List<PC_Association__c> associationList) {
        Map<Id, PC_WorkCaseDistributionHelper.RecordIdWorkCaseDistDetailsWrapper> recordIdWorkCaseDistDetailsWrapperMap = new Map<Id, PC_WorkCaseDistributionHelper.RecordIdWorkCaseDistDetailsWrapper>();
        List<PC_WorkCaseDistributionConfig__c> workCaseDistributionConfigList = new List<PC_WorkCaseDistributionConfig__c>();
        Map<Id, Id> parentIdChildIdMap = new Map<Id, Id>();
        List<Id> engagementProgramIdList = new List<Id>();
        Map<Id, PC_WorkCaseDistributionConfig__c> associationWorkCaseDistRecordMap = new Map<Id, PC_WorkCaseDistributionConfig__c>();
        Map<Id, String> engProgIdAssignmentLookupFldMap = new Map<Id, String>();
        Set<String> zipCodeFieldNameOnAccountSet = new Set<String>();
        String zipCodeFieldNameOnAccountString = PC_Constants.EMPTY_STRING;
        Set<Id> accountIdSet = new Set<Id>();
        Map<Id, String> recordIdZipCodeFieldNameMap = new Map<Id, String>();
        Map<Id, String> recordIdZipCodeMap = new Map<Id, String>();
        Map<Id, String> recordIdZipCodeForAccountMap = new Map<Id, String>();

        for (PC_Association__c associationRecord : associationList) {
            PC_WorkCaseDistributionHelper.RecordIdWorkCaseDistDetailsWrapper recordIdWorkCaseDistDetailsWrapper = new PC_WorkCaseDistributionHelper.RecordIdWorkCaseDistDetailsWrapper();
            recordIdWorkCaseDistDetailsWrapper.engagementProgramId = associationRecord.PC_Program__r.PC_Engagement_Program__c;
            recordIdWorkCaseDistDetailsWrapper.accountId = associationRecord.PC_Account__c;
            recordIdWorkCaseDistDetailsWrapper.userId = associationRecord.PC_Associated_User__c;
            recordIdWorkCaseDistDetailsWrapper.caseId = associationRecord.PC_Program__c;
            recordIdWorkCaseDistDetailsWrapper.role = associationRecord.PC_Role__c;

            recordIdWorkCaseDistDetailsWrapperMap.put(associationRecord.Id, recordIdWorkCaseDistDetailsWrapper);

            engagementProgramIdList.add(associationRecord.PC_Program__r.PC_Engagement_Program__c);
            if (associationRecord.PC_Account__c != null) {
                parentIdChildIdMap.put(associationRecord.Id , associationRecord.PC_Account__c);
            }
        }

        if (engagementProgramIdList != null && !engagementProgramIdList.isEmpty()) {
            //FLS is NOT needed in Triggers, as they always run in System Mode.
            /** Fetch all PC_WorkCaseDistributionConfig__c records which have Assignment Type 'Association' **/
            workCaseDistributionConfigList = [
                    SELECT Id, PC_AssignmentLookupField__c, PC_EngagementProgram__c, PC_AssignmentType__c, PC_AssociationRole__c
                    FROM PC_WorkCaseDistributionConfig__c
                    WHERE PC_EngagementProgram__c IN:engagementProgramIdList AND PC_AssignmentType__c = :PC_Constants.PC_WCD_ASSOCIATION
                    AND PC_AssignmentLookupField__c LIKE 'Account.%'
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

                recordIdWorkCaseDistDetailsWrapperMap = PC_WorkCaseDistributionHelper.populateManufacturerIdForEngagementProg(engProgIdAssignmentLookupFldMap, recordIdWorkCaseDistDetailsWrapperMap);

                /** 1) We need a set of Account ids:'accountIdSet' and a map of Account ids and their zip code field names: 'recordIdZipCodeFieldNameMap'
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
                        }
                    }
                }

                /** Get zip code details from the zip code fields/fields listed on Account object **/
                if (!String.isBlank(zipCodeFieldNameOnAccountString)) {
                    recordIdZipCodeMap = PC_WorkCaseDistributionHelper.getZipCodeDetails(zipCodeFieldNameOnAccountString, PC_Constants.PC_ACCOUNT, accountIdSet, recordIdZipCodeFieldNameMap, parentIdChildIdMap, recordIdZipCodeMap);
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


    public static List<PC_Association__c> returnAssociationsByProcessingWorkCaseRedistribution(Map<Id, PC_WorkCaseDistributionHelper.RecordIdWorkCaseDistDetailsWrapper> recordIdWorkCaseDistDetailsWrapperMap) {
        List<PC_Association__c> careTeamAssociationList = new List<PC_Association__c>();
        recordIdWorkCaseDistDetailsWrapperMap = PC_WorkCaseDistributionHelper.getRegionZipCodeAndRegionDetails(recordIdWorkCaseDistDetailsWrapperMap);
        careTeamAssociationList = PC_WorkCaseDistributionHelper.getCareTeamAssociationRecords(recordIdWorkCaseDistDetailsWrapperMap);
        mapOfRecordIdWorkCaseDistDetailsWrapper = recordIdWorkCaseDistDetailsWrapperMap;
        return careTeamAssociationList;
    }
}