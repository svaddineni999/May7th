/**
 * Created by vkashikar on 8/1/2018.
 */
({
    initialize : function(component, event, helper) {
        debugger;
        component.set("v.body",[]);
        component.set("v.isLoading", true);
        var action = component.get("c.getInitData");
        var recordId = component.get("v.recordId");
        action.setParams({
            recordId : recordId,
        });
        action.setCallback(this, function(a) {
            var state = a.getState();
            if (state === "SUCCESS") {
                if(component.isValid()) {
                    var returnValue = a.getReturnValue();
                    console.log('iic -- ');
                    console.log(returnValue);
                    component.set("v.initData", returnValue);
                    component.set("v.isLoading", false);
                    helper.createIntelligentIndicators(component, event, helper);
                }
                else {
                    component.set("v.errors", "Component Is Invalid");
                }
            } else if (state ==="ERROR") {
                var errors = a.getError();
                console.log(JSON.stringify(errors));
                component.set("v.errors", helper.getErrorsAsArray(errors, helper));
            }
            else {
                component.set("v.errors", "Unknown State " + state);
            }
            component.set("v.isLoading", false);
        });
        $A.enqueueAction(action);
    },

    createIntelligentIndicators : function(component, event, helper) {
        component.set("v.body",[]);
        var initData = component.get("v.initData");
        if(!$A.util.isEmpty(initData) && !$A.util.isEmpty(initData.intelligentIndicators)) {
            var mdtList = initData.intelligentIndicators;
            mdtList.sort(function (a, b) {
              return a.order - b.order;
            });
            var mdt;
            var recordId = component.get("v.recordId");
            var allAttributesObj = {"title":"","content":"","recordId":recordId,"attributes":"","auraId":"","aura:id":"","contentComponent":"","contentComponentAttributes":""};
            var componentName;

            var body = component.get("v.body");
            var errors;
            for(var i=0; i<mdtList.length; i++) {
                mdt = mdtList[i];
                componentName = mdt.componentAPIName;
                var title = CH_PC_Util.getCustomLabelValue(mdt["title"]);
                var content = CH_PC_Util.getCustomLabelValue(mdt["content"]);

                allAttributesObj.title = title;
                allAttributesObj.content = content;
                allAttributesObj.attributes = mdt["attributes"];
                allAttributesObj.auraId = Date.now();
                allAttributesObj["aura:id"] = allAttributesObj.auraId;
                allAttributesObj.contentComponent = mdt["contentComponent"];
                allAttributesObj.contentComponentAttributes = mdt["contentComponentAttributes"];
                console.log("Ready to create component with name --" + componentName);
                try {
                    $A.createComponent(
                        componentName,
                        allAttributesObj,
                        function(newComponent, status, errorMessage) {
                            if(status == "SUCCESS") {
                                body.push(newComponent);
                                component.set("v.body", body);
                                console.log("iic - successfully created component with name " + componentName);
                            }
                            else {
                                console.error("iic - failed to create component with name " + componentName);
                                errors.push("Error while creating component with name " + componentName);
                                component.set("v.errors", errors);
                            }
                        }
                    );
                }
                catch(err) {
                    errors.push("Error while creating component with name " + componentName + '. Error -> ' + err);
                    component.set("v.errors", errors);
                }
            }
        }
    },
    clearErrorMessages : function(component) {
        var errors;
        component.set("v.errors", errors);
    },
    getErrorsAsArray : function(errors, helper) {
        var errorArr = [];
        if(!$A.util.isEmpty(errors)) {

            for(var i=0; i<errors.length; i++) {
                var errorObj = errors[i];
                helper.setErrorArr(errorObj, errorArr);
                for (var property in errorObj) {
                    if (errorObj.hasOwnProperty(property) && !$A.util.isEmpty(errorObj[property])) {
                       for(var j=0; j<errorObj[property].length; j++) {
                          helper.setErrorArr(errorObj[property][j], errorArr);
                       }
                    }
                }
            }
        }
        return errorArr;
    },
    setErrorArr : function(errorObj, ret_errorArr) {
        if(!$A.util.isEmpty(errorObj.message)) {
            var msg = '';
            if(!$A.util.isEmpty(errorObj.statusCode)) {
                msg = errorObj.statusCode + ' : ';
            }
            msg = msg + errorObj.message;
            ret_errorArr.push(msg);
        }
    },
})