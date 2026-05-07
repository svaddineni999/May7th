({
    doInit: function(component, event, helper) {
        helper.showSpinner(component, event, helper);
        helper.setNamespace(component);
        helper.setPageReferenceValues(component, event, helper);
        helper.setDefaultValues(component, event, helper);
        helper.hideSpinner(component, event, helper);
    },

    onSave: function (component, event, helper) {
        helper.handleSubmit(component, event, helper);
    },
    handleCancel : function(component, event, helper) {
        helper.handleCancel(component,event,helper);
    },
    handleSuccess: function (component, event, helper) {
        helper.handleSuccess(component, event, helper);
    },
})