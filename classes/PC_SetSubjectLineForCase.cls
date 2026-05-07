/**********************************************************************************************************************************************************
Class Name      : PC_SetSubjectLineForCase
Description     : Set customized Subject line for program and service cases
Created By      : Hitha Avalakki
Created Date    : May 31, 2019
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer                   Date                   	Description
--------------------------------------------------------------------------------------------------------------
Hitha Avalakki				May 31, 2019			PC-4772: Initial version
Hitha Avalakki				June 28, 2019           PC-5004: When a service case is created and has no Program case Account/Applicant/Engagement Program details from
                                                             should be fetched from the service case itself and not program case
Hitha Avalakki              July 8, 2019            PC-5004: Added a new method 'getAccountApplicantDetails' in order to concatenate Account/Applicant's
                                                             Last Name,First Name details
Hitha Avalakki              Mar 19, 2021            PC-7533: Replaced constant CASE_PROGRAM_RECORD_TYPE_NAME to CASE_PROGRAM_TYPE
Hitha Avalakki              May 25, 2021            PC-7545: Removed 'with sharing' class level declaration since trigger handler code runs in system context.
Satheesh Kumar              Nov 16, 2021            [PC-8213] Excluded FLS Check and added inherited sharing
*****************************************************************************************************************************************************************/

