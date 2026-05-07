/*********************************************************************************
Class Name      : PC_Trigger_HealthPlan_ProgramCoverage
Description        : <Purpose of the class and do’s and don’t’s, if any. Components using this class >
Created By        : mapatil
Created Date     : 8/15/2017
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------           
mapatil                   8/15/2017                [PC-1898] Initial Version
Mayuresh Patil            8/18/2017                [PC-2126] program coverage update to insert only active coverages
Shabda Bhujad             Nov 14, 2017             PC-2485 Removing the reference to trigger state
Mayuresh Patil            Aug 20, 2018             PC-3241 Adding access to medical health plan recordtype
Xiukai Ning               Feb 28, 2019             PC-3775 - Code review. FLS is NOT needed in Triggers, as they always run in System Mode.
                                                   Trigger delegate class (handler) that has with Sharing keyword however, will apply user sharing.
                                                   We are removing all FLS and With Sharing keywords in the handlers.
Hitha Avalakki            Mar 19, 2021             [PC-7533] Replaced constant CASE_PROGRAM_RECORD_TYPE_NAME to CASE_PROGRAM_TYPE
Vijay Kashikar            Jun 09, 2021             [PC-7821] Moved out the query within for loop
Vijay Kashikar            Jun 24, 2021             [PC-7841] Create a program coverage only when the corresponding health plan is created using PC record types.
Vijay Kashikar            Jun 24, 2021             [PC-7851] Create a Coverage of type Pharmacy Plan when a Health Plan of type Pharmacy Plan is created
Satheesh Kumar            Nov 16, 2021             [PC-8213] Excluded FLS Check and added inherited sharing
Vijay Kashikar            Apr 27, 2022             [PC-8676] New program coverages will be created only on the associated OPEN cases only
*********************************************************************************/

