/**
 * Created by vkashikar on 6/20/2018.
 */
({
    setNamespace : function(component, event, helper) {
        debugger;
        var ns = CH_PC_Util.getNamespace(component);
        var nsPrefix = CH_PC_Util.getNamespacePrefix(component);
        component.set("v.namespace", ns);
        component.set("v.namespacePrefix", nsPrefix);
    },
    init : function(component, event, helper) {
        debugger;

        var action = component.get("c.getData");
        var recordId = component.get("v.recordId");
        var option = helper.getOverridePrescriptionWithCoverage(component, event, helper);

        action.setParams({
            "caseId" : recordId,
            "overridePrescriptionWithCoverage": option
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                console.log("in doinit...");
                console.log(returnValue);

                var returnValue = response.getReturnValue();
                component.set("v.formData",returnValue);

                helper.setDropDownOptions(component, event, helper, 'inputHealthPlan', 'healthPlans');
                helper.setDefaultOption(component, event, helper, 'inputHealthPlan', 'healthPlans');
                helper.setSelectedHealthPlan(component, event, helper);

                //var option = helper.getOverridePrescriptionWithCoverage( component,event,helper);
                if( option == "false"){
                    helper.setDropDownOptions(component, event, helper, 'inputPrescription', 'prescriptions');
                    helper.setDefaultOption(component, event, helper, 'inputPrescription', 'prescriptions');

                    helper.setSelectedPrescription(component, event, helper);
                }
                else{
                    helper.setDropDownOptions(component, event, helper, 'inputProgramCoverage', 'programCoverages');
                    helper.setDefaultOption(component, event, helper, 'inputProgramCoverage', 'programCoverages');
                    helper.setSelectedProgramCoverage(component, event, helper)

                }




                helper.triggerSearch(component, event, helper);

            }
            else {
               //var toastErrorTitle = component.get("v.toastErrorTitle");
               //CH_PC_Util.handleErrors(state, response.getError(), toastErrorTitle, '');
               component.set("v.errors", response.getError());

            }
        });
        $A.enqueueAction(action);

    },
    triggerSearch : function(component, event, helper) {
        var healthPlans = component.get("v.formData")['healthPlans'];
        debugger;
        //var products = component.get("v.formData")['products'];
        var override = helper.getOverridePrescriptionWithCoverage(component, event, helper);
        var property = override == 'false'? 'prescriptions' : 'programCoverages';


        var items = component.get("v.formData")[property];
        /*if((! $A.util.isEmpty(healthPlans) && healthPlans.length == 1) &&
        ((! $A.util.isEmpty(products) && products.length == 1))) {*/
        if((! $A.util.isEmpty(healthPlans) && healthPlans.length == 1) &&
            (! $A.util.isEmpty(items) && (items.length == 1) )) {
            helper.clearErrorMessages(component);
            helper.clearSearchFormAttributes(component);
            helper.searchForms(component, event, helper);
        }


       /* var programCoverage = component.get("v.formData")['programCoverage'];
        if((! $A.util.isEmpty(healthPlans) && healthPlans.length == 1) &&
            ((! $A.util.isEmpty(programCoverage) && programCoverage.length == 1))) {

                        helper.clearErrorMessages(component);
                        helper.clearSearchFormAttributes(component);
                        helper.searchForms(component, event, helper);
        */

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
    enableAccordionHeaders : function(component, event, helper) {
        helper.enableAccordionHeadersHelper('healthPlanDetailsHeader');
        helper.enableAccordionHeadersHelper('prescriptionDetailsHeader');
        helper.enableAccordionHeadersHelper('patientDetailsHeader');
    },
    enableAccordionHeadersHelper : function(component, event, auraId) {
        $A.util.removeClass(component.find(auraId), 'accordionHeaderDisabled');
        $A.util.addClass(component.find(auraId), 'accordionHeaderEnabled');

    },
    setSelectedHealthPlan : function(component, event, helper) {
        var selectedItem = null;

        var id = component.find('inputHealthPlan').get('v.value');
        debugger;

        if(id != 'select') {
            var items = component.get("v.formData").healthPlans;
            selectedItem = items.find(hp => hp['id'] == id);
        }
        component.set("v.selectedHealthPlan", selectedItem);

        console.log('selected health plan');
        console.log(component.get("v.selectedHealthPlan"));
    },

    setSelectedPrescription : function(component, event, helper) {

        var selectedItem = null;
        var id = component.find('inputPrescription').get('v.value');

        if(id != 'select') {
            var items = component.get("v.formData").prescriptions;
            selectedItem = items.find(hp => hp['id'] == id);
        }
        debugger;
        component.set("v.selectedPrescription", selectedItem);
        console.log('selected prescription');
        console.log(component.get("v.selectedPrescription"));
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
    searchForms : function(component, event, helper) {

        debugger;

        var isValid = helper.validateSearchForm(component, event, helper);
        var productId;

        if(isValid) {

            component.set("v.searchInProgress", true);
            var action = component.get("c.searchPAForms");
            var recordId = component.get("v.recordId");
            var pbmId = component.get("v.selectedHealthPlan").id;
            var option = helper.getOverridePrescriptionWithCoverage(component, event, helper);


            if(option == 'false'){
            productId = component.get("v.selectedPrescription").product.id;
            }
            else{
                productId = component.get("v.selectedProgamCoverage").prescription.product.id;
            }

            action.setParams({
                "caseId" : recordId,
                "pbmId" : pbmId,
                "productId" : productId
            });
            action.setCallback(this, function(response) {
                var state = response.getState();
                component.set("v.searchInProgress", false);
                if (component.isValid() && state === "SUCCESS") {
                    console.log("in searchPAForms success block...");
                    var returnValue = response.getReturnValue();
                    console.log(returnValue);
                    if( $A.util.isEmpty(returnValue) ||
                        $A.util.isEmpty(returnValue.forms) ||
                        returnValue.forms.length == 0)
                    {
                        // no forms found case
                        component.set("v.searchFormsAvailable", false);
                        component.set("v.showSearchMessage", true);
                    }
                    else {
                        // found case
                        component.set("v.searchFormsAvailable", true);
                        component.set("v.searchForms",returnValue);
                        component.set("v.showSearchMessage", false);

                    }
                }
                else {
                   //var toastErrorTitle = component.get("v.toastErrorTitle");
                   component.set("v.searchFormsAvailable", false);

                   component.set("v.showSearchMessage", false);
                   //CH_PC_Util.handleErrors(state, response.getError(), toastErrorTitle, '');
                   component.set("v.errors", helper.getErrorsAsArray(response.getError(), helper));

                }
            });
            $A.enqueueAction(action);
        }
    },
    validateSearchForm : function(component, event, helper) {
        var isHealthPlanSelected = helper.validateSelectedHealthPlan(component, event, helper);
        var isPrescriptionSelected = helper.validateSelectedPrescription(component, event , helper);
        var isProgramCoverageSelected  = helper.validateSelectedProgramCoverage(component, event, helper);
        //var toastErrorTitle = component.get("v.toastErrorTitle");
        var option = helper.getOverridePrescriptionWithCoverage(component,event, helper);
        var msg;
        if(!isHealthPlanSelected) {
            msg = component.get("v.healthPlanDetailsMissingMessage");
            //CH_PC_Util.handleErrors('', msg, toastErrorTitle, '');
            component.set("v.errors", [msg]);
            return false;
        }
        else if(!isPrescriptionSelected && (option == 'false') ) {
            msg = component.get("v.prescriptionDetailsMissingMessage");
            //CH_PC_Util.handleErrors('', msg, toastErrorTitle, '');
            component.set("v.errors", [msg]);
            return false;
        }
        else if(!isProgramCoverageSelected && (option == 'true') ) {
            msg = component.get("v.programCoverageDetailsMissingMessage");
            //CH_PC_Util.handleErrors('', msg, toastErrorTitle, '');
            component.set("v.errors", [msg]);
            return false;
        }
        return true;
    },

    validateSelectedHealthPlan : function(component, event, helper) {
        debugger;
        var item = component.get("v.selectedHealthPlan");
        if($A.util.isEmpty(item) || $A.util.isEmpty(item.name) || $A.util.isEmpty(item.groupName) || $A.util.isEmpty(item.state)) {
            return false;
        }
        if($A.util.isEmpty(item.pcn) && $A.util.isEmpty(item.bin)) {
            return false;
        }
        return true;
    },

    validateSelectedPrescription: function(component, event, helper) {
            var item = component.get("v.selectedPrescription");

            if(  ($A.util.isEmpty(item))) {

                return false;
            }

            if( $A.util.isEmpty(item.product.name) || $A.util.isEmpty(item.product.ndc)) {

                return false;
            }

            return true;
        },

    validateSelectedProgramCoverage: function(component, event, helper) {
        debugger;

        var item = component.get("v.selectedProgamCoverage");

        if( ($A.util.isEmpty(item)) ||   $A.util.isEmpty(item.prescription)){
            return false;
        }


       if( (item.prescription.product == null) || ( $A.util.isEmpty(item.prescription.product.name)|| $A.util.isEmpty(item.prescription.product.ndc))) {
           return false;
           }
         return true;
        },

    validatePatientInfo : function(component, event, helper) {
        var item = component.get("v.formData");
        if($A.util.isEmpty(item) || $A.util.isEmpty(item.patient) ||
                $A.util.isEmpty(item.patient.name) || $A.util.isEmpty(item.patient.gender) ||
                $A.util.isEmpty(item.patient.firstName) || $A.util.isEmpty(item.patient.lastName) ||
                $A.util.isEmpty(item.patient.zipCode) || $A.util.isEmpty(item.patient.birthDate)) {
            return false;
        }
        return true;

    },
    validateSelectedForm : function(component,event, helper ){
        var item = component.get("v.selectedForm");
        if($A.util.isEmpty(item)){
            return false;
        }
        return true;
    },
    clearErrorMessages : function(component) {
        var errors;
        component.set("v.errors", errors);
    },
    clearSearchFormAttributes : function(component) {
        component.set("v.searchFormsAvailable", false);
        component.set("v.searchForms", null);
        component.set("v.selectedForm", null);
        component.set("v.showSearchMessage", false);
    },
    submitPA : function(component, event, helper) {
        debugger;
        var isValid = helper.validateSubmitPA(component, event, helper);
        if(isValid) {
            component.set("v.submitInProgress", "true");
            var action = component.get("c.submitPA");
            var recordId = component.get("v.recordId");
            var pbmId = component.get("v.selectedHealthPlan").id;

            var formId = component.get("v.selectedForm").id +'';
            var prescriptionItem = component.get("v.selectedPrescription");
            var programCoverageItem  = component.get("v.selectedProgamCoverage");
            var prescriptionId =null;
            var option = helper.getOverridePrescriptionWithCoverage(component,event,helper);


            var programCoverageId = null;
            if(! $A.util.isEmpty(prescriptionItem)){



                 prescriptionId = component.get("v.selectedPrescription").id;

            }
            if(! $A.util.isEmpty(programCoverageItem)){



                 programCoverageId = component.get("v.selectedProgamCoverage").id;

            }
            var ePADetails = new Map();
                    ePADetails['caseId'] = recordId;
                    ePADetails['pbmId'] = pbmId;
                    ePADetails['prescriptionId'] = prescriptionId;
                    ePADetails['programCoverageId'] = programCoverageId;
                    ePADetails['overridePrescriptionWithCoverage'] = option;
                    ePADetails['formId'] = formId;

            action.setParams({
                "ePADetails" : ePADetails
            });
            action.setCallback(this, function(response) {
                var state = response.getState();
                component.set("v.submitInProgress", "false");
                if (component.isValid() && state === "SUCCESS") {
                    console.log("in submitPA success block...");
                    var returnValue = response.getReturnValue();
                    console.log(returnValue);
                    if( $A.util.isEmpty(returnValue))
                    {
                        var errorMessage = ["Something went wrong, TBD2"];
                        component.set("v.errors", errorMessage);
                    }
                    else {
                        // success
                        if(returnValue.isSuccess) {
                            component.set("v.pa_response", returnValue);
                            var successBlock = component.find("ePASuccessOverlayContent");
                            $A.util.toggleClass(successBlock, 'slds-hide');
                            helper.autoRedirect(component, returnValue.htmlURL);
                        }
                        else {
                            var msgs = [];
                            msgs.push(returnValue.errorMessage);
                            if(returnValue.is_ePA_created) {
                                msgs.push(returnValue.htmlURL);
                            }
                            component.set("v.errors", msgs);
                        }


                    }
                }
                else {
                   var errors = helper.getErrorsAsArray(response.getError(), helper);
                   component.set("v.errors", errors);

                }
            });
            $A.enqueueAction(action);
        }



    },

    showSuccess : function(component, event, helper, returnValue) {
        //component.set("v.isPACreatedSuccessfully", "true");
        helper.showSuccessOverlay(component, event, helper, returnValue);
    }  ,

    showToastSuccess : function(component, event, helper, returnValue) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": component.get("v.toastSuccessTitle"),
            "message": component.get("v.successMessage"),
            "type" : 'success',
            "mode" : "pester",
            "duration" : "15000",
            messageTemplate: component.get("v.successMessage"),
            messageTemplateData: ['Salesforce', {
                url: returnValue.htmlURL,
                label: component.get("v.successMessagePlaceholder1")
            }
                                 ]
        });
        toastEvent.fire();
    }  ,

    autoRedirect : function(component, url) {
        setTimeout(function() {
            debugger;
            if(component.get("v.cancelAutoRedirect") == undefined) {
                // do nothing
            }
            else if(component.get("v.cancelAutoRedirect") == true) {
                // do nothing
            }
            else {
                var popUp = window.open(url, '_blank');
                popUp.focus();
            }
        }, 10000);
    },
    getErrorsAsArray : function(errors, helper) {
        var errorArr = [];
        if(!$A.util.isEmpty(errors)) {

            for(var i=0; i<errors.length; i++) {
                var errorObj = errors[i];
                helper.setErrorArr(errorObj, errorArr);
                for (var property in errorObj) {
                    if (errorObj.hasOwnProperty(property) && !$A.util.isEmpty(errorObj[property])) {
                       for(var j=0; j<errorObj[property].length; j++) {
                          helper.setErrorArr(errorObj[property][j], errorArr);
                       }
                    }
                }
            }
        }
        return errorArr;
    },
    setErrorArr : function(errorObj, ret_errorArr) {
        if(!$A.util.isEmpty(errorObj.message)) {
            var msg = '';
            if(!$A.util.isEmpty(errorObj.statusCode)) {
                msg = errorObj.statusCode + ' : ';
            }
            msg = msg + errorObj.message;
            ret_errorArr.push(msg);
        }
    },
    getOverridePrescriptionWithCoverage: function(component,event,helper){
        var option = component.get("v.overridePrescriptionWithCoverage");
        if((option == 'false')|| (option == false))
        {
            return 'false';
        }
        else{
            return 'true';
        }

    },

    validateSubmitPA : function(component, event, helper) {
        debugger;
        var isHealthPlanSelected = helper.validateSelectedHealthPlan(component, event, helper);

        var isPrescriptionSelected = helper.validateSelectedPrescription(component, event , helper);
        var isProgramCoverageSelected  = helper.validateSelectedProgramCoverage(component, event, helper);
        var isFormSelected = helper.validateSelectedForm(component, event, helper);
        var hasPatientDetails = helper.validatePatientInfo(component, event, helper);

        //var toastErrorTitle = component.get("v.toastErrorTitle");

        var option = helper.getOverridePrescriptionWithCoverage(component, event , helper);
        var msg;
        if(!hasPatientDetails) {
            msg = component.get("v.patientDetailsMissingMessage");
             component.set("v.errors", [msg]);
                return false;
        }
        else if(!isHealthPlanSelected) {

                msg = component.get("v.healthPlanDetailsMissingMessage");
                component.set("v.errors", [msg]);
                return false;

        }

        else if(!isPrescriptionSelected && (option == 'false')) {


                msg = component.get("v.prescriptionDetailsMissingMessage");
                //CH_PC_Util.handleErrors('', msg, toastErrorTitle, '');
                component.set("v.errors", [msg]);
                return false;



        }

        else if(!isProgramCoverageSelected && (option == 'true')) {
            msg = component.get("v.programCoverageDetailsMissingMessage");
            //CH_PC_Util.handleErrors('', msg, toastErrorTitle, '');
            component.set("v.errors", [msg]);
            return false;
        }

        else if(!isFormSelected) {
            msg = component.get("v.formDetailsMissingMessage");
            component.set("v.errors", [msg]);
            return false;
        }
        else {
            return true;
        }
    }

})