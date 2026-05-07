/**
 * Created by havalakki on 3/6/2020.
 */
({
    showSuccessToastMessage : function(component, event, helper) {
            var toastEvent = $A.get("e.force:showToast");
            var title = component.get("v.toastSuccessTitle");
            var message = component.get("v.successMailMessage");
            toastEvent.setParams({
                "title": title,
                "message": message,
                "type": "success",
                "mode": "dismissible"
            });
            toastEvent.fire();
    },
})