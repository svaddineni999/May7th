/**
 * Created by sathekumar on 8/3/2020.
 */
({
    doInit : function(component, event, helper) {
        helper.setNamespace(component, event, helper);
    },

    launchEletter2Component : function(component, event, helper) {
        helper.launchEletter(component, event, helper);
    }
})