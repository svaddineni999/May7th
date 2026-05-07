/**
 * Created by havalakki on 4/8/2019.
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

    geteLetterPreviewDetails: function(component,event,helper){
        debugger;
        if(component.get("v.eLetterId")!=component.get("v.noneValue") && component.get("v.eLetterId")!=undefined){
            var action = component.get("c.previewEletterDetails");
                                    action.setParams({
                            			"letterId": component.get("v.eLetterId")
                            		});
                                    action.setCallback(this, function(a) {
                                        var state = a.getState();
                                        if (state === 'SUCCESS'){
                                            component.set('v.previewComponentName', a.getReturnValue().previewComponentName);
                                            component.set('v.eLetterTemplatePreviewTitle',a.getReturnValue().eLetterPreviewTitle);
                                            helper.createEletterPreviewComponent(component, event, helper);
                                        } else if (state === "ERROR") {
                            				console.log('Error in fetching eLetter template body');
                            			}
                            		});
                                    $A.enqueueAction(action);
        }
        else{
            debugger;
            var previewEvent=component.getEvent('eLetterEvent');
            previewEvent.setParams({"isEletterInvalid" : true});
            previewEvent.fire();
        }

    },

     createEletterPreviewComponent: function(component, event, helper){
            debugger;
            var namespace = component.get("v.namespace");
            var componentName = component.get("v.previewComponentName");
            var url = '/'+namespace+'/PC_eLetterPreviewApp.app'+'?eLetterId=' + component.get('v.eLetterId') +'&recordId='+component.get('v.recordId')+'&eLetterPreviewTitle='+component.get('v.eLetterTemplatePreviewTitle')+ '&dynamicPreviewCmpName=' + componentName;

            window.open(url,component.get('v.eLetterTemplatePreviewTitle'),"toolbar=yes,scrollbars=yes,resizable=yes,left=20,top=100,width=800,height=650");


      }

})