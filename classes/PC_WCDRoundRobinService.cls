/**
 Class Name     : PC_WCDRoundRobinService
 Author         : Pavankumar
 Description    : This class is used to fetch 'Program Region Records' that needs Association to be created for a 'Case'
 User-Story     : PC-8123
 */

public with sharing class PC_WCDRoundRobinService implements PC_WCD.UserMappingFinder {

    public PC_WCD.FindMapperResponse findMapper(PC_WCD.FindMapperRequest request) {
        Map<Id, List<PC_ProgramRegionUserMapping__c>> ProgramRegionMappingWithEngagement = new Map<Id, List<PC_ProgramRegionUserMapping__c>>();
        List<PC_WCD.programRegionUsersMappingByEngagementPrograms> programRegionUsersMappingByEngagementProgramsClass = new List<PC_WCD.programRegionUsersMappingByEngagementPrograms>();
        List<PC_WCD.programRegionUsersHistoryMappingByEngagementPrograms> programRegionUsersHistoryMappingByEngagementProgramsClass = new List<PC_WCD.programRegionUsersHistoryMappingByEngagementPrograms>();
        Map<Id, PC_WCD.caseDetails> caseRecordIdMappingWithCaseDetails = new Map<Id, PC_WCD.caseDetails>();
        Map<Id, List<PC_ProgramRegionUserHistory__c>> programRegionUsersHistoryMappingByEngagement = new Map<Id, List<PC_ProgramRegionUserHistory__c>>();
        Set<String> careTeamRoles = new Set<String>();
        Set<Id> regionIdSet = new Set<Id>();
        Map<Id, List<PC_ProgramRegionUserMapping__c>> caseMappingWithRequiredProgramRegionUserMappingRecords;

        programRegionUsersMappingByEngagementProgramsClass = request.programRegionUsersMappingByEngPrograms;
        programRegionUsersHistoryMappingByEngagementProgramsClass = request.programRegionUsersHistoryMappingByEngPrograms;
        caseRecordIdMappingWithCaseDetails = request.caseIdMapWithCaseDetails;
        for (PC_WCD.programRegionUsersMappingByEngagementPrograms classRecord : programRegionUsersMappingByEngagementProgramsClass) {
            ProgramRegionMappingWithEngagement.put(classRecord.engagementProgram, classRecord.programRegionUserMappingsByRoles) ;
        }
        for (PC_WCD.programRegionUsersHistoryMappingByEngagementPrograms historyClassRecord : programRegionUsersHistoryMappingByEngagementProgramsClass) {
            programRegionUsersHistoryMappingByEngagement.put(historyClassRecord.engagementProgramId, historyClassRecord.programRegionUserHistoryRecords);
        }

        caseMappingWithRequiredProgramRegionUserMappingRecords = new Map<Id, List<PC_ProgramRegionUserMapping__c>>();
        Map<String,PC_ProgramRegionUserMapping__c> historyForCase = new Map<String,PC_ProgramRegionUserMapping__c>();
        for (Id caserecordId : caseRecordIdMappingWithCaseDetails.keySet()) {

            regionIdSet = caseRecordIdMappingWithCaseDetails.get(caserecordId).regionSetId ;
            for(Id regionId:regionIdSet){
                List<PC_ProgramRegionUserMapping__c> programRegionsListForCase = getMappingsForRegionByEngagementProgramId(caseRecordIdMappingWithCaseDetails.get(caserecordId).engagementProgramId, regionId, ProgramRegionMappingWithEngagement.get(caseRecordIdMappingWithCaseDetails.get(caserecordId).engagementProgramId));
                List<PC_ProgramRegionUserMapping__c> toBeAssignedCaseMappings = new List<PC_ProgramRegionUserMapping__c>();
                List<PC_ProgramRegionUserMapping__c> programRegionsForRole = new List<PC_ProgramRegionUserMapping__c>();
                PC_ProgramRegionUserMapping__c programRegionToBeAssigned = new PC_ProgramRegionUserMapping__c();
                Set<PC_ProgramRegionUserMapping__c> listOfProgramRegionsToBeAssigned = new Set<PC_ProgramRegionUserMapping__c>();
                String role;
                for (PC_ProgramRegionUserMapping__c programregionusermapping : programRegionsListForCase) {
                    PC_ProgramRegionUserHistory__c latestHistoryRecord;
                    if (role != programregionusermapping.PC_CareTeamRole__c) {
                        role = programregionusermapping.PC_CareTeamRole__c;
                        programRegionsForRole = getProgramRegionsForRole(role, programRegionsListForCase);
                        String uniquekey = String.valueOf(caseRecordIdMappingWithCaseDetails.get(caserecordId).engagementProgramId) + '-' + String.valueOf(regionId) + '-' + String.valueOf(role);
                        if(historyForCase.containsKey(uniquekey)){
                            PC_ProgramRegionUserMapping__c programRegionRecord = historyForCase.get(uniquekey);
                            Integer indexOfLastProgramRegionRecord = programRegionsForRole.indexOf(programRegionRecord);
                            Integer maxIndex = programRegionsForRole.size()-1;
                            Integer indexOfNextProgramRegionRecord;
                            if(indexOfLastProgramRegionRecord == 0 && programRegionsForRole.size() == 1){
                                indexOfNextProgramRegionRecord = 0;
                                programRegionToBeAssigned = programRegionsForRole[indexOfNextProgramRegionRecord];
                                historyForCase.put(uniquekey,programRegionToBeAssigned);
                                listOfProgramRegionsToBeAssigned.add(programRegionToBeAssigned);
                            }else if (indexOfLastProgramRegionRecord == 0 && programRegionsForRole.size() != 1){
                                indexOfNextProgramRegionRecord = 1;
                                programRegionToBeAssigned = programRegionsForRole[indexOfNextProgramRegionRecord];
                                historyForCase.put(uniquekey,programRegionToBeAssigned);
                                listOfProgramRegionsToBeAssigned.add(programRegionToBeAssigned);
                            }
                            else if(indexOfLastProgramRegionRecord == maxIndex){
                                indexOfNextProgramRegionRecord =  0;
                                programRegionToBeAssigned = programRegionsForRole[indexOfNextProgramRegionRecord];
                                historyForCase.put(uniquekey,programRegionToBeAssigned);
                                listOfProgramRegionsToBeAssigned.add(programRegionToBeAssigned);
                            }else {
                                indexOfNextProgramRegionRecord = indexOfLastProgramRegionRecord + 1;
                                programRegionToBeAssigned = programRegionsForRole[indexOfNextProgramRegionRecord];
                                historyForCase.put(uniquekey,programRegionToBeAssigned);
                                listOfProgramRegionsToBeAssigned.add(programRegionToBeAssigned);
                            }
                        }else{
                            List<PC_ProgramRegionUserHistory__c> programHistoryRegionMapWithCaseForRole = new List<PC_ProgramRegionUserHistory__c>();
                            if (programRegionUsersHistoryMappingByEngagement.containsKey(caseRecordIdMappingWithCaseDetails.get(caserecordId).engagementProgramId)) {
                                for (PC_ProgramRegionUserHistory__c historyrecord : programRegionUsersHistoryMappingByEngagement.get(caseRecordIdMappingWithCaseDetails.get(caserecordId).engagementProgramId)) {
                                    if (historyrecord.PC_EngagementProgram__c == caseRecordIdMappingWithCaseDetails.get(caserecordId).engagementProgramId && historyrecord.PC_Region__c == regionId && historyrecord.PC_CareTeamRole__c == role) {
                                        programHistoryRegionMapWithCaseForRole.add(historyrecord);
                                    }
                                }
                            }

                            if (programHistoryRegionMapWithCaseForRole.size() > 0 || !programHistoryRegionMapWithCaseForRole.isEmpty()) {
                                latestHistoryRecord = getLatestCreatedHistoryRecordForRole(role, programHistoryRegionMapWithCaseForRole);
                                programRegionToBeAssigned = getToBeAssignedMapping(latestHistoryRecord, programRegionsForRole);
                                historyForCase.put(uniquekey,programRegionToBeAssigned);
                                listOfProgramRegionsToBeAssigned.add(programRegionToBeAssigned);
                            } else {
                                programRegionToBeAssigned = programRegionsForRole[0];
                                historyForCase.put(uniquekey,programRegionToBeAssigned);
                                listOfProgramRegionsToBeAssigned.add(programRegionToBeAssigned);
                            }
                        }
                    }
                }
                if(caseMappingWithRequiredProgramRegionUserMappingRecords.keySet().contains(caserecordId)){
                    List<PC_ProgramRegionUserMapping__c> programRegionUserMappingsList = caseMappingWithRequiredProgramRegionUserMappingRecords.get(caserecordId);
                    programRegionUserMappingsList.addAll(listOfProgramRegionsToBeAssigned);
                    caseMappingWithRequiredProgramRegionUserMappingRecords.put(caserecordId, programRegionUserMappingsList);
                }else{
                    List<PC_ProgramRegionUserMapping__c> listOfProgramRegionUserMappings = new List<PC_ProgramRegionUserMapping__c>();
                    listOfProgramRegionUserMappings.addAll(listOfProgramRegionsToBeAssigned);
                    caseMappingWithRequiredProgramRegionUserMappingRecords.put(caserecordId, listOfProgramRegionUserMappings);
                }
            }
        }

        PC_WCD.FindMapperResponse pcd = new PC_WCD.FindMapperResponse();
        pcd.programRegionUserMappingsByCase = caseMappingWithRequiredProgramRegionUserMappingRecords;
        return pcd;

    }

    /**
     * This method is used to group the Program Region User Mapping records by respective Engagement Program and a Region
     * User-Story : PC-8123
     * @param engagementProgramId - engagement program Id
     * @param regionId - region Id
     * @param programRegionListForCase - list of program region user mapping records
     *
     * @return - list of program region user mapping records
     */
    private static List<PC_ProgramRegionUserMapping__c> getMappingsForRegionByEngagementProgramId(Id engagementProgramId, Id regionId, List<PC_ProgramRegionUserMapping__c> programRegionListForCase) {

        List<PC_ProgramRegionUserMapping__c> programRegionsList = new List<PC_ProgramRegionUserMapping__c>();
        for (PC_ProgramRegionUserMapping__c programregionrecord : programRegionListForCase) {
            if (programregionrecord.PC_EngagementProgram__c == engagementProgramId && programregionrecord.PC_Region__c == regionId) {
                programRegionsList.add(programregionrecord);
            }
        }
        return programRegionsList;
    }

    /**
     * This method is used to get the latest created Program Region User History by respective Engagement Program, Region and Role
     * User-Story : PC-8123
     * @param role - role
     * @param programHistoryRegionMapWithCase - list of program region user mapping history records
     *
     * @return - program region user mapping history record
     */
    private static PC_ProgramRegionUserHistory__c getLatestCreatedHistoryRecordForRole(String role, List<PC_ProgramRegionUserHistory__c> programHistoryRegionMapWithCase) {
        PC_ProgramRegionUserHistory__c programRegionHistoryRecord = new PC_ProgramRegionUserHistory__c();
        List<PC_ProgramRegionUserHistory__c> programRegionHistoryRecords = new List<PC_ProgramRegionUserHistory__c>();
        List<Datetime> lastModifiedDates = new List<Datetime>();
        Map<Datetime, PC_ProgramRegionUserHistory__c> lastModifiedDateProgramRegionHistoryMap = new Map<Datetime, PC_ProgramRegionUserHistory__c>();
        PC_ProgramRegionUserHistory__c latestModifiedHistoryRecord = new PC_ProgramRegionUserHistory__c();
        for (PC_ProgramRegionUserHistory__c pghistory : programHistoryRegionMapWithCase) {
            if (pghistory.PC_CareTeamRole__c == role) {
                programRegionHistoryRecords.add(pghistory);
            }
        }

        for (PC_ProgramRegionUserHistory__c historyrecord : programRegionHistoryRecords) {
            lastModifiedDates.add(historyrecord.LastModifiedDate);
            lastModifiedDateProgramRegionHistoryMap.put(historyrecord.LastModifiedDate, historyrecord);
        }
        lastModifiedDates.sort();
        Datetime latestModifiedDate = lastModifiedDates[lastModifiedDates.size() - 1];
        if (lastModifiedDateProgramRegionHistoryMap.containsKey(latestModifiedDate)) {
            latestModifiedHistoryRecord = lastModifiedDateProgramRegionHistoryMap.get(latestModifiedDate);
        }
        return latestModifiedHistoryRecord;
    }

    /**
     * This method is used to get the Program Region User Mappings for a Role of respective Engagement Program & Region
     * User-Story : PC-8123
     * @param role - role
     * @param programRegionsList - list of program region user mapping records
     *
     * @return - list of program region user mapping records
     */
    private static List<PC_ProgramRegionUserMapping__c> getProgramRegionsForRole(String role, List<PC_ProgramRegionUserMapping__c> programRegionsList) {
        List<PC_ProgramRegionUserMapping__c> programRegionRecordsList = new List<PC_ProgramRegionUserMapping__c>();
        for (PC_ProgramRegionUserMapping__c programregion : programRegionsList) {
            if (programregion.PC_CareTeamRole__c == role) {
                programRegionRecordsList.add(programregion);
            }
        }
        return programRegionRecordsList;
    }

    /**
     * This method is used to get the Program Region User Mapping record for which Associate record needs to be created for a specific role, engagement program and region
     * User-Story : PC-8123
     * @param historyRecord - program region user mapping history record
     * @param ProgramRegionRecordList - list of program region user mapping records
     *
     * @return - program region user mapping record
     */
    private static PC_ProgramRegionUserMapping__c getToBeAssignedMapping(PC_ProgramRegionUserHistory__c historyRecord, List<PC_ProgramRegionUserMapping__c> ProgramRegionRecordList) {
        PC_ProgramRegionUserMapping__c programRegionToAssociate = new PC_ProgramRegionUserMapping__c();
        PC_ProgramRegionUserMapping__c programRegionWithLatestHistory = new PC_ProgramRegionUserMapping__c();
        Integer indexOfProgramRegionWithLatestHistory;
        //get the index of each prum record
        Integer index = 0;
        Integer requiredIndex;
        Integer maximumIndex = ProgramRegionRecordList.size();
        Map<PC_ProgramRegionUserMapping__c, Integer> programRegionIndexMap = new Map<PC_ProgramRegionUserMapping__c, Integer>();
        Map<Integer, PC_ProgramRegionUserMapping__c> indexMappingWithProgramRegions = new Map<Integer, PC_ProgramRegionUserMapping__c>();
        for (PC_ProgramRegionUserMapping__c programRegionUserRecord : ProgramRegionRecordList) {
            index = index + 1;
            programRegionIndexMap.put(programRegionUserRecord, index);
            indexMappingWithProgramRegions.put(index, programRegionUserRecord);
        }
        //fetch the program region record thats needs to be associated
        for (PC_ProgramRegionUserMapping__c programregionusermapping : ProgramRegionRecordList) {
            if ((programregionusermapping.PC_CareTeamMember__c != null && programregionusermapping.PC_CareTeamMember__c == historyRecord.PC_CareTeamUser__c) || (programregionusermapping.PC_CareTeamAccount__c != null && programregionusermapping.PC_CareTeamAccount__c == historyRecord.PC_CareTeamAccount__c)) {
                programRegionWithLatestHistory = programregionusermapping;
                break;
            }
        }
        if (programRegionIndexMap.containsKey(programRegionWithLatestHistory)) {
            indexOfProgramRegionWithLatestHistory = programRegionIndexMap.get(programRegionWithLatestHistory);
        }
        if ((indexOfProgramRegionWithLatestHistory == maximumIndex && indexMappingWithProgramRegions.containsKey(1)) || (indexOfProgramRegionWithLatestHistory == null && indexMappingWithProgramRegions.containsKey(1))){
            programRegionToAssociate = indexMappingWithProgramRegions.get(1);
        } else if(indexOfProgramRegionWithLatestHistory != null){
            requiredIndex = indexOfProgramRegionWithLatestHistory + 1;
            if (indexMappingWithProgramRegions.containsKey(requiredIndex)) {
                programRegionToAssociate = indexMappingWithProgramRegions.get(requiredIndex);
            }
        }

        return programRegionToAssociate;
    }

}