({
    doInit : function(component, event, helper) {
        component.set("v.isModalMapActive", true);
        helper.setRecordId(component);
        helper.applyCSS(component);
        helper.setNamespace(component);
        var componentName = component.get("v.namespace") + ':' + 'PC_PatientLocationMapViewer';
        $A.createComponent(
            componentName,
            {
                "recordId" : component.get("v.recordId")
            },
            function(newComponent) {
                component.set("v.body", newComponent);
            }
        );
    },
	closeMap : function(component, event, helper){
        component.set("v.isModalMapActive", false);
        helper.revertCssChange(component);
        var compEvent = component.getEvent("actionPanel");
        compEvent.setParams({"actionPanel" : false });
		compEvent.fire();
    }
})