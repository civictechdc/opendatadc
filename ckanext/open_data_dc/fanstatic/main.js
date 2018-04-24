$("#side-panel-open").click(function(){
    $('.side-panel').width('300px');
    //$('.main').css('margin-left', '300px');
    //$('.navbar').css('margin-left', '300px');
    // $('#side-panel-open').hide();
});

$("#side-panel-close").click(function(){
    $('.side-panel').width('0');
    //$('.main').css('margin-left', '0');
    //$('.navbar').css('margin-left', '0');
    // $('#side-panel-open').show();
});

var substringMatcher = function(strs) {
    return function findMatches(q, cb) {
      var matches, substringRegex;
  
      // an array that will be populated with substring matches
      matches = [];
  
      // regex used to determine if a string contains the substring `q`
      substrRegex = new RegExp(q, 'i');
  
      // iterate through the pool of strings and for any string that contains the substring `q`, add it to the `matches` array
      $.each(strs, function(i, str) {
        if (substrRegex.test(str)) {
          matches.push(str);
        }
      });
  
      cb(matches);
    };
  };
  
  var states = ['Alabama', 'Alaska', 'Arizona', 'Arkansas', 'California',
    'Colorado', 'Connecticut', 'Delaware', 'Florida', 'Georgia', 'Hawaii',
    'Idaho', 'Illinois', 'Indiana', 'Iowa', 'Kansas', 'Kentucky', 'Louisiana',
    'Maine', 'Maryland', 'Massachusetts', 'Michigan', 'Minnesota',
    'Mississippi', 'Missouri', 'Montana', 'Nebraska', 'Nevada', 'New Hampshire',
    'New Jersey', 'New Mexico', 'New York', 'North Carolina', 'North Dakota',
    'Ohio', 'Oklahoma', 'Oregon', 'Pennsylvania', 'Rhode Island',
    'South Carolina', 'South Dakota', 'Tennessee', 'Texas', 'Utah', 'Vermont',
    'Virginia', 'Washington', 'West Virginia', 'Wisconsin', 'Wyoming'
  ];
  
  var ckanTags = ["GIS", "Transportation", "Transit", "Education", "Locations", "Streets", "Schools", "Housing", "Public Services", "Infrastructure", "Budget", "Zoning", "Boundaries", "Procurement", "Transparency", "Office of Contracti...", "Census", "Accountability", "Purchase Orders", "PO", "Health", "Financials", "DCPS", "Government Operation", "Traffic", "Tourism", "Real Estate", "Environment", "DC", "Criminal Justice", "Planning", "OCTO", "Historical", "Broadband", "Wards", "USDA", "Summer", "Poverty", "OSSE", "HUD", "Elections", "ERS", "Buildings", "Roads", "Public Health", "Points", "Districts", "Athletics", "ACS", "2010"
  ];
  
  $('#the-basics .typeahead').typeahead({
    hint: true,
    highlight: true,
    minLength: 1
  },
  {
    name: 'ckanTags',
    source: substringMatcher(ckanTags)
  });