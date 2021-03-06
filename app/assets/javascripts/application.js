// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/sstephenson/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require 'blacklight_advanced_search'

//= require jquery_ujs
//
// Required by Blacklight
//= require blacklight/blacklight
//= require_tree ./global

//= require underscore-min


//= require handlebars.runtime
//= require_tree ./templates
//= require handlebars.helpers

//= require jquery.plug-google-content

//= require bootstrap/tooltip
//= require bootstrap/popover
//= require infobox

//= require analytics



// For blacklight_range_limit built-in JS, if you don't want it you don't need
// this:
//= require 'blacklight_range_limit'


// Shelf-Browse
//= require 'jquery.stackview.min.js'


// ==========================
// General utility functions
// ==========================
window.josiahObject = {};
window.josiahObject.getUrlParameter = function(param) {
  var url = window.location.search.substring(1);
  var params = url.split('&');
  var i, tokens;
  for (var i = 0; i < params.length; i++) {
    tokens = params[i].split('=');
    if (tokens[0] == param) {
      return tokens[1];
    }
  }
  return null;
}

// Source: https://www.w3schools.com/howto/howto_js_sort_table.asp
window.josiahObject.sortHtmlTable = function(tableId, colNumber) {
  var table = document.getElementById(tableId);
  var rows = table.rows;
  var th = rows[0].getElementsByTagName("TH")[colNumber];
  var descending = (th.dataset.sortDirection == "desc");
  var i, xElement, yElement, x, y, shouldSwitch;
  var switching = true;

  while (switching) {

    switching = false;
    rows = table.rows;

    // Loop through all the table rows
    // (except the first, which contains the headers)
    for (i = 1; i < (rows.length - 1); i++) {

      shouldSwitch = false;

      // Get the two elements to compare (current row and next row)
      xElement = rows[i].getElementsByTagName("TD")[colNumber];
      yElement = rows[i + 1].getElementsByTagName("TD")[colNumber];
      if (xElement.dataset.hasOwnProperty("sortByNumber")) {
          x = parseInt(xElement.dataset.sortByNumber, 10);
          y = parseInt(yElement.dataset.sortByNumber, 10);
      } else {
          x = xElement.dataset.sortByText.toLowerCase();
          y = yElement.dataset.sortByText.toLowerCase();
      }

      // console.log(i.toString() + " " + x.toString() + " " + y.toString());

      // Check if the two rows should switch place, and
      // if so, mark as a switch and break the loop
      if (descending) {
        if (x < y) {
            shouldSwitch = true;
            break;
        }
      } else {
        if (x > y) {
            shouldSwitch = true;
            break;
        }
      }
    } // for

    if (shouldSwitch) {
      // If a switch has been marked, make the switch
      // and loop again
      rows[i].parentNode.insertBefore(rows[i + 1], rows[i]);
      switching = true;
    }
  } // while

  // Reverse the sorting direction for the next round.
  if (descending) {
      th.dataset.sortDirection = "asc";
  } else {
      th.dataset.sortDirection = "desc";
  }
}

window.josiahObject.setupSortColumn = function (tableId, colNumber, direction, defaultSort) {
  var header = document.getElementById(tableId).rows[0];
  var column = header.getElementsByTagName("TH")[colNumber];
  var columnId = tableId + "_col_" + colNumber.toString();
  var sortLink = "<a href='#' id='" + columnId + "' title='Click to sort'>" + column.innerHTML + "</a>";
  var sortIcon;

  if (defaultSort) {
      sortIcon = "<span style='font-size: 12px;' class='glyphicon glyphicon-sort'></span>";
  } else {
      sortIcon = "<span style='font-size: 12px;' class='hidden glyphicon glyphicon-sort'></span>";
  }

  // Sets the default sort direction for the column,
  // adds a link to the header to allow user to click to sort,
  // and wire the link to call the sortTable() function.
  column.setAttribute("data-sort-direction", direction);
  column.innerHTML = sortLink + "&nbsp;" + sortIcon;
  $("#" + columnId).on("click", function(e) {
      var i, th;
      e.preventDefault();
      // Sort the data...
      window.josiahObject.sortHtmlTable(tableId, colNumber);
      // ...and make sure this column is marked as the one we are sorting on
      for(i = 0; i < header.getElementsByTagName("TH").length; i++) {
          th = header.getElementsByTagName("TH")[i]
          if (i == colNumber) {
              $(th).find("span").removeClass("hidden");
          } else {
              $(th).find("span").addClass("hidden");
          }
      }
  });
}

function getUrlParameterFromString(url, param) {
  var params = url.split('&');
  var i, tokens;
  for (var i = 0; i < params.length; i++) {
    tokens = params[i].split('=');
    if (tokens[0] == param) {
      return tokens[1];
    }
  }
  return null;
}

// ------------------------------
// Functions used to display the option to Scan an
// item or request it.

