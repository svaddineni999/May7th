({
    
    doInit : function(component, event, helper) {
        helper.getConstantsValuesMap(component,event,helper);
        helper.fetchActivity(component, event, helper);
        helper.getPicklistEntryMap(component, helper);
        helper.getFieldLabels(component);
        helper.getReferenceDatePicklist(component,event,helper);
        helper.setRecordValues(component);
    },
    display : function(component, event, helper) {
        helper.toggleHelper(component, event);
    },

    displayOut : function(component, event, helper) {
        helper.toggleHelper(component, event);
    },
    saveActivity : function(component, event, helper) {
        component.set("v.disabled",true);
        helper.validateRequired(component, event, helper);
        helper.handleSave(component, event, helper);   
    },
    
    deleteActivity : function(component, event, helper) {
      
      	helper.handleDelete(component, event, helper);

    },
    
    closeComponent : function(component, event, helper) {

      	helper.closeComponent(component, event, helper);

    },

    editActivity : function(component, event, helper) {
      	component.set("v.disabled", false);
    },
    
      hideAckModal : function(component, event, helper) {
        helper.hideAckModal(component, event, helper);
    },
    
    showAckModal : function(component, event, helper) {
        helper.showAckModal(component, event, helper);
    },

    onChangeFunction :  function(component, event, helper){
        helper.changeReferenceType(component, event);
    },

    onCondBehavChange : function(component, event, helper){
        helper.changeConditionOption(component, event, helper);
    },

    showCondition : function(component, event, helper){
        helper.showCondition(component, event, helper);
    },

    createConditionalBuilder : function(component, event, helper){
        helper.createConditionalBuilder(component, event, helper, false);
    },
    createFieldMappingBuilder : function(component, event, helper){
            helper.createFieldMappingBuilder(component, event, helper, false);
    },

    onRecordChange : function(component, event, helper){
        helper.onRecordChange(component, event, helper);
    },
    conditionsToSave : function(component, event, helper){
        helper.conditionsToSave(component, event, helper);
    },

    onConditonSelect : function(component, event, helper){
        helper.onConditonSelect(component, event, helper);
    },
    onSingleSelectChange: function(component, event, helper) {
        helper.onSingleSelectChange(component, event, helper);
    },

    onSubTypeChange: function(component, event, helper){

        component.find("AutomationTaskLightningComponent").set("v.body", "");

        var value = component.find("subType").get("v.value");
        helper.dynamicSubtypeComponent(component, event, helper, value);

    },
    onChangeSelectedRecord : function(component, event, helper) {
        var oldValue = event.getParam("oldValue");
        var currentValue = event.getParam("value");
        if(currentValue == "{}") {
            // re-render the Conditional Builder to clear the field values.
           component.set("v.isAddFieldMapRow",false);
           component.set("v.storedObjectApiName",'');
           

        }else if(currentValue != 'undefined' && currentValue != "{}"){
            if(currentValue != oldValue &&  currentValue.QualifiedApiName != component.get("v.storedObjectApiName")){
                component.set("v.storedObjectApiName",'');
                component.set("v.isAddFieldMapRow",true);
                component.set('v.isRecordCreation',true);
                var fieldMapper = component.find('fieldMappingBuilder');
                fieldMapper.initializeComponent();
                var subTypeError = component.find("subTypeError");
                $A.util.removeClass(subTypeError,'slds-show');
                $A.util.addClass(subTypeError,'slds-hide');
            }
        }
        
    }
})