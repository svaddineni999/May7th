/**
 * Created by havalakki on 1/17/2018.
 */
({
    doneRendering: function(component, event, helper) {
        	helper.doneRendering(component, event);
        },

    doInit : function(component, event, helper) {
            helper.setNamespace(component);
            helper.getInit(component, event, helper);
            //helper.getSubComponentList(component, event, helper);
            //helper.getLogs(component);
        },

    popOutDocument : function (component, event, helper) {
            var docId = component.get("v.recordId");
            //var isEmail = component.get("v.loadEmailContainer");
           	var componentName = "PC_Document_InboundEmail";;
           	var titleName="Document Preview";
            /*if (isEmail === true) {
            	componentName = "PC_Document_InboundEmail";
            } else {
            	componentName = "PC_Document_InboundFax";
            }*/
            var vfpage = component.get("v.namespacePrefix")+'PC_PopOutDocument';
            var url = '/apex/'+ vfpage +'?documentId=' + docId + '&componentName=' + componentName + '&isPopout=' + true;

            window.open(url,titleName+docId,"toolbar=yes,scrollbars=yes,resizable=yes,left=1050,top=100,width=800,height=800");
    	},
})