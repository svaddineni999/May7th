/**
 * Created by shisbansal on 3/8/2019.
 *
 ***************************************************
 * Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------
Shishir Bansal              3/8/2019                Initial Version
Shishir Bansal              06-Dec-2019             [PC-5792] Avoid hardcoding of string variable
Haritha Reddy               21-Jan-2021              [PC-7102] Force Reviewer scan issue fix. Updated Sharing declaration.
*********************************************************************************/


public with sharing class PC_MedicalBenefits_VirMedica implements PC_eBenefits.MedicalBenefits{


    public static final String VirMedica_Male_Gender = 'Male';
    public static final String VirMedica_Male_Gender_Abbreviation = 'M';
    public static final String VirMedica_Female_Gender_Abbreviation = 'F';

    public PC_eBenefits.MedicalBenefitsRequest createMedicalBenefitRequest() {
        return new PC_eBenefits.MedicalBenefitsRequest();
    }

    /**
    * Converting MedicalBenefitsRequest object into SOAP request object form and making callout
    */
    public PC_eBenefits.MedicalBenefitsResponse lookupMedicalBenefits(PC_eBenefits.MedicalBenefitsRequest request){

    try {


        PC_VirMedicaWSDL2Apex.policyInfo pInfo = new PC_VirMedicaWSDL2Apex.policyInfo();
        PC_VirMedicaWSDL2Apex.policyInfoWithLetter pInfoWithLetter = new PC_VirMedicaWSDL2Apex.policyInfoWithLetter();
        PC_VirMedicaWSDL2Apex.medeBVRequest soapRequest = new PC_VirMedicaWSDL2Apex.medeBVRequest();

        soapRequest.patientFirstName = request.patient.firstName;
        soapRequest.patientLastName = request.patient.lastName;
        if(request.patient.dob !=null) {
            soapRequest.patientDOB = request.patient.dob;
        }

        if(request.patient.gender.equalsIgnoreCase(PC_Constants.PATIENT_FEMALE)) {
            soapRequest.patientGender = VirMedica_Female_Gender_Abbreviation;
        }
        if(request.patient.gender.equalsIgnoreCase(PC_Constants.PATIENT_MALE)) {
            soapRequest.patientGender = VirMedica_Male_Gender_Abbreviation;
        }
        if(!String.isBlank(request.patient.ssn)) {
            soapRequest.patientSSN = request.patient.ssn;
        }
        soapRequest.patientZip = request.patient.zipCode;
        soapRequest.product = request.prescription.productName;

        if (request.cptCodes != null) {

            Integer len = request.cptCodes.size();

            if(len >0){
            soapRequest.cptCode1 = String.valueOf(request.cptCodes[0]);
            }


            if (len > 1) {
                soapRequest.cptCode2 = String.valueOf(request.cptCodes[1]);
            }


            if (len > 2) {
                soapRequest.cptCode3 = String.valueOf(request.cptCodes[2]);
            }


            if (len > 3) {
                soapRequest.cptCode4 = String.valueOf(request.cptCodes[3]);
            }

            if (len > 4) {
                soapRequest.cptCode5 = String.valueOf(request.cptCodes[4]);
            }
        }


        soapRequest.primaryDiagnosis = request.prescription.primaryDiagnosis;
        soapRequest.secondaryDiagnosis = request.prescription.secondaryDiagnosis;

        if( (request.prescription.placeOfService !=null) || (request.clinic.placeOfService != null)) {
            soapRequest.pos =
                    (request.prescription.placeOfService != null)?request.prescription.placeOfService :
                                                                            request.clinic.placeOfService;
        }
        soapRequest.providerFirstName = request.prescription.physician.firstName;
        soapRequest.providerLastName = request.prescription.physician.lastName;
        soapRequest.providerNPI = request.clinic.npi;
        soapRequest.providerState = request.prescription.physician.address.state;

        //soapRequest.providerTaxId = request. --todo--
        //soapRequest.practiceName = request --todo--
        //soapRequest.practiceState = request. --todo--
        //soapRequest.practiceNPI = request.  --todo--

        soapRequest.mfg = request.prescription.drug.drugManufacturerName;




        //soapRequest.policy1Params = mapPolicyParam (request, 0);
        if(request.primaryHealthPlan !=null) {



            PC_VirMedicaWSDL2Apex.policyInfo policyInfo1 = new PC_VirMedicaWSDL2Apex.policyInfo();

            policyInfo1.policyMemberId = request.primaryHealthPlan.memberId;
            policyInfo1.policyPayerId = request.primaryHealthPlan.payerId;

            if(!request.primaryHealthPlan.relationshipToCardholder.equalsIgnoreCase(PC_Constants.SELF)){
                PC_VirMedicaWSDL2Apex.subscriberInfo subscriberInfo1 = new PC_VirMedicaWSDL2Apex.subscriberInfo();



                subscriberInfo1.firstName = request.primaryHealthPlan.cardholderFirstName;
                subscriberInfo1.lastName = request.primaryHealthPlan.cardholderLastName;
                subscriberInfo1.DOB = request.primaryHealthPlan.cardholderDoB;
                subscriberInfo1.gender = request.primaryHealthPlan.cardholderGender;
                subscriberInfo1.memberId = request.primaryHealthPlan.cardholderIdPolicy;

                policyInfo1.subscriberInfo = subscriberInfo1;
            }
          soapRequest.policy1Params = policyInfo1;
        }

        if( request.secondaryHealthPlan !=null) {



            PC_VirMedicaWSDL2Apex.policyInfoWithLetter policyInfo2 = new PC_VirMedicaWSDL2Apex.policyInfoWithLetter();

            policyInfo2.policyMemberId = request.secondaryHealthPlan.memberId;
            policyInfo2.policyPayerId = request.secondaryHealthPlan.payerId;
            if(request.secondaryHealthPlan.medicareSupplementalPlanLetter !=null) {
                policyInfo2.mcSuppPlanLetter =request.secondaryHealthPlan.medicareSupplementalPlanLetter;

            }
            if(!request.secondaryHealthPlan.relationshipToCardholder.equalsIgnoreCase(PC_Constants.SELF)){
                PC_VirMedicaWSDL2Apex.subscriberInfo subscriberInfo2 = new PC_VirMedicaWSDL2Apex.subscriberInfo();




                subscriberInfo2.firstName = request.secondaryHealthPlan.cardholderFirstName;
                subscriberInfo2.lastName = request.secondaryHealthPlan.cardholderLastName;
                subscriberInfo2.DOB = request.secondaryHealthPlan.cardholderDoB;
                subscriberInfo2.gender = request.secondaryHealthPlan.cardholderGender;
                subscriberInfo2.memberId = request.secondaryHealthPlan.cardholderIdPolicy;

                policyInfo2.subscriberInfo = subscriberInfo2;
            }


            soapRequest.policy2Params = policyInfo2;
        }




        if(request.tertiaryHealthPlan !=null) {







            PC_VirMedicaWSDL2Apex.policyInfo policyInfo3 = new PC_VirMedicaWSDL2Apex.policyInfo();

            policyInfo3.policyMemberId = request.primaryHealthPlan.memberId;
            policyInfo3.policyPayerId = request.primaryHealthPlan.payerId;


            if(!request.tertiaryHealthPlan.relationshipToCardholder.equalsIgnoreCase(PC_Constants.SELF)){
                PC_VirMedicaWSDL2Apex.subscriberInfo subscriberInfo3 = new PC_VirMedicaWSDL2Apex.subscriberInfo();



                subscriberInfo3.firstName = request.tertiaryHealthPlan.cardholderFirstName;
                subscriberInfo3.lastName = request.tertiaryHealthPlan.cardholderLastName;
                subscriberInfo3.DOB = request.tertiaryHealthPlan.cardholderDoB;
                subscriberInfo3.gender = request.tertiaryHealthPlan.cardholderGender;
                subscriberInfo3.memberId = request.tertiaryHealthPlan.cardholderIdPolicy;

                policyInfo3.subscriberInfo = subscriberInfo3;
            }
            soapRequest.policy3Params = policyInfo3;
        }



        PC_VirMedicaWSDL2Apex.medeBVResponse soapResponse = new PC_VirMedicaWSDL2Apex.medeBVResponse();
        PC_VirMedicaWSDL2Apex.VirmedicaPortSoap11 requestSoap = new PC_VirMedicaWSDL2Apex.VirmedicaPortSoap11();
        soapResponse = requestSoap.GetMedeBV(soapRequest);

        system.debug(JSON.serialize(soapResponse));

        PC_VirMedica_Utility  virMedica_utility= new PC_VirMedica_Utility();
        PC_eBenefits.MedicalBenefitsResponse mResponse = new PC_eBenefits.MedicalBenefitsResponse();

        mResponse =virMedica_utility.convertVmiMedicalBenefitsResponse(request,soapResponse);//convertVmiMedicalBenefitsResponse

        system.debug('mResponse tertiary'+mResponse.programCoverage.tertiaryCoverageBenefit);


        return mResponse;

    }catch (exception ex){
        system.debug('message '+ex.getMessage()+' line '+ex.getStackTraceString());
        PC_Utility.logAndThrowException(ex);
    }
     return null;
    }

    /**
    * Converting response to sObject form and saving the data into respective objects
    */
    public void updateCoverage(PC_eBenefits.MedicalBenefitsResponse response, PC_eBenefits.sCoverageDetail sCoverage) {
        PC_eBenefits_Utility.updateCoverageDetails(sCoverage, response);
        //PC_VirMedica_Utility.updateCoverageDetails(sCoverage, response);
    }

    }