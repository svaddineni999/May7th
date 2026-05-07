/*********************************************************************************************************
Class Name      : PC_WorkCaseRedistributionForUserHandler
Description     : trigger on User object to process work case redistribution
Created By      : Satheesh Kumar
Created Date    : April 18, 2022
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer                   Date                   	Description
--------------------------------------------------------------------------------------------------------------
Satheesh Kumar          April 18, 2022           Initial Version
****************************************************************************************************************/

public inherited sharing class PC_WorkCaseRedistributionForUserHandler extends PC_TriggerHandler{
    public static boolean isProcessed = false;
    public static Map<Id, PC_WorkCaseDistributionHelper.RecordIdWorkCaseDistDetailsWrapper> mapOfRecordIdWorkCaseDistDetailsWrapper = new Map<Id, PC_WorkCaseDistributionHelper.RecordIdWorkCaseDistDetailsWrapper>();

    override public void afterUpdate() {
        if (isProcessed == false) {
            system.debug('Trigger Handler ::: PC_WorkCaseRedistributionForUserHandler');
            processWorkCaseRedistributionOnUserUpdate((Map<Id, User>) newMap, (Map<Id, User>) oldMap);
        }
    }

    private void processWorkCaseRedistributionOnUserUpdate(Map<Id, User> newUserMap, Map<Id, User> oldUserMap) {
        try {
            List<PC_Association__c> associationListToCreate = new List<PC_Association__c>();
            PC_WorkCaseDistributionHelper.WCDOutputWrapper wcdOutputWrapper = new PC_WorkCaseDistributionHelper.WCDOutputWrapper();
            String enableWorkCaseDistribution = PC_SYSTEM.getPatientConnectSetting(PC_Constants.PC_ENABLE_WORK_CASE_DISTRIBUTION, PC_Constants.FALSE_STRING);
            String enableWorkCaseRedistribution = PC_SYSTEM.getPatientConnectSetting(PC_Constants.PC_ENABLE_WORK_CASE_REDISTRIBUTION, PC_Constants.FALSE_STRING);
            String enableAsynchronousWorkCaseDistribution = PC_WorkCaseDistributionHelper.getWCDMode();
            if (Test.isRunningTest()) {
                enableWorkCaseDistribution = PC_Constants.TRUE_STRING;
                enableWorkCaseRedistribution = PC_Constants.TRUE_STRING;
            }

            if (!String.isBlank(enableWorkCaseDistribution) && !String.isBlank(enableWorkCaseRedistribution) && enableWorkCaseDistribution.equalsIgnoreCase(PC_Constants.TRUE_STRING) && enableWorkCaseRedistribution.equalsIgnoreCase(PC_Constants.TRUE_STRING)) {
                if ((!String.isBlank(enableAsynchronousWorkCaseDistribution) && enableAsynchronousWorkCaseDistribution.equalsIgnoreCase(PC_Constants.FALSE_STRING)) || enableAsynchronousWorkCaseDistribution == null) {
                    associationListToCreate = getAssociationsToCreateOnUserUpdate(newUserMap, oldUserMap);
                    if (associationListToCreate != null && associationListToCreate.size() > 0 && !associationListToCreate.isEmpty()) {
                        if (associationListToCreate.size() > 200) {
                            isProcessed = true;
                            wcdOutputWrapper.associationListToCreate = associationListToCreate;
                            wcdOutputWrapper.recordIdWorkCaseDistDetailsWrapperMap = mapOfRecordIdWorkCaseDistDetailsWrapper;
                            wcdOutputWrapper.programRegionHistoryCreateList = PC_WorkCaseDistributionHelper.programRegionUserHistoryCreateList;
                            wcdOutputWrapper.programRegionHistoryDeleteList = PC_WorkCaseDistributionHelper.programRegionHistoryDeleteList;
                            PC_WorkCaseDistributionHelper.createAssociationsAsynchronously(wcdOutputWrapper, 'UserHandler');
                        } else {
                            isProcessed = true;
                            PC_Database.ins(associationListToCreate, false);
                            PC_Database.del(PC_WorkCaseDistributionHelper.programRegionHistoryDeleteList, false);
                            PC_Database.ins(PC_WorkCaseDistributionHelper.programRegionUserHistoryCreateList, false);
                        }
                    }

                } else if (!String.isBlank(enableAsynchronousWorkCaseDistribution) && enableAsynchronousWorkCaseDistribution.equalsIgnoreCase(PC_Constants.TRUE_STRING)) {
                    associationListToCreate = getAssociationsToCreateOnUserUpdate(newUserMap, oldUserMap);
                    if (associationListToCreate != null && associationListToCreate.size() != 0 && !associationListToCreate.isEmpty()) {
                        isProcessed = true;
                        wcdOutputWrapper.associationListToCreate = associationListToCreate;
                        wcdOutputWrapper.recordIdWorkCaseDistDetailsWrapperMap = mapOfRecordIdWorkCaseDistDetailsWrapper;
                        wcdOutputWrapper.programRegionHistoryCreateList = PC_WorkCaseDistributionHelper.programRegionUserHistoryCreateList;
                        wcdOutputWrapper.programRegionHistoryDeleteList = PC_WorkCaseDistributionHelper.programRegionHistoryDeleteList;
                        PC_WorkCaseDistributionHelper.createAssociationsAsynchronously(wcdOutputWrapper, 'UserHandler');
                    }
                } else if (!String.isBlank(enableAsynchronousWorkCaseDistribution) && !enableAsynchronousWorkCaseDistribution.equalsIgnoreCase(PC_Constants.TRUE_STRING)
                        && !enableAsynchronousWorkCaseDistribution.equalsIgnoreCase(PC_Constants.FALSE_STRING) && enableAsynchronousWorkCaseDistribution != null) {
                    for (User newUserRec : newUserMap.values()) {
                        newUserRec.addError(Label.PC_InvalidPatientConnectSetting);
                    }
                }
            }
        } catch (Exception ex) {
            PC_Utility.publishErrorLog(ex, ex.getMessage());
        }
    }

    public static List<PC_Association__c> getAssociationsToCreateOnUserUpdate(Map<Id, User> newUserMap, Map<Id, User> oldUserMap)
    {
        List<PC_Association__c> associationListToCreate = new List<PC_Association__c>();
        Map<Id, User> updatedNewUserMap = new Map<Id, User>();
        Map<Id, User> updatedOldUserMap = new Map<Id, User>();
        Map<Id, Account> accountMap;
        Set<Id> associationAccIds = new Set<Id>();
        List<Case> programCaseList = new List<Case>();
        List<PC_Association__c> associationList = new List<PC_Association__c>();
        Map<Id, PC_WorkCaseDistributionHelper.RecordIdWorkCaseDistDetailsWrapper> recordIdWorkCaseDistDetailsWrapperMap = new Map<Id, PC_WorkCaseDistributionHelper.RecordIdWorkCaseDistDetailsWrapper>();

        /** Prepare a valid old address Map, new address map and account Id list**/
        for (Id eachUserId : newUserMap.keySet()) {
            if (newUserMap.get(eachUserId).IsActive == PC_Constants.TRUE_BOOLEAN && String.isNotBlank(newUserMap.get(eachUserId).PostalCode) && newUserMap.get(eachUserId).PostalCode != oldUserMap.get(eachUserId).PostalCode) {
                updatedNewUserMap.put(eachUserId, newUserMap.get(eachUserId));
                updatedOldUserMap.put(eachUserId, oldUserMap.get(eachUserId));
            }
        }

        if (!updatedNewUserMap.isEmpty()) {
            /** Fetch all association records for the accounts **/
            //FLS is NOT needed in Triggers, as they always run in System Mode.
            associationList = [
                    SELECT Id, PC_Role__c, PC_Program__c, PC_Program__r.PC_Engagement_Program__c, PC_Account__c, PC_Associated_User__c, PC_AssociationStatus__c
                    FROM PC_Association__c
                    WHERE PC_Associated_User__c IN :updatedNewUserMap.keySet() and PC_AssociationStatus__c = :PC_Constants.ACTIVE and PC_Program__r.PC_Engagement_Program__c != NULL
            ];
            if (associationList.size() > 0) {
                recordIdWorkCaseDistDetailsWrapperMap = getWorkCaseDistributionDetailsForUserRoles(associationList);
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

    public static Map<Id, PC_WorkCaseDistributionHelper.RecordIdWorkCaseDistDetailsWrapper> getWorkCaseDistributionDetailsForUserRoles(List<PC_Association__c> associationList) {
        Map<Id, PC_WorkCaseDistributionHelper.RecordIdWorkCaseDistDetailsWrapper> recordIdWorkCaseDistDetailsWrapperMap = new Map<Id, PC_WorkCaseDistributionHelper.RecordIdWorkCaseDistDetailsWrapper>();
        List<PC_WorkCaseDistributionConfig__c> workCaseDistributionConfigList = new List<PC_WorkCaseDistributionConfig__c>();
        Map<Id, Id> parentIdChildIdMap = new Map<Id, Id>();
        List<Id> engagementProgramIdList = new List<Id>();
        Map<Id, PC_WorkCaseDistributionConfig__c> associationWorkCaseDistRecordMap = new Map<Id, PC_WorkCaseDistributionConfig__c>();
        Map<Id, String> engProgIdAssignmentLookupFldMap = new Map<Id, String>();
        Set<String> zipCodeFieldNameOnUserSet = new Set<String>();
        String zipCodeFieldNameOnUserString = PC_Constants.EMPTY_STRING;
        Set<Id> userIdSet = new Set<Id>();
        Map<Id, String> recordIdZipCodeFieldNameMap = new Map<Id, String>();
        Map<Id, String> recordIdZipCodeMap = new Map<Id, String>();
        Map<Id, String> recordIdZipCodeForUserMap = new Map<Id, String>();

        for (PC_Association__c associationRecord : associationList) {
            PC_WorkCaseDistributionHelper.RecordIdWorkCaseDistDetailsWrapper recordIdWorkCaseDistDetailsWrapper = new PC_WorkCaseDistributionHelper.RecordIdWorkCaseDistDetailsWrapper();
            recordIdWorkCaseDistDetailsWrapper.engagementProgramId = associationRecord.PC_Program__r.PC_Engagement_Program__c;
            recordIdWorkCaseDistDetailsWrapper.accountId = associationRecord.PC_Account__c;
            recordIdWorkCaseDistDetailsWrapper.userId = associationRecord.PC_Associated_User__c;
            recordIdWorkCaseDistDetailsWrapper.caseId = associationRecord.PC_Program__c;
            recordIdWorkCaseDistDetailsWrapper.role = associationRecord.PC_Role__c;

            recordIdWorkCaseDistDetailsWrapperMap.put(associationRecord.Id, recordIdWorkCaseDistDetailsWrapper);

            engagementProgramIdList.add(associationRecord.PC_Program__r.PC_Engagement_Program__c);
            if (associationRecord.PC_Associated_User__c != null) {
                parentIdChildIdMap.put(associationRecord.Id , associationRecord.PC_Associated_User__c);
            }
        }

        if (engagementProgramIdList != null && !engagementProgramIdList.isEmpty()) {
            //FLS is NOT needed in Triggers, as they always run in System Mode.
            /** Fetch all PC_WorkCaseDistributionConfig__c records which have Assignment Type 'Association' **/
            workCaseDistributionConfigList = [
                    SELECT Id, PC_AssignmentLookupField__c, PC_EngagementProgram__c, PC_AssignmentType__c, PC_AssociationRole__c
                    FROM PC_WorkCaseDistributionConfig__c
                    WHERE PC_EngagementProgram__c IN:engagementProgramIdList AND PC_AssignmentType__c = :PC_Constants.PC_WCD_ASSOCIATION
                    AND PC_AssignmentLookupField__c LIKE 'User.%'
            ];
        }

        system.debug('workCaseDistributionConfigList----'+workCaseDistributionConfigList);

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

                            if (!String.isBlank(parentObjectName) && parentObjectName.equals(PC_Constants.PC_USER)) {
                                zipCodeFieldNameOnUserSet.add(zipCodeFieldName);
                            }
                        }
                    }
                }
            }

            system.debug('associationWorkCaseDistRecordMap----'+associationWorkCaseDistRecordMap);

            if (associationWorkCaseDistRecordMap != null && !associationWorkCaseDistRecordMap.isEmpty()) {
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

                        if (recordIdWorkCaseDistDetailsWrapperMap.get(recordId).userId != null) {
                            userIdSet.add(recordIdWorkCaseDistDetailsWrapperMap.get(recordId).userId);
                            recordIdZipCodeFieldNameMap.put(recordId, engProgIdAssignmentLookupFldMap.get(recordIdWorkCaseDistDetailsWrapperMap.get(recordId).engagementProgramId));
                        }
                    }
                }

                /** Get zip code details from the zip code fields/fields listed on User object **/
                if (!String.isBlank(zipCodeFieldNameOnUserString)) {
                    recordIdZipCodeMap = PC_WorkCaseDistributionHelper.getZipCodeDetails(zipCodeFieldNameOnUserString, PC_Constants.PC_USER, userIdSet, recordIdZipCodeFieldNameMap, parentIdChildIdMap, recordIdZipCodeMap);
                }

                system.debug('recordIdZipCodeMap ::: '+recordIdZipCodeMap);

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