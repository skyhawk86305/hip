(function($) {
  
  var HIP = window.HIP;

  // Handles fields shared across the different Out Of Cycle pages.
  HIP.OocSearchView = Backbone.View.extend({
    events: {
      'click .resetForm': 'resetForm',
      'change [name=ooc_scan_type]': 'updateGroups',
      'change [name=ooc_group_type]': 'updateGroups',
      'change [name=ooc_group_id]': 'render'
    },
    resetForm: function() {
      // http://stackoverflow.com/questions/680241/resetting-a-multi-stage-form-with-jquery/680252#680252
      var $inputs = this.$(':input').not(':button, :submit, :reset, :hidden');
      $inputs.val('').removeAttr('checked').removeAttr('selected');
      this.updateGroups();
    },
    // updates the Group Type and Group Name based on the Scan Type
    updateGroups: function() {
      this.$(this.submitSel).attr('disabled', true);

      var data = {};
      data.authenticity_token = $('meta[name=csrf-token]').attr('content');
      data[this.scanListField] = this.$('[name=' + this.scanListField + ']').val();

      $.ajax({
        url: this.scanListUrl,
        type: 'POST',
        data: data,
        context: this,
        success: function(body, textStatus, response) {
          this.$(this.scanListSel).html(body);
          this.render();
        }
      });
      return false;
    },
    render: function() {
      this.$(this.submitSel).attr('disabled', this.$('#ooc_group_id').val() == 'choose');
    },
    submitSel: 'input[type=submit][value=find], input[type=submit][value="get file"]',
    scanListField: 'ooc_scan_type',
    scanListUrl: '/out_of_cycle/scans/group_scan_lists',
    scanListSel: '#group_scan'
  });

  HIP.OocAssetSearchView = HIP.OocSearchView.extend({
    scanListField: 'ooc_group_type',
    scanListUrl: '/out_of_cycle/assets/group_scan_lists',
    scanListSel: '#group_name'
  });

  HIP.initOocSearch = function() {
    var $form = $('form.hip-search');
    var opts = {
      el: $form
    };
    if ($form.hasClass('hip-ooc-asset-search')) {
      HIP.searchView = new HIP.OocAssetSearchView(opts);
    } else {
      HIP.searchView = new HIP.OocSearchView(opts);
    }
    HIP.searchView.updateGroups();
  };

})(jQuery);

