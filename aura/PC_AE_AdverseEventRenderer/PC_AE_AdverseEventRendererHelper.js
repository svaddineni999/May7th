/**
 * Created by shisbansal on 12/3/2018.
 */
({
    getAdverseEventData:function(component, event, helper){
        var action = component.get("c.getAdverseEventData");
        var aeId = component.get("v.aeId");
         if(aeId == undefined || $A.util.isEmpty(aeId) )
         {
            aeId ='';
         }
         action.setParams({
            aeId : aeId,
            adverseEventInfo : component.get("v.aeWrapper")

         });
         action.setCallback(this, function(response) {
              var state = response.getState();
               if (component.isValid() && state === "SUCCESS") {
                    var returnValue = response.getReturnValue();
                    component.set("v.fieldLabels" , returnValue.adverseEventLabels);
                        var outComeValues=[];
                        for(var i=0;i< returnValue.outcomeOptions.length;i++){
                            outComeValues.push({label: returnValue.outcomeOptions[i].label, value:returnValue.outcomeOptions[i].value});
                        }
                        component.set("v.outcomeOptions", outComeValues);
                        component.set("v.aeWrapper.outcome" , '');
                        var submissionStatusValues=[];

                        for(var j=0;j< returnValue.submissionStatusOptions.length;j++){
                        submissionStatusValues.push({label: returnValue.submissionStatusOptions[j].label, value:returnValue.submissionStatusOptions[j].value});
                        }
                        component.set("v.submissionStatusOptions", submissionStatusValues);
                        //component.set("v.aeWrapper.submissionStatus" , '');



                        if(aeId != '' && aeId != null){
                            var aeWrap =returnValue.adverseEventInfo;
                            component.set("v.aeWrapper" , aeWrap);

                            var testDeathValueCheck = aeWrap.outcome;

                            if(testDeathValueCheck != undefined){

                                if(testDeathValueCheck.includes('Death')){
                                    component.set("v.causeOfDeathDeactivate",false);
                                }
                            }
                        }
               }
               else {
                    console.log("Failed with state: " + state);
               }
         });

         $A.enqueueAction(action);
    },


    onOutcomeChange:function(component, event, helper){

        var deathLabel = '';
        var outcomeOptions = component.get("v.outcomeOptions");
        if( outcomeOptions != null && outcomeOptions != ''){
            for(var i=outcomeOptions.length -1;i> -1;i--){
                if(outcomeOptions[i].value == 'Death'){
                    deathLabel = outcomeOptions[i].label;
                    break;

                }
            }
        }
        var stringVal =event.getSource().get("v.value");

        if(deathLabel != ''){

            if(stringVal.indexOf(deathLabel) >-1){
                component.set('v.DeathdatefieldDeativate', false);
            }
            else{
                component.find('causeOfDeathVal').set("v.value",'');
                component.set('v.DeathdatefieldDeativate',true);
            }
        }
    }
})