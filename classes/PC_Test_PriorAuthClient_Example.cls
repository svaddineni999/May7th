/**
 * Created by vkashikar on 7/27/2022.
 */

@isTest
public with sharing class PC_Test_PriorAuthClient_Example {
    @isTest
    static void run() {
        PC_PriorAuthClient_Example example = new PC_PriorAuthClient_Example();
        PC_ePA.PARequest paRequest = example.submitPA();
        system.assert(paRequest != null);
        PC_ePA.FormsRequest formsRequest = example.createSearchFormsRequest();
        system.assert(formsRequest != null);
        PC_ePA.FormsResponse formsResponse = example.searchForms(formsRequest);
        system.assert(formsResponse.forms.size() > 0);
        PC_ePA.PAResponse paResponse = example.CreatePA(paRequest);
        system.debug(paResponse.is_ePA_created == true);
        Case paCase = new Case();
        example.updatePACase(paCase, paResponse);
        system.assert(paCAse.RecordTypeId != null);

    }
}