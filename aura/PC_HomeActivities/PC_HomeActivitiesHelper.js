({
    
    toggleTask : function(component,event) {

        var  acc = component.find('Tasks');
        $A.util.addClass(acc, 'slds-active');

        acc = component.find('Alerts');
        $A.util.removeClass(acc, 'slds-active');

        acc = component.find('showTask');
        $A.util.removeClass(acc, 'slds-hide');
        $A.util.addClass(acc, 'slds-show');
        acc = component.find('showAlert');
        $A.util.removeClass(acc, 'slds-show');
        $A.util.addClass(acc, 'slds-hide');

    },

    toggleAlert : function(component,event) {

        var  acc = component.find('Alerts');
        $A.util.addClass(acc, 'slds-active');

        acc = component.find('Tasks');
        $A.util.removeClass(acc, 'slds-active');

        acc = component.find('showAlert');
        $A.util.removeClass(acc, 'slds-hide');
        $A.util.addClass(acc, 'slds-show');
        acc = component.find('showTask');
        $A.util.removeClass(acc, 'slds-show');
        $A.util.addClass(acc, 'slds-hide');
        
    },
})