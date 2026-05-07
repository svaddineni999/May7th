({
	doInit : function(component, event, helper) {
        helper.setNamespace(component);
        helper.launchPopUp (component, event, helper);
       // helper.getCustomcomp (component, event, helper);
	},
    
    hideModalBox : function(component, event, helper) {
        helper.hideModal(component, event, helper);
    },
    
    goToCase : function(component, event, helper) {
    	helper.goToCase(component, event, helper);        
    },
    OpenNewComponent:function(component, event, helper) {
        var componentName=component.get("v.compDetails.componentName");
        var iconLabel = event.currentTarget.name;
        component.set("v.iconLabel", iconLabel); 
            $A.createComponent(
                componentName,
                    {
                        "docId" : component.get("v.recordId"),
                        "caseId" : component.get("v.caseId")
                    },
                    function(newComponent) {
                        component.set("v.body", newComponent);
                    }
              ); 
        
    }
})