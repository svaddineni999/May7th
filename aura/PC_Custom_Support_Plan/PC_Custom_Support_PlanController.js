/**
 * Created by havalakki on 10/11/2018.
 */
({
     doInit : function(component, event, helper) {
           helper.getAllInformation(component, event, helper);
           helper.setNamespace(component);
     },

     saveActivity : function(component, event, helper) {
        helper.clearErrors(component);
        helper.validateRequired(component, event, helper);
        helper.handleSave(component, event, helper);
     },

     onCondBehavChange : function(component, event, helper){
        helper.changeConditionOption(component, event, helper);
     },

     showCondition : function(component, event, helper){
         helper.showCondition(component, event, helper);
     },

     hideModalBox : function(component, event, helper){
        helper.hideModal(component, event, helper);
     },

     onRecordChange : function(component, event, helper){
         helper.onRecordChange(component, event, helper);
     },

     createConditionalBuilder : function(component, event, helper){
         helper.createConditionalBuilder(component, event, helper, false);
     },
     onChangeSelectedObjectRecord : function(component, event, helper){
        helper.onChangeSelectedObjectRecord(component, event, helper);
     },
     onChangeSupportPlanName : function(component, event, helper){
        helper.onChangeSupportPlanName(component, event, helper);
     }
})