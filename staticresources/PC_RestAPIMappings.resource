{
  "Case": {
    "propertyMappings": {
      "programId": {
        "sObjectFieldName": "PC_Program__c"
      },
      "patientId": {
        "sObjectFieldName": "AccountId"
      },
      "id": {
        "sObjectFieldName": "Id"
      },
      "enrollmentDate": {
        "sObjectFieldName": "PC_Enrollment_Date__c"
      },
      "engagementProgramId": {
        "sObjectFieldName": "PC_Engagement_Program__c"
      },
      "caseProduct": {
        "sObjectFieldName": "PC_Program_Product__r.PC_Product__r.Name"
      },
      "engagementProgramName": {
        "sObjectFieldName": "PC_Engagement_Program__r.Name"
      }
    }
  },
  "Association": {
    "propertyMappings": {
      "userId": {
        "sObjectFieldName": "PC_Associated_User__c"
      },
      "role": {
        "sObjectFieldName": "PC_Role__c"
      },
      "programId": {
        "sObjectFieldName": "PC_Program__c"
      },
      "id": {
        "sObjectFieldName": "Id"
      },
      "endDate": {
        "sObjectFieldName": "PC_EndDate__c"
      },
      "associationStatus": {
        "sObjectFieldName": "PC_AssociationStatus__c"
      },
      "accountId": {
        "sObjectFieldName": "PC_Account__c"
      }
    }
  },
  "Payer": {
    "propertyMappings": {
      "subType": {
        "sObjectFieldName": "PC_Sub_Type__c"
      },
      "status": {
        "sObjectFieldName": "PC_Status__c"
      },
      "phone": {
        "sObjectFieldName": "Phone"
      },
      "name": {
        "sObjectFieldName": "Name"
      },
      "type": {
        "sObjectFieldName": "Type"
      },
      "id": {
        "sObjectFieldName": "Id"
      }
    }
  },
  "EngagementProgram": {
    "propertyMappings": {
      "programCode": {
        "sObjectFieldName": "PC_Program_Code__c"
      },
      "name": {
        "sObjectFieldName": "Name"
      },
      "manufacturerId": {
        "sObjectFieldName": "PC_Manufacturer__c"
      },
      "id": {
        "sObjectFieldName": "Id"
      },
      "programCaseRecordType": {
        "sObjectFieldName": "PC_ProgramCaseRecordType__c"
      },
      "programCaseRecordTypeNamespace": {
        "sObjectFieldName": "PC_ProgramCaseRecordTypeNamespace__c"
      }
    }
  },
  "Interaction": {
    "propertyMappings": {
      "name": {
        "sObjectFieldName": "Name"
      },
      "id": {
        "sObjectFieldName": "Id"
      },
      "patientProgram": {
        "sObjectFieldName": "PC_Patient_Program__c"
      },
      "status": {
        "sObjectFieldName": "PC_Status__c"
      },
      "type": {
        "sObjectFieldName": "PC_Type__c"
      },
      "start": {
        "sObjectFieldName": "PC_Start__c"
      },
      "end": {
        "sObjectFieldName": "PC_End__c"
      },
      "participant": {
        "sObjectFieldName": "PC_Participant__c"
      },
      "patient": {
        "sObjectFieldName": "PC_Patient__c"
      },
      "notes": {
        "sObjectFieldName": "PC_Notes__c"
      },
      "durationHrs": {
        "sObjectFieldName": "PC_Duration_Hrs__c"
      }
    }
  },
  "SelfServiceSetting": {
    "propertyMappings": {
      "id": {
        "sObjectFieldName": "Id"
      },
      "active": {
        "sObjectFieldName": "PC_Active__c"
      },
      "serviceFlowIdentifier": {
        "sObjectFieldName": "PC_ServiceFlowIdentifier__c"
      },
      "vendorName": {
        "sObjectFieldName": "PC_VendorName__c"
      },
      "engagementProgram": {
        "sObjectFieldName": "PC_EngagementProgram__c"
      },
      "order": {
        "sObjectFieldName": "PC_Order__c"
      },
      "serviceName": {
        "sObjectFieldName": "PC_ServiceName__c"
      },
      "downstreamFlowIdentifier": {
        "sObjectFieldName": "PC_DownstreamFlowIdentifier__c"
      },
      "channel": {
        "sObjectFieldName": "PC_Channel__c"
      },
      "otherChannel": {
        "sObjectFieldName": "PC_OtherChannel__c"
      }
    }
  },
  "Manufacturer": {
    "propertyMappings": {
      "phone": {
        "sObjectFieldName": "Phone"
      },
      "name": {
        "sObjectFieldName": "Name"
      },
      "id": {
        "sObjectFieldName": "Id"
      },
      "description": {
        "sObjectFieldName": "Description"
      }
    }
  },
  "HealthPlan": {
    "propertyMappings": {
      "rxPCN": {
        "sObjectFieldName": "PC_Rx_PCN__c"
      },
      "rxGrp": {
        "sObjectFieldName": "PC_Rx_Grp__c"
      },
      "rxBin": {
        "sObjectFieldName": "PC_Rx_Bin__c"
      },
      "renewalDate": {
        "sObjectFieldName": "PC_Renewal_Date__c"
      },
      "planType": {
        "sObjectFieldName": "PC_Plan_Type__c"
      },
      "planStatus": {
        "sObjectFieldName": "PC_Plan_Status__c"
      },
      "planClaimCardNo": {
        "sObjectFieldName": "PC_Plan_Claim_Card_No__c"
      },
      "payerId": {
        "sObjectFieldName": "PC_Payer__c"
      },
      "patientId": {
        "sObjectFieldName": "Patient__c"
      },
      "idPolicyNo": {
        "sObjectFieldName": "ID_Policy_No__c"
      },
      "id": {
        "sObjectFieldName": "Id"
      },
      "groupNo": {
        "sObjectFieldName": "Group_No__c"
      },

      "effectiveDate": {
        "sObjectFieldName": "PC_Effective_Date__c"
      },
      "cardholderRelationToPatient": {
        "sObjectFieldName": "PC_Cardholder_Relationship_to_Patient__c"
      },
      "cardHolderRelationshipToPatient": {
        "sObjectFieldName": "PC_Cardholder_Relationship_to_Patient__c"
      },
      "cardholderName": {
        "sObjectFieldName": "PC_Card_Holder_Name__c"
      },
      "cardholderEmployer": {
        "sObjectFieldName": "PC_Cardholder_Employer__c"
      },
      "cardholderDateOfBirth": {
        "sObjectFieldName": "PC_Cardholder_s_Date_of_Birth__c"
      },
      "expirationDate": {
        "sObjectFieldName": "PC_Expiration_Date__c"
      }
    }
  },
  "ProgramCoverage": {
    "propertyMappings": {
      "alternateFunding": {
        "sObjectFieldName": "PC_Alternate_Funding__c"
      },
      "annualOutOfPocket": {
        "sObjectFieldName": "PC_Annual_Out_of_Pocket__c"
      },
      "appealAvailable": {
        "sObjectFieldName": "PC_Appeal_Available__c"
      },
      "coinsurancePercent": {
        "sObjectFieldName": "PC_Coinsurance_Percent__c"
      },
      "comments": {
        "sObjectFieldName": "PC_Comments__c"
      },
      "copayAmount": {
        "sObjectFieldName": "PC_Copay_Amount__c"
      },
      "copayAssistanceAmount": {
        "sObjectFieldName": "PC_Copay_Assistance_Amount__c"
      },
      "copayCardExpirationDate": {
        "sObjectFieldName": "PC_Copay_Card_Expiration_Date__c"
      },
      "copayCardGroupNumber": {
        "sObjectFieldName": "PC_Copay_Card_Group_No__c"
      },
      "copayCardNumber": {
        "sObjectFieldName": "PC_Copay_Card_No__c"
      },
      "copayCardRxBinNumber": {
        "sObjectFieldName": "PC_Copay_Card_Rx_BIN_No__c"
      },
      "copayCardStatus": {
        "sObjectFieldName": "PC_Copay_Card_Status__c"
      },
      "coveragePercent": {
        "sObjectFieldName": "PC_Coverage_Percentage__c"
      },
      "coverageStatus": {
        "sObjectFieldName": "PC_Coverage_Status__c"
      },
      "coverageType": {
        "sObjectFieldName": "PC_Coverage_Type__c"
      },
      "deductible": {
        "sObjectFieldName": "PC_Deductible__c"
      },
      "isEligible": {
        "sObjectFieldName": "PC_Eligible__c"
      },
      "expirationDate": {
        "sObjectFieldName": "PC_Expiration_Date__c"
      },
      "healthPlan": {
        "sObjectFieldName": "PC_Health_Plan__c"
      },
      "meetsQualification": {
        "sObjectFieldName": "PC_Meets_qualifications__c"
      },
      "programId":{
        "sObjectFieldName": "PC_Program__c"
      },
      "id":{
        "sObjectFieldName": "Id"
      }
    }
  },

  "AdverseEvent": {
    "propertyMappings": {
      "patientId": {
        "sObjectFieldName": "PC_Patient__c"
      },
      "caseId": {
        "sObjectFieldName": "PC_Care_Program__c"
      },
      "gender": {
        "sObjectFieldName": "PC_Gender__c"
      },
      "ethnicity": {
        "sObjectFieldName": "PC_Ethnicity__c"
      },
      "dateOfBirth": {
        "sObjectFieldName": "PC_Date_of_Birth__c"
      },
      "age": {
        "sObjectFieldName": "PC_Age__c"
      },
      "weight": {
        "sObjectFieldName": "PC_Weight__c"
      },
      "weightUnit": {
        "sObjectFieldName": "PC_Weight_Unit__c"
      },

      "race": {
        "sObjectFieldName": "PC_Race__c"
      },
      "ageUnit": {
        "sObjectFieldName": "PC_Age_Unit__c"
      },

      "dateOfTheReport": {
        "sObjectFieldName": "PC_Date_of_the_Report__c"
      },
      "eventOnsetDate": {
        "sObjectFieldName": "PC_Event_Onset_Date__c"
      },
      "endDate": {
        "sObjectFieldName": "PC_Stop_Date__c"
      },
      "description": {
        "sObjectFieldName": "PC_Description__c"
      },
      "laboratoryData": {
        "sObjectFieldName": "PC_Laboratory_Data__c"
      },
      "otherReleventHistory": {
        "sObjectFieldName": "PC_Other_Relevent_History__c"
      },
      "eventVerbatim": {
        "sObjectFieldName": "PC_Event_Verbatim__c"
      },
      "outcome": {
        "sObjectFieldName": "PC_Event_Outcome__c"
      },
      "dateofDeath": {
        "sObjectFieldName": "PC_Death_Date__c"
      },
      "systemOrganClassCode": {
        "sObjectFieldName": "PC_Event_SOC_Code__c"
      },
      "highLevelGroupTermCode": {
        "sObjectFieldName": "PC_Event_HLGT_Code__c"
      },
      "highLevelTermCode":{
        "sObjectFieldName": "PC_Event_HLT_Code__c"
      },
      "preferredTermCode":{
        "sObjectFieldName": "PC_Event_PT_Code__c"
      },
      "lowLevelTermCode":{
          "sObjectFieldName": "PC_Event_LLT_Code__c"
      },
      "reporterFirstName":{
        "sObjectFieldName": "PC_Reporter_First_Name__c"
      },
      "reporterLastName":{
        "sObjectFieldName": "PC_Reporter_Last_Name__c"
      },
      "reporterAddress":{
        "sObjectFieldName": "PC_ReporterAddress__c"
       },
      "reporterCity":{
        "sObjectFieldName": "PC_Reporter_City__c"
      },
      "reporterState":{
        "sObjectFieldName": "PC_Reporter_State__c"
      },
      "reporterCountry":{
        "sObjectFieldName": "PC_Reporter_Country__c"
      },
      "reporterZip":{
        "sObjectFieldName": "PC_Reporter_Zip_Code__c"
      },
      "reporterEmail":{
        "sObjectFieldName": "PC_Reporter_Email__c"
      },
      "reporterPhone":{
        "sObjectFieldName": "PC_Reporter_Phone__c"
      },
      "reporterType":{
        "sObjectFieldName": "PC_Adverse_Event_Reporter__c"
      },
      "initialReporterSentReportToFda":{
        "sObjectFieldName": "PC_Ini_Reporter_Also_Sent_Report_to_FDA__c"
      },
      "healthCareProfessional":{
        "sObjectFieldName": "PC_HealthCareProfessional__c"
      },
      "manufacturerName":{
        "sObjectFieldName": "PC_Manufacturer_Name__c"
      },
      "manufacturerAddress":{
        "sObjectFieldName": "PC_Manufacturer_Address__c"
      },
      "manufacturerEmail":{
        "sObjectFieldName": "PC_Manufacturer_Email__c"
      },
      "manufacturerCompOutsourcingFac":{
        "sObjectFieldName": "PC_Manufacturer_Comp_Outsourcing_Fac__c"
      },
      "manufacturerPhone":{
        "sObjectFieldName": "PC_Manufacturer_Phone__c"
      },
      "dateReceivedByManufacturer":{
        "sObjectFieldName": "PC_AE_Received_by_Manufacturer_Date__c"
      },
      "newDrugApplication":{
        "sObjectFieldName": "PC_NDA__c"
      },
      "abbreviatedNewDrugApplicationNumber":{
        "sObjectFieldName": "PC_ANDA__c"
      },
      "investigationalNewDrugApplicationNumber":{
        "sObjectFieldName": "PC_IND__c"
      },
      "biologicsApplicationNumber":{
        "sObjectFieldName": "PC_BLA__c"
      },
      "premarketApplication510kNumber":{
        "sObjectFieldName": "PC_PMA_510k__c"
      },
      "pre1938Flag":{
        "sObjectFieldName": "PC_Pre_1938_Flag__c"
      },
      "overTheCounterProduct":{
        "sObjectFieldName": "PC_Product_OTC__c"
      },
      "manufacturerReportNumber":{
        "sObjectFieldName": "PC_Manufacturer_Report_Number__c"
      },
      "ifIndProtocolNumber":{
        "sObjectFieldName": "PC_If_IND_Give_Protocol__c"
      },
      "adverseEventTerms":{
        "sObjectFieldName": "PC_Adverse_Event_Terms__c"
      },
      "reportSourceOtherText":{
        "sObjectFieldName": "PC_Report_Source_Other_Text__c"
      },
      "reportTypeOtherText":{
        "sObjectFieldName": "PC_Report_Type_Other_Text__c"
      },
      "reportSource":{
        "sObjectFieldName": "PC_Report_Source__c"
      },
      "reportTypes":{
        "sObjectFieldName": "PC_Report_Type__c"
      },
      "expirationDate":{
        "sObjectFieldName": "PC_Expiration_Date__c"
      },
      "combinationProductUse":{
        "sObjectFieldName": "PC_Combination_Product_Report__c"
      },
      "id":{
        "sObjectFieldName": "Id"
      }
    }
  },
  "AdverseEvent2": {
    "propertyMappings": {
      "patientId": {
        "sObjectFieldName": "PC_Patient__c"
      },
      "caseId": {
        "sObjectFieldName": "PC_Care_Program__c"
      },
      "gender": {
        "sObjectFieldName": "PC_Gender__c"
      },
      "ethnicity": {
        "sObjectFieldName": "PC_Ethnicity__c"
      },
      "dateOfBirth": {
        "sObjectFieldName": "PC_Date_of_Birth__c"
      },
      "age": {
        "sObjectFieldName": "PC_Age__c"
      },
      "weight": {
        "sObjectFieldName": "PC_Weight__c"
      },
      "weightUnit": {
        "sObjectFieldName": "PC_Weight_Unit__c"
      },

      "race": {
        "sObjectFieldName": "PC_Race__c"
      },
      "ageUnit": {
        "sObjectFieldName": "PC_Age_Unit__c"
      },

      "dateOfTheReport": {
        "sObjectFieldName": "PC_Date_of_the_Report__c"
      },
      "eventOnsetDate": {
        "sObjectFieldName": "PC_Event_Onset_Date__c"
      },
      "endDate": {
        "sObjectFieldName": "PC_Stop_Date__c"
      },
      "description": {
        "sObjectFieldName": "PC_Description__c"
      },
      "laboratoryData": {
        "sObjectFieldName": "PC_Laboratory_Data__c"
      },
      "otherReleventHistory": {
        "sObjectFieldName": "PC_Other_Relevent_History__c"
      },
      "eventVerbatim": {
        "sObjectFieldName": "PC_Event_Verbatim__c"
      },
      "outcome": {
        "sObjectFieldName": "PC_Event_Outcome__c"
      },
      "dateofDeath": {
        "sObjectFieldName": "PC_Death_Date__c"
      },
      "systemOrganClassCode": {
        "sObjectFieldName": "PC_Event_SOC_Code__c"
      },
      "highLevelGroupTermCode": {
        "sObjectFieldName": "PC_Event_HLGT_Code__c"
      },
      "highLevelTermCode":{
        "sObjectFieldName": "PC_Event_HLT_Code__c"
      },
      "preferredTermCode":{
        "sObjectFieldName": "PC_Event_PT_Code__c"
      },
      "lowLevelTermCode":{
        "sObjectFieldName": "PC_Event_LLT_Code__c"
      },
      "reporterFirstName":{
        "sObjectFieldName": "PC_Reporter_First_Name__c"
      },
      "reporterLastName":{
        "sObjectFieldName": "PC_Reporter_Last_Name__c"
      },
      "reporterAddress":{
        "sObjectFieldName": "PC_ReporterAddress__c"
      },
      "reporterCity":{
        "sObjectFieldName": "PC_Reporter_City__c"
      },
      "reporterState":{
        "sObjectFieldName": "PC_Reporter_State__c"
      },
      "reporterCountry":{
        "sObjectFieldName": "PC_Reporter_Country__c"
      },
      "reporterZip":{
        "sObjectFieldName": "PC_Reporter_Zip_Code__c"
      },
      "reporterEmail":{
        "sObjectFieldName": "PC_Reporter_Email__c"
      },
      "reporterPhone":{
        "sObjectFieldName": "PC_Reporter_Phone__c"
      },
      "reporterType":{
        "sObjectFieldName": "PC_Adverse_Event_Reporter__c"
      },
      "initialReporterSentReportToFda":{
        "sObjectFieldName": "PC_Ini_Reporter_Also_Sent_Report_to_FDA__c"
      },
      "healthCareProfessional":{
        "sObjectFieldName": "PC_HealthCareProfessional__c"
      },
      "manufacturerName":{
        "sObjectFieldName": "PC_Manufacturer_Name__c"
      },
      "manufacturerAddress":{
        "sObjectFieldName": "PC_Manufacturer_Address__c"
      },
      "manufacturerEmail":{
        "sObjectFieldName": "PC_Manufacturer_Email__c"
      },
      "manufacturerCompOutsourcingFac":{
        "sObjectFieldName": "PC_Manufacturer_Comp_Outsourcing_Fac__c"
      },
      "manufacturerPhone":{
        "sObjectFieldName": "PC_Manufacturer_Phone__c"
      },
      "dateReceivedByManufacturer":{
        "sObjectFieldName": "PC_AE_Received_by_Manufacturer_Date__c"
      },
      "newDrugApplication":{
        "sObjectFieldName": "PC_NDA__c"
      },
      "abbreviatedNewDrugApplicationNumber":{
        "sObjectFieldName": "PC_ANDA__c"
      },
      "investigationalNewDrugApplicationNumber":{
        "sObjectFieldName": "PC_IND__c"
      },
      "biologicsApplicationNumber":{
        "sObjectFieldName": "PC_BLA__c"
      },
      "premarketApplication510kNumber":{
        "sObjectFieldName": "PC_PMA_510k__c"
      },
      "pre1938Flag":{
        "sObjectFieldName": "PC_Pre_1938_Flag__c"
      },
      "overTheCounterProduct":{
        "sObjectFieldName": "PC_Product_OTC__c"
      },
      "manufacturerReportNumber":{
        "sObjectFieldName": "PC_Manufacturer_Report_Number__c"
      },
      "ifIndProtocolNumber":{
        "sObjectFieldName": "PC_If_IND_Give_Protocol__c"
      },
      "adverseEventTerms":{
        "sObjectFieldName": "PC_Adverse_Event_Terms__c"
      },
      "reportSourceOtherText":{
        "sObjectFieldName": "PC_Report_Source_Other_Text__c"
      },
      "reportTypeOtherText":{
        "sObjectFieldName": "PC_Report_Type_Other_Text__c"
      },
      "reportSource":{
        "sObjectFieldName": "PC_Report_Source__c"
      },
      "reportTypes":{
        "sObjectFieldName": "PC_Report_Type__c"
      },
      "expirationDate":{
        "sObjectFieldName": "PC_Expiration_Date__c"
      },
      "combinationProductUse":{
        "sObjectFieldName": "PC_Combination_Product_Report__c"
      },
      "id":{
        "sObjectFieldName": "Id"
      }
    }
  },

  "SuspectPrescription": {
    "propertyMappings": {
      "eventAbated":{
        "sObjectFieldName": "PC_Abated_After_Use_Stopped_or_Reduced__c"
      },
      "combinationProductUse":{
        "sObjectFieldName": "PC_Combination_Product_Report__c"
      },
      "concomitant":{
        "sObjectFieldName": "PC_Concomitant_Medical_Products__c"
      },
      "indicationForProductUse":{
        "sObjectFieldName": "PC_Indication_for_Product_Use__c"
      },
      "dose":{
        "sObjectFieldName": "PC_Dose__c"
      },
      "eventReappeared":{
        "sObjectFieldName": "PC_Event_Reappeared_After_Reintroduction__c"
      },
      "expirationDate": {
        "sObjectFieldName": "PC_Expiration_Date__c"
      },
      "frequency":{
        "sObjectFieldName": "PC_Frequency__c"
      },
      "productCompounded":{
        "sObjectFieldName": "PC_Product_Compounded__c"
      },
      "isProductOverTheCounter":{
        "sObjectFieldName": "PC_Product_OTC__c"
      },
      "lotNumber":{
        "sObjectFieldName": "PC_Product_Lot__c"
      },
      "manufacturer":{
        "sObjectFieldName": "PC_Product_Manufacturer__c"
      },
      "ndc":{
        "sObjectFieldName": "PC_Drug_NDC__c"
      },
      "prescription":{
        "sObjectFieldName": "PC_Prescription__c"
      },
      "product":{
        "sObjectFieldName": "PC_Product_Name__c"
      },
      "productStrength":{
        "sObjectFieldName": "PC_Product_Strength__c"
      },
      "route":{
        "sObjectFieldName": "PC_Route_of_Administration__c"
      },
      "therapyEndDate":{
        "sObjectFieldName": "PC_Therapy_End_Date__c"
      },
      "therapyStartDate":{
        "sObjectFieldName": "PC_Therapy_Start_Date__c"
      },
      "adverseEventId":{
        "sObjectFieldName": "PC_Adverse_Event__c"
      },
      "adverseEventId2":{
        "sObjectFieldName": "PC_Adverse_Event2__c"
      },
      "id":{
        "sObjectFieldName": "Id"
      }

    }
  },
  "Address": {
    "propertyMappings": {
      "zipCode": {
        "sObjectFieldName": "PC_Zip_Code__c"
      },
      "status": {
        "sObjectFieldName": "PC_Status__c"
      },
      "state": {
        "sObjectFieldName": "PC_State__c"
      },
      "startDate": {
        "sObjectFieldName": "PC_Start_Date__c"
      },
      "providerId": {
        "sObjectFieldName": "PC_Account__c"
      },
      "primaryAddress": {
        "sObjectFieldName": "PC_Primary_Address__c"
      },
      "patientId": {
        "sObjectFieldName": "PC_Account__c"
      },
      "id": {
        "sObjectFieldName": "Id"
      },
      "endDate": {
        "sObjectFieldName": "PC_End_Date__c"
      },
      "country": {
        "sObjectFieldName": "PC_Country__c"
      },
      "city": {
        "sObjectFieldName": "PC_City__c"
      },
      "addressType": {
        "sObjectFieldName": "PC_Address_Description__c"
      },
      "address3": {
        "sObjectFieldName": "PC_Address_3__c"
      },
      "address2": {
        "sObjectFieldName": "PC_Address_2__c"
      },
      "address1": {
        "sObjectFieldName": "PC_Address_1__c"
      },
      "accountId": {
        "sObjectFieldName": "PC_Account__c"
      }
    }
  },
  "Physician": {
    "propertyMappings": {
      "type": {
        "sObjectFieldName": "Type"
      },
      "specialistType": {
        "sObjectFieldName": "PC_Specialist_Type__c"
      },
      "preferredCommunicationChannel": {
        "sObjectFieldName": "PC_Preferred__c"
      },
      "phone": {
        "sObjectFieldName": "Phone"
      },
      "npi": {
        "sObjectFieldName": "PC_NPI__c"
      },
      "name": {
        "sObjectFieldName": "Name"
      },
      "lastName": {
        "sObjectFieldName": "PC_Last_Name__c"
      },
      "id": {
        "sObjectFieldName": "Id"
      },
      "firstName": {
        "sObjectFieldName": "PC_First_Name__c"
      },
      "fax": {
        "sObjectFieldName": "Fax"
      },
      "email": {
        "sObjectFieldName": "PC_Email__c"
      },
      "communicationLanguage": {
        "sObjectFieldName": "PC_Communication_Language__c"
      }
    }
  },
  "Applicant/HCO": {
    "propertyMappings": {
      "zipcode": {
        "sObjectFieldName": "PC_HCO?_Zipcode__c"
      },
      "type": {
        "sObjectFieldName": "PC_HCO?_Type__c"
      },
      "streetAddress": {
        "sObjectFieldName": "PC_HCO?_Street_Address?__c"
      },
      "state": {
        "sObjectFieldName": "PC_HCO?_State__c"
      },
      "phone": {
        "sObjectFieldName": "PC_HCO?_Phone__c"
      },
      "name": {
        "sObjectFieldName": "PC_HCO?_Name__c"
      },
      "fax": {
        "sObjectFieldName": "PC_HCO?_Fax__c"
      },
      "city": {
        "sObjectFieldName": "PC_HCO?_City__c"
      }
    }
  },
  "Applicant/HealthPlan": {
    "propertyMappings": {
      "rxPCN": {
        "sObjectFieldName": "PC_HP?_Rx_PCN__c"
      },
      "rxGrp": {
        "sObjectFieldName": "PC_HP?_Rx_Grp__c"
      },
      "rxBin": {
        "sObjectFieldName": "PC_HP?_Rx_Bin__c"
      },
      "recordType": {
        "sObjectFieldName": "PC_HP?_Record_Type__c"
      },
      "planType": {
        "sObjectFieldName": "PC_HP?_Plan_Type__c"
      },
      "planStatus": {
        "sObjectFieldName": "PC_HP?_Plan_Status__c"
      },
      "payerName": {
        "sObjectFieldName": "PC_HP?_Payer_Name__c"
      },
      "idPolicyNo": {
        "sObjectFieldName": "PC_HP?_ID_Policy_No__c"
      },
      "groupNo": {
        "sObjectFieldName": "PC_HP?_Group_No__c"
      },
      "expirationDate": {
        "sObjectFieldName": "PC_HP?_Expiration_Date__c"
      },
      "effectiveDate": {
        "sObjectFieldName": "PC_HP?_Effective_Date__c"
      },
      "cardholderRelationToPatient": {
        "sObjectFieldName": "PC_HP?_Cardholder_Rel_to_Patient__c"
      },
      "cardholderName": {
        "sObjectFieldName": "PC_HP?_Cardholder_Name__c"
      },
      "cardholderEmployer": {
        "sObjectFieldName": "PC_HP?_Cardholder_Employer__c"
      },
      "cardholderDateOfBirth": {
        "sObjectFieldName": "PC_HP?_Cardholder_s_Date_of_Birth__c"
      }
    }
  },
  "Applicant/Address": {
    "propertyMappings": {
      "primaryAddress": {
        "sObjectFieldName": "PC_Primary_Address?__c"
      },
      "state": {
        "sObjectFieldName": "PC_State?__c"
      },
      "zipCode": {
        "sObjectFieldName": "PC_Zip_Code?__c"
      },
      "country": {
        "sObjectFieldName": "PC_Country?__c"
      },
      "city": {
        "sObjectFieldName": "PC_City?__c"
      },
      "addressType": {
        "sObjectFieldName": "PC_Address?_Description__c"
      },
      "address3": {
        "sObjectFieldName": "PC_Address?_3__c"
      },
      "address2": {
        "sObjectFieldName": "PC_Address?_2__c"
      },
      "address1": {
        "sObjectFieldName": "PC_Address?_1__c"
      }
    }
  },
  "Applicant": {
    "propertyMappings": {
      "lastName": {
        "sObjectFieldName": "PC_Last_Name__c"
      },
      "firstName": {
        "sObjectFieldName": "PC_First_Name__c"
      },
      "caregiverRelationToPatient": {
        "sObjectFieldName": "PC_Caregiver_Relationship_to_Patient__c"
      },
      "caregiverLastName": {
        "sObjectFieldName": "PC_Caregiver_Last_Name__c"
      },
      "caregiverFirstName": {
        "sObjectFieldName": "PC_Caregiver_First_Name__c"
      },
      "caregiverSalutation": {
        "sObjectFieldName": "PC_Caregiver_Salutation__c"
      },
      "preferredCommunicationChannel": {
        "sObjectFieldName": "PC_Preferred_Channel__c"
      },
      "phone": {
        "sObjectFieldName": "PC_Phone__c"
      },
      "email": {
        "sObjectFieldName": "PC_Patient_Email__c"
      },
      "communicationLanguage": {
        "sObjectFieldName": "PC_Communication__c"
      },
      "gender": {
        "sObjectFieldName": "PC_Gender__c"
      },
      "dateOfBirth": {
        "sObjectFieldName": "PC_Date_of_Birth__c"
      },
      "salutation": {
        "sObjectFieldName": "PC_Salutation__c"
      },
      "engagementProgramId": {
        "sObjectFieldName": "PC_Engagement_Program__c"
      },
      "patientId": {
        "sObjectFieldName": "PC_Account__c"
      },
      "physicianCity": {
        "sObjectFieldName": "PC_Physician_City__c"
      },
      "physicianEmail": {
        "sObjectFieldName": "PC_Physician_Email__c"
      },
      "physicianFax": {
        "sObjectFieldName": "PC_Physician_Fax__c"
      },
      "physicianName": {
        "sObjectFieldName": "PC_Physician_Name__c"
      },
      "physicianPhone": {
        "sObjectFieldName": "PC_Physician_Phone__c"
      },
      "physicianState": {
        "sObjectFieldName": "PC_Physician_State__c"
      },
      "physicianAddress1": {
        "sObjectFieldName": "PC_Physician_Street_Address1__c"
      },
      "physicianAddress2": {
        "sObjectFieldName": "PC_Physician_Street_Address2__c"
      },
      "physicianZipcode": {
        "sObjectFieldName": "PC_Physician_Zipcode__c"
      }
    }
  },
  "Account": {
    "propertyMappings": {
      "recordTypeId": {
        "sObjectFieldName": "RecordTypeId"
      },
      "phone": {
        "sObjectFieldName": "Phone"
      },
      "name": {
        "sObjectFieldName": "Name"
      },
      "id": {
        "sObjectFieldName": "Id"
      },
      "dateOfBirth": {
        "sObjectFieldName": "PC_Date_of_Birth__c"
      },
      "salutation": {
        "sObjectFieldName": "PC_Salutation__c"
      },
      "primaryAddress": {
        "sObjectFieldName": "PC_Primary_Address__c"
      },
      "preferredCommunicationChannel": {
        "sObjectFieldName": "PC_Preferred__c"
      },
      "manufacturerId": {
        "sObjectFieldName": "ParentId",
        "alternatePersonAccountSObjectFieldName" : "PC_ParentManufacturer__c"
      },
      "lastName": {
        "sObjectFieldName": "PC_Last_Name__c",
        "alternatePersonAccountSObjectFieldName" : "LastName"
      },
      "gender": {
        "sObjectFieldName": "PC_Gender__c"
      },
      "firstName": {
        "sObjectFieldName": "PC_First_Name__c",
        "alternatePersonAccountSObjectFieldName" : "FirstName"
      },
      "fax": {
        "sObjectFieldName": "Fax"
      },
      "email": {
        "sObjectFieldName": "PC_Email__c",
        "alternatePersonAccountSObjectFieldName" : "PersonEmail"
      },
      "communicationLanguage": {
        "sObjectFieldName": "PC_Communication_Language__c"
      },
      "caregiverSalutation": {
        "sObjectFieldName": "PC_Caregiver_Salutation__c"
      },
      "caregiverRelationToPatient": {
        "sObjectFieldName": "PC_Caregiver_Relationship_to_Patient__c"
      },
      "caregiverLastName": {
        "sObjectFieldName": "PC_Caregiver_Last_Name__c"
      },
      "caregiverFirstName": {
        "sObjectFieldName": "PC_Caregiver_First_Name__c"
      },
      "caregiverDetails": {
        "sObjectFieldName": "PC_Caregiver_Details__c"
      },
      "additionalPermission": {
        "sObjectFieldName": "PC_Additional_Permission__c"
      },
      "primaryZipcode" : {
        "sObjectFieldName":"PC_Primary_Zip_Code__c"
      }
    }
  },
  "Patient": {
    "propertyMappings": {
      "recordTypeId": {
        "sObjectFieldName": "RecordTypeId"
      },
      "salutation": {
        "sObjectFieldName": "PC_Salutation__c"
      },
      "primaryAddress": {
        "sObjectFieldName": "PC_Primary_Address__c"
      },
      "preferredCommunicationChannel": {
        "sObjectFieldName": "PC_Preferred__c"
      },
      "phone": {
        "sObjectFieldName": "Phone"
      },
      "name": {
        "sObjectFieldName": "Name"
      },
      "manufacturerId": {
        "sObjectFieldName": "ParentId",
        "alternatePersonAccountSObjectFieldName" : "PC_ParentManufacturer__c"
      },
      "lastName": {
        "sObjectFieldName": "PC_Last_Name__c",
        "alternatePersonAccountSObjectFieldName" : "LastName"
      },
      "id": {
        "sObjectFieldName": "Id"
      },
      "gender": {
        "sObjectFieldName": "PC_Gender__c"
      },
      "firstName": {
        "sObjectFieldName": "PC_First_Name__c",
        "alternatePersonAccountSObjectFieldName" : "FirstName"
      },
      "fax": {
        "sObjectFieldName": "Fax"
      },
      "email": {
        "sObjectFieldName": "PC_Email__c",
        "alternatePersonAccountSObjectFieldName" : "PersonEmail"
      },
      "dateOfBirth": {
        "sObjectFieldName": "PC_Date_of_Birth__c"
      },
      "communicationLanguage": {
        "sObjectFieldName": "PC_Communication_Language__c"
      },
      "caregiverSalutation": {
        "sObjectFieldName": "PC_Caregiver_Salutation__c"
      },
      "caregiverRelationToPatient": {
        "sObjectFieldName": "PC_Caregiver_Relationship_to_Patient__c"
      },
      "caregiverLastName": {
        "sObjectFieldName": "PC_Caregiver_Last_Name__c"
      },
      "caregiverFirstName": {
        "sObjectFieldName": "PC_Caregiver_First_Name__c"
      },
      "caregiverDetails": {
        "sObjectFieldName": "PC_Caregiver_Details__c"
      },
      "additionalPermission": {
        "sObjectFieldName": "PC_Additional_Permission__c"
      },
      "primaryZipcode" : {
        "sObjectFieldName":"PC_Primary_Zip_Code__c"
      }
    }
  },
  "Order": {
    "propertyMappings": {
      "actualDeliveryDate": {
        "sObjectFieldName": "PC_ActualDeliveryDate__c"
      },
      "address1": {
        "sObjectFieldName": "PC_OrderAddress1__c"
      },
      "address2": {
        "sObjectFieldName": "PC_OrderAddress2__c"
      },
      "address3": {
        "sObjectFieldName": "PC_OrderAddress3__c"
      },
      "city": {
        "sObjectFieldName": "PC_OrderAddressCity__c"
      },
      "deliveryDayRun": {
        "sObjectFieldName": "PC_DeliveryDayRun__c"
      },
      "estimatedDeliveryDate": {
        "sObjectFieldName": "PC_EstimatedDeliveryDate__c"
      },
      "id": {
        "sObjectFieldName": "Id"
      },
      "instructions": {
        "sObjectFieldName": "PC_OrderInstructions__c"
      },
      "orderNumber": {
        "sObjectFieldName": "Name"
      },
      "status": {
        "sObjectFieldName": "PC_OrderStatus__c"
      },
      "type": {
        "sObjectFieldName": "PC_OrderType__c"
      },
      "preferredDeliveryDate": {
        "sObjectFieldName": "PC_PreferredDeliveryDate__c"
      },
      "preferredDeliveryWindow": {
        "sObjectFieldName": "PC_PreferredDeliveryWindow__c"
      },
      "prescription": {
        "sObjectFieldName": "PC_Prescription__c"
      },
      "programCase": {
        "sObjectFieldName": "PC_ProgramCase__c"
      },
      "receivedBy": {
        "sObjectFieldName": "PC_ReceivedBy__c"
      },
      "shipTo": {
        "sObjectFieldName": "PC_ShipTo__c"
      },
      "shipmentTrackingNumber": {
        "sObjectFieldName": "PC_ShipmentTrackingNumber__c"
      },
      "orderState" : {
        "sObjectFieldName":"PC_OrderAddressState__c"
      },
      "shippingDate" : {
        "sObjectFieldName":"PC_ShippingDate__c"
      },
      "submittedDate" : {
        "sObjectFieldName":"PC_SubmittedDate__c"
      },
      "orderZipCode" : {
        "sObjectFieldName":"PC_OrderAddressZipCode__c"
      },
      "orderNumber" : {
        "sObjectFieldName": "Name"
      }
    }
  },
  "OrderItem": {
    "propertyMappings": {
      "actualDeliveryDate": {
        "sObjectFieldName": "PC_ActualDeliveryDate__c"
      },
      "daysSupply": {
        "sObjectFieldName": "PC_DaysSupply__c"
      },
      "estimatedDeliveryDate": {
        "sObjectFieldName": "PC_EstimatedDeliveryDate__c"
      },
      "ndc": {
        "sObjectFieldName": "PC_NDC__c"
      },
      "order": {
        "sObjectFieldName": "PC_Order__c"
      },
      "type": {
        "sObjectFieldName": "PC_OrderItemType__c"
      },
      "status": {
        "sObjectFieldName": "PC_OrderItemStatus__c"
      },
      "id": {
        "sObjectFieldName": "Id"
      },
      "packaging": {
        "sObjectFieldName": "PC_Packaging__c"
      },
      "product": {
        "sObjectFieldName": "PC_Product__c"
      },
      "productDescription": {
        "sObjectFieldName": "PC_ProductDescription__c"
      },
      "quantity": {
        "sObjectFieldName": "PC_Quantity__c"
      },
      "receivedBy": {
        "sObjectFieldName": "PC_ReceivedBy__c"
      },
      "shipmentTrackingNumber": {
        "sObjectFieldName": "PC_ShipmentTrackingNumber__c"
      },
      "shipmentDate": {
        "sObjectFieldName": "PC_ShippingDate__c"
      },
      "strength": {
        "sObjectFieldName": "PC_Strength__c"
      },
      "orderItemNumber" : {
        "sObjectFieldName": "Name"
      }
    }
  }
}