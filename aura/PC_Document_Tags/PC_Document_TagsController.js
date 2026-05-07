/**
 * Created by havalakki on 1/30/2018.
 */
({
    doneRendering: function(component, event, helper) {
        helper.doneRendering(component, event);
    },

    doInit : function(component, event, helper) {
        component.set("v.errors", null);
        helper.setNamespace(component);
        /*helper.getSubComponentList(component, event, helper);*/
        helper.getInit(component, event, helper);
        /*helper.getLogs(component);   */
    },
    selectCategory : function(component, event, helper) {
        var selectedCateg = event.srcElement.getAttribute('data-category');
        helper.saveCategory(component, event, helper, selectedCateg);
    },
    
    showAccordion : function(component, event, helper) {
       helper.showHideSection(component,event,'articleOne');
    }
})