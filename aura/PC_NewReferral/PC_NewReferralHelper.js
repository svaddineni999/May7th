/**
 * Created by vkashikar on 8/13/2018.
 */
({
    fetchFormData : function(component, event, helper) {
        component.set("v.inProgress", true);
        var action = component.get("c.getData");
        var recordId = component.get("v.recordId");
        action.setParams({
            "caseId" : recordId
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            component.set("v.inProgress", false);

            if (component.isValid() && state === "SUCCESS") {
                console.log("in doinit of PC_NewReferral...");
                console.log(returnValue);

                var returnValue = response.getReturnValue();
                component.set("v.formData",returnValue);

                helper.setDropDownOptions(component, event, helper, 'inputProgramCoverage', 'programCoverages');
                helper.setDefaultOption(component, event, helper, 'inputProgramCoverage', 'programCoverages');
                helper.setSelectedProgramCoverage(component, event, helper);
                helper.setDefaultButtonGroupOption(component, event, helper);

            }
            else {
               var standardErrorMessage = component.get("v.standardErrorMessage");
               //CH_PC_Util.handleErrors(state, response.getError(), toastErrorTitle, '');
               $A.util.addClass(component.find("formContent"), 'slds-hide');
               component.set("v.errors", standardErrorMessage + ' --- ' + JSON.stringify(response.getError()));

            }
        });
        $A.enqueueAction(action);
    },
    clearErrorMessages : function(component) {
        var errors;
        component.set("v.errors", errors);
    },
    setDropDownOptions: function(component, event, helper, listAuraId, optionKey) {
        debugger
        var response = component.get("v.formData")[optionKey];
        var dependentOptions = [];
        dependentOptions.push({
                    class: "optionClass",
                    label: component.get("v.defaultDropDownValue"),
                    value: "select"
        });

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
        component.find(listAuraId).set("v.options", dependentOptions);
    },
    setDefaultOption : function(component, event, helper, listAuraId, optionKey) {
        debugger;
        var response = component.get("v.formData")[optionKey];
        if(response != null && response.length == 1) {
            var firstOption = response[0].id;
            component.find(listAuraId).set("v.value",firstOption);
            //helper.updateCardHolderInfo(component, event, helper);
        }
    },
    setSelectedProgramCoverage : function(component, event, helper) {

        var selectedItem = null;
        var id = component.find('inputProgramCoverage').get('v.value');

        if(id != 'select') {
            var items = component.get("v.formData").programCoverages;
            selectedItem = items.find(hp => hp['id'] == id);
        }
        debugger;
        component.set("v.selectedProgamCoverage", selectedItem);

        console.log('selected program Coverage');
        console.log(component.get("v.selectedProgamCoverage"));
    },
    toggle: function(component, auraId, isProgramCoveragesVisible) {
         var block = component.find(auraId);
         $A.util.removeClass(block, 'slds-show');
         $A.util.removeClass(block, 'slds-hide');
         if(isProgramCoveragesVisible) {
             if($A.util.hasClass(block, 'slds-show')) {
                // do nothing
             }
             else {
                 $A.util.addClass(block, 'slds-show');
             }
         }
         else {
              if($A.util.hasClass(block, 'slds-hide')) {
                 // do nothing
              }
              else {
                  $A.util.addClass(block, 'slds-hide');
              }
         }
    },
    unselectProgramCoverage : function(component) {
         var items = component.get("v.formData").programCoverages;
         var dummy;
         if(!$A.util.isEmpty(items) && items.length > 0) {
             component.find("inputProgramCoverage").set("v.value","select");
             component.set("v.selectedProgamCoverage", dummy);
         }
    },
    setDefaultButtonGroupOption : function(component, event, helper) {
        debugger;

        var response = component.get("v.formData")["programCoverages"];
        if($A.util.isEmpty(response) || response.length == 0) {
            helper.toggleButtons(component, event, helper, "noBtn");
        }
        else {
            helper.toggleButtons(component, event, helper, "yesBtn");
        }
    },
    launchMap : function(component, event, helper){

        var body = component.get("v.body");
        if(!$A.util.isEmpty(body) && body.length > 0) {

            return;
        }
        component.set("v.inProgress", true);

        component.set("v.isModalMapActive", true);

        var componentName = component.get("v.namespace") + ':' + 'PC_PatientLocationMapViewer';
        $A.createComponent(
            componentName,
            {
                "recordId" : component.get("v.recordId"),
                "genericMap" : false

            },
            function(newComponent, status) {
                component.set("v.inProgress", false);
                if(status == 'SUCCESS') {
                    component.set("v.body", newComponent);
                }
                else {
                    var toastEvent=$A.get("e.force:showToast");
                        toastEvent.setParams({
                            "title":    'Warning',
                            "message":  'Something went wrong, Please contact System Administrator',
                            "type":     'warning'
                            });
                            toastEvent.fire();
                }
            }
        );
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
    validateForm : function(component, event, helper) {
         var selectedProgamCoverage = component.get("v.selectedProgamCoverage");
         if($A.util.isEmpty(selectedProgamCoverage) ||
            $A.util.isEmpty(selectedProgamCoverage.id) ||
            $A.util.isEmpty(selectedProgamCoverage.pharmacy) ||
            $A.util.isEmpty(selectedProgamCoverage.pharmacy.id)) {

             var missingPharmacy = component.get("v.missingPharmacy");
             component.set("v.errors", missingPharmacy);
             return false;

         }
         return true;
    },
    createNewReferral : function(component, event, helper) {
        debugger;
        if(helper.validateForm(component, event, helper)) {
            var createRecordEvent = $A.get("e.force:createRecord");
            var selectedProgamCoverage = component.get("v.selectedProgamCoverage");
            var params = {
                "entityApiName": component.get("v.namespacePrefix") + "PC_Pharmacy_Referral__c",
                "defaultFieldValues" : {
                }
            }
            var program = component.get("v.namespacePrefix") + "PC_Program__c" ;
            var account = component.get("v.namespacePrefix") + "PC_Patient__c" ;
            var coverage = component.get("v.namespacePrefix") + "PC_Program_Coverage__c" ;
            var pharmacy = component.get("v.namespacePrefix") + "PC_Target_Pharmacy__c" ;
            var prescription = component.get("v.namespacePrefix") + "PC_Prescription__c"
            var paCase = component.get("v.namespacePrefix") + "PC_Prior_Authorization__c"


            params["defaultFieldValues"][program] = component.get("v.recordId");
            params["defaultFieldValues"][account] = selectedProgamCoverage.patientId;
            params["defaultFieldValues"][coverage] = selectedProgamCoverage.id;
            params["defaultFieldValues"][pharmacy] = selectedProgamCoverage.pharmacy.id;
            params["defaultFieldValues"][prescription] = selectedProgamCoverage.prescription.id;
            params["defaultFieldValues"][paCase] = selectedProgamCoverage.defaultPriorAuthCaseId;

            createRecordEvent.setParams(params);
            createRecordEvent.fire();
            return true;
        }
        else {
            return false;
        }

    },
    toggleButtons : function(component, event, helper, auraId) {
        if(auraId == "yesBtn") {
            component.find("yesBtn").set("v.variant","brand");
            component.find("noBtn").set("v.variant","neutral");
            helper.toggle(component, 'mapBlock', false);
            helper.toggle(component, 'programCoveragesBlock', true);
            helper.toggle(component, true);
        }
        else {
            component.find("noBtn").set("v.variant","brand");
            component.find("yesBtn").set("v.variant","neutral");
            //helper.unselectProgramCoverage(component);
            helper.toggle(component, 'programCoveragesBlock', false);
            helper.toggle(component, 'mapBlock', true);
            helper.launchMap(component, event, helper);
        }
    },
    setRecordId : function(component, event, helper) {
        if(!$A.util.isEmpty(component.get("v.relatedToId"))
                        && !$A.util.isEmpty("v.relatedToObject")
                        && component.get("v.relatedToObject").toLowerCase() == 'case')
        {
            component.set("v.recordId", component.get("v.relatedToId"));
        }
    }
})