/**
 * Created by vkashikar on 8/2/2018.
 */
({
    initialize : function(component, event, helper) {
        var attributes = component.get("v.attributes");
        if($A.util.isEmpty(attributes)) {
            // do nothing
        }
        else {
            var action = component.get("c.getInitData");
            action.setParams({
                caseId : component.get("v.recordId"),
                attributes : component.get("v.attributes"),
            });
            action.setCallback(this, function(a) {
                var state = a.getState();
                var initData = {};
                if (state === "SUCCESS") {
                    if(component.isValid()) {
                        debugger;
                        var returnValue = a.getReturnValue();
                        console.log('ii -- printing return value');
                        console.log(returnValue);
                        component.set("v.initData", returnValue);
                        component.set("v.status", returnValue.intelligentIndicatorStatus);
                        component.set("v.statusIcon", returnValue.intelligentIndicatorStatusIcon);
                        if(!$A.util.isEmpty(returnValue.intelligentIndicatorStatusIconSize)) {
                            component.set("v.iconSize", returnValue.intelligentIndicatorStatusIconSize);
                        }
                        if(!$A.util.isEmpty(returnValue.intelligentIndicatorStatusIconVariant)) {
                            component.set("v.iconVariant", returnValue.intelligentIndicatorStatusIconVariant);
                        }

                        var counter = component.get("v.testCounter");
                        component.set("v.testCounter", counter+1);
                    }
                    else {
                        initData["isError"] = true;
                        initData["errorMessage"] = "Component is invalid";
                        component.set("v.initData", initData);
                    }
                } else if (state ==="ERROR") {
                    var errors = a.getError();
                    console.log(JSON.stringify(errors));
                    initData["isError"] = true;
                    initData["errorMessage"] = JSON.stringify(errors);
                    component.set("v.initData", initData);
                }
            });
            $A.enqueueAction(action);
        }

    },
    getLabelValue : function(titleString) {
        if($A.util.isEmpty(titleString)) {
            return '';
        }
        else if (titleString.startsWith('$label')) {
            //alert(titleString);
            var y = $A.getReference("$label.c."+'PC_AppMessage');
            return y;
        }
        return titleString;
    },
    refreshView : function(component, event, helper) {
        var cc=component.getConcreteComponent();
        //var cchelper=cc.getDef().getHelper();
        //var cmp = component.find(component.get("v.auraId"));
        try {
            cc.setValues(component, event, helper);
        }
        catch(err) {
            console.error(err);
            console.log("Either set values failed or was not found and hence calling default initialize");
            helper.initialize(component, event, helper);
        }
    },
    toggle: function(component, auraId, isVisible) {
         var block = component.find(auraId);
         $A.util.removeClass(block, 'slds-transition-show');
         $A.util.removeClass(block, 'slds-transition-hide');
         if(isVisible) {
             if($A.util.hasClass(block, 'slds-transition-show')) {
                // do nothing
             }
             else {
                 $A.util.addClass(block, 'slds-transition-show');
             }
         }
         else {
              if($A.util.hasClass(block, 'slds-transition-hide')) {
                // do nothing
              }
              else {
                  $A.util.addClass(block, 'slds-transition-hide');
              }
         }
    },
    handleShowCustomModal : function(component, event, helper) {
        debugger;
        //component.find("overlayLib").set("v.body",[]);
        var title = component.get("v.title");
        //var popBody = component.find("moreInfoBlock");
        //helper.toggle(component, "moreInfoBlockContent", true);
        var extBody = component.get("v.body");
        component.find('overlayLib').showCustomModal({
           header: title,
           body: extBody,
           showCloseButton: true,
           cssClass : "ePAOverlay",
           closeCallback: function() {
               debugger;
               console.log('You closed the alert!');
               //helper.toggle(component, "moreInfoBlockContent", false);
               //helper.revertCssChange(component);
               //component.set("v.ePAModalCloseTracker", !component.get("v.ePAModalCloseTracker"));
           }
       })
    },
    handleShowPopover : function(component,event,helper) {
        var ns = 'c';
        component.find('overlayLib').showCustomPopover({
            body: component.get("v.title"),
            referenceSelector: ".viewBlock",
            cssClass: "slds-nubbin_bottom,slds-popover_walkthrough,no-pointer,"+ns+"PC_StatusIndicator"
        }).then(function (overlay) {
            setTimeout(function(){
                //close the popover after 3 seconds
                overlay.close();
            }, 3000);
        });

        component.find("overlayLib").notifyClose();
    },
    createContentComponent : function(component,event,helper) {
        var cmpName = component.get("v.contentComponent");
        if($A.util.isEmpty(cmpName)) {
            return;
        }
        var cmpAttributes = component.get("v.contentComponentAttributes");
        var cmpAttributesObj;
        if($A.util.isEmpty(cmpAttributes)) {
            cmpAttributesObj = {};
        }
        else {
            cmpAttributesObj = JSON.parse(cmpAttributes);
        }


        var defaultAttributesObj = {"recordId":""};
        defaultAttributesObj['recordId'] = component.get("v.recordId");



        var allAttributesObj = Object.assign({},defaultAttributesObj,cmpAttributesObj);

        console.log('All Attributes...');
        console.log(allAttributesObj);

        $A.createComponent(
            cmpName,
            allAttributesObj,
            function(newCmp, status, errorMessage){
                if (status === "SUCCESS") {
                    var body = component.get("v.DynamicContentComponent");
                    body.pop(); // necessary to remove items added earlier
                    body.push(newCmp);
                    component.set("v.DynamicContentComponent", body);
                }
                else if (status === "INCOMPLETE") {
                    console.log("No response from server or client is offline.")
                }
                else if (status === "ERROR") {
                    console.log("Error: " + errorMessage);
                }
                else {
                    console.log("Unknown Error" + errorMessage);
                }
            }
        );
    }
})