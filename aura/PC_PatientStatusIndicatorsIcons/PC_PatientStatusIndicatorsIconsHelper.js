({
	getCaseType : function(component, event, helper) {
		var caseId = component.get("v.recordId");
        
        var action = component.get("c.getCase");
        action.setParams({
          "caseID": caseId
        });
        action.setCallback(this, function(a) {
            if(a.getState() ==="SUCCESS"){
                var c = a.getReturnValue();
                /* [PC-7442] Replaced the use of DeveloperName with 'Type' field of Case object to decide if its a program case record */
                if (c && c.Type == 'Program') {
                    component.set("v.showIcons", true);
                }
            } else if (a.getState() ==="ERROR"){
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