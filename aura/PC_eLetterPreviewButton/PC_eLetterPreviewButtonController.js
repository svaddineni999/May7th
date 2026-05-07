/**
 * Created by havalakki on 4/8/2019.
 */
({
    doInit: function(component, event, helper){
        helper.setNamespace(component);
    },
    createPreviewComponent: function(component, event, helper){
        helper.geteLetterPreviewDetails(component, event, helper);
    }
})