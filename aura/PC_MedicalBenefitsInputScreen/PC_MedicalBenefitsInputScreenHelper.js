/**
 * Created by Shishir Bansal on 1/31/2019.
 */
({
    setNamespace : function(component, event, helper) {
        var ns = CH_PC_Util.getNamespace(component);
        var nsPrefix = CH_PC_Util.getNamespacePrefix(component);
        component.set("v.namespace", ns);
        component.set("v.namespacePrefix", nsPrefix);
    },
    resetComponentAttributes : function(component) {
        component.set("v.currentPrescription" ,null);
        component.set("v.primaryHealthPlanOptions", null);
        component.set("v.noPlanTypePrimaryHealthPlanOptions", null);
        component.set("v.currentPrimaryHealthPlan", null);

        component.set("v.secondaryHealthPlanOptions", null);
        component.set("v.noPlanTypeSecondaryHealthPlanOptions", null);
        component.set("v.currentSecondaryHealthPlan", null);
        component.set("v.disableSecondarypicklist", true);
        component.set("v.resetSecondaryOption", false);

        component.set("v.tertiaryHealthPlanOptions", null);
        component.set("v.noPlanTypeTertiaryHealthPlanOptions", null);
        component.set("v.currentTertiaryHealthPlan", null);
        component.set("v.enableTertiarySection", false);
        component.set("v.resetTertiaryOption", false);

        component.set("v.noPlanTypeHealthPlanOptions", null);
        component.set("v.prescriptionOptions", null);

        component.set("v.clinicOptions", null);
        component.set("v.currentClinic", null);

        component.set("v.noAdminCodesHelpText" ,'');
        component.set("v.adminCodeOptions",null);
        component.set("v.isPrimaryHealthPlanValid",true);
        component.set("v.primaryHealthPlanErrors",null);
        component.set("v.isSecondaryHealthPlanValid",true);
        component.set("v.secondaryHealthPlanErrors",null);
        component.set("v.isTertiaryHealthPlanValid",true);
        component.set("v.tertiaryHealthPlanErrors",null);

    },
    init : function(component, event, helper) {

            component.set("v.showSpinner", true);
            var action = component.get("c.getMedicalBenefitsInfo");
            var caseId = component.get("v.caseId");
            action.setParams({
                "caseId" : caseId
            });
            action.setCallback(this, function(response) {

                var state = response.getState();
                if (component.isValid() && state === "SUCCESS") {
                    var returnValue = response.getReturnValue();

                    if((!$A.util.isEmpty(returnValue))){
                        component.set("v.showSpinner", false);

                        component.set("v.medicalBenefits",returnValue.formData);

                        // checking for the blank value conditions

                        if(!($A.util.isEmpty((returnValue.formData.noPlanTypeHealthPlansList))) ){

                            var noPlanTypeHealthPlansList = returnValue.formData.noPlanTypeHealthPlansList;

                            component.set("v.noPlanTypeHealthPlanOptions",noPlanTypeHealthPlansList);
                            component.set("v.noPlanTypePrimaryHealthPlanOptions",noPlanTypeHealthPlansList);
                            component.set("v.noPlanTypeSecondaryHealthPlanOptions",noPlanTypeHealthPlansList);
                            component.set("v.noPlanTypeTertiaryHealthPlanOptions",noPlanTypeHealthPlansList);

                        }


                        if( !($A.util.isEmpty((returnValue.formData.primaryHealthPlansList)))){

                            component.set('v.primaryHealthPlanOptions',returnValue.formData.primaryHealthPlansList);

                        }

                        if( !($A.util.isEmpty((returnValue.formData.secondaryHealthPlansList)))){

                            component.set('v.secondaryHealthPlanOptions',returnValue.formData.secondaryHealthPlansList);

                        }

                        if( !($A.util.isEmpty((returnValue.formData.tertiaryHealthPlansList)))){

                            component.set('v.tertiaryHealthPlanOptions',returnValue.formData.tertiaryHealthPlansList);

                        }

                        if( !($A.util.isEmpty((returnValue.formData.prescriptionDetailsList)))){

                            component.set('v.prescriptionOptions',returnValue.formData.prescriptionDetailsList);

                        }

                        if( !($A.util.isEmpty((returnValue.formData.clinicDetailsList)))){
                            var clinicOptions = returnValue.formData.clinicDetailsList ;
                            // aura id set message on error not on component level
                            // default method for clinic

                            var clinicDefaultValue = helper.setDefaultClinicValues(component, event, helper,clinicOptions );

                            if(!clinicDefaultValue){
                                component.set("v.clinicOptions", clinicOptions);
                            }
                        }
                        helper.setDefaultPrimaryValues(component, event, helper);
                        helper.setDefaultSecondaryValues(component, event, helper);
                        helper.setDefaultTertiaryValues(component, event, helper);
                        helper.setDefaultPrescriptionValues(component, event, helper);
                        helper.validateMedeBVForm(component, event, helper);

                        }
                    }
                else {
                   console.error("Something went wrong.");
                   console.error(response.getError());
                    var error = component.get("v.lightingErrorMessage");
                    var errors = response.getError();

                    if(!$A.util.isEmpty(errors) && errors.length > 0 && !$A.util.isEmpty(errors[0]['message'])) {
                         error = errors[0]['message'];

                    }
                    component.set("v.errors", [error]);

                    console.error(response.getError());
                    component.set("v.showSpinner", false);
                }
            });
            $A.enqueueAction(action);
        },

        clearErrorMessages: function(component, event, helper){
            var emptyArray;
            component.set("v.errors", emptyArray);
        },

        setPrimaryHealthPlanDetails: function(component, event, helper){
            // blank value should be set
            var primaryHealthPlanId = component.find('primaryHealthPlan').get('v.value');
            component.set('v.isSecondaryHealthPlanValid',true);
            component.set('v.secondaryHealthPlanErrors',null);
            component.set('v.isTertiaryHealthPlanValid',true);
            component.set('v.tertiaryHealthPlanErrors',null);

            if(primaryHealthPlanId == ''){

                var tactive = component.get("v.enableTertiarySection");
                if(tactive){
                     component.find("tertiaryHealthPlan").set("v.value",'');
                }

                component.set("v.currentPrimaryHealthPlan", null);


                component.set("v.currentTertiaryHealthPlan", null);
                component.set("v.resetTertiaryOption", true);
                component.set("v.enableTertiarySection", false);

                component.set("v.currentSecondaryHealthPlan", null);
                 component.set("v.resetSecondaryOption" , true);
                 component.find("secondaryHealthPlan").set("v.value",'');
                 component.set("v.disableSecondarypicklist", true);

                 var pHealthList = component.get("v.primaryHealthPlanOptions");
                 pHealthList =  helper.resetDropDownOptions(component, event, helper, pHealthList);
                 component.set("v.primaryHealthPlanOptions",pHealthList);

                 var sHealthList = component.get("v.secondaryHealthPlanOptions");
                 sHealthList =  helper.resetDropDownOptions(component, event, helper, sHealthList);
                 component.set("v.secondaryHealthPlanOptions",sHealthList);

                 var tHealthList = component.get("v.tertiaryHealthPlanOptions");
                 tHealthList =  helper.resetDropDownOptions(component, event, helper, tHealthList);
                 component.set("v.tertiaryHealthPlanOptions",tHealthList);

                 var noPHealthList = component.get("v.noPlanTypePrimaryHealthPlanOptions");
                 noPHealthList =  helper.resetDropDownOptions(component, event, helper, noPHealthList);
                 component.set("v.noPlanTypePrimaryHealthPlanOptions",noPHealthList);
                 component.set("v.noPlanTypeSecondaryHealthPlanOptions",noPHealthList);
                 component.set("v.noPlanTypeTertiaryHealthPlanOptions",noPHealthList);



            }
            else{
                var primaryHealthPlans = component.get("v.primaryHealthPlanOptions");
                var noplanType = component.get("v.noPlanTypeHealthPlanOptions");
                // SETTING ACCORDION VALUES FOR THE PRIMARY HEALTH PLAN
                var selectedPrimaryHealthPlan = helper.selectedHealthPlanDetails(component, primaryHealthPlanId, primaryHealthPlans);
                component.set("v.currentPrimaryHealthPlan",selectedPrimaryHealthPlan);
                // RESETTING VALUES FOR THE SECONDARY NON PLAN TYPE
                component.set("v.noPlanTypeSecondaryHealthPlanOptions",noplanType);
                var noPlanSecondaryList = component.get("v.noPlanTypeSecondaryHealthPlanOptions");
                // RESETTING VALUES FOR THE TERTIARY NON PLAN TYPE
                component.set("v.noPlanTypeTertiaryHealthPlanOptions",noplanType);
                var noPlanTertiaryList = component.get("v.noPlanTypeTertiaryHealthPlanOptions");

                // SPLICING THE SECONDARY NON PLAN LIST IF IT IS SELECTED IN PRIMARY DROPDOWN

                var updatedNoPlanList =helper.updatingNoPlanTypeList(primaryHealthPlanId,noPlanSecondaryList ) ;


                //if( !$A.util.isEmpty(updatedNoPlanList)){
                if( updatedNoPlanList != null){
                    if( (updatedNoPlanList.length != noplanType.length)){
                        component.set("v.noPlanTypeSecondaryHealthPlanOptions",updatedNoPlanList );
                    }

                }


                // SPLICING THE TERTIARY NON PLAN LIST IF IT IS SELECTED IN THE PRIMARY DROPDOWN

                updatedNoPlanList =helper.updatingNoPlanTypeList(primaryHealthPlanId,noPlanTertiaryList ) ;
                if(updatedNoPlanList != null){
                    if((updatedNoPlanList.length != noplanType.length) && (updatedNoPlanList.length !=0)){

                     component.set("v.noPlanTypeTertiaryHealthPlanOptions",updatedNoPlanList );
                     component.set("v.resetSecondaryOption", false);
                     component.set("v.disableSecondarypicklist", false);
                    }

                }

                helper.setDefaultSecondaryValues(component, event, helper);
                helper.setDefaultTertiaryValues(component, event, helper);

            }
        },


        setSecondaryHealthPlanDetails: function(component, event, helper){
            component.set('v.isTertiaryHealthPlanValid',true);
            component.set('v.tertiaryHealthPlanErrors',null);
            var primaryHealthPlanId = component.find('primaryHealthPlan').get('v.value');
            var secondaryHealthPlanId = component.find('secondaryHealthPlan').get('v.value');

            var secondaryHealthPlans = component.get("v.secondaryHealthPlanOptions");
            var noplanType = component.get("v.noPlanTypeHealthPlanOptions");

            if(secondaryHealthPlanId == ''){

                component.set("v.currentSecondaryHealthPlan", null);

                component.set("v.resetTertiaryOption", true);
                component.set("v.currentTertiaryHealthPlan", null);

                var tactive = component.get("v.enableTertiarySection");
                if(tactive){
                    component.find("tertiaryHealthPlan").set("v.value",'');
                }
                component.set("v.enableTertiarySection", false);

                var noSPlanList = component.get("v.noPlanTypeSecondaryHealthPlanOptions");
                noSPlanList = helper.resetDropDownOptions(component, event, helper, noSPlanList);

                component.set("v.noPlanTypeSecondaryHealthPlanOptions",noSPlanList);

                component.set("v.noPlanTypeTertiaryHealthPlanOptions", noplanType);
            }
            else{


                //component.set("v.enableTertiarySection", true);

                // resetting tertiary no plan list

                component.set("v.noPlanTypeTertiaryHealthPlanOptions",noplanType);
                var noPlanTertiaryList = component.get("v.noPlanTypeTertiaryHealthPlanOptions");


                var selectedSecondaryHealthPlan = helper.selectedHealthPlanDetails(component, secondaryHealthPlanId, secondaryHealthPlans);
                component.set("v.currentSecondaryHealthPlan",selectedSecondaryHealthPlan);

                // splicing primary selection from tertiary no plan list

                var updatedNoPlanList =helper.updatingNoPlanTypeList(primaryHealthPlanId,noPlanTertiaryList ) ;

                if( $A.util.isEmpty(updatedNoPlanList)){

                    if( updatedNoPlanList != null){

                    // splicing secondary selection from tertiary no plan list
                    updatedNoPlanList =helper.updatingNoPlanTypeList(secondaryHealthPlanId,updatedNoPlanList ) ;
                    }

                    else{
                        updatedNoPlanList =helper.updatingNoPlanTypeList(secondaryHealthPlanId,noPlanTertiaryList ) ;
                    }
                }



                if(updatedNoPlanList != null){
                    if( (updatedNoPlanList.length != noplanType.length) && (updatedNoPlanList.length !=0)){
                        component.set("v.noPlanTypeTertiaryHealthPlanOptions",updatedNoPlanList );
                        component.set("v.enableTertiarySection", true);
                        component.set("v.resetTertiaryOption", false);

                    }
                }
            }

            helper.setDefaultTertiaryValues(component, event, helper);
        },

        setTertiaryHealthPlanDetails: function(component, event, helper){

            var tactive = component.get("v.enableTertiarySection");

            if(tactive){

                var tertiaryHealthPlanId = component.find('tertiaryHealthPlan').get('v.value');
            }
            var tertiaryHealthPlans = component.get("v.tertiaryHealthPlanOptions");

            var selectedTertiaryHealthPlan = helper.selectedHealthPlanDetails(component, tertiaryHealthPlanId, tertiaryHealthPlans);
            component.set("v.currentTertiaryHealthPlan",selectedTertiaryHealthPlan);
        },


        selectedHealthPlanDetails: function(component, healthPlanId , healthPlans){


            var noplanTypeHealthPlans  = component.get("v.noPlanTypeHealthPlanOptions");
            var concatHealthPlans;
            if(!($A.util.isEmpty(healthPlans))){

                if(!($A.util.isEmpty(noplanTypeHealthPlans))){
                    concatHealthPlans= healthPlans.concat(noplanTypeHealthPlans);
                }
                else{
                    concatHealthPlans =healthPlans;
                }
            }
            else  if(!($A.util.isEmpty(noplanTypeHealthPlans))){
                concatHealthPlans = noplanTypeHealthPlans
            }

            else{
                return null;
            }

            for(var i=0, iLen=concatHealthPlans.length; i<iLen; i++){
                if(concatHealthPlans[i].id == healthPlanId){
                    return concatHealthPlans[i];

                }
            }
            return null;
        },

        setPrescriptionDetails: function(component, event, helper){
            component.set("v.noAdminCodesHelpText",'');
            component.set("v.adminCodeOptions",null);
            var prescriptionId = component.find('prescription').get("v.value");

            var prescriptionOptions = component.get("v.prescriptionOptions");

            if(prescriptionId != ''){
                 for(var i=0, iLen=prescriptionOptions.length; i<iLen; i++){
                       if(prescriptionOptions[i].id == prescriptionId){
                            component.set("v.currentPrescription", prescriptionOptions[i]);
                            component.set("v.adminCodeOptions",prescriptionOptions[i].adminCodes);
                            if($A.util.isUndefined(prescriptionOptions[i].adminCodes)){
                                component.set("v.noAdminCodesHelpText",$A.get("{!$Label.c.PC_MedicalBenefits_NoAdminCodesHelpText}"));
                            }
                            return null;
                       }

                 }

            }
            else{

                component.set("v.currentPrescription",null );
                helper.resetDropDownOptions(component, event, helper,prescriptionOptions);

            }
        },


        setClinicDetails:function(component, event, helper){

            var clinicId = component.find('clinic').get("v.value");

            var clinicOptions = component.get("v.clinicOptions");

            if(clinicId != ''){

                for(var i=0, iLen=clinicOptions.length; i<iLen; i++){
                    if(clinicOptions[i].clinicId == clinicId){

                        component.set("v.currentClinic",clinicOptions[i] );

                        return null;

                    }
                }
            }
            else{
                 component.set("v.currentClinic",null );
                 helper.resetDropDownOptions(component, event, helper,clinicOptions);
            }



        },

        updatingNoPlanTypeList: function( noPlanIdSelected , noPlanList){

            if(!$A.util.isEmpty(noPlanList)){
              for(var i=0, iLen=noPlanList.length; i<iLen; i++){
                    if(noPlanList[i].id == noPlanIdSelected){

                       noPlanList.splice(i,1);
                       return noPlanList;
                    }
              }
            }

            return null;
        },

        setDefaultClinicValues:function(component, event, helper, clinicList){
            if(clinicList.length == 1){
                component.set("v.currentClinic",clinicList[0]);
                component.find('clinic').set("v.value",clinicList[0].clinicId);
                clinicList[0]['selected'] = true;

               component.set("v.clinicOptions", clinicList);
               return true;
            }
            else{
                return false;
            }
        },

        setDefaultPrimaryValues: function(component, event, helper){
            var primaryList = component.get("v.primaryHealthPlanOptions");
            var primaryLength = 0;
            var pOptions ;
            var noPlanList = component.get("v.noPlanTypePrimaryHealthPlanOptions");
            var pHealthLength = !$A.util.isEmpty(primaryList) ? primaryList.length:0;
            var noPHealthLength =(!$A.util.isEmpty(noPlanList))? noPlanList.length:0;
            primaryLength = pHealthLength +  noPHealthLength;

            if(primaryLength == 1){
                if(pHealthLength ==1){
                    pOptions = component.get("v.primaryHealthPlanOptions");
                    component.set("v.currentPrimaryHealthPlan", pOptions[0] );
                    pOptions[0]['selected'] = true;
                    component.set("v.primaryHealthPlanOptions",pOptions);

                }
                else{
                    pOptions = component.get("v.noPlanTypePrimaryHealthPlanOptions");
                    component.set("v.noPlanTypeSecondaryHealthPlanOptions" , null);
                    component.set("v.noPlanTypeTertiaryHealthPlanOptions", null);
                    component.set("v.currentPrimaryHealthPlan", pOptions[0] );
                     pOptions[0]['selected'] = true;
                    component.set("v.noPlanTypePrimaryHealthPlanOptions",pOptions);

                }
                component.find("primaryHealthPlan").set("v.value",  pOptions[0].id);
            }
        },

        setDefaultSecondaryValues: function(component, event, helper){

            var secondaryList = component.get("v.secondaryHealthPlanOptions");
            var sHealthLength = (!$A.util.isEmpty(secondaryList))? secondaryList.length:0;

            var sOptions ;

            var noSPlanList = component.get("v.noPlanTypeSecondaryHealthPlanOptions");
            var noSLength = (!$A.util.isEmpty(noSPlanList))? noSPlanList.length:0;


            var currentPrimaryHealthPlan = component.get("v.currentPrimaryHealthPlan");
            var secondaryLength = noSLength + sHealthLength;

            if(secondaryLength == 1 && (!$A.util.isEmpty(currentPrimaryHealthPlan))){

                component.set("v.disableSecondarypicklist", false);

                if(sHealthLength ==1){
                   sOptions = component.get("v.secondaryHealthPlanOptions");
                   component.set("v.currentSecondaryHealthPlan", sOptions[0] );
                   sOptions[0]['selected'] = true;
                   component.set("v.secondaryHealthPlanOptions",sOptions);
                }

                else{
                    sOptions = component.get("v.noPlanTypeSecondaryHealthPlanOptions");
                    component.set("v.currentSecondaryHealthPlan", sOptions[0] );
                    sOptions[0]['selected'] = true;
                    component.set("v.noPlanTypeSecondaryHealthPlanOptions",sOptions);
                    component.set("v.noPlanTypeTertiaryHealthPlanOptions", null);

                }



                component.find("secondaryHealthPlan").set("v.value",  sOptions[0].id);

            }

            if(secondaryLength == 0){

                var nonePickVal = component.get("v.nonePicklistValue");

                component.find("secondaryHealthPlan").set("v.value", nonePickVal);
                component.set("v.resetSecondaryOption", true);
                component.set("v.disableSecondarypicklist", true);
                component.set("v.currentSecondaryHealthPlan", null);

            }

            if( (secondaryLength > 1) && (!$A.util.isEmpty(currentPrimaryHealthPlan))  ){

                component.set("v.resetSecondaryOption", false);
                component.set("v.disableSecondarypicklist", false);
                component.set("v.currentSecondaryHealthPlan", null);

            }

        },

        handleSubmit: function(component, event, helper){
            component.set("v.showProgressOnSubmit", true);
            var caseId = component.get("v.caseId");
            var primaryId = !$A.util.isEmpty( component.get("v.currentPrimaryHealthPlan")) ?  component.get("v.currentPrimaryHealthPlan").id : null;
            var secondaryId = !$A.util.isEmpty(component.get("v.currentSecondaryHealthPlan"))? component.get("v.currentSecondaryHealthPlan").id : null;
            var tertiaryId = !$A.util.isEmpty(component.get("v.currentTertiaryHealthPlan"))?  component.get("v.currentTertiaryHealthPlan").id : null;

            var presId = !$A.util.isEmpty(component.get("v.currentPrescription")) ? component.get("v.currentPrescription").id : null;
            var clinicId =!$A.util.isEmpty(component.get("v.currentClinic"))? component.get("v.currentClinic").clinicId : null;
            var patientId =!$A.util.isEmpty(component.get("v.medicalBenefits").patientDetails.id) ? component.get("v.medicalBenefits").patientDetails.id : null;
            var action = component.get("c.submitMedicalBenefitsInfo");
            action.setParams({
                "caseId" : caseId,
                "primaryHealthPlanId": primaryId,
                "secondaryHealthPlanId": secondaryId,
                "tertiaryHealthPlanId": tertiaryId,
                "prescriptionId": presId,
                "clinicId": clinicId,
                "patientId": patientId,
                "adminCodes": component.get("v.selectedAdminCodes")
            });
            action.setCallback(this, function(response) {
                var state = response.getState();
                component.set("v.showProgressOnSubmit", false);
                if (component.isValid() && state === "SUCCESS") {
                    var returnValue = response.getReturnValue();
                    if(!$A.util.isUndefinedOrNull(returnValue)){
                        if(returnValue.isSuccess){
                            var successMessages = component.get("v.successMessage");
                            for(var i=0; i<returnValue.successMessages.length; i++){
                                if(!$A.util.isUndefinedOrNull(successMessages)){
                                    successMessages =  successMessages+ '\n' +returnValue.successMessages[i] ;
                                }else{
                                    successMessages =  returnValue.successMessages[i] ;
                                }
                            }
                            component.find('notifLib').showToast({
                                "variant": "success",
                                "header": "SUCCESS!",
                                "message": successMessages,
                                "mode":"sticky"
                            });
                            component.find("medicalBenefitsPopup").notifyClose();
                            var refreshEvent = $A.get("e.c:PC_RefreshMedeBVListView");
                            refreshEvent.fire();
                        }else{
                            var errorMessages = [];
                            //errorMessages.push(component.get("v.errorMessage"));
                            if(returnValue.errors != null) {
                                if(returnValue.errors.length == 0) {
                                    errorMessages.push(component.get("v.lightingErrorMessage"));
                                }
                                else {
                                    for(var j = 0; j < returnValue.errors.length ; j++) {
                                        errorMessages.push(returnValue.errors[j]);
                                    }
                                }
                            }
                            component.set("v.errors",errorMessages);
                        }
                    }
                }else {
                    console.error("Something went wrong.");
                    console.error(response.getError());
                    var lError = component.get("v.lightingErrorMessage");
                    var errors = response.getError();
                    var error;
                    if(!$A.util.isEmpty(errors) && errors.length > 0 && !$A.util.isEmpty(errors[0]['message'])) {
                        error = errors[0]['message'];
                    }
                    component.set("v.errors", [lError, error]);
                    console.error(response.getError());
                }
            });
            $A.enqueueAction(action);
        },

        setDefaultTertiaryValues: function(component, event, helper){


            var tertiaryList = component.get("v.tertiaryHealthPlanOptions");
            var tHealthLength = (!$A.util.isEmpty(tertiaryList))? tertiaryList.length:0;

            var tOptions ;

            var noTPlanList = component.get("v.noPlanTypeTertiaryHealthPlanOptions");
            var noTLength = (!$A.util.isEmpty(noTPlanList))? noTPlanList.length:0;


            var tertiaryLength = tHealthLength +  noTLength;

            var currentSecondaryPlan = component.get("v.currentSecondaryHealthPlan");


            if(tertiaryLength == 1 && (!$A.util.isEmpty(currentSecondaryPlan))){

                component.set("v.resetTertiaryOption", false);
                component.set("v.enableTertiarySection", true);


                if(tHealthLength ==1){
                    tOptions = component.get("v.tertiaryHealthPlanOptions");
                    component.set("v.currentTertiaryHealthPlan", tOptions[0] );
                    tOptions[0]['selected'] = true;
                    component.set("v.tertiaryHealthPlanOptions",tOptions);
                }

                else{
                    tOptions = component.get("v.noPlanTypeTertiaryHealthPlanOptions");
                    component.set("v.currentTertiaryHealthPlan", tOptions[0] );
                    tOptions[0]['selected'] = true;
                    component.set("v.noPlanTypeTertiaryHealthPlanOptions",tOptions);

                }
                component.find("tertiaryHealthPlan").set("v.value",  tOptions[0].id);

            }

            if(tertiaryLength ==0){
             component.set("v.resetTertiaryOption", true);
                component.set("v.currentTertiaryHealthPlan", null);
                var tactive = component.get("v.enableTertiarySection");
                if(tactive){
                     component.find("tertiaryHealthPlan").set("v.value",'');
                }

                component.set("v.enableTertiarySection", false);
            }

            if( (tertiaryLength > 1 && (!$A.util.isEmpty(currentSecondaryPlan)))){
                component.set("v.resetTertiaryOption", true);
                component.set("v.enableTertiarySection", true);
                component.set("v.currentTertiaryHealthPlan", null);


            }
        },

        setDefaultPrescriptionValues : function(component, event, helper){
            var prescriptionOptions = component.get("v.prescriptionOptions");
            if(!$A.util.isEmpty(prescriptionOptions)){
                if(prescriptionOptions.length == 1){
                    component.set("v.currentPrescription",prescriptionOptions[0] );

                    component.set("v.adminCodeOptions",prescriptionOptions[0].adminCodes);
                    if($A.util.isUndefined(prescriptionOptions[0].adminCodes)){
                        component.set("v.noAdminCodesHelpText",$A.get("{!$Label.c.PC_MedicalBenefits_NoAdminCodesHelpText}"));
                    }

                    component.find("prescription").set("v.value" ,prescriptionOptions[0].id );
                    prescriptionOptions[0]['selected'] = true;

                    component.set("v.prescriptionOptions", prescriptionOptions);

                }
            }
        },

        resetDropDownOptions: function(component, event, helper, resetHealthPlanList){

            if(!$A.util.isEmpty(resetHealthPlanList)){

                for(var i=0, iLen=resetHealthPlanList.length; i<iLen; i++){

                  resetHealthPlanList[i]['selected'] = false;

                }

                return resetHealthPlanList;

            }
            return null;
        },

    validateMedeBVForm: function(component, event, helper){
        helper.validatePatientDetails(component, event, helper);
        helper.validatePrimaryHealthPlan(component, event, helper);
        helper.validateSecondaryHealthPlan(component, event, helper);
        helper.validateTertiaryHealthPlan(component, event, helper);
        helper.validatePrescription(component, event, helper);
        helper.validateClinic(component, event, helper);
    },
    addErrorTolst: function(component,helper,errorMessage){
        var errorlst = component.get("v.errors");
        if(errorlst == null){
           errorlst = [];
        }
        errorlst.push(errorMessage);
        component.set('v.errors',errorlst);
    },
    checkIfFormValid: function(component, event, helper){
        var isPrimaryHealthPlanValid = component.get("v.isPrimaryHealthPlanValid");
        var isSecondaryHealthPlanValid = component.get("v.isSecondaryHealthPlanValid");
        var isTertiaryHealthPlanValid = component.get("v.isTertiaryHealthPlanValid");
        var isPrescriptionValid = component.get("v.isPrescriptionValid");
        var isFormValidStandard = component.get("v.isFormValidStandard");
        var isPatientValid = component.get("v.isPatientValid");
        if(isPatientValid && isPrimaryHealthPlanValid && isSecondaryHealthPlanValid && isTertiaryHealthPlanValid && isPrescriptionValid && isFormValidStandard){
            component.set("v.isFormValid",true);
        }else{
            component.set("v.isFormValid",false);
        }
    },
    validatePrescription: function(component, event, helper){
        component.set('v.isPrescriptionValid',true);
        component.set('v.prescriptionErrors',null);
        var currentPrescription = component.get("v.currentPrescription");
        var prescriptionLabels = component.get("v.medicalBenefits").prescriptionLabels;
        var missingFieldsList = '';
        if(!$A.util.isEmpty(currentPrescription)){
            if($A.util.isEmpty(currentPrescription.drug.name)){
                missingFieldsList = missingFieldsList+ ', '+prescriptionLabels.productName;
            }
            if($A.util.isEmpty(currentPrescription.drug.strength)){
                missingFieldsList = missingFieldsList+ ', '+prescriptionLabels.strength;
            }
            if($A.util.isEmpty(currentPrescription.primaryDiagnosis)){
                missingFieldsList = missingFieldsList+ ', '+prescriptionLabels.primaryDiagnosis;
            }
            if($A.util.isEmpty(currentPrescription.placeOfService)){
                missingFieldsList = missingFieldsList+ ', '+prescriptionLabels.placeOfService;
            }
            if($A.util.isEmpty(currentPrescription.physician.firstName)){
                missingFieldsList = missingFieldsList+ ', '+prescriptionLabels.providerFirstName;
            }
            if($A.util.isEmpty(currentPrescription.physician.lastName)){
                missingFieldsList = missingFieldsList+ ', '+prescriptionLabels.providerLastName;
            }
            if($A.util.isEmpty(currentPrescription.physician.npi)){
                missingFieldsList = missingFieldsList+ ', '+prescriptionLabels.providerNPI;
            }
            if($A.util.isEmpty(currentPrescription.physician.address.state)){
                missingFieldsList = missingFieldsList+ ', '+prescriptionLabels.providerState;
            }
            if($A.util.isEmpty(currentPrescription.drug.drugManufacturerName)){
                missingFieldsList = missingFieldsList+ ', '+prescriptionLabels.drugManufacturer;
            }

            missingFieldsList = missingFieldsList.substring(1);
            if(!$A.util.isEmpty(missingFieldsList)){
                component.set('v.isPrescriptionValid',false);
                var errorlst = component.get("v.prescriptionErrors");
                if(errorlst == null){
                   errorlst = [];
                }
                var requiredFieldMissingError = component.get("v.requiredFieldMissingError");
                errorlst.push(requiredFieldMissingError+missingFieldsList);
                component.set('v.prescriptionErrors',errorlst);
            }
        }
    },
    validateClinic: function(component, event, helper){
        component.set('v.isClinicValid',true);
        component.set('v.clinicErrors',null);
        var currentClinic = component.get("v.currentClinic");
        var clinicLabels = component.get("v.medicalBenefits").clinicLabels;
        var missingFieldsList = '';
        if(!$A.util.isEmpty(currentClinic)){
            if($A.util.isEmpty(currentClinic.npi)){
                missingFieldsList = missingFieldsList+ ', '+clinicLabels.clinicNpiLabel;
            }
            missingFieldsList = missingFieldsList.substring(1);
            if(!$A.util.isEmpty(missingFieldsList)){
                component.set('v.isClinicValid',false);
                var errorlst = component.get("v.clinicErrors");
                if(errorlst == null){
                   errorlst = [];
                }
                var requiredFieldMissingError = component.get("v.requiredFieldMissingError");
                errorlst.push(requiredFieldMissingError+missingFieldsList);
                component.set('v.clinicErrors',errorlst);
            }
        }
    },
    validatePatientDetails: function(component, event, helper){
        component.set('v.isPatientValid',true);
        component.set('v.patientErrors',null);
        var patient = component.get("v.medicalBenefits").patientDetails;
        var patientLabels = component.get("v.medicalBenefits").patientLabels;
        var missingFieldsList = '';
        if($A.util.isEmpty(patient.firstName)){
            missingFieldsList = missingFieldsList+ ', '+patientLabels.firstNameLabel;
        }
        if($A.util.isEmpty(patient.lastName)){
            missingFieldsList = missingFieldsList+ ', '+patientLabels.lastNameLabel;
        }
        if($A.util.isEmpty(patient.dob)){
            missingFieldsList = missingFieldsList+ ', '+patientLabels.dobLabel;
        }
        if($A.util.isEmpty(patient.gender)){
            missingFieldsList = missingFieldsList+ ', '+patientLabels.genderLabel;
        }
        missingFieldsList = missingFieldsList.substring(1);
        if(!$A.util.isEmpty(missingFieldsList)){
            component.set('v.isPatientValid',false);
            var errorlst = component.get("v.patientErrors");
            if(errorlst == null){
               errorlst = [];
            }
            var requiredFieldMissingError = component.get("v.requiredFieldMissingError");
            errorlst.push(requiredFieldMissingError+missingFieldsList);
            component.set('v.patientErrors',errorlst);
        }
    },
    validatePrimaryHealthPlan: function(component, event, helper){
        helper.validateHealthPlan(component,helper,component.find("primaryHealthPlan"),component.get("v.currentPrimaryHealthPlan"),'primary');
    },
    validateSecondaryHealthPlan: function(component, event, helper){
        helper.validateHealthPlan(component,helper,component.find("secondaryHealthPlan"),component.get("v.currentSecondaryHealthPlan"),'secondary');
    },
    validateTertiaryHealthPlan: function(component, event, helper){
        helper.validateHealthPlan(component,helper,component.find("tertiaryHealthPlan"),component.get("v.currentTertiaryHealthPlan"),'tertiary');
    },
    validateHealthPlan: function(component,helper,healthPlan,selectedPlan,healthPlanType){
        helper.resetHealthPlanValidations(component,healthPlanType);
        var medicalBenefitsFieldLabels = component.get("v.medicalBenefits").medicalBenefitsFieldLabels;
        if(selectedPlan != null){
            var healthPlanValue = healthPlan.get("v.value");
            var missingFieldsList = '';
            var errorMessage;

            if(!$A.util.isEmpty(healthPlanValue)){
                if($A.util.isEmpty(selectedPlan.payerName)){
                    missingFieldsList = missingFieldsList+ ', '+medicalBenefitsFieldLabels.payerNameLabel;
                }
                if($A.util.isEmpty(selectedPlan.relationshipToCardholder)){
                    missingFieldsList = missingFieldsList+ ', '+medicalBenefitsFieldLabels.relationshipToCardholderLabel;
                }
                if(!$A.util.isEmpty(selectedPlan.relationshipToCardholder) &&
                        selectedPlan.relationshipToCardholder.toLowerCase() != 'self' && $A.util.isEmpty(selectedPlan.memberId)){
                    missingFieldsList = missingFieldsList+ ', '+medicalBenefitsFieldLabels.memberIdLabel;
                }
                missingFieldsList = missingFieldsList.substring(1);
                if(!$A.util.isEmpty(missingFieldsList)){
                    var requiredFieldMissingError = component.get("v.requiredFieldMissingError");
                    errorMessage = requiredFieldMissingError+missingFieldsList;
                    helper.addHealthPlanErrors(component,healthPlanType,errorMessage);
                }
            }
        }
    },
    addHealthPlanErrors: function(component,healthPlanType,errorMessage){
        var errorlst;
        if(healthPlanType == 'primary'){
            component.set('v.isPrimaryHealthPlanValid',false);
            errorlst = component.get("v.primaryHealthPlanErrors");
            if(errorlst == null){
               errorlst = [];
            }
            errorlst.push(errorMessage);
            component.set('v.primaryHealthPlanErrors',errorlst);
        }else if(healthPlanType == 'secondary'){
            component.set('v.isSecondaryHealthPlanValid',false);
            errorlst = component.get("v.secondaryHealthPlanErrors");
            if(errorlst == null){
               errorlst = [];
            }
            errorlst.push(errorMessage);
            component.set('v.secondaryHealthPlanErrors',errorlst);
        }else if(healthPlanType == 'tertiary'){
            component.set('v.isTertiaryHealthPlanValid',false);
            errorlst = component.get("v.tertiaryHealthPlanErrors");
            if(errorlst == null){
               errorlst = [];
            }
            errorlst.push(errorMessage);
            component.set('v.tertiaryHealthPlanErrors',errorlst);
        }
    },
    resetHealthPlanValidations: function(component,healthPlanType){
        if(healthPlanType == 'primary'){
            component.set('v.isPrimaryHealthPlanValid',true);
            component.set('v.primaryHealthPlanErrors',null);
        }else if(healthPlanType == 'secondary'){
            component.set('v.isSecondaryHealthPlanValid',true);
            component.set('v.secondaryHealthPlanErrors',null);
        }else if(healthPlanType == 'tertiary'){
            component.set('v.isTertiaryHealthPlanValid',true);
            component.set('v.tertiaryHealthPlanErrors',null);
        }
    },
    doStandardValidations: function(component,helper){
        component.set('v.isFormValidStandard',true);
        var adminCodes = component.find("adminCodes");
        if(!$A.util.isUndefined(adminCodes)){
            if(!adminCodes.checkValidity()){
                component.set('v.isFormValidStandard',false);
                adminCodes.showHelpMessageIfInvalid();
            }
        }
        var clinic = component.find("clinic");
        if(!clinic.checkValidity()){
            component.set('v.isFormValidStandard',false);
            clinic.showHelpMessageIfInvalid();
        }
        var prescription = component.find("prescription");
        if(!prescription.checkValidity()){
            component.set('v.isFormValidStandard',false);
            prescription.showHelpMessageIfInvalid();
        }
        var primaryHealthPlan = component.find("primaryHealthPlan")
        if(!$A.util.isUndefined(primaryHealthPlan)){
            if(!primaryHealthPlan.checkValidity()){
                component.set('v.isFormValidStandard',false);
                primaryHealthPlan.showHelpMessageIfInvalid();
            }
        }
        var secondaryHealthPlan = component.find("secondaryHealthPlan")
        if(!$A.util.isUndefined(secondaryHealthPlan)){
            if(!secondaryHealthPlan.checkValidity()){
                component.set('v.isFormValidStandard',false);
                secondaryHealthPlan.showHelpMessageIfInvalid();
            }
        }
        var tertiaryHealthPlan = component.find("tertiaryHealthPlan")
        if(!$A.util.isUndefined(tertiaryHealthPlan)){
            if(!tertiaryHealthPlan.checkValidity()){
                component.set('v.isFormValidStandard',false);
                tertiaryHealthPlan.showHelpMessageIfInvalid();
            }
        }
    },
})