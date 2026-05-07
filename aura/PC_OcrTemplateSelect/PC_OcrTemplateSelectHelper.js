/**
 * Created by sathekumar on 10/9/2021.
 */
({
    getTemplateSelectionOptions : function(component, event, helper){
        helper.showSpinner(component, event, helper);
        var action = component.get('c.getOcrTemplateOptions');
        var request = {
            categoryList : component.get('v.selectedCategory'),
            engagementProgram : component.get('v.engagementProgram')
        }
        action.setParams({
            templateSelectionRequestString: JSON.stringify(request)
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS'){
                var result = response.getReturnValue();
                if(!$A.util.isUndefined(result.engagementProgramList)) {
                    component.set('v.engagementProgramOptions', this.createEngagementProgramOptions(component, result.engagementProgramList));
                }
                if(!$A.util.isUndefined(result.templateTypeList)) {
                    component.set('v.templateTypeOptions', this.createTemplateTypeOptions(result.templateTypeList));
                    this.validateTemplateTypeOptions(component, event, helper);
                }
                if(!$A.util.isUndefined(result.templateCategoryList)) {
                    component.set('v.templateCategoryList', this.createTemplateCategoryOptions(component, result.templateCategoryList));
                }

                console.log(JSON.stringify(response.getReturnValue()));
            } else{
                console.log('Error');
                var errors = response.getError();
                CH_PC_Util.showAllErrors(component.get("v.errorStatus"),errors);
            }
            helper.hideSpinner(component, event, helper);
        });
        $A.enqueueAction(action);
    },

    validateTemplateTypeOptions : function(component, event, helper){
        if(component.get('v.templateTypeOptions').length == 0){
            component.set('v.templateTypeId', '');
        } else {
            var templateTypeOptions = component.get('v.templateTypeOptions');
            var templateTypeId = component.get('v.templateTypeId');
            templateTypeOptions
            const templateFound = templateTypeOptions.some(el => el.value === templateTypeId);
            if(!templateFound){
                component.set('v.templateTypeId', '');
            }
        }
    },

    refreshTemplateTypeAndCategoryOptions : function(component, event, helper){
        //helper.showSpinner(component, event, helper);
        component.set('v.isTemplateTypeLoading', true);
        var action = component.get('c.getOcrTemplateTypeAndCategoryOptions');
        var request = {
            categoryList : component.get('v.selectedCategory'),
            engagementProgram : component.get('v.engagementProgram')
        }
        action.setParams({
            templateSelectionRequestString: JSON.stringify(request)
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS'){
                var result = response.getReturnValue();
                if(!$A.util.isUndefined(result.templateTypeList)) {
                    component.set('v.templateTypeOptions', this.createTemplateTypeOptions(result.templateTypeList));
                    this.validateTemplateTypeOptions(component, event, helper);
                }
                if(!$A.util.isUndefined(result.templateCategoryList)) {
                    component.set('v.templateCategoryList', this.createTemplateCategoryOptions(component, result.templateCategoryList));
                }
            } else{
                console.log('Error');
                var errors = response.getError();
                CH_PC_Util.showAllErrors(component.get("v.errorStatus"),errors);
            }
            //helper.hideSpinner(component, event, helper);
            component.set('v.isTemplateTypeLoading', false);
        });
        $A.enqueueAction(action);
    },

    refreshTemplateTypeOptions : function(component, event, helper){
        //helper.showSpinner(component, event, helper);
        helper.disableCategory(component, event, helper);
        component.set('v.isTemplateTypeLoading', true);
        var action = component.get('c.getOcrTemplateTypeOptions');
        var request = {
            categoryList : component.get('v.selectedCategory'),
            engagementProgram : component.get('v.engagementProgram')
        }
        action.setParams({
            templateSelectionRequestString: JSON.stringify(request)
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS'){
                var result = response.getReturnValue();
                if(!$A.util.isUndefined(result.templateTypeList)) {
                    component.set('v.templateTypeOptions', this.createTemplateTypeOptions(result.templateTypeList));
                    this.validateTemplateTypeOptions(component, event, helper);
                }
            } else{
                console.log('Error');
                var errors = response.getError();
                CH_PC_Util.showAllErrors(component.get("v.errorStatus"),errors);
            }
            //helper.hideSpinner(component, event, helper);
            helper.enableCategory(component, event, helper);
            component.set('v.isTemplateTypeLoading', false);
        });
        $A.enqueueAction(action);
    },


    createEngagementProgramOptions : function(component, engagementProgramList) {
        var engNoneOption = [{
                              "label": component.get('v.picklistNone'),
                              "value": ''
                              }];
         var tempList = engagementProgramList.map(opt => ({ value: opt.programId, label: opt.programName, description: opt.manufacturerName}));
         return engNoneOption.concat(tempList);
    },

    createTemplateTypeOptions : function(templateTypeList){
        return templateTypeList.map(opt => ({ value: opt.value, label: opt.label, description: opt.description}));
    },

    createTemplateCategoryOptions : function(component, templateCategoryList){
        var selectedCategory = component.get('v.selectedCategory');
        var updatedCategoryList = [];
        var newSelectedCategory = [];
        templateCategoryList.forEach((category, index, array) => {
            if(selectedCategory.includes(category.value)){
                newSelectedCategory.push(category.value);
            }
            updatedCategoryList.push({ value: category.value, label: category.label, selected: selectedCategory.includes(category.value)});
        });
        component.set('v.selectedCategory', newSelectedCategory);
        return updatedCategoryList;
    },

    onTemplateTypeChange: function(component, event, helper) {
        helper.showSpinner(component, event, helper);
        var action = component.get('c.validateTemplateMapping');
        action.setParams({
            templateTypeId : component.get("v.templateTypeId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS'){
                if(component.find('templateType') != undefined) {
                    var templateTypeCmp = component.find("templateType");
                    templateTypeCmp.setCustomValidity('');
                    templateTypeCmp.reportValidity();
                }
            } else {
                var errors = response.getError();
                if (errors && errors[0] && errors[0].message) {
                    var error = errors[0].message;
                    if(component.find('templateType') != undefined) {
                        var templateTypeCmp = component.find("templateType");
                        templateTypeCmp.setCustomValidity(error);
                        templateTypeCmp.reportValidity();
                    }
                }
            }
            helper.hideSpinner(component, event, helper);
        });
        $A.enqueueAction(action);
    },

    showSpinner: function(component, event, helper) {
        component.set('v.showSpinner', true);
    },

    hideSpinner : function(component,event,helper){
        component.set('v.showSpinner', false);
    },

    disableCategory: function(component, event, helper) {
        var categorySection = component.find('template-category-section');
        $A.util.addClass(categorySection, "disabled");
    },

    enableCategory: function(component, event, helper) {
        var categorySection = component.find('template-category-section');
        $A.util.removeClass(categorySection, "disabled");
    }
})