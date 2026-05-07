/**
 * Created by peharitha on 11/21/2018.
 */
({
    doInit: function(component, event, helper) {
        helper.fetchPatientInfoData(component);
        var aeId = component.get('v.aeId');
        var caseId = component.get("v.caseId");
        var patId = component.get("v.patientId");
        if(aeId != 'undefined' && aeId != null && !$A.util.isEmpty(aeId)){
            helper.loadDataFromAE(component, event, helper,aeId);
        }
        else if(caseId != 'undefined' && caseId != null && !$A.util.isEmpty(caseId)){
            helper.loadDataFromPatient(component, event, helper,caseId);
        }
        else if(!$A.util.isEmpty(patId)){
            debugger;
            helper.loadDataFromPatientRecord(component,event,helper);
        }
        else{
            //aeWrap = JSON.parse('{"race":"","ageType":"Year(s)"}');

            //component.set("v.aeWrapper" , aeWrap);
            helper.loadDataFromPatientRecord(component,event,helper);
        }

    },
    validatePatientInfo: function(component, event, helper) {
        return true;
    },
})