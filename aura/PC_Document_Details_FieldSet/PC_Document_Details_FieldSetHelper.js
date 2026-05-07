({
    setNamespace : function(cmp) {
        var component_to_string = cmp.toString();
        var markupTagLoc = component_to_string.indexOf('markup://');
        var endOfNamespaceLoc = component_to_string.indexOf(':',markupTagLoc+9);
        var ns = component_to_string.substring(markupTagLoc+9,endOfNamespaceLoc);
        var namespacePrefix = (ns == "c" || ns == "C") ?  "" :  ns + "__";
        cmp.set("v.fsName", namespacePrefix+(cmp.get("v.fsName")));
        cmp.set("v.typeName", namespacePrefix+(cmp.get("v.typeName")));
    }
})