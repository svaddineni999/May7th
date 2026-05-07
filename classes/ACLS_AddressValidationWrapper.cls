/*********************************************************************************
    Class Name     : ACLS_AddressValidationWrapper
    Description    : Prepares the data to get the MelissaAddress response
    Return Type    : 
    Varaibles      : CampaignName,State,PhoneNumber,MessageText
    *********************************************************************************/
public with sharing class ACLS_AddressValidationWrapper {
    public List<Records> Records;
	public String TotalRecords;
	public String TransmissionReference;
	public String TransmissionResults;
	public String Version;

	public class Records {
		
		public String AddressKey;
		public String AddressLine1;
		public String AddressLine2;
		public String AddressLockBox;
		public String AddressPostDirection;
		public String AddressPreDirection;
		public String AddressPrivateMailboxName;
		public String AddressPrivateMailboxRange;
		public String AddressRouteService;
		public String AddressStreetName;
		public String AddressStreetSuffix;
		public String AddressSuiteName;
		public String AddressSuiteNumber;
		public String AddressTypeCode;
		public String AreaCode;
		public String City;
		public String CountryCode;
		public String CountryName;
		public String MelissaAddressKey;
		public String MelissaAddressKeyBase;
		public String PostalCode;
		public String RecordID;
		public String Reserved;
		public String Results;
		public String State;
		
	}

	
	
}