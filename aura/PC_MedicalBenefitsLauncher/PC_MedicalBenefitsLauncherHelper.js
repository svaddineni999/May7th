/**
 * Created by peharitha on 1/31/2019.
 */
({
    setNamespace : function(component) {
        component.set("v.namespace", CH_PC_Util.getNamespace(component));
        component.set("v.namespacePrefix", CH_PC_Util.getNamespacePrefix(component));
    },
    clearErrorMessages : function(component) {
       var errors;
       component.set("v.errors", errors);
    },
})