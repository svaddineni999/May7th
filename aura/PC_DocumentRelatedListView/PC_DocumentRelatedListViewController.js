/**
 * Created by peharitha on 7/2/2019.
 */
({
    doInit : function(component, event, helper) {
        //set Document Id
        var docId = component.get("v.docId");
        var recordId = component.get("v.recordId");
        if($A.util.isEmpty(docId) && !$A.util.isEmpty(recordId)){
            component.set("v.docId",recordId);
        }

        helper.setNamespace(component);
        helper.setFileURL(component);
        helper.getInit(component, event, helper);
    },
    showAccordion : function(component, event, helper) {
        helper.showHideSection(component,event,'articleOne');
    },
    navigateToDocument : function(component,event,helper){
        helper.navigateToDocument(component,event,helper);
    },
    navigateToFile : function(component,event,helper){
        helper.navigateToFile(component,event,helper);
    },
})