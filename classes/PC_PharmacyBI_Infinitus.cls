/**************************************************************************************************************************************************************************
Class Name      : PC_PharmacyBI_Infinitus
Description     : This is the Infinitus Service Class For Pharmacy BI.
Created By      : Satheesh Kumar & Chetna Mohapatra
Created Date    : 01-Mar-2022
Modification Log:
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Developer                   Date                  Description
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Chetna Mohapatra
& Satheesh Kumar        01-Mar-2022             Initial Version
 **********************************************************************************************************************************************************************/
 public with sharing class PC_PharmacyBI_Infinitus extends PC_Infinitus implements PC_eBenefits2.PharmacyBenefits {

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

    public List<PC_eBenefits2.PharmacyBenefitsResponse> lookupPharmacyBenefits(PC_eBenefits2.PharmacyBenefitsRequest pharmacyBenefitsRequest) {
        List<PC_eBenefits2.PharmacyBenefitsResponse> pharmacyBenefitsResponse = new List<PC_eBenefits2.PharmacyBenefitsResponse> ();
        TasksRequest tasksRequest = getRequestForPharmacyBenefit(pharmacyBenefitsRequest.sourceRecordId,PC_Infinitus.BITaskType.INF_TASK_TYPE_PHARMACY_BENEFIT_MANAGER);
        System.debug('TasksRequest--' + tasksRequest);

        // Create Request
        payload = JSON.serialize(tasksRequest);
        HttpRequest request = generateHttpRequest();
        String requestBody = request.getBody();
        String requestEndpoint= request.getEndpoint();
        system.debug('request body----' + requestBody);

        //Response received
        HttpResponse response = sendRequest(request);
        Integer statusCode = response.getStatusCode();
        String responseBody = response.getBody();
        system.debug('response details----' +responseBody+'---'+statusCode);

        //Create Remote Service Log for each TaskRequest
        String infinitusServiceName= PC_Constants.INFINITUS;
        String serviceType= PC_Constants.REMOTE_SERVICE_TYPE_OUTBOUND;
        PC_Remote_Service_Log__c remoteServiceLog = new PC_Remote_Service_Log__c();
        remoteServiceLog=PC_RemoteServiceLogHandler.getRemoteServiceLog(infinitusServiceName, requestEndpoint, requestBody, responseBody, '',serviceType);
        PC_Database.ins(remoteServiceLog);

        //Processing the response received from Infinitus
        pharmacyBenefitsResponse= processPharmacyBIResponse(response, statusCode, remoteServiceLog);
        return pharmacyBenefitsResponse;
    }

     public List<PC_eBenefits2.PharmacyBenefitsResponse> processPharmacyBIResponse(HttpResponse response,Integer statusCode, PC_Remote_Service_Log__c remoteServiceLog){
         //Parse the response
         String responseBody = response.getBody();
         PC_Infinitus.InfinitusBIResponse res = PC_Infinitus.parseInfinitusBIResponse(responseBody);
         system.debug('Infinitus response----' + res);
         List<PC_eBenefits2.PharmacyBenefitsResponse> pharmacyBenefitsResponses= new List<PC_eBenefits2.PharmacyBenefitsResponse>();
         if(res.message== null && res.data!=null) {
             for (Data data : res.Data) {
                 PC_eBenefits2.PharmacyBenefitsResponse eachResponse = new PC_eBenefits2.PharmacyBenefitsResponse();
                 if (data.error == null && statusCode != null && statusCode == 200) {
                     eachResponse.isSuccess = PC_Constants.TRUE_BOOLEAN;
                     eachResponse.externalId = data.taskId;
                     eachResponse.remoteServiceLogId = remoteServiceLog.Id;
                     eachResponse.relatedRecordId = data.customerId;
                     pharmacyBenefitsResponses.add(eachResponse);

                 } else if (data.error != null && statusCode != null && statusCode == 200) {
                     eachResponse.isSuccess = PC_Constants.FALSE_BOOLEAN;
                     eachResponse.errorMessage = data.error.errorMessage;
                     eachResponse.remoteServiceLogId = remoteServiceLog.Id;
                     eachResponse.relatedRecordId = data.customerId;
                     pharmacyBenefitsResponses.add(eachResponse);
                 }
             }
         }else {
                 //For failure in request
                 PC_eBenefits2.eBenefits2Exception ex = new PC_eBenefits2.eBenefits2Exception();
                 ex.setMessage(PC_Constants.ERROR+'- '+res.message);
                 throw ex;
         }
         return pharmacyBenefitsResponses;
     }

    public TasksRequest getRequestForPharmacyBenefit(Id sourceRecordId,PC_Infinitus.BITaskType requestType){
        TasksRequest tasksRequest= new TasksRequest();
        try{
            tasksRequest = new TasksRequest(sourceRecordId,requestType);
        } catch (Exception ex){
            PC_Utility.createExceptionLog(ex);
        }
        return tasksRequest;
    }

     public static void createProgramCoverageAndUpdateActivity(List<Data> pbmCallbackDataList){
         Map<String,PbmTaskOutput> taskIdAndPbmTaskOutputMap= new Map<String,PbmTaskOutput>();
         for(Data eachData:pbmCallbackDataList){
             if(eachData.taskStatus== 'INF_TASK_STATUS_SUCCESSFUL' || eachData.taskStatus== 'INF_TASK_STATUS_UNSUCCESSFUL'){
                 taskIdAndPbmTaskOutputMap.put(eachData.taskId, eachData.pbmTaskOutput);
             }
         }
         List<PC_RecordIdentifier__c> externalRecordIdentifiers = new List<PC_RecordIdentifier__c>();
         if(taskIdAndPbmTaskOutputMap != null && !taskIdAndPbmTaskOutputMap.isEmpty() ) {
             externalRecordIdentifiers = getRecordIdentifiersForExternalTask(taskIdAndPbmTaskOutputMap.keySet());
         }
         if(externalRecordIdentifiers != null && !externalRecordIdentifiers.isEmpty() ) {
             List<PC_Program_Coverage__c> pharmacyCoverageList= new List<PC_Program_Coverage__c>();
             List<PbmTaskOutput> pbmTaskOutputs= new List<PbmTaskOutput>();
             List<String> relatedRecordIdList = new List<String>();
             Map<String, String> callbackErrorMap = new Map<String,String>();
             for (PC_RecordIdentifier__c ri : externalRecordIdentifiers) {
                 PbmTaskOutput pbm= taskIdAndPbmTaskOutputMap.get(ri.PC_Value__c);
                 String relatedRecordId= ri.PC_RecordId__c;
                 relatedRecordIdList.add(relatedRecordId);
                 //Check if pbm has error or not, if not create Prg Cov & update the task else create Error log & update the task as well
                 if(pbm.errorInfo!=null){
                     callbackErrorMap.put(relatedRecordId,pbm.errorInfo.failureReason);
                 }else {
                     pharmacyCoverageList.addAll(getPharmacyCoverageRecords(pbm, relatedRecordId));
                     pbmTaskOutputs.add(pbm);
                 }
             }
             if(pharmacyCoverageList!=null && !pharmacyCoverageList.isEmpty()) {
                 if (pbmTaskOutputs != null && !pbmTaskOutputs.isEmpty()) {
                     updatePharmacyCoverages(pharmacyCoverageList, pbmTaskOutputs);//update program coverage
                 }
                 PC_Database.ins(pharmacyCoverageList, false);//Bulk-insert of Pharmacy coverage records

                 List<PC_RecordIdentifier__c> internalRecordIdentifers = getRecordIdentifiersForInternalTask(relatedRecordIdList);
                 List<String> internalTaskIdList = new List<String>();
                 for (PC_RecordIdentifier__c ri : internalRecordIdentifers) {
                     String taskId = ri.PC_Value__c;
                     internalTaskIdList.add(taskId);
                 }
                 updateInternalTasks(internalTaskIdList,null);
             }else if(callbackErrorMap!=null && !callbackErrorMap.isEmpty()){
                 List<String> relatedRecordIds= new List<String>();
                 relatedRecordIds.addAll(callbackErrorMap.keySet());
                 List<PC_RecordIdentifier__c> internalRecordIdentifers = getRecordIdentifiersForInternalTask(relatedRecordIds);
                 Map<String,String> errorDetailsMap= new Map<String,String>();
                 for (PC_RecordIdentifier__c ri : internalRecordIdentifers) {
                     String taskId = ri.PC_Value__c;
                     String errorInfo= callbackErrorMap.get(ri.PC_RecordId__c);
                     errorDetailsMap.put(taskId,errorInfo);
                 }updateInternalTasks(null,errorDetailsMap);
             }
         }
     }

     private static List<PC_RecordIdentifier__c> getRecordIdentifiersForInternalTask(List<String> relatedRecordIdList) {
         List<PC_RecordIdentifier__c> recordIdentiferList = new List<PC_RecordIdentifier__c>();
         recordIdentiferList= [SELECT PC_RecordId__c,PC_Value__c,PC_Type__c
         FROM PC_RecordIdentifier__c
         WHERE PC_RecordId__c IN: relatedRecordIdList
         AND PC_Type__c =: PC_Constants.INTERNAL_TASK
         WITH SECURITY_ENFORCED
         ];
         return recordIdentiferList;
     }

     private static void updateInternalTasks(List<String> internalTaskIds,Map<String,String> errorDetailsMap ){
         if(internalTaskIds== null && errorDetailsMap!= null){
             List<Task> internalTaskList= [SELECT Id,Subject,PC_Direction__c, Description,Status
                                            FROM Task
                                            WHERE Id IN: errorDetailsMap.keySet()
                                            AND Status=:PC_Constants.PC_LOG_STATUS_IN_PROGRESS
                                            WITH SECURITY_ENFORCED
             ];
             List<Task> tasksToUpdate= new List<Task>();
             for(Task task:internalTaskList){
                 String errorMsg= errorDetailsMap.get(task.Id);
                 task.Subject= System.Label.PC_PharmacyBIFailureMessage;
                 task.Status=PC_Constants.PC_TASK_STATUS_WAITING;
                 task.PC_Direction__c= PC_Constants.INBOUND;
                 task.Description=  task.Description+'\n\n'+PC_Constants.ERROR+'- '+errorMsg;
                 tasksToUpdate.add(task);
                 PC_Utility.createErrorLog(errorMsg);
             }
             PC_Database.upd(tasksToUpdate,false);
             System.debug('tasksToUpdate-Error--' +tasksToUpdate);
         }
         else{
             List<Task> internalTaskList= [SELECT Id,Subject,PC_Direction__c, Description,Status
                                             FROM Task
                                             WHERE Id IN: internalTaskIds
                                             AND Status=:PC_Constants.PC_LOG_STATUS_IN_PROGRESS
                                             WITH SECURITY_ENFORCED
                                             LIMIT 1
             ];
             List<Task> tasksToUpdate= new List<Task>();
             for(Task task:internalTaskList){
                 task.Subject= System.Label.PC_PharmacyBICompletionMessage;
                 task.Status=PC_Constants.PC_TASK_STATUS_COMPLETED;
                 task.PC_Direction__c= PC_Constants.INBOUND;
                 tasksToUpdate.add(task);
             }
             PC_Database.upd(tasksToUpdate,false);
             System.debug('tasksToUpdate-Success--' +tasksToUpdate);
         }

     }

     private static List<PC_RecordIdentifier__c> getRecordIdentifiersForExternalTask(Set<String> keySet) {
         List<PC_RecordIdentifier__c> recordIdentiferList = new List<PC_RecordIdentifier__c>();
         recordIdentiferList= [SELECT PC_RecordId__c,PC_Value__c,PC_Type__c
                               FROM PC_RecordIdentifier__c
                               WHERE PC_Value__c IN: keySet
                               AND PC_Type__c =: PC_Constants.INFINITUS
                               WITH SECURITY_ENFORCED
                                LIMIT 1
         ];
         return recordIdentiferList;
     }

     private static List<PC_Program_Coverage__c> getPharmacyCoverageRecords(PbmTaskOutput pbm, String relatedRecordId){
         List<PC_Program_Coverage__c> pharmacyCoverages= new List<PC_Program_Coverage__c>();
         List<String> relatedIdList= relatedRecordId.split('-');
         //Query to get Health Plan specific details
         PC_Health_Plan__c healthPlan= [SELECT Id, Patient__c, Patient__r.Name,PC_Payer_Name__c,RecordType.DeveloperName,PC_Public_Or_Private__c
                                         FROM PC_Health_Plan__c
                                         WHERE Id=:relatedIdList[0]
                                         WITH SECURITY_ENFORCED
         ];
         String caseId= relatedIdList[1];
         for(ProductCoverage productCoverage:pbm.productCoverage){
             PC_Program_Coverage__c pharmacyCoverage= new PC_Program_Coverage__c();
             pharmacyCoverage.PC_Health_Plan__c=healthPlan.Id;
             pharmacyCoverage.PC_Program__c=caseId;
             pharmacyCoverage.PC_Coverage_Status__c = PC_Constants.ACTIVE;
             //Method for Program Coverage RecordType & Coverage Type selection
             PC_eBenefits2.setCoverageRecordTypeAndType(healthPlan,pharmacyCoverage);
             pharmacyCoverage.PC_Comments__c= String.format(System.Label.PC_ProgramCoverageSource, new List<Object>{pbm.taskLink});
             pharmacyCoverages.add(pharmacyCoverage);
         }
         return pharmacyCoverages;
     }

     public static void updatePharmacyCoverages(List<sObject> coverageObjects, Object pbmTaskOutput){
        System.debug('Coverage Objects--'+coverageObjects+'PbmOutputs--'+pbmTaskOutput);
     }
 }