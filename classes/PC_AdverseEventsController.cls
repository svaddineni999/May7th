/*********************************************************************************
Class Name      :   PC_AdverseEventsController
Description        : Controller for PC_AdverseEvents Component
Created By        : Haritha Reddy
Created Date     : 14-11-2018
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------
Haritha Reddy          14-11-2018              Initial Version
Hitha Avalakki         18-02-2019              [PC-4384]Added new method getAdverseEventConfigData and new class AdverseEventConfig to handle data related to
                                               AdditionalInfo tab to be displayed on AE PDF page
Shishir Bansal         11-10-2019             [PC-5570]  Added two methods to fetch parent records with no child and the latest child records if present
                                                . version number check if it is null (for old records pass 1) , version Number label to be shown on UI
Shishir Bansal         06-12-2019             [PC-5792] Avoid hardcoding of string variable
Haritha Reddy          11-Dec-2019            [PC-5791] Added Error handling for getFieldLabels method
Shishir Bansal         13-Dec-2019            [PC-5812] Added the logic to filter custom metadata values based on Case Record type too
                                                (along with Engagement program and Active Status)
*********************************************************************************/

public with sharing class PC_AdverseEventsController
{
    public class InitData {
        @AuraEnabled public List<ListWrapper> AEList;
        @AuraEnabled public FieldLabels fieldLabels ;
        @AuraEnabled public String dateFormat;
        @AuraEnabled public String dateFormatErrorMessage ;

        public InitData() {
            AEList = new List<ListWrapper>();
            fieldLabels  = new FieldLabels();
            dateFormat = PC_SYSTEM.getPatientConnectSetting(PC_Constants.PC_AE_DOWNLOAD_DATEFORMAT_NAME,
                    null) ;

        }
    }

    /*********************************************************
    Method Name          : getRelAERecs
    Description               : fetch Adverse Event Records related to the Program Case
    Input Params            : List<Id> CaseId
    Return Type             : InitData Wrapper
    *********************************************************************************/
    @AuraEnabled
    public static InitData getRelAERecs(List<Id> caseId){

        InitData initData = new InitData();
        try{
            LIST<ListWrapper> listInfo 	= new LIST <ListWrapper>();
            LIST<PC_AdverseEvent__c> relAEList = new LIST <PC_AdverseEvent__c>();
            LIST<PC_Suspect_Prescription__c> relProdList = new LIST <PC_Suspect_Prescription__c>();
            //Check FLS
            List<String> fields = new List<String>{
            PC_Constants.getQualifiedAPIName('Id'),
            PC_Constants.getQualifiedAPIName('Name'),
            PC_Constants.getQualifiedAPIName('PC_Event_PT__c'),
            PC_Constants.getQualifiedAPIName('PC_Event_LLT__c'),
            PC_Constants.getQualifiedAPIName('PC_Reporter__c'),
            PC_Constants.getQualifiedAPIName('PC_ParentAdverseEvent__c'),
            PC_Constants.getQualifiedAPIName('PC_SubmissionStatus__c'),
            PC_Constants.getQualifiedAPIName('PC_LatestAdverseEvent__c'),
            PC_Constants.getQualifiedAPIName('PC_VersionNumber__c'),
            PC_Constants.getQualifiedAPIName('PC_EventType__c')
            };
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_AdverseEvent__c'),PC_Database.Operation.Reading, fields);
            List<String> spFields = new List<String>{
                    PC_Constants.getQualifiedAPIName('Id'),
                    PC_Constants.getQualifiedAPIName('Name')};
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Suspect_Prescription__c'),PC_Database.Operation.Reading, spFields);



            /* Creating a set of Latest AdverseEvent2 record Ids so that we can filter the latest AE2 record on list Menu*/

            LIST<PC_AdverseEvent__c>  aeList = new LIST<PC_AdverseEvent__c>();
            Set<Id> latestAEIdList = new Set<Id>();
            aeList = [SELECT PC_LatestAdverseEvent__c FROM PC_AdverseEvent__c where  PC_ParentAdverseEvent__c = Null AND PC_LatestAdverseEvent__c !=Null];
            if(aeList.size()>0) {
                for (PC_AdverseEvent__c aeRecord : aeList) {
                    latestAEIdList.add(aeRecord.PC_LatestAdverseEvent__c);
                }
            }

            /*
            * where clause covers the scenarios of
             * backward compatibility old records
            * newly created AdverseEvent2 records
            * Latest Adverse Event2 records
            *
            * */

            relAEList = [SELECT Id, Name, PC_Reporter_First_Name__c, PC_Reporter_Last_Name__c, PC_Event_PT_Code__c, PC_Event_LLT_Code__c,PC_ParentAdverseEvent__c,
                    PC_SubmissionStatus__c,PC_LatestAdverseEvent__c,PC_VersionNumber__c,PC_LatestAdverseEvent__r.PC_VersionNumber__c,
                    PC_LatestAdverseEvent__r.PC_SubmissionStatus__c,PC_EventType__c,PC_LatestAdverseEvent__r.Name,
                            (SELECT Id,Name FROM Suspect_Prescriptions__r)
                            FROM PC_AdverseEvent__c
                            WHERE   PC_Care_Program__c in :caseId AND ( (PC_ParentAdverseEvent__c = NULL AND PC_VersionNumber__c = NULL AND PC_LatestAdverseEvent__c = Null)
                            OR (PC_ParentAdverseEvent__c = NULL AND PC_VersionNumber__c = 1 AND PC_LatestAdverseEvent__c =Null )
                            OR (PC_LatestAdverseEvent__c =NULL AND PC_ParentAdverseEvent__c !=NULL AND PC_VersionNumber__c != NULL AND Id IN :latestAEIdList
                            ) )
                             ORDER BY LastModifiedDate DESC];


           /* LIST<PC_AdverseEvent__c> relParentAEList = new LIST <PC_AdverseEvent__c>();
            relParentAEList = getRelatedParentAERecords(caseId);
            if(relParentAEList != Null) {
                relAEList.addAll(relParentAEList);
            }
            LIST<PC_AdverseEvent__c> relLatestAEList = new LIST <PC_AdverseEvent__c>();
            relLatestAEList = getRelatedLatestAERecords(caseId);

            if(relLatestAEList != Null) {
                relAEList.addAll(relLatestAEList);
            } */

            if(relAEList !=null){
                if(!relAEList.isEmpty()){
                    for(PC_AdverseEvent__c ae : relAEList){
                        List<PC_Suspect_Prescription__c> spList = new List<PC_Suspect_Prescription__c>();
                        for(PC_Suspect_Prescription__c sp : ae.Suspect_Prescriptions__r){
                            spList.add(sp);
                        }
                        listInfo.add(new ListWrapper(ae,spList));
                    }
                }
            }


            initData.AEList = listInfo;
            initData.fieldLabels = getFieldLabels();
            try {
                    Datetime todayDateTime = Datetime.now();
                    String successDateFormatting = todayDateTime.format(initData.dateFormat);
            }catch(Exception ex){
                initData.dateFormatErrorMessage = ex.getMessage();
            }


        }catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return initData;
    }



    /********************************************************************************
    Method Name          : getRelatedParentAERecords
    Description          : fetching parent AE records related to caseId
    Input Params         : Id
    Return Type          : LIST<PC_AdverseEvent__c>
    *********************************************************************************/
    public static LIST<PC_AdverseEvent__c> getRelatedParentAERecords(List<Id> caseId){

        if(String.isNotBlank(String.valueOf(caseId))){
            LIST<PC_AdverseEvent__c>  aeList = new LIST<PC_AdverseEvent__c>();
            aeList = [SELECT Id, Name, PC_Reporter_First_Name__c, PC_Reporter_Last_Name__c, PC_Event_PT_Code__c, PC_Event_LLT_Code__c,PC_ParentAdverseEvent__c,
                    PC_SubmissionStatus__c,PC_LatestAdverseEvent__c,PC_VersionNumber__c, PC_EventType__c,
            (SELECT Id,Name FROM Suspect_Prescriptions__r)
            FROM PC_AdverseEvent__c
            WHERE  PC_Care_Program__c in :caseId AND PC_ParentAdverseEvent__c = NULL AND
            PC_LatestAdverseEvent__c = NULL
            ORDER BY CreatedDate DESC];
            return aeList;
        }
        return null;
    }

    /********************************************************************************
    Method Name          : getRelatedLatestAERecords
    Description          : fetching Latest AE records related to caseId
    Input Params         : Id
    Return Type          : LIST<PC_AdverseEvent__c>
    *********************************************************************************/
    public static LIST<PC_AdverseEvent__c> getRelatedLatestAERecords(List<Id> caseId){

        if(String.isNotBlank(String.valueOf(caseId))){
            LIST<PC_AdverseEvent__c>  aeList = new LIST<PC_AdverseEvent__c>();

            List<Id> latestAEIdList = new List<Id>();

            aeList = [SELECT PC_LatestAdverseEvent__c FROM PC_AdverseEvent__c where  PC_ParentAdverseEvent__c = Null AND PC_LatestAdverseEvent__c !=Null];
            if(aeList.size()>0) {
                for (PC_AdverseEvent__c aeRecord : aeList) {
                    latestAEIdList.add(aeRecord.PC_LatestAdverseEvent__c);
                }

                aeList = [
                        SELECT Id, Name, PC_Reporter_First_Name__c, PC_Reporter_Last_Name__c, PC_Event_PT_Code__c, PC_Event_LLT_Code__c,PC_ParentAdverseEvent__c,
                                PC_SubmissionStatus__c,PC_LatestAdverseEvent__c,PC_VersionNumber__c, PC_EventType__c, (SELECT Id,Name FROM Suspect_Prescriptions__r)
                        FROM PC_AdverseEvent__c
                        WHERE PC_Care_Program__c in :caseId AND Id in :latestAEIdList
                        ORDER BY CreatedDate DESC
                ];
                return aeList;
            }
        }
        return null;
    }

    /*********************************************************
    Method Name          : getFieldLabels
    Description               : fetch Field Labels from Database
    Input Params            : NA
    Return Type             : FieldLabels Wrapper
    *********************************************************************************/
    @AuraEnabled
    public static FieldLabels getFieldLabels(){
        FieldLabels fieldlabels 		= new FieldLabels();
        try {
            fieldlabels.name = PC_AdverseEvent__c.Name.getDescribe().getLabel();
            fieldlabels.reporter = PC_AdverseEvent__c.PC_Reporter__c.getDescribe().getLabel();
            fieldlabels.pt = PC_AdverseEvent__c.PC_Event_PT__c.getDescribe().getLabel();
            fieldlabels.llt = PC_AdverseEvent__c.PC_Event_LLT__c.getDescribe().getLabel();
            fieldlabels.products = System.Label.PC_AE_Suspect_Products;
            fieldlabels.version = PC_AdverseEvent__c.PC_VersionNumber__c.getDescribe().getLabel();
            fieldlabels.submissionStatus = PC_AdverseEvent__c.PC_SubmissionStatus__c.getDescribe().getLabel();
            fieldlabels.eventType = PC_AdverseEvent__c.PC_EventType__c.getDescribe().getLabel();
        }catch (Exception ex){
            PC_Utility.logAndThrowException(ex);
        }

        return fieldlabels;
    }
    public class FieldLabels{
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String reporter { get; set; }
        @AuraEnabled public String pt { get; set; }
        @AuraEnabled public String llt { get; set; }
        @AuraEnabled public String products { get; set; }
        @AuraEnabled public String version { get; set; }
        @AuraEnabled public String submissionStatus { get; set; }
        @AuraEnabled public String eventType { get; set; }


        public FieldLabels() {
        }
    }

    public class ListWrapper{
        @AuraEnabled public String aeId { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String reporter { get; set; }
        @AuraEnabled public String pt { get; set; }
        @AuraEnabled public String llt { get; set; }
        @AuraEnabled public String adverseEventCaption{ get; set; }
        @AuraEnabled public Integer versionNumber { get; set; }
        @AuraEnabled public String parentAdverseEventId{ get; set; }
        @AuraEnabled public String submissionStatus{ get; set; }
        @AuraEnabled public String eventType{ get; set; }
        @AuraEnabled public String submissionStatusDefaultVal{ get; set; }
        @AuraEnabled public List<PC_Suspect_Prescription__c> prodList { get; set; }

        public ListWrapper(PC_AdverseEvent__c ae, List<PC_Suspect_Prescription__c> relSuspectProducts) {
            aeId = ae.Id;
            name = ae.Name;
            Decimal versionVal;
            parentAdverseEventId = ae.PC_ParentAdverseEvent__c;
            submissionStatus = ae.PC_SubmissionStatus__c;
            eventType = ae.PC_EventType__c;
            if(ae.PC_VersionNumber__c == Null){
                ae.PC_VersionNumber__c =1;
            }
            versionNumber =Integer.valueOf(ae.PC_VersionNumber__c);

            if (submissionStatus == PC_Constants.PC_AE_SUBMISSION_STATUS) {
                versionVal = (ae.PC_VersionNumber__c != 1 ? ++ae.PC_VersionNumber__c : 2);
                adverseEventCaption = String.format(System.Label.PC_AE_CreateVersion,new String[]{String.valueOf(versionVal)}) ;
                submissionStatusDefaultVal = PC_Constants.EMPTY_STRING;
            }
            else{
                versionVal = (ae.PC_VersionNumber__c != 1 ? ae.PC_VersionNumber__c : 1);
                adverseEventCaption =  String.format(System.Label.PC_AE_EditVersion, new String[]{String.valueOf(versionVal)} );
                submissionStatusDefaultVal = submissionStatus;
            }
            if(ae.PC_Reporter_First_Name__c != null){
                reporter = ae.PC_Reporter_First_Name__c;
            }
            if(ae.PC_Reporter_Last_Name__c != null){
                reporter = reporter+' '+ ae.PC_Reporter_Last_Name__c;
            }
            pt = ae.PC_Event_PT_Code__c;
            llt = ae.PC_Event_LLT_Code__c;
            prodList = relSuspectProducts;
        }

        public ListWrapper() {}
    }
    @AuraEnabled
    public static String getAEDownloadPDFPageName(){
        String vfPageName=PC_Constants.EMPTY_STRING;
        try{
            vfPageName=PC_SYSTEM.getPatientConnectSetting(PC_Constants.PC_AE_VF_PAGE_NAME,PC_Constants.PC_AE_DEFAULT_VF_PAGE_NAME);
        }catch (Exception ex){
            PC_Utility.logAndThrowException(ex);
        }
        return vfPageName;
    }

    /********************************************************************************
   Method Name          : getAdverseEventConfigData
   Description          : fetch action component attributes for Adverse Event PDF functionality
   Input Params         : Id
   Return Type          : AdverseEventConfig
   *********************************************************************************/
    public static AdverseEventConfig getAdverseEventConfigData(Id adverseEventId){

        AdverseEventConfig adverseEventConfig=new AdverseEventConfig();
        string caseRecordTypeName = '';
        try{
            /*
            * FLS Check for PC_AdverseEvent__c
            */
            List<String> aeFields = new List<String>{PC_Constants.getQualifiedAPIName('PC_Care_Program__c')};
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_AdverseEvent__c'), PC_Database.Operation.Reading, aeFields);

            /*
            * FLS Check for Case
            */
            List<String> caseFields = new List<String>{PC_Constants.getQualifiedAPIName('PC_Engagement_Program__c')};
            PC_Database.assertAccess(PC_Constants.PC_CASE, PC_Database.Operation.Reading, caseFields);

            /*
            * FLS Check for PC_Engagement_Program__c
            */
            List<String> engagementProgFields = new List<String>{PC_Constants.getQualifiedAPIName('PC_Program_Code__c')};
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Engagement_Program__c'), PC_Database.Operation.Reading, engagementProgFields);

            PC_AdverseEvent__c adverseEventRecord = [SELECT Id, PC_Care_Program__c from PC_AdverseEvent__c WHERE Id = :adverseEventId LIMIT 1];
            Case programCase = [SELECT Id, PC_Engagement_Program__c, RecordTypeId FROM Case WHERE Id = :adverseEventRecord.PC_Care_Program__c LIMIT 1];
            PC_Engagement_Program__c engagementProgramRecord = [SELECT Id,PC_Program_Code__c FROM PC_Engagement_Program__c WHERE Id = :programCase.PC_Engagement_Program__c LIMIT 1];
            caseRecordTypeName = PC_SYSTEM.recordTypeDeveloperNameById('Case',programCase.RecordTypeId);
            List<PC_Action_Center_Setting__mdt> actionCenterMetadataRecordList = [
                    SELECT Id,PC_Action_Component_Attributes__c, PC_Other_Case_Record_Type__c, PC_Case_Record_Type__c
                    FROM PC_Action_Center_Setting__mdt
                    WHERE
                            PC_Engagement_Program_Code__c = :engagementProgramRecord.PC_Program_Code__c AND PC_Active__c = :PC_Constants.TRUE_BOOLEAN
            ];

            for (PC_Action_Center_Setting__mdt actionCenterRec : actionCenterMetadataRecordList) {
                if (!String.isBlank(actionCenterRec.PC_Action_Component_Attributes__c) &&
                        actionCenterRec.PC_Action_Component_Attributes__c.contains(PC_Constants.PC_AE_MENU_COMPONENT_ATTR)) {

                    if ((actionCenterRec.PC_Case_Record_Type__c == PC_Constants.CASE_OTHER_RECORD_TYPE && actionCenterRec.PC_Other_Case_Record_Type__c.equals(caseRecordTypeName) ||
                            (actionCenterRec.PC_Case_Record_Type__c .equals(caseRecordTypeName)))) {

                        Map<String, Object> mapOfActionComponentAttributes = (Map<String, Object>) JSON.deserializeUntyped(actionCenterRec.PC_Action_Component_Attributes__c);

                        if (mapOfActionComponentAttributes != null && !mapOfActionComponentAttributes.isEmpty()) {

                            Map<String, Object> actionComponentAttrMap = (Map<String, Object>) mapOfActionComponentAttributes.get(PC_Constants.PC_AE_MENU_COMPONENT_ATTR);
                            if (actionComponentAttrMap != null && !actionComponentAttrMap.isEmpty()) {
                                adverseEventConfig.hideAdditionalInfoSection = (Boolean) actionComponentAttrMap.get(PC_Constants.PC_AE_HIDE_ADDITIONAL_INFO_TAB);
                                adverseEventConfig.fieldsetName = (String) actionComponentAttrMap.get(PC_Constants.PC_AE_ADDITIONAL_INFO_TAB_FS);
                                Boolean usePrescription = (Boolean) actionComponentAttrMap.get(PC_Constants.PC_AE_USE_PRESCRIPTION);
                                if(usePrescription != null){
                                    adverseEventConfig.usePrescription = usePrescription;
                                }else{
                                    adverseEventConfig.usePrescription = PC_Constants.TRUE_BOOLEAN;
                                }
                            }
                        }
                    }
                }
            }
        }
        catch(Exception e){
            PC_Utility.createExceptionLog(e);
        }

        return adverseEventConfig;
    }

    /********************************************************************************
   Class Name           : AdverseEventConfig
   Description          : holds Adverse Event Configuration data
   *********************************************************************************/
    public class AdverseEventConfig{
        public Boolean hideAdditionalInfoSection{get;set;}
        public String fieldsetName{get;set;}
        public Boolean usePrescription{get;set;}

        AdverseEventConfig(){
            hideAdditionalInfoSection=false;
            fieldsetName=PC_Constants.EMPTY_STRING;
            usePrescription=PC_Constants.TRUE_BOOLEAN;
        }
    }

}