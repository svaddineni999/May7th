({
    fetchAEList: function (component, event, helper){

        component.set("v.isLoading", true);
        var action =  component.get("c.getRelAERecs");
        action.setParams({
            caseId: component.get("v.recordId")
        });
        action.setCallback(this, function(response){
            var state= response.getState();

            if (state == "SUCCESS"){
                var relAEList =response.getReturnValue();
                component.set("v.AEList", relAEList.AEList);
                component.set("v.fieldLabels",relAEList.fieldLabels);
                var adverseEventMenuCmpAttributes  = component.get("v.adverseEventMenuCmpAttributes");
                if($A.util.isUndefinedOrNull(adverseEventMenuCmpAttributes)){
                    //If in case PC_AdverseEvents2 is used independently and not through Action center then below line is Important.
                    adverseEventMenuCmpAttributes  = new Object();
                    adverseEventMenuCmpAttributes['additionalInfoTabFieldSet'] = relAEList.fieldsetName;
                    if(relAEList.hideAdditionalInfoTab){
                        adverseEventMenuCmpAttributes['hideAdditionalInfoTab'] = true;
                    }
                    if(!relAEList.isCaseObject){
                       adverseEventMenuCmpAttributes['usePrescriptionForSuspectProducts'] = false;
                    }
                    //Below attribute is required when PC_AdverseEvents2 component is used both through action center and also added on case page layout
                    component.set("v.isActionCenterComponent",false);
                }
                adverseEventMenuCmpAttributes['dateFormat'] = relAEList.dateFormat;
                component.set("v.adverseEventMenuCmpAttributes",adverseEventMenuCmpAttributes);
                component.set("v.dateFormatErrorMessage" ,relAEList.dateFormatErrorMessage);
                helper.setAEMenuProperties(component,event,helper);
                 //component.set("v.errors",'This is testing , error check');
            }
			else {
                //helper.handleErrors(response.getError());

                component.set("v.errors",response.getError());
            }
            component.set("v.isLoading", false);
        });
        $A.enqueueAction(action);
    },
    setAEMenuProperties : function(component,event,helper){
        var actionCenterAEAttributes = component.get("v.adverseEventMenuCmpAttributes");
        if(!actionCenterAEAttributes.hasOwnProperty('hideAdditionalInfoTab')){
            actionCenterAEAttributes['hideAdditionalInfoTab'] = component.get("v.hideAdditionalInfoTab");
        }
        if(!actionCenterAEAttributes.hasOwnProperty('usePrescriptionForSuspectProducts')){
            actionCenterAEAttributes['usePrescriptionForSuspectProducts'] = component.get("v.usePrescriptionForSuspectProducts");
        }
        if(!actionCenterAEAttributes.hasOwnProperty('useRxForMI')){
            actionCenterAEAttributes['useRxForMI'] = component.get("v.useRxForMI");
        }
        if(!actionCenterAEAttributes.hasOwnProperty('hideCoding')){
            actionCenterAEAttributes['hideCoding'] = component.get("v.hideCoding");
        }
        if(!actionCenterAEAttributes.hasOwnProperty('hideMfr')){
            actionCenterAEAttributes['hideMfr'] = component.get("v.hideMfr");
        }
        if(!actionCenterAEAttributes.hasOwnProperty('hideNotes')){
            actionCenterAEAttributes['hideNotes'] =  component.get("v.hideNotes");
        }
        component.set("v.adverseEventMenuCmpAttributes",actionCenterAEAttributes);
    },
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

    clearErrorMessages : function(component, event, helper) {
        var errors;
        component.set("v.errors", errors);
    },

    clearAEListAttributes : function(component, event, helper) {
        component.set("v.AEList",null);
        component.set("v.fieldLabels",null);
    },
    fetchDownloadPDFPageName: function(component,event,helper){

               var action=component.get("c.getAEDownloadPDFPageName");
                action.setCallback(this,function(response){
                    var state=response.getState();
                    debugger;
                    if((state=="SUCCESS") && (!$A.util.isEmpty(response.getReturnValue()))){
                        component.set('v.vfPageName',response.getReturnValue());
                    }
                });
               $A.enqueueAction(action);
    },

})