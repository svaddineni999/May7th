/**
 * Created by havalakki on 2/8/2018.
 */
({
    showSpinner : function (component, event, helper) {
            var spinner = component.find('spinner');
            var evt = spinner.get("e.toggle");
            evt.setParams({ isVisible : true });
            evt.fire();
        },
    hideSpinner : function (component, event, helper) {
       var spinner = component.find('spinner');
       var evt = spinner.get("e.toggle");
       evt.setParams({ isVisible : false });
       evt.fire();
    },

    doInit : function(component, event, helper) {

        helper.setNamespace(component);
        var patient = component.get("v.patientId");
        component.set('v.objectFieldsWrapper',[]);
        component.set("v.patientName",'');
        component.set('v.isError',false);
        component.set('v.showDiv',false);
         if(typeof patient != 'undefined'){
                helper.getAccountDetailsAndApexFields(component, event, patient);
          }

    },

    closeWindow : function(component, event, helper) {
        component.set("v.patientId", null);
        component.set("v.account", []);
        component.set("v.accountSelected", null);
        component.set("v.programIds", []);
        component.set("v.selectedAdverseEventList", []);
        component.set("v.selectedInteractionList", []);
        component.set("v.showMessage", false);

        component.set("v.interactionList", []);
        component.set("v.programList", []);
        component.set("v.adverseEventList", []);


        helper.closeWindow(component);
    },

    goToSelectedLink : function(component, event, helper) {
        var objectId = event.currentTarget.id;
        window.open('/one/one.app#/sObject/' + objectId + '/view', '_blank',  "toolbar=yes,scrollbars=yes,resizable=yes,left=1050,top=100,width=800,height=800");
    },

    saveUpdateDocLogs :function(component, event, helper){
        helper.saveUpdateDocLogs(component, event, helper);
    }
})