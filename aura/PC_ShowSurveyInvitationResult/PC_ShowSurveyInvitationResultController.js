/**
 * Created by vkashikar on 7/7/2021.
 */
({
    doInit: function(component,event,helper){
        debugger;
        helper.setNamespace(component);
        helper.clearErrors(component);
        helper.setURLParamValues(component, event, helper);
        helper.getInvitationResults(component, event, helper);
    },
    refresh: function(component, event, helper) {
        helper.clearErrors(component);
        helper.getInvitationResults(component, event, helper);
    }
})