/*********************************************************************************
Class Name      :   PC_AE_PatientInfoRendererController
Description        : Controller for PC_AE_PatientInfoRenderer Component
Created By        : Haritha Reddy
Created Date     : 20-11-2018
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------
Haritha Reddy          20-11-2018              Initial Version
Haritha Reddy          25-09-2019              [PC-5275] Removed logic which was auto calculating age in adverse Event from Patient Date Of Birth
Shishir Bansal         15-10-2019              [PC-5606]  Error handling of picklist with special characters
Vijay Kashikar         21-Jan-21               [PC-7102] Added sharing clause
*********************************************************************************/

public with sharing class PC_AE_PatientInfoRendererController implements PC_AdverseEventMenuController.AdverseEventProcessor{

    /*********************************************************
    Method Name          : getPatientInfoData
    Description               : fetch Field Labels,Picklist Values of Adverse Event Fields on Patient Info Tab
    Input Params            : NA
    Return Type             : PatientInfoFormData Wrapper
    *********************************************************************************/
    @AuraEnabled
    public static PatientInfoFormData getPatientInfoData(){
        PatientInfoFormData formData = new PatientInfoFormData();
        try {
            formData.fieldLabels = getPatientInfoLabels();
            formData.genderOptions = getGenderPicklistValues();
            formData.ethnicityOptions =getEthnicityPicklistValues();
            formData.raceOptions = getRacePicklistValues();
            formData.weightOptions =getWeightPicklistValues();
            formData.ageTypeOptions = getAgeTypePicklistValues();
        }
        catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return formData;
    }

    /*********************************************************
Method Name          : fetchDataFromAE
Description               : Map Current Adverse event details to aeWrapper
Input Params            : List<Id> aeId, Map<Object,Object> patientInfoObj
Return Type             : Map<Object,Object>
*********************************************************************************/
    @AuraEnabled
    public static Map<Object,Object> fetchDataFromAE(String aeId, Map<Object,Object> patientInfoObj) {
        try {
            //Check FLS
            List<String> fields = new List<String>{
                    PC_Constants.getQualifiedAPIName('PC_Patient_Identifier__c'),
                    PC_Constants.getQualifiedAPIName('PC_Gender__c'),
                    PC_Constants.getQualifiedAPIName('PC_Ethnicity__c'),
                    PC_Constants.getQualifiedAPIName('PC_Date_of_Birth__c'),
                    PC_Constants.getQualifiedAPIName('PC_Age__c'),
                    PC_Constants.getQualifiedAPIName('PC_Weight__c'),
                    PC_Constants.getQualifiedAPIName('PC_Weight_Unit__c'),
                    PC_Constants.getQualifiedAPIName('PC_Race__c'),
                    PC_Constants.getQualifiedAPIName('PC_Age_Unit__c')
            };
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_AdverseEvent__c'),PC_Database.Operation.Reading, fields);

            PC_AdverseEvent__c aeRec = [
                    Select PC_Patient_Identifier__c,PC_Gender__c,PC_Ethnicity__c,PC_Date_of_Birth__c,
                            PC_Age__c,PC_Weight__c,PC_Weight_Unit__c,PC_Race__c,PC_Age_Unit__c
                    from PC_AdverseEvent__c
                    where id = :aeId
            ];
            if(patientInfoObj == null){
                patientInfoObj = new Map<Object,Object>();
            }
            patientInfoObj.put('patId', aeRec.PC_Patient_Identifier__c);
            patientInfoObj.put('gender', aeRec.PC_Gender__c);
            patientInfoObj.put('ethnicity', aeRec.PC_Ethnicity__c);
            patientInfoObj.put('dob', aeRec.PC_Date_of_Birth__c);
            patientInfoObj.put('age', aeRec.PC_Age__c);
            patientInfoObj.put('weight', aeRec.PC_Weight__c);
            patientInfoObj.put('weightType', aeRec.PC_Weight_Unit__c);
            patientInfoObj.put('ageType', aeRec.PC_Age_Unit__c);
            if(aeRec.PC_Race__c != null){
                patientInfoObj.put('race', aeRec.PC_Race__c);
            }else{
                patientInfoObj.put('race', PC_Constants.EMPTY_STRING);
            }

            return patientInfoObj;
        }catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return null;
    }

    /*********************************************************
Method Name          : fetchDataFromPatient
Description               : Map Patient details to aeWrapper
Input Params            : List<Id> aeId, Map<Object,Object> patInfo
Return Type             : Map<Object,Object>
*********************************************************************************/
    @AuraEnabled
    public static Map<Object,Object> fetchDataFromPatient(String caseId, Map<Object,Object> patInfo) {
        try {
            //Check FLS
            List<String> fields = new List<String>{
                    PC_Constants.getQualifiedAPIName('Id'),
                    PC_Constants.getQualifiedAPIName('PC_Date_of_Birth__c'),
                    PC_Constants.getQualifiedAPIName('PC_Gender__c')
            };
            PC_Database.assertAccess('Account',PC_Database.Operation.Reading, fields);
            List<String> caseFields = new List<String>{
                    PC_Constants.getQualifiedAPIName('Id'),
                    PC_Constants.getQualifiedAPIName('AccountId')
            };
            PC_Database.assertAccess('Case',PC_Database.Operation.Reading, caseFields);

            Case currentCase = [Select AccountId from Case where id=:caseId];
            Account patientAcc = [Select PC_Date_of_Birth__c,PC_Gender__c,Id from Account where id=:currentCase.AccountId];
            Integer days;

            if(patInfo == null){
                patInfo = new Map<Object,Object>();
            }
            patInfo.put('dob', patientAcc.PC_Date_of_Birth__c);
            patInfo.put('gender', patientAcc.PC_Gender__c);
            patInfo.put('patId', patientAcc.Id);
            patInfo.put('ageType', 'Year(s)');
            patInfo.put('race',PC_Constants.EMPTY_STRING);
            return patInfo;

        }catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return null;
    }

    public void updateAdverseEvent(PC_AdverseEvent__c aeRec, Map<Object,Object> patientInfoObj) {
        aeRec.PC_Patient_Identifier__c = (String)patientInfoObj.get('patId');
        aeRec.PC_Gender__c = (String)patientInfoObj.get('gender');
        aeRec.PC_Ethnicity__c = (String)patientInfoObj.get('ethnicity');
        if(patientInfoObj.get('dob') != PC_Constants.EMPTY_STRING && patientInfoObj.get('dob') != null){
            aeRec.PC_Date_of_Birth__c = Date.valueOf((String)patientInfoObj.get('dob'));
        }
        aeRec.PC_Age__c = Integer.valueOf(patientInfoObj.get('age'));
        aeRec.PC_Weight__c = Integer.valueOf(patientInfoObj.get('weight'));
        aeRec.PC_Weight_Unit__c = (String)patientInfoObj.get('weightType');

        if(patientInfoObj.get('race') != PC_Constants.EMPTY_STRING && patientInfoObj.get('race') != null){
            String SelectedRaces = String.valueOf(patientInfoObj.get('race'));

            if(String.isNotBlank(SelectedRaces)) {

                String selectedRacesValues = '';

                if(SelectedRaces.startsWith('(') && SelectedRaces.endsWith(')') ) {
                    SelectedRaces = SelectedRaces.removeStart('(');
                    SelectedRaces = SelectedRaces.removeEnd(')');
                }

                List<String> lstRace = SelectedRaces.split(',');
                if (lstRace != null) {
                    for (String picklistValue : lstRace) {
                        if (selectedRacesValues == '') {
                            selectedRacesValues = picklistValue;
                        } else {
                            selectedRacesValues = selectedRacesValues + ';' + picklistValue;
                        }
                    }
                }
                if(selectedRacesValues !='') {
                    aeRec.PC_Race__c = selectedRacesValues;
                }
            }
        }

        aeRec.PC_Age_Unit__c = (String)patientInfoObj.get('ageType');
    }

    public static List<PicklistWrapper> getGenderPicklistValues(){
        PicklistWrapper picklistObj ;
        List<PicklistWrapper> fieldValueWrapperList = new List<PicklistWrapper>();
        Schema.DescribeFieldResult picklistFieldResult = PC_AdverseEvent__c.PC_Gender__c.getDescribe();
        List<Schema.PicklistEntry> picklistValueList = picklistFieldResult.getPicklistValues();
        for (Schema.PicklistEntry picklistValue : picklistValueList) {
            picklistObj = new PicklistWrapper();
            picklistObj.label = picklistValue.getLabel();
            picklistObj.value = picklistValue.getValue();
            fieldValueWrapperList.add(picklistObj);
        }
        return fieldValueWrapperList;
    }
    public static List<PicklistWrapper> getEthnicityPicklistValues(){
        PicklistWrapper picklistObj ;
        List<PicklistWrapper> fieldValueWrapperList = new List<PicklistWrapper>();
        Schema.DescribeFieldResult picklistFieldResult = PC_AdverseEvent__c.PC_Ethnicity__c.getDescribe();
        List<Schema.PicklistEntry> picklistValueList = picklistFieldResult.getPicklistValues();
        for (Schema.PicklistEntry picklistValue : picklistValueList) {
            picklistObj = new PicklistWrapper();
            picklistObj.label = picklistValue.getLabel();
            picklistObj.value = picklistValue.getValue();
            fieldValueWrapperList.add(picklistObj);
        }
        return fieldValueWrapperList;
    }

    public static List<PicklistWrapper> getRacePicklistValues(){
        PicklistWrapper picklistObj ;
        List<PicklistWrapper> fieldValueWrapperList = new List<PicklistWrapper>();
        Schema.DescribeFieldResult picklistFieldResult = PC_AdverseEvent__c.PC_Race__c.getDescribe();
        List<Schema.PicklistEntry> picklistValueList = picklistFieldResult.getPicklistValues();
        for (Schema.PicklistEntry picklistValue : picklistValueList) {
            picklistObj = new PicklistWrapper();
            picklistObj.label = picklistValue.getLabel();
            picklistObj.value = picklistValue.getValue();
            fieldValueWrapperList.add(picklistObj);
        }
        return fieldValueWrapperList;
    }

    public static List<PicklistWrapper> getWeightPicklistValues(){
        PicklistWrapper picklistObj ;
        List<PicklistWrapper> fieldValueWrapperList = new List<PicklistWrapper>();
        Schema.DescribeFieldResult picklistFieldResult = PC_AdverseEvent__c.PC_Weight_Unit__c.getDescribe();
        List<Schema.PicklistEntry> picklistValueList = picklistFieldResult.getPicklistValues();
        for (Schema.PicklistEntry picklistValue : picklistValueList) {
            picklistObj = new PicklistWrapper();
            picklistObj.label = picklistValue.getLabel();
            picklistObj.value = picklistValue.getValue();
            fieldValueWrapperList.add(picklistObj);
        }
        return fieldValueWrapperList;
    }

    public static List<PicklistWrapper> getAgeTypePicklistValues(){
        PicklistWrapper picklistObj ;
        List<PicklistWrapper> fieldValueWrapperList = new List<PicklistWrapper>();
        Schema.DescribeFieldResult picklistFieldResult = PC_AdverseEvent__c.PC_Age_Unit__c.getDescribe();
        List<Schema.PicklistEntry> picklistValueList = picklistFieldResult.getPicklistValues();
        for (Schema.PicklistEntry picklistValue : picklistValueList) {
            picklistObj = new PicklistWrapper();
            picklistObj.label = picklistValue.getLabel();
            picklistObj.value = picklistValue.getValue();
            fieldValueWrapperList.add(picklistObj);
        }
        return fieldValueWrapperList;
    }

    public inherited sharing class PatientInfoFormData{

        @AuraEnabled public FieldLabels fieldLabels;
        @AuraEnabled public List<PicklistWrapper> genderOptions;
        @AuraEnabled public List<PicklistWrapper> ethnicityOptions;
        @AuraEnabled public List<PicklistWrapper> raceOptions;
        @AuraEnabled public List<PicklistWrapper> weightOptions;
        @AuraEnabled public List<PicklistWrapper> ageTypeOptions;

    }
    public inherited sharing class PicklistWrapper {
        @AuraEnabled public String label {get; set;}
        @AuraEnabled public String value {get; set;}

        public PicklistWrapper(){
        }
    }

    /*********************************************************
    Method Name          : getPatientInfoLabels
    Description               : fetch Field Labels of Adverse Event Fields on Patient Info Tab
    Input Params            : NA
    Return Type             : FieldLabels Wrapper
    *********************************************************************************/
    public static FieldLabels getPatientInfoLabels(){

        FieldLabels fieldlabels = new FieldLabels();
        fieldlabels.patId = PC_AdverseEvent__c.PC_Patient_Identifier__c.getDescribe().getLabel();
        fieldlabels.age	= PC_AdverseEvent__c.PC_Age__c.getDescribe().getLabel();
        fieldlabels.dob	= PC_AdverseEvent__c.PC_Date_of_Birth__c.getDescribe().getLabel();
        fieldlabels.gender = PC_AdverseEvent__c.PC_Gender__c.getDescribe().getLabel();
        fieldlabels.weight = PC_AdverseEvent__c.PC_Weight__c.getDescribe().getLabel();
        fieldlabels.ethnicity = PC_AdverseEvent__c.PC_Ethnicity__c.getDescribe().getLabel();
        fieldlabels.race = PC_AdverseEvent__c.PC_Race__c.getDescribe().getLabel();

        return fieldlabels;
    }

    public inherited sharing class FieldLabels {
        @AuraEnabled public String patId { get; set; }
        @AuraEnabled public String age { get; set; }
        @AuraEnabled public String dob { get; set; }
        @AuraEnabled public String gender { get; set; }
        @AuraEnabled public String weight { get; set; }
        @AuraEnabled public String ethnicity { get; set;}
        @AuraEnabled public String race { get; set; }

        public FieldLabels() {
        }
    }
}