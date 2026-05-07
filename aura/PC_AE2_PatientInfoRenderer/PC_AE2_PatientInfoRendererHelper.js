/**
 * Created by peharitha on 11/21/2018.
 */
({
    loadDataFromAE: function (component, event, helper,aeId){
      
        var action =  component.get("c.fetchDataFromAE");
        action.setParams({
            aeId: aeId,
            patientInfoObj: component.get("v.aeWrapper")
        });
        action.setCallback(this, function(response){
            var state= response.getState();
            if (state == "SUCCESS"){
                var aeWrap =response.getReturnValue();
                component.set("v.aeWrapper" , aeWrap);
            }
            else{
                helper.handleErrors(component, response.getError());
            }
        });
        $A.enqueueAction(action);
    },
    
    loadDataFromPatient: function (component, event, helper,caseId){
        
        var patInfo = component.get("v.aeWrapper");
        
        var action =  component.get("c.fetchDataFromPatient");
        action.setParams({
            caseId: caseId,
            patInfo: patInfo
        });
        action.setCallback(this, function(response){
            var state= response.getState();
            if (state == "SUCCESS"){
                var aeWrap =response.getReturnValue();
                component.set("v.aeWrapper" , aeWrap);
            }
            else{
                helper.handleErrors(component, response.getError());
            }
        });
        $A.enqueueAction(action);
    },


     loadDataFromPatientRecord: function (component, event, helper){

        var patId = component.get("v.patientId");
        var action =  component.get("c.fetchDataFromPatientRecordPage");
        action.setParams({
           patientId: patId
        });
        action.setCallback(this, function(response){
            var state= response.getState();
            if (state == "SUCCESS"){
                var aeWrap =response.getReturnValue();
                component.set("v.aeWrapper" , aeWrap);
            }
            else{
                helper.handleErrors(component, response.getError());
            }
        });
        $A.enqueueAction(action);

    },

    fetchPatientInfoData : function(component){
        var action = component.get("c.getPatientInfoData");
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                
                var returnValue = response.getReturnValue();
                component.set("v.fieldLabels", returnValue.fieldLabels);
                
                var genderOptions=[];
                for(var i=0;i< returnValue.genderOptions.length;i++){
                    genderOptions.push({label: returnValue.genderOptions[i].label, value:returnValue.genderOptions[i].value});
                }
                component.set("v.genderOptions", genderOptions);
                
                var ethnicityOptions=[];
                for(var j=0;j< returnValue.ethnicityOptions.length;j++){
                    ethnicityOptions.push({label: returnValue.ethnicityOptions[j].label, value:returnValue.ethnicityOptions[j].value});
                }
                component.set("v.ethnicityOptions", ethnicityOptions);
                
                var raceOptions=[];
                for(var k=0;k< returnValue.raceOptions.length;k++){
                    raceOptions.push({label: returnValue.raceOptions[k].label, value:returnValue.raceOptions[k].value});
                }
                component.set("v.raceOptions", raceOptions);
                
                var weightOptions=[];
                for(var l=0;l< returnValue.weightOptions.length;l++){
                    weightOptions.push({label: returnValue.weightOptions[l].label, value:returnValue.weightOptions[l].value});
                }
                component.set("v.weightOptions", weightOptions);
                
                var ageTypeOptions=[];
                for(var m=0;m< returnValue.ageTypeOptions.length;m++){
                    ageTypeOptions.push({label: returnValue.ageTypeOptions[m].label, value:returnValue.ageTypeOptions[m].value});
                }
                component.set("v.ageTypeOptions", ageTypeOptions);
                
                
            }else {
                helper.handleErrors(response.getError());
            }
        });
        $A.enqueueAction(action);
    },
    handleErrors : function(component, errors) {
        // Configure error toast
        console.error('Errors:');
        console.error(errors);
        let toastParams = {
            title: "Error",
            message: component.get("v.errorDescription"), // Default error message
            type: "error"
        };
        // Pass the error message if any
        if (errors && Array.isArray(errors) && errors.length > 0) {
            toastParams.message = errors[0].message;
        }
        // Fire error toast
        let toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams(toastParams);
        toastEvent.fire();
    },
})