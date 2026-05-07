/****************************************************************************************************************
Class Name    	: ACLS_AddressVerificationController
Description     : controller for MelissaAddressVerification callouts
Created By      : Deloitte
Created Date    : Apr 9, 2023
*****************************************************************************************************************/
public with sharing class ACLS_AddressValidationController {
    /*********************************************************************************
    Method Name    : verifyAddress
    Description    : Method to send melissa api callout request by capturing the parameters passed from aura
    Return Type    : Map<String, Object>
    *********************************************************************************/
 @AuraEnabled
    public static Map<String, Object> verifyAddress(String actuala1,String actuala2,String actualpostal,String actualstate,String actualcity,String actualcountry) {
        ACLS_AddressValidation_IntegrationUtil AddressVal = new ACLS_AddressValidation_IntegrationUtil();
        return AddressVal.getValidatedAddress(actuala1,actuala2,actualcity,actualstate,actualpostal,actualcountry);    
    }
    
    
}