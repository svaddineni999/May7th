({
    doInit : function(component, event, helper) {
        helper.setNamespace(component, event, helper)  ;
        var namespace = component.get("v.namespace");
        var pageReference = component.get("v.pageReference");
        var Id = CH_PC_Util.getQualifiedQueryParam(component,'Id',namespace);
        var enrollmentCaseId = component.get("v.enrollmentCaseId");
        if($A.util.isUndefinedOrNull(enrollmentCaseId) || $A.util.isEmpty(enrollmentCaseId)){
            if(pageReference != null && pageReference.state[Id] != 'NULL' && pageReference.state[Id] != 'undefined'){
                enrollmentCaseId = pageReference.state[Id];
            }else{
                var query = location.search.substr(1);
                var result = {};
                query.split("&").forEach(function(part) {
                    var item = part.split("=");
                    if(!$A.util.isUndefinedOrNull(item[0]) && !$A.util.isUndefinedOrNull(item[1])){
                        result[item[0]] = decodeURIComponent(item[1]);
                    }
                });
                enrollmentCaseId = result[Id];
            }
            component.set("v.enrollmentCaseId", enrollmentCaseId);
        }
        helper.setupEnrollmentWizard(component, event);
    },
    refreshView : function(component, event, helper) {
        $A.get('e.force:refreshView').fire();
    },
    pageMetadataChanged : function(component, event, helper) {
        helper.setWizardPage(component, 0, 0, helper);
    },
    back : function(component, event, helper) {
        var currentPage = component.get("v.currentPage");
        var currentPageIndex = component.get("v.currentPageIndex");
        var valid = true;

        if (currentPageIndex > 0) {
            if (!$A.util.isUndefinedOrNull(currentPage)) {
                currentPage.set("v.navigationAction", "BACK");
                currentPage.validate();
                valid = currentPage.get("v.isValid");
            }

            if (valid) {
                helper.setWizardPage(component, currentPageIndex - 1, currentPageIndex, helper);
            }
        }
        if (component.get("v.isErrorComponentVisited")) {
            helper.resetErrorMessage(component, event, helper);
        }
    },
    next : function(component, event, helper) {
        var currentPage = component.get("v.currentPage");
        currentPage.set("v.navigationAction", "NEXT");
        currentPage.validate();
        if (component.get("v.currentPage").get("v.isValid")) {
            var pageMetadata = component.get("v.pageMetadata");
            var currentPageIndex = component.get("v.currentPageIndex");
            if (currentPageIndex < pageMetadata.length) {
                helper.setWizardPage(component, currentPageIndex + 1, currentPageIndex, helper);
            }
        }

        if (component.get("v.isErrorComponentVisited")) {
            helper.resetErrorMessage(component, event, helper);
        }

        event.preventDefault();
        return false;
    },
    navigateToComponent : function (component, event, helper) {
        var pageMetadata = component.get("v.pageMetadata");
        var currentPageIndex = component.get("v.currentPageIndex");
        var newPageIndex;
        for (var i = 0; i < pageMetadata.length; i++) {
            if (pageMetadata[i].developerName == component.get("v.errorComponentName")) {
                newPageIndex = i;
                break;
            }
        }
        helper.setWizardPage(component, newPageIndex, currentPageIndex, helper);
    },
    save : function(component, event, helper) {
        var currentPageIndex = component.get("v.currentPageIndex");
        var pageMetadata = component.get("v.pageMetadata");
        var pageAttributeMap = component.get("v.pageAttributeMap");
        var currentPage = component.get("v.currentPage");
        currentPage.set("v.navigationAction", "SAVE");
        helper.saveWizardState(component, pageMetadata, pageAttributeMap, currentPage, currentPageIndex, true);
    },
    close : function(component, event, helper) {
        var device = $A.get("$Browser.formFactor");
        if(device != 'DESKTOP'){
            helper.hideModelEnrollmentComplete(component);
        }else{
            var isCustomApp = component.get("v.isCustomApp");
            if(isCustomApp){
                helper.hideModelEnrollmentComplete(component);
            }else{
                var workspaceAPI = component.find("enrollmentWizardWorkspace");
                workspaceAPI.isConsoleNavigation().then(function(isConsole) {
                    if (isConsole) {
                        workspaceAPI.getFocusedTabInfo().then(function(info) {
                            workspaceAPI.closeTab({tabId: info.tabId});
                        });
                    }
                    else {
                        helper.hideModelEnrollmentComplete(component);
                    }
                }).catch(function(error) {
                    console.log(error);
                });
            }
        }
    },
    enroll : function(component, event, helper) {
        helper.processEnrollment(component, event, helper);
    },
    viewcase : function(component, event, helper) {
        var device = $A.get("$Browser.formFactor");
        if(device != 'DESKTOP'){
            var navService = component.find("navService");
            var pageReference = {
                "type": "standard__recordPage",
                "attributes": {
                   "recordId": component.get("v.programCase"),
                   "objectApiName": "Case",
                   "actionName": "view"
               }
            };
            event.preventDefault();
            navService.navigate(pageReference);
        }else{
            var workspaceAPI = component.find("enrollmentWizardWorkspace");
            var recordId = component.get("v.programCase");
            var focus = true;
            var closeEnclosingTabId = false;
            var isCustomApp = component.get("v.isCustomApp");
            if(isCustomApp){
                var url = '/one/one.app#/sObject/' + recordId + '/view';
                window.open(url,'_self');
            }else{
                CH_PC_Util.openRecordInNewMainTab(workspaceAPI ,recordId , focus , closeEnclosingTabId);
            }
        }
    },

    currentPageIndexChanged: function(component, event, helper) {

    },
    waiting: function(component, event, helper) {
        //TODO: VIJAY - improve loading UX
    },

    doneWaiting: function(component, event, helper) {
        //TODO: VIJAY - improve loading UX
    },
    dismissToast: function(component, event, helper) {
        helper.dismissToast(component);
    }
})