/***************************************************************************************************************
Class Name      : PC_BREMedicalBI_Example
Description     : This is an example class when initiating the Medical eBenefits via BRE.
Created By      : Chetna Mohapatra
Created Date    :  27-Apr-2022
Modification Log:
------------------------------------------------------------------------------------------------------------------
Developer                   Date                  Description
-------------------------------------------------------------------------------------------------------------------
Chetna Mohapatra         27-Apr-2022             Initial Version
Satheesh Kumar           12-Oct-2022             [PC-9262] Added condition to avoid removing namespace prefix from sObject when sobject contains no namespace.
*******************************************************************************************************************/
public with sharing class PC_BREMedicalBI_Example implements PC_eBenefits2.MedicalBenefits {
    public List<PC_eBenefits2.MedicalBenefitsResponse> lookupMedicalBenefits(PC_eBenefits2.MedicalBenefitsRequest medicalBenefitsRequest) {
        /**MedicalBenefitsRequest contains the sourceId(Trigger object Id) that can be used to create the Request Payload to be sent to the third-party vendor.*/
        List<PC_eBenefits2.MedicalBenefitsResponse> medicalBenefitsResponseList = new List<PC_eBenefits2.MedicalBenefitsResponse> ();

        /**Service callouts to third party vendors can be done as per the following example:-
        *String payload = JSON.serialize(request);//Create request and covert it into JSON format
        * String endpoint='www.example.com/endpointurl';//To access this external website, create a Remote Site Setting for the same.
        *HttpRequest request = new HttpRequest();//Initialize the external webservice callout request
        *request.setMethod(POST);//Using Http POST Method
        *request.setEndpoint(endpoint);
        *request.setBody(payload);
   
        //Response received
        *HttpResponse response = sendRequest(request);
        *Integer statusCode = response.getStatusCode();
        *String responseBody = response.getBody();
        *
        *Once the request is initiated, we can get the immediate API response for our request from the Third-party vendor and based on the success or failure of the request
        * use a logging mechanism such as our Remote Service Logs(PC_Remote_Service_Log__c) to log the request and response details.
        * We can also use our Record Identifier Object(PC_RecordIdentifier__c) to log the related Salesforce Ids that were a part of that request,
        * and later use those ids to update the related records based on the response.
        * */

        /**Create the MedicalBenefitsResponse using the Http Response received from the vendor :-
        PC_eBenefits2.MedicalBenefitsResponse eachMedicalBenefitsResponse = new PC_eBenefits2.MedicalBenefitsResponse();
          eachMedicalBenefitsResponse.isSuccess=true;
          eachMedicalBenefitsResponse.errorMessage=null;
          eachMedicalBenefitsResponse.relatedRecordId='';//Health Plan Id
          eachMedicalBenefitsResponse.remoteServiceLogId='';//Remote Service Log Id
          eachMedicalBenefitsResponse.externalId='';//Third-party vendor related Id/External Id
          */
        /**Calling this method to mock the process post successful vendor integration.*/
        processMedicalCoverage(MedicalBenefitsRequest);
        return MedicalBenefitsResponseList;
    }
    private void processMedicalCoverage(PC_eBenefits2.MedicalBenefitsRequest MedicalBenefitsRequest){
        String sourceRecordId= MedicalBenefitsRequest.sourceRecordId;
        Case programCase= new Case();
        Account patient= new Account();
        List<PC_CaseProduct__c> caseProducts= new List<PC_CaseProduct__c>();
        List<PC_Health_Plan__c> healthPlans= new List<PC_Health_Plan__c>();
        Id medicalHealthPlanRecord = PC_SYSTEM.recordTypeId(PC_Constants.PC_HEALTH_PLAN, PC_Constants.HEALTH_PLAN_MEDICAL_RECORD_TYPE);
        String objType = String.valueOf(Id.valueOf(sourceRecordId).getSobjectType());
        //remove namespace prefix from objType when objType contains namespace
        objType = objType.contains('__') ? (objType.countMatches('__') == 2 ? objType.substringAfter('__') : objType): objType;
        if(objType== PC_Constants.PC_CASE) {
            programCase = [SELECT Id, AccountId,PC_Care_Coordinator__c, OwnerId
                            FROM Case
                            WHERE Id = :sourceRecordId AND Type = :PC_Constants.CASE_PROGRAM_TYPE
                            WITH SECURITY_ENFORCED
                            LIMIT 1
            ];
            patient = [SELECT (SELECT Id, Name, PC_Plan_Name__c, PC_Payer_Name__c, Patient__c,Patient__r.Name,RecordType.DeveloperName,PC_Public_Or_Private__c
                            FROM Health_Plans__r
                            WHERE RecordTypeId = :medicalHealthPlanRecord
                            AND PC_Plan_Status__c = :PC_Constants.ACTIVE)
                    FROM Account
                    WHERE Id = :programCase.AccountId
                    WITH SECURITY_ENFORCED
            ];
            healthPlans = patient.Health_Plans__r;
            caseProducts = [SELECT Id, PC_Product__c, PC_Product__r.Name,PC_Product__r.ProductCode, PC_Product__r.PC_CPT_Codes__c
                    FROM PC_CaseProduct__c
                    WHERE PC_Case__c = :sourceRecordId
                    WITH SECURITY_ENFORCED
            ];
        }else if(objType== PC_Constants.PC_ACCOUNT){
            patient= [SELECT (SELECT Id FROM Account.Cases WHERE Type =: PC_Constants.CASE_PROGRAM_TYPE LIMIT 1)
                    FROM Account
                    WHERE Id=:sourceRecordId WITH SECURITY_ENFORCED
            ];
            programCase=[SELECT Id,PC_Care_Coordinator__c,OwnerId FROM Case WHERE Id
                    =: patient.Cases[0].Id];
            healthPlans=[ SELECT Id, Name, PC_Plan_Name__c, PC_Payer_Name__c, Patient__c,Patient__r.Name,RecordType.DeveloperName,PC_Public_Or_Private__c
                        FROM PC_Health_Plan__c
                        WHERE Patient__c=:patient.Id
                        AND RecordTypeId = :medicalHealthPlanRecord
                        AND PC_Plan_Status__c = :PC_Constants.ACTIVE
                        WITH SECURITY_ENFORCED
            ];
            caseProducts= [SELECT Id, PC_Product__c, PC_Product__r.Name,PC_Product__r.ProductCode, PC_Product__r.PC_CPT_Codes__c,PC_Case__c
                            FROM PC_CaseProduct__c
                            WHERE PC_Case__c = :programCase.Id
                            WITH SECURITY_ENFORCED
            ];

        }else if(objType==PC_Constants.PC_CASEPRODUCT) {
            caseProducts = [SELECT Id, PC_Product__c, PC_Product__r.Name,PC_Product__r.ProductCode, PC_Product__r.PC_CPT_Codes__c,PC_Case__c
                            FROM PC_CaseProduct__c
                            WHERE Id = :sourceRecordId
                            WITH SECURITY_ENFORCED
            ];
            programCase = [SELECT Id, AccountId,PC_Care_Coordinator__c, OwnerId FROM Case WHERE Id = :caseProducts[0].PC_Case__c WITH SECURITY_ENFORCED];
            healthPlans = [SELECT Id, Name, PC_Plan_Name__c, PC_Payer_Name__c, Patient__c,Patient__r.Name,RecordType.DeveloperName,PC_Public_Or_Private__c
                            FROM PC_Health_Plan__c
                            WHERE Patient__c = :programCase.AccountId
                            AND RecordTypeId = :medicalHealthPlanRecord
                            AND PC_Plan_Status__c = :PC_Constants.ACTIVE
                            WITH SECURITY_ENFORCED
            ];
        }
        /**Program Coverage Record & Task Creation*/
        List<sObject> coverageRelatedRecords= new List<sObject> ();
        for(PC_Health_Plan__c healthPlan :healthPlans) {
            System.debug('All Details--'+programCase+'--'+caseProducts+'--'+healthPlan);
            coverageRelatedRecords.addAll(createMedicalCoverageRecordsAndTasks(programCase,caseProducts, healthPlan));
        }
        if(coverageRelatedRecords!=null && !coverageRelatedRecords.isEmpty()){
            PC_Database.ins(coverageRelatedRecords,false);//Insertion of all the coverage records and tasks
            System.debug('Coverage Related Records--' +coverageRelatedRecords);
        }
        /**Calling the updateMedicalCoverages() with the list of coverageRelatedRecords and null value for PbmTaskOutput since we do not have that value.*/
        updateMedicalCoverages(coverageRelatedRecords,null);

    }
    private List<sObject> createMedicalCoverageRecordsAndTasks(Case programCase,List<PC_CaseProduct__c> caseProducts, PC_Health_Plan__c healthPlan){
        List<sObject> medicalCoverageRecordsAndTask= new List<sObject>();
        /**Coverage Record Creation- Program Coverage Records are created post successful BI/BV for the Patient's health plan.
        * Here in, only one Program Coverage record is created for all medical health plans associated with the Patient/Member
        * but for each product,a Coverage Benefit record and each Cpt code associated with the product, a Coverage Benefit Item record gets created*/
        //Program Coverage
        PC_Program_Coverage__c medicalCoverage= createProgramCoverage(healthPlan,programCase);
        //Member Plan
        MemberPlan memberPlan= new MemberPlan();
        memberPlan.MemberId= healthPlan.Patient__c;
        memberPlan.Name= PC_Constants.PC_MEMBER_PLAN_ABBREVIATION+healthPlan.Patient__r.Name;
        PC_Database.ins(memberPlan,false);
        /**Coverage Benefit Record is created for each Product*/
        for (PC_CaseProduct__c caseProduct  : caseProducts) {
            if (medicalCoverage != null && memberPlan != null) {
                CoverageBenefit coverageBenefit = new CoverageBenefit();
                coverageBenefit.PC_ProgramCoverage__c = medicalCoverage.Id;
                coverageBenefit.Name = healthPlan.PC_Payer_Name__c + ' : ' + caseProduct.PC_Product__r.ProductCode;
                coverageBenefit.MemberPlanId = memberPlan.Id;
                PC_Database.ins(coverageBenefit,false);
               /**Coverage Benefit Item records are created for all the cpt codes associated with each product*/
                if(caseProduct.PC_Product__r.PC_CPT_Codes__c !=null) {
                    List<String> cptStrings = caseProduct.PC_Product__r.PC_CPT_Codes__c .split(';');
                    for(String cpt:cptStrings){
                        CoverageBenefitItem coverageBenefitItem = new CoverageBenefitItem();
                        coverageBenefitItem.CoverageBenefitId = coverageBenefit.Id;
                        coverageBenefitItem.Name = coverageBenefit.Name+' : ' +cpt;
                        medicalCoverageRecordsAndTask.add(coverageBenefitItem);
                    }
                }
            }
        }
        /**Final Status Related Task(Successful BI/BV)- The task related to the status of the BI/BV process reflects
        * on the activity timeline of the Patient's associated Program Case */
        Task task= new Task();
        if(programCase.PC_Care_Coordinator__c !=null){
            task.OwnerId= programCase.PC_Care_Coordinator__c;
        }else if(programCase.PC_Care_Coordinator__c == null && programCase.OwnerId !=null){
            task.OwnerId= programCase.OwnerId;
        }
        task.WhatId= programCase.Id;
        task.Subject= System.Label.PC_MedicalBICompletionMessage;
        task.Status=PC_Constants.PC_TASK_STATUS_COMPLETED;
        task.PC_Direction__c= PC_Constants.INBOUND;
        task.PC_Channel__c = PC_Constants.PC_TASK;
        task.Priority = PC_Constants.PC_PRIORITY_NORMAL;
        task.ActivityDate = System.today();
        medicalCoverageRecordsAndTask.add(task);
        return  medicalCoverageRecordsAndTask;
    }
    private PC_Program_Coverage__c createProgramCoverage(PC_Health_Plan__c healthPlan,Case programCase){
        PC_Program_Coverage__c medicalCoverage= new PC_Program_Coverage__c();
        medicalCoverage.PC_Health_Plan__c=healthPlan.Id;
        medicalCoverage.PC_Program__c=programCase.Id;
        medicalCoverage.PC_Coverage_Status__c = PC_Constants.ACTIVE;
        //Method for Program Coverage RecordType & Coverage Type selection
        PC_eBenefits2.setCoverageRecordTypeAndType(healthPlan,medicalCoverage);
        PC_Database.ins(medicalCoverage,false);
        return medicalCoverage;
    }
    /**Update the Program coverage records with additional coverage details obtained from the vendor as part of bvTaskOutput*/
    public static void updateMedicalCoverages(List<sObject> coverageObjects, Object bvTaskOutput){
        System.debug('Coverage Related Objects--'+coverageObjects);
    }
}