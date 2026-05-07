/**
 * Created by sathekumar on 2/25/2022.
 */
({
    doInit : function(component,event,helper){
        var action = component.get("c.getMedicalBIInfo");
        action.setParams({
            "supportPlanId"   : component.get("v.supportPlanID")
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state == 'SUCCESS') {
                var result = response.getReturnValue();
                if(!$A.util.isEmpty(result)){
                    if(result.isValidTriggerEventObject) {
                        component.set('v.isValidTriggerEventObject', true);
                    } else {
                        component.set('v.BINotSupportedErrorMessage', result.notSupportErrorMessage);
                        helper.showSupportError(component,event,helper);
                    }
                }
            } else if (state === "ERROR") {
                var errors = response.getError();
                CH_PC_Util.showAllErrors(component.get("v.errorStatus"),errors);
            } else {
                var unknownErrors = [];
                var error = {"message" : component.get("v.errorStatus")}
                unknownErrors.push(error);
                CH_PC_Util.showAllErrors(component.get("v.toastErrorTitle"),unknownErrors);
            }
        });
        $A.enqueueAction(action);
    },

    showSupportError: function(component, event, helper){
        component.set('v.isValidTriggerEventObject', false);
        var supportError = component.find('supportError')
        $A.util.removeClass(supportError,'slds-hide');
        $A.util.addClass(supportError,'slds-show');
    },

    validateData : function(component,event,helper){
        var isValid = true;
        if(! component.get('v.isValidTriggerEventObject')){
            if(!$A.util.isEmpty(component.find("supportError"))){
                component.find("supportError").getElement().scrollIntoView({behavior: "smooth",block: "center"});
            }
            isValid = false;
        }
        component.set("v.isValid", isValid);
    }
})