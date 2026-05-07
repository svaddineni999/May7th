({
    doInit : function (component, event, helper) {
        helper.setNamespace(component);
        helper.setConfiguration(component);
        helper.getAccountOrApplicant(component,event,helper);
    },
    validate : function(component, event, helper) {
        if(component.get("v.pageErrors").length != 0){
            return;
        }
        component.set('v.isValid', false);
        var pcRecordFormCmp = component.find('pcRecordFormByFieldSets');
        var formFields = pcRecordFormCmp.getAllFormValues();
        var isValid = pcRecordFormCmp.validateForm();
        if(isValid){
            component.set("v.isValid",isValid);
            formFields["LastModifiedDate"] = component.get("v.lastModifiedDate");
            component.set('v.persistentAccount',formFields);
        }
        return isValid;
    },
    setPersistentAccount : function(component, event, helper){
        var formFields = event.getParam('value');
        formFields["LastModifiedDate"] = component.get("v.lastModifiedDate");
        component.set('v.persistentAccount',formFields);
    }
})