({
	navigateToRecord : function(component, event, helper) {
        var context = component.get("v.usersContext");
        var objAlert  = component.get("v.objAlert");
        var pid = objAlert.alertID ;
        if(context != undefined) {
        	if(context == 'Theme4t' || context == 'Theme4d') {
                sforce.one.navigateToSObject(pid);
            } else {
                //window.location.assign('/'+rid);
                window.open('/' + pid);
           }
		} else {
			var navEvt = $A.get("e.force:navigateToSObject");
            navEvt.setParams({
                "recordId": pid,
                "slideDevName": "related"
            });
            navEvt.fire();
    	}
    },
    closeAlert : function(component, event, helper) {
        var objAlert  = component.get("v.objAlert");
        var pid = objAlert.alertID ;
        var action = component.get("c.overrideAlert");
        action.setParams({
            "objAlertId": pid
        });
        action.setCallback(this, function(actionResult) {
            if(actionResult.getState() ==="SUCCESS"){
                //Fire update event
                var taskUpdatedEvent = component.getEvent("taskUpdated");
                taskUpdatedEvent.fire();
            } else if (actionResult.getState() ==="ERROR"){
                var errors = a.getError();
                console.log(JSON.stringify(errors));
                var errText = component.get("v.errorText");
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log(errText);
                    }
                } else {
                    console.log("Unknown error");
                }
            }

        });
        $A.enqueueAction(action);
    }
})