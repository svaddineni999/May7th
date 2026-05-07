/**********************************************************************************************************
Class Name      : PC_EmbedSurveyController
Description     : This class will take care of generating survey invitations for PAP surveys for Account and Case records
Created By      : Hitha Avalakki
Created Date    : June 11,2021
Modification Log:
-----------------------------------------------------------------------------------------------------
Developer                   Date                           Description
-----------------------------------------------------------------------------------------------------
Hitha Avalakki              June 11,2021                    Initial Version
Hitha Avalakki              June 23,2021                    Added a nee callout to fetch default/configured PAP survey developer name. Removed reference to old custom metadata being used to fetch PAP survey name.
Hitha Avalakki              June 29,2021                    [PC-7462] Added code to populate survey invitation related object records and to fetch engagement program settings
Hitha Avalakki              July 08,2021                    [PC-7870] Added code to save survey category in Survey Invitation junction object. Code added to generate survey invitation name as per survey context.
Hitha Avalakki              Sept 06,2021                    [PC-8114] Added code in order to make it modular and resuable.
*********************************************************************************************************/

public with sharing class PC_EmbedSurveyController {

    @AuraEnabled
    public static String generateSurveyLink(String recordIdValue,String engagementProgramId,String surveyContext) {
        String surveyInvitationLink = '';
        SurveyDetailsWrapper surveyDetailsWrapper = new SurveyDetailsWrapper();

        try {

            if (String.isBlank(surveyContext) || surveyContext == 'null') {
                SurveyContextException surveyContextException = new SurveyContextException();
                surveyContextException.setMessage(Label.PC_InvalidWorkflowContextError);
                PC_Utility.logAndThrowException(surveyContextException);
            }

            /* Get the configured/default survey developer name of the Survey record for the respective engagement program */
            surveyDetailsWrapper.engagementProgramId = engagementProgramId;
            surveyDetailsWrapper.surveyContext = surveyContext;
            surveyDetailsWrapper.recordIdValue = recordIdValue;

            //Get survey developer name
            surveyDetailsWrapper.surveyDeveloperName = getSurveyName(surveyDetailsWrapper);

            /* Get the survey invitation link (either new or existing one) for the above survey record */
            surveyInvitationLink = getSurveyInvitationLink(surveyDetailsWrapper);

        } catch (Exception e) {
            PC_Utility.logAndThrowException(e, Label.PC_SurveyInvitationLinkError+ surveyDetailsWrapper.surveyDeveloperName );
        }

        return surveyInvitationLink;
    }

    /*********************************************************************************
    Method Name    : getSurveyName
    Author         : Hitha Avalakki
    Description    : Get the configured/default survey developer name of the Survey record for the respective engagement program
    Return Type    : String
    Parameter      : engagementProgramId, surveyContext
    *********************************************************************************/
    //public static String getSurveyName(String engagementProgramId,String surveyContext){
    public static String getSurveyName(SurveyDetailsWrapper surveyDetailsWrapper){
        String surveyDeveloperName;
        String engagementProgramCode;

        //FLS check for Engagement Program fields
        List<String> engagementProgramFields = new List<String>{
                'Id', PC_Constants.getQualifiedAPIName('PC_Program_Code__c')
        };
        PC_Database.assertAccess(PC_Constants.PC_ENGAGEMENT_PROGRAM, PC_Database.Operation.Reading, engagementProgramFields);

        //PC-7459: Fetch Program code for engagement program record
        if (surveyDetailsWrapper.engagementProgramId != null) {
            engagementProgramCode = [SELECT Id,PC_Program_Code__c FROM PC_Engagement_Program__c WHERE Id = :surveyDetailsWrapper.engagementProgramId][0].PC_Program_Code__c;
        }

        //PC-7459: Fetch PAP survey name configured for the respective engagement program
        if (!String.isBlank(engagementProgramCode)) {
            if (!String.isBlank(surveyDetailsWrapper.surveyContext) && surveyDetailsWrapper.surveyContext.equals('PC_PAP')) {
                surveyDeveloperName = PC_SYSTEM.getSettingByEngagementProgram(engagementProgramCode, PC_Constants.PATIENT_CONNECT_SETTING_PAP_SURVEY, PC_Constants.SETTINGS_TYPE.PATIENT_CONNECT_SETTING, PC_Constants.DEFAULT_PAP_SURVEY);

            } else if (!String.isBlank(surveyDetailsWrapper.surveyContext) && surveyDetailsWrapper.surveyContext.equals('PC_Copay')) {
                surveyDeveloperName = PC_SYSTEM.getSettingByEngagementProgram(engagementProgramCode, PC_Constants.PATIENT_CONNECT_SETTING_COPAY_SURVEY, PC_Constants.SETTINGS_TYPE.PATIENT_CONNECT_SETTING, PC_Constants.DEFAULT_COPAY_SURVEY);
            }
        }

        return surveyDeveloperName;
    }

    /*********************************************************************************
    Method Name    : getSurveyInvitationLink
    Author         : Hitha Avalakki
    Description    : Get the survey invitation link (either new or existing one) for the above survey record
    Return Type    : String
    Parameter      : recordIdValue,surveyDeveloperName,engagementProgramId,surveyContext
    *********************************************************************************/
    //public static String getSurveyInvitationLink(String recordIdValue,String surveyDeveloperName,String engagementProgramId,String surveyContext){
    public static String getSurveyInvitationLink(SurveyDetailsWrapper surveyDetailsWrapper){
        List<PC_SurveyInvitationRelatedObjects__c> surveyInvitationRelatedObjects = new List<PC_SurveyInvitationRelatedObjects__c>();
        List<SurveyInvitation> existingSurveyInvitations = new List<SurveyInvitation>();
        List<Id> surveyInvitationIds = new List<Id>();
        Survey surveyRecord;
        String surveyInvitationLink = '';

        //FLS check for Survey fields
        List<String> surveyFields = new List<String>{
                'Id'
        };
        PC_Database.assertAccess(PC_Constants.PC_SURVEY, PC_Database.Operation.Reading, surveyFields);
        //PC-7459: Fetch survey record details
        surveyRecord = [SELECT Id FROM Survey WHERE DeveloperName = :surveyDetailsWrapper.surveyDeveloperName];
        surveyDetailsWrapper.surveyRecord = surveyRecord;

        List<String> surveyInvitationRelatedObjectFields = new List<String>{
                PC_Constants.getQualifiedAPIName('PC_SurveyInvitation__c'), PC_Constants.getQualifiedAPIName('PC_Case__c'), PC_Constants.getQualifiedAPIName('PC_Account__c'), PC_Constants.getQualifiedAPIName('PC_EngagementProgram__c'), PC_Constants.getQualifiedAPIName('PC_SurveyCategory__c')
        };
        PC_Database.assertAccess(PC_Constants.PC_SURVEY_INVITATION_RELATED_OBJECT, PC_Database.Operation.Reading, surveyInvitationRelatedObjectFields);

        /* Fetch the Survey Invitation Related Object records for the Account/Case, Engagement Program and Survey Context combination */
        surveyInvitationRelatedObjects = [
                SELECT Id,PC_SurveyInvitation__c,PC_Case__c,PC_Account__c,PC_EngagementProgram__c,PC_SurveyCategory__c
                FROM PC_SurveyInvitationRelatedObjects__c
                WHERE (PC_Case__c = :surveyDetailsWrapper.recordIdValue OR PC_Account__c = :surveyDetailsWrapper.recordIdValue) AND
                PC_EngagementProgram__c = :surveyDetailsWrapper.engagementProgramId AND PC_SurveyInvitation__c != null AND
                PC_SurveyCategory__c = :surveyDetailsWrapper.surveyContext
        ];

        if (surveyInvitationRelatedObjects != null && !surveyInvitationRelatedObjects.isEmpty()) {
            //FLS check for Survey Invitation fields
            List<String> surveyInvitationFields = new List<String>{
                    'Id', 'Name', 'InvitationLink'
            };
            PC_Database.assertAccess(PC_Constants.PC_SURVEY_INVITATION, PC_Database.Operation.Reading, surveyInvitationFields);

            //PC-8114 : Create a list of survey invitation ids
            for(PC_SurveyInvitationRelatedObjects__c surveyInvitationRelatedObjectRecord: surveyInvitationRelatedObjects){
                surveyInvitationIds.add(surveyInvitationRelatedObjectRecord.PC_SurveyInvitation__c);
            }

            //PC-7459 : Fetch existing survey invitations for account/case record if any
            existingSurveyInvitations = [
                    SELECT Id,Name,InvitationLink,ResponseStatus
                    FROM SurveyInvitation
                    WHERE Id IN :surveyInvitationIds AND
                    SurveyId = :surveyRecord.Id AND
                    ResponseStatus != :PC_Constants.SURVEY_RESPONSE_STATUS_COMPLETED
            ];
        }

        if (existingSurveyInvitations != null && !existingSurveyInvitations.isEmpty()) {
            surveyInvitationLink = String.valueOf(existingSurveyInvitations[0].InvitationLink);
        }
        else{
            /* Create a new Survey Invitation */
            surveyInvitationLink = createNewSurveyInvitation(surveyDetailsWrapper);
        }

        return surveyInvitationLink;
    }

    /*********************************************************************************
    Method Name    : createNewSurveyInvitation
    Author         : Hitha Avalakki
    Description    : Create a new Survey Invitation
    Return Type    : String
    Parameter      : recordIdValue,surveyDeveloperName,engagementProgramId,surveyContext
    *********************************************************************************/
    //public static String createNewSurveyInvitation(String surveyContext,String recordIdValue,Survey surveyRecord,String engagementProgramId){
    public static String createNewSurveyInvitation(SurveyDetailsWrapper surveyDetailsWrapper){
        String surveyInvitationName = '';
        String surveyContextForSurveyInvitationName = '';
        String surveyInvitationLink = '';
        List<SurveyInvitation> surveyInvitationList = new List<SurveyInvitation>();

        //PC-7459: Generate survey invitation for Case/Account record
        SurveyInvitation surveyInvitation = new SurveyInvitation();
        surveyInvitation.SurveyId = surveyDetailsWrapper.surveyRecord.Id;

        SObjectType sobjectTypeValue = Id.valueOf(surveyDetailsWrapper.recordIdValue).getSobjectType();

        if (!String.isBlank(surveyDetailsWrapper.surveyContext) && surveyDetailsWrapper.surveyContext.equals('PC_PAP')) {
            surveyContextForSurveyInvitationName = Label.PC_PAPTitle;
        } else if (!String.isBlank(surveyDetailsWrapper.surveyContext) && surveyDetailsWrapper.surveyContext.equals('PC_Copay')) {
            surveyContextForSurveyInvitationName = Label.PC_CopayTitle;
        }
        if (Schema.Account.SObjectType == sobjectTypeValue) {

            //FLS check for Account fields
            List<String> accountFields = new List<String>{
                    'Id', 'Name'
            };
            PC_Database.assertAccess(PC_Constants.PC_ACCOUNT, PC_Database.Operation.Reading, accountFields);

            List<Account> accountRecords = [SELECT Id, Name FROM Account WHERE Id = :surveyDetailsWrapper.recordIdValue];

            List<Object> formattingArguments = new List<Object>{surveyContextForSurveyInvitationName,
                    Label.PC_ACCOUNT, accountRecords[0].Name
            };
            surveyInvitationName = String.format(Label.PC_SurveyInvitationName, formattingArguments);

        } else if (Schema.Case.SObjectType == sobjectTypeValue) {
            //FLS check for case fields
            List<String> caseFields = new List<String>{
                    'Id', 'AccountId', 'CaseNumber', PC_Constants.getQualifiedAPIName('PC_Engagement_Program__c')
            };
            PC_Database.assertAccess(PC_Constants.PC_CASE, PC_Database.Operation.Reading, caseFields);

            List<Case> caseRecords = [SELECT Id,CaseNumber FROM Case WHERE Id = :surveyDetailsWrapper.recordIdValue];
            if (caseRecords != null && !caseRecords.isEmpty()) {

                List<Object> formattingArguments = new List<Object>{surveyContextForSurveyInvitationName,
                        Label.PC_CASE, caseRecords[0].CaseNumber
                };
                surveyInvitationName = String.format(Label.PC_SurveyInvitationName, formattingArguments);
            }
        }
        surveyInvitation.Name = surveyInvitationName;
        surveyInvitationList.add(surveyInvitation);
        PC_Database.ins(surveyInvitationList);
        SurveyInvitation surveyInvRecord = [SELECT Id,InvitationLink,Name FROM SurveyInvitation WHERE Id = :surveyInvitationList[0].Id];
        surveyDetailsWrapper.surveyInvRecord = surveyInvRecord;
        surveyInvitationLink = String.valueOf(surveyInvRecord.InvitationLink);

        //Create Survey Invitation Related Object Record
        createSurveyInvitationRelatedObjectRecord(surveyDetailsWrapper);

        return surveyInvitationLink;
    }

    /*********************************************************************************
    Method Name    : createSurveyInvitationRelatedObjectRecord
    Author         : Hitha Avalakki
    Description    : create Survey Invitation Related Object Record
    Return Type    : void
    Parameter      : surveyInvRecord,recordIdValue,engagementProgramId,surveyContext
    *********************************************************************************/
    //public static void createSurveyInvitationRelatedObjectRecord(SurveyInvitation surveyInvRecord,String recordIdValue,String engagementProgramId,String surveyContext){
    public static void createSurveyInvitationRelatedObjectRecord(SurveyDetailsWrapper surveyDetailsWrapper){
        PC_SurveyInvitationRelatedObjects__c surveyInvitationRelatedObject = new PC_SurveyInvitationRelatedObjects__c();
        List<PC_SurveyInvitationRelatedObjects__c> surveyInvitationRelatedObjectList = new List<PC_SurveyInvitationRelatedObjects__c>();

        if (Id.valueOf(surveyDetailsWrapper.recordIdValue).getSobjectType() == Schema.Account.SObjectType) {
            surveyInvitationRelatedObject.PC_Account__c = Id.valueOf(surveyDetailsWrapper.recordIdValue);
        } else if (Id.valueOf(surveyDetailsWrapper.recordIdValue).getSobjectType() == Schema.Case.SObjectType) {
            surveyInvitationRelatedObject.PC_Case__c = Id.valueOf(surveyDetailsWrapper.recordIdValue);

            List<Case> caseList = [SELECT Id,AccountId FROM Case WHERE Id = :surveyDetailsWrapper.recordIdValue];

            if (caseList != null && !caseList.isEmpty() && caseList[0].AccountId != null) {
                surveyInvitationRelatedObject.PC_Account__c = caseList[0].AccountId;
            }
        }
        surveyInvitationRelatedObject.PC_SurveyInvitation__c = surveyDetailsWrapper.surveyInvRecord.Id;
        surveyInvitationRelatedObject.PC_EngagementProgram__c = surveyDetailsWrapper.engagementProgramId;
        surveyInvitationRelatedObject.PC_SurveyCategory__c = surveyDetailsWrapper.surveyContext;

        surveyInvitationRelatedObjectList.add(surveyInvitationRelatedObject);

        PC_Database.ins(surveyInvitationRelatedObjectList);

    }

    public class SurveyDetailsWrapper{
        public String recordIdValue{get;set;}
        public String engagementProgramId{get;set;}
        public String surveyContext{get;set;}
        public String surveyDeveloperName{get;set;}
        public Survey surveyRecord{get;set;}
        public SurveyInvitation surveyInvRecord{get;set;}

        SurveyDetailsWrapper(){
        }
    }

    public class SurveyContextException extends Exception {}
}