/**
 * Created by peharitha on 9/30/2019.
 */
({
    setNamespace : function(component) {
        var ns = CH_PC_Util.getNamespace(component);
        var nsPrefix = CH_PC_Util.getNamespacePrefix(component);
        component.set("v.namespace", ns);
        component.set("v.namespacePrefix", nsPrefix);
    },
    clearErrorMessages : function(component) {
        var errors;
        component.set("v.errors", errors);
    },
    readQueryParams : function(component, event, helper) {
        var namespace = component.get("v.namespace");
        var identifierParam = CH_PC_Util.getQualifiedQueryParam(component,'identifier',namespace);
        var identifier;
        var pageReference = component.get("v.pageReference");
        if(pageReference != null && pageReference.state[identifierParam] != 'NULL' && pageReference.state[identifierParam] != 'undefined'){
            identifier = pageReference.state[identifierParam];
        }else{
            var query = location.search.substr(1);
            var result = {};
            query.split("&").forEach(function(part) {
                var item = part.split("=");
                if(!$A.util.isUndefinedOrNull(item[0]) && !$A.util.isUndefinedOrNull(item[1])){
                    result[item[0]] = decodeURIComponent(item[1]);
                }
            });
            identifier = result[identifierParam];
        }
        if(!$A.util.isUndefined(identifier) || !$A.util.isEmpty(identifier)){
            component.set("v.identifier", identifier);
        }
    },
    initializeAttributes : function(component, event, helper) {
        var action = component.get("c.getOrgNamespace");
        action.setCallback(this,function(response) {
            var state=response.getState();
            if(state=='SUCCESS'){
                var returnValue=response.getReturnValue();
                component.set('v.orgNamespace', returnValue);
                helper.setProperties(component, event, helper);
                helper.createSearchForm(component, event, helper);
            }else if(state == 'ERROR') {
                var errors = JSON.stringify(response.getError());
                component.set("v.errors",errors);
            }else{
                console.log("createSearchForm: Failed with state: " + state);
            }
        });
        $A.enqueueAction(action);
    },
    setProperties : function(component, event, helper) {
        var orgNamespace = component.get("v.orgNamespace");
        //Set Button Label
        var buttonName;
        var buttonLabel = CH_PC_Util.replaceOrgNSPlaceholder(orgNamespace,component.get("v.searchButtonLabel"));
        if(buttonLabel.startsWith("$Label.")){
            buttonName = $A.getReference(buttonLabel);
        }else{
            buttonName = buttonLabel;
        }
        component.set("v.searchButtonName", buttonName);
        //Set search Form Field set Name
        var searchFormFieldsetName = CH_PC_Util.replaceOrgNSPlaceholder(orgNamespace, component.get("v.searchFormFieldsetAPIName"));
        component.set("v.searchFormFieldsetName", searchFormFieldsetName);
        //Set search Result Field set Name
        var searchResultsFieldsetName = CH_PC_Util.replaceOrgNSPlaceholder(orgNamespace, component.get("v.searchResultsFieldsetAPIName"));
        component.set("v.searchResultsFieldsetName", searchResultsFieldsetName);
        //Set search Object Name
        var searchObjectName = CH_PC_Util.replaceOrgNSPlaceholder(orgNamespace, component.get("v.searchObjectAPIName"));
        component.set("v.searchObjectName", searchObjectName);
    },
    createSearchForm : function(cmp, event, helper) {
        var action = cmp.get("c.getInitData");
        action.setParams({
            searchObjectAPIName: cmp.get('v.searchObjectName'),
            searchFormFieldsetAPIName: cmp.get('v.searchFormFieldsetName'),
        });
        action.setCallback(this,
            function(response) {
                var state=response.getState();
                if(state=='SUCCESS'){
                    var returnValue=response.getReturnValue();
                    cmp.set('v.fsFields', returnValue.fsFields);
                    var fields = returnValue.listFieldSetMembers;
                    var renamedFields = {};
                    var obj = {};
                    if(fields != null && fields.length > 0){
                       for (var key in fields) {
                           if (fields.hasOwnProperty(key)) {
                               obj[fields[key].fieldPath.replace('.','___')] = '';
                           }
                       }
                       helper.createFieldSetCmp(cmp, event, helper, fields);
                    }
                    else {
                        var noFieldsFoundErrorDescription = cmp.get("v.noFieldsFoundErrorDescription");
                        cmp.set("v.errors",noFieldsFoundErrorDescription);
                    }
                }else if(state == 'ERROR') {
                    var errors = JSON.stringify(response.getError());
                    cmp.set("v.errors",errors);
                }else{
                    console.log("createSearchForm: Failed with state: " + state);
                }
            }
        );
        $A.enqueueAction(action);
    },
    createFieldSetCmp : function(cmp, event, helper, fields) {
        var autofocusFirstField = true;
        $A.createComponent(
            cmp.get("v.namespace") + ":PC_FieldSetForm",
            {
                "fsName": cmp.get("v.searchFormFieldsetName"),
                "typeName": cmp.get("v.searchObjectName"),
                "record": cmp.getReference("v.fsFields"),
                "isValid" : cmp.getReference("v.isFieldSetFormValid"),
                "autofocusFirstField" : autofocusFirstField,
                "noOfItemsInARow": cmp.get("v.fieldsPerRow")
            },
            function(newCmp, status, errorMessage){
                //Add the new button to the body array
                if (status === "SUCCESS") {
                    var body = cmp.get("v.fieldSetFormBody");
                    body.push(newCmp);
                    cmp.set("v.fieldSetFormBody", body);
                }
                else if (status === "ERROR") {
                    cmp.set("v.errors",errorMessage);
                }
            }
        );
    },
    validateFieldSetForm :function(component) {
        component.set("v.isFieldSetFormValid",true);
        if (component.get("v.fieldSetFormBody") != null) {
            var fieldSetCmp = component.get("v.fieldSetFormBody")[0];
            fieldSetCmp.validate(); // this sets v.isFieldSetFormValid.
        }
        return component.get("v.isFieldSetFormValid");
    },
    fireSearchParamsEvent : function (component, event, helper) {
        var identifier = component.get("v.identifier");
        var searchObjectAPIName = component.get("v.searchObjectName");
        var searchFormFieldsetAPIName = component.get("v.searchFormFieldsetName");
        var searchResultsFieldsetAPIName = component.get("v.searchResultsFieldsetName");
        var searchParams = component.get("v.fsFields");
        var searchParamsEvent = $A.get("e.c:PC_SearchParams");
        searchParamsEvent.setParams({
            "identifier" : identifier,
            "searchObjectAPIName" : searchObjectAPIName,
            "searchFormFieldsetAPIName" : searchFormFieldsetAPIName,
            "searchResultFieldsetAPIName" : searchResultsFieldsetAPIName,
            "searchParams" : searchParams});
        searchParamsEvent.fire();
    },
})