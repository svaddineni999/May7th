/**
 * Created by havalakki on 4/9/2019.
 */
({
    setNamespace : function(component) {

                var component_to_string = component.toString();
                console.log(component_to_string);
                var markupTagLoc = component_to_string.indexOf('markup://');
                console.log(markupTagLoc);
                var endOfNamespaceLoc = component_to_string.indexOf(':',markupTagLoc+9);
                console.log(endOfNamespaceLoc);

                var ns = component_to_string.substring(markupTagLoc+9,endOfNamespaceLoc);
                console.log(ns);
                var namespacePrefix = (ns == "c" || ns == "C") ?  "" :  ns + "__";
                console.log(namespacePrefix);
                component.set("v.namespace", ns);
                component.set("v.namespacePrefix", namespacePrefix);

    },

    previewEletter: function(component, event, helper){
        var action = component.get("c.previewEletterContent");
        action.setParams({
            "letterId": component.get("v.eLetterId"),
            "sObjectRecordId": component.get("v.recordId")
        });
        action.setCallback(this, function(a) {
            var state = a.getState();
            if (state === 'SUCCESS'){
                component.set('v.eLetterPreviewData',a.getReturnValue().eLetterPreviewData);
            } else if (state === "ERROR") {
                console.log('Error in fetching eLetter template body');
            }
        });
        $A.enqueueAction(action);
        }
})