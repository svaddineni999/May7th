({
    handleRowSelection : function(component, event, helper) {
        debugger;
        var selectedRows = event.getParam('selectedRows');
        //component.set("v.selectedRows",selectedRows);
        var compEvent = component.getEvent("selectedDataTableRow");
        compEvent.setParams({"selectedRows" : selectedRows });
        compEvent.setParams({"keyField" : component.get("v.keyField")});
        compEvent.setParams({"sourceUniqueId" : component.get("v.sourceUniqueId")});
        compEvent.fire();
        debugger;
        console.log('handleRowSelection executed successfully');
        component.set("v.showActiveFlag", true);
    },
    handleRowAction : function(component, event, helper) {
        var action = event.getParam('action');
        var row = event.getParam('row');
        debugger;
        component.set('v.selectedRows', [row[component.get("v.keyField")]]);
        var compEvent = component.getEvent("selectedDataTableRow");
        compEvent.setParams({"selectedRows" : [row] });
        compEvent.setParams({"keyField" : component.get("v.keyField")});
        compEvent.setParams({"sourceUniqueId" : component.get("v.sourceUniqueId")});
        compEvent.setParams({"actionType" : 'ROW_ACTION'});
        compEvent.setParams({"actionName" : action.name});
        compEvent.fire();
        console.log('handleRowAction executed successfully');
    },
    unselectRow : function(component, event, helper) {
        debugger;
        var sourceId = component.get("v.sourceUniqueId");
        var currentSelectedSourceId = event.getParam("currentSelectionSource");
        if(sourceId != currentSelectedSourceId) {
            //component.set("v.selectedRows",[]);
            //component.find("unselect").click();
            //component.find("unselectContainer").getElements()[0].firstChild.click();
            component.set("v.selectedRows",[]);
            component.set("v.showActiveFlag", false);
        }

    },
    unselect : function(component, event, helper) {
        debugger;
        component.set("v.selectedRows",[]);
    },
})