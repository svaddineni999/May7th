/**
 * Created by ronbansal on 1/07/2023.
 */
({
    doInit : function (component, event,helper) {
        helper.clearErrors(component);
        helper.setNamespace(component);
        helper.showNewAppealComponent(component, event, helper);
    }
})