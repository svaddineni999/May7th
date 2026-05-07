/**
 * Created by sathekumar on 4/29/2021.
 */
({
    setNamespace : function(component, event, helper) {
        var ns = CH_PC_Util.getNamespace(component);
        var nsPrefix = CH_PC_Util.getNamespacePrefix(component);
        component.set("v.namespace", ns);
        component.set("v.namespacePrefix", nsPrefix);
    },

    setObjectAndFieldApiName : function(component, event, helper){
        var objectApiName = component.get('v.ocrQueueObjectApiName');
        var templateTypeFieldApiName = component.get('v.templateTypeFieldApiName');
        var documentFieldApiName = component.get('v.documentApiName');
        var namespacePrefix = component.get("v.namespacePrefix");
        component.set('v.ocrQueueObjectApiName', namespacePrefix + objectApiName);
        component.set('v.templateTypeFieldApiName', namespacePrefix + templateTypeFieldApiName);
        component.set('v.documentApiName', namespacePrefix + documentFieldApiName);
    },

    isDocumentReadyForOCR: function(component, event, helper) {
        helper.showSpinner(component, event, helper);
        var action = component.get('c.checkDocumentReadyForOCR');
        action.setParams({
           documentId : component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
           var state = response.getState();
           if (state === 'SUCCESS'){
               console.log(response.getReturnValue());
               component.set('v.isDocumentReadyForOCR', true);
               helper.validateDocument(component, event, helper);
           } else {
               var error = component.get("v.lightingErrorMessage");
               var errors = response.getError();
               if (errors && errors[0] && errors[0].message) {
                   error = errors[0]['message'];
                   component.set("v.errors", [error]);
               } else {
                   component.set("v.errors", [error]);
               }
               component.set('v.disabled', true);
           }
           helper.hideSpinner(component, event, helper);
        });
        $A.enqueueAction(action);
    },

    validateDocument: function(component, event, helper) {
        helper.showSpinner(component, event, helper);
        var action = component.get('c.validateDocument');
        action.setParams({
            documentId : component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS'){
                console.log(response.getReturnValue());
                component.set('v.isValidDocumentForOCR', true);
                //helper.validateOcrSetup(component, event, helper);
            } else {
                var error = component.get("v.lightingErrorMessage");
                var errors = response.getError();
                if (errors && errors[0] && errors[0].message) {
                    error = errors[0]['message'];
                    component.set("v.errors", [error]);
                } else {
                    component.set("v.errors", [error]);
                }
                component.set('v.disabled', true);
            }
            helper.hideSpinner(component, event, helper);
        });
        $A.enqueueAction(action);
    },

    validateOcrSetup: function(component, event, helper) {
        helper.showSpinner(component, event, helper);
        var action = component.get('c.validateOcrSetup');
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS'){
                console.log(response.getReturnValue());
                component.set('v.isOcrSetupValid', true);
                helper.isDocumentReadyForOCR(component, event, helper);
            } else {
                var error = component.get("v.lightingErrorMessage");
                var errors = response.getError();
                if (errors && errors[0] && errors[0].message) {
                    error = errors[0]['message'];
                    component.set("v.errors", [error]);
                } else {
                    component.set("v.errors", [error]);
                }
                component.set('v.disabled', true);
            }
            helper.hideSpinner(component, event, helper);
        });
        $A.enqueueAction(action);
    },

    onTemplateTypeChange: function(component, event, helper) {
        helper.showSpinner(component, event, helper);
        var action = component.get('c.validateTemplateWithDocument');
        action.setParams({
            documentId : component.get("v.recordId"),
            templateTypeId : event.getParam("value")[0]
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS'){
                console.log(response.getReturnValue());
                var returnValue = response.getReturnValue();
                if(returnValue.errorMessages != undefined && returnValue.errorMessages.length > 0){
                    component.set('v.isSelectedTemplateTypeValid', false);
                } else {
                    component.set('v.isSelectedTemplateTypeValid', true);
                }
                component.set('v.templateTypeValidationMessages', returnValue);
            } else {
                var error = component.get("v.lightingErrorMessage");
                var errors = response.getError();
                if (errors && errors[0] && errors[0].message) {
                    error = errors[0]['message'];
                    component.set("v.errors", [error]);
                } else {
                    component.set("v.errors", [error]);
                }
            }
            helper.hideSpinner(component, event, helper);
        });
        $A.enqueueAction(action);
    },

    handleSubmit: function(component, event, helper) {
        component.set("v.errors", []);
        helper.disableSubmit(component, event, helper);
        var action = component.get('c.enqueueDocument');
        var documentInfoObj = {
            documentId : component.get("v.recordId"),
            templateTypeId : component.get("v.templateTypeId"),
            notifyOnCompletion : component.find('notifyOnCompletion').get("v.checked")
        };
        action.setParams({
            documentInfoJSON : JSON.stringify(documentInfoObj)
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS'){
                console.log(response.getReturnValue());
                var returnValue = response.getReturnValue();
                helper.closeModal(component, event, helper);
                var toastMessage = component.get('v.ocrDocumentQueuedSuccessMessage');
                if(component.find('notifyOnCompletion').get("v.checked") == true){
                    toastMessage = toastMessage + ' ' + component.get('v.ocrQueueCompletionNotifyMessage');
                }
                var toastData = [];
                toastData.push(returnValue.objectApiName);
                toastData.push(returnValue.queueId);
                toastData.push(returnValue.name);
                //Success Toast
                helper.showSuccessToast(component, event, helper, toastMessage, toastData);
            } else {
                var error = component.get("v.lightingErrorMessage");
                var errors = response.getError();
                    if (errors && errors[0] && errors[0].message) {
                        error = errors[0]['message'];
                        component.set("v.errors", [error]);
                    } else {
                        component.set("v.errors", [error]);
                    }
            }
            helper.enableSubmit(component, event, helper);
        });
        $A.enqueueAction(action);
    },

    disableSubmit : function(component, event, helper) {
        component.set("v.disableSubmit", true);
    },

    enableSubmit : function(component, event, helper) {
        component.set("v.disableSubmit", false);
    },

    checkFieldValidation : function(component, event, helper) {
        var isAllValid = true;
        if($A.util.isEmpty(component.get("v.templateTypeId"))){
            isAllValid = false;
        }
        return isAllValid;
    },

    closeModal : function(component, event, helper) {
        component.set("v.isOpen", false);
    },

    showSpinner: function(component, event, helper) {
        component.set('v.showSpinner', true);
    },

    hideSpinner : function(component,event,helper){
        component.set('v.showSpinner', false);
    },

    showSuccessToast : function(component, event, helper, toastMessage, toastData) {
        component.find('RunOcrNotifLib').showToast({
            //"title": "Success!",
            "variant": "success",
            "message": toastMessage,
            "messageData": [
                {
                    url: '/lightning/r/'+toastData[0]+'/'+toastData[1]+'/view',
                    label: toastData[2],
                }
            ],
            "mode" : "dismissable"
        });
    }
})