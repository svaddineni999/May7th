/**********************************************************************************************************
Class Name    	: PC_RestAPISpecController
Description     : Controller for PC_RestAPISpec VF page that augments the swagger spec stored in the
RestAPIJsonSpec static resource with custom field mapping information.
Created By      : Deloitte
Created Date    : 2017-08-23
Modification Log:
-----------------------------------------------------------------------------------------------------------
Developer          Date                   Description
-----------------------------------------------------------------------------------------------------------
Mike Klumpenaar    2017-08-23             Initial Version
Vijay Kashikar     2017-12-08             Updated to dynamically add custom metadata relationships
Vijay Kashikar     2019-04-01             [PC-2689] Updated to dynamically replace the namespace placeholder
**********************************************************************************************************/
public with sharing class PC_RestAPISpecController {
    public String restApiJsonSpec {
        get {
            
            StaticResource sr = [select Body from StaticResource where Name = 'PC_RestAPISpec10' ];
            Map<String, Object> openAPI = (Map<String, Object>) JSON.deserializeUntyped(sr.Body.toString());
            updateBasePath(openAPI);
            String host = ApexPages.currentPage().getHeaders().get('Host');
            String tokenUrl = 'https://' + host + '/services/oauth2/token';
            Map<String, Object> securityDefinitions = (Map<String, Object>) openAPI.get('securityDefinitions');
            Map<String, Object> passwordDef = (Map<String, Object>) securityDefinitions.get('password');
            passwordDef.put('tokenUrl', tokenUrl);
            
            openAPI.put('host', host);
            
            Map<String, Object> definitions =  (Map<String, Object>) openAPI.get('definitions');
            try{
                /* Start - Dynamically add objects from relationship mappings */
                List<PC_REST_Object_Relationship_Mapping__mdt> relationshipMappings = PC_RestAPIUtilities.getAllRESTRelationshipMappings();
                for(PC_REST_Object_Relationship_Mapping__mdt relationshipMap : relationshipMappings) {
                    // In the below line, just remove the hardcoded conditional check so as to make it generic
                    if(definitions.containsKey(relationshipMap.PC_Parent_REST_Object_Name__c) && relationshipMap.PC_Parent_REST_Object_Name__c == 'Patient') {
                        //Map<String, Object> restObject = (Map<String, Object>) definitions.get(relationshipMap.PC_Parent_REST_Object_Name__c);
                        // To make it generic, comment out the below line and uncomment the above line.
                        Map<String, Object> restObject = (Map<String, Object>) definitions.get('PatientWithAllRelatedObjects');
                        Map<String, Object> restObjectProperties;
                        String newProperty = '{"items": {"$ref": "#/definitions/' + relationshipMap.PC_Child_REST_Object_Name__c + '"},"type": "array"}';
                        Object newProperty_AsJSON = JSON.deserializeUntyped(newProperty);
                        system.debug(JSON.serialize(restObject));
                        if(restObject.containsKey('allOf')) {
                            List<Object> allOf = new List<Object>();
                            allof = (List<Object>) restObject.get('allOf');
                            boolean allOfHasProperties = false;
                            Map<String, Object> allOfItem_AsMap;
                            for(Object allOfItem : allOf){
                                allOfItem_AsMap = (Map<String, Object>) allOfItem;
                                if(allOfItem_AsMap.containsKey('properties')) {
                                    // tested
                                    allOfHasProperties = true;
                                    restObjectProperties = (Map<String, Object>) allOfItem_AsMap.get('properties');
                                    break;
                                }
                            }
                            if(allOfHasProperties) {
                                //tested
                            }
                            else {
                                // tested
                                Map<String, Object> property = new Map<String, Object>();
                                property.put('properties', new Map<String, Object>());
                                allOf.add(property);
                                for(Object allOfItem : allOf) {
                                    allOfItem_AsMap = (Map<String, Object>) allOfItem;
                                    if(allOfItem_AsMap.containsKey('properties')) {
                                        restObjectProperties = (Map<String, Object>) allOfItem_AsMap.get('properties');
                                        break;
                                    }
                                }
                                
                            }
                            if(restObjectProperties != null) {
                                // tested
                                system.debug(JSON.serialize(restObjectProperties));
                                restObjectProperties.put(relationshipMap.PC_Rest_Object_Field_Name__c, newProperty_AsJSON);
                            }
                            
                        }
                        else {
                            if(restObject.containsKey('properties')) {
                                restObjectProperties = (Map<String, Object>) restObject.get('properties');
                                restObject.put('properties', newProperty_AsJSON);
                            }
                        }
                    }
                    
                }
                /* End - Dynamically add objects from relationship mappings */
                
                /* start - dynamically add field mappings on other sobjects */
                Map<String, Object> otherDefinitions = new Map<String, Object>();
                Map<String, String> propertyType = new Map<String, String>();
                propertyType.put('type','string');
                Map<String, Object> property = new Map<String, Object>();
                Map<String, Object> currentDefinitionNode;
                Map<String, Object> currentDefinitionNode_Properties= new Map<String, Object>();
                for(PC_REST_Field_Mapping__mdt fieldMapping : PC_RestAPIUtilities.getRESTFieldMappings('other')) {
                    currentDefinitionNode =  new Map<String, Object>();
                    if(otherDefinitions.containsKey(fieldMapping.PC_Other_REST_Object_Name__c)) {
                        currentDefinitionNode = (Map<String, Object>) otherDefinitions.get(fieldMapping.PC_Other_REST_Object_Name__c);
                        currentDefinitionNode_Properties = (Map<String, Object>) currentDefinitionNode.get('properties');
                        currentDefinitionNode_Properties.put(fieldMapping.PC_REST_Field_Name__c, propertyType);
                    }
                    else {
                        otherDefinitions.put(fieldMapping.PC_Other_REST_Object_Name__c,currentDefinitionNode);
                        
                        currentDefinitionNode = (Map<String, Object>) otherDefinitions.get(fieldMapping.PC_Other_REST_Object_Name__c);
                        currentDefinitionNode.put('type', 'object');
                        
                        currentDefinitionNode.put('properties', new Map<String, Object>());
                        currentDefinitionNode_Properties = (Map<String, Object>) currentDefinitionNode.get('properties');
                        
                        currentDefinitionNode_Properties.put(fieldMapping.PC_REST_Field_Name__c, propertyType);
                        
                    }
                }
                
                system.debug('otherDefinitions');
                system.debug(JSON.serialize(otherDefinitions));
                definitions.putAll(otherDefinitions);
                system.debug('all Definitions');
                system.debug(JSON.serialize(definitions));
                
                /* end - dynamically add field mappings on other sobjects */
                for (String restObjectName : definitions.keySet()) {
                    Map<String, Object> objectDef = (Map<String, Object>) definitions.get(restObjectName);
                    Map<String, Object> properties = (Map<String, Object>) objectDef.get('properties');
                    
                    if (properties == null) {
                        List<Object> allOf = (List<Object>) objectDef.get('allOf');
                        
                        if (allOf != null && allOf.size() > 1) {
                            //TODO: confirm that this is always in second item in the list
                            Map<String, Object> allOfItem_AsMap;
                            for(Object allOfItem : allOf) {
                                allOfItem_AsMap = (Map<String, Object>) allOfItem;
                                system.debug(allOfItem_AsMap);
                                if(allOfItem_AsMap.containsKey('properties')) {
                                    objectDef = allOfItem_AsMap;
                                    properties = (Map<String, Object>) allOfItem_AsMap.get('properties');
                                    break;
                                }
                            }
                            //objectDef = (Map<String, Object>) allOf[1];
                            //properties = (Map<String, Object>) objectDef.get('properties');
                        }
                    }
                    
                    if (properties == null) {
                        continue;
                    }
                    
                    String normalizedRestObjectName = restObjectName.replace('#', '/');
                    List<PC_REST_Field_Mapping__mdt> fieldMappings = PC_RestAPIUtilities.getRESTFieldMappings(normalizedRestObjectName);
                    Map<String, SObjectField> sObjectFields;
                    
                    if (fieldMappings != null && fieldMappings.size() > 0) {
                        String sObjectName;
                        if(PC_RestAPIConstants.REST_OBJECT_TO_SOBJECT_MAPPING.get(normalizedRestObjectName) != null)
                        {
                            sObjectName = PC_RestAPIConstants.REST_OBJECT_TO_SOBJECT_MAPPING.get(normalizedRestObjectName);
                            sObjectName = PC_Constants.getQualifiedAPIName(sObjectName);
                        }
                        
                        if(string.isBlank(sObjectName))
                        {
                            sObjectName = fieldMappings[0].PC_Other_sObject_API_Name__c;
                        }
                        system.debug('sObjectName = ' + sObjectName);
                        DescribeSObjectResult objDef = Schema.getGlobalDescribe().get(sObjectName).getDescribe();
                        sObjectFields = objDef.fields.getMap();
                        
                        //TODO: allow addition of required fields based on field mapping metadata property
                        for (PC_REST_Field_Mapping__mdt fieldMapping : fieldMappings) {
                            String restFieldName = fieldMapping.PC_REST_Field_Name__c;
                            if(restFieldName.equalsIgnoreCase('other')) {
                                restFieldName = fieldMapping.PC_Other_REST_Object_Name__c;
                            }
                            
                            if (!properties.containsKey(restFieldName)) {
                                Map<String, Object> propertyDef = new Map<String, Object>();
                                
                                SObjectField sObjectField = sObjectFields.get(fieldMapping.PC_SObject_Field_Name__c);
                                
                                if (sObjectField != null) {
                                    DescribeFieldResult fieldResult = sObjectField.getDescribe();
                                    
                                    // Set type
                                    if (fieldResult.getType() == DisplayType.BOOLEAN) {
                                        propertyDef.put('type', 'boolean');
                                    } else {
                                        propertyDef.put('type', 'string');
                                    }
                                    
                                    // Set format
                                    if (fieldResult.getType() == DisplayType.DATE) {
                                        propertyDef.put('format', 'date');
                                    } else if (fieldResult.getType() == DisplayType.DATETIME) {
                                        propertyDef.put('format', 'date-time');
                                    }
                                    
                                    // Set required
                                    if (!fieldResult.isNillable()) {
                                        List<Object> requiredProperties = (List<Object>) objectDef.get('required');
                                        
                                        if (requiredProperties == null) {
                                            requiredProperties = new List<Object>{
                                                restFieldName
                                                    };
                                                        objectDef.put('required', requiredProperties);
                                        } else {
                                            requiredProperties.add(restFieldName);
                                        }
                                    }
                                } else {
                                    propertyDef.put('description', 'ERROR: Mapped to missing field ' + fieldMapping.PC_SObject_Field_Name__c);
                                }
                                
                                properties.put(restFieldName, propertyDef);
                            }
                        }
                    }
                }
            }
            catch (Exception e){
                PC_Utility.logAndThrowException(e);
            }
            return JSON.serialize(openAPI);
            
            
        }
    }

    private static void updateBasePath(Map<String, Object> openAPI) {
        final String BASE_PATH_KEY = 'basePath';
        if(openAPI != null && openAPI.containsKey(BASE_PATH_KEY)) {
            String basePathValue = (String) openAPI.get(BASE_PATH_KEY);
            if(String.isNotBlank(basePathValue)) {
                String orgNS = PC_Constants.OrgNamespace;
                String placeHolder = '/{PC_Namespace}/'; // This should match with the base path in PC_RestAPISpec10
                String newBasePathValue = basePathValue;
                if(String.isBlank(orgNS)) {
                    newBasePathValue = newBasePathValue.replace(placeHolder, '/');
                }
                else {
                    String placeHolderValue = '/' + orgNS + '/';
                    newBasePathValue = newBasePathValue.replace(placeHolder, placeHolderValue);
                }
                openAPI.remove(BASE_PATH_KEY);
                openAPI.put(BASE_PATH_KEY, newBasePathValue);
            }
        }
    }
}