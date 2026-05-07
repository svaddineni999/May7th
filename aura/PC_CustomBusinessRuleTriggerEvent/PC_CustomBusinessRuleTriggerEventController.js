/**
 * Created by tusarora on 3/18/2020.
 */
({
    doInit : function(component, event, helper) {
       helper.setNamespace(component);
    },
     onTriggerEventObjectChange : function(component, event, helper){
         console.log('TriggerEventObjectChange Called :::::');
         helper.onTriggerEventObjectChange(component, event, helper);
     },
     getTriggerEventConditions : function(component, event, helper){
         //debugger;
         console.log('CalledFromParentSave::::');
         return helper.getTriggerEventConditions(component, event, helper);
     },
     initiateConditionBuilderOnEdit : function(component, event, helper){
        helper.initiateConditionBuilderOnEdit(component, event, helper);
     },
     validate : function(component, event, helper){
         return helper.validate(component, event, helper);
     },
     doValidationOnTriggerEventObject: function(component,event,helper){
         return helper.doValidationOnTriggerEventObject(component, event, helper);
     }
})