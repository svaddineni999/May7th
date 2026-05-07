/**
 * Created by kkanteti on 6/18/2020.
 */
({
    doInit  : function(component,event,helper){
        helper.showSpinner(component,event,helper);
        helper.initializeAttributes(component,event,helper);
    },
    createFieldMappingBuilder : function(component, event, helper){
        helper.createFieldMappingBuilder(component, event, helper, false);
    },
    createRelatedObjectFilter : function(component, event, helper){
        helper.createRelatedObjectFilter(component, event, helper, false);
    },
    handleObjectChange : function(component, event, helper){
        helper.handleObjectChange(component,event,helper);
    },
    onChangeOrderByFields : function(component,event,helper){
        helper.onChangeOrderByFields(component,event,helper);
    },
    getTaskJSONToSave : function(component, event, helper){
        var taskJSON = helper.getTaskJSONToSave(component, event, helper);
        return taskJSON;
    }
})