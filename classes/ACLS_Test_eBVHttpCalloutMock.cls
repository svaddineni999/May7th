@isTest
public with sharing class ACLS_Test_eBVHttpCalloutMock implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest request) {
        // Create a fake response
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');  
        
        if(request.getEndpoint().contains('/pharmacy/costcalculator/1')){
           	response.setBody(geteBVResponse());
            response.setStatusCode(200);
        }
        
        return response; 
    }    
    
    public String geteBVResponse(){
        ACLS_eBVPharmacy_IntegrationWrapper.DrugInfo dr = new ACLS_eBVPharmacy_IntegrationWrapper.DrugInfo('1234',Double.valueOf(2.50),Double.valueOf(2.50),30);
        
        ACLS_eBVPharmacy_IntegrationWrapper.PlanInfo pi = new ACLS_eBVPharmacy_IntegrationWrapper.PlanInfo();
        pi.PBMName = 'CAREMARK';
        pi.PlanName = 'CAREMARK';
        pi.BIN = '004336';
        pi.PCN = 'ADV';
        pi.MemberId = 'A159W818520';
        pi.PBMPhone = '800-522-8159';
        pi.PersonCode = '01';
        pi.StartDate = '2022-01-01';
        pi.EndDate = '2039-12-31';
        pi.IsCalendarYearPlan = true;
        pi.PAPhone = '888-836-0730';
        pi.PAFax = '888-836-0730';
        
        ACLS_eBVPharmacy_IntegrationWrapper.MedicarePlanInfo mi = new ACLS_eBVPharmacy_IntegrationWrapper.MedicarePlanInfo();
       	mi.IsLowIncomeSubsidyEnrolled = null;
        mi.Stage = null;
        mi.IsCoverageGap = null;
        mi.Amount = null;
        
        ACLS_eBVPharmacy_IntegrationWrapper.accumulatorAccrual aa = new ACLS_eBVPharmacy_IntegrationWrapper.accumulatorAccrual();
        aa.accumulatedDeductibleAmount = 'N/A';
        aa.amountAppliedToPeriodicDeductible = 'N/A';
        aa.annualCap = 'N/A';
        aa.coInsurancePercent = 'N/A';
        aa.deductibleMet = null;
        aa.isDeductibleAppliedToOOP = null;
        aa.OOPMax = 'N/A';
        aa.OOPMet = false;
        aa.OOPRemaining = 'N/A';
        aa.remainingDeductibleAmount = 'N/A';
        
        ACLS_eBVPharmacy_IntegrationWrapper.coveragePreferredResult cpr = new ACLS_eBVPharmacy_IntegrationWrapper.coveragePreferredResult();
        cpr.scenarioId = 'A';
        cpr.planOrder = 'Primary';
		cpr.planType = 'Primary';
        cpr.coverageStatus = 'Covered';
        cpr.claimStatus = 'Paid';
        cpr.rejectDesc = 'Test';
        cpr.hasMandatoryContractedSP = false;
        cpr.isProductOnFormulary = null;
        cpr.productFormularyTier = null;
        cpr.isPARequired = false;
        cpr.SPPName = new List<String>{'Test'};
        cpr.planInfo = pi;
        cpr.MedicarePlanInfo = mi;
        cpr.accumulatorAccrual = aa;
        
        ACLS_eBVPharmacy_IntegrationWrapper.eBV_ResponseWrapper td = new ACLS_eBVPharmacy_IntegrationWrapper.eBV_ResponseWrapper('COMPLETE', dr, new List<ACLS_eBVPharmacy_IntegrationWrapper.coveragePreferredResult>{cpr});
        td.transId = 'COMPLETE';
        td.coveragePreferredResult = new List<ACLS_eBVPharmacy_IntegrationWrapper.coveragePreferredResult>{cpr};
        td.drugInfo = dr;
        
        return json.serialize(td);
    }
}