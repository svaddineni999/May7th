/**
 * Created by shisbansal on 7/5/2018.
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



        searchPharmacies : function(component, event, helper) {
            helper.setOnSearchAttributes(component, event, helper);
            var result = helper.getQueryParams(component,event,helper);


            console.log("searching pharmacies");

            var action  = component.get("c.searchPharmacies");
            action.setParams({
                "pharmacySearchParamsJson" : JSON.stringify(result)

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
                    component.set("v.pharmacyMultiSelect",returnValue);

                }
                else {
                    console.error("Something went wrong.");
                    var error = component.get("v.lightningError");
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

        setOnSearchAttributes : function(component, event, helper) {
            var dummy;
            component.set("v.pharmacies",dummy);
            component.set("v.pharmacyMultiSelect",dummy);
            component.set("v.searchInProgress", "true");
            component.set("v.isError", "false");
        },

        getQueryParams:function(component,event,helper){


            var queryObj = {"name": "", "npi": "", "zipCode":"","searchBy":"", "isSpecialty":false, "isLongTerm":false, "isRetail":false, "isMailOrder":false};

            if(component.get("v.display_npi_param_section") == 'npiSection') {
                queryObj.npi         =  component.find('NPI').get("v.value");
                queryObj.searchBy    = 'NPI';
            }
            else{

                queryObj.searchBy    = 'BEST_MATCH';
                queryObj.name        = $A.util.isEmpty(component.find('PharmacyName').get("v.value") ) ? '' :  component.find('PharmacyName').get("v.value");
                queryObj.zipCode     = $A.util.isEmpty(component.find('ZipCode').get("v.value")) ? '' :  component.find('ZipCode').get("v.value");
                queryObj.isSpecialty =  component.find('specialty').get("v.checked") ;
                queryObj.isLongTerm =  component.find('longterm').get("v.checked") ;
                queryObj.isRetail    = component.get("v.selectParam") == 'Retail'? true : false;
                //queryObj.isMailOrder = component.get("v.selectParam") == 'Mail'? true : false;
                queryObj.isMailOrder = component.get("v.selectParamMailOrder") == 'Mail'? true : false;
            }


            return queryObj;
        },

        setPharmacyOptions: function(component, event, helper) {

            var response = component.get("v.pharmacies");
            var dependentOptions = [];
            if(response != null && response.length > 0) {
                for (var i = 0; i < response.length; i++) {
                    dependentOptions.push({
                    class: "optionClass",
                    label: response[i].displayName,
                    value: response[i].id,
                    additionalInfo: response[i].additionalInfo
                    });
                }
            }

            component.set("v.pharmacyMultiSelect", dependentOptions);


        },



        addPharmacies : function(component, event, helper) {
        // fire event

            var currentNode = event.currentTarget;

            var id = currentNode.getAttribute("data-name");


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

            var cmpEvent = component.getEvent("addPharmacyEvent");

            cmpEvent.setParams({
                "selectedPharmacies" : component.get("v.selectedPharmacies")
            });

            cmpEvent.fire();
        },


        handleSearch:function(component,event,helper){
            if(component.get("v.display_npi_param_section") =="npiSection" ){
                if(helper.validateNpiField(component, event, helper)) {
                    helper.searchPharmacies(component,event,helper);
                }
            }
           else{
                helper.searchPharmacies(component,event,helper);
           }
        },


        validateNpiField:function(component ,event ,helper){


            if(component.find('NPI').checkValidity()) {
                return true;
            }
            else {

            component.find('NPI').reportValidity();
            }
                return false;


        },

        validatePharmacyName: function(component ,event , helper){


            if(!component.find('PharmacyName').indexOf(' ') >= 0) {
                return true;
            }
            else {

                component.find('PharmacyName').reportValidity();
            }
                return false;


        },



        validateZipCode: function(component ,event , helper){


            if(component.find('ZipCode').checkValidity()) {
                return true;
            }
            else {

                component.find('ZipCode').reportValidity();
            }
                return false;


        },



})