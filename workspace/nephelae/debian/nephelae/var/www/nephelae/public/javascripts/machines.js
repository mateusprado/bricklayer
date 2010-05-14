Rails.machines = {};

Rails.machines['show'] = function () {
	$('a.remove').click(function (e) {
		$.stopEvent(e);
		if (confirm(I18n.t('confirm_deletion'))) {
			location.href = this.href + '/confirmed';
		}
	});
	
	$('li.restart a').click(function (e) {
		$.stopEvent(e);
		if (confirm(I18n.t('machines.commands.confirm_restart'))) {
			location.href = this.href + 'ed';
		}
	});
	
	$('li.force-restart a').click(function (e) {
		$.stopEvent(e);
		if (confirm(I18n.t('machines.commands.confirm_forced_restart'))) {
			location.href = this.href + 'ed';
		}
	});
	
	$('a.revert').click(function (e) {
		$.stopEvent(e);
		if (confirm(I18n.t('snapshots.confirm_revertion'))) {
			location.href = this.href + 'ed';
		}
	});

	$('li.uninstall a').click(function (e) {
		$.stopEvent(e);
		if (confirm(I18n.t('machines.confirm_uninstall'))) {
			location.href = this.href + 'ed';
		}
	});
	
	// $("#create-snapshot").click(function(){
	// 		$.get(this.href, function(html){
	// 			$.facybox(html);
	// 		});
	// 
	// 		return false;
	// 	});
};
