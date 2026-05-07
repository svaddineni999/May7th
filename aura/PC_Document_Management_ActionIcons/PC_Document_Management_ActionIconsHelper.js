({
    setNamespace : function(component) {

        var component_to_string = component.toString();

        var markupTagLoc = component_to_string.indexOf('markup://');
        var endOfNamespaceLoc = component_to_string.indexOf(':',markupTagLoc+9);
        var ns = component_to_string.substring(markupTagLoc+9,endOfNamespaceLoc);

        var namespacePrefix = (ns == "c" || ns == "C") ?  "" :  ns + "__";

        component.set("v.namespace", ns);
        component.set("v.namespacePrefix", namespacePrefix);
    },

    setupActionIcons : function(component, helper){
        component.set("v.isLoading", true);
        var docId = component.get("v.recordId");
        var action = component.get("c.setupActionIcons");

        action.setParams({
            "docId": docId
        });

        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                var returnValue = response.getReturnValue();
                component.set("v.actionIconsWrapper", returnValue);
                var actionIconsWrapper = component.get("v.actionIconsWrapper");
                var namespace = component.get("v.namespace");
                // reservedLabels contains fully qualified custom label path for all existing Document iconLabel for backward compatibility
                var reservedLabels = new Map([
                            ['pc_change_owner', '$Label.'+namespace+'.PC_Change_Owner'],
                            ['pc_change_status', '$Label.'+namespace+'.PC_Change_Status'],
                            ['pc_document_management_consent', '$Label.'+namespace+'.PC_Document_Management_Consent'],
                            ['pc_document_enrollment', '$Label.'+namespace+'.PC_Document_Enrollment'],
                            ['pc_document_link', '$Label.'+namespace+'.PC_Document_Link'],
                            ['pc_document_split', '$Label.'+namespace+'.PC_Document_Split'],
                            ['reply to email', '$Label.'+namespace+'.PC_ReplyToEmail']
                        ]);
                let iconLabel;
                for(var i=0; i<returnValue.length; i++){
                    // older document action iconValue supports (PC_Change_Owner and PatientConnect.PC_Change_Owner)
                    // get substring after last dot(.) and check with the reservedLabels for backward compatibility
                    iconLabel = (returnValue[i].iconLabel).split('.').pop();
                    iconLabel = iconLabel.toLowerCase();
                    // Check if iconLabel value is present in reservedLabels.
                    if(reservedLabels.has(iconLabel)) {
                        // If yes, then get fully qualified custom label path from reservedLabels map
                        returnValue[i].iconLabel = reservedLabels.get(iconLabel);
                    }
                    // logic to support custom label for document action center Icon label
                    var actionIconLabel = CH_PC_Util.getCustomLabelValue(returnValue[i].iconLabel);
                    component.set('v.actionIconsWrapper.'+i+'.iconLabel', actionIconLabel);
                }
                component.set("v.showForm", true);
            } else {
                console.log("setupActionIcons: Failed with state: " + state);
                var errors = [];
                var error = {"message" : component.get("v.errorStatus")}
                errors.push(error);
                console.log('errors::::'+JSON.stringify(errors));
                CH_PC_Util.showAllErrors(component.get('v.toastErrorTitle'),errors);
            }
            component.set("v.isLoading", false);
        });
        $A.enqueueAction(action);
    },

    createMap : function(component){
        // convert to map
        var createMap = {};
        var cmps = component.get("v.actionIconsWrapper");
        var noOfItems = component.get("v.noOfItemsInARow");
        var noOfCols = component.get("v.noOfColumns");
        var noOfRows = component.get("v.noOfRows");
        //Set Columns
        for(var k=1; k<=noOfItems; k++){
            noOfCols.push(k);
        }
        component.set("v.noOfColumns",noOfCols);

        //Set Rows
        for(var l=1; l<=Math.ceil((cmps.length)/noOfItems); l++){
            noOfRows.push(l);
        }
        component.set("v.noOfRows",noOfRows);
        var cmpIndex = 0;
        for(var i=0; i<noOfRows.length; i++) {
            for(var j=0; j<noOfCols.length; j++) {
                if(cmpIndex < cmps.length) {
                    createMap[i + '' + j] = cmps[cmpIndex];
                } else {
                    createMap[i + '' + j] = {};
                }
                cmpIndex++;
            }
        }
        component.set("v.actionIconsWrapperMap",createMap);
        component.set("v.showForm", true);
    },

    showErrorToastMessage : function(component, event, helper, message) {
    	var toastEvent = $A.get("e.force:showToast");
    	var title = component.get("v.toastErrorTitle");
    	toastEvent.setParams({
    		"title": title,
    		"message": message,
    		"type": "error",
    		"mode": "sticky"
    	});
    	toastEvent.fire();
    },

    showModalBox : function (component, event){
        var auraModalBoxBackground = component.find('auraModalBoxBackground').getElement();
        var auraModalBoxMain = component.find('auraModalBoxMain').getElement();
        auraModalBoxBackground.style.display = "block";
        auraModalBoxMain.style.display = "block";
    },

    getAccessibilityStatus : function(component, event, helper) {
        var action = component.get("c.getAccessibilityStatus");
            action.setParams({
                recordId       : component.get("v.recordId"),
                validatorClass : component.get("v.actionComponentValidator"),
                componentName : component.get("v.iconActionComponent")
            });
            action.setCallback(this, function(a) {
                var state = a.getState();
                if (state === "SUCCESS") {
                    var returnValue = a.getReturnValue();
                    console.log('returnValueAccessibility::::'+returnValue);
                    component.set("v.isAccessible",returnValue.isAccessible);
                    console.log('returnValueAccessibility::::'+component.get("v.isAccessible"));
                    component.set("v.actionValidationMessage",returnValue.message);

                    if(component.get("v.isAccessible")) {
                        helper.createComponent(component, event);
                    } else {
                        this.showErrorToastMessage(component, event, helper, component.get("v.actionValidationMessage"));
                    }
                } else if (state ==="ERROR") {
                    console.log("Document Action Icon Accessibility : Failed with state: " + state);
                    var errors =  [];
                    var error = {"message" : component.get("v.errorStatus")}
                    errors.push(error);
                    console.log('errors::::'+JSON.stringify(errors));
                    CH_PC_Util.showAllErrors(component.get('v.toastErrorTitle'),errors);
                }
            });
        $A.enqueueAction(action);
    },
    createComponent : function (component, event){
        var componentName = component.get("v.iconActionComponent");
        if($A.util.isEmpty(component.get("v.iconAction"))){
            $A.createComponent(
                componentName,
                {
                    "recordId" : component.get("v.recordId"),
                    "actionAttribute" : component.get("v.iconActionAttribute")
                },
                function(newComponent) {
                    component.set("v.body", newComponent);
                }
            );
        } else {
            debugger;
            $A.createComponent(
                componentName,
                {
                    "recordId" : component.get("v.recordId"),
                    "actionAttribute" : component.get("v.iconActionAttribute"),
                    "action" : component.get("v.iconAction")
                },
                function(newComponent) {
                    component.set("v.body", newComponent);
                }
            );
        }
    },
    resetAttributes : function (component, event){
        var actionIconsWrapper = [];
        component.set("v.actionIconsWrapper",actionIconsWrapper);
    }

})