/**
 * Created by shisbansal on 8/27/2018.
 */
({


    doInit: function(component, event, helper){
        helper.setNamespace(component);
        helper.clearErrorMessages(component);
        helper.fetchProgramCoveragesList(component, event, helper);
        //helper.getFieldLabels(component, event, helper);
    },

    createProgramCoverage: function(component, event, helper){
        console.log(component.get("v.namespace"));
        console.log(component.get("v.namespacePrefix"));
        helper.insertNewProgramCoverage(component, event, helper);

    },

    editProgramCoverage : function(component, event, helper){
        debugger;
        helper.editExistingProgramCoverage(component, event, helper);

    },

    goToSelectedLink : function(component, event, helper) {
        var objectId = event.currentTarget.id;
        window.open('/one/one.app#/sObject/' + objectId + '/view', '_blank',  "toolbar=yes,scrollbars=yes,resizable=yes,left=1050,top=100,width=800,height=800");

    },


})