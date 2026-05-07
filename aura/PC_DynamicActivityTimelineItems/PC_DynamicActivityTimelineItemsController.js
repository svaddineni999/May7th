({
	// common reusable function for toggle sections
	toggleActivityDetail : function(component, event, helper) {
        component.set("v.isExpanded", !component.get("v.isExpanded"));
	},
	goToRecord : function(component, event, helper) {
        var recordId = event.currentTarget.dataset.recordId;
        var objectName = event.currentTarget.getAttribute("data-target");
        var urlEvent = $A.get("e.force:navigateToURL");
        if(objectName.toUpperCase() == 'USER'){
            urlEvent.setParams({
                "url": '/profile/'+recordId,
                "isredirect" :false
            });
        }else if(objectName.toUpperCase() == 'TASK'){
            urlEvent.setParams({
                "url": '/task/'+recordId,
                "isredirect" :false
            });
        }else{
            urlEvent.setParams({
                "url": '/detail/'+recordId,
                "isredirect" :false
            });
        }
        urlEvent.fire();
	},
})