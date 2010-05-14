// Instantiate the Cloud library
var Cloud = {};

// Settings
Cloud.memoryRAM = {
	1: [512, "512MB"],
	2: [1024, "1GB"],
	3: [2048, "2GB"],
	4: [3072, "3GB"],
	5: [4096, "4GB"],
	6: [5120, "5GB"],
	7: [6144, "6GB"],
	8: [7168, "7GB"]
}

Cloud.errorsFor = function(type, record) {
	var message = "<ul class='with-errors'>";

	for (var i in record.errors) {
		var error = record.errors[i];
		var options = {
			scope: "activerecord.attributes." + type,
			defaultValue: error[0]
		};

		if (error[0] == "base") {
			message += "<li>" + error[1] + "</li>";
		} else {
			message += "<li>" + I18n.t(error[0], options) + " " + error[1] + "</li>";
		}
	}

	message += "</ul>";

	return message;
};

// If virtual machine is installing/installed, then we can safely display a success message.
// In any other case, we have to display an error message.
Cloud.virtualMachineSetupWatcher = function(id) {
	$.getJSON("/machines/" + id + ".json", function(data){
		var vm = data.virtual_machine;

		$("#step4 .prev").addClass("hidden");

		if (vm.configuring && vm.status == "invalid_setup") {
			$("#pre-install-status")
				.removeClass("running")
				.addClass("error")
				.append("<p>" + I18n.t("pre_install.setup_error") + "</p>");

			$("#step4 .prev").removeClass("hidden")
		} else if (vm.installing) {
			$("#pre-install-status")
				.removeClass("running")
				.addClass("done");

			$("#installing-status")
				.removeClass("hidden")
				.addClass("running");
		} else if (vm.installed) {
			$("#installing-status")
				.removeClass("running")
				.addClass("done");

			$("#installed-status")
				.removeClass("hidden")
				.addClass("done")
				.append("<p>" + I18n.t("pre_install.installed_details", {address: vm.public_ip.address}) + "</p>");
		}

		if ($("#facybox").length > 0 && vm.status != "installed" && vm.status != "invalid_setup") {
			setTimeout(Cloud.virtualMachineSetupWatcher, 15000, id);
		}
	});
};

// This function validates an instance before creating it.
// Only password presence and terms acceptance are verified for now.
Cloud.validNewInstance = function() {
	var terms = $("#virtual_machine_terms");
	var termsBlock = $(terms).parent("p");
	var password = $("#virtual_machine_password");
	var passwordBlock = $(password).parent(".field");
	var passwordConfirmation = $("#virtual_machine_password_confirmation");
	var passwordConfirmationBlock = $("#virtual_machine_password_confirmation").parent(".field");
	var formWithErrors = false;

	// Validate acceptance
	if ($(terms).is(":checked") == false) {
		$(termsBlock)
			.addClass("error")
			.effect("shake", {times: 1}, 100);

		formWithErrors = true;
	} else {
		$(termsBlock).removeClass("error");
	}

	// Validate password
	if (!$(password).val()) {
		$(passwordBlock).addClass("error")
		formWithErrors = true;
	} else {
		$(passwordBlock).removeClass("error")
	}

	// Validate password confirmation
	if ($(password).val() != $(passwordConfirmation).val()) {
		$(passwordConfirmationBlock).addClass("error")
		formWithErrors = true;
	} else {
		$(passwordConfirmationBlock).removeClass("error")
	}

	return !formWithErrors;
};

Cloud.setupSlider = function(selector, options, sliderHandler) {
	options.stop = function(event, ui) {
		$("span.balloon", event.target).remove();
	};

	options.animate = true;
	// options.change = sliderHandler;
	options.slide = sliderHandler;

	$(selector).slider(options);
};

