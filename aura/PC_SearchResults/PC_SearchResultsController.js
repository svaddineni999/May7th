/**
 * Created by vkashikar on 10/16/2019.
 */
({
    doInit : function(component, event, helper) {
        helper.setNamespace(component);
        helper.clearAttributes(component, event, helper);
        helper.initializeAttributes(component, event, helper);
        helper.setResultClasses(component, event, helper);
    },
    handleSearchParams : function(component, event, helper) {
        debugger;
        helper.clearAttributes(component, event, helper);
        helper.setSearchParams(component, event, helper);
        if(helper.validateSearchParams(component, event, helper)) {
            helper.setResultClasses(component, event, helper);
            helper.loadResultsCmp(component, event, helper);
        }
    },
    fireSelectedRecordForNone : function(component, event, helper) {
        component.set("v.selectedRecordId", null);
        component.set("v.selectedRecordSource", null);
        helper.fireUnselectEventForNone(component, event, helper);
        helper.fireSelectedRecordHelper(component, event, helper);

    },
    handleSelectedDataTableRow : function(component, event, helper) {
        debugger;
        component.find("noneOfThese").set("v.value",null);
        var selectedRows = event.getParam('selectedRows');
        var keyField = event.getParam('keyField');
        var source = event.getParam('sourceUniqueId');
        var actionType = event.getParam('actionType');
        var actionName = event.getParam('actionName');
        if(selectedRows != null && selectedRows.length >0){
            var selectedRecordId = selectedRows[0][keyField];
            component.set("v.selectedRecordId", selectedRecordId);
            component.set("v.selectedRecordSource",source);
            component.set("v.actionType", actionType);
            component.set("v.actionName", actionName);

            helper.fireUnselectEvent(component, event, helper);
            helper.fireSelectedRecordHelper(component, event, helper);
        }

    }
})