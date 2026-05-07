/**
 * Created by havalakki on 3/1/2018.
 */
({

     //Function to populate the list of child documents if the document opened in the parent component is has children
     getChildDocList : function(component, event, helper){
        helper.setNamespace(component);

        helper.getInit(component, event, helper);
     },

     showAccordion : function(component, event, helper) {
            helper.showHideSection(component,event,'articleOne');
     }
})