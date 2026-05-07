({
    getInitialReportData : function(component, event, helper){

        component.set("v.loaded",true);
        var caseId = component.get("v.caseId");
        var aeId = component.get("v.aeId");
        var patientId = component.get("v.patientId");
        var action = component.get("c.getInitialReporterData");

        action.setParams({
            caseIdParam : caseId,
            aeIdParam : aeId,
            patientIdParam : patientId
        });

        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {

                var returnValue = response.getReturnValue();
                component.set("v.fieldLabels", returnValue.fieldLabels);

                var reporterTypeOptions=[];
                for(var i=0;i< returnValue.reporterTypeOptions.length;i++){
                    reporterTypeOptions.push({label: returnValue.reporterTypeOptions[i].label, value:returnValue.reporterTypeOptions[i].value});
                }
                component.set("v.reporterTypeOptions", reporterTypeOptions);

                var healthCareProfessionalReporterTypeOptions = [];
                for(var j=0;j< returnValue.healthCareProfessionalReporterTypeOptions.length;j++){
                    healthCareProfessionalReporterTypeOptions.push({label: returnValue.healthCareProfessionalReporterTypeOptions[j].label, value:returnValue.healthCareProfessionalReporterTypeOptions[j].value});
                }
                component.set("v.healthCareProfessionalReporterTypeOptions", healthCareProfessionalReporterTypeOptions);

                var nonHealthCareProfessionalReporterTypeOptions = [];
                for(var k=0;k< returnValue.nonHealthCareProfessionalReporterTypeOptions.length;k++){
                    nonHealthCareProfessionalReporterTypeOptions.push({label: returnValue.nonHealthCareProfessionalReporterTypeOptions[k].label, value:returnValue.nonHealthCareProfessionalReporterTypeOptions[k].value});
                }
                component.set("v.nonHealthCareProfessionalReporterTypeOptions", nonHealthCareProfessionalReporterTypeOptions);

                var reporterSentToFdaOptions=[];
                for(var l=0;l< returnValue.reporterSentToFdaOptions.length;l++){
                    reporterSentToFdaOptions.push({label: returnValue.reporterSentToFdaOptions[l].label, value:returnValue.reporterSentToFdaOptions[l].value});
                }
                component.set("v.reporterSentToFdaOptions", reporterSentToFdaOptions);

                var healthCareProfessionalOptions=[];
                for(var m=0;m< returnValue.healthCareProfessionalOptions.length;m++){
                    healthCareProfessionalOptions.push({label: returnValue.healthCareProfessionalOptions[m].label, value:returnValue.healthCareProfessionalOptions[m].value});
                }
                component.set("v.healthCareProfessionalOptions", healthCareProfessionalOptions);
                if(!$A.util.isEmpty(returnValue.patientIdValue)){
                    component.set("v.patientId",returnValue.patientIdValue );
                }
                if($A.util.isEmpty(aeId) && (!$A.util.isEmpty(caseId) || (!$A.util.isEmpty(patientId) ))){

                   if(!$A.util.isEmpty(returnValue.defaultPatientReporter) && (!$A.util.isEmpty(returnValue.defaultReporterTypeValue))){
                        var reporterWrapper = returnValue.defaultPatientReporter

                        //var reporterType  = reporterWrapper['occupation'];
                        // var testing = component.get("v.existingReporterMap");

                        var aeWrapper = component.get("v.aeWrapper");
                        aeWrapper['occupation'] = returnValue.defaultReporterTypeValue;
                        //component.set("v.showRefreshIcon" , true);
                        helper.cloneExistingMap(component ,reporterWrapper);
                        // component.set("v.existingReporterMap", reporterWrapper);

                        component.set("v.existingReporterType" , returnValue.defaultReporterTypeValue);
                        component.set("v.aeWrapper.healthCareProfessional", returnValue.defaultHealthCareProfessionalValue);
                        helper.setReporterTypeOptions(component,event,helper);
                        helper.setAE2Wrapper(component,aeWrapper, reporterWrapper);

                    }
                }

            }else {
                helper.handleErrors(response.getError());
            }
            component.set("v.loaded",false);
        });
        $A.enqueueAction(action);
    },

    loadDataFromAE: function (component, event, helper){

        var action =  component.get("c.getDataFromAE");
        action.setParams({
            aeId: component.get("v.aeId"),
            initialReporterObj: component.get("v.aeWrapper")

        });
        action.setCallback(this, function(response){
            var state= response.getState();

            if (state == "SUCCESS"){

                var aeWrap =response.getReturnValue();
                component.set("v.aeWrapper" , aeWrap);

                if(!$A.util.isEmpty(aeWrap)){
                    var reporterType = aeWrap['occupation'];
                    component.set("v.showRefreshIcon" ,true);
                    helper.validateHealthCareProfessionalOption(component,event,helper);

                    helper.cloneExistingMap(component,aeWrap);

                    if($A.util.isEmpty(reporterType)){
                        component.set("v.existingReporterType" , '');
                    }else{
                        component.set("v.existingReporterType" , reporterType);

                    }
                    //}
                     // if none than do nothing but if value is there than show or hide warning
                }
            }
            else{
                helper.handleErrors(component, response.getError());
            }
        });
        $A.enqueueAction(action);
    },

    setReporterTypeOptions:function(component,event,helper){
        var healthCareProfessionalValue= event.getSource().get("v.value");
        var healthCareProfessionalReporterType = component.get("v.healthCareProfessionalReporterTypeOptions");
        var nonHealthCareProfessionalReporterType = component.get("v.nonHealthCareProfessionalReporterTypeOptions");

        if(healthCareProfessionalValue == "Yes"){
            component.set("v.showReporterWarning",false);
            component.set("v.wrongHealthCareProfessionalOption",false);
            component.set("v.reporterTypeOptions" , healthCareProfessionalReporterType);
        }
        else{
            component.set("v.showReporterWarning",false);
            component.set("v.wrongHealthCareProfessionalOption",false);
            component.set("v.reporterTypeOptions", nonHealthCareProfessionalReporterType);

        }
     },

    validateHealthCareProfessionalOption:function(component,event,helper)
    {
        var healthCareProfessionalReporterType = component.get("v.healthCareProfessionalReporterTypeOptions");
        var nonHealthCareProfessionalReporterType = component.get("v.nonHealthCareProfessionalReporterTypeOptions");

         var reporterType = component.get("v.aeWrapper.occupation");
         var healthCareProfessionalOptionSelected = component.get("v.aeWrapper.healthCareProfessional");
         var healthCareProfessionalReporterTypeLength = healthCareProfessionalReporterType.length;
         var nonHealthCareProfessionalReporterTypeLength = nonHealthCareProfessionalReporterType.length;
         var isHealthCareProfessionalWrong= false;
         if((!$A.util.isEmpty(reporterType)) && ($A.util.isEmpty(healthCareProfessionalOptionSelected))){
           isHealthCareProfessionalWrong = true;
           }
           if(healthCareProfessionalOptionSelected == "No"){
                       for( var i=0; i<healthCareProfessionalReporterTypeLength; i++){
                           if(reporterType == healthCareProfessionalReporterType[i].value ){
                               isHealthCareProfessionalWrong = true;
                           }
                       }
                   }
               else {
                     for( var j=0; j<nonHealthCareProfessionalReporterTypeLength; j++){
                           if(reporterType == nonHealthCareProfessionalReporterType[j].value){
                               isHealthCareProfessionalWrong = true;
                           }
                       }
                   }
           if(isHealthCareProfessionalWrong){
             component.set("v.wrongHealthCareProfessionalOption",true);

           }

     },

    onReporterTypeChange: function(component, event, helper){

        helper.validateHealthCareProfessionalOption(component,event,helper);
        var reportTypeValue = event.getSource().get("v.value");
        var existingWrapper = component.get("v.existingReporterMap");
        var existingRoleType = component.get("v.existingReporterType");
        if(reportTypeValue == 'None' || ($A.util.isEmpty(reportTypeValue) && ((reportTypeValue != existingRoleType) || JSON.stringify(existingWrapper).length ==2))){
            component.set("v.showRefreshIcon",false);

            helper.resetReporterValues(component,event,helper);
        }
        else{
            var result = helper.isExistingReporterTypeSelected(component, event, helper,reportTypeValue);
            if(!result || $A.util.isEmpty(result)){
                var caseId = component.get("v.caseId");

                if(!$A.util.isEmpty(caseId) ){

                    helper.setReporterValues(component, event, helper, reportTypeValue);
                }else{
                     component.set("v.showRefreshIcon",false);
                     helper.resetReporterValues(component,event,helper);
                }
            }
        }
    },

    resetReporterValues: function(component, event, helper){

        component.set('v.loaded', true);
        var aeWrapper  = component.get("v.aeWrapper");
        aeWrapper['firstName'] = '';
        aeWrapper['lastName'] = '';
        aeWrapper['address'] = '';
        aeWrapper['state'] = '';
        aeWrapper['zip'] = '';
        aeWrapper['phone'] = '';
        aeWrapper['city'] = '';
        aeWrapper['country'] = '';
        aeWrapper['email'] = '';
        component.set("v.aeWrapper",aeWrapper);
        component.set('v.loaded', false);
    },

    isExistingReporterTypeSelected :function(component, event, helper , roleType){

        var existingReporterType = component.get("v.existingReporterType");
        //if((!$A.util.isEmpty(existingReporterType) && roleType == existingReporterType)){
        if(roleType == existingReporterType){
            var reporterTypeWrapper = component.get("v.existingReporterMap");
            var aeWrapper = component.get("v.aeWrapper");

            // if(JSON.stringify(reporterTypeWrapper).length > 2){
            if (JSON.stringify(reporterTypeWrapper).length >2){
                var aeId = component.get("v.aeId");
                if(!$A.util.isEmpty(aeId)){
                    component.set("v.showRefreshIcon", true);
                }else{
                    component.set("v.showRefreshIcon",false);
                }


                helper.setAE2Wrapper(component,aeWrapper,reporterTypeWrapper)
                return true;
            // }else if(reporterTypeWrapper.size == 0  ){
            }else if(JSON.stringify(reporterTypeWrapper).length == 2 ){
                component.set("v.showRefreshIcon", false);
                helper.resetReporterValues(component, event, helper);
                return false;
            }
             else{
                component.set("v.showRefreshIcon", false);
                return false;
             }
        }
        else{
            component.set("v.showRefreshIcon", false);
            return false;
        }

    },

    setReporterValues: function(component, event, helper, typeValue){
        if(typeValue != 'None'){
        component.set('v.loaded', true);
        var caseIdVal = component.get("v.caseId");
          if(!$A.util.isEmpty(typeValue) && !$A.util.isEmpty(caseIdVal) ){
             var reporterAction = component.get("c.getReporterDataBasedOnRole");

             reporterAction.setParams({
                 "caseId" : caseIdVal,
                 "reporterRole" : typeValue
             });

             reporterAction.setCallback(this, function(response) {
                var state = response.getState();

                if (component.isValid() && state === "SUCCESS") {

                    var returnValue = response.getReturnValue();
                    // more than one is coming here

                    if(!$A.util.isEmpty(returnValue)){
                        if(!$A.util.isEmpty(returnValue.waringMessage)){
                             component.set("v.showReporterWarning",true );
                             component.set("v.morethanOneReporter" , true);
                              helper.resetReporterValues(component, event, helper);
                        }

                        else {
                            var aeWrapper  = component.get("v.aeWrapper");
                            helper.setAE2Wrapper(component,aeWrapper , returnValue)
                        }
                    }
                    else{
                        component.set("v.showReporterWarning",true );
                        component.set("v.notFoundReporter" , true);
                        helper.resetReporterValues(component, event, helper);
                    }
                }
                else {
                    helper.handleErrors(component,response.getError());
                }
                component.set('v.loaded', false);
             });
             $A.enqueueAction(reporterAction);
          }
        }
    },

    setAE2Wrapper: function(component,aeWrapper ,reporterWrapper){

        aeWrapper['firstName']=reporterWrapper.firstName;
        aeWrapper['lastName']=reporterWrapper.lastName;
        aeWrapper['state']=reporterWrapper.state;
        aeWrapper['zip']=reporterWrapper.zip;
        aeWrapper['phone']=reporterWrapper.phone;
        aeWrapper['city']=reporterWrapper.city;
        aeWrapper['address']=reporterWrapper.address;
        aeWrapper['email']=reporterWrapper.email;
        aeWrapper['country']=reporterWrapper.country;
        component.set("v.aeWrapper",aeWrapper);
        console.log('reporterWrapper'+reporterWrapper);

    },

    cloneExistingMap: function(component , aeWrapper){


        var existingMap = component.get("v.existingReporterMap");
         if(!$A.util.isEmpty(aeWrapper.firstName)){
            existingMap['firstName']=aeWrapper.firstName;
        }

        if(!$A.util.isEmpty(aeWrapper.lastName)){
            existingMap['lastName']=aeWrapper.lastName;
        }
        if(!$A.util.isEmpty(aeWrapper.state)){
            existingMap['state']=aeWrapper.state;
        }
        if(!$A.util.isEmpty(aeWrapper.zip)){
           existingMap['zip']=aeWrapper.zip;
        }
        if(!$A.util.isEmpty(aeWrapper.phone)){
           existingMap['phone']=aeWrapper.phone;
        }

        if(!$A.util.isEmpty(aeWrapper.city)){
           existingMap['city']=aeWrapper.city;
        }

        if(!$A.util.isEmpty(aeWrapper.address)){
            existingMap['address']=aeWrapper.address;
        }

        if(!$A.util.isEmpty(aeWrapper.email)){
            existingMap['email']=aeWrapper.email;
        }
        if(!$A.util.isEmpty(aeWrapper.country)){
            existingMap['country']=aeWrapper.country;
        }
        component.set("v.existingReporterMap",existingMap);
        console.log('existingMap'+existingMap);

    },


    onRefreshClick: function(component, event, helper){
        console.log('inside helper');
        var aeWrapper = component.get("v.aeWrapper");
        var roleType = aeWrapper['occupation'];

        if(!$A.util.isEmpty(roleType)){

            helper.setReporterValues(component, event , helper,roleType );
        }

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