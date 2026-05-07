/*********************************************************************************
Class Name      :   PC_AE2_SuspectProductsRendererController
Description        : Controller for PC_AE_SuspectProductsRenderer Component
Created By        : Haritha Reddy
Created Date     : 26-11-2018
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------
Haritha Reddy          26-11-2018              Initial Version
Shishir Bansal         22-08-2019              Added three date variables in Suspect Prescription Wrapper for Date Formatting in
                                               Adverse Event PDF download feature
Haritha Reddy          22-11-2019              [PC-5656] Added setProductDetails method which will fetch Product details
                                               and update suspectProductInfo in aewrapper with selected Product Details
Haritha Reddy 		   09-01-2020              [PC-5600] Code changes to make Prescription drop-down/Product Lookup on Suspect Product Tab configurable
Haritha Reddy 		   09-01-2020              [PC-5600] Added logic to display & save Additional SuspectPrescription Fields while
                                                creating/editing Adverse Event
Vijay Kashikar         21-Jan-21               [PC-7102] Added sharing clause
*********************************************************************************/
public with sharing class PC_AE2_SuspectProductsRendererController implements PC_AdverseEventMenu2Controller.AdverseEventProcessor{
    /*********************************************************
    Method Name          : getPrescriptionData
    Description          : fetches Field Labels of Suspect Prescription Fields, prescriptions related to case,
                           Suspect Prescriptions related to Adverse Event
    Input Params         : caseId, Adverse Event Id
    Return Type          : SuspectProductFormData Wrapper
    *********************************************************************************/
    @AuraEnabled
    public static SuspectProductFormData getPrescriptionData(String caseId, String aeId, Boolean usePrescription,Boolean isMedicalInquiry){
        SuspectProductFormData formData = new SuspectProductFormData();
        try {
            formData.additionalFieldsConfig = getAdditionalFieldsConfigData(usePrescription,false);
            formData.fieldLabels = getFieldLabels();
            formData.prescriptions = getRelatedPrescriptions(caseId);
            formData.suspectPrescriptions = getRelatedSuspectPrescriptions(aeId,formData.additionalFieldsConfig.fieldSetName);
            formData.prodCompoundedOptions = getProdCompoundedOptions();
            formData.prodOTCOptions = getProdOTCOptions();
            formData.eventAbatedOptions = getEventAbatedOptions();
            formData.eventReappearedOptions = getEventReappearedOptions();
        }
        catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return formData;
    }

    /*********************************************************
    Method Name          : getAdditionalFieldsConfigData
    Description          : fetches configuration of Additional Fields to be displayed on Suspect Prescription Form
    Input Params         : usePrescription
    Return Type          : AdditionalFieldsConfig Wrapper
    *********************************************************************************/
    public static AdditionalFieldsConfig getAdditionalFieldsConfigData(Boolean usePrescription, Boolean isMedicalInquiry){
        AdditionalFieldsConfig additionalFieldsConfig = new AdditionalFieldsConfig();
        try {
            String additionalFieldsConfigJSON,patientConnectSettingName;
            if(usePrescription == null || usePrescription){
                if(isMedicalInquiry){
                    patientConnectSettingName = PC_Constants.PC_AE_MI_SUSPECT_PRESCRIPTION_RX_FIELD_MAP;
                }else{
                    patientConnectSettingName = PC_Constants.PC_AE_SUSPECT_PRESCRIPTION_RX_FIELD_MAP;
                }
            }else{
                if(isMedicalInquiry){
                    patientConnectSettingName = PC_Constants.PC_AE_MI_SUSPECT_PRESCRIPTION_PRODUCT_FIELD_MAP;
                }else {
                    patientConnectSettingName = PC_Constants.PC_AE_SUSPECT_PRESCRIPTION_PRODUCT_FIELD_MAP;
                }
            }
            additionalFieldsConfigJSON = PC_SYSTEM.getPatientConnectSetting(patientConnectSettingName, PC_Constants.EMPTY_STRING);
            if(string.isNotEmpty(additionalFieldsConfigJSON)) {
                Boolean isAdditionalFieldsConfigValid = validateAdditionalFieldsConfig(patientConnectSettingName, additionalFieldsConfigJSON);
                if(isAdditionalFieldsConfigValid){
                    Map<String, Object> additionalFieldsConfigMap = new Map<String, Object>();
                    try{
                        additionalFieldsConfigMap = (Map<String, Object>) JSON.deserializeUntyped(additionalFieldsConfigJSON);
                    }catch(Exception ex){
                        PC_Utility.createExceptionLog(ex);
                    }
                    String fieldSetName = (String) additionalFieldsConfigMap.get(PC_Constants.PC_AE_FIELD_SET_NAME);
                    additionalFieldsConfig.fieldSetName = fieldSetName;
                    additionalFieldsConfig.fieldsMap = (Map<String, Object>) additionalFieldsConfigMap.get(PC_Constants.PC_AE_FIELD_MAP);
                    additionalFieldsConfig.objectAPIName = PC_Constants.PC_SUSPECT_PRESCRIPTION_OBJECT;
                    if(String.isNotEmpty(fieldSetName)){
                        try{
                            additionalFieldsConfig.fsFields = PC_FieldSetController.getFieldsByName(PC_Constants.PC_SUSPECT_PRESCRIPTION_OBJECT, fieldSetName);
                        }catch(Exception ex){
                            PC_Utility.createExceptionLog(ex);
                        }
                    }
                }
            }
        }
        catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return additionalFieldsConfig;
    }

    /*********************************************************************************
    Method Name    : validateAdditionalFieldsConfig
    Description    : Returns true is additional Fields configuration is valid in Patient Connect Setting
    Return Type    : String
    *********************************************************************************/
    private static Boolean validateAdditionalFieldsConfig(String patientConnectSettingName,String additionalFieldsConfigJSON) {
        Map<String, Object> additionalFieldsConfigMap;
        Boolean isAdditionalFieldsConfigValid = true;
        try{
            additionalFieldsConfigMap = (Map<String, Object>) JSON.deserializeUntyped(additionalFieldsConfigJSON);
        }catch(Exception ex){
            isAdditionalFieldsConfigValid = false;
            throw new PC_AE2_SuspectProductsRendererController.SuspectProduct_Exception(
                    PC_Constants.PC_AE_JSON_FORMAT_INCORRECT_ERROR_MESSAGE+patientConnectSettingName+'. '+PC_Constants.PC_AE_CONTACT_SYSTEM_ADMINISTRATOR_ERROR_MESSAGE);
        }
        String fieldSetName = (String) additionalFieldsConfigMap.get(PC_Constants.PC_AE_FIELD_SET_NAME);
        Map<String, Object> fieldsMap = (Map<String, Object>) additionalFieldsConfigMap.get(PC_Constants.PC_AE_FIELD_MAP);
        if(String.isEmpty(fieldSetName) || fieldsMap == null){
            isAdditionalFieldsConfigValid = false;
            throw new PC_AE2_SuspectProductsRendererController.SuspectProduct_Exception(
                    PC_Constants.PC_AE_JSON_FORMAT_INCORRECT_ERROR_MESSAGE+patientConnectSettingName+'. '+PC_Constants.PC_AE_CONTACT_SYSTEM_ADMINISTRATOR_ERROR_MESSAGE);
        }

        if(String.isNotEmpty(fieldSetName)){
            List<String> fsFields = new List<String>();
            try{
                fsFields= PC_FieldSetController.getFieldsByName(PC_Constants.PC_SUSPECT_PRESCRIPTION_OBJECT, fieldSetName);
            }catch(Exception ex){
                isAdditionalFieldsConfigValid = false;
                throw new PC_AE2_SuspectProductsRendererController.SuspectProduct_Exception(
                        PC_Constants.PC_AE_INVALID_FIELDSET_ERROR_MESSAGE+patientConnectSettingName+'. '+PC_Constants.PC_AE_CONTACT_SYSTEM_ADMINISTRATOR_ERROR_MESSAGE);
            }
            if(fsFields.isEmpty()){
                isAdditionalFieldsConfigValid = false;
                throw new PC_AE2_SuspectProductsRendererController.SuspectProduct_Exception(
                        PC_Constants.PC_AE_NO_FIELDS_FOUND_ERROR_MESSAGE+patientConnectSettingName+'. '+PC_Constants.PC_AE_CONTACT_SYSTEM_ADMINISTRATOR_ERROR_MESSAGE);
            }else{
                String incorrectlyMappedFields = PC_Constants.EMPTY_STRING;
                for (String field : fsFields) {
                    if(fieldsMap != null) {
                        String mappedField = String.valueOf(fieldsMap.get(field));
                        if(String.isEmpty(mappedField)) {
                            if(incorrectlyMappedFields != PC_Constants.EMPTY_STRING){
                                incorrectlyMappedFields = incorrectlyMappedFields+', '+ field;
                            }else{
                                incorrectlyMappedFields = field;
                            }
                        }
                    }
                }
                if(incorrectlyMappedFields != PC_Constants.EMPTY_STRING){
                    isAdditionalFieldsConfigValid = false;
                    throw new PC_AE2_SuspectProductsRendererController.SuspectProduct_Exception(PC_Constants.PC_AE_FIELD_MAPPING_INCORRECT_ERROR_MESSAGE+incorrectlyMappedFields+'. '+PC_Constants.PC_AE_CONTACT_SYSTEM_ADMINISTRATOR_ERROR_MESSAGE);
                }
            }
        }
        return isAdditionalFieldsConfigValid;
    }

    @AuraEnabled
    public static FieldPathAndValue getPopulatedFieldSet(String fsName, Map<Object, Object> suspectProductInfoObj) {
        try {
            String typeName = PC_Constants.PC_SUSPECT_PRESCRIPTION_OBJECT;

            FieldPathAndValue fieldPathAndValue = new FieldPathAndValue();
            if(fsName != null && fsName != PC_Constants.EMPTY_STRING && fsName != PC_Constants.UNDEFINED_STRING){
                List<String> fieldPath= PC_FieldSetController.getFieldsByName(typeName, fsName);
                //Added for PDF
                List<PC_FieldSetController.FieldSetMember> fieldSetMembers=PC_FieldSetController.getFields(typeName,fsName);

                if (fieldPath!=null && !fieldPath.isEmpty()) {
                    Map<Object,Object> fieldValuePair = new Map<Object,Object>();
                    if(suspectProductInfoObj.get('additionalFields') !=null){
                        fieldValuePair = (Map<Object,Object>)suspectProductInfoObj.get('additionalFields');
                    }else{
                        for (String field : fieldPath) {
                            fieldValuePair.put(field, PC_Constants.EMPTY_STRING);
                        }
                    }
                    //Added for PDF
                    Map<Object, Object> fieldLabelsMap = new Map<Object, Object>();
                    for (PC_FieldSetController.FieldSetMember fieldSetMember : fieldSetMembers) {
                        fieldLabelsMap.put(fieldSetMember.fieldPath, fieldSetMember.label);
                    }

                    fieldPathAndValue.fieldPath = fieldPath;
                    fieldPathAndValue.fieldValue = fieldValuePair;
                    //Added for PDF
                    fieldPathAndValue.fieldLabels = fieldLabelsMap;
                    return fieldPathAndValue;
                }else{
                    return null;
                }
            }

        }catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return null;
    }

    public inherited sharing class FieldPathAndValue {
        @AuraEnabled public List<String> fieldPath { get; set; }
        @AuraEnabled public Map<Object,Object> fieldValue { get; set; }
        @AuraEnabled public Map<Object,Object> fieldLabels { get; set; }

        public FieldPathAndValue() {
        }
    }

    /*****************************************************************************************************
    * Parameter    : SObject sobj
    * Method name  : initialiseFieldSetFieldsMap
    * Return Type  : Map<String, Object>
    * Description  : Method to initialise Map of fieldset member values to empty values.
    *****************************************************************************************************/
    @AuraEnabled
    public static Map<String, Object> initialiseFieldSetFieldsMap(String objectAPIName, String fieldSetName) {
        Map<String, Object> fsFields = new Map<String, Object>();
        try {
            SObjectType sObjType = Schema.getGlobalDescribe().get(objectAPIName);
            List<String> fsList = new List<String>();
            if (String.isNotBlank(fieldSetName)) {
                fsList = PC_FieldSetController.getFieldsByName(objectAPIName, fieldSetName);
            }
            for (String fieldName : fsList) {
                Schema.DisplayType fieldType = sObjType.getDescribe().fields.getMap().get(fieldName).getDescribe().getType();

                if (fieldType == Schema.DisplayType.STRING || fieldType == Schema.DisplayType.EMAIL || fieldType == Schema.DisplayType.PICKLIST ||
                        fieldType == Schema.DisplayType.PHONE || fieldType == Schema.DisplayType.TEXTAREA) {
                    fsFields.put(fieldName, PC_Constants.EMPTY_STRING);
                } else if (fieldType == Schema.DisplayType.DATE || fieldType == Schema.DisplayType.DATETIME || fieldType == Schema.DisplayType.BOOLEAN ||
                        fieldType == Schema.DisplayType.DOUBLE) {
                    fsFields.put(fieldName, null);
                } else {
                    fsFields.put(fieldName, PC_Constants.EMPTY_STRING);
                }

            }
        }catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return fsFields;
    }

    public void updateAdverseEvent(PC_AdverseEvent2__c aeRec, Map<Object,Object> suspectProductInfo) {

        PC_AdverseEvents2Controller.AdverseEventConfig adverseEventConfig=PC_AdverseEvents2Controller.getAdverseEventConfigData(aeRec.Id);
        PC_AE2_SuspectProductsRendererController.AdditionalFieldsConfig spAdditionalInfoConfig =
                PC_AE2_SuspectProductsRendererController.getAdditionalFieldsConfigData(adverseEventConfig.usePrescription,false);
        List<String> fsFields = spAdditionalInfoConfig.fsFields;

        //insert draft Suspect Prescription Records
        if(suspectProductInfo.get('newSuspectPrescriptionList') != null && suspectProductInfo.get('newSuspectPrescriptionList') != PC_Constants.EMPTY_STRING){
            String JSONString = JSON.serialize(suspectProductInfo.get('newSuspectPrescriptionList'));
            List<SuspectPrescriptionWrapper> newSPWrapperList = (List<SuspectPrescriptionWrapper>) JSON.deserialize(JSONString,List<SuspectPrescriptionWrapper>.class);
            List<PC_Suspect_Prescription__c> toBeInsertedSPList = new  List<PC_Suspect_Prescription__c>();
            for(SuspectPrescriptionWrapper sp: newSPWrapperList){
                PC_Suspect_Prescription__c spRec = new PC_Suspect_Prescription__c();
                spRec.PC_Adverse_Event2__c = aeRec.Id;
                spRec.PC_Prescription__c = sp.prescription;
                spRec.PC_Product__c = sp.product;
                spRec.PC_Product_Name__c = sp.productName;
                spRec.PC_Drug_NDC__c = sp.ndc;
                spRec.PC_Product_Lot__c = sp.lot;
                spRec.PC_Product_Strength__c = sp.productStrength;
                spRec.PC_Product_Manufacturer__c = sp.manufacturer;
                spRec.PC_Concomitant_Medical_Products__c = sp.concomitant;
                spRec.PC_Dose__c = sp.dose;
                spRec.PC_Frequency__c = sp.frequency;
                spRec.PC_Route_of_Administration__c = sp.route;
                spRec.PC_Indication_for_Product_Use__c = sp.diagnosis;
                spRec.PC_Product_Compounded__c = sp.prodCompounded;
                spRec.PC_Abated_After_Use_Stopped_or_Reduced__c  = sp.eventAbated;
                spRec.PC_Product_OTC__c = sp.prodOTC;
                spRec.PC_Event_Reappeared_After_Reintroduction__c = sp.eventReappeared;
                spRec.PC_Therapy_Start_Date__c = sp.therapyStartDate;
                spRec.PC_Therapy_End_Date__c = sp.therapyEndDate;
                spRec.PC_Expiration_Date__c = sp.expirationDate;

                if(sp.additionalFields != null && fsFields != null){
                    Map<String,String> additionalFields = sp.additionalFields;
                    Object castValue;
                    for (String field : fsFields) {
                        castValue = PC_FieldSetController.castFieldValueBasedOnType(field, additionalFields.get(field), spRec);
                        spRec.put(field, castValue);
                    }
                }

                toBeInsertedSPList.add(spRec);
            }
            PC_Database.ins(toBeInsertedSPList, true);
        }

        //update edited Suspect Prescription Records
        if(suspectProductInfo.get('updatedSuspectPrescriptionList') != null && suspectProductInfo.get('updatedSuspectPrescriptionList') != PC_Constants.EMPTY_STRING){
            String updSPJSONString = JSON.serialize(suspectProductInfo.get('updatedSuspectPrescriptionList'));
            List<SuspectPrescriptionWrapper> updatedSPWrapperList = (List<SuspectPrescriptionWrapper>) JSON.deserialize(updSPJSONString,List<SuspectPrescriptionWrapper>.class);
            List<String> toBeUpdatedSPIds = new List<String>();
            for(SuspectPrescriptionWrapper sp: updatedSPWrapperList) {
                toBeUpdatedSPIds.add(sp.recId);
            }
            //Check FLS
            Set<String> suspectPresFieldsSet = new Set<String>{'Id','Name',
                    PC_Constants.getQualifiedAPIName('PC_Prescription__c'),
                    PC_Constants.getQualifiedAPIName('PC_Product__c'),
                    PC_Constants.getQualifiedAPIName('PC_Product_Name__c'),
                    PC_Constants.getQualifiedAPIName('PC_Product_Manufacturer__c'),
                    PC_Constants.getQualifiedAPIName('PC_Drug_NDC__c'),
                    PC_Constants.getQualifiedAPIName('PC_Product_Lot__c'),
                    PC_Constants.getQualifiedAPIName('PC_Dose__c'),
                    PC_Constants.getQualifiedAPIName('PC_Frequency__c'),
                    PC_Constants.getQualifiedAPIName('PC_Route_of_Administration__c'),
                    PC_Constants.getQualifiedAPIName('PC_Therapy_Start_Date__c'),
                    PC_Constants.getQualifiedAPIName('PC_Product_Strength__c'),
                    PC_Constants.getQualifiedAPIName('PC_Indication_for_Product_Use__c'),
                    PC_Constants.getQualifiedAPIName('PC_Product_Compounded__c'),
                    PC_Constants.getQualifiedAPIName('PC_Product_OTC__c'),
                    PC_Constants.getQualifiedAPIName('PC_Expiration_Date__c'),
                    PC_Constants.getQualifiedAPIName('PC_Concomitant_Medical_Products__c'),
                    PC_Constants.getQualifiedAPIName('PC_Abated_After_Use_Stopped_or_Reduced__c'),
                    PC_Constants.getQualifiedAPIName('PC_Event_Reappeared_After_Reintroduction__c'),
                    PC_Constants.getQualifiedAPIName('PC_Therapy_End_Date__c')
            };
            if (fsFields!= null && !fsFields.isEmpty()) {
                suspectPresFieldsSet.addAll(fsFields);
            }
            List<String> suspectPresFieldList = new List<String>();
            suspectPresFieldList.addAll(suspectPresFieldsSet);
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Suspect_Prescription__c'),PC_Database.Operation.Reading, suspectPresFieldList);
            String spFields = String.join(suspectPresFieldList, ',');
            String spQuery = 'Select ' +spFields;

            spQuery = spQuery+' from PC_Suspect_Prescription__c where Id IN:toBeUpdatedSPIds';
            List<PC_Suspect_Prescription__c> toBeUpdatedSPList = Database.query (spQuery);

            for(PC_Suspect_Prescription__c spRec: toBeUpdatedSPList) {
                for (SuspectPrescriptionWrapper sp : updatedSPWrapperList) {
                    IF(spRec.Id == sp.recId){
                        spRec.PC_Prescription__c = sp.prescription;
                        spRec.PC_Product__c = sp.product;
                        spRec.PC_Product_Name__c = sp.productName;
                        spRec.PC_Drug_NDC__c = sp.ndc;
                        spRec.PC_Product_Lot__c = sp.lot;
                        spRec.PC_Product_Strength__c = sp.productStrength;
                        spRec.PC_Product_Manufacturer__c = sp.manufacturer;
                        spRec.PC_Concomitant_Medical_Products__c = sp.concomitant;
                        spRec.PC_Dose__c = sp.dose;
                        spRec.PC_Frequency__c = sp.frequency;
                        spRec.PC_Route_of_Administration__c = sp.route;
                        spRec.PC_Indication_for_Product_Use__c = sp.diagnosis;
                        spRec.PC_Product_Compounded__c = sp.prodCompounded;
                        spRec.PC_Abated_After_Use_Stopped_or_Reduced__c = sp.eventAbated;
                        spRec.PC_Product_OTC__c = sp.prodOTC;
                        spRec.PC_Event_Reappeared_After_Reintroduction__c = sp.eventReappeared;
                        spRec.PC_Therapy_Start_Date__c = sp.therapyStartDate;
                        spRec.PC_Therapy_End_Date__c = sp.therapyEndDate;
                        spRec.PC_Expiration_Date__c = sp.expirationDate;
                        if(sp.additionalFields != null && fsFields != null) {
                            Map<String,String> additionalFields = sp.additionalFields;
                            Object castValue;
                            for (String field : fsFields) {
                                castValue = PC_FieldSetController.castFieldValueBasedOnType(field, additionalFields.get(field), spRec);
                                spRec.put(field, castValue);
                            }
                        }
                    }
                }
            }
            PC_Database.upd(toBeUpdatedSPList, true);
        }

        //delete selected Suspect Prescription Records
        if(suspectProductInfo.get('deletedSPList') != null && suspectProductInfo.get('deletedSPList') != PC_Constants.EMPTY_STRING){
            List<Object> delSPList = (List<Object>)suspectProductInfo.get('deletedSPList');
            List<string> delSPIds= new List<string>();
            for(Object a: delSPList){
                delSPIds.add(String.valueOf(a));
            }
            //Check FLS
            List<String> spFields = new List<String>{
                    PC_Constants.getQualifiedAPIName('Id')
            };
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Suspect_Prescription__c'),PC_Database.Operation.Reading, spFields);

            List<PC_Suspect_Prescription__c> deletedSPList = [select Id From PC_Suspect_Prescription__c Where Id IN: delSPIds];
            PC_Database.del(deletedSPList, true);
        }
    }

    /*********************************************************
Method Name          : prePopulateSuspectPrescriptionForm
Description               : Pre-Populate aeWrapper suspectProductInfo details with Data from Selected Prescription & it's related Product
Input Params            : String prescriptionId, Map<Object,Object> suspectProductInfoObj
Return Type             : Map<Object,Object>
*********************************************************************************/
    @AuraEnabled
    public static Map<Object,Object> prePopulateSuspectPrescriptionForm(Map<String, Object> fieldsMap, List<String> fsFields, String prescriptionId, Map<Object,Object> suspectProductInfoObj) {
        try {
            if(prescriptionId != PC_Constants.UNDEFINED_STRING && prescriptionId != null) {
                //Check FLS for Prescription Fields
                Set<String> prescriptionFieldSet = new Set<String>{'Id',
                        PC_Constants.getQualifiedAPIName('PC_Dosage__c'),
                        PC_Constants.getQualifiedAPIName('PC_Frequency__c'),
                        PC_Constants.getQualifiedAPIName('PC_Rx_End_Date__c'),
                        PC_Constants.getQualifiedAPIName('PC_Rx_Start_Date__c'),
                        PC_Constants.getQualifiedAPIName('PC_Product__r.Name'),
                        PC_Constants.getQualifiedAPIName('PC_Product__r.')+ PC_Constants.getQualifiedAPIName('PC_NDC__c'),
                        PC_Constants.getQualifiedAPIName('PC_Product__r.')+ PC_Constants.getQualifiedAPIName('PC_Strength__c'),
                        PC_Constants.getQualifiedAPIName('PC_Product__r.')+ PC_Constants.getQualifiedAPIName('PC_Manufacturer__r.Name')
                };
                if (fsFields!= null && !fsFields.isEmpty()) {
                    for(string SPField: fsFields){
                        if(fieldsMap != null){
                            String mappedPrescriptionField = String.valueOf(fieldsMap.get(SPField));
                            if(String.isNotEmpty(mappedPrescriptionField)){
                                prescriptionFieldSet.add(mappedPrescriptionField);
                            }
                        }
                    }
                }
                List<String> prescriptionFieldList = new List<String>();
                prescriptionFieldList.addAll(prescriptionFieldSet);
                PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Prescription__c'),PC_Database.Operation.Reading, prescriptionFieldList);

                String prescriptionFields = String.join(prescriptionFieldList, ',');
                String prescriptionQuery = 'Select ' +prescriptionFields;

                prescriptionQuery = prescriptionQuery+' from PC_Prescription__c where id =:prescriptionId';
                PC_Prescription__c prescription = Database.query (prescriptionQuery);

                Map<Object,Object> additionalFields = new Map<Object,Object>();
                if (fsFields!= null && !fsFields.isEmpty()) {
                    for (String field : fsFields) {
                        if(fieldsMap != null) {
                            String mappedPrescriptionField = String.valueOf(fieldsMap.get(field));
                            if(String.isNotEmpty(mappedPrescriptionField)) {
                                additionalFields.put(field, prescription.get(mappedPrescriptionField));
                            }
                        }
                    }
                }

                if(suspectProductInfoObj == null){
                    suspectProductInfoObj = new Map<Object,Object>();
                }
                //suspectProductInfoObj.put('prescription', PC_Constants.EMPTY_STRING);
                suspectProductInfoObj.put('productName', prescription.PC_Product__r.Name);
                suspectProductInfoObj.put('productStrength', prescription.PC_Product__r.PC_Strength__c);
                suspectProductInfoObj.put('manufacturer', prescription.PC_Product__r.PC_Manufacturer__r.Name);
                suspectProductInfoObj.put('ndc', prescription.PC_Product__r.PC_NDC__c);
                suspectProductInfoObj.put('lot', PC_Constants.EMPTY_STRING);
                suspectProductInfoObj.put('concomitant', PC_Constants.EMPTY_STRING);
                suspectProductInfoObj.put('dose', prescription.PC_Dosage__c);
                suspectProductInfoObj.put('frequency', prescription.PC_Frequency__c);
                suspectProductInfoObj.put('route', PC_Constants.EMPTY_STRING);
                suspectProductInfoObj.put('therapyStartDate', prescription.PC_Rx_Start_Date__c);
                suspectProductInfoObj.put('therapyEndDate', prescription.PC_Rx_End_Date__c);
                suspectProductInfoObj.put('diagnosis', PC_Constants.EMPTY_STRING);
                suspectProductInfoObj.put('prodCompounded', PC_Constants.EMPTY_STRING);
                suspectProductInfoObj.put('prodOTC', PC_Constants.EMPTY_STRING);
                suspectProductInfoObj.put('expirationDate', PC_Constants.EMPTY_STRING);
                suspectProductInfoObj.put('eventAbated', PC_Constants.EMPTY_STRING);
                suspectProductInfoObj.put('eventReappeared', PC_Constants.EMPTY_STRING);
                suspectProductInfoObj.put('product', PC_Constants.EMPTY_STRING);
                suspectProductInfoObj.put('additionalFields', additionalFields);

                return suspectProductInfoObj;
            }

        }catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return null;
    }
    /*********************************************************
    Method Name           : setProductDetails
    Description           : Pre-Populate aeWrapper suspectProductInfo details with Data from Selected Product
    Input Params          : String productId, Map<Object,Object> suspectProductInfoObj
    Return Type           : Map<Object,Object>
    *********************************************************************************/
    @AuraEnabled
    public static Map<Object,Object> setProductDetails(Map<String,Object> fieldsMap, List<String> fsFields,String productId, Map<Object,Object> suspectProductInfoObj, Boolean usePrescription) {
        try {
            if(productId != PC_Constants.UNDEFINED_STRING && productId != null) {
                //Check FLS
                Set<String> productFieldsSet = new Set<String>{'Id','Name',
                        PC_Constants.getQualifiedAPIName('PC_NDC__c'),
                        PC_Constants.getQualifiedAPIName('PC_Strength__c'),
                        PC_Constants.getQualifiedAPIName('PC_Manufacturer__r.Name')
                };
                if(usePrescription != null && usePrescription == false){
                    String additionalProductFields = '';
                    if (fsFields!= null && !fsFields.isEmpty()) {
                        for(string SPField: fsFields){
                            if(fieldsMap != null){
                                String mappedProductField= String.valueOf(fieldsMap.get(SPField));
                                if(String.isNotEmpty(mappedProductField)){
                                    productFieldsSet.add(mappedProductField);
                                }
                            }
                        }
                    }
                }

                List<String> productFieldList = new List<String>();
                productFieldList.addAll(productFieldsSet);
                PC_Database.assertAccess('Product2',PC_Database.Operation.Reading, productFieldList);
                String productFields = String.join(productFieldList, ',');
                String productQuery = 'Select ' +productFields;

                productQuery = productQuery+' from Product2 where id =:productId';
                Product2 product = Database.query (productQuery);

                if(suspectProductInfoObj == null){
                    suspectProductInfoObj = new Map<Object,Object>();
                }
                suspectProductInfoObj.put('productName', product.Name);
                suspectProductInfoObj.put('product', product.Name);
                suspectProductInfoObj.put('productStrength', product.PC_Strength__c);
                suspectProductInfoObj.put('manufacturer', product.PC_Manufacturer__r.Name);
                suspectProductInfoObj.put('ndc', product.PC_NDC__c);

                if(!usePrescription) {
                    Map<Object, Object> additionalFields = new Map<Object, Object>();
                    if (fsFields != null && !fsFields.isEmpty()) {
                        for (String field : fsFields) {
                            if (fieldsMap != null) {
                                String mappedProductField= String.valueOf(fieldsMap.get(field));
                                if(String.isNotEmpty(mappedProductField)){
                                    additionalFields.put(field, product.get(mappedProductField));
                                }
                            }
                        }
                    }
                    suspectProductInfoObj.put('additionalFields', additionalFields);
                }

                return suspectProductInfoObj;
            }

        }catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return null;
    }

    /*********************************************************
Method Name          : addSuspectPrescription
Description               : map values on aeWrapper to the new Suspect Prescription to be added
Input Params            : String aeId, Map<Object,Object> suspectProductInfoObj
Return Type             : PC_Suspect_Prescription__c
*********************************************************************************/
    @AuraEnabled
    public static SuspectPrescriptionWrapper addSuspectPrescription(String aeId,Map<Object,Object> suspectProductInfoObj) {
        try {
            SuspectPrescriptionWrapper spRec = new SuspectPrescriptionWrapper();

            if(aeId != PC_Constants.UNDEFINED_STRING && aeId != null) {
                spRec.aeId = aeId;
            }
            String prescriptionId = (String)suspectProductInfoObj.get('prescription');
            if(prescriptionId != null && prescriptionId != PC_Constants.EMPTY_STRING && prescriptionId != PC_Constants.PC_NONE_PICKLISTVALUE){
                //Check FLS
                List<String> fields = new List<String>{'Name'};
                PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Prescription__c'),PC_Database.Operation.Reading, fields);

                spRec.prescription = [Select Name From PC_Prescription__c Where Id =:prescriptionId Limit 1].Name;
            }
            spRec.prescriptionId = prescriptionId;
            spRec.product = (String)suspectProductInfoObj.get('product');
            spRec.productName = (String)suspectProductInfoObj.get('productName');
            spRec.ndc = (String)suspectProductInfoObj.get('ndc');
            spRec.lot = (String)suspectProductInfoObj.get('lot');
            spRec.productStrength = (String)suspectProductInfoObj.get('productStrength');
            spRec.manufacturer = (String)suspectProductInfoObj.get('manufacturer');
            spRec.concomitant = (String)suspectProductInfoObj.get('concomitant');
            spRec.dose = (String)suspectProductInfoObj.get('dose');
            spRec.frequency = (String)suspectProductInfoObj.get('frequency');
            spRec.route = (String)suspectProductInfoObj.get('route');
            spRec.diagnosis = (String)suspectProductInfoObj.get('diagnosis');
            spRec.prodCompounded = (String)suspectProductInfoObj.get('prodCompounded');
            spRec.eventAbated    = (String)suspectProductInfoObj.get('eventAbated');
            spRec.prodOTC = (String)suspectProductInfoObj.get('prodOTC');
            spRec.eventReappeared = (String)suspectProductInfoObj.get('eventReappeared');
            if(suspectProductInfoObj.get('therapyStartDate') != PC_Constants.EMPTY_STRING && suspectProductInfoObj.get('therapyStartDate') != null){
                spRec.therapyStartDate = Date.valueOf((String)suspectProductInfoObj.get('therapyStartDate'));
            }
            if(suspectProductInfoObj.get('therapyEndDate') != PC_Constants.EMPTY_STRING && suspectProductInfoObj.get('therapyEndDate') != null){
                spRec.therapyEndDate = Date.valueOf((String)suspectProductInfoObj.get('therapyEndDate'));
            }
            if(suspectProductInfoObj.get('expirationDate') != PC_Constants.EMPTY_STRING && suspectProductInfoObj.get('expirationDate') != null){
                spRec.expirationDate = Date.valueOf((String)suspectProductInfoObj.get('expirationDate'));
            }
            return spRec;

        }catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return null;
    }

    /*********************************************************
    Method Name          : getRelatedPrescriptions
    Description          : fetches Field Labels of Suspect Prescription Fields on Suspect Products Tab
    Input Params         : caseId
    Return Type          : FieldLabels Wrapper
    *********************************************************************************/
    public static List<PicklistWrapper> getRelatedPrescriptions(String caseId){
        PicklistWrapper picklistObj ;
        List<PicklistWrapper> fieldValueWrapperList = new List<PicklistWrapper>();
        //Check FLS
        List<String> fields = new List<String>{'Id','Name'};
        PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Prescription__c'),PC_Database.Operation.Reading, fields);

        List<PC_Prescription__c> prescriptionList = new List<PC_Prescription__c>();

        if(caseId != null && caseId != ''){
            prescriptionList =[Select Id,Name FROM PC_Prescription__c WHERE PC_Program_Case__c=:caseId ORDER BY CreatedDate DESC];
        }

        for (PC_Prescription__c prescription : prescriptionList) {
            picklistObj = new PicklistWrapper();
            picklistObj.label = prescription.Name;
            picklistObj.value = prescription.Id;
            fieldValueWrapperList.add(picklistObj);
        }
        return fieldValueWrapperList;
    }

    /*********************************************************
    Method Name          : getRelatedSuspectPrescriptions
    Description          : fetches Suspect Prescription Records related to Adverse Event
    Input Params         : Adverse Event Id
    Return Type          : SuspectPrescriptionWrapper Wrapper
    *********************************************************************************/
    public static List<SuspectPrescriptionWrapper> getRelatedSuspectPrescriptions(String aeId,String fieldSetName){
        try {
            if(aeId != PC_Constants.UNDEFINED_STRING && aeId != null){
                SuspectPrescriptionWrapper suspectPresObj ;
                List<SuspectPrescriptionWrapper> susPresWrapperList = new List<SuspectPrescriptionWrapper>();

                List<String> presFields = new List<String>{'Id','Name'};
                PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Prescription__c'),PC_Database.Operation.Reading, presFields);

                //Check FLS
                Set<String> suspectPresFieldsSet = new Set<String>{'Id','Name',
                        PC_Constants.getQualifiedAPIName('PC_Prescription__c'),
                        PC_Constants.getQualifiedAPIName('PC_Product__c'),
                        PC_Constants.getQualifiedAPIName('PC_Product_Name__c'),
                        PC_Constants.getQualifiedAPIName('PC_Product_Manufacturer__c'),
                        PC_Constants.getQualifiedAPIName('PC_Drug_NDC__c'),
                        PC_Constants.getQualifiedAPIName('PC_Product_Lot__c'),
                        PC_Constants.getQualifiedAPIName('PC_Dose__c'),
                        PC_Constants.getQualifiedAPIName('PC_Frequency__c'),
                        PC_Constants.getQualifiedAPIName('PC_Route_of_Administration__c'),
                        PC_Constants.getQualifiedAPIName('PC_Therapy_Start_Date__c'),
                        PC_Constants.getQualifiedAPIName('PC_Product_Strength__c'),
                        PC_Constants.getQualifiedAPIName('PC_Indication_for_Product_Use__c'),
                        PC_Constants.getQualifiedAPIName('PC_Product_Compounded__c'),
                        PC_Constants.getQualifiedAPIName('PC_Product_OTC__c'),
                        PC_Constants.getQualifiedAPIName('PC_Expiration_Date__c'),
                        PC_Constants.getQualifiedAPIName('PC_Concomitant_Medical_Products__c'),
                        PC_Constants.getQualifiedAPIName('PC_Abated_After_Use_Stopped_or_Reduced__c'),
                        PC_Constants.getQualifiedAPIName('PC_Event_Reappeared_After_Reintroduction__c'),
                        PC_Constants.getQualifiedAPIName('PC_Therapy_End_Date__c')
                };
                List<String> fsFields = new List<String>();
                if(string.isNotEmpty(fieldSetName)){
                    fsFields = PC_FieldSetController.getFieldsByName(PC_Constants.PC_SUSPECT_PRESCRIPTION_OBJECT, fieldSetName);
                    if (fsFields!= null && !fsFields.isEmpty()) {
                        suspectPresFieldsSet.addAll(fsFields);
                    }
                }
                List<String> suspectPresFields = new List<String>();
                suspectPresFields.addAll(suspectPresFieldsSet);
                PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Suspect_Prescription__c'),PC_Database.Operation.Reading, suspectPresFields);
                String spFields = String.join(suspectPresFields, ',');

                String spQuery = 'Select ' +spFields;

                spQuery = spQuery+' from PC_Suspect_Prescription__c where PC_Adverse_Event2__c =:aeId';
                List<PC_Suspect_Prescription__c> suspectPrescriptionList = Database.query (spQuery);
                List<String> prescriptionNameList = new List<String>();
                for (PC_Suspect_Prescription__c sp : suspectPrescriptionList) {
                    prescriptionNameList.add(sp.PC_Prescription__c);
                }
                List<PC_Prescription__c> prescriptionList = [Select Id, Name FROM PC_Prescription__c WHERE Name IN:prescriptionNameList];

                Map<String, String> additionalFields;
                for (PC_Suspect_Prescription__c sp : suspectPrescriptionList) {
                    suspectPresObj = new SuspectPrescriptionWrapper();
                    for(PC_Prescription__c pres : prescriptionList){
                        if(sp.PC_Prescription__c == pres.Name){
                            suspectPresObj.prescriptionId = pres.Id;
                        }
                    }
                    additionalFields = new Map<String, String>();
                    if(fsFields != null){
                        for (String field : fsFields) {
                            if(sp.get(field) != null){
                                additionalFields.put(field , string.valueOf(sp.get(field)));
                            }else{
                                additionalFields.put(field , '');
                            }
                        }
                    }
                    suspectPresObj.additionalFields = additionalFields;
                    suspectPresObj.recId = sp.Id;
                    suspectPresObj.name = sp.Name;
                    suspectPresObj.productName = sp.PC_Product_Name__c;
                    suspectPresObj.manufacturer = sp.PC_Product_Manufacturer__c;
                    suspectPresObj.ndc = sp.PC_Drug_NDC__c;
                    suspectPresObj.prescription = sp.PC_Prescription__c;
                    suspectPresObj.product = sp.PC_Product__c;
                    suspectPresObj.productStrength = sp.PC_Product_Strength__c;
                    suspectPresObj.lot =  sp.PC_Product_Lot__c;
                    suspectPresObj.concomitant =  sp.PC_Concomitant_Medical_Products__c;
                    suspectPresObj.dose =  sp.PC_Dose__c;
                    suspectPresObj.frequency =  sp.PC_Frequency__c;
                    suspectPresObj.route =  sp.PC_Route_of_Administration__c;
                    suspectPresObj.therapyStartDate =  sp.PC_Therapy_Start_Date__c;
                    suspectPresObj.therapyEndDate =  sp.PC_Therapy_End_Date__c;
                    suspectPresObj.diagnosis =  sp.PC_Indication_for_Product_Use__c;
                    suspectPresObj.prodCompounded =  sp.PC_Product_Compounded__c;
                    suspectPresObj.prodOTC =  sp.PC_Product_OTC__c;
                    suspectPresObj.expirationDate =  sp.PC_Expiration_Date__c;
                    suspectPresObj.eventAbated =  sp.PC_Abated_After_Use_Stopped_or_Reduced__c;
                    suspectPresObj.eventReappeared =  sp.PC_Event_Reappeared_After_Reintroduction__c;
                    susPresWrapperList.add(suspectPresObj);
                }
                return susPresWrapperList;
            }
        }catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return null;
    }

    public static List<PicklistWrapper> getProdCompoundedOptions(){
        PicklistWrapper picklistObj ;
        List<PicklistWrapper> fieldValueWrapperList = new List<PicklistWrapper>();
        Schema.DescribeFieldResult picklistFieldResult = PC_Suspect_Prescription__c.PC_Product_Compounded__c.getDescribe();
        List<Schema.PicklistEntry> picklistValueList = picklistFieldResult.getPicklistValues();
        for (Schema.PicklistEntry picklistValue : picklistValueList) {
            picklistObj = new PicklistWrapper();
            picklistObj.label = picklistValue.getLabel();
            picklistObj.value = picklistValue.getValue();
            fieldValueWrapperList.add(picklistObj);
        }
        return fieldValueWrapperList;
    }
    public static List<PicklistWrapper> getProdOTCOptions(){
        PicklistWrapper picklistObj ;
        List<PicklistWrapper> fieldValueWrapperList = new List<PicklistWrapper>();
        Schema.DescribeFieldResult picklistFieldResult = PC_Suspect_Prescription__c.PC_Product_OTC__c.getDescribe();
        List<Schema.PicklistEntry> picklistValueList = picklistFieldResult.getPicklistValues();
        for (Schema.PicklistEntry picklistValue : picklistValueList) {
            picklistObj = new PicklistWrapper();
            picklistObj.label = picklistValue.getLabel();
            picklistObj.value = picklistValue.getValue();
            fieldValueWrapperList.add(picklistObj);
        }
        return fieldValueWrapperList;
    }
    public static List<PicklistWrapper> getEventAbatedOptions(){
        PicklistWrapper picklistObj ;
        List<PicklistWrapper> fieldValueWrapperList = new List<PicklistWrapper>();
        Schema.DescribeFieldResult picklistFieldResult = PC_Suspect_Prescription__c.PC_Abated_After_Use_Stopped_or_Reduced__c.getDescribe();
        List<Schema.PicklistEntry> picklistValueList = picklistFieldResult.getPicklistValues();
        for (Schema.PicklistEntry picklistValue : picklistValueList) {
            picklistObj = new PicklistWrapper();
            picklistObj.label = picklistValue.getLabel();
            picklistObj.value = picklistValue.getValue();
            fieldValueWrapperList.add(picklistObj);
        }
        return fieldValueWrapperList;
    }
    public static List<PicklistWrapper> getEventReappearedOptions(){
        PicklistWrapper picklistObj ;
        List<PicklistWrapper> fieldValueWrapperList = new List<PicklistWrapper>();
        Schema.DescribeFieldResult picklistFieldResult = PC_Suspect_Prescription__c.PC_Event_Reappeared_After_Reintroduction__c .getDescribe();
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
    Method Name          : getFieldLabels
    Description               : fetch Field Labels of Suspect Prescription Fields on Suspect Products Tab
    Input Params            : NA
    Return Type             : FieldLabels Wrapper
    *********************************************************************************/
    public static FieldLabels getFieldLabels(){

        FieldLabels fieldlabels = new FieldLabels();
        fieldlabels.suspectPresName = PC_Suspect_Prescription__c.Name.getDescribe().getLabel();
        fieldlabels.prescription = PC_Suspect_Prescription__c.PC_Prescription__c.getDescribe().getLabel();
        fieldlabels.productName = PC_Suspect_Prescription__c.PC_Product_Name__c.getDescribe().getLabel();
        fieldlabels.prodStrength    = PC_Suspect_Prescription__c.PC_Product_Strength__c.getDescribe().getLabel();
        fieldlabels.manufacturer    = PC_Suspect_Prescription__c.PC_Product_Manufacturer__c.getDescribe().getLabel();
        fieldlabels.ndc = PC_Suspect_Prescription__c.PC_Drug_NDC__c.getDescribe().getLabel();
        fieldlabels.lot = PC_Suspect_Prescription__c.PC_Product_Lot__c.getDescribe().getLabel();
        fieldlabels.concomitant = PC_Suspect_Prescription__c.PC_Concomitant_Medical_Products__c.getDescribe().getLabel();
        fieldlabels.dose = PC_Suspect_Prescription__c.PC_Dose__c.getDescribe().getLabel();
        fieldlabels.frequency = PC_Suspect_Prescription__c.PC_Frequency__c.getDescribe().getLabel();
        fieldlabels.route = PC_Suspect_Prescription__c.PC_Route_of_Administration__c.getDescribe().getLabel();
        fieldlabels.therapyStartDate = PC_Suspect_Prescription__c.PC_Therapy_Start_Date__c.getDescribe().getLabel();
        fieldlabels.therapyEndDate = PC_Suspect_Prescription__c.PC_Therapy_End_Date__c.getDescribe().getLabel();
        fieldlabels.diagnosis = PC_Suspect_Prescription__c.PC_Indication_for_Product_Use__c.getDescribe().getLabel();
        fieldlabels.prodCompounded = PC_Suspect_Prescription__c.PC_Product_Compounded__c.getDescribe().getLabel();
        fieldlabels.prodOTC = PC_Suspect_Prescription__c.PC_Product_OTC__c.getDescribe().getLabel();
        fieldlabels.expirationDate = PC_Suspect_Prescription__c.PC_Expiration_Date__c.getDescribe().getLabel();
        fieldlabels.eventAbated = PC_Suspect_Prescription__c.PC_Abated_After_Use_Stopped_or_Reduced__c.getDescribe().getLabel();
        fieldlabels.eventReappeared = PC_Suspect_Prescription__c.PC_Event_Reappeared_After_Reintroduction__c.getDescribe().getLabel();
        fieldlabels.inquiryDescription = PC_AdverseEvent2__c.PC_InquiryDescription__c.getDescribe().getLabel();

        return fieldlabels;
    }

    public inherited sharing class FieldLabels {
        @AuraEnabled public String suspectPresName { get; set; }
        @AuraEnabled public String prescription { get; set; }
        @AuraEnabled public String productName { get; set; }
        @AuraEnabled public String prodStrength { get; set; }
        @AuraEnabled public String manufacturer { get; set; }
        @AuraEnabled public String ndc { get; set; }
        @AuraEnabled public String lot { get; set; }
        @AuraEnabled public String concomitant { get; set; }
        @AuraEnabled public String dose { get; set; }
        @AuraEnabled public String frequency { get; set; }
        @AuraEnabled public String route { get; set; }
        @AuraEnabled public String therapyStartDate { get; set; }
        @AuraEnabled public String therapyEndDate { get; set; }
        @AuraEnabled public String diagnosis { get; set; }
        @AuraEnabled public String prodCompounded { get; set; }
        @AuraEnabled public String prodOTC { get; set; }
        @AuraEnabled public String expirationDate { get; set; }
        @AuraEnabled public String eventAbated { get; set; }
        @AuraEnabled public String eventReappeared { get; set; }
        @AuraEnabled public String inquiryDescription { get; set; }

        public FieldLabels() {
        }
    }

    public inherited sharing class SuspectPrescriptionWrapper {
        @AuraEnabled public String recId {get; set;}
        @AuraEnabled public String name {get; set;}
        @AuraEnabled public String prescription {get; set;}
        @AuraEnabled public String product {get; set;}
        @AuraEnabled public String productName {get; set;}
        @AuraEnabled public String manufacturer {get; set;}
        @AuraEnabled public String ndc {get; set;}
        @AuraEnabled public String lot {get; set;}
        @AuraEnabled public String productStrength {get; set;}
        @AuraEnabled public String concomitant {get; set;}
        @AuraEnabled public String dose {get; set;}
        @AuraEnabled public String frequency {get; set;}
        @AuraEnabled public String route {get; set;}
        @AuraEnabled public String diagnosis {get; set;}
        @AuraEnabled public String prodCompounded {get; set;}
        @AuraEnabled public String eventAbated {get; set;}
        @AuraEnabled public String prodOTC {get; set;}
        @AuraEnabled public String eventReappeared {get; set;}
        @AuraEnabled public Date therapyStartDate {get; set;}
        @AuraEnabled public String formatedTherapyStartDate {set; get;}
        @AuraEnabled public Date therapyEndDate {get; set;}
        @AuraEnabled public String formatedTherapyEndDate {set; get;}
        @AuraEnabled public Date expirationDate {get;set;}
        @AuraEnabled public String formatedExpirationDate {set; get;}
        @AuraEnabled public String aeId {get; set;}
        @AuraEnabled public String prescriptionId {get; set;}
        @AuraEnabled public Map<String,String> additionalFields {get; set;}

        public SuspectPrescriptionWrapper(){
        }
    }


    public inherited sharing class PicklistWrapper {
        @AuraEnabled public String label {get; set;}
        @AuraEnabled public String value {get; set;}

        public PicklistWrapper(){
        }
    }

    public inherited sharing class AdditionalFieldsConfig {
        @AuraEnabled public String fieldSetName {get; set;}
        @AuraEnabled public String objectAPIName {get; set;}
        @AuraEnabled public Map<String,Object> fieldsMap {get; set;}
        @AuraEnabled public List<String> fsFields { get; set; }

        public AdditionalFieldsConfig(){
            fieldSetName = '';
            objectAPIName = '';
            fieldsMap = new Map<String,Object>();
            fsFields = new List<String>();
        }
    }

    public inherited sharing class SuspectProductFormData{

        @AuraEnabled public FieldLabels fieldLabels;
        @AuraEnabled public List<SuspectPrescriptionWrapper> suspectPrescriptions;
        @AuraEnabled public AdditionalFieldsConfig additionalFieldsConfig;
        @AuraEnabled public List<PicklistWrapper> prescriptions;
        @AuraEnabled public List<PicklistWrapper> prodCompoundedOptions;
        @AuraEnabled public List<PicklistWrapper> prodOTCOptions;
        @AuraEnabled public List<PicklistWrapper> eventAbatedOptions;
        @AuraEnabled public List<PicklistWrapper> eventReappearedOptions;

    }

    /********************************************************************************
    Class Name           : SuspectProduct_Exception
    Description          : Holds the exception related to Suspect Product on Adverse Event
    *********************************************************************************/
    public inherited sharing class SuspectProduct_Exception extends Exception{
        public String errorMessage;
        public String errorCode;

        public SuspectProduct_Exception(String message, String errCode){
            this.errorMessage=message;
            this.errorCode=errCode;
        }
    }

}