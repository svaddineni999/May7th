/**
 * Created by sathekumar on 11/19/2020.
 */
({
    doInit : function(component, event, helper) {
        helper.setNamespace(component, event, helper);
        helper.setAttributeValues(component, event, helper);
        helper.launchEletter(component, event, helper);
    }
})