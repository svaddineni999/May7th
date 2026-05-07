/**
 * Created by kkanteti on 11/15/2021.
 */
({
    doInit : function(component,event,helper){
        helper.setNamespace(component);
        helper.setConfiguration(component);
        helper.getExistingAddresses(component,event,helper);
    },
    handleAvailableAddressRowAction : function(component,event,helper){
        helper.handleAvailableAddressRowAction(component,event,helper);
    },
    handleSelectedAddressRowAction : function(component,event,helper){
        helper.handleSelectedAddressRowAction(component,event,helper);
    },
    addNewAddress : function(component,event,helper){
        helper.addNewAddress(component,event,helper);
    },
    validate : function(component, event, helper){
        return helper.validate(component,event,helper);
    },
})