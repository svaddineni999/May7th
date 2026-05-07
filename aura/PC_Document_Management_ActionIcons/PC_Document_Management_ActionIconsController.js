({
	doInit : function(component, event, helper) {
        helper.setNamespace(component);
        helper.resetAttributes(component, event, helper);
        helper.setupActionIcons(component, helper);
    },

    callActionComponent : function(component, event, helper){
        var targetValueAttr = event.currentTarget.value;
     	var iconActionComponent = targetValueAttr;
        var iconLabel = event.currentTarget.name;
        component.set("v.iconLabel", iconLabel);
        var iconAction = "";
        var iconActionAttribute = "";
        var iconActionValidatorClass = "";
        if (targetValueAttr.indexOf("::") >= 0) {
            var parts = targetValueAttr.split("::");
            iconActionComponent = parts[0];
            iconAction = parts[1];
            iconActionAttribute = parts[2];
            iconActionValidatorClass = parts[3];
        }
        component.set("v.iconActionComponent", iconActionComponent);
        component.set("v.iconAction", iconAction);
        component.set("v.iconActionAttribute", iconActionAttribute);
        component.set("v.actionComponentValidator",iconActionValidatorClass);
        if($A.util.isEmpty(iconActionComponent)){
            return;
        } else{
            if(!$A.util.isEmpty(component.get("v.actionComponentValidator"))){
                 helper.getAccessibilityStatus(component, event, helper);
            } else {
                 helper.createComponent(component, event);
            }
        }
   },
   handleDocumentTagsChangedEvent : function(component, event, helper) {
       if(component.get("v.refreshControlInterface")){
           helper.resetAttributes(component, event, helper);
           helper.setupActionIcons(component, helper);
       }
   },


   handleDocumentTagsChangedEventLWT : function(component, event, helper) {
          if(component.get("v.refreshControlInterface")){
              helper.resetAttributes(component, event, helper);
              helper.setupActionIcons(component, helper);
          }
      }

})