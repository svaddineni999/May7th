({
	getUserAlerts: function(component) {
        var action = component.get("c.getActiveUserAlerts");

        action.setCallback(this, function(a) {
            if(a.getState() ==="SUCCESS"){
            	component.set("v.lstAlerts", a.getReturnValue());
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
    
    toList : function(component, event) {
        var action = component.get("c.getReturnUrl");
        action.setCallback(this, function(a) {
            if (a.getState() === "SUCCESS") {                
                if(component.isValid()) {
           			var url = a.getReturnValue();
                    component.set("v.listURL", url);
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
    },
    setNamespace : function(component) {
  		
        var component_to_string = component.toString();
        
        var markupTagLoc = component_to_string.indexOf('markup://');
        var endOfNamespaceLoc = component_to_string.indexOf(':',markupTagLoc+9);
        var ns = component_to_string.substring(markupTagLoc+9,endOfNamespaceLoc);
        
        var namespacePrefix = (ns == "c" || ns == "C") ?  "" :  ns + "__";
        
  		component.set("v.namespace", ns);
        component.set("v.namespacePrefix", namespacePrefix);
    }
})