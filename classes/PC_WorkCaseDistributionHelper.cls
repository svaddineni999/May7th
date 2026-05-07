/*********************************************************************************************************
Class Name      : PC_WorkCaseDistributionHelper
Description     : Helper class to process work case distribution
Created By      : Hitha Avalakki
Created Date    : July 03, 2019
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer                   Date                   	Description
--------------------------------------------------------------------------------------------------------------
Hitha Avalakki            	July 03, 2019           Initial Version
Hitha Avalakki              July 10, 2019           PC-5032: Added error handling scenarios for Work Case Distribution logic
Vijay Kashikar              21-Jan-21               [PC-7102] Added sharing clause
Satheesh Kumar              04-May-21               [PC-8670] Added isActive condition to the engagement program setting query to get only active settings
****************************************************************************************************************/
public with sharing class PC_WorkCaseDistributionHelper {

    public static String testRunModeIsAsynchronous;
    public enum Handlers {CaseHandler, AssociationHandler, AccountHandler, AddressHandler, UserHandler}
    public static final String DEFAULT_SETTING_VALUE = '{"defaultclass": "PC_WCDDefaultService"}';
    public static List<PC_ProgramRegionUserHistory__c> programRegionUserHistoryCreateList = new List<PC_ProgramRegionUserHistory__c>();
    public static List<PC_ProgramRegionUserHistory__c> programRegionHistoryDeleteList = new List<PC_ProgramRegionUserHistory__c>();
    public static Map<Id, List<String>> rolesByRegionMap = new Map<Id, List<String>>();
    /*********************************************************************************
    Method Name    : getRegionZipCodeAndRegionDetails
    Author         : Hitha Avalakki
    Description    : This method is used to fetch 'Region Zip Code' and 'Region' details
    Return Type    : Map<Id, RecordIdWorkCaseDistDetailsWrapper>
    Parameter      : Map<Id, RecordIdWorkCaseDistDetailsWrapper>
    User-Story     : PC-4014
    *********************************************************************************/
    public static Map<Id, RecordIdWorkCaseDistDetailsWrapper> getRegionZipCodeAndRegionDetails(Map<Id, RecordIdWorkCaseDistDetailsWrapper> recordIdWorkCaseDistDetailsWrapperMap) {
        Map<Id, Set<String>> regionIdSetOfZipCodeMap = new Map<Id, Set<String>>();
        Map<Id, Id> regionIdManufacturerIdMap = new Map<Id, Id>();
        Set<Id> regionIdsSet;
        List<String> zipCodeValueList = new List<String>();
        List<PC_Region__c> regionRecordList = new List<PC_Region__c>();

        /** Prepare a list of zip code values **/
        for (Id caseId : recordIdWorkCaseDistDetailsWrapperMap.keySet()) {
            zipCodeValueList.add(recordIdWorkCaseDistDetailsWrapperMap.get(caseId).zipCodeValue);
        }

        if (zipCodeValueList != null && !zipCodeValueList.isEmpty()) {
            /** Fetch details from PC_RegionZipCode__c table for all zipcode values **/
            List<PC_RegionZipCode__c> regionZipCodeList = [
                    SELECT Id, PC_Region__c, PC_ZipCode__c
                    FROM PC_RegionZipCode__c
                    WHERE PC_ZipCode__c IN:zipCodeValueList
            ];

            if (regionZipCodeList != null && !regionZipCodeList.isEmpty()) {
                /** As one zip code can be associated with multiple region ids, we prepare a map consisting of entries where
                * region id acts as key and a Set of zip codes act as value **/
                for (PC_RegionZipCode__c regionZipCode : regionZipCodeList) {
                    if (!regionIdSetOfZipCodeMap.containsKey(regionZipCode.PC_Region__c)) {
                        Set<String> zipCodeSet = new Set<String>();
                        zipCodeSet.add(regionZipCode.PC_ZipCode__c);
                        regionIdSetOfZipCodeMap.put(regionZipCode.PC_Region__c, zipCodeSet);
                    } else {
                        Set<String> existingZipCodeSet = regionIdSetOfZipCodeMap.get(regionZipCode.PC_Region__c);
                        existingZipCodeSet.add(regionZipCode.PC_ZipCode__c);
                        regionIdSetOfZipCodeMap.put(regionZipCode.PC_Region__c, existingZipCodeSet);
                    }
                }
            } else {
                /** PC-5032: Error handling scenarios **/
                PC_WorkCaseDistributionException workCaseDistributionException = new PC_WorkCaseDistributionException();
                workCaseDistributionException.setMessage(Label.PC_NoRecordsFoundInRegionZipCode + zipCodeValueList);
                throw workCaseDistributionException;
            }
        }

        if (regionIdSetOfZipCodeMap != null && !regionIdSetOfZipCodeMap.isEmpty()) {

            /** Fetch the region ids and its corresponding manufacturer id values **/
            //FLS check is not needed since the code runs in trigger context mode
            regionRecordList = [
                    SELECT Id, PC_Manufacturer__c, PC_EffectiveFromTime__c, PC_EffectiveToTime__c
                    FROM PC_Region__c
                    WHERE Id IN:regionIdSetOfZipCodeMap.keySet() AND PC_Active__c = true
            ];
            if (regionRecordList != null && !regionRecordList.isEmpty()) {

                /** Prepare a map of region ids as keys and its corresponding manufacturer ids as values **/
                for (PC_Region__c region : regionRecordList) {

                    /** Following condition is required to check if the Region id is active for current time frame **/
                    if ((region.PC_EffectiveFromTime__c == null && region.PC_EffectiveToTime__c == null) ||
                            (region.PC_EffectiveFromTime__c == null && System.now() <= region.PC_EffectiveToTime__c) ||
                            (region.PC_EffectiveToTime__c == null && System.now() >= region.PC_EffectiveFromTime__c) ||
                            (System.now() >= region.PC_EffectiveFromTime__c && System.now() <= region.PC_EffectiveToTime__c)) {
                        regionIdManufacturerIdMap.put(region.Id, region.PC_Manufacturer__c);
                    }
                }

                /** Here we try to find if the main wrapper: recordIdWorkCaseDistDetailsWrapperMap's zip code value is present
                * in the set of zip code values of 'regionIdSetOfZipCodeMap' map for any region record id. If the zip code value is
                * present then we fetch the manufacturer id from 'regionIdManufacturerIdMap' and try to match it with the manufacturer id
                * in the main wrapper:recordIdWorkCaseDistDetailsWrapperMap's manufacturer id. If it matches, then we populate the region record id in
                 * main wrapper: 'recordIdWorkCaseDistDetailsWrapperMap' **/
                for (Id recordId : recordIdWorkCaseDistDetailsWrapperMap.keySet()) {
                    String zipCodeValue = recordIdWorkCaseDistDetailsWrapperMap.get(recordId).zipCodeValue;
                    regionIdsSet = new Set<Id>();
                    for (Id regionId : regionIdSetOfZipCodeMap.keySet()) {

                        if (regionIdSetOfZipCodeMap.get(regionId).contains(zipCodeValue)) {

                            if (regionIdManufacturerIdMap.get(regionId) == recordIdWorkCaseDistDetailsWrapperMap.get(recordId).manufacturerId) {
                                recordIdWorkCaseDistDetailsWrapperMap.get(recordId).regionId = regionId;
                                regionIdsSet.add(regionId);
                            }
                        }
                    }
                    recordIdWorkCaseDistDetailsWrapperMap.get(recordId).regionIdSet = regionIdsSet;
                }

            } else {
                /** PC-5032: Error handling scenarios **/
                PC_WorkCaseDistributionException workCaseDistributionException = new PC_WorkCaseDistributionException();
                workCaseDistributionException.setMessage(Label.PC_InActiveRegion + regionIdSetOfZipCodeMap.keySet());
                throw workCaseDistributionException;
            }
        }
        return recordIdWorkCaseDistDetailsWrapperMap;
    }

    /**
     * This method is used to verify if the class name(parameter) is implementing interface PC_WCD
     * User-Story     : PC-8163
     * @param serviceClassName - Its the class name
     *
     * @return This will return Boolean
     */
    public static Boolean isServiceClassValid(String serviceClassName) {

        Type t = Type.forName(serviceClassName);
        if (t != null) {
            Object o = t.newInstance();
            if (o instanceof PC_WCD.UserMappingFinder) {
                return true;
            } else {
                return false;
            }
        }
        return false;
    }

    /**
     * This method is used to return Setting value from patient connect setting 'Enable Async Work Case Distribution' or to return true/false for test class
     * User-Story: PC-8503
     * @return String
     */
    public static String getWCDMode(){
        if(Test.isRunningTest()){
            return testRunModeIsAsynchronous;
        }

        return PC_SYSTEM.getPatientConnectSetting(PC_Constants.PC_ENABLE_ASYNCHRONOUS_WORK_CASE_DISTRIBUTION, PC_Constants.FALSE_STRING);
    }

    /**
     * This method is used to fetch details from Program Region User Mapping table and create Association records using the details
     * User-Story : PC-4014
     * @param recordIdWorkCaseDistDetailsWrapperMap - This is a map of case Id and case details wrapper
     *
     * @return List of Associations
     */
    public static List<PC_Association__c> getCareTeamAssociationRecords(Map<Id, RecordIdWorkCaseDistDetailsWrapper> recordIdWorkCaseDistDetailsWrapperMap) {
        Set<Id> regionIdSet;
        Set<String> careTeamRoles;
        Set<Id> engagementProgramIdsToGetCustomMetadata;
        List<PC_ProgramRegionUserMapping__c> activeProgramRegionUserMappingList;
        List<PC_Association__c> careTeamAssociationList;
        List<PC_ProgramRegionUserMapping__c> programRegionUserMappingsList;
        List<PC_EngagementProgram__mdt> engagmentProgramMetaData;
        List<PC_Engagement_Program__c> engagementProgramsList;
        Set<PC_ProgramRegionUserMapping__c> programRegionUserMappingsSet;
        List<PC_ProgramRegionUserHistory__c> engagementProgramHistories;
        Map<Id, PC_WCD.caseDetails> caseIdMappingWithCaseDetails;
        Map<Id, String> engagementProgramIdWithCode;
        Map<Id, List<PC_ProgramRegionUserMapping__c>> engagementProgramIdWithProgramRegionsList;
        String settingValue;

        /** Prepare a list of region record ids from main wrapper object:recordIdWorkCaseDistDetailsWrapperMap  **/
        regionIdSet = new Set<Id>();
        caseIdMappingWithCaseDetails = new Map<Id, PC_WCD.caseDetails>();

        for (Id recordId : recordIdWorkCaseDistDetailsWrapperMap.keySet()) {
            regionIdSet.addAll(recordIdWorkCaseDistDetailsWrapperMap.get(recordId).regionIdSet);
            PC_WCD.caseDetails caseDetailRecord = new PC_WCD.caseDetails();
            caseDetailRecord.caseId = recordIdWorkCaseDistDetailsWrapperMap.get(recordId).caseId;
            caseDetailRecord.engagementProgramId = recordIdWorkCaseDistDetailsWrapperMap.get(recordId).engagementProgramId;
            caseDetailRecord.regionId = recordIdWorkCaseDistDetailsWrapperMap.get(recordId).regionId;
            caseDetailRecord.regionSetId = recordIdWorkCaseDistDetailsWrapperMap.get(recordId).regionIdSet;
            caseIdMappingWithCaseDetails.put(recordId, caseDetailRecord);
        }

        activeProgramRegionUserMappingList = new List<PC_ProgramRegionUserMapping__c>();

        if (regionIdSet != null && !regionIdSet.isEmpty()) {
            /** Fetch all the PC_ProgramRegionUserMapping__c records which match the regionIdSet prepare above **/
            //FLS check is not needed since the code runs in trigger context mode
            activeProgramRegionUserMappingList = [
                    SELECT Id, Name, PC_Region__c, PC_CareTeamMember__c, PC_CareTeamRole__c, PC_EngagementProgram__c,
                            PC_EngagementProgram__r.Name, PC_EngagementProgram__r.PC_Program_Code__c, PC_StartDateTime__c,
                            PC_EndDateTime__c, PC_Ordinal__c, PC_CareTeamAccount__c, LastModifiedDate
                    FROM PC_ProgramRegionUserMapping__c
                    WHERE PC_Region__c IN:regionIdSet AND
                    ((PC_CareTeamMember__c != NULL AND PC_CareTeamMember__r.IsActive = TRUE) OR (PC_CareTeamMember__c = NULL AND PC_CareTeamAccount__c != NULL))
                    ORDER BY PC_EngagementProgram__c ASC, PC_CareTeamRole__c ASC NULLS LAST, PC_Region__c ASC, PC_Ordinal__c ASC NULLS LAST, LastModifiedDate DESC
            ];
            careTeamAssociationList = new List<PC_Association__c>();

            if (activeProgramRegionUserMappingList != null && !activeProgramRegionUserMappingList.isEmpty()) {

                /** Run through the retrieved PRUM records and compare if any PRUM record has a matching region id and engagement program id with any
                  * of main wrapper:recordIdWorkCaseDistDetailsWrapperMap records. If there is a match, create association record using details from
                  * the main wrapper:recordIdWorkCaseDistDetailsWrapperMap**/
                careTeamRoles = new Set<String>();
                engagementProgramIdsToGetCustomMetadata = new Set<Id>();
                engagementProgramIdWithCode = new Map<Id, String>();
                engagementProgramIdWithProgramRegionsList = new Map<Id, List<PC_ProgramRegionUserMapping__c>>();
                programRegionUserMappingsSet = new Set<PC_ProgramRegionUserMapping__c>();
                programRegionUserMappingsList = new List<PC_ProgramRegionUserMapping__c>();
                engagementProgramsList = new List<PC_Engagement_Program__c>();

                settingValue = getWCDClassName();
                for (Id recordId : recordIdWorkCaseDistDetailsWrapperMap.keySet()) {
                    for (Id regionId : recordIdWorkCaseDistDetailsWrapperMap.get(recordId).regionIdSet) {
                        for (PC_ProgramRegionUserMapping__c progRegionUserMappingRecord : activeProgramRegionUserMappingList) {
                            if (regionId == progRegionUserMappingRecord.PC_Region__c &&
                                    recordIdWorkCaseDistDetailsWrapperMap.get(recordId).engagementProgramId == progRegionUserMappingRecord.PC_EngagementProgram__c) {

                                if ((progRegionUserMappingRecord.PC_StartDateTime__c == null && progRegionUserMappingRecord.PC_EndDateTime__c == null) ||
                                        (progRegionUserMappingRecord.PC_StartDateTime__c == null && System.now() <= progRegionUserMappingRecord.PC_EndDateTime__c) ||
                                        (progRegionUserMappingRecord.PC_EndDateTime__c == null && System.now() >= progRegionUserMappingRecord.PC_StartDateTime__c) ||
                                        (System.now() >= progRegionUserMappingRecord.PC_StartDateTime__c && System.now() <= progRegionUserMappingRecord.PC_EndDateTime__c)) {

                                    engagementProgramIdsToGetCustomMetadata.add(progRegionUserMappingRecord.PC_EngagementProgram__c);
                                    programRegionUserMappingsSet.add(progRegionUserMappingRecord);
                                    careTeamRoles.add(progRegionUserMappingRecord.PC_CareTeamRole__c);
                                }
                            }
                        }
                    }
                }
                //FLS check is not needed since the code runs in trigger context mode
                engagementProgramsList = [SELECT Id,Name,PC_Program_Code__c from PC_Engagement_Program__c WHERE Id IN:engagementProgramIdsToGetCustomMetadata];
                for (PC_Engagement_Program__c engagementprogram : engagementProgramsList) {
                    engagementProgramIdWithCode.put(engagementprogram.Id, engagementprogram.PC_Program_Code__c);
                }

                if (!programRegionUserMappingsSet.isEmpty()) {
                    programRegionUserMappingsList.addAll(programRegionUserMappingsSet);
                }

                //logic to set map with engagement program id as key and related list of program region user mapping records as value
                engagementProgramIdWithProgramRegionsList = getMapOfEngagementProgramWithProgramRegionUserMappings(programRegionUserMappingsList, engagementProgramIdWithCode.keySet(), engagementProgramIdWithProgramRegionsList);
                //fetch program region history records
                engagementProgramHistories = new List<PC_ProgramRegionUserHistory__c>();
                engagementProgramHistories = queryProgramRegionHistories(engagementProgramIdWithCode.keySet(), careTeamRoles, regionIdSet);
                careTeamAssociationList = getAssociations(settingValue, engagementProgramIdWithProgramRegionsList, engagementProgramIdWithCode, engagementProgramHistories, caseIdMappingWithCaseDetails, recordIdWorkCaseDistDetailsWrapperMap, regionIdSet);

            }
        }
        return careTeamAssociationList;
    }

    /**
     * This method is used to get the Setting Value from custom metadata record 'PC_WCDServiceClassName' of Patient Connect Settings
     * User-Story     : PC-8163
     *
     * @return - This will return setting value in form of a string
     */
    private static String getWCDClassName(){
        if(Test.isRunningTest()){
            return '{"defaultclass": "PC_WCDRoundRobinService"}';
        }

        return PC_SYSTEM.getPatientConnectSetting(PC_Constants.PC_WCD_SERVICE_CLASS_NAME, DEFAULT_SETTING_VALUE);
    }

    /**
     * This method is used to map the engagement program ids with their related program region user mapping records
     * User-Story : PC-8232
     * @param listOfProgramRegionUserMappings - List of program region user mapping records
     * @param engagementProgramIds - Set of engagement program Ids
     * @param engagementProgramIdWithProgramRegionsList - Map of engagement program id with list of program region user mapping records
     *
     * @return Map of engagement program id with list of program region user mapping records
     */
    private static Map<Id, List<PC_ProgramRegionUserMapping__c>> getMapOfEngagementProgramWithProgramRegionUserMappings(List<PC_ProgramRegionUserMapping__c> listOfProgramRegionUserMappings, Set<Id> engagementProgramIds, Map<Id, List<PC_ProgramRegionUserMapping__c>> engagementProgramIdWithProgramRegionsList) {

        List<PC_ProgramRegionUserMapping__c> programRegionUserMappingsList = new List<PC_ProgramRegionUserMapping__c>();
        if(listOfProgramRegionUserMappings.size() > 0 && !listOfProgramRegionUserMappings.isEmpty()){
            programRegionUserMappingsList.addAll(listOfProgramRegionUserMappings);
        }

        if (programRegionUserMappingsList.size() > 0 && !programRegionUserMappingsList.isEmpty()) {
            for (Id engagementprogramid : engagementProgramIds) {
                for (PC_ProgramRegionUserMapping__c programregionrecord : programRegionUserMappingsList) {
                    if (engagementprogramid == programregionrecord.PC_EngagementProgram__c) {
                        if (engagementProgramIdWithProgramRegionsList.containsKey(engagementprogramid)) {
                            List<PC_ProgramRegionUserMapping__c> programRegionsList = engagementProgramIdWithProgramRegionsList.get(engagementprogramid);
                            programRegionsList.add(programregionrecord);
                            engagementProgramIdWithProgramRegionsList.put(engagementprogramid, programRegionsList);
                        } else {
                            List<PC_ProgramRegionUserMapping__c> programRegionRecordsList = new List<PC_ProgramRegionUserMapping__c>();
                            programRegionRecordsList.add(programregionrecord);
                            engagementProgramIdWithProgramRegionsList.put(engagementprogramid, programRegionRecordsList);
                        }
                    }
                }
            }
        }

        return engagementProgramIdWithProgramRegionsList;
    }

    /**
     * This method is used to query the program region user mapping history records
     * User-Story : PC-8232
     * @param engagementProgramIds - Set of engagement program Ids
     * @param careTeamRoles - Set of roles
     * @param regionIdSet - Set of regions
     *
     * @return - List of program region user mapping history records
     */
    private static List<PC_ProgramRegionUserHistory__c> queryProgramRegionHistories(Set<Id> engagementProgramIds, Set<String> careTeamRoles, Set<Id> regionIdSet) {
        List<PC_ProgramRegionUserHistory__c> programRegionUserHistories = new List<PC_ProgramRegionUserHistory__c>();
        //FLS check is not needed since the code runs in trigger context mode
        programRegionUserHistories = [
                SELECT Id,Name,CreatedDate, PC_Case__c, PC_CareTeamUser__c,PC_EngagementProgram__c,PC_CareTeamRole__c,PC_Region__c,LastModifiedDate,PC_CareTeamAccount__c
                FROM PC_ProgramRegionUserHistory__c
                WHERE PC_EngagementProgram__c IN:engagementProgramIds AND PC_CareTeamRole__c IN:careTeamRoles AND PC_Region__c IN:regionIdSet
                ORDER BY LastModifiedDate DESC
        ];

        return programRegionUserHistories;
    }

    /**
     * This method is used to fetch the associations using custom logic per engagement programs
     * User-Story  : PC-8232
     * @param settingValue - Setting value of custom metadata PC_WCDServiceClassName from Patient Connect Settings
     * @param engagementProgramIdWithProgramRegionsList - Map of engagement program Id with related list of program region user mapping records
     * @param engagementProgramIdWithCode - Map of engagement program Id with correspond program code
     * @param engagementProgramHistories - List of program region user mapping history records
     * @param caseIdMappingWithCaseDetails - Map of case Id and PC_WCD.caseDetails
     * @param recordIdWorkCaseDistDetailsWrapperMap - Map of case Id and case details wrapper
     * @param regionIdSet - Set of region Id
     *
     * @return - List of Associations
     */
    private static List<PC_Association__c> getAssociations(String settingValue, Map<Id, List<PC_ProgramRegionUserMapping__c>> engagementProgramIdWithProgramRegionsList, Map<Id, String> engagementProgramIdWithCode, List<PC_ProgramRegionUserHistory__c> engagementProgramHistories, Map<Id, PC_WCD.caseDetails> caseIdMappingWithCaseDetails, Map<Id, RecordIdWorkCaseDistDetailsWrapper> recordIdWorkCaseDistDetailsWrapperMap, Set<Id> regionIdSet) {
        List<PC_Association__c> associationsToBeCreated = new List<PC_Association__c>();
        String defaultClassName = '';
        String serviceClassName;
        String settingname;
        Set<String> allClasses = new Set<String>();
        List<Id> engagementProgramsWithDefaultSetting = new List<Id>();
        Map<String, Set<String>> mapOfClassesAndRoles = new Map<String, Set<String>>();
        Map<String, Set<Id>> classesMapWithEngagementPrograms = new Map<String, Set<Id>>();
        Map<Id, List<PC_ProgramRegionUserMapping__c>> casesMapWithProgramRegionUserMappings = new Map<Id, List<PC_ProgramRegionUserMapping__c>>();
        classesMapWithEngagementProgramsWrapper classMappingWrapper = new classesMapWithEngagementProgramsWrapper();
        classesMapWithEngagementProgramsWrapper classMappingWrapper2 = new classesMapWithEngagementProgramsWrapper();
        classesMapWithEngagementProgramsWrapper classMappingWrapper3 = new classesMapWithEngagementProgramsWrapper();
        Map<String, PC_EngagementProgramSetting__mdt> programCodeWithMetadata = new Map<String, PC_EngagementProgramSetting__mdt>();

        List<PC_EngagementProgramSetting__mdt> engagementProgramsMetadataList = [
                SELECT ID, PC_EngagementProgram__c, PC_EngagementProgram__r.PC_EngagementProgramCode__c, PC_SettingValue__c
                FROM PC_EngagementProgramSetting__mdt
                WHERE PC_PatientConnectSetting__r.PC_Active__c = TRUE AND PC_PatientConnectSetting__r.PC_IsOverridable__c = TRUE AND PC_PatientConnectSetting__r.PC_SettingName__c = :PC_Constants.PC_WCD_SERVICE_CLASS_NAME
                AND PC_EngagementProgram__r.PC_IsActive__c = TRUE AND PC_IsActive__c = TRUE
        ];
        if (!engagementProgramsMetadataList.isEmpty()) {
            for (PC_EngagementProgramSetting__mdt pgm : engagementProgramsMetadataList) {
                String code = pgm.PC_EngagementProgram__r.PC_EngagementProgramCode__c;
                programCodeWithMetadata.put(code, pgm);
            }
        }
        if(Test.isRunningTest()){
            String code = 'EPTest';
            String valueOfSetting = '{"defaultclass": "PC_WCDDefaultService"}';
            PC_EngagementProgramSetting__mdt epSetting = new PC_EngagementProgramSetting__mdt();
            epSetting.PC_SettingValue__c = valueOfSetting;
            programCodeWithMetadata.put(code,epSetting);
        }

        classMappingWrapper = getWrapperOfClassesAndEngagementPrograms(engagementProgramIdWithCode, programCodeWithMetadata, engagementProgramIdWithProgramRegionsList);
        Map<String, Set<Id>> mapOfClassesWithEngagementPrograms = classMappingWrapper.classesMappingWithEngagementPrograms;
        List<Id> engagementProgramsListWithDefaultSetting = classMappingWrapper.engagementProgramIdsWithDefaultSetting;
        Map<String, Set<String>> mappingOfClassesAndRoles = classMappingWrapper.classesMappingWithRole;

        engagementProgramsWithDefaultSetting.addAll(engagementProgramsListWithDefaultSetting);
        if (!engagementProgramsWithDefaultSetting.isEmpty()) {
            classMappingWrapper2 = getWrapperofClassesWithDefaultSettingEngagementPrograms(settingValue, engagementProgramsListWithDefaultSetting, mappingOfClassesAndRoles, engagementProgramIdWithProgramRegionsList, mapOfClassesWithEngagementPrograms);
            classesMapWithEngagementPrograms = classMappingWrapper2.classesMappingWithEngagementPrograms;
            engagementProgramsWithDefaultSetting = classMappingWrapper2.engagementProgramIdsWithDefaultSetting;
            mapOfClassesAndRoles = classMappingWrapper2.classesMappingWithRole;
        } else {
            classesMapWithEngagementPrograms = classMappingWrapper.classesMappingWithEngagementPrograms;
            mapOfClassesAndRoles = classMappingWrapper.classesMappingWithRole;
        }

        allClasses.addAll(classesMapWithEngagementPrograms.keySet());
        casesMapWithProgramRegionUserMappings = getMapOfCasesWithProgramRegionUserMappingRecords(allClasses, mapOfClassesAndRoles, classesMapWithEngagementPrograms, engagementProgramIdWithProgramRegionsList, engagementProgramHistories, caseIdMappingWithCaseDetails, recordIdWorkCaseDistDetailsWrapperMap, regionIdSet);
        List<PC_Association__c> associationsListToCreate = getAssociationsToCreate(engagementProgramHistories, casesMapWithProgramRegionUserMappings, recordIdWorkCaseDistDetailsWrapperMap, regionIdSet);
        associationsToBeCreated.addAll(associationsListToCreate);

        return associationsToBeCreated;
    }

    /**
     * This method is used to map the classes with respective engagement programs
     * User-Story : PC-8436
     * @param engagementProgramIdWithCode - Map of engagement program Id with correspond program code
     * @param programCodeWithMetadata - Map of engagement program code with engagement program metadata record
     * @param engagementProgramIdWithProgramRegionsList - Map of engagement program Id with related list of program region user mapping records
     *
     * @return - record of wrapper class classesMapWithEngagementProgramsWrapper
     */
    private static classesMapWithEngagementProgramsWrapper getWrapperOfClassesAndEngagementPrograms(Map<Id, String> engagementProgramIdWithCode, Map<String,PC_EngagementProgramSetting__mdt> programCodeWithMetadata, Map<Id, List<PC_ProgramRegionUserMapping__c>> engagementProgramIdWithProgramRegionsList){
        String settingName;
        Set<String> classes;
        List<Id> engagementProgramsWithDefaultSetting = new List<Id>();
        PC_WCDServiceClassNameWrapper deserializedString = new PC_WCDServiceClassNameWrapper();
        Map<String, Set<String>> mapOfClassesAndRoles = new Map<String, Set<String>>();
        Map<String,Set<Id>> classesMapWithEngagementPrograms = new Map<String,Set<Id>>();
        for (Id engagementprogramid : engagementProgramIdWithCode.keySet()) {
            String engagementProgramCode = engagementProgramIdWithCode.get(engagementprogramid);
            if(programCodeWithMetadata.containsKey(engagementProgramCode)){
                settingName = programCodeWithMetadata.get(engagementProgramCode).PC_SettingValue__c;
                deserializedString = (PC_WCDServiceClassNameWrapper) JSON.deserialize(settingName, PC_WCDServiceClassNameWrapper.Class);
                List<PC_WCDServiceClassNameWrapper.careTeamRoles> rolesMap = new List<PC_WCDServiceClassNameWrapper.careTeamRoles>();
                rolesMap = deserializedString.classPerRole;
                List<String> rolesHavingClasses = new List<String>();
                classes = new Set<String>();
                if (rolesMap != null) {
                    for (PC_WCDServiceClassNameWrapper.careTeamRoles classrole : rolesMap) {
                        rolesHavingClasses.add(classrole.role);
                        classes.add(classrole.classname);
                        String key = engagementprogramid + '-' + classrole.classname;
                        if (mapOfClassesAndRoles.containsKey(key)) {
                            Set<String> rolesList = mapOfClassesAndRoles.get(key);
                            rolesList.add(classrole.role);
                            mapOfClassesAndRoles.put(key, rolesList);
                        } else {
                            Set<String> rolesList2 = new Set<String>();
                            rolesList2.add(classrole.role);
                            mapOfClassesAndRoles.put(key, rolesList2);
                        }
                    }
                }

                Set<String> rolesFromProgramRegionUserMappingsSet = new Set<String>();
                List<String> rolesFromProgramRegionUserMappingsList = new List<String>();
                List<String> rolesWithoutClasses = new List<String>();

                for (PC_ProgramRegionUserMapping__c pgrecord : engagementProgramIdWithProgramRegionsList.get(engagementprogramid)) {
                    rolesFromProgramRegionUserMappingsSet.add(pgrecord.PC_CareTeamRole__c);
                }

                rolesFromProgramRegionUserMappingsList.addAll(rolesFromProgramRegionUserMappingsSet);
                for (String rolefromprogramregion : rolesFromProgramRegionUserMappingsList) {
                    if (rolesHavingClasses.size() == 0 || !rolesHavingClasses.contains(rolefromprogramregion)) {
                        rolesWithoutClasses.add(rolefromprogramregion);
                    }
                }

                String defaultClass = deserializedString.defaultclass;
                if (String.isBlank(defaultClass)) {
                    defaultClass = 'PC_WCDDefaultService';
                }
                classes.add(defaultClass);
                String key = engagementprogramid + '-' + defaultClass;
                if (mapOfClassesAndRoles.containsKey(key)) {
                    Set<String> rolesList = mapOfClassesAndRoles.get(key);
                    rolesList.addAll(rolesWithoutClasses);
                    mapOfClassesAndRoles.put(key,rolesList);
                }else{
                    Set<String> rolesList2 = new Set<String>();
                    rolesList2.addAll(rolesWithoutClasses);
                    mapOfClassesAndRoles.put(key,rolesList2);
                }
                if(!classes.isEmpty()){
                    for(String classname:classes){
                        if(classesMapWithEngagementPrograms.containsKey(classname)){
                            Set<Id> engagementProgramsIds = classesMapWithEngagementPrograms.get(classname);
                            engagementProgramsIds.add(engagementprogramid);
                            classesMapWithEngagementPrograms.put(classname,engagementProgramsIds);
                        }else{
                            Set<Id> engagementIds = new Set<Id>();
                            engagementIds.add(engagementprogramid);
                            classesMapWithEngagementPrograms.put(classname,engagementIds);
                        }
                    }
                }
            } else {
                engagementProgramsWithDefaultSetting.add(engagementprogramid);
            }

        }
        classesMapWithEngagementProgramsWrapper classMapWrapper = new classesMapWithEngagementProgramsWrapper();
        classMapWrapper.engagementProgramIdsWithDefaultSetting = engagementProgramsWithDefaultSetting;
        classMapWrapper.classesMappingWithEngagementPrograms = classesMapWithEngagementPrograms;
        classMapWrapper.classesMappingWithRole = mapOfClassesAndRoles;

        return classMapWrapper;
    }

    /**
     * This method is used to map the classes with related engagement programs
     * User-Story : PC-8436
     * @param settingValue - Setting value of custom metadata PC_WCDServiceClassName from Patient Connect Settings
     * @param engagementProgramsWithDefaultSetting - List of Ids of engagement programs with default setting
     * @param mapOfClassesAndRoles - Map of class with set of roles
     * @param engagementProgramIdWithProgramRegionsList - Map of engagement program Id with related list of program region user mapping records
     * @param classesMapWithEngagementPrograms - Map of class with related set of engagement program Ids
     *
     * @return - record of wrapper class classesMapWithEngagementProgramsWrapper
     */
    private static classesMapWithEngagementProgramsWrapper getWrapperofClassesWithDefaultSettingEngagementPrograms(String settingValue, List<Id> engagementProgramsWithDefaultSetting, Map<String, Set<String>> mapOfClassesAndRoles,Map<Id, List<PC_ProgramRegionUserMapping__c>> engagementProgramIdWithProgramRegionsList, Map<String,Set<Id>> classesMapWithEngagementPrograms){
        PC_WCDServiceClassNameWrapper deserializedString = new PC_WCDServiceClassNameWrapper();
        String settingValueString = settingValue;
        Set<String> classesWithDefaultSetting = new Set<String>();
        List<String> rolesHavingClasses = new List<String>();
        if (String.isNotBlank(settingValueString)) {
            deserializedString = (PC_WCDServiceClassNameWrapper) JSON.deserialize(settingValueString, PC_WCDServiceClassNameWrapper.Class);
            List<PC_WCDServiceClassNameWrapper.careTeamRoles> rolesMap = new List<PC_WCDServiceClassNameWrapper.careTeamRoles>();
            rolesMap = deserializedString.classPerRole;
            if (rolesMap != null) {
                for(Id engagementprogramid:engagementProgramsWithDefaultSetting){
                    for (PC_WCDServiceClassNameWrapper.careTeamRoles classrole : rolesMap) {
                        classesWithDefaultSetting.add(classrole.classname);
                        rolesHavingClasses.add(classrole.role);
                        String key = engagementprogramid + '-' + classrole.classname;
                        if (mapOfClassesAndRoles.containsKey(key)) {
                            Set<String> rolesList = mapOfClassesAndRoles.get(key);
                            rolesList.add(classrole.role);
                            mapOfClassesAndRoles.put(key, rolesList);
                        } else {
                            Set<String> rolesList2 = new Set<String>();
                            rolesList2.add(classrole.role);
                            mapOfClassesAndRoles.put(key, rolesList2);
                        }
                    }
                }
            }
        }

        Set<String> rolesFromProgramRegionUserMappingsSet = new Set<String>();
        List<String> rolesFromProgramRegionUserMappingsList = new List<String>();
        List<String> rolesWithoutClasses = new List<String>();
        for(Id engagementprogramid:engagementProgramsWithDefaultSetting){
            for (PC_ProgramRegionUserMapping__c pgrecord : engagementProgramIdWithProgramRegionsList.get(engagementprogramid)) {
                rolesFromProgramRegionUserMappingsSet.add(pgrecord.PC_CareTeamRole__c);
            }
        }
        rolesFromProgramRegionUserMappingsList.addAll(rolesFromProgramRegionUserMappingsSet);
        for (String rolefromprogramregion : rolesFromProgramRegionUserMappingsList) {
            if (rolesHavingClasses.size() == 0 || !rolesHavingClasses.contains(rolefromprogramregion)) {
                rolesWithoutClasses.add(rolefromprogramregion);
            }
        }

        String defaultClass = deserializedString.defaultclass;
        if (String.isBlank(defaultClass)) {
            defaultClass = 'PC_WCDDefaultService';
        }
        classesWithDefaultSetting.add(defaultClass);

        for(Id engagementprogramid:engagementProgramsWithDefaultSetting){
            String key = engagementprogramid + '-' + defaultClass;
            if (mapOfClassesAndRoles.containsKey(key)) {
                Set<String> rolesList = mapOfClassesAndRoles.get(key);
                rolesList.addAll(rolesWithoutClasses);
                mapOfClassesAndRoles.put(key,rolesList);
            }else{
                Set<String> rolesList2 = new Set<String>();
                rolesList2.addAll(rolesWithoutClasses);
                mapOfClassesAndRoles.put(key,rolesList2);
            }

            for(String classname:classesWithDefaultSetting){
                if(classesMapWithEngagementPrograms.containsKey(classname)){
                    Set<Id> engagementPrograms = classesMapWithEngagementPrograms.get(classname);
                    engagementPrograms.add(engagementprogramid);
                    classesMapWithEngagementPrograms.put(classname,engagementPrograms);
                }else{
                    Set<Id> engagementProgramsList = new Set<Id>();
                    engagementProgramsList.add(engagementprogramid);
                    classesMapWithEngagementPrograms.put(classname,engagementProgramsList);
                }
            }
        }

        classesMapWithEngagementProgramsWrapper classMapWrapper = new classesMapWithEngagementProgramsWrapper();
        classMapWrapper.engagementProgramIdsWithDefaultSetting = engagementProgramsWithDefaultSetting;
        classMapWrapper.classesMappingWithEngagementPrograms = classesMapWithEngagementPrograms;
        classMapWrapper.classesMappingWithRole = mapOfClassesAndRoles;

        return classMapWrapper;
    }

    /**
     * This method is used to return the map of cases with related program region user mapping records
     * User-Story : PC-8436
     * @param allClasses - Set of classes
     * @param mapOfClassesAndRoles - Map of class with set of roles
     * @param classesMapWithEngagementPrograms - Map of class with set of engagement program Ids
     * @param engagementProgramIdWithProgramRegionsList - Map of engagement program Id with related list of program region user mapping records
     * @param engagementProgramHistories - List of program region user mapping history records
     * @param caseIdMappingWithCaseDetails - Map of case Id and PC_WCD.caseDetails
     * @param recordIdWorkCaseDistDetailsWrapperMap - Map of case Id and case details wrapper
     * @param regionIdSet - Set of regions
     *
     * @return - Map of case Id with list of program region user mapping records
     */
    private static Map<Id, List<PC_ProgramRegionUserMapping__c>> getMapOfCasesWithProgramRegionUserMappingRecords(Set<String> allClasses, Map<String, Set<String>> mapOfClassesAndRoles, Map<String,Set<Id>> classesMapWithEngagementPrograms, Map<Id, List<PC_ProgramRegionUserMapping__c>> engagementProgramIdWithProgramRegionsList, List<PC_ProgramRegionUserHistory__c> engagementProgramHistories, Map<Id, PC_WCD.caseDetails> caseIdMappingWithCaseDetails, Map<Id, RecordIdWorkCaseDistDetailsWrapper> recordIdWorkCaseDistDetailsWrapperMap, Set<Id> regionIdSet){
        Map<Id, List<PC_ProgramRegionUserMapping__c>> casesMappingWithProgramRegionUserMappings = new Map<Id, List<PC_ProgramRegionUserMapping__c>>();
        Map<Id, List<PC_ProgramRegionUserMapping__c>> associationsList = new Map<Id, List<PC_ProgramRegionUserMapping__c>>();
        for(String classname:allClasses){
            Set<Id> engagementProgramesIds = classesMapWithEngagementPrograms.get(classname);
            List<String> rolesOfClassList = new List<String>();
            List<PC_ProgramRegionUserMapping__c> programRegionUserMappingsList =  new List<PC_ProgramRegionUserMapping__c>();
            for(Id engagementprogramid : engagementProgramesIds){
                String uniqueKey = engagementprogramid + '-' + classname;
                Set<String> rolesOfEngagementProgram = mapOfClassesAndRoles.get(uniqueKey);
                rolesOfClassList.addAll(rolesOfEngagementProgram);
                for(String role:rolesOfEngagementProgram){
                    for(PC_ProgramRegionUserMapping__c programregionusermapping:engagementProgramIdWithProgramRegionsList.get(engagementprogramid)){
                        if(programregionusermapping.PC_CareTeamRole__c == role){
                            programRegionUserMappingsList.add(programregionusermapping);
                        }
                    }
                }
            }
            if (isServiceClassValid(classname)) {
                associationsList = processProgramRegionMappingRecords(classname, engagementProgramesIds, engagementProgramHistories, programRegionUserMappingsList, rolesOfClassList, caseIdMappingWithCaseDetails, recordIdWorkCaseDistDetailsWrapperMap, regionIdSet);
            }else{
                PC_WorkCaseDistributionException workCaseDistributionException = new PC_WorkCaseDistributionException();
                workCaseDistributionException.setMessage(Label.PC_ClassNameNotFound + classname);
                throw workCaseDistributionException;
            }
            for(Id caseId:associationsList.keySet()){
                if(casesMappingWithProgramRegionUserMappings.containsKey(caseId)){
                    List<PC_ProgramRegionUserMapping__c> programRegionUsersList = casesMappingWithProgramRegionUserMappings.get(caseId);
                    Set<PC_ProgramRegionUserMapping__c> programRegionUsersSet = new Set<PC_ProgramRegionUserMapping__c>();
                    programRegionUsersSet.addAll(associationsList.get(caseId));
                    programRegionUsersSet.addAll(programRegionUsersList);
                    List<PC_ProgramRegionUserMapping__c> setOfProgramRegionUsersList = new List<PC_ProgramRegionUserMapping__c>();
                    setOfProgramRegionUsersList.addAll(programRegionUsersSet);
                    casesMappingWithProgramRegionUserMappings.put(caseId,setOfProgramRegionUsersList);
                }else{
                    Set<PC_ProgramRegionUserMapping__c> setOfProgramRegionUsers = new Set<PC_ProgramRegionUserMapping__c>();
                    setOfProgramRegionUsers.addAll(associationsList.get(caseId));
                    List<PC_ProgramRegionUserMapping__c> listOfProgramRegionUsers = new List<PC_ProgramRegionUserMapping__c>();
                    listOfProgramRegionUsers.addAll(setOfProgramRegionUsers);
                    casesMappingWithProgramRegionUserMappings.put(caseId,listOfProgramRegionUsers);
                }
            }
        }
        return casesMappingWithProgramRegionUserMappings;
    }

    /**
     * This method is used to process the program region user mapping records and return Associations those need to be created
     * User-Story : PC-8232
     * @param serviceClassName - class
     * @param engagementProgramIds - Set of engagement program Ids
     * @param engagementProgramHistories - List of program region user mapping history records
     * @param programRegionUserMappingsList - List of program region user mapping records
     * @param roles - List of roles
     * @param caseIdMappingWithCaseDetails - Map of case Id and PC_WCD.caseDetails
     * @param recordIdWorkCaseDistDetailsWrapperMap - Map of case Id and case details wrapper
     * @param regionIdSet - Set of region Ids
     *
     * @return - Map of case Id with list of program region user mapping records
     */
    private static Map<Id, List<PC_ProgramRegionUserMapping__c>> processProgramRegionMappingRecords(String serviceClassName, Set<Id> engagementProgramIds, List<PC_ProgramRegionUserHistory__c> engagementProgramHistories, List<PC_ProgramRegionUserMapping__c> programRegionUserMappingsList, List<String> roles, Map<Id, PC_WCD.caseDetails> caseIdMappingWithCaseDetails, Map<Id, RecordIdWorkCaseDistDetailsWrapper> recordIdWorkCaseDistDetailsWrapperMap, Set<Id> regionIdSet) {
        List<PC_Association__c> associationsToCreate = new List<PC_Association__c>();
        List<PC_ProgramRegionUserHistory__c> programRegionUserHistoriesList = new List<PC_ProgramRegionUserHistory__c>();
        List<PC_ProgramRegionUserMapping__c> pgCreateList = new List<PC_ProgramRegionUserMapping__c>();
        List<PC_WCD.programRegionUsersHistoryMappingByEngagementPrograms> programRegionUserHistories = new List<PC_WCD.programRegionUsersHistoryMappingByEngagementPrograms>();
        //checking whether the class is implementing PC_WCD interface
        Type t = Type.forName(serviceClassName);
        Object o = t.newInstance();
        PC_WCD.UserMappingFinder processor = (PC_WCD.UserMappingFinder) o;
        PC_WCD.FindMapperRequest request = new PC_WCD.FindMapperRequest();
        programRegionUserHistories = groupProgramRegionHistoryRecordsByEngagementPrograms(engagementProgramIds, engagementProgramHistories, roles);
        request.programRegionUsersHistoryMappingByEngPrograms = programRegionUserHistories;
        request.programRegionUsersMappingByEngPrograms = groupProgramRegionRecordsByEngagementPrograms(engagementProgramIds, programRegionUserMappingsList, roles);
        request.caseIdMapWithCaseDetails = filterCaseIdMappingWithCaseDetails(caseIdMappingWithCaseDetails,engagementProgramIds);
        PC_WCD.FindMapperResponse casesMappingWithValidProgramRegionMappingsForAssociations = new PC_WCD.FindMapperResponse();
        casesMappingWithValidProgramRegionMappingsForAssociations = processor.findMapper(request);
        Map<Id, List<PC_ProgramRegionUserMapping__c>> casesMappingWithValidProgramRegions = new Map<Id, List<PC_ProgramRegionUserMapping__c>>();
        casesMappingWithValidProgramRegions = casesMappingWithValidProgramRegionMappingsForAssociations.programRegionUserMappingsByCase;
        List<PC_ProgramRegionUserMapping__c> programRegionsToHaveCareTeam = new List<PC_ProgramRegionUserMapping__c>();
        Set<PC_ProgramRegionUserMapping__c> programRegionsToHaveCareTeamSet = new Set<PC_ProgramRegionUserMapping__c>();
        for (Id caseId : casesMappingWithValidProgramRegions.keySet()) {
            for (PC_ProgramRegionUserMapping__c programRegionUserMapping : casesMappingWithValidProgramRegions.get(caseId)) {
                programRegionsToHaveCareTeamSet.add(programRegionUserMapping);
            }
        }
        if (!programRegionsToHaveCareTeamSet.isEmpty()) {
            programRegionsToHaveCareTeam.addAll(programRegionsToHaveCareTeamSet);
        }

        for(PC_WCD.programRegionUsersHistoryMappingByEngagementPrograms historyRecordMap:programRegionUserHistories){
            for(PC_ProgramRegionUserHistory__c historyrecord:historyRecordMap.programRegionUserHistoryRecords){
                programRegionUserHistoriesList.add(historyrecord);
            }
        }

        return casesMappingWithValidProgramRegions;
    }

    /**
     * This method is used to return the case mapping details for an engagement program
     * User-Story : PC-8397
     * @param caseIdMappingWithCaseDetails - Map of case Id and PC_WCD.caseDetails
     * @param engagementProgramIds - Set of engagement program Ids
     *
     * @return - Returns map of case Id and PC_WCD.caseDetails which are related to engagement program Ids 'engagementProgramIds'
     */
    private static Map<Id, PC_WCD.caseDetails> filterCaseIdMappingWithCaseDetails(Map<Id, PC_WCD.caseDetails> caseIdMappingWithCaseDetails,Set<Id> engagementProgramIds){
        Map<Id, PC_WCD.caseDetails> caseDetailsMap = new Map<Id, PC_WCD.caseDetails>();
        for(Id i:caseIdMappingWithCaseDetails.keySet()){
            if(engagementProgramIds.contains(caseIdMappingWithCaseDetails.get(i).engagementProgramId)) {
                caseDetailsMap.put(i, caseIdMappingWithCaseDetails.get(i));
            }
        }
        return caseDetailsMap;
    }

    /**
     * This method is used to group the Program Region User Mapping records by related Engagement Programs
     * User-Story : PC-8123
     * @param EngagementPrograms - Set of engagement program Ids
     * @param programRegionRecordsList - List of program region user mapping records
     * @param roles - List of roles
     *
     * @return - List of PC_WCD.programRegionUsersMappingByEngagementPrograms records
     */
    private static List<PC_WCD.programRegionUsersMappingByEngagementPrograms> groupProgramRegionRecordsByEngagementPrograms(Set<Id> EngagementPrograms, List<PC_ProgramRegionUserMapping__c> programRegionRecordsList, List<String> roles) {

        List<PC_WCD.programRegionUsersMappingByEngagementPrograms> programRegionUsersMappingWithEngagementPrograms = new List<PC_WCD.programRegionUsersMappingByEngagementPrograms>();
        Map<Id, List<PC_ProgramRegionUserMapping__c>> roleProgramRegionMap = new Map<Id, List<PC_ProgramRegionUserMapping__c>>();
        List<PC_ProgramRegionUserMapping__c> programRegionsList;
        Set<PC_ProgramRegionUserMapping__c> programRegionsSet;
        for (Id engagementprogramId : EngagementPrograms) {
            programRegionsList = new List<PC_ProgramRegionUserMapping__c>();
            programRegionsSet = new Set<PC_ProgramRegionUserMapping__c>();
            for (String role : roles) {
                for (PC_ProgramRegionUserMapping__c pgrecord : programRegionRecordsList) {
                    if (engagementprogramId == pgrecord.PC_EngagementProgram__c && role == pgrecord.PC_CareTeamRole__c) {
                        programRegionsSet.add(pgrecord);
                    }
                }
            }
            programRegionsList.addAll(programRegionsSet);
            roleProgramRegionMap.put(engagementprogramId, programRegionsList);
            PC_WCD.programRegionUsersMappingByEngagementPrograms mappingRecord = new PC_WCD.programRegionUsersMappingByEngagementPrograms();
            mappingRecord.engagementProgram = engagementprogramId;
            mappingRecord.programRegionUserMappingsByRoles = programRegionsList;
            programRegionUsersMappingWithEngagementPrograms.add(mappingRecord);

        }

        return programRegionUsersMappingWithEngagementPrograms;
    }

    /**
     * This method is used to group the Program Region records by respective Engagement Programs
     * User-Story : PC-8123
     * @param engagementProgramIds - Set of engagement program Ids
     * @param engagementProgramHistories - List of program region user mapping history records
     * @param roles - List of roles
     *
     * @return - List of PC_WCD.programRegionUsersHistoryMappingByEngagementPrograms records
     */
    private static List<PC_WCD.programRegionUsersHistoryMappingByEngagementPrograms> groupProgramRegionHistoryRecordsByEngagementPrograms(Set<Id> engagementProgramIds, List<PC_ProgramRegionUserHistory__c> engagementProgramHistories, List<String> roles) {
        Map<Id, List<PC_ProgramRegionUserHistory__c>> roleProgramRegionHistoryMap = new Map<Id, List<PC_ProgramRegionUserHistory__c>>();
        List<PC_ProgramRegionUserHistory__c> programRegionUserHistoryList;
        Set<PC_ProgramRegionUserHistory__c> programRegionUserHistorySet;
        List<PC_WCD.programRegionUsersHistoryMappingByEngagementPrograms> programRegionUserHistories = new List<PC_WCD.programRegionUsersHistoryMappingByEngagementPrograms>();
        for (Id engagementprogramId : engagementProgramIds) {
            programRegionUserHistoryList = new List<PC_ProgramRegionUserHistory__c>();
            programRegionUserHistorySet = new Set<PC_ProgramRegionUserHistory__c>();
            for (String role : roles) {
                for (PC_ProgramRegionUserHistory__c programregionuserhistory : engagementProgramHistories) {
                    if (engagementprogramId == programregionuserhistory.PC_EngagementProgram__c && role == programregionuserhistory.PC_CareTeamRole__c) {
                        programRegionUserHistorySet.add(programregionuserhistory);
                    }
                }
            }
            programRegionUserHistoryList.addAll(programRegionUserHistorySet);
            roleProgramRegionHistoryMap.put(engagementprogramId, programRegionUserHistoryList);
            PC_WCD.programRegionUsersHistoryMappingByEngagementPrograms programregionuserhistorymap = new PC_WCD.programRegionUsersHistoryMappingByEngagementPrograms();
            programregionuserhistorymap.engagementProgramId = engagementprogramId;
            programregionuserhistorymap.programRegionUserHistoryRecords = programRegionUserHistoryList;
            programRegionUserHistories.add(programregionuserhistorymap);
        }
        return programRegionUserHistories;
    }

    /**
     * This method is used to return the Associate records that needs to be created and call another method that creates/updates Program Region User History records
     *
     * @param programRegionUserHistoryList - List of program region user mapping history records
     * @param casesMappingWithValidProgramRegions - Map of case Id with list of program region user mapping records
     * @param recordIdWorkCaseDistDetailsWrapperMap - Map of case Id with case details wrapper
     * @param regionIdSet - Set of regions
     *
     * @return - List of associations
     */
    private static List<PC_Association__c> getAssociationsToCreate(List<PC_ProgramRegionUserHistory__c> programRegionUserHistoryList, Map<Id, List<PC_ProgramRegionUserMapping__c>> casesMappingWithValidProgramRegions, Map<Id, RecordIdWorkCaseDistDetailsWrapper> recordIdWorkCaseDistDetailsWrapperMap, Set<Id> regionIdSet) {

        List<PC_Association__c> associateList = new List<PC_Association__c>();

        for (Id recordId : casesMappingWithValidProgramRegions.keySet()) {
            for (Id regionId : recordIdWorkCaseDistDetailsWrapperMap.get(recordId).regionIdSet) {
                for (PC_ProgramRegionUserMapping__c programregionusermapping : casesMappingWithValidProgramRegions.get(recordId)) {
                    if (regionId == programregionusermapping.PC_Region__c &&
                            recordIdWorkCaseDistDetailsWrapperMap.get(recordId).engagementProgramId == programregionusermapping.PC_EngagementProgram__c) {
                        PC_Association__c careTeamAssociateRecord = new PC_Association__c();
                        careTeamAssociateRecord.PC_Role__c = programregionusermapping.PC_CareTeamRole__c;
                        if (programregionusermapping.PC_CareTeamMember__c != null) {
                            careTeamAssociateRecord.PC_Associated_User__c = programregionusermapping.PC_CareTeamMember__c;
                        }
                        if (programregionusermapping.PC_CareTeamAccount__c != null) {
                            careTeamAssociateRecord.PC_Account__c = programregionusermapping.PC_CareTeamAccount__c;
                        }
                        if (programregionusermapping.PC_EndDateTime__c != null) {
                            careTeamAssociateRecord.PC_EndDate__c = programregionusermapping.PC_EndDateTime__c.Date();
                        }
                        careTeamAssociateRecord.PC_AssociationStatus__c = PC_Constants.ACTIVE;
                        careTeamAssociateRecord.PC_IsCreatedViaWCD__c = PC_Constants.TRUE_BOOLEAN;
                        careTeamAssociateRecord.PC_Program__c = recordIdWorkCaseDistDetailsWrapperMap.get(recordId).caseId;

                        associateList.add(careTeamAssociateRecord);
                    }
                }
            }
        }

        createOrDeleteHistoryRecords(programRegionUserHistoryList,casesMappingWithValidProgramRegions, recordIdWorkCaseDistDetailsWrapperMap, regionIdSet);

        return associateList;
    }

    /**
     * This method is used to create or delete the History records
     * User-Story     : PC-8123
     * @param listOfProgramRegionUserHistories - List of program region user mapping history records
     * @param casesMappingWithValidProgramRegions - Map of case id with list of program region user mapping records
     * @param recordIdWorkCaseDistDetailsWrapperMap - Map of case id with case details wrapper
     * @param regionIdSet - Set of region Ids
     */
    private static void createOrDeleteHistoryRecords(List<PC_ProgramRegionUserHistory__c> listOfProgramRegionUserHistories,Map<Id, List<PC_ProgramRegionUserMapping__c>> casesMappingWithValidProgramRegions,Map<Id, RecordIdWorkCaseDistDetailsWrapper> recordIdWorkCaseDistDetailsWrapperMap, Set<Id> regionIdSet) {
        //List<PC_ProgramRegionUserHistory__c> programRegionUserHistoryCreateList = new List<PC_ProgramRegionUserHistory__c>();
        Set<PC_ProgramRegionUserHistory__c> programRegionUserHistoryCreateSet = new Set<PC_ProgramRegionUserHistory__c>();
        Set<PC_ProgramRegionUserHistory__c> programRegionHistoryDeleteSet = new Set<PC_ProgramRegionUserHistory__c>();
        //List<PC_ProgramRegionUserHistory__c> programRegionHistoryDeleteList = new List<PC_ProgramRegionUserHistory__c>();
        List<PC_ProgramRegionUserMapping__c> programRegionRecordList = new List<PC_ProgramRegionUserMapping__c>();
        Set<PC_ProgramRegionUserMapping__c> existingProgramRegionUserMappingsSet = new Set<PC_ProgramRegionUserMapping__c>();
        Set<String> teamRoles = new Set<String>();
        Set<Id> engagementIds = new Set<Id>();
        Set<Id> regionIds = new Set<Id>();
        Set<PC_ProgramRegionUserMapping__c> updatedRecords = new Set<PC_ProgramRegionUserMapping__c>();

        if (!casesMappingWithValidProgramRegions.isEmpty()) {
            for (Id caseId : casesMappingWithValidProgramRegions.keySet()) {
                for (PC_ProgramRegionUserMapping__c programRegionUserMapping : casesMappingWithValidProgramRegions.get(caseId)) {
                    existingProgramRegionUserMappingsSet.add(programRegionUserMapping);
                    if(rolesByRegionMap.containsKey(caseId)){
                        if(String.isNotBlank(programRegionUserMapping.PC_CareTeamRole__c)) {
                            rolesByRegionMap.get(caseId).add(programRegionUserMapping.PC_CareTeamRole__c);
                        }
                    } else {
                        if(String.isNotBlank(programRegionUserMapping.PC_CareTeamRole__c)) {
                            rolesByRegionMap.put(caseId, new List<String>{programRegionUserMapping.PC_CareTeamRole__c});
                        }
                    }
                }
            }
        }

        if (!existingProgramRegionUserMappingsSet.isEmpty()) {
            programRegionRecordList.addAll(existingProgramRegionUserMappingsSet);
        }

        for (PC_ProgramRegionUserMapping__c programregionusermapping : programRegionRecordList) {
            teamRoles.add(programregionusermapping.PC_CareTeamRole__c);
            engagementIds.add(programregionusermapping.PC_EngagementProgram__c);
            regionIds.add(programregionusermapping.PC_Region__c);
        }

        for(PC_ProgramRegionUserHistory__c programregionuserhistory : listOfProgramRegionUserHistories){
            for(Id engagementId : engagementIds){
                for(Id regionid : regionIds){
                    for(String role : teamRoles){
                        if(programregionuserhistory.PC_EngagementProgram__c == engagementId && programregionuserhistory.PC_CareTeamRole__c == role
                                && programregionuserhistory.PC_Region__c == regionid){
                            programRegionHistoryDeleteSet.add(programregionuserhistory);
                        }
                    }
                }
            }
        }

        if (!programRegionRecordList.isEmpty()) {
            for (Id recordId : casesMappingWithValidProgramRegions.keySet()) {
                for (Id regionId : recordIdWorkCaseDistDetailsWrapperMap.get(recordId).regionIdSet) {
                    for (PC_ProgramRegionUserMapping__c programRegionUserMapping : casesMappingWithValidProgramRegions.get(recordId)) {
                        if (regionId == programRegionUserMapping.PC_Region__c &&
                                recordIdWorkCaseDistDetailsWrapperMap.get(recordId).engagementProgramId == programRegionUserMapping.PC_EngagementProgram__c) {
                            PC_ProgramRegionUserHistory__c programRegionUserHistory = new PC_ProgramRegionUserHistory__c();
                            programRegionUserHistory.PC_CareTeamRole__c = programRegionUserMapping.PC_CareTeamRole__c;
                            if (programRegionUserMapping.PC_CareTeamMember__c != null) {
                                programRegionUserHistory.PC_CareTeamUser__c = programRegionUserMapping.PC_CareTeamMember__c;
                            }
                            if (programRegionUserMapping.PC_CareTeamAccount__c != null) {
                                programRegionUserHistory.PC_CareTeamAccount__c = programRegionUserMapping.PC_CareTeamAccount__c;
                            }
                            programRegionUserHistory.PC_Case__c = recordIdWorkCaseDistDetailsWrapperMap.get(recordId).caseId;
                            programRegionUserHistory.PC_EngagementProgram__c = programRegionUserMapping.PC_EngagementProgram__c;
                            programRegionUserHistory.PC_Region__c = regionId;
                            programRegionUserHistoryCreateList.add(programRegionUserHistory);
                        }
                    }
                }
            }
        }

        if (!programRegionHistoryDeleteSet.isEmpty()) {
            programRegionHistoryDeleteList.addAll(programRegionHistoryDeleteSet);
        }

        /*if (!programRegionHistoryDeleteList.isEmpty()) {
            PC_Database.del(programRegionHistoryDeleteList, false);
        }

        if (!programRegionUserHistoryCreateList.isEmpty()) {
            PC_Database.ins(programRegionUserHistoryCreateList, false);
        }*/
    }


    /**
     * This method is used to populate the correct manufacturer id for given engagement program id
     * User-Story : PC-4014
     * @param engProgIdAssignmentLookupFldMap - Map of engagement program Id with assignment lookup field
     * @param recordIdWorkCaseDistDetailsWrapperMap - Map of case Id with case details wrapper
     *
     * @return Map of case Id with case details wrapper with manufacturer Id
     */
    public static Map<Id, RecordIdWorkCaseDistDetailsWrapper> populateManufacturerIdForEngagementProg(Map<Id, String> engProgIdAssignmentLookupFldMap, Map<Id, RecordIdWorkCaseDistDetailsWrapper> recordIdWorkCaseDistDetailsWrapperMap) {
        List<PC_Engagement_Program__c> engagementProgramList = new List<PC_Engagement_Program__c>();
        Map<Id, Id> engProgramManufacturerMap = new Map<Id, Id>();

        /** Fetch Engagement Program details: Manufacturer from PC_Engagement_Program__c table **/
        //FLS check is not needed since the code runs in trigger context mode
        engagementProgramList = [
                SELECT Id, PC_Manufacturer__c
                FROM PC_Engagement_Program__c
                WHERE Id IN:engProgIdAssignmentLookupFldMap.keySet()
        ];

        /** Create a Map of Engagement Program Id as key and its Manufacturer as the value**/
        for (PC_Engagement_Program__c engagementProgram : engagementProgramList) {
            engProgramManufacturerMap.put(engagementProgram.Id, engagementProgram.PC_Manufacturer__c);
        }

        /** Populate the correct manufacturer id for the engagement program id in 'recordIdWorkCaseDistDetailsWrapperMap' map**/
        for (Id recordId : recordIdWorkCaseDistDetailsWrapperMap.keySet()) {
            if (recordIdWorkCaseDistDetailsWrapperMap.containsKey(recordId) && engProgramManufacturerMap.containsKey(recordIdWorkCaseDistDetailsWrapperMap.get(recordId).engagementProgramId)) {
                recordIdWorkCaseDistDetailsWrapperMap.get(recordId).manufacturerId = engProgramManufacturerMap.get(recordIdWorkCaseDistDetailsWrapperMap.get(recordId).engagementProgramId);
            }
        }

        return recordIdWorkCaseDistDetailsWrapperMap;
    }

    /*********************************************************************************
    Method Name    : getZipCodeDetails
    Author         : Hitha Avalakki
    Description    : This method is used to get zip code values
    Return Type    : Map<Id, String>
    Parameter      : String, String, Set<Id>, Map<Id,String>
    User-Story     : PC-4014
    *********************************************************************************/
    /**
     * This method is used to get zip code values
     * User-Story : PC-4014
     * @param zipCodeFieldNameString - Zip code field name
     * @param sObjectName - sObject name
     * @param recordIdSet - Set of case Ids
     * @param recordIdZipCodeFieldNameMap - Map of case Id with assignment lookup field
     * @param parentIdChildIdMap - Map of case Id with Account Id
     * @param recordIdZipCodeMap - Map of case Id with region zipcode value
     *
     * @return - Map of case Id with region zipcode value
     */
    public static Map<Id, String> getZipCodeDetails(String zipCodeFieldNameString, String sObjectName, Set<Id> recordIdSet, Map<Id, String> recordIdZipCodeFieldNameMap, Map<Id, Id> parentIdChildIdMap, Map<Id, String> recordIdZipCodeMap) {
        String zipCodeQuery = '';

        String selectClause = 'SELECT Id, ' + zipCodeFieldNameString;
        zipCodeQuery = zipCodeQuery + selectClause + ' FROM ' + sObjectName + ' WHERE Id IN: recordIdSet';

        List<SObject> sobjectList = Database.query(zipCodeQuery);

        /** Run through the dynamic query results and prepare a Map of case record id as key and the corresponding zipcode as value **/
        for (SObject sobjectRecord : sobjectList) {
            String zipCodeVal = '';
            if (sObjectName.equals(PC_Constants.PC_CASE)) {
                Case caseObject = (Case) sobjectRecord;

                if (recordIdZipCodeFieldNameMap.containsKey(caseObject.Id)) {
                    zipCodeVal = (String) caseObject.get(recordIdZipCodeFieldNameMap.get(caseObject.Id));
                    recordIdZipCodeMap.put(caseObject.Id, zipCodeVal);
                }
            }
            if (sObjectName.equals(PC_Constants.PC_ACCOUNT)) {
                Account accountObject = (Account) sobjectRecord;
                Set<String> objectFields = Account.getSobjectType().getDescribe().fields.getMap().keySet();
                String fieldName = PC_Constants.EMPTY_STRING;
                for (Id parentId : parentIdChildIdMap.keySet()) {
                    if (parentIdChildIdMap.get(parentId) == accountObject.Id) {
                        if (recordIdZipCodeFieldNameMap.containsKey(parentId)) {
                            fieldName = recordIdZipCodeFieldNameMap.get(parentId);
                            if(fieldName.startsWith('Account.')){
                                fieldName = fieldName.removeStart('Account.');
                                if(objectFields.contains(fieldName.toLowerCase())){
                                    zipCodeVal = (String) accountObject.get(fieldName);
                                    recordIdZipCodeMap.put(parentId, zipCodeVal);
                                }
                            }
                        }
                    }
                }
            }
            if (sObjectName.equals(PC_Constants.PC_USER)) {
                User userObject = (User) sobjectRecord;
                for (Id parentId : parentIdChildIdMap.keySet()) {
                    if (parentIdChildIdMap.get(parentId) == userObject.Id) {
                        if (recordIdZipCodeFieldNameMap.containsKey(parentId)) {
                            zipCodeVal = (String) userObject.get(recordIdZipCodeFieldNameMap.get(parentId));
                            recordIdZipCodeMap.put(parentId, zipCodeVal);
                        }
                    }
                }
            }
        }

        return recordIdZipCodeMap;
    }

    /**
     * This method removes the association from the list if it already exists
     * @param associationsToInsert - List of association records
     * @return - List of association after removing existing association records
     */
    public static List<PC_Association__c> removeAssociationIfAlreadyExists(List<PC_Association__c> associationsToInsert) {
        List<PC_Association__c> existingAssociationList = new List<PC_Association__c>();
        Map<Id, List<PC_Association__c>> programCaseToNewAssociationsMap = new Map<Id, List<PC_Association__c>>();
        Map<Id, List<PC_Association__c>> programCaseToOldAssociationsMap = new Map<Id, List<PC_Association__c>>();
        Boolean isAssociationExists = false;
        List<PC_Association__c> newAssociationsList = new List<PC_Association__c>();

        for (PC_Association__c newAssoc : associationsToInsert) {
            if (programCaseToNewAssociationsMap.containsKey(newAssoc.PC_Program__c)) {
                programCaseToNewAssociationsMap.get(newAssoc.PC_Program__c).add(newAssoc);
            } else {
                programCaseToNewAssociationsMap.put(newAssoc.PC_Program__c, new List<PC_Association__c>{newAssoc});
            }
        }

        /** Fetch all existing association*/
        //FLS check is not needed since the code runs in trigger context mode
        existingAssociationList = [
                SELECT Id, PC_Role__c, PC_Program__c, PC_Program__r.PC_Engagement_Program__c, PC_Account__c, PC_Associated_User__c, PC_AssociationStatus__c
                FROM PC_Association__c
                WHERE PC_AssociationStatus__c = :PC_Constants.ACTIVE and PC_Program__c IN :programCaseToNewAssociationsMap.keySet()
        ];

        for (PC_Association__c existingAssoc : existingAssociationList) {
            if (programCaseToOldAssociationsMap.containsKey(existingAssoc.PC_Program__c)) {
                programCaseToOldAssociationsMap.get(existingAssoc.PC_Program__c).add(existingAssoc);
            } else {
                programCaseToOldAssociationsMap.put(existingAssoc.PC_Program__c, new List<PC_Association__c>{existingAssoc});
            }
        }

        /** Compare new associations with existing associations. If matches remove it from the new association list*/
        for (PC_Association__c newAssoc : associationsToInsert) {
            isAssociationExists = false;
            List<PC_Association__c> caseAssociations = programCaseToOldAssociationsMap.get(newAssoc.PC_Program__c);
            if (caseAssociations != null && caseAssociations.size() > 0) {
                for (PC_Association__c existingAssoc : caseAssociations) {
                    if ((newAssoc.PC_Role__c == existingAssoc.PC_Role__c) &&
                            (((newAssoc.PC_Account__c == existingAssoc.PC_Account__c) && newAssoc.PC_Account__c != null) ||
                                    ((newAssoc.PC_Associated_User__c == existingAssoc.PC_Associated_User__c) && newAssoc.PC_Associated_User__c != null))) {
                        isAssociationExists = true;
                        break;
                    }
                }
            }
            if (!isAssociationExists) {
                newAssociationsList.add(newAssoc);
            }
        }
        return newAssociationsList;
    }

    /**
     * This method is used to create Associations asynchronously
     * @param associationsToInsert - List of association records
     * @param handlerName - Handler Name
     */
    public static void createAssociationsAsynchronously(PC_WorkCaseDistributionHelper.WCDOutputWrapper wcdOutputWrapper, String handlerName) {
        system.debug('Asynchronous handlerName ::: '+handlerName);
        List<PC_Association__c> associationsToInsert = wcdOutputWrapper.associationListToCreate;
        List<PC_ProgramRegionUserHistory__c> programRegionHistoryCreateList = wcdOutputWrapper.programRegionHistoryCreateList;
        List<PC_ProgramRegionUserHistory__c> programRegionHistoryDeleteList = wcdOutputWrapper.programRegionHistoryDeleteList;
        Map<Id, List<PC_Association__c>> caseMappingWithAssociation = new Map<Id, List<PC_Association__c>>();
        Map<Id, List<PC_ProgramRegionUserHistory__c>> PRUHCreateListByCaseIds = new Map<Id, List<PC_ProgramRegionUserHistory__c>>();
        Map<Id, List<PC_ProgramRegionUserHistory__c>> PRUHDeleteListByCaseIds = new Map<Id, List<PC_ProgramRegionUserHistory__c>>();
        Integer associationsBatchSize = 0;
        List<PC_Association__c> associationsToBeInsertedInABatch = new List<PC_Association__c>();
        List<PC_ProgramRegionUserHistory__c> PRUHsToBeInsertedInABatch = new List<PC_ProgramRegionUserHistory__c>();
        List<PC_ProgramRegionUserHistory__c> PRUHsToBeDeletedInABatch = new List<PC_ProgramRegionUserHistory__c>();

        for (PC_Association__c assoc : associationsToInsert) {
            if (caseMappingWithAssociation.containsKey(assoc.PC_Program__c)) {
                caseMappingWithAssociation.get(assoc.PC_Program__c).add(assoc);
            } else {
                caseMappingWithAssociation.put(assoc.PC_Program__c, new List<PC_Association__c>{assoc});
            }
        }

        for (PC_ProgramRegionUserHistory__c PRUHCreateRec : programRegionHistoryCreateList) {
            if (PRUHCreateListByCaseIds.containsKey(PRUHCreateRec.PC_Case__c)) {
                PRUHCreateListByCaseIds.get(PRUHCreateRec.PC_Case__c).add(PRUHCreateRec);
            } else {
                PRUHCreateListByCaseIds.put(PRUHCreateRec.PC_Case__c, new List<PC_ProgramRegionUserHistory__c>{PRUHCreateRec});
            }
        }
        PRUHDeleteListByCaseIds = createMapOfCaseIdAndDeletePRUHList(wcdOutputWrapper.recordIdWorkCaseDistDetailsWrapperMap, programRegionHistoryDeleteList);

        for (Id caseId : caseMappingWithAssociation.keySet()) {
            List<PC_Association__c> currentCaseAssociations = caseMappingWithAssociation.get(caseId);
            List<PC_ProgramRegionUserHistory__c> currentCaseCreatePRUHs = PRUHCreateListByCaseIds.get(caseId);
            /** currentCaseDeletePRUHs holds the list the PRUH records to be deleted based on the case engagement program, role and its region*/
            List<PC_ProgramRegionUserHistory__c> currentCaseDeletePRUHs = PRUHDeleteListByCaseIds.get(caseId);
            if (currentCaseAssociations == null) {
                currentCaseAssociations = new List<PC_Association__c>();
            }
            currentCaseCreatePRUHs = (currentCaseCreatePRUHs == null) ? new List<PC_ProgramRegionUserHistory__c>() : currentCaseCreatePRUHs;
            currentCaseDeletePRUHs = (currentCaseDeletePRUHs == null) ? new List<PC_ProgramRegionUserHistory__c>() : currentCaseDeletePRUHs;
            associationsBatchSize = associationsBatchSize + currentCaseAssociations.size();
            if (associationsBatchSize >= 200 && !associationsToBeInsertedInABatch.isEmpty()) {
                PC_WorkCaseDistributionHelper.WCDOutputWrapper wcdResultWrapper = new PC_WorkCaseDistributionHelper.WCDOutputWrapper();
                wcdResultWrapper.associationListToCreate = associationsToBeInsertedInABatch;
                wcdResultWrapper.programRegionHistoryCreateList = PRUHsToBeInsertedInABatch;
                wcdResultWrapper.programRegionHistoryDeleteList = PRUHsToBeDeletedInABatch;
                Id jobId = system.enqueueJob(new PC_AssociationsCreationFromCaseQueueable(wcdResultWrapper, handlerName));
                // reset batch parameter values once the Queue is called
                associationsBatchSize = 0;
                associationsToBeInsertedInABatch = new List<PC_Association__c>();
                PRUHsToBeInsertedInABatch = new List<PC_ProgramRegionUserHistory__c>();
                PRUHsToBeDeletedInABatch = new List<PC_ProgramRegionUserHistory__c>();
            }
            associationsToBeInsertedInABatch.addAll(currentCaseAssociations);
            PRUHsToBeInsertedInABatch.addAll(currentCaseCreatePRUHs);
            PRUHsToBeDeletedInABatch.addAll(currentCaseDeletePRUHs);
        }
        if (associationsToBeInsertedInABatch != null && !associationsToBeInsertedInABatch.isEmpty()) {
            // This block will ensure tha the Queueable Apex is called for the last batch items.
            // There is still a chance that we get more than 200 records to process
            // Splitting it in smaller batches can be considered. However, it may still lead to UNABLE_TO_LOCK_ROW error.
            // Hence, it is assumed that we will always be dealing with less than 200 associations to be inserted for a case.
            PC_WorkCaseDistributionHelper.WCDOutputWrapper wcdResultWrapper = new PC_WorkCaseDistributionHelper.WCDOutputWrapper();
            wcdResultWrapper.associationListToCreate = associationsToBeInsertedInABatch;
            wcdResultWrapper.programRegionHistoryCreateList = PRUHsToBeInsertedInABatch;
            wcdResultWrapper.programRegionHistoryDeleteList = PRUHsToBeDeletedInABatch;
            Id jobId = system.enqueueJob(new PC_AssociationsCreationFromCaseQueueable(wcdResultWrapper, handlerName));
        }
    }

    /**
    * This method is used to create a map of Case Id and list of PC_ProgramRegionUserHistory__c records for deletion
    * @param recordIdWorkCaseDistDetailsWrapperMap - recordIdWorkCaseDistDetailsWrapperMap
    * @param programRegionHistoryDeleteList - Program Region User History deletion List
    */
    public static Map<Id, List<PC_ProgramRegionUserHistory__c>> createMapOfCaseIdAndDeletePRUHList(Map<Id, PC_WorkCaseDistributionHelper.RecordIdWorkCaseDistDetailsWrapper> recordIdWorkCaseDistDetailsWrapperMap, List<PC_ProgramRegionUserHistory__c> PRUHDeleteList) {
        Map<Id, List<PC_ProgramRegionUserHistory__c>> PRUHDeleteListByCaseIds = new Map<Id, List<PC_ProgramRegionUserHistory__c>>();
        // Create a clone copy of PRUH list for manipulation
        List<PC_ProgramRegionUserHistory__c> newDeletePRUHList = PRUHDeleteList.deepClone(true, true, true);
        Boolean isEvaluated = false;
        Integer deletePRUHIndex = 0;
        /** Prepare a map of Case Id and list of PC_ProgramRegionUserHistory__c records based on case engagementProgram, Region and role **/
        for (Id recordId : recordIdWorkCaseDistDetailsWrapperMap.keySet()) {
            String caseId = recordIdWorkCaseDistDetailsWrapperMap.get(recordId).caseId;
            Set<Id> regionList = recordIdWorkCaseDistDetailsWrapperMap.get(recordId)?.regionIdSet;
            for (PC_ProgramRegionUserHistory__c PRUHDeleteRec : PRUHDeleteList) {
                isEvaluated = false;
                if (regionList != null && regionList.size() > 0) {
                    for (Id regionId : regionList) {
                        List<String> roleList = rolesByRegionMap.get(recordId);
                        if (roleList != null && roleList.size() > 0) {
                            for (String role : roleList) {
                                /** Comparing Program Region User History record's engagement program, region and role
                                * with the Case engagement program and its available region and role */
                                if (recordIdWorkCaseDistDetailsWrapperMap.get(recordId)?.engagementProgramId == PRUHDeleteRec.PC_EngagementProgram__c &&
                                        regionId == PRUHDeleteRec.PC_Region__c && role == PRUHDeleteRec.PC_CareTeamRole__c)
                                {
                                    if (PRUHDeleteListByCaseIds.containsKey(caseId)) {
                                        PRUHDeleteListByCaseIds.get(caseId).add(PRUHDeleteRec);
                                    } else {
                                        PRUHDeleteListByCaseIds.put(caseId, new List<PC_ProgramRegionUserHistory__c>{PRUHDeleteRec});
                                    }
                                    isEvaluated = true;
                                    deletePRUHIndex = newDeletePRUHList.indexOf(PRUHDeleteRec);
                                    if(deletePRUHIndex != -1) {
                                        /** Remove the ProgramRegionUserHistory record from the clonePRUH list to avoid putting
                                        * same History records to the another entries in PRUHDeleteListByCaseIds map.**/
                                        newDeletePRUHList.remove(deletePRUHIndex);
                                    }
                                    break;
                                }
                            }
                        }
                        if(isEvaluated){
                            break;
                        }
                    }
                }
            }
            /** Assign the clonePRUH to the Original PRUH List */
            PRUHDeleteList = newDeletePRUHList.deepClone(true, true, true);
        }
        return PRUHDeleteListByCaseIds;
    }

    /*********************************************************************************************************
    Class Name    : RecordIdWorkCaseDistDetailsWrapper
    Author        : Hitha Avalakki
    Description   : Wrapper class for record id and work case distribution details
    User-Story    : PC-4014
    **********************************************************************************************************/
    public inherited sharing class RecordIdWorkCaseDistDetailsWrapper {
        public Id recordId;
        public Id caseId;
        public Id manufacturerId;
        public Id engagementProgramId;
        public String zipCodeValue;
        public Id regionId;
        public Set<Id> regionIdSet;
        public Id accountId;
        public Id userId;
        public String role;

        public RecordIdWorkCaseDistDetailsWrapper() {
            zipCodeValue = '';
            role = '';
        }
    }

    /*********************************************************************************************************
    Class Name    :classesMapWithEngagementProgramsWrapper
    Author        : Pavankumar
    Description   : Wrapper class for engagement programs with default setting and classes map with engagement programs
    User-Story    : PC-8436
    **********************************************************************************************************/
    public inherited sharing class classesMapWithEngagementProgramsWrapper {
        public List<String> engagementProgramIdsWithDefaultSetting;
        public Map<String,Set<Id>> classesMappingWithEngagementPrograms;
        public Map<String, Set<String>> classesMappingWithRole;
        public classesMapWithEngagementProgramsWrapper() {
        }
    }

    /*********************************************************************************************************
    Class Name    :WCDOutputWrapper
    Author        : Satheesh Kumar
    Description   : Wrapper class for association list and PRUH create and delete records
    User-Story    : PC-8436
    **********************************************************************************************************/
    public inherited sharing class WCDOutputWrapper {
        public List<PC_Association__c> associationListToCreate;
        public List<PC_ProgramRegionUserHistory__c> programRegionHistoryCreateList;
        public List<PC_ProgramRegionUserHistory__c> programRegionHistoryDeleteList;
        public Map<Id, PC_WorkCaseDistributionHelper.RecordIdWorkCaseDistDetailsWrapper> recordIdWorkCaseDistDetailsWrapperMap;
        public WCDOutputWrapper() {
            associationListToCreate = new List<PC_Association__c>();
            programRegionHistoryCreateList = new List<PC_ProgramRegionUserHistory__c>();
            programRegionHistoryDeleteList = new List<PC_ProgramRegionUserHistory__c>();
            recordIdWorkCaseDistDetailsWrapperMap = new Map<Id, PC_WorkCaseDistributionHelper.RecordIdWorkCaseDistDetailsWrapper>();
        }
    }

    /*********************************************************************************************************
    Class Name    : PC_WorkCaseDistributionException
    Author        : Hitha Avalakki
    Description   : Exception class for Work Case Distribution
    User-Story    : PC-4014
    **********************************************************************************************************/
    public inherited sharing class PC_WorkCaseDistributionException extends Exception {
        public String errorMessage;
        public String errorCode;

        public PC_WorkCaseDistributionException(String message, String errorCode) {
            this.errorMessage = message;
            this.errorCode = errorCode;
        }
    }
}