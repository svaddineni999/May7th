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
    
    getPAInfo : function(component){
        var action = component.get("c.getPARecords");
        action.setParams({
            "programId"		: component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                var returnValue = response.getReturnValue();
                component.set("v.paInfo", returnValue);
                if (returnValue==null || returnValue.length==0) {
                    component.set("v.isDataAvailable", false);
                }
                else {
                    component.set("v.isDataAvailable", true);
                }
            } else {
                console.log("Failed with state: " + state);
            }
        });
        $A.enqueueAction(action);
    },
    
    isPACaseActive : function(component){
        component.set("v.isPAActive", false);
        /*var action = component.get("c.isPACaseActive");
        action.setParams({
            "programId"		: component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                var returnValue = response.getReturnValue();
                component.set("v.isPAActive", returnValue);
             } else {
                console.log("Failed with state: " + state);
            }
        });
        $A.enqueueAction(action);*/
    },
    
    gotoURL : function (component, event, helper, url) {
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": url
        });
        urlEvent.fire();
    },
    
    getPARecordTypeId : function(component, objName){
        var action = component.get("c.getPARecordTypeId");
        action.setParams({
            "objName"		: objName
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                component.set("v.paRecTypeId", response.getReturnValue());
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
    applyCSS: function(component){
        component.set("v.cssStyle", ".slds-modal__container{margin: 10 auto; max-width: 90% !important; min-width: 90% !important;} ");
    },
    revertCssChange: function(component){
        component.set("v.cssStyle", ".slds-modal__container{}");
    },
    
})