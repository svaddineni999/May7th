({
	starActivity : function (component) {
		var objTask  = component.get("v.objTask");
    	var action = component.get("c.updateTask");
        action.setParams({
            "taskID" : objTask.taskID
        });
        action.setCallback(this, function(a) {
            var state = a.getState();
            if (state === 'SUCCESS'){
            	component.set("v.objTask", a.getReturnValue());
                //Fire update event
            	var taskUpdatedEvent = component.getEvent("taskUpdated");
                taskUpdatedEvent.fire();
            } else if (state ==="ERROR"){
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