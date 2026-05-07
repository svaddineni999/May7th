/**
 * Created by vkashikar on 8/1/2018.
 */
({
    doInit : function(component, event, helper) {
        helper.clearErrorMessages(component);
        helper.initialize(component, event, helper);
    },
    refreshView : function(component, event, helper) {
        helper.clearErrorMessages(component);
        helper.initialize(component, event, helper);
    }
})