({
    doInit : function(component, event, helper) {
        //For New Record Page, when there is no recordId send out empty string;
        helper.setNamespace(component, event, helper);
        helper.setPageReferenceValues(component, event, helper);
        if(!$A.util.isEmpty(component.get("v.recordId")) && !component.get('v.openInNewTab')){
            var recordId = component.get('v.recordId');
            //Checking if recordId is a CaseId.
            if(recordId.startsWith('500')){
                component.set("v.programId",recordId);
                component.set("v.recordId", '');
            }
        }
        if(!component.get("v.recordId")){
            component.set("v.recordId", '');
        }
        if(component.get('v.openInNewTab')){
            helper.launchOrderInNewTab(component, event, helper);
        }
    },
    handleCloseTab : function(component, event, helper) {
        helper.navigationNeeded(component, event, helper);
        var closeClicked = event.getParam('close');
        var orderId = event.getParam('orderIdCreated');
        var orderNumber = event.getParam('orderNumberCreated');
        var namespace = component.get("v.namespace");
        var namespacePrefix = component.get("v.namespacePrefix");
        var orderAPIName =  namespacePrefix +component.get("v.orderAPIName");
        if(orderId != null && orderId != 'undefined'){
            var workspaceAPI = component.find("orderWorkspace");
            workspaceAPI.isConsoleNavigation().then(function(isConsole) {
                if (isConsole) {
                    workspaceAPI.getFocusedTabInfo().then(function(response) {
                        console.log('responseisSubtab::::'+JSON.stringify(response));
                        workspaceAPI.isSubtab({
                            tabId: response.tabId
                        }).then(function(response) {
                            if (response) {
                                if(component.get('v.navigate')){
                                    workspaceAPI.openSubtab({
                                        pageReference: {
                                            "type": "standard__recordPage",
                                            "attributes": {
                                                "recordId": orderId,
                                                "actionName":"view"
                                            }
                                        },
                                        focus: true
                                    }).then(function(newTabId){
                                        workspaceAPI.closeTab({tabId : response.tabId});
                                        workspaceAPI.focusTab(newTabId);
                                    });
                                } else {
                                    workspaceAPI.setTabLabel({
                                        tabId: response.tabId,
                                        label: orderNumber
                                    });
                                }
                            }else {
                                if(component.get('v.navigate')){
                                    workspaceAPI.openTab({
                                        pageReference: {
                                            "type": "standard__recordPage",
                                            "attributes": {
                                                "recordId": orderId,
                                                "actionName":"view"
                                            }
                                        },
                                        focus: true
                                    }).then(function(newTabId){
                                        workspaceAPI.getEnclosingTabId()
                                        .then(function(enclosingTabId) {
                                            workspaceAPI.closeTab({tabId : enclosingTabId});
                                            workspaceAPI.focusTab(newTabId);
                                        });
                                    });
                                }
                            }
                        });
                    })
                } else {
                    if(component.get('v.navigate')){
                        var navLink = component.find("orderNavigationService");
                        var pageRef = {
                            type: 'standard__recordPage',
                                attributes: {
                                actionName: 'view',
                                objectApiName: orderAPIName,
                                recordId : orderId
                            },
                        };
                        navLink.navigate(pageRef, true);
                    }
                }
            })

        }
    },
    onPageReferenceChanged  : function(cmp, event, helper) {
        $A.get('e.force:refreshView').fire();
    }

})