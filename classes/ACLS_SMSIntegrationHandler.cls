/****************************************************************************************************************
Trigger Name    : ACLS_SMSIntegrationHandler
Description     : Handler for PC_Message__c object. 
Created By      : Deloitte
Created Date    : Jan 19, 2023
*****************************************************************************************************************
Version History :
Date			  Developer 			  User Story					     Changes
Jan 27, 2023	 Vartika Goyal				US-176				Added ACLS_MissingInfoRecordCreation method
*****************************************************************************************************************/
public with sharing class ACLS_SMSIntegrationHandler{

    @testvisible private static HttpResponse res1;
    @testvisible private static HttpResponse res2;
    @testvisible private static HttpResponse res3;
    @testvisible private static HttpResponse res4;

    /**********************************************************************************************************
	Method Name    : SMS_getToken 
	Author         : Deloitte
	Description    : This method is used to get the access token for SMS integratio
	Return Type    : String
	**********************************************************************************************************/
    public static String smsGetToken(){
        Map<String,Object> response = new Map<String,Object>();
        if(!Test.isRunningTest()) {
           response = ACLS_IP_Callouts_Utility_v2.makeCalloutFromIP(ACLS_Utility.getCurrentEnvironment(), ACLS_Constants.SMS_MDT_TOKEN, ACLS_Constants.INTEGERATION_CONFIG_MDT, ACLS_Constants.SMS_IP_GETTOKEN);
           res1 = ACLS_IP_Callouts_Utility_v2.prepareHttpResponse(response); 
        }

        //Create remote service log
        createRemoteServiceLog(JSON.serialize(response.get('requestBody')), JSON.serialize(response.get('endPoint')), res1.getBody(), response.get('statusCode')!=null? String.valueOf(response.get('statusCode')) : null);

        if(response.get('statusCode')!=null && (response.get('statusCode') == 200 || response.get('statusCode') == 202 || response.get('statusCode') == 204)){
            return (response.get('accessToken')!=null)? String.valueOf(response.get('accessToken')) : null;    
        }else{
            ACLS_Utility.createINTErrorLogs(null, '', '', ACLS_Constants.SMS_TOKEN_ERRORLOG1, '', ACLS_Constants.CLASS_SMS_INTEGRATIONHANDLER, '', '');
        }

        return null;
    }

    /**********************************************************************************************************
	Method Name    : smsUpdateOptInOptOut 
	Author         : Deloitte
	Description    : This method update the Optin/Optout status of a phone number
	Return Type    : Boolean
	Parameter      : String phoneNumber, String state, String accessToken           
	**********************************************************************************************************/
    public static Boolean smsUpdateOptInOptOut(String phoneNumber, String state, String accessToken){   
        Map<String,Object> response = new Map<String,Object>();
        phoneNumber = phoneNumber.length() == 10 ? '+1'+ phoneNumber: phoneNumber;

        if(!Test.isRunningTest()) {
           response = ACLS_IP_Callouts_Utility_v2.makeCalloutFromIPWithToken(ACLS_Utility.getCurrentEnvironment(), ACLS_Constants.SMS_MDT_UPDATEOPTIN, ACLS_Constants.SMS_UPDATEOPTIN_DR, ACLS_Constants.SMS_IP_UPDATEOPTIN,accessToken,null,phoneNumber,state,null,null,null);
           res2 = ACLS_IP_Callouts_Utility_v2.prepareHttpResponse(response); 
        }

        //Create remote service log
        createRemoteServiceLog(JSON.serialize(response.get('requestBody')), JSON.serialize(response.get('endPoint')), res2.getBody(), response.get('statusCode')!=null? String.valueOf(response.get('statusCode')) : null);

        if(response.get('statusCode')!=null && (response.get('statusCode') == 200 || response.get('statusCode') == 202 || response.get('statusCode') == 204)){
            return true;
        }else{
            ACLS_Utility.createINTErrorLogs(null, ACLS_Constants.SMS_OPTIN_ERRORLOG1, '', ACLS_Constants.SMS_OPTIN_ERRORLOG1, '', ACLS_Constants.CLASS_SMS_INTEGRATIONHANDLER, '', '');
        }

        return false;  
    }

    /**********************************************************************************************************
	Method Name    : sendMessage 
	Author         : Deloitte
	Description    : This method is used to send a sms via Integration
	Return Type    : String
	Parameter      : PC_Message__c messageRecord, String accessToken
	**********************************************************************************************************/
    public static String sendMessage(PC_Message__c messageRecord, String accessToken){

        String phoneNumber = messageRecord.PC_ExternalRecipientNumber__c.length() == 10 ? '+1'+messageRecord.PC_ExternalRecipientNumber__c: messageRecord.PC_ExternalRecipientNumber__c;

        Map<String,Object> response = new Map<String,Object>();
        if(!Test.isRunningTest()) {
           response = ACLS_IP_Callouts_Utility_v2.makeCalloutFromIPWithToken(ACLS_Utility.getCurrentEnvironment(), ACLS_Constants.SMS_MDT_SENDMESSAGE, ACLS_Constants.SMS_SENDMESSAGE_DR, ACLS_Constants.SMS_IP_SENDMESSAGE,accessToken,null,phoneNumber,null,messageRecord.Id,null,messageRecord.PC_Content__c);
           res2 = ACLS_IP_Callouts_Utility_v2.prepareHttpResponse(response); 
        }

        //Create remote service log
        createRemoteServiceLog(JSON.serialize(response.get('requestBody')), JSON.serialize(response.get('endPoint')), res2?.getBody(), response.get('statusCode')!=null? String.valueOf(response.get('statusCode')) : null);

        if(response.get('statusCode')!=null && (response.get('statusCode') == 200 || response.get('statusCode') == 202 || response.get('statusCode') == 204)){
            return (response.get('sendSmsTaskId')!=null)? String.valueOf(response.get('sendSmsTaskId')) : null;
        }else{
            ACLS_Utility.createINTErrorLogs(null, ACLS_Constants.SMS_SEND_ERRORLOG1, '', ACLS_Constants.SMS_SEND_ERRORLOG2, '', ACLS_Constants.CLASS_SMS_INTEGRATIONHANDLER, '', '');
        }

        return null;     
    }

    /**********************************************************************************************************
	Method Name    : getCampaignName 
	Author         : Deloitte
	Description    : This method is get the campaign details
	Return Type    : String
	Parameter      : None
	**********************************************************************************************************/
    public static String getCampaignName(){
        List<PC_EngagementProgramSetting__mdt> smsCampaignDetails = new  List<PC_EngagementProgramSetting__mdt> ();
        if(Schema.sObjectType.PC_EngagementProgramSetting__mdt.isAccessible()){
        smsCampaignDetails = new List<PC_EngagementProgramSetting__mdt>([Select Id,DeveloperName, PC_SettingValue__c, PC_EngagementProgram__c from PC_EngagementProgramSetting__mdt Where DeveloperName =: ACLS_Constants.EP_SMS_RAREASSIST_RX]);
        }
        Map<String, String> mapCampaignName = new Map<String, String>();
        mapCampaignName = (Map<String,String>) JSON.deserialize(smsCampaignDetails[0].PC_SettingValue__c, Map<String,String>.class);
        return mapCampaignName.get('name');

    }

    /**********************************************************************************************************
	Method Name    : createRemoteServiceLog 
	Author         : Deloitte
	Description    : This method is to create a RSL instance
	Return Type    : String
	Parameter      : None
	**********************************************************************************************************/
    public static void createRemoteServiceLog(String requestBody, String requestURL,String response, String statusCode) {
        String serviceType= PC_Constants.REMOTE_SERVICE_TYPE_OUTBOUND;
        String serviceName = ACLS_Constants.RSL_SERVICE_NAME_FIVE9SMS;
        
        PC_Remote_Service_Log__c record = PC_RemoteServiceLogHandler.getRemoteServiceLog(serviceName, requestURL, requestBody, response, '', serviceType);
        record.PC_StatusCode__c = statusCode;
        
        ACLS_SMS_SendSMSBatch.listRsl.add(record);
        ACLS_SMS_GetSMSStatusBatch.listRsl.add(record);

    }

    /**********************************************************************************************************
	Method Name    : getMessageStatus 
	Author         : Deloitte
	Description    : This method is used to get a sms list via Integration
	Return Type    : String
	**********************************************************************************************************/
    public static String getMessageStatus(PC_Message__c messageRecord, String accessToken){

        Map<String,Object> response = new Map<String,Object>();
        if(!Test.isRunningTest()) {
           response = ACLS_IP_Callouts_Utility_v2.makeCalloutFromIPWithToken(ACLS_Utility.getCurrentEnvironment(), ACLS_Constants.SMS_MDT_GETMESSAGESTATUS, ACLS_Constants.SMS_GETMESSAGESTATUS_DR, ACLS_Constants.SMS_IP_GETMESSAGESTATUS,accessToken,null,null,null,messageRecord.Id,'/'+messageRecord.PC_TransactionId__c,null);
           res2 = ACLS_IP_Callouts_Utility_v2.prepareHttpResponse(response); 
        }

        //Create remote service logm
        createRemoteServiceLog(JSON.serialize(response.get('requestBody')), JSON.serialize(response.get('endPoint')), res2?.getBody(), response.get('statusCode')!=null? String.valueOf(response.get('statusCode')) : null);

        if(response.get('statusCode')!=null && (response.get('statusCode') == 200 || response.get('statusCode') == 202 || response.get('statusCode') == 204)){
            return (response.get('status')!=null)? String.valueOf(response.get('status')) : null;
        }else{
            ACLS_Utility.createINTErrorLogs(null, ACLS_Constants.SMS_SEND_ERRORLOG1, '', ACLS_Constants.SMS_SEND_ERRORLOG2, '', ACLS_Constants.CLASS_SMS_INTEGRATIONHANDLER, '', '');
        }

        return null;             
    }
    
}