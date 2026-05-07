/*********************************************************************************************************
Class Name      : PC_SendAdverseEventEmailController
Description     :
Created By      : Deloitte
Created Date    :
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer                  Date                   Description
Kanteti Kishore           May 5,2020             [PC-5940]Adverse Event Report Mailing feature-Controller for PC_SendAdverseEventEmail Component
Haritha Reddy             May 12,2020            [PC-6249]Added limit 2000 for inner SOQL Queries(Force Reviewer Scan Issue)
Haritha Reddy           21-Jan-2021             [PC-7102] Added FLS Check
Vijay Kashikar          21-Jan-2021              [PC-7102] Added sharing clause
****************************************************************************************************************/
public with sharing class PC_SendAdverseEventEmailController {
    private static final String ADVERSE_EVENT = 'Adverse Event';
    private static final String ADVERSE_EVENT2 = 'Adverse Event 2';


    @AuraEnabled
    public static EmailAddressAndTemplatesWrapper getEmailAddressAndTemplateDetails(Id adverseEventRecordId){
        EmailAddressAndTemplatesWrapper emailAddressAndTemplatesWrapper = new EmailAddressAndTemplatesWrapper();
        try {
            emailAddressAndTemplatesWrapper.orgWideEmailAddressWrapperList = getOrgWideEmailAddressList();

            eLetterTemplateDetailsAndEmailAddressMapWrapper eLetterTemplateDetailsAndEmailAddressMapWrapper = new eLetterTemplateDetailsAndEmailAddressMapWrapper();
            eLetterTemplateDetailsAndEmailAddressMapWrapper = getELetterTemplateList(adverseEventRecordId);

            emailAddressAndTemplatesWrapper.eLetterTemplateWrapperList = eLetterTemplateDetailsAndEmailAddressMapWrapper.eLetterTemplateWrapperList;
            emailAddressAndTemplatesWrapper.eLetterTemplateIdAndConfiguredRecipientsMap = eLetterTemplateDetailsAndEmailAddressMapWrapper.eLetterTemplateIdAndConfiguredRecipientsMap;


        }catch (Exception ex){
            PC_Utility.logAndThrowException(ex);
        }
        return emailAddressAndTemplatesWrapper;
    }

    @AuraEnabled
    public static List<OrgWideEmailAddressWrapper> getOrgWideEmailAddressList(){
        List<OrgWideEmailAddressWrapper> orgWideEmailAddressWrappers = new List<OrgWideEmailAddressWrapper>();
        try {
            //Patient Connect Setting Not Required
            String emailAddressString = PC_SYSTEM.getPatientConnectSetting(PC_Constants.PC_AdverseEventEmailAddressSettingName, '');
            if (!String.isBlank(emailAddressString) && emailAddressString.contains(',')) {
                for (String emailAddress : emailAddressString.split(',')) {
                    OrgWideEmailAddressWrapper orgWideEmailAddressWrapper = new OrgWideEmailAddressWrapper();
                    orgWideEmailAddressWrapper.orgWideEmailAddress = emailAddress;

                    orgWideEmailAddressWrappers.add(orgWideEmailAddressWrapper);
                }
            } else {
                OrgWideEmailAddressWrapper orgWideEmailAddressWrapper = new OrgWideEmailAddressWrapper();
                orgWideEmailAddressWrapper.orgWideEmailAddress = emailAddressString;
                orgWideEmailAddressWrappers.add(orgWideEmailAddressWrapper);
            }
        }catch (Exception ex){
            PC_Utility.logAndThrowException(ex);
        }
        return orgWideEmailAddressWrappers;
    }


    @AuraEnabled
    public static eLetterTemplateDetailsAndEmailAddressMapWrapper getELetterTemplateList(Id adverseEventRecordId){
        eLetterTemplateDetailsAndEmailAddressMapWrapper eLetterTemplateDetailsAndEmailAddressMapWrapper = new eLetterTemplateDetailsAndEmailAddressMapWrapper();
        try {
            List<eLetterTemplateWrapper> eLetterTemplateWrapperList = new List<eLetterTemplateWrapper>();
            Map<String, List<recipientDetailsWrapper>> eLetterTemplateIdAndEmailRecipientsMap = new Map<String, List<recipientDetailsWrapper>>();
            String objectType = String.valueOf(adverseEventRecordId.getSobjectType());
            Map<Id, PC_eLetter__c> eLetterMap ;
            PC_AdverseEvent__c adverseEventRecord = new PC_AdverseEvent__c();
            PC_AdverseEvent2__c adverseEvent2Record = new PC_AdverseEvent2__c();
            List<PC_Engagement_Program_Eletter__c> engagementProgramEletterList = new List<PC_Engagement_Program_Eletter__c>();

            //FLS Check
            List<String> eLetterFields = new List<String>{'Name',PC_Constants.getQualifiedAPIName('PC_Template_Name__c'),
                    PC_Constants.getQualifiedAPIName('PC_Send_to_User__c'),PC_Constants.getQualifiedAPIName('PC_Allow_Send_to_Patient__c'),
                    PC_Constants.getQualifiedAPIName('PC_Target_Recipients__c'),PC_Constants.getQualifiedAPIName('PC_Source_Object__c')
            };

            List<String> engagementProgramEletterFields = new List<String>{
                    'Id', PC_Constants.getQualifiedAPIName('PC_eLetter__c'),PC_Constants.getQualifiedAPIName('PC_PreConfiguredEmailRecipients__c'),
                    PC_Constants.getQualifiedAPIName('PC_Engagement_Program__c')
            };

            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_eLetter__c'), PC_Database.Operation.Reading, eLetterFields);
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Engagement_Program_Eletter__c'), PC_Database.Operation.Reading, engagementProgramEletterFields);

            if (objectType == PC_Constants.getQualifiedApiName(PC_Constants.PC_AdverseEvent_Object)) {

                eLetterMap = new Map<Id,PC_eLetter__c>([
                        SELECT Id, Name, PC_Template_Name__c, PC_Send_to_User__c, PC_Allow_Send_to_Patient__c,PC_Target_Recipients__c,
                        (SELECT Id,PC_Engagement_Program__r.Name,PC_PreConfiguredEmailRecipients__c,PC_eLetter__c,PC_Engagement_Program__c FROM Engagement_Program_eLetter__r LIMIT 2000)
                        FROM PC_eLetter__c
                        WHERE PC_Source_Object__c = :ADVERSE_EVENT
                ]);
                //FLS Check
                List<String> adverseEventFields = new List<String>{PC_Constants.getQualifiedAPIName('PC_Care_Program__c'),
                        PC_Constants.getQualifiedAPIName('PC_Care_Program__r')+'.'+PC_Constants.getQualifiedAPIName('PC_Engagement_Program__c')};
                PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_AdverseEvent__c'), PC_Database.Operation.Reading, adverseEventFields);

                adverseEventRecord = [
                        SELECT Id,PC_Care_Program__c, PC_Care_Program__r.PC_Engagement_Program__c
                        FROM PC_AdverseEvent__c
                        WHERE Id = :adverseEventRecordId
                ];
                if (adverseEventRecord.PC_Care_Program__c != null) {
                    for(PC_eletter__c eachLetter : eLetterMap.values()){
                        for(PC_Engagement_Program_Eletter__c eachEngagementProgramEletter : eachLetter.Engagement_Program_eLetter__r){
                            if(adverseEventRecord.PC_Care_Program__r.PC_Engagement_Program__c == eachEngagementProgramEletter.PC_Engagement_Program__c){
                                engagementProgramEletterList.add(eachEngagementProgramEletter);
                            }
                        }
                    }
                }else{
                    eLetterTemplateDetailsAndEmailAddressMapWrapper allEletterAndEmailAddressDetailsWrapper = getAllELetterAndAddressDetails(eLetterMap);
                    eLetterTemplateDetailsAndEmailAddressMapWrapper.eLetterTemplateWrapperList = allEletterAndEmailAddressDetailsWrapper.eLetterTemplateWrapperList;
                    eLetterTemplateDetailsAndEmailAddressMapWrapper.eLetterTemplateIdAndConfiguredRecipientsMap = allEletterAndEmailAddressDetailsWrapper.eLetterTemplateIdAndConfiguredRecipientsMap;
                }
            }else if (objectType == PC_Constants.getQualifiedApiName(PC_Constants.PC_AdverseEvent2_Object)) {

                eLetterMap = new Map<Id, PC_eLetter__c>([
                        SELECT Id, Name, PC_Template_Name__c, PC_Send_to_User__c, PC_Allow_Send_to_Patient__c,PC_Target_Recipients__c,
                        (SELECT Id,PC_Engagement_Program__r.Name,PC_PreConfiguredEmailRecipients__c,PC_eLetter__c,PC_Engagement_Program__c FROM Engagement_Program_eLetter__r LIMIT 2000)
                        FROM PC_eLetter__c
                        WHERE PC_Source_Object__c = :ADVERSE_EVENT2
                ]);
                //FLS Check
                List<String> adverseEvent2Fields = new List<String>{PC_Constants.getQualifiedAPIName('PC_Care_Program__c'),
                        PC_Constants.getQualifiedAPIName('PC_Care_Program__r')+'.'+PC_Constants.getQualifiedAPIName('PC_Engagement_Program__c')
                };
                PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_AdverseEvent2__c'), PC_Database.Operation.Reading, adverseEvent2Fields);

                adverseEvent2Record = [
                        SELECT Id,PC_Care_Program__c, PC_Care_Program__r.PC_Engagement_Program__c
                        FROM PC_AdverseEvent2__c
                        WHERE Id = :adverseEventRecordId
                ];
                if (adverseEvent2Record.PC_Care_Program__c != null) {
                    for(PC_eletter__c eachLetter : eLetterMap.values()){
                        for(PC_Engagement_Program_Eletter__c eachEngagementProgramEletter : eachLetter.Engagement_Program_eLetter__r){
                            if(adverseEvent2Record.PC_Care_Program__r.PC_Engagement_Program__c == eachEngagementProgramEletter.PC_Engagement_Program__c){
                                engagementProgramEletterList.add(eachEngagementProgramEletter);
                            }
                        }
                    }
                }else{
                    eLetterTemplateDetailsAndEmailAddressMapWrapper allEletterAndEmailAddressDetailsWrapper = getAllELetterAndAddressDetails(eLetterMap);
                    eLetterTemplateDetailsAndEmailAddressMapWrapper.eLetterTemplateWrapperList = allEletterAndEmailAddressDetailsWrapper.eLetterTemplateWrapperList;
                    eLetterTemplateDetailsAndEmailAddressMapWrapper.eLetterTemplateIdAndConfiguredRecipientsMap = allEletterAndEmailAddressDetailsWrapper.eLetterTemplateIdAndConfiguredRecipientsMap;
                }
            }
            //If Case on AE is not null then engagementProgramEletterList wont be empty
            if (!engagementProgramEletterList.isEmpty()) {
                for (PC_Engagement_Program_Eletter__c engagementProgramEletter : engagementProgramEletterList) {
                    if (eLetterMap != null && !eLetterMap.isEmpty() && eLetterMap.containsKey(engagementProgramEletter.PC_eLetter__c)) {

                        List<recipientDetailsWrapper> recipientDetailsWrapperList = new List<recipientDetailsWrapper>();
                        recipientDetailsWrapperList = getRecipientDetailsWrappersList(engagementProgramEletter.PC_PreConfiguredEmailRecipients__c);
                        eLetterTemplateIdAndEmailRecipientsMap.put(eLetterMap.get(engagementProgramEletter.PC_eLetter__c).Id, recipientDetailsWrapperList);
                    }
                }
            }
            //If Case on AE is not null then eLetterTemplateIdAndEmailRecipientsMap wont be empty
            if (!eLetterTemplateIdAndEmailRecipientsMap.values().isEmpty()) {
                for (PC_eLetter__c eLetterTemplate : eLetterMap.values()) {
                    eLetterTemplateWrapper eLetterTemplateWrapper = new eLetterTemplateWrapper();
                    if (eLetterTemplateIdAndEmailRecipientsMap.containsKey(eLetterTemplate.Id)) {
                        eLetterTemplateWrapper.eLetterTemplateId = eLetterTemplate.Id;
                        eLetterTemplateWrapper.eLetterTemplateName = eLetterTemplate.Name;
                        eLetterTemplateWrapperList.add(eLetterTemplateWrapper);
                    }
                }
                eLetterTemplateDetailsAndEmailAddressMapWrapper.eLetterTemplateWrapperList = eLetterTemplateWrapperList;
                eLetterTemplateDetailsAndEmailAddressMapWrapper.eLetterTemplateIdAndConfiguredRecipientsMap = eLetterTemplateIdAndEmailRecipientsMap;
            }
        }catch (Exception ex){
            PC_Utility.logAndThrowException(ex);
        }
        return eLetterTemplateDetailsAndEmailAddressMapWrapper;
    }


    @AuraEnabled
    public static eLetterTemplateDetailsAndEmailAddressMapWrapper getAllELetterAndAddressDetails(Map<Id,PC_eLetter__c> eLetterMap){
        eLetterTemplateDetailsAndEmailAddressMapWrapper allEletterAndEmailAddressDetailsWrapper = new eLetterTemplateDetailsAndEmailAddressMapWrapper();
        Map<String, List<recipientDetailsWrapper>> eLetterIdAndEmailRecipientsMap = new Map<String, List<recipientDetailsWrapper>>();
        List<eLetterTemplateWrapper> allELetterTemplateWrappersList = new List<eLetterTemplateWrapper>();
        for (PC_eLetter__c eLetterTemplate : eLetterMap.values()) {

            if(eLetterTemplate.Engagement_Program_eLetter__r.size()>0) {
                for (PC_Engagement_Program_Eletter__c eachEngagementProgramEletter : eLetterTemplate.Engagement_Program_eLetter__r) {
                    eLetterTemplateWrapper eachELetterTemplateWrapper = new eLetterTemplateWrapper();
                    eachELetterTemplateWrapper.eLetterTemplateId = eLetterTemplate.Id + '-' +eachEngagementProgramEletter.Id;
                    eachELetterTemplateWrapper.eLetterTemplateName = eLetterTemplate.Name + ' - ' + eachEngagementProgramEletter.PC_Engagement_Program__r.Name;
                    allELetterTemplateWrappersList.add(eachELetterTemplateWrapper);

                    List<recipientDetailsWrapper> recipientDetailsWrapperList = new List<recipientDetailsWrapper>();
                    recipientDetailsWrapperList = getRecipientDetailsWrappersList(eachEngagementProgramEletter.PC_PreConfiguredEmailRecipients__c);
                    eLetterIdAndEmailRecipientsMap.put(eLetterTemplate.Id+ '-' +eachEngagementProgramEletter.Id, recipientDetailsWrapperList);
                }
            }else {
                eLetterTemplateWrapper eachELetterTemplateWrapper = new eLetterTemplateWrapper();
                eachELetterTemplateWrapper.eLetterTemplateId = eLetterTemplate.Id;
                eachELetterTemplateWrapper.eLetterTemplateName = eLetterTemplate.Name;
                allELetterTemplateWrappersList.add(eachELetterTemplateWrapper);

                List<recipientDetailsWrapper> noRecipientDetailsWrapperList = new List<recipientDetailsWrapper>();
                eLetterIdAndEmailRecipientsMap.put(eLetterTemplate.Id, noRecipientDetailsWrapperList);
            }
        }
        allEletterAndEmailAddressDetailsWrapper.eLetterTemplateWrapperList = allELetterTemplateWrappersList;
        allEletterAndEmailAddressDetailsWrapper.eLetterTemplateIdAndConfiguredRecipientsMap = eLetterIdAndEmailRecipientsMap;
        return allEletterAndEmailAddressDetailsWrapper;
    }



    @AuraEnabled
    public static void sendAdverseEventMail(List<String> toAddressList, String eLetterId, Id recordId){
        try {
            //FLS Check
            List<String> eLetterFields = new List<String>{PC_Constants.getQualifiedAPIName('PC_Template_Name__c'),
                    PC_Constants.getQualifiedAPIName('PC_Communication_Language__c')};

            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_eLetter__c'), PC_Database.Operation.Reading, eLetterFields);

            if(String.isNotBlank(eLetterId)) {
                PC_eLetter__c eLetter = new PC_eLetter__c();
                eLetter = [
                        SELECT Id,PC_Template_Name__c,PC_Communication_Language__c
                        FROM PC_eLetter__c
                        WHERE Id = :eLetterId
                ];
                List<PC_eLetter.RecipientWrapper> recipientWrapperList = new List<PC_eLetter.RecipientWrapper>();
                for(String recipientEmail : toAddressList){
                    PC_eLetter.RecipientWrapper recipientWrapper = new PC_eLetter.RecipientWrapper();
                    recipientWrapper.Id = null;
                    recipientWrapper.communicationLanguage = eLetter.PC_Communication_Language__c;
                    recipientWrapper.type = PC_eLetter.RecipientType.PRE_CONFIGURED_EMAIL.name();
                    recipientWrapper.fax = '';
                    recipientWrapper.email = recipientEmail;
                    recipientWrapper.name = '';
                    recipientWrapperList.add(recipientWrapper);
                }
                PC_eLetterService.sendLetter(recordId,eLetter,PC_Constants.EMAIL,recipientWrapperList,false);

            }
        }catch(Exception ex){
            PC_Utility.logAndThrowException(ex);
        }

    }

    public inherited sharing class OrgWideEmailAddressWrapper{
       @AuraEnabled public Id  orgWideEmailAddressId {get; set;}
       @AuraEnabled public String orgWideEmailAddress{get; set;}

     public OrgWideEmailAddressWrapper(){
            orgWideEmailAddress ='';
        }
    }

    public inherited sharing class eLetterTemplateWrapper{
        @AuraEnabled public String  eLetterTemplateId {get; set;}
        @AuraEnabled public String eLetterTemplateName{get; set;}

        public eLetterTemplateWrapper(){
            eLetterTemplateName = '';

        }
    }
    public inherited sharing class recipientDetailsWrapper{
        @AuraEnabled public String recipientName {get; set;}
        @AuraEnabled public String recipientEmailId{get; set;}
    }
    public inherited sharing class eLetterTemplateDetailsAndEmailAddressMapWrapper{
        @AuraEnabled public List<eLetterTemplateWrapper>  eLetterTemplateWrapperList {get; set;}
        @AuraEnabled public Map<String,List<recipientDetailsWrapper>> eLetterTemplateIdAndConfiguredRecipientsMap{get; set;}

        public eLetterTemplateDetailsAndEmailAddressMapWrapper(){
            eLetterTemplateWrapperList = new List<eLetterTemplateWrapper>();
            eLetterTemplateIdAndConfiguredRecipientsMap = new Map<String, List<recipientDetailsWrapper>>();
        }
    }

    public inherited sharing class EmailAddressAndTemplatesWrapper{
        @AuraEnabled public List<OrgWideEmailAddressWrapper>  orgWideEmailAddressWrapperList {get; set;}
        @AuraEnabled public List<eLetterTemplateWrapper> eLetterTemplateWrapperList{get; set;}
        @AuraEnabled public Map<String,List<recipientDetailsWrapper>> eLetterTemplateIdAndConfiguredRecipientsMap{get; set;}
        //@AuraEnabled public String emailTemplateAndConfiguredRecipientsMap{get; set;}

        public EmailAddressAndTemplatesWrapper(){
            orgWideEmailAddressWrapperList =new List<OrgWideEmailAddressWrapper>();
            eLetterTemplateWrapperList = new List<eLetterTemplateWrapper>();
            eLetterTemplateIdAndConfiguredRecipientsMap =new Map<String, List<recipientDetailsWrapper>>();
        }
    }

    public static List<recipientDetailsWrapper> getRecipientDetailsWrappersList(String emailAddressString){
        List<recipientDetailsWrapper> recipientDetailsWrapperList= new List<recipientDetailsWrapper>();

        if(!String.isBlank(emailAddressString) && emailAddressString.contains(',')){
            for(String emailAddress: emailAddressString.split(',')){
                recipientDetailsWrapper recipientDetail = new recipientDetailsWrapper();
                recipientDetail.recipientEmailId = emailAddress;
                recipientDetail.recipientName = '';
                recipientDetailsWrapperList.add(recipientDetail);
            }
        }
        else{
            recipientDetailsWrapper recipientDetail = new recipientDetailsWrapper();
            recipientDetail.recipientEmailId = emailAddressString;
            recipientDetail.recipientName = '';
            recipientDetailsWrapperList.add(recipientDetail);
            //emailAddressList.add(emailAddressString);
        }
        return recipientDetailsWrapperList;
    }
}