/**
 * Created by vkashikar on 10/10/2017.
 * - Tejas Patel 15/Dec/2017 logic to pull namespace for managed package
 * - Reverted commit by Tejas Patel done on 15/Dec/2017
 * - Vijay Kashikar 13/Dec/2017 Made changes to handle report title as 'plain text'
 */
({
    doInit : function(component, event, helper) {
			helper.setNamespace(component);
			helper.replacePCNamespace(component);
			var attrValLabelName = component.get("v.reportTitleLabelName");
            if(attrValLabelName == '' || attrValLabelName == null || attrValLabelName == undefined) {
                // do nothing
            }
            else {
                if(attrValLabelName.toLowerCase().startsWith('$label')) {
                    var dynamicLabel = $A.get(attrValLabelName);
                    if(dynamicLabel == '' || dynamicLabel == null || dynamicLabel == undefined) {
                        dynamicLabel = 'Label not found';
                    }
                    component.set("v.reportTitleDynamicLabel",dynamicLabel);
                }
                else {
                    component.set("v.reportTitleDynamicLabel",attrValLabelName);
                }
            }


    }
})