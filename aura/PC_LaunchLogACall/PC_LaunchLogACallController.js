/**
 * Created by tusarora on 7/21/2020.
 */
({
    doInit : function (component, event,helper) {
        helper.clearErrors(component);
        helper.setNamespace(component);
        helper.getLogACallRecordTypeInfo(component, event, helper);
    },
    openLogACallActionComponent : function (component, event, helper) {
        helper.callLogACallComponent(component, event, helper);
    }
})