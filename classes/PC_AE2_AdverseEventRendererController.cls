/*********************************************************************************
Class Name      :   PC_AE_AdverseEventRendererController2
Description        : Controller for PC_AE_AdverseEventRenderer Component
Created By        : Shishir Bansal
Created Date     : 3-12-2018
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------
Shishir Bansal         3-12-2018            Initial Version
Shishir Bansal         26-Sep-2019          [PC-4628] Track revisions on Adverse Event
Shishir Bansal         10-11-2019           [PC-5606]Fixed the bad value of PC_Event_Outcome__c
Shishir Bansal        Dec-06-2019           [PC-5792] Avoid hardcoding of string variable
Kishore Kanteti        21-Dec-2020          [PC-7037] Removed Submission status saving
Vijay Kashikar         21-Jan-21            [PC-7102] Added sharing clause
*********************************************************************************/

public with sharing class PC_AE2_AdverseEventRendererController implements PC_AdverseEventMenu2Controller.AdverseEventProcessor {

    /*public PC_AE_AdverseEventRendererController(){

    }*/

    //public Map<Object,Object> adverseEventPDFInfo{get;set;}
    public Map<String,String> adverseEventPDFLabels{get;set;}

    /*public PC_AE_AdverseEventRendererController(ApexPages.StandardController stdController){
        getAdverseEventPDFInfo();
        getAdverseEventPDFLabels();
    }

    public void getAdverseEventPDFInfo(){
        Id adverseEventId='a011I00000LOYuLQAX';
        adverseEventPDFInfo=new Map<Object, Object>();
        adverseEventPDFInfo=loadDataFromAE(adverseEventId,adverseEventPDFInfo);
        for(Object key: adverseEventPDFInfo.keySet()){
            if(adverseEventPDFInfo.get(key)==null){
                adverseEventPDFInfo.put(key,PC_Constants.EMPTY_STRING);
            }
        }
    }*/

    public void getAdverseEventPDFLabels(){
        adverseEventPDFLabels=new Map<String, String>();
        adverseEventPDFLabels.put('dateOfTheReport',PC_AdverseEvent2__c.PC_Date_of_the_Report__c.getDescribe().getLabel());
        adverseEventPDFLabels.put('eventOnsetDate',PC_AdverseEvent2__c.PC_Event_Onset_Date__c.getDescribe().getLabel());
        adverseEventPDFLabels.put('endDate',String.valueOf(PC_AdverseEvent2__c.PC_Stop_Date__c.getDescribe().getLabel()));
        adverseEventPDFLabels.put('description',PC_AdverseEvent2__c.PC_Description__c.getDescribe().getLabel());
        adverseEventPDFLabels.put('laboratoryData',PC_AdverseEvent2__c.PC_Laboratory_Data__c.getDescribe().getLabel());
        adverseEventPDFLabels.put('otherReleventHistory',PC_AdverseEvent2__c.PC_Other_Relevent_History__c.getDescribe().getLabel());
        adverseEventPDFLabels.put('eventVerbatim',PC_AdverseEvent2__c.PC_Event_Verbatim__c.getDescribe().getLabel());
        adverseEventPDFLabels.put('outcome',PC_AdverseEvent2__c.PC_Event_Outcome__c.getDescribe().getLabel());
        adverseEventPDFLabels.put('dateofDeath',PC_AdverseEvent2__c.PC_Death_Date__c.getDescribe().getLabel());
        adverseEventPDFLabels.put('eventCoding_SOC',PC_AdverseEvent2__c.PC_Event_SOC_Code__c.getDescribe().getLabel());
        adverseEventPDFLabels.put('eventCoding_HLGT',PC_AdverseEvent2__c.PC_Event_HLGT_Code__c.getDescribe().getLabel());
        adverseEventPDFLabels.put('eventCoding_HLT',PC_AdverseEvent2__c.PC_Event_HLT_Code__c.getDescribe().getLabel());
        adverseEventPDFLabels.put('eventCoding_PT',PC_AdverseEvent2__c.PC_Event_PT_Code__c.getDescribe().getLabel());
        adverseEventPDFLabels.put('eventCoding_LLT',PC_AdverseEvent2__c.PC_Event_LLT_Code__c.getDescribe().getLabel());
        adverseEventPDFLabels.put('submissionStatus',PC_AdverseEvent2__c.PC_SubmissionStatus__c.getDescribe().getLabel());
    }

    /*********************************************************
    Method Name          : getAdverseEventData
    Description          : fetch Field Labels,Picklist Values of Adverse Event Fields on Adverse Event  Tab
    Input Params         : String adverse Event Id
    Return Type          : AdverseEventFormData Wrapper
    *********************************************************************************/
    @AuraEnabled
    public static AdverseEventFormData getAdverseEventData(String aeId, Map<Object,Object> adverseEventInfo ){
        AdverseEventFormData formData = new AdverseEventFormData();
        try {
            formData.adverseEventLabels = getAdverseEventLabels();
            formData.outcomeOptions = getOutcomePicklistValues();
            formData.submissionStatusOptions =getSubmissionStatusPicklistValues();
            formData.adverseEventInfo = loadDataFromAE(aeId, adverseEventInfo);
        }
        catch (exception ex){
            PC_Utility.logAndThrowException(ex);
        }
        return formData;
    }



    /*********************************************************
   Method Name          : updateAdverseEvent
   Description          : for  upserting the record on Adverse Event Object
   Input Params         : PC_AdverseEvent2__c object ,    Map<Object,Object>
   Return Type          : Void
   *********************************************************************************/


    public void updateAdverseEvent(PC_AdverseEvent2__c aeRec, Map<Object,Object> adverseEventInfo) {


        try {
            if ((adverseEventInfo.get('dateOfTheReport') != null) && adverseEventInfo.get('dateOfTheReport') != PC_Constants.EMPTY_STRING) {
                aeRec.PC_Date_of_the_Report__c = Date.valueOf((String)adverseEventInfo.get('dateOfTheReport'));
            }
            if(adverseEventInfo.get('outcome') != PC_Constants.EMPTY_STRING && adverseEventInfo.get('outcome') != null){
                String outcomeOptions = String.valueOf( adverseEventInfo.get('outcome'));
                if(String.isNotBlank(outcomeOptions)){
                    String outcomeRecordValues = PC_Constants.EMPTY_STRING;

                    if(outcomeOptions.startsWith('(') && outcomeOptions.endsWith(')') ) {
                        outcomeOptions = outcomeOptions.removeStart('(');
                        outcomeOptions = outcomeOptions.removeEnd(')');
                    }
                    List<String> outcomeOptionList = outcomeOptions.split(',');
                    if(outcomeOptionList !=null){
                        for(String picklistValue : outcomeOptionList){
                            if(outcomeRecordValues ==PC_Constants.EMPTY_STRING){
                                outcomeRecordValues = picklistValue;
                            }
                            else{
                                outcomeRecordValues = outcomeRecordValues +';'+ picklistValue;
                            }
                        }
                    }
                    if(outcomeRecordValues !=PC_Constants.EMPTY_STRING) {
                        aeRec.PC_Event_Outcome__c = outcomeRecordValues;
                    }
                }
            }

            /*String submissionStatusOptions = String.valueOf( adverseEventInfo.get('submissionStatus'));
            aeRec.PC_SubmissionStatus__c = submissionStatusOptions;*/
            if (((adverseEventInfo.get('eventOnsetDate')) != null) && (adverseEventInfo.get('eventOnsetDate') != PC_Constants.EMPTY_STRING)) {
                aeRec.PC_Event_Onset_Date__c = Date.valueOf( (String)adverseEventInfo.get('eventOnsetDate'));
            }
            if (((adverseEventInfo.get('endDate')) != null) && (adverseEventInfo.get('endDate') != PC_Constants.EMPTY_STRING)) {
                aeRec.PC_Stop_Date__c = Date.valueOf((String) adverseEventInfo.get('endDate'));
            }
            aeRec.PC_Description__c = (String) adverseEventInfo.get('description');
            aeRec.PC_Laboratory_Data__c = (String) adverseEventInfo.get('laboratoryData');
            aeRec.PC_Other_Relevent_History__c = (String) adverseEventInfo.get('otherReleventHistory');
            aeRec.PC_Event_Verbatim__c = (String) adverseEventInfo.get('eventVerbatim');
            aeRec.PC_Event_SOC_Code__c = (String) adverseEventInfo.get('eventCoding_SOC');
            aeRec.PC_Event_HLGT_Code__c = (String) adverseEventInfo.get('eventCoding_HLGT');
            aeRec.PC_Event_HLT_Code__c = (String) adverseEventInfo.get('eventCoding_HLT');
            aeRec.PC_Event_PT_Code__c = (String) adverseEventInfo.get('eventCoding_PT');
            aeRec.PC_Event_LLT_Code__c = (String) adverseEventInfo.get('eventCoding_LLT');
            //aeRec.PC_CauseOfDeath__c = (String) adverseEventInfo.get('causeOfDeath');
            if ((adverseEventInfo.get('dateofDeath') != null) && (adverseEventInfo.get('dateofDeath')!= PC_Constants.EMPTY_STRING)) {
                aeRec.PC_Death_Date__c = Date.valueOf((String) adverseEventInfo.get('dateofDeath'));
            }
        }
        catch (exception ex){
            system.debug('message '+ex.getMessage()+' line '+ex.getStackTraceString());
            PC_Utility.logAndThrowException(ex);
        }
    }


    /*********************************************************
  Method Name          : loadDataFromAE
  Description          : for  updating the ui part on adverse Events
  Input Params         : PC_AdverseEvent2__c  Id ,    Map<String, Map<Object,Object>>
  Return Type          :  Map<Object,Object>
  *********************************************************************************/


    @AuraEnabled
    public static  Map<Object,Object> loadDataFromAE(String aeRecordId, Map<Object,Object> adverseEventInfo ) {
        try{
            if(aeRecordId != null && aeRecordId != PC_Constants.EMPTY_STRING) {
                List<String> fields = new List<String>{
                        PC_Constants.getQualifiedAPIName('PC_Date_of_the_Report__c'),
                        PC_Constants.getQualifiedAPIName('PC_Event_Outcome__c'),
                        PC_Constants.getQualifiedAPIName('PC_Event_Onset_Date__c'),
                        PC_Constants.getQualifiedAPIName('PC_Stop_Date__c'),
                        PC_Constants.getQualifiedAPIName('PC_Description__c'),
                        PC_Constants.getQualifiedAPIName('PC_Laboratory_Data__c'),
                        PC_Constants.getQualifiedAPIName('PC_Other_Relevent_History__c'),
                        PC_Constants.getQualifiedAPIName('PC_Event_Verbatim__c'),
                        PC_Constants.getQualifiedAPIName('PC_Death_Date__c'),
                        PC_Constants.getQualifiedAPIName('PC_CauseOfDeath__c'),
                        PC_Constants.getQualifiedAPIName('PC_Event_HLGT_Code__c'),
                        PC_Constants.getQualifiedAPIName('PC_Event_SOC_Code__c'),
                        PC_Constants.getQualifiedAPIName('PC_Event_HLT_Code__c'),
                        PC_Constants.getQualifiedAPIName('PC_Event_PT_Code__c'),
                        PC_Constants.getQualifiedAPIName('PC_Event_LLT_Code__c'),
                        PC_Constants.getQualifiedAPIName('PC_SubmissionStatus__c'),
                        PC_Constants.getQualifiedAPIName('PC_ParentAdverseEvent__c'),
                        PC_Constants.getQualifiedAPIName('PC_VersionNumber__c')
                };
                PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_AdverseEvent2__c'),PC_Database.Operation.Reading, fields);

                PC_AdverseEvent2__c aeRec = [
                        Select PC_Date_of_the_Report__c,PC_Event_Outcome__c,PC_Event_Onset_Date__c,PC_Stop_Date__c,PC_Description__c,PC_Laboratory_Data__c,
                                PC_Other_Relevent_History__c,PC_Event_Verbatim__c,PC_Death_Date__c,PC_CauseOfDeath__c,PC_Event_HLGT_Code__c,
                                PC_Event_SOC_Code__c,PC_Event_HLT_Code__c,PC_Event_PT_Code__c,PC_Event_LLT_Code__c,PC_SubmissionStatus__c,
                                PC_ParentAdverseEvent__c,PC_VersionNumber__c
                        from PC_AdverseEvent2__c
                        where id = :aeRecordId
                ];



                adverseEventInfo.put('dateOfTheReport', String.valueOf(aeRec.PC_Date_of_the_Report__c));
                adverseEventInfo.put('eventOnsetDate', String.valueOf(aeRec.PC_Event_Onset_Date__c));
                adverseEventInfo.put('endDate', String.valueOf(aeRec.PC_Stop_Date__c));
                adverseEventInfo.put('description', String.valueOf(aeRec.PC_Description__c));
                adverseEventInfo.put('laboratoryData', String.valueOf(aeRec.PC_Laboratory_Data__c));
                adverseEventInfo.put('otherReleventHistory', String.valueOf(aeRec.PC_Other_Relevent_History__c));
                adverseEventInfo.put('eventVerbatim', String.valueOf(aeRec.PC_Event_Verbatim__c));
                adverseEventInfo.put('dateofDeath', String.valueOf(aeRec.PC_Death_Date__c));
                adverseEventInfo.put('eventCoding_SOC', String.valueOf(aeRec.PC_Event_SOC_Code__c));
                adverseEventInfo.put('eventCoding_HLGT', String.valueOf(aeRec.PC_Event_HLGT_Code__c));
                adverseEventInfo.put('eventCoding_HLT', String.valueOf(aeRec.PC_Event_HLT_Code__c));
                adverseEventInfo.put('eventCoding_PT', String.valueOf(aeRec.PC_Event_PT_Code__c));
                adverseEventInfo.put('eventCoding_LLT', String.valueOf(aeRec.PC_Event_LLT_Code__c));
                if (aeRec.PC_Event_Outcome__c != null) {
                    adverseEventInfo.put('outcome', aeRec.PC_Event_Outcome__c);
                } else {
                    adverseEventInfo.put('outcome', PC_Constants.EMPTY_STRING);
                }
                if (aeRec.PC_SubmissionStatus__c != null) {
                    adverseEventInfo.put('submissionStatus', aeRec.PC_SubmissionStatus__c);
                } else {
                    adverseEventInfo.put('submissionStatus', PC_Constants.EMPTY_STRING);
                }
            }

            else{
                adverseEventInfo.put('dateOfTheReport', null);
                adverseEventInfo.put('eventOnsetDate', null);
                adverseEventInfo.put('endDate', null);
                adverseEventInfo.put('description', null);
                adverseEventInfo.put('laboratoryData',null);
                adverseEventInfo.put('otherReleventHistory',null);
                adverseEventInfo.put('eventVerbatim', null);
                adverseEventInfo.put('dateofDeath', null);
                adverseEventInfo.put('eventCoding_SOC',null);
                adverseEventInfo.put('eventCoding_HLGT', null);
                adverseEventInfo.put('eventCoding_HLT', null);
                adverseEventInfo.put('eventCoding_PT', null);
                adverseEventInfo.put('eventCoding_LLT', null);
                adverseEventInfo.put('outcome', null);
                adverseEventInfo.put('submissionStatus', null);
            }

        }catch (exception ex){
            PC_Utility.logAndThrowException(ex);
        }

        return adverseEventInfo;
    }


    /*********************************************************
    Method Name          : getOutcomePicklistValues
    Description          : getting values for the picklist of outcome field
    Input Params         :null
    Return Type          :List<PicklistWrapper>
    *********************************************************************************/

    public static List<PicklistWrapper> getOutcomePicklistValues(){
        PicklistWrapper picklistObj ;
        List<PicklistWrapper> fieldValueWrapperList = new List<PicklistWrapper>();
        Schema.DescribeFieldResult picklistFieldResult = PC_AdverseEvent2__c.PC_Event_Outcome__c.getDescribe();
        List<Schema.PicklistEntry> picklistValueList = picklistFieldResult.getPicklistValues();
        for (Schema.PicklistEntry picklistValue : picklistValueList) {
            picklistObj = new PicklistWrapper();
            picklistObj.label = picklistValue.getLabel();
            picklistObj.value = picklistValue.getValue();
            fieldValueWrapperList.add(picklistObj);
        }
        return fieldValueWrapperList;
    }

    /*********************************************************
    Method Name          : getSubmissionStatusPicklistValues
    Description          : getting values for the picklist of SubmissionStatus field
    Input Params         :null
    Return Type          :List<PicklistWrapper>
    *********************************************************************************/

    public static List<PicklistWrapper> getSubmissionStatusPicklistValues(){
        PicklistWrapper picklistObj ;
        List<PicklistWrapper> fieldValueWrapperList = new List<PicklistWrapper>();
        Schema.DescribeFieldResult picklistFieldResult = PC_AdverseEvent2__c.PC_SubmissionStatus__c.getDescribe();
        List<Schema.PicklistEntry> picklistValueList = picklistFieldResult.getPicklistValues();
        picklistObj = new PicklistWrapper();
        picklistObj.label = System.Label.PC_Picklist_None;
        picklistObj.value = PC_Constants.EMPTY_STRING;
        fieldValueWrapperList.add(picklistObj);

        for (Schema.PicklistEntry picklistValue : picklistValueList) {
            picklistObj = new PicklistWrapper();
            picklistObj.label = picklistValue.getLabel();
            picklistObj.value = picklistValue.getValue();
            fieldValueWrapperList.add(picklistObj);
        }
        return fieldValueWrapperList;
    }



    public inherited sharing class PicklistWrapper {
        @AuraEnabled public String label {get; set;}
        @AuraEnabled public String value {get; set;}
        @AuraEnabled public Boolean selected {get; set;}

        PicklistWrapper(){

        }
    }

    /*********************************************************
  Method Name          : getAdverseEventLabels
  Description          : getting all the field labels for the translation
  Input Params         :null
  Return Type          :FieldLabels class
  *********************************************************************************/


    public static FieldLabels getAdverseEventLabels(){

        FieldLabels fieldlabels = new FieldLabels();
        try {
            fieldlabels.eventOnsetDateLabel = PC_AdverseEvent2__c.PC_Event_Onset_Date__c.getDescribe().getLabel();
            fieldlabels.dateOfTheReportLabel = PC_AdverseEvent2__c.PC_Date_of_the_Report__c.getDescribe().getLabel();
            fieldlabels.dateOfDeathLabel = PC_AdverseEvent2__c.PC_Death_Date__c.getDescribe().getLabel();
            fieldlabels.endDateLabel = PC_AdverseEvent2__c.PC_Stop_Date__c.getDescribe().getLabel();
            fieldlabels.outcomeLabel = PC_AdverseEvent2__c.PC_Event_Outcome__c.getDescribe().getLabel();
            fieldlabels.descriptionLabel = PC_AdverseEvent2__c.PC_Description__c.getDescribe().getLabel();
            fieldlabels.laboratoryDataLabel = PC_AdverseEvent2__c.PC_Laboratory_Data__c.getDescribe().getLabel();
            fieldlabels.otherReleventHistoryLabel = PC_AdverseEvent2__c.PC_Other_Relevent_History__c.getDescribe().getLabel();
            fieldlabels.eventVerbatimLabel = PC_AdverseEvent2__c.PC_Event_Verbatim__c.getDescribe().getLabel();
            fieldlabels.eventCoding_SOC_Label = PC_AdverseEvent2__c.PC_Event_SOC_Code__c.getDescribe().getLabel();
            fieldlabels.eventCoding_HLGT_Label = PC_AdverseEvent2__c.PC_Event_HLGT_Code__c.getDescribe().getLabel();
            fieldlabels.eventCoding_HLT_Label = PC_AdverseEvent2__c.PC_Event_HLT_Code__c.getDescribe().getLabel();
            fieldlabels.eventCoding_PT_Label = PC_AdverseEvent2__c.PC_Event_PT_Code__c.getDescribe().getLabel();
            fieldlabels.eventCoding_LLT_Label = PC_AdverseEvent2__c.PC_Event_LLT_Code__c.getDescribe().getLabel();
            fieldlabels.submissionStatusLabel = PC_AdverseEvent2__c.PC_SubmissionStatus__c.getDescribe().getLabel();

        }catch (exception ex){
            PC_Utility.logAndThrowException(ex);
        }

        return fieldlabels;
    }



    // fieldLables class

    public inherited sharing class FieldLabels {
        //Activity Fields
        @AuraEnabled public String eventOnsetDateLabel { get; set; }
        @AuraEnabled public String dateOfTheReportLabel { get; set; }
        @AuraEnabled public String dateOfDeathLabel { get; set; }
        @AuraEnabled public String outcomeLabel { get; set; }
        @AuraEnabled public String endDateLabel { get; set; }
        @AuraEnabled public String descriptionLabel { get; set;}
        @AuraEnabled public String laboratoryDataLabel { get; set; }
        @AuraEnabled public String otherReleventHistoryLabel { get; set; }
        @AuraEnabled public String eventVerbatimLabel { get; set; }
        @AuraEnabled public String eventCoding_SOC_Label { get; set; }
        @AuraEnabled public String eventCoding_HLGT_Label { get; set; }
        @AuraEnabled public String eventCoding_HLT_Label { get; set; }
        @AuraEnabled public String eventCoding_PT_Label { get; set; }
        @AuraEnabled public String eventCoding_LLT_Label { get; set; }
        @AuraEnabled public String submissionStatusLabel { get; set; }


        public FieldLabels() {
        }
    }



    public inherited sharing class AdverseEventFormData{

        /**
        * Property to hold Field Labels for adverse Event  section
        */
        @AuraEnabled public FieldLabels adverseEventLabels;

        /**
        * Property to hold different types of  outcome
        */
        @AuraEnabled public List<PicklistWrapper> outcomeOptions;
        /**
        * Property to hold different values of  submissionStatus
        */
        @AuraEnabled public List<PicklistWrapper> submissionStatusOptions;

        /**
        * Property for holding and setting data from adverse Event Object
        */
        @AuraEnabled public Map<Object,Object> adverseEventInfo;


    }

}