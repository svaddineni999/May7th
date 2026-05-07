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
                     adverseEventMenuCmpAttributes['dateFormat'] = relAEList.dateFormat;
                     component.set("v.adverseEventMenuCmpAttributes",adverseEventMenuCmpAttributes );
                     component.set("v.dateFormatErrorMessage" ,relAEList.dateFormatErrorMessage );
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
                    if((state=="SUCCESS") && (!$A.util.isEmpty(response.getReturnValue()))){
                        component.set('v.vfPageName',response.getReturnValue());
                    }
                });
               $A.enqueueAction(action);
    },

})