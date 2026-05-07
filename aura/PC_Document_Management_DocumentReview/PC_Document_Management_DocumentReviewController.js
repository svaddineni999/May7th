/**
 * Created by sathekumar on 10/7/2021.
 */
({
    doInit : function(component, event, helper) {
        helper.setNamespace(component, event, helper);
        helper.setAttributeValues(component, event, helper);
        helper.launchOCR(component, event, helper);
    }
})