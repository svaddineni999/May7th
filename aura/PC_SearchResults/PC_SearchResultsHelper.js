/**
 * Created by vkashikar on 10/16/2019.
 */
({
    setNamespace : function(component) {
        var ns = CH_PC_Util.getNamespace(component);
        var nsPrefix = CH_PC_Util.getNamespacePrefix(component);
        component.set("v.namespace", ns);
        component.set("v.namespacePrefix", nsPrefix);
    },

    initializeAttributes : function(component, event, helper) {
        var action = component.get("c.getOrgNamespace");
        action.setCallback(this,function(response) {
            var state=response.getState();
            if(state=='SUCCESS'){
                var returnValue=response.getReturnValue();
                component.set('v.orgNamespace', returnValue);
                helper.setProperties(component, event, helper);
            }else{
                console.log("SearchResults GetOrgNamespace: Failed with state: " + state);
            }
        });
        $A.enqueueAction(action);
    },

    setProperties : function(component, event, helper) {
        var orgNamespace = component.get("v.orgNamespace");
        //Set Search Results Title Label
        var searchTitleValue;
        var searchTitle = CH_PC_Util.replaceOrgNSPlaceholder(orgNamespace, component.get("v.searchTitle"));
        if(searchTitle.startsWith("$Label.")){
            searchTitleValue = $A.getReference(searchTitle);
        }else{
            searchTitleValue = searchTitle;
        }
        component.set("v.searchTitleValue", searchTitleValue);
        //Set search Result Classes List Attribute
        var resultClassesList = CH_PC_Util.replaceOrgNSPlaceholder(orgNamespace, component.get("v.resultClassesString"));
        component.set("v.resultClassesList", resultClassesList);
    },

    setSearchParams : function(component, event, helper) {
        debugger;
        var identifier = event.getParam("identifier");
        component.set("v.identifier", identifier);

        var searchObjectAPIName = event.getParam("searchObjectAPIName");
        component.set("v.searchObjectAPIName", searchObjectAPIName);

        var searchFormFieldsetAPIName = event.getParam("searchFormFieldsetAPIName");
        component.set("v.searchFormFieldsetAPIName", searchFormFieldsetAPIName);

        var searchResultFieldsetAPIName = event.getParam("searchResultFieldsetAPIName");
        component.set("v.searchResultFieldsetAPIName", searchResultFieldsetAPIName);

        var searchParams = event.getParam("searchParams");
        component.set("v.searchParams", searchParams);


        console.log('PC_SearchParam event parameters');
        console.log('identifier = ' + identifier);
        console.log('searchObjectAPIName = ' + searchObjectAPIName);
        console.log('searchFormFieldSetAPIName = ' + searchFormFieldsetAPIName);
        console.log('searchParams = ');
        console.log(JSON.stringify(searchParams));
        console.log('searchResultsFieldSetAPIName = ' + searchResultFieldsetAPIName);
    },
    validateSearchParams : function(component, event, helper) {
        var identifier = component.get("v.identifier", identifier);
        var searchObjectAPIName = component.get("v.searchObjectAPIName");
        var searchFormFieldSetAPIName = component.get("v.searchObjectAPIName");
        var searchResultsFieldSetAPIName = component.get("v.searchResultFieldsetAPIName");
        var errorMessage = 'Following Search Params were found to be empty';
        var isValid = true;
        if($A.util.isEmpty(identifier)) {
            errorMessage = errorMessage + 'identifer';
            isValid = false;
        }
        if($A.util.isEmpty(searchObjectAPIName)) {
            errorMessage = errorMessage + ',searchObjectAPIName';
            isValid = false;
        }
        if($A.util.isEmpty(searchFormFieldSetAPIName)) {
            errorMessage = errorMessage + ',searchFormFieldSetAPIName';
            isValid = false;
        }
        if($A.util.isEmpty(searchResultsFieldSetAPIName)) {
            errorMessage = errorMessage + ',searchResultsFieldSetAPIName';
            isValid = false;
        }
        errorMessage = errorMessage + '. Cannot continue, please contact the adminstrator.';
        if(isValid == false) {
            component.set("v.errors", [errorMessage]);
            // SHOW ERROR in Error Panel
        }
        return isValid;

    },
    clearAttributes : function(component, event, helper) {
        //component.find("resultClasses").innerHTML = "";
        component.set("v.errors", []);
        var temp;
        component.set("v.resultClasses",temp);
        component.find("noneOfThese").set("v.value",null);
    },
    setResultClasses : function(component, event, helper) {
        if($A.util.isEmpty(component.get("v.resultClassesList"))) {
            // Do nothing
        }
        else {
            var resultClassesString = component.get("v.resultClassesList");
            resultClassesString = resultClassesString.replace(/ /g, ''); //Replace all spaces
            component.set("v.resultClasses",resultClassesString.split(","));
            console.log('@vj');
            console.log(resultClassesString);
            console.log(component.get("v.resultClasses"));
        }
    },
    loadResultsCmp : function(component, event, helper) {
        debugger;
        component.set("v.body",[]);
        var noSearchParams;
        var allAttributesObj = {"identifier":"","searchObjectAPIName":"",
                            "searchFormFieldsetAPIName":"","searchResultFieldsetAPIName":"",
                            "searchParams":noSearchParams,"resultClass":"","defaultRowActions":""};
        var errors;
        var componentName = component.get("v.namespace") + ":PC_SearchResultsHelper";
        allAttributesObj['identifier'] = component.get("v.identifier");
        allAttributesObj['searchObjectAPIName'] = component.get("v.searchObjectAPIName");
        allAttributesObj['searchFormFieldsetAPIName'] = component.get("v.searchFormFieldsetAPIName");
        allAttributesObj['searchResultFieldsetAPIName'] = component.get("v.searchResultFieldsetAPIName");
        allAttributesObj['searchParams'] = component.get("v.searchParams");
        allAttributesObj['searchTableHeight'] = component.get("v.searchTableHeight");
        allAttributesObj['defaultRowActions'] = component.get("v.defaultRowActions");
        var resultClasses = component.get("v.resultClasses");
        var body = component.get("v.body");
        if(!$A.util.isEmpty(resultClasses) && resultClasses.length > 0) {
            for(var i=0; i < resultClasses.length; i++) {
                allAttributesObj['resultClass'] = resultClasses[i];

                try {
                    $A.createComponent(
                        componentName,
                        allAttributesObj,
                        function(newComponent, status, errorMessage) {
                            if(status == "SUCCESS") {
                                body.push(newComponent);
                                component.set("v.body", body);
                                console.log("Successfully created component with name " + componentName);
                            }
                            else {
                                errors = component.get("v.errors");
                                errors.push("Error while creating component with name " + componentName);
                                component.set("v.errors", errors);
                                console.error("Error while creating component with name " + componentName);
                            }
                        }
                    );
                }
                catch(err) {
                    errors.push("Error while creating component with name " + componentName + '. Error -> ' + err);
                    component.set("v.errors", errors);
                }
            }
        }
    },
    fireSelectedRecordHelper : function(component, event, helper) {
        //helper.clearAttributes(component, event, helper);
        debugger;
        var appEvent = $A.get("e.c:PC_SelectedRecord");
        appEvent.setParams({
            "identifier" : component.get("v.identifier"),
            "selectedRecordId" :component.get("v.selectedRecordId"),
            "sourceUniqueId" :component.get("v.selectedRecordSource"),
            "searchParams" : component.get("v.searchParams"),
            "actionType" : component.get("v.actionType"),
            "actionName" : component.get("v.actionName"),
        });
        appEvent.fire();
        console.log("PC_SelectedRecord event fired successfully");
        component.set("v.tempMessage", "PC_SelectedRecord event fired successfully");

        //helper.setResultClasses(component, event, helper);
    },
    fireUnselectEvent : function(component, event, helper) {
        var appEvent = $A.get("e.c:PC_UnselectDataTableRow");
        appEvent.setParams({
            "currentSelectedRecordId" : component.get("v.selectedRecordId"),
            "currentSelectionSource" : component.get("v.selectedRecordSource")
        });
        appEvent.fire();

    },
    fireUnselectEventForNone : function(component, event, helper) {
        var appEvent = $A.get("e.c:PC_UnselectDataTableRow");
        appEvent.setParams({
            "currentSelectedRecordId" : component.get("v.selectedRecordId"),
            "currentSelectionSource" : ''
        });
        appEvent.fire();

    }
})