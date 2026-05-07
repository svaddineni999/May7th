({
    init: function(cmp, event, helper) {
        helper.clearAttributes(cmp);
        console.log('FieldSetFormController.init');

         var device = $A.get("$Browser.formFactor");
         if(device != 'DESKTOP'){
             console.log('not desktop');
             cmp.set('v.noOfItemsInARow', 1);
         }else{
             console.log('desktop');
         }

        console.log(cmp.get("v.record"));
        cmp.set("v.configHtmlMap", helper.configHtmlMap);
        var action = cmp.get('c.getFields');
        action.setParams({
            fsName: cmp.get('v.fsName'),
            typeName: cmp.get('v.typeName')
        });
        action.setCallback(this,
            function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    console.log('FieldSetFormController getFields callback');
                    var fields = response.getReturnValue();
                    cmp.set('v.fields', fields);
                    helper.createLightningForm(cmp,event, helper);
                }
                else {
                    console.error('Unable to create fieldset component')
                }
            }
        );
        $A.enqueueAction(action);
    },
    validate: function(cmp, event, helper) {
     	helper.validate(cmp, event, helper);
    },

    handleValueChange: function(cmp, event, helper) {
        /*
        console.log('change');
        var inputToField = cmp.get('v.inputToField');
        var field = inputToField[event.getSource().getGlobalId()];
        var obj = cmp.get('v.record');
        if (!obj[field]) {
            // Have to make a copy of the object to set a new property - thanks LockerService!
            obj = JSON.parse(JSON.stringify(obj));
        }
        obj[field] = event.getSource().get('v.value');
        cmp.set('v.record', obj);*/
    },
    doneRendering: function(cmp, event, helper) {
        helper.setFocus(cmp, event, helper);
    }
})