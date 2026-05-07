/**
 * Created by shisbansal on 7/3/2018.
 */
({

        setNamespace : function(component) {
            var component_to_string = component.toString();
            var markupTagLoc = component_to_string.indexOf('markup://');
            var endOfNamespaceLoc = component_to_string.indexOf(':',markupTagLoc+9);
            var ns = component_to_string.substring(markupTagLoc+9,endOfNamespaceLoc);
            var namespacePrefix = (ns == "c" || ns == "C") ?  "" :  ns + "__";
            component.set("v.namespace", ns);
            component.set("v.namespacePrefix", namespacePrefix);
        },

        searchPharmacies : function(component, event, helper, idParam) {
                helper.setOnSearchAttributes(component, event, helper);
                console.log("searching pharmacies");

                debugger;

                //var action = component.get("c.getPharmacies");
                var action  = component.get("c.getPharmaciesFromDistributor");

                action.setParams({
                    prescriptionId : idParam
                });
                action.setCallback(this, function(response) {
                    var state = response.getState();
                    component.set("v.searchInProgress", "false");
                    if (component.isValid() && state === "SUCCESS") {
                        var returnValue = response.getReturnValue();
                        debugger;
                        component.set("v.pharmacies",returnValue);
                        console.log("return value");
                        console.log(returnValue);
                        component.set("v.pharmacyMultiSelect", returnValue);
                        //helper.setPharmacyOptions(component, event, helper);
                    }
                    else {
                      console.error("Something went wrong.");
                      var error = 'Something went wrong. Please contact administrator.'
                      var errors = response.getError();
                      if(errors != null && errors.length > 0 && !$A.util.isEmpty(errors[0]['message'])) {
                          error = errors[0]['message'];

                      }
                      component.set("v.errors", [error]);

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

            debugger;

            component.set("v.pharmacyMultiSelect", dependentOptions);




        },
        setOnSearchAttributes : function(component, event, helper) {
            var dummy;
            component.set("v.pharmacies",dummy);
            component.set("v.pharmacyMultiSelect",dummy);
            component.set("v.searchInProgress", "true");
            component.set("v.isError", "false");
        },

        addPharmacies : function(component, event, helper) {
            // fire event

            var currentNode = event.currentTarget;

            var id = currentNode.getAttribute("data-name");

                   //var val = component.get("pharmacyMultiSelect").get("v.value");
            var selectedPharmacies = [];
            var allPharmacies = component.get("v.pharmacies");

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



        fireAddPharmacyEvent : function(component, event, helper) {
                        //var cmpEvent = $A.get("e." + ns + ":" + "PC_AddPharmacy");
            var cmpEvent = component.getEvent("addPharmacyEvent");

            cmpEvent.setParams({
                "selectedPharmacies" : component.get("v.selectedPharmacies")
            });
            cmpEvent.fire();
        }
})