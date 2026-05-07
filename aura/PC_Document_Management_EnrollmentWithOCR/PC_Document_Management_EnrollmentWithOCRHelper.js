/**
 * Created by sathekumar on 6/24/2021.
 */
({
    setNamespace : function(component, event, helper) {
        var ns = CH_PC_Util.getNamespace(component);
        var nsPrefix = CH_PC_Util.getNamespacePrefix(component);
        component.set("v.namespace", ns);
        component.set("v.namespacePrefix", nsPrefix);
    },

    checkDocumentOcrStatus: function(component, event, helper) {
        helper.showSpinner(component, event, helper);
        var action = component.get('c.checkDocumentOcrStatus');
        action.setParams({
           documentId : component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS'){
                console.log(response.getReturnValue());
                var returnValue, ocrServiceEnabled, previousOcrQueueStatus, applicantExistOnDocument, enrollmentCaseExistOnDocument;
                returnValue = response.getReturnValue();
                ocrServiceEnabled = returnValue.ocrServiceEnabled;
                previousOcrQueueStatus = returnValue.previousOcrQueueStatus;
                applicantExistOnDocument = returnValue.applicantExistOnDocument;
                enrollmentCaseExistOnDocument = returnValue.enrollmentCaseExistOnDocument;
                component.set('v.ocrServiceEnabled', ocrServiceEnabled);
                component.set('v.previousOcrQueueStatus', previousOcrQueueStatus);
                component.set('v.applicantExistOnDocument', applicantExistOnDocument);
                component.set('v.enrollmentCaseExistOnDocument', enrollmentCaseExistOnDocument);
                if(ocrServiceEnabled && (previousOcrQueueStatus == undefined || previousOcrQueueStatus == 'Canceled') && !(applicantExistOnDocument || enrollmentCaseExistOnDocument)){
                    component.set('v.isOpen', true);
                    component.set('v.skipAndContinue', true);
                    component.set('v.infoMessage', component.get("v.runOcrBeforeEnrollmentWarning"));
                } else if(ocrServiceEnabled && (previousOcrQueueStatus == 'Queued' || previousOcrQueueStatus == 'In Progress')){
                    component.set('v.isOpen', true);
                    component.set('v.cancelAndContinue', true);
                    component.set('v.infoMessage', component.get("v.ocrInprogressWarning"));
                } else if(ocrServiceEnabled && (previousOcrQueueStatus == 'Failed') && !(applicantExistOnDocument || enrollmentCaseExistOnDocument)){
                    component.set('v.isOpen', true);
                    component.set('v.skipAndContinue', true);
                    component.set('v.infoMessage', component.get("v.previousOcrFailedMessage"));
                } else {
                    helper.launchEnrollment(component, event, helper);
                }
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

    launchEnrollment: function(component, event, helper) {
        $A.createComponent(
            component.get("v.namespace") + ":PC_Document_Management_Enrollment",
            {
                "recordId" : component.get("v.recordId"),
                "actionAttribute" : component.get("v.actionAttribute")
            },
            function(newComponent) {
                component.set("v.body", newComponent);
            }
        );
        console.log('Launch Enrollment Wizard Component');
    },

    launchOCR: function(component, event, helper) {
        $A.createComponent(
            component.get("v.namespace") + ":PC_DocumentOcrSubmitter",
            {
                "recordId" : component.get("v.recordId")
            },
            function(newComponent) {
                component.set("v.body", newComponent);
            }
        );
        console.log('Launch OCR Submitter Component');
    },

    handleSkipAndContinue : function(component, event, helper) {
        component.set('v.isOpen', false);
        helper.launchEnrollment(component, event, helper);
    },

    handleCancelAndContinue : function(component, event, helper) {
        helper.showSpinner(component, event, helper);
        var action = component.get('c.cancelOCR');
        action.setParams({
           documentId : component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS'){
                console.log(response.getReturnValue());
                var returnValue = response.getReturnValue();
                if(returnValue == null){
                    component.set('v.isOpen', false);
                    helper.launchEnrollment(component, event, helper);
                } else {
                    component.set('v.warningMessage', returnValue);
                    component.set('v.cancelAndContinue', false);
                    component.set('v.continueEnrollment', true);
                }
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

    closeModal : function(component, event, helper) {
         component.set("v.isOpen", false);
    },

    showSpinner: function(component, event, helper) {
        component.set('v.showSpinner', true);
    },

    hideSpinner : function(component,event,helper){
        component.set('v.showSpinner', false);
    }
})