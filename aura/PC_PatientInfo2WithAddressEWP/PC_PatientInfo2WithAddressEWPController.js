/**
 * Created by kkanteti on 11/30/2021.
 */
({
    doInitialize : function(component, event, helper){
        helper.setPatientAddressConfig(component,event,helper);
    },
    validate : function(component, event, helper){
        helper.validate(component,event,helper);
    },
})