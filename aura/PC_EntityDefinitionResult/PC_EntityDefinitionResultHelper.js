/**
 * Created by tusarora on 3/13/2020.
 */
({
    setNamespace : function(component) {
        console.log('Entered Namespace::::');
        var component_to_string = component.toString();
        console.log('component_to_string::::'+component_to_string);
        var markupTagLoc = component_to_string.indexOf('markup://');
        var endOfNamespaceLoc = component_to_string.indexOf(':',markupTagLoc+9);
        var ns = component_to_string.substring(markupTagLoc+9,endOfNamespaceLoc);
        var namespacePrefix = (ns == "c" || ns == "C") ?  "" :  ns + "__";
        component.set("v.namespace", ns);
        component.set("v.namespacePrefix", namespacePrefix);
    }
})