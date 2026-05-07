/*********************************************************************************
Class Name      : ACLS_IP_Callouts_Utility
Description     : 
Created By      : R
Created Date    : 
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                    Description
-----------------------------------------------------------------------------------
               14-Mar-2023              Initial Version
*********************************************************************************/
global with sharing class ACLS_IP_Callouts_Utility implements Callable,omnistudio.VlocityOpenInterface{
    /********************************************************************************************************************
    Method Name    : makeCalloutFromIP
    Author         : Deloitte
    Description    : Method calls the Parent IntegrationProcedure 
    Return Type    : Map<String,Object>
    Parameter      : String endpoint, String requestBody, Map<String,String> mapHeaders, String ipProcedureNam
    *********************************************************************************************************************/
    public static HttpResponse makeCalloutFromIP(String endPoint, String requestBody, Map<String, String> mapHeaders, String certificateName, Integer timeout, String ipProcedureName){
        
        Map<String,Object> ipInput      = new Map<String,Object>();
        Map<String,Object> ipOutput     = new Map<String,Object>();
        Map<String,Object> ipOptions    = new Map<String,Object>();

        ipInput.put('endPoint',endPoint);
        ipInput.put('requestBody',requestBody);
        ipInput.put('certificateName',certificateName);
        ipInput.put('timeout',timeout);
        

        for(String key : mapHeaders.keyset()){
            ipInput.put(key,mapHeaders.get(key));   // ipInput.put(Authorization,hkduosboj); //Content-Type
        }
        
        ipOutput = (Map<String,Object>)omnistudio.IntegrationProcedureService.runIntegrationService(ipProcedureName,ipInput,ipOptions);
        System.debug('ipInput '+ipInput);
        System.debug('ipOutput '+ipOutput);
        HttpResponse response = prepareHttpResponse(ipOutput);
        return response;
    }

    /********************************************************************************************************************
    Method Name    : prepareHttpResponse
    Description    : typecast the returned value into a HTTP response instance
    Parameter      : Map<String,Object>
    *********************************************************************************************************************/ 
    public static HttpResponse prepareHttpResponse(Map<String,Object> ipResponse){
        HttpResponse response = new HttpResponse();
        System.debug('VG '+ipResponse.get('statusCode'));
        if((ipResponse.get('statusCode')) != null){
            response.setStatusCode(Integer.valueof((ipResponse.get('statusCode'))));
        }
        response.setBody(JSON.serialize(ipResponse.get('body')));
        
       System.debug('response line 52 '+response);
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
            outMap.put(ACLS_Constants.OMNISTUDIO_IP_RESULT,'');
            return true;
        }catch(Exception e){
            return false;
        }
    }
}