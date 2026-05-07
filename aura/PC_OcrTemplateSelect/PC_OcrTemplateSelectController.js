/**
 * Created by sathekumar on 10/8/2021.
 */
({
    doInit : function(component, event, helper) {
        if(!$A.util.isEmpty(component.get('v.engagementProgram')) && component.get('v.isDocumentEngagementProgram')){
            var engagementProgramCmp = component.find("engagementProgram");
            engagementProgramCmp.set('v.disabled', true);
        }
        helper.getTemplateSelectionOptions(component, event, helper);
    },

    handleTemplateChange: function(component, event, helper) {
        if(!$A.util.isEmpty(component.get("v.templateTypeId"))){
            var templateOptions = component.get("v.templateTypeOptions");
            component.set("v.templateTypeName", templateOptions.find(opt => opt.value === event.getParam("value")).label);
            helper.onTemplateTypeChange(component, event, helper);
        }
    },

    onClear: function(component, event, helper) {
        component.set("v.engagementProgram", '');
        component.set("v.selectedCategory", []);
        helper.getTemplateSelectionOptions(component, event, helper);
    },

    handleCategory: function(component, event, helper) {
        var selectedCategory = event.getParam('filters');
        selectedCategory = [...selectedCategory];
        component.set("v.selectedCategory", selectedCategory);
        console.log('selectedCategory-->'+selectedCategory);
        helper.refreshTemplateTypeOptions(component, event, helper);
    },

    onEngProgramSelect: function(component, event, helper) {
        if($A.util.isEmpty(component.get("v.engagementProgram"))){
            component.set("v.selectedCategory", []);
        }
        helper.refreshTemplateTypeAndCategoryOptions(component, event, helper);
    },

    validate: function(component, event, helper) {
        var templateTypeCmp = component.find("templateType");
        templateTypeCmp.reportValidity();
        return inputCmp.checkValidity();
    }
})