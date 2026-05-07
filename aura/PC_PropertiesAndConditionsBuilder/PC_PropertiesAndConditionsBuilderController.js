/**
 * Created by kkanteti on 8/14/2020.
 */
({
    doInit : function(component, event, helper){
        if(component.get("v.objectName")){
            helper.showSpinner(component,event,helper);
            helper.setNamespace(component);
            helper.initializeComponent(component, event, helper);
        }
    },
    handleComponentEvent: function(component,event,helper){
        helper.handleComponentEvent(component,event,helper);
    },
    onChangeConditionOption: function(component,event,helper){
        if(component.get("v.conditionValue") != 'PC_CustomLogic'){
            component.set("v.isCustomLogicValid",true);
            component.set("v.serverSideCustomLogicValid",true);
        }else{
            component.set("v.serverSideCustomLogicValid",false);
            helper.validateConditionLogic(component,event,helper);
        }
    },
    createNewRow : function(component,event,helper){
        helper.createNewRow(component,event,helper);
        if(component.get("v.builderContext") == 'ConditionalBuilder' && component.get("v.conditionValue") == 'PC_CustomLogic'){
            helper.validateConditionLogic(component,event,helper);
        }
    },
    removeRow : function(component, event, helper){
        helper.removeRow(component, event, helper);
        if(component.get("v.builderContext") == 'ConditionalBuilder' && component.get("v.conditionValue") == 'PC_CustomLogic'){
            helper.validateConditionLogic(component,event,helper);
        }
    },
    getBuilderJSONToSave : function(component,event,helper){
        var builderJSONWithValidationResult =  helper.getBuilderJSONToSave(component,event,helper);
        return builderJSONWithValidationResult;
    },
    validateConditionLogic : function(component,event,helper){
        helper.validateConditionLogic(component,event,helper);
    },
    validateServerSideLogic : function(component,event,helper){
        helper.validateServerSideLogic(component,event,helper);
    }
})