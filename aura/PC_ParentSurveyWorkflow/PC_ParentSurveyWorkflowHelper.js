/**
 * Created by havalakki on 6/4/2021.
 */
({
    setNamespace : function(component) {
        var ns = CH_PC_Util.getNamespace(component);
        var nsPrefix = CH_PC_Util.getNamespacePrefix(component);
        component.set("v.namespace", ns);
        component.set("v.namespacePrefix", nsPrefix);
    },

    getAccountCaseDetails : function(component,event,helper) {
        helper.showSpinner(component, event, helper);
        var action= component.get("c.getAccountCaseDetails");
                action.setParams({
                     "recordIdValue": component.get("v.recordId")
                });
        action.setCallback(this, function(response) {

         if (response.getState() == "SUCCESS") {
             var returnValue = response.getReturnValue();
             component.set('v.engagementProgId',returnValue.engagementProgramId);
             component.set('v.accountRecordId',returnValue.accountId);
             component.set('v.caseRecordId',returnValue.caseId);

             if(returnValue.caseId!=null && returnValue.engagementProgramId!=null && returnValue.accountId!=null){
                 helper.navigateToSurveyInvitationPage(component,event,helper);
             }
         } else {
             var errors = [];
             errors.push(component.get('v.caseDetailsErrorMessage'));
             component.set("v.errors", errors);
         }
         helper.hideSpinner(component, event, helper);
        });
        $A.enqueueAction(action);
    },

    showSpinner: function(component, event, helper) {
        var spinner = component.find("papSpinner");
        $A.util.removeClass(spinner, "slds-hide");
    },

    hideSpinner : function(component,event,helper){
        var spinner = component.find("papSpinner");
        $A.util.addClass(spinner, "slds-hide");
    },

    navigateToSurveyInvitationPage : function (component, event, helper,actionName) {
            debugger;
            var ns = component.get("v.namespace");
            var qualifiedIdName = CH_PC_Util.getQualifiedQueryParam(component, 'caseId' , ns);
            var workflowSurveyContextAttrName = CH_PC_Util.getQualifiedQueryParam(component,'workflowSurveyContext' , ns);
            var engProgramIdQualifiedName = CH_PC_Util.getQualifiedQueryParam(component, component.get('v.engagementProgramUrlFieldName'), ns);
            var componentAPIPage = ns + '__'+ component.get('v.surveyInvitationPageName');
            var urlParams={};
            urlParams[qualifiedIdName] = component.get('v.recordId');
            urlParams[engProgramIdQualifiedName] = component.get('v.engagementProgId');
            urlParams[workflowSurveyContextAttrName] = component.get('v.workflowSurveyContext');

            var workspaceAPI = component.find("workspaceAPI");
            var urlParamsString = CH_PC_Util.convertIntoURLParamsFormat(urlParams);

            workspaceAPI.isConsoleNavigation().then(function(isConsole) {
                    if (isConsole) {
                        workspaceAPI.getEnclosingTabId().then(function(enclosingTabId) {
                            if (!enclosingTabId) {
                                workspaceAPI.openTab({
                                    url: '/lightning/n/' + componentAPIPage +'?'+ urlParamsString,
                                    focus: true
                                }).then(function(newTabId) {
                                    workspaceAPI.setTabLabel({
                                      tabId: newTabId,
                                      label: component.get('v.surveyLabel')
                                    });
                                    workspaceAPI.setTabIcon({
                                      tabId: newTabId,
                                      icon: component.get("v.surveyTabIcon"),
                                      iconAlt: component.get('v.surveyLabel')
                                    });
                                    workspaceAPI.refreshTab({
                                        tabId: newTabId
                                    });
                                });
                            }else {
                                workspaceAPI.openSubtab({
                                    parentTabId: enclosingTabId,
                                    focus: true,
                                    url: '/lightning/n/' + componentAPIPage +'?'+ urlParamsString
                                }).then(function(newTabId) {
                                    workspaceAPI.setTabLabel({
                                      tabId: newTabId,
                                      label: component.get('v.surveyLabel')
                                    });
                                    workspaceAPI.setTabIcon({
                                      tabId: newTabId,
                                      icon: component.get("v.surveyTabIcon"),
                                      iconAlt: component.get('v.surveyLabel')
                                    });
                                    workspaceAPI.refreshTab({
                                        tabId: newTabId
                                    });
                                });
                            }
                        });
                    }else {
                        var url = '/lightning/n/' + componentAPIPage +'?'+ urlParamsString;
                        window.open(url,"_self");
                    }
                }).catch(function(error) {

                    if(!$A.util.isEmpty(component.get('v.errors'))){
                        var errorsList = component.get('v.errors');
                        errorsList.push(error);
                        component.set("v.errors", errorsList);
                    }
                    else{
                        var errors = [];
                        errors.push(error);
                        component.set("v.errors", errors);
                    }
                });
        },
    clearErrors : function(component) {
            var errors = [];
            component.set("v.errors", errors);
        }
})