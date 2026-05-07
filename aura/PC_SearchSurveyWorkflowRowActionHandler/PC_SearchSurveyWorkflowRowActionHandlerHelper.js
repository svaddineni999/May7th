/**
 * Created by vkashikar on 5/20/2021.
 */
({
    setNamespace : function(component) {
        var ns = CH_PC_Util.getNamespace(component);
        var nsPrefix = CH_PC_Util.getNamespacePrefix(component);
        component.set("v.namespace", ns);
        component.set("v.namespacePrefix", nsPrefix);
    },
    setMode : function(component, event, helper) {
        debugger;
        var url = window.location.href;
        //"https://coredev-dev-ed.lightning.force.com/flexipageEditor/surface.app?appLayout=lg&formfactorName=DESKTOP&aura.mode=PROD"

        // SF loads the edit components in the URI flexipageEditor/surface.app. We will use this to determine,
        // if we are in edit mode or not.
        if(!$A.util.isEmpty(url) && url.indexOf('/flexipageEditor/surface.app') > 0) {
            component.set("v.isEditMode", true);
        }
    },
    navigateToCmp : function (component, event, helper, actionName) {
        var cmpName;
        debugger;
        if((actionName == 'PC_LAUNCH_PAP' && component.get('v.workflowSurveyContext')=='PC_PAP') ||
        (actionName == 'PC_LAUNCH_COPAY' && component.get('v.workflowSurveyContext')=='PC_Copay')) {
            cmpName = 'PC_SurveyWorkflow';
        }

        if(!$A.util.isEmpty(cmpName)) {
            var ns = component.get("v.namespace");
            var pageAPIName = null;
            var nsPrefix = component.get("v.namespacePrefix");
            var recordId = component.get("v.selectedRecordId");
            var componentAPIName = ns + ':' + cmpName;
            var workspaceAPI = component.find("workspaceAPI");
            var tabParamsObject = new Object();

            var workflowName = CH_PC_Util.getQualifiedQueryParam(component, 'name' , ns);
            var tabLabel;

            var qualifiedIdName = CH_PC_Util.getQualifiedQueryParam(component, 'Id' , ns);
            tabParamsObject.uid = 'PC_SearchSurveyWorkflowRowAction-' + recordId +actionName;
            tabParamsObject[qualifiedIdName] = recordId;

            var accountFieldSetAttrName = CH_PC_Util.getQualifiedQueryParam(component, 'accountFieldSetAPIName' , ns);
            tabParamsObject[accountFieldSetAttrName] = component.get("v.accountFieldSetAPIName");

            var caseFieldsetAttrName = CH_PC_Util.getQualifiedQueryParam(component, 'caseFieldsetAPIName' , ns);
            tabParamsObject[caseFieldsetAttrName] = component.get("v.caseFieldsetAPIName");

            var urlParams = '?' + qualifiedIdName + '=' + recordId +
                            '&' + accountFieldSetAttrName + '=' + component.get("v.accountFieldSetAPIName") +
                            '&' + caseFieldsetAttrName + '=' + component.get("v.caseFieldsetAPIName");

            tabParamsObject[workflowName]= component.get('v.workflowSurveyContext');
            urlParams =urlParams + '&' + workflowName+'='+ component.get('v.workflowSurveyContext');

            if(actionName == 'PC_LAUNCH_PAP'){
                tabLabel = $A.get('$Label.c.PC_PAPTitle')+' '+$A.get('$Label.c.PC_SurveyLabel');
            }
            else if(actionName == 'PC_LAUNCH_COPAY') {
                tabLabel = $A.get('$Label.c.PC_CopayTitle')+' '+$A.get('$Label.c.PC_SurveyLabel');
            }

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
                               label: tabLabel
                             });
                             workspaceAPI.setTabIcon({
                               tabId: newTabId,
                               icon: component.get("v.tabIcon"),
                               iconAlt: tabLabel
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
                               label: tabLabel
                             });
                             workspaceAPI.setTabIcon({
                               tabId: newTabId,
                               icon: component.get("v.tabIcon"),
                               iconAlt: tabLabel
                             });
                         });
                     }
                 });
                }
                else {
                    var url = '/lightning/cmp/' + componentAPIName + urlParams;
                    window.open(url,"_blank");
                }
             })
             .catch(function(error) {
                console.error(error);
             });
        }
    }
})