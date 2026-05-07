/**
 * Created by havalakki on 5/28/2021.
 */
({
    setNamespace : function(component) {
        var ns = CH_PC_Util.getNamespace(component);
        var nsPrefix = CH_PC_Util.getNamespacePrefix(component);
        component.set("v.namespace", ns);
        component.set("v.namespacePrefix", nsPrefix);
    },

    navigateToCmp : function (component, event, helper) {
        debugger;
            var ns = component.get("v.namespace");
            var pageAPIName = null;
            var nsPrefix = component.get("v.namespacePrefix");
            var qualifiedIdName = CH_PC_Util.getQualifiedQueryParam(component, 'Id' , ns);
            var componentAPIName = ns + ':' + component.get('v.surveyEligibilityCheckScreenCompName');
            var workflowSurveyContextAttrName = CH_PC_Util.getQualifiedQueryParam(component,'workflowSurveyContext' , ns);
            var workspaceAPI = component.find("workspaceAPI");
            var tabParamsObject = new Object();
            var urlParams='';
            if(event.getParam('action').name == component.get('v.accountSurveyActionName')){
                tabParamsObject[qualifiedIdName] = component.get('v.recordId');
                urlParams = '?' + qualifiedIdName + '=' + component.get('v.recordId');
            }
            else if(event.getParam('action').name == component.get('v.caseSurveyActionName')){
                tabParamsObject[qualifiedIdName] = event.getParam('row').Id;
                urlParams = '?' + qualifiedIdName + '=' + event.getParam('row').Id;
            }

            tabParamsObject[workflowSurveyContextAttrName] = component.get('v.workflowSurveyContext');
            urlParams=urlParams +'&'+ workflowSurveyContextAttrName + '=' + component.get('v.workflowSurveyContext');

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
                                 pageReference: pageReferenceSurvey,
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
                         }
                     });
                 }else {
                     var url = '/lightning/n/' + componentAPIName + urlParams;
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

    getAccountAndCaseDetails : function(component, event, helper){
        helper.showSpinner(component, event, helper);
        debugger;
        var action= component.get("c.getAccountCaseRecordDetails");
        action.setParams({
             "accountRecordId": component.get("v.recordId"),
             "accountFieldSetAPIName": component.get("v.accountFieldSetAPIName"),
             "caseFieldSetAPIName" : component.get("v.caseFieldsetAPIName")
        });
        action.setCallback(this, function(response) {

         if (response.getState() == "SUCCESS") {
             var returnValue = response.getReturnValue();
             var accountPapEligibilityButton = {label:component.get('v.actionLabel'), fieldName:'papEligibilityCheck', type:'button', typeAttributes:{iconName:'utility:add', iconPosition:'left',label:component.get('v.surveyEligibilityCheckLabel'),name:component.get('v.accountSurveyActionName'),title:component.get('v.buttonTitle'),variant:'Success'}};
             var casePapEligibilityButton = {label:component.get('v.actionLabel'), fieldName:'papEligibilityCheck', type:'button', typeAttributes:{iconName:'utility:add', iconPosition:'left',label:component.get('v.surveyEligibilityCheckLabel'),name:component.get('v.caseSurveyActionName'),title:component.get('v.buttonTitle'),variant:'Success'}};

             var accountColumns = returnValue.accountColumnsWrapper;
             accountColumns.push(accountPapEligibilityButton);
             component.set("v.accountColumns",accountColumns);

             var caseColumns = returnValue.caseColumnsWrapper;
             caseColumns.push(casePapEligibilityButton);
             component.set("v.caseColumns",caseColumns);

             var i=0;
             var caseRecords = returnValue.casesList;
             var engagementProgramFieldAPIName = component.get('v.namespace')+'__'+'PC_Engagement_Program__c';
             for(i=0;i<caseRecords.length;i++){
                 caseRecords[i].caseUrl='/'+caseRecords[i].Id;
                 caseRecords[i].engagementProgramUrl='/'+caseRecords[i][engagementProgramFieldAPIName];
             }

             component.set("v.caseData",caseRecords);

             var accountRecords = returnValue.accountsList;
             for(i=0;i<accountRecords.length;i++){
                  accountRecords[i].accountUrl='/'+accountRecords[i].Id;
              }

              component.set("v.accountData",accountRecords);
             if(!$A.util.isEmpty(returnValue.casesList)){
                component.set('v.showCaseRecords',true);
             }
             else{
                 component.set('v.showCaseRecords',false);
             }

         } else {
             var errors = [];
             errors.push(component.get('v.accountCaseDetailsErrorMessage'));
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
        var engProgramIdQualifiedName = CH_PC_Util.getQualifiedQueryParam(component, component.get('v.engagementProgramUrlFieldName'), ns);
        var workflowSurveyContextAttrName = CH_PC_Util.getQualifiedQueryParam(component,'workflowSurveyContext' , ns);
        var componentAPIPage;
        if(!$A.util.isEmpty(ns) && ns!='c'){
            componentAPIPage = ns + '__'+ component.get('v.surveyInvitationPageName');
        }
        else{
            componentAPIPage = component.get('v.surveyInvitationPageName');
        }
        var urlParams={};
        urlParams[qualifiedIdName] = event.getParam('row').Id;
        urlParams[engProgramIdQualifiedName] = component.get('v.engagementProgramId');
        debugger;
        urlParams[workflowSurveyContextAttrName] = component.get('v.workflowSurveyContext');

        var workspaceAPI = component.find("workspaceAPI");
        var urlParamsString = CH_PC_Util.convertIntoURLParamsFormat(urlParams);
        var pageReference = component.get('v.pageReference');

        debugger;
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

    launchSurvey : function(component,event,helper) {
       debugger;
        var engProgramIdFieldAPIName = component.get('v.namespace')+'__'+component.get('v.engagementProgramFieldAPIName');
        var engagementProgramId;
        if(component.get('v.namespace')=='c' || $A.util.isEmpty(component.get('v.namespace'))){
            engagementProgramId = event.getParam('row')[component.get('v.engagementProgramFieldAPIName')];
        }
        else{
            engagementProgramId = event.getParam('row')[engProgramIdFieldAPIName];
        }
         if(engagementProgramId!=null && engagementProgramId!='' && engagementProgramId!=undefined){
             component.set('v.engagementProgramId',engagementProgramId);
             helper.navigateToSurveyInvitationPage(component,event,helper);
         }
         else{
             helper.navigateToCmp(component,event,helper);
         }
    },

    clearErrors : function(component) {
        var errors = [];
        component.set("v.errors", errors);
    }

})