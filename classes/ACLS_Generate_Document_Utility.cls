/*********************************************************************************
Class Name      : ACLS_Generate_Document_Utility
Description     : Methods for eLetter2 lightning component
Created By      : R
Created Date    : 14-Mar-2023
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                    Description
-----------------------------------------------------------------------------------
               14-Mar-2023              Initial Version
*********************************************************************************/
global with sharing class ACLS_Generate_Document_Utility implements Callable,omnistudio.VlocityOpenInterface{
    /********************************************************************************************************************
    Method Name    : generateDocumentFromIP
    Author         : Deloitte
    Description    : Method calls the Parent IntegrationProcedure for DocGen
    Return Type    : void
    Parameter      : String sourceRecordId, String targetRecordId, String engagementProgramName, String accountId, String programCaseId, String eLetterId, String baseExtractDRName
    *********************************************************************************************************************/
    public static Map<String,Object> generateDocumentFromIP(String sourceRecordId, String targetRecordId, String engagementProgramName, String accountId, String programCaseId, String eLetterId, String ipProcedureName, String baseExtractDataRaptorName){
        
        Map<String,Object> ipInput      = new Map<String,Object>();
        Map<String,Object> ipOutput     = new Map<String,Object>();
        Map<String,Object> ipOptions    = new Map<String,Object>();

        ipInput.put(ACLS_Constants.OMNISTUDIO_IP_SOURCE_RECORD_ID,sourceRecordId);
        ipInput.put(ACLS_Constants.OMNISTUDIO_IP_TARGET_RECORD_ID,targetRecordId);
        ipInput.put(ACLS_Constants.OMNISTUDIO_IP_ELETTER_ID,eLetterId);
        ipInput.put(ACLS_Constants.OMNISTUDIO_IP_EXTRACT_RAPTOR,baseExtractDataRaptorName);
        ipInput.put(ACLS_Constants.OMNISTUDIO_IP_EP_NAME,engagementProgramName);
        ipInput.put(ACLS_Constants.OMNISTUDIO_IP_ACCOUNT_ID,accountId);
        ipInput.put(ACLS_Constants.OMNISTUDIO_IP_PROGRAM_CASE_ID,programCaseId);

        ipOutput = (Map<String,Object>)omnistudio.IntegrationProcedureService.runIntegrationService(ipProcedureName,ipInput,ipOptions);
        System.debug('ipOutput '+ipOutput);

        return ipOutput;
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
                getExtractDR(inputMap,outMap,options);  
            }else if(methodName.equalsIgnoreCase(ACLS_Constants.OMNISTUDIO_IP_GET_TRANSFORM_DR)){
                getTransfromDR(inputMap,outMap,options);
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
    *********************************************************************************************************************/    
    public void getExtractDR(Map<String,object> inputMap, Map<String,object> outMap,Map<String,object> options){
        
        String extractDataRaptor        = (String)inputMap.get(ACLS_Constants.OMNISTUDIO_IP_EXTRACT_RAPTOR);
        String sourceRecordId           = (String)inputMap.get(ACLS_Constants.OMNISTUDIO_IP_SOURCE_RECORD_ID);
        String eLetterId                = (String)inputMap.get(ACLS_Constants.OMNISTUDIO_IP_ELETTER_ID);
        String objectId                 = (String)inputMap.get(ACLS_Constants.OMNISTUDIO_IP_TARGET_RECORD_ID);
        String engagementProgramName    = (String)inputMap.get(ACLS_Constants.OMNISTUDIO_IP_EP_NAME);
        String accountId                = (String)inputMap.get(ACLS_Constants.OMNISTUDIO_IP_ACCOUNT_ID);
        String programCaseId            = (String)inputMap.get(ACLS_Constants.OMNISTUDIO_IP_PROGRAM_CASE_ID);

        Map<String,object> extractDataMap = new Map<String,object>{ACLS_Constants.OMNISTUDIO_IP_ELETTER_ID=>eLetterId,ACLS_Constants.OMNISTUDIO_IP_SOURCE_RECORD_ID=>sourceRecordId,ACLS_Constants.OMNISTUDIO_IP_TARGET_RECORD_ID=>objectId,ACLS_Constants.OMNISTUDIO_IP_EP_NAME=>engagementProgramName,ACLS_Constants.OMNISTUDIO_IP_ACCOUNT_ID=>accountId,ACLS_Constants.OMNISTUDIO_IP_PROGRAM_CASE_ID=>programCaseId}; 
        omnistudio.DRProcessResult resultOutput = omnistudio.DRGlobal.process(extractDataMap, extractDataRaptor); 
        
        List<Map<String, Object>> extractDRResult = (List<Map<String, Object>>)resultOutput.toJsonList();
        outMap.put(ACLS_Constants.OMNISTUDIO_IP_EXTRACT_DR_RESULT,extractDRResult);

        System.debug('extractDRResult->'+outMap);
    }

    /********************************************************************************************************************
    Method Name    : getTransfromDR
    Author         : Deloitte
    Description    : method to invoke the transform data raptor for the remoteAction element used in IntegrationProcedure
    Return Type    : void
    Parameter      : Map<String,object> inputMap, Map<String,object> outMap,Map<String,object> options
    *********************************************************************************************************************/
    public void getTransfromDR(Map<String,object> inputMap, Map<String,object> outMap,Map<String,object> options){
        

        String transformDataRaptor = (String)inputMap.get(ACLS_Constants.OMNISTUDIO_IP_TRANSFORM_RAPTOR);
        List<Map<String,object>> transformDataMap = new List<Map<String,object>>();
        transformDataMap = (List<Map<String,object>>)inputMap.get(ACLS_Constants.OMNISTUDIO_IP_EXTRACT_DR_OUTPUTMAP);

        omnistudio.DRProcessResult resultOutput = omnistudio.DRGlobal.process(transformDataMap, transformDataRaptor); 
        
        List<Map<String, Object>> transformDRResult = (List<Map<String, Object>>)resultOutput.toJsonList();
        outMap.put(ACLS_Constants.OMNISTUDIO_IP_TRANSFORM_DR_RESULT,transformDRResult);

        System.debug('transformDRResult->'+transformDRResult);
    }
}