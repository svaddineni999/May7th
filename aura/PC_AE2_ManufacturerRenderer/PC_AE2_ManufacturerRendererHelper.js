/**
 * Created by shisbansal on 11/26/2018.
 */
({
        getManufacturerData : function(component){

            var action = component.get("c.getManufacturerData");
            var aeId = component.get("v.aeId");

            if(aeId == undefined || $A.util.isEmpty(aeId) )
            {
                aeId ='';
            }
            action.setParams({
                adverseEventId : aeId,
                caseId   : component.get("v.caseId")
             });

            action.setCallback(this, function(response) {
                var state = response.getState();
                if (component.isValid() && state === "SUCCESS") {

                    var returnValue = response.getReturnValue();
                    component.set("v.fieldLabels", returnValue.manufacturerLabels);

                    var typeOfReports=[];
                    for(var i=0;i< returnValue.reportType.length;i++){
                        typeOfReports.push({label: returnValue.reportType[i].label, value:returnValue.reportType[i].value});
                    }
                    component.set("v.typeOfReportsOption", typeOfReports);

                    var reportSourceOptions=[];
                    for(var j=0;j< returnValue.reportSource.length;j++){
                        reportSourceOptions.push({label: returnValue.reportSource[j].label, value:returnValue.reportSource[j].value});
                    }
                    component.set("v.reportSourceOptions",reportSourceOptions);
                    var combinationProductOptions=[];
                    for(var k=0;k< returnValue.combinationProduct.length;k++){
                        combinationProductOptions.push({label:returnValue.combinationProduct[k].label, value:returnValue.combinationProduct[k].value, selected:returnValue.combinationProduct[k].selected});
                    }
                    component.set("v.combinationProductOptions",combinationProductOptions);
                    var productOTCLabelOptions=[];
                    for(var l=0;l< returnValue.productOtc.length;l++){
                        productOTCLabelOptions.push({label:returnValue.productOtc[l].label, value:returnValue.productOtc[l].value, selected:returnValue.combinationProduct[l].selected});
                    }

                     component.set("v.productOtcOptions",productOTCLabelOptions);

                     var pre1938FlagOptions=[];
                         for(var m=0;m< returnValue.pre1938Flag.length;m++){
                             pre1938FlagOptions.push({label:returnValue.pre1938Flag[m].label, value:returnValue.pre1938Flag[m].value, selected:returnValue.pre1938Flag[m].selected});
                         }

                      component.set("v.pre1938FlagOptions",pre1938FlagOptions);

                } else {
                    console.log("Failed with state: " + state);
                }
            });
            $A.enqueueAction(action);
        },


        loadDataFromAE: function (component, event, helper){

            var action =  component.get("c.loadDataFromAE");
            var aeId = component.get('v.aeId');

            action.setParams({
                aeRecordId : aeId,
                manufacturerInfo  : component.get("v.aeWrapper")
            });
            action.setCallback(this, function(response){

                var state= response.getState();
                if (state == "SUCCESS"){
                    var aeWrap =response.getReturnValue();
                    component.set("v.aeWrapper" , aeWrap);
                    component.set("v.combinationProductOptions",aeWrap.combinationProductUse);
                    component.set("v.productOtcOptions" ,aeWrap.productOTC );
                    component.set("v.pre1938FlagOptions" ,aeWrap.pre1938Flag );


                    var testOtherValueCheck = aeWrap.reportSource;

                    if(testOtherValueCheck.includes('Other')){
                        component.set("v.reportSourceOtherTextDeactivate",false);
                    }

                    var testFollowUpCheck  =aeWrap.typeOfReports;

                    if(testFollowUpCheck.includes('Follow-up')){
                         component.set("v.reportTypeOtherTextDeactivate",false);

                    }



               }
                else{
                    console.log('error');
                }
            });
            $A.enqueueAction(action);
        },

        onReportSourceChange:function(component, event, helper){


            var otherLabel = '';
            var reportSourceOptions = component.get("v.reportSourceOptions");
            for(var i=reportSourceOptions.length -1;i> -1;i--){
                if(reportSourceOptions[i].value == 'Other'){
                    otherLabel = reportSourceOptions[i].label;
                    break;

                }
            }
            var stringVal =event.getSource().get("v.value");
            //alert('stringVal-->'+stringVal.option[0]);

            if(stringVal.indexOf(otherLabel) >-1){
                component.set('v.reportSourceOtherTextDeactivate', false);

            }
            else{

                component.find('reportSourceOtherValue').set("v.value",'');

                component.set('v.reportSourceOtherTextDeactivate',true);
            }
        },

        onReportTypeChange:function(component, event, helper){


            var otherLabel = '';
            var reportTypeOptions = component.get("v.typeOfReportsOption");
            for(var i=reportTypeOptions.length -1;i> -1;i--){
                if(reportTypeOptions[i].value == 'Follow-up'){
                    otherLabel = reportTypeOptions[i].label;
                    break;

                }
            }
            var stringVal =event.getSource().get("v.value");
            if(stringVal.indexOf(otherLabel) >-1){
                component.set('v.reportTypeOtherTextDeactivate', false);

            }
            else{

                component.find('reportTypeOtherValue').set("v.value",'');

                component.set('v.reportTypeOtherTextDeactivate',true);
            }
        },

        loadDataFromManufacturer: function (component, event, helper){
            var action =  component.get("c.fetchDataFromManufacturer");
            action.setParams({
                caseId: component.get("v.caseId"),
                manufacturerInfo: component.get("v.aeWrapper")
            });
            action.setCallback(this, function(response){
                var state= response.getState();
                if (state == "SUCCESS"){
                    var aeWrap =response.getReturnValue();
                    component.set("v.aeWrapper" , aeWrap);
                    console.log('successfully loaded');
                }
                else{
                    console.log (response.getError());
                }
            });

            $A.enqueueAction(action);
        },


})