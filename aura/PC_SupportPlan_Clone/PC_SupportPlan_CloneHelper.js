/**
 * Created by tejapatel on 2/19/2019.
 */
({
    hideCloneModal : function(component, event, helper){
        var aura_cloneSectionId = component.find("aura_cloneSectionId");
        var aura_backGroundSectionId = component.find("aura_backGroundSectionId");
        $A.util.removeClass(aura_cloneSectionId, 'slds-show');
        $A.util.removeClass(aura_backGroundSectionId, 'slds-show');
        $A.util.addClass(aura_cloneSectionId, 'slds-hide');
        $A.util.addClass(aura_backGroundSectionId, 'slds-hide');
    },

    validate : function(component, event, helper){
        var clonedSPName = component.find("clonedSPName");
        var checkValidity = clonedSPName.checkValidity();
        return checkValidity;
    },

    getFieldLabels : function(component){
        var action = component.get("c.getFieldLabels");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                var returnValue = response.getReturnValue();
                component.set("v.fieldLabels", returnValue);
            } else {
                console.log("Failed with state: " + state);
            }
        });
        $A.enqueueAction(action);
    },

    cloneSupportPlan : function(component, event, helper){
        var action = component.get("c.cloneSupportPlan");
            action.setParams({
                "recordId"      : component.get("v.recordId"),
                "clonedSPName"  : component.find("clonedSPName").get("v.value"),
            });

            action.setCallback(this, function(response) {
                var state = response.getState();
                if (component.isValid() && state === "SUCCESS") {
                    var clonedSPWrapper = response.getReturnValue();
                    if(clonedSPWrapper.exceptionFlag){
                        var error = [];
                        error = clonedSPWrapper.exceptionMessage;
                        component.set("v.errors",error);
                    }else{
                        var navEvt = $A.get("e.force:navigateToSObject");
                            navEvt.setParams({
                                "recordId": clonedSPWrapper.clonedSupportPlanId
                            });
                        navEvt.fire();
                        helper.hideCloneModal(component, event, helper);
                        var errors = [];
                        component.set("v.errors",errors);
                    }
                } else {
                    CH_PC_Util.showAllErrors(component.get("v.errorMessage"),$A.get("$Label.c.PC_UnknownError"));
                }
            });
            $A.enqueueAction(action);
    }
})