({
	doInit : function(component, event, helper) {
        debugger;
        var action = component.get("c.getProgramCaseStatus");
        action.setCallback(this, function(a) {
            var state = a.getState();

            if (state === "SUCCESS") {
				try {
                    component.set("v.programStatus", a.getReturnValue());
                    for (var i = 0; i < a.getReturnValue().length; i++) {
                        var obj = a.getReturnValue()[i];
                        var elementName = "";

                        if(obj.type == 'Adherence') {
                            component.set("v.AdherenceCompletedPercentage", Math.round(obj.completedPercentage * 100));
                        } else if(obj.type == 'Coverage') {
                            component.set("v.CoverageCompletedPercentage", Math.round(obj.completedPercentage * 100));
                        } else {
                        	return;
                        }
                    }
                } catch(err) {
                    console.log('Error occured in program status summary: ' + err.message);
                    console.log(err);
                }
            } else if (state === "INCOMPLETE") {
                console.log("Program Status Summary: State Incomplete");
            } else if (state === "ERROR") {
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