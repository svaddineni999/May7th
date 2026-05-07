/**
 * Created by vkashikar on Jan 12 2018.
 */
({
    doInit : function(component, event, helper) {
        helper.resetAll(component, event, helper);
        helper.getPharmacyCardholderInfo(component, event, helper);
        helper.getRelatedHealthPlans(component, event, helper);
        //var ns = CH_PC_Util.getNamespace(component);
        //var nsPrefix = CH_PC_Util.getNamespacePrefix(component);
        //console.log("Namespace: " + ns);
        //console.log("NamespacePrefix: " + nsPrefix);
    },
    invokeLookupPharmacyCard : function (component, event, helper){
        helper.invokeLookupPharmacyCard(component, event, helper);
    },
    closeWindow : function(component, event, helper){
        helper.revertCssChange(component);
        helper.resetInvokeLookupPharmacyCard(component, event, helper);
    },
    showSpinner: function(component, event, helper) {
        var pharmaServerCall = component.get("v.isModalMapActive");
        if(pharmaServerCall == true){
          component.set("v.isModalMapActiveInner", false);
        }
    },
    hideSpinner : function(component,event,helper){
       var pharmaServerCall = component.get("v.isModalMapActive");
        if(pharmaServerCall == true){
          component.set("v.isModalMapActiveInner", true);
        }
    },
    saveHealthPlan : function(component, event, helper){
        helper.saveHealthPlan(component, event, helper);
    }
})