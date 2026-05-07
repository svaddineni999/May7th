/**
 * Created by vkashikar on 10/17/2019.
 */
({
    getResults : function(component, event, helper) {
        debugger;
        var action = component.get("c.search");
        component.set("v.inProgress",true);
        var searchDetails = new Map();
        searchDetails['identifier'] = component.get("v.identifier");
        searchDetails['searchObjectAPIName'] = component.get("v.searchObjectAPIName");
        searchDetails['searchFormFieldsetAPIName'] = component.get("v.searchFormFieldsetAPIName");
        searchDetails['searchResultFieldsetAPIName'] = component.get("v.searchResultFieldsetAPIName");
        searchDetails['searchParamsJSON'] = JSON.stringify(component.get("v.searchParams"));
        searchDetails['resultClass'] = component.get("v.resultClass");
        searchDetails['defaultRowActions'] = component.get("v.defaultRowActions");
        action.setParams({
            "searchDetails" : searchDetails
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                var returnValue = response.getReturnValue();
                if(!$A.util.isEmpty(returnValue)) {
                    if(!$A.util.isEmpty(returnValue['rows'])) {
                        component.set("v.rows", returnValue.rows);
                        component.set("v.keyField" , returnValue.keyFieldAPIName);
                        component.set("v.noResultsMessage", returnValue.noResultsMessage);
                    }
                    if(!$A.util.isEmpty(returnValue['columns'])) {
                        if(!$A.util.isEmpty(returnValue['customRowActions'])) {
                            component.set("v.customRowActions", returnValue.customRowActions); // may be we can remove this along with the attributes
                            var columnsWithActions = returnValue.columns;
                            columnsWithActions.push({ type: 'action', typeAttributes: { rowActions: returnValue.customRowActions, menuAlignment: 'auto' } });
                            component.set('v.columns', columnsWithActions);
                        }
                        else {
                            component.set("v.columns", returnValue.columns);
                        }
                    }
                    if(!$A.util.isEmpty(returnValue['title'])) {
                        component.set("v.title", returnValue.title);
                    }
                    if(!$A.util.isEmpty(returnValue['sourceUniqueId'])) {
                        component.set("v.sourceUniqueId", returnValue.sourceUniqueId);
                    }
                }
            }
            else {
                var errors = component.get("v.errors");
                errors.push(response.getError()[0].message);
                component.set("v.errors",errors);
            }
            component.set("v.inProgress",false);
        });
        $A.enqueueAction(action);
    }
})