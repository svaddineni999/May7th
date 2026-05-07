/**
 * Created by vkashikar on 7/7/2021.
 */
({
    setNamespace : function(component) {
        var ns = CH_PC_Util.getNamespace(component);
        var nsPrefix = CH_PC_Util.getNamespacePrefix(component);
        component.set("v.namespace", ns);
        component.set("v.namespacePrefix", nsPrefix);
    },
    clearErrors : function(component) {
        var errors = [];
        component.set("v.errors", errors);
    },
    getInvitationResults: function(component, event, helper) {
        component.set("v.inProgress",true);
        var action = component.get("c.getInvitationResult");
        action.setParams({
            'engagementProgramId' : component.get("v.engagementProgramId"),
            'caseId' : component.get("v.caseId"),
            'accountId' : component.get("v.accountId"),
            'workflowContext': component.get("v.workflowContext")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                debugger;
                var returnValue = response.getReturnValue();
                console.log(returnValue);
                component.set('v.columns', returnValue.columns);
                component.set('v.rows', returnValue.rows);
            } else {
                var errors = [];
                var err = '';
                if(Array.isArray(response.getError()) && !$A.util.isEmpty(response.getError()[0]['message'])) {
                    err = response.getError()[0].message;
                }
                errors.push(component.get("v.standardLoggedErrorMessage") + err);
                component.set("v.errors", errors);
            }
            component.set("v.inProgress",false);
        });
        $A.enqueueAction(action);

    },
    setURLParamValues:function(component,event,helper) {
            debugger;
            var sPageURL = decodeURIComponent(window.location.search.substring(1));
            var accountRecordIdParam = component.get('v.namespace')+'__accountId';
            var caseRecordIdParam = component.get('v.namespace')+'__caseId';
            var engagementProgramIdParam = component.get('v.namespace')+'__'+component.get('v.engagementProgramUrlFieldName');
            var workflowSurveyContextParam = component.get('v.namespace')+'__workflowSurveyContext';
            var sURLVariables = sPageURL.split('&');
            var sParameterName;
            var i;
            var j;

            for (i = 0; i < sURLVariables.length; i++) {
                sParameterName = sURLVariables[i].split('=');

                for(j = 0;j<sParameterName.length;j++){

                    if (sParameterName[j] == accountRecordIdParam) {
                        component.set("v.accountId", sParameterName[j+1]);
                    }
                    else if(sParameterName[j] == caseRecordIdParam) {
                        component.set("v.caseId", sParameterName[j+1]);
                    }
                    else if(sParameterName[j] == engagementProgramIdParam){
                        component.set("v.engagementProgramId", sParameterName[j+1]);
                    }
                    else if(sParameterName[j] == workflowSurveyContextParam){
                        component.set("v.workflowContext", sParameterName[j+1]);
                    }
                }
            }
        }
})