/*********************************************************************************
Class Name      : ACLS_IP_Callouts_Utility_DEVORG
Description     : 
Created By      : R
Created Date    : 
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                    Description
-----------------------------------------------------------------------------------
               14-Mar-2023              Initial Version
*********************************************************************************/
global with sharing class ACLS_IP_Callouts_Utility_v2 implements Callable,omnistudio.VlocityOpenInterface{

    /********************************************************************************************************************
    Method Name    : makeCalloutFromIP
    Author         : Deloitte
    Description    : Method calls the Parent IntegrationProcedure 
    Return Type    : Map<String,Object>
    Parameter      : String endpoint, String requestBody, Map<String,String> mapHeaders, String ipProcedureNam
    *********************************************************************************************************************/
    public static Map<String,Object> makeCalloutFromIPWithToken(String environment,String integrationName,String baseExtractDataRaptorName,String ipProcedureName, String accessToken,String efaxID, String phoneNumber, String state, String messageRecordId, String smsTaskId, String message){
        
        Map<String,Object> ipInput      = new Map<String,Object>();
        Map<String,Object> ipOutput     = new Map<String,Object>();
        Map<String,Object> ipOptions    = new Map<String,Object>();

       
        //ipInput.put('integrationName',integrationName);
        //ipInput.put('extractDataRaptor',baseExtractDataRaptorName);
        ipInput.put('environment',environment);
        ipInput.put('accessToken',accessToken);
        ipInput.put('efaxID',efaxID);
        ipInput.put('state',state);
        ipInput.put('phoneNumber',phoneNumber);
        ipInput.put('messageRecordId',messageRecordId);
        ipInput.put('smsTaskId',smsTaskId);
        ipInput.put('eFaxRecordId',efaxID);
        ipInput.put('message',message);

        ipOutput = (Map<String,Object>)omnistudio.IntegrationProcedureService.runIntegrationService(ipProcedureName,ipInput,ipOptions);
        System.debug('ipOutput-->'+ipOutput);
        return ipOutput;
    }

    /********************************************************************************************************************
    Method Name    : makeCalloutFromIP
    Author         : Deloitte
    Description    : Method calls the Parent IntegrationProcedure 
    Return Type    : Map<String,Object>
    Parameter      : String endpoint, String requestBody, Map<String,String> mapHeaders, String ipProcedureNam
    *********************************************************************************************************************/
    public static Map<String,Object> makeCalloutFromIP(String environment,String integrationName,String baseExtractDataRaptorName,String ipProcedureName){
        
        Map<String,Object> ipInput      = new Map<String,Object>();
        Map<String,Object> ipOutput     = new Map<String,Object>();
        Map<String,Object> ipOptions    = new Map<String,Object>();

       
        //ipInput.put('integrationName',integrationName);
        //ipInput.put('extractDataRaptor',baseExtractDataRaptorName);
        ipInput.put('environment',environment);
        

        
        ipOutput = (Map<String,Object>)omnistudio.IntegrationProcedureService.runIntegrationService(ipProcedureName,ipInput,ipOptions);
        return ipOutput;
    }

    /********************************************************************************************************************
    Method Name    : prepareHttpResponse
    Description    : typecast the returned value into a HTTP response instance
    Parameter      : Map<String,Object>
    *********************************************************************************************************************/ 
    public static HttpResponse prepareHttpResponse(Map<String,Object> ipResponse){
        HttpResponse response = new HttpResponse();
        if((ipResponse.get('statusCode')) != null){
            response.setStatusCode(Integer.valueof((ipResponse.get('statusCode'))));
        }
        response.setBody(JSON.serialize(ipResponse.get('body')));
        return response;
    }
    
    /********************************************************************************************************************
    Method Name    : call
    Description    : Interface implementation from Callable,omnistudio.VlocityOpenInterface
    Parameter      : String action, Map<String, Object> args
    *********************************************************************************************************************/    
    global Object call(String action, Map<String, Object> args) {
        
        Map<String, Object> input = (Map<String, Object>)args.get('input');
        Map<String, Object> output = (Map<String, Object>)args.get('output');
        Map<String, Object> options = (Map<String, Object>)args.get('options');
        
        return invokeMethod(action, input, output, options);
    }

    /********************************************************************************************************************
    Method Name    : invokeMethod
    Description    : Interface implementation from Callable,omnistudio.VlocityOpenInterface
    Parameter      : String methodName, Map<String, Object> inputMap, Map<String, Object> outMap, Map<String, Object> options
    *********************************************************************************************************************/    
    global boolean invokeMethod(String methodName, Map<String, Object> inputMap, Map<String, Object> outMap, Map<String, Object> options) {
        
        try{
            if(methodName.equalsIgnoreCase(ACLS_Constants.OMNISTUDIO_IP_GET_EXTRACT_DR)){
                //getExtractDR(inputMap,outMap,options);  
            }else if(methodName.equalsIgnoreCase('replaceString')){
               replaceString(inputMap,outMap,options);  
            }else{
                outMap.put(ACLS_Constants.OMNISTUDIO_IP_RESULT,'');
            }
            return true;
        }catch(Exception e){
            return false;
        }
    }
    /********************************************************************************************************************
    Method Name    : getExtractDR
    Author         : Deloitte
    Description    : method to invoke the extract data raptor for the remoteAction element used in IntegrationProcedure
    Return Type    : void
    Parameter      : Map<String,object> inputMap, Map<String,object> outMap,Map<String,object> options
    *********************************************************************************************************************    
    public void getExtractDR(Map<String,object> inputMap, Map<String,object> outMap,Map<String,object> options){
        
        String integrationName        = (String)inputMap.get(ACLS_Constants.OMNISTUDIO_IP_INTEGRATION_NAME);
        String environment 			  = (String)inputMap.get('environment');
        String extractDataRaptor      = (String)inputMap.get(ACLS_Constants.OMNISTUDIO_IP_EXTRACT_RAPTOR);
        String efaxID        		  = (String)inputMap.get('efaxID');
        String smsTaskId              = (String)inputMap.get('smsTaskId');
        String accessToken            = (String)inputMap.get('accessToken');
        String messageRecordId        = (String)inputMap.get('messageRecordId');
        String state                  = (String)inputMap.get('state');
        String eFaxRecordId           = (String)inputMap.get('eFaxRecordId');
        String phoneNumber            = (String)inputMap.get('phoneNumber');
        String message                = (String)inputMap.get('message');
        

        Map<String,object> extractDataMap = new Map<String,object>{ACLS_Constants.OMNISTUDIO_IP_INTEGRATION_NAME=>integrationName,'environment' => environment,'efaxID' => efaxID,'smsTaskId' => smsTaskId,'messageRecordId' => messageRecordId,'state' => state,'accessToken' => accessToken, 'eFaxRecordId' => eFaxRecordId, 'phoneNumber' => phoneNumber, 'message' => message}; 
        omnistudio.DRProcessResult resultOutput = omnistudio.DRGlobal.process(extractDataMap, extractDataRaptor); 
        
        List<Map<String, Object>> extractDRResult = (List<Map<String, Object>>)resultOutput.toJsonList();
        outMap.put(ACLS_Constants.OMNISTUDIO_IP_EXTRACT_DR_RESULT,extractDRResult);
    }*/
    
    /********************************************************************************************************************
    Method Name    : replaceString
    Author         : Deloitte
    Description    : method to replace chars in a string
    Return Type    : void
    Parameter      : Map<String,object> inputMap, Map<String,object> outMap,Map<String,object> options
    *********************************************************************************************************************/    
    public void replaceString(Map<String,object> inputMap, Map<String,object> outMap,Map<String,object> options){
        List<Object> arguments = (List<Object>)inputMap.get('arguments');
        String str = String.valueOf(arguments[0]);
        String target = String.valueOf(arguments[1]);
        String result = str.replace('{faxid}', target);
        outMap.put('result', result);
    } 
}