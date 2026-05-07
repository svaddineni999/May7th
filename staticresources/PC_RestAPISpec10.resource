{
  "swagger": "2.0",
  "info": {
    "version": "1.0",
    "title": "Patient Connect API",
    "description": "Patient Connect REST API to support patient enrollment into a program. All of the services can be extended to include custom fields on the objects by configuring REST API mappings in the Salesforce REST API Mappings Custom Metadata Type. Please note that some of the services are in Beta and are marked as *Beta. This indicates that the services may undergo changes in endpoint, request payload and response payloads in further releases. Hence, it is recommended to get in touch with product team before consuming such services."
  },
  "security": [
    {
      "password": [
        "read",
        "write"
      ]
    }
  ],
  "tags": [
    {
      "name": "patient",
      "description": "Patient operations"
    },
    {
      "name": "physician",
      "description": "Physician operations"
    },
    {
      "name": "healthPlan",
      "description": "Health Plan operations"
    },
    {
      "name": "address",
      "description": "Address operations for Patient and Physician"
    },
    {
      "name": "program",
      "description": "Program operations"
    },
     {
      "name": "association",
      "description": "Association operations"
    },
    {
      "name": "payer",
      "description": "Payer operations"
    },
    {
      "name": "manufacturer",
      "description": "Manufacturer operations"
    },
    {
      "name": "applicant",
      "description": "Applicant operations"
    },
    {
      "name": "programCoverage",
      "description": "Program Coverage operations"
    },
    {
      "name": "adverseEvent",
      "description": "adverseEvent operations"
    },
    {
      "name": "adverseEvent2",
      "description": "adverseEvent operations"
    },
    {
      "name": "order",
      "description": "order operations"
    },
    {
      "name": "orderItem",
      "description": "orderItem operations"
    },
    {
      "name": "account",
      "description": "Account operations"
    },
    {
      "name": "interaction",
      "description": "Interaction operations"
    },
    {
      "name": "engagementProgramSettings",
      "description": "Engagement Program Settings operations"
    }
  ],
  "schemes": [
    "https"
  ],
  "paths": {
    "/patient": {
      "post": {
        "tags": [
          "patient"
        ],
        "summary": "Add a new patient",
        "description": "Create a new patient",
        "operationId": "addPatient",
        "consumes": [
          "application/json"
        ],
        "produces": [
          "application/json"
        ],
        "parameters": [
          {
            "in": "body",
            "name": "body",
            "description": "Patient object that needs to be added. An array of addresses and health plans can also be provided and will be created for the patient. One of the addresses MUST be flagged as primary. The id fields on Patient, Address and HealthPlan are not expected and will be ignored. The Address.accountId and HealthPlan.patientId fields must not be provided.",
            "required": true,
            "schema": {
              "$ref": "#/definitions/Patient"
            }
          },
          {
            "in": "query",
            "name": "allOrNone",
            "description": "Indicates that parent and all child records must be created when true. If false a best effort to create child records is used and operation is considered successful unless parent record cannot be created.",
            "required": false,
            "type": "boolean",
            "example": false
          }
        ],
        "responses": {
          "200": {
            "description": "Patient Created",
            "schema": {
              "type": "object",
              "properties": {
                "patient": {
                  "type": "string",
                  "description": "Id of the patient that was created"
                },
                "addresses": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  },
                  "description": "Ids of the child addresses that were created in the order that they were provided, or ERROR:[errorLogRef] if allOrNone=false and the address could not be created."
                },
                "healthPlans": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  },
                  "description": "Ids of the child health plans that were created in the order that they were provided, or ERROR:[errorLogRef] if allOrNone=false and the health plan could not be created."
                },
                "errors": {
                  "type": "object",
                  "additionalProperties": {
                    "$ref": "#/definitions/ErrorResponse"
                  },
                  "description": "Map of errors where keys are of the form ERROR:[errorLogRef]. This map is only present when allOrNone=false and at least one error has occurred."
                }
              }
            }
          },
          "400": {
            "description": "Bad Request",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          },
          "500": {
            "description": "Internal Server Error",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          }
        }
      },
      "put": {
        "tags": [
          "patient"
        ],
        "summary": "Update an existing patient",
        "description": "Update a Patient with the provided information.",
        "consumes": [
          "application/json"
        ],
        "produces": [
          "application/json"
        ],
        "parameters": [
          {
            "in": "body",
            "name": "body",
            "description": "Patient object with information used to update an existing patient with corresponding id. Addresses and health plans can also be provided, but must exist and have valid ids. Address.accountId and HealthPlan.patientId may be provide but should not be changed form the original value.",
            "required": true,
            "schema": {
              "$ref": "#/definitions/Patient"
            }
          },
          {
            "in": "query",
            "name": "allOrNone",
            "description": "Indicates that parent and all child records must be updated successfully when true. If false a best effort to update child records is used and operation is considered successful unless the parent object cannot be updated.",
            "required": false,
            "type": "boolean",
            "example": false
          }
        ],
        "responses": {
          "200": {
            "description": "Updated",
            "schema": {
              "type": "object",
              "properties": {
                "patient": {
                  "type": "string",
                  "description": "Id of the patient that was updated"
                },
                "addresses": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  },
                  "description": "Ids of the child addresses that were updated in the order that they were provided, or ERROR:[errorLogRef] if allOrNone=false and the address could not be updated."
                },
                "healthPlans": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  },
                  "description": "Ids of the child health plans that were updated in the order that they were provided, or ERROR:[errorLogRef] if allOrNone=false and the health plan could not be updated."
                },
                "errors": {
                  "type": "object",
                  "additionalProperties": {
                    "$ref": "#/definitions/ErrorResponse"
                  },
                  "description": "Map of errors where keys are of the form ERROR:[errorLogRef]. This map is only present when allOrNone=false and at least one error has occurred."
                }
              }
            }
          },
          "400": {
            "description": "Bad Request",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          },
          "500": {
            "description": "Internal Server Error",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          }
        }
      }
    },
    "/patient/{patientId}": {
      "get": {
        "tags": [
          "patient"
        ],
        "summary": "Find patient by ID",
        "description": "Returns a patient either with or without addresses, health plans and any other configured child objects based on query parameter values.",
        "operationId": "getPatientById",
        "produces": [
          "application/json"
        ],
        "parameters": [
          {
            "name": "patientId",
            "in": "path",
            "description": "Salesforce ID of patient to return",
            "required": true,
            "type": "string"
          },
          {
            "in": "query",
            "name": "relationshipScope",
            "description": "Indicates the scope level based on which the extent of patient's information is retrieved.\n Default value is 'none'.\n If 'none', no child objects are returned.\n If 'specified', only the specified 'relationships' are returned.\n If 'all', all addresses, health plans and other configured relationships are returned.",
            "required": false,
            "type": "string",
            "enum": [
              "none",
              "specified",
              "all"
            ]
          },
          {
            "in": "query",
            "name": "relationships",
            "description": "Valid relationships separated by comma. This is mandatory when relationshipScope is 'specified'",
            "required": false,
            "type": "string",
            "example": "addresses,healthPlans",
            "enum": [
              "addresses",
              "healthPlans",
              "Any other valid relationship defined in the custom metadata settings."
            ]
          }
        ],
        "responses": {
          "200": {
            "description": "successful operation",
            "schema": {
              "$ref": "#/definitions/PatientWithAllRelatedObjects"
            }
          },
          "400": {
            "description": "Missing or Invalid Id",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          },
          "500": {
            "description": "Internal Server Error",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          }
        }
      }
    },
    "/patient/": {
      "get": {
        "tags": [
          "patient"
        ],
        "summary": "Find patient depending on the custom filter algo in the query parameters (Max records returned = 100)",
        "description": "Returns zero or more patients",
        "operationId": "getPatientsByCustomHeaderAlgo",
        "produces": [
          "application/json"
        ],
        "parameters": [
          {
            "in": "query",
            "name": "firstName",
            "description": "Patient's first name",
            "required": true,
            "type": "string"
          },

          {
            "in": "query",
            "name": "lastName",
            "description": "Patient's last name",
            "required": true,
            "type": "string"
          },
          {
            "in": "query",
            "name": "dateOfBirth",
            "description": "Patient's date of birth",
            "required": true,
            "type": "date"
          },
          {
            "in": "query",
            "name": "gender",
            "description": "Patient's gender",
            "required": false,
            "type": "string",
            "enum": [
              "Male",
              "Female"
            ]
          },
          {
            "in": "query",
            "name": "primaryZipcode",
            "description": "Patient's zip code",
            "required": false,
            "type": "string"
          },
          {
            "in": "query",
            "name": "phone",
            "description": "Patient's phone",
            "required": false,
            "type": "string"
          },
          {
            "in": "query",
            "name": "manufacturerId",
            "description": "Patient's manufacturer id",
            "required": false,
            "type": "string"
          },
          {
            "in": "query",
            "name": "patientClass",
            "description": "If you are using 'Individual' or 'Person Account' model then you must specify the patientClass. patientClass refers to the name of the record in 'Individual Record Type Mapper' custom meta data. This is used to filter patient records based on record type set in the 'Individual Mapper'.",
            "required": false,
            "type": "string"
          }
        ],
        "responses": {
          "200": {
            "description": "successful operation",
            "schema": {
              "type": "array",
              "items": {
                "allOf": [
                  {
                    "$ref": "#/definitions/BasePatient"
                  },
                  {
                    "type": "object",
                    "properties": {
                      "recordTypeId": {
                        "type": "string",
                        "description": "Record Type Id of the Patient"
                      },
                      "id": {
                        "type": "string",
                        "example": "0014100000gBiMsAAK",
                        "description": "Id of the patient"
                      },
                      "manufacturerId": {
                        "type": "string",
                        "example": "00141000001LfAcEAG",
                        "description": "Id of the manufacturer that the patient is related to."
                      },
                      "fax": {
                        "type": "string"
                      }
                    }
                  }
                ]
              }
            }
          },
          "400": {
            "description": "Missing or Invalid Id",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          },
          "500": {
            "description": "Internal Server Error",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          }
        }
      }
    },
    "/physician": {
      "post": {
        "tags": [
          "physician"
        ],
        "summary": "Add a new physician",
        "description": "Create a new physician",
        "operationId": "addPysician",
        "consumes": [
          "application/json"
        ],
        "produces": [
          "application/json"
        ],
        "parameters": [
          {
            "in": "body",
            "name": "body",
            "description": "Physician object that needs to be added. An array of addresses can also be provided and will be created for the physician. One of the addresses MUST be flagged as primary. The id fields of Physician and Address are not expected and will be ignored. The Address.accountId must not be provided.",
            "required": true,
            "schema": {
              "$ref": "#/definitions/Physician"
            }
          },
          {
            "in": "query",
            "name": "allOrNone",
            "description": "Indicates that parent and all child records must be created successfully when true. If false a best effort to create child records is used and operation is considered successful unless the parent object cannot be created.",
            "required": false,
            "type": "boolean",
            "example": false
          }
        ],
        "responses": {
          "200": {
            "description": "Created",
            "schema": {
              "type": "object",
              "properties": {
                "physician": {
                  "type": "string",
                  "description": "Id of the physician that was created"
                },
                "addresses": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  },
                  "description": "Ids of the child addresses that were created in they order that they were provided, or ERROR:[errorLogRef] if allOrNone=false and the address could not be created."
                },
                "errors": {
                  "type": "object",
                  "additionalProperties": {
                    "$ref": "#/definitions/ErrorResponse"
                  },
                  "description": "Map of errors where keys are of the form ERROR:[errorLogRef]. This map is only present when allOrNone=false and at least one error has occurred."
                }
              }
            }
          },
          "400": {
            "description": "Bad Request",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          },
          "500": {
            "description": "Internal Server Error",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          }
        }
      },
      "put": {
        "tags": [
          "physician"
        ],
        "summary": "Update an existing physician",
        "description": "Update a Physician with given id or npi.",
        "consumes": [
          "application/json"
        ],
        "produces": [
          "application/json"
        ],
        "parameters": [
          {
            "in": "body",
            "name": "body",
            "description": "Physician object with information used to update an existing physician. Addresses can also be provided, but must exist and have a valid id. Address.accountId MAY be provided but should not be changed from the original value.",
            "required": true,
            "schema": {
              "$ref": "#/definitions/Physician"
            }
          },
          {
            "in": "query",
            "name": "allOrNone",
            "description": "Indicates that parent and all child records must be updated successfully when true. If false a best effort to update child records is used and operation is considered successful unless the parent object cannot be updated.",
            "required": false,
            "type": "boolean",
            "example": false
          }
        ],
        "responses": {
          "200": {
            "description": "Updated",
            "schema": {
              "type": "object",
              "properties": {
                "physician": {
                  "type": "string",
                  "description": "Id of the physician that was updated"
                },
                "addresses": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  },
                  "description": "Ids of the child addresses that were updated in the order that they were provided, or ERROR:[errorLogRef] if allOrNone=false and the address could not be updated."
                },
                "errors": {
                  "type": "object",
                  "additionalProperties": {
                    "$ref": "#/definitions/ErrorResponse"
                  },
                  "description": "Map of errors where the keys are of the form ERROR:[errorLogRef]. This map is only present when allOrNone=false and at least one error has occurred."
                }
              }
            }
          },
          "400": {
            "description": "Bad Request",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          },
          "500": {
            "description": "Internal Server Error",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          }
        }
      }
    },
    "/physician/{physicianId}": {
      "get": {
        "tags": [
          "physician"
        ],
        "summary": "Find physician by ID",
        "description": "Returns a physician along with addresses",
        "operationId": "getPhysicianById",
        "produces": [
          "application/json"
        ],
        "parameters": [
          {
            "name": "physicianId",
            "in": "path",
            "description": "Salesforce ID of physician to return",
            "required": true,
            "type": "string"
          }
        ],
        "responses": {
          "200": {
            "description": "successful operation",
            "schema": {
              "$ref": "#/definitions/Physician"
            }
          },
          "400": {
            "description": "Missing or invalid physician Id",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          },
          "500": {
            "description": "Internal Server Error",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          }
        }
      }
    },
    "/physician/findByNPI/{npi}": {
      "get": {
        "tags": [
          "physician"
        ],
        "summary": "Find physician by NPI",
        "description": "Returns a physician along with addresses",
        "operationId": "findPhysicianByNPI",
        "produces": [
          "application/json"
        ],
        "parameters": [
          {
            "name": "npi",
            "in": "path",
            "description": "National Provider Identifier",
            "required": true,
            "type": "string"
          }
        ],
        "responses": {
          "200": {
            "description": "successful operation",
            "schema": {
              "$ref": "#/definitions/Physician"
            }
          },
          "400": {
            "description": "Missing or invalid NPI",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          },
          "500": {
            "description": "Internal Server Error",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          }
        }
      }
    },
    "/address": {
      "post": {
        "tags": [
          "address"
        ],
        "summary": "Add a new Address",
        "description": "Create a new Address",
        "operationId": "addAddress",
        "consumes": [
          "application/json"
        ],
        "produces": [
          "application/json"
        ],
        "parameters": [
          {
            "in": "body",
            "name": "body",
            "description": "Address object to be added. MUST contain an accountId for the owning account (Patient or Physician). An id is not expected and will be ignored if present.",
            "required": true,
            "schema": {
              "$ref": "#/definitions/Address"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Created",
            "schema": {
              "type": "object",
              "properties": {
                "address": {
                  "type": "string",
                  "description": "Id of the address that was created"
                }
              }
            }
          },
          "400": {
            "description": "Bad Request",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          },
          "500": {
            "description": "Internal Server Error",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          }
        }
      },
      "put": {
        "tags": [
          "address"
        ],
        "summary": "Update an existing address",
        "description": "Update an address with the provided information.",
        "consumes": [
          "application/json"
        ],
        "produces": [
          "application/json"
        ],
        "parameters": [
          {
            "in": "body",
            "name": "body",
            "description": "Address object with information used to update an existing address with corresponding id. A valid ID MUST be provided.",
            "required": true,
            "schema": {
              "$ref": "#/definitions/Address"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Updated",
            "schema": {
              "type": "object",
              "properties": {
                "address": {
                  "type": "string",
                  "description": "Id of the address that was updated"
                }
              }
            }
          },
          "400": {
            "description": "Bad Request",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          },
          "500": {
            "description": "Internal Server Error",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          }
        }
      }
    },
    "/address/{addressId}": {
      "get": {
        "tags": [
          "address"
        ],
        "summary": "Find address by ID",
        "description": "Returns an address",
        "operationId": "getAddressById",
        "produces": [
          "application/json"
        ],
        "parameters": [
          {
            "name": "addressId",
            "in": "path",
            "description": "Salesforce ID of address to return",
            "required": true,
            "type": "string"
          }
        ],
        "responses": {
          "200": {
            "description": "successful operation",
            "schema": {
              "$ref": "#/definitions/Address"
            }
          },
          "400": {
            "description": "Invalid or missing Id",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          },
          "500": {
            "description": "Internal Server Error",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          }
        }
      }
    },
    "/healthPlan": {
      "post": {
        "tags": [
          "healthPlan"
        ],
        "summary": "Add a new Health Plan",
        "description": "Create a new Health Plan",
        "operationId": "addHealthPlan",
        "consumes": [
          "application/json"
        ],
        "produces": [
          "application/json"
        ],
        "parameters": [
          {
            "in": "body",
            "name": "body",
            "description": "Health Plan object to be added. MUST contain a patientId for the owning Patient. An id is not expected and will be ignored if present.",
            "required": true,
            "schema": {
              "$ref": "#/definitions/HealthPlan"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Created",
            "schema": {
              "type": "object",
              "properties": {
                "healthPlan": {
                  "type": "string",
                  "description": "Id of the health plan that was created"
                }
              }
            }
          },
          "400": {
            "description": "Bad Request",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          },
          "500": {
            "description": "Internal Server Error",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          }
        }
      },
      "put": {
        "tags": [
          "healthPlan"
        ],
        "summary": "Update an existing Health Plan",
        "description": "Update a health plan with the provided information.",
        "consumes": [
          "application/json"
        ],
        "produces": [
          "application/json"
        ],
        "parameters": [
          {
            "in": "body",
            "name": "body",
            "description": "HealthPlan object with information used to update an existing health plan with corresponding id. A valid ID MUST be provided.",
            "required": true,
            "schema": {
              "$ref": "#/definitions/HealthPlan"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Updated",
            "schema": {
              "type": "object",
              "properties": {
                "healthPlan": {
                  "type": "string",
                  "description": "Id of the health plan that was updated"
                }
              }
            }
          },
          "400": {
            "description": "Bad Request",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          },
          "500": {
            "description": "Internal Server Error",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          }
        }
      }
    },
    "/healthPlan/{healthPlanId}": {
      "get": {
        "tags": [
          "healthPlan"
        ],
        "summary": "Find health plan by ID",
        "description": "Returns a health plan",
        "operationId": "getHealthPlanById",
        "produces": [
          "application/json"
        ],
        "parameters": [
          {
            "name": "healthPlanId",
            "in": "path",
            "description": "Salesforce ID of health plan to return",
            "required": true,
            "type": "string"
          }
        ],
        "responses": {
          "200": {
            "description": "successful operation",
            "schema": {
              "$ref": "#/definitions/HealthPlan"
            }
          },
          "400": {
            "description": "Missing or invalid health plan Id",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          },
          "500": {
            "description": "Internal Server Error",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          }
        }
      }
    },
    "/programCoverage": {
      "post": {
        "tags": [
          "programCoverage"
        ],
        "summary": "Add a new Program Coverage",
        "description": "Create a new program coverage",
        "operationId": "addProgramCoverage",
        "consumes": [
          "application/json"
        ],
        "produces": [
          "application/json"
        ],
        "parameters": [
          {
            "in": "body",
            "name": "body",
            "description": "Program Coverage object to be added. MUST contain a health plan id. An id is not expected and will be ignored if present.",
            "required": true,
            "schema": {
              "$ref": "#/definitions/ProgramCoverage"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Created",
            "schema": {
              "type": "object",
              "properties": {
                "healthPlan": {
                  "type": "string",
                  "description": "Id of the proram coverage that was created"
                }
              }
            }
          },
          "400": {
            "description": "Bad Request",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          },
          "500": {
            "description": "Internal Server Error",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          }
        }
      },
      "put": {
        "tags": [
          "programCoverage"
        ],
        "summary": "Update an existing Program Coverage",
        "description": "Update a program coverage with the provided information. Program Id should not be provided when using this service (Put), as parent of Program Coverage cannot be changed",
        "consumes": [
          "application/json"
        ],
        "produces": [
          "application/json"
        ],
        "parameters": [
          {
            "in": "body",
            "name": "body",
            "description": "ProgramCoverage object with information used to update an existing program coverage with corresponding id. A valid ID MUST be provided.",
            "required": true,
            "schema": {
              "$ref": "#/definitions/ProgramCoverage"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Updated",
            "schema": {
              "type": "object",
              "properties": {
                "healthPlan": {
                  "type": "string",
                  "description": "Id of the program coverage that was updated"
                }
              }
            }
          },
          "400": {
            "description": "Bad Request",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          },
          "500": {
            "description": "Internal Server Error",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          }
        }
      }
    },
    "/programCoverage/{programCoverageId}": {
      "get": {
        "tags": [
          "programCoverage"
        ],
        "summary": "Find program coverage by ID",
        "description": "Returns a program coverage",
        "operationId": "getProgramCoverageById",
        "produces": [
          "application/json"
        ],
        "parameters": [
          {
            "name": "programCoverageId",
            "in": "path",
            "description": "Salesforce ID of program coverage to return",
            "required": true,
            "type": "string"
          }
        ],
        "responses": {
          "200": {
            "description": "successful operation",
            "schema": {
              "$ref": "#/definitions/ProgramCoverage"
            }
          },
          "400": {
            "description": "Missing or invalid health plan Id",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          },
          "500": {
            "description": "Internal Server Error",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          }
        }
      }
    },
    "/programCoverage/findByProgramId/{programId}": {
      "get": {
        "tags": [
          "programCoverage"
        ],
        "summary": "Find all program coverages by program id",
        "description": "Returns list of program coverages",
        "operationId": "getProgramCoveragesByProgramId",
        "produces": [
          "application/json"
        ],
        "parameters": [
          {
            "name": "programId",
            "in": "path",
            "description": "Salesforce ID of the program id to which the patient is associated",
            "required": true,
            "type": "string"
          }
        ],
        "responses": {
          "200": {
            "description": "successful operation",
            "schema": {
              "type": "array",
              "items": {
                "$ref": "#/definitions/ProgramCoverage"
              }
            }
          },
          "400": {
            "description": "Missing or invalid patient Id",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          },
          "500": {
            "description": "Internal Server Error",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          }
        }
      }
    },
    "/adverseEvent": {
      "post": {
        "tags": [
          "adverseEvent"
        ],
        "summary": "Add a new adverseEvent",
        "description": "Create a new adverseEvent",
        "operationId": "addAdverseEvent",
        "consumes": [
          "application/json"
        ],
        "produces": [
          "application/json"
        ],
        "parameters": [
          {
            "in": "body",
            "name": "body",
            "description": "Adverse Event object to be added. MUST contain mandatory fields.",
            "required": true,
            "schema": {
              "$ref": "#/definitions/AdverseEvent"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Created",
            "schema": {
              "type": "object",
              "properties": {
                "adverseEvent": {
                  "type": "string",
                  "description": "Id of the adverse event that was created"
                },
                "suspectProducts": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  },
                  "description": "Ids of the suspect products  that were updated in order that they were provided"
                }
              }
            }
          },
          "400": {
            "description": "Bad Request",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          },
          "500": {
            "description": "Internal Server Error",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          }
        }
      },
      "put": {
        "tags": [
          "adverseEvent"
        ],
        "summary": "Update an existing adverseEvent",
        "description": "Update an adverseEvent with the provided information.",
        "consumes": [
          "application/json"
        ],
        "produces": [
          "application/json"
        ],
        "parameters": [
          {
            "in": "body",
            "name": "body",
            "description": "adverseEvent object with information used to update an existing adverseEvent with corresponding id.",
            "required": true,
            "schema": {
              "$ref": "#/definitions/AdverseEvent"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Updated",
            "schema": {
              "type": "object",
              "properties": {
                "adverseEvent": {
                  "type": "string",
                  "description": "Id of the adverse event that was updated"
                },
                "suspectProducts": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  },
                  "description": "Ids of the suspect products  that were updated in order that they were provided"
                }

              }
            }
          },
          "400": {
            "description": "Bad Request",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          },
          "500": {
            "description": "Internal Server Error",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          }
        }
      }
    },
    "/adverseEvent/findByPatientId/{patientId}": {
      "get": {
        "tags": [
          "adverseEvent"
        ],
        "summary": "Find by patient ID",
        "description": "Return adverse events based on query parameter value.",
        "operationId": "getAdverseEventsByPatientId",
        "produces": [
          "application/json"
        ],
        "parameters": [
          {
            "name": "patientId",
            "in": "path",
            "description": "Salesforce ID of the patient to which the adverse events are associated",
            "required": true,
            "type": "string"
          }
        ],
        "responses": {
          "200": {
            "description": "successful operation",
            "schema": {
              "type": "array",
              "items": {
                "$ref": "#/definitions/AdverseEvent"
              }
            }
          },
          "400": {
            "description": "Missing or Invalid Id",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          },
          "500": {
            "description": "Internal Server Error",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          }
        }
      }
    },
    "/adverseEvent2": {
      "post": {
        "tags": [
          "adverseEvent2"
        ],
        "summary": "Add a new adverseEvent",
        "description": "Create a new adverseEvent",
        "operationId": "addAdverseEvent",
        "consumes": [
          "application/json"
        ],
        "produces": [
          "application/json"
        ],
        "parameters": [
          {
            "in": "body",
            "name": "body",
            "description": "Adverse Event object to be added. MUST contain mandatory fields.",
            "required": true,
            "schema": {
              "$ref": "#/definitions/AdverseEvent2"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Created",
            "schema": {
              "type": "object",
              "properties": {
                "adverseEvent": {
                  "type": "string",
                  "description": "Id of the adverse event that was created"
                },
                "suspectProducts": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  },
                  "description": "Ids of the suspect products  that were updated in order that they were provided"
                }
              }
            }
          },
          "400": {
            "description": "Bad Request",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          },
          "500": {
            "description": "Internal Server Error",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          }
        }
      },
      "put": {
        "tags": [
          "adverseEvent2"
        ],
        "summary": "Update an existing adverseEvent",
        "description": "Update an adverseEvent with the provided information.",
        "consumes": [
          "application/json"
        ],
        "produces": [
          "application/json"
        ],
        "parameters": [
          {
            "in": "body",
            "name": "body",
            "description": "adverseEvent object with information used to update an existing adverseEvent with corresponding id.",
            "required": true,
            "schema": {
              "$ref": "#/definitions/AdverseEvent2"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Updated",
            "schema": {
              "type": "object",
              "properties": {
                "adverseEvent": {
                  "type": "string",
                  "description": "Id of the adverse event that was updated"
                },
                "suspectProducts": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  },
                  "description": "Ids of the suspect products  that were updated in order that they were provided"
                }

              }
            }
          },
          "400": {
            "description": "Bad Request",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          },
          "500": {
            "description": "Internal Server Error",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          }
        }
      }
    },
    "/adverseEvent2/findByPatientId/{patientId}": {
      "get": {
        "tags": [
          "adverseEvent2"
        ],
        "summary": "Find by patient ID",
        "description": "Return adverse events based on query parameter value.",
        "operationId": "getAdverseEventsByPatientId",
        "produces": [
          "application/json"
        ],
        "parameters": [
          {
            "name": "patientId",
            "in": "path",
            "description": "Salesforce ID of the patient to which the adverse events are associated",
            "required": false,
            "type": "string"
          }
        ],
        "responses": {
          "200": {
            "description": "successful operation",
            "schema": {
              "type": "array",
              "items": {
                "$ref": "#/definitions/AdverseEvent2"
              }
            }
          },
          "400": {
            "description": "Missing or Invalid Id",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          },
          "500": {
            "description": "Internal Server Error",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          }
        }
      }
    },
    "/program": {
      "post": {
        "tags": [
          "program"
        ],
        "summary": "Creates a new patient program",
        "description": "Create a new patient program and associations with care team members.",
        "operationId": "addProgram",
        "consumes": [
          "application/json"
        ],
        "produces": [
          "application/json"
        ],
        "parameters": [
          {
            "in": "body",
            "name": "body",
            "description": "Program object to be added. MUST contain a patientId for the enrolled Patient. An id is not expected and will be ignored if present. Care team members, such as a treaing Physician can be included.",
            "required": true,
            "schema": {
              "$ref": "#/definitions/Program"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Created",
            "schema": {
              "type": "object",
              "properties": {
                "program": {
                  "type": "string",
                  "description": "Id of the program that was created"
                },
                "associations": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  },
                  "description": "Ids of the associations that were updated in order that they were provided"
                },
                "supportCases": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  },
                  "description": "Ids of the support cases that were created in order that they were provided"
                }
              }
            }
          },
          "400": {
            "description": "Bad Request",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          },
          "500": {
            "description": "Internal Server Error",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          }
        }
      }
    },
    "/program/findByPatientId/{patientId}": {
      "get": {
        "tags": [
          "program"
        ],
        "summary": "Find all programs that the patient is enrolled in.",
        "description": "Returns an array of Programs.",
        "operationId": "findProgramsByPatientId",
        "produces": [
          "application/json"
        ],
        "parameters": [
          {
            "name": "patientId",
            "in": "path",
            "description": "Salesforce id of the patient",
            "required": true,
            "type": "string"
          }
        ],
        "responses": {
          "200": {
            "description": "successful operation",
            "schema": {
              "type": "array",
              "items": {
                "allOf": [
                  {
                    "$ref": "#/definitions/Program"
                  },
                  {
                    "type": "object",
                    "properties": {
                      "caseProduct": {
                        "type": "string",
                        "description": "Product name of the related Program Product."
                      },
                      "engagementProgramName": {
                        "type": "string",
                        "description": "Name of the related Engagement Program."
                      }
                    }
                  }
                ]
              }
            }
          },
          "400": {
            "description": "Bad Request",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          },
          "500": {
            "description": "Internal Server Error",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          }
        }
      }
    },
    "/supportCase": {
      "post": {
        "tags": [
          "supportCase"
        ],
        "summary": "Creates a new program support case",
        "operationId": "addSupportCase",
        "consumes": [
          "application/json"
        ],
        "produces": [
          "application/json"
        ],
        "parameters": [
          {
            "in": "body",
            "name": "body",
            "description": "Support Case object to be added. MUST contain a programId and valid recordType. An id is not expected and will be ignored if present.",
            "required": true,
            "schema": {
              "$ref": "#/definitions/SupportCase"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Created",
            "schema": {
              "type": "object",
              "properties": {
                "supportCase": {
                  "type": "string",
                  "description": "Id of the support case that was created"
                }
              }
            }
          },
          "400": {
            "description": "Bad Request",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          },
          "500": {
            "description": "Internal Server Error",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          }
        }
      }
    },
    "/supportCase/findByProgramId/{programId}": {
      "get": {
        "tags": [
          "supportCase"
        ],
        "summary": "Find all program support cases for the given patient program case.",
        "description": "Returns an array of Support Cases.",
        "operationId": "findSupportCasesByProgramId",
        "produces": [
          "application/json"
        ],
        "parameters": [
          {
            "name": "programId",
            "in": "path",
            "description": "Salesforce id of the program case",
            "required": true,
            "type": "string"
          }
        ],
        "responses": {
          "200": {
            "description": "successful operation",
            "schema": {
              "type": "array",
              "items": {
                "$ref": "#/definitions/SupportCase"
              }
            }
          },
          "400": {
            "description": "Bad Request",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          },
          "500": {
            "description": "Internal Server Error",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          }
        }
      }
    },
    "/association":{
      "post": {
        "tags": [
          "association"
        ],
        "summary": "Creates a new association record",
        "description": "Create a new association on an existing program case",
        "operationId": "addAssociation",
        "consumes": [
          "application/json"
        ],
        "produces": [
          "application/json"
        ],
        "parameters": [
          {
            "in": "body",
            "name": "body",
            "description": "Association object to be added. MUST contain a role, program Case Id, userId/accountId. The values userId and accountId are mutually exclusive(either one) and based on the role.",
            "required": true,
            "schema": {
              "$ref": "#/definitions/Association"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Created",
            "schema": {
              "type": "object",
              "properties": {
                "association": {
                  "type": "string",
                  "description": "Id of the association that was created"
                }
              }
            }
          },
          "400": {
            "description": "Bad Request",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          },
          "500": {
            "description": "Internal Server Error",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          }
        }
      },
      "put":{
        "tags": [
          "association"
        ],
        "summary": "Update an existing association",
        "description": "Update an association with the provided information.",
        "operationId": "updateAssociation",
        "consumes": [
          "application/json"
        ],
        "produces": [
          "application/json"
        ],
        "parameters": [
          {
            "in": "body",
            "name": "body",
            "description": "Association object with information used to update an existing association with corresponding id.",
            "required": true,
            "schema": {
              "$ref": "#/definitions/Association"
            }
          }],
        "responses": {
          "200": {
            "description": "Updated",
            "schema": {
              "type": "object",
              "properties": {
                "association": {
                  "type": "string",
                  "description": "Id of the association that was updated"
                }
              }
            }
          },
          "400": {
            "description": "Bad Request",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          },
          "500": {
            "description": "Internal Server Error",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          }
        }
      }
    },
    "/association/{associationId}":{
      "delete": {
        "tags": [
          "association"
        ],
        "summary": "Delete an existing association record",
        "description": "Delete an existing association record",
        "operationId": "deleteAssociation",
        "consumes": [
          "application/json"
        ],
        "produces": [
          "application/json"
        ],
        "parameters": [
          {
            "in"          : "path",
            "name"        : "associationId",
            "description" : "Salesforce id of the association to be deleted.",
            "required"    : true,
            "type"        : "string"
          }
        ],
        "responses": {
          "202": {
            "description": "Deleted",
            "schema": {
              "$ref": "#/definitions/DeleteResponse"
            }
          },
          "400": {
            "description": "Bad Request",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          },
          "500": {
            "description": "Internal Server Error",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          }
        }
      }
    },
    "/payer": {
      "get": {
        "tags": [
          "payer"
        ],
        "summary": "Returns all payers in the system",
        "operationId": "getPayers",
        "produces": [
          "application/json"
        ],
        "responses": {
          "200": {
            "description": "successful operation",
            "schema": {
              "type": "array",
              "items": {
                "$ref": "#/definitions/Payer"
              }
            }
          },
          "400": {
            "description": "Bad Request",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          },
          "500": {
            "description": "Internal Server Error",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          }
        }
      }
    },
    "/payer": {
      "get": {
        "tags": [
          "payer"
        ],
        "summary": "Finds all payers filtered by the query parameters",
        "produces": [
          "application/json"
        ],
        "parameters": [
          {
            "name": "findBy",
            "in": "query",
            "description": "Filter Type",
            "required": true,
            "type": "string",
            "enum": ["name"]
          },
          {
            "name": "name",
            "in": "query",
            "description": "Name of the payer. Can take wild card character (*). There must be a minimum of 3 characters.",
            "required": true,
            "type": "string"
          },
          {
            "name": "phone",
            "in": "query",
            "description": "Phone number of the payer",
            "required": false,
            "type": "string"
          }
        ],
        "responses": {
          "200": {
            "description": "successful operation",
            "schema": {
              "type": "array",
              "items": {
                "$ref": "#/definitions/Payer"
              }
            }
          }
        },
        "400": {
          "description": "Bad Request",
          "schema": {
            "$ref": "#/definitions/ErrorResponse"
          }
        },
        "500": {
          "description": "Internal Server Error",
          "schema": {
            "$ref": "#/definitions/ErrorResponse"
          }
        }
      }
    },
    "/payer/findByName/{name}": {
      "get": {
        "tags": [
          "payer"
        ],
        "summary": "Finds all payers with the given name",
        "produces": [
          "application/json"
        ],
        "parameters": [
          {
            "name": "name",
            "in": "path",
            "description": "Name of the payer",
            "required": true,
            "type": "string"
          }
        ],
        "responses": {
          "200": {
            "description": "successful operation",
            "schema": {
              "type": "array",
              "items": {
                "$ref": "#/definitions/Payer"
              }
            }
          }
        },
        "400": {
          "description": "Bad Request",
          "schema": {
            "$ref": "#/definitions/ErrorResponse"
          }
        },
        "500": {
          "description": "Internal Server Error",
          "schema": {
            "$ref": "#/definitions/ErrorResponse"
          }
        }
      }
    },
    "/manufacturer": {
      "get": {
        "tags": [
          "manufacturer"
        ],
        "summary": "Returns all manufacturers in the system",
        "operationId": "getManufacturer",
        "produces": [
          "application/json"
        ],
        "responses": {
          "200": {
            "description": "successful operation",
            "schema": {
              "type": "array",
              "items": {
                "$ref": "#/definitions/Manufacturer"
              }
            }
          },
          "400": {
            "description": "Bad Request",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          },
          "500": {
            "description": "Internal Server Error",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          }
        }
      }
    },
    "/manufacturer/findByName/{name}": {
      "get": {
        "tags": [
          "manufacturer"
        ],
        "summary": "Finds all manufacturers with the given name",
        "produces": [
          "application/json"
        ],
        "parameters": [
          {
            "name": "name",
            "in": "path",
            "description": "Name of the manufacturer",
            "required": true,
            "type": "string"
          }
        ],
        "responses": {
          "200": {
            "description": "successful operation",
            "schema": {
              "type": "array",
              "items": {
                "$ref": "#/definitions/Manufacturer"
              }
            }
          },
          "400": {
            "description": "Bad Request",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          },
          "500": {
            "description": "Internal Server Error",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          }
        }
      }
    },
    "/engagementProgram/findByCode/{programCode}": {
      "get": {
        "tags": [
          "engagementProgram"
        ],
        "summary": "Finds the Engagement Program with the given program code",
        "produces": [
          "applicaiton/json"
        ],
        "parameters": [
          {
            "name": "programCode",
            "in": "path",
            "required": true,
            "type": "string"
          }
        ],
        "responses": {
          "200": {
            "description": "successful operation",
            "schema": {
              "$ref": "#/definitions/EngagementProgram"
            }
          }
        },
        "400": {
          "description": "Bad Request",
          "schema": {
            "$ref": "#/definitions/ErrorResponse"
          }
        },
        "500": {
          "description": "Internal Server Error",
          "schema": {
            "$ref": "#/definitions/ErrorResponse"
          }
        }
      }
    },
    "/applicant": {
      "post": {
        "tags": [
          "applicant"
        ],
        "summary": "Add a new applicant",
        "description": "Create a new applicant",
        "operationId": "addApplicant",
        "consumes": [
          "application/json"
        ],
        "produces": [
          "application/json"
        ],
        "parameters": [
          {
            "in": "body",
            "name": "body",
            "description": "Applicant object that needs to be added. along with the applicant's addresses, health plans and physician",
            "required": true,
            "schema": {
              "$ref": "#/definitions/Applicant"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Created",
            "schema": {
              "type": "object",
              "properties": {
                "applicant": {
                  "type": "string",
                  "description": "Id of the applicant that was created"
                }
              }
            }
          },
          "400": {
            "description": "Bad Request",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          },
          "500": {
            "description": "Internal Server Error",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          }
        }
      }
    },
    "/order/{orderId}" : {
      "get": {
        "tags": [
          "order"
        ],
        "summary": "Find order by ID",
        "description": "Returns an order",
        "operationId": "getOrderById",
        "produces": [
          "application/json"
        ],
        "parameters": [
          {
            "name": "orderId",
            "in": "path",
            "description": "Salesforce ID of order to return",
            "required": true,
            "type": "string"
          }
        ],
        "responses": {
          "200": {
            "description": "successful operation",
            "schema": {
              "$ref": "#/definitions/OrderResponse"
            }
          },
          "400": {
            "description": "Missing or invalid order item Id",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          },
          "500": {
            "description": "Internal Server Error",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          }
        }
      }
    },
    "/order": {
      "get": {
        "tags": [
          "order"
        ],
        "summary": "Find order depending on the custom filter algo in the query parameters. Provide atleast one query parameter (Max records returned = 100)",
        "description": "Returns zero or more order",
        "operationId": "getOrderByCustomHeaderAlgo",
        "produces": [
          "application/json"
        ],
        "parameters": [
          {
            "in": "query",
            "name": "orderNumber",
            "description": "Order number",
            "required": false,
            "type": "string"
          },
          {
            "in": "query",
            "name": "programCase",
            "description": "Associated program case ID",
            "required": false,
            "type": "string"
          },
          {
            "in": "query",
            "name": "submittedDate",
            "description": "Order Submitted Date",
            "required": false,
            "type": "string",
            "format": "date",
            "example": "2012-04-23"
          }
        ],
        "responses": {
          "200": {
            "description": "successful operation",
            "schema": {
              "type": "array",
              "items": {
                "allOf": [
                  {
                    "$ref": "#/definitions/OrderWithOrderItemsResponse"
                  }
                ]
              }
            }
          },
          "400": {
            "description": "Missing or Invalid Id",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          },
          "500": {
            "description": "Internal Server Error",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          }
        }
      },
      "post": {
        "tags": [
          "order"
        ],
        "summary": "Add a new order",
        "description": "Create a new order",
        "operationId": "addOrder",
        "consumes": [
          "application/json"
        ],
        "produces": [
          "application/json"
        ],
        "parameters": [
          {
            "in": "body",
            "name": "body",
            "description": "Order object that needs to be added. An array of order items can also be provided and will be created for the order. The id fields on Order and Order Items are not expected and will be ignored. Do not specifiy 'order' field on orderItems",
            "required": true,
            "schema": {
              "$ref": "#/definitions/OrderWithOrderItems"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Created",
            "schema": {
              "type": "object",
              "properties": {
                "order": {
                  "type": "string",
                  "description": "Id of the order that was updated"
                },
                "orderItems": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  },
                  "description": "Ids of the child order that were updated in the order that they were provided."
                }
              }
            }
          },
          "400": {
            "description": "Bad Request",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          },
          "500": {
            "description": "Internal Server Error",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          }
        }
      },
      "put": {
        "tags": [
          "order"
        ],
        "summary": "Update an existing order",
        "description": "Update an order with the provided information.",
        "consumes": [
          "application/json"
        ],
        "produces": [
          "application/json"
        ],
        "parameters": [
          {
            "in": "body",
            "name": "body",
            "description": "Order object with information used to update an existing order with corresponding id. Order Items can also be provided, but must exist and have valid ids.",
            "required": true,
            "schema": {
              "$ref": "#/definitions/OrderWithOrderItems"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Updated",
            "schema": {
              "type": "object",
              "properties": {
                "order": {
                  "type": "string",
                  "description": "Id of the order that was updated"
                },
                "orderItems": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  },
                  "description": "Ids of the child order that were updated in the order that they were provided."
                }
              }
            }
          },
          "400": {
            "description": "Bad Request",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          },
          "500": {
            "description": "Internal Server Error",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          }
        }
      }
    },
    "/oderItem/{orderItemId}" : {
      "get": {
        "tags": [
          "orderItem"
        ],
        "summary": "Find order item by ID",
        "description": "Returns an order item",
        "operationId": "getOrderItemById",
        "produces": [
          "application/json"
        ],
        "parameters": [
          {
            "name": "orderItemId",
            "in": "path",
            "description": "Salesforce ID of order item to return",
            "required": true,
            "type": "string"
          }
        ],
        "responses": {
          "200": {
            "description": "successful operation",
            "schema": {
              "$ref": "#/definitions/OrderItemResponse"
            }
          },
          "400": {
            "description": "Missing or invalid order item Id",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          },
          "500": {
            "description": "Internal Server Error",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          }
        }
      }
    },
    "/orderItem": {
      "get": {
        "tags": [
          "orderItem"
        ],
        "summary": "Find order item depending on the custom filter algo in the query parameters. Provide atleast one of the query parameters (Max records returned = 100)",
        "description": "Returns zero or more order items",
        "operationId": "getOrderItemsByCustomHeaderAlgo",
        "produces": [
          "application/json"
        ],
        "parameters": [
          {
            "in": "query",
            "name": "orderNumber",
            "description": "Associated order number",
            "required": false,
            "type": "string"
          },

          {
            "in": "query",
            "name": "productId",
            "description": "Associated product ID",
            "required": false,
            "type": "string"
          }
        ],
        "responses": {
          "200": {
            "description": "successful operation",
            "schema": {
              "type": "array",
              "items": {
                "allOf": [
                  {
                    "$ref": "#/definitions/OrderItemResponse"
                  }
                ]
              }
            }
          },
          "400": {
            "description": "Missing or Invalid Id",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          },
          "500": {
            "description": "Internal Server Error",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          }
        }
      },
      "post": {
        "tags": [
          "orderItem"
        ],
        "summary": "Add a new order item",
        "description": "Create a new order item",
        "operationId": "addOrderItem",
        "consumes": [
          "application/json"
        ],
        "produces": [
          "application/json"
        ],
        "parameters": [
          {
            "in": "body",
            "name": "body",
            "description": "Order Item object that needs to be added.",
            "required": true,
            "schema": {
              "$ref": "#/definitions/OrderItem"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Created",
            "schema": {
              "type": "object",
              "properties": {
                "orderItem": {
                  "type": "string",
                  "description": "Id of the order item that was created"
                }
              }
            }
          },
          "400": {
            "description": "Bad Request",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          },
          "500": {
            "description": "Internal Server Error",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          }
        }
      },
      "put": {
        "tags": [
          "orderItem"
        ],
        "summary": "Update an existing order.",
        "description": "Update an order with the provided information.",
        "consumes": [
          "application/json"
        ],
        "produces": [
          "application/json"
        ],
        "parameters": [
          {
            "in": "body",
            "name": "body",
            "description": "Order Item object with information used to update an existing order item with corresponding id. Do not provide 'order' field.",
            "required": true,
            "schema": {
              "$ref": "#/definitions/OrderItem"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Updated",
            "schema": {
              "type": "object",
              "properties": {
                "orderItem": {
                  "type": "string",
                  "description": "Id of the order item that was updated"
                }
              }
            }
          },
          "400": {
            "description": "Bad Request",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          },
          "500": {
            "description": "Internal Server Error",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          }
        }
      }
    },
    "/account/": {
      "get": {
        "tags": [
          "account"
        ],
        "summary": "Find Account depending on the custom filters in the query parameters. (Beta. Max records returned = 100.)",
        "description": "Returns zero or more accounts. (*Beta - Expect changes in endpoint, request and response JSON in further releases. Hence, recommended to get in touch with product team before consuming the service.)",
        "operationId": "getAccountsByPhone",
        "produces": [
          "application/json"
        ],
        "parameters": [
          {
            "in": "query",
            "name": "phone",
            "description": "Account's Phone",
            "required": true,
            "type": "string"
          },
          {
            "in": "query",
            "name": "patientClass",
            "description": "If you are using 'Individual' or 'Person Account' model then you can specify the patientClass to filter Account based on record type. patientClass refers to the name of the record in 'Individual Record Type Mapper' custom meta data.",
            "required": false,
            "type": "string"
          }
        ],
        "responses": {
          "200": {
            "description": "successful operation",
            "schema": {
              "$ref": "#/definitions/BaseAccount"
            }
          },
          "400": {
            "description": "Missing or Invalid Phone",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          },
          "500": {
            "description": "Internal Server Error",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          }
        }
      }
    },
    "/engagementProgramSettings/": {
      "get": {
        "tags": [
          "engagementProgramSettings"
        ],
        "summary": "Get Self service settings depending on the filters given in the query parameters.(Beta)",
        "description": "Returns zero or more Engagement Program Settings. (*Beta - Expect changes in endpoint, request and response JSON in further releases. Hence, recommended to get in touch with product team before consuming the service.)",
        "operationId": "getSettingsByEngagementProgramId",
        "produces": [
          "application/json"
        ],
        "parameters": [
          {
            "in": "query",
            "name": "engagementProgramId",
            "description": "Salesforce Id of Engagement Program",
            "required": true,
            "type": "string"
          },
          {
            "in": "query",
            "name": "vendor",
            "description": "Name of the vendor for which services are configured",
            "required": false,
            "type": "string"
          },
          {
            "in": "query",
            "name": "channel",
            "description": "Channel used by self service",
            "required": false,
            "type": "string"
          }
        ],
        "responses": {
          "200": {
            "description": "successful operation",
            "schema": {
              "$ref": "#/definitions/BaseSelfServiceSetting"
            }
          },
          "400": {
            "description": "Missing or Invalid Query Parameters",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          },
          "500": {
            "description": "Internal Server Error",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          }
        }
      }
    },
    "/interaction": {
      "put": {
        "tags": [
          "interaction"
        ],
        "summary": "Update an existing interaction.(Beta)",
        "description": "Updates an interaction with provided information. (*Beta - Expect changes in endpoint, request and response JSON in further releases. Hence, recommended to get in touch with product team before consuming the service.)",
        "operationId": "updateInteraction",
        "consumes": [
          "application/json"
        ],
        "produces": [
          "application/json"
        ],
        "parameters": [
          {
            "in": "body",
            "name": "body",
            "description": "Interaction object with information that needs to be updated. A valid Id must be provided. ",
            "required": true,
            "schema": {
              "$ref": "#/definitions/BaseInteraction"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Updated",
            "schema": {
              "type": "object",
              "properties": {
                "interaction": {
                  "type": "string",
                  "description": "Id of the interaction that was updated"
                }
              }
            }
          },
          "400": {
            "description": "Bad Request",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          },
          "500": {
            "description": "Internal Server Error",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          }
        }
      }
    },
    "/interaction/findByPatientId/": {
      "get": {
        "tags": [
          "interaction"
        ],
        "summary": "Find Interactions depending on the custom filters given in the query parameters.(Beta)",
        "description": "Returns zero or more interactions. (*Beta - Expect changes in endpoint, request and response JSON in further releases. Hence, recommended to get in touch with product team before consuming the service.)",
        "operationId": "getInteractionsByPatientId",
        "produces": [
          "application/json"
        ],
        "parameters": [
          {
            "in": "query",
            "name": "patientId",
            "description": "Id of Patient Account",
            "required": true,
            "type": "string"
          },
          {
            "in": "query",
            "name": "limit",
            "description": "Limit for the interaction records to fetch. Default value will be 5 if this parameter is not provided.",
            "required": false,
            "type": "string"
          }
        ],
        "responses": {
          "200": {
            "description": "successful operation",
            "schema": {
              "$ref": "#/definitions/BaseInteraction"
            }
          },
          "400": {
            "description": "Missing or Invalid Query Parameters",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          },
          "500": {
            "description": "Internal Server Error",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          }
        }
      }
    },
    "/interaction/findByEngagementProgramId/": {
      "get": {
        "tags": [
          "interaction"
        ],
        "summary": "Find Interactions depending on the custom filters given in the query parameters.(Beta)",
        "description": "Returns zero or more interactions. (*Beta - Expect changes in endpoint, request and response JSON in further releases. Hence, recommended to get in touch with product team before consuming the service.)",
        "operationId": "getInteractionsByEngagementProgramId",
        "produces": [
          "application/json"
        ],
        "parameters": [
          {
            "in": "query",
            "name": "patientId",
            "description": "Id of Patient Account",
            "required": true,
            "type": "string"
          },
          {
            "in": "query",
            "name": "engagementProgramId",
            "description": "Id of Engagement Program",
            "required": true,
            "type": "string"
          },
          {
            "in": "query",
            "name": "limit",
            "description": "Limit for the interaction records to fetch. Default value will be 5 if this parameter is not provided.",
            "required": false,
            "type": "string"
          }
        ],
        "responses": {
          "200": {
            "description": "successful operation",
            "schema": {
              "$ref": "#/definitions/BaseInteraction"
            }
          },
          "400": {
            "description": "Missing or Invalid Query Parameters",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          },
          "500": {
            "description": "Internal Server Error",
            "schema": {
              "$ref": "#/definitions/ErrorResponse"
            }
          }
        }
      }
    }
  },
  "securityDefinitions": {
    "password": {
      "type": "oauth2",
      "tokenUrl": "https://login.salesforce.com/services/oauth2/token",
      "flow": "password",
      "scopes": {
        "write": "allows modifying resources",
        "read": "allows reading resources"
      }
    }
  },
  "definitions": {
    "BaseHealthPlan": {
      "type": "object",
      "properties": {
        "recordType": {
          "type": "string",
          "description": "The record type API name",
          "example":"<namespace>__<record type developer name>"
        },
        "planType": {
          "type": "string"
        },
        "groupNo": {
          "type": "string"
        },
        "idPolicyNo": {
          "type": "string"
        },
        "effectiveDate": {
          "type": "string",
          "format": "date"
        },
        "expirationDate": {
          "type": "string",
          "format": "date"
        },
        "rxBin": {
          "type": "string"
        },
        "rxGrp": {
          "type": "string"
        },
        "rxPCN": {
          "type": "string"
        },
        "cardholderRelationToPatient": {
          "type": "string",
          "enum": [
            "Self",
            "Spouse",
            "Child",
            "Father",
            "Mother",
            "Domestic Partner",
            "Guardian",
            "Other"
          ]
        },
        "cardholderDateOfBirth": {
          "type": "string",
          "format": "date"
        },
        "cardholderName": {
          "type": "string"
        },
        "cardholderEmployer": {
          "type": "string"
        }
      }
    },
    "BaseProgramCoverage": {
      "type": "object",
      "properties": {
        "recordType": {
          "type": "string",
          "description": "The record type API name",
          "example":"<namespace>__<record type developer name>"
        },
        "alternateFunding": {
          "type": "string"
        },
        "annualOutOfPocket": {
          "type": "integer"
        },
        "appealAvailable": {
          "type": "string"
        },
        "coinsurancePercent": {
          "type": "integer"
        },
        "comments": {
          "type": "integer"
        },
        "copayAmount": {
          "type": "integer"
        },
        "copayAssistanceAmount": {
          "type": "integer"
        },
        "copayCardExpirationDate": {
          "type": "string",
          "format":"date"
        },
        "copayCardGroupNumber": {
          "type": "string"
        },
        "copayCardNumber": {
          "type": "string"
        },
        "copayCardRxBinNumber": {
          "type": "string"
        },
        "copayCardStatus": {
          "type": "string"
        },
        "coveragePercent": {
          "type": "string"
        },
        "coverageStatus": {
          "type": "string"
        },
        "coverageType": {
          "type": "string"
        },
        "deductible": {
          "type": "string"
        },
        "isEligible": {
          "type": "boolean"
        },
        "expirationDate": {
          "type": "string",
          "format":"date"
        },
        "healthPlan": {
          "type": "string"
        },
        "meetsQualification": {
          "type": "string"
        },
        "programId":{
          "type": "string"
        },
        "id":{
          "type": "string"
        }
      }
    },
    "BaseSelfServiceSetting": {
      "type": "object",
      "properties": {
        "id": {
          "type": "string",
          "example": "0014100000gBiMsAAK",
          "description": "Id of the Self Service Setting"
        },
        "active": {
          "type": "string",
          "description": "Indicates if setting is active or not"
        },
        "serviceFlowIdentifier": {
          "type": "string",
          "description": "Unique Identifier for the service flow"
        },
        "vendorName": {
          "type": "string",
          "description": "Name of the vendor for which setting is configured"
        },
        "engagementProgram": {
          "type": "string",
          "description": "The Engagement program to which the setting is associated to"
        },
        "order": {
          "type": "string",
          "description": "Order in which services are defined"
        },
        "serviceName": {
          "type": "string",
          "description": "Name of the service that is offered"
        },
        "downstreamFlowIdentifier": {
          "type": "string",
          "description": "Unique identifier for the flow that need to be executed after Service flow is run"
        },
        "channel": {
          "type": "string",
          "description": "Self service Channel"
        },
        "otherChannel": {
          "type": "string",
          "description": "Other channel name if Other is selected in Channel"
        }
      }
    },
    "BaseAccount": {
      "type": "object",
      "properties": {
        "salutation": {
          "type": "string",
          "description": "Based on picklist, which may be customized",
          "enum": [
            "Mr.",
            "Ms.",
            "Mrs.",
            "Dr."
          ]
        },
        "patientClass": {
          "type": "string",
          "description": "If you are using 'Individual' or 'Person Account' model then this indicates record type of Account. patientClass refers to the name of the record in 'Individual Record Type Mapper' custom meta data. "
        },
        "firstName": {
          "type": "string"
        },
        "lastName": {
          "type": "string"
        },
        "dateOfBirth": {
          "type": "string",
          "format": "date"
        },
        "gender": {
          "type": "string",
          "description": "Gender of the Account",
          "enum": [
            "Male",
            "Female"
          ]
        },
        "communicationLanguage": {
          "type": "string"
        },
        "email": {
          "type": "string"
        },
        "phone": {
          "type": "string"
        },
        "preferredCommunicationChannel": {
          "type": "string",
          "description": "Preferred communication channel",
          "enum": [
            "Phone",
            "Email",
            "Fax",
            "SMS",
            "Postal Mail"
          ]
        },
        "caregiverSalutation": {
          "type": "string",
          "description": "Based on picklist, which may be customized",
          "enum": [
            "Mr.",
            "Ms.",
            "Mrs.",
            "Dr."
          ]
        },
        "caregiverFirstName": {
          "type": "string"
        },
        "caregiverLastName": {
          "type": "string"
        },
        "caregiverRelationToPatient": {
          "type": "string",
          "enum": [
            "Spouse",
            "Child",
            "Father",
            "Mother",
            "Domestic Partner",
            "Guardian",
            "Other"
          ]
        },
        "id": {
          "type": "string",
          "example": "0014100000gBiMsAAK",
          "description": "Id of the Account"
        },
        "manufacturerId": {
          "type": "string",
          "example": "00141000001LfAcEAG",
          "description": "Id of the manufacturer that the account is related to."
        },
        "fax": {
          "type": "string"
        }
      }
    },
    "BaseInteraction": {
      "type": "object",
      "properties": {
        "name": {
          "type": "string",
          "description": "Name of the Interaction"
        },
        "id": {
          "type": "string",
          "example": "0014100000gBiMsAAK",
          "description": "Id of the Interaction"
        },
        "patientProgram": {
          "type": "string",
          "description": "Program case that interaction is related to"
        },
        "status": {
          "type": "string",
          "example": "Confirmed",
          "description": "Status of the interaction"
        },
        "type": {
          "type": "string",
          "description": "Type of the interaction"
        },
        "start": {
          "type": "string",
          "description": "Start date time of the interaction"
        },
        "end": {
          "type": "string",
          "description": "End date time of the interaction"
        },
        "participant": {
          "type": "string",
          "description": "Account who is participant in the interaction"
        },
        "patient": {
          "type": "string",
          "description": "Patient the interaction is related to"
        },
        "notes": {
          "type": "string",
          "description": "Notes on interaction"
        },
        "durationHrs": {
          "type": "string",
          "description": "Total duration of the interaction in hours"
        }
      }
    },
    "BaseAddress": {
      "type": "object",
      "required": [
        "address1"
      ],
      "properties": {
        "addressType": {
          "type": "string",
          "example": "Business",
          "description": "Picklist of address types",
          "enum": [
            "Business"
          ]
        },
        "address1": {
          "type": "string",
          "example": "ConvergeHEALTH"
        },
        "address2": {
          "type": "string",
          "example": "275 Washington Street"
        },
        "zipCode": {
          "type": "string",
          "example": "02458"
        },
        "city": {
          "type": "string",
          "example": "Newton"
        },
        "country": {
          "type": "string",
          "example": "United States"
        },
        "state": {
          "type": "string",
          "example": "MA"
        },
        "primaryAddress": {
          "type": "boolean",
          "example": true
        }
      }
    },
    "BasePatient": {
      "type": "object",
      "required": [
        "firstName",
        "lastName",
        "dateOfBirth"
      ],
      "properties": {
        "salutation": {
          "type": "string",
          "description": "Based on picklist, which may be customized",
          "enum": [
            "Mr.",
            "Ms.",
            "Mrs.",
            "Dr."
          ]
        },
        "patientClass": {
          "type": "string",
          "description": "If you are using 'Individual' or 'Person Account' model then you must specify the patientClass. patientClass refers to the name of the record in 'Individual Record Type Mapper' custom meta data. This is used to set the record type of the patient record that is being created. This is not valid in PUT."
        },
        "firstName": {
          "type": "string"
        },
        "lastName": {
          "type": "string"
        },
        "dateOfBirth": {
          "type": "string",
          "format": "date"
        },
        "gender": {
          "type": "string",
          "description":"Gender of the Patient",
          "enum": [
            "Male",
            "Female"
          ]
        },
        "communicationLanguage": {
          "type": "string"
        },
        "email": {
          "type": "string"
        },
        "phone": {
          "type": "string"
        },
        "preferredCommunicationChannel": {
          "type": "string",
          "description": "Preferred communication channel",
          "enum": [
            "Phone",
            "Email",
            "Fax",
            "SMS",
            "Postal Mail"
          ]
        },
        "caregiverSalutation": {
          "type": "string",
          "description": "Based on picklist, which may be customized",
          "enum": [
            "Mr.",
            "Ms.",
            "Mrs.",
            "Dr."
          ]
        },
        "caregiverFirstName": {
          "type": "string"
        },
        "caregiverLastName": {
          "type": "string"
        },
        "caregiverRelationToPatient": {
          "type": "string",
          "enum": [
            "Spouse",
            "Child",
            "Father",
            "Mother",
            "Domestic Partner",
            "Guardian",
            "Other"
          ]
        }
      }
    },
    "AdverseEvent":{
      "type": "object",
      "allOf": [{
        "properties": {
          "patientId": {
            "type": "string",
            "required": true,
            "description": "Patient account with which the adverse event is associated."
          },
          "caseId": {
            "type": "string",
            "description": "The Program (Case) to which the adverse event is associated with."
          },
          "gender": {
            "type": "string",
            "description": "Gender of the patient",
            "example": "Male",
            "enum": [
              "Male",
              "Female"
            ]
          },
          "ethnicity": {
            "type": "string",
            "description": "Ethnicity of the Patient.",
            "enum": [
              "Hispanic/Latino",
              "Not Hispanic/Latino"
            ]
          },
          "dateOfBirth": {
            "type": "string",
            "format": "date",
            "description": "The patient's date of birth. This value will be populated from the Account object."
          },
          "age": {
            "type": "integer",
            "description": "The patient's age at the onset of the adverse event."
          },
          "weight": {
            "type": "integer",
            "description": "Weight of the Patient."
          },
          "weightUnit": {
            "type": "string",
            "description": "Unit in which the patient's  weight is denoted. For example, lb. or kg.",
            "enum": [
              "lb",
              "kg"
            ]
          },
          "ageUnit": {
            "type": "string",
            "description": "Units used to determine the patient's age. For example, in years, months, weeks, or days.",
            "enum": [
              "Year(s)",
              "Month(s)",
              "Week(s)",
              "Day(s)"
            ]
          },
          "race": {
            "type": "string",
            "example": "Asian;American Indian or Alaskan Native;White",
            "description": "More than one Race of the Patient can be selected. The values should be semicolon seperated",
            "enum": [
              "Asian",
              "American Indian or Alaskan Native",
              "Black or African American",
              "White",
              "Native Hawaiian or Other Pacific Islander"
            ]
          },
          "dateOfTheReport": {
            "type": "string",
            "format": "date",
            "example": "2019-05-21",
            "description": "Date of the Report on the Event"
          },
          "eventOnsetDate": {
            "type": "string",
            "format": "date",
            "example": "2019-05-21",
            "description": "Indicates the actual or best estimate of the date of first onset of the adverse event."
          },
          "endDate": {
            "type": "string",
            "format": "date",
            "example": "2019-05-21",
            "description": "Indicates the actual or best estimate of the date of end of the adverse event."
          },
          "description": {
            "type": "string",
            "example": "long text area",
            "description": "Describes the event in detail using the reporter’s own words, including a description of what happened and a summary of all relevant clinical information (medical status prior to the event, signs and/or symptoms, differential diagnosis for the event in question, clinical course, treatment, outcome, and so on)."
          },
          "laboratoryData": {
            "type": "string",
            "example": "text area",
            "description": "Indicates all appropriate information, including relevant negative test and laboratory findings, in order to most completely convey how the medical work-up/assessment led to strong consideration of medical-product-induced disease as etiology for clinical status, as other differential diagnostic considerations were being eliminated."
          },
          "otherReleventHistory": {
            "type": "string",
            "example": "Text area",
            "description": "Any other relavent history data"
          },
          "eventVerbatim": {
            "type": "string",
            "example": "text area",
            "description": "Describes the occurred adverse event in reporter's words."
          },
          "outcome": {
            "type": "string",
            "example": "Death;Life-threatening;Disability or Permanent Damage",
            "description": "More than one outcome can be selected. The values should be semicolon seperated",
            "enum": [
              "Death",
              "Life-threatening",
              "Disability or Permanent Damage",
              "Hospitalization – initial or prolonged",
              "Congenital Anomaly/Birth Defects",
              "Other Serious (Important Medical Events)",
              "Required Intervention to Prevent Permanent Impairment/Damage (Devices)"
            ]
          },
          "dateofDeath": {
            "type": "string",
            "format": "date",
            "example": "2019-05-21",
            "description": "Date of Death"
          },
          "systemOrganClassCode": {
            "type": "string",
            "description": "Indicates the System Organ Class (SOC) code to which the adverse event belongs to."
          },
          "highLevelGroupTermCode": {
            "type": "string",
            "description": "High Level Group Term (HLGT) code to which the adverse event belongs to."
          },
          "highLevelTermCode": {
            "type": "string",
            "description": "High Level Term (HLT) code to which the adverse event belongs to."
          },
          "preferredTermCode": {
            "type": "string",
            "description": "Preferred Term (PT) code to which the adverse event belongs to."
          },
          "lowLevelTermCode": {
            "type": "string",
            "description": "Low Level Term (LLT) code to which the adverse event belongs to."
          },
          "reporterFirstName": {
            "type": "string",
            "description": "First name of the reporter"
          },
          "reporterLastName": {
            "type": "string",
            "description": "Last name of the Reporter"
          },
          "reporterAddress": {
            "type": "string",
            "example": " text area",
            "description": "The complete address of the person who reports the adverse event."
          },
          "reporterCity": {
            "type": "string",
            "description": " The City of the person who reports the adverse event."
          },
          "reporterState": {
            "type": "string",
            "description": "The State of the person who reports the adverse event."
          },
          "reporterCountry": {
            "type": "string",
            "description": "The Country of the person who reports the adverse event."
          },
          "reporterZip": {
            "type": "string",
            "description": "The contact Zip Code of the person who reports the adverse event."
          },
          "reporterEmail": {
            "type": "string",
            "example": "xyz@gmail.com",
            "description": "The Email address of the person who reports the adverse event."
          },
          "reporterPhone": {
            "type": "string",
            "description": "The telephone number of the person who reports the adverse event."
          },
          "reporterType": {
            "type": "string",
            "example": "Physician",
            "description": "Role who reported Adverse Event",
            "enum": [
              "Nurse",
              "Physician",
              "Nurse Practitioner",
              "Dentist",
              "Physician Assistant",
              "Other Healthcare Professional",
              "Risk Manager",
              "Biomedical Engineer",
              "Administrator/Supervisor",
              "Pharmacist"
            ]
          },
          "initialReporterSentReportToFda": {
            "type": "string",
            "description": "If Initial reporter also has sent report to FDA",
            "enum": [
              "Yes",
              "No",
              "Unknown"
            ]
          },
          "healthCareProfessional": {
            "type": "string",
            "description": "Indicates if Initial reporter is a Health care Professional",
            "enum": [
              "Yes",
              "No"
            ]
          },
          "manufacturerName": {
            "type": "string",
            "description": "Indicates the manufacturer's name who reports the adverse event."
          },
          "manufacturerAddress": {
            "type": "string",
            "description": "Drug manufacturer's address"
          },
          "manufacturerEmail": {
            "type": "string",
            "example": "xyz@gmail.com",
            "description": "Drug manufacture's email"
          },
          "manufacturerCompOutsourcingFac": {
            "type": "STRING",
            "example": false,
            "description": "Indicates if the manufacturer is registered as 503B facility."
          },
          "manufacturerPhone": {
            "type": "string",
            "description": "Phone number of the drug manufacturer"
          },
          "dateReceivedByManufacturer": {
            "type": "string",
            "format": "date",
            "example": "2019-05-21",
            "description": "This indicates the date when the applicant, manufacturer, corporate affiliate, and so on received information about the occurrence of an adverse event."
          },
          "newDrugApplication ": {
            "type": "string",
            "description": "Indicates the unique identifier used by the manufacturer for this report."
          },
          "abbreviatedNewDrugApplicationNumber": {
            "type": "string",
            "description": "The abbreviated new drug application or the new drug application (NDA) number."
          },
          "investigationalNewDrugApplicationNumber": {
            "type": "string",
            "description": "The Investigational New Drug (IND) application number."
          },
          "biologicsApplicationNumber": {
            "type": "string",
            "description": "The 6 digit Biologics Application Number (BLA)."
          },
          "premarketApplication510kNumber": {
            "type": "string",
            "description": "The Premarket Application (PMA) or pre-market notification [510(k)] submission number for the approved / cleared medical device or combination product."
          },
          "pre1938Flag": {
            "type": "string",
            "description": "Indicates if the  suspect product  was marketed prior to 1938 and does not have an application number.",
            "example": "Yes",
            "enum": [
              "Yes",
              "No"
            ]
          },
          "combinationProductUse": {
            "type": "string",
            "description": "Combination Product Report flag",
            "enum": [
              "Yes",
              "No"
            ]
          },
          "overTheCounterProduct": {
            "type": "string",
            "description": "Indicates if the product is issued over-the-counter.",
            "enum": [
              "Yes",
              "No"
            ]
          },
          "manufacturerReportNumber": {
            "type": "string",
            "description": "Indicates the unique identifier used by the manufacturer for this report."
          },
          "ifIndProtocolNumber": {
            "type": "string",
            "description": "If Investigational New Drug (IND) number exists then mention the protocol number."
          },
          "adverseEventTerms": {
            "type": "string",
            "description": "Includes a list of adverse event terms that most accurately characterize the adverse event."
          },
          "reportSourceOtherText": {
            "type": "string",
            "example": "value other than report sources",
            "description": "When -Other- option is selected in -reportSources- field then mention the value in this field."
          },
          "reportTypeOtherText": {
            "type": "string",
            "example": "Other type of report which is not present in Report Types",
            "description": "When -Other- option is selected in -reportTypes- field then mention the value in this field."
          },
          "reportSource": {
            "type": "string",
            "description": "Multiple sources of the report can be selected with semicolon as a seperator",
            "example": "Company Representative;User Facility;Distributor",
            "enum": [
              "Company Representative",
              "User Facility",
              "Distributor",
              "Foreign",
              "Study",
              "Consumer",
              "Literature",
              "Health Professional",
              "Other"
            ]
          },
          "reportTypes": {
            "type": "string",
            "description": "Types of report can be selected with semicolon as a separator",
            "example": "5-day;7-day;10-day",
            "enum": [
              "5-day",
              "7-day",
              "10-day",
              "15-day",
              "30-day",
              "Periodic",
              "Initial",
              "Follow-up",
              "Other"
            ]
          },
          "id": {
            "type": "string",
            "example": "a0R41000001LfAcEAK",
            "description": "Salesforce Id. This value should be populated for PUT method, otherwise it is optional."
          },
          "suspectProducts": {
            "type": "array",
            "items": {
              "$ref": "#/definitions/SuspectProducts"
            }
          }
        }

      }]

    },
    "AdverseEvent2":{
      "type": "object",
      "allOf": [{
        "properties": {
          "patientId": {
            "type": "string",
            "required": true,
            "description": "Patient account with which the adverse event is associated."
          },
          "caseId": {
            "type": "string",
            "description": "The Program (Case) to which the adverse event is associated with."
          },
          "gender": {
            "type": "string",
            "description": "Gender of the patient",
            "example": "Male",
            "enum": [
              "Male",
              "Female"
            ]
          },
          "ethnicity": {
            "type": "string",
            "description": "Ethnicity of the Patient.",
            "enum": [
              "Hispanic/Latino",
              "Not Hispanic/Latino"
            ]
          },
          "dateOfBirth": {
            "type": "string",
            "format": "date",
            "description": "The patient's date of birth. This value will be populated from the Account object."
          },
          "age": {
            "type": "integer",
            "description": "The patient's age at the onset of the adverse event."
          },
          "weight": {
            "type": "integer",
            "description": "Weight of the Patient."
          },
          "weightUnit": {
            "type": "string",
            "description": "Unit in which the patient's  weight is denoted. For example, lb. or kg.",
            "enum": [
              "lb",
              "kg"
            ]
          },
          "ageUnit": {
            "type": "string",
            "description": "Units used to determine the patient's age. For example, in years, months, weeks, or days.",
            "enum": [
              "Year(s)",
              "Month(s)",
              "Week(s)",
              "Day(s)"
            ]
          },
          "race": {
            "type": "string",
            "example": "Asian;American Indian or Alaskan Native;White",
            "description": "More than one Race of the Patient can be selected. The values should be semicolon seperated",
            "enum": [
              "Asian",
              "American Indian or Alaskan Native",
              "Black or African American",
              "White",
              "Native Hawaiian or Other Pacific Islander"
            ]
          },
          "dateOfTheReport": {
            "type": "string",
            "format": "date",
            "example": "2019-05-21",
            "description": "Date of the Report on the Event"
          },
          "eventOnsetDate": {
            "type": "string",
            "format": "date",
            "example": "2019-05-21",
            "description": "Indicates the actual or best estimate of the date of first onset of the adverse event."
          },
          "endDate": {
            "type": "string",
            "format": "date",
            "example": "2019-05-21",
            "description": "Indicates the actual or best estimate of the date of end of the adverse event."
          },
          "description": {
            "type": "string",
            "example": "long text area",
            "description": "Describes the event in detail using the reporter’s own words, including a description of what happened and a summary of all relevant clinical information (medical status prior to the event, signs and/or symptoms, differential diagnosis for the event in question, clinical course, treatment, outcome, and so on)."
          },
          "laboratoryData": {
            "type": "string",
            "example": "text area",
            "description": "Indicates all appropriate information, including relevant negative test and laboratory findings, in order to most completely convey how the medical work-up/assessment led to strong consideration of medical-product-induced disease as etiology for clinical status, as other differential diagnostic considerations were being eliminated."
          },
          "otherReleventHistory": {
            "type": "string",
            "example": "Text area",
            "description": "Any other relavent history data"
          },
          "eventVerbatim": {
            "type": "string",
            "example": "text area",
            "description": "Describes the occurred adverse event in reporter's words."
          },
          "outcome": {
            "type": "string",
            "example": "Death;Life-threatening;Disability or Permanent Damage",
            "description": "More than one outcome can be selected. The values should be semicolon seperated",
            "enum": [
              "Death",
              "Life-threatening",
              "Disability or Permanent Damage",
              "Hospitalization – initial or prolonged",
              "Congenital Anomaly/Birth Defects",
              "Other Serious (Important Medical Events)",
              "Required Intervention to Prevent Permanent Impairment/Damage (Devices)"
            ]
          },
          "dateofDeath": {
            "type": "string",
            "format": "date",
            "example": "2019-05-21",
            "description": "Date of Death"
          },
          "systemOrganClassCode": {
            "type": "string",
            "description": "Indicates the System Organ Class (SOC) code to which the adverse event belongs to."
          },
          "highLevelGroupTermCode": {
            "type": "string",
            "description": "High Level Group Term (HLGT) code to which the adverse event belongs to."
          },
          "highLevelTermCode": {
            "type": "string",
            "description": "High Level Term (HLT) code to which the adverse event belongs to."
          },
          "preferredTermCode": {
            "type": "string",
            "description": "Preferred Term (PT) code to which the adverse event belongs to."
          },
          "lowLevelTermCode": {
            "type": "string",
            "description": "Low Level Term (LLT) code to which the adverse event belongs to."
          },
          "reporterFirstName": {
            "type": "string",
            "description": "First name of the reporter"
          },
          "reporterLastName": {
            "type": "string",
            "description": "Last name of the Reporter"
          },
          "reporterAddress": {
            "type": "string",
            "example": " text area",
            "description": "The complete address of the person who reports the adverse event."
          },
          "reporterCity": {
            "type": "string",
            "description": " The City of the person who reports the adverse event."
          },
          "reporterState": {
            "type": "string",
            "description": "The State of the person who reports the adverse event."
          },
          "reporterCountry": {
            "type": "string",
            "description": "The Country of the person who reports the adverse event."
          },
          "reporterZip": {
            "type": "string",
            "description": "The contact Zip Code of the person who reports the adverse event."
          },
          "reporterEmail": {
            "type": "string",
            "example": "xyz@gmail.com",
            "description": "The Email address of the person who reports the adverse event."
          },
          "reporterPhone": {
            "type": "string",
            "description": "The telephone number of the person who reports the adverse event."
          },
          "reporterType": {
            "type": "string",
            "example": "Physician",
            "description": "Role who reported Adverse Event",
            "enum": [
              "Nurse",
              "Physician",
              "Nurse Practitioner",
              "Dentist",
              "Physician Assistant",
              "Other Healthcare Professional",
              "Risk Manager",
              "Biomedical Engineer",
              "Administrator/Supervisor",
              "Pharmacist"
            ]
          },
          "initialReporterSentReportToFda": {
            "type": "string",
            "description": "If Initial reporter also has sent report to FDA",
            "enum": [
              "Yes",
              "No",
              "Unknown"
            ]
          },
          "healthCareProfessional": {
            "type": "string",
            "description": "Indicates if Initial reporter is a Health care Professional",
            "enum": [
              "Yes",
              "No"
            ]
          },
          "manufacturerName": {
            "type": "string",
            "description": "Indicates the manufacturer's name who reports the adverse event."
          },
          "manufacturerAddress": {
            "type": "string",
            "description": "Drug manufacturer's address"
          },
          "manufacturerEmail": {
            "type": "string",
            "example": "xyz@gmail.com",
            "description": "Drug manufacture's email"
          },
          "manufacturerCompOutsourcingFac": {
            "type": "STRING",
            "example": false,
            "description": "Indicates if the manufacturer is registered as 503B facility."
          },
          "manufacturerPhone": {
            "type": "string",
            "description": "Phone number of the drug manufacturer"
          },
          "dateReceivedByManufacturer": {
            "type": "string",
            "format": "date",
            "example": "2019-05-21",
            "description": "This indicates the date when the applicant, manufacturer, corporate affiliate, and so on received information about the occurrence of an adverse event."
          },
          "newDrugApplication ": {
            "type": "string",
            "description": "Indicates the unique identifier used by the manufacturer for this report."
          },
          "abbreviatedNewDrugApplicationNumber": {
            "type": "string",
            "description": "The abbreviated new drug application or the new drug application (NDA) number."
          },
          "investigationalNewDrugApplicationNumber": {
            "type": "string",
            "description": "The Investigational New Drug (IND) application number."
          },
          "biologicsApplicationNumber": {
            "type": "string",
            "description": "The 6 digit Biologics Application Number (BLA)."
          },
          "premarketApplication510kNumber": {
            "type": "string",
            "description": "The Premarket Application (PMA) or pre-market notification [510(k)] submission number for the approved / cleared medical device or combination product."
          },
          "pre1938Flag": {
            "type": "string",
            "description": "Indicates if the  suspect product  was marketed prior to 1938 and does not have an application number.",
            "example": "Yes",
            "enum": [
              "Yes",
              "No"
            ]
          },
          "combinationProductUse": {
            "type": "string",
            "description": "Combination Product Report flag",
            "enum": [
              "Yes",
              "No"
            ]
          },
          "overTheCounterProduct": {
            "type": "string",
            "description": "Indicates if the product is issued over-the-counter.",
            "enum": [
              "Yes",
              "No"
            ]
          },
          "manufacturerReportNumber": {
            "type": "string",
            "description": "Indicates the unique identifier used by the manufacturer for this report."
          },
          "ifIndProtocolNumber": {
            "type": "string",
            "description": "If Investigational New Drug (IND) number exists then mention the protocol number."
          },
          "adverseEventTerms": {
            "type": "string",
            "description": "Includes a list of adverse event terms that most accurately characterize the adverse event."
          },
          "reportSourceOtherText": {
            "type": "string",
            "example": "value other than report sources",
            "description": "When -Other- option is selected in -reportSources- field then mention the value in this field."
          },
          "reportTypeOtherText": {
            "type": "string",
            "example": "Other type of report which is not present in Report Types",
            "description": "When -Other- option is selected in -reportTypes- field then mention the value in this field."
          },
          "reportSource": {
            "type": "string",
            "description": "Multiple sources of the report can be selected with semicolon as a seperator",
            "example": "Company Representative;User Facility;Distributor",
            "enum": [
              "Company Representative",
              "User Facility",
              "Distributor",
              "Foreign",
              "Study",
              "Consumer",
              "Literature",
              "Health Professional",
              "Other"
            ]
          },
          "reportTypes": {
            "type": "string",
            "description": "Types of report can be selected with semicolon as a separator",
            "example": "5-day;7-day;10-day",
            "enum": [
              "5-day",
              "7-day",
              "10-day",
              "15-day",
              "30-day",
              "Periodic",
              "Initial",
              "Follow-up",
              "Other"
            ]
          },
          "id": {
            "type": "string",
            "example": "a0R41000001LfAcEAK",
            "description": "Salesforce Id. This value should be populated for PUT method, otherwise it is optional."
          },
          "suspectProducts": {
            "type": "array",
            "items": {
              "$ref": "#/definitions/SuspectProducts"
            }
          }
        }

      }]

    },
    "HealthPlan": {
      "type": "object",
      "allOf": [
        {
          "$ref": "#/definitions/BaseHealthPlan"
        },
        {
          "properties": {
            "id": {
              "type": "string",
              "example": "a0R41000001LfAcEAK",
              "description": "Salesforce identifier"
            },
            "payerId": {
              "type": "string",
              "example": "00141000001LfAcEAG",
              "description": "Id of the payer that provides the health plan"
            },
            "patientId": {
              "type": "string",
              "description": "Id of the Patient account that the address belongs to"
            },
            "renewalDate": {
              "type": "string",
              "format": "date"
            }
          }
        }
      ]
    },
    "ProgramCoverage": {
      "type": "object",
      "allOf": [
        {
          "$ref": "#/definitions/BaseProgramCoverage"
        }
      ]
    },
    "Address": {
      "type": "object",
      "allOf": [
        {
          "$ref": "#/definitions/BaseAddress"
        },
        {
          "properties": {
            "id": {
              "type": "string",
              "example": "a0D41000006gtglEAA",
              "description": "Salesforce identifier that is defined when the object is created and MUST be provided when updating an address."
            },
            "accountId": {
              "type": "string",
              "description": "Account (Patient or Provider) that the address is associated with."
            },
            "address3": {
              "type": "string",
              "example": "Suite 200"
            },
            "status": {
              "type": "string",
              "enum": [
                "Active",
                "Inactive"
              ]
            }
          }
        }
      ]
    },
    "PatientWithAllRelatedObjects": {
      "type": "object",
      "allOf": [
        {
          "$ref": "#/definitions/Patient"
        }
      ]
    },
    "Patient": {
      "type": "object",
      "allOf": [
        {
          "$ref": "#/definitions/BasePatient"
        },
        {
          "properties": {
            "id": {
              "type": "string",
              "example": "0014100000gBiMsAAK",
              "description": "Id of the patient"
            },
            "manufacturerId": {
              "type": "string",
              "example": "00141000001LfAcEAG",
              "description": "Id of the manufacturer that the patient is related to."
            },
            "addresses": {
              "type": "array",
              "items": {
                "$ref": "#/definitions/Address"
              }
            },
            "healthPlans": {
              "type": "array",
              "items": {
                "$ref": "#/definitions/HealthPlan"
              }
            },
            "fax": {
              "type": "string"
            }
          }
        }
      ]
    },
    "Physician": {
      "type": "object",
      "required": [
        "firstName",
        "lastName"
      ],
      "properties": {
        "id": {
          "type": "string",
          "example": "0014100000gBiMsAAK",
          "description": "Salesforce identifier"
        },
        "firstName": {
          "type": "string"
        },
        "lastName": {
          "type": "string"
        },
        "type": {
          "type": "string",
          "description": "Must match a picklist value.",
          "enum": [
            "Specialist",
            "Primary Care"
          ]
        },
        "specialistType": {
          "type": "string",
          "description": "Specialist type when type is Specialist"
        },
        "npi": {
          "type": "string",
          "description": "National Provider Identifier"
        },
        "communicationLanguage": {
          "type": "string"
        },
        "email": {
          "type": "string"
        },
        "phone": {
          "type": "string"
        },
        "fax": {
          "type": "string"
        },
        "preferredCommunicationChannel": {
          "type": "string",
          "description": "Preferred communication channel",
          "enum": [
            "Phone",
            "Email",
            "Fax",
            "SMS",
            "Postal Mail"
          ]
        },
        "addresses": {
          "type": "array",
          "items": {
            "$ref": "#/definitions/Address"
          }
        }
      }
    },
    "Association": {
      "type": "object",
      "description": "A patient association with a care team member in a given program. There can only be one care team member HCO, HCP, User, etc per association, so the accountId and userId fields are mutually exclusive.",
      "allOf": [
        {
          "$ref": "#/definitions/BaseAssociation"
        },
        {
        "properties": {
          "programId": {
            "type": "string",
            "description": "The id of the Program that is being associated."
          },
          "accountId": {
            "type": "string",
            "description": "The id of the HCO or HCP (Provider) being associated."
          },
          "userId": {
            "type": "string",
            "description": "The userId of the user that is being associated."
          },
          "role": {
            "type": "string",
            "example": "Treating Physician",
            "description": "Role of the care team member being associated."
          }
      }}]
    },
    "BaseAssociation": {
      "type": "object",
      "properties": {
        "id": {
          "type": "string",
          "description": "Salesforce ID of Association"
        },
        "associationStatus": {
          "type": "string",
          "enum": [
            "Active",
            "Inactive"
          ],
          "default": "Active"
        },
        "endDate": {
          "type": "string",
          "format": "date"
        }
      }
    },
    "Program": {
      "type": "object",
      "description": "Represents a patient's enrollment and overall activity in an Engagement Program that provides services and benefits related to a pharmaceutical product or medical device.",
      "required": [
        "patientId"
      ],
      "properties": {
        "id": {
          "type": "string",
          "example": "5004100000CxItT"
        },
        "patientId": {
          "type": "string",
          "description": "Id of the patient that is enrolled into the program."
        },
        "engagementProgramId": {
          "type": "string",
          "description": "The id for the Engagement Program that the patient is enrolled in. The values set for PC_ProgramCaseRecordType__c and PC_ProgramCaseRecordTypeNamespace__c for the given engagementProgramId will be used to derive the record type of the program being created. If no values are passed, then a program case of type PC_Program is created by default."
        },
        "enrollmentDate": {
          "type": "string",
          "format": "date"
        },
        "associations": {
          "type": "array",
          "items": {
            "$ref": "#/definitions/Association"
          }
        },
        "supportCases": {
          "type": "array",
          "items": {
            "$ref": "#/definitions/SupportCase"
          }
        }
      }
    },
    "SupportCase": {
      "type": "object",
      "required": [
        "programId",
        "recordType"
      ],
      "properties": {
        "id": {
          "type": "string"
        },
        "programId": {
          "type": "string"
        },
        "recordType": {
          "type": "string",
          "description": "The record type API name.",
          "example":"<namespace>__<record type developer name>",
          "enum": [
            "PC_Alternate_Funding",
            "PC_Benefits_Investigation_Benefits_Verification",
            "PC_Copay",
            "PC_PAP",
            "PC_Prior_Authorization"
          ]
        }
      }
    },
    "Payer": {
      "type": "object",
      "required": [
        "name"
      ],
      "properties": {
        "id": {
          "type": "string"
        },
        "name": {
          "type": "string"
        },
        "status": {
          "type": "string",
          "enum": [
            "Active",
            "Inactive"
          ]
        },
        "type": {
          "type": "string"
        },
        "subType": {
          "type": "string"
        }
      }
    },
    "EngagementProgram": {
      "type": "object",
      "properties": {
        "id": {
          "type": "string"
        },
        "manufacturerId": {
          "type": "string"
        },
        "name": {
          "type": "string"
        },
        "programCode": {
          "type": "string"
        },
        "programCaseRecordType": {
          "type": "string",
          "example":"<namespace>__<record type developer name>"
        },                          
        "programCaseRecordTypeNamespace": {
          "type": "string"
        }
      }
    },
    "Manufacturer": {
      "type": "object",
      "required": [
        "name"
      ],
      "properties": {
        "id": {
          "type": "string"
        },
        "name": {
          "type": "string",
          "example": "Acme"
        },
        "description": {
          "type": "string"
        },
        "engagementPrograms": {
          "type": "array",
          "items": {
            "$ref": "#/definitions/EngagementProgram"
          }
        }
      }
    },
    "Applicant#HealthPlan": {
      "type": "object",
      "allOf": [
        {
          "$ref": "#/definitions/BaseHealthPlan"
        },
        {
          "properties": {
            "payerName": {
              "type": "string",
              "example": "ACME Health Insurance of Alaska",
              "description": "Name of the payer that provides the health plan"
            }
          }
        }
      ]
    },
    "Applicant#Address": {
      "type": "object",
      "allOf": [
        {
          "$ref": "#/definitions/BaseAddress"
        }
      ]
    },
    "Applicant": {
      "type": "object",
      "allOf": [
        {
          "$ref": "#/definitions/BasePatient"
        },
        {
          "required": [
            "engagementProgramId"
          ],
          "properties": {
            "engagementProgramId": {
              "type": "string",
              "description": "The id for the Engagement Program that the applicant is enrolling into."
            },
            "patientId": {
              "type": "string",
              "description": "The id of an existing patient if already enrolled in another program."
            },
            "physicianCity": {
              "type": "string"
            },
            "physicianEmail": {
              "type": "string"
            },
            "physicianFax": {
              "type": "string"
            },
            "physicianName": {
              "type": "string"
            },
            "physicianPhone": {
              "type": "string"
            },
            "physicianState": {
              "type": "string"
            },
            "physicianAddress1": {
              "type": "string"
            },
            "physicianAddress2": {
              "type": "string"
            },
            "physicianZipcode": {
              "type": "string"
            },
            "addresses": {
              "type": "array",
              "items": {
                "$ref": "#/definitions/Applicant#Address"
              }
            },
            "healthPlans": {
              "type": "array",
              "items": {
                "$ref": "#/definitions/Applicant#HealthPlan"
              }
            }
          }
        }
      ]
    },
    "SuspectProducts":{
      "type": "object",
      "properties": {
        "product":{
          "type" :"string",
          "description" : "The drug associated with a specific prescription."
        },
        "productStrength":{
          "type" :"string",
          "description" : "Indicates the strength of the product used by the patient during the occurrence of the adverse event."
        },
        "manufacturer":{
          "type" :"string",
          "description" : "lookup to the manufacturer account the product is associated to"
        },
        "ndc":{
          "type" :"string",
          "description" : "National Drug Code, is a universal product identifier for human drugs in the United States"
        },
        "lotNumber":{
          "type" :"string",
          "description" : "Indicates the lot number of the product used by the patient."
        },
        "concomitant":{
          "type" :"string",
          "description" : "Name of the Concomitant Medical Product and the therapy dates."
        },
        "dose":{
          "type" :"string",
          "description" : "The dosage information that caused the adverse event."
        },
        "frequency":{
          "type" :"string",
          "description" : "Frequency at which the patient used the product."
        },
        "route":{
          "type" :"string",
          "description" : "Route in which patient consumed the product."
        },
        "therapyStartDate":{
          "type" :"string",
          "format":"date",
          "description" : "Indicates the date on which the administration of the therapy started."
        },
        "therapyEndDate":{
          "type" :"string",
          "format":"date",
          "description" : "Indicates the  date on which the administration of the therapy ended."
        },
        "indicationForProductUse":{
          "type" :"string",
          "description" : "The symptom of the disease for which the product was prescribed for or used by the particular patient."
        },
        "productCompounded":{
          "type" :"string",
          "description" : "Indicates if the product was compounded.",
          "enum": [
            "Yes",
            "No"
          ]

        },
        "isProductOverTheCounter":{
          "type" :"string",
          "example":"Yes",
          "description" : "Product OTC flag.",
          "enum": [
            "Yes",
            "No"
          ]
        },
        "expirationDate":{
          "type" :"string",
          "format":"date",
          "description" : "Indicates the expiry date of the product."
        },
        "eventAbated":{
          "type" :"string",
          "example":"Yes",
          "description" : "Event Abated after use stopped or dosage reduced flag.",
          "enum": [
            "Yes",
            "No",
            "Doesn't apply"
          ]
        },
        "eventReappeared":{
          "type" :"string",
          "description" : "Event Reappeared after Reintroduction flag.",
          "enum": [
            "Yes",
            "No",
            "Doesn't apply"
          ]

        },
        "combinationProductUse":{
          "type":"string",
          "description":"Combination Product Report flag",
          "enum": [
            "Yes",
            "No"
          ]
        },
        "id": {
          "type": "string",
          "example": "a0R41000001LfAcEAK",
          "description": "Salesforce identifier. This value should be populated in PUT method, otherwise it is optional."
        },
        "adverseEventId" :{
          "type": "string",
          "example": "a0R41000001LfAcEAK",
          "description": "Salesforce identifier. This value should be populated in PUT method, otherwise it is optional."
        },
        "adverseEventId2" :{
          "type": "string",
          "example": "a0R41000001LfAcEAK",
          "description": "Salesforce identifier. This value should be populated in PUT method, otherwise it is optional."
        }
      }
    },
    "ErrorResponse": {
      "type": "object",
      "properties": {
        "message": {
          "type": "string",
          "description": "Description of the error or message from the originating exception",
          "example": "Field mapping for REST API field named 'firstNmae' was not found."
        },
        "errorType": {
          "type": "string",
          "enum": [
            "APPLICATION",
            "PATIENT_CONNECT",
            "HEALTH_CLOUD"
          ]
        },
        "errorCode": {
          "type": "string",
          "description": "An error code that defines the cause of the error",
          "example": "MISSING_FIELD_MAPPING"
        },
        "errorLogRef": {
          "type": "string",
          "description": "A reference to the Error Log record that was created",
          "example": "ERR-0001"
        }
      }
    },
    "DeleteResponse": {
      "type": "object",
      "properties": {
        "message": {
          "type": "string",
          "description": "Message delivered on successfull deletion of the object.",
          "example": "Association record was successfully deleted."
        }
      }
    },
    "OrderItem": {
      "type": "object",
      "required": [

      ],
      "properties": {
        "actualDeliveryDate": {
          "type": "string",
          "format": "date-time",
          "example": "2012-04-23T18:25:43.511Z",
          "description": "Date when the order was delivered"
        },
        "daysSupply": {
          "type": "number",
          "description": "Number of days the prescribed medication will last if taken as per the recommended dosage"
        },
        "estimatedDeliveryDate": {
          "type": "string",
          "format": "date-time",
          "example": "2012-04-23T18:25:43.511Z",
          "description": "Date when the order is expected to deliver"
        },
        "order": {
          "type": "string",
          "format": "lookup",
          "example": "<salesforce id>",
          "description": "Order associated with the order item"
        },
        "type": {
          "type": "string",
          "description": "Type of the order item",
          "enum": [
            "Informational Kits",
            "Drugs",
            "Combination Product",
            "Related Supplies"
          ]
        },
        "status": {
          "type": "string",
          "description": "Status of the order item",
          "enum": [
            "Draft",
            "Pending",
            "Submitted",
            "Shipped",
            "Delivered",
            "Entered-in-error",
            "Stopped"
          ]
        },
        "id": {
          "type": "string",
          "description": "Salesforce Id of the order item"
        },
        "packaging": {
          "type": "string",
          "description": "Type of packaging of the order item",
          "enum": [
            "Pills",
            "Bottles",
            "Cardboard Boxes",
            "Plastic Containers"
          ]
        },
        "product": {
          "type": "string",
          "format": "lookup",
          "example": "<salesforce id>",
          "description": "Product being ordered"
        },
        "quantity": {
          "type": "number",
          "format": "double",
          "description": "Quantity of the product being ordered"
        },
        "receivedBy": {
          "type": "string",
          "description": "Entity who received the order"
        },
        "shipmentTrackingNumber": {
          "type": "string",
          "description": "Unique tracking number of the order shipment"
        },
        "shipmentDate": {
          "type": "string",
          "format": "date-time",
          "example": "2012-04-23T18:25:43.511Z",
          "description": "Date when the order item is shipped"
        }
      }
    },
    "OrderItemResponse": {
      "type": "object",
      "required": [

      ],
      "allOf": [
        {
          "$ref": "#/definitions/OrderItem"
        },
        {
          "properties": {
            "ndc": {
              "type": "string",
              "description": "National Drug Code associated with the product being order"
            },
            "productDescription": {
              "type": "string",
              "description": "Description of the Product being ordered"
            },
            "strength": {
              "type": "string",
              "description": "Strength of the Drug / Product"
            },
            "orderItemNumber" : {
              "type": "string",
              "description": "Auto number generated for the order item"
            }
        }
        }]
    },
    "Order": {
      "type": "object",
      "required": [

      ],
      "properties": {
        "actualDeliveryDate": {
          "type": "string",
          "format": "date-time",
          "example": "2012-04-23T18:25:43.511Z",
          "description": "Date when the order was delivered"
        },
        "deliveryDayRun": {
          "type": "string",
          "description": "Time period when the order delivery would be done",
          "enum": [
            "Same Day Delivery",
            "2 Day Delivery",
            "Weekend Delivery"
          ]
        },
        "estimatedDeliveryDate": {
          "type": "string",
          "format": "date-time",
          "example": "2012-04-23T18:25:43.511Z",
          "description": "Date when the order is expected to deliver"
        },
        "id": {
          "type": "string",
          "description": "Salesforce id of the Order"
        },
        "instructions": {
          "type": "string",
          "format": "long text",
          "description": "Instructions for the order or delivery"
        },
        "status": {
          "type": "string",
          "enum": [
            "Draft",
            "Pending",
            "Submitted",
            "Shipped",
            "Delivered",
            "Entered-in-error",
            "Stopped"
          ],
          "description": "Status of the order"
        },
        "type": {
          "type": "string",
          "enum": [
            "Bridge Program",
            "PAP",
            "Sample Products",
            "Enrollment Package",
            "Home Infusion Training set"
          ],
          "description": "Type of order"
        },
        "preferredDeliveryDate": {
          "type": "string",
          "format": "date-time",
          "example": "2012-04-23T18:25:43.511Z",
          "description": "Date when the order recipient prefers to receive the shipment"
        },
        "preferredDeliveryWindow": {
          "type": "string",
          "enum": [
            "Anytime",
            "8:00AM - Noon",
            "Noon - 4:00PM",
            "4:00PM - 8:00PM"
          ],
          "description": "Time when the order recipient prefers to receive the shipment"
        },
        "prescription": {
          "type": "string",
          "format": "lookup",
          "example": "<salesforce id>",
          "description": "Prescription the order is submitted for"
        },
        "programCase": {
          "type": "string",
          "format": "lookup",
          "example": "<salesforce id>",
          "description": "Program case the order is related to"
        },
        "receivedBy": {
          "type": "string",
          "format": "text area",
          "description": "Entity who received the order"
        },
        "shipTo": {
          "type": "string",
          "format": "lookup",
          "example": "<salesforce id>",
          "description": "Entity whom the order is being shipped to"
        },
        "shipmentTrackingNumber": {
          "type": "string",
          "format": "text area",
          "description": "Unique tracking number of the order shipment"
        },
        "shippingDate": {
          "type": "string",
          "format": "date-time",
          "example": "2012-04-23T18:25:43.511Z",
          "description": "Date when the order is shipped"
        },
        "submittedDate": {
          "type": "string",
          "format": "date-time",
          "example": "2012-04-23T18:25:43.511Z",
          "description": "Date when the request of order was submitted"
        }
      }
    },
    "OrderResponse": {
      "type": "object",
      "required": [

      ],
      "allOf": [
        {
          "$ref": "#/definitions/Order"
        },
        {
          "properties": {
            "address1": {
              "type": "string",
              "description": "First line of the primary address of ‘Ship To’ Account"
            },
            "address2": {
              "type": "string",
              "description": "Second line of the primary address of ‘Ship To’ Account"
            },
            "address3": {
              "type": "string",
              "description": "Third line of the primary address of ‘Ship To’ Account"
            },
            "city": {
              "type": "string",
              "description": "City of the primary address of ‘Ship To’ Account"
            },
            "orderNumber": {
              "type": "string",
              "format": "autonumber",
              "example": "autonumber",
              "description": "Autonumber generated for the order"
            },
            "orderState": {
              "type": "string",
              "description": "State of the primary address of ‘Ship To’ Account"
            },
            "orderZipCode": {
              "type": "string",
              "description": "Zip code of the primary address of ‘Ship To’ Account"
            },
            "orderNumber" : {
              "type": "string",
              "description": "Auto number generated for the order"
            }
      }}]
    },
    "OrderWithOrderItems": {
      "type": "object",
      "allOf": [
        {
          "$ref": "#/definitions/Order"
        },
        {
          "properties": {
            "orderItems": {
              "type": "array",
              "items": {
                "$ref": "#/definitions/OrderItem"
              }
            }
          }
        }
      ]
    },
    "OrderWithOrderItemsResponse": {
      "type": "object",
      "allOf": [
        {
          "$ref": "#/definitions/OrderResponse"
        },
        {
          "properties": {
            "orderItems": {
              "type": "array",
              "items": {
                "$ref": "#/definitions/OrderItemResponse"
              }
            }
          }
        }
      ]
    }
  },
  "basePath": "/services/apexrest/{PC_Namespace}/1.0",
  "host": "<your_salesforce_domain>"
}
