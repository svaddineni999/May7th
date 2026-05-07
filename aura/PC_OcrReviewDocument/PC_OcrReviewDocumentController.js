/**
 * Created by sathekumar on 10/8/2021.
 */
({
    doInit: function (component, event, helper) {
        helper.setNamespace(component, event, helper);
        helper.doInit(component, event, helper);
        //helper.calculateSection(component, event, helper);
    },

    onPrevious: function (component, event, helper) {
        helper.handlePrevious(component, event, helper);
    },

    onNext: function (component, event, helper) {
        helper.handleNext(component, event, helper);
    },

    onSave: function (component, event, helper) {
        helper.handleSubmit(component, event, helper);
    },

    onCancel: function (component, event, helper) {
        helper.closeTab(component, event, helper);
    },

    handleLoad: function (component, event, helper) {
        helper.handleLoad(component, event, helper);
    },

    handleSuccess: function (component, event, helper) {
        helper.handleSuccess(component, event, helper);
    },

    handleError: function (component, event, helper) {
        helper.handleError(component, event, helper);
    },

    collapseLeftPanel: function (component, event, helper) {
        var leftPanel = component.find('left-panel');
        $A.util.toggleClass(leftPanel, "collapsed");
        $A.util.toggleClass(leftPanel, "slds-scrollable");

        var leftPanelContainer = component.find('left-panel-container');
        $A.util.toggleClass(leftPanelContainer, "slds-hide");

        var rightPanel = component.find('right-panel');
        $A.util.toggleClass(rightPanel, "slds-size_1-of-2");
    },
})