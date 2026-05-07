/**
 * Created by havalakki on 12/12/2018.
 */
/************************************************************************************************************************
  Modification Log:
  -----------------------------------------------------------------------------
  Developer             Date                        Description
  -----------------------------------------------------------------------------
  Hitha Avalakki       2018-12-12                   New controller class to handle conversion of VF page to PDF
  Hitha Avalakki       2019-02-20                   [PC-4384] Added a catch block to handle an exception explicitly thrown in case fieldset name is blank or null
  Shishir Bansal       2019-7-20                    [PC-5298]  Added methods for date formatting as per the User input
                                                    in Patient Connect Settings
  Shishir Bansal       2019-8-28                    Added AdverseEvent_Exception  handling class [PC-5298]
  Shishir Bansal       19 Nov 2019                 [PC-5731] added null check if there are no fields added on fieldset
  Shishir Bansal       06-Dec-2019                 [PC-5792] Avoid hardcoding of string variable
  Haritha Reddy        19-Dec-2019                 [PC-5723] Added new Field 'Health Care Professional'
  Haritha Reddy        16-Jan-2020                 [PC-5600] Added logic to display Additional Suspect Prescription Fields
  Vijay Kashikar       21-Jan-21                   [PC-7102] Added sharing clause
 ************************************************************************************************************************/
