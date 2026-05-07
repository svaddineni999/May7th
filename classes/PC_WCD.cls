/**
 * Created By       : Pavankumar
 * Created Date     : 8/19/2021
 * Description      : This interface is implemented by class for assigning Associate records for the cases by using WCD logic.
 */
/***********************************************************************************************************************
Class Name  : PC_WCD
Author       : Pavankumar
Description  : Purpose of this class is to process the logic for creating Association records by fetching Program Region User Mappings and Program Region User Histories for respective Engagement Programs and will return list of Program Region User Mappings that needs Association for respective cases.
Return Type  : Map<Id,List<PC_ProgramRegionUserMapping__c>> programRegionUserMappingsByCase
Parameters   : List<programRegionUsersMappingByEngagementPrograms> programRegionUsersMappingByEngPrograms, List<programRegionUsersHistoryMappingByEngagementPrograms> programRegionUsersHistoryMappingByEngPrograms, Map<Id,caseDetails> caseIdMapWithCaseDetails
User-Story   : PC-8123
***********************************************************************************************************************/
global with sharing class PC_WCD {
    /**
     * Interface to fetch Program Region User Mapping Records for respective cases
     */
    global interface UserMappingFinder {
        /**
         * Fetches Program Region User Mapping Records for respective cases
         *
         * @param request Wrappers of program region user mappings with engagement programs, program region user history mappings with engagement programs and case Id mapping with case detaiks
         *
         * @return Program Region User Mappings with respective Case Ids
         */
        FindMapperResponse findMapper(FindMapperRequest request);
    }

    /**
     * Contains the response of performing an action
     */
    global inherited sharing class FindMapperResponse {
        /**
         * Contains the Case Id mapping with Program Region User Mapping records for which Associate records needs to be created
         */
        global Map<Id, List<PC_ProgramRegionUserMapping__c>> programRegionUserMappingsByCase;
    }

    /**
     * Contains the request of performing an action
     */
    global inherited sharing class FindMapperRequest {

        /**
         * Contains the wrapper of program region user mapping records with engagement programs
         */
        global List<programRegionUsersMappingByEngagementPrograms> programRegionUsersMappingByEngPrograms;
        /**
         * Contains the wrapper of program region user history mapping records with engagement programs
         */
        global List<programRegionUsersHistoryMappingByEngagementPrograms> programRegionUsersHistoryMappingByEngPrograms;
        /**
         * Contains the map of case Id & case details
         */
        global Map<Id, caseDetails> caseIdMapWithCaseDetails;

        global FindMapperRequest() {

        }

    }

    /**
     * This is a wrapper of program region user mapping records with engagement programs
     */
    global inherited sharing class programRegionUsersMappingByEngagementPrograms {
        /**
         * Engagement Program Id
         */
        global Id engagementProgram;
        /**
         * List of Program Region User Mapping records
         */
        global List<PC_ProgramRegionUserMapping__c> programRegionUserMappingsByRoles;
    }

    /**
     * This is a wrapper of program region user history mapping records with engagement programs
     */
    global inherited sharing class programRegionUsersHistoryMappingByEngagementPrograms {
        /**
         * Engagement Program Id
         */
        global Id engagementProgramId;
        /**
         * List of Program Region User History records
         */
        global List<PC_ProgramRegionUserHistory__c> programRegionUserHistoryRecords;
    }

    /**
     * This is a wrapper of case Id, case's engagement program Id and case's region Id
     */
    global inherited sharing class caseDetails {
        /**
         * Case Id
         */
        global Id caseId;
        /**
         * Engagement Program Id
         */
        global Id engagementProgramId;
        /**
         * Region Id
         */
        global Id regionId;
        /**
         * Set of Region Ids
         */
        global Set<Id> regionSetId;
    }

}