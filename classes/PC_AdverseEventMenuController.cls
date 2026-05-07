/*********************************************************************************
Class Name      :   PC_AdverseEventMenuController
Description        : Controller for PC_AdverseEventMenu Component
Created By        : Haritha Reddy
Created Date     : 16-11-2018
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------
Haritha Reddy          16 Nov 2018              Initial Version
Vijay Kashikar         02 Jul 2019              [PC-5013] Bug Fix1 : Field level error thrown wasn't available on the front end.
                                                Bug Fix2: AE was getting created even though its associated product insertion failed.
Shishir Bansal         25 Sep 2019              [PC-4628] Track revisions on Adverse Event
Shishir Bansal        4-Oct-2019                PC-5553 Capturing Type on Adverse Event record
Kanteti Kishore       4-Nov-2019                PC-5679 Updated createAdverseEvent Method to return adverse event details for toast message.
Shishir Bansal        18 Nov 2019               [PC-5734] Added a null check if fieldset doesn't have fields
Shishir Bansal        06-Dec-2019               [PC-5792] Avoid hardcoding of string variable
Haritha Reddy         10-Dec-19                 [PC-5791] Added error handling for getFieldLabels method
Haritha Reddy         21-Jan-2021              [PC-7102] Added FLS Check
Vijay Kashikar        21-Jan-21                 [PC-7102] Added sharing clause
*********************************************************************************/


