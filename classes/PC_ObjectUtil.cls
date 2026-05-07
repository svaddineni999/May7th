public with sharing class PC_ObjectUtil {
    public static id recordTypeId(string objectAPIName, string recordTypeName) {
        if(String.isBlank(objectAPIName) || String.isBlank(recordTypeName)) {
            return null;
        }        
        
        Map<String, Schema.SObjectType> sobjectSchemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType sObjType = sobjectSchemaMap.get(objectAPIName);
        Schema.DescribeSObjectResult cfrSchema = sObjType.getDescribe() ;
        Map<String,Schema.RecordTypeInfo> RecordTypeInfo = cfrSchema.getRecordTypeInfosByName();
        Id recordTypeId = RecordTypeInfo.get(recordTypeName).getRecordTypeId();
        
        return recordTypeId;
    }
    
    public static string recordTypeName(string objectAPIName, string recordTypeName) {
        if(String.isBlank(objectAPIName) || String.isBlank(recordTypeName)){
            return null;
        }        
        
        Map<String, Schema.SObjectType> sobjectSchemaMap = Schema.getGlobalDescribe();

        Schema.SObjectType sObjType = sobjectSchemaMap.get(objectAPIName) ;
        Schema.DescribeSObjectResult cfrSchema = sObjType.getDescribe() ;
        Map<String,Schema.RecordTypeInfo> RecordTypeInfo = cfrSchema.getRecordTypeInfosByName();
        String rtName = RecordTypeInfo.get(recordTypeName).getName();
        return rtName;
    }
	
    public static string getMeRecordTypeId(string objectAPIName, string recordTypeName) {
        if(String.isBlank(objectAPIName) || String.isBlank(recordTypeName)){
            return null;
        }        
        Id devRecordTypeId = Schema.getGlobalDescribe().get(objectAPIName).getDescribe().getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId();
        return devRecordTypeId;                
    }    
}