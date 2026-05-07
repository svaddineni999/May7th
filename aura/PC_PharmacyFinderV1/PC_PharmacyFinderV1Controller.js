/**
 * Created by vkashikar on 6/18/2018.
 */
({
    validate : function(component, event, helper) {
        console.log("validating");
    },
    doInit : function(component, event, helper) {

        helper.setNamespace(component);
        helper.searchPharmacies(component, event, helper);
    },
    addPharmacies : function(component, event, helper) {
        debugger;
        console.log("adding values...");
        helper.addPharmacies(component, event, helper);
    },
    onPharmacySelectChange : function(component, event, helper) {
        console.log("Selected values...");
        //console.log(component.find("pharmacyMultiSelect").get("v.value"));
        //var val = component.find("pharmacyMultiSelect").get("v.value");



        var val =component.get("pharmacyMultiSelect").get("v.value");
        var selectedPharmacies = [];
        var allPharmacies = component.get("v.pharmacies");
        if(!$A.util.isEmpty(val)) {
            var values = val.split(';');
            for(var i=0; i < values.length; i++) {
                for(var j=0; j < allPharmacies.length; j++) {
                    if(allPharmacies[j].id == values[i]) {
                        selectedPharmacies.push(allPharmacies[j]);
                        break;
                    }
                }
            }
        }
        component.set("v.selectedPharmacies",selectedPharmacies);
        console.log(component.get("v.selectedPharmacies"));
    }
})