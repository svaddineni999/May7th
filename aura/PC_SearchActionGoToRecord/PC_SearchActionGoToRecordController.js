/**
 * Created by havalakki on 10/18/2019.
 */
({
    doInit : function (component, event, helper) {
        helper.setNamespace(component);
        helper.initializeAttributes(component, event, helper);
    },
    handleSearchParams : function(component) {
       component.set("v.selectedRecordId", null);
    },
    populateSelectedRecDetails : function(component, event, helper) {
         var selectedRecId= event.getParam("selectedRecordId");
         debugger;
         component.set('v.selectedRecordId',selectedRecId);

         if(selectedRecId != null && selectedRecId != undefined){
             var goToRecordButton = component.find('goToRecordButtonId');
             goToRecordButton.set("v.disabled",false);
         }
    },

    navigateToRecord : function (component, event, helper) {
      var selectedRecId= component.get('v.selectedRecordId');

      var navEvt = $A.get("e.force:navigateToSObject");
      navEvt.setParams({
        "recordId": selectedRecId,
        "slideDevName": "detail"
      });
      navEvt.fire();
    }

})