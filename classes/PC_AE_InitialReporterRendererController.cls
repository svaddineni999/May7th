/*********************************************************************************
Class Name       : PC_AE_InitialReporterRendererController
Description      : Controller for PC_AE_InitialReporterRenderer Component
Created By       : Xiukai Ning
Created Date     : 28-11-2018
Modification Log :
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------
Xiukai Ning          28-11-2018              Initial Version
Haritha Reddy        18-12-2019              [PC-5723] Added Code to fetch details of new Field 'Health Care Professional'
Vijay Kashikar       Apr 20, 2020            [PC-6169] Made changes so that the reporter address shown on AE pop up
                                             considers the individual address street fields instead of complete address
Chetna Mohapatra     Apr 23,2020            [PC-6118] Made changes in getInitialReporterData method to set a default
                                                     HealthCare Professional Value on opening a new AE screen.
                                                     Also in the updateAdverseEvent method for reporter type value updation.
Haritha Reddy         21-Jan-2021           [PC-7102] Added FLS Check
Haritha Reddy         21-Jan-2021          [PC-7102] Force Reviewer scan issue fix. Updated Sharing declaration.
*********************************************************************************/

public with sharing class PC_AE_InitialReporterRendererController implements PC_AdverseEventMenuController.AdverseEventProcessor{

    public static Id patientIdParameter;
    public static boolean isDefaultReporterTypePicklistPresent = false;

    /*********************************************************
    Method Name          	: getInitialReporterData
    Description             : get Field Labels,Picklist Values of Adverse Event Fields on Initial Reporter Tab
    Input Params            : NA
    Return Type             : InitialReporterFormData Wrapper
    *********************************************************************************/
    @AuraEnabled
    public static InitialReporterFormData getInitialReporterData(String caseIdParam , String aeIdParam, String patientIdParam){
        InitialReporterFormData formData = new InitialReporterFormData();
        try {
            formData.fieldLabels = getInitialReporterLabels();
            //formData.reporterTypeOptions = getReporterTypePicklistValues();
            setReporterTypeOptions(formData);
            formData.reporterSentToFdaOptions = getReporterSent2FdaPicklistValues();
            formData.healthCareProfessionalOptions = getHealthCareProfessionalPicklistValues();
            if( (String.isNotBlank(caseIdParam) || String.isNotBlank(patientIdParam)) && String.isBlank(aeIdParam) && isDefaultReporterTypePicklistPresent == true){
                formData.defaultPatientReporter = getRelatedPatientReporter(caseIdParam, patientIdParam);
                formData.defaultReporterTypeValue = PC_Constants.DEFAULT_REPORTER_TYPE_PICKLIST;
                formData.defaultHealthCareProfessionalValue= PC_Constants.DEFAULT_HEALTH_CARE_PROFESSIONAL_VALUE ;
                if(patientIdParameter !=null){
                    formData.patientIdValue = patientIdParameter;
                }else{
                    formData.patientIdValue = null;
                }
            }
            else{
                formData.defaultPatientReporter = null;
                formData.patientIdValue = null;
                formData.defaultHealthCareProfessionalValue= null;
            }
        }
        catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return formData;
    }

    private static void setReporterTypeOptions(InitialReporterFormData formData) {
        List<PicklistWrapper> allOptions = getReporterTypePicklistValues();

        /*PicklistWrapper noneOption = new PicklistWrapper();
        noneOption.label = 'None';
        noneOption.value = Label.PC_None;*/

        List<PicklistWrapper> healthCareProfessionalOptions = new List<PicklistWrapper>();
        //healthCareProfessionalOptions.add(noneOption);

        List<PicklistWrapper> nonhealthCareProfessionalOptions = new List<PicklistWrapper>();
        //nonhealthCareProfessionalOptions.add(noneOption);

        Set<String> nonHealthCareProfessionalOptionKeys = new Set<String>();
        nonHealthCareProfessionalOptionKeys.add('Patient');
        nonHealthCareProfessionalOptionKeys.add('Non-Healthcare Professional');

        for(PicklistWrapper wrapper : allOptions) {
            if(String.isBlank(wrapper.value)) {
                nonhealthCareProfessionalOptions.add(wrapper);
                healthCareProfessionalOptions.add(wrapper);
            }
            else if(nonHealthCareProfessionalOptionKeys.contains(wrapper.label)) {
                nonhealthCareProfessionalOptions.add(wrapper);
            }
            else {
                healthCareProfessionalOptions.add(wrapper);
            }
        }

        formData.reporterTypeOptions = allOptions;
        formData.healthCareProfessionalReporterTypeOptions = healthCareProfessionalOptions;
        formData.nonHealthCareProfessionalReporterTypeOptions = nonhealthCareProfessionalOptions;
    }

    /*********************************************************
    Method Name          	: getDataFromAE
    Description             : Map Current Adverse event details to aeWrapper
    Input Params            : List<Id> aeId, Map<Object,Object> initialReporterObj
    Return Type             : Map<Object,Object>
    *********************************************************************************/
    @AuraEnabled
    public static Map<Object,Object> getDataFromAE(String aeId, Map<Object,Object> initialReporterObj) {
        try {
            List<String> fields = new List<String>{PC_Constants.getQualifiedAPIName('PC_Reporter_First_Name__c'),
                    PC_Constants.getQualifiedAPIName('PC_Reporter_Last_Name__c'),
                    PC_Constants.getQualifiedAPIName('PC_ReporterAddress__c'),
                    PC_Constants.getQualifiedAPIName('PC_Reporter_City__c'),
                    PC_Constants.getQualifiedAPIName('PC_Reporter_State__c'),
                    PC_Constants.getQualifiedAPIName('PC_Reporter_Country__c'),
                    PC_Constants.getQualifiedAPIName('PC_Reporter_Zip_Code__c'),
                    PC_Constants.getQualifiedAPIName('PC_Reporter_Email__c'),
                    PC_Constants.getQualifiedAPIName('PC_Reporter_Phone__c'),
                    PC_Constants.getQualifiedAPIName('PC_Adverse_Event_Reporter__c'),
                    PC_Constants.getQualifiedAPIName('PC_Ini_Reporter_Also_Sent_Report_to_FDA__c'),
                    PC_Constants.getQualifiedAPIName('PC_HealthCareProfessional__c')
            };
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_AdverseEvent2__c'), PC_Database.Operation.Reading, fields);

            PC_AdverseEvent__c aeRec = [
                    Select PC_Reporter_First_Name__c, PC_Reporter_Last_Name__c, PC_ReporterAddress__c, PC_Reporter_City__c,
                            PC_Reporter_State__c,PC_Reporter_Country__c, PC_Reporter_Zip_Code__c, PC_Reporter_Email__c,
                            PC_Reporter_Phone__c, PC_Adverse_Event_Reporter__c, PC_Ini_Reporter_Also_Sent_Report_to_FDA__c, PC_HealthCareProfessional__c
                    from PC_AdverseEvent__c
                    where id = :aeId
            ];
            if(initialReporterObj == null){
                initialReporterObj = new Map<Object,Object>();
            }
            initialReporterObj.put('firstName', aeRec.PC_Reporter_First_Name__c);
            initialReporterObj.put('lastName', aeRec.PC_Reporter_Last_Name__c);
            initialReporterObj.put('address', aeRec.PC_ReporterAddress__c);
            initialReporterObj.put('city', aeRec.PC_Reporter_City__c);
            initialReporterObj.put('state', aeRec.PC_Reporter_State__c);
            initialReporterObj.put('country', aeRec.PC_Reporter_Country__c);
            initialReporterObj.put('zip', aeRec.PC_Reporter_Zip_Code__c);
            initialReporterObj.put('email', aeRec.PC_Reporter_Email__c);
            initialReporterObj.put('phone', aeRec.PC_Reporter_Phone__c);
            initialReporterObj.put('occupation', aeRec.PC_Adverse_Event_Reporter__c);
            initialReporterObj.put('IRalsoSentReportToFDA', aeRec.PC_Ini_Reporter_Also_Sent_Report_to_FDA__c);
            initialReporterObj.put('healthCareProfessional', aeRec.PC_HealthCareProfessional__c);

            return initialReporterObj;
        }catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return null;
    }


    @AuraEnabled
    public static ReporterWrapper getReporterDataBasedOnRole(String caseId , String reporterRole){

        try{
            if(String.isNotBlank(caseId) && String.isNotBlank(reporterRole)) {
                ReporterWrapper reportWrapper;


                if (reporterRole.equalsIgnoreCase(PC_Constants.PATIENT_ACCOUNT_TYPE_VALUE)) {
                    reportWrapper = new ReporterWrapper();


                    reportWrapper = getRelatedPatientReporter(caseId, null);


                    if (reportWrapper != null) {
                        return reportWrapper;
                    } else {
                        return null;
                    }

                } else {

                    /*
            * FLS Check for Account
            */
                    List<String> fields = new List<String>{
                            PC_Constants.getQualifiedAPIName('PC_Role__c'),
                            PC_Constants.getQualifiedAPIName('PC_Account__c'),
                            PC_Constants.getQualifiedAPIName('PC_Account__r') + '.' + PC_Constants.getQualifiedAPIName('PC_First_Name__c'),
                            PC_Constants.getQualifiedAPIName('PC_Account__r') + '.' + PC_Constants.getQualifiedAPIName('PC_Last_Name__c'),
                            PC_Constants.getQualifiedAPIName('PC_Account__r') + '.' + PC_Constants.getQualifiedAPIName('PC_Primary_Address__r')
                                    + '.' + PC_Constants.getQualifiedAPIName('PC_Address_1__c'),
                            PC_Constants.getQualifiedAPIName('PC_Account__r') + '.' + PC_Constants.getQualifiedAPIName('PC_Primary_Address__r')
                                    + '.' + PC_Constants.getQualifiedAPIName('PC_Address_2__c'),
                            PC_Constants.getQualifiedAPIName('PC_Account__r') + '.' + PC_Constants.getQualifiedAPIName('PC_Primary_Address__r')
                                    + '.' + PC_Constants.getQualifiedAPIName('PC_Address_3__c'),
                            PC_Constants.getQualifiedAPIName('PC_Account__r') + '.' + PC_Constants.getQualifiedAPIName('PC_Primary_Address__r')
                                    + '.' + PC_Constants.getQualifiedAPIName('PC_City__c'),
                            PC_Constants.getQualifiedAPIName('PC_Account__r') + '.' + PC_Constants.getQualifiedAPIName('PC_Primary_Address__r')
                                    + '.' + PC_Constants.getQualifiedAPIName('PC_Zip_Code__c'),
                            PC_Constants.getQualifiedAPIName('PC_Account__r') + '.' + PC_Constants.getQualifiedAPIName('PC_Primary_Address__r')
                                    + '.' + PC_Constants.getQualifiedAPIName('PC_State__c'),
                            PC_Constants.getQualifiedAPIName('PC_Account__r') + '.' + PC_Constants.getQualifiedAPIName('PC_Primary_Address__r')
                                    + '.' + PC_Constants.getQualifiedAPIName('PC_Country__c'),
                            PC_Constants.getQualifiedAPIName('PC_Account__r') + '.' + PC_Constants.getQualifiedAPIName('PC_Primary_Address__c'),
                            PC_Constants.getQualifiedAPIName('PC_Account__r') + '.' + 'Phone',
                            PC_Constants.getQualifiedAPIName('PC_Account__r') + '.' + PC_Constants.getQualifiedAPIName('PC_Email__c'),
                            PC_Constants.getQualifiedAPIName('PC_Associated_User__c'),
                            PC_Constants.getQualifiedAPIName('PC_Associated_User__r') + '.' + 'Address',
                            PC_Constants.getQualifiedAPIName('PC_Associated_User__r') + '.' + 'Email',
                            PC_Constants.getQualifiedAPIName('PC_Associated_User__r') + '.' + 'Phone',
                            PC_Constants.getQualifiedAPIName('PC_Associated_User__r') + '.' + 'lastname',
                            PC_Constants.getQualifiedAPIName('PC_Associated_User__r') + '.' + 'firstname',
                            PC_Constants.getQualifiedAPIName('PC_Associated_User__r') + '.' + 'Street',
                            PC_Constants.getQualifiedAPIName('PC_Associated_User__r') + '.' + 'City',
                            PC_Constants.getQualifiedAPIName('PC_Associated_User__r') + '.' + 'State',
                            PC_Constants.getQualifiedAPIName('PC_Associated_User__r') + '.' + 'postalCode',
                            PC_Constants.getQualifiedAPIName('PC_Associated_User__r') + '.' + 'country',
                            PC_Constants.getQualifiedAPIName('PC_Program__c')
                    };
                    PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Association__c'), PC_Database.Operation.Reading, fields);
                    List<PC_Association__c> assList = [
                            SELECT Id, PC_Role__c, PC_Account__c,PC_Account__r.PC_First_Name__c, PC_Account__r.PC_Last_Name__c,
                                    PC_Account__r.PC_Primary_Address__r.PC_State__c,PC_Account__r.PC_Primary_Address__c, PC_Account__r.PC_Primary_Address__r.PC_Country__c,
                                    PC_Account__r.PC_Primary_Address__r.PC_Primary_Address__c,
                                    PC_Account__r.PC_Primary_Address__r.PC_Address_1__c,
                                    PC_Account__r.PC_Primary_Address__r.PC_Address_2__c,
                                    PC_Account__r.PC_Primary_Address__r.PC_Address_3__c,
                                    PC_Account__r.PC_Primary_Address__r.PC_City__c,PC_Account__r.PC_Primary_Address__r.PC_Zip_Code__c, PC_Account__r.Phone,
                                    PC_Account__r.PC_Email__c, PC_Associated_User__c, PC_Associated_User__r.Address,
                                    PC_Associated_User__r.Email, PC_Associated_User__r.Phone,PC_Program__c,PC_Associated_User__r.IsActive
                            FROM PC_Association__c
                            WHERE PC_Program__c = :caseId
                            AND PC_AssociationStatus__c = :PC_Constants.ACTIVE
                            AND PC_Role__c = :reporterRole

                    ];


                    if (assList != null) {
                        if (assList.size() > 1) {
                            /*
                        String exMessage = System.label.PC_MoreThanOneReporterErrMessage;
                        AuraHandledException ex = new AuraHandledException(exMessage);
                        PC_Utility.logAndThrowException(ex, exMessage); */

                            reportWrapper = new ReporterWrapper();


                            reportWrapper.waringMessage = 'true';   // this will act as a flag

                            return reportWrapper;


                        }

                        else {
                            if (assList.size() == 1) {
                                reportWrapper = new ReporterWrapper();
                                reportWrapper = fetchReporterWrapperValues(assList[0]);
                                return reportWrapper;
                            } else {
                                return null;
                            }
                        }
                    } else {
                        // no rows found
                        return null;
                    }

                }
            }
        }catch(Exception ex){
            PC_Utility.logAndThrowException(ex);
        }

        return null;
    }

    public static ReporterWrapper fetchReporterWrapperValues(PC_Association__c associationObj){
        try {
            ReporterWrapper reporterWrapper = new ReporterWrapper();
            if (associationObj.PC_Account__c != null ) {
                if (associationObj.PC_Account__r.PC_Email__c != null) {
                    reporterWrapper.email = String.valueOf(associationObj.PC_Account__r.PC_Email__c);
                }
                if (associationObj.PC_Account__r.PC_Last_Name__c != null) {
                    reporterWrapper.lastName = associationObj.PC_Account__r.PC_Last_Name__c;
                }
                if (associationObj.PC_Account__r.PC_First_Name__c != null) {
                    reporterWrapper.firstName = associationObj.PC_Account__r.PC_First_Name__c;
                }
                if (associationObj.PC_Account__r.PC_Primary_Address__c != null) {

                    if (associationObj.PC_Account__r.PC_Primary_Address__r.PC_Primary_Address__c == true) {

                        reporterWrapper.state = associationObj.PC_Account__r.PC_Primary_Address__r.PC_State__c;
                        reporterWrapper.zip = associationObj.PC_Account__r.PC_Primary_Address__r.PC_Zip_Code__c;
                        reporterWrapper.city = associationObj.PC_Account__r.PC_Primary_Address__r.PC_City__c;
                        reporterWrapper.country = associationObj.PC_Account__r.PC_Primary_Address__r.PC_Country__c;
                        reporterWrapper.address = getCompleteAddress(associationObj.PC_Account__r);
                    }
                }
                if (associationObj.PC_Account__r.phone != null) {

                    reporterWrapper.phone = String.valueOf(associationObj.PC_Account__r.phone);
                }


            } else {

                if (associationObj.PC_Associated_User__c != null) {
                    if (associationObj.PC_Associated_User__r.IsActive == true){
                        if (associationObj.PC_Associated_User__r.email != null) {
                            reporterWrapper.email = String.valueOf(associationObj.PC_Associated_User__r.email);
                        }
                        if (associationObj.PC_Associated_User__r.lastname != null) {
                            reporterWrapper.lastName = associationObj.PC_Associated_User__r.lastname;
                        }
                        if (associationObj.PC_Associated_User__r.firstname != null) {
                            reporterWrapper.firstName = associationObj.PC_Associated_User__r.firstname;
                        }
                        if (associationObj.PC_Associated_User__r.phone != null) {
                            reporterWrapper.phone = String.valueOf(associationObj.PC_Associated_User__r.phone);
                        }
                        if (associationObj.PC_Associated_User__r.Street != null) {
                            reporterWrapper.address += String.valueOf(associationObj.PC_Associated_User__r.Street) + '  ';
                        }
                        if (associationObj.PC_Associated_User__r.City != null) {
                            reporterWrapper.city = associationObj.PC_Associated_User__r.City;
                            reporterWrapper.address += String.valueOf(associationObj.PC_Associated_User__r.City) + ' ';
                        }
                        if (associationObj.PC_Associated_User__r.State != null) {
                            reporterWrapper.state = associationObj.PC_Associated_User__r.state;
                            reporterWrapper.address += String.valueOf(associationObj.PC_Associated_User__r.State) + '  ';
                        }// city state zip
                        if (associationObj.PC_Associated_User__r.postalCode != null) {
                            reporterWrapper.zip = associationObj.PC_Associated_User__r.postalCode;
                            reporterWrapper.address += String.valueOf(associationObj.PC_Associated_User__r.postalCode) + ' ';
                        }// city state zip
                        if (associationObj.PC_Associated_User__r.country != null) {
                            reporterWrapper.country = associationObj.PC_Associated_User__r.country;
                            reporterWrapper.address += String.valueOf(associationObj.PC_Associated_User__r.country) ;
                        }// city state zip
                    }
                }else{
                    return null;
                }

            }

            return reporterWrapper;
        }
        catch(Exception ex){
            PC_Utility.logAndThrowException(ex);

        }
        return null;
    }

    public static ReporterWrapper getRelatedPatientReporter(String caseIdParam, String patientIdParam){
        try {

            Id patientId = null;
            if(String.isNotBlank(patientIdParam)){
                patientId = Id.valueOf(patientIdParam);
            }

            if(patientId == null && String.isNotBlank(caseIdParam)){
                List<String> caseFields = new List<String>();
                caseFields.add('AccountId');
                PC_Database.assertAccess(PC_Constants.PC_CASE, PC_Database.Operation.Reading, caseFields);

                List<Case> caseList = [Select AccountId from Case where id =:caseIdParam LIMIT 1];

                if(caseList !=null) {
                    patientId = caseList[0].AccountId;
                }
            }

            patientIdParameter = patientId;



            List<String> fields = new List<String>();
            fields.add(PC_Constants.getQualifiedAPIName('PC_First_Name__c'));
            fields.add(PC_Constants.getQualifiedAPIName('PC_Last_Name__c'));
            fields.add('Phone');
            fields.add(PC_Constants.getQualifiedAPIName('PC_Email__c'));
            fields.add(PC_Constants.getQualifiedAPIName('PC_Primary_Address__c'));
            fields.add(PC_Constants.getQualifiedAPIName('PC_Primary_Address__r') +'.'+PC_Constants.getQualifiedAPIName('PC_Zip_Code__c'));
            fields.add(PC_Constants.getQualifiedAPIName('PC_Primary_Address__r') +'.'+PC_Constants.getQualifiedAPIName('PC_Country__c'));
            fields.add(PC_Constants.getQualifiedAPIName('PC_Primary_Address__r') +'.'+PC_Constants.getQualifiedAPIName('PC_City__c'));
            fields.add(PC_Constants.getQualifiedAPIName('PC_Primary_Address__r') +'.'+PC_Constants.getQualifiedAPIName('PC_State__c'));
            fields.add(PC_Constants.getQualifiedAPIName('PC_Primary_Address__r') +'.'+PC_Constants.getQualifiedAPIName('PC_Address_1__c'));
            fields.add(PC_Constants.getQualifiedAPIName('PC_Primary_Address__r') +'.'+PC_Constants.getQualifiedAPIName('PC_Address_2__c'));
            fields.add(PC_Constants.getQualifiedAPIName('PC_Primary_Address__r') +'.'+PC_Constants.getQualifiedAPIName('PC_Address_3__c'));
            fields.add(PC_Constants.getQualifiedAPIName('PC_Primary_Address__r') +'.'+PC_Constants.getQualifiedAPIName('PC_Primary_Address__c'));

            PC_Database.assertAccess(PC_Constants.PC_ACCOUNT, PC_Database.Operation.Reading, fields);
            List<Account> acclist = [
                    Select  PC_First_Name__c, PC_Last_Name__c,PC_Primary_Address__c, Phone,
                            PC_Email__c,
                            PC_Primary_Address__r.PC_Address_1__c, PC_Primary_Address__r.PC_Address_2__c, PC_Primary_Address__r.PC_Address_3__c,
                            PC_Primary_Address__r.PC_State__c , PC_Primary_Address__r.PC_City__c ,PC_Primary_Address__r.PC_Zip_Code__c,
                            PC_Primary_Address__r.PC_Country__c, PC_Primary_Address__r.PC_Primary_Address__c
                    From Account
                    where Id = :patientId
                    LIMIT 1
            ];

            if (acclist != null ) {

                if ( (acclist.size()>0)) {
                    ReporterWrapper accReporter = new ReporterWrapper();

                    accReporter.firstName = acclist[0].PC_First_Name__c;
                    accReporter.lastName = acclist[0].PC_Last_Name__c;
                    if (acclist[0].PC_Primary_Address__c != null && (acclist[0].PC_Primary_Address__r.PC_Primary_Address__c == true)) {
                        accReporter.state = acclist[0].PC_Primary_Address__r.PC_State__c;
                        accReporter.city = acclist[0].PC_Primary_Address__r.PC_City__c;
                        accReporter.zip = acclist[0].PC_Primary_Address__r.PC_Zip_Code__c;
                        accReporter.country = acclist[0].PC_Primary_Address__r.PC_Country__c;
                    }

                    accReporter.email = String.valueOf(acclist[0].PC_Email__c);
                    accReporter.phone = String.valueOf(acclist[0].Phone);


                    if (Account.PC_Primary_Address__c != null) {
                        accReporter.address = getCompleteAddress(acclist[0]);
                    }


                    return accReporter;

                }
            }
        } catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return null;
    }

    private static String getCompleteAddress(Account accountWithPrimaryAddress) {
        String completeAddress = '';
        if(String.isNotBlank(accountWithPrimaryAddress.PC_Primary_Address__r.PC_Address_1__c)) {
            completeAddress = completeAddress + accountWithPrimaryAddress.PC_Primary_Address__r.PC_Address_1__c;
        }
        if(String.isNotBlank(accountWithPrimaryAddress.PC_Primary_Address__r.PC_Address_2__c)) {
            if(String.isNotBlank(completeAddress)) {
                completeAddress = completeAddress + ', ';
            }
            completeAddress = completeAddress + accountWithPrimaryAddress.PC_Primary_Address__r.PC_Address_2__c;
        }
        if(String.isNotBlank(accountWithPrimaryAddress.PC_Primary_Address__r.PC_Address_3__c)) {
            if(String.isNotBlank(completeAddress)) {
                completeAddress = completeAddress + ', ';
            }
            completeAddress = completeAddress + accountWithPrimaryAddress.PC_Primary_Address__r.PC_Address_3__c;
        }
        return completeAddress;
    }

    public void updateAdverseEvent(PC_AdverseEvent__c aeRec, Map<Object,Object> initialReporterObj) {
        aeRec.PC_Reporter_First_Name__c  = (String)initialReporterObj.get('firstName');
        aeRec.PC_Reporter_Last_Name__c = (String)initialReporterObj.get('lastName');
        aeRec.PC_ReporterAddress__c = (String)initialReporterObj.get('address');
        aeRec.PC_Reporter_City__c = (String)initialReporterObj.get('city');
        aeRec.PC_Reporter_State__c = (String)initialReporterObj.get('state');
        aeRec.PC_Reporter_Country__c = (String)initialReporterObj.get('country');
        aeRec.PC_Reporter_Zip_Code__c = (String)initialReporterObj.get('zip');
        aeRec.PC_Reporter_Email__c = (String)initialReporterObj.get('email');
        aeRec.PC_Reporter_Phone__c = (String)initialReporterObj.get('phone');
        String reporterType = (String) initialReporterObj.get('occupation');
        if(reporterType != 'None'){
            aeRec.PC_Adverse_Event_Reporter__c = reporterType;
        }
        aeRec.PC_Ini_Reporter_Also_Sent_Report_to_FDA__c = (String)initialReporterObj.get('IRalsoSentReportToFDA');
        aeRec.PC_HealthCareProfessional__c = (String)initialReporterObj.get('healthCareProfessional');
    }

    public static List<PicklistWrapper> getReporterTypePicklistValues(){
        PicklistWrapper picklistObj ;
        List<PicklistWrapper> fieldValueWrapperList = new List<PicklistWrapper>();
        picklistObj = new PicklistWrapper();

        picklistObj.label =System.Label.PC_Picklist_None ;
        picklistObj.value = PC_Constants.EMPTY_STRING;

        fieldValueWrapperList.add(picklistObj);
        Schema.DescribeFieldResult picklistFieldResult = PC_AdverseEvent__c.PC_Adverse_Event_Reporter__c.getDescribe();
        List<Schema.PicklistEntry> picklistValueList = picklistFieldResult.getPicklistValues();
        for (Schema.PicklistEntry picklistValue : picklistValueList) {
            picklistObj = new PicklistWrapper();
            picklistObj.label = picklistValue.getLabel();
            picklistObj.value = picklistValue.getValue();
            fieldValueWrapperList.add(picklistObj);

            if (picklistObj.value == PC_Constants.DEFAULT_REPORTER_TYPE_PICKLIST) {
                isDefaultReporterTypePicklistPresent = true;
            }
        }
        return fieldValueWrapperList;
    }

    public static List<PicklistWrapper> getReporterSent2FdaPicklistValues(){
        PicklistWrapper picklistObj ;
        List<PicklistWrapper> fieldValueWrapperList = new List<PicklistWrapper>();
        Schema.DescribeFieldResult picklistFieldResult = PC_AdverseEvent__c.PC_Ini_Reporter_Also_Sent_Report_to_FDA__c.getDescribe();
        List<Schema.PicklistEntry> picklistValueList = picklistFieldResult.getPicklistValues();
        for (Schema.PicklistEntry picklistValue : picklistValueList) {
            picklistObj = new PicklistWrapper();
            picklistObj.label = picklistValue.getLabel();
            picklistObj.value = picklistValue.getValue();
            fieldValueWrapperList.add(picklistObj);
        }
        return fieldValueWrapperList;
    }

    public static List<PicklistWrapper> getHealthCareProfessionalPicklistValues(){
        PicklistWrapper picklistObj ;
        List<PicklistWrapper> fieldValueWrapperList = new List<PicklistWrapper>();
        Schema.DescribeFieldResult picklistFieldResult = PC_AdverseEvent2__c.PC_HealthCareProfessional__c.getDescribe();
        List<Schema.PicklistEntry> picklistValueList = picklistFieldResult.getPicklistValues();
        for (Schema.PicklistEntry picklistValue : picklistValueList) {
            picklistObj = new PicklistWrapper();
            picklistObj.label = picklistValue.getLabel();
            picklistObj.value = picklistValue.getValue();
            fieldValueWrapperList.add(picklistObj);
        }
        return fieldValueWrapperList;
    }

    public inherited sharing class InitialReporterFormData{

        @AuraEnabled public FieldLabels fieldLabels;
        @AuraEnabled public List<PicklistWrapper> reporterTypeOptions;
        @AuraEnabled public List<PicklistWrapper> healthCareProfessionalReporterTypeOptions;
        @AuraEnabled public List<PicklistWrapper> nonHealthCareProfessionalReporterTypeOptions;
        @AuraEnabled public List<PicklistWrapper> reporterSentToFdaOptions;
        @AuraEnabled public List<PicklistWrapper> healthCareProfessionalOptions;
        @AuraEnabled public Id patientIdValue ;
        @AuraEnabled public ReporterWrapper defaultPatientReporter;
        @AuraEnabled public String defaultReporterTypeValue;
        @AuraEnabled public String defaultHealthCareProfessionalValue;
    }
    public inherited sharing class PicklistWrapper {
        @AuraEnabled public String label {get; set;}
        @AuraEnabled public String value {get; set;}

        public PicklistWrapper(){
        }
    }

    /*********************************************************
    Method Name          	: getInitialReporterLabels
    Description             : get Field Labels of Adverse Event Fields on Initial Reporter Tab
    Input Params            : NA
    Return Type             : FieldLabels Wrapper
    *********************************************************************************/
    public static FieldLabels getInitialReporterLabels(){

        FieldLabels fieldlabels = new FieldLabels();
        fieldlabels.reporterFirstName = PC_AdverseEvent__c.PC_Reporter_First_Name__c.getDescribe().getLabel();
        fieldlabels.reporterLastName	= PC_AdverseEvent__c.PC_Reporter_Last_Name__c.getDescribe().getLabel();
        fieldlabels.reporterAddress	= PC_AdverseEvent__c.PC_ReporterAddress__c.getDescribe().getLabel();
        fieldlabels.reporterCity = PC_AdverseEvent__c.PC_Reporter_City__c.getDescribe().getLabel();
        fieldlabels.reporterState = PC_AdverseEvent__c.PC_Reporter_State__c.getDescribe().getLabel();
        fieldlabels.reporterCountry = PC_AdverseEvent__c.PC_Reporter_Country__c.getDescribe().getLabel();
        fieldlabels.reporterZip = PC_AdverseEvent__c.PC_Reporter_Zip_Code__c.getDescribe().getLabel();
        fieldlabels.reporterEmail	= PC_AdverseEvent__c.PC_Reporter_Email__c.getDescribe().getLabel();
        fieldlabels.reporterPhone	= PC_AdverseEvent__c.PC_Reporter_Phone__c.getDescribe().getLabel();
        fieldlabels.occupation = PC_AdverseEvent__c.PC_Adverse_Event_Reporter__c.getDescribe().getLabel();
        fieldlabels.reporterSentToFda = PC_AdverseEvent__c.PC_Ini_Reporter_Also_Sent_Report_to_FDA__c.getDescribe().getLabel();
        fieldlabels.healthCareProfessional = PC_AdverseEvent2__c.PC_HealthCareProfessional__c.getDescribe().getLabel();

        return fieldlabels;
    }

    public inherited sharing class FieldLabels {
        @AuraEnabled public String reporterFirstName { get; set; }
        @AuraEnabled public String reporterLastName { get; set; }
        @AuraEnabled public String reporterAddress { get; set; }
        @AuraEnabled public String reporterCity { get; set; }
        @AuraEnabled public String reporterState { get; set; }
        @AuraEnabled public String reporterCountry { get; set;}
        @AuraEnabled public String reporterZip{ get; set; }
        @AuraEnabled public String reporterEmail{ get; set; }
        @AuraEnabled public String reporterPhone{ get; set; }
        @AuraEnabled public String occupation{ get; set; }
        @AuraEnabled public String reporterSentToFda{ get; set; }
        @AuraEnabled public String healthCareProfessional{ get; set; }

        public FieldLabels() {
        }
    }


    public inherited sharing class ReporterWrapper {
        @AuraEnabled public String firstName { get; set; }
        @AuraEnabled public String lastName { get; set; }
        @AuraEnabled public String city { get; set; }
        @AuraEnabled public String state { get; set; }
        @AuraEnabled public String country { get; set; }
        @AuraEnabled public String zip { get; set; }
        @AuraEnabled public String email { get; set; }
        @AuraEnabled public String phone { get; set; }
        @AuraEnabled public String address { get; set; }
        @AuraEnabled public String waringMessage { get; set; }

        public ReporterWrapper() {

            firstName = PC_Constants.EMPTY_STRING ;
            lastName = PC_Constants.EMPTY_STRING ;
            city = PC_Constants.EMPTY_STRING ;
            state = PC_Constants.EMPTY_STRING ;
            country = PC_Constants.EMPTY_STRING ;
            zip = PC_Constants.EMPTY_STRING ;
            email = PC_Constants.EMPTY_STRING ;
            phone = PC_Constants.EMPTY_STRING ;
            address = PC_Constants.EMPTY_STRING ;
            waringMessage = PC_Constants.EMPTY_STRING;
        }
    }
}