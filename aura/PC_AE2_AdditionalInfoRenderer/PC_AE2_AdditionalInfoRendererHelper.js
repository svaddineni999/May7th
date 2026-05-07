({
	setNamespace : function(component, helper) {
        var component_to_string = component.toString();
        var markupTagLoc = component_to_string.indexOf('markup://');
        var endOfNamespaceLoc = component_to_string.indexOf(':',markupTagLoc+9);
        var ns = component_to_string.substring(markupTagLoc+9,endOfNamespaceLoc);
        var namespacePrefix = (ns == "c" || ns == "C") ?  "" :  ns + "__";
        component.set("v.namespace", ns);
        component.set("v.namespacePrefix", namespacePrefix);
    },

    setFieldSetNameAndType : function(component, helper) {
        component.set("v.fieldSetName", helper.getFieldSetName(component));
        component.set("v.typeName", component.get("v.namespacePrefix")+component.get("v.typeName"));
	},

    getFieldSetName : function(component) {
        var fName = component.get("v.additionalInfoTabFieldSet");
        if($A.util.isEmpty(fName)) {
            return null;
        }
        else {
            if(fName.indexOf("__") > -1) {
                return fName;
            }
            else {
                return component.get("v.namespacePrefix") + fName;
            }
        }
    },

    setFieldSetObject : function(cmp, event, helper) {
        if (cmp.get("v.fieldSetName") != null) {
            var action = cmp.get('c.getPopulatedFieldSet');
            action.setParams({
            	aeId: cmp.get("v.aeId"),
            	aeWrapper: cmp.get("v.aeWrapper"),
                typeName: cmp.get('v.typeName'),
                fsName: cmp.get('v.fieldSetName')
            });

            action.setCallback(this,
                               function(response) {
                                   console.log('FieldSetForm AE-Additional Information -  getFields callback start');
                                   var state = response.getState();
                                   if (state == "SUCCESS"){
                                       if (response.getReturnValue()==null){
                                           cmp.set("v.fieldSetFields", null);
                                           console.log('No fields found from fieldset');
                                       }
                                       else{
                                           var obj = {};
                                           var fields = response.getReturnValue().fieldPath;
                                           var aeWrap = response.getReturnValue().fieldValue;
                                           cmp.set("v.fieldSetFields", fields);
                                           if(fields != null && fields.length > 0){
                                               if($A.util.isEmpty(fields)) {
                                                   // do nothing
                                               }
                                               else{

                                                    var HpField = '';
                                                    for(var i=0; i<fields.length; i++) {
                                                        HpField = fields[i].fieldPath;
                                                        if(!$A.util.isEmpty(HpField) && $A.util.isEmpty(aeWrap[HpField])){
                                                           aeWrap[HpField] = '';
                                                        }
                                                    }
                                                    cmp.set("v.aeWrapper", aeWrap);
                                                }
                                                console.log('AE-Additional Information getFields callback end');
                                                helper.createFieldSetCmp(cmp, event, helper, fields);
                                           }
                                       }
                                   }
                                   else{
                                       var fieldsetError = cmp.get("v.fieldsetError");
                                       var adverseEventErrorHeader = cmp.get("v.adverseEventErrorHeader");
                                       var err = [fieldsetError];
                                       cmp.set('v.errors',err);
                                       cmp.set('v.errorHeaderVal',adverseEventErrorHeader);
                						//helper.handleErrors(cmp, response.getError());
            					   }

                               }
                              );
            $A.enqueueAction(action);
        }
    },

    createFieldSetCmp : function(cmp, event, helper, fields) {
        $A.createComponent(
            cmp.get("v.namespace") + ":PC_FieldSetForm",
            {
                "fsName": cmp.get("v.fieldSetName"),
                "typeName": cmp.get("v.typeName"),
                "record": cmp.getReference("v.aeWrapper"),
                "isValid" : cmp.getReference("v.isFieldSetFormValid")
            },
            function(newCmp, status, errorMessage){
                if (status === "SUCCESS") {
                    var body = cmp.get("v.fieldSetFormBody");
                    body.push(newCmp);
                    cmp.set("v.fieldSetFormBody", body);
                    var aeWrapper = cmp.get("v.aeWrapper");
                    cmp.set("v.aeWrapper", aeWrapper);
                }
                else if (status === "INCOMPLETE") {
                    console.log("No response from server or client is offline.")
                }
                else if (status === "ERROR") {
                        console.log("Error: " + errorMessage);
                }
            }
        );
    },
    validateFieldSetForm :function(component) {
        console.log(component.get("v.fieldSetFormBody"));
        component.set("v.isFieldSetFormValid",true);
        if (component.get("v.fieldSetFormBody") != null && component.get("v.fieldSetFormBody").length > 0) {
            console.log('In here');
            var fieldSetCmp = component.get("v.fieldSetFormBody")[0];
            fieldSetCmp.validate(); // this sets v.isFieldSetFormValid.
        }

        var isAdditionalInfoConfigValid=true;
        if(component.get("v.errors").length >0){
            isAdditionalInfoConfigValid=false;
        }
        return (component.get("v.isFieldSetFormValid") && isAdditionalInfoConfigValid);
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