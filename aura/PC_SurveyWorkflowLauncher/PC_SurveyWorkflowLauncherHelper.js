/**
 * Created by havalakki on 6/11/2021.
 */
({
    setNamespace : function(component) {
            var ns = CH_PC_Util.getNamespace(component);
            var nsPrefix = CH_PC_Util.getNamespacePrefix(component);
            component.set("v.namespace", ns);
            component.set("v.namespacePrefix", nsPrefix);
     },

    checkIfRecordIdAccountOrCase : function(component, event, helper){
        var action= component.get("c.getAccountCaseDetails");
        action.setParams({
             "recordIdValue": component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
         if (response.getState() == "SUCCESS") {
             var returnValue = response.getReturnValue();
             component.set('v.accountIdValue',returnValue.accountId);
             component.set('v.engProgramIdValue',returnValue.engagementProgramId);
             component.set('v.caseRecordId',returnValue.caseId);

             if(returnValue.caseId!=null && returnValue.engagementProgramId!=null){
                helper.navigateToSurveyInvitationPage(component, event, helper);
             }else{
                 helper.navigateToCmp(component, event, helper);
             }

         } else{
             var errors = [];
             errors.push(component.get('v.caseDetailsErrorMessage'));
             component.set("v.errors", errors);
         }
        });
        $A.enqueueAction(action);
    },

    navigateToCmp : function (component, event, helper) {
            debugger;
            var tabParamsObject = new Object();
            var urlParams={};
                var ns = component.get("v.namespace");
                var pageAPIName = null;
                var nsPrefix = component.get("v.namespacePrefix");
                var qualifiedIdName = CH_PC_Util.getQualifiedQueryParam(component, 'Id' , ns);
                var accountFieldSetName = CH_PC_Util.getQualifiedQueryParam(component, 'accountFieldSetAPIName', ns);
                var caseFieldSetName = CH_PC_Util.getQualifiedQueryParam(component,'caseFieldsetAPIName', ns);
                var workflowSurveyContextAttrName = CH_PC_Util.getQualifiedQueryParam(component,'workflowSurveyContext' , ns);

                var componentAPIName;
                var recordId = component.get('v.recordId');
                var caseRecordId = component.get('v.caseRecordId');
                var accountIdValue = component.get('v.accountIdValue');
                var engProgramIdValue = component.get('v.engProgramIdValue');

                if((accountIdValue!= null && accountIdValue!= undefined && accountIdValue!= '') &&
                (caseRecordId==null || caseRecordId==undefined && caseRecordId=='')){
                    componentAPIName = ns + ':' + 'PC_SurveyWorkflow';
                }
                else if((recordId!=null && accountIdValue!=null && caseRecordId!=null) ||
                        (recordId==null || recordId==undefined || recordId=='')){
                    componentAPIName = ns + ':' + 'PC_ParentSurveyWorkflow';
                }

                if(componentAPIName!='' && componentAPIName!=null && componentAPIName!=undefined)
                {
                    var workspaceAPI = component.find("workspaceAPI");
                    tabParamsObject[qualifiedIdName] = component.get('v.recordId');
                    tabParamsObject[workflowSurveyContextAttrName] = component.get('v.workflowSurveyContext');
                    tabParamsObject[accountFieldSetName] = component.get('v.accountFieldSetAPIName');
                    tabParamsObject[caseFieldSetName] = component.get('v.caseFieldsetAPIName');

                    urlParams[qualifiedIdName]=component.get('v.recordId');
                    urlParams[workflowSurveyContextAttrName] = component.get('v.workflowSurveyContext');
                    urlParams[accountFieldSetName] = component.get('v.accountFieldSetAPIName');
                    urlParams[caseFieldSetName] = component.get('v.caseFieldsetAPIName');

                    var urlParamsString = CH_PC_Util.convertIntoURLParamsFormat(urlParams);
                    var pageReferenceSurvey = {"type": "standard__component",
                                                   "attributes": {
                                                       "componentName": componentAPIName
                                                   },
                                                   "state": tabParamsObject
                                                 }

                     workspaceAPI.isConsoleNavigation().then(function(isConsole) {
                        if (isConsole) {
                            workspaceAPI.getEnclosingTabId().then(function(enclosingTabId) {
                                 if (!enclosingTabId) {
                                     workspaceAPI.openTab({
                                         pageReference: pageReferenceSurvey,
                                         focus: true
                                     }).then(function(newTabId) {
                                         workspaceAPI.setTabLabel({
                                           tabId: newTabId,
                                           label: component.get('v.surveyEligibilityCheckLabel')
                                         });
                                         workspaceAPI.setTabIcon({
                                           tabId: newTabId,
                                           icon: component.get("v.accountCaseDetailsTabIcon"),
                                           iconAlt: component.get('v.surveyEligibilityCheckLabel')
                                         });
                                     });
                                 }else {
                                     workspaceAPI.openSubtab({
                                         parentTabId: enclosingTabId,
                                         pageReference: pageReferenceSurvey,
                                         focus: true
                                     }).then(function(newTabId) {
                                         workspaceAPI.setTabLabel({
                                           tabId: newTabId,
                                           label: component.get('v.surveyEligibilityCheckLabel')
                                         });
                                         workspaceAPI.setTabIcon({
                                           tabId: newTabId,
                                           icon: component.get("v.accountCaseDetailsTabIcon"),
                                           iconAlt: component.get('v.surveyEligibilityCheckLabel')
                                         });
                                     });
                                 }
                             });
                        }
                        else {
                            var url = '/lightning/cmp/' + componentAPIName +'?'+urlParamsString;
                            window.open(url,"_blank");
                        }
                     })
                     .catch(function(error) {

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

         },

    navigateToSurveyInvitationPage : function (component, event, helper) {
        debugger;
        var ns = component.get("v.namespace");
        var qualifiedIdName = CH_PC_Util.getQualifiedQueryParam(component, 'caseId' , ns);
        var engProgramIdQualifiedName = CH_PC_Util.getQualifiedQueryParam(component, component.get('v.engagementProgramUrlFieldName'), ns);
        var workflowSurveyContextAttrName = CH_PC_Util.getQualifiedQueryParam(component,'workflowSurveyContext' , ns);
        var componentAPIPage = ns + '__'+ component.get('v.surveyInvitationPageName');
        var urlParams={};
        urlParams[qualifiedIdName] = component.get('v.recordId');
        urlParams[engProgramIdQualifiedName] = component.get('v.engProgramIdValue');
        urlParams[workflowSurveyContextAttrName] = component.get('v.workflowSurveyContext');

        var workspaceAPI = component.find("workspaceAPI");
        var urlParamsString = CH_PC_Util.convertIntoURLParamsFormat(urlParams);
        var pageReference = component.get('v.pageReference');

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
                                  label: component.get('v.surveyEligibilityCheckLabel')
                                });
                                workspaceAPI.setTabIcon({
                                  tabId: newTabId,
                                  icon: component.get("v.tabIcon"),
                                  iconAlt: component.get('v.surveyEligibilityCheckLabel')
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
                                  label: component.get('v.surveyEligibilityCheckLabel')
                                });
                                workspaceAPI.setTabIcon({
                                  tabId: newTabId,
                                  icon: component.get("v.tabIcon"),
                                  iconAlt: component.get('v.surveyEligibilityCheckLabel')
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
})