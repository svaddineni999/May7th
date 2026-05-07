/**
 * Created by peharitha on 9/30/2019.
 */
({
    doInit : function (component, event, helper) {
        helper.clearErrorMessages(component);
        helper.setNamespace(component);
        helper.readQueryParams(component);
        helper.initializeAttributes(component, event, helper);
    },
    searchRecords : function (component, event, helper) {
        var validFieldSet = helper.validateFieldSetForm(component, event, helper);
        if(validFieldSet){
            helper.fireSearchParamsEvent(component, event, helper);
        }
    },
})