/**
 Class Name     : PC_WCDDefaultService
 Author         : Pavankumar
 Description    : This class is used to create Associations for all the 'Program Region Records' received
 User-Story     : PC-8232
 */

public with sharing class PC_WCDDefaultService implements PC_WCD.UserMappingFinder{

/*********************************************************************************************************************************************
Method Name    : createAssociations
Author         : Pavankumar
Description    : This method is used to create Associations for all the 'Program Region Records' received
Return Type    : List<PC_Association__c>
Parameter      : List<PC_ProgramRegionUserMapping__c>, Map<Id, Id>
User-Story     : PC-8232
*********************************************************************************************************************************************/
    public PC_WCD.FindMapperResponse findMapper(PC_WCD.FindMapperRequest request) {
        List<PC_WCD.programRegionUsersMappingByEngagementPrograms> programRegionUsersMappingByEngagementProgramsClass = new List<PC_WCD.programRegionUsersMappingByEngagementPrograms>();
        List<PC_WCD.programRegionUsersHistoryMappingByEngagementPrograms> programRegionUsersHistoryMappingByEngagementProgramsClass = new List<PC_WCD.programRegionUsersHistoryMappingByEngagementPrograms>();
        Map<Id, PC_WCD.caseDetails> caseRecordIdMappingWithCaseDetails = new Map<Id, PC_WCD.caseDetails>();
        Map<Id, List<PC_ProgramRegionUserMapping__c>> ProgramRegionMappingWithEngagement = new Map<Id, List<PC_ProgramRegionUserMapping__c>>();
        Map<Id, List<PC_ProgramRegionUserHistory__c>> programRegionUsersHistoryMappingByEngagement = new Map<Id, List<PC_ProgramRegionUserHistory__c>>();
        Map<Id, List<PC_ProgramRegionUserMapping__c>> caseMappingWithRequiredProgramRegionUserMappingRecords = new Map<Id, List<PC_ProgramRegionUserMapping__c>>();
        Set<Id> regionIdSet = new Set<Id>();
        programRegionUsersMappingByEngagementProgramsClass = request.programRegionUsersMappingByEngPrograms;
        programRegionUsersHistoryMappingByEngagementProgramsClass = request.programRegionUsersHistoryMappingByEngPrograms;
        caseRecordIdMappingWithCaseDetails = request.caseIdMapWithCaseDetails;
        for (PC_WCD.programRegionUsersMappingByEngagementPrograms classRecord : programRegionUsersMappingByEngagementProgramsClass) {
            ProgramRegionMappingWithEngagement.put(classRecord.engagementProgram, classRecord.programRegionUserMappingsByRoles) ;
        }
        for (PC_WCD.programRegionUsersHistoryMappingByEngagementPrograms historyClassRecord : programRegionUsersHistoryMappingByEngagementProgramsClass) {
            programRegionUsersHistoryMappingByEngagement.put(historyClassRecord.engagementProgramId, historyClassRecord.programRegionUserHistoryRecords);
        }

        for(Id caserecordId : caseRecordIdMappingWithCaseDetails.keySet()){
            Set<PC_ProgramRegionUserMapping__c> programRegionUserMappingsSet = new Set<PC_ProgramRegionUserMapping__c>();
            regionIdSet = caseRecordIdMappingWithCaseDetails.get(caserecordId).regionSetId;
            for(Id regionId:regionIdSet){
                List<PC_ProgramRegionUserMapping__c> programRegionsList = new List<PC_ProgramRegionUserMapping__c>();
                for (PC_ProgramRegionUserMapping__c programregionrecord : ProgramRegionMappingWithEngagement.get(caseRecordIdMappingWithCaseDetails.get(caserecordId).engagementProgramId)) {
                    if (programregionrecord.PC_EngagementProgram__c == caseRecordIdMappingWithCaseDetails.get(caserecordId).engagementProgramId && programregionrecord.PC_Region__c == regionId) {
                        programRegionsList.add(programregionrecord);
                    }
                }
                programRegionUserMappingsSet.addAll(programRegionsList);
            }
            system.debug('programRegionUserMappingsSet is '+programRegionUserMappingsSet);
            if(caseMappingWithRequiredProgramRegionUserMappingRecords.keySet().contains(caserecordId)){
                List<PC_ProgramRegionUserMapping__c> programRegionUserMappingsList = caseMappingWithRequiredProgramRegionUserMappingRecords.get(caserecordId);
                programRegionUserMappingsList.addAll(programRegionUserMappingsSet);
                caseMappingWithRequiredProgramRegionUserMappingRecords.put(caserecordId, programRegionUserMappingsList);
            }else{
                List<PC_ProgramRegionUserMapping__c> listOfProgramRegionUserMappings = new List<PC_ProgramRegionUserMapping__c>();
                listOfProgramRegionUserMappings.addAll(programRegionUserMappingsSet);
                caseMappingWithRequiredProgramRegionUserMappingRecords.put(caserecordId, listOfProgramRegionUserMappings);
            }
        }

        system.debug('caseMappingWithRequiredProgramRegionUserMappingRecords is '+caseMappingWithRequiredProgramRegionUserMappingRecords);
        PC_WCD.FindMapperResponse pcd = new PC_WCD.FindMapperResponse();
        pcd.programRegionUserMappingsByCase = caseMappingWithRequiredProgramRegionUserMappingRecords;
        return pcd;
    }

}