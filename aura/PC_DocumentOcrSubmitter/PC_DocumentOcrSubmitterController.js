/**
 * Created by sathekumar on 4/29/2021.
 */
({
    doInit : function(component, event, helper) {
        helper.setNamespace(component, event, helper);
        helper.setObjectAndFieldApiName(component, event, helper);
        helper.validateOcrSetup(component, event, helper);
        //helper.isDocumentReadyForOCR(component, event, helper);
        //helper.validateDocument(component, event, helper);
    },

    handleTemplateTypeChange: function(component, event, helper) {
        var templateTypeId = event.getParam("value")[0];
        component.set("v.templateTypeId", '');
        component.set('v.templateTypeValidationMessages', '');
        component.set('v.isSelectedTemplateTypeValid', false);
        if(templateTypeId != undefined){
            component.set("v.templateTypeId", event.getParam("value")[0]);
            helper.onTemplateTypeChange(component, event, helper);
        }
    },

    closeModal : function(component, event, helper) {
        helper.closeModal(component, event, helper);
    },

    onSubmit: function (component, event, helper){
        if(! (helper.checkFieldValidation(component, event, helper))){
            return false;
        }
        helper.handleSubmit(component, event, helper);
    }
})