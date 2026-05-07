/**************************************************************************************************************************************************************************
Class Name      : PC_MedicalBI_Infinitus
Description     : This is the Infinitus Service Class For Medical BI.
Created By      : Chetna Mohapatra
Created Date    : 28-Mar-2022
Modification Log:
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Developer                   Date                  Description
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Chetna Mohapatra         28-Mar-2022             Initial Version
 **********************************************************************************************************************************************************************/
    public with sharing class PC_MedicalBI_Infinitus extends PC_Infinitus implements PC_eBenefits2.MedicalBenefits {

        public override void init() {
            endpoint = PC_SYSTEM.getIntegrationSetting('PC_InfinitusEndpointURL', '');//Setting the endpoint URL.
            method = HttpMethod.XPOST;
            apiKey=PC_SYSTEM.getIntegrationSetting('PC_InfinitusAPIKey', ''); //Setting the API Key
            //For getting custom metadata values when Test class is running.
            if (Test.isRunningTest()) {
                endpoint= 'https://api.infinitusai.com/v1/tasks';
                apiKey = 'prodKey.c0e413cc-7492-47ce-a37e-fa63293e1d77.2.4AjmS9GFYe6VFzTJhRNEQCKNE6ZA7ePTzRR3drkGLdVnDRSmGqHVlEFUoAcVzh028VNJGlh5l_uGqORsZl64yQ';
            }
            if (String.isBlank(endpoint)) {
                PC_eBenefits2.eBenefits2Exception ex = new PC_eBenefits2.eBenefits2Exception();
                ex.setMessage(System.Label.PC_InfinitusEndpointURL_Missing);
                throw ex;
            }
            if (String.isBlank(apiKey)) {
                PC_eBenefits2.eBenefits2Exception ex = new PC_eBenefits2.eBenefits2Exception();
                ex.setMessage(System.Label.PC_InfintusAPIKey_Missing);
                throw ex;
            } else {
                setHeader('X-INF-API-KEY', apiKey);//Setting the Request header with a valid api key
            }
        }

        public List<PC_eBenefits2.MedicalBenefitsResponse> lookupMedicalBenefits(PC_eBenefits2.MedicalBenefitsRequest medicalBenefitsRequest) {
            List<PC_eBenefits2.MedicalBenefitsResponse> medicalBenefitsResponse = new List<PC_eBenefits2.MedicalBenefitsResponse> ();
            TasksRequest tasksRequest = getRequestForMedicalBenefit(medicalBenefitsRequest.sourceRecordId, PC_Infinitus.BITaskType.INF_TASK_TYPE_BENEFITS_VERIFICATION);
            System.debug('Medical TasksRequest--' + tasksRequest);

            // Create Request
            payload = JSON.serialize(tasksRequest);
            HttpRequest request = generateHttpRequest();
            String requestBody = request.getBody();
            String requestEndpoint = request.getEndpoint();
            system.debug('Medical request body----' + requestBody);

            //Response received
            HttpResponse response = sendRequest(request);
            Integer statusCode = response.getStatusCode();
            String responseBody = response.getBody();
            system.debug('Medical response details----' + responseBody + '---' + statusCode);

            //Create Remote Service Log for each TaskRequest
            String infinitusServiceName = PC_Constants.INFINITUS;
            String serviceType = PC_Constants.REMOTE_SERVICE_TYPE_OUTBOUND;
            PC_Remote_Service_Log__c remoteServiceLog = new PC_Remote_Service_Log__c();
            remoteServiceLog = PC_RemoteServiceLogHandler.getRemoteServiceLog(infinitusServiceName, requestEndpoint, requestBody, responseBody, '', serviceType);
            PC_Database.ins(remoteServiceLog);

            //Processing the response received from Infinitus
            medicalBenefitsResponse = processMedicalBIResponse(response, statusCode, remoteServiceLog);
            return medicalBenefitsResponse;
        }

        public List<PC_eBenefits2.MedicalBenefitsResponse> processMedicalBIResponse(HttpResponse response, Integer statusCode, PC_Remote_Service_Log__c remoteServiceLog) {
            //Parse the response
            String responseBody = response.getBody();
            PC_Infinitus.InfinitusBIResponse res = PC_Infinitus.parseInfinitusBIResponse(responseBody);
            system.debug('Infinitus Med response----' + res);
            Map<String, String> relatedRecordIdMap = new Map<String, String>();
            List<PC_eBenefits2.MedicalBenefitsResponse> medicalBenefitsResponses = new List<PC_eBenefits2.MedicalBenefitsResponse>();
            if (res.message == null && res.data != null) {
                for (Data data : res.Data) {
                    PC_eBenefits2.MedicalBenefitsResponse eachResponse = new PC_eBenefits2.MedicalBenefitsResponse();
                    if (data.error == null && statusCode != null && statusCode == 200) {
                        eachResponse.isSuccess = PC_Constants.TRUE_BOOLEAN;
                        eachResponse.externalId = data.taskId;
                        eachResponse.remoteServiceLogId = remoteServiceLog.Id;
                        eachResponse.relatedRecordId = data.customerId;
                        medicalBenefitsResponses.add(eachResponse);

                    } else if (data.error != null && statusCode != null && statusCode == 200) {
                        eachResponse.isSuccess = PC_Constants.FALSE_BOOLEAN;
                        eachResponse.errorMessage = data.error.errorMessage;
                        eachResponse.remoteServiceLogId = remoteServiceLog.Id;
                        eachResponse.relatedRecordId = data.customerId;
                        medicalBenefitsResponses.add(eachResponse);
                    }
                }
            } else {
                //For failure in request
                PC_eBenefits2.eBenefits2Exception ex = new PC_eBenefits2.eBenefits2Exception();
                ex.setMessage(PC_Constants.ERROR + '- ' + res.message);
                throw ex;
            }
            return medicalBenefitsResponses;
        }

        public static void createProgramCoverageAndUpdateActivity(List<Data> bvCallbackData){
            Map<String,BvTaskOutput> taskIdAndBvTaskOutputMap= new Map<String,BvTaskOutput>();
            for(Data eachData:bvCallbackData){
                if(eachData.taskStatus== 'INF_TASK_STATUS_SUCCESSFUL' || eachData.taskStatus== 'INF_TASK_STATUS_UNSUCCESSFUL'){
                    taskIdAndBvTaskOutputMap.put(eachData.taskId, eachData.BvTaskOutput);
                }
            }
            List<PC_RecordIdentifier__c> externalRecordIdentifiers = new List<PC_RecordIdentifier__c>();
            if(taskIdAndBvTaskOutputMap != null && !taskIdAndBvTaskOutputMap.isEmpty() ) {
                externalRecordIdentifiers = getRecordIdentifiersForExternalTask(taskIdAndBvTaskOutputMap.keySet());
            }
            if(externalRecordIdentifiers != null && !externalRecordIdentifiers.isEmpty() ) {
                List<sObject> medicalCoverageList= new List<sObject>();
                List<BvTaskOutput> BvTaskOutputs= new List<BvTaskOutput>();
                List<String> relatedRecordIdList = new List<String>();
                Map<String, String> callbackErrorMap = new Map<String,String>();
                for (PC_RecordIdentifier__c ri : externalRecordIdentifiers) {
                    BvTaskOutput bv= taskIdAndBvTaskOutputMap.get(ri.PC_Value__c);
                    String relatedRecordId= ri.PC_RecordId__c;
                    relatedRecordIdList.add(relatedRecordId);
                    if(bv.errorInfo!=null){
                        callbackErrorMap.put(relatedRecordId,bv.errorInfo.failureReason);
                    }else {
                        //Need to change the medical coverage logic
                        medicalCoverageList=getMedicalCoverageRecords(bv, relatedRecordId);
                        BvTaskOutputs.add(bv);
                    }
                }
                System.debug('medicalCoverages-'+medicalCoverageList);
                if(medicalCoverageList!=null && !medicalCoverageList.isEmpty()) {
                    if (BvTaskOutputs != null && !BvTaskOutputs.isEmpty()) {
                        updateMedicalCoverages(medicalCoverageList, BvTaskOutputs);//update program coverage
                    }
                    List<PC_RecordIdentifier__c> internalRecordIdentifiers = getRecordIdentifiersForInternalTask(relatedRecordIdList);
                    List<String> internalTaskIdList = new List<String>();
                    for (PC_RecordIdentifier__c ri : internalRecordIdentifiers) {
                        String taskId = ri.PC_Value__c;
                        internalTaskIdList.add(taskId);
                    }
                    updateInternalTasks(internalTaskIdList,null);
                }else if(callbackErrorMap!=null && !callbackErrorMap.isEmpty()){
                    List<String> relatedRecordIds= new List<String>();
                    relatedRecordIds.addAll(callbackErrorMap.keySet());
                    List<PC_RecordIdentifier__c> internalRecordIdentifiers = getRecordIdentifiersForInternalTask(relatedRecordIds);
                    Map<String,String> errorDetailsMap= new Map<String,String>();
                    for (PC_RecordIdentifier__c ri : internalRecordIdentifiers) {
                        String taskId = ri.PC_Value__c;
                        String errorInfo= callbackErrorMap.get(ri.PC_RecordId__c);
                        errorDetailsMap.put(taskId,errorInfo);
                    }updateInternalTasks(null,errorDetailsMap);
                }
            }
        }

        private static List<PC_RecordIdentifier__c> getRecordIdentifiersForInternalTask(List<String> relatedRecordIdList) {
            List<PC_RecordIdentifier__c> recordIdentifierList = new List<PC_RecordIdentifier__c>();
            recordIdentifierList= [SELECT PC_RecordId__c,PC_Value__c,PC_Type__c
            FROM PC_RecordIdentifier__c
            WHERE PC_RecordId__c IN: relatedRecordIdList
            AND PC_Type__c =: PC_Constants.INTERNAL_TASK
            WITH SECURITY_ENFORCED
            ];
            return recordIdentifierList;
        }

        private static void updateInternalTasks(List<String> internalTaskIds,Map<String,String> errorDetailsMap ){
            if(internalTaskIds== null && errorDetailsMap!= null){
                List<Task> internalTaskList= [SELECT Id,Subject,PC_Direction__c, Description,Status
                FROM Task
                WHERE Id IN: errorDetailsMap.keySet()
                AND Status=:PC_Constants.PC_LOG_STATUS_IN_PROGRESS
                WITH SECURITY_ENFORCED
                LIMIT 1
                ];
                List<Task> tasksToUpdate= new List<Task>();
                for(Task task:internalTaskList){
                    String errorMsg= errorDetailsMap.get(task.Id);
                    task.Subject= System.Label.PC_MedicalBIFailureMessage;
                    task.Status=PC_Constants.PC_TASK_STATUS_WAITING;
                    task.Description= task.Description+'\n\n'+PC_Constants.ERROR+'- '+errorMsg;
                    task.PC_Direction__c= PC_Constants.INBOUND;
                    tasksToUpdate.add(task);
                    PC_Utility.createErrorLog(errorMsg);
                }
                PC_Database.upd(tasksToUpdate,false);
                System.debug('tasksToUpdate-Error--' +tasksToUpdate);
            }
            else{
                List<Task> internalTaskList= [SELECT Id,Subject, PC_Direction__c,Description,Status
                FROM Task
                WHERE Id IN: internalTaskIds
                AND Status=:PC_Constants.PC_LOG_STATUS_IN_PROGRESS
                WITH SECURITY_ENFORCED
                LIMIT 1
                ];
                List<Task> tasksToUpdate= new List<Task>();
                for(Task task:internalTaskList){
                    task.Subject= System.Label.PC_MedicalBICompletionMessage;
                    task.Status=PC_Constants.PC_TASK_STATUS_COMPLETED;
                    task.PC_Direction__c= PC_Constants.INBOUND;
                    tasksToUpdate.add(task);
                }
                PC_Database.upd(tasksToUpdate,false);
                System.debug('tasksToUpdate-Success--' +tasksToUpdate);
            }

        }

        private static List<PC_RecordIdentifier__c> getRecordIdentifiersForExternalTask(Set<String> keySet) {
            List<PC_RecordIdentifier__c> recordIdentifierList = new List<PC_RecordIdentifier__c>();
            recordIdentifierList= [SELECT PC_RecordId__c,PC_Value__c,PC_Type__c
            FROM PC_RecordIdentifier__c
            WHERE PC_Value__c IN: keySet
            AND PC_Type__c =: PC_Constants.INFINITUS
            WITH SECURITY_ENFORCED
            ];
            return recordIdentifierList;
        }

        private static List<sObject> getMedicalCoverageRecords(BvTaskOutput bv, String relatedRecordId){
            List<sObject> medicalCoverageRecords= new List<sObject>();
            /**Program Coverage**/
            List<String> relatedIdList= relatedRecordId.split('-');
            //Query to get Health Plan specific details
            PC_Health_Plan__c healthPlan= [SELECT Id, Patient__c, Patient__r.Name,PC_Payer_Name__c,RecordType.DeveloperName,PC_Public_Or_Private__c
                                            FROM PC_Health_Plan__c
                                            WHERE Id=:relatedIdList[0]
                                            WITH SECURITY_ENFORCED
            ];
            String caseId= relatedIdList[1];
            PC_Program_Coverage__c medicalCoverage= createProgramCoverage(healthPlan,caseId,bv);
            medicalCoverageRecords.add(medicalCoverage);
            /**Member Plan**/
            MemberPlan memberPlan= new MemberPlan();
            memberPlan.MemberId= healthPlan.Patient__c;
            memberPlan.Name= PC_Constants.PC_MEMBER_PLAN_ABBREVIATION+healthPlan.Patient__r.Name;
            PC_Database.ins(memberPlan,false);//Insert the Member Plan Record
            /**Coverage Benefit**/
            List<CoverageBenefit> coverageBenefits= new List<CoverageBenefit>();
            if(bv.productCodeBenefits!=null) {
                for (ProductCodeBenefits productCodeBenefits : bv.productCodeBenefits) {
                    if (medicalCoverage != null && memberPlan != null) {
                        CoverageBenefit coverageBenefit = new CoverageBenefit();
                        coverageBenefit.PC_ProgramCoverage__c = medicalCoverage.Id;
                        //coverageBenefit.Name = PC_Constants.PC_COVERAGE_BENEFIT_ABBREVIATION + productCodeBenefits.code;
                        coverageBenefit.Name = healthPlan.PC_Payer_Name__c+' : ' +productCodeBenefits.code;
                        coverageBenefit.MemberPlanId = memberPlan.Id;
                        coverageBenefit.CoinsuranceNotes = String.valueOf(productCodeBenefits.coinsurance);
                        coverageBenefit.CopayNotes = String.valueOf(productCodeBenefits.copay);
                        coverageBenefit.BenefitNotes = productCodeBenefits.additionalNotes;
                        coverageBenefits.add(coverageBenefit);
                    }
                }
            }
            PC_Database.ins(coverageBenefits,false);//Insert CoverageBenefit Records
            medicalCoverageRecords.addAll(coverageBenefits);
            /**Coverage Benefit Item**/
            List<CoverageBenefitItem> coverageBenefitItems= new List<CoverageBenefitItem>();
            //TODO-Find the exact Coverage Benefit for its Benefit Item
            for(coverageBenefit coverageBenefit:coverageBenefits) {
                if(bv.cptCodeBenefits!=null) {
                    for (ProductCodeBenefits cptCodeBenefit : bv.cptCodeBenefits) {
                        CoverageBenefitItem coverageBenefitItem = new CoverageBenefitItem();
                        coverageBenefitItem.CoverageBenefitId = coverageBenefit.Id;
                        //coverageBenefitItem.Name = PC_Constants.PC_COVERAGE_BENEFIT_ITEM_ABBREVIATION + cptCodeBenefit.code;
                        coverageBenefitItem.Name = coverageBenefit.Name+' : ' + cptCodeBenefit.code;
                        //coverageBenefitItem.DoesDeductibleApply=cptCodeBenefit.deductibleApplies;
                        coverageBenefitItem.Notes = cptCodeBenefit.code + '\n\n' + cptCodeBenefit.additionalNotes;
                        coverageBenefitItems.add(coverageBenefitItem);
                    }
                }
            }
            PC_Database.ins(coverageBenefitItems,false);//Insert CoverageBenefitItem Records
            medicalCoverageRecords.addAll(coverageBenefitItems);
            return medicalCoverageRecords;
        }
        private static PC_Program_Coverage__c createProgramCoverage(PC_Health_Plan__c healthPlan, String caseId,BvTaskOutput bv ){
            PC_Program_Coverage__c medicalCoverage= new PC_Program_Coverage__c();
            medicalCoverage.PC_Health_Plan__c=healthPlan.Id;
            medicalCoverage.PC_Program__c=caseId;
            //Method for Program Coverage RecordType & Coverage Type selection
            PC_eBenefits2.setCoverageRecordTypeAndType(healthPlan,medicalCoverage);
            medicalCoverage.PC_Coverage_Status__c = PC_Constants.ACTIVE;
            medicalCoverage.PC_Comments__c= String.format(System.Label.PC_ProgramCoverageSource, new List<Object>{bv.taskLink});
            PC_Database.ins(medicalCoverage,false);//Insert the Program Coverage Record
            return medicalCoverage;
        }

        public TasksRequest getRequestForMedicalBenefit(Id sourceRecordId,PC_Infinitus.BITaskType requestType) {
            TasksRequest tasksRequest = new TasksRequest();
            try {
                tasksRequest = new TasksRequest(sourceRecordId,requestType);
            } catch (Exception ex) {
                PC_Utility.createExceptionLog(ex);
            }
            return tasksRequest;
        }

        public static void updateMedicalCoverages(List<sObject> coverageObjects, Object medicalBVOutput){
            System.debug('CoverageObjects--'+coverageObjects+'MedicalBVOutput--'+medicalBVOutput);
        }
    }