({
    showToast: function(component, event, helper) {
        debugger;
        var message = event.getParam("message");
        component.set("v.toastMessage", message);
        // get toast and remove class
        var toast = component.find("toast");
        $A.util.removeClass(toast, "slds-transition-hide");

        // get toastType and set the class
        var toastType = event.getParam("toastType");
        var alertType = component.find("alertType");

        if(toastType == 'success') {
            component.set("v.toastType", 'success');
        }
        if(toastType == 'error') {
            component.set("v.toastType", 'error');
            $A.util.removeClass(alertType, "slds-theme--success");
            $A.util.addClass(alertType, "slds-theme--error");
        }
        if(toastType == 'warning') {
            component.set("v.toastType", 'warning');
            $A.util.removeClass(alertType, "slds-theme--success");
            $A.util.addClass(alertType, "slds-theme--warning");
        }
        setTimeout($A.getCallback(function() {
            $A.util.addClass(toast, "transition-timing");
        	$A.util.addClass(toast, "slds-transition-hide");
        }), 2500);
    },

	dismissToast: function(component, event, helper) {
        var toast = component.find("toast");
    	$A.util.removeClass(toast, "transition-timing");
        $A.util.addClass(toast, "slds-transition-hide");
    }
})