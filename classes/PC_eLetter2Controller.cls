/*********************************************************************************
Class Name      : PC_eLetter2
Description     : Methods for eLetter2 lightning component
Created By      : Satheesh Kumar
Created Date    : 29-Jun-20
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   	Description
-----------------------------------------------------------------------------------
Satheesh Kumar            29-Jun-2020              Initial Version
Satheesh Kumar            15-Oct-2020              [PC-6490] Changed logic in getElettersAsPerEngagementProg method to get description from PC_Eletter__c and PC_Engagement_Program_Eletter__c object
Satheesh Kumar            15-Oct-2020              [PC-6635] Modified logic to send email to logged-in user when sendToMe is enabled
Satheesh Kumar            16-Oct-2020              [PC-5024] added new attribute templateType to RenderedMailTemplate Class.
Satheesh Kumar            16-Nov-2020              [PC-6908] Added new methods to get from address based on engagement program email Ids
Satheesh Kumar            30-Nov-2020              [PC-7084] Added Regular expression to split method in getEngagementProgramEmailAddress to fix space issue.
Satheesh Kumar            04-Dec-2020              [PC-7096] Added new property(documentId) in SendLetterRequest for linking outbound document
Satheesh Kumar            10-Dec-2020              [PC-6699] Added method to get pre configured recipients (non-case roles)
Hitha Avalakki            23-Feb-2021              [PC-7442] Replaced the use of RecordTypeId with 'Type' field of Case object to decide if its a program case record
Satheesh Kumar            15-Mar-2021              [PC-7525] Added UserType check to support eletter for community users
Hitha Avalakki            19-Mar-2021              [PC-7533] Replaced constant CASE_PROGRAM_RECORD_TYPE_NAME to CASE_PROGRAM_TYPE
Satheesh Kumar            05-Apr-2021              [PC-6528] Add logic to fetch e-letter template categories
Hitha Avalakki            07-Apr-2021              [PC-7537] Removed the condition of Type in query in order to fetch eletters configured as per engagement program for any type of Case record
Hitha Avalakki            07-Nov-2021              [PC-8029] Added code to fetch consent records(PC_Program_Service_Permission__c) records configured for services specific to eletter recipient roles
Hitha Avalakki            09-Nov-2021              [PC-8029] Added check in order to execute consent model logic for Case type object records
Hitha Avalakki            17-Nov-2021              [PC-8029] Added code to execute/ not execute the consent model logic based on the configuration provided in case action attributes and design attributes on eletter2 launcher component
*********************************************************************************/
public with sharing class PC_eLetter2Controller {

    /**
    * Retrieves available eLetters by object type
    *
    * @param recordId   recordId for getting available eletter
    * @return EletterTemplateWrapper  Wrapper Object for List<EletterFromAddress> and List<EletterTemplate>
    */
    @AuraEnabled
    public static EletterTemplateWrapper getEletterTemplates(Id recordId, List<String> emailCategoryList, List<String> faxCategoryList) {
        EletterTemplateWrapper eLetterTemplateWrapper = new EletterTemplateWrapper();
        List<EletterTemplate> lstAvailableEletters = new List<EletterTemplate>();
        List<PC_Engagement_Program_Eletter__c> engagementProgramEletters = new List<PC_Engagement_Program_Eletter__c>();
        String objType = String.valueOf(recordId.getSobjectType());
        String recordTypeName = PC_Constants.EMPTY_STRING;
        Id caseId;
        try {
            if (objType == PC_Constants.DOCUMENT_OBJECT || objType == PC_Constants.PC_TASK) {
                recordId = getCaseId(recordId);
                objType = PC_Constants.PC_CASE;
            }
            if (objType == PC_Constants.PC_INTERACTION) {
                objType = PC_Constants.PC_ELETTER_OBJECT_PICKLIST_INTERACTION;
            } else if (objType == PC_Constants.PC_PROGRAM_COVERAGE) {
                objType = PC_Constants.PC_ELETTER_OBJECT_PICKLIST_PROGRAM_COVERAGE;
            }
            recordTypeName = PC_Utility.getRecordTypeNameByRecordId(recordId);
            caseId = getCaseId(recordId);
            engagementProgramEletters = getElettersAsPerEngagementProg(caseId, objType, recordTypeName, emailCategoryList, faxCategoryList);
            if (engagementProgramEletters == null || engagementProgramEletters.isEmpty()) {
                throw new AuraHandledException(System.label.PC_Eletter2_NoEletterError);
            }
            List<String> eletterIds = new List<String>();
            for (PC_Engagement_Program_Eletter__c epe : engagementProgramEletters) {
                if(! eletterIds.contains(epe.PC_eLetter__r.Id)){
                    eletterIds.add(epe.PC_eLetter__r.Id);
                    lstAvailableEletters.add(new EletterTemplate(epe));
                }
            }
            List<String> engagementProgramEmailId = getEngagementProgramEmailAddress(caseId);
            List<EletterFromAddress> eletterFromAddressList = getFromAddressList(engagementProgramEmailId);
            eLetterTemplateWrapper.eletterTemplateList = lstAvailableEletters;
            eLetterTemplateWrapper.eletterFromAddressList = eletterFromAddressList;
        } catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return eLetterTemplateWrapper;
    }


    /**
    * Retrieves eLetters recipients and eletter template info based on eletter id
    *
    * @param letterId       Id of the eletter
    * @param recordId       recordId for getting recipients and rendered template
    * @return EletterInfo   This returns values of both eLetterRecipients and rendered eletterTemplate
    */
    @AuraEnabled
    public static EletterInfo getEletterInfo(String letterId, Id recordId, String eletterContext,Boolean hideConsent) {
        EletterInfo eLetterInfo = new EletterInfo();
        String replyToDocumentId;
        String eLetterTemplateName = PC_Constants.EMPTY_STRING;
        EmailTemplate emailTemplate;
        RenderedMailTemplate renderedMailTemplate;
        List<PC_eLetter_Recipient> eLetterRecipients;

        try {
            String objType = String.valueOf(recordId.getSobjectType());
            if (objType == PC_Constants.PC_TASK) {
                //FLS check for task
                List<String> taskFields = new List<String>{'Id', 'WhatId', PC_Constants.getQualifiedAPIName('PC_Program__c'), PC_Constants.getQualifiedAPIName('PC_Document__c')};
                PC_Database.assertAccess(PC_Constants.PC_TASK, PC_Database.Operation.Reading, taskFields);
                Task task = [SELECT Id, WhatId, PC_Program__c, PC_Document__c FROM Task WHERE Id = :recordId];
                if (task != null) {
                    if (task.WhatId != null) {
                        recordId = task.WhatId;
                    } else {
                        throw new AuraHandledException(System.label.PC_Eletter2_ErrorNoCaseRelated);
                    }
                    if (task.PC_Document__c != null) {
                        replyToDocumentId = task.PC_Document__c;
                        objType = PC_Constants.DOCUMENT_OBJECT;
                    }
                }
            } else if (objType == PC_Constants.DOCUMENT_OBJECT) {
                // Check FLS for PC_Document_Log__c
                List<String> pcDocumentLogFields = new List<String>{'Id', PC_Constants.getQualifiedAPIName('PC_Program__c'),PC_Constants.getQualifiedAPIName('PC_Document__c')};
                replyToDocumentId = recordId;
                List<PC_Document_Log__c> docLogList = new List<PC_Document_Log__c>();
                PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Document_Log__c'), PC_Database.Operation.Reading, pcDocumentLogFields);
                docLogList = [SELECT Id, PC_Program__c, PC_Document__c FROM PC_Document_Log__c WHERE PC_Document__c = :recordId and PC_Program__c != null LIMIT 1];
                if (docLogList.size() > 0) {
                    recordId = docLogList[0].PC_Program__c;
                } else {
                    throw new AuraHandledException(System.Label.PC_Eletter2_ErrorNoCaseRelatedToDocument);
                }
            }

            // Check the eletter context
            PC_eLetter__c eLetter = new PC_eLetter__c();
            if (eletterContext == PC_Constants.PC_ELETTER_CONTEXT_NEW) {
                if (String.isNotBlank(letterId)) {
                    /** Get eletter recipients when eletterContext is NEW and have selected eletterId */
                    eLetter = PC_eLetterService.getELetter(letterId);
                    if (eLetter != null && eLetter.PC_Template_Name__c != null) {
                        eLetterTemplateName = eLetter.PC_Template_Name__c;
                        emailTemplate = getEmailTemplateDetails(eLetterTemplateName);
                    } else {
                        throw new AuraHandledException(System.Label.PC_Eletter2_ErrorEmailTemplate);
                    }
                    eLetterRecipients = getRecipients(letterId, recordId);
                    renderedMailTemplate = getRenderedMailTemplate(emailTemplate.Id, recordId);
                } else {
                    /** Get all recipients of case when eletterContext is NEW and no eletter is selected */
                    renderedMailTemplate = new RenderedMailTemplate();
                    renderedMailTemplate.templateType = 'html';
                    eLetterRecipients = getAllRecipients(recordId);
                }
            } else if (eletterContext == PC_Constants.PC_ELETTER_CONTEXT_REPLY) {
                if (String.isNotBlank(letterId)) {
                    /** Get only sender of the inbound email as recipient when eletterContext is REPLY */
                    eLetter = PC_eLetterService.getELetter(letterId);
                    if (eLetter != null && eLetter.PC_Template_Name__c != null) {
                        eLetterTemplateName = eLetter.PC_Template_Name__c;
                        emailTemplate = getEmailTemplateDetails(eLetterTemplateName);
                    } else {
                        throw new AuraHandledException(System.Label.PC_Eletter2_ErrorEmailTemplate);
                    }
                    eLetterRecipients = getReplyDocumentRecipients(recordId, eLetter, replyToDocumentId);
                    renderedMailTemplate = getRenderedMailTemplate(emailTemplate.Id, recordId);
                } else {
                    renderedMailTemplate = new RenderedMailTemplate();
                    renderedMailTemplate.templateType = 'html';
                    eLetterRecipients = getReplyDocumentRecipients(recordId, eLetter, replyToDocumentId);
                }
            }

            /*START:[PC-8029] Added code to fetch consent records(PC_Program_Service_Permission__c) records configured for services specific to eletter recipient roles*/
            //The logic of consents is applicable only for Case object,hence added the below check
            //The consent model logic will execute based on configuration provided in case action centre attributes or design attributes defined on eletter2 launcher component
            if (objType == PC_Constants.PC_CASE && !hideConsent) {
                //FLS check for case
                List<String> caseFields = new List<String>{
                        'Id', 'RecordTypeId', PC_Constants.getQualifiedAPIName('PC_Engagement_Program__c')
                };
                PC_Database.assertAccess(PC_Constants.PC_CASE, PC_Database.Operation.Reading, caseFields);

                Case caseObject = [SELECT Id, PC_Engagement_Program__c FROM Case WHERE Id = :recordId LIMIT 1];

                getProgramServicePermissionsForRecipientsRoles(letterId, recordId, caseObject.PC_Engagement_Program__c, eLetterRecipients);

                /* END:[PC-8029] */
            }
            eLetterInfo = new EletterInfo(renderedMailTemplate, eLetterRecipients);
        } catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return eLetterInfo;
    }

    /********************************************************************************************************************
    Method Name    : getProgramServicePermissionsForRecipientsRoles
    Author         : Hitha Avalakki
    Description    : Get information related to PRogram service permission records for eletter recipient roles
    Return Type    : void
    Parameter      : String letterId,Id caseRecordId,Id engagementProgramId,List<PC_eLetter_Recipient> eLetterRecipients
    *********************************************************************************************************************/
    public static void getProgramServicePermissionsForRecipientsRoles(String letterId,Id caseRecordId,Id engagementProgramId,List<PC_eLetter_Recipient> eLetterRecipients){
        List<Id> serviceIdList = new List<Id>();
        List<PC_Engagement_Program_Service__c> engagementProgramServicesList = new List<PC_Engagement_Program_Service__c>();
        List<PC_Service__c> allServicesList = new List<PC_Service__c>();
        List<PC_Program_Service_Permission__c> programServicePermissionsListForServices = new List<PC_Program_Service_Permission__c>();
        Map<Id,PC_Service__c> serviceIdServiceRecordMap = new Map<Id, PC_Service__c>();
        Map<Id,List<PC_Program_Service_Permission__c>> serviceIdAndProgServicePermissionMap = new Map<Id, List<PC_Program_Service_Permission__c>>();
        List<PC_Program_Service_Permission__c> programServicePermissionList = new List<PC_Program_Service_Permission__c>();

        //Get list of all Active engagement program services for the selected eletter template and engagement program
        engagementProgramServicesList = [SELECT Id,PC_Service__c FROM PC_Engagement_Program_Service__c WHERE PC_Notification_Template__c=:letterId AND PC_Engagement_Program__c =:engagementProgramId AND PC_Active__c=true];

        //Prepare the list of service ids
        for(PC_Engagement_Program_Service__c engagementProgramService : engagementProgramServicesList){
            serviceIdList.add(engagementProgramService.PC_Service__c);
        }

        //Get details related to the services
        allServicesList = [SELECT Id,Name,PC_Default_Expiration_Days__c, PC_Patient_Permission_Required__c,PC_HCP_Permission_Required__c,PC_CareTeamPermissionRequiredRoles__c FROM PC_Service__c WHERE Id IN: serviceIdList];

        //Prepare a map of service record id and service records
        for(PC_Service__c serviceRecord: allServicesList){
            serviceIdServiceRecordMap.put(serviceRecord.Id,serviceRecord);
        }

        //Get all the program service permission records for the service records
        programServicePermissionsListForServices = [SELECT Id,PC_Active__c,PC_Start_Date__c,PC_End_Date__c,PC_Patient_Response__c,PC_HCP_Response__c,PC_CareTeamMember__c,PC_CareTeamMember__r.PC_Role__c,PC_CareTeamMemberResponse__c,PC_Service__r.Name,PC_Service__c FROM PC_Program_Service_Permission__c WHERE PC_ProgramCase__c=:caseRecordId AND PC_Service__c IN:serviceIdList];

        //Prepare a map of service record id and its related list of program service permission records
        for(PC_Program_Service_Permission__c progServicePermissionRecord: programServicePermissionsListForServices) {

            /* Following check is required if a program service permission record exists but has not service record associated.
            Since both program service permission record and Service record are associated via lookup relationship, it is possible that service record can be kept blank on program service permission record.*/
            if (progServicePermissionRecord.PC_Service__c!=null){

                if (serviceIdAndProgServicePermissionMap != null &&
                        serviceIdAndProgServicePermissionMap.containsKey(progServicePermissionRecord.PC_Service__c)) {
                    programServicePermissionList = serviceIdAndProgServicePermissionMap.get(progServicePermissionRecord.PC_Service__c);
                    programServicePermissionList.add(progServicePermissionRecord);
                    serviceIdAndProgServicePermissionMap.put(progServicePermissionRecord.PC_Service__c, programServicePermissionList);
                } else {
                    programServicePermissionList = new List<PC_Program_Service_Permission__c>();
                    programServicePermissionList.add(progServicePermissionRecord);
                    serviceIdAndProgServicePermissionMap.put(progServicePermissionRecord.PC_Service__c, programServicePermissionList);
                }
            }
        }

        //For all the recipient roles get program service permission details of services
        for(PC_eLetter_Recipient eLetterRecipient : eLetterRecipients){

            if(!String.isBlank(eLetterRecipient.recipientRole)){

                List<PC_eLetter_Recipient.ProgramServicePermissionWrapper> programServicePermissionWrappers = new List<PC_eLetter_Recipient.ProgramServicePermissionWrapper>();
                Map<Id, List<PC_eLetter_Recipient.ProgramServicePermissionWrapper>> serviceRecordDetails = new Map<Id, List<PC_eLetter_Recipient.ProgramServicePermissionWrapper>>();

                serviceRecordDetails = getServiceAndProgramServicePermissionDetails(eLetterRecipient.recipientRole, serviceIdServiceRecordMap, serviceIdAndProgServicePermissionMap);

                //Prepare a consolidated list of all program service permission records for all services
                for(Id serviceId: serviceRecordDetails.keySet()){
                    programServicePermissionWrappers.addAll(serviceRecordDetails.get(serviceId));
                }

                eLetterRecipient.serviceDetails = serviceRecordDetails;
                eLetterRecipient.programServicePermissionRecordsList = programServicePermissionWrappers;
            }
        }
    }

    /********************************************************************************************************************
    Method Name    : getServiceAndProgramServicePermissionDetails
    Author         : Hitha Avalakki
    Description    : Get Programs service permission reords for all services confured for roles
    Return Type    : Map<Id, List<PC_eLetter_Recipient.ProgramServicePermissionWrapper>>
    Parameter      : String ,Map<Id,PC_Service__c> , Map<Id,List<PC_Program_Service_Permission__c>>
    *********************************************************************************************************************/
    public static Map<Id, List<PC_eLetter_Recipient.ProgramServicePermissionWrapper>> getServiceAndProgramServicePermissionDetails(String recipientRole,Map<Id,PC_Service__c> serviceIdServiceRecordMap, Map<Id,List<PC_Program_Service_Permission__c>> serviceIdAndProgServicePermissionMap){
        Map<Id,List<PC_eLetter_Recipient.ProgramServicePermissionWrapper>> serviceIdProgramServicePermissionMap =  new Map<Id, List<PC_eLetter_Recipient.ProgramServicePermissionWrapper>>();

        for(Id serviceRecordId: serviceIdServiceRecordMap.keySet()) {

            Boolean isEletterRecipientRolePresentOnServiceRecord = false;

            if(!String.isBlank(recipientRole) && !PC_Constants.PATIENT_ACCOUNT_TYPE_VALUE.equals(recipientRole)) {

            //Check if the eletter recipient role is present on the service record
                isEletterRecipientRolePresentOnServiceRecord = checkIfEletterRecipientRoleIsPresentOnServiceRecord(recipientRole, serviceIdServiceRecordMap.get(serviceRecordId));
            }

            //Following check is required since a service record should be processed only if its related to any role(Patient or Care team roles)
            if((PC_Constants.PATIENT_ACCOUNT_TYPE_VALUE.equals(recipientRole) && serviceIdServiceRecordMap.get(serviceRecordId).PC_Patient_Permission_Required__c!=null && serviceIdServiceRecordMap.get(serviceRecordId).PC_Patient_Permission_Required__c) ||
                    (isEletterRecipientRolePresentOnServiceRecord!=null && isEletterRecipientRolePresentOnServiceRecord)){

            if(serviceIdAndProgServicePermissionMap!=null && !serviceIdAndProgServicePermissionMap.isEmpty()) {

                List<PC_Program_Service_Permission__c> programServicePermissionList = serviceIdAndProgServicePermissionMap.get(serviceRecordId);

                List<PC_eLetter_Recipient.ProgramServicePermissionWrapper> programServicePermissionWrapperList = new List<PC_eLetter_Recipient.ProgramServicePermissionWrapper>();

                /* if condition: It takes care of the scenario when program service permission records exist for a service record
                *  else condition: It takes care when service record exists for an eletter recipient role, but no program service permission record exists*/
                    if(programServicePermissionList!=null && !programServicePermissionList.isEmpty()){

                        for (PC_Program_Service_Permission__c programServicePermission : programServicePermissionList) {
                        PC_eLetter_Recipient.ProgramServicePermissionWrapper programServicePermissionWrapper = new PC_eLetter_Recipient.ProgramServicePermissionWrapper();

                        if (PC_Constants.PATIENT_ACCOUNT_TYPE_VALUE.equals(recipientRole)) {

                            if (serviceIdServiceRecordMap.get(serviceRecordId)!=null && serviceIdServiceRecordMap.get(serviceRecordId).PC_Patient_Permission_Required__c) {

                                //The following check is essential because a Program service Permission response record exists only for a particular role at a time
                                //Also it is based on assumption that only one consent record can exist for a role
                                if(!String.isBlank(programServicePermission.PC_Patient_Response__c) && programServicePermission.PC_CareTeamMember__c==null){

                                    /* Following check is required because we would consider only those Program Service Permission records which have start date <= current date.
                                       We wont consider those Program Service Permission records which have a future start date */
                                    if(programServicePermission.PC_Start_Date__c!=null && programServicePermission.PC_Start_Date__c<=Date.today()){
                                        programServicePermissionWrapper =  populateProgramServicePermissionWrapperDetails(true,programServicePermission);
                                    }
                                }
                            }
                        }

                        /* Else block will take care of all roles other than Patient.
                           This has been done in order to support client provided custom roles which would be other than Patient Connect managed package roles*/
                       else{

                           if (isEletterRecipientRolePresentOnServiceRecord) {

                               if (programServicePermission.PC_CareTeamMember__c!=null && programServicePermission.PC_CareTeamMember__r.PC_Role__c != null &&
                                       recipientRole.equals(programServicePermission.PC_CareTeamMember__r.PC_Role__c)) {

                                   /* Following check is required because we would consider only those Program Service Permission records which have start date <= current date.
                                       We wont consider those Program Service Permission records which have a future start date */
                                   if(programServicePermission.PC_Start_Date__c!=null && programServicePermission.PC_Start_Date__c<=Date.today()) {

                                       programServicePermissionWrapper = populateProgramServicePermissionWrapperDetails(false, programServicePermission);
                                   }
                               }

                           }
                        }

                        /* if condition: Add the 'programServicePermissionWrapper' to the list only if PC_Program_Service_Permission__c record exists for any service record
                         * else condition: We need to display the Service name even if the consent record does not exist for the service, and display the information label accordingly */
                            if (!String.isBlank(programServicePermissionWrapper.serviceName)) {

                                /* if condition:At any point of time for any Role, for any service record, there can exist only one valid consent record.
                                                If there exists more than one active consent record, then we need to choose the consent record which has higher end date,
                                                since it would be the one that will stay active for longer period of time.
                               * else condition: It handles the normal flow for the PC_Program_Service_Permission_c record. */
                                if (serviceIdProgramServicePermissionMap != null && !serviceIdProgramServicePermissionMap.isEmpty() && serviceIdProgramServicePermissionMap.containsKey(serviceRecordId)) {
                                    List<PC_eLetter_Recipient.ProgramServicePermissionWrapper> existingProgServicePermissionWrapperList = serviceIdProgramServicePermissionMap.get(serviceRecordId);

                                    if(existingProgServicePermissionWrapperList!=null && !existingProgServicePermissionWrapperList.isEmpty()){

                                        if(existingProgServicePermissionWrapperList[0].startDate<=Date.today() && programServicePermissionWrapper.startDate<=Date.today()) {

                                            if(existingProgServicePermissionWrapperList[0].endDate>=Date.today() && programServicePermissionWrapper.endDate>=Date.today()) {

                                                if(programServicePermissionWrapper.endDate > existingProgServicePermissionWrapperList[0].endDate){
                                                    List<PC_eLetter_Recipient.ProgramServicePermissionWrapper> newProgServicePermissionWrapperList = new List<PC_eLetter_Recipient.ProgramServicePermissionWrapper>();
                                                    newProgServicePermissionWrapperList.add(programServicePermissionWrapper);

                                                    serviceIdProgramServicePermissionMap.put(serviceRecordId, newProgServicePermissionWrapperList);
                                                }
                                            }
                                        }
                                    }

                                }else {
                                    List<PC_eLetter_Recipient.ProgramServicePermissionWrapper> newProgramServicePermissionWrapperList = new List<PC_eLetter_Recipient.ProgramServicePermissionWrapper>();
                                    newProgramServicePermissionWrapperList.add(programServicePermissionWrapper);

                                    serviceIdProgramServicePermissionMap.put(serviceRecordId, newProgramServicePermissionWrapperList);
                                }
                            }
                        }

                        //Following section of code takes care of the scenario when for a service record, PSP records are present, but none of them match the required role
                        //Please note we have not added the check for isEmpty on the map 'serviceIdProgramServicePermissionMap', since it might happen that in the first iteration itself no data might have been added to the map and thus it is empty
                        if(serviceIdProgramServicePermissionMap!=null &&
                                !serviceIdProgramServicePermissionMap.containsKey(serviceRecordId)){
                            populateProgramServicePermissionWrapperDetailsForEmptyConsent(serviceIdServiceRecordMap.get(serviceRecordId),programServicePermissionWrapperList,serviceIdProgramServicePermissionMap);
                        }

                    }
                    else{
                        //Populate details when no consent record is available for the service record
                        populateProgramServicePermissionWrapperDetailsForEmptyConsent(serviceIdServiceRecordMap.get(serviceRecordId),programServicePermissionWrapperList,serviceIdProgramServicePermissionMap);
                    }
                }
            }
        }

        return serviceIdProgramServicePermissionMap;
    }

    /********************************************************************************************************************
    Method Name    : populateProgramServicePermissionWrapperDetails
    Author         : Hitha Avalakki
    Description    : Populate Program Service Permission wrapper details to be used to dispaly data on UI
    Return Type    : PC_eLetter_Recipient.ProgramServicePermissionWrapper
    Parameter      : Boolean ,PC_Program_Service_Permission__c
    *********************************************************************************************************************/
    public static PC_eLetter_Recipient.ProgramServicePermissionWrapper populateProgramServicePermissionWrapperDetails(Boolean isPatientRole,PC_Program_Service_Permission__c programServicePermission){
        PC_eLetter_Recipient.ProgramServicePermissionWrapper programServicePermissionWrapper =  new PC_eLetter_Recipient.ProgramServicePermissionWrapper();

        programServicePermissionWrapper.serviceName = programServicePermission.PC_Service__r.Name;
        programServicePermissionWrapper.programServicePermissionId = programServicePermission.Id;
        programServicePermissionWrapper.startDate = programServicePermission.PC_Start_Date__c;
        programServicePermissionWrapper.endDate = programServicePermission.PC_End_Date__c;

        //A consent record is available only when it is active and the response is captured for the specific role
        //If a consent record is active but its response is declined/revoked then the service is not available
        //If a consent is not active then it considered to be expired
        //Please note a consent record is active/inactive is decided on the basis of start date and end date present on record
        if(programServicePermission.PC_Active__c){

            if ((isPatientRole && PC_Constants.PERMISSION_PATIENT_RESPONSE.equals(programServicePermission.PC_Patient_Response__c))||
                    (!isPatientRole && PC_Constants.CARE_TEAM_MEMBER_RESPONSE.equals(programServicePermission.PC_CareTeamMemberResponse__c))){

                programServicePermissionWrapper.isConsentAvailable = true;
                programServicePermissionWrapper.informationIconLabel = Label.PC_ServiceConsentIsAvailable;

            } else {
                programServicePermissionWrapper.isConsentAvailable = false;
                programServicePermissionWrapper.informationIconLabel = Label.PC_ServiceConsentIsNotAvailable;
            }
        }
        else{
            programServicePermissionWrapper.isConsentAvailable = false;
            programServicePermissionWrapper.informationIconLabel = Label.PC_ServiceConsentHasExpired;
        }

        return programServicePermissionWrapper;
    }

    /********************************************************************************************************************
    Method Name    : checkIfEletterRecipientRoleIsPresentOnServiceRecord
    Author         : Hitha Avalakki
    Description    : Check if the eletter recpient role is present on Service record
    Return Type    : PBoolean
    Parameter      : String , PC_Service__c
    *********************************************************************************************************************/
    public static Boolean checkIfEletterRecipientRoleIsPresentOnServiceRecord(String recipientRole, PC_Service__c serviceRecord){
        Boolean isEletterRecipientRolePresentOnServiceRecord = false;

        if (serviceRecord !=null && !String.isBlank(serviceRecord.PC_CareTeamPermissionRequiredRoles__c)) {

            List<String> associationRolesList = new List<String>();
            associationRolesList = serviceRecord.PC_CareTeamPermissionRequiredRoles__c.split(';');

            if (associationRolesList.contains(recipientRole)) {
                isEletterRecipientRolePresentOnServiceRecord = true;
            }
            else{
                isEletterRecipientRolePresentOnServiceRecord = false;
            }
        }

        return isEletterRecipientRolePresentOnServiceRecord;
    }

    /********************************************************************************************************************
    Method Name    : populateProgramServicePermissionWrapperDetailsForEmptyConsent
    Author         : Hitha Avalakki
    Description    : Populate Program Service Permission wrapper details when no consent record is present for a service record for a role
    Return Type    : void
    Parameter      : PC_Service__c,  List<PC_eLetter_Recipient.ProgramServicePermissionWrapper> ,Map<Id,List<PC_eLetter_Recipient.ProgramServicePermissionWrapper>>
    *********************************************************************************************************************/
    public static void populateProgramServicePermissionWrapperDetailsForEmptyConsent(PC_Service__c serviceRecord,  List<PC_eLetter_Recipient.ProgramServicePermissionWrapper> programServicePermissionWrapperList ,Map<Id,List<PC_eLetter_Recipient.ProgramServicePermissionWrapper>> serviceIdProgramServicePermissionMap){
        PC_eLetter_Recipient.ProgramServicePermissionWrapper emptyProgramServicePermissionWrapper = new PC_eLetter_Recipient.ProgramServicePermissionWrapper();

        //Populate only the service name and the information label accordingly as no consent record is present for the service
        emptyProgramServicePermissionWrapper.serviceName = serviceRecord.Name;
        emptyProgramServicePermissionWrapper.consentDoesNotExist = true;
        emptyProgramServicePermissionWrapper.informationIconLabel = Label.PC_ServiceConsentDoesNotExist;
        programServicePermissionWrapperList.add(emptyProgramServicePermissionWrapper);

        serviceIdProgramServicePermissionMap.put(serviceRecord.Id, programServicePermissionWrapperList);
    }

    /**
    * Returns the caseId from the object recordId
    *
    * @param recordId   recordId of the object (Interaction, Program Coverage)
    * @return String  caseId
    */
    public static String getCaseId(String recordId){
        String objType = String.valueOf((Id.valueOf(recordId)).getSobjectType());
        List<String> fields;
        Id caseId = recordId;
        if (objType == PC_Constants.PC_PROGRAM_COVERAGE) {
            //FLS check for Program Coverage
            fields = new List<String>{PC_Constants.getQualifiedAPIName('PC_Program__c')};
            PC_Database.assertAccess(PC_Constants.PC_PROGRAM_COVERAGE, PC_Database.Operation.Reading, fields);
            PC_Program_Coverage__c coverage = [SELECT Id, PC_Program__c FROM PC_Program_Coverage__c WHERE Id = :recordId];
            caseId = coverage.PC_Program__c;
        } else if (objType == PC_Constants.PC_INTERACTION) {
            //FLS check for Interaction
            fields = new List<String>{PC_Constants.getQualifiedAPIName('PC_Patient_Program__c')};
            PC_Database.assertAccess(PC_Constants.PC_INTERACTION, PC_Database.Operation.Reading, fields);
            PC_Interaction__c interaction = [SELECT Id, PC_Patient_Program__c FROM PC_Interaction__c WHERE Id = :recordId];
            caseId = interaction.PC_Patient_Program__c;
        } else if (objType == PC_Constants.DOCUMENT_OBJECT) {
            // FLS Check for PC_Document_Log__c
            fields = new List<String>{'Id', PC_Constants.getQualifiedAPIName('PC_Program__c'), PC_Constants.getQualifiedAPIName('PC_Document__c')};
            List<PC_Document_Log__c> docLogList = new List<PC_Document_Log__c>();
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Document_Log__c'), PC_Database.Operation.Reading, fields);
            docLogList = [SELECT Id, PC_Program__c, PC_Document__c FROM PC_Document_Log__c WHERE PC_Document__c = :recordId and PC_Program__c != null LIMIT 1];
            if(docLogList.size() > 0){
                caseId = docLogList[0].PC_Program__c;
            }
            else{
                throw new AuraHandledException(System.Label.PC_Eletter2_ErrorNoCaseRelatedToDocument);
            }
        } else if (objType == PC_Constants.PC_TASK) {
            //FLS check for Task
            fields = new List<String>{'Id', 'WhatId'};
            PC_Database.assertAccess(PC_Constants.PC_TASK, PC_Database.Operation.Reading, fields);

            List<Task> taskList = [SELECT Id, WhatId FROM Task WHERE Id = :recordId LIMIT 1];
            if (taskList.size() > 0) {
                if (taskList[0].WhatId != null) {
                    caseId = taskList[0].WhatId;
                } else {
                    throw new PC_eLetter2Controller.Eletter2Exception(System.label.PC_Eletter2_ErrorNoCaseRelated);
                }
            }
        }
        return caseId;
    }

    /**
   * Get the Recipients from the document for Reply. It checks the sender email address with the care team members.
   * If matches it will return that member else it will return as non case team member.
   *
   * @param recordId   Program Case Id of the Document
   * @param eLetter   eLetter Object.
   * @param replyToDocumentId   Inbound email DocumentId
   * @return List<PC_eLetter_Recipient>  returns the recipients for reply
   */
    public static List<PC_eLetter_Recipient> getReplyDocumentRecipients(String recordId, PC_eLetter__c eLetter, String replyToDocumentId){
        List<PC_eLetter_Recipient> recipients = new List<PC_eLetter_Recipient>();
        String caseId = getCaseId(recordId);

        // Check FLS for PC_Document__c
        List<String> pcDocumentFields = new List<String>{'Id', PC_Constants.getQualifiedAPIName('PC_From_Email_Address__c'),PC_Constants.getQualifiedAPIName('PC_From_Fax_Number__c'),PC_Constants.getQualifiedAPIName('PC_From_Name__c')};
        PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Document__c'), PC_Database.Operation.Reading, pcDocumentFields);

        if(String.isNotBlank(replyToDocumentId)){
            PC_Document__c replyDocument = [SELECT Id, PC_From_Fax_Number__c, PC_From_Email_Address__c,PC_From_Name__c FROM PC_Document__c WHERE Id =:replyToDocumentId];
            List<PC_eLetter_Recipient> allRecipients = getAllRecipients(caseId);
            allRecipients.addAll(PC_ELetter2Helper.getConfiguredRecipientsAsEletterRecipients(recordId, eLetter.Id));
            String recipientEmailAddress = (replyDocument.PC_From_Email_Address__c != null)?replyDocument.PC_From_Email_Address__c:PC_Constants.EMPTY_STRING;
            if(String.isBlank(recipientEmailAddress)){
                throw new AuraHandledException(System.label.PC_Eletter2_Error_NoFromAddressInDocument);
            } else {
                Boolean isSendToMeEnabled = (String.isNotBlank(eLetter.Id) && eLetter.PC_Send_to_User__c) ? true : false;
                for(PC_eLetter_Recipient recipient : allRecipients){
                    if(recipientEmailAddress.equalsIgnoreCase(recipient.recipientEmail)){
                        recipient.sendToMe = isSendToMeEnabled;
                        recipient.bDisableSendToMe = !isSendToMeEnabled;
                        recipient.bDisableEmail = !recipient.hasContactEmail;
                        recipient.bDisableFax = !recipient.hasContactFax;
                        recipient.sendFax = false;
                        recipient.sendEmail = !!recipient.hasContactEmail;
                        recipients.add(recipient);
                    }
                }
                if(recipients.size() == 0){
                    PC_eLetter.RecipientWrapper recipientWrapper = new PC_eLetter.RecipientWrapper();
                    recipientWrapper.Id = null;
                    recipientWrapper.communicationLanguage = '';
                    recipientWrapper.type = PC_eLetter.RecipientType.PRE_CONFIGURED_EMAIL.name();
                    recipientWrapper.fax = replyDocument.PC_From_Fax_Number__c;
                    recipientWrapper.email = replyDocument.PC_From_Email_Address__c;
                    recipientWrapper.name = replyDocument.PC_From_Name__c;

                    PC_eLetter_Recipient newRecipient = new PC_eLetter_Recipient(recipientWrapper, null, null, null, new Set<String>(), null, null, null);
                    newRecipient.sendToMe = isSendToMeEnabled;
                    newRecipient.bDisableSendToMe = !isSendToMeEnabled;
                    newRecipient.bDisableEmail = String.isBlank(replyDocument.PC_From_Email_Address__c);
                    newRecipient.bDisableFax = String.isBlank(replyDocument.PC_From_Fax_Number__c);
                    newRecipient.hasContactEmail = String.isNotBlank(replyDocument.PC_From_Email_Address__c);
                    newRecipient.sendFax = String.isNotBlank(replyDocument.PC_From_Fax_Number__c);
                    newRecipient.sendEmail = String.isNotBlank(replyDocument.PC_From_Email_Address__c);
                    recipients.add(newRecipient);
                }
            }
        }
        return recipients;
    }

    /**
    * Get all the care team members as recipients.
    *
    * @param recordId   Program Case Id
    * @return List<PC_eLetter_Recipient>  returns the all the care team member as recipients
    */
    public static List<PC_eLetter_Recipient> getAllRecipients(String recordId){
        List<PC_eLetter_Recipient> recipients = new List<PC_eLetter_Recipient>();
        PC_eLetter__c eLetter = new PC_eLetter__c();
        /** Get caseId from the recordId */
        String caseId = getCaseId(recordId);
        try{
            recipients = PC_eLetterService.getParticipants(caseId, eLetter);
            for (PC_eLetter_Recipient rec : recipients) {
                rec.sendToMe = false;
                // Disable SendToMe column
                rec.bDisableSendToMe = true;
                rec.bDisableEmail = !rec.hasContactEmail;
                rec.bDisableFax = !rec.hasContactFax;
                rec.sendFax = false;
                rec.sendEmail = false;
            }
            return recipients;
        } catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
            return null;
        }
    }

    /**
    * returns email template record based on template Name
    *
    * @param templateName       name of the email template
    * @return EmailTemplate     This returns emailtemplate record
    */
    public static EmailTemplate getEmailTemplateDetails(String templateName) {
        List<String> fields = new List<String>{
                'Body', 'DeveloperName', 'Subject'
        };
        PC_Database.assertAccess(PC_Constants.PC_EMAIL_TEMPLATE, PC_Database.Operation.Reading, fields);

        EmailTemplate emailTemplate = [SELECT Id, Body, Subject FROM EmailTemplate WHERE DeveloperName = :templateName];
        return emailTemplate;
    }

    /**
    * retrieves rendered email template based on whatId and whoid.
    * [PC-6353] - As per the story we need to show the rendered template in the Send Eletter2 component
    *
    * @param templateId             id of the selected template
    * @param sObjectRecordId        whatId for rendering email template
    * @return RenderedMailTemplate  This returns details of rendered email template
    */
    public static RenderedMailTemplate getRenderedMailTemplate(String templateId, Id sObjectRecordId) {
        RenderedMailTemplate renderedMailTemplate = new RenderedMailTemplate();
        PC_eLetterPreviewController.PreviewRequest previewRequest = new PC_eLetterPreviewController.PreviewRequest();
        Messaging.SingleEmailMessage singleEmailMessage;
        try {
            String objectType = String.valueOf(sObjectRecordId.getSobjectType());
            //Add the object record id that triggered eletter functionality
            previewRequest.whatId = String.valueOf(sObjectRecordId);
            Case currentCase = new Case();
            if (objectType != null && objectType.equals(PC_Constants.PC_CASE)) {
                //FLS check for case
                List<String> caseFields = new List<String>{
                        'Id', 'AccountId'
                };
                PC_Database.assertAccess(PC_Constants.PC_CASE, PC_Database.Operation.Reading, caseFields);

                //Add the account id of object record that triggered eletter functionality
                currentCase = [Select Id, AccountId from Case where id = :sObjectRecordId];
            }
            //FLS check for Contact
            List<String> contactFields = new List<String>{
                    'Id', 'AccountId', 'PC_Patient__c'
            };
            PC_Database.assertAccess(PC_Constants.CONTACT, PC_Database.Operation.Reading, contactFields);
            List<Contact> contactList = new List<Contact>();

            //Add the contact record id of account record
            if (currentCase != null && currentCase.AccountId != null) {
                contactList = [SELECT Id FROM Contact WHERE AccountId = :currentCase.AccountId];
            }
            if (contactList.size() > 0) {
                previewRequest.whoId = contactList[0].Id;
            }

            if (templateId != null) {
                //Add the email template id of eletter record
                previewRequest.templateId = templateId;
                /** FLS Check for EmailTemplate */
                List<String> emailTemplateFields = new List<String>{'TemplateType'};
                PC_Database.assertAccess(PC_Constants.PC_EMAIL_TEMPLATE,PC_Database.Operation.Reading, emailTemplateFields);

                List<EmailTemplate> emailTemplate = [SELECT Id, TemplateType  FROM EmailTemplate WHERE Id =: templateId];
                String templateType = emailTemplate[0].TemplateType;
                //Get eLetter content for preview
                singleEmailMessage = PC_eLetterService.geteLetterPreview(previewRequest);
                List<PC_AttachmentController.RecordAttachment> templateAttachments = PC_AttachmentController.getRecordAttachments(singleEmailMessage.getEntityAttachments());

                if (singleEmailMessage != null) {
                    renderedMailTemplate = new RenderedMailTemplate(
                            singleEmailMessage.getTemplateName(),
                            singleEmailMessage.getSubject(),
                            templateType,
                            singleEmailMessage.getPlainTextBody(),
                            singleEmailMessage.getHtmlBody()
                    );
                    renderedMailTemplate.templateAttachments = templateAttachments;
                } else {
                    renderedMailTemplate = new RenderedMailTemplate();
                }
            }
        } catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return renderedMailTemplate;
    }


    /*********************************************************************************
    Method Name    : getRecepients
    Description    : Retrieves eLetters recipients based on selected letter
    Parameter      : String letterId, Id recordId
    Return Type    : List<PC_eLetter_Recipient>
    *********************************************************************************/
    public static List<PC_eLetter_Recipient> getRecipients(String letterId, Id recordId) {
        String objType = String.valueOf(recordId.getSobjectType());
        List<PC_eLetter_Recipient> recipients = new List<PC_eLetter_Recipient> ();
        Id caseId = recordId;

        try {
            if (String.valueof(letterId) != Label.PC_None) {
                PC_eLetter__c eLetter = PC_eLetterService.getELetter(letterId);
                caseId = getCaseId(recordId);
                recipients = PC_eLetterService.getParticipants(caseId, eLetter);
                recipients = (recipients == null) ? new List<PC_eLetter_Recipient> () : recipients; // Added null check to avoid null pointer exception
                recipients.addAll(PC_ELetter2Helper.getConfiguredRecipientsAsEletterRecipients(recordId, letterId));
                if (recipients == null) {
                    // If no participants found, don't proceed.
                    return null;
                }

                // After getting all the Recipients, for special eLetter templates (with Allow_Editing=true or Send_To_User=True) set the sendToMe flag to True and uncheck other flags
                if (eLetter.PC_Send_to_User__c) {
                    for (PC_eLetter_Recipient rec : recipients) {
                        rec.sendToMe = true;
                        rec.sendFax = false;
                        rec.sendEmail = false;
                        // Enable SendToMe column
                        rec.bDisableSendToMe = false;
                        // Disble the SendFax & SendEmail checkboxes on eLetter Page:
                        rec.bDisableEmail = false;
                        rec.bDisableFax = false;
                    }
                } else {
                    // Disble the SendToMe checkboxes on eLetter Page for the eLetters where 'Send to User' is not selected.
                    for (PC_eLetter_Recipient rec : recipients) {
                        rec.sendToMe = false;
                        // Disable SendToMe column
                        rec.bDisableSendToMe = true;
                        rec.bDisableEmail = !rec.hasContactEmail;
                        rec.bDisableFax = !rec.hasContactFax;
                        rec.sendFax = false;
                        rec.sendEmail = false;
                    }
                }
            }
        } catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        System.debug('@@' + recipients);
        return recipients;
    }

    /**
    * Send eLetter to select recipients.
    *
    * @param recipientsString   JSON string containing PC_eLetter_Recipient list
    * @param eLetterSenderJSON	JSON string containing eLetter request params
    */
    @AuraEnabled
    public static string sendOutboundDocuments(String eLetterSenderJSON, String recipientsString) {
        try {
            SendLetterRequest request = (SendLetterRequest) System.JSON.deserialize(eLetterSenderJSON, SendLetterRequest.class);
            String recordId = request.recordId;
            String eletterContext = request.eletterContext;
            String letterId = request.eletterId;

            String objType = String.valueOf(Id.valueOf(recordId).getSobjectType());
            if (objType == PC_Constants.DOCUMENT_OBJECT) {
                // Check FLS for PC_Document_Log__c
                List<String> pcDocumentLogFields = new List<String>{
                        'Id', PC_Constants.getQualifiedAPIName('PC_Program__c'), PC_Constants.getQualifiedAPIName('PC_Document__c')
                };
                PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Document_Log__c'), PC_Database.Operation.Reading, pcDocumentLogFields);

                List<PC_Document_Log__c> docLogObj = new List<PC_Document_Log__c>();
                docLogObj = [SELECT Id, PC_Program__c, PC_Document__c FROM PC_Document_Log__c WHERE PC_Document__c = :recordId and PC_Program__c != null];
                if(docLogObj.size() > 0){
                    request.documentId = recordId;
                    request.recordId = docLogObj[0].PC_Program__c;
                    recordId = docLogObj[0].PC_Program__c;
                }
            } else if (objType == PC_Constants.PC_TASK){
                //FLS check for task
                List<String> taskFields = new List<String>{
                        'Id', 'WhatId', PC_Constants.getQualifiedAPIName('PC_Program__c'), PC_Constants.getQualifiedAPIName('PC_Document__c')
                };
                PC_Database.assertAccess(PC_Constants.PC_TASK, PC_Database.Operation.Reading, taskFields);
                List<Task> taskList = [SELECT Id, WhatId, PC_Program__c, PC_Document__c FROM Task WHERE Id = :recordId LIMIT 1];
                if (taskList.size() > 0) {
                    if (taskList[0].WhatId != null) {
                        request.recordId = taskList[0].WhatId;
                        recordId = taskList[0].WhatId;
                    }
                    request.documentId = (taskList[0].PC_Document__c != null && eletterContext == PC_Constants.PC_ELETTER_CONTEXT_REPLY) ? taskList[0].PC_Document__c : null;
                }
            }

            List<PC_eLetter_Recipient> recipients = (List<PC_eLetter_Recipient>) System.JSON.deserialize(recipientsString, List<PC_eLetter_Recipient>.class);
            // Prepare a list of recipients based on selection on eletter page:
            List<PC_eLetter.RecipientWrapper> faxRecipients = new List<PC_eLetter.RecipientWrapper>();
            List<PC_eLetter.RecipientWrapper> emailRecipients = new List<PC_eLetter.RecipientWrapper>();

            PC_eLetter.RecipientWrapper eletterRecipient = new PC_eLetter.RecipientWrapper();
            for (PC_eLetter_Recipient recipient : recipients) {
                eletterRecipient = recipient.recipient;
                if (recipient.sendFax) {
                    faxRecipients.add(eletterRecipient);
                }
                if (recipient.sendEmail) {
                    emailRecipients.add(eletterRecipient);
                }
            }

            // If the recipient list is empty then throw error message else info message
            if (faxRecipients.isEmpty() && emailRecipients.isEmpty()) {
                return System.Label.PC_Eletter2_NoRecipientSelectedMessage;
            } else {
                PC_eLetter__c eLetter = (String.isNotBlank(letterId)) ? PC_eLetterService.getELetter(letterId) : null;
                if (!emailRecipients.isEmpty()) {
                    system.debug('emailRecipients-----' + emailRecipients);
                    if (eLetter != null && eLetter.PC_Send_to_User__c) {
                        /** Send Email to Logged-in user */
                        PC_eLetterService.sendLetter(recordId, eLetter, PC_Constants.EMAIL, emailRecipients, true, request);
                    } else {
                        /** Send Email to selected recipients */
                        PC_eLetterService.sendLetter(recordId, eLetter, PC_Constants.EMAIL, emailRecipients, false, request);
                    }
                }
                if (!faxRecipients.isEmpty()) {
                    system.debug('faxRecipients-----' + faxRecipients);
                    if (eLetter != null && eLetter.PC_Send_to_User__c) {
                        /** Send Fax to logged-in user */
                        PC_eLetterService.sendLetter(recordId, eLetter, PC_Constants.FAX, faxRecipients, true, request);
                    } else {
                        /** Send Fax to selected recipients */
                        PC_eLetterService.sendLetter(recordId, eLetter, PC_Constants.FAX, faxRecipients, false, request);
                    }
                }
            }
        } catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return System.Label.PC_Eletter2_SendSuccessMessage;
    }

    /*********************************************************************************
    Method Name    : getElettersAsPerEngagementProg
    Description    : Retrieves eLetters on the basis of engagement program of Program case
    Return Type    : List<PC_Engagement_Program_Eletter__c>
    User Story	   : PC-4487
    Author		   : Hitha Avalakki
    *********************************************************************************/
    public static List<PC_Engagement_Program_Eletter__c> getElettersAsPerEngagementProg(Id caseRecordId, String objType, String recordTypeName, List<String> emailCategoryList, List<String> faxCategoryList) {
        //List<PC_eLetter__c> eLetters = new List<PC_eLetter__c>();
        List<PC_Engagement_Program_Eletter__c> engagementProgramEletters = new List<PC_Engagement_Program_Eletter__c>();
        List<Case> caseObject = new List<Case>();
        String queryString, whereConditionString = PC_Constants.EMPTY_STRING;
        List<String> whereConditions = new List<String>();
        List<String> selectedCategory = new List<String>();

        try {
            //FLS check for case
            List<String> caseFields = new List<String>{'Id', 'RecordTypeId', PC_Constants.getQualifiedAPIName('PC_Engagement_Program__c')};
            PC_Database.assertAccess(PC_Constants.PC_CASE, PC_Database.Operation.Reading, caseFields);

            /* PC-7537: Removed the condition of Type in order to fetch eletters for any type of Case record*/
            caseObject = [SELECT Id, PC_Engagement_Program__c FROM Case WHERE Id =:caseRecordId LIMIT 1];
            if (caseObject.size() > 0 && caseObject[0].PC_Engagement_Program__c != null) {
                String caseEngagementProgram = caseObject[0].PC_Engagement_Program__c;
                List<String> eLetterFields = new List<String>();
                eLetterFields = new List<String>{
                        'Id', 'Name', PC_Constants.getQualifiedAPIName('PC_Description__c'), PC_Constants.getQualifiedAPIName('PC_Hide_From_eLetter_Page__c'), PC_Constants.getQualifiedAPIName('PC_Source_Object__c'),
                        PC_Constants.getQualifiedAPIName('PC_Category__c'), PC_Constants.getQualifiedAPIName('PC_Object_Record_Types__c'), PC_Constants.getQualifiedAPIName('PC_AllowExternalRecipients__c')
                };
                PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_eLetter__c'), PC_Database.Operation.Reading, eLetterFields);

                List<Id> eLetterIdsList = new List<Id>();
                List<String> engagementProgEletterFields = new List<String>();
                engagementProgEletterFields = new List<String>{
                        'Id', 'Name', PC_Constants.getQualifiedAPIName('PC_Description__c'), PC_Constants.getQualifiedAPIName('PC_eLetter__c'), PC_Constants.getQualifiedAPIName('PC_Engagement_Program__c')
                };
                PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Engagement_Program_Eletter__c'), PC_Database.Operation.Reading, engagementProgEletterFields);

                for (String category : emailCategoryList){
                    selectedCategory.add('\''+ String.escapeSingleQuotes(category) +'\'');
                }
                for (String category : faxCategoryList){
                    selectedCategory.add('\''+ String.escapeSingleQuotes(category) +'\'');
                }
                whereConditions.add('PC_Engagement_Program__c = :caseEngagementProgram');
                whereConditions.add('PC_eLetter__r.PC_Hide_From_eLetter_Page__c != true');
                whereConditions.add('PC_eLetter__r.PC_Source_Object__c = :objType');
                if(selectedCategory.size() > 0){
                    whereConditions.add('PC_eLetter__r.PC_Category__c INCLUDES (' + String.join(selectedCategory, ',') + ')');
                }
                if (!String.isBlank(recordTypeName)) {
                    whereConditions.add('PC_eLetter__r.PC_Object_Record_Types__c INCLUDES (:recordTypeName)');
                }
                whereConditionString = String.join(whereConditions, ' AND ');
                if(String.isNotBlank(whereConditionString)){
                    whereConditionString = 'WHERE ' + whereConditionString + ' ORDER BY PC_eLetter__r.Name ASC, LastModifiedDate DESC';
                }
                queryString = 'SELECT Id, Name, PC_Description__c, PC_eLetter__r.Id, PC_eLetter__r.Name, PC_eLetter__r.PC_Description__c, PC_eLetter__r.PC_Category__c, PC_eLetter__r.PC_AllowExternalRecipients__c FROM PC_Engagement_Program_Eletter__c '+ whereConditionString;
                system.debug('queryString--->'+queryString);
                engagementProgramEletters = database.query(queryString);
            }
        } catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return engagementProgramEletters;
    }

    /**
   * Get email address of specific engagement program using caseId
   *
   * @param caseId   Id of the case
   */
    public static List<String> getEngagementProgramEmailAddress(Id caseId){
        List<String> emailAddressList = new List<String>();
        Case caseObject = [SELECT Id, PC_Engagement_Program__c FROM Case WHERE Id =:caseId];

        if(caseObject != null && caseObject.PC_Engagement_Program__c != null) {
            List<String> engagementProgramFields = new List<String>();
            engagementProgramFields = new List<String>{
                    'Id', 'Name', PC_Constants.getQualifiedAPIName('PC_ProgramEmails__c')
            };
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Engagement_Program__c'), PC_Database.Operation.Reading, engagementProgramFields);

            PC_Engagement_Program__c engagementProgram = [SELECT Id, Name, PC_ProgramEmails__c from PC_Engagement_Program__c where id = :caseObject.PC_Engagement_Program__c];
            emailAddressList = String.isNotBlank(engagementProgram.PC_ProgramEmails__c) ? (engagementProgram.PC_ProgramEmails__c).trim().split('\\s*,\\s*') : new List<String>();
        }
        return emailAddressList;
    }

    /**
   * Method helps to create List<EletterFromAddress> from the OrgWideEmailAddress List
   *
   * @param emailIds   A List of emailId
   * @return List of EletterFromAddress
   */
    public static List<EletterFromAddress> getFromAddressList(List<String> emailIds){
        List<EletterFromAddress> fromAddressList = new List<EletterFromAddress>();
        try {
            fromAddressList.add(new EletterFromAddress(UserInfo.getName(), UserInfo.getUserEmail(), UserInfo.getUserId()));
            if(emailIds.size() > 0 && UserInfo.getUserType() == PC_Constants.PC_USERTYPE_STANDARD) {
                List<OrgWideEmailAddress> oweaList = getOrgWideEmailAddresses(emailIds);
                for (OrgWideEmailAddress owea : oweaList) {
                    fromAddressList.add(new EletterFromAddress(owea.DisplayName, owea.Address, owea.Id));
                }
            }
        } catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return fromAddressList;
    }

    /**
   * Method takes list of emailIds as input parameter and returns the list of OrgWideEmailAddress that matches input emailIds
   *
   * @param emailIds   A List of emailId
   * @return List of OrgWideEmailAddress
   */
    public static List<OrgWideEmailAddress> getOrgWideEmailAddresses (List<String> emailIds) {
        List<OrgWideEmailAddress> lstEmailAddress = new List<OrgWideEmailAddress>();
        try {
            // FLS for OrgWideEmailAddress
            List<String> orgWideEmailAddressFields = new List<String>();
            orgWideEmailAddressFields = new List<String>{ 'Id', 'Address', 'DisplayName' };
            PC_Database.assertAccess('OrgWideEmailAddress', PC_Database.Operation.Reading, orgWideEmailAddressFields);
            // Query from Organization-Wide Email Address
            lstEmailAddress=[select Id, Address, DisplayName from OrgWideEmailAddress WHERE Address IN :emailIds];
        } catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return lstEmailAddress;
    }

    /**
    * Wrapper for the eletter FromAddress.
    */
    public class EletterFromAddress {
        @AuraEnabled public String displayName { get; set; }
        @AuraEnabled public String emailAddress { get; set; }
        @AuraEnabled public String fromId { get; set; }

        public EletterFromAddress() {
            displayName = PC_Constants.EMPTY_STRING;
            emailAddress = PC_Constants.EMPTY_STRING;
            fromId = PC_Constants.EMPTY_STRING;
        }

        public EletterFromAddress(String displayName, String emailAddress, String fromId) {
            this.displayName = displayName;
            this.emailAddress = emailAddress;
            this.fromId = fromId;
        }
    }

    /**
    * Wrapper for the eletter template.
    */
    public class EletterTemplate {
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String value { get; set; }
        @AuraEnabled public String description { get; set; }
        @AuraEnabled public String categories { get; set; }
        @AuraEnabled public String engProgEletterDescription { get; set; }
        @AuraEnabled public Boolean allowAdditionalRecipients { get; set; }

        public EletterTemplate(PC_Engagement_Program_Eletter__c epe) {
            name = epe.PC_eLetter__r.Name;
            value = epe.PC_eLetter__r.Id;
            categories  = epe.PC_eLetter__r.PC_Category__c; // value is separated by Semicolon(;)
            description = epe.PC_eLetter__r.PC_Description__c;
            engProgEletterDescription = epe.PC_Description__c;
            allowAdditionalRecipients = epe.PC_eLetter__r.PC_AllowExternalRecipients__c;
        }
    }

    public class EletterTemplateWrapper {
        @AuraEnabled public List<EletterTemplate> eletterTemplateList;
        @AuraEnabled public List<EletterFromAddress> eletterFromAddressList;

        public EletterTemplateWrapper(){
            eletterTemplateList = new List<EletterTemplate>();
            eletterFromAddressList = new List<EletterFromAddress>();
        }

        public EletterTemplateWrapper(List<EletterTemplate> eletterTemplates, List<EletterFromAddress> eletterFromAddresses) {
            eletterTemplateList = eletterTemplates;
            eletterFromAddressList = eletterFromAddresses;
        }
    }

    /**
    * Wrapper for the eLetter Recipients and rendered template
    */
    public class EletterInfo {
        @AuraEnabled public RenderedMailTemplate renderedMailTemplate { get; set; }
        @AuraEnabled public List<PC_eLetter_Recipient> eLetterRecipients { get; set; }

        public EletterInfo() {
        }
        public EletterInfo(RenderedMailTemplate renderedMailTemplate, List<PC_eLetter_Recipient> eLetterRecipients) {
            this.renderedMailTemplate = renderedMailTemplate;
            this.eLetterRecipients = eLetterRecipients;
        }
    }

    /**
    * Wrapper for the rendered mail template.
    */
    public class RenderedMailTemplate {
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String subject { get; set; }
        @AuraEnabled public String templateType { get; set; }
        @AuraEnabled public String plainTextBody { get; set; }
        @AuraEnabled public String htmlBody { get; set; }
        @AuraEnabled public List<PC_AttachmentController.RecordAttachment> templateAttachments { get; set; }

        public RenderedMailTemplate() {
            this.name = PC_Constants.EMPTY_STRING;
            this.subject = PC_Constants.EMPTY_STRING;
            this.templateType = PC_Constants.EMPTY_STRING;
            this.plainTextBody = PC_Constants.EMPTY_STRING;
            this.htmlBody = PC_Constants.EMPTY_STRING;
            this.templateAttachments = new List<PC_AttachmentController.RecordAttachment>();
        }

        public RenderedMailTemplate(String name, String subject, String templateType, String plainTextBody, String htmlBody) {
            this.name = name;
            this.subject = subject;
            this.templateType = templateType;
            this.plainTextBody = plainTextBody;
            this.htmlBody = htmlBody;
        }
    }

    /**
    * Wrapper for the send eletter request.
    */
    public class SendLetterRequest {
        @AuraEnabled public FromAddress fromAddress { get; set; }
        @AuraEnabled public String eletterId { get; set; }
        @AuraEnabled public String eletterContext { get; set; }
        @AuraEnabled public String recordId { get; set; }
        @AuraEnabled public String documentId { get; set; }
        @AuraEnabled public Boolean isSecureEmail { get; set; }
        @AuraEnabled public Boolean sendToCurrentUser { get; set; }
        @AuraEnabled public List<String> attachmentIds { get; set; }
        @AuraEnabled public String subject { get; set; }
        @AuraEnabled public String textBody { get; set; }
        @AuraEnabled public String htmlBody { get; set; }
        @AuraEnabled public String communicationMethod { get; set; }

        public SendLetterRequest(){
            eletterContext = PC_Constants.EMPTY_STRING;
            fromAddress = new FromAddress();
            eletterId = PC_Constants.EMPTY_STRING;
            recordId = PC_Constants.EMPTY_STRING;
            documentId = PC_Constants.EMPTY_STRING;
            isSecureEmail = PC_Constants.FALSE_BOOLEAN;
            sendToCurrentUser = PC_Constants.FALSE_BOOLEAN;
            attachmentIds = new List<String>();
            subject = PC_Constants.EMPTY_STRING;
            textBody = PC_Constants.EMPTY_STRING;
            htmlBody = PC_Constants.EMPTY_STRING;
            communicationMethod = PC_Constants.EMPTY_STRING;
        }
    }

    /**
    * Wrapper object for fromAddress.
    */
    public class FromAddress {
        public String name;
        public String address;
        public String fromId;
        public FromAddress(){
            name = PC_Constants.EMPTY_STRING;
            address = PC_Constants.EMPTY_STRING;
            fromId = PC_Constants.EMPTY_STRING;
        }
    }

    public class Eletter2Exception extends Exception {}
}