public with sharing class PC_AdverseEvent_PDF_Controller {

    public Datetime dateTimeVal{get;set;}
    public String gmtDateTimeVal{get;set;}
    public String eventType{get;set;}
    public Map<Object,Object> adverseEventPatInfoMap{get;set;}
    public List<String> aePatRaceValList{get;set;}
    public List<String> aeAEEventOutValList{get;set;}
    public List<String> aeManuReportSourceValList{get;set;}
    public List<String> aeManuReportTypeValList{get;set;}
    public String adverseEventId{get;set;}
    public String fieldsetName{get;set;}
    public String spAdditionalfsName{get;set;}
    public Boolean hideAdditionalInfoTab{get;set;}
    public Map<String,String> fieldLabelsMap{get;set;}
    public List<SelectOption> ageTypeOptions{get;set;}
    public Map<Object,Object> adverseEventPDFInfo{get;set;}
    public Map<String,String> adverseEventPDFLabels{get;set;}
    public Map<String,String> aeSuspectProdFieldLabelsMap{get;set;}
    public List<PC_AE_SuspectProductsRendererController.SuspectPrescriptionWrapper> adverseEventSuspectProdInfoWrapList{get;set;}
    public Map<Object,Object> aeInitialReportPDFInfo{get;set;}
    public Map<String,String> aeInitialReportPDFLabels{get;set;}
    public Map<Object,Object> aeManuPDFInfo{get;set;}
    public Map<String,String> aeManuPDFLabels{get;set;}
    public Map<Object,Object> aeAddInfoPDFInfo{get;set;}
    public Map<Object,Object> aeAddInfoPDFLabels{get;set;}
    public List<String> aeAddInfoPDFFieldApiNames{get;set;}
    public Map<Object,Object> spAddInfoPDFInfo{get;set;}
    public Map<Object,Object> spAddInfoPDFLabels{get;set;}
    public List<String> spAddInfoPDFFieldApiNames{get;set;}
    public Boolean isError{get;set;}
    public String errorLogRecordName{get;set;}
    public String errorMessage{get;set;}
    public static String dateFormat{get;set;}


    public PC_AdverseEvent_PDF_Controller(ApexPages.StandardController stdController){

    }

    public void fetchPDFData() {
        try{
            dateFormat = PC_SYSTEM.getPatientConnectSetting(PC_Constants.PC_AE_DOWNLOAD_DATEFORMAT_NAME,
                    null) ;
            dateTimeVal=Datetime.now();
           // gmtDateTimeVal=dateTimeVal.formatGMT('MMM d, y H:m a')+' GMT';

            // code to check if the dateformat is entered blank
            if(String.isBlank(dateFormat)) {
                AdverseEvent_PDF_Exception dateFormatNullException  = new AdverseEvent_PDF_Exception();
                dateFormatNullException.errorMessage = Label.PC_AdverseEvent_DownloadPDF_DateFormatWarning;
                dateFormatNullException.errorCode = null;

                throw dateFormatNullException;

            }

            gmtDateTimeVal=PC_Utility.getFormattedDate(dateTimeVal.date(), dateFormat) +' '+
                                 String.valueOf(gmtDateTimeVal=dateTimeVal.formatGMT('H:m a')+' GMT');
            adverseEventId=System.currentPageReference().getParameters().get('adverseEventId');
            fieldsetName=PC_Constants.EMPTY_STRING;
            spAdditionalfsName = PC_Constants.EMPTY_STRING;
            isError=false;
            errorLogRecordName=PC_Constants.EMPTY_STRING;
            errorMessage=PC_Constants.EMPTY_STRING;

            getAdverseEventPatientInfo();
            getPatInfoLabels();
            getAgeTypeOptions();
            getAdverseEventAEInfo();
            getAdverseEventPDFLabels();
            getAeSuspectProdFieldLabelsMap();
            getAeInitialReportPDFInfo();
            getAeInitialReportPDFLabels();
            getAeManuPDFInfo();
            getAeManuPDFLabels();

            eventType = PC_AdverseEventMenuController.getUserInputTypeValue(adverseEventId);

            PC_AdverseEventsController.AdverseEventConfig adverseEventConfig=PC_AdverseEventsController.getAdverseEventConfigData(adverseEventId);
            hideAdditionalInfoTab=adverseEventConfig.hideAdditionalInfoSection;
            fieldsetName=adverseEventConfig.fieldsetName;

            if(!adverseEventConfig.hideAdditionalInfoSection){
                if(!String.isBlank(adverseEventConfig.fieldsetName) && adverseEventConfig.fieldsetName != PC_Constants.UNDEFINED_STRING){
                    getAeAddInfoPDFInfoAndLabels();
                }
            }
            PC_AE_SuspectProductsRendererController.AdditionalFieldsConfig spAdditionalInfoConfig =
                    PC_AE_SuspectProductsRendererController.getAdditionalFieldsConfigData(adverseEventConfig.usePrescription);
            spAdditionalfsName = spAdditionalInfoConfig.fieldSetName;
            getAESuspectProdInfoMap();
            if(!String.isBlank(spAdditionalfsName) && spAdditionalfsName != PC_Constants.UNDEFINED_STRING){
                getSPAdditionalInfoPDFInfoAndLabels();
            }

        }catch (PC_FieldSetController.FieldSetNullException fsNullException){
            isError=true;
            errorMessage=fsNullException.errorMessage;
            fsNullException.setMessage(fsNullException.errorMessage);
            errorLogRecordName=PC_Utility.createExceptionLog(fsNullException,PC_Constants.ERROR);
        }catch(AdverseEvent_PDF_Exception ex){
            isError=true;
            errorMessage=ex.errorMessage;
            ex.setMessage(ex.errorMessage);
            errorLogRecordName=PC_Utility.createExceptionLog(ex,PC_Constants.ERROR);
        }
        catch (Exception ex){
            isError=true;
            errorMessage=ex.getMessage();
            errorLogRecordName=PC_Utility.createExceptionLog(ex,PC_Constants.ERROR);
        }
    }

        /*********************************************************************************
        Method Name    : getPatInfoLabels
        Description    : method used to fetch labels of field related to Adverse event's Patient Information Menu
        Return Type    : Void
        Parameter      : None
        *********************************************************************************/
    public void getPatInfoLabels(){
        fieldLabelsMap=new Map<String, String>();
        fieldLabelsMap.put('patId',PC_AdverseEvent__c.PC_Patient_Identifier__c.getDescribe().getLabel());
        fieldLabelsMap.put('gender',PC_AdverseEvent__c.PC_Gender__c.getDescribe().getLabel());
        fieldLabelsMap.put('ethnicity',PC_AdverseEvent__c.PC_Ethnicity__c.getDescribe().getLabel());
        fieldLabelsMap.put('dob',PC_AdverseEvent__c.PC_Date_of_Birth__c.getDescribe().getLabel());
        fieldLabelsMap.put('age',PC_AdverseEvent__c.PC_Age__c.getDescribe().getLabel());
        fieldLabelsMap.put('weight',PC_AdverseEvent__c.PC_Weight__c.getDescribe().getLabel());
        fieldLabelsMap.put('weightType',PC_AdverseEvent__c.PC_Weight_Unit__c.getDescribe().getLabel());
        fieldLabelsMap.put('ageType',PC_AdverseEvent__c.PC_Age_Unit__c.getDescribe().getLabel());
        fieldLabelsMap.put('race',PC_AdverseEvent__c.PC_Race__c.getDescribe().getLabel());
        fieldLabelsMap.put('eventType',PC_AdverseEvent__c.PC_EventType__c.getDescribe().getLabel());
    }

    /*********************************************************************************
    Method Name    : getAgeTypeOptions
    Description    : method used to fetch labels of picklist values for age type field
    Return Type    : Void
    Parameter      : None
    *********************************************************************************/
    public void getAgeTypeOptions(){
        ageTypeOptions=new List<SelectOption>();
        List<PC_AE_PatientInfoRendererController.PicklistWrapper> ageTypeOptionsList=PC_AE_PatientInfoRendererController.getAgeTypePicklistValues();
        if(ageTypeOptionsList!=null && !ageTypeOptionsList.isEmpty()){
            for(PC_AE_PatientInfoRendererController.PicklistWrapper picklistWrapper: ageTypeOptionsList){
                ageTypeOptions.add(new SelectOption(picklistWrapper.label,picklistWrapper.value));
            }
        }

    }

    /*********************************************************************************
    Method Name    : getAdverseEventPatientInfo
    Description    : method used to fetch Patient information menu of Adverse event record
    Return Type    : Void
    Parameter      : None
    *********************************************************************************/
    public void getAdverseEventPatientInfo(){
        adverseEventPatInfoMap=new Map<Object, Object>();
        adverseEventPatInfoMap=PC_AE_PatientInfoRendererController.fetchDataFromAE(adverseEventId,adverseEventPatInfoMap);

        if( adverseEventPatInfoMap.containsKey('dob') && adverseEventPatInfoMap.get('dob') != null) {

            Date dateOfBirth = Date.valueOf(adverseEventPatInfoMap.get('dob'));
            String returnDateVal = PC_Utility.getFormattedDate(dateOfBirth, dateFormat);
            if(returnDateVal !=null) {
                adverseEventPatInfoMap.put('dob', returnDateVal);
            }
        }
        aePatRaceValList=new List<String>();

        if(adverseEventPatInfoMap!=null && !adverseEventPatInfoMap.isEmpty()){

            for(Object key: adverseEventPatInfoMap.keySet()){
                if(adverseEventPatInfoMap.get(key)==null){
                    adverseEventPatInfoMap.put(key,PC_Constants.EMPTY_STRING);
                }
            }

            String aeRaceStr=(String)adverseEventPatInfoMap.get('race');
            aePatRaceValList=splitString(aeRaceStr);

        }

    }

    /*********************************************************************************
    Method Name    : getAdverseEventPatientInfo
    Description    : method used to fetch Adverse event menu information of Adverse event record
    Return Type    : Void
    Parameter      : None
    *********************************************************************************/
    public void getAdverseEventAEInfo(){
        aeAEEventOutValList=new List<String>();
        adverseEventPDFInfo=new Map<Object, Object>();
        adverseEventPDFInfo=PC_AE_AdverseEventRendererController.loadDataFromAE(adverseEventId,adverseEventPDFInfo);
        String dateCasting = PC_Constants.EMPTY_STRING;
        String returnDateVal ;


        if(adverseEventPDFInfo.containsKey('dateOfTheReport') && adverseEventPDFInfo.get('dateOfTheReport') != null) {
            dateCasting  = String.valueOf(adverseEventPDFInfo.get('dateOfTheReport'));
            Date dateOfTheReport = Date.valueOf(dateCasting);

            returnDateVal = PC_Utility.getFormattedDate(dateOfTheReport, dateFormat);
            if(returnDateVal !=null) {
                adverseEventPDFInfo.put('dateOfTheReport',returnDateVal);
            }
        }
        if(adverseEventPDFInfo.containsKey('eventOnsetDate') && adverseEventPDFInfo.get('eventOnsetDate') != null) {
            dateCasting  = String.valueOf(adverseEventPDFInfo.get('eventOnsetDate'));
            Date eventOnsetDate = Date.valueOf(dateCasting);
            returnDateVal = PC_Utility.getFormattedDate(eventOnsetDate, dateFormat);
            if(returnDateVal !=null) {
                adverseEventPDFInfo.put('eventOnsetDate', returnDateVal);
            }
        }
       if(adverseEventPDFInfo.containsKey('endDate') && adverseEventPDFInfo.get('endDate') != null) {
           dateCasting  = String.valueOf(adverseEventPDFInfo.get('endDate'));
           Date endDate = Date.valueOf(dateCasting);
           returnDateVal = PC_Utility.getFormattedDate(endDate, dateFormat);
           if(returnDateVal != null) {
               adverseEventPDFInfo.put('endDate', returnDateVal);
           }
       }
       if(adverseEventPDFInfo.containsKey('dateofDeath') && adverseEventPDFInfo.get('dateofDeath') != null) {
           dateCasting  = String.valueOf(adverseEventPDFInfo.get('dateofDeath'));
           Date dateofDeath = Date.valueOf(dateCasting);
           returnDateVal = PC_Utility.getFormattedDate(dateofDeath, dateFormat);
           if(returnDateVal !=null) {
               adverseEventPDFInfo.put('dateofDeath', returnDateVal);
           }
       }

       if(adverseEventPDFInfo!=null && !adverseEventPDFInfo.isEmpty()){
           for(Object key: adverseEventPDFInfo.keySet()){
               if(adverseEventPDFInfo.get(key)==null){
                   adverseEventPDFInfo.put(key,PC_Constants.EMPTY_STRING);
               }
           }

           String aeOutcomeStr=(String)adverseEventPDFInfo.get('outcome');
           aeAEEventOutValList=splitString(aeOutcomeStr);
       }

    }

    /*********************************************************************************
    Method Name    : getAdverseEventPatientInfo
    Description    : method used to fetch Adverse event menu field labels of Adverse event record
    Return Type    : Void
    Parameter      : None
    *********************************************************************************/
    public void getAdverseEventPDFLabels(){
        adverseEventPDFLabels=new Map<String, String>();
        adverseEventPDFLabels.put('dateOfTheReport',PC_AdverseEvent__c.PC_Date_of_the_Report__c.getDescribe().getLabel());
        adverseEventPDFLabels.put('eventOnsetDate',PC_AdverseEvent__c.PC_Event_Onset_Date__c.getDescribe().getLabel());
        adverseEventPDFLabels.put('description',PC_AdverseEvent__c.PC_Description__c.getDescribe().getLabel());
        adverseEventPDFLabels.put('laboratoryData',PC_AdverseEvent__c.PC_Laboratory_Data__c.getDescribe().getLabel());
        adverseEventPDFLabels.put('otherReleventHistory',PC_AdverseEvent__c.PC_Other_Relevent_History__c.getDescribe().getLabel());
        adverseEventPDFLabels.put('eventVerbatim',PC_AdverseEvent__c.PC_Event_Verbatim__c.getDescribe().getLabel());
        adverseEventPDFLabels.put('outcome',PC_AdverseEvent__c.PC_Event_Outcome__c.getDescribe().getLabel());
        adverseEventPDFLabels.put('dateofDeath',PC_AdverseEvent__c.PC_Death_Date__c.getDescribe().getLabel());
        adverseEventPDFLabels.put('eventCoding_SOC',PC_AdverseEvent__c.PC_Event_SOC_Code__c.getDescribe().getLabel());
        adverseEventPDFLabels.put('eventCoding_HLGT',PC_AdverseEvent__c.PC_Event_HLGT_Code__c.getDescribe().getLabel());
        adverseEventPDFLabels.put('eventCoding_HLT',PC_AdverseEvent__c.PC_Event_HLT_Code__c.getDescribe().getLabel());
        adverseEventPDFLabels.put('eventCoding_PT',PC_AdverseEvent__c.PC_Event_PT_Code__c.getDescribe().getLabel());
        adverseEventPDFLabels.put('eventCoding_LLT',PC_AdverseEvent__c.PC_Event_LLT_Code__c.getDescribe().getLabel());
    }

    /*********************************************************************************
    Method Name    : getAdverseEventPatientInfo
    Description    : method used to fetch Suspect Product menu field labels of Adverse event record
    Return Type    : Void
    Parameter      : None
    *********************************************************************************/
    public void getAeSuspectProdFieldLabelsMap(){
        aeSuspectProdFieldLabelsMap=new Map<String, String>();
        aeSuspectProdFieldLabelsMap.put('suspectPresName',PC_Suspect_Prescription__c.Name.getDescribe().getLabel());
        aeSuspectProdFieldLabelsMap.put('prescription',PC_Suspect_Prescription__c.PC_Prescription__c.getDescribe().getLabel());
        aeSuspectProdFieldLabelsMap.put('product',PC_Suspect_Prescription__c.PC_Product_Name__c.getDescribe().getLabel());
        aeSuspectProdFieldLabelsMap.put('prodStrength',PC_Suspect_Prescription__c.PC_Product_Strength__c.getDescribe().getLabel());
        aeSuspectProdFieldLabelsMap.put('manufacturer',PC_Suspect_Prescription__c.PC_Product_Manufacturer__c.getDescribe().getLabel());
        aeSuspectProdFieldLabelsMap.put('ndc',PC_Suspect_Prescription__c.PC_Drug_NDC__c.getDescribe().getLabel());
        aeSuspectProdFieldLabelsMap.put('lot',PC_Suspect_Prescription__c.PC_Product_Lot__c.getDescribe().getLabel());
        aeSuspectProdFieldLabelsMap.put('concomitant',PC_Suspect_Prescription__c.PC_Concomitant_Medical_Products__c.getDescribe().getLabel());
        aeSuspectProdFieldLabelsMap.put('dose',PC_Suspect_Prescription__c.PC_Dose__c.getDescribe().getLabel());
        aeSuspectProdFieldLabelsMap.put('frequency',PC_Suspect_Prescription__c.PC_Frequency__c.getDescribe().getLabel());
        aeSuspectProdFieldLabelsMap.put('route',PC_Suspect_Prescription__c.PC_Route_of_Administration__c.getDescribe().getLabel());
        aeSuspectProdFieldLabelsMap.put('therapyStartDate',PC_Suspect_Prescription__c.PC_Therapy_Start_Date__c.getDescribe().getLabel());
        aeSuspectProdFieldLabelsMap.put('therapyEndDate',PC_Suspect_Prescription__c.PC_Therapy_End_Date__c.getDescribe().getLabel());
        aeSuspectProdFieldLabelsMap.put('diagnosis',PC_Suspect_Prescription__c.PC_Indication_for_Product_Use__c.getDescribe().getLabel());
        aeSuspectProdFieldLabelsMap.put('prodCompounded',PC_Suspect_Prescription__c.PC_Product_Compounded__c.getDescribe().getLabel());
        aeSuspectProdFieldLabelsMap.put('prodOTC',PC_Suspect_Prescription__c.PC_Product_OTC__c.getDescribe().getLabel());
        aeSuspectProdFieldLabelsMap.put('expirationDate',PC_Suspect_Prescription__c.PC_Expiration_Date__c.getDescribe().getLabel());
        aeSuspectProdFieldLabelsMap.put('eventAbated',PC_Suspect_Prescription__c.PC_Abated_After_Use_Stopped_or_Reduced__c.getDescribe().getLabel());
        aeSuspectProdFieldLabelsMap.put('eventReappeared',PC_Suspect_Prescription__c.PC_Event_Reappeared_After_Reintroduction__c.getDescribe().getLabel());

    }

    /*********************************************************************************
    Method Name    : getAdverseEventPatientInfo
    Description    : method used to fetch Suspect Product menu field values of Adverse event record
    Return Type    : Void
    Parameter      : None
    *********************************************************************************/
    public void getAESuspectProdInfoMap(){

        adverseEventSuspectProdInfoWrapList=new List<PC_AE_SuspectProductsRendererController.SuspectPrescriptionWrapper>();
        adverseEventSuspectProdInfoWrapList=PC_AE_SuspectProductsRendererController.getRelatedSuspectPrescriptions(
                adverseEventId,spAdditionalfsName);
        String returnDateVal ;
        if(adverseEventSuspectProdInfoWrapList.size()>0) {
            for (PC_AE_SuspectProductsRendererController.SuspectPrescriptionWrapper suspectPrescription:
                                                                                  adverseEventSuspectProdInfoWrapList) {

                    if(String.isNotBlank(String.valueOf(suspectPrescription.expirationDate))){
                        returnDateVal = PC_Utility.getFormattedDate(suspectPrescription.expirationDate, dateFormat);
                        if(returnDateVal !=null) {
                            suspectPrescription.formatedExpirationDate =returnDateVal;
                        }
                    }
                    if(String.isNotBlank(String.valueOf(suspectPrescription.therapyStartDate))){
                        returnDateVal = PC_Utility.getFormattedDate(suspectPrescription.therapyStartDate, dateFormat);
                        if(returnDateVal !=null) {
                            suspectPrescription.formatedTherapyStartDate =returnDateVal;
                        }
                    }
                   if(String.isNotBlank(String.valueOf(suspectPrescription.therapyEndDate))){
                       returnDateVal = PC_Utility.getFormattedDate(suspectPrescription.therapyEndDate, dateFormat);
                       if(returnDateVal !=null) {
                           suspectPrescription.formatedTherapyEndDate =returnDateVal;
                       }
                    }
            }
        }
    }

    /*********************************************************************************
    Method Name    : getAdverseEventPatientInfo
    Description    : method used to fetch Initial Report menu field values of Adverse event record
    Return Type    : Void
    Parameter      : None
    *********************************************************************************/
    public void getAeInitialReportPDFInfo(){
        aeInitialReportPDFInfo=new Map<Object, Object>();
        aeInitialReportPDFInfo=PC_AE_InitialReporterRendererController.getDataFromAE(adverseEventId,aeInitialReportPDFInfo);

        if(aeInitialReportPDFInfo!=null && !aeInitialReportPDFInfo.isEmpty()){
            for(Object key: aeInitialReportPDFInfo.keySet()){
                if(aeInitialReportPDFInfo.get(key)==null){
                    aeInitialReportPDFInfo.put(key,PC_Constants.EMPTY_STRING);
                }
            }
        }
    }

    /*********************************************************************************
    Method Name    : getAdverseEventPatientInfo
    Description    : method used to fetch Initial Report menu field labels of Adverse event record
    Return Type    : Void
    Parameter      : None
    *********************************************************************************/
    public void getAeInitialReportPDFLabels(){
        aeInitialReportPDFLabels=new Map<String, String>();
        aeInitialReportPDFLabels.put('firstName', PC_AdverseEvent__c.PC_Reporter_First_Name__c.getDescribe().getLabel());
        aeInitialReportPDFLabels.put('lastName', PC_AdverseEvent__c.PC_Reporter_Last_Name__c.getDescribe().getLabel());
        aeInitialReportPDFLabels.put('address', PC_AdverseEvent__c.PC_ReporterAddress__c.getDescribe().getLabel());
        aeInitialReportPDFLabels.put('city', PC_AdverseEvent__c.PC_Reporter_City__c.getDescribe().getLabel());
        aeInitialReportPDFLabels.put('state', PC_AdverseEvent__c.PC_Reporter_State__c.getDescribe().getLabel());
        aeInitialReportPDFLabels.put('country', PC_AdverseEvent__c.PC_Reporter_Country__c.getDescribe().getLabel());
        aeInitialReportPDFLabels.put('zip', PC_AdverseEvent__c.PC_Reporter_Zip_Code__c.getDescribe().getLabel());
        aeInitialReportPDFLabels.put('email', PC_AdverseEvent__c.PC_Reporter_Email__c.getDescribe().getLabel());
        aeInitialReportPDFLabels.put('phone', PC_AdverseEvent__c.PC_Reporter_Phone__c.getDescribe().getLabel());
        aeInitialReportPDFLabels.put('occupation', PC_AdverseEvent__c.PC_Adverse_Event_Reporter__c.getDescribe().getLabel());
        aeInitialReportPDFLabels.put('IRalsoSentReportToFDA', PC_AdverseEvent__c.PC_Ini_Reporter_Also_Sent_Report_to_FDA__c.getDescribe().getLabel());
        aeInitialReportPDFLabels.put('healthCareProfessional', PC_AdverseEvent2__c.PC_HealthCareProfessional__c.getDescribe().getLabel());

    }

    /*********************************************************************************
    Method Name    : getAdverseEventPatientInfo
    Description    : method used to fetch Manufacturer menu field values of Adverse event record
    Return Type    : Void
    Parameter      : None
    *********************************************************************************/
    public void getAeManuPDFInfo(){
        aeManuReportSourceValList=new List<String>();
        aeManuReportTypeValList=new List<String>();
        aeManuPDFInfo=new Map<Object, Object>();
        aeManuPDFInfo=PC_AE_ManufacturerRendererController.loadDataFromAE(adverseEventId,aeManuPDFInfo);


        if(aeManuPDFInfo.containsKey('aeReceivedByManufacturerDate') &&
                                                              aeManuPDFInfo.get('aeReceivedByManufacturerDate') !=null){
            String dateCasting  = String.valueOf(aeManuPDFInfo.get('aeReceivedByManufacturerDate'));
            Date aeReceivedByManufacturerDate = Date.valueOf(dateCasting);
            //String returnDateVal = getDateFormatted(aeReceivedByManufacturerDate);
            String returnDateVal = PC_Utility.getFormattedDate(aeReceivedByManufacturerDate , dateFormat);
            if(returnDateVal !=null) {
                //aeManuPDFInfo.put('aeReceivedByManufacturerDate', getDateFormatted(aeReceivedByManufacturerDate));
                aeManuPDFInfo.put('aeReceivedByManufacturerDate',returnDateVal);
            }
        }

        if(aeManuPDFInfo!=null && !aeManuPDFInfo.isEmpty()){
            for(Object key: aeManuPDFInfo.keySet()){
                if(aeManuPDFInfo.get(key)==null){
                    aeManuPDFInfo.put(key,PC_Constants.EMPTY_STRING);
                }
            }

            String aeReportSourceStr=(String)aeManuPDFInfo.get('reportSource');
            aeManuReportSourceValList=splitString(aeReportSourceStr);

            String aeReportTypeStr=(String)aeManuPDFInfo.get('typeOfReports');
            aeManuReportTypeValList=splitString(aeReportTypeStr);
        }

    }

    /*********************************************************************************
    Method Name    : getAdverseEventPatientInfo
    Description    : method used to fetch Manufacturer menu field labels of Adverse event record
    Return Type    : Void
    Parameter      : None
    *********************************************************************************/
    public void getAeManuPDFLabels(){
        aeManuPDFLabels=new Map<String, String>();
        aeManuPDFLabels.put('manufacturerName', PC_AdverseEvent__c.PC_Manufacturer_Name__c.getDescribe().getLabel());
        aeManuPDFLabels.put('manufacturerAddress', PC_AdverseEvent__c.PC_Manufacturer_Address__c.getDescribe().getLabel());
        aeManuPDFLabels.put('manufacturerEmail', PC_AdverseEvent__c.PC_Manufacturer_Email__c.getDescribe().getLabel());
        aeManuPDFLabels.put('manufacturerCompOutsourcingFac', PC_AdverseEvent__c.PC_Manufacturer_Comp_Outsourcing_Fac__c.getDescribe().getLabel());
        aeManuPDFLabels.put('manufacturerPhone', PC_AdverseEvent__c.PC_Manufacturer_Phone__c.getDescribe().getLabel());
        aeManuPDFLabels.put('aeReceivedByManufacturerDate', PC_AdverseEvent__c.PC_AE_Received_by_Manufacturer_Date__c.getDescribe().getLabel());
        aeManuPDFLabels.put('reportSource', PC_AdverseEvent__c.PC_Report_Source__c.getDescribe().getLabel());
        aeManuPDFLabels.put('nda', PC_AdverseEvent__c.PC_NDA__c.getDescribe().getLabel());
        aeManuPDFLabels.put('anda', PC_AdverseEvent__c.PC_ANDA__c.getDescribe().getLabel());
        aeManuPDFLabels.put('ind', PC_AdverseEvent__c.PC_IND__c.getDescribe().getLabel());
        aeManuPDFLabels.put('bla', PC_AdverseEvent__c.PC_BLA__c.getDescribe().getLabel());
        aeManuPDFLabels.put('pma510', PC_AdverseEvent__c.PC_PMA_510k__c.getDescribe().getLabel());
        aeManuPDFLabels.put('pdfPre1938Flag', PC_AdverseEvent__c.PC_Pre_1938_Flag__c.getDescribe().getLabel());
        aeManuPDFLabels.put('productOTCcurrentVal', PC_AdverseEvent__c.PC_Product_OTC__c.getDescribe().getLabel());
        aeManuPDFLabels.put('combinationProductCurrentVal', PC_AdverseEvent__c.PC_Combination_Product_Report__c.getDescribe().getLabel());
        aeManuPDFLabels.put('manufacturerReportNumber', PC_AdverseEvent__c.PC_Manufacturer_Report_Number__c.getDescribe().getLabel());
        aeManuPDFLabels.put('typeOfReports', PC_AdverseEvent__c.PC_Report_Type__c.getDescribe().getLabel());
        aeManuPDFLabels.put('ifIndProtocolLabel', PC_AdverseEvent__c.PC_If_IND_Give_Protocol__c.getDescribe().getLabel());
        aeManuPDFLabels.put('adverseEventTerms', PC_AdverseEvent__c.PC_Adverse_Event_Terms__c.getDescribe().getLabel());
        aeManuPDFLabels.put('reportSourceOtherText', PC_AdverseEvent__c.PC_Report_Source_Other_Text__c.getDescribe().getLabel());
        aeManuPDFLabels.put('reportTypeOtherText', PC_AdverseEvent__c.PC_Report_Type_Other_Text__c.getDescribe().getLabel());
    }

    /*********************************************************************************
    Method Name    : getAdverseEventPatientInfo
    Description    : method used to split multipicklist values into list of strings
    Return Type    : Void
    Parameter      : None
    *********************************************************************************/
    public List<String> splitString(String multipicklistVal){
        List<String> picklistValList=new List<String>();
        if(!String.isBlank(multipicklistVal)) {
            picklistValList = multipicklistVal.split(';');
        }
        return picklistValList;
    }

    /*********************************************************************************
    Method Name    : getSPAdditionalInfoPDFInfoAndLabels
    Description    : method used to fetch Suspect Product Additional information field labels and Values
    Return Type    : Void
    Parameter      : None
    *********************************************************************************/
    public void getSPAdditionalInfoPDFInfoAndLabels(){

        Map<Object,Object> suspectProductInfoObj =new Map<Object, Object>();
        spAddInfoPDFInfo = new Map<Object, Object>();
        spAddInfoPDFLabels =  new Map<Object, Object>();
        String returnDateVal;
        PC_AE_SuspectProductsRendererController.FieldPathAndValue fieldPathAndValue=PC_AE_SuspectProductsRendererController.getPopulatedFieldSet(spAdditionalfsName, suspectProductInfoObj);
        if(fieldPathAndValue!=null){
            spAddInfoPDFInfo=fieldPathAndValue.fieldValue;
            spAddInfoPDFLabels=fieldPathAndValue.fieldLabels;
        }
    }

    /*********************************************************************************
    Method Name    : getAdverseEventPatientInfo
    Description    : method used to fetch Additional information menu field labels of Adverse event record
    Return Type    : Void
    Parameter      : None
    *********************************************************************************/
    public void getAeAddInfoPDFInfoAndLabels(){

        Map<Object,Object> additionalInfoObj =new Map<Object, Object>();
        aeAddInfoPDFInfo = new Map<Object, Object>();
        aeAddInfoPDFLabels =  new Map<Object, Object>();
        aeAddInfoPDFFieldApiNames=new List<String>();
        String returnDateVal;
        PC_AE_AdditionalInfoRendererController.FieldPathAndValue fieldPathAndValue=PC_AE_AdditionalInfoRendererController.getPopulatedFieldSet(adverseEventId,additionalInfoObj,PC_Constants.getQualifiedAPIName('PC_AdverseEvent__c'),fieldsetName);
        if(fieldPathAndValue!=null){
            getAdditionalInfoDateFormatted(fieldPathAndValue ,'PC_Date_of_Birth__c' );
            getAdditionalInfoDateFormatted(fieldPathAndValue ,'PC_Death_Date__c' );
            getAdditionalInfoDateFormatted(fieldPathAndValue ,'PC_Date_of_the_Report__c' );
            getAdditionalInfoDateFormatted(fieldPathAndValue ,'PC_AE_Received_by_Manufacturer_Date__c' );
            getAdditionalInfoDateFormatted(fieldPathAndValue ,'PC_Stop_Date__c' );
            getAdditionalInfoDateFormatted(fieldPathAndValue ,'PC_Event_Onset_Date__c' );
            getAdditionalInfoDateFormatted(fieldPathAndValue ,'PC_Expiration_Date__c' );
            getAdditionalInfoDateFormatted(fieldPathAndValue ,'PC_Hospitalization_Date__c' );
            getAdditionalInfoDateFormatted(fieldPathAndValue ,'PC_Therapy_End_Date__c' );
            getAdditionalInfoDateFormatted(fieldPathAndValue ,'PC_Therapy_Start_Date__c' );

            aeAddInfoPDFInfo=fieldPathAndValue.fieldValue;
            aeAddInfoPDFLabels=fieldPathAndValue.fieldLabels;
            aeAddInfoPDFFieldApiNames=fieldPathAndValue.fieldPath;
        }
    }

    /*********************************************************
    Method Name          : getAdditionalInfoDateFormatted
    Description          : Changing the date format for display purpose
    Input Params         : PC_AE_AdditionalInfoRendererController.FieldPathAndValue , String
    Return Type          : void
    *********************************************************************************/
    public static void getAdditionalInfoDateFormatted ( PC_AE_AdditionalInfoRendererController.FieldPathAndValue fieldPathAndValue , String fieldName) {
        String returnDateVal;
        if (fieldPathAndValue.fieldValue.containsKey(PC_Constants.getQualifiedAPIName(fieldName)) &&
                String.isNotBlank(String.valueOf(fieldPathAndValue.fieldValue.get(PC_Constants.getQualifiedAPIName(fieldName))))) {
            /*returnDateVal =
                 getDateFormatted(Date.valueOf(String.valueOf(fieldPathAndValue.fieldValue.get(PC_Constants.getQualifiedAPIName(fieldName)))));*/
            returnDateVal =
                 PC_Utility.getFormattedDate(Date.valueOf(String.valueOf(fieldPathAndValue.fieldValue.get(PC_Constants.getQualifiedAPIName(fieldName)))), dateFormat);

            if (returnDateVal != null) {
                     fieldPathAndValue.fieldValue.put(PC_Constants.getQualifiedAPIName(fieldName),returnDateVal);
            }
        }
    }


    /********************************************************************************
    Class Name           : AdverseEvent_PDF_Exception
    Description          : Hold the exception
    *********************************************************************************/
    public inherited sharing class AdverseEvent_PDF_Exception extends Exception{
        public String errorMessage;
        public String errorCode;

        public AdverseEvent_PDF_Exception(String message, String errCode){
            this.errorMessage=message;
            this.errorCode=errCode;
        }
    }
}