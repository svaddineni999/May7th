({
	doInit : function(component, event, helper) {
        helper.getCaseType(component, event, helper);
        var caseId = component.get("v.recordId");
        //helper.getStages(component, caseId); 
        
        var action = component.get("c.getStatusIndicatorIcons");
        action.setParams({
          "caseId": caseId
        });
        action.setCallback(this, function(a) {
            if(a.getState() ==="SUCCESS") {
                component.set("v.statusIndicators", a.getReturnValue());
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
    },
     showSpinner : function (component, event, helper) {
        var spinner = component.find('spinner');
        var evt = spinner.get("e.toggle");
        evt.setParams({ isVisible : true });
        evt.fire();    
    },
    
    hideSpinner : function (component, event, helper) {
       var spinner = component.find('spinner');
       var evt = spinner.get("e.toggle");
       evt.setParams({ isVisible : false });
       evt.fire();    
    }
})