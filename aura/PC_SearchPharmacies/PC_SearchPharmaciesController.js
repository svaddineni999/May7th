/**
 * Created by shisbansal on 7/5/2018.
 */
({

    doInit : function(component, event, helper) {
        component.set("v.display_npi_param_section","retailMailButtonSection");
        component.set("v.display_checkbox_section", "");
        component.set("v.display_zipCode_section", "true");
        component.set("v.selected", false);
        helper.setNamespace(component);
    },

    addPharmacies : function(component, event, helper) {
        console.log("adding values...");
        helper.addPharmacies(component, event, helper);
    },

    handleNPIClick: function(component,event,helper){
        component.set("v.display_npi_param_section","npiSection");
        component.set("v.display_zipCode_section", "false");
        component.set("v.display_checkbox_section","false");
        component.set("v.selected",true);
        component.find('ZipCode').set("v.value","");
    },

    handleParamsClick:function (component , event , helper){
     component.set("v.display_npi_param_section","retailMailButtonSection");
     component.set("v.display_zipCode_section", "true");
     component.set("v.display_checkbox_section", "false");
     component.set("v.selected",false);
     component.set("v.selectParam","NA");
    },



    handleRetailClick: function(component , event , helper){

     component.set("v.display_zipCode_section","true");

     var  buttonLabelActive  =  component.get("v.selectParam");
     var toggleVariant = (buttonLabelActive =='Retail')? 'NA' : 'Retail';
     component.set("v.selectParam" ,toggleVariant );
     var MailParam = component.get("v.selectParamMailOrder");

      if(toggleVariant != 'Retail' && MailParam == 'Mail' ){
         component.find("ZipCode").set("v.value","");
         component.set("v.display_zipCode_section","false");
     }

     else if (toggleVariant == 'Retail'){
         component.set("v.selectParamMailOrder","NA");
     }


    },

    handleMailOrderClick: function(component , event , helper){


        var  buttonLabelActive  =  component.get("v.selectParamMailOrder");
        var toggleVariant = (buttonLabelActive =='Mail')? 'NA' : 'Mail';
         component.set("v.selectParamMailOrder" ,toggleVariant );
         if(toggleVariant == 'Mail'){
             component.set("v.display_zipCode_section","false");
             component.find("ZipCode").set("v.value","");
             component.set("v.selectParam", "NA");

         }

         else if (toggleVariant  != 'Mail'){
             component.find("ZipCode").set("v.value","");
             component.set("v.display_zipCode_section","true");
         }


    },

    /*handleNAClick: function(component , event , helper){
        component.set("v.display_checkbox_section","false");
        component.set("v.display_zipCode_section","true");
         component.set("v.selectParam","NA");

    },*/

        handleSearch: function(component , event , helper){
            helper.handleSearch(component,event,helper);
        },


})