Cloud.wizardInit = function() {
	Cloud.step = 1;
	Cloud.totalSteps = 3;
	
	$(document).bind('close.facybox', function() {
		if(Cloud.wizardDone) {			
			location.reload();
		}
	});

	$("#new_virtual_machine").submit(function(e){
	  $.stopEvent(e);
	  return false;
	});

	$("#images div.vm-image").click(function(){
		$("#virtual_machine_system_image_id").val(this.id.replace(/vm-/, ""));

		Cloud.step = 2;
		Cloud.stepManager();
	});

	$.strength("root", "#virtual_machine_password", function(u, p, strength){
		$("#strength").attr("src", "/images/" + strength.status + ".png");
	});

	$("#step2 .prev").click(function(){
		Cloud.step = 1;
		Cloud.stepManager();
	});

	$("#step2 .next").click(function(){
		var memoryStep = $("#memory .slider").slider("value");
		var cpuStep = $("#cpu .slider").slider("value");
		var storageStep = $("#storage .slider").slider("value");

		// Update displayed values
		$("#vm-description")
			.find("dl").remove().end()
			.append($("#vm-" + $("#virtual_machine_system_image_id").val()).html());

		$("#step3 .memory strong").text(Cloud.memoryRAM[memoryStep][1]);
		$("#step3 .cpu strong").text(cpuStep);
		$("#step3 .storage strong").text(storageStep + "GB");

		// Update fields
		$("#virtual_machine_memory").val(Cloud.memoryRAM[memoryStep][0]);
		$("#virtual_machine_cpus").val(cpuStep);
		$("#virtual_machine_hdd").val(storageStep);

		Cloud.step = 3;
		Cloud.stepManager();
	});

	$("#step3 .prev").click(function(){
		// Remove validation class
		$("#facybox .error").removeClass("error");

		Cloud.step = 2;
		Cloud.stepManager();
	});

	$("#step3 .next").click(function(){
		if (Cloud.validNewInstance()) {
			$("div.step").addClass("hidden");
			$("#step4").removeClass("hidden");
			$("#step4 .prev").addClass("hidden");
			$("#step4 .with-errors").remove();
			$("#pre-install-status")
				.removeClass("error")
				.addClass("running");

			var options = {
				url: "/machines",
				dataType: "json",
				data: $("#new_virtual_machine").formSerialize(),
				type: "post",
				success: function(data) {
					var id;

					try {
						id = data.virtual_machine.id;
					} catch (e) {
						//
					}

					if (id) {
						Cloud.wizardDone = true;
						Cloud.virtualMachineSetupWatcher(id);
					} else {
						$("#pre-install-status")
							.removeClass("running")
							.addClass("error")
							.append(Cloud.errorsFor("virtual_machine", data.virtual_machine));

						$("#step4 .prev").removeClass("hidden");
					}
				},
				error: function(xhr) {
					//FIXME: Do error handling
					Cloud.wizardDone = true;
				}
			};

			$.ajax(options);
		}
	});

	$("#step4 .prev").click(function(){
		$("div.step").addClass("hidden");
		$("#step3").removeClass("hidden");
	});

	$("#step4 .next").click(function(){
		$.facybox.close();
	});

	Cloud.setupSlider("#memory .slider", {value: 1, min: 1, max: 8}, function(event, ui){
		// $(".ui-slider-handle", event.target).html("<span class='balloon'><strong>R$0.05/h</strong><span/></span>");
		$(event.target).parents(".slider-container:first").find(".display strong").text(Cloud.memoryRAM[ui.value][1]);
	});

	Cloud.setupSlider("#cpu .slider", {value: 1, min: 1, max: 20}, function(event, ui){
		// $(".ui-slider-handle", event.target).html("<span class='balloon'><strong>R$0.02</strong><span/></span>");
		$(event.target).parents(".slider-container:first").find(".display strong").text(ui.value);
	});

	Cloud.setupSlider("#storage .slider", {value: 1, min: 1, max: 20}, function(event, ui){
		// $(".ui-slider-handle", event.target).html("<span class='balloon'><strong>R$0.01</strong><span/></span>");
		$(event.target).parents(".slider-container:first").find(".display strong").text(ui.value + "GB");
	});
};

Cloud.stepManager = function() {
	$("div.step").addClass("hidden");
	$("#step" + Cloud.step).removeClass("hidden");
};

// Bootstrap setting essential functionality for
// all libraries
Cloud.bootstrap = function() {
	I18n.defaultLocale = "pt";
	I18n.locale = $("html").attr("xml:lang");

	$("#init-instance").click(function(){
		$.get("/machines/wizard", function(html){
			$.facybox(html);
			Cloud.wizardInit();
		});

		return false;
	});
};

// Dispatch boostrapping
if (window.Rails) { Rails.before = Cloud.bootstrap; }
