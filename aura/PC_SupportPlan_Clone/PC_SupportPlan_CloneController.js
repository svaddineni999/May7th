/**
 * Created by tejapatel on 2/19/2019.
 */
({
    doInit : function(component, event, helper) {
        helper.getFieldLabels(component, event, helper);
        var clonedSPName    = component.find("clonedSPName");
        var name            = component.get("v.clonePrefix")+component.get("v.SPName");
        clonedSPName.set("v.value",name);
    },

    hideCloneModal : function(component, event, helper) {
        helper.hideCloneModal(component, event, helper);
    },

    clone : function(component, event, helper) {
        var error = [];
        component.set("v.errors",error);
        var checkValidity = helper.validate(component, event, helper);
        if(checkValidity){
            helper.cloneSupportPlan(component, event, helper);
        }
    },

    doneRendering : function(component, event, helper){
        var clonedSPName    = component.find("clonedSPName");
        clonedSPName.focus();
    }
})