/*
- Displays availability status of all items for given bib.
  - Grabs bib_id from dom.
  - Hits availability api.
  - Builds html & inserts it into dom.
- Loaded by `app/views/catalog/show.html.erb`.
*/

$(document).ready(
  function(){
    var bib_id = getBibId();
    var api_url = availabilityService + bib_id + "/?callback=?";
    var limit = getUrlParameter("limit");
    if (limit == "false") {
      api_url = api_url + "&limit=false"
    }
    $.getJSON(api_url, addAvailability);

    if (location.search.indexOf("nearby") > -1) {
      findNearbyItems(bib_id);
    }
  }
);

function getBibId() {
  /* Pulls bib_id from DOM.
   * Called on doc.ready */
  bib_id_div_name = $( "div[id^='doc_']" )[0].id;
  bib_id_start = bib_id_div_name.search( '_' ) + 1;
  bib_id = bib_id_div_name.substring( bib_id_start );
  return bib_id;
}

function getTitle() {
  return $('h3[itemprop="name"]').text();
}

function getFormat() {
  return $("dd.blacklight-format").text().trim();
}

function processItems(availabilityResponse) {
  var out = []
  $.each(availabilityResponse.items, function( index, item ) {
    var loc = item['location'].toLowerCase();
    out.push(item);
  });
  var rsp = availabilityResponse;
  return rsp;
}

function hasItems(availabilityResponse) {
  return (availabilityResponse.items.length > 0);
}

function addAvailability(availabilityResponse) {
  var title = getTitle();
  var bib = getBibId();
  var format = getFormat();
  //check for request button
  addRequestButton(availabilityResponse)
  //do realtime holdings
  context = availabilityResponse;
  context['book_title'] = title;
  if (hasItems(availabilityResponse)) {
    _.each(context['items'], function(item) {

      // add title to map link.
      item['map'] = item['map'] + '&title=' + title;

      // add bookplate information
      // item_info() is defined in _show_default.html.erb
      var bookplate = item_info(item['barcode'])
      if (bookplate != null) {
        item['bookplate_url'] = bookplate.url;
        item['bookplate_display'] = bookplate.display;
      }

      //add easyScan link & item request
      if (canScanItem(item['location'], format)) {
        item['scan'] = easyScanFullLink(item['scan'], bib, title);
        item['item_request_url'] = itemRequestFullLink(item['barcode'], bib);
      } else {
        item['scan'] = null;
        item['item_request_url'] = null;
      }
    });
  }

  if (context['has_more'] == true) {
    context['more_link'] = window.location.href + '?limit=false';
  }
  //turning off for now.
  context['show_ezb_button'] = false;
  if (availabilityResponse.requestable) {
    context['request_link'] = requestLink();
  };
  //context['openurl'] = openurl
  html = HandlebarsTemplates['catalog/catalog_record_availability_display'](context);
  $("#availability").append(html);
}

function browseShelfUri(id) {
  // josiahRootUrl is defined in shared/_header_navbar.html.erb
  return josiahRootUrl + "api/items/nearby?id=" + id;
}

function callnumbers_text(callnumbers) {
  if (!callnumbers) {
    return "";
  }
  var text = " (";
  var count = count = callnumbers.length;
  var i;
  for(i=0; i < count; i++) {
    text += callnumbers[i];
    text += (i < (count-1)) ? ", " : "";
  }
  text += ")";
  return text;
}

function findNearbyItems(id) {
  $.ajax({
      type: "GET",
      url: browseShelfUri(id),
      success: function(data) {
        renderNearbyItems(data.documents);
      }
  });
}

function renderNearbyItems(items) {
  var i, doc, link;
  var docs = [];
  var useCovers = location.search.indexOf("nearbycovers") > -1;
  for(i = 0; i < items.length; i++) {
    link = josiahRootUrl + "catalog/" + items[i].id;
    link += useCovers ? "?nearbycovers" : "?nearby";
    doc = {
      title: items[i].title,
      creator: [items[i].author],
      measurement_page_numeric: items[i].pages,
      measurement_height_numeric: items[i].height,
      shelfrank: items[i].highlight ? 50 : 15,
      pub_date: items[i].year,
      link: link,
      isbn: items[i].isbn
    };
    docs.push(doc);
  }

  if (useCovers) {
    renderGalleryView(docs);
  } else {
    renderStackView(docs);
  }
}

function renderGalleryView(docs) {
  var i, isbn, doc, link, docDiv;
  var rootEl = $("#documents");
  var isbns = "";
  for(i = 0; i < docs.length; i++) {
    doc = docs[i];
    isbn = "ISBN" + doc.isbn;
    link = '<a href="' + doc.link + '">' + doc.title + '</a>';
    isbns += isbn;
    if (i < (docs.length-1)) {
      isbns += ",";
    }
    docDiv = '<div class="document col-xs-6 col-md-3">';
    docDiv += link
    docDiv += '<img id="' + isbn + '" class="cover-image " src="/assets/sampleCover.png" height="189" width="128" src="" data-isbn="' + isbn + '">';
    docDiv += '<span id="PLACEHOLDER_' + isbn + '"></span>';
    docDiv += '</div>';
    $(rootEl).append(docDiv)
  }
  requestBookcovers(isbns);
}

function renderStackView(docs) {
  var data = {
    "start": "-1",
    "limit": "0",
    "num_found": docs.length,
    "docs":docs
  };
  $('#basic-stack').stackView({data: data, ribbon: null});
}

function requestLink() {
  var bib = getBibId();
  return 'https://josiah.brown.edu/search~S7?/.' + bib + '/.' + bib + '/%2C1%2C1%2CB/request~' + bib;
}

function addRequestButton(availabilityResponse) {
  //ugly Josiah request url.
  //https://josiah.brown.edu/search~S7?/.b2305331/.b2305331/1%2C1%2C1%2CB/request~b2305331
  if (availabilityResponse.requestable) {
    var bib = getBibId();
    var url = 'https://josiah.brown.edu/search~S7?/.' + bib + '/.' + bib + '/%2C1%2C1%2CB/request~' + bib;
    //$('#sidebar ul.nav').prepend('<li><a href=\"' + url + '\">Request this</a></li>');
  };
}


function getUrlParameter(sParam)
{
    var sPageURL = window.location.search.substring(1);
    var sURLVariables = sPageURL.split('&');
    for (var i = 0; i < sURLVariables.length; i++)
    {
        var sParameterName = sURLVariables[i].split('=');
        if (sParameterName[0] == sParam)
        {
            return sParameterName[1];
        }
    }
}

function requestBookcovers(isbns) {
  var booksApiUrl = '//books.google.com/books?jscmd=viewapi&bibkeys=' + isbns;

  $.ajax({
    type: 'GET',
    url: booksApiUrl,
    async: false,
    contentType: "application/json",
    dataType: 'jsonp',

    success: function(json) {
      $.each(json, function(id, data) {
        if (data.thumbnail_url != undefined) {
          var thumbUrl = data.thumbnail_url;
          thumbUrl = thumbUrl.replace(/zoom=5/, 'zoom=1');
          thumbUrl = thumbUrl.replace(/&?edge=curl/, '');
          var imgEl = $("#" + id);
          imgEl.attr('src', thumbUrl);
        }
      });
    },
    error: function(e) {
      console.log(e);
    }
  });

}
