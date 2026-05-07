({
    getFieldLabels : function(component){
        var action = component.get("c.getFieldLabels");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                var returnValue = response.getReturnValue();
                component.set("v.fieldLabels", returnValue);
            } else {
                console.log("Failed with state: " + state);
            }
        });
        $A.enqueueAction(action);
    },
    
    getRefInfo : function(component){
        var action = component.get("c.getRefRecords");
        action.setParams({
            "programId"		: component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                var returnValue = response.getReturnValue();
                component.set("v.refInfo", returnValue);
                if (returnValue==null || returnValue.length==0) {
                    component.set("v.isDataAvailable", false);
                }
                    
            } else {
                console.log("Failed with state: " + state);
            }
        });
        $A.enqueueAction(action);
    },
    
    isReferralActive : function(component){
        var action = component.get("c.isReferralActive");
        action.setParams({
            "programId"		: component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                debugger;
                var returnValue = response.getReturnValue();
                component.set("v.isRefActive", returnValue);
             } else {
                console.log("Failed with state: " + state);
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
    },

    clearErrorMessages : function(component) {
        var errors = [];
        component.set("v.errors", errors);
    },

    setRecordId : function(component, event, helper) {
        if(!$A.util.isEmpty(component.get("v.relatedToId"))
                             && !$A.util.isEmpty("v.relatedToObject")
                             && component.get("v.relatedToObject").toLowerCase() == 'case')
        {
            component.set("v.recordId", component.get("v.relatedToId"));
            component.set("v.disabled", false);
        } else {
            component.set("v.disabled", true);
        }
    }
    
})