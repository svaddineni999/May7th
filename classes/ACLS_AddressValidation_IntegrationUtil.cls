/****************************************************************************************************************
Class Name    	: ACLS_AddressValidation_IntegrationUtil
Description     : Utility class for MelissaAddressVerification callouts
Created By      : Deloitte
Created Date    : Apr 9, 2023
*****************************************************************************************************************/
public with sharing class ACLS_AddressValidation_IntegrationUtil {
    /**********************************************************************************************************
	Method Name    : getValidatedAddress 
	Author         : Deloitte
	Description    : This method is used to get the validated address from the melissa callout api
	Return Type    : Map<String, Object>
	**********************************************************************************************************/
    //HttpResponse res = new HttpResponse();
    @testvisible private static HttpResponse res;
    List<PC_Remote_Service_Log__c> lstRemoteServiceLogs;
    public static final String CLASS_ACLS_AddressValidation_IntegrationUtil = 'ACLS_AddressValidation_IntegrationUtil';
    public Map<String, Object> getValidatedAddress(String a1,String a2,String city,String state,String postal,String country){
        String endPoint;
        String ipName;
        Map<String, String> mapHeader = new Map<String, String>();
        Map<String, Object> fields = new Map<String, Object>();
        ACLS_IntegrationConfig__mdt melissaTokenDetails = ACLS_Utility.getIntegrationConfigs(ACLS_Constants.MELISSA_ADDRESS, ACLS_Utility.getCurrentEnvironment());
        
        if(melissaTokenDetails != null){
         mapHeader = (Map<String,String>) JSON.deserialize(melissaTokenDetails.ACLS_Headers__c, Map<String,String>.class); 
            
        endPoint=melissaTokenDetails.ACLS_Endpoint__c;
            ipName=melissaTokenDetails.ACLS_Integration_Procedure_Name__c;
        
            
        if(a1!=null){
            a1=a1.replaceAll('\\s+', '%20');
            endPoint=endPoint+'a1='+a1;
        }
        if(a2!=null){
            a2=a2.replaceAll('\\s+', '%20');
            endPoint=endPoint+'&a2='+a2;
        }
        if(city!=null){
            city=city.replaceAll('\\s+', '%20');
            endPoint=endPoint+'&city='+city;
        }
        if(state!=null){
            state=state.replaceAll('\\s+', '%20');
            endPoint=endPoint+'&state='+state;
        }
        if(postal!=null){
            postal=postal.replaceAll('\\s+', '%20');
            endPoint=endPoint+'&postal='+postal;
        }
        
        
        System.debug('endpoint '+endPoint);
        //HttpResponse res = ACLS_Http_RequestResponse_Util.handleHTTPCallouts(ACLS_Constants.METHOD_GET, mapHeader, endPoint, null, Integer.valueOf(melissaTokenDetails.ACLS_Timeout__c), null);
        
            //HttpResponse res = new HttpResponse();
        if(!Test.isRunningTest()) {
         res = ACLS_IP_Callouts_Utility.makeCalloutFromIP(endPoint,'',mapHeader,'', 120000,ipName);
            System.debug('res '+res);
        }
       
        createRemoteServiceLog('', endpoint, res);

            
        ACLS_AddressValidationWrapper responseDetails = new ACLS_AddressValidationWrapper();
            
        if(res!=null && (res.getStatusCode() == 200 || res.getStatusCode() == 202 || res.getStatusCode() == 204) && res.getBody()!=null){
            responseDetails = (ACLS_AddressValidationWrapper)JSON.deserialize(res.getBody(),ACLS_AddressValidationWrapper.class);
           
        }
        system.debug('responseDetails '+responseDetails);
        
        if(responseDetails.Records != null && !responseDetails.Records.isEmpty()){
            fields.put('PC_Address_1__c', responseDetails.Records[0].AddressLine1);
            fields.put('PC_Address_2__c', responseDetails.Records[0].AddressLine2);
            fields.put('PC_City__c', responseDetails.Records[0].City);
            fields.put('PC_State__c', responseDetails.Records[0].State);
            fields.put('PC_Country__c', country);
            fields.put('ACLS_Verification_Status__c', '');
            fields.put('PC_Primary_Address__c', '');
            fields.put('PC_Zip_Code__c', responseDetails.Records[0].PostalCode.substringBefore('-'));
            fields.put('ACLS_Zip_Code_Extension__c', responseDetails.Records[0].PostalCode.substringAfter('-'));
            fields.put('ACLS_Address_Codes__c', responseDetails.Records[0].Results);
        }
        
        
        System.debug('fields '+fields);
        
        
    }else{
            ACLS_Utility.createINTErrorLogs(null, ACLS_Constants.Add_ERRORLOG1, '', ACLS_Constants.Add_ERRORLOG2 + '\n', '',CLASS_ACLS_AddressValidation_IntegrationUtil, '', '');
            return null;
        }
        
        return fields;
    }
    /********************************************************************************************************************
    Method Name    : createRemoteServiceLog
    Description    : Create instance of Remote service logs
    Return Type    : void
    Parameter      :  String endPoint, HttpResponse res
    *********************************************************************************************************************/
    public void createRemoteServiceLog(String RequestBody, String endPoint, HttpResponse res){
        PC_Remote_Service_Log__c addValRSL = PC_RemoteServiceLogHandler.getRemoteServiceLog(ACLS_Constants.MELISSA_ADDRESS, endPoint, '', res?.getBody(), 'Callout made for validation of address', PC_Constants.REMOTE_SERVICE_TYPE_OUTBOUND);
        addValRSL.PC_StatusCode__c = (res!=null)? String.valueOf(res.getStatusCode()) : '';
        
        if(Schema.sObjectType.PC_Remote_Service_Log__c.isCreateable()){
				PC_Database.ins(addValRSL);
            }
    }
}