({
	init: function(cmp, event, helper) {
        helper.setNamespace(cmp);
        var action = cmp.get('c.getFields');
        action.setParams({
            fsName: cmp.get('v.fsName'),
            typeName: cmp.get('v.typeName'),
            recordId: cmp.get('v.recordId')
        });
        action.setCallback(this,
            function(response) {
                var fields = response.getReturnValue();
                cmp.set('v.fieldset', fields);
            }
        );
        $A.enqueueAction(action);
    }
})