({
	doneRendering: function(component, event, helper) {
    	helper.doneRendering(component, event);
    },

    doInit : function(component, event, helper) {
        helper.clearAttributes(component);
        helper.setNamespace(component);
        helper.getInit(component, event, helper);
    },

    showAccordion : function(component, event, helper) {
       helper.showHideSection(component,event,'articleOne');
    },
})