// Only items from the Annex that are books and periodical
// titles can be requested.
// I think we might need to add a check on "status" since
// only Available items can be requested.
// See https://github.com/Brown-University-Library/easyscan/blob/391cbef95f4731894a0b0b30cf15f062263fd77e/easyscan_app/lib/josiah_easyscan.js#L214-L224
function canScanItem(location, format, status) {
  var location = (location || "").toLowerCase();
  var format = (format || "").toLowerCase();
  var status = (status || "").toLowerCase();

  if (status != "available") {
    return false;
  }

  if (location != "annex") {
    return false;
  }

  if ((format != "book") && (format != "periodical title")) {
    return false;
  }
  return true;
}


function easyScanFullLink(scanLink, bib, title) {
  return scanLink + '&title=' + title + '&bibnum=' + bib;
}


function itemRequestFullLink(barCode, bib, itemId) {
  var baseUrl = "https://library.brown.edu/easyrequest/login/";
  return baseUrl + "?bibnum=" + bib + "&barcode=" + barCode + "&itemnum=" + itemId;
}


// Returns true if the "item is requestable".
//
// Parameter itemData has following properties:
//    requestableBib:     Value from Sierra whether the BIB record is marked as requestable (boolean)
//    reopeningLocations: Locations where requesting is allowed (array of strings)
//    location:           Location of the item to validate (string)
//    status:             Status of the item to validate (string)
function canRequestItem(itemData) {
  var status;
  if (itemData.requestableBib === true) {
    status = itemData.status;
    if (status.includes("HOLD") || status.includes("MISSING") || status.includes("DUE ")) {
      return false;
    }
    return itemData.reopeningLocations.includes(itemData.location)
  }
  return false;
}

/*
============================================================
JCB Aeon link code
============================================================
Reference Josiah pages:
- `JCB`: <http://127.0.0.1:3000/catalog/b3902979>
- `JCB REF`: <http://127.0.0.1:3000/catalog/b6344512>
- `JCB VISUAL MATERIALS`: <http://127.0.0.1:3000/catalog/b5660654>
- `JCB - multiple copies`: <http://127.0.0.1:3000/catalog/b2223864>
- Very-long-title handling: <http://127.0.0.1:3000/catalog/b5713050>  */

function jcbRequestFullLink( bib, title, author, publisher, callnumber ) {
  // console.log( 'starting' )
  var jcb_ref_num = bib;
  var jcb_title = extractTitle( title );
  var jcb_author = extractAuthor( author );
  var jcb_publisher = publisher;  // pre-sliced
  var jcb_callnumber = encodeURIComponent(callnumber);
  return "https://jcbl.aeon.atlas-sys.com/aeon.dll?Action=10&Form=30&ReferenceNumber=" + jcb_ref_num + "&ItemTitle=" + jcb_title + "&ItemAuthor=" + jcb_author + "&ItemPublisher=" + jcb_publisher + "&CallNumber=" + jcb_callnumber + "&ItemInfo2=";
  // var full_url = "https://jcbl.aeon.atlas-sys.com/aeon.dll?Action=10&Form=30&ReferenceNumber=" + jcb_ref_num + "&ItemTitle=" + jcb_title + "&ItemAuthor=" + jcb_author + "&ItemPublisher=" + jcb_publisher + "&CallNumber=" + jcb_callnumber + "&ItemInfo2=";
  // console.log( '- returning full_url value of, ```' + full_url + '```' )
  // return full_url;
}

/*
END JCB link code
=================  */


/*
============================================================
Hay Aeon link code
============================================================
Note: initially very similar to JCB link code, but I (bjd) expect this to end up being different
Reference Josiah pages: TODO- update these to search.library.brown.edu urls
- `HAY BROADSIDES` - regular: <http://127.0.0.1:3000/catalog/b3326323>
- `HAY BROADSIDES` - multiple 'HAY BROADSIDES' copies: <http://127.0.0.1:3000/catalog/b3000585>
- `HAY STAR & HAY LINCOLN` - multiple copies, mixture of two: <http://127.0.0.1:3000/catalog/b1870356>
- `HAY STAR` - very-long-title handling: <http://127.0.0.1:3000/catalog/b1001443>
- `HAY MANUSCRIPTS` - updated 2019-July; Aeon link now should appear: <http://127.0.0.1:3000/catalog/b2499606>
- multiple results page: <http://127.0.0.1:3000/catalog?utf8=%E2%9C%93&search_field=all_fields&q=The+capture+of+Jefferson+Davis>  */

function hayAeonFullLink( bib, title, author, publisher, callnumber, location ) {
  if((typeof window.isCovid !== 'undefined') && (window.isCovid !== null) && (window.isCovid)) {
    return "https://brown.libanswers.com/form?queue_id=3794";
  }

  /* called by catalog_record_availability.js */
  // console.log( '- starting hayAeonFullLink()' );
  var hayA_root_url = "https://brown.aeon.atlas-sys.com/logon/";
  var hayA_ref_num = bib;
  var hayA_title = extractTitle( title );
  var hayA_author = extractAuthor( author );
  var hayA_publisher = publisher;  // pre-sliced
  var hayA_callnumber = encodeURIComponent(callnumber);
  var hayA_location = location;
  var full_url = hayA_root_url + "?Action=10&Form=30" + "&ReferenceNumber=" + hayA_ref_num + "&ItemTitle=" + hayA_title + "&ItemAuthor=" + hayA_author + "&ItemPublisher=" + hayA_publisher + "&CallNumber=" + hayA_callnumber + "&Location=" + hayA_location + "&ItemInfo2=";
  // console.log( '- returning full_url value of, ```' + full_url + '```' )
  return full_url;
}

