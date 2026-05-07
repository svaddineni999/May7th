/**
 * Created by vkashikar on 6/18/2018.
 */
({
    searchPharmacies : function(component, event, helper) {
        debugger;
        console.log("searching pharmacies");
        var action = component.get("c.getPharmacies");

        action.setParams({

        });
        action.setCallback(this, function(response) {
            var state = response.getState();

            if (component.isValid() && state === "SUCCESS") {
                var returnValue = response.getReturnValue();
                component.set("v.pharmacies",returnValue);
                console.log("return value");
                console.log(returnValue);
                helper.setPharmacyOptions(component, event, helper);
            }
            else {
               console.error("Something went wrong.");
               console.error(response.getError());
            }
        });
        $A.enqueueAction(action);
    },
    setPharmacyOptions: function(component, event, helper) {

            var response = component.get("v.pharmacies");
            var dependentOptions = [];
            if(response != null && response.length > 0) {
                for (var i = 0; i < response.length; i++) {
                    dependentOptions.push({
                        class: "optionClass",
                         label: response[i].displayName,
                         value: response[i].id
                    });
                }
            }
            //component.find('pharmacyMultiSelect').set("v.options", dependentOptions);
            component.set("v.pharmacyMultiSelect", dependentOptions);
        },
    addPharmacies : function(component, event, helper) {
        // fire event
        //var val = component.find("pharmacyMultiSelect").get("v.value");
        debugger;
        var currentNode = event.currentTarget;

        var id = currentNode.getAttribute("data-name");
        debugger;
        //var val = component.get("pharmacyMultiSelect").get("v.value");
        var selectedPharmacies = [];
        var allPharmacies = component.get("v.pharmacies");
        debugger;
       /* if(!$A.util.isEmpty(val)) {
            var values = val.split(';');
            for(var i=0; i < values.length; i++) {
                for(var j=0; j < allPharmacies.length; j++) {
                    if(allPharmacies[j].id == values[i]) {
                        selectedPharmacies.push(allPharmacies[j]);
                        break;
                    }
                }
            }
        } */
        if(!$A.util.isEmpty(id)) {
            for(var j=0; j < allPharmacies.length; j++) {
                 if(allPharmacies[j].id == id) {
                        selectedPharmacies.push(allPharmacies[j]);
                            break;
                 }

            }
        }

        component.set("v.selectedPharmacies",selectedPharmacies);
        helper.fireAddPharmacyEvent(component, event, helper);
    },
    setNamespace : function(component) {
        var component_to_string = component.toString();
        var markupTagLoc = component_to_string.indexOf('markup://');
        var endOfNamespaceLoc = component_to_string.indexOf(':',markupTagLoc+9);
        var ns = component_to_string.substring(markupTagLoc+9,endOfNamespaceLoc);
        var namespacePrefix = (ns == "c" || ns == "C") ?  "" :  ns + "__";
        component.set("v.namespace", ns);
        component.set("v.namespacePrefix", namespacePrefix);
    },
    fireAddPharmacyEvent : function(component, event, helper) {
        //var cmpEvent = $A.get("e." + ns + ":" + "PC_AddPharmacy");
        var cmpEvent = component.getEvent("addPharmacyEvent");

        cmpEvent.setParams({
            "selectedPharmacies" : component.get("v.selectedPharmacies")
            });
        cmpEvent.fire();
    }
})