({
    applyCSS: function(component){
        if(component.get("v.displayModal") == "true") {
            component.set("v.cssStyle", ".forceStyle .viewport .oneHeader.slds-global-header_container {z-index:0} .forceStyle.desktop .viewport{overflow:hidden}");
        }
    },
    revertCssChange: function(component){
        component.set("v.cssStyle", ".forceStyle .viewport .oneHeader.slds-global-header_container {z-index:5} .forceStyle.desktop .viewport{overflow:visible}");
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
    setRecordId : function(component, event, helper) {
        if(!$A.util.isEmpty(component.get("v.relatedToId"))
                && !$A.util.isEmpty("v.relatedToObject")
                && component.get("v.relatedToObject").toLowerCase() == 'case')
        {
            component.set("v.recordId", component.get("v.relatedToId"));
        }
    }
})