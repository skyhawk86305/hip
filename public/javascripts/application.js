// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
var $j=jQuery.noConflict()
/*
 *  toggle Id display on or off.
*/
function toggleIdDisplay(id){
  if ( id ){
    element = document.getElementById(id)
    display = element.style.display

    if (display=='none'){
      element.style.display='block'
    }
    if (display=='block'){
      element.style.display='none'
    }
  }
}
/*
 *  Show the Element
*/
function showElement(id) {
  if (id != ""){
    document.getElementById(id).style.display = "block";
  }
}

/*
 *  Hide the Element
*/
function hideElement(id) {
  document.getElementById(id).style.display = "none";
}

/*
 * will_pagination AJAX
*/
document.observe("dom:loaded", function() {
  // the element in which we will observe all clicks and capture
  // ones originating from pagination links
  var container = $(document.body)

  if (container) {
    var img = new Image
    img.src = '/images/spinner.gif'

    function createSpinner() {
      return new Element('img', {
        src: img.src,
        'class': 'spinner'
      })
    }

    container.observe('click', function(e) {
      var el = e.element()
      if (el.match('.pagination.ajax a')) {
        el.up('.pagination.ajax').insert(createSpinner())
        new Ajax.Request(el.href, {
          method: 'get'
        })
        e.stop()
      }
    })
  }
})

/*
 * checks if the first element is selected and
 * sends an alert.
 *
 * id - the element
 * msg - the message to send
*/
function checkSelectElement(id,msg){
  element = document.getElementById(id)
  if (element.options.selectedIndex==0){
    alert(msg)
    return false
  }
  return true
}

/* for dynamic fields */
function remove_fields(link) {
  $(link).previous('input[type="hidden"]').value = "1";
  $(link).up(".fields").hide();
}

function add_fields(link, association, content) {
  var new_id = new Date().getTime();
  var regexp = new RegExp("new_" + association, "g")
  //
  $('body').up().insert({
    bottom: content.replace(regexp, new_id)
  });
}

(function($) {

  window.HIP = {};

  HIP.HcController = function(attrs) {
    attrs = attrs || {};
    this.groupSelectId = attrs.groupSelectId;

    var self = this;
    $(document).ready(function() {
      var $select = $('#' + self.groupSelectId),
          $reset  = $('.start-over', $select.closest('form'));

      self.updateFindButton();
      $select.bind('change', function() { self.updateFindButton(); });
      $reset.bind('click', function() { self.resetForm(); });
    });
  };

  HIP.HcController.prototype.updateFindButton = function() {
    var $find    = $('#find'),
    $select  = $('#' + this.groupSelectId),
    disabled = $select.val() == '';
    $find.attr('disabled', disabled);
  };

  HIP.HcController.prototype.resetForm = function() {
    // http://stackoverflow.com/questions/680241/resetting-a-multi-stage-form-with-jquery/680252#680252
    var $form   = $('#' + this.groupSelectId).closest('form'),
        $inputs = $(':input', $form).not(':button, :submit, :reset, :hidden');
    $inputs.val('').removeAttr('checked').removeAttr('selected');
    this.updateFindButton();
    return false;
  };

  HIP.Util = {};

})(jQuery);
