/**
 * Created by shisbansal on 8/28/2018.
 */
({

        doInit: function(component, event, helper){
            debugger;
            helper.setNamespace(component);
            helper.clearErrorMessages(component);
            helper.fetchEngagementTasksList(component, event, helper);

        },

        createEngagementTask: function(component, event, helper){
            console.log(component.get("v.namespace"));
            console.log(component.get("v.namespacePrefix"));
            helper.insertNewEngagementTask(component, event, helper);

        },

        editEngagementTask : function(component, event, helper){
            debugger;
            helper.editExistingEngagementTask(component, event, helper);

        },

        goToSelectedLink : function(component, event, helper) {
                var objectId = event.currentTarget.id;
                window.open('/one/one.app#/sObject/' + objectId + '/view', '_blank',  "toolbar=yes,scrollbars=yes,resizable=yes,left=1050,top=100,width=800,height=800");

        },







})