/*
END Hay Aeon link code
======================  */


/*
============================================================
easyRequest-Hay Aeon link code
============================================================
Note: initially very similar to JCB link code, but I (bjd) expect this to end up being different
Reference Josiah pages: TODO- update these to search.library.brown.edu urls
- `HAY BROADSIDES` - regular: <http://127.0.0.1:3000/catalog/b3326323>
- `HAY BROADSIDES` - multiple 'HAY BROADSIDES' copies: <http://127.0.0.1:3000/catalog/b3000585>
- `HAY STAR & HAY LINCOLN` - multiple copies, mixture of two: <http://127.0.0.1:3000/catalog/b1870356>
- `HAY STAR` - very-long-title handling: <http://127.0.0.1:3000/catalog/b1001443>
- `HAY MANUSCRIPTS` - updated 2019-July; Aeon link now should appear: <http://127.0.0.1:3000/catalog/b2499606>
- multiple results page: <http://127.0.0.1:3000/catalog?utf8=%E2%9C%93&search_field=all_fields&q=The+capture+of+Jefferson+Davis>  */

function easyrequestHayFullLink( bib, barcode, title, author, publisher, callnumber, location ) {
  /* called by catalog_record_availability.js */
  // console.log( '- starting easyrequestHayFullLink()' );
  var ezRqHay_root_url = "https://library.brown.edu/easyrequest_hay/confirm/"
  var ezRqHay_bib = bib;
  var ezRqHay_barcode = barcode;
  var ezRqHay_title = extractTitle( title );
  var ezRqHay_author = extractAuthor( author );
  var ezRqHay_publisher = publisher;  // pre-sliced
  var ezRqHay_callnumber = encodeURIComponent(callnumber);
  var ezRqHay_location = location;
  var ezRqHay_full_url = ezRqHay_root_url + "?item_bib=" + ezRqHay_bib + "&item_barcode=" + ezRqHay_barcode + "&item_title=" + ezRqHay_title + "&item_author=" + ezRqHay_author + "&item_publisher=" + ezRqHay_publisher + "&item_callnumber=" + ezRqHay_callnumber + "&item_location=" + ezRqHay_location + "&item_digital_version_url=" + "" + "&referring_url=https%3A%2F%2Fsearch.library.brown.edu%2Fcatalog%2F" + ezRqHay_bib;
  return ezRqHay_full_url;
}

function isValidHayAeonLocation( josiah_location ) {
  /* called by catalog_record_availability.js */
  var hay_found = false;

  // original code...
  var non_aeon_locations = hay_aeon_exclusions;  // hay_aeon_exclusions is a global var loaded from app/views/layouts/blacklight.html.erb
  // console.log( '- INITIAL non_aeon_locations, ```' + non_aeon_locations + '```' )

  /* TEMP CODE
     TODO: before moving to production, restore the code above after...
     - removing "HAY MANUSCRIPTS" from <https://library.brown.edu/hay_aeon_exclusions/hay_aeon_exclusions.js>
     */
  // console.log( 'josiah_location being evaluated, `' + josiah_location + '`' );
  // console.log( '- INITIAL non_aeon_locations, ```' + hay_aeon_exclusions + '```' )
  // var non_aeon_locations = hay_aeon_exclusions.filter(
  //   function( value, index, arr ){
  //     if (value != "HAY MANUSCRIPTS") {
  //       return value;
  //     }
  //   }
  // );
  //
  // non_aeon_locations.push( "HAY MICROFILM" );
  // non_aeon_locations.push( "HAY MICROFLM" );  // spelling not a mistake; see <https://search.library.brown.edu/catalog/b2734709>
  // non_aeon_locations.push( "HAY JOHN-HAY" );
  // console.log( '- non_aeon_locations, ```' + non_aeon_locations + '```' )
  // END OF TEMP CODE

  // console.log( '- josiah_location, ```' + josiah_location + '```' )
  if ( josiah_location.slice(0, 3) == "HAY" ){
    var index_of_val = non_aeon_locations.indexOf( josiah_location );
    if ( index_of_val == -1 ) {
      hay_found = true;
      // console.log( 'hay_found, `' + hay_found + '`' )
    }
  } else if ( josiah_location == "HMCF" || josiah_location == "HJH" ) {
    hay_found = true;
  }
  // console.log( 'hay_found determination, `' + hay_found + '`' );
  return hay_found;
}

/*
END easyRequest-Hay Aeon link code
==================================  */


/*
============================================================
common Aeon link code
============================================================  */

function extractTitle( title ) {
  var t = title;
  if ( title.length > 100 ) {
    t = title.slice( 0, 97 ) + "..."; }
  return t;
}

function extractAuthor( author ) {
  var a = author;
  if ( author.length > 100 ) {
    a = author.slice( 0, 97 ) + "..."; }
  return a;
}

/*
END common link code
====================  */
