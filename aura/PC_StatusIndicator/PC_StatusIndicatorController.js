/**
 * Created by vkashikar on 8/2/2018.
 */
({

    onTabFocused : function(component, event, helper) {
        console.log("Tab Focused");
        var focusedTabId = event.getParam('currentTabId');
        var workspaceAPI = component.find("workspace");
        if(focusedTabId == component.get("v.currentTabId")) {
            //alert("this tab should be refreshed" + " focusedTabId=" + focusedTabId + "storedTabId=" + component.get("v.currentTabId"));
            //TODO refresh the intelligent indicator
            helper.refreshView(component, event, helper);
        }
        workspaceAPI.getTabInfo({
            tabId : focusedTabId
        }).then(function(response) {
            console.log(response);
        });
    },
    doInit : function(component, event, helper) {
        component.set("v.showOnlySummaryView", false);
        var workspaceAPI = component.find("workspace");
        workspaceAPI.isConsoleNavigation().then(function(response) {
            component.set("v.isConsoleNavigation", response);
            console.log("isConsoleNavigation = " + response);
        }).catch(function(error) {
            component.set("v.isConsoleNavigation", false);
            console.error(error);
        });

        workspaceAPI.getEnclosingTabId().then(function(tabId) {
            component.set("v.currentTabId", tabId);
            console.log("current tab id = " + tabId);
        }).catch(function(error) {
            component.set("v.currentTabId", "-1");
            console.error(error);
        });

        //component.set("v.title", helper.getLabelValue(component.get("v.title")));
        //component.set("v.content", helper.getLabelValue(component.get("v.content")));

        helper.refreshView(component, event, helper);

    },
    refreshView : function(component, event, helper) {
        helper.refreshView(component, event, helper);
    },
    showPopUp : function(component, event, helper) {
        component.set("v.showModal", true);
        helper.createContentComponent(component, event, helper);
        //helper.handleShowCustomModal(component, event, helper);
    },
    closeModal : function(component, event, helper) {
        component.set("v.showModal", false);
    }



})