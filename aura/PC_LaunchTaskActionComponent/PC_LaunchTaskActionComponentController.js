/**
 * Created by vkashikar on 7/9/2020.
 */
({
    doInit: function(component, event, helper) {
        debugger;
        helper.clearErrors(component);
        helper.setNamespace(component, event, helper);
        helper.getActionComponent(component, event, helper);
    },
    onChangeActionComponentDetails : function(component, event, helper) {
        debugger;
        helper.onChangeActionComponentDetails(component, event, helper);
    },
    refreshView : function(component, event, helper) {
        helper.clearErrors(component);
        var x;
        component.set("v.actionComponentDetails", x);
        component.set("v.body",x);
        helper.setNamespace(component, event, helper);
        helper.getActionComponent(component, event, helper);
    }
})