public with sharing class   PC_AdverseEventMenuController
{
    static String hideAdditionalInfoTab;
    static String additionalInfoTabFieldSet;

    public inherited sharing class InitData {

        /**
        * Property to hold different types of report Source
        */
        @AuraEnabled public List<ListWrapper> type;
        /**
        * Property to hold default/selected type value
        */
        @AuraEnabled public string typeSelectedVal;
        /**
       * Property to hold  field Labels
       */
        @AuraEnabled public FieldLabels fieldLabels ;

        public InitData() {
            type= new List<ListWrapper>();
            typeSelectedVal =PC_Constants.EMPTY_STRING;
            fieldLabels = new FieldLabels();
        }
    }

    public inherited sharing class ListWrapper {
        @AuraEnabled public String label {get; set;}
        @AuraEnabled public String value {get; set;}
        @AuraEnabled public Boolean selected {get; set;}

        ListWrapper(String label , String value, boolean selected){
            this.label =label;
            this.value =value;
            this.selected = selected;
        }
    }

    public inherited sharing class FieldLabels{
        @AuraEnabled public String type { get; set; }
        public FieldLabels() {
        }
    }


    /*********************************************************
  Method Name          : getData
  Description          : fetch Adverse Event Records related to the Program Case
  Input Params         :
  Return Type          : InitData Wrapper
  *********************************************************************************/
    @AuraEnabled
    public static InitData getData(Id aeId){

        try {

            InitData initData = new InitData();

            initData.fieldLabels = getFieldLabels();
            initData.typeSelectedVal =getUserInputTypeValue(aeID);
            initData.type =getType(initData.typeSelectedVal );
            return initData;
        }catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
    return null;
    }


    /*********************************************************
    Method Name          : getUserInputTypeValue
    Description          : fetching user input picklist value of PC_EventType__c
    Input Params         : adverse event id
    Return Type          : String
    *********************************************************************************/

    public static String getUserInputTypeValue(Id aeId){
        String defaultVal = PC_Constants.EMPTY_STRING;
        List<PC_AdverseEvent__c> aeRecord = new List<PC_AdverseEvent__c>();
        if(String.isNotBlank(String.valueOf(aeId))) {

            List<String> aeFields = new List<String>();
            aeFields.add(PC_Constants.getQualifiedAPIName('PC_EventType__c'));
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_AdverseEvent__c'),  PC_Database.Operation.Reading, aeFields);

            aeRecord = [Select PC_EventType__c From PC_AdverseEvent__c where Id = :aeId];
            if (String.isNotBlank(aeRecord[0].PC_EventType__c)) {
                defaultVal = aeRecord[0].PC_EventType__c;
            }
        }
        else{
            Schema.DescribeFieldResult F = PC_AdverseEvent__c.PC_EventType__c.getDescribe();
            List <Schema.PicklistEntry> pickVals = F.getPicklistValues();
            for (Schema.PicklistEntry pv : pickVals) {
                if (pv.isDefaultValue() && pv.isActive()) {
                    defaultVal = pv.value;
                }
            }
        }
        return defaultVal;
    }
    /*********************************************************
   Method Name          : getType
   Description          : fetching picklist values of PC_EventType__c
   Input Params         : null
   Return Type          : List<ListWrapper>
   *********************************************************************************/
    public static List<ListWrapper> getType(String defaultVal){
        List<ListWrapper> fieldValueWrapperList = new List<ListWrapper>();
        Schema.DescribeFieldResult F = PC_AdverseEvent__c.PC_EventType__c.getDescribe();
        List <Schema.PicklistEntry> pickVals = F.getPicklistValues();
        if(defaultVal == PC_Constants.EMPTY_STRING){
            fieldValueWrapperList.add(new ListWrapper(PC_Constants.PICKLIST_NONE_VAL, PC_Constants.EMPTY_STRING, true));
        }
        else{
            fieldValueWrapperList.add(new ListWrapper(PC_Constants.PICKLIST_NONE_VAL, PC_Constants.EMPTY_STRING, false));
        }

        for (Schema.PicklistEntry pv : pickVals) {
            if(pv.isActive()){
                if (defaultVal == pv.value) {
                    fieldValueWrapperList.add(new ListWrapper(pv.label, pv.value, true));
                } else {
                    fieldValueWrapperList.add(new ListWrapper(pv.label, pv.value, false));
                }
            }
        }
     return fieldValueWrapperList;
    }

    /*********************************************************
   Method Name          : getFieldLabels
   Description               : fetch Field Labels from Database
   Input Params            : NA
   Return Type             : FieldLabels Wrapper
   *********************************************************************************/
    @AuraEnabled
    public static FieldLabels getFieldLabels(){
        FieldLabels fieldlabels = new FieldLabels();
        try {
            fieldlabels.type = PC_AdverseEvent2__c.PC_EventType__c.getDescribe().getLabel();
        }catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return fieldlabels;
    }




/*********************************************************
Method Name          : createAdverseEvent
Description               : creates new Adverse Event with data provided
Input Params            : List<Id> CaseId, Map<String, Map<Object,Object>> aeWrapper
Return Type             : List<String>
*********************************************************************************/
    @AuraEnabled
    public static List<String> createAdverseEvent(String aeId , String caseId , Map<String, Map<Object,Object>> aeWrapper, Map<String, Boolean> visitedTab,
         Map<String,String> adverseEventMenuCmpAttributes  ) {
        Savepoint sp = Database.setSavepoint();
        List<String> aeDetails = new List<String>();

        try {


            System.debug('adverseEventMenuCmpAttributes@@'+adverseEventMenuCmpAttributes);

            Map<Object,Object> patInfo = aeWrapper.get('patInfo');
            Map<Object,Object> manufacturerInfo = aeWrapper.get('manufacturerInfo');
            Map<Object,Object> adverseEventInfo = aeWrapper.get('adverseEventInfo');
            Map<Object,Object> initialReporterInfo = aeWrapper.get('initialReporterInfo');
            Map<Object,Object> suspectProductInfo = aeWrapper.get('suspectProductInfo');
            Map<Object,Object> additionalInfo = aeWrapper.get('fsFields');

            Boolean isPatientInfoVisited = visitedTab.get('patientInfo');
            Boolean isAdverseEventVisited = visitedTab.get('adverseEvent');
            Boolean isSuspectProductsVisited = visitedTab.get('suspectProducts');
            Boolean isInitialReporterVisited = visitedTab.get('initialReporter');
            Boolean isManufacturerVisited = visitedTab.get('manufacturer');
            Boolean isAdditionalInfoVisited = visitedTab.get('additionalInfo');

            system.debug('isAdditionalInfoVisited**'+isAdditionalInfoVisited);
            system.debug('before value');
            //system.debug('adverseEventMenuCmpAttributes-->'+adverseEventMenuCmpAttributes);
            hideAdditionalInfoTab = adverseEventMenuCmpAttributes.get('hideAdditionalInfoTab');
            additionalInfoTabFieldSet = adverseEventMenuCmpAttributes.get('additionalInfoTabFieldSet');



            Object patientInfoController = PC_AE_PatientInfoRendererController.Class.newInstance();
            Object manufacturerInfoController = PC_AE_ManufacturerRendererController.Class.newInstance();
            Object adverseEventInfoController = PC_AE_AdverseEventRendererController.Class.newInstance();
            Object initialReporterController = PC_AE_InitialReporterRendererController.Class.newInstance();
            Object suspectProductController = PC_AE_SuspectProductsRendererController.Class.newInstance();
            Object additionalinfoController = PC_AE_AdditionalInfoRendererController.Class.newInstance();

            List<PC_Suspect_Prescription__c> suspectProductNewVersionList = new List<PC_Suspect_Prescription__c>();
            PC_AdverseEvent__c aeRec;

            Map<Object,Object> aeInfoMap = new Map<Object,Object>();
            aeInfoMap =  (Map<Object,Object>)aeWrapper.get('aeInfo');
            String typeValue = String.valueOf(aeInfoMap.get('type'));

            Boolean updateParentAERecordCheck=false;
            if(aeId == null || aeId ==PC_Constants.UNDEFINED_STRING){
                aeRec = new PC_AdverseEvent__c();

                aeRec.PC_EventType__c = typeValue;

                List<String> caseFields = new List<String>();
                caseFields.add('AccountId');
                PC_Database.assertAccess(PC_Constants.PC_CASE, PC_Database.Operation.Reading, caseFields);

                Case currentCase = [Select AccountId from Case where id=:caseId];
                aeRec.PC_Patient__c = currentCase.AccountId;
                aeRec.PC_Care_Program__c = caseId;

                if(patientInfoController instanceof AdverseEventProcessor) {
                    ((AdverseEventProcessor) patientInfoController).updateAdverseEvent(aeRec, patInfo);
                }
                if(manufacturerInfoController instanceof AdverseEventProcessor) {
                    ((AdverseEventProcessor) manufacturerInfoController).updateAdverseEvent(aeRec, manufacturerInfo);
                }
                if(initialReporterController instanceof AdverseEventProcessor) {
                    ((AdverseEventProcessor) initialReporterController).updateAdverseEvent(aeRec, initialReporterInfo);
                }
                if(adverseEventInfoController instanceof AdverseEventProcessor) {
                    ((AdverseEventProcessor) adverseEventInfoController).updateAdverseEvent(aeRec, adverseEventInfo);
                }
                if(additionalinfoController instanceof AdverseEventProcessor) {
                    ((AdverseEventProcessor) additionalinfoController).updateAdverseEvent(aeRec, additionalInfo);
                }

                PC_Database.ins(aeRec, true);
                if(suspectProductController instanceof AdverseEventProcessor && isSuspectProductsVisited) {
                    ((AdverseEventProcessor) suspectProductController).updateAdverseEvent(aeRec, suspectProductInfo);
                }
            }else{
                aeRec = new PC_AdverseEvent__c();

                List<String> fields = new List<String>();
                fields.add(PC_Constants.getQualifiedAPIName('PC_Patient__c'));
                fields.add(PC_Constants.getQualifiedAPIName('PC_EventType__c'));
                fields.add(PC_Constants.getQualifiedAPIName('PC_LatestAdverseEvent__c'));
                fields.add(PC_Constants.getQualifiedAPIName('PC_Care_Program__c'));
                fields.add(PC_Constants.getQualifiedAPIName('PC_SubmissionStatus__c'));
                fields.add(PC_Constants.getQualifiedAPIName('PC_ParentAdverseEvent__c'));
                fields.add(PC_Constants.getQualifiedAPIName('PC_VersionNumber__c'));
                fields.add(PC_Constants.getQualifiedAPIName('Name'));
                PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_AdverseEvent__c'), PC_Database.Operation.Reading, fields);

                aeRec = [Select Id,PC_Patient__c,PC_EventType__c, PC_LatestAdverseEvent__c , PC_Care_Program__c, PC_SubmissionStatus__c, PC_ParentAdverseEvent__c, PC_VersionNumber__c from PC_AdverseEvent__c where id = :aeId];

                /*Fetching Adverse Event type and Submission Status. Based on that value of
                Submission Status (if Submitted- create a new version , else edit the current version)
                */
                aeRec.PC_EventType__c = typeValue;
                String submissionVal = aeRec.PC_SubmissionStatus__c;
                Id parentAdverseEventId = aeRec.PC_ParentAdverseEvent__c;
                if(submissionVal ==PC_Constants.PC_AE_SUBMISSION_STATUS) {

                    /*This piece of code will be execured to create a new version of the adverse Event.
                    If the user has not visited any of the tabs , than respective aeWrappers are populated and all the
                    tabs(patient , adverseEvent , suspectProduct, initial Reporter, additionalInf)o are visited
                    */

                    if(isPatientInfoVisited != true){

                        patInfo = getAdverseEventWrapper(aeRec, PC_Constants.PC_AE_PATIENT_TAB);
                        isPatientInfoVisited = true;
                    }
                    if(isAdverseEventVisited != true){

                        adverseEventInfo = getAdverseEventWrapper(aeRec, PC_Constants.PC_AE_ADVERSE_EVENT_TAB);
                        isAdverseEventVisited = true;
                    }
                    if(isSuspectProductsVisited != true){
                        suspectProductNewVersionList = getRelatedSuspectProducts(aeRec, PC_Constants.PC_AE_SUSPECT_PRODUCT_TAB);
                    }
                    if(isSuspectProductsVisited == true){

                        String updSPJSONString = JSON.serialize(suspectProductInfo.get('updatedSuspectPrescriptionList'));
                        if(String.isNotBlank(updSPJSONString)) {
                            List<PC_AE_SuspectProductsRendererController.SuspectPrescriptionWrapper> updatedSPWrapperList = (List<PC_AE_SuspectProductsRendererController.SuspectPrescriptionWrapper>) JSON.deserialize(updSPJSONString, List<PC_AE_SuspectProductsRendererController.SuspectPrescriptionWrapper>.class);

                            if(updatedSPWrapperList !=null) {
                                suspectProductNewVersionList.addAll( convertSuspectPrescription(updatedSPWrapperList));
                            }
                        }
                        String JSONString = JSON.serialize(suspectProductInfo.get('newSuspectPrescriptionList'));
                        if(String.isNotBlank(JSONString)) {
                            List<PC_AE_SuspectProductsRendererController.SuspectPrescriptionWrapper> newSPWrapperList = (List<PC_AE_SuspectProductsRendererController.SuspectPrescriptionWrapper>) JSON.deserialize(JSONString, List<PC_AE_SuspectProductsRendererController.SuspectPrescriptionWrapper>.class);

                            if(newSPWrapperList != null){
                                suspectProductNewVersionList.addAll( convertSuspectPrescription(newSPWrapperList));
                            }
                        }
                        isSuspectProductsVisited = false;
                    }
                    if(isInitialReporterVisited != true){

                        initialReporterInfo = getAdverseEventWrapper(aeRec, PC_Constants.PC_AE_INITIAL_REPORTER_TAB);
                        isInitialReporterVisited = true;
                    }
                    if(isManufacturerVisited != true){

                        manufacturerInfo = getAdverseEventWrapper(aeRec, PC_Constants.PC_AE_MANUFACTURER_TAB);
                        isManufacturerVisited =true;
                    }
                    if(isAdditionalInfoVisited != true){


                        additionalInfo = getAdverseEventWrapper(aeRec, PC_Constants.PC_AE_ADDITIONAL_INFO_TAB);
                        isAdditionalInfoVisited= true;
                    }
                }

                if(isPatientInfoVisited == true && patientInfoController instanceof AdverseEventProcessor) {
                    ((AdverseEventProcessor) patientInfoController).updateAdverseEvent(aeRec, patInfo);
                }
                if(isManufacturerVisited == true && manufacturerInfoController instanceof AdverseEventProcessor) {
                    ((AdverseEventProcessor) manufacturerInfoController).updateAdverseEvent(aeRec, manufacturerInfo);
                }
                if(isInitialReporterVisited == true && initialReporterController instanceof AdverseEventProcessor) {
                    ((AdverseEventProcessor) initialReporterController).updateAdverseEvent(aeRec, initialReporterInfo);
                }
                if(isAdverseEventVisited == true && adverseEventInfoController instanceof AdverseEventProcessor) {
                    ((AdverseEventProcessor) adverseEventInfoController).updateAdverseEvent(aeRec, adverseEventInfo);
                }
                if(isSuspectProductsVisited == true && suspectProductController instanceof AdverseEventProcessor && submissionVal != PC_Constants.PC_AE_SUBMISSION_STATUS ) {
                    ((AdverseEventProcessor) suspectProductController).updateAdverseEvent(aeRec, suspectProductInfo);
                }
                if(isAdditionalInfoVisited == true && additionalinfoController instanceof AdverseEventProcessor) {
                    ((AdverseEventProcessor) additionalinfoController).updateAdverseEvent(aeRec, additionalInfo);
                }
                if(submissionVal == PC_Constants.PC_AE_SUBMISSION_STATUS) {

                    if (aeRec.PC_ParentAdverseEvent__c == null){
                        aeRec.PC_ParentAdverseEvent__c = aeRec.Id;
                        parentAdverseEventId=  aeRec.Id;
                    }
                    aeRec.PC_VersionNumber__c +=1;
                    aeRec.Id = null;

                    PC_Database.ins(aeRec);
                    updateParentAERecordCheck = true;
                    Id  newAEId = aeRec.Id;
                    if(suspectProductNewVersionList.size()>0){
                        for(PC_Suspect_Prescription__c  suspectPrescription:suspectProductNewVersionList ){
                            suspectPrescription.PC_Adverse_Event__c = newAEId;
                            suspectPrescription.Id = null;
                        }
                        PC_Database.ins(suspectProductNewVersionList);
                    }

                    if(aeRec.PC_SubmissionStatus__c !=PC_Constants.PC_AE_SUBMISSION_STATUS && String.isNotBlank(String.valueOf(parentAdverseEventId))) {
                        PC_AdverseEvent__c updateParentAEREcord = new PC_AdverseEvent__c();

                        List<String> aeFields = new List<String>();
                        aeFields.add(PC_Constants.getQualifiedAPIName('PC_LatestAdverseEvent__c'));
                        PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_AdverseEvent__c'), PC_Database.Operation.Reading, aeFields);

                        updateParentAEREcord = [Select Id,PC_LatestAdverseEvent__c from PC_AdverseEvent__c where id = :parentAdverseEventId];
                        updateParentAEREcord.PC_LatestAdverseEvent__c = newAEId;
                        PC_Trigger_SetAdverseEventVersion.isExecuting = true;
                        PC_Database.upd(updateParentAEREcord);
                    }
                }

                if(!updateParentAERecordCheck) {
                    PC_Trigger_SetAdverseEventVersion.isExecuting = true;
                    PC_Database.upd(aeRec);
                }

            }
            if(aeRec.Id != null) {

                List<String> aeFields = new List<String>();
                aeFields.add('Name');
                PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_AdverseEvent__c'), PC_Database.Operation.Reading, aeFields);

                PC_AdverseEvent__c advEvt = [SELECT Id,Name from PC_AdverseEvent__c where Id = :aeRec.Id];
                aeDetails.add(advEvt.Name);
                aeDetails.add(advEvt.Id);
                aeDetails.add(PC_Constants.getQualifiedAPIName('PC_AdverseEvent'));
            }
        }
        catch(Exception ex) {
            Database.rollback(sp);
            PC_Utility.publishErrorLog(ex, ex.getMessage());
            PC_Utility.throwAuraHandledException(ex.getMessage());
        }
        return aeDetails;
    }

    public interface AdverseEventProcessor {
        /**
         * Update the AdverseEvent on the response returned from the service.
         * @param adverseEvent Adverse Event object that is to be saved.
         * @param infoObjects Holds values received for creating/updating the adverse event.
         */
        void updateAdverseEvent(PC_AdverseEvent__c aeRec, Map<Object,Object> infoObjects);

    }




    /*********************************************************
    Method Name          : getAdverseEvent
    Description          : fetching Adverse Event wrapper related to the tabString passed
    Input Params         : PC_AdverseEvent__c aeRec,String tabString
    Return Type          : Map<Object,Object>
    *********************************************************************************/
    public static Map<Object,Object> getAdverseEventWrapper( PC_AdverseEvent__c aeRec, String tabString ){
        try {

            if(String.isNotBlank(tabString) && (aeRec != null) &&  tabString == PC_Constants.PC_AE_PATIENT_TAB){

                Map<Object, Object> adverseEventPatInfoMap=new Map<Object, Object>();
                adverseEventPatInfoMap=PC_AE_PatientInfoRendererController.fetchDataFromAE(aeRec.Id,adverseEventPatInfoMap);

                return adverseEventPatInfoMap;

            }

            if(String.isNotBlank(tabString) && (aeRec != null) &&  tabString == PC_Constants.PC_AE_ADVERSE_EVENT_TAB){

                Map<Object, Object> adverseEventInfo=new Map<Object, Object>();
                adverseEventInfo=PC_AE_AdverseEventRendererController.loadDataFromAE(aeRec.Id,adverseEventInfo);

                return adverseEventInfo;

            }

            if(String.isNotBlank(tabString) && (aeRec != null) &&  tabString == PC_Constants.PC_AE_INITIAL_REPORTER_TAB){


                Map<Object, Object> aeInitialReportInfo=new Map<Object, Object>();
                aeInitialReportInfo=PC_AE_InitialReporterRendererController.getDataFromAE(aeRec.Id,aeInitialReportInfo);
                return aeInitialReportInfo;

            }


            if(String.isNotBlank(tabString) && (aeRec != null) &&  tabString == PC_Constants.PC_AE_MANUFACTURER_TAB){

                Map<Object, Object> aeManuInfo=new Map<Object, Object>();
                aeManuInfo=PC_AE_ManufacturerRendererController.loadDataFromAE(aeRec.Id,aeManuInfo);
                return aeManuInfo;
            }


            if(String.isNotBlank(tabString) && (aeRec != null) &&  tabString == PC_Constants.PC_AE_ADDITIONAL_INFO_TAB) {

                //PC_AdverseEventsController.AdverseEventConfig adverseEventConfig = PC_AdverseEventsController.getAdverseEventConfigData(aeRec.Id);
                // Boolean hideAdditionalInfoTab=adverseEventConfig.hideAdditionalInfoSection;
                //String fieldsetName=adverseEventConfig.fieldsetName;
                if (String.isNotBlank(hideAdditionalInfoTab) && String.isNotBlank(additionalInfoTabFieldSet)) {
                  //  if (! hideAdditionalInfoTab) {
                    String fieldsetName = additionalInfoTabFieldSet;
                    if (! Boolean.valueOf(hideAdditionalInfoTab)) {
                        if (!String.isBlank(fieldsetName) && fieldsetName != PC_Constants.UNDEFINED_STRING) {
                            Map<Object, Object> additionalInfoObj = new Map<Object, Object>();
                            PC_AE_AdditionalInfoRendererController.FieldPathAndValue fieldPathAndValue = PC_AE_AdditionalInfoRendererController.getPopulatedFieldSet(aeRec.Id, additionalInfoObj, PC_Constants.getQualifiedAPIName('PC_AdverseEvent__c'), fieldsetName);
                            if (fieldPathAndValue != null) {
                                return fieldPathAndValue.fieldValue;
                            }
                        }
                    }
                }
            }
        }catch(Exception ex) {
            ex.setMessage(System.Label.PC_Fieldset_Error);
            PC_Utility.logAndThrowException(ex);
        }
        return null;
    }


    /*********************************************************
    Method Name          : getRelatedSuspectProducts
    Description          : fetching suspect products related to adverse event
    Input Params         : PC_AdverseEvent__c aeRec,String tabString
    Return Type          : List<PC_Suspect_Prescription__c>
    *********************************************************************************/

    static List<PC_Suspect_Prescription__c> getRelatedSuspectProducts(PC_AdverseEvent__c aeRec, String tabString){
        if(String.isNotBlank(tabString) && (aeRec != null) &&  tabString == PC_Constants.PC_AE_SUSPECT_PRODUCT_TAB){

            List<String> spFields = new List<String>();
            spFields.add(PC_Constants.getQualifiedAPIName('PC_Prescription__c'));
            spFields.add(PC_Constants.getQualifiedAPIName('PC_Product_Name__c'));
            spFields.add(PC_Constants.getQualifiedAPIName('PC_Product_Manufacturer__c'));
            spFields.add(PC_Constants.getQualifiedAPIName('PC_Drug_NDC__c'));
            spFields.add(PC_Constants.getQualifiedAPIName('PC_Product_Lot__c'));
            spFields.add(PC_Constants.getQualifiedAPIName('PC_Dose__c'));
            spFields.add(PC_Constants.getQualifiedAPIName('PC_Frequency__c'));
            spFields.add(PC_Constants.getQualifiedAPIName('PC_Route_of_Administration__c'));
            spFields.add(PC_Constants.getQualifiedAPIName('PC_Therapy_Start_Date__c'));
            spFields.add(PC_Constants.getQualifiedAPIName('PC_Product_Strength__c'));
            spFields.add(PC_Constants.getQualifiedAPIName('PC_Indication_for_Product_Use__c'));
            spFields.add(PC_Constants.getQualifiedAPIName('PC_Product_Compounded__c'));
            spFields.add(PC_Constants.getQualifiedAPIName('PC_Product_OTC__c'));
            spFields.add(PC_Constants.getQualifiedAPIName('PC_Expiration_Date__c'));
            spFields.add(PC_Constants.getQualifiedAPIName('PC_Concomitant_Medical_Products__c'));
            spFields.add(PC_Constants.getQualifiedAPIName('PC_Abated_After_Use_Stopped_or_Reduced__c'));
            spFields.add(PC_Constants.getQualifiedAPIName('PC_Event_Reappeared_After_Reintroduction__c'));
            spFields.add(PC_Constants.getQualifiedAPIName('PC_Therapy_End_Date__c'));
            spFields.add(PC_Constants.getQualifiedAPIName('PC_Adverse_Event__c'));

            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Suspect_Prescription__c'), PC_Database.Operation.Reading, spFields);
            List<PC_Suspect_Prescription__c> suspectPrescriptionList = [
                    Select Id, Name,PC_Prescription__c,PC_Product_Name__c, PC_Product_Manufacturer__c,PC_Drug_NDC__c,
                            PC_Product_Lot__c,PC_Dose__c,PC_Frequency__c,PC_Route_of_Administration__c,PC_Therapy_Start_Date__c,PC_Product_Strength__c,
                            PC_Indication_for_Product_Use__c,PC_Product_Compounded__c,PC_Product_OTC__c,PC_Expiration_Date__c,PC_Concomitant_Medical_Products__c,
                            PC_Abated_After_Use_Stopped_or_Reduced__c,PC_Event_Reappeared_After_Reintroduction__c,PC_Therapy_End_Date__c,PC_Adverse_Event__c
                    FROM PC_Suspect_Prescription__c
                    WHERE PC_Adverse_Event__c = :aeRec.Id
            ];
            return suspectPrescriptionList;
        }
        return null;
    }


    static List<PC_Suspect_Prescription__c> convertSuspectPrescription (List<PC_AE_SuspectProductsRendererController.SuspectPrescriptionWrapper> spWrapper){


        if(spWrapper != null){
            List<PC_Suspect_Prescription__c> spList = new List<PC_Suspect_Prescription__c>();

            for(PC_AE_SuspectProductsRendererController.SuspectPrescriptionWrapper spNew:spWrapper ){
                PC_Suspect_Prescription__c spRec = new PC_Suspect_Prescription__c();
                spRec.PC_Prescription__c = spNew.prescription;
                spRec.PC_Product_Name__c = spNew.productName;
                spRec.PC_Drug_NDC__c = spNew.ndc;
                spRec.PC_Product_Lot__c = spNew.lot;
                spRec.PC_Product_Strength__c = spNew.productStrength;
                spRec.PC_Product_Manufacturer__c = spNew.manufacturer;
                spRec.PC_Concomitant_Medical_Products__c = spNew.concomitant;
                spRec.PC_Dose__c = spNew.dose;
                spRec.PC_Frequency__c = spNew.frequency;
                spRec.PC_Route_of_Administration__c = spNew.route;
                spRec.PC_Indication_for_Product_Use__c = spNew.diagnosis;
                spRec.PC_Product_Compounded__c = spNew.prodCompounded;
                spRec.PC_Abated_After_Use_Stopped_or_Reduced__c = spNew.eventAbated;
                spRec.PC_Product_OTC__c = spNew.prodOTC;
                spRec.PC_Event_Reappeared_After_Reintroduction__c = spNew.eventReappeared;
                spRec.PC_Therapy_Start_Date__c = spNew.therapyStartDate;
                spRec.PC_Therapy_End_Date__c = spNew.therapyEndDate;
                spRec.PC_Expiration_Date__c = spNew.expirationDate;

                spList.add(spRec);
            }

            return spList;
        }
        return null;
    }
}