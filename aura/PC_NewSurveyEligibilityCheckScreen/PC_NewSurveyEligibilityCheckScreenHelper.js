/**
 * Created by havalakki on 6/3/2021.
 */
({
    setNamespace : function(component) {
            var ns = CH_PC_Util.getNamespace(component);
            var nsPrefix = CH_PC_Util.getNamespacePrefix(component);
            component.set("v.namespace", ns);
            component.set("v.namespacePrefix", nsPrefix);
     },

    getAccountCaseDetails : function(component,event,helper) {
            var action= component.get("c.getAccountCaseDetails");
            action.setParams({
                 "recordIdValue": component.get("v.recordId"),
                 "surveyContext": component.get("v.workflowSurveyContext")
            });
            action.setCallback(this, function(response) {

             if (response.getState() == "SUCCESS") {
                 var returnValue = response.getReturnValue();
                 component.set('v.accountIdValue',returnValue.accountId);
                 component.set('v.engProgramIdValue',returnValue.engagementProgramId);
                 component.set('v.caseRecordId',returnValue.caseId);
                 component.set('v.newSurveyEligibilityCheckLabel',returnValue.newSurveyEligibilityCheckTitle);

                 if(returnValue.accountId!=null){
                    component.find('accountAuraId').set('v.value',returnValue.accountId);
                 }
                 if(returnValue.engagementProgramId!=null){
                     component.find('engagementProgAuraId').set('v.value',returnValue.engagementProgramId);
                 }

             } else {
                 var errors = [];
                 errors.push(component.get('v.caseDetailsErrorMessage'));
                 component.set("v.errors", errors);
             }
            });
            $A.enqueueAction(action);
    },

    navigateToSurveyInvitationPage : function (component, event, helper,actionName) {
        debugger;
            var ns = component.get("v.namespace");
            var qualifiedIdName;
            var accountDataValid =true;
            var caseRecordId = component.get('v.caseRecordId');
            var accountRecordId = component.get('v.accountIdValue');
            var errorMessage='';

            if(caseRecordId!=null && caseRecordId!=undefined && caseRecordId!=''){
                if(component.find('accountAuraId').get('v.value') == accountRecordId){
                    accountDataValid = true;
                }
                else{
                    accountDataValid = false;
                    errorMessage = component.get('v.invalidAccountOnCase');
                }

                qualifiedIdName = CH_PC_Util.getQualifiedQueryParam(component, 'caseId' , ns)
            }
            else if(accountRecordId!=null && accountRecordId!=undefined && accountRecordId!=''){
                qualifiedIdName = CH_PC_Util.getQualifiedQueryParam(component, 'accountId' , ns)
            }

            if(accountDataValid){
                var engProgramIdQualifiedName = CH_PC_Util.getQualifiedQueryParam(component, component.get('v.engagementProgramUrlFieldName'), ns);
                var workflowSurveyContextAttrName = CH_PC_Util.getQualifiedQueryParam(component,'workflowSurveyContext' , ns);
                var componentAPIPage;
                if(ns!='c' && ns!='' && ns!=undefined){
                    componentAPIPage = ns + '__'+ component.get('v.surveyInvitationPageName');
                }
                else{
                    componentAPIPage = component.get('v.surveyInvitationPageName');
                }
                var urlParams={};
                if(component.get('v.recordId')!=null && component.get('v.recordId')!='null' && component.get('v.recordId')!=undefined && component.get('v.recordId')!=''){
                    urlParams[qualifiedIdName] = component.get('v.recordId');
                }
                else{
                    qualifiedIdName = CH_PC_Util.getQualifiedQueryParam(component, 'accountId' , ns)
                    urlParams[qualifiedIdName] = component.find('accountAuraId').get('v.value');
                }
                urlParams[engProgramIdQualifiedName] = component.find('engagementProgAuraId').get('v.value');
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
            }
            else{
                var errors = [];
                errors.push(errorMessage);
                component.set("v.errors", errors);
            }
    },

clearErrors : function(component) {
    var errors = [];
    component.set("v.errors", errors);
}

})