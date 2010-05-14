Rails.dashboard = {};

Rails.dashboard.index = function() {
	$("#vms tr.installed").click(function(e){
		if ($(e.target).is("a")) {
			return;
		}

		location.href = $(this).find("a.details").attr("href");
	});
};
