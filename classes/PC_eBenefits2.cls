/**************************************************************************************************************************************************************************
Class Name      : PC_eBenefits2
Description     : Provides interfaces, methods and classes necessary for eBi/Bv.
Created By      : Satheesh Kumar & Chetna Mohapatra
Created Date    : 01-Mar-2022
Modification Log:
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Developer                   Date                  Description
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Chetna Mohapatra
& Satheesh Kumar        01-Mar-2022             Initial Version
 **********************************************************************************************************************************************************************/
global inherited sharing class PC_eBenefits2 {
    /**PHARMACY BENEFITS INVESTIGATION**/
    /**
     * This interface should be implemented by all Pharmacy BI Service Classes to be process a Pharmacy BI request
     */
    global interface PharmacyBenefits {
        //Process the Pharmacy BI Request to get the coverage details
        List<PharmacyBenefitsResponse> lookupPharmacyBenefits(PharmacyBenefitsRequest pharmacyBenefitsRequest);
        //Update the Program Coverages with additional coverage details obtained from the vendor
        void updatePharmacyCoverages (List<sObject> coverageObjects, Object pbmTaskOutputs);
    }
    /**
    * Constitutes the Request for the Pharmacy BI
    */
    global inherited sharing class PharmacyBenefitsRequest {
        global String sourceRecordId;
        global PharmacyBenefitsRequest() {
            this.sourceRecordId = PC_Constants.EMPTY_STRING;
        }
    }

    /**
    * Defines the fields that constitute the response values as part of any Pharmacy BI process.
    */
    global inherited sharing class PharmacyBenefitsResponse {
        /**Boolean attribute to identify the response as success or failure**/
        global boolean isSuccess;
        /**Attribute to hold the Error message in case of request failure.**/
        global string errorMessage;
        /**Attribute to hold the Identifier value attained from the vendor**/
        global string externalId;
        /**Attribute to hold the Remote Service Log Id for the record that contains the request & response details.*/
        global string remoteServiceLogId;
        /**Attribute to hold the Salesforce Record Id that is related to the request*/
        global String relatedRecordId;
    }

    /**
   * Get the instance of pharmacy benefits class that implements PharmacyBenefits interface
   */
    global static PharmacyBenefits getPharmacyBenefitsService() {
        String handlerClass = getPharmacyBIClass();
        if (Test.isRunningTest()) {
            handlerClass='PC_PharmacyBI_Infinitus';
        }
        Type t = Type.forName(handlerClass);
        if (t != null) {
            Object o = t.newInstance();
            if (o instanceof PharmacyBenefits) {
                PharmacyBenefits handler = (PharmacyBenefits) o;
                return handler;
            } else {
                eBenefits2Exception ex = new eBenefits2Exception();
                ex.setMessage(System.Label.PC_Ebenefits_Handler_Class_Not_Found);
                throw ex;
            }
        } else {
            eBenefits2Exception ex = new eBenefits2Exception();
            ex.setMessage(System.Label.PC_Ebenefits_Handler_Class_Not_Found);
            throw ex;
        }
    }
    /**
    * Get the pharmacy benefits class name configured in the custom metadata.
    */
    private static string getPharmacyBIClass() {
        return PC_eBenefits_Utility.getHandlerClass(PC_Constants.PC_eBENEFITS_PHARMACY_BENEFITS_INVESTIGATION_SERVICE_TYPE);
    }

    /**MEDICAL BENEFITS INVESTIGATION**/
    /**
     * This interface should be implemented by all Medical BI Service Classes to be process a Medical BI request
     */
    global interface MedicalBenefits {
        //Process the Medical BI Request to get the coverage details
        List<MedicalBenefitsResponse> lookupMedicalBenefits(MedicalBenefitsRequest medicalBenefitsRequest);
        //Update the related Coverage object records with additional coverage details obtained from the vendor
        void updateMedicalCoverages (List<sObject> coverageObjects, Object medicalBIOutput);
    }
    /**
     * Constitutes the Request for the Pharmacy BI
     */
    global inherited sharing class MedicalBenefitsRequest {
        global String sourceRecordId;
        global MedicalBenefitsRequest() {
            this.sourceRecordId = PC_Constants.EMPTY_STRING;
        }
    }

    /**
   * Defines the fields that constitute the response values as part of any Medical BI process.
   */
    global inherited sharing class MedicalBenefitsResponse {
        /**Boolean attribute to identify the response as success or failure**/
        global boolean isSuccess;
        /**Attribute to hold the Error message in case of request failure.**/
        global string errorMessage;
        /**Attribute to hold the Identifier value attained from the vendor**/
        global string externalId;
        /**Attribute to hold the Remote Service Log Id for the record that contains the request & response details.*/
        global string remoteServiceLogId;
        /**Attribute to hold the Salesforce Record Id that is related to the request*/
        global String relatedRecordId;
    }

    /**
   * Get the instance of medical benefits class that implements MedicalBenefits interface
   */
    global static MedicalBenefits getMedicalBenefitsService() {
        String handlerClass = getMedicalBIClass();
        if (Test.isRunningTest()) {
            handlerClass='PC_MedicalBI_Infinitus';
        }
        Type t = Type.forName(handlerClass);
        if (t != null) {
            Object o = t.newInstance();
            if (o instanceof MedicalBenefits) {
                MedicalBenefits handler = (MedicalBenefits) o;
                return handler;
            } else {
                eBenefits2Exception ex = new eBenefits2Exception();
                ex.setMessage(System.Label.PC_Ebenefits_Handler_Class_Not_Found);
                throw ex;
            }
        } else {
            eBenefits2Exception ex = new eBenefits2Exception();
            ex.setMessage(System.Label.PC_Ebenefits_Handler_Class_Not_Found);
            throw ex;
        }
    }

    /**
    * Get the medical benefits class name configured in the custom meta data.
    */
    private static string getMedicalBIClass() {
        return PC_eBenefits_Utility.getHandlerClass(PC_Constants.PC_eBENEFITS_MEDICAL_BENEFITS_INVESTIGATION_SERVICE_TYPE);
    }
    /**
     * Set the RecordType and Coverage Type for each Coverage record created post successful Benefits Investigation
     * depending on the Health Plan RecordType and Public or Private field
     */
    public static void setCoverageRecordTypeAndType(PC_Health_Plan__c healthPlan, PC_Program_Coverage__c programCoverage){
        Id privateCoverageRecordTypeId = PC_System.recordTypeId(PC_Constants.PC_PROGRAM_COVERAGE, PC_Constants.PROGRAM_COVERAGE_PRIVATE_RECORD_TYPE);
        Id publicCoverageRecordTypeId = PC_System.recordTypeId(PC_Constants.PC_PROGRAM_COVERAGE, PC_Constants.PROGRAM_COVERAGE_PUBLIC_RECORD_TYPE);
        Id medicalCoverageRecordTypeId = PC_System.recordTypeId(PC_Constants.PC_PROGRAM_COVERAGE, PC_Constants.PROGRAM_COVERAGE_MEDICAL_RECORD_TYPE);
        Id pharmacyCoverageRecordTypeId = PC_System.recordTypeId(PC_Constants.PC_PROGRAM_COVERAGE, PC_Constants.PROGRAM_COVERAGE_PHARMACY_PLAN_RECORD_TYPE);
        String healthPlanRecordTypeDeveloperName = healthPlan.RecordType.DeveloperName;
        if(healthPlanRecordTypeDeveloperName!=null && String.isNotBlank(healthPlanRecordTypeDeveloperName)) {
            if (healthPlanRecordTypeDeveloperName == PC_Constants.HEALTH_PLAN_PRIVATE_RECORD_TYPE) {
                programCoverage.RecordTypeId = privateCoverageRecordTypeId;
                programCoverage.PC_Coverage_Type__c = PC_Constants.PRIVATE_COVERAGE_TYPE;
            } else if (healthPlanRecordTypeDeveloperName == PC_Constants.HEALTH_PLAN_PUBLIC_RECORD_TYPE) {
                programCoverage.RecordTypeId = publicCoverageRecordTypeId;
                programCoverage.PC_Coverage_Type__c = PC_Constants.PUBLIC_COVERAGE_TYPE;
            } else if (healthPlanRecordTypeDeveloperName == PC_Constants.HEALTH_PLAN_MEDICAL_RECORD_TYPE) {
                programCoverage.RecordTypeId = medicalCoverageRecordTypeId;
                if (healthPlan.PC_Public_Or_Private__c == PC_Constants.HEALTH_PLAN_TYPE_PUBLIC) {
                    programCoverage.PC_Coverage_Type__c = PC_Constants.PUBLIC_COVERAGE_TYPE;
                } else if (healthPlan.PC_Public_Or_Private__c == PC_Constants.HEALTH_PLAN_TYPE_PRIVATE) {
                    programCoverage.PC_Coverage_Type__c = PC_Constants.PRIVATE_COVERAGE_TYPE;
                }
            } else if (healthPlanRecordTypeDeveloperName == PC_Constants.HEALTH_PLAN_PHARMACY_PLAN_RECORD_TYPE) {
                programCoverage.RecordTypeId = pharmacyCoverageRecordTypeId;
                if (healthPlan.PC_Public_Or_Private__c == PC_Constants.HEALTH_PLAN_TYPE_PUBLIC) {
                    programCoverage.PC_Coverage_Type__c = PC_Constants.PUBLIC_COVERAGE_TYPE;
                } else if (healthPlan.PC_Public_Or_Private__c == PC_Constants.HEALTH_PLAN_TYPE_PRIVATE) {
                    programCoverage.PC_Coverage_Type__c = PC_Constants.PRIVATE_COVERAGE_TYPE;
                }
            }
        }
    }

    /**
    * A custom Exception class for eBenefits2`
    */
    global inherited sharing class eBenefits2Exception extends Exception {}
}