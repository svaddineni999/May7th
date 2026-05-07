/**
 * Created by peharitha on 4/2/2019.
 *//*********************************************************************************
Class Name      :   PC_MedicalBenefitsListController
Description        : Controller for PC_MedicalBenefitsList Component
Created By        : Haritha Reddy
Created Date     : 02-04-2019
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------
Haritha Reddy          02-04-2019              Initial Version
Haritha Reddy          16-Dec-2019             [PC-5791] Removed @AuraEnabled annotation for getFieldLabels Method
                                                as it is not being called from Lightning component
Haritha Reddy           21-Jan-2021             [PC-7102] Added FLS Check
Haritha Reddy           21-Jan-2021           [PC-7102] Force Reviewer scan issue fix. Updated Sharing declaration.
*********************************************************************************/

public with sharing class PC_MedicalBenefitsListController {
    public inherited sharing class InitData {
        @AuraEnabled public List<ListWrapper> programCoverageList;
        @AuraEnabled public FieldLabels fieldLabels ;

        public InitData() {
            programCoverageList = new List<ListWrapper>();
            fieldLabels  = new FieldLabels();
        }
    }
    /*********************************************************
    Method Name             : getRelProgramCoverages
    Description             : fetch Program Coverage Records related to the Program Case
    Input Params            : List<Id> CaseId
    Return Type             : InitData Wrapper
    *********************************************************************************/
    @AuraEnabled
    public static InitData getRelProgramCoverages(List<Id> caseId){

        InitData initData = new InitData();
        try{
            LIST<ListWrapper> listInfo 	= new LIST <ListWrapper>();
            LIST<PC_Program_Coverage__c> relProgramCoverageList = new LIST <PC_Program_Coverage__c>();
            LIST<CoverageBenefitItem> coverageBenefitItemList = new LIST <CoverageBenefitItem>();
            //Check FLS
            List<String> PCFields = new List<String>{PC_Constants.getQualifiedAPIName('PC_Program__c'),
                    PC_Constants.getQualifiedAPIName('PC_Expiration_Date__c'),
                    PC_Constants.getQualifiedAPIName('PA_Required__c')};
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Program_Coverage__c'),PC_Database.Operation.Reading, PCFields);

            List<String> coverageBenefitfields = new List<String>{
                    PC_Constants.getQualifiedAPIName('PC_CoverageLevel__c'),
                    PC_Constants.getQualifiedAPIName('PC_CoverageStatus__c')};
            PC_Database.assertAccess(PC_Constants.PC_CoverageBenefit,PC_Database.Operation.Reading, coverageBenefitfields);

            List<String> coverageBenefitItemfields = new List<String>{'CoverageLevel','BenefitCategory','CoverageBenefitId'};
            PC_Database.assertAccess(PC_Constants.PC_CoverageBenefitItem,PC_Database.Operation.Reading, coverageBenefitItemfields);

            Id medicalCoverageRecordTypeId = PC_System.recordTypeId(PC_Constants.PC_PROGRAM_COVERAGE, PC_Constants.PROGRAM_COVERAGE_MEDICAL_RECORD_TYPE);

            relProgramCoverageList = [SELECT Id, Name, PC_Expiration_Date__c,PA_Required__c,
                (SELECT Id,PC_CoverageLevel__c,PC_CoverageStatus__c
                FROM PC_Coverage_Benefits__r WHERE PC_CoverageLevel__c =: PC_Constants.HEALTH_PLAN_TYPE_PRIMARY Limit 1)
            FROM PC_Program_Coverage__c WHERE  PC_Program__c in :caseId AND recordTypeId =: medicalCoverageRecordTypeId ORDER BY CreatedDate DESC];

            string coverageStatus,productStatus;

            coverageBenefitItemList = [SELECT Id,CoverageLevel,BenefitCategory,CoverageBenefitId FROM CoverageBenefitItem
            WHERE BenefitCategory =: PC_Constants.PC_BENEFITCATEGORY_PRODUCT];

            for(PC_Program_Coverage__c programCoverage : relProgramCoverageList){
                if(!programCoverage.PC_Coverage_Benefits__r.isEmpty()){
                    coverageStatus = programCoverage.PC_Coverage_Benefits__r[0].PC_CoverageStatus__c;

                    for(CoverageBenefitItem cbi : coverageBenefitItemList){
                        if(cbi.CoverageBenefitId == programCoverage.PC_Coverage_Benefits__r[0].Id){
                            productStatus = cbi.CoverageLevel;
                        }
                    }
                }
                listInfo.add(new ListWrapper(programCoverage,coverageStatus,productStatus));
            }


            initData.programCoverageList = listInfo;
            initData.fieldLabels = getFieldLabels();

        }catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return initData;
    }

    /*********************************************************
    Method Name             : getFieldLabels
    Description             : fetch Field Labels from Database
    Input Params            : NA
    Return Type             : FieldLabels Wrapper
    *********************************************************************************/
    public static FieldLabels getFieldLabels(){
        FieldLabels fieldlabels = new FieldLabels();
        fieldlabels.coverageNumber = PC_Program_Coverage__c.Name.getDescribe().getLabel();
        fieldlabels.primaryCoverageStatus = System.Label.PC_MedicalBenefits_PrimaryCoverageStatus;
        fieldlabels.primaryProductStatus = System.Label.PC_MedicalBenefits_PrimaryProductStatus;
        fieldlabels.expirationDate = PC_Program_Coverage__c.PC_Expiration_Date__c.getDescribe().getLabel();
        fieldlabels.PARequired = PC_Program_Coverage__c.PA_Required__c.getDescribe().getLabel();

        return fieldlabels;
    }
    public inherited sharing class FieldLabels{
        @AuraEnabled public String coverageNumber { get; set; }
        @AuraEnabled public String primaryCoverageStatus { get; set; }
        @AuraEnabled public String primaryProductStatus { get; set; }
        @AuraEnabled public String expirationDate { get; set; }
        @AuraEnabled public String PARequired { get; set; }

        public FieldLabels() {
        }
    }
    /*********************************************************
    Method Name             : ListWrapper
    Description             : fetches values for each field in the table
    Input Params            : NA
    Return Type             : NA
    *********************************************************************************/
    public inherited sharing class ListWrapper{
        @AuraEnabled public String programCoverageId { get; set; }
        @AuraEnabled public String programCoverageNumber { get; set; }
        @AuraEnabled public String primaryCoverageStatus { get; set; }
        @AuraEnabled public String primaryProductStatus { get; set; }
        @AuraEnabled public Date expirationDate { get; set; }
        @AuraEnabled public String PARequired { get; set; }

        public ListWrapper(PC_Program_Coverage__c programCoverage, String coverageStatus, String productStatus) {
            programCoverageId = programCoverage.Id;
            programCoverageNumber = programCoverage.Name;
            primaryCoverageStatus = coverageStatus;
            primaryProductStatus = productStatus;
            expirationDate = programCoverage.PC_Expiration_Date__c;
            PARequired = programCoverage.PA_Required__c;
        }
    }
}