public inherited sharing class PC_Trigger_HealthPlan_ProgramCoverage extends PC_TriggerHandler {

    override public void afterInsert(){
        createProgramCoverage((List<PC_Health_Plan__c>) newList);
    }

    override public void afterUpdate(){
        updateProgramCoverage((List<PC_Health_Plan__c>) newList, (Map<Id, PC_Health_Plan__c>)oldMap);
    }

    /*********************************************************************************
    Method Name    : createProgramCoverage
    Author         : mapatil
    Description    : This method  creates program coverage for each healthplan that have a program case created.
    Return Type    : void
    Parameter      : List of incoming account records - Trigger.new
    *********************************************************************************/
    private void createProgramCoverage(List<PC_Health_Plan__c> newHealthPlans) {
        Set<Id> patientIds = new Set<Id>();
        List<PC_Program_Coverage__c> programCoveragesToCreate = new List<PC_Program_Coverage__c>();
        Date todaysDate = Date.today();
        //List of Patient Ids
        for (PC_Health_Plan__c healthPlan : newHealthPlans) {
            patientIds.add(healthPlan.Patient__c);
        }
        String programCaseType =  PC_Constants.CASE_PROGRAM_TYPE;
        String programCaseRecordType = PC_Constants.CASE_PROGRAM_RECORD_TYPE;

        List<Case> lstProgramCases = [SELECT ID, AccountId
                                      FROM Case
                                      WHERE AccountId in : patientIds AND IsClosed = false
                                        AND (Type = : programCaseType
                                         OR RecordType.DeveloperName = : programCaseRecordType)];
        Id privateCoverageRecordTypeId = PC_System.recordTypeId(PC_Constants.PC_PROGRAM_COVERAGE, PC_Constants.PROGRAM_COVERAGE_PRIVATE_RECORD_TYPE);
        Id publicCoverageRecordTypeId = PC_System.recordTypeId(PC_Constants.PC_PROGRAM_COVERAGE, PC_Constants.PROGRAM_COVERAGE_PUBLIC_RECORD_TYPE);
        Id medicalCoverageRecordTypeId = PC_System.recordTypeId(PC_Constants.PC_PROGRAM_COVERAGE, PC_Constants.PROGRAM_COVERAGE_MEDICAL_RECORD_TYPE);
        Id pharmacyCoverageRecordTypeId = PC_System.recordTypeId(PC_Constants.PC_PROGRAM_COVERAGE, PC_Constants.PROGRAM_COVERAGE_PHARMACY_PLAN_RECORD_TYPE);

        Map<Id, RecordType> healthPlanRecordTypes = new Map<ID, RecordType>(
        [SELECT Id, DeveloperName, NamespacePrefix FROM RecordType WHERE SobjectType = :PC_Constants.PC_HEALTH_PLAN]);

        Boolean createNewProgramCoverage;
        for (Case eachCase : lstProgramCases) {
            for(PC_Health_Plan__c eachHealthPlan : newHealthPlans) {
                if (eachCase.AccountId == eachHealthPlan.Patient__c) {
                    //String healthPlanRecordTypeDeveloperName = PC_System.recordTypeDeveloperNameById(PC_Constants.PC_HEALTH_PLAN, eachHealthPlan.RecordTypeId);
                    String healthPlanRecordTypeDeveloperName = healthPlanRecordTypes.get(eachHealthPlan.RecordTypeId).DeveloperName;
                        if (eachHealthPlan.PC_Plan_Status__c == PC_Constants.ACTIVE
                        || (eachHealthPlan.PC_Effective_Date__c != null && eachHealthPlan.PC_Expiration_Date__c != null && eachHealthPlan.PC_Expiration_Date__c > todaysDate && eachHealthPlan.PC_Effective_Date__c <= todaysDate)
                        || (eachHealthPlan.PC_Effective_Date__c != null && eachHealthPlan.PC_Expiration_Date__c == null && eachHealthPlan.PC_Effective_Date__c <= todaysDate)){
                                    PC_Program_Coverage__c pc = new PC_Program_Coverage__c(
                                        PC_Program__c = eachCase.Id,
                                        PC_Coverage_Status__c = PC_Constants.ACTIVE,
                                        PC_Health_Plan__c = eachHealthPlan.Id,
                                        PC_Expiration_Date__c = eachHealthPlan.PC_Expiration_Date__c
                                    );
                            createNewProgramCoverage = true;
                            if (healthPlanRecordTypeDeveloperName == PC_Constants.HEALTH_PLAN_PRIVATE_RECORD_TYPE) {
                                pc.RecordTypeId = privateCoverageRecordTypeId;
                                pc.PC_Coverage_Type__c = PC_Constants.PRIVATE_COVERAGE_TYPE;
                            } else if (healthPlanRecordTypeDeveloperName == PC_Constants.HEALTH_PLAN_PUBLIC_RECORD_TYPE) {
                                pc.RecordTypeId = publicCoverageRecordTypeId;
                                pc.PC_Coverage_Type__c = PC_Constants.PUBLIC_COVERAGE_TYPE;
                            } else if (healthPlanRecordTypeDeveloperName == PC_Constants.HEALTH_PLAN_MEDICAL_RECORD_TYPE) {
                                pc.RecordTypeId = medicalCoverageRecordTypeId;
                                if (eachHealthPlan.PC_Public_Or_Private__c == PC_Constants.HEALTH_PLAN_TYPE_PUBLIC) {
                                    pc.PC_Coverage_Type__c = PC_Constants.PUBLIC_COVERAGE_TYPE;
                                } else if (eachHealthPlan.PC_Public_Or_Private__c == PC_Constants.HEALTH_PLAN_TYPE_PRIVATE) {
                                    pc.PC_Coverage_Type__c = PC_Constants.PRIVATE_COVERAGE_TYPE;
                                }
                            } else if (healthPlanRecordTypeDeveloperName == PC_Constants.HEALTH_PLAN_PHARMACY_PLAN_RECORD_TYPE) {
                                pc.RecordTypeId = pharmacyCoverageRecordTypeId;
                                if (eachHealthPlan.PC_Public_Or_Private__c == PC_Constants.HEALTH_PLAN_TYPE_PUBLIC) {
                                    pc.PC_Coverage_Type__c = PC_Constants.PUBLIC_COVERAGE_TYPE;
                                } else if (eachHealthPlan.PC_Public_Or_Private__c == PC_Constants.HEALTH_PLAN_TYPE_PRIVATE) {
                                    pc.PC_Coverage_Type__c = PC_Constants.PRIVATE_COVERAGE_TYPE;
                                }
                            }
                            else {
                                createNewProgramCoverage = false;
                            }
                            if(createNewProgramCoverage) {
                                programCoveragesToCreate.add(pc);
                            }
                        }
                    }
                }
            }
        if (programCoveragesToCreate != null && !programCoveragesToCreate.isEmpty()) {
            PC_Database.ins(programCoveragesToCreate, false);//CRUD/FLS enforced in the database ins method
        }
    }


    /*********************************************************************************
    Method Name    : updateProgramCoverage
    Author         : mapatil
    Description    : This method  creates program coverage for each healthplan that have a program case created.
    Return Type    : void
    Parameter      : List of incoming account records - Trigger.new
    *********************************************************************************/
    private void updateProgramCoverage(List<PC_Health_Plan__c> newHealthPlans, Map<Id, PC_Health_Plan__c> oldHealthPlans) {
        Set<Id> healthPlanIds = new Set<Id>();
        List<PC_Program_Coverage__c> programCoveragesToUpdate = new List<PC_Program_Coverage__c>();
        Date todaysDate = Date.today();

        //List of Patient Ids
        for (PC_Health_Plan__c healthPlan : newHealthPlans) {
            healthPlanIds.add(healthPlan.Id);
        }
        List<PC_Program_Coverage__c> lstProgramCoverages = [SELECT Id, PC_Expiration_Date__c, PC_Coverage_Status__c, PC_Health_Plan__c
                                                            FROM PC_Program_Coverage__c
                                                            WHERE PC_Health_Plan__c in : healthPlanIds];

        if (lstProgramCoverages != null && !lstProgramCoverages.isEmpty()) {
            for (PC_Program_Coverage__c eachProgramCoverage : lstProgramCoverages) {
                for (PC_Health_Plan__c eachHealthPlan : newHealthPlans) {
                    if ((eachProgramCoverage.PC_Health_Plan__c == eachHealthPlan.Id) && ((oldHealthPlans.get(eachHealthPlan.Id).PC_Expiration_Date__c != eachHealthPlan.PC_Expiration_Date__c) || (oldHealthPlans.get(eachHealthPlan.Id).PC_Plan_Status__c != eachHealthPlan.PC_Plan_Status__c))) {
                        if ((eachHealthPlan.PC_Expiration_Date__c != null && eachHealthPlan.PC_Expiration_Date__c <= todaysDate) || (eachHealthPlan.PC_Plan_Status__c == PC_Constants.INACTIVE)) {
                            programCoveragesToUpdate.add(
                                    new PC_Program_Coverage__c(
                                            Id = eachProgramCoverage.Id,
                                            PC_Coverage_Status__c = PC_Constants.INACTIVE,
                                            PC_Expiration_Date__c = eachHealthPlan.PC_Expiration_Date__c
                                    )
                            );
                        } else {
                            programCoveragesToUpdate.add(
                                    new PC_Program_Coverage__c(
                                            Id = eachProgramCoverage.Id,
                                            PC_Coverage_Status__c = PC_Constants.ACTIVE,
                                            PC_Expiration_Date__c = null
                                    )
                            );
                        }
                    }
                }
            }
        }
        if (programCoveragesToUpdate != null && !programCoveragesToUpdate.isEmpty()) {
            PC_Database.upd(programCoveragesToUpdate, false);//CRUD/FLS enforced in the database upd method
        }
    }
}