({
    doInit: function(component, event, helper) {
        helper.setNamespace(component);
        helper.setPageReferenceValues(component, event, helper);
        helper.getParticipantData(component, event, helper);
    },
    navigateToRecordDetail : function(component , event, helper){
        var recId = event.currentTarget.id;
        window.open('/one/one.app#/sObject/' + recId );
    },
    saveParticipantInfo : function(component , event, helper){
        helper.saveParticipantData(component , event, helper);
    },
})