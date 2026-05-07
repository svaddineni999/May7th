/**
 * Created by sathekumar on 6/24/2021.
 */
({
    doInit : function(component, event, helper) {
        helper.setNamespace(component, event, helper);
        helper.checkDocumentOcrStatus(component, event, helper);
    },

    closeModal : function(component, event, helper) {
        helper.closeModal(component, event, helper);
    },

    openOCR: function (component, event, helper){
        component.set('v.isOpen', false);
        helper.launchOCR(component, event, helper);
    },

    onSkipAndContinue: function (component, event, helper){
        helper.handleSkipAndContinue(component, event, helper);
    },

    onCancelAndContinue: function (component, event, helper){
        helper.handleCancelAndContinue(component, event, helper);
    },

    onContinueEnrollment: function (component, event, helper){
        helper.closeModal(component, event, helper);
        helper.launchEnrollment(component, event, helper);
    }

})