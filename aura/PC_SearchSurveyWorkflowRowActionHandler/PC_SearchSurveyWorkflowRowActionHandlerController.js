/**
 * Created by vkashikar on 5/21/2021.
 */
({
    doInit : function (component, event, helper) {
        helper.setNamespace(component);
        helper.setMode(component, event, helper);
    },
    handleSearchParams : function(component) {
       component.set("v.selectedRecordId", null);
    },
    handleSelectedRecDetails : function(component, event, helper) {
         var selectedRecId= event.getParam("selectedRecordId");
         var identifier = event.getParam('identifier');
         var searchParams = event.getParam('searchParams');
         var sourceUniqueId = event.getParam('sourceUniqueId');
         var actionType = event.getParam('actionType');
         var actionName = event.getParam('actionName');

         console.log('selectedRecId = ' + selectedRecId);
         console.log('identifier = ' + identifier);
         console.log('searchParams = ');
         console.log(searchParams);
         console.log('selectedSourceId = ' + sourceUniqueId);
         console.log('actionType = ' + actionType);
         console.log('actionName = ' + actionName);

         component.set('v.selectedRecordId',selectedRecId);
         component.set('v.identifier',identifier);
         component.set('v.searchParams',searchParams);
         component.set('v.sourceUniqueId',sourceUniqueId);
         component.set('v.actionType',actionType);
         component.set('v.actionName',actionName);

         debugger;
         if(selectedRecId != null && selectedRecId != undefined){
            if(actionType == 'ROW_ACTION' && actionName == 'PC_LAUNCH_PAP') {
                helper.navigateToCmp(component, event, helper, actionName);
            }
            else if(actionType == 'ROW_ACTION' && actionName == 'PC_LAUNCH_COPAY') {
                helper.navigateToCmp(component, event, helper, actionName);
            }
         }
    }
})