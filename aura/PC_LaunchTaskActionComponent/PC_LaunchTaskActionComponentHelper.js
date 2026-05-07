/**
 * Created by vkashikar on 7/9/2020.
 */
({
    setNamespace : function(component, event, helper) {
        var ns = CH_PC_Util.getNamespace(component);
        //var nsPrefix = CH_PC_Util.getNamespacePrefix(component);
        component.set("v.namespace", ns);
        //component.set("v.namespacePrefix", nsPrefix);
    },
    getActionComponent : function(component, event, helper) {
        component.set("v.showSpinner",true);
        var action = component.get("c.getActionComponent");
        action.setParams({
            'taskRecordId' : component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                var returnValue = response.getReturnValue();
                component.set('v.actionComponentDetails', returnValue);
            } else {
                var errors = [];
                var err = '';
                if(Array.isArray(response.getError()) && !$A.util.isEmpty(response.getError()[0]['message'])) {
                    err = response.getError()[0].message;
                }
                errors.push(component.get("v.standardLoggedErrorMessage") + err);
                component.set("v.errors", errors);
                //todo show error toast
            }
            component.set("v.showSpinner",false);
        });
        $A.enqueueAction(action);
    },
    onChangeActionComponentDetails : function(component, event, helper) {
        component.set("v.showSpinner", false);
        helper.clearErrors(component);
        var actionComponentDetails = component.get("v.actionComponentDetails");
        if(actionComponentDetails != null &&
            !$A.util.isEmpty(actionComponentDetails['actionComponent']) &&
            !$A.util.isEmpty(actionComponentDetails['actionComponent']['apiName'])
            )
        {
            var componentName = actionComponentDetails['actionComponent']['apiName'];
            console.log("Trying to create component - " + componentName);
            var consolidatedAttributes = helper.getConsolidatedAttributes(component, actionComponentDetails);
            if(consolidatedAttributes != 'ERROR') {
                component.set("v.showSpinner", true);
                $A.createComponent(
                    componentName, consolidatedAttributes,
                    function(newComponent, status, error) {
                        if(status == 'SUCCESS') {
                            component.set("v.body", newComponent);
                        }
                        else {
                            var errors = [];
                            errors.push(component.get("v.standardClientSideErrorMessage") + ' ' + error);
                            component.set("v.errors", errors);
                        }
                        component.set("v.showSpinner", false);
                    }
                );
            }
        }
        //We won't set any error message on the screen if Action Component name is blank.
    },
    getConsolidatedAttributes : function(component, actionComponentDetails) {
        try {
            var defaultAttributes = {displayModal : false,
                                     taskRecordId : component.get("v.recordId"),
                                     relatedToId: actionComponentDetails['relatedToId'],
                                     relatedToObject : actionComponentDetails['relatedToObject'],
                                     taskDocumentId: actionComponentDetails['documentId']};
            var componentAttributes = JSON.parse(actionComponentDetails['actionCenterAttributes']); // expected to be a JSON
            var consolidatedAttributes = defaultAttributes;
            for(var key in componentAttributes) {
               consolidatedAttributes[key] = componentAttributes[key];
            }
            return consolidatedAttributes;
        }
        catch(err) {
            var errors = [];
            errors.push(component.get("v.standardClientSideErrorMessage") + ' ' + err);
            component.set("v.errors", errors);
            return 'ERROR';
        }
    },
    clearErrors : function(component) {
        var errors = [];
        component.set("v.errors", errors);
    }
})