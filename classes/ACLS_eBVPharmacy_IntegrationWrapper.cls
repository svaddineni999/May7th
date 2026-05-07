/*********************************************************************************
 Class Name     : ACLS_eBVPharmacy_IntegrationWrapper
Description     : Stores all the request wrappers and response wrappers needed to perform the eBV API
Created By      : Ronak Bansal
Created Date    : April 5, 2023
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------
Ronak Bansal            April 5, 2023              Initial Version
*********************************************************************************/
public with sharing class ACLS_eBVPharmacy_IntegrationWrapper {

    /*********************************************************************************
    Class Name     : eBV_RequestWrapper
    Description    : Prepares the request wrapper
    *********************************************************************************/
    public class eBV_RequestWrapper{
        public PatientInfo patientInfo;
        public HealthPlanInfo patientPlanInfo;
        public DrugInfo drugInfo;
        public ProviderInfo providerInfo;

        public eBV_RequestWrapper(PatientInfo patientInfo, HealthPlanInfo patientPlanInfo, DrugInfo drugInfo, ProviderInfo providerInfo){
            this.patientInfo = patientInfo;
            this.patientPlanInfo = patientPlanInfo;
            this.drugInfo = drugInfo;
            this.providerInfo = providerInfo;
        }
    }

    /*********************************************************************************
    Class Name     : eBV_ResponseWrapper
    Description    : Used to deserialize the response JSON into wrappers
    *********************************************************************************/
    public class eBV_ResponseWrapper{
        public String transId;
        public DrugInfo drugInfo;
        public List<CoveragePreferredResult> coveragePreferredResult;

        public eBV_ResponseWrapper(String transId, DrugInfo drugInfo, List<CoveragePreferredResult> coveragePreferredResult){
            this.transId = transId;
            this.drugInfo = drugInfo;
            this.coveragePreferredResult = coveragePreferredResult;
        }
    }
    
    /*********************************************************************************
    Class Name     : PatientInfo
    Description    : Prepares the wrapper data for the selected patient
    *********************************************************************************/
    public class PatientInfo {
		public String patientId;
		public String firstName;
		public String lastName;
		public String dateOfBirth;
		public String gender;
		public String zipcode;
		public String relationshipCode;

        public PatientInfo(String patientId, String firstName, String lastName, String dateOfBirth, String gender, String zipcode, String relationshipCode){
            this.patientId = patientId;
            this.firstName = firstName;
            this.lastName = lastName;
            this.dateOfBirth = dateOfBirth;
            this.gender = gender;
            this.zipcode = zipcode;
            this.relationshipCode = relationshipCode;
        }   
	}

    /*********************************************************************************
    Class Name     : HealthPlanInfo
    Description    : Prepares the wrapper data for the selected health plan
    *********************************************************************************/
    public class HealthPlanInfo {
		public String BIN;
		public String PCN;
		public String GroupNo; //'Group' is a reserved keyword
		public String MemberId;
		public String PersonCode;

        public HealthPlanInfo(String BIN, String PCN, String GroupNo, String MemberId, String PersonCode){
            this.BIN = BIN;
            this.PCN = PCN;
            this.GroupNo = GroupNo;
            this.MemberId = MemberId;
            this.PersonCode = PersonCode;
        }
	}

    /*********************************************************************************
    Class Name     : DrugInfo
    Description    : Prepares the wrapper data for the selected product
    *********************************************************************************/
	public class DrugInfo {
		public String ndc;
		public Double qtDispense;
        public String unitOfMeasurement;
		public Double qtPrescribed;
		public Integer daySupply;

        public DrugInfo(String ndc, Double qtDispense, Double qtPrescribed, Integer daySupply){
            this.ndc =  ndc;
            this.qtDispense = qtDispense;
            this.qtPrescribed = qtPrescribed;
            this.daySupply = daySupply;
        }
	}

    /*********************************************************************************
    Class Name     : SMS_SendSMS_Response
    Description    : Prepares the wrapper data for the selected physician
    *********************************************************************************/
	public class ProviderInfo {
		public String providernpi;

        public ProviderInfo(String providernpi){
            this.providernpi = providernpi;
        }
	}

    /*********************************************************************************
    Class Name     : CoveragePreferredResult
    Description    : Used to deserialize the coverage results from the response JSON into wrappers
    *********************************************************************************/
    public class CoveragePreferredResult {
		public String scenarioId;
		public PlanInfo planInfo;
		public MedicarePlanInfo MedicarePlanInfo;
		public Boolean CoB;
		public String planOrder;
		public String planType;
		public String coverageStatus;
		public String claimStatus;
		public String patientPayAmount;
		public AccumulatorAccrual accumulatorAccrual;
		public String rejectDesc;
		public List<String> SPPName;
		public Boolean hasMandatoryContractedSP;
		public Boolean isProductOnFormulary;
		public Integer productFormularyTier;
		public Boolean isPARequired;
        
        public CoveragePreferredResult(){}        
	}

    /*********************************************************************************
    Class Name     : AccumulatorAccrual
    Description    : Used to deserialize the accumulated accrural results from the response JSON into wrappers
    *********************************************************************************/
    public class AccumulatorAccrual {
		public String accumulatedDeductibleAmount;
		public String remainingDeductibleAmount;
		public String amountAppliedToPeriodicDeductible;
		public Boolean deductibleMet;
		public Boolean isDeductibleAppliedToOOP;
		public Boolean OOPMet;
		public String OOPMax;
		public String OOPRemaining;
		public String coInsurancePercent;
		public String annualCap;
        
        public AccumulatorAccrual(){}
	}

    /*********************************************************************************
    Class Name     : PlanInfo
    Description    : Used to deserialize the Health Plan results from the response JSON into wrappers
    *********************************************************************************/
    public class PlanInfo {
		public String PBMName;
		public String PlanName; 
		public String BIN;
		public String PCN;
		//public String Group
		public String MemberId;
		public String PBMPhone;
		public String PersonCode; 
		public String StartDate;
		public String EndDate;
		public Boolean IsCalendarYearPlan;
		public String PAPhone;
		public String PAFax;
        
        public PlanInfo(){}
	}

    /*********************************************************************************
    Class Name     : MedicarePlanInfo
    Description    : Used to deserialize the Medicare Plan results from the response JSON into wrappers
    *********************************************************************************/
    public class MedicarePlanInfo {
		public Boolean IsLowIncomeSubsidyEnrolled;
		public List<String> Stage;
		public Object IsCoverageGap;
		public List<String> Amount;
        
        public MedicarePlanInfo(){}
	}
}