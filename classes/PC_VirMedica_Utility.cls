/**
 * Created by shisbansal on 4/4/2019.
 */
/******************************************************************************
  Modification Log:
  -----------------------------------------------------------------------------
  Developer             Date            Description
  -----------------------------------------------------------------------------
  Shishir               2019-04-04      Initial Version
  Shishir               2019-24-04      Added logic to convert String to Currency fields
  Shishir               11-Dec-2019     [PC-5792] Avoid hardcoding of string variable
 ******************************************************************************/

public with sharing class PC_VirMedica_Utility {


    private static string Yes = 'Yes';
    private static string No = 'No';
    private static string Undetermined = 'Undetermined';
    private static string NA = 'N/A';
    private static string COMPLETE = 'Complete';
    private static string PARTIAL = 'Partial';
    private static string INCOMPLETE = 'Incomplete';
    private static string COULD_NOT_IDENTIFY = 'Could not identify';
    private static string COLON = ' : ';

    // named credential method

    /**
    * Method to convert soap response to MedicalBenefitsResponse by passing soap response as parameter
    */
    public PC_eBenefits.MedicalBenefitsResponse convertVmiMedicalBenefitsResponse(PC_eBenefits.MedicalBenefitsRequest request,
            PC_VirMedicaWSDL2Apex.medeBVResponse soapResponse) {


        PC_eBenefits.MedicalBenefitsResponse response = new PC_eBenefits.MedicalBenefitsResponse();

        try {



            updateResponseWithCoverageDetails(response, soapResponse);


            if (soapResponse.policy1 != null){

            updateResponseWithCoverageBenefit1Data(response, soapResponse);

            updateResponseWithCoverageBenefit1_OfficeResult(response, soapResponse, request);
            updateResponseWithCoverageBenefit1_ProductResult(response, soapResponse, request);
            updateResponseWithCoverageBenefit1_CptCode1Result(response, soapResponse, request);
            updateResponseWithCoverageBenefit1_CptCode2Result(response, soapResponse, request);
            updateResponseWithCoverageBenefit1_CptCode3Result(response, soapResponse, request);
            updateResponseWithCoverageBenefit1_CptCode4Result(response, soapResponse, request);
            updateResponseWithCoverageBenefit1_CptCode5Result(response, soapResponse, request);


            }

            if(soapResponse.policy2 !=null) {



                updateResponseWithCoverageBenefit2Data(response, soapResponse);
                updateResponseWithCoverageBenefit2_OfficeResult(response, soapResponse,request);
                updateResponseWithCoverageBenefit2_ProductResult(response, soapResponse,request);
                updateResponseWithCoverageBenefit2_CptCode1Result(response, soapResponse,request);
                updateResponseWithCoverageBenefit2_CptCode2Result(response, soapResponse,request);
                updateResponseWithCoverageBenefit2_CptCode3Result(response, soapResponse,request);
                updateResponseWithCoverageBenefit2_CptCode4Result(response, soapResponse,request);
                updateResponseWithCoverageBenefit2_CptCode5Result(response, soapResponse,request);


            }


            if(soapResponse.policy3 !=null) {



                updateResponseWithCoverageBenefit3Data(response, soapResponse);
                updateResponseWithCoverageBenefit3_OfficeResult(response, soapResponse,request);
                updateResponseWithCoverageBenefit3_ProductResult(response, soapResponse,request);
                updateResponseWithCoverageBenefit3_CptCode1Result(response, soapResponse,request);
                updateResponseWithCoverageBenefit3_CptCode2Result(response, soapResponse,request);
                updateResponseWithCoverageBenefit3_CptCode3Result(response, soapResponse,request);
                updateResponseWithCoverageBenefit3_CptCode4Result(response, soapResponse,request);
                updateResponseWithCoverageBenefit3_CptCode5Result(response, soapResponse,request);
            }

             response.isSuccess = true;
             response.completionStatus = getCoverageCompletionStatus(Integer.valueOf(soapResponse.responseTypeCode));


            if(!String.isBlank( response.completionStatus)) {

                response.programCoverage.completionStatus = response.completionStatus;
                List<Object> formattingArguments =
                                                new List<Object>{ response.completionStatus};
                response.successMessages.add(String.format(Label.PC_MedicalBenefits_ProgramCoverage_CompletionStatus,
                                                     formattingArguments));

                if(! response.completionStatus.equalsIgnoreCase(COMPLETE)){
                    response.successMessages.add(Label.PC_MedicalBenefits_InfoMessage);
                }
            }



        }catch(Exception ex){
            PC_Utility.createExceptionLog (ex);
        }

        return response;
    }



    public static String getCoverageCompletionStatus(Integer responseTypeCode) {

        String completionStatus = PC_Constants.EMPTY_STRING;


        switch on responseTypeCode {
            when 1001,1002,1003, 1010, 1011, 1012, 1101, 1102 , 1104, 1105, 1108, 1109{

                completionStatus=COMPLETE;
            }
            when 1004,1005, 1006, 1112, 1113, 1114 {

                completionStatus=PARTIAL;
            }
            when 1007, 1008, 1009, 1106, 1107, 1115 {

                completionStatus=INCOMPLETE;
            }
            when 1013, 1014, 1015, 1103, 1110, 1111 {

                completionStatus=NA;
            }

            when 1999 {

                completionStatus=COULD_NOT_IDENTIFY;
            }

            when else {		  // default block, optional

                completionStatus=String.valueOf(responseTypeCode);
            }
        }


        return completionStatus;
    }

    /**
    * Method to update program coverage details from soap response
    */
    private void updateResponseWithCoverageDetails(PC_eBenefits.MedicalBenefitsResponse response,
            PC_VirMedicaWSDL2Apex.medeBVResponse soapResponse) {
        PC_eBenefits.ProgramCoverageBenefit programCoverage = new PC_eBenefits.ProgramCoverageBenefit();
        response.programCoverage = new PC_eBenefits.ProgramCoverage();
        response.programCoverage.coordinatedPlanBenefits = soapResponse.coordinatedPlanBenefits;


    }
    private static Decimal parseTextAsPercent(String decimalText) {
        if(String.isNotBlank(decimalText) && decimalText.toLowerCase() != PC_Constants.NOT_FOUND.toLowerCase()) {
            if(decimalText.contains('%')) {
                decimalText = decimalText.replace('%',PC_Constants.EMPTY_STRING);
            }
            return Decimal.valueOf(decimalText);
        }
        return null;
    }

    /**
    * Method to update Primary Coverage Benefit from soap response
    */
    private void updateResponseWithCoverageBenefit1Data(PC_eBenefits.MedicalBenefitsResponse response,
            PC_VirMedicaWSDL2Apex.medeBVResponse soapResponse) {


        if (soapResponse.policy1 != null){



            PC_eBenefits.ProgramCoverageBenefit programCoverageBenefit1 = new PC_eBenefits.ProgramCoverageBenefit();

            programCoverageBenefit1.transactionId = soapResponse.policy1.transactionId;
            programCoverageBenefit1.transactionDate = soapResponse.policy1.transactionDate;
            programCoverageBenefit1.coverageStatus = soapResponse.policy1.eligibilityStatus;
            programCoverageBenefit1.startDate = soapResponse.policy1.effDate;
            programCoverageBenefit1.endDate = soapResponse.policy1.endDate;
            programCoverageBenefit1.payerName = soapResponse.policy1.payerName;
            programCoverageBenefit1.planType = soapResponse.policy1.planType;
            programCoverageBenefit1.groupNo = soapResponse.policy1.groupNumber;
            programCoverageBenefit1.groupName = soapResponse.policy1.groupName;


            Decimal  dedIndAmt =
                    PC_VirMedica_Utility.convertCurrenyToDecimal( soapResponse.policy1.dedIndAmt);
            if(dedIndAmt !=null) {
                programCoverageBenefit1.individualInNetworkDeductibleLimit =dedIndAmt;
            }

            Decimal dedIndAmtMet =
                    PC_VirMedica_Utility.convertCurrenyToDecimal(soapResponse.policy1.dedIndAmtMet);
            if( dedIndAmt != null && dedIndAmtMet != null) {
                programCoverageBenefit1.individualInNetworkDeductibleRemaining =dedIndAmt -dedIndAmtMet;
            }

            Decimal oopMaxIndAmt =
                    PC_VirMedica_Utility.convertCurrenyToDecimal(soapResponse.policy1.oopMaxIndAmt);
            if(oopMaxIndAmt !=null) {
                programCoverageBenefit1.individualInNetworkOutofPocketLimit =oopMaxIndAmt;
            }

            Decimal oopMaxIndMet =
                    PC_VirMedica_Utility.convertCurrenyToDecimal(soapResponse.policy1.oopMaxIndMet);
            if( oopMaxIndAmt != null && oopMaxIndMet != null) {
                programCoverageBenefit1.individualInNetworkOutofPocketRemaining =oopMaxIndAmt -oopMaxIndMet;
            }


            Decimal dedFamAmt =
                    PC_VirMedica_Utility.convertCurrenyToDecimal(soapResponse.policy1.dedFamAmt);
            if(dedFamAmt !=null) {
                programCoverageBenefit1.familyInNetworkDeductibleLimit = dedFamAmt;
            }

            Decimal dedFamAmtMet =
                    PC_VirMedica_Utility.convertCurrenyToDecimal( soapResponse.policy1.dedFamAmtMet);
            if( dedFamAmt != null && dedFamAmtMet!=null) {
                programCoverageBenefit1.familyInNetworkDeductibleRemaining = dedFamAmt - dedFamAmtMet;
            }

            Decimal oopMaxFamAmt =
                    PC_VirMedica_Utility.convertCurrenyToDecimal(soapResponse.policy1.oopMaxFamAmt);
            if(oopMaxFamAmt != null) {
                programCoverageBenefit1.familyInNetworkOutofPocketLimit =  oopMaxFamAmt;
            }

            Decimal oopMaxFamMet =
                    PC_VirMedica_Utility.convertCurrenyToDecimal( soapResponse.policy1.oopMaxFamMet);
            if(oopMaxFamAmt != null && oopMaxFamMet!= null) {
                programCoverageBenefit1.familyInNetworkOutofPocketRemaining =oopMaxFamAmt - oopMaxFamMet;
            }

            programCoverageBenefit1.paRequired = soapResponse.policy1.priorAuthRqd;
            programCoverageBenefit1.buyAndBill = soapResponse.policy1.buyBill;
            programCoverageBenefit1.specialtyPharmacyRequired = soapResponse.policy1.spReq;
            programCoverageBenefit1.specialtyPharmacyInfo = soapResponse.policy1.spName;


            programCoverageBenefit1.isGovernmentPlan = soapResponse.policy1.govInd;
            programCoverageBenefit1.governmentPlanType = soapResponse.policy1.govPolicyType;
            programCoverageBenefit1.transactionMessageID = soapResponse.policy1.msgId;
            programCoverageBenefit1.benefitNotes = soapResponse.policy1.msgContent;
            programCoverageBenefit1.productAdminMessage = soapResponse.policy1.customMessage1 ;
            programCoverageBenefit1.billingMessage = soapResponse.policy1.customMessage2 ;
            programCoverageBenefit1.priorAuthMessage = soapResponse.policy1.customMessage3 ;
            programCoverageBenefit1.payerMessage = soapResponse.policy1.customMessage4 ;
            programCoverageBenefit1.coverageLevel = PC_Constants.HEALTH_PLAN_TYPE_PRIMARY;
            response.programCoverage.primaryCoverageBenefit = programCoverageBenefit1;
        }


    }


    /**
    * Method to update Primary Coverage Benefit item of type "office" from soap response
    */
    private void updateResponseWithCoverageBenefit1_OfficeResult(PC_eBenefits.MedicalBenefitsResponse response,
            PC_VirMedicaWSDL2Apex.medeBVResponse soapResponse, PC_eBenefits.MedicalBenefitsRequest request) {

        if(soapResponse.policy1 !=null) {



            PC_eBenefits.ProgramCoverageBenefitItem officeCategory = new PC_eBenefits.ProgramCoverageBenefitItem();
            officeCategory.name = request.primaryHealthPlan.memberId + COLON +
                                                    String.valueOf(PC_Constants.BenefitCategory.OfficeVisit);

            officeCategory.benefitCategory = String.valueOf(PC_Constants.BenefitCategory.OfficeVisit);
            officeCategory.serviceTypeCode =PC_Constants.NA;
            officeCategory.serviceType = PC_Constants.NA;
            officeCategory.benefitCategory = String.valueOf(PC_Constants.BenefitCategory.OfficeVisit);
            officeCategory.coverageLevel = soapResponse.policy1.officeVisitStatus;
            officeCategory.deductableApplies = categoryBasedCPTInfo(soapResponse.policy1.officeVisitDedApplies);
            officeCategory.copayApplies = categoryBasedCPTInfo(soapResponse.policy1.officeVisitCopayApplies);
            officeCategory.coinsuranceApplies = categoryBasedCPTInfo(soapResponse.policy1.officeVisitCoinsApplies);
            officeCategory.oopMaxApplies = categoryBasedCPTInfo(soapResponse.policy1.officeVisitOopMaxApplies);
            officeCategory.pcpCopayAmount = convertCurrenyToDecimal(soapResponse.policy1.officeCopayPCPAmt);
            officeCategory.specialistCopayAmount = convertCurrenyToDecimal(soapResponse.policy1.officeSpecCopayAmt);
            officeCategory.coinsurancePercent = parseTextAsPercent(soapResponse.policy1.officeCoinsAmt);
            response.programCoverage.primaryCoverageBenefit.benefitItems.add(officeCategory);


        }
    }

    /**
    * Method to update Primary Coverage Benefit item of type "Product" from soap response
    */
    private void updateResponseWithCoverageBenefit1_ProductResult(PC_eBenefits.MedicalBenefitsResponse response,
            PC_VirMedicaWSDL2Apex.medeBVResponse soapResponse, PC_eBenefits.MedicalBenefitsRequest request) {


        if(soapResponse.policy1 !=null) {




            PC_eBenefits.ProgramCoverageBenefitItem productCategory = new PC_eBenefits.ProgramCoverageBenefitItem();

            productCategory.name =request.primaryHealthPlan.memberId + COLON +
                                                 String.valueOf(PC_Constants.BenefitCategory.Product);

            if(!String.isEmpty(request.prescription.productName)){

                productCategory.name += COLON + request.prescription.productName;

            }
            productCategory.benefitCategory = String.valueOf(PC_Constants.BenefitCategory.Product);
            productCategory.serviceType =PC_Constants.NA;
            productCategory.serviceTypeCode =request.prescription.productName;
            productCategory.coverageLevel = soapResponse.policy1.productStatus;
            productCategory.deductableApplies = categoryBasedCPTInfo(soapResponse.policy1.productDedApplies);
            productCategory.copayApplies = categoryBasedCPTInfo(soapResponse.policy1.productCopayApplies);
            productCategory.coinsuranceApplies = categoryBasedCPTInfo(soapResponse.policy1.productCoinsApplies);
            productCategory.oopMaxApplies = categoryBasedCPTInfo(soapResponse.policy1.productOopMaxApplies);
            productCategory.pcpCopayAmount = convertCurrenyToDecimal(soapResponse.policy1.productPCPCopayAmt);
            productCategory.specialistCopayAmount = convertCurrenyToDecimal(soapResponse.policy1.productSpecCopayAmt);
            productCategory.coinsurancePercent = parseTextAsPercent(soapResponse.policy1.productCoinsAmt);
            response.programCoverage.primaryCoverageBenefit.benefitItems.add(productCategory);


        }
    }


    /**
    * Method to update Primary Coverage Benefit item of type "CPT" from soap response
    */
    private void updateResponseWithCoverageBenefit1_CptCode1Result(PC_eBenefits.MedicalBenefitsResponse response,
            PC_VirMedicaWSDL2Apex.medeBVResponse soapResponse, PC_eBenefits.MedicalBenefitsRequest request) {


        //PC_eBenefits.ProgramCoverageBenefitItem  coverageBenefitItem = new  PC_eBenefits.ProgramCoverageBenefitItem();
        if(soapResponse.policy1 !=null) {



            if (soapResponse.policy1.cptCode1Result != null) {


                PC_eBenefits.ProgramCoverageBenefitItem cpt1 = new PC_eBenefits.ProgramCoverageBenefitItem();

                cpt1.name = request.primaryHealthPlan.memberId +
                                     COLON+ String.valueOf(PC_Constants.BenefitCategory.Administration);
                if(!String.isEmpty(soapResponse.inputParameters.cptCode1)){

                    cpt1.name += COLON +soapResponse.inputParameters.cptCode1;

                }
                cpt1.benefitCategory = String.valueOf(PC_Constants.BenefitCategory.Administration);
                cpt1.serviceTypeCode =soapResponse.inputParameters.cptCode1;
                cpt1.serviceType = request.cptCodeMap.get(soapResponse.inputParameters.cptCode1);
                cpt1.coverageLevel = soapResponse.policy1.cptCode1Result.cptStatus;
                cpt1.deductableApplies = categoryBasedCPTInfo(soapResponse.policy1.cptCode1Result.dedApplies);
                cpt1.copayApplies = categoryBasedCPTInfo(soapResponse.policy1.cptCode1Result.copayApplies);
                cpt1.coinsuranceApplies = categoryBasedCPTInfo(soapResponse.policy1.cptCode1Result.coinsApplies);
                cpt1.oopMaxApplies = categoryBasedCPTInfo(soapResponse.policy1.cptCode1Result.oopMaxApplies);
                cpt1.pcpCopayAmount = convertCurrenyToDecimal(soapResponse.policy1.cptCode1Result.pcpCopayAmt);
                cpt1.specialistCopayAmount = convertCurrenyToDecimal(soapResponse.policy1.cptCode1Result.specCopayAmt);
                cpt1.coinsurancePercent = parseTextAsPercent(soapResponse.policy1.cptCode1Result.coinsAmt);
                response.programCoverage.primaryCoverageBenefit.benefitItems.add(cpt1);


            }
        }

    }

    /**
    * Method to update Primary Coverage Benefit item of type "CPT" from soap response
    */
    private void updateResponseWithCoverageBenefit1_CptCode2Result(PC_eBenefits.MedicalBenefitsResponse response,
            PC_VirMedicaWSDL2Apex.medeBVResponse soapResponse, PC_eBenefits.MedicalBenefitsRequest request) {


        if(soapResponse.policy1 !=null) {


            if (soapResponse.policy1.cptCode2Result != null) {


                PC_eBenefits.ProgramCoverageBenefitItem cpt2 = new PC_eBenefits.ProgramCoverageBenefitItem();


                cpt2.name = request.primaryHealthPlan.memberId +
                        COLON+ String.valueOf(PC_Constants.BenefitCategory.Administration);
                if(!String.isEmpty(soapResponse.inputParameters.cptCode2)){

                    cpt2.name += COLON +soapResponse.inputParameters.cptCode2;

                }
                cpt2.benefitCategory = String.valueOf(PC_Constants.BenefitCategory.Administration);

                cpt2.serviceTypeCode =soapResponse.inputParameters.cptCode2;
                cpt2.serviceType = request.cptCodeMap.get(soapResponse.inputParameters.cptCode2);
                cpt2.coverageLevel = soapResponse.policy1.cptCode2Result.cptStatus;
                cpt2.deductableApplies = categoryBasedCPTInfo(soapResponse.policy1.cptCode2Result.dedApplies);
                cpt2.copayApplies = categoryBasedCPTInfo(soapResponse.policy1.cptCode2Result.copayApplies);
                cpt2.coinsuranceApplies = categoryBasedCPTInfo(soapResponse.policy1.cptCode2Result.coinsApplies);
                cpt2.oopMaxApplies = categoryBasedCPTInfo(soapResponse.policy1.cptCode2Result.oopMaxApplies);
                cpt2.pcpCopayAmount = convertCurrenyToDecimal(soapResponse.policy1.cptCode2Result.pcpCopayAmt);
                cpt2.specialistCopayAmount = convertCurrenyToDecimal(soapResponse.policy1.cptCode2Result.specCopayAmt);
                cpt2.coinsurancePercent = parseTextAsPercent(soapResponse.policy1.cptCode2Result.coinsAmt);
                response.programCoverage.primaryCoverageBenefit.benefitItems.add(cpt2);

            }
        }

    }

    /**
    * Method to update Primary Coverage Benefit item of type "CPT" from soap response
    */
    private void updateResponseWithCoverageBenefit1_CptCode3Result(PC_eBenefits.MedicalBenefitsResponse response,
            PC_VirMedicaWSDL2Apex.medeBVResponse soapResponse, PC_eBenefits.MedicalBenefitsRequest request) {


        if(soapResponse.policy1 != null) {
            if (soapResponse.policy1.cptCode3Result != null) {

                PC_eBenefits.ProgramCoverageBenefitItem cpt3 = new PC_eBenefits.ProgramCoverageBenefitItem();


                cpt3.name = request.primaryHealthPlan.memberId +
                        COLON+ String.valueOf(PC_Constants.BenefitCategory.Administration);
                if(!String.isEmpty(soapResponse.inputParameters.cptCode3)){

                    cpt3.name += COLON +soapResponse.inputParameters.cptCode3;

                }
                cpt3.benefitCategory = String.valueOf(PC_Constants.BenefitCategory.Administration);

                cpt3.serviceTypeCode =soapResponse.inputParameters.cptCode3;
                cpt3.serviceType = request.cptCodeMap.get(soapResponse.inputParameters.cptCode3);
                cpt3.coverageLevel = soapResponse.policy1.cptCode3Result.cptStatus;
                cpt3.deductableApplies = categoryBasedCPTInfo(soapResponse.policy1.cptCode3Result.dedApplies);
                cpt3.copayApplies = categoryBasedCPTInfo(soapResponse.policy1.cptCode3Result.copayApplies);
                cpt3.coinsuranceApplies = categoryBasedCPTInfo(soapResponse.policy1.cptCode3Result.coinsApplies);
                cpt3.oopMaxApplies = categoryBasedCPTInfo(soapResponse.policy1.cptCode3Result.oopMaxApplies);
                cpt3.pcpCopayAmount = convertCurrenyToDecimal(soapResponse.policy1.cptCode3Result.pcpCopayAmt);
                cpt3.specialistCopayAmount = convertCurrenyToDecimal(soapResponse.policy1.cptCode3Result.specCopayAmt);
                cpt3.coinsurancePercent = parseTextAsPercent(soapResponse.policy1.cptCode3Result.coinsAmt);
                response.programCoverage.primaryCoverageBenefit.benefitItems.add(cpt3);



            }
        }

    }

    /**
    * Method to update Primary Coverage Benefit item of type "CPT" from soap response
    */
    private void updateResponseWithCoverageBenefit1_CptCode4Result(PC_eBenefits.MedicalBenefitsResponse response,
            PC_VirMedicaWSDL2Apex.medeBVResponse soapResponse, PC_eBenefits.MedicalBenefitsRequest request) {


        //PC_eBenefits.ProgramCoverageBenefitItem  coverageBenefitItem = new  PC_eBenefits.ProgramCoverageBenefitItem();

        if(soapResponse.policy1 !=null) {

            if (soapResponse.policy1.cptCode4Result != null) {


                PC_eBenefits.ProgramCoverageBenefitItem cpt4 = new PC_eBenefits.ProgramCoverageBenefitItem();


                cpt4.name = request.primaryHealthPlan.memberId +
                        COLON+ String.valueOf(PC_Constants.BenefitCategory.Administration);
                if(!String.isEmpty(soapResponse.inputParameters.cptCode1)){

                    cpt4.name += COLON +soapResponse.inputParameters.cptCode4;

                }
                cpt4.benefitCategory = String.valueOf(PC_Constants.BenefitCategory.Administration);
                cpt4.serviceTypeCode =soapResponse.inputParameters.cptCode4;
                cpt4.serviceType = request.cptCodeMap.get(soapResponse.inputParameters.cptCode4);
                cpt4.coverageLevel = soapResponse.policy1.cptCode4Result.cptStatus;
                cpt4.deductableApplies = categoryBasedCPTInfo(soapResponse.policy1.cptCode4Result.dedApplies);
                cpt4.copayApplies = categoryBasedCPTInfo(soapResponse.policy1.cptCode4Result.copayApplies);
                cpt4.coinsuranceApplies = categoryBasedCPTInfo(soapResponse.policy1.cptCode4Result.coinsApplies);
                cpt4.oopMaxApplies = categoryBasedCPTInfo(soapResponse.policy1.cptCode4Result.oopMaxApplies);
                cpt4.pcpCopayAmount = convertCurrenyToDecimal(soapResponse.policy1.cptCode4Result.pcpCopayAmt);
                cpt4.specialistCopayAmount = convertCurrenyToDecimal(soapResponse.policy1.cptCode4Result.specCopayAmt);
                cpt4.coinsurancePercent = parseTextAsPercent(soapResponse.policy1.cptCode4Result.coinsAmt);
                response.programCoverage.primaryCoverageBenefit.benefitItems.add(cpt4);



            }
        }

    }

    /**
    * Method to update Primary Coverage Benefit item of type "CPT" from soap response
    */
   private void updateResponseWithCoverageBenefit1_CptCode5Result(PC_eBenefits.MedicalBenefitsResponse response,
            PC_VirMedicaWSDL2Apex.medeBVResponse soapResponse, PC_eBenefits.MedicalBenefitsRequest request) {


        //PC_eBenefits.ProgramCoverageBenefitItem  coverageBenefitItem = new  PC_eBenefits.ProgramCoverageBenefitItem();

        if(soapResponse.policy1 !=null) {

            if (soapResponse.policy1.cptCode5Result != null) {


                PC_eBenefits.ProgramCoverageBenefitItem cpt5 = new PC_eBenefits.ProgramCoverageBenefitItem();

                cpt5.name = request.primaryHealthPlan.memberId +
                        COLON+ String.valueOf(PC_Constants.BenefitCategory.Administration);
                if(!String.isEmpty(soapResponse.inputParameters.cptCode5)){

                    cpt5.name += COLON +soapResponse.inputParameters.cptCode5;

                }
                cpt5.benefitCategory = String.valueOf(PC_Constants.BenefitCategory.Administration);
                //cpt5.benefitCategory = String.valueOf(PC_Constants.BenefitCategory.CPT);
                cpt5.serviceTypeCode =soapResponse.inputParameters.cptCode5;
                cpt5.serviceType = request.cptCodeMap.get(soapResponse.inputParameters.cptCode5);
                cpt5.coverageLevel = soapResponse.policy1.cptCode5Result.cptStatus;
                cpt5.deductableApplies = categoryBasedCPTInfo(soapResponse.policy1.cptCode5Result.dedApplies);
                cpt5.copayApplies = categoryBasedCPTInfo(soapResponse.policy1.cptCode5Result.copayApplies);
                cpt5.coinsuranceApplies = categoryBasedCPTInfo(soapResponse.policy1.cptCode5Result.coinsApplies);
                cpt5.oopMaxApplies = categoryBasedCPTInfo(soapResponse.policy1.cptCode5Result.oopMaxApplies);
                cpt5.pcpCopayAmount = convertCurrenyToDecimal(soapResponse.policy1.cptCode5Result.pcpCopayAmt);
                cpt5.specialistCopayAmount = convertCurrenyToDecimal(soapResponse.policy1.cptCode5Result.specCopayAmt);
                cpt5.coinsurancePercent = parseTextAsPercent(soapResponse.policy1.cptCode5Result.coinsAmt);
                response.programCoverage.primaryCoverageBenefit.benefitItems.add(cpt5);



            }
        }

    }



    /**
    * Method to update Secondary Coverage Benefit from soap response
    */
   private void updateResponseWithCoverageBenefit2Data(PC_eBenefits.MedicalBenefitsResponse response,
            PC_VirMedicaWSDL2Apex.medeBVResponse soapResponse) {




        if(soapResponse.policy2 !=null) {

          PC_eBenefits.ProgramCoverageBenefit programCoverageBenefit2 = new PC_eBenefits.ProgramCoverageBenefit();
            programCoverageBenefit2.transactionId = soapResponse.policy2.transactionId;
            programCoverageBenefit2.transactionDate = soapResponse.policy2.transactionDate;
            programCoverageBenefit2.coverageStatus = soapResponse.policy2.eligibilityStatus;
            programCoverageBenefit2.startDate = soapResponse.policy2.effDate;
            programCoverageBenefit2.endDate = soapResponse.policy2.endDate;
            programCoverageBenefit2.payerName = soapResponse.policy2.payerName;
            programCoverageBenefit2.planType = soapResponse.policy2.planType;
            programCoverageBenefit2.groupNo = soapResponse.policy2.groupNumber;
            programCoverageBenefit2.groupName = soapResponse.policy2.groupName;


            Decimal  dedIndAmt =
                    PC_VirMedica_Utility.convertCurrenyToDecimal( soapResponse.policy2.dedIndAmt);
            if(dedIndAmt !=null) {
                programCoverageBenefit2.individualInNetworkDeductibleLimit =dedIndAmt;
            }

            Decimal dedIndAmtMet =
                    PC_VirMedica_Utility.convertCurrenyToDecimal(soapResponse.policy2.dedIndAmtMet);
            if( dedIndAmt != null && dedIndAmtMet != null) {
                programCoverageBenefit2.individualInNetworkDeductibleRemaining =dedIndAmt -dedIndAmtMet;
            }

            Decimal oopMaxIndAmt =
                    PC_VirMedica_Utility.convertCurrenyToDecimal(soapResponse.policy2.oopMaxIndAmt);
            if(oopMaxIndAmt !=null) {
                programCoverageBenefit2.individualInNetworkOutofPocketLimit =oopMaxIndAmt;
            }

            Decimal oopMaxIndMet =
                    PC_VirMedica_Utility.convertCurrenyToDecimal(soapResponse.policy2.oopMaxIndMet);
            if( oopMaxIndAmt != null && oopMaxIndMet != null) {
                programCoverageBenefit2.individualInNetworkOutofPocketRemaining =oopMaxIndAmt -oopMaxIndMet;
            }


            Decimal dedFamAmt =
                    PC_VirMedica_Utility.convertCurrenyToDecimal(soapResponse.policy2.dedFamAmt);
            if(dedFamAmt !=null) {
                programCoverageBenefit2.familyInNetworkDeductibleLimit = dedFamAmt;
            }

            Decimal dedFamAmtMet =
                    PC_VirMedica_Utility.convertCurrenyToDecimal( soapResponse.policy2.dedFamAmtMet);
            if( dedFamAmt != null && dedFamAmtMet!=null) {
                programCoverageBenefit2.familyInNetworkDeductibleRemaining = dedFamAmt - dedFamAmtMet;
            }

            Decimal oopMaxFamAmt =
                    PC_VirMedica_Utility.convertCurrenyToDecimal(soapResponse.policy2.oopMaxFamAmt);
            if(oopMaxFamAmt != null) {
                programCoverageBenefit2.familyInNetworkOutofPocketLimit =  oopMaxFamAmt;
            }

            Decimal oopMaxFamMet =
                    PC_VirMedica_Utility.convertCurrenyToDecimal( soapResponse.policy2.oopMaxFamMet);
            if(oopMaxFamAmt != null && oopMaxFamMet!= null) {
                programCoverageBenefit2.familyInNetworkOutofPocketRemaining =oopMaxFamAmt - oopMaxFamMet;
            }


            programCoverageBenefit2.paRequired = soapResponse.policy2.priorAuthRqd;
            programCoverageBenefit2.buyAndBill = soapResponse.policy2.buyBill;
            programCoverageBenefit2.specialtyPharmacyRequired = soapResponse.policy2.spReq;
            programCoverageBenefit2.specialtyPharmacyInfo = soapResponse.policy2.spName;


            programCoverageBenefit2.isGovernmentPlan = soapResponse.policy2.govInd;
            programCoverageBenefit2.governmentPlanType = soapResponse.policy2.govPolicyType;
            programCoverageBenefit2.transactionMessageID = soapResponse.policy2.msgId;
            programCoverageBenefit2.benefitNotes = soapResponse.policy2.msgContent;
            programCoverageBenefit2.productAdminMessage = soapResponse.policy2.customMessage1 ;
            programCoverageBenefit2.billingMessage = soapResponse.policy2.customMessage2 ;
            programCoverageBenefit2.priorAuthMessage = soapResponse.policy2.customMessage3 ;
            programCoverageBenefit2.payerMessage = soapResponse.policy2.customMessage4 ;
            programCoverageBenefit2.coverageLevel = PC_Constants.HEALTH_PLAN_TYPE_SECONDARY;
            response.programCoverage.secondaryCoverageBenefit = programCoverageBenefit2;
        }



    }

    /**
    * Method to update Secondary Coverage Benefit item of type "Office" from soap response
    */
   private void updateResponseWithCoverageBenefit2_OfficeResult(PC_eBenefits.MedicalBenefitsResponse response,
            PC_VirMedicaWSDL2Apex.medeBVResponse soapResponse, PC_eBenefits.MedicalBenefitsRequest request) {

       if(soapResponse.policy2 !=null) {



           PC_eBenefits.ProgramCoverageBenefitItem officeCategory = new PC_eBenefits.ProgramCoverageBenefitItem();
           officeCategory.name = request.secondaryHealthPlan.memberId + COLON +
                                                 String.valueOf(PC_Constants.BenefitCategory.OfficeVisit);
           officeCategory.benefitCategory = String.valueOf(PC_Constants.BenefitCategory.OfficeVisit);
           officeCategory.serviceTypeCode =soapResponse.inputParameters.cptCode1;
           officeCategory.serviceType = request.cptCodeMap.get(soapResponse.inputParameters.cptCode1);
           officeCategory.coverageLevel = soapResponse.policy2.officeVisitStatus;
           officeCategory.deductableApplies = categoryBasedCPTInfo(soapResponse.policy2.officeVisitDedApplies);
           officeCategory.copayApplies = categoryBasedCPTInfo(soapResponse.policy2.officeVisitCopayApplies);
           officeCategory.coinsuranceApplies = categoryBasedCPTInfo(soapResponse.policy2.officeVisitCoinsApplies);
           officeCategory.oopMaxApplies = categoryBasedCPTInfo(soapResponse.policy2.officeVisitOopMaxApplies);
           officeCategory.pcpCopayAmount = convertCurrenyToDecimal(soapResponse.policy2.officeCopayPCPAmt);
           officeCategory.specialistCopayAmount = convertCurrenyToDecimal(soapResponse.policy2.officeSpecCopayAmt);
           officeCategory.coinsurancePercent = parseTextAsPercent(soapResponse.policy2.officeCoinsAmt);
           response.programCoverage.secondaryCoverageBenefit.benefitItems.add(officeCategory);

       }


    }

    /**
    * Method to update Secondary Coverage Benefit item of type "Product" from soap response
    */
   private void updateResponseWithCoverageBenefit2_ProductResult(PC_eBenefits.MedicalBenefitsResponse response,
            PC_VirMedicaWSDL2Apex.medeBVResponse soapResponse, PC_eBenefits.MedicalBenefitsRequest request) {

       if(soapResponse.policy2 !=null) {



           PC_eBenefits.ProgramCoverageBenefitItem productCategory = new PC_eBenefits.ProgramCoverageBenefitItem();

           productCategory.name =request.secondaryHealthPlan.memberId + COLON +
                                                 String.valueOf(PC_Constants.BenefitCategory.Product) ;

           if(!String.isEmpty(request.prescription.productName)){

               productCategory.name += COLON + request.prescription.productName;

           }
           productCategory.benefitCategory = String.valueOf(PC_Constants.BenefitCategory.Product);
           productCategory.serviceTypeCode =request.prescription.productName;
           productCategory.serviceType = PC_Constants.NA;
           productCategory.coverageLevel = soapResponse.policy2.productStatus;
           productCategory.deductableApplies = categoryBasedCPTInfo(soapResponse.policy2.productDedApplies);
           productCategory.copayApplies = categoryBasedCPTInfo(soapResponse.policy2.productCopayApplies);
           productCategory.coinsuranceApplies = categoryBasedCPTInfo(soapResponse.policy2.productCoinsApplies);
           productCategory.oopMaxApplies = categoryBasedCPTInfo(soapResponse.policy2.productOopMaxApplies);
           productCategory.pcpCopayAmount = convertCurrenyToDecimal(soapResponse.policy2.productPCPCopayAmt);
           productCategory.specialistCopayAmount = convertCurrenyToDecimal(soapResponse.policy2.productSpecCopayAmt);
           productCategory.coinsurancePercent = parseTextAsPercent(soapResponse.policy2.productCoinsAmt);
           response.programCoverage.secondaryCoverageBenefit.benefitItems.add(productCategory);

       }

    }


    /**
    * Method to update Secondary Coverage Benefit item of type "Product" from soap response
    */
   private void updateResponseWithCoverageBenefit2_CptCode1Result(PC_eBenefits.MedicalBenefitsResponse response,
            PC_VirMedicaWSDL2Apex.medeBVResponse soapResponse, PC_eBenefits.MedicalBenefitsRequest request) {


       if(soapResponse.policy2 !=null) {



           if (soapResponse.policy2.cptCode1Result != null) {
               PC_eBenefits.ProgramCoverageBenefitItem cpt1 = new PC_eBenefits.ProgramCoverageBenefitItem();



               cpt1.name = request.secondaryHealthPlan.memberId +
                       COLON+ String.valueOf(PC_Constants.BenefitCategory.Administration);
               if(!String.isEmpty(soapResponse.inputParameters.cptCode1)){

                   cpt1.name += COLON +soapResponse.inputParameters.cptCode1;

               }
               cpt1.benefitCategory = String.valueOf(PC_Constants.BenefitCategory.Administration);
               //cpt1.benefitCategory = String.valueOf(PC_Constants.BenefitCategory.CPT);

               cpt1.serviceTypeCode =soapResponse.inputParameters.cptCode1;
               cpt1.serviceType = request.cptCodeMap.get(soapResponse.inputParameters.cptCode1);

               cpt1.coverageLevel = soapResponse.policy2.cptCode1Result.cptStatus;
               cpt1.deductableApplies = categoryBasedCPTInfo(soapResponse.policy2.cptCode1Result.dedApplies);
               cpt1.copayApplies = categoryBasedCPTInfo(soapResponse.policy2.cptCode1Result.copayApplies);
               cpt1.coinsuranceApplies = categoryBasedCPTInfo(soapResponse.policy2.cptCode1Result.coinsApplies);
               cpt1.oopMaxApplies = categoryBasedCPTInfo(soapResponse.policy2.cptCode1Result.oopMaxApplies);
               cpt1.pcpCopayAmount = convertCurrenyToDecimal(soapResponse.policy2.cptCode1Result.pcpCopayAmt);
               cpt1.specialistCopayAmount = convertCurrenyToDecimal(soapResponse.policy2.cptCode1Result.specCopayAmt);
               cpt1.coinsurancePercent = parseTextAsPercent(soapResponse.policy2.cptCode1Result.coinsAmt);
               response.programCoverage.secondaryCoverageBenefit.benefitItems.add(cpt1);


           }
       }

    }

   private void updateResponseWithCoverageBenefit2_CptCode2Result(PC_eBenefits.MedicalBenefitsResponse response,
            PC_VirMedicaWSDL2Apex.medeBVResponse soapResponse, PC_eBenefits.MedicalBenefitsRequest request) {


        //PC_eBenefits.ProgramCoverageBenefitItem  coverageBenefitItem = new  PC_eBenefits.ProgramCoverageBenefitItem();

       if(soapResponse.policy2 !=null) {



           if (soapResponse.policy2.cptCode2Result != null) {



               PC_eBenefits.ProgramCoverageBenefitItem cpt2 = new PC_eBenefits.ProgramCoverageBenefitItem();


               cpt2.name = request.secondaryHealthPlan.memberId +
                       COLON+ String.valueOf(PC_Constants.BenefitCategory.Administration);
               if(!String.isEmpty(soapResponse.inputParameters.cptCode2)){

                   cpt2.name += COLON +soapResponse.inputParameters.cptCode2;

               }
               cpt2.benefitCategory = String.valueOf(PC_Constants.BenefitCategory.Administration);
               //cpt2.benefitCategory = String.valueOf(PC_Constants.BenefitCategory.CPT);

               cpt2.serviceTypeCode =soapResponse.inputParameters.cptCode2;
               cpt2.serviceType = request.cptCodeMap.get(soapResponse.inputParameters.cptCode2);

               cpt2.coverageLevel = soapResponse.policy2.cptCode2Result.cptStatus;
               cpt2.deductableApplies = categoryBasedCPTInfo(soapResponse.policy2.cptCode2Result.dedApplies);
               cpt2.copayApplies = categoryBasedCPTInfo(soapResponse.policy2.cptCode2Result.copayApplies);
               cpt2.coinsuranceApplies = categoryBasedCPTInfo(soapResponse.policy2.cptCode2Result.coinsApplies);
               cpt2.oopMaxApplies = categoryBasedCPTInfo(soapResponse.policy2.cptCode2Result.oopMaxApplies);
               cpt2.pcpCopayAmount = convertCurrenyToDecimal(soapResponse.policy2.cptCode2Result.pcpCopayAmt);
               cpt2.specialistCopayAmount = convertCurrenyToDecimal(soapResponse.policy2.cptCode2Result.specCopayAmt);
               cpt2.coinsurancePercent = parseTextAsPercent(soapResponse.policy2.cptCode2Result.coinsAmt);
               response.programCoverage.secondaryCoverageBenefit.benefitItems.add(cpt2);

           }
       }

    }

   private void updateResponseWithCoverageBenefit2_CptCode3Result(PC_eBenefits.MedicalBenefitsResponse response,
            PC_VirMedicaWSDL2Apex.medeBVResponse soapResponse, PC_eBenefits.MedicalBenefitsRequest request) {


        //PC_eBenefits.ProgramCoverageBenefitItem  coverageBenefitItem = new  PC_eBenefits.ProgramCoverageBenefitItem();
       if(soapResponse.policy2 !=null) {



           if (soapResponse.policy2.cptCode3Result != null) {
               PC_eBenefits.ProgramCoverageBenefitItem cpt3 = new PC_eBenefits.ProgramCoverageBenefitItem();

               cpt3.name = request.secondaryHealthPlan.memberId +
                       COLON+ String.valueOf(PC_Constants.BenefitCategory.Administration);
               if(!String.isEmpty(soapResponse.inputParameters.cptCode3)){

                   cpt3.name += COLON +soapResponse.inputParameters.cptCode3;

               }
               cpt3.benefitCategory = String.valueOf(PC_Constants.BenefitCategory.Administration);
               //cpt3.benefitCategory = String.valueOf(PC_Constants.BenefitCategory.CPT);

               cpt3.serviceTypeCode =soapResponse.inputParameters.cptCode3;
               cpt3.serviceType = request.cptCodeMap.get(soapResponse.inputParameters.cptCode3);
               cpt3.coverageLevel = soapResponse.policy2.cptCode3Result.cptStatus;
               cpt3.deductableApplies = categoryBasedCPTInfo(soapResponse.policy2.cptCode3Result.dedApplies);
               cpt3.copayApplies = categoryBasedCPTInfo(soapResponse.policy2.cptCode3Result.copayApplies);
               cpt3.coinsuranceApplies = categoryBasedCPTInfo(soapResponse.policy2.cptCode3Result.coinsApplies);
               cpt3.oopMaxApplies = categoryBasedCPTInfo(soapResponse.policy2.cptCode3Result.oopMaxApplies);
               cpt3.pcpCopayAmount = convertCurrenyToDecimal(soapResponse.policy2.cptCode3Result.pcpCopayAmt);
               cpt3.specialistCopayAmount = convertCurrenyToDecimal(soapResponse.policy2.cptCode3Result.specCopayAmt);
               cpt3.coinsurancePercent = parseTextAsPercent(soapResponse.policy2.cptCode3Result.coinsAmt);
               response.programCoverage.secondaryCoverageBenefit.benefitItems.add(cpt3);

           }
       }

    }

   private void updateResponseWithCoverageBenefit2_CptCode4Result(PC_eBenefits.MedicalBenefitsResponse response,
            PC_VirMedicaWSDL2Apex.medeBVResponse soapResponse, PC_eBenefits.MedicalBenefitsRequest request) {


        //PC_eBenefits.ProgramCoverageBenefitItem  coverageBenefitItem = new  PC_eBenefits.ProgramCoverageBenefitItem();

       if(soapResponse.policy2 !=null) {



           if (soapResponse.policy2.cptCode4Result != null) {
               PC_eBenefits.ProgramCoverageBenefitItem cpt4 = new PC_eBenefits.ProgramCoverageBenefitItem();

               cpt4.name = request.secondaryHealthPlan.memberId +
                       COLON+ String.valueOf(PC_Constants.BenefitCategory.Administration);
               if(!String.isEmpty(soapResponse.inputParameters.cptCode4)){

                   cpt4.name += COLON +soapResponse.inputParameters.cptCode4;

               }
               cpt4.benefitCategory = String.valueOf(PC_Constants.BenefitCategory.Administration);
               //cpt4.benefitCategory = String.valueOf(PC_Constants.BenefitCategory.CPT);
               cpt4.serviceTypeCode =soapResponse.inputParameters.cptCode4;
               cpt4.serviceType = request.cptCodeMap.get(soapResponse.inputParameters.cptCode4);
               cpt4.coverageLevel = soapResponse.policy2.cptCode4Result.cptStatus;
               cpt4.deductableApplies = categoryBasedCPTInfo(soapResponse.policy2.cptCode4Result.dedApplies);
               cpt4.copayApplies = categoryBasedCPTInfo(soapResponse.policy2.cptCode4Result.copayApplies);
               cpt4.coinsuranceApplies = categoryBasedCPTInfo(soapResponse.policy2.cptCode4Result.coinsApplies);
               cpt4.oopMaxApplies = categoryBasedCPTInfo(soapResponse.policy2.cptCode4Result.oopMaxApplies);
               cpt4.pcpCopayAmount = convertCurrenyToDecimal(soapResponse.policy2.cptCode4Result.pcpCopayAmt);
               cpt4.specialistCopayAmount = convertCurrenyToDecimal(soapResponse.policy2.cptCode4Result.specCopayAmt);
               cpt4.coinsurancePercent = parseTextAsPercent(soapResponse.policy2.cptCode4Result.coinsAmt);
               response.programCoverage.secondaryCoverageBenefit.benefitItems.add(cpt4);

           }
       }

    }

   private void updateResponseWithCoverageBenefit2_CptCode5Result(PC_eBenefits.MedicalBenefitsResponse response,
            PC_VirMedicaWSDL2Apex.medeBVResponse soapResponse, PC_eBenefits.MedicalBenefitsRequest request) {


       if(soapResponse.policy2 !=null) {



           if (soapResponse.policy2.cptCode5Result != null) {
               PC_eBenefits.ProgramCoverageBenefitItem cpt5 = new PC_eBenefits.ProgramCoverageBenefitItem();


               cpt5.name = request.secondaryHealthPlan.memberId +
                       COLON+ String.valueOf(PC_Constants.BenefitCategory.Administration);
               if(!String.isEmpty(soapResponse.inputParameters.cptCode5)){

                   cpt5.name += COLON +soapResponse.inputParameters.cptCode5;

               }
               cpt5.benefitCategory = String.valueOf(PC_Constants.BenefitCategory.Administration);
               //cpt5.benefitCategory = String.valueOf(PC_Constants.BenefitCategory.CPT);
               cpt5.serviceTypeCode =soapResponse.inputParameters.cptCode5;
               cpt5.serviceType = request.cptCodeMap.get(soapResponse.inputParameters.cptCode5);
               cpt5.coverageLevel = soapResponse.policy2.cptCode5Result.cptStatus;
               cpt5.deductableApplies = categoryBasedCPTInfo(soapResponse.policy2.cptCode5Result.dedApplies);
               cpt5.copayApplies = categoryBasedCPTInfo(soapResponse.policy2.cptCode5Result.copayApplies);
               cpt5.coinsuranceApplies = categoryBasedCPTInfo(soapResponse.policy2.cptCode5Result.coinsApplies);
               cpt5.oopMaxApplies = categoryBasedCPTInfo(soapResponse.policy2.cptCode5Result.oopMaxApplies);
               cpt5.pcpCopayAmount = convertCurrenyToDecimal(soapResponse.policy2.cptCode5Result.pcpCopayAmt);
               cpt5.specialistCopayAmount = convertCurrenyToDecimal(soapResponse.policy2.cptCode5Result.specCopayAmt);
               cpt5.coinsurancePercent = parseTextAsPercent(soapResponse.policy2.cptCode5Result.coinsAmt);
               response.programCoverage.secondaryCoverageBenefit.benefitItems.add(cpt5);


           }
       }

    }


    /* coveragebenefit3 */

   private void updateResponseWithCoverageBenefit3Data(PC_eBenefits.MedicalBenefitsResponse response,
            PC_VirMedicaWSDL2Apex.medeBVResponse soapResponse) {





       if(soapResponse.policy3 !=null) {



           PC_eBenefits.ProgramCoverageBenefit programCoverageBenefit3 = new PC_eBenefits.ProgramCoverageBenefit();
           programCoverageBenefit3.transactionId = soapResponse.policy3.transactionId;
           programCoverageBenefit3.transactionDate = soapResponse.policy3.transactionDate;
           programCoverageBenefit3.coverageStatus = soapResponse.policy3.eligibilityStatus;
           programCoverageBenefit3.startDate = soapResponse.policy3.effDate;
           programCoverageBenefit3.endDate = soapResponse.policy3.endDate;
           programCoverageBenefit3.payerName = soapResponse.policy3.payerName;
           programCoverageBenefit3.planType = soapResponse.policy3.planType;
           programCoverageBenefit3.groupNo = soapResponse.policy3.groupNumber;
           programCoverageBenefit3.groupName = soapResponse.policy3.groupName;


           Decimal  dedIndAmt =
                   PC_VirMedica_Utility.convertCurrenyToDecimal( soapResponse.policy3.dedIndAmt);
           if(dedIndAmt !=null) {
               programCoverageBenefit3.individualInNetworkDeductibleLimit =dedIndAmt;
           }

           Decimal dedIndAmtMet =
                   PC_VirMedica_Utility.convertCurrenyToDecimal(soapResponse.policy3.dedIndAmtMet);
           if( dedIndAmt != null && dedIndAmtMet != null) {
               programCoverageBenefit3.individualInNetworkDeductibleRemaining =dedIndAmt -dedIndAmtMet;
           }

           Decimal oopMaxIndAmt =
                   PC_VirMedica_Utility.convertCurrenyToDecimal(soapResponse.policy3.oopMaxIndAmt);
           if(oopMaxIndAmt !=null) {
               programCoverageBenefit3.individualInNetworkOutofPocketLimit =oopMaxIndAmt;
           }

           Decimal oopMaxIndMet =
                   PC_VirMedica_Utility.convertCurrenyToDecimal(soapResponse.policy3.oopMaxIndMet);
           if( oopMaxIndAmt != null && oopMaxIndMet != null) {
               programCoverageBenefit3.individualInNetworkOutofPocketRemaining =oopMaxIndAmt -oopMaxIndMet;
           }


           Decimal dedFamAmt =
                   PC_VirMedica_Utility.convertCurrenyToDecimal(soapResponse.policy3.dedFamAmt);
           if(dedFamAmt !=null) {
               programCoverageBenefit3.familyInNetworkDeductibleLimit = dedFamAmt;
           }

           Decimal dedFamAmtMet =
                   PC_VirMedica_Utility.convertCurrenyToDecimal( soapResponse.policy3.dedFamAmtMet);
           if( dedFamAmt != null && dedFamAmtMet!=null) {
               programCoverageBenefit3.familyInNetworkDeductibleRemaining = dedFamAmt - dedFamAmtMet;
           }

           Decimal oopMaxFamAmt =
                   PC_VirMedica_Utility.convertCurrenyToDecimal(soapResponse.policy3.oopMaxFamAmt);
           if(oopMaxFamAmt != null) {
               programCoverageBenefit3.familyInNetworkOutofPocketLimit =  oopMaxFamAmt;
           }

           Decimal oopMaxFamMet =
                   PC_VirMedica_Utility.convertCurrenyToDecimal( soapResponse.policy3.oopMaxFamMet);
           if(oopMaxFamAmt != null && oopMaxFamMet!= null) {
               programCoverageBenefit3.familyInNetworkOutofPocketRemaining =oopMaxFamAmt - oopMaxFamMet;
           }


           programCoverageBenefit3.paRequired = soapResponse.policy3.priorAuthRqd;
           programCoverageBenefit3.buyAndBill = soapResponse.policy3.buyBill;
           programCoverageBenefit3.specialtyPharmacyRequired = soapResponse.policy3.spReq;
           programCoverageBenefit3.specialtyPharmacyInfo = soapResponse.policy3.spName;


           programCoverageBenefit3.isGovernmentPlan = soapResponse.policy3.govInd;
           programCoverageBenefit3.governmentPlanType = soapResponse.policy3.govPolicyType;
           programCoverageBenefit3.transactionMessageID = soapResponse.policy3.msgId;
           programCoverageBenefit3.benefitNotes = soapResponse.policy3.msgContent;
           programCoverageBenefit3.productAdminMessage = soapResponse.policy3.customMessage1 ;
           programCoverageBenefit3.billingMessage = soapResponse.policy3.customMessage2 ;
           programCoverageBenefit3.priorAuthMessage = soapResponse.policy3.customMessage3 ;
           programCoverageBenefit3.payerMessage = soapResponse.policy3.customMessage4 ;
           programCoverageBenefit3.coverageLevel = PC_Constants.HEALTH_PLAN_TYPE_TERTIARY;
           response.programCoverage.tertiaryCoverageBenefit = programCoverageBenefit3;

       }
   }

    private void updateResponseWithCoverageBenefit3_OfficeResult(PC_eBenefits.MedicalBenefitsResponse response,
            PC_VirMedicaWSDL2Apex.medeBVResponse soapResponse, PC_eBenefits.MedicalBenefitsRequest request) {

        if(soapResponse.policy3 !=null) {


            PC_eBenefits.ProgramCoverageBenefitItem officeCategory = new PC_eBenefits.ProgramCoverageBenefitItem();
            officeCategory.name = request.tertiaryHealthPlan.memberId + COLON +
                                                       String.valueOf(PC_Constants.BenefitCategory.OfficeVisit);
            officeCategory.benefitCategory = String.valueOf(PC_Constants.BenefitCategory.OfficeVisit);
            officeCategory.serviceTypeCode =soapResponse.inputParameters.cptCode1;
            officeCategory.serviceType = request.cptCodeMap.get(soapResponse.inputParameters.cptCode1);
            officeCategory.coverageLevel = soapResponse.policy3.officeVisitStatus;
            officeCategory.deductableApplies = categoryBasedCPTInfo(soapResponse.policy3.officeVisitDedApplies);
            officeCategory.copayApplies = categoryBasedCPTInfo(soapResponse.policy3.officeVisitCopayApplies);
            officeCategory.coinsuranceApplies = categoryBasedCPTInfo(soapResponse.policy3.officeVisitCoinsApplies);
            officeCategory.oopMaxApplies = categoryBasedCPTInfo(soapResponse.policy3.officeVisitOopMaxApplies);
            officeCategory.pcpCopayAmount = convertCurrenyToDecimal(soapResponse.policy3.officeCopayPCPAmt);
            officeCategory.specialistCopayAmount = convertCurrenyToDecimal(soapResponse.policy3.officeSpecCopayAmt);
            officeCategory.coinsurancePercent = parseTextAsPercent(soapResponse.policy3.officeCoinsAmt);
            response.programCoverage.tertiaryCoverageBenefit.benefitItems.add(officeCategory);

        }


    }


    private void updateResponseWithCoverageBenefit3_ProductResult(PC_eBenefits.MedicalBenefitsResponse response,
            PC_VirMedicaWSDL2Apex.medeBVResponse soapResponse, PC_eBenefits.MedicalBenefitsRequest request) {


        if(soapResponse.policy3 !=null) {




            PC_eBenefits.ProgramCoverageBenefitItem productCategory = new PC_eBenefits.ProgramCoverageBenefitItem();

            productCategory.name =request.tertiaryHealthPlan.memberId  +COLON +
                                            String.valueOf(PC_Constants.BenefitCategory.Product)  ;

            if(!String.isEmpty(request.prescription.productName)){

                productCategory.name += COLON + request.prescription.productName;

            }
            productCategory.benefitCategory = String.valueOf(PC_Constants.BenefitCategory.Product);
            productCategory.serviceTypeCode =request.prescription.productName;
            productCategory.serviceType = PC_Constants.NA;
            productCategory.coverageLevel = soapResponse.policy3.productStatus;
            productCategory.deductableApplies = categoryBasedCPTInfo(soapResponse.policy3.productDedApplies);
            productCategory.copayApplies = categoryBasedCPTInfo(soapResponse.policy3.productCopayApplies);
            productCategory.coinsuranceApplies = categoryBasedCPTInfo(soapResponse.policy3.productCoinsApplies);
            productCategory.oopMaxApplies = categoryBasedCPTInfo(soapResponse.policy3.productOopMaxApplies);
            productCategory.pcpCopayAmount = convertCurrenyToDecimal(soapResponse.policy3.productPCPCopayAmt);
            productCategory.specialistCopayAmount = convertCurrenyToDecimal(soapResponse.policy3.productSpecCopayAmt);
            productCategory.coinsurancePercent = parseTextAsPercent(soapResponse.policy3.productCoinsAmt);
            response.programCoverage.tertiaryCoverageBenefit.benefitItems.add(productCategory);

        }


    }


   private void updateResponseWithCoverageBenefit3_CptCode1Result(PC_eBenefits.MedicalBenefitsResponse response,
            PC_VirMedicaWSDL2Apex.medeBVResponse soapResponse, PC_eBenefits.MedicalBenefitsRequest request) {


        //PC_eBenefits.ProgramCoverageBenefitItem  coverageBenefitItem = new  PC_eBenefits.ProgramCoverageBenefitItem();

       if(soapResponse.policy3 !=null) {

           if (soapResponse.policy3.cptCode1Result != null) {
               PC_eBenefits.ProgramCoverageBenefitItem cpt1 = new PC_eBenefits.ProgramCoverageBenefitItem();

               cpt1.name = request.tertiaryHealthPlan.memberId +
                       COLON+ String.valueOf(PC_Constants.BenefitCategory.Administration);
               if(!String.isEmpty(soapResponse.inputParameters.cptCode1)){

                   cpt1.name += COLON +soapResponse.inputParameters.cptCode1;

               }
               cpt1.benefitCategory = String.valueOf(PC_Constants.BenefitCategory.Administration);
               //cpt1.benefitCategory = String.valueOf(PC_Constants.BenefitCategory.CPT);
               cpt1.serviceTypeCode =soapResponse.inputParameters.cptCode1;
               cpt1.serviceType = request.cptCodeMap.get(soapResponse.inputParameters.cptCode1);

               cpt1.coverageLevel = soapResponse.policy3.cptCode1Result.cptStatus;
               cpt1.deductableApplies = categoryBasedCPTInfo(soapResponse.policy3.cptCode1Result.dedApplies);
               cpt1.copayApplies = categoryBasedCPTInfo(soapResponse.policy3.cptCode1Result.copayApplies);
               cpt1.coinsuranceApplies = categoryBasedCPTInfo(soapResponse.policy3.cptCode1Result.coinsApplies);
               cpt1.oopMaxApplies = categoryBasedCPTInfo(soapResponse.policy3.cptCode1Result.oopMaxApplies);
               cpt1.pcpCopayAmount = convertCurrenyToDecimal(soapResponse.policy3.cptCode1Result.pcpCopayAmt);
               cpt1.specialistCopayAmount = convertCurrenyToDecimal(soapResponse.policy3.cptCode1Result.specCopayAmt);
               cpt1.coinsurancePercent = parseTextAsPercent(soapResponse.policy3.cptCode1Result.coinsAmt);
               response.programCoverage.tertiaryCoverageBenefit.benefitItems.add(cpt1);

           }
       }

    }

   private void updateResponseWithCoverageBenefit3_CptCode2Result(PC_eBenefits.MedicalBenefitsResponse response,
            PC_VirMedicaWSDL2Apex.medeBVResponse soapResponse, PC_eBenefits.MedicalBenefitsRequest request) {


        //PC_eBenefits.ProgramCoverageBenefitItem  coverageBenefitItem = new  PC_eBenefits.ProgramCoverageBenefitItem();

       if(soapResponse.policy3 !=null) {



           if (soapResponse.policy3.cptCode2Result != null) {
               PC_eBenefits.ProgramCoverageBenefitItem cpt2 = new PC_eBenefits.ProgramCoverageBenefitItem();
               cpt2.name = request.tertiaryHealthPlan.memberId +
                       COLON+ String.valueOf(PC_Constants.BenefitCategory.Administration);
               if(!String.isEmpty(soapResponse.inputParameters.cptCode2)){

                   cpt2.name += COLON +soapResponse.inputParameters.cptCode2;

               }
               cpt2.benefitCategory = String.valueOf(PC_Constants.BenefitCategory.Administration);
               //cpt2.benefitCategory = String.valueOf(PC_Constants.BenefitCategory.CPT);
               cpt2.serviceTypeCode =soapResponse.inputParameters.cptCode2;
               cpt2.serviceType = request.cptCodeMap.get(soapResponse.inputParameters.cptCode2);

               cpt2.coverageLevel = soapResponse.policy3.cptCode2Result.cptStatus;
               cpt2.deductableApplies = categoryBasedCPTInfo(soapResponse.policy3.cptCode2Result.dedApplies);
               cpt2.copayApplies = categoryBasedCPTInfo(soapResponse.policy3.cptCode2Result.copayApplies);
               cpt2.coinsuranceApplies = categoryBasedCPTInfo(soapResponse.policy3.cptCode2Result.coinsApplies);
               cpt2.oopMaxApplies = categoryBasedCPTInfo(soapResponse.policy3.cptCode2Result.oopMaxApplies);
               cpt2.pcpCopayAmount = convertCurrenyToDecimal(soapResponse.policy3.cptCode2Result.pcpCopayAmt);
               cpt2.specialistCopayAmount = convertCurrenyToDecimal(soapResponse.policy3.cptCode2Result.specCopayAmt);
               cpt2.coinsurancePercent = parseTextAsPercent(soapResponse.policy3.cptCode2Result.coinsAmt);
               response.programCoverage.tertiaryCoverageBenefit.benefitItems.add(cpt2);


           }
       }

    }

   private void updateResponseWithCoverageBenefit3_CptCode3Result(PC_eBenefits.MedicalBenefitsResponse response,
            PC_VirMedicaWSDL2Apex.medeBVResponse soapResponse, PC_eBenefits.MedicalBenefitsRequest request) {


        //PC_eBenefits.ProgramCoverageBenefitItem  coverageBenefitItem = new  PC_eBenefits.ProgramCoverageBenefitItem();

       if(soapResponse.policy3 !=null) {



           if (soapResponse.policy3.cptCode3Result != null) {
               PC_eBenefits.ProgramCoverageBenefitItem cpt3 = new PC_eBenefits.ProgramCoverageBenefitItem();

               cpt3.name = request.tertiaryHealthPlan.memberId +
                       COLON+ String.valueOf(PC_Constants.BenefitCategory.Administration);
               if(!String.isEmpty(soapResponse.inputParameters.cptCode3)){

                   cpt3.name += COLON +soapResponse.inputParameters.cptCode3;

               }
               cpt3.benefitCategory = String.valueOf(PC_Constants.BenefitCategory.Administration);
               //cpt3.benefitCategory = String.valueOf(PC_Constants.BenefitCategory.CPT);
               cpt3.serviceTypeCode =soapResponse.inputParameters.cptCode3;
               cpt3.serviceType = request.cptCodeMap.get(soapResponse.inputParameters.cptCode3);

               cpt3.coverageLevel = soapResponse.policy3.cptCode3Result.cptStatus;
               cpt3.deductableApplies = categoryBasedCPTInfo(soapResponse.policy3.cptCode3Result.dedApplies);
               cpt3.copayApplies = categoryBasedCPTInfo(soapResponse.policy3.cptCode3Result.copayApplies);
               cpt3.coinsuranceApplies = categoryBasedCPTInfo(soapResponse.policy3.cptCode3Result.coinsApplies);
               cpt3.oopMaxApplies = categoryBasedCPTInfo(soapResponse.policy3.cptCode3Result.oopMaxApplies);
               cpt3.pcpCopayAmount = convertCurrenyToDecimal(soapResponse.policy3.cptCode3Result.pcpCopayAmt);
               cpt3.specialistCopayAmount = convertCurrenyToDecimal(soapResponse.policy3.cptCode3Result.specCopayAmt);
               cpt3.coinsurancePercent = parseTextAsPercent(soapResponse.policy3.cptCode3Result.coinsAmt);
               response.programCoverage.tertiaryCoverageBenefit.benefitItems.add(cpt3);


           }
       }

    }

   private void updateResponseWithCoverageBenefit3_CptCode4Result(PC_eBenefits.MedicalBenefitsResponse response,
            PC_VirMedicaWSDL2Apex.medeBVResponse soapResponse, PC_eBenefits.MedicalBenefitsRequest request) {


        //PC_eBenefits.ProgramCoverageBenefitItem  coverageBenefitItem = new  PC_eBenefits.ProgramCoverageBenefitItem();

       if(soapResponse.policy3 !=null) {



           if (soapResponse.policy3.cptCode4Result != null) {
               PC_eBenefits.ProgramCoverageBenefitItem cpt4 = new PC_eBenefits.ProgramCoverageBenefitItem();
               cpt4.name = request.tertiaryHealthPlan.memberId +
                       COLON+ String.valueOf(PC_Constants.BenefitCategory.Administration);
               if(!String.isEmpty(soapResponse.inputParameters.cptCode4)){

                   cpt4.name += COLON +soapResponse.inputParameters.cptCode4;

               }
               cpt4.benefitCategory = String.valueOf(PC_Constants.BenefitCategory.Administration);
               //cpt4.benefitCategory = String.valueOf(PC_Constants.BenefitCategory.CPT);
               cpt4.serviceTypeCode =soapResponse.inputParameters.cptCode4;
               cpt4.serviceType = request.cptCodeMap.get(soapResponse.inputParameters.cptCode4);

               cpt4.coverageLevel = soapResponse.policy3.cptCode4Result.cptStatus;
               cpt4.deductableApplies = categoryBasedCPTInfo(soapResponse.policy3.cptCode4Result.dedApplies);
               cpt4.copayApplies = categoryBasedCPTInfo(soapResponse.policy3.cptCode4Result.copayApplies);
               cpt4.coinsuranceApplies = categoryBasedCPTInfo(soapResponse.policy3.cptCode4Result.coinsApplies);
               cpt4.oopMaxApplies = categoryBasedCPTInfo(soapResponse.policy3.cptCode4Result.oopMaxApplies);
               cpt4.pcpCopayAmount = convertCurrenyToDecimal(soapResponse.policy3.cptCode4Result.pcpCopayAmt);
               cpt4.specialistCopayAmount = convertCurrenyToDecimal(soapResponse.policy3.cptCode4Result.specCopayAmt);
               cpt4.coinsurancePercent = parseTextAsPercent(soapResponse.policy3.cptCode4Result.coinsAmt);
               response.programCoverage.tertiaryCoverageBenefit.benefitItems.add(cpt4);



           }
       }

    }

   private void updateResponseWithCoverageBenefit3_CptCode5Result(PC_eBenefits.MedicalBenefitsResponse response,
            PC_VirMedicaWSDL2Apex.medeBVResponse soapResponse, PC_eBenefits.MedicalBenefitsRequest request) {


        //PC_eBenefits.ProgramCoverageBenefitItem  coverageBenefitItem = new  PC_eBenefits.ProgramCoverageBenefitItem();
       if(soapResponse.policy3 !=null) {



           if (soapResponse.policy3.cptCode5Result != null) {
               PC_eBenefits.ProgramCoverageBenefitItem cpt5 = new PC_eBenefits.ProgramCoverageBenefitItem();
               cpt5.name = request.secondaryHealthPlan.memberId +
                       COLON+ String.valueOf(PC_Constants.BenefitCategory.Administration);
               if(!String.isEmpty(soapResponse.inputParameters.cptCode5)){

                   cpt5.name += COLON +soapResponse.inputParameters.cptCode5;

               }
               cpt5.benefitCategory = String.valueOf(PC_Constants.BenefitCategory.Administration);
               //cpt5.benefitCategory = String.valueOf(PC_Constants.BenefitCategory.CPT);
               cpt5.serviceTypeCode =soapResponse.inputParameters.cptCode5;
               cpt5.serviceType = request.cptCodeMap.get(soapResponse.inputParameters.cptCode5);
               cpt5.coverageLevel = soapResponse.policy3.cptCode5Result.cptStatus;
               cpt5.deductableApplies = categoryBasedCPTInfo(soapResponse.policy3.cptCode5Result.dedApplies);
               cpt5.copayApplies = categoryBasedCPTInfo(soapResponse.policy3.cptCode5Result.copayApplies);
               cpt5.coinsuranceApplies = categoryBasedCPTInfo(soapResponse.policy3.cptCode5Result.coinsApplies);
               cpt5.oopMaxApplies = categoryBasedCPTInfo(soapResponse.policy3.cptCode5Result.oopMaxApplies);
               cpt5.pcpCopayAmount = convertCurrenyToDecimal(soapResponse.policy3.cptCode5Result.pcpCopayAmt);
               cpt5.specialistCopayAmount = convertCurrenyToDecimal(soapResponse.policy3.cptCode5Result.specCopayAmt);
               cpt5.coinsurancePercent = parseTextAsPercent(soapResponse.policy3.cptCode5Result.coinsAmt);
               response.programCoverage.tertiaryCoverageBenefit.benefitItems.add(cpt5);



           }
       }

    }


    public static String categoryBasedCPTInfo(String inputParam){

        String outputParam = PC_Constants.EMPTY_STRING;

        if(inputParam !=null) {

            if (inputParam.equalsIgnoreCase(Yes)) {
                outputParam = Yes;
            } else if (inputParam.equalsIgnoreCase(No)) {
                outputParam = No;
            } else if (inputParam.equalsIgnoreCase(Undetermined)) {
                outputParam = Undetermined;
            }
            /*if(inputParam.equalsIgnoreCase(NA)){
            outputParam = NA;
        }*/ else {
                outputParam = NA;
            }
        }
        return outputParam;
    }


    public static Decimal convertCurrenyToDecimal(String inputParam){

        if (String.isNotBlank(inputParam) && !inputParam.equalsIgnoreCase(PC_Constants.NOT_FOUND)) {
            //
            Pattern dollarPattern = Pattern.compile('[\\p{Sc},]');
            string s = dollarPattern.matcher(inputParam).replaceAll(PC_Constants.EMPTY_STRING);
            return Decimal.valueOf(s);
        }
        return null;
    }




}