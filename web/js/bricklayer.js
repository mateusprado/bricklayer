$(function(){

    function show_details(section, name) {
        var template = $.ajax({url:"/static/templates/" + section + "_details.html", async: false}).responseText;
        var details = $.parseJSON($.ajax({url: "/project/" + name, dataType: "json", async: false}).responseText);
        var builds = $.parseJSON($.ajax({url: "/build/" + name, dataType: "json", async: false}).responseText);
        
        $("#" + section + "-" + name + "-details").html($.mustache(template, { builds: builds, details:details }));
        $("#" + section + "-" + name + "-details").toggle("blind");
        $("table[class*=tablesorter]").tablesorter()

        $("a[id='build-log-show']").click(function () {
                show_log(name, $(this).attr("build_id"));
        });
    }

    function show_log(name, build_id) {
        var build_log = $.ajax({url: "/log/" + name + "/" + build_id, dataType: "json", async: false}).responseText;
        $("#build-log-view").find("textarea").val(build_log);
        $("#build-log-view").dialog("option", "buttons", [
            { 
                text: "Refresh", 
                click: function() {
                    show_log(name, build_id);
                }
            },
        ]);
        $("#build-log-view").dialog("open");

        $('#build-log-view-text').scrollTop($('#build-log-view-text')[0].scrollHeight);
    }

    function visit(section) {
        $.ajax({
            url:"/" + section,
            method: "GET",
            dataType: "json",
            success: function(data) {
                var template = $.ajax({url:"/static/templates/" + section + ".html", async: false}).responseText;
                $("#content").html($.mustache(template, { items : data } ));
                $("#create").button().click(function() {
                        $("div[id="+ section +"-form]").dialog("open");
                });

                switch(section) {
                    case 'group':
                            $(".edit").editInPlace({
                                callback : function(unused, enteredText) { 
                                    console.log($(this).attr("id") + " " + enteredText);
                                    $.ajax("/group/" + $(this).attr("group"), {
                                        type: "POST", 
                                        data: "edit=true&" + $(this).attr("id") + "=" + enteredText
                                    });
                                    return enteredText; 
                                }
                            });
                        break;

                    case 'project':
                        var groups_select = $.parseJSON($.ajax({url: "/group", dataType: "json", async: false}).responseText);
                        $("select#group_name").html("");
                        for(i=0, len=groups_select.length; i < len; i++) {
                            $("select#group_name").append("<option>" + groups_select[i].name + "</option>");
                        }

                        $("a[id^='show_']").each(function() {
                            $(this).click(function () { 
                                show_details('project', $(this).attr("id").split("_")[1]);
                            }); 
                        });

                        break;
                }

            } // sucess callback
        }); // ajax 

    }
    
    $('div[id*="-form"]').each(function() {
        /* init forms */
        var section = $(this).attr("id").split("-")[0];
        $(this).dialog({
            autoOpen: false,
            height: 400,
            width: 450,
            modal: true,
            buttons: {
                "Create": function() { 
                    var data = $("div[id=" + section + "-form]").find("form").serialize();
                    $.post("/"+ section, data, function() {
                        $("#" + section +"-form").find("input").each(
                            function () {
                                $(this).val("");
                            });
                        $("div[id="+ section +"-form]").dialog("close"); 
                        visit(section);
                    });
                },
                "Cancel": function() { $(this).dialog("close"); },
            }
        });
    });
                
    $("#build-log-view").dialog({
        autoOpen: false,
        height: 400,
        width: 470,
        modal: true,
    });
    
    $("#main-menu").find("li").each(function(){
        var menu_item = $(this);
        menu_item.click(function() {
            var menu_text = $(this);
            visit(menu_text.attr("class").toLowerCase()); 
        });
    });
    
    visit("project");
});
