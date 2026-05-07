/*********************************************************************************************************
Class Name      : PC_MedicalBenefitsInputScreenController
Description     : Controller for PC_MedicalBenefitsInputScreen
Created By      : Hitha Avalakki
Created Date    : Jan 31, 2019
Modification Log:
-----------------------------------------------------------------------------------------------------
Developer                   Date                           Description
-----------------------------------------------------------------------------------------------------
Hitha Avalakki              Jan 31, 2019                   Initial Version
Shishir Bansal              Feb 18 , 2019                  [PC-4327 ] logic to fetch active prescriptions
                                                            list related to the program case
Haritha Reddy               Mar 20 , 2019                  [PC-4167] added logic to check required fields on submit
Shishir Bansal              Mar 27, 2019                   [PC-4147] Masking of patient SSN on the UI
Vijay Kashikar              Apr 23, 2019                   [PC-4574] Creating program coverages only when the response is a success. (Added conditions)
*********************************************************************************************************/

public with sharing class PC_MedicalBenefitsInputScreenController {

    public static String COLON=' : ';

    /*****************************************************************************************
    Method Name    : getMedicalBenefitsInfo
    Author         : Hitha Avalakki
    Description    : This method is used to fetch Health Plan,Prescription and Clinic data
                     for Medical Benefits investigation
    Return Type    : MedicalBenefitsFormData
    Parameter      : Id
    User Story     : PC-4130
    ******************************************************************************************/
    @AuraEnabled
    public static MedicalBenefitsFormData getMedicalBenefitsInfo(Id caseId) {
        MedicalBenefitsFormData medicalBenefitsFormData;
        List<PC_Prescription__c> prescriptionList = new List<PC_Prescription__c>();

        try {
            medicalBenefitsFormData=new MedicalBenefitsFormData();
            Id medicalHealthPlanRecTypeId=(Id)PC_SYSTEM.recordTypeId(PC_Constants.PC_HEALTH_PLAN,
                                                                        PC_Constants.HEALTH_PLAN_MEDICAL_RECORD_TYPE);

            Id patientRecordId=PC_eBenefits.getAccountIdByCaseId(caseId);

            if(patientRecordId!=null){

                /*** PC-4130, PC-4131: Logic to fetch primary,secondary and tertiary Health Plans and their details *** START ***/
                //Refactored code
                HealthPlanInfoWrapper healthPlanInfoWrapper=new HealthPlanInfoWrapper();

                healthPlanInfoWrapper=getHealthPlanInfo(patientRecordId);

                if(healthPlanInfoWrapper!=null){
                    if(healthPlanInfoWrapper.primaryHealthPlansList!=null && !healthPlanInfoWrapper.primaryHealthPlansList.isEmpty()){
                        medicalBenefitsFormData.formData.primaryHealthPlansList.addAll(healthPlanInfoWrapper.primaryHealthPlansList);
                    }
                    if(healthPlanInfoWrapper.secondaryHealthPlansList!=null && !healthPlanInfoWrapper.secondaryHealthPlansList.isEmpty()){
                        medicalBenefitsFormData.formData.secondaryHealthPlansList.addAll(healthPlanInfoWrapper.secondaryHealthPlansList);
                    }
                    if(healthPlanInfoWrapper.tertiaryHealthPlansList!=null && !healthPlanInfoWrapper.tertiaryHealthPlansList.isEmpty()){
                        medicalBenefitsFormData.formData.tertiaryHealthPlansList.addAll(healthPlanInfoWrapper.tertiaryHealthPlansList);
                    }
                    if(healthPlanInfoWrapper.noPlanTypeHealthPlansList!=null && !healthPlanInfoWrapper.noPlanTypeHealthPlansList.isEmpty()){
                        medicalBenefitsFormData.formData.noPlanTypeHealthPlansList.addAll(healthPlanInfoWrapper.noPlanTypeHealthPlansList);
                    }
                }

                /*** PC-4130, PC-4131: Logic to fetch primary,secondary and tertiary Health Plans and their details *** END ***/

                /*** PC-4132, PC-4133: Logic to fetch Clinic and Clinic NPI details *** START ***/
                ClinicInfoWrapper clinicInfoWrapper=getClinicInfo(caseId);

                if(clinicInfoWrapper!=null && clinicInfoWrapper.clinicDetailsList!=null && !clinicInfoWrapper.clinicDetailsList.isEmpty()){
                    medicalBenefitsFormData.formData.clinicDetailsList.addAll(clinicInfoWrapper.clinicDetailsList);
                }

                /*** PC-4132, PC-4133: Logic to fetch Clinic and Clinic NPI details *** END ***/

                /*** PC-4360, PC-4327: Logic to fetch prescriptions and their details *** START ***/

                PrescriptionInfoWrapper prescriptionInfoWrapper=getPrescriptionInfo(caseId);
                if(prescriptionInfoWrapper!=null &&
                   prescriptionInfoWrapper.prescriptionDetailsList!=null && !prescriptionInfoWrapper.prescriptionDetailsList.isEmpty()){
                    medicalBenefitsFormData.formData.prescriptionDetailsList.addAll(prescriptionInfoWrapper.prescriptionDetailsList);
                }
                /*** PC-4360, PC-4327: Logic to fetch prescriptions and their details *** END ***/

                /********* PC-4147: Fetch Patient Information: START *********/
                PatientInfoWrapper patientInfoWrapper=new PatientInfoWrapper();

                patientInfoWrapper=getPatientInfoData(patientRecordId);
                medicalBenefitsFormData.formData.patientDetails.ssn=patientInfoWrapper.ssnVal;

                if(patientInfoWrapper!=null && !patientInfoWrapper.patientRecList.isEmpty()){
                    medicalBenefitsFormData.formData.patientDetails.id=patientInfoWrapper.patientRecList[0].Id;
                    medicalBenefitsFormData.formData.patientDetails.firstName=patientInfoWrapper.patientRecList[0].PC_First_Name__c;
                    medicalBenefitsFormData.formData.patientDetails.lastName=patientInfoWrapper.patientRecList[0].PC_Last_Name__c;
                    medicalBenefitsFormData.formData.patientDetails.dob=patientInfoWrapper.patientRecList[0].PC_Date_of_Birth__c;
                    medicalBenefitsFormData.formData.patientDetails.gender=patientInfoWrapper.patientRecList[0].PC_Gender__c;
                    medicalBenefitsFormData.formData.patientDetails.zipCode=patientInfoWrapper.patientRecList[0].PC_Primary_Zip_Code__c;
                }
                /********* PC-4147: Fetch Patient Information: END *********/
         }

        }
        catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return medicalBenefitsFormData;
    }

    /*****************************************************************************************
    Method Name    : getPatientInfoData
    Author         : Hitha Avalakki
    Description    : This method is used to fetch Patient Information details

    Return Type    :PatientInfoWrapper
    Parameter      :Id patientRecordId
    User Story     : PC-4147
    ******************************************************************************************/
    @AuraEnabled
    public static PatientInfoWrapper getPatientInfoData(Id patientRecordId) {

        PatientInfoWrapper patientInfoWrapper=new PatientInfoWrapper();
        Map<String, Object> accountIdentifiersMap=new Map<String, Object>();
        /*
         * FLS Check for PC_Health_Plan__c
         */
        List<String> accountFields = new List<String>{PC_Constants.getQualifiedAPIName('PC_First_Name__c'), PC_Constants.getQualifiedAPIName('PC_Last_Name__c'),PC_Constants.getQualifiedAPIName('PC_Date_of_Birth__c'),
                PC_Constants.getQualifiedAPIName('PC_Gender__c'),PC_Constants.getQualifiedAPIName('PC_Primary_Zip_Code__c')};
        PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('Account'), PC_Database.Operation.Reading, accountFields);



        List<Account> patientRecList=[SELECT Id,PC_First_Name__c, PC_Last_Name__c,PC_Date_of_Birth__c, PC_Gender__c, PC_Primary_Zip_Code__c
                                      FROM Account
                                      WHERE Id=: patientRecordId];

        List<String> accountIdentifierFields = new List<String>{
                PC_Constants.getQualifiedAPIName('Name'),
                PC_Constants.getQualifiedAPIName('PC_Account__c'),
                PC_Constants.getQualifiedAPIName('PC_Assigner__c'),
                PC_Constants.getQualifiedAPIName('PC_Type__c'),
                PC_Constants.getQualifiedAPIName('PC_Value__c')
        };
        //check access before SOQL
        PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Account_Identifier__c'),
                PC_Database.Operation.Reading, accountIdentifierFields);

        String accIdentifier = null;

        accIdentifier=PC_SYSTEM.getAccountIdentifier(patientRecordId,
                                                       PC_Constants.ACCOUNT_IDENTIFIER_TYPE_SSN,
                                                        PC_Constants.ACCOUNT_IDENTIFIER_ASSIGNER_US_SSN);

        String maskedSSN_String ='';
        if(!String.isEmpty(accIdentifier)) {

            maskedSSN_String = PC_SYSTEM.getMaskedSSNvalue(accIdentifier);
        }

        patientInfoWrapper.ssnVal=maskedSSN_String;
        patientInfoWrapper.patientRecList=patientRecList;
        return patientInfoWrapper;
    }

    /*****************************************************************************************
    Method Name    : getHealthPlanInfo
    Author         : Hitha Avalakki
    Description    : This method is used to fetch Health Plan Information details

    Return Type    : PatientInfoWrapper
    Parameter      : Id patientRecordId
    User Story     : PC-4147
    ******************************************************************************************/
    @AuraEnabled
    public static HealthPlanInfoWrapper getHealthPlanInfo(Id patientRecordId) {
        HealthPlanInfoWrapper healthPlanInfoWrapper=new HealthPlanInfoWrapper();
        Id medicalHealthPlanRecTypeId=(Id)PC_SYSTEM.recordTypeId(PC_Constants.PC_HEALTH_PLAN, PC_Constants.HEALTH_PLAN_MEDICAL_RECORD_TYPE);
        /*
        * FLS Check for PC_Health_Plan__c
        */
        List<String> healthPlanFields = new List<String>{PC_Constants.getQualifiedAPIName('PC_Plan_Name__c'), PC_Constants.getQualifiedAPIName('PC_Payer__c'),PC_Constants.getQualifiedAPIName('PC_Plan_Type__c'),
                PC_Constants.getQualifiedAPIName('PC_Payer_Name__c'),PC_Constants.getQualifiedAPIName('PC_Cardholder_Relationship_to_Patient__c'),PC_Constants.getQualifiedAPIName('ID_Policy_No__c')};

        PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Health_Plan__c'), PC_Database.Operation.Reading, healthPlanFields);


        //Get the list of all active medical plans for the patientRecordId
        List<PC_Health_Plan__c> medicalHealthPlansList=[SELECT Id, PC_Plan_Name__c, PC_Payer__c, toLabel(PC_Plan_Type__c), Name, PC_Payer_Name__c,
                PC_Cardholder_Relationship_to_Patient__c, ID_Policy_No__c
        FROM PC_Health_Plan__c
        WHERE Patient__c =: patientRecordId AND
        RecordTypeId =: medicalHealthPlanRecTypeId AND
        PC_Plan_Status__c=:PC_Constants.ACTIVE];

        //Prepare the list of PC_eBenefits.PicklistWrapper with the details related to health plan
        for(PC_Health_Plan__c medicalHealthPlanObj: medicalHealthPlansList){

            PC_eBenefits.HealthPlan healthPlanObj=new PC_eBenefits.HealthPlan();
            healthPlanObj.healthPlanLabel=getHealthPlanLabel(medicalHealthPlanObj);
            healthPlanObj.id=medicalHealthPlanObj.Id;
            healthPlanObj.isHealthPlanSelected=false;
            healthPlanObj.planType=medicalHealthPlanObj.PC_Plan_Type__c;
            healthPlanObj.payerName=medicalHealthPlanObj.PC_Payer_Name__c;
            healthPlanObj.planName=medicalHealthPlanObj.PC_Plan_Name__c;
            healthPlanObj.memberId=medicalHealthPlanObj.ID_Policy_No__c;
            healthPlanObj.relationshipToCardholderLabel= getHealthPlanCardRelationLabel(medicalHealthPlanObj);
            healthPlanObj.relationshipToCardholder = medicalHealthPlanObj.PC_Cardholder_Relationship_to_Patient__c;

            if(PC_Constants.HEALTH_PLAN_TYPE_PRIMARY.equals(healthPlanObj.planType)){
                healthPlanInfoWrapper.primaryHealthPlansList.add(healthPlanObj);
            }
            else if(PC_Constants.HEALTH_PLAN_TYPE_SECONDARY.equals(healthPlanObj.planType)){
                healthPlanInfoWrapper.secondaryHealthPlansList.add(healthPlanObj);
            }
            else if(PC_Constants.HEALTH_PLAN_TYPE_TERTIARY.equals(healthPlanObj.planType)){
                healthPlanInfoWrapper.tertiaryHealthPlansList.add(healthPlanObj);
            }
            else{
                healthPlanInfoWrapper.noPlanTypeHealthPlansList.add(healthPlanObj);
            }
        }
        return healthPlanInfoWrapper;
    }

    public static String getHealthPlanCardRelationLabel(PC_Health_Plan__c healthPlan) {
        if(healthPlan != null) {
            List<PC_PicklistFieldManager.PicklistEntryWrapper> relationships =
                    PC_PicklistFieldManager.getPicklistEntryWrappers(PC_Health_Plan__c.PC_Cardholder_Relationship_to_Patient__c);
            system.debug('@translation');
            system.debug(relationships);
            for (PC_PicklistFieldManager.PicklistEntryWrapper r : relationships) {
                if (r.value == healthPlan.PC_Cardholder_Relationship_to_Patient__c) {
                    return r.label;
                }
            }
        }
        return null;
    }
    /*****************************************************************************************
    Method Name    : getClinicInfo
    Author         : Hitha Avalakki
    Description    : This method is used to fetch Clinic details

    Return Type    : ClinicInfoWrapper
    Parameter      : Id caseId
    User Story     : PC-4147
    ******************************************************************************************/
    @AuraEnabled
    public static ClinicInfoWrapper getClinicInfo(Id caseId) {

        ClinicInfoWrapper clinicInfoWrapper=new ClinicInfoWrapper();
        /*
        * FLS Check for PC_Association__c
        */
        List<String> associationFields = new List<String>{PC_Constants.getQualifiedAPIName('PC_Account__c')};
        PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Association__c'), PC_Database.Operation.Reading, associationFields);

        /*
        * FLS Check for Account
        */
        List<String> accountFields = new List<String>{PC_Constants.getQualifiedAPIName('PC_NPI__c')};
        PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('Account'), PC_Database.Operation.Reading, accountFields);

        Id hcoRecordTypeId=(Id)PC_SYSTEM.recordTypeId(PC_Constants.PATIENT_OBJECT, PC_Constants.HCO_RecordType);
        List<Id> accountIdList=new List<Id>();
        List<PC_Association__c> associationList=[SELECT Id, PC_Account__c FROM  PC_Association__c WHERE PC_Program__c=:caseId AND PC_AssociationStatus__c=: PC_Constants.ACTIVE];

        if(associationList!=null && !associationList.isEmpty()){
            for(PC_Association__c associationRec:associationList){
                accountIdList.add(associationRec.PC_Account__c);
            }
        }

        List<Account> hcoAccountList=[SELECT Id,Name, PC_NPI__c FROM Account WHERE Id IN: accountIdList and RecordTypeId=:hcoRecordTypeId];

        for(Account hcoAccount: hcoAccountList){
            PC_eBenefits.Clinic clinicObj=new PC_eBenefits.Clinic();
            clinicObj.clinicId=hcoAccount.Id;
            clinicObj.name=hcoAccount.Name;
            clinicObj.npi=hcoAccount.PC_NPI__c;
            clinicInfoWrapper.clinicDetailsList.add(clinicObj);
        }
        return clinicInfoWrapper;

    }

    /*****************************************************************************************
    Method Name    : getPrescriptionInfo
    Author         : Hitha Avalakki
    Description    : This method is used to fetch Prescription details

    Return Type    : PrescriptionInfoWrapper
    Parameter      : Id caseId
    User Story     : PC-4147
    ******************************************************************************************/
    @AuraEnabled
    public static PrescriptionInfoWrapper getPrescriptionInfo(Id caseId) {

        PrescriptionInfoWrapper prescriptionInfoWrapper=new PrescriptionInfoWrapper();
        List<PC_Prescription__c> prescriptionList = new List<PC_Prescription__c>();

        /*
        * FLS Check for PC_Prescription__c
        */
        List<String> prescriptionFields = new List<String>{
                PC_Constants.getQualifiedAPIName('PC_Rx_Status__c'),
                PC_Constants.getQualifiedAPIName('PC_Physician_Account__r') + '.'+ 'Name',
                PC_Constants.getQualifiedAPIName('PC_Physician_Account__r') + '.'+ PC_Constants.getQualifiedAPIName('PC_Primary_State__c'),
                PC_Constants.getQualifiedAPIName('PC_Product__r') + '.'+ 'Name',
                PC_Constants.getQualifiedAPIName('PC_Product__r') + '.'+  PC_Constants.getQualifiedAPIName('PC_Manufacturer__r') + '.'+'Name',
                PC_Constants.getQualifiedAPIName('PC_Product__r') + '.'+  PC_Constants.getQualifiedAPIName('PC_Strength__c'),
                PC_Constants.getQualifiedAPIName('PC_PlaceOfService__c'),
                PC_Constants.getQualifiedAPIName('PC_PrimaryDiagnosis__c'),
                PC_Constants.getQualifiedAPIName('PC_SecondaryDiagnosis__c'),
                PC_Constants.getQualifiedAPIName('PC_Product__r') + '.'+  PC_Constants.getQualifiedAPIName('PC_CPT_Codes__c'),
                PC_Constants.getQualifiedAPIName('PC_Physician_Account__r') + '.'+ PC_Constants.getQualifiedAPIName('PC_NPI__c')};

        PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Prescription__c'), PC_Database.Operation.Reading, prescriptionFields);

        //Get the list of all active  prescriptions from the patientRecordId
        prescriptionList=[SELECT Id, Name, PC_Physician_Account__r.PC_First_Name__c, PC_Physician_Account__r.PC_Last_Name__c, PC_Physician_Account__r.PC_Primary_State__c, PC_Product__r.Name,
                PC_Product__r.PC_Manufacturer__r.Name,PC_Product__r.PC_Strength__c ,PC_PlaceOfService__c , PC_PrimaryDiagnosis__c, PC_SecondaryDiagnosis__c, CreatedDate,
                PC_Product__r.PC_CPT_Codes__c, PC_Physician_Account__r.PC_NPI__c
        FROM PC_Prescription__c
        WHERE PC_Program_Case__c = :caseId AND  PC_Rx_Status__c =:PC_Constants.TRUE_BOOLEAN AND PC_Product__c != :PC_Constants.EMPTY_STRING ];

        // system.debug('testing-->'+PC_Prescription__c.PC_PrimaryDiagnosis__c.getDescribe().getPicklistValues().getLabel());

        Map <String, String > placeOfServiceMap = new Map<String, String>();

        Schema.DescribeFieldResult fieldPlaceOfServiceResult = PC_Prescription__c.PC_PlaceOfService__c.getDescribe();
        List<Schema.PicklistEntry> placeOfServiceValues = fieldPlaceOfServiceResult.getPicklistValues();
        for (Schema.PicklistEntry f : placeOfServiceValues) {
            System.debug('Label ='+ f.getLabel()+' === Value ='+ f.getValue());
            placeOfServiceMap.put(f.getValue(), f.getLabel());
        }

        Map <String, String > primaryDiagnosisMap = new Map<String, String>();

        Schema.DescribeFieldResult fieldpResult = PC_Prescription__c.PC_PrimaryDiagnosis__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldpResult.getPicklistValues();
        for (Schema.PicklistEntry f : ple) {
            System.debug('Label ='+ f.getLabel()+' === Value ='+ f.getValue());
            primaryDiagnosisMap.put(f.getValue(), f.getLabel());
        }

        Map <String, String > secondaryDiagnosisMap = new Map<String, String>();

        Schema.DescribeFieldResult fieldsResult = PC_Prescription__c.PC_SecondaryDiagnosis__c.getDescribe();
        List<Schema.PicklistEntry> ples = fieldsResult.getPicklistValues();
        for (Schema.PicklistEntry f : ples) {
            System.debug('Label ='+ f.getLabel()+' === Value ='+ f.getValue());
            secondaryDiagnosisMap.put(f.getValue(), f.getLabel());
        }

        if(!prescriptionList.isEmpty()){

            for(PC_Prescription__c activePrescription : prescriptionList ){
                PC_eBenefits.Prescription prescriptionObj = new  PC_eBenefits.Prescription();
                prescriptionObj.name = activePrescription.PC_Product__r.Name + COLON + activePrescription.CreatedDate.month()+ COLON +  activePrescription.CreatedDate.year() ;
                prescriptionObj.id = activePrescription.id;
                prescriptionObj.drug = new PC_eBenefits.Product();
                prescriptionObj.drug.name = activePrescription.PC_Product__r.Name;
                prescriptionObj.drug.drugManufacturerName = activePrescription.PC_Product__r.PC_Manufacturer__r.Name;
                prescriptionObj.drug.strength = activePrescription.PC_Product__r.PC_Strength__c;

                prescriptionObj.physician = new PC_eBenefits.Physician();
                prescriptionObj.physician.firstName = activePrescription.PC_Physician_Account__r.PC_First_Name__c;
                prescriptionObj.physician.lastName = activePrescription.PC_Physician_Account__r.PC_Last_Name__c;
                prescriptionObj.physician.address = new PC_eBenefits.Address();
                prescriptionObj.physician.address.state = activePrescription.PC_Physician_Account__r.PC_Primary_State__c;
                prescriptionObj.primaryDiagnosis = '';
                prescriptionObj.secondaryDiagnosis  ='';
                prescriptionObj.physician.npi  =activePrescription.PC_Physician_Account__r.PC_NPI__c;
                if(activePrescription.PC_Product__r.PC_CPT_Codes__c != null){
                    List<String> adminCodelst = activePrescription.PC_Product__r.PC_CPT_Codes__c.split(';');
                    List<PC_eBenefits.keyValue> options = new List<PC_eBenefits.keyValue>();

                    Schema.DescribeFieldResult fieldResult = Product2.PC_CPT_Codes__c.getDescribe();
                    List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
                    for( Schema.PicklistEntry picklistValue : picklistValues){
                        for(String adminCode : adminCodelst) {
                            if(adminCode == picklistValue.getValue()){
                                PC_eBenefits.keyValue option = new PC_eBenefits.keyValue();
                                option.value =  picklistValue.getValue();
                                option.label =  picklistValue.getLabel();
                                options.add(option);
                            }
                        }
                    }
                    prescriptionObj.adminCodes = options;
                }

                if(  activePrescription.PC_PlaceOfService__c !=null) {
                    prescriptionObj.placeOfService = placeOfServiceMap.get(activePrescription.PC_PlaceOfService__c);
                }

                if(  activePrescription.PC_PrimaryDiagnosis__c !=null) {
                    prescriptionObj.primaryDiagnosis = primaryDiagnosisMap.get(activePrescription.PC_PrimaryDiagnosis__c);
                }


                if( activePrescription.PC_SecondaryDiagnosis__c !=null) {
                    prescriptionObj.secondaryDiagnosis = secondaryDiagnosisMap.get(activePrescription.PC_SecondaryDiagnosis__c) ;
                }

                prescriptionInfoWrapper.prescriptionDetailsList.add(prescriptionObj);

            }
        }

        return prescriptionInfoWrapper;
    }


    /*****************************************************************************************
    Method Name    : submitMedicalBenefitsInfo
    Author         : Shishir Bansal
    Description    : This method is used to submit the user input data to the SOP  request class

    Return Type    :
    Parameter      :
    User Story     :
    ******************************************************************************************/
    @AuraEnabled
    public static PC_eBenefits.MedicalBenefitsResponse submitMedicalBenefitsInfo(Id caseId,  Id primaryHealthPlanId,
                                                   Id secondaryHealthPlanId, Id tertiaryHealthPlanId, Id prescriptionId,
                                                                      Id clinicId, Id patientId, String[] adminCodes) {
       try{

            PC_eBenefits.MedicalBenefits handler = PC_eBenefits.getMedicalBenefitsService();
            PC_eBenefits.MedicalBenefitsRequest request = handler.createMedicalBenefitRequest();
            PC_eBenefits_Utility.updateMedicalBenefitRequest(caseId, primaryHealthPlanId,  secondaryHealthPlanId,
                                      tertiaryHealthPlanId,  prescriptionId,  clinicId,  patientId,adminCodes,request);
            PC_eBenefits.MedicalBenefitsResponse response = handler.lookupMedicalBenefits(request);
            if(response != null && response.isSuccess) {
                PC_ebenefits.sCoverageDetail sCoverage = new PC_ebenefits.sCoverageDetail();

                handler.updateCoverage(response, sCoverage);
                sCoverage.patientId = patientId;
                sCoverage.caseId = caseId;
                sCoverage.programCoverage.PC_Prescription__c = prescriptionId;
                sCoverage.programCoverage.PC_Clinic__c = clinicId;

                if (primaryHealthPlanId != null && sCoverage.primaryCoverageBenefit != null) {
                    sCoverage.primaryCoverageBenefit.PC_HealthPlan__c = primaryHealthPlanId;
                    List<Object> formattingArguments = new List<Object>{
                            request.primaryHealthPlan.memberId,
                            request.primaryHealthPlan.payerName
                    };


                    if (!String.isBlank(request.primaryHealthPlan.planName)) {
                        formattingArguments.add(request.primaryHealthPlan.planName);


                        sCoverage.primaryCoverageBenefit.Name = String.format(Label.PC_MedicalBenefits_CoverageBenefit_Name,
                                formattingArguments);
                    }
                    if (String.isBlank(request.primaryHealthPlan.planName)) {


                        sCoverage.primaryCoverageBenefit.Name = String.format(Label.PC_MedicalBenefits_CoverageBenefit_NameV2,
                                formattingArguments);


                    }
                }
                if (secondaryHealthPlanId != null && sCoverage.secondaryCoverageBenefit != null) {
                    sCoverage.secondaryCoverageBenefit.PC_HealthPlan__c = secondaryHealthPlanId;
                    List<Object> formattingArguments = new List<Object>{
                            request.secondaryHealthPlan.memberId,
                            request.secondaryHealthPlan.payerName
                    };


                    if (!String.isBlank(request.secondaryHealthPlan.planName)) {

                        formattingArguments.add(request.secondaryHealthPlan.planName);


                        sCoverage.secondaryCoverageBenefit.Name = String.format(Label.PC_MedicalBenefits_CoverageBenefit_Name,
                                formattingArguments);
                    }
                    if (String.isBlank(request.secondaryHealthPlan.planName)) {

                        sCoverage.secondaryCoverageBenefit.Name = String.format(Label.PC_MedicalBenefits_CoverageBenefit_NameV2,
                                formattingArguments);
                    }
                }
                if (tertiaryHealthPlanId != null && sCoverage.tertiaryCoverageBenefit != null) {


                    List<Object> formattingArguments = new List<Object>{
                            request.tertiaryHealthPlan.memberId,
                            request.tertiaryHealthPlan.payerName
                    };

                    sCoverage.tertiaryCoverageBenefit.PC_HealthPlan__c = tertiaryHealthPlanId;


                    if (!String.isEmpty(request.tertiaryHealthPlan.planName)) {

                        formattingArguments.add(request.tertiaryHealthPlan.planName);
                        sCoverage.tertiaryCoverageBenefit.Name = String.format(Label.PC_MedicalBenefits_CoverageBenefit_Name,
                                formattingArguments);
                    }
                    if (String.isEmpty(request.tertiaryHealthPlan.planName)) {
                        sCoverage.tertiaryCoverageBenefit.Name = String.format(Label.PC_MedicalBenefits_CoverageBenefit_NameV2,
                                formattingArguments);
                    }
                }

                PC_eBenefits_Utility.insertingMedicalBenefitsData(sCoverage);
                response.programCoverage.id = sCoverage.programCoverage.Id;
            }
            return response;
        }
        catch(Exception ex) {
            PC_Utility.publishErrorLog(ex, ex.getMessage());

            system.debug('ex'+ex);
            system.debug('ex.getMessage'+ex.getMessage());
            AuraHandledException auraEx = new AuraHandledException(ex.getMessage());
            auraEx.setMessage(ex.getMessage());
            throw auraEx;
        }
    }



    /*********************************************************************************
   Method Name    : getHealthPlanLabel
   Author         : Hitha Avalakki
   Description    : This method is used to get Health Plan label
   Return Type    : String
   Parameter      : PC_Health_Plan__c healthPlanObj
   User Story     : PC-4130
   *********************************************************************************/
    public static String getHealthPlanLabel(PC_Health_Plan__c healthPlanObj){
        String healthPlanLabel=PC_Constants.EMPTY_STRING;

        if(!String.isBlank(healthPlanObj.PC_Payer_Name__c) && !String.isBlank(healthPlanObj.PC_Plan_Name__c)){
            healthPlanLabel= healthPlanObj.PC_Payer_Name__c + COLON + healthPlanObj.PC_Plan_Name__c;
        }
        else if(!String.isBlank(healthPlanObj.PC_Payer_Name__c) && String.isBlank(healthPlanObj.PC_Plan_Name__c)){
            healthPlanLabel=healthPlanObj.PC_Payer_Name__c;
        }
        else if(String.isBlank(healthPlanObj.PC_Payer_Name__c) && !String.isBlank(healthPlanObj.PC_Plan_Name__c)){
            healthPlanLabel=healthPlanObj.PC_Plan_Name__c;
        }
        else{
            healthPlanLabel=healthPlanObj.Name;
        }
        return healthPlanLabel;
    }


    /**
    * MedicalBenefitsFormData class holds the data related to Health Plan, Prescription and Clinic
    */
    public class MedicalBenefitsFormData{
        @AuraEnabled public FormData formData;

        public MedicalBenefitsFormData(){
            formData=new FormData();
        }
    }



    /**
    * FormData class holds the data related to Health Plan
    */
    public class FormData{

        @AuraEnabled public List<PC_eBenefits.HealthPlan> primaryHealthPlansList;
        @AuraEnabled public List<PC_eBenefits.HealthPlan> secondaryHealthPlansList;
        @AuraEnabled public List<PC_eBenefits.HealthPlan> tertiaryHealthPlansList;
        @AuraEnabled public List<PC_eBenefits.HealthPlan> noPlanTypeHealthPlansList;
        @AuraEnabled public PC_eBenefits.HealthPlanLabel medicalBenefitsFieldLabels;
        @AuraEnabled public List<PC_eBenefits.Clinic> clinicDetailsList;
        @AuraEnabled public PC_eBenefits.ClinicLabels clinicLabels;
        @AuraEnabled public List<PC_eBenefits.Prescription> prescriptionDetailsList;
        @AuraEnabled public PC_eBenefits.PrescriptionLabels prescriptionLabels;
        @AuraEnabled public PC_eBenefits.Patient patientDetails;
        @AuraEnabled public PC_eBenefits.PatientLabels patientLabels;

        public FormData(){
            primaryHealthPlansList=new List<PC_eBenefits.HealthPlan>();
            secondaryHealthPlansList=new List<PC_eBenefits.HealthPlan>();
            tertiaryHealthPlansList=new List<PC_eBenefits.HealthPlan>();
            noPlanTypeHealthPlansList=new List<PC_eBenefits.HealthPlan>();
            medicalBenefitsFieldLabels=new PC_eBenefits.HealthPlanLabel(true);
            clinicDetailsList=new List<PC_eBenefits.Clinic>();
            clinicLabels=new PC_eBenefits.ClinicLabels();
            prescriptionDetailsList = new List<PC_eBenefits.Prescription>();
            prescriptionLabels = new PC_eBenefits.PrescriptionLabels();
            patientDetails=new PC_eBenefits.Patient();
            patientLabels=new PC_eBenefits.PatientLabels();
        }
    }

    public class HealthPlanInfoWrapper{
        public List<PC_eBenefits.HealthPlan> primaryHealthPlansList;
        public List<PC_eBenefits.HealthPlan> secondaryHealthPlansList;
        public List<PC_eBenefits.HealthPlan> tertiaryHealthPlansList;
        public List<PC_eBenefits.HealthPlan> noPlanTypeHealthPlansList;

        public HealthPlanInfoWrapper(){
            primaryHealthPlansList=new List<PC_eBenefits.HealthPlan>();
            secondaryHealthPlansList=new List<PC_eBenefits.HealthPlan>();
            tertiaryHealthPlansList=new List<PC_eBenefits.HealthPlan>();
            noPlanTypeHealthPlansList=new List<PC_eBenefits.HealthPlan>();
        }
    }

    public class ClinicInfoWrapper{
        public List<PC_eBenefits.Clinic> clinicDetailsList;

        public ClinicInfoWrapper(){
            clinicDetailsList=new List<PC_eBenefits.Clinic>();
        }
    }

    public class PrescriptionInfoWrapper{
        public List<PC_eBenefits.Prescription> prescriptionDetailsList;

        public PrescriptionInfoWrapper(){
            prescriptionDetailsList=new List<PC_eBenefits.Prescription>();
        }
    }

    public class PatientInfoWrapper{
        public List<Account> patientRecList;
        public String ssnVal;

        public PatientInfoWrapper(){
            patientRecList=new List<Account>();
            ssnVal='';
        }
    }


}