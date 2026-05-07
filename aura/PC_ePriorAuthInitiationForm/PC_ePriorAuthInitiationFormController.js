/**
 * Created by vkashikar on 6/20/2018.
 */
({
    doInit : function(component, event, helper) {
        debugger;
        helper.setNamespace(component, event, helper);
        helper.clearSearchFormAttributes(component);
        helper.clearErrorMessages(component);
        //helper.enableAccordionHeaders(component, event, helper);
        helper.init(component, event, helper);

    },
    setSelectedPrescription : function(component, event, helper) {
        helper.clearErrorMessages(component);
        helper.clearSearchFormAttributes(component);
        helper.setSelectedPrescription(component, event, helper);
    },

    setSelectedProgramCoverage : function(component, event, helper){
        helper.clearErrorMessages(component);
        helper.clearSearchFormAttributes(component);
        helper.setSelectedProgramCoverage(component, event, helper);
    },

    setSelectedHealthPlan : function(component, event, helper) {
        helper.clearErrorMessages(component);
        helper.clearSearchFormAttributes(component);
        helper.setSelectedHealthPlan(component, event, helper);
    },
    searchForms : function(component, event, helper) {
        debugger;
        helper.clearErrorMessages(component);
        helper.clearSearchFormAttributes(component);
        helper.searchForms(component, event, helper);
    },
    toggleAccordion : function(component, event, helper) {
           CH_PC_Util.toggleAccordion(component, event, 'data-toggleContentAuraId');
    },
    onFormSelectionChanged : function(component, event, helper) {
        helper.clearErrorMessages(component);
        var selectedFormId = event.getSource().get("v.text");
        var items = component.get("v.searchForms");
        var selectedItem = items.forms.find(form => form['id'] == selectedFormId);
        console.log("selected form...")
        console.log(selectedItem);
        component.set("v.selectedForm", selectedItem);
    },
    initiatePriorAuth : function(component, event, helper) {
        helper.submitPA(component, event, helper);
    },
    cancelRedirection : function(component, event, helper){
        debugger;
        component.set("v.cancelAutoRedirect", true);
        component.find('ePAOverlay').notifyClose();
    },
    openVendorPortal : function(component, event, helper) {
        var response = component.get("v.pa_response");
        window.open(response.htmlURL, '_blank');
    }
})