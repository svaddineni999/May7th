/*************************************************************************************************************************************
Class Name      : ACLS_Fax_IntegrationHandlerQueueable
Description     : Handler class for Fax Outbound API
Created Date    : April 14, 2023
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer                   Date                   Description
--------------------------------------------------------------------------------------------------------------
Dev Desai            April 14, 2023             Initial Version - US-709
****************************************************************************************************************************************************/
public with sharing class ACLS_Fax_IntegrationHandlerQueueable implements Queueable,Database.AllowsCallouts {

    @testvisible private static HttpResponse httpRes;
     @testvisible private static HttpResponse httpRes1;
     private List<EFX__efax__c> faxList;
     List<PC_Remote_Service_Log__c> lstRemoteServiceLogs;
     List<PC_Error_Log__c> lstErrorLogs;
     List<Id> faxIds = new List<Id>();
     Map<Id,Id> mapFaxVsDocId = new Map<Id,Id>();
     public static final String CLASSNAME = 'ACLS_Fax_IntegrationHandlerQueueable';
     public static final String ERRORMESSAGE = 'Bearer Token received is Null';
     public Boolean isError;
 
     
     /********************************************************************************************************************
     Method Name    : ACLS_Fax_IntegrationHandlerQueueable
     Description    : Constructor to initialize variables
     Parameter      : Id faxId
     *********************************************************************************************************************/
     public ACLS_Fax_IntegrationHandlerQueueable(List<EFX__efax__c> faxList, Map<Id,Id> mapFaxVsDocId) {
         this.faxList = faxList;
         this.isError = false;
         this.lstRemoteServiceLogs = new List<PC_Remote_Service_Log__c>();
         this.lstErrorLogs = new List<PC_Error_Log__c>();
         this.mapFaxVsDocId = mapFaxVsDocId;
 
         for(EFX__efax__c fax : this.faxList ){
             this.faxIds.add(fax.Id);
         }
     }
 
     /********************************************************************************************************************
     Method Name    : execute
     Description    : perform operations to make callout and send Fax
     Return Type    : void
     Parameter      : QueueableContext context
     *********************************************************************************************************************/
     public void execute(QueueableContext context) {
         Map<Id, List<Id>> attachmentContents= new Map<Id, List<Id>>();
         try{
             String bearerToken = getAccessToken();
             if(bearerToken!=null){
                 for(EFX__efax__c fax : faxList){                                        //When multiple recipients are choosen then multiple Fax records are created.
                    fax = sendFaxOutbound(bearerToken, fax);
                 }
             }
             else{
                 this.isError = true;
                 ACLS_Utility.createINTErrorLogs(null, Label.ACLS_Fax_Error + ERRORMESSAGE, '', ERRORMESSAGE, '', CLASSNAME, '', this.faxList[0].Id);
                 //failure reason = Bearer Toekn is Null
                  setFaxFailResponse(faxList);
                  setFaxStatusAsFailed(faxList);
             }
             if(Schema.sObjectType.PC_Remote_Service_Log__c.isCreateable() && !lstRemoteServiceLogs.isEmpty())
             {
                 insert this.lstRemoteServiceLogs;
             }
             if(Schema.sObjectType.PC_Remote_Service_Log__c.isCreateable() && !lstErrorLogs.isEmpty())
             {
                 insert this.lstErrorLogs;
             }
             if(Schema.sObjectType.EFX__efax__c.isUpdateable() && !faxList.isEmpty())
             {
                 update this.faxList;
             }
             
             if(isError){
                 Id recordId = (this.mapFaxVsDocId.containsKey(this.faxList[0].Id))? this.mapFaxVsDocId.get(this.faxList[0].Id) : this.faxList[0].Id;
                 Task exceptionTask = ACLS_Utility.createTask(ACLS_Constants.OUTBOUND_FAX_EXCEPTION, ACLS_Constants.OUTBOUND_FAX_INTEGRATION, ACLS_Constants.OUTBOUND_FAX_FAX, DATE.today(), UserInfo.getUserId(), recordId, System.Label.ACLS_Fax_Error + ACLS_Constants.FAX_CALLOUTEXCEPTION);
                 if(Schema.sObjectType.Task.isCreateable())
             	{
                 insert exceptionTask;
             	}
             }
         }
         catch(Exception e){
             //failure reason = Exception occured
             setFaxFailResponseException(faxList);
             setFaxStatusAsFailed(faxList);
             ACLS_Utility.createINTErrorLogs(e, Label.ACLS_Fax_Error, null, null, '', CLASSNAME, '', this.faxList[0].Id);
             Id recordId = (this.mapFaxVsDocId.containsKey(this.faxList[0].Id))? this.mapFaxVsDocId.get(this.faxList[0].Id) : this.faxList[0].Id;
             Task exceptionTask = ACLS_Utility.createTask(ACLS_Constants.OUTBOUND_FAX_EXCEPTION, ACLS_Constants.OUTBOUND_FAX_INTEGRATION, ACLS_Constants.OUTBOUND_FAX_FAX, DATE.today(), UserInfo.getUserId(), recordId, System.Label.ACLS_Fax_Error + ACLS_Constants.FAX_CALLOUTEXCEPTION);
             if(Schema.sObjectType.Task.isCreateable())
             {
                 insert exceptionTask;
             }
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
            ACLS_Utility.createINTErrorLogs(null, ACLS_Constants.Fax_ERRORLOG1, '', ACLS_Constants.Fax_ERRORLOG2 + '\n', '', CLASSNAME, '', this.faxList[0].Id);
            return null;
        }
    }
 
     /**********************************************************************************************************
     Method Name    : sendFaxOutbound 
     Author         : Deloitte
     Description    : This method is used to make callout and send Fax
     Return Type    : String, EFX__efax__c
     **********************************************************************************************************/
     public EFX__efax__c sendFaxOutbound(String bearerToken, EFX__efax__c fax) {        
		Map<String,Object> response1 = new Map<String,Object>();
		if(!Test.isRunningTest()) {
            response1 = ACLS_IP_Callouts_Utility_v2.makeCalloutFromIPWithToken(ACLS_Utility.getCurrentEnvironment(), ACLS_Constants.FAX_EFAX_SENDFAX, ACLS_Constants.FAX_DR_SEND_FAX, ACLS_Constants.FAX_IP_SEND_FAX,bearerToken,fax.Id,null,null,null,null,null);
            httpRes1 = ACLS_IP_Callouts_Utility_v2.prepareHttpResponse(response1);      
        }

        //Create Remote Service Log            
        createRemoteServiceLog(JSON.serialize(response1.get('requestBody')), JSON.serialize(response1.get('endPoint')), httpRes1);
        
        if(response1!=null && response1.get('statusCode')!=null && Integer.valueOf(response1.get('statusCode')) == 201 && response1.get('eFaxId')!=null){                 
            fax.EFX__eFax_Id__c = (String)response1.get('eFaxId');
            fax.EFX__Status__c = ACLS_Constants.IN_PROGRESS;
        }else{
            fax.ACLS_Failure_Reason__c = (String)response1.get('failureReason');
            fax.EFX__Status__c = ACLS_Constants.ERROR;   
            this.isError = true;     
            ACLS_Utility.createINTErrorLogs(null, ACLS_Constants.FAX_EXCEPTION_OCCURED, '', ACLS_Constants.FAX_CALLOUTEXCEPTION + '\n', '', CLASSNAME, '', this.faxList[0].Id);
        }
        return fax;
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
 
     
     /********************************************************************************************************************
     Method Name    : setFaxStatusAsFailed
     Description    : set the fax status as failed 
     Return Type    : void
     Parameter      : List<Id> faxList
     *********************************************************************************************************************/
     public void setFaxStatusAsFailed(List<EFX__efax__c> faxList)
     {
        List<EFX__efax__c> lstStatusUpdate = new List<EFX__efax__c>();
        for(EFX__efax__c fax : faxList){    
            fax.EFX__Status__c = ACLS_Constants.ERROR; 
            lstStatusUpdate.add(fax);
        }
         update lstStatusUpdate;
     }
     
     /********************************************************************************************************************
     Method Name    : setFaxFailResponse
     Description    : set the fax Fail response
     Return Type    : void
     Parameter      : List<Id> faxList
     *********************************************************************************************************************/
    public void setFaxFailResponse(List<EFX__efax__c> faxList)
     {
        List<EFX__efax__c> lstFailResponse = new List<EFX__efax__c>();
        for(EFX__efax__c fax : faxList){    
            fax.ACLS_Failure_Reason__c = ACLS_Constants.FAX_BEARER_TOKEN_NULL;
            lstFailResponse.add(fax);
        }
         update lstFailResponse;
     }  
     
     /********************************************************************************************************************
     Method Name    : setFaxFailResponseException
     Description    : set the fax Fail response as Exception Occured
     Return Type    : void
     Parameter      : List<Id> faxList
     *********************************************************************************************************************/
    public void setFaxFailResponseException(List<EFX__efax__c> faxList)
    {
        List<EFX__efax__c> lstFailResponseException = new List<EFX__efax__c>();
        for(EFX__efax__c fax : faxList){    
            fax.ACLS_Failure_Reason__c = ACLS_Constants.FAX_EXCEPTION_OCCURED;
            lstFailResponseException.add(fax);
        }
         update lstFailResponseException;
    } 
     
 }