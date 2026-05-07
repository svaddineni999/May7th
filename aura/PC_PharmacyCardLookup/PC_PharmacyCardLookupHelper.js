/**
 * Created by vkashikar on Jan 12 2018.
 */
({
    resetAll: function(component, event, helper) {
        var temp;
        component.set("v.pharmacyCardFetchInfo", temp);
        component.set("v.refInfo", temp);
        component.set("v.refInfoLabels", temp);
        component.set("v.isDataAvailable", false);
        component.set("v.healthPlansErrorMsg", temp);
        component.set("v.denyPharmaCardLookupMessage", temp);
        helper.resetInvokeLookupPharmacyCard(component, event, helper);
    },
    resetInvokeLookupPharmacyCard: function(component, event, helper) {
        component.set("v.isModalMapActive", false);
        var temp;
        component.set("v.displaySpinner",true);
        component.set("v.serviceResponse", temp);
        component.set("v.isModalMapActiveInner", false);
    },
    applyCSS: function(component){
        component.set("v.cssStyle", ".forceStyle .viewport .oneHeader.slds-global-header_container {z-index:0} .forceStyle.desktop .viewport{overflow:hidden}");
    },
    getPharmacyCardholderInfo : function(component, event, helper) {
        var action = component.get("c.getPharmacyCardholderInfo");
        var recordId = component.get("v.recordId");
        action.setParams({
            "caseId" : recordId
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                var returnValue = response.getReturnValue();
                console.log("in doinit...")
                console.log(returnValue);
                component.set("v.pharmacyCardFetchInfo", returnValue);
                //cardLookupButton.set("v.disabled", false);
            }
            else {
               var errors = response.getError();
               var msg;
               if (errors && Array.isArray(errors) && errors.length > 0) {
                   msg = errors[0].message;
               }
               else {
                   msg = errors;
               }
               component.set("v.denyPharmaCardLookupMessage", msg);
               //CH_PC_Util.handleErrors(state, response.getError(), toastErrorTitle, '');
               //cardLookupButton.set("v.disabled", true);
            }
        });
        $A.enqueueAction(action);
    },
    getRelatedHealthPlans: function(component, event, helper) {
        console.log('caseid ' + component.get("v.recordId"));
        var action = component.get("c.getRelatedHealthPlans");
        action.setParams({
            "caseId"		: component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                var returnValue = response.getReturnValue();
                component.set("v.refInfo", returnValue.healthPlans);
                component.set("v.refInfoLabels", returnValue);
                if (returnValue==null || returnValue.length==0 || returnValue.healthPlans == null || returnValue.healthPlans.length == 0){
                    component.set("v.isDataAvailable", false);
                    component.set("v.healthPlansErrorMsg", component.get("v.noHealthPlansFound"));
                }
                else {
                    component.set("v.isDataAvailable", true);
                }

            }
            else {
                component.set("v.isDataAvailable", false);
                var errors = response.getError();
                var msg;
                if (errors && Array.isArray(errors) && errors.length > 0) {
                    msg = errors[0].message;
                }
                else {
                    msg = errors;
                }

                component.set("v.healthPlansErrorMsg", msg);
                //CH_PC_Util.handleErrors(state, response.getError(), toastErrorTitle, getHealthPlansError);
            }
        });
        $A.enqueueAction(action);
    },
    revertCssChange: function(component){
        component.set("v.cssStyle", ".forceStyle .viewport .oneHeader.slds-global-header_container {z-index:5} .forceStyle.desktop .viewport{overflow:visible}");
    },
    showErrorToastMessage : function(component, event, helper, message) {
        var toastEvent = $A.get("e.force:showToast");
        var title = component.get("v.toastErrorTitle");
        toastEvent.setParams({
            "title": title,
            "message": message,
            "type": "error",
            "mode": "sticky"
        });
        toastEvent.fire();
    },
    showSuccessToastMessage : function(component, event, helper, message) {
            var toastEvent = $A.get("e.force:showToast");
            var title = component.get("v.toastSuccessTitle");
            toastEvent.setParams({
                "title": title,
                "message": message,
                "type": "success",
                "mode": "dismissible"
            });
            toastEvent.fire();
            component.set("v.isModalMapActive",false);
    },
    invokeLookupPharmacyCard : function(component, event, helper){
        if($A.util.isEmpty(component.get("v.denyPharmaCardLookupMessage"))) {
            component.set("v.displaySpinner",true);
            component.set("v.isModalMapActive", true);
            helper.applyCSS(component);
            var recordId = component.get("v.recordId");
            var action = component.get("c.getPharmacyCardLookupResponse");
            action.setParams({
                "caseId" : recordId,
                "requestObjJSONString" : JSON.stringify(component.get("v.pharmacyCardFetchInfo"))
            });
            action.setCallback(this, function(response) {
                var state = response.getState();
                console.log('State for lookupPharmacyCard = ' + state);
                var saveHealthPlanButton = component.find("saveHealthPlanButton");
                /**** PC-3018: Author: Hitha Avalakki
                Following check is required because if the Pharmacy lookup function is in progress and if Cancel button/Close button is clicked the 'Save'
                button cannot be referenced and hence we get javascript error*/
                if(!$A.util.isUndefinedOrNull(saveHealthPlanButton)){
                    saveHealthPlanButton.set("v.disabled", false);
                }

                if (component.isValid() && state === "SUCCESS") {
                    var returnValue = response.getReturnValue();
                    console.log(returnValue);
                    if(returnValue != null){
                        component.set("v.serviceResponse", returnValue);
                        component.set("v.isModalMapActiveInner", true);
                    }
                    else{

                        component.set("v.displaySpinner",false);
                        var getCardInfoError = component.get("v.getCardInfoError");
                        var toastErrorTitle = component.get("v.toastErrorTitle");
                        CH_PC_Util.handleErrors(state, response.getError(), toastErrorTitle, getCardInfoError);
                        //helper.showErrorToastMessage(component, event, helper, getCardInfoError);
                        component.set("v.errorMessage",getCardInfoError);
                        component.get("v.displayError",true);
                        if(!$A.util.isUndefinedOrNull(saveHealthPlanButton)){
                            saveHealthPlanButton.set("v.disabled", true);
                        }
                    }

                }
                else {
                    component.set("v.displaySpinner",false);
                    component.set("v.errorMessage",response.getError());
                    component.get("v.displayError",true);
                    var cardInfoError = component.get("v.getCardInfoError");
                    var errorTitle = component.get("v.toastErrorTitle");
                    //helper.showErrorToastMessage(component, event, helper, getCardInfoError);
                    CH_PC_Util.handleErrors(state, response.getError(), errorTitle, cardInfoError);
                    if(!$A.util.isUndefinedOrNull(saveHealthPlanButton)){
                        saveHealthPlanButton.set("v.disabled", true);
                    }
                }

            });
            $A.enqueueAction(action);
        }
        else {
            var msg = component.get("v.denyPharmaCardLookupMessage");
            var toastErrorTitle = component.get("v.toastErrorTitle");
            CH_PC_Util.handleErrors('Error', msg, toastErrorTitle, '');
        }
    },
    saveHealthPlan : function(component, event, helper) {
        var action = component.get("c.savePharmaCard");
        var recordId = component.get("v.recordId");
        var requestObjJSONString = JSON.stringify(component.get("v.pharmacyCardFetchInfo"));
        var responseObjJSONString = JSON.stringify(component.get("v.serviceResponse"));
        if($A.util.isEmpty(recordId) || $A.util.isEmpty(requestObjJSONString) || $A.util.isEmpty(requestObjJSONString)) {
            helper.showErrorToastMessage(component, event, helper, 'Nothing to save!');
        }
        else {
            action.setParams({
                "caseId" : recordId,
                "requestObjJSONString" : requestObjJSONString,
                "responseObjJSONString" : responseObjJSONString
            });
            action.setCallback(this, function(response) {
                var state = response.getState();
                var returnValue = response.getReturnValue();
                if (component.isValid() && state === "SUCCESS" && !$A.util.isEmpty(returnValue)) {
                    component.set('v.isDataAvailable',true);
                    $A.get('e.force:refreshView').fire();
                    var insertHealthPlanSuccess = component.get("v.insertHealthPlanSuccess");
                    helper.showSuccessToastMessage(component, event, helper, insertHealthPlanSuccess);
                } else {
                    var insertHealthPlanError = component.get("v.insertHealthPlanError");
                    var toastErrorTitle = component.get("v.toastErrorTitle");
                    //helper.showErrorToastMessage(component, event, helper, insertHealthPlanError);
                    CH_PC_Util.handleErrors(state, response.getError(), toastErrorTitle, insertHealthPlanError);
                }
                helper.revertCssChange(component);
            });
            $A.enqueueAction(action);
        }
    },


})