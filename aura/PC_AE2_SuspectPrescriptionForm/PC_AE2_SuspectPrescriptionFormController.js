/**
 * Created by peharitha on 12/6/2018.
 */
({
    handleCancel : function(component, event, helper) {
        //closes the modal or popover from the component
        component.find("overlayLib").notifyClose();
    },

    upsertSuspectProduct: function (component, event, helper){
        var isEdit = component.get("v.isEdit");
        if(isEdit != true){
            helper.addSuspectProduct(component, event, helper);
        }else if(isEdit == true){
            helper.updateSuspectProduct(component, event, helper);
        }
    },

    autoPopulateProductDetails: function (component, event, helper){
        helper.autoPopulateProductDetails(component, event, helper);
    },
})