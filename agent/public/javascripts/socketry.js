// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

var lastInMessageID = null;
var updateInMessages = null; // function with 1 parameter

var unsentMessageCount = [];
var updateUnsentMessages = null; // function with 1 parameter

var sentMessageCount = [];
var updateSentMessages = null; // function with 1 parameter

var trackedInAttachmentIDs = [];
var updateTrackedInAttachment = null; // function with 1 parameter

var downloadCount = null;
var updateDownloads = null;

function progressToPercentage(progress, total) {
	if (0 == total) {
		return 100;
	}
	return Math.floor(progress*100/total);
}

function resetTrackedInAttachmentIDs() {
	trackedInAttachmentIDs = [];
}

function addTrackedInAttachmentID(attachmentID) {
	if ($.inArray(attachmentID, trackedInAttachmentIDs) >= 0) {
		// already there
		return;
	}
	trackedInAttachmentIDs.push(attachmentID);
}

function removeTrackedInAttachmentID(attachmentID) {
	var index = $.inArray(attachmentID, trackedInAttachmentIDs);
	if (index < 0) {
		// not there
		return;
	}
	trackedInAttachmentIDs.splice(index, 1);
}

function updateBadge(id, count) {
	var badge = $('#' + id);

	if (count > 0) {
		badge.html(count);
		badge.removeClass('inactive');
	} else {
		badge.addClass('inactive');
		badge.html('');
	}
}

function freezeDimensions(element) {
	var w = element.width();
	var h = element.height();
	element.css({ width: w + 'px', height: h + 'px', overflow: 'auto' });
}

/**
 * Convert number of bytes into human readable format
 *
 * @param integer bytes     Number of bytes to convert
 * @param integer precision Number of digits after the decimal separator
 * @return string
 */
// from: http://codeaid.net/javascript/convert-size-in-bytes-to-human-readable-format-(javascript)
function bytesToSize(bytes, precision)
{
	var kilobyte = 1024;
	var megabyte = kilobyte * 1024;
	var gigabyte = megabyte * 1024;
	var terabyte = gigabyte * 1024;

	if ((bytes >= 0) && (bytes < kilobyte)) {
    return bytes + ' B';
	} else if ((bytes >= kilobyte) && (bytes < megabyte)) {
    return (bytes / kilobyte).toFixed(precision) + ' KB';
	} else if ((bytes >= megabyte) && (bytes < gigabyte)) {
    return (bytes / megabyte).toFixed(precision) + ' MB';
	} else if ((bytes >= gigabyte) && (bytes < terabyte)) {
    return (bytes / gigabyte).toFixed(precision) + ' GB';
	} else if (bytes >= terabyte) {
    return (bytes / terabyte).toFixed(precision) + ' TB';
	} else {
    return bytes + ' B';
	}
}

function numberToHumanSize(number) {
	return bytesToSize(number, 1);
}

// function setupButton(buttonID, options) {
// 	if (!options) var options = {};
// 	if (options.enable == undefined) options.enable = true;
// 	if (options.implemented == undefined) options.implemented = true;
// 	
// 	var button = $('#button-' + buttonID);
// 	button.unbind('click');
// }

function doRefresh() {
	var data = {};
	if (null != lastInMessageID) {
		data.last_in_message_id = lastInMessageID;
	}
	data.tracked_in_attachment_ids = JSON.stringify(trackedInAttachmentIDs);
	// alert(data.tracked_in_attachment_ids);
	// alert(trackedInAttachmentIDs);
	
	$.ajax({
		type: 'get',
		contentType: 'application/json',
		url: '/refresh',
		data: data,
		dataType: 'json',
		success: function(response) {
			// process badges data
			var counts = response.counts;
			updateBadge('unread-count', counts.unread);
			updateBadge('draft-count', counts.draft);
			updateBadge('unsent-count', counts.unsent);
			updateBadge('download-count', counts.download);
			
			// process new incoming message IDs
			var newLastInMessageID = response.last_in_message_id;
			if (null != newLastInMessageID) {
		    // alert("Got a new message: " + newLastInMessageID);
				// alert("A: " + newLastInMessageID);
				if ((null == lastInMessageID || lastInMessageID < newLastInMessageID) && null != updateInMessages) {
					// alert("B");
					updateInMessages(newLastInMessageID);
				}
			}
			
			// process unsent message count
			if (null != updateUnsentMessages) {
				if (counts.unsent != unsentMessageCount) {
					updateUnsentMessages(counts.unsent);
				}
			}
			
			// process sent message count
			if (null != updateSentMessages) {
				if (counts.sent != sentMessageCount) {
					updateSentMessages(counts.sent);
				}
			}
			
			// process download count
			if (null != updateDownloads) {
				if (counts.download != downloadCount) {
					updateDownloads(counts.download);
				}
			}
			
			// process tracked in-attachments
			var trackedInAttachments = response.tracked_in_attachments;
			// alert(trackedInAttachments);
			if (null != updateTrackedInAttachment) {
				$.each(trackedInAttachments, function(index, trackedInAttachment) {
					updateTrackedInAttachment(trackedInAttachment);
				});
			}
			
		}
	});
}

// setup periodic status updates
$(document).ready(function() {
	var updateId = setInterval(function() {
		doRefresh();
	}, 
	3000);
	
	// disable all hyperlinks with class 'disabled'
	$('a.disabled').click(function() {
		return false;
	});
	
	// bind an alert to all hyperlinks with class 'non-impl'
	$('a.not-impl').click(function() {
		alert('This function is not yet implemented');
		return false;
	});

	doRefresh();
	
});
