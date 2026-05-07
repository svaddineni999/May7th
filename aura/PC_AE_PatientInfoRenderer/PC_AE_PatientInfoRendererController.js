/**
 * Created by peharitha on 11/21/2018.
 */
({
    doInit: function(component, event, helper) {
        helper.fetchPatientInfoData(component);
        var aeId = component.get('v.aeId');
        var caseId = component.get("v.caseId");
        if(aeId != 'undefined' && aeId != null){
            helper.loadDataFromAE(component, event, helper,aeId);
        }
        else if(caseId != 'undefined' && caseId != null){
            helper.loadDataFromPatient(component, event, helper,caseId);
        }
        else{
        	var aeWrap = JSON.parse('{"race":""}');
            component.set("v.aeWrapper" , aeWrap);
        }
    },
    validatePatientInfo: function(component, event, helper) {
        return true;
    },
})