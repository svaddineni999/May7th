/**
 * Created by kkanteti on 12/1/2021.
 */
({
    setPatientAddressConfig : function(component, event, helper){
        var configString = component.get("v.config");
        if(!$A.util.isUndefinedOrNull(configString)) {
            var config = JSON.parse(configString);
            component.set("v.patientInfoConfig",JSON.stringify(config.patientInfo));
            component.set("v.addressInfoConfig",JSON.stringify(config.addressInfo));
        }
        component.set("v.showPatientAddress",true);
    },
    validate : function(component, event, helper){
        var patientInfoCmp = component.find("patientInformation");
        if(!$A.util.isUndefinedOrNull(patientInfoCmp)){
            var patientInfoValid = patientInfoCmp.validate();
            if(!patientInfoValid){
                component.set("v.isValid",false);
            }else{
                var addressInfoCmp = component.find("addressInformation");
                if(!$A.util.isUndefinedOrNull(addressInfoCmp)){
                    var addressInfoIsValid = addressInfoCmp.validate();
                    if(!addressInfoIsValid){
                        component.set("v.isValid",false);
                    }else{
                        component.set("v.isValid",true);
                    }
                }
            }
        }
    },
})