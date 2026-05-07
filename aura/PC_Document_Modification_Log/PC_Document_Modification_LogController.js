/**
 * Created by havalakki on 1/12/2018.
 */
({
    doneRendering: function(component, event, helper) {
        	helper.doneRendering(component, event);
        },

    doInit : function(component, event, helper) {
            helper.setNamespace(component);
            //helper.getSubComponentList(component, event, helper);
            //helper.getInit(component, event, helper);
            helper.getLogs(component);
        },

    goToSelectedLink : function(component, event, helper) {
        helper.goToSelectedLink(component,event,helper);
    },
    showAccordion : function(component, event, helper) {
       helper.showHideSection(component,event,'articleOne');
    },

    refreshView : function(component, event, helper) {
        helper.getLogs(component);
    }

})