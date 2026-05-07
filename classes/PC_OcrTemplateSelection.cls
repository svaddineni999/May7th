/**
 * Created by sathekumar on 10/27/2021.
 */

public with sharing class PC_OcrTemplateSelection {

    @AuraEnabled
    public static TemplateSelectionResponse getOcrTemplateOptions(String templateSelectionRequestString){
        TemplateSelectionResponse optionsToReturn = new TemplateSelectionResponse();
        TemplateSelectionRequest request = new TemplateSelectionRequest();
        List<String> selectedCategoryListAfterRemovingInvalid = new List<String>();
        List<String> validCategoryList = new List<String>();
        List<String> availableCategory = new List<String>();
        List<TemplateCategory> templateCategories = new List<TemplateCategory>();
        try{
            request = (TemplateSelectionRequest) System.JSON.deserialize(templateSelectionRequestString, TemplateSelectionRequest.class);
            if (request != null && (request.categoryList).size() > 0) {
                selectedCategoryListAfterRemovingInvalid = checkAndRemoveInvalidCategory(request.categoryList);
            }
            if(String.isNotBlank(request.engagementProgram)) {
                templateCategories = getDependentCategoryValues(getTemplateTypes(request.engagementProgram, new List<String>()));
            } else {
                templateCategories = getTemplateCategoryValues();
            }
            for (TemplateCategory tc : templateCategories) {
                availableCategory.add(tc.value);
            }
            for (String category : selectedCategoryListAfterRemovingInvalid) {
                if(availableCategory.contains(category)){
                    validCategoryList.add(category);
                }
            }
            optionsToReturn.templateTypeList = getTemplateTypes(request.engagementProgram, validCategoryList);
            optionsToReturn.templateCategoryList = templateCategories;
            optionsToReturn.engagementProgramList = getEngagementPrograms();
        } catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return optionsToReturn;
    }

    @AuraEnabled
    public static TemplateSelectionResponse getOcrTemplateTypeAndCategoryOptions(String templateSelectionRequestString){
        TemplateSelectionResponse optionsToReturn = new TemplateSelectionResponse();
        TemplateSelectionRequest request = new TemplateSelectionRequest();
        List<String> validCategory = new List<String>();
        try{
            request = (TemplateSelectionRequest) System.JSON.deserialize(templateSelectionRequestString, TemplateSelectionRequest.class);
            if((request.categoryList).size() > 0) {
                validCategory = checkAndRemoveInvalidCategory(request.categoryList);
            }
            optionsToReturn.templateTypeList = getTemplateTypes(request.engagementProgram, validCategory);
            optionsToReturn.templateCategoryList = (String.isNotBlank(request.engagementProgram) ? getDependentCategoryValues(getTemplateTypes(request.engagementProgram, new List<String>())) : getTemplateCategoryValues());
        } catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return optionsToReturn;
    }

    @AuraEnabled
    public static TemplateSelectionResponse getOcrTemplateTypeOptions(String templateSelectionRequestString){
        TemplateSelectionResponse optionsToReturn = new TemplateSelectionResponse();
        TemplateSelectionRequest request = new TemplateSelectionRequest();
        try{
            request = (TemplateSelectionRequest) System.JSON.deserialize(templateSelectionRequestString, TemplateSelectionRequest.class);
            optionsToReturn.templateTypeList = getTemplateTypes(request.engagementProgram, request.categoryList);
        } catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return optionsToReturn;
    }

    public static List<TemplateCategory> getDependentCategoryValues(List<TemplateTypeSetting> templateTypeList){
        List<TemplateCategory> templateCategoriesToReturn = new  List<TemplateCategory>();
        List<TemplateCategory> templateCategories = new  List<TemplateCategory>();
        Map<String, TemplateCategory> templateCategoryMap = new Map<String, TemplateCategory>();
        Set<String> categoryValues = new Set<String>();
        List<String> categoryList = new List<String>();
        try{
            templateCategories = getTemplateCategoryValues();
            for(TemplateCategory tc : templateCategories)
            {
                templateCategoryMap.put(tc.value, tc);
            }
            for(TemplateTypeSetting tts: templateTypeList){
                if(String.isNotBlank(tts.category)){
                    List<String> values = (tts.category).split(';');
                    categoryValues.addAll(values);
                }
            }
            categoryList = (new List<String>(categoryValues));
            categoryList.sort();
            for(String category : categoryList){
                if(templateCategoryMap.containsKey(category)) {
                    templateCategoriesToReturn.add(templateCategoryMap.get(category));
                }
            }
        } catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return templateCategoriesToReturn;
    }

    public static List<String> checkAndRemoveInvalidCategory(List<String> categoryList){
        List<String> validCategoryList = new List<String>();
        List<TemplateCategory> templateCategories = new List<TemplateCategory>();
        try {
            templateCategories = getTemplateCategoryValues();
            List<String> templateCategoryList = new List<String>();
            for (TemplateCategory tc : templateCategories) {
                templateCategoryList.add(tc.value);
            }
            for (String category : categoryList) {
                if (templateCategoryList.contains(category)) {
                    validCategoryList.add(category);
                }
            }
        } catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return validCategoryList;
    }

    public static List<TemplateTypeSetting> getTemplateTypes(String engagementProgram, List<String> categoryList){
        List<TemplateTypeSetting> templateTypeSettings = new List<TemplateTypeSetting>();
        List<PC_EngagementProgram_OcrTemplateType__c> engagementProgramTemplateTypeList = new List<PC_EngagementProgram_OcrTemplateType__c>();
        List<String> whereConditions = new List<String>();
        List<String> selectedCategory = new List<String>();
        String queryString, whereConditionString = PC_Constants.EMPTY_STRING;
        try{
            if (String.isNotBlank(engagementProgram)) {
                //whereConditions.add('PC_EngagementProgram__r.PC_Program_Code__c = \''+ engagementProgram +'\'');
                whereConditions.add('PC_EngagementProgram__c = \''+ engagementProgram +'\'');
                if (categoryList.size() > 0) {
                    for (String category : categoryList) {
                        selectedCategory.add('\'' + String.escapeSingleQuotes(category) + '\'');
                    }
                    whereConditions.add('PC_OcrTemplateType__r.PC_Category__c INCLUDES (' + String.join(selectedCategory, ',') + ')');
                }
                whereConditions.add('PC_OcrTemplateType__r.PC_IsActive__c = true');
                whereConditionString = String.join(whereConditions, ' AND ');
                if (String.isNotBlank(whereConditionString)) {
                    whereConditionString = 'WHERE ' + whereConditionString + ' ORDER BY PC_OcrTemplateType__r.PC_Label__c ASC';
                }
                queryString = 'SELECT Id, PC_EngagementProgram__c, PC_OcrTemplateType__r.PC_IsActive__c, PC_OcrTemplateType__r.Name, PC_OcrTemplateType__r.PC_Description__c,' +
                        'PC_OcrTemplateType__r.PC_Label__c, PC_OcrTemplateType__r.Id, PC_OcrTemplateType__r.PC_APIName__c,  PC_OcrTemplateType__r.PC_Category__c ' +
                        'FROM PC_EngagementProgram_OcrTemplateType__c ' + whereConditionString;
                system.debug('queryString--->' + queryString);
                engagementProgramTemplateTypeList = database.query(queryString);

                for (PC_EngagementProgram_OcrTemplateType__c engPgmTemplateType : engagementProgramTemplateTypeList) {
                    templateTypeSettings.add(new TemplateTypeSetting(engPgmTemplateType.PC_OcrTemplateType__r));
                }
            } else {
                // FLS Check PC_OcrTemplateType__c
                List<String> ocrTemplateTypeFields = new List<String>{PC_Constants.getQualifiedAPIName('PC_IsActive__c'), PC_Constants.getQualifiedAPIName('PC_Label__c'), PC_Constants.getQualifiedAPIName('PC_Category__c'), PC_Constants.getQualifiedAPIName('PC_APIName__c'), PC_Constants.getQualifiedAPIName('PC_Description__c'), PC_Constants.getQualifiedAPIName('PC_CreateResultsAfterOCRCompletion__c')};
                PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_OcrTemplateType__c'), PC_Database.Operation.Reading, ocrTemplateTypeFields);
                //Getting all OCR Template Types
                if (categoryList.size() > 0) {
                    for (String category : categoryList) {
                        selectedCategory.add('\'' + String.escapeSingleQuotes(category) + '\'');
                    }
                    whereConditions.add('PC_Category__c INCLUDES (' + String.join(selectedCategory, ',') + ')');
                }
                whereConditions.add('PC_IsActive__c = true');
                whereConditionString = String.join(whereConditions, ' AND ');
                if (String.isNotBlank(whereConditionString)) {
                    whereConditionString = 'WHERE ' + whereConditionString + ' ORDER BY Name ASC';
                }
                queryString = 'SELECT Id, Name, PC_IsActive__c, PC_Label__c, PC_APIName__c, PC_Category__c, PC_Description__c, PC_CreateResultsAfterOCRCompletion__c ' +
                        'FROM PC_OcrTemplateType__c ' + whereConditionString;
                List<PC_OcrTemplateType__c> templateTypeList = database.query(queryString);
                for (PC_OcrTemplateType__c templateType : templateTypeList) {
                    templateTypeSettings.add(new TemplateTypeSetting(templateType));
                }
            }
        }  catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return templateTypeSettings;
    }

    public static List<TemplateCategory> getTemplateCategoryValues(){
        TemplateCategory templateCategoryObj ;
        List<TemplateCategory> templateCategoryList = new List<TemplateCategory>();
        Schema.DescribeFieldResult picklistFieldResult = PC_OcrTemplateType__c.PC_Category__c.getDescribe();
        List<Schema.PicklistEntry> picklistValueList = picklistFieldResult.getPicklistValues();
        for (Schema.PicklistEntry picklistValue : picklistValueList) {
            templateCategoryObj = new TemplateCategory();
            templateCategoryObj.label = picklistValue.getLabel();
            templateCategoryObj.value = picklistValue.getValue();
            templateCategoryList.add(templateCategoryObj);
        }
        return templateCategoryList;
    }

    public static List<EngProgramWrapper> getEngagementPrograms() {
        List<EngProgramWrapper> lstEngProgram = new List<EngProgramWrapper>();
        List<String> epFields = new List<String> {'Name',PC_Constants.getQualifiedAPIName('PC_Manufacturer__c'),PC_Constants.getQualifiedAPIName('PC_Active__c')};
        PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Engagement_Program__c'), PC_Database.Operation.Reading, epFields);
        List<String> accountFields = new List<String>{'Name'};
        PC_Database.assertAccess(PC_Constants.PC_ACCOUNT, PC_Database.Operation.Reading, accountFields);
        List<PC_Engagement_Program__c> lstEp = [
                SELECT Id, PC_Manufacturer__c, PC_Manufacturer__r.Name, Name
                FROM PC_Engagement_Program__c
                WHERE PC_Active__c = true ORDER BY Name ASC
                LIMIT 100
        ];
        if (lstEp != null && lstEp.size() > 0) {
            for (PC_Engagement_Program__c a : lstEp) {
                lstEngProgram.add(new EngProgramWrapper(a));
            }
        }
        return lstEngProgram;
    }

    @AuraEnabled
    public static void validateTemplateMapping(String templateTypeId) {
        List<PC_OcrTemplateMapping__c> templateMappings = getOcrTemplateMapping(templateTypeId);
        if (templateMappings.size() == 0) {
            throw new AuraHandledException(System.label.PC_NoActiveMappingsForSelectedTemplate);
        }
    }

    public static List<PC_OcrTemplateMapping__c> getOcrTemplateMapping(String templateTypeId) {
        List<PC_OcrTemplateMapping__c> templateMappings = new List<PC_OcrTemplateMapping__c>();
        try {
            templateMappings = [SELECT Id, PC_OcrTemplateType__c, PC_TargetObject__c, PC_IsActive__c FROM PC_OcrTemplateMapping__c WHERE PC_IsActive__c = true AND PC_OcrTemplateType__c = :templateTypeId];
        } catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return templateMappings;
    }

    public inherited sharing class TemplateSelectionRequest{
        @AuraEnabled
        public List<String> categoryList{get;set;}
        @AuraEnabled
        public String engagementProgram{get;set;}

        public TemplateSelectionRequest(){
            categoryList = new List<String>();
            engagementProgram = PC_Constants.EMPTY_STRING;
        }
    }

    public inherited sharing class TemplateSelectionResponse{
        @AuraEnabled
        public List<TemplateCategory> templateCategoryList{get;set;}
        @AuraEnabled
        public List<TemplateTypeSetting> templateTypeList{get;set;}
        @AuraEnabled
        public List<EngProgramWrapper> engagementProgramList{get;set;}

        public TemplateSelectionResponse(){
            templateCategoryList = new List<TemplateCategory>();
            templateTypeList = new List<TemplateTypeSetting>();
            engagementProgramList = new List<EngProgramWrapper>();
        }
    }

    public inherited sharing class TemplateCategory {
        @AuraEnabled
        public String label { get; set; }
        @AuraEnabled
        public String value { get; set; }
        @AuraEnabled
        public String selected { get; set; }
    }

    public inherited sharing class TemplateTypeSetting {
        @AuraEnabled
        public String label { get; set; }
        @AuraEnabled
        public String value { get; set; }
        @AuraEnabled
        public String description { get; set; }
        @AuraEnabled
        public String category { get; set; }
        @AuraEnabled
        public Boolean createResultsImmediately { get; set; }
        public TemplateTypeSetting(){
            label = PC_Constants.EMPTY_STRING;
            value = PC_Constants.EMPTY_STRING;
            description = PC_Constants.EMPTY_STRING;
            category = PC_Constants.EMPTY_STRING;
            //createResultsImmediately = PC_Constants.FALSE_BOOLEAN;
        }

        public TemplateTypeSetting(PC_OcrTemplateType__c templateType){
            label = templateType.Name;
            value = templateType.Id;
            description = templateType.PC_Description__c;
            category = templateType.PC_Category__c;
            //createResultsImmediately = templateType.PC_CreateResultsAfterOCRCompletion__c;
        }
    }

    public inherited sharing class EngProgramWrapper {
        @AuraEnabled public Id programId {get;set;}
        @AuraEnabled public String programName {get; set;}
        @AuraEnabled public String manufacturerName {get; set;}

        public EngProgramWrapper(PC_Engagement_Program__c pgm) {
            programId = pgm.Id;
            programName = pgm.Name;
            manufacturerName = pgm.PC_Manufacturer__r.Name;
        }
    }

}