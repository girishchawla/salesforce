public class GeocodeAddressDistance {
    
    private static Boolean geocodingCalled = false;
    // wrapper method to prevent calling future
    //methods from an existing future context
    
    
    public static void DoAddressGeocode(id
                                        addressId) {
                                            if
                                                (geocodingCalled || System.isFuture()) {
                                                    System.debug(LoggingLevel.WARN,
                                                                 '***Address Geocoding Future Method Already Called - Aborting...');
                                                    return;
                                                }
                                            
                                            //if not being called from future context, geocode the address
                                            geocodingCalled = true;
                                            
                                            geocodeAddress(addressId);
                                        }
    
    // we need a future method to call Google
    //Geocoding API from Salesforce
    @future (callout=true)
    static private void geocodeAddress(id addressId)
    { 
        // Key
        //for Google Maps Geocoding API
        String geocodingKey = 'API_KEY';
        
        // get
        //the passed in address
        AddressDistance__c geoAddress = [SELECT Street__c, City__c, State__c, Country__c,
                                         Zip__c, distanceFrom__c, Geo__c
                                         FROM
                                         AddressDistance__c
                                         WHERE
                                         id = :addressId];
        
        
       
        //create a string for the address to pass to Google Geocoding API
        String geoAddressString = '';
        if
            (geoAddress.Street__c != null)
            geoAddressString
            += geoAddress.Street__c + ', ';
        if
            (geoAddress.City__c != null)
            geoAddressString
            += geoAddress.City__c + ', ';
        if
            (geoAddress.State__c != null)
            geoAddressString
            += geoAddress.State__c + ', ';
        if
            (geoAddress.Country__c != null)
            geoAddressString
            += geoAddress.Country__c + ', ';
        if
            (geoAddress.Zip__c != null)
            geoAddressString
            += geoAddress.Zip__c;
        
        
        //
        //encode the string so we can pass it as part of URL
        geoAddressString = EncodingUtil.urlEncode(geoAddressString, 'UTF-8');
        
        //
        //build and make the callout to the Geocoding API
        Http http = new Http();
        
        HttpRequest request = new HttpRequest();
        
        request.setEndpoint('https://maps.googleapis.com/maps/api/geocode/json?address='
                            +
                            geoAddressString + '&key=' + geocodingKey
                            + '&sensor=false');
        request.setMethod('GET');
        request.setTimeout(60000);
        try {
            //
            //make the http callout
            HttpResponse response = http.send(request);
            
            //
            //parse JSON to extract co-ordinates
            JSONParser responseParser = JSON.createParser(response.getBody());
            
            //
            //initialize co-ordinates
            double latitude = null;
            
            double longitude = null;
            
            while
                (responseParser.nextToken() != null) {
                    if
                        ((responseParser.getCurrentToken() == JSONToken.FIELD_NAME) &&
                         (responseParser.getText()
                          == 'location')) {
                              responseParser.nextToken();
                              while
                                  (responseParser.nextToken() != JSONToken.END_OBJECT) {
                                      
                                      String locationText = responseParser.getText();
                                      
                                      responseParser.nextToken();
                                      
                                      if (locationText == 'lat')
                                          
                                          latitude = responseParser.getDoubleValue();
                                      
                                      else if (locationText == 'lng')
                                          
                                          longitude = responseParser.getDoubleValue();
                                  }
                          }
                }
            //
            //update co-ordinates on address if we get them back
            if(latitude != null) {
                geoAddress.Geo__Latitude__s
                        = latitude;
                geoAddress.Geo__Longitude__s
                        = longitude;
                update geoAddress;       
                    
            }
            Location addressGeo = Location.newInstance(latitude,longitude);
            System.debug(LoggingLevel.WARN,
                             'Geocoding Address - '+ geoAddress.Geo__c + ' distance ' + geoAddress.distanceFrom__c);
            updateContactInfo(addressGeo, geoAddress.distanceFrom__c);    
            updateLeadInfo(addressGeo, geoAddress.distanceFrom__c);   
            updateAccountInfo(addressGeo, geoAddress.distanceFrom__c);   
            
            
            
            
            } catch (Exception e) {
                    System.debug(LoggingLevel.ERROR,
                             'Error Geocoding Address - ' + e.getMessage());
            }
    }    
    
    
    static private void updateContactInfo(Location a, Decimal d) 
    {
        
        List<Contact> updatedContacts = new List<Contact>();
        
        
        try{ for(Contact c : [SELECT Id,  distance__c, MailingLatitude, MailingLongitude FROM Contact])
        {
            //Decimal distance_l = GeocodeAddressDistance.calculateDistance(latitude, longitude, c.Location__Latitude__s,c.Location__Longitude__s);
            Location cloc = Location.newInstance(c.MailingLatitude, c.MailingLongitude);
            Double distance_l = Location.getDistance(a, cloc, 'mi');
            
            System.debug(LoggingLevel.DEBUG,'***Geocoding Distance - ' + distance_l);
            
            
            //Decimal distance_l = DISTANCE(a, c.Location__c, 'mi');
            if( distance_l <= d)
            {   
                c.distance__c = distance_l;
            }    
            else
            {
                c.distance__c = 0.0;
            }    
            updatedContacts.add(c);
        }
            update updatedContacts; 
            
           }
        
        catch(exception e){
            throw e;
        }
    }    
    
 static private void updateLeadInfo(Location a, Decimal d) 
    {
        
        List<Lead> updatedLeads = new List<Lead>();
        
        
        try{ for(Lead c : [SELECT Id,  distance__c, Latitude, Longitude FROM Lead])
        {
            //Decimal distance_l = GeocodeAddressDistance.calculateDistance(latitude, longitude, c.Location__Latitude__s,c.Location__Longitude__s);
            Location cloc = Location.newInstance(c.Latitude, c.Longitude);
            Double distance_l = Location.getDistance(a, cloc, 'mi');
            
            System.debug(LoggingLevel.DEBUG,'***Geocoding Distance - ' + distance_l);
            
            
            //Decimal distance_l = DISTANCE(a, c.Location__c, 'mi');
            if( distance_l <= d)
            {   
                c.distance__c = distance_l;
            }    
            else
            {
                c.distance__c = 0.0;
            }    
            updatedLeads.add(c);
        }
            update updatedLeads; 
            
           }
        
        catch(exception e){
            throw e;
        }
    }    
     
    static private void updateAccountInfo(Location a, Decimal d) 
    {
        
        List<Account> updatedAccounts = new List<Account>();
        
        
        try{ for(Account c : [SELECT Id,  distance__c, BillingLatitude, BillingLongitude FROM Account])
        {
            //Decimal distance_l = GeocodeAddressDistance.calculateDistance(latitude, longitude, c.Location__Latitude__s,c.Location__Longitude__s);
            Location cloc = Location.newInstance(c.BillingLatitude, c.BillingLongitude);
            Double distance_l = Location.getDistance(a, cloc, 'mi');
            
            System.debug(LoggingLevel.DEBUG,'***Geocoding Distance - ' + distance_l);
            
            
            //Decimal distance_l = DISTANCE(a, c.Location__c, 'mi');
            if( distance_l <= d)
            {   
                c.distance__c = distance_l;
            }    
            else
            {
                c.distance__c = 0.0;
            }    
            updatedAccounts.add(c);
        }
        update updatedAccounts; 
            
       }
        
        catch(exception e){
            throw e;
        }
    }    
    
}