/* PC-7545: 'with sharing' class level declaration is not required since trigger handler code runs in Trigger Context*/
public inherited sharing class PC_SetSubjectLineForCase extends PC_TriggerHandler{
    private static Map<String,String> caseTypeAndValueMap=new Map<String, String>();
    private static final String ACCOUNT = 'Account';
    private static final String APPLICANT = 'Applicant';
    private static final String ENGAGEMENT_PROGRAM = 'Engagement Program';

    override public void beforeInsert() {
        evaluateForSubjectChange((List<Case>) newList);
    }

    override public void beforeUpdate() {
        evaluateForSubjectChange((Map<Id, Case>) oldMap, (List<Case>) newList);
    }

    /**
     * @Description Evaluate if the subject needs to be modified
     * @param newCaseList List of new Cases to be created
     * @return  NA
    */
    private void evaluateForSubjectChange(List<Case> newList) {
        List<Case> sendForUpdate =  new List<Case>();
        for(Case c : newList){
            if(String.isBlank(c.Subject)){
                sendForUpdate.add(c);
            }
        }
        setSubjectLine(sendForUpdate);
    }

    /**
     * @Description Evaluate if the subject needs to be modified
     * @param oldMap Map of Cases before update.
     * @param newCaseList List of new Cases to be created
     * @return  NA
    */
    private void evaluateForSubjectChange(Map<Id, Case> oldMap, List<Case> newList) {
        List<Case> sendForUpdate =  new List<Case>();
        for(Case c : newList){
            if((c.Subject == oldMap.get(c.Id).Subject)){
                sendForUpdate.add(c);
            }
        }
        setSubjectLine(sendForUpdate);
    }

    /**
     * @Description Set customized Subject line for service cases of patient program cases
     * @param newCaseList List of new Cases to be created
     * @return  NA
    */
    private void setSubjectLine(List<Case> newList) {
        List<Case> programCaseList=new List<Case>();
        List<Case> programCasesOfServiceCasesList=new List<Case>();
        List<Case> serviceCaseList=new List<Case>();
        List<Id> programCaseIdList=new List<Id>();
        RecordIdDetailsWrapper recordIdDetailsWrapper=new RecordIdDetailsWrapper();
        Map<Id,Case> progCaseOfServiceCaseMap=new Map<Id, Case>();
        Map<Id,String> programCaseTypeMap=new Map<Id,String>();
        List<Id> programCaseIdOfServiceCaseList=new List<Id>();
        Map<Id,List<Case>> programToServiceCase = new Map<Id,List<Case>>();

        /** Following Map is required to get translated 'Type' field labels which would be used for preparing Subject Line description **/
        caseTypeAndValueMap=getCaseTypeAndTranslatedValMap(Case.Type.getDescribe());

        /** Create separate lists for service cases, program cases' records and for service cases and program cases' record types **/
        for(Case newCaseRecord:newList){
            /** Any case which is neither 'Program' nor 'Enrollment' would be treated as service case **/
            if(newCaseRecord.Type != PC_Constants.CASE_PROGRAM_TYPE && newCaseRecord.Type != PC_Constants.CASE_ENROLLMENT_RECORD_TYPE_NAME){

                /**** If condition: This is meant for those service cases which have a program case populated in 'PC_Program__c' field  ****/
                /**** PC-5004: else condition: This is meant for those service cases which DON'T have a program case populated in 'PC_Program__c' field  ****/
                if(newCaseRecord.PC_Program__c!=null){
                    programCaseIdList.add(newCaseRecord.PC_Program__c);
                    if(programToServiceCase.containsKey(newCaseRecord.PC_Program__c)){
                        List<Case> tempCase = new List<Case>();
                        tempCase =  programToServiceCase.get(newCaseRecord.PC_Program__c);
                        tempCase.add(newCaseRecord);
                        programToServiceCase.put(newCaseRecord.PC_Program__c,tempCase);
                    }else{
                        List<Case> tempCase = new List<Case>();
                        tempCase.add(newCaseRecord);
                        programToServiceCase.put(newCaseRecord.PC_Program__c,tempCase);
                    }
                }
                else{
                    programCaseList.add(newCaseRecord);
                }
            }
            else{
                programCaseList.add(newCaseRecord);
            }
        }

        /**** Fetch the type of all the program cases present on service cases ****/
        List<Case> programCasesList=[SELECT Id, Type FROM Case  WHERE Id IN: programCaseIdList];
        for(Case caseRecord: programCasesList){
            programCaseTypeMap.put(caseRecord.Id, caseRecord.Type);
        }

        /* Following piece of code is required to decide if the Program case field of Service case has 'Program' type of case since the field
        'PC_Program__c' is a lookup to cases without any filtration condition and hence can take any non program case value as well.*/
        for(Id programCaseId : programToServiceCase.keySet()){
            if(programCaseTypeMap.containsKey(programCaseId)){
                programCaseIdOfServiceCaseList.add(programCaseId);
            }   serviceCaseList.addAll(programToServiceCase.get(programCaseId));
        }

        /** Fetch the details of program cases of service cases **/
        if(programCaseIdOfServiceCaseList!=null && !programCaseIdOfServiceCaseList.isEmpty()){

            programCasesOfServiceCasesList=[SELECT Id,AccountId,PC_ActiveApplicant__c,RecordTypeId,PC_Engagement_Program__c
                                            FROM Case
                                            WHERE Id IN:programCaseIdOfServiceCaseList];

            /** Below Map is required to populate Subject line details, since for service cases, the details are pulled up from corresponding Program cases,
              whereas the same is not required for Program cases **/
            for(Case caseRec:programCasesOfServiceCasesList){
                progCaseOfServiceCaseMap.put(caseRec.Id,caseRec);
            }
        }

        /** Populate subject line for service cases **/
        if(programCasesOfServiceCasesList!=null && !programCasesOfServiceCasesList.isEmpty()){

            /** Fetch details for creating Subject line description for service cases **/
            recordIdDetailsWrapper= fetchDetailsForSubjectLine(programCasesOfServiceCasesList);

            /** Populate Subject Line description for service cases **/
            populateSubjectLineForCases(recordIdDetailsWrapper, serviceCaseList,progCaseOfServiceCaseMap);
        }

        /** Populate subject line for program cases **/
        if(programCaseList!=null && !programCaseList.isEmpty()){

            /** Fetch details for creating Subject line description for program cases **/
            recordIdDetailsWrapper= fetchDetailsForSubjectLine(programCaseList);

            /** Populate Subject Line description for program cases **/
            populateSubjectLineForCases(recordIdDetailsWrapper, programCaseList,progCaseOfServiceCaseMap);
        }
    }

    /*********************************************************************************
    Method Name    : fetchDetailsForSubjectLine
    Author         : Hitha Avalakki
    Description    : This method is used to fetch Program's Account, Engagement Program Details to develop the Subject line for cases
    Return Type    : RecordIdDetailsWrapper
    Parameter      : List<Case>
    User-Story     : PC-4772
    *********************************************************************************/
    public RecordIdDetailsWrapper fetchDetailsForSubjectLine(List<Case> programCasesList){

        List<List<Id>> allIdsList=new List<List<Id>>();
        Map<String, List<Id>> allIdsMap=new Map<String, List<Id>>();
        RecordIdDetailsWrapper recordIdDetailsWrapper=new RecordIdDetailsWrapper();

        /** Get separate lists of Ids of Account, Applicant and Engagement Programs of program cases **/
        allIdsMap=getSeparatedIdList(programCasesList);

        /** Get details of Accounts, Applicants and Engagement Programs of program cases **/
        recordIdDetailsWrapper=fetchRecordDetails(allIdsMap);

        return recordIdDetailsWrapper;
    }

    /*************************************************************************************************************************
    Method Name    : getSeparatedIdList
    Author         : Hitha Avalakki
    Description    : This method is used to create separate Id lists for Account, Applicant and Engagement program of cases
    Return Type    : Map<String, List<Id>>
    Parameter      : List<Case>
    User-Story     : PC-4772
    *************************************************************************************************************************/
    public Map<String, List<Id>> getSeparatedIdList(List<Case> caseList){
        List<Id> accountIdList=new List<Id>();
        List<Id> applicantIdList=new List<Id>();
        List<Id> engagementProgramIdList=new List<Id>();
        Map<String, List<Id>> allIdsMap=new Map<String, List<Id>>();

        for(Case caseRecord: caseList){

            if(caseRecord.AccountId!=null){
                accountIdList.add(caseRecord.AccountId);
            }else if(caseRecord.PC_ActiveApplicant__c!=null){
                applicantIdList.add(caseRecord.PC_ActiveApplicant__c);
            }
            if(caseRecord.PC_Engagement_Program__c!=null){
                engagementProgramIdList.add(caseRecord.PC_Engagement_Program__c);
            }
        }

        allIdsMap.put(ACCOUNT, accountIdList);
        allIdsMap.put(APPLICANT, applicantIdList);
        allIdsMap.put(ENGAGEMENT_PROGRAM, engagementProgramIdList);

        return  allIdsMap;
    }

    /*************************************************************************************************************************
    Method Name    : fetchRecordDetails
    Author         : Hitha Avalakki
    Description    : This method is used to fetch record details of Account, Applicant and Engagement program of Cases
    Return Type    : RecordIdDetailsWrapper
    Parameter      : List<List<Id>>
    User-Story     : PC-4772
    *************************************************************************************************************************/
    public RecordIdDetailsWrapper fetchRecordDetails(Map<String, List<Id>> allIdsMap){
        RecordIdDetailsWrapper recordIdDetailsWrapper=new RecordIdDetailsWrapper();
        Map<Id,Account> accountIdAccountRecMap=new Map<Id, Account>();
        Map<Id,String> engagementProgramDetailsMap=new Map<Id, String>();
        Map<Id,PC_Applicant__c> appIdAppRecMap=new Map<Id, PC_Applicant__c>();
        List<PC_Engagement_Program__c> engagementProgramDetailsList=new List<PC_Engagement_Program__c>();

        /** Get details of accounts of service cases **/
        if(allIdsMap.get(ACCOUNT)!=null && !allIdsMap.get(ACCOUNT).isEmpty()){
            accountIdAccountRecMap = new Map<Id,Account>([SELECT Id, PC_First_Name__c, PC_Last_Name__c FROM Account WHERE Id IN: allIdsMap.get(ACCOUNT)]);
        }

        /** Get details of applicants of service cases **/
        if(allIdsMap.get(APPLICANT)!=null && !allIdsMap.get(APPLICANT).isEmpty()){
            appIdAppRecMap = new Map<Id,PC_Applicant__c>([SELECT Id, PC_First_Name__c, PC_Last_Name__c FROM PC_Applicant__c WHERE Id IN: allIdsMap.get(APPLICANT)]);
        }

        /** Get details of engagement program of service cases **/
        if(allIdsMap.get(ENGAGEMENT_PROGRAM)!=null && !allIdsMap.get(ENGAGEMENT_PROGRAM).isEmpty()) {
            engagementProgramDetailsList = [SELECT Id, Name FROM PC_Engagement_Program__c WHERE Id IN:allIdsMap.get(ENGAGEMENT_PROGRAM)];
        }

        for(PC_Engagement_Program__c engagmentProgram:engagementProgramDetailsList){
            engagementProgramDetailsMap.put(engagmentProgram.Id, engagmentProgram.Name);
        }

        recordIdDetailsWrapper.accountIdAccountRecMap=accountIdAccountRecMap;
        recordIdDetailsWrapper.engagementProgramDetailsMap=engagementProgramDetailsMap;
        recordIdDetailsWrapper.appIdAppRecMap=appIdAppRecMap;

        return recordIdDetailsWrapper;
    }

    /*************************************************************************************************************************
    Method Name    : populateSubjectLineForCases
    Author         : Hitha Avalakki
    Description    : This method is used to populate Cases with Subject lines
    Return Type    : void
    Parameter      : RecordIdDetailsWrapper, List<Case>, Map<Id,Case>
    User-Story     : PC-4772
    *************************************************************************************************************************/
    public void populateSubjectLineForCases(RecordIdDetailsWrapper recordIdDetailsWrapper, List<Case> casesList,Map<Id,Case> programCasesOfServiceCaseMap){
        for(Case caseRecord: casesList){
            String subjectLine='';
            String accountOrApplicantDetails ='';
            String engagementProgramDetails ='';
            String caseRecordTypeDetails ='';

            Id accountId;
            Id applicantId;
            Id engagementProgramId;

            /* Following logic has been introduced in order to make code generic for Program and Non-Program cases.
             * Since the subject for non-program cases(service cases) is constructed using the Account, Engagement Program details of its Program case and
             * Program cases use their own Account, Engagement Program details for Subject lines
             */
            if(caseRecord.Type != PC_Constants.CASE_PROGRAM_TYPE && caseRecord.Type != PC_Constants.CASE_ENROLLMENT_RECORD_TYPE_NAME){

                /** The null check is required if a service case doesn't have a program case. **/
                /** PC-5004: else condition: It has been introduced since if a service case doesn't have a program case,
                                             then the service cases details would be used to prepare the subject line **/
                if(caseRecord.PC_Program__c!=null){
                    if(programCasesOfServiceCaseMap!=null && !programCasesOfServiceCaseMap.isEmpty() &&
                            programCasesOfServiceCaseMap.containsKey(caseRecord.PC_Program__c)){

                        accountId = programCasesOfServiceCaseMap.get(caseRecord.PC_Program__c).AccountId;
                        applicantId = programCasesOfServiceCaseMap.get(caseRecord.PC_Program__c).PC_ActiveApplicant__c;
                        engagementProgramId = programCasesOfServiceCaseMap.get(caseRecord.PC_Program__c).PC_Engagement_Program__c;
                    }
                }
                else{
                    accountId = caseRecord.AccountId;
                    applicantId = caseRecord.PC_ActiveApplicant__c;
                    engagementProgramId = caseRecord.PC_Engagement_Program__c;
                }

            }else{
                accountId = caseRecord.AccountId;
                applicantId = caseRecord.PC_ActiveApplicant__c;
                engagementProgramId = caseRecord.PC_Engagement_Program__c;
            }

            /** Get the Account/Applicant details to be added to Subject line **/
            if(accountId!= null){
                /** PC-5004: Get Account's Last Name, First Name details **/
                if(recordIdDetailsWrapper.accountIdAccountRecMap!=null && recordIdDetailsWrapper.accountIdAccountRecMap.containsKey(accountId)){
                    accountOrApplicantDetails = getAccountApplicantDetails(recordIdDetailsWrapper.accountIdAccountRecMap.get(accountId).PC_First_Name__c, recordIdDetailsWrapper.accountIdAccountRecMap.get(accountId).PC_Last_Name__c);
                }
            }
            else if(applicantId!= null){
                /** PC-5004: Get Applicant's Last Name, First Name details **/
                if(recordIdDetailsWrapper.appIdAppRecMap!=null && recordIdDetailsWrapper.appIdAppRecMap.containsKey(applicantId)) {
                    accountOrApplicantDetails = getAccountApplicantDetails(recordIdDetailsWrapper.appIdAppRecMap.get(applicantId).PC_First_Name__c, recordIdDetailsWrapper.appIdAppRecMap.get(applicantId).PC_Last_Name__c);
                }
            }

            /** Get the Engagement Program details to be added to Subject line **/
            if(engagementProgramId!= null && recordIdDetailsWrapper.engagementProgramDetailsMap.get(engagementProgramId)!= null){
                engagementProgramDetails = recordIdDetailsWrapper.engagementProgramDetailsMap.get(engagementProgramId);
            }

            /** Get the Case Type details to be added to Subject line **/
            caseRecordTypeDetails = caseTypeAndValueMap.get(caseRecord.Type);

            /** Prepare the subject line as per the details available
             * Please note:
             * 1) If only account/applicant details are available, then the subject will contain only accountOrApplicantDetails
             * 2) If only account/applicant details and engagement program details are available, then the subject will contain accountOrApplicantDetails+' - ' + engagement program details
             * 3) If all the details are available then subject will contain accountOrApplicantDetails+' - ' + engagement program details + ' - '+ case type details
             * i.e. ' - ' character would be added in the subject as and when required **/
            if(!String.isBlank(accountOrApplicantDetails)){
                subjectLine = subjectLine+accountOrApplicantDetails;
            }
            if(!String.isBlank(engagementProgramDetails) && !String.isBlank(subjectLine)){
                subjectLine = subjectLine+' - '+engagementProgramDetails;
            }
            else if(!String.isBlank(engagementProgramDetails)){
                subjectLine = subjectLine+engagementProgramDetails;
            }

            if(!String.isBlank(caseRecordTypeDetails) && !String.isBlank(subjectLine)){
                subjectLine = subjectLine+' - '+caseRecordTypeDetails;
            }
            else if(!String.isBlank(caseRecordTypeDetails)){
                subjectLine = subjectLine+caseRecordTypeDetails;
            }
            caseRecord.Subject = subjectLine;
        }
    }

    /*************************************************************************************************************************
    Method Name    : getCaseTypeAndTranslatedValMap
    Author         : Hitha Avalakki
    Description    : This method is used to get translates Labels of picklist values
    Return Type    : Map<String,String>
    Parameter      : Schema.DescribeFieldResult
    User-Story     : PC-4772
    *************************************************************************************************************************/
    public Map<String,String> getCaseTypeAndTranslatedValMap(Schema.DescribeFieldResult descField) {
        Map<String,String> caseTypeMap  = new Map<String,String>();

        for (Schema.PicklistEntry picklistEntry : descField.getPicklistValues()) {
            caseTypeMap.put(picklistEntry.getValue(),picklistEntry.getLabel());
        }

        return caseTypeMap;
    }

    /*************************************************************************************************************************
    Method Name    : getAccountApplicantDetails
    Author         : Hitha Avalakki
    Description    : This method is used to get concatenated string of account/applicant's first name, last name details
    Return Type    : String
    Parameter      : String, String, String
    User-Story     : PC-5004
    *************************************************************************************************************************/
    public String getAccountApplicantDetails(String firstName, String lastName) {

        String accountApplicantDetails='';

        if(!String.isBlank(lastName) && !String.isBlank(firstName)){
            accountApplicantDetails = lastName+ ', '+ firstName;
        }
        else if(String.isBlank(lastName) && !String.isBlank(firstName)){
            accountApplicantDetails = firstName;
        }
        else if(!String.isBlank(lastName) && String.isBlank(firstName)){
            accountApplicantDetails = lastName;
        }
        return accountApplicantDetails;
    }

    /*********************************************************************************************************
    Class Name    : RecordIdDetailsWrapper
    Author        : Hitha Avalakki
    Description   : Wrapper class for record id details of account,applicant,recordtype and engagement program
    User-Story    : PC-4772
    **********************************************************************************************************/
    public class RecordIdDetailsWrapper{
        Map<Id,Account> accountIdAccountRecMap;
        Map<Id,String> engagementProgramDetailsMap;
        Map<Id,PC_Applicant__c> appIdAppRecMap;

        public RecordIdDetailsWrapper(){
            accountIdAccountRecMap=new Map<Id, Account>();
            engagementProgramDetailsMap=new Map<Id, String>();
            appIdAppRecMap=new Map<Id, PC_Applicant__c>();
        }
    }
}