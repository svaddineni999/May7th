({
    setNamespace : function(component) {
  		
        var component_to_string = component.toString();
        
        var markupTagLoc = component_to_string.indexOf('markup://');
        var endOfNamespaceLoc = component_to_string.indexOf(':',markupTagLoc+9);
        var ns = component_to_string.substring(markupTagLoc+9,endOfNamespaceLoc);
        
        var namespacePrefix = (ns == "c" || ns == "C") ?  "" :  ns + "__";
        
  		component.set("v.namespace", ns);
        component.set("v.namespacePrefix", namespacePrefix);
    },
    setCaseType : function(component) {
        var caseId = component.get("v.recordId");
        var caseType;
        var action = component.get("c.getCaseType");
        action.setParams({
            "caseId": caseId
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                var returnValue = response.getReturnValue();
                if (returnValue == "Not Enrollment"){
                    component.set("v.newEnrollment", false);
                    component.set("v.processedEnrollment", false);
                }
                else{ 
                    if (returnValue == "New Enrollment"){
                        component.set("v.newEnrollment", true);
                        component.set("v.processedEnrollment", false);
                    }
                    else{ 
                        if (returnValue == "Completed Enrollment" || returnValue == "New Enrollment Without Applicant"){
                            component.set("v.newEnrollment", false);
                            component.set("v.processedEnrollment", true);
                        }
                    }
                }
                
                //alert(JSON.stringify(response.getReturnValue()));
            } else {
                console.log("Failed with state: " + state);
            }
        });
        
        $A.enqueueAction(action);
    }
})