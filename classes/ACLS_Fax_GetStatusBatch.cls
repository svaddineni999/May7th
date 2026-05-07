/*********************************************************************************************************
Class Name      : ACLS_Fax_GetStatusBatch
Description     : This Batch is used to perform the handshake with eFax vendor and invoke APIs to get Fax details 
Created By      : Ronak Bansal
Created Date    : Apr 18th 2023
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer                   Date                   Description
Ronak Bansal              Apr 18th 2023           Initial Version
-------------------------------------------------------------------------------------------------------------- */  
public with sharing class ACLS_Fax_GetStatusBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {
    
    
   @testvisible private static HttpResponse httpRes;
   @testvisible private static HttpResponse httpRes1;
   
   //@testvisible private static String bearerToken;
    String query = '';   
    List<PC_Remote_Service_Log__c> lstRemoteServiceLogs;
    public static final List<PC_Remote_Service_Log__c> listRsl = new List<PC_Remote_Service_Log__c>();
    public static final String CLASS_BATCH_GETFAXSTATUS = 'ACLS_Fax_GetStatusBatch';
    public static final String ERRORMESSAGE = 'Bearer Token received is Null';
    
    /********************************************************************************************************************
    Method Name    : ACLS_Fax_GetStatusBatch
    Description    : Constructor to initialize query variable
    Parameter      : String inputQuery
    *********************************************************************************************************************/
    public ACLS_Fax_GetStatusBatch(String inputQuery){       
        query = inputQuery;  
        this.lstRemoteServiceLogs = new List<PC_Remote_Service_Log__c>(); 
    }

    /********************************************************************************************************************
    Method Name    : start
    Description    : Implemented method to perform query for the batch
    Parameter      : Database.BatchableContext bc
    *********************************************************************************************************************/
    public Database.QueryLocator start(Database.BatchableContext bc) {
        query = (query =='' || query ==null)? 'Select id,EFX__eFax_Id__c,EFX__Status__c,ACLS_Failure_Reason__c from EFX__efax__c where RecordType.DeveloperName = \'Sent_Fax\' and EFX__Status__c = \'IN PROGRESS\' and EFX__eFax_Id__c != null' : query;
        return Database.getQueryLocator(query);
    }

    /********************************************************************************************************************
    Method Name    : execute
    Description    : Implemented method to perform the batch processing
    Parameter      : Database.BatchableContext bc, List<EFX__efax__c> scope
    *********************************************************************************************************************/
    public void execute(Database.BatchableContext bc, List<EFX__efax__c> scope){
        try{
            String bearerToken = getAccessToken();
            if(bearerToken!=null){
                for(EFX__efax__c fax: scope){
                    fax = getFaxStatus(fax, bearerToken);
                    if(fax==null)
                        break;
                }
            }else{
                ACLS_Utility.createINTErrorLogs(null, Label.ACLS_Fax_Error + ERRORMESSAGE, '', ERRORMESSAGE, '', CLASS_BATCH_GETFAXSTATUS, '', '');
            }

            if(!scope.isEmpty()){
            	update scope;
            }
            if(!this.lstRemoteServiceLogs.isEmpty()){
            	insert this.lstRemoteServiceLogs;
        	}

        }catch(Exception ex){
            ACLS_Utility.createINTErrorLogs(ex, null, null, null, null, CLASS_BATCH_GETFAXSTATUS, 'execute', '');
        }
    }

    /********************************************************************************************************************
    Method Name    : finish
    Description    : Implemented method to reinstate the batch
    Parameter      : Database.BatchableContext bc
    *********************************************************************************************************************/
    public void finish(Database.BatchableContext bc){
        AsyncApexJob asyncJob = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = : bc.getJobId()];    
        Integer batchSize = 40;
        Integer batchFrequency = 15;
        batchSize = ACLS_KeyValMapperUtil.getValue(CLASS_BATCH_GETFAXSTATUS, ACLS_Constants.KEYVAL_TYPE_BATCHSIZE) != null ? Integer.ValueOf(ACLS_KeyValMapperUtil.getValue(CLASS_BATCH_GETFAXSTATUS, ACLS_Constants.KEYVAL_TYPE_BATCHSIZE)) : batchSize;
        batchFrequency = ACLS_KeyValMapperUtil.getValue(CLASS_BATCH_GETFAXSTATUS, ACLS_Constants.KEYVAL_TYPE_BATCHFREQ) != null ? Integer.ValueOf(ACLS_KeyValMapperUtil.getValue(CLASS_BATCH_GETFAXSTATUS, ACLS_Constants.KEYVAL_TYPE_BATCHFREQ)) : batchFrequency;
		if(asyncJob.NumberOfErrors>0) {  
            ACLS_Utility.createINTErrorLogs(null, null, null, 'Batch Status - The batch apex job has processed ' + asyncJob.TotalJobItems + ' jobs with ' + asyncJob.NumberOfErrors + ' failures.', null, CLASS_BATCH_GETFAXSTATUS, ACLS_Constants.METHOD_BATCH_SENDSMS_FINISH, '');
        }
        if(!Test.isRunningTest()) {
            System.scheduleBatch(new ACLS_Fax_GetStatusBatch(''), 'GetFaxStatusBatch' ,batchFrequency, batchSize);  
        }
    }


        /**********************************************************************************************************
	Method Name    : getAccessToken 
	Author         : Deloitte
	Description    : This method is used to get the access token for Fax Integration
	Return Type    : String
	**********************************************************************************************************/
    public String getAccessToken() {
        Map<String,Object> response = new Map<String,Object>();
        if(!Test.isRunningTest()) {
            response = ACLS_IP_Callouts_Utility_v2.makeCalloutFromIP(ACLS_Utility.getCurrentEnvironment(), ACLS_Constants.FAX_EFAX_TOKEN, ACLS_Constants.INTEGERATION_CONFIG_MDT, ACLS_Constants.FAX_IP_GETTOKEN);
            httpRes = ACLS_IP_Callouts_Utility_v2.prepareHttpResponse(response);
        }
    
        //Create remote service log
        createRemoteServiceLog(JSON.serialize(response.get('requestBody')), JSON.serialize(response.get('endPoint')), httpRes);

        //Parse response
        if(response!=null && response.get('statusCode')!=null && Integer.valueOf(response.get('statusCode')) == 200 &&  response.get('accessToken')!=null){
            String returnAccessToken = (String)response.get('accessToken');
            return returnAccessToken;                
        }
        else{               
            ACLS_Utility.createINTErrorLogs(null, ACLS_Constants.Fax_ERRORLOG1, '', ACLS_Constants.Fax_ERRORLOG2 + '\n', '', CLASS_BATCH_GETFAXSTATUS, '', '');
 			return null;
        }
    }

    /********************************************************************************************************************
    Method Name    : createRemoteServiceLog
    Description    : Create instance of Remote service logs
    Return Type    : void
    Parameter      : String splitRequestBody, String endPoint, HttpResponse res
    *********************************************************************************************************************/
    public void createRemoteServiceLog(String requestBody, String endPoint, HttpResponse res){
        requestBody = (requestBody.length() > 131071)? requestBody.substring(0,131070) : requestBody;        

        PC_Remote_Service_Log__c faxRSL = PC_RemoteServiceLogHandler.getRemoteServiceLog(ACLS_Constants.OUTBOUND_FAX_FAX, endPoint, requestBody, res?.getBody(), 'Callout made to send Fax', PC_Constants.REMOTE_SERVICE_TYPE_OUTBOUND);
        faxRSL.PC_StatusCode__c = (res!=null)? String.valueOf(res.getStatusCode()) : '';
        this.lstRemoteServiceLogs.add(faxRSL);
    }

    /**********************************************************************************************************
	Method Name    : getFaxStatus 
	Author         : Deloitte
	Description    : This method is used to poll the status of the Fax
	Return Type    : String
	**********************************************************************************************************/
    public EFX__efax__c getFaxStatus(EFX__efax__c fax, String bearerToken){
        Map<String,Object> response1 = new Map<String,Object>();
        if(!Test.isRunningTest()) {
            response1 = ACLS_IP_Callouts_Utility_v2.makeCalloutFromIPWithToken(ACLS_Utility.getCurrentEnvironment(), ACLS_Constants.FAX_EFAX_GETSTATUS, ACLS_Constants.FAX_DR_GET_STATUS, ACLS_Constants.FAX_IP_GET_STATUS,bearerToken,fax.EFX__eFax_Id__c,null,null,null,null,null);
            httpRes1 = ACLS_IP_Callouts_Utility_v2.prepareHttpResponse(response1);  
        }
                

        //Create Remote Service Log
        createRemoteServiceLog('GET Callout',JSON.serialize(response1.get('endPoint')) , httpRes1);

        //Parse Response
        if(response1!=null && response1.get('statusCode')!=null && Integer.valueOf(response1.get('statusCode')) == 200 && response1.get('status')!=null){
            if(response1.get('status') != 'NEW')
                fax.EFX__Status__c = (response1.get('status'))!=null? String.valueOf((response1.get('status'))) : null;

            if(fax.EFX__Status__c == ACLS_Constants.ERROR)
                fax.ACLS_Failure_Reason__c = (response1.get('failureReason'))!=null? String.valueOf((response1.get('failureReason'))) : null;
        }else{
            fax.EFX__Status__c = ACLS_Constants.ERROR;      
        }

        return fax;
    }
}