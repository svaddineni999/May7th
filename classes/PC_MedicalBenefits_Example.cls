/**
 * Created by shisbansal on 3/15/2019.
 ***************************************************
 * Modification Log:
 * Shishir Bansal     Initial Version
Haritha Reddy             21-Jan-2021         [PC-7102] Force Reviewer scan issue fix. Updated Sharing declaration.
 */

public with sharing class PC_MedicalBenefits_Example implements PC_eBenefits.MedicalBenefits{

    private static string COMPLETE = 'Complete';
    private static string COLON = ':';

    public PC_eBenefits.MedicalBenefitsRequest createMedicalBenefitRequest() {
        return new PC_eBenefits.MedicalBenefitsRequest();

    }

    public PC_eBenefits.MedicalBenefitsResponse lookupMedicalBenefits(PC_eBenefits.MedicalBenefitsRequest request){
        try {

            // PC_MedicalEbenefitsLookup_Example client = new PC_MedicalEbenefitsLookup_Example();


            system.debug('cptCodes'+request.cptCodes);
            system.debug('cptCodes'+request.cptCodes.size());




            PC_eBenefits.MedicalBenefitsResponse response  = new PC_eBenefits.MedicalBenefitsResponse() ;

            response.ProgramCoverage.coordinatedPlanBenefits = 'Health ';
            response.ProgramCoverage.completionStatus =COMPLETE;

            PC_eBenefits.ProgramCoverageBenefit programCoverage = new PC_eBenefits.ProgramCoverageBenefit();
            // programCoverage.memberPlan.id='A24825528';
            programCoverage.transactionId = '12020';
            programCoverage.transactionDate = System.today();
            programCoverage.coverageStatus = PC_Constants.ACTIVE;  //eligibilityStatus
            programCoverage.startDate =System.today();
            programCoverage.endDate = System.today().addDays(10);
            programCoverage.payerName = 'Medicare';
            programCoverage.planName = 'Medicare';
            programCoverage.planType = 'Medicare Part B';
            programCoverage.groupNo = '11942';
            programCoverage.groupName = 'COV-11942';
            programCoverage.individualInNetworkDeductibleLimit = 180.0;
            programCoverage.individualInNetworkDeductibleRemaining = 90.2;
            programCoverage.familyInNetworkDeductibleLimit = 100.0;
            programCoverage.familyInNetworkDeductibleRemaining = 40.5;
            programCoverage.individualInNetworkOutofPocketLimit = 200.5;
            programCoverage.individualInNetworkOutofPocketRemaining = 100.5;
            programCoverage.familyInNetworkOutofPocketLimit = 90.5;
            programCoverage.familyInNetworkOutofPocketRemaining = 10.6;
            programCoverage.paRequired = PC_Constants.NO_STRING;
            programCoverage.buyAndBill = PC_Constants.YES_STRING;
            programCoverage.specialtyPharmacyRequired = PC_Constants.YES_STRING;
            programCoverage.specialtyPharmacyInfo = PC_Constants.YES_STRING;
            programCoverage.isGovernmentPlan = PC_Constants.YES_STRING;
            programCoverage.governmentPlanType = 'Medicaid, Medicare';
            programCoverage.transactionMessageID = '082';
            programCoverage.productAdminMessage = 'Test product admin';
            programCoverage.billingMessage = 'Test billing message';
            programCoverage.priorAuthMessage = 'Test prior auth message';
            programCoverage.payerMessage = 'Test payer';
            programCoverage.benefitNotes = 'Test benefitNotes';
            programCoverage.coverageLevel = PC_Constants.HEALTH_PLAN_TYPE_PRIMARY;
            programCoverage.coverageLevel = PC_Constants.HEALTH_PLAN_TYPE_PRIMARY;







            PC_eBenefits.ProgramCoverageBenefit  primaryCoverageBenefit =
                                                           getcoverageBenefit(PC_Constants.HEALTH_PLAN_TYPE_PRIMARY);


            response.programCoverage.primaryCoverageBenefit =primaryCoverageBenefit;

            String val ='';


            if(request.cptCodes !=null){

                if(request.cptCodes.size()>0 ) {

                    val = String.valueOf(PC_Constants.BenefitCategory.Product);
                    PC_eBenefits.ProgramCoverageBenefitItem coverageBenefitItem1 =
                            getcoverageBenefitItem(val, request.primaryHealthPlan.memberId + COLON +
                                    String.valueOf(PC_Constants.BenefitCategory.Product)+
                                    COLON + request.prescription.productName);

                    response.programCoverage.primaryCoverageBenefit.benefitItems.add(coverageBenefitItem1);


                    val = String.valueOf(PC_Constants.BenefitCategory.OfficeVisit);
                    PC_eBenefits.ProgramCoverageBenefitItem coverageBenefitItem2 =
                            getcoverageBenefitItem(val, request.primaryHealthPlan.memberId + COLON +
                                    String.valueOf(PC_Constants.BenefitCategory.OfficeVisit));

                    response.programCoverage.primaryCoverageBenefit.benefitItems.add(coverageBenefitItem2);


                    PC_eBenefits.ProgramCoverageBenefitItem coverageBenefitItem;


                    for (Integer i = 0; i < request.cptCodes.size(); i++) {

                        val = String.valueOf(PC_Constants.BenefitCategory.Administration);
                        coverageBenefitItem =
                                getcoverageBenefitItem(val,   request.primaryHealthPlan.memberId +
                                        COLON+ String.valueOf(PC_Constants.BenefitCategory.Administration)+
                                        COLON + request.cptCodes[i]);

                        response.programCoverage.primaryCoverageBenefit.benefitItems.add(coverageBenefitItem);
                    }
                }
            }

           if (request.secondaryHealthPlan !=null) {

                PC_eBenefits.ProgramCoverageBenefit secondaryCoverageBenefit =
                                                    getcoverageBenefit( PC_Constants.HEALTH_PLAN_TYPE_SECONDARY);
                response.programCoverage.secondaryCoverageBenefit = secondaryCoverageBenefit;




                if(request.cptCodes !=null) {


                    if (request.cptCodes.size() > 0) {

                        val = String.valueOf(PC_Constants.BenefitCategory.Product);
                        PC_eBenefits.ProgramCoverageBenefitItem coverageBenefitItem1 =
                                getcoverageBenefitItem(val, request.secondaryHealthPlan.memberId + COLON +
                                        String.valueOf(PC_Constants.BenefitCategory.Product)+
                                        COLON + request.prescription.productName);

                        response.programCoverage.secondaryCoverageBenefit.benefitItems.add(coverageBenefitItem1);


                        val = String.valueOf(PC_Constants.BenefitCategory.OfficeVisit);
                        PC_eBenefits.ProgramCoverageBenefitItem coverageBenefitItem2 =
                                getcoverageBenefitItem(val, request.secondaryHealthPlan.memberId + COLON +
                                        String.valueOf(PC_Constants.BenefitCategory.OfficeVisit));

                        response.programCoverage.secondaryCoverageBenefit.benefitItems.add(coverageBenefitItem2);


                        PC_eBenefits.ProgramCoverageBenefitItem coverageBenefitItem;


                        for (Integer i = 0; i < request.cptCodes.size(); i++) {

                            val = String.valueOf(PC_Constants.BenefitCategory.Administration);
                            coverageBenefitItem =
                                    getcoverageBenefitItem(val,  request.secondaryHealthPlan.memberId +
                                            COLON+ String.valueOf(PC_Constants.BenefitCategory.Administration)+
                                            COLON + request.cptCodes[i]);

                            response.programCoverage.secondaryCoverageBenefit.benefitItems.add(coverageBenefitItem);
                        }
                    }
                }

            }


            if (request.tertiaryHealthPlan != null) {

                PC_eBenefits.ProgramCoverageBenefit tertiaryCoverageBenefit =
                                                             getcoverageBenefit(PC_Constants.HEALTH_PLAN_TYPE_TERTIARY);
                response.programCoverage.tertiaryCoverageBenefit = tertiaryCoverageBenefit;


                if(request.cptCodes !=null) {

                    if (request.cptCodes.size() > 0) {

                        val = String.valueOf(PC_Constants.BenefitCategory.Product);
                        PC_eBenefits.ProgramCoverageBenefitItem coverageBenefitItem1 = getcoverageBenefitItem(val,
                                request.tertiaryHealthPlan.memberId + COLON +
                                String.valueOf(PC_Constants.BenefitCategory.Product)+
                                        COLON + request.prescription.productName);

                        response.programCoverage.tertiaryCoverageBenefit.benefitItems.add(coverageBenefitItem1);


                        val = String.valueOf(PC_Constants.BenefitCategory.OfficeVisit);
                        PC_eBenefits.ProgramCoverageBenefitItem coverageBenefitItem2 = getcoverageBenefitItem(val,
                                request.tertiaryHealthPlan.memberId + COLON +
                                String.valueOf(PC_Constants.BenefitCategory.OfficeVisit));

                        response.programCoverage.tertiaryCoverageBenefit.benefitItems.add(coverageBenefitItem2);
                        PC_eBenefits.ProgramCoverageBenefitItem coverageBenefitItem;


                        for (Integer i = 0; i < request.cptCodes.size(); i++) {

                            val = String.valueOf(PC_Constants.BenefitCategory.Administration);
                            coverageBenefitItem = getcoverageBenefitItem(val, request.secondaryHealthPlan.memberId +
                                    COLON+ String.valueOf(PC_Constants.BenefitCategory.Administration)+
                                    COLON + request.cptCodes[i]);
                            response.programCoverage.tertiaryCoverageBenefit.benefitItems.add(coverageBenefitItem);
                        }
                    }
                }
            }


            response.completionStatus = COMPLETE;
            List<String> successMessage = new List<String>();


            if(!String.isBlank( response.completionStatus)) {
                List<Object> formattingArguments =
                        new List<Object>{response.completionStatus};
                response.successMessages.add(String.format(Label.PC_MedicalBenefits_ProgramCoverage_CompletionStatus,
                                                                     formattingArguments));

                if(!response.completionStatus.equalsIgnoreCase(COMPLETE)) {

                    response.successMessages.add(Label.PC_MedicalBenefits_InfoMessage);
                }


                response.isSuccess = true;
            }


            return response;


        }catch (exception ex){
            system.debug('message '+ex.getMessage()+' line '+ex.getStackTraceString());
            PC_Utility.logAndThrowException(ex);
        }
        return null;
    }




    public PC_eBenefits.ProgramCoverageBenefitItem getcoverageBenefitItem(String benefitCategory, String cptCodeName) {

        PC_eBenefits.ProgramCoverageBenefitItem coverageBenefitItem = new PC_eBenefits.ProgramCoverageBenefitItem();

        coverageBenefitItem.coverageLevel ='Covered';
        coverageBenefitItem.benefitCategory =benefitCategory;
        coverageBenefitItem.deductableApplies =PC_Constants.YES_STRING;
        coverageBenefitItem.copayApplies =PC_Constants.NO_STRING;
        coverageBenefitItem.coinsuranceApplies =PC_Constants.YES_STRING;
        coverageBenefitItem.oopMaxApplies =PC_Constants.NO_STRING;
        coverageBenefitItem.pcpCopayAmount = 200.00;
        coverageBenefitItem.specialistCopayAmount =100.00;
        coverageBenefitItem.coinsurancePercent = 20.00;
        coverageBenefitItem.name =cptCodeName;


        return coverageBenefitItem;

    }



    public PC_eBenefits.ProgramCoverageBenefit getcoverageBenefit(String coverageLevel) {


        PC_eBenefits.ProgramCoverageBenefit coverageBenefit = new PC_eBenefits.ProgramCoverageBenefit();

        coverageBenefit.coverageLevel = coverageLevel;
        coverageBenefit.transactionId = '12120';
        coverageBenefit.transactionDate = Date.newInstance(2019, 4, 7);
        coverageBenefit.coverageStatus = PC_Constants.STATUS_ACTIVE;
        coverageBenefit.benefitNotes = 'benefitNotes';
        coverageBenefit.startDate = Date.newInstance(2018, 8, 16);
        coverageBenefit.endDate = null;
        coverageBenefit.payerName = 'Medicare';
        coverageBenefit.planName = PC_Constants.EMPTY_STRING;
        coverageBenefit.planType = 'Medicare Part B';
        coverageBenefit.groupNo = PC_Constants.EMPTY_STRING;
        coverageBenefit.groupName = PC_Constants.EMPTY_STRING;
        coverageBenefit.individualInNetworkDeductibleLimit = 0.0;
        coverageBenefit.individualInNetworkDeductibleRemaining = 0.0;
        coverageBenefit.individualInNetworkOutofPocketLimit = 0.0;
        coverageBenefit.individualInNetworkOutofPocketRemaining = 0.0;
        coverageBenefit.familyInNetworkOutofPocketLimit =0.0;
        coverageBenefit.familyInNetworkDeductibleLimit =0.0;
        coverageBenefit.familyInNetworkDeductibleRemaining = 0.0;
        coverageBenefit.familyInNetworkOutofPocketRemaining =0.0;

        coverageBenefit.paRequired = PC_Constants.NO_STRING;
        coverageBenefit.buyAndBill = PC_Constants.YES_STRING;
        coverageBenefit.specialtyPharmacyRequired = PC_Constants.NO_STRING;
        coverageBenefit.specialtyPharmacyInfo = PC_Constants.EMPTY_STRING;
        coverageBenefit.isGovernmentPlan = PC_Constants.YES_STRING;
        coverageBenefit.governmentPlanType = PC_Constants.EMPTY_STRING;
        coverageBenefit.transactionMessageID = PC_Constants.EMPTY_STRING;
        coverageBenefit.productAdminMessage = PC_Constants.EMPTY_STRING;
        coverageBenefit.billingMessage = PC_Constants.EMPTY_STRING;
        coverageBenefit.priorAuthMessage = PC_Constants.EMPTY_STRING;
        coverageBenefit.payerMessage = PC_Constants.EMPTY_STRING;


        return coverageBenefit;
    }

    public void updateCoverage(PC_eBenefits.MedicalBenefitsResponse response, PC_eBenefits.sCoverageDetail sCoverage) {
        PC_eBenefits_Utility.updateCoverageDetails(sCoverage, response);
    }


}