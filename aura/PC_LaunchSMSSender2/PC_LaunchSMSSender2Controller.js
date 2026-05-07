/**
 * Created by cmohapatra on 12/4/2020.
 */
({
    doInit : function(component, event, helper) {
        helper.setNamespace(component, event, helper);
    },

    launchSMSSender2Component : function(component, event, helper) {
         helper.launchSMSSender(component, event, helper);
    }
})