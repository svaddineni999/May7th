/**
 * Created by kkanteti on 9/24/2020.
 */
({
    //Below methods are for operations on the row.
    onField : function(component, event, helper){
        if(component.get('v.isDisabled') || !component.get("v.row.isDeleteAllowed")){
            return;
        }
        helper.onField(component, event, helper);
    },
    onOperatorChange : function(component, event, helper){
        if(component.get("v.showOperator")){
            helper.onOperatorChange(component, event, helper);
        }
    },
    valueChange : function(component, event, helper){
        helper.valueChange(component,event,helper);
    },
    toValueChange : function(component, event, helper){
        //console.log(JSON.stringify(component.get("v.row")));
    },
    onTodayChange : function(component,event,helper){
        helper.onTodayChange(component,event,helper);
    },
    onNowChange : function(component,event,helper){
        helper.onNowChange(component,event,helper);
    },
    onChangeToAssignId : function(component,event,helper){
        helper.onChangeToAssignId(component,event,helper);
    },
    onChangeToBoundPicklist : function(component,event,helper){
        helper.onChangeToBoundPicklist(component,event,helper);
    },
    onDateReferenceChange : function(component,event,helper){
        helper.onDateReferenceChange(component,event,helper);
    },
    validateRowData : function(component,event,helper){
        var isValid = true;
        if(component.get("v.conditionsRequired")){
           isValid = helper.validateRowData(component,event,helper);
        }
        return isValid;
    },
    initiateMultiSelectCombobox : function(component,event,helper){
        helper.initiateMultiSelectCombobox(component,event,helper);
    },
    //Below methods are related  to field selector modal
    onFieldChangeInFieldSelector : function(component, event, helper){
        helper.onFieldChangeInFieldSelector(component, event, helper);
    },
    onSelectInFieldSelector : function(component, event, helper){
        helper.onSelectInFieldSelector(component, event, helper);
    },
    onCancelInFieldSelector : function(component, event, helper){
        helper.onCancelInFieldSelector(component, event, helper);
    }
})