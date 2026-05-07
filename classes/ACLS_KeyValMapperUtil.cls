/*********************************************************************************
Class Name      : ACLS_KeyValMapperUtil
Description     : Utility class for Key Value Metadata
Created By      : Deloitte
Created Date    : 29-Mar-2023

Modification Log:
---------------------------------------------------------------------------------
Developer                Date                   Description
---------------------------------------------------------------------------------
Deloitte                 29-Mar-2023            Initial Version
*********************************************************************************/
public with sharing class ACLS_KeyValMapperUtil {
    
    //Constants for the Type values to be used
    public static final String CONFIG_1 = 'Config 1';
    
   	
    public static Map<String,Map<String,String>> keyValueMap = new Map<String,Map<String,String>>();

    /**************************************************************************************
    Method Name     : getValue
    Description     : Returns a Value for a specific Key
    Input Args      : String apiName
    Returns         : String
    Author          : Deloitte
    ******************************************************************************************/
    public static String getValue(String apiName){
        String returnVal ;
        ACLS_KeyValue__mdt keyVal = ACLS_KeyValue__mdt.getInstance(apiName);
        returnVal = keyVal.ACLS_Value__c;        
        return returnVal;
    }    
    
    /**************************************************************************************
    Method Name     : getValue
    Description     : Returns a Value for a specific Key
    Input Args      : String key, String keyType
    Returns         : String
    Author          : Deloitte
    ******************************************************************************************/ 
    public static String getValue(String key, String keyType){
        String returnVal;
        if(String.isNotBlank(keyType) 
           && !keyValueMap?.containsKey(keyType)){
               Map<String,String> keyValMap = new Map<String,String>();
               if(Schema.sObjectType.ACLS_KeyValue__mdt.isAccessible()){
               for(ACLS_KeyValue__mdt keyVal : [SELECT Id, 
                                               ACLS_Key__c, 
                                               ACLS_Value__c, 
                                               ACLS_Type__c 
                                               FROM 
                                               ACLS_KeyValue__mdt 
                                               WHERE 
                                               ACLS_Type__c = :keyType]){
                                                   keyValMap.put(keyVal.ACLS_Key__c,keyVal.ACLS_Value__c);
                                               }
               keyValueMap.put(keyType,keyValMap);
           }     
        }
        
        returnVal = keyValueMap?.get(keyType)?.get(key); 
        return returnVal; 
    }
    
    /**************************************************************************************
    Method Name     : getEPCodeValue
    Description     : Returns a Value for a specific Key and EPCode
    Input Args      : String key, String keyType
    Returns         : String
    Author          : Deloitte
    ******************************************************************************************/ 
    public static String getEPCodeValue(String key, String keyType, String EPCode) {
        String returnVal;     
        if(keyValueMap == null || keyValueMap.isEmpty()){
           String mapKey;
           Map<String,String> keyValMap = new Map<String,String>();
           if(Schema.sObjectType.ACLS_KeyValue__mdt.isAccessible()){
           for(ACLS_KeyValue__mdt keyVal : [SELECT Id, 
                                                   ACLS_Key__c, 
                                                   ACLS_Value__c, 
                                                   ACLS_Type__c,
                                                   ACLS_EPCODE__c
                                                   FROM 
                                                   ACLS_KeyValue__mdt 
                                                   WHERE 
                                                   ACLS_Type__c = :keyType
                                                  ]){
                                                     mapKey = '';
                                                     mapKey +=  String.isBlank(keyVal.ACLS_EPCODE__c) ? '' : (keyVal.ACLS_EPCODE__c + '||');
                                                     mapKey +=  keyVal.ACLS_Key__c;
                                                     keyValMap.put(mapKey,keyVal.ACLS_Value__c);
                                                   }
                   keyValueMap.put(keyType,keyValMap); 
        }
    }
        returnVal = keyValueMap?.get(keyType)?.get(EPCode.trim()+'||'+key);
        if(String.isBlank(returnVal)){
            returnVal = keyValueMap?.get(keyType)?.get(key);
        }
        return returnVal;
    }
    
    /**************************************************************************************
    Method Name     : getKeyValueMap
    Description     : Returns a Value for a specific Key and EPCode
    Input Args      : String key, String keyType
    Returns         : String
    Author          : Deloitte
    ******************************************************************************************/ 
    public static Map<String,String> getKeyValueMap(String keyType, String EPCode) {
        Map<String,String> keyValMap = new Map<String,String>();
        if(Schema.sObjectType.ACLS_KeyValue__mdt.isAccessible()){
            for(ACLS_KeyValue__mdt keyVal : [SELECT Id, 
                                            ACLS_Key__c, 
                                            ACLS_Value__c, 
                                            ACLS_Type__c,
                                            ACLS_EPCODE__c
                                            FROM 
                                            ACLS_KeyValue__mdt 
                                            WHERE 
                                            ACLS_Type__c = :keyType
                                            AND
                                            ACLS_EPCODE__c = :EPCode
                                        ]){
                                            keyValMap.put(keyVal.ACLS_Key__c,keyVal.ACLS_Value__c);
                                        }
                                        }
       return keyValMap;
    }
}