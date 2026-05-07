/**
 * Created by shisbansal on 11/26/2018.
 */
({
    doInit: function(component, event, helper){

        helper.getManufacturerData(component);
         var aeId = component.get('v.aeId');
         var caseId = component.get("v.caseId");
         if(aeId != 'undefined' && aeId != null){
             helper.loadDataFromAE(component, event, helper);
        }
        else if(caseId != 'undefined' && caseId != null){
             helper.loadDataFromManufacturer(component, event, helper);
        }
    },

    onReportSourceChange: function(component, event, helper){
        helper.onReportSourceChange(component, event, helper);
    },

    onReportTypeChange: function(component, event, helper){
        helper.onReportTypeChange(component, event, helper);
    },
})