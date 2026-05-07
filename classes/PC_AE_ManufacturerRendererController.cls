/*********************************************************************************
Class Name      :   PC_AE_ManufacturerRendererController
Description        : Controller for PC_AE_ManufacturerRendererController Component
Created By        : Shishir Bansal
Created Date     : 27-11-2018
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------
Shishir Bansal         27-11-2018              Initial Version
Shishir Bansal         15-10-2019              [PC-5606] Bug fix added logic to handle picklist values
                                                with special character
Shishir Bansal         06-12-2019              [PC-5792] Avoid hardcoding of string variable
Chetna Mohapatra       18-06-2020              [PC-6365] Updated fetchDataFromManufacturer() to fetch the Manufacturer email address.
Haritha Reddy         21-Jan-2021              [PC-7102] Added FLS Check
Haritha Reddy         21-Jan-2021              [PC-7102] Force Reviewer scan issue fix. Updated Sharing declaration.
*********************************************************************************/

public with sharing class PC_AE_ManufacturerRendererController implements PC_AdverseEventMenuController.AdverseEventProcessor {

    /*********************************************************
    Method Name          : getManufacturerData
    Description          : fetch Field Labels,Picklist Values of Adverse Event Fields on Manufacturer  Tab
    Input Params         : String adverse Event Id , String Case Id
    Return Type          : ManufacturerFormData Wrapper
    *********************************************************************************/


    @AuraEnabled
    public static ManufacturerFormData getManufacturerData(String aeId, String caseId){
        ManufacturerFormData formData = new ManufacturerFormData();
        try {


            formData.manufacturerLabels = getManufacturerLabels();
            formData.reportType = getReportTypeMultiPicklistValues();
            formData.reportSource = getReportSourceMultiPicklistValues();
            formData.combinationProduct = getCombinationProductPicklistValues(PC_Constants.EMPTY_STRING);
            formData.productOtc = getproductOtcPicklistValues(PC_Constants.EMPTY_STRING);
            formData.pre1938Flag = getPre1938FlagPicklistValues(PC_Constants.EMPTY_STRING);
        } catch (exception ex){
            PC_Utility.logAndThrowException(ex);
        }
        return formData;

    }

    /*********************************************************
    Method Name          : updateAdverseEvent
    Description          : for  upserting the record on Adverse Event Object
    Input Params         : PC_AdverseEvent__c object ,    Map<Object,Object>
    Return Type          : Void
    *********************************************************************************/


    public void updateAdverseEvent(PC_AdverseEvent__c aeRec, Map<Object,Object> manufacturerInfo) {

        try {

            aeRec.PC_Manufacturer_Name__c = (String) manufacturerInfo.get('manufacturerName');
            aeRec.PC_Manufacturer_Address__c = (String) manufacturerInfo.get('manufacturerAddress');
            aeRec.PC_Manufacturer_Email__c = (String) manufacturerInfo.get('manufacturerEmail');
            if(manufacturerInfo.get('manufacturerCompOutsourcingFac') != null) {
                aeRec.PC_Manufacturer_Comp_Outsourcing_Fac__c = Boolean.valueOf(manufacturerInfo.get('manufacturerCompOutsourcingFac'));
            }
            aeRec.PC_Manufacturer_Phone__c = (String) manufacturerInfo.get('manufacturerPhone');
            if (((manufacturerInfo.get('aeReceivedByManufacturerDate')) != null) && (manufacturerInfo.get('aeReceivedByManufacturerDate') != PC_Constants.EMPTY_STRING)) {
                aeRec.PC_AE_Received_by_Manufacturer_Date__c = Date.valueOf(String.valueOf ((manufacturerInfo.get('aeReceivedByManufacturerDate'))));
            }

            aeRec.PC_NDA__c = (String) manufacturerInfo.get('nda');
            aeRec.PC_ANDA__c = (String) manufacturerInfo.get('anda');
            aeRec.PC_IND__c = (String) manufacturerInfo.get('ind');
            aeRec.PC_BLA__c = (String) manufacturerInfo.get('bla');
            aeRec.PC_PMA_510k__c = (String) manufacturerInfo.get('pma510');
            manufacturerInfo.put('pre1938Flag',getPre1938FlagPicklistValues((String)manufacturerInfo.get('pre1938FlagCurrentVal')));
            aeRec.PC_Pre_1938_Flag__c = (String)manufacturerInfo.get('pre1938FlagCurrentVal');


            manufacturerInfo.put('combinationProductUse', getCombinationProductPicklistValues((String) manufacturerInfo.get('combinationProductCurrentVal')));
            aeRec.PC_Combination_Product_Report__c = (String) manufacturerInfo.get('combinationProductCurrentVal');
            manufacturerInfo.put('productOTC', getproductOtcPicklistValues((String) manufacturerInfo.get('productOTCcurrentVal')));
            aeRec.PC_Product_OTC__c = (String) manufacturerInfo.get('productOTCcurrentVal');
            aeRec.PC_Manufacturer_Report_Number__c = (String) manufacturerInfo.get('manufacturerReportNumber');
            aeRec.PC_If_IND_Give_Protocol__c = (String) manufacturerInfo.get('ifIndProtocolLabel');
            aeRec.PC_Adverse_Event_Terms__c = (String) manufacturerInfo.get('adverseEventTerms');

            String reportSource = String.valueOf(manufacturerInfo.get('reportSource'));
            if(String.isNotBlank(reportSource)) {

                String reportSourceValues = PC_Constants.EMPTY_STRING;
                if(reportSource.startsWith('(') && reportSource.endsWith(')') ) {
                    reportSource = reportSource.removeStart('(');
                    reportSource = reportSource.removeEnd(')');
                }

                List<String> reportSourceList = reportSource.split(',');
                if(reportSourceList !=null){
                    for(String picklistValue : reportSourceList){
                        if(reportSourceValues ==PC_Constants.EMPTY_STRING){
                            reportSourceValues = picklistValue;
                        }
                        else{
                            reportSourceValues = reportSourceValues +';'+ picklistValue;
                        }
                    }
                }

                if(reportSourceValues !=PC_Constants.EMPTY_STRING) {
                    aeRec.PC_Report_Source__c = reportSourceValues;
                }
            }

            String typeOfReports = String.valueOf(manufacturerInfo.get('typeOfReports'));
            if(String.isNotBlank(typeOfReports)) {

                String typeOfReportsValues = PC_Constants.EMPTY_STRING;
                typeOfReports = typeOfReports.removeStart('(');
                typeOfReports = typeOfReports.removeEnd(')');

                List<String> typeOfReportsList = typeOfReports.split(',');

                if(typeOfReportsList !=null){
                    for(String picklistValue : typeOfReportsList){
                        if(typeOfReportsValues ==PC_Constants.EMPTY_STRING){
                            typeOfReportsValues = picklistValue;
                        }
                        else{
                            typeOfReportsValues = typeOfReportsValues +';'+ picklistValue;
                        }
                    }
                }

                if(typeOfReportsValues !=PC_Constants.EMPTY_STRING) {
                    aeRec.PC_Report_Type__c = typeOfReportsValues;
                }

            }
            aeRec.PC_Report_Source_Other_Text__c = (String) manufacturerInfo.get('reportSourceOtherText');
            aeRec.PC_Report_Type_Other_Text__c = (String) manufacturerInfo.get('reportTypeOtherText');
        }
        catch (exception ex){
            system.debug('message '+ex.getMessage()+' line '+ex.getStackTraceString());
            PC_Utility.logAndThrowException(ex);
        }

    }

    /*********************************************************
    Method Name          : loadDataFromAE
    Description          : for  updating the ui part on adverse Events
    Input Params         : PC_AdverseEvent__c  Id ,    Map<Object,Object>
    Return Type          :  Map<Object,Object>
    *********************************************************************************/


    @AuraEnabled
    public static Map<Object,Object> loadDataFromAE(String aeRecordId, Map<Object,Object> manufacturerInfo ) {

        try{
            //Check FLS
            List<String> aeFields = new List<String>{PC_Constants.getQualifiedAPIName('PC_Manufacturer_Name__c'),
                    PC_Constants.getQualifiedAPIName('PC_Manufacturer_Address__c'),PC_Constants.getQualifiedAPIName('PC_Manufacturer_Email__c'),
                    PC_Constants.getQualifiedAPIName('PC_Manufacturer_Comp_Outsourcing_Fac__c'),PC_Constants.getQualifiedAPIName('PC_Manufacturer_Phone__c'),
                    PC_Constants.getQualifiedAPIName('PC_NDA__c'),PC_Constants.getQualifiedAPIName('PC_ANDA__c'),
                    PC_Constants.getQualifiedAPIName('PC_IND__c'),PC_Constants.getQualifiedAPIName('PC_BLA__c'),
                    PC_Constants.getQualifiedAPIName('PC_PMA_510k__c'),PC_Constants.getQualifiedAPIName('PC_Pre_1938_Flag__c'),
                    PC_Constants.getQualifiedAPIName('PC_Product_OTC__c'),PC_Constants.getQualifiedAPIName('PC_Combination_Product_Report__c'),
                    PC_Constants.getQualifiedAPIName('PC_Manufacturer_Report_Number__c'),PC_Constants.getQualifiedAPIName('PC_Report_Source__c'),
                    PC_Constants.getQualifiedAPIName('PC_Report_Type__c'),PC_Constants.getQualifiedAPIName('PC_AE_Received_by_Manufacturer_Date__c'),
                    PC_Constants.getQualifiedAPIName('PC_Adverse_Event_Terms__c'),PC_Constants.getQualifiedAPIName('PC_If_IND_Give_Protocol__c'),
                    PC_Constants.getQualifiedAPIName('PC_Report_Source_Other_Text__c'),PC_Constants.getQualifiedAPIName('PC_Report_Type_Other_Text__c')
            };
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_AdverseEvent__c'),PC_Database.Operation.Reading, aeFields);

            PC_AdverseEvent__c aeRec = [
                    Select PC_Manufacturer_Name__c,PC_Manufacturer_Address__c,
                            PC_Manufacturer_Email__c, PC_Manufacturer_Comp_Outsourcing_Fac__c, PC_Manufacturer_Phone__c, PC_NDA__c,
                            PC_ANDA__c, PC_IND__c, PC_BLA__c, PC_PMA_510k__c, PC_Pre_1938_Flag__c, PC_Product_OTC__c,
                            PC_Combination_Product_Report__c,
                            PC_Manufacturer_Report_Number__c, PC_Report_Source__c, PC_Report_Type__c,PC_AE_Received_by_Manufacturer_Date__c,PC_Adverse_Event_Terms__c,
                            PC_If_IND_Give_Protocol__c,PC_Report_Source_Other_Text__c,PC_Report_Type_Other_Text__c
                            from PC_AdverseEvent__c
                            where id = :aeRecordId
            ];
            if(manufacturerInfo == null){
                manufacturerInfo = new Map<Object,Object>();
            }
            manufacturerInfo.put('manufacturerName', aeRec.PC_Manufacturer_Name__c);
            manufacturerInfo.put('manufacturerAddress', aeRec.PC_Manufacturer_Address__c);
            manufacturerInfo.put('manufacturerEmail', aeRec.PC_Manufacturer_Email__c);
            manufacturerInfo.put('manufacturerCompOutsourcingFac', aeRec.PC_Manufacturer_Comp_Outsourcing_Fac__c);
            manufacturerInfo.put('manufacturerPhone', aeRec.PC_Manufacturer_Phone__c);
            manufacturerInfo.put('aeReceivedByManufacturerDate', aeRec.PC_AE_Received_by_Manufacturer_Date__c);
            manufacturerInfo.put('nda', aeRec.PC_NDA__c);
            manufacturerInfo.put('anda', aeRec.PC_ANDA__c);
            manufacturerInfo.put('ind', aeRec.PC_IND__c);
            manufacturerInfo.put('bla', aeRec.PC_BLA__c);
            manufacturerInfo.put('pma510', aeRec.PC_PMA_510k__c);
            manufacturerInfo.put('pre1938Flag', getPre1938FlagPicklistValues(aeRec.PC_Pre_1938_Flag__c));
            //Author: Hitha: PC-3937: Below field has been added for PDF generation logic
            manufacturerInfo.put('pdfPre1938Flag', aeRec.PC_Pre_1938_Flag__c);
            //manufacturerInfo.put('pre1938Flag', aeRec.PC_Pre_1938_Flag__c);
            manufacturerInfo.put('combinationProductCurrentVal', aeRec.PC_Combination_Product_Report__c);
            manufacturerInfo.put('combinationProductUse', getCombinationProductPicklistValues((String) aeRec.PC_Combination_Product_Report__c));
            manufacturerInfo.put('productOTCcurrentVal', aeRec.PC_Product_OTC__c);
            manufacturerInfo.put('productOTC', getproductOtcPicklistValues((String) aeRec.PC_Product_OTC__c));
            manufacturerInfo.put('manufacturerReportNumber', aeRec.PC_Manufacturer_Report_Number__c);
            manufacturerInfo.put('ifIndProtocolLabel', aeRec.PC_If_IND_Give_Protocol__c);
            manufacturerInfo.put('adverseEventTerms', aeRec.PC_Adverse_Event_Terms__c);
            manufacturerInfo.put('reportSourceOtherText', aeRec.PC_Report_Source_Other_Text__c);
            manufacturerInfo.put('reportTypeOtherText', aeRec.PC_Report_Type_Other_Text__c);

            if (aeRec.PC_Report_Source__c != null) {
                manufacturerInfo.put('reportSource', aeRec.PC_Report_Source__c);
            }else{
                manufacturerInfo.put('reportSource', PC_Constants.EMPTY_STRING);
            }

            if (aeRec.PC_Report_Type__c != null) {
                manufacturerInfo.put('typeOfReports', aeRec.PC_Report_Type__c);
            }else{
                manufacturerInfo.put('typeOfReports', PC_Constants.EMPTY_STRING);
            }
        }catch (exception ex){
            system.debug('message '+ex.getMessage()+' line '+ex.getStackTraceString());
            PC_Utility.logAndThrowException(ex);
        }

        return manufacturerInfo;
    }


    /*********************************************************
    Method Name          : fetchDataFromManufacturer
    Description               : Map Manufacturer details to aeWrapper
    Input Params            : List<Id> aeId, Map<Object,Object> aeWrapper
    Return Type             : Map<Object,Object>
    *********************************************************************************/
    @AuraEnabled
    public static Map<Object,Object> fetchDataFromManufacturer(String caseId, Map<Object,Object> manufacturerInfo) {
        try {

            List<String> fields = new List<String>{PC_Constants.getQualifiedAPIName('PC_Engagement_Program__c')};
            PC_Database.assertAccess(PC_Constants.PC_CASE,PC_Database.Operation.Reading, fields);

            fields = new List<String>{PC_Constants.getQualifiedAPIName('PC_Primary_Address__c'), 'ShippingCity', 'ShippingCountry',
                    'ShippingPostalCode', 'ShippingState', 'ShippingStreet', 'Phone', PC_Constants.getQualifiedAPIName('PC_Email__c')};
            PC_Database.assertAccess(PC_Constants.PC_ACCOUNT,PC_Database.Operation.Reading, fields);

            fields = new List<String>{PC_Constants.getQualifiedAPIName('PC_Manufacturer__c')};
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Engagement_Program__c'),PC_Database.Operation.Reading,fields);

            fields = new List<String>{PC_Constants.getQualifiedAPIName('PC_Address_1__c'),PC_Constants.getQualifiedAPIName('PC_Address_2__c'),
                    PC_Constants.getQualifiedAPIName('PC_Address_3__c')};
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Address__c'),PC_Database.Operation.Reading, fields);

            Case  curentCaseManufacturer = [Select PC_Engagement_Program__r.PC_Manufacturer__r.Name,
                    PC_Engagement_Program__r.PC_Manufacturer__r.PC_Primary_Address__r.PC_Address_1__c,
                    PC_Engagement_Program__r.PC_Manufacturer__r.PC_Primary_Address__r.PC_Address_2__c,
                    PC_Engagement_Program__r.PC_Manufacturer__r.PC_Primary_Address__r.PC_Address_3__c,
                    PC_Engagement_Program__r.PC_Manufacturer__r.ShippingCity,
                    PC_Engagement_Program__r.PC_Manufacturer__r.ShippingCountry,
                    PC_Engagement_Program__r.PC_Manufacturer__r.ShippingPostalCode,
                    PC_Engagement_Program__r.PC_Manufacturer__r.ShippingState,
                    PC_Engagement_Program__r.PC_Manufacturer__r.ShippingStreet ,
                    PC_Engagement_Program__r.PC_Manufacturer__r.Phone,
                    PC_Engagement_Program__r.PC_Manufacturer__r.PC_Email__c

            from Case where Id =: caseId LIMIT 1];
            String  address = PC_Constants.EMPTY_STRING;


            if(curentCaseManufacturer.PC_Engagement_Program__r.PC_Manufacturer__r.ShippingStreet  !=null)
                address +=curentCaseManufacturer.PC_Engagement_Program__r.PC_Manufacturer__r.ShippingStreet;

            if(curentCaseManufacturer.PC_Engagement_Program__r.PC_Manufacturer__r.ShippingCity  !=null) {
                if (address != PC_Constants.EMPTY_STRING) {
                    address +=', ' + curentCaseManufacturer.PC_Engagement_Program__r.PC_Manufacturer__r.ShippingCity;
                }

                else{
                    address += curentCaseManufacturer.PC_Engagement_Program__r.PC_Manufacturer__r.ShippingCity;
                }
            }

            if(curentCaseManufacturer.PC_Engagement_Program__r.PC_Manufacturer__r.ShippingState  !=null) {
                if (address != PC_Constants.EMPTY_STRING) {
                    address += ', ' + curentCaseManufacturer.PC_Engagement_Program__r.PC_Manufacturer__r.ShippingState;
                }

                else {
                    address += curentCaseManufacturer.PC_Engagement_Program__r.PC_Manufacturer__r.ShippingState;
                }
            }

            if(curentCaseManufacturer.PC_Engagement_Program__r.PC_Manufacturer__r.ShippingPostalCode  !=null) {
                if (address != PC_Constants.EMPTY_STRING) {
                    address +=', '+curentCaseManufacturer.PC_Engagement_Program__r.PC_Manufacturer__r.ShippingPostalCode;
                }

                else {
                    address +=curentCaseManufacturer.PC_Engagement_Program__r.PC_Manufacturer__r.ShippingPostalCode;
                }
            }



            if(curentCaseManufacturer.PC_Engagement_Program__r.PC_Manufacturer__r.ShippingCountry  !=null){
                if (address != PC_Constants.EMPTY_STRING) {
                    address +=', ' +curentCaseManufacturer.PC_Engagement_Program__r.PC_Manufacturer__r.ShippingCountry;
                }

                else {
                    address +=curentCaseManufacturer.PC_Engagement_Program__r.PC_Manufacturer__r.ShippingCountry;
                }
            }

            if(manufacturerInfo == null){
                manufacturerInfo = new Map<Object,Object>();
            }
            manufacturerInfo.put('manufacturerName', curentCaseManufacturer.PC_Engagement_Program__r.PC_Manufacturer__r.Name);
            manufacturerInfo.put('manufacturerPhone', curentCaseManufacturer.PC_Engagement_Program__r.PC_Manufacturer__r.Phone);
            manufacturerInfo.put('manufacturerAddress', address);
            manufacturerInfo.put('manufacturerEmail', curentCaseManufacturer.PC_Engagement_Program__r.PC_Manufacturer__r.PC_Email__c);
            manufacturerInfo.put('reportSource',PC_Constants.EMPTY_STRING);
            manufacturerInfo.put('typeOfReports',PC_Constants.EMPTY_STRING);

            //manufacturerInfo.put('manufacturerPhone', patientAcc.Id);


            return manufacturerInfo;

        }catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return null;
    }

    /*********************************************************
    Method Name          : getManufacturerLabels
    Description          : getting all the field labels for the translation
    Input Params         :null
    Return Type          :FieldLabels class
    *********************************************************************************/



    public static FieldLabels getManufacturerLabels(){

        FieldLabels fieldlabels = new FieldLabels();

        try {
            fieldlabels.manufacturerNameLabel = PC_AdverseEvent__c.PC_Manufacturer_Name__c.getDescribe().getLabel();
            fieldlabels.manufacturerAddressLabel = PC_AdverseEvent__c.PC_Manufacturer_Address__c.getDescribe().getLabel();
            fieldlabels.manufacturerEmailLabel = PC_AdverseEvent__c.PC_Manufacturer_Email__c.getDescribe().getLabel();
            fieldlabels.manufacturerCompOutsourcingFacLabel = PC_AdverseEvent__c.PC_Manufacturer_Comp_Outsourcing_Fac__c.getDescribe().getLabel();
            fieldlabels.manufacturerPhoneLabel = PC_AdverseEvent__c.PC_Manufacturer_Phone__c.getDescribe().getLabel();
            fieldlabels.aeReceivedByManufacturerDateLabel = PC_AdverseEvent__c.PC_AE_Received_by_Manufacturer_Date__c.getDescribe().getLabel();
            fieldlabels.reportSourceLabel = PC_AdverseEvent__c.PC_Report_Source__c.getDescribe().getLabel();
            fieldlabels.ndaLabel = PC_AdverseEvent__c.PC_NDA__c.getDescribe().getLabel();
            fieldlabels.andaLabel = PC_AdverseEvent__c.PC_ANDA__c.getDescribe().getLabel();
            fieldlabels.indLabel = PC_AdverseEvent__c.PC_IND__c.getDescribe().getLabel();
            fieldlabels.blaLabel = PC_AdverseEvent__c.PC_BLA__c.getDescribe().getLabel();
            fieldlabels.pma510Label = PC_AdverseEvent__c.PC_PMA_510k__c.getDescribe().getLabel();
            fieldlabels.pre1938FlagLabel = PC_AdverseEvent__c.PC_Pre_1938_Flag__c.getDescribe().getLabel();
            fieldlabels.indicationForProductUseLabel = PC_AdverseEvent__c.PC_Indication_for_Product_Use__c.getDescribe().getLabel();
            fieldlabels.productOTCLabel = PC_AdverseEvent__c.PC_Product_OTC__c.getDescribe().getLabel();
            fieldlabels.combinationProductUseLabel = PC_AdverseEvent__c.PC_Combination_Product_Report__c.getDescribe().getLabel();
            fieldlabels.manufacturerReportNumberLabel = PC_AdverseEvent__c.PC_Manufacturer_Report_Number__c.getDescribe().getLabel();
            fieldlabels.typeOfReportsLabel = PC_AdverseEvent__c.PC_Report_Type__c.getDescribe().getLabel();
            fieldlabels.ifIndProtocolLabel = PC_AdverseEvent__c.PC_If_IND_Give_Protocol__c.getDescribe().getLabel();
            fieldlabels.adverseEventTermsLabel = PC_AdverseEvent__c.PC_Adverse_Event_Terms__c.getDescribe().getLabel();
            fieldlabels.reportSourceOtherTextLabel = PC_AdverseEvent__c.PC_Report_Source_Other_Text__c.getDescribe().getLabel();
            fieldlabels.reportTypeOtherTextLabel = PC_AdverseEvent__c.PC_Report_Type_Other_Text__c.getDescribe().getLabel();
        }
        catch (exception ex){
            PC_Utility.logAndThrowException(ex);
        }

        return fieldlabels;

    }

    // fieldLables class

    public inherited sharing class FieldLabels {
        //Activity Fields
        @AuraEnabled public String manufacturerNameLabel { get; set; }
        @AuraEnabled public String manufacturerAddressLabel { get; set; }
        @AuraEnabled public String manufacturerEmailLabel { get; set; }
        @AuraEnabled public String manufacturerCompOutsourcingFacLabel { get; set; }
        @AuraEnabled public String manufacturerPhoneLabel { get; set; }
        @AuraEnabled public String aeReceivedByManufacturerDateLabel { get; set;}
        @AuraEnabled public String reportSourceLabel { get; set; }
        @AuraEnabled public String ndaLabel { get; set; }
        @AuraEnabled public String andaLabel { get; set; }
        @AuraEnabled public String indLabel { get; set; }
        @AuraEnabled public String blaLabel { get; set; }
        @AuraEnabled public String pma510Label { get; set; }
        @AuraEnabled public String pre1938FlagLabel { get; set; }
        @AuraEnabled public String indicationForProductUseLabel { get; set; }
        @AuraEnabled public String productOTCLabel { get; set; }
        @AuraEnabled public String combinationProductUseLabel { get; set; }
        @AuraEnabled public String manufacturerReportNumberLabel { get; set; }
        @AuraEnabled public String typeOfReportsLabel { get; set; }
        @AuraEnabled public String ifIndProtocolLabel { get; set; }
        @AuraEnabled public String adverseEventTermsLabel { get; set; }
        @AuraEnabled public String reportSourceOtherTextLabel {get; set;}
        @AuraEnabled public String reportTypeOtherTextLabel {get; set;}

        public FieldLabels() {
        }
    }

    /*********************************************************
    Method Name          : getReportTypeMultiPicklistValues
    Description          : getting values for the picklist of Report Type
    Input Params         :null
    Return Type          :List<PicklistWrapper>
    *********************************************************************************/

    public static List<PicklistWrapper> getReportTypeMultiPicklistValues(){

        PicklistWrapper reportTypeObj  ;

        List<PicklistWrapper> reportTypeWrapperList = new List<PicklistWrapper>();



        try {

            Schema.DescribeFieldResult reportTypefieldResult = PC_AdverseEvent__c.PC_Report_Type__c.getDescribe();
            List<Schema.PicklistEntry> reportTypeList = reportTypefieldResult.getPicklistValues();

            for (Schema.PicklistEntry reportTypeValue : reportTypeList) {
                //reportType.add(reportTypeValue.getLabel());
                reportTypeObj = new PicklistWrapper();
                reportTypeObj.label = reportTypeValue.getLabel();
                reportTypeObj.value = reportTypeValue.getValue();
                reportTypeWrapperList.add(reportTypeObj);
            }
        }
        catch (exception ex){
            PC_Utility.logAndThrowException(ex);
        }
        return reportTypeWrapperList;
    }

    /*********************************************************
    Method Name          : getCombinationProductPicklistValues
    Description          : getting values for the picklist of Combination Product
    Input Params         :String value from ui
    Return Type          :List<PicklistWrapper>
    *********************************************************************************/

    public static List<PicklistWrapper> getCombinationProductPicklistValues(String value){

        PicklistWrapper combinationProductObj = new PicklistWrapper()  ;
        List<PicklistWrapper>combinationProductWrapperList = new List<PicklistWrapper>();


        try {

            combinationProductObj.label = PC_Constants.PICKLIST_NONE_VAL;
            combinationProductObj.value = PC_Constants.EMPTY_STRING;
            if (value == PC_Constants.EMPTY_STRING) {
                combinationProductObj.selected = true;
            }

            else {
                combinationProductObj.selected = false;
            }

            combinationProductWrapperList.add(combinationProductObj);


            Schema.DescribeFieldResult combinationProductfieldResult = PC_AdverseEvent__c.PC_Combination_Product_Report__c.getDescribe();
            List<Schema.PicklistEntry> combinationProductList = combinationProductfieldResult.getPicklistValues();
            for (Schema.PicklistEntry combinationProductValue : combinationProductList) {

                combinationProductObj = new PicklistWrapper();
                combinationProductObj.label = combinationProductValue.getLabel();
                combinationProductObj.value = combinationProductValue.getValue();
                if (combinationProductObj.value == value) {
                    combinationProductObj.selected = true;

                }

                else {
                    combinationProductObj.selected = false;
                }

                combinationProductWrapperList.add(combinationProductObj);
            }
        }

        catch (exception ex){
            system.debug('message '+ex.getMessage()+' line '+ex.getStackTraceString());
            PC_Utility.logAndThrowException(ex);
        }
        return combinationProductWrapperList;
    }

    /*********************************************************
    Method Name          : getproductOtcPicklistValues
    Description          : getting values for the picklist of Product OTC
    Input Params         :String value from ui
    Return Type          :List<PicklistWrapper>
    *********************************************************************************/


    public static List<PicklistWrapper> getproductOtcPicklistValues(String value){

        PicklistWrapper productOtcObj = new PicklistWrapper();
        List<PicklistWrapper>productOtcWrapperList = new List<PicklistWrapper>();

        try {

            productOtcObj.label = PC_Constants.PICKLIST_NONE_VAL;
            productOtcObj.value = PC_Constants.EMPTY_STRING;
            if (value == PC_Constants.EMPTY_STRING) {
                productOtcObj.selected = true;
            }

            else {
                productOtcObj.selected = false;
            }


            productOtcWrapperList.add(productOtcObj);


            Schema.DescribeFieldResult productOtcfieldResult = PC_AdverseEvent__c.PC_Combination_Product_Report__c.getDescribe();
            List<Schema.PicklistEntry> productOtcList = productOtcfieldResult.getPicklistValues();
            for (Schema.PicklistEntry productOtcValue : productOtcList) {

                productOtcObj = new PicklistWrapper();
                productOtcObj.label = productOtcValue.getLabel();
                productOtcObj.value = productOtcValue.getValue();

                if (value == productOtcObj.value) {
                    productOtcObj.selected = true;
                }

                else {
                    productOtcObj.selected = false;
                }


                productOtcWrapperList.add(productOtcObj);
            }
        }

        catch (exception ex){
            system.debug('message '+ex.getMessage()+' line '+ex.getStackTraceString());
            PC_Utility.logAndThrowException(ex);
        }

        return productOtcWrapperList;
    }

    /*********************************************************
    Method Name          : getPre1938FlagPicklistValues
    Description          : getting values for the picklist of Pre1938
    Input Params         :String value from ui
    Return Type          :List<PicklistWrapper>
    *********************************************************************************/

    public static List<PicklistWrapper> getPre1938FlagPicklistValues(String value){

        PicklistWrapper pre1938FlagObj = new PicklistWrapper()  ;
        List<PicklistWrapper>pre1938FlagObjWrapperList = new List<PicklistWrapper>();


        try {

            pre1938FlagObj.label = PC_Constants.PICKLIST_NONE_VAL;
            pre1938FlagObj.value = PC_Constants.EMPTY_STRING;
            if (value == PC_Constants.EMPTY_STRING) {
                pre1938FlagObj.selected = true;
            }

            else {
                pre1938FlagObj.selected = false;
            }

            pre1938FlagObjWrapperList.add(pre1938FlagObj);


            Schema.DescribeFieldResult pre1938FlagfieldResult = PC_AdverseEvent__c.PC_Combination_Product_Report__c.getDescribe();
            List<Schema.PicklistEntry> pre1938FlagList = pre1938FlagfieldResult.getPicklistValues();
            for (Schema.PicklistEntry pre1938FlagValue : pre1938FlagList) {

                pre1938FlagObj = new PicklistWrapper();
                pre1938FlagObj.label = pre1938FlagValue.getLabel();
                pre1938FlagObj.value = pre1938FlagValue.getValue();
                if (pre1938FlagObj.value == value) {
                    pre1938FlagObj.selected = true;

                }

                else {
                    pre1938FlagObj.selected = false;
                }

                pre1938FlagObjWrapperList.add(pre1938FlagObj);
            }
        }

        catch (exception ex){
            system.debug('message '+ex.getMessage()+' line '+ex.getStackTraceString());
            PC_Utility.logAndThrowException(ex);
        }
        return pre1938FlagObjWrapperList;
    }

    /*********************************************************
    Method Name          : getReportSourceMultiPicklistValues
    Description          : getting values for the multi select picklist of report source
    Input Params         :null
    Return Type          :List<PicklistWrapper>
    *********************************************************************************/


    public static List<PicklistWrapper> getReportSourceMultiPicklistValues() {


        PicklistWrapper reportSourceObj ;
        List<PicklistWrapper> reportSourceWrapperList = new List<PicklistWrapper>();

        try {

            Schema.DescribeFieldResult fieldResult = PC_AdverseEvent__c.PC_Report_Source__c.getDescribe();
            List<Schema.PicklistEntry> pList = fieldResult.getPicklistValues();
            for (Schema.PicklistEntry pValue : pList) {
                reportSourceObj = new PicklistWrapper();
                //reportSource.add(pValue.getLabel());
                reportSourceObj.label = pValue.getLabel();
                reportSourceObj.value = pValue.getValue();
                reportSourceWrapperList.add(reportSourceObj);
            }
        }
        catch (exception ex){
            system.debug('message '+ex.getMessage()+' line '+ex.getStackTraceString());
            PC_Utility.logAndThrowException(ex);
        }

            return reportSourceWrapperList;
    }


    public inherited sharing class PicklistWrapper {
        @AuraEnabled public String label {get; set;}
        @AuraEnabled public String value {get; set;}
        @AuraEnabled public Boolean selected {get; set;}

        PicklistWrapper(){

        }
    }


    public inherited sharing class ManufacturerFormData{

        /**
        * Property to hold Field Labels for Manufacturer section
        */
        @AuraEnabled public FieldLabels manufacturerLabels;

        /**
        * Property to hold different types of report Source
        */
        @AuraEnabled public List<PicklistWrapper> reportSource;

        /**
        * Property to hold different types of report type
        */
        @AuraEnabled public List<PicklistWrapper> reportType;


        /**
        * Property to hold picklist values of combination Product
        */
        @AuraEnabled public List<PicklistWrapper>  combinationProduct;


        /**
        * Property to hold picklist values of Product Otc
        */
        @AuraEnabled public List<PicklistWrapper> productOtc;

        /**
        * Property to hold picklist values of pre1938Flag
        */
       @AuraEnabled public List<PicklistWrapper> pre1938Flag;

    }

}