/**
 * Created by kkanteti on 11/17/2021.
 */
({
    doInit : function(component,event,helper){
        helper.doInit(component,event,helper);
    },
    closeModal : function(component,event,helper){
        component.set("v.showAddressModal",false);
    },
    submitAddress : function(component,event,helper){
        helper.submitAddress(component,event,helper);
    },
    setPersistentAddress : function(component,event,helper){
        helper.setPersistentAddress(component,event,helper);
    }
})