/**
 * Created by shisbansal on 11/15/2018.
 */
({
    doInit : function(component, event, helper) {
        helper.getELetter(component, event, helper);
        helper.getFieldLabels(component, event, helper);
    },

    onEletterChange: function(component, event, helper){
        helper.onEletterChange(component, event, helper);
    },

    setSelected: function(component, event, helper){
        helper.setSelected(component, event, helper);
    },

    validateData: function(component, event, helper){
        helper.validateData(component, event, helper);
    },
})