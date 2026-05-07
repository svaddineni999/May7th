/**
 * Created by shisbansal on 6/29/2018.
 */
({
    doInit : function(component, event, helper) {
        debugger;
        console.log(component.get("v.pharmacyFinderCmpAttributes"));
        helper.setNamespace(component);
        helper.searchPharmacies(component, event, helper, component.get("v.prescriptionId"));
    },

    validate : function(component, event, helper) {
        console.log("validating");
    },

    addPharmacies : function(component, event, helper) {
        console.log("adding values...");
        helper.addPharmacies(component, event, helper);
    },

    onPrescriptionIdUpdated : function(component, event, helper) {
        helper.searchPharmacies(component, event, helper, component.get("v.prescriptionId"));
    }
})