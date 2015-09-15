
function fetch(regex, data)
{
	var result = data.match(regex);
	return result ? result[1] : "";
}

function append_td(tr, value) {
	append(tr, 'td').innerHTML = value ? value : "?";
}

function wifi_scan()
{
	var s = $('wifiscan_selection');
	var device = s.options[s.selectedIndex].value;

	send("/cgi-bin/misc", {func:'wifiscan', device:device}, function(data) {
		var tbody = $("wifiscan_tbody");
		removeChilds(tbody);

		var items = data.split(/BSS /).filter(Boolean);
		for(var i = 0; i < items.length; ++i)
		{
			var item = items[i];
			var ssid = fetch(/SSID: (.*)\n/, item);
			var channel = fetch(/channel (.*)\n/, item);
			var signal = fetch(/signal: (.*)\n/, item);
			var capability = fetch(/capability: (.*)\n/, item);
			var mesh_id = fetch(/MESH ID: (.*)\n/, item);

			var tr = append(tbody, 'tr');
			append_td(tr, mesh_id ? mesh_id : ssid);
			append_td(tr, channel);
			append_td(tr, signal);

			//determine the wifi mode
			if(mesh_id) {
				append_td(tr, "  802.11s");
			} else  if(/IBSS/.test(capability)) {
				append_td(tr, "  AdHoc");
			} else  if(/ESS/.test(capability)) {
				append_td(tr, "  AccessPoint");
			} else {
				append_td(tr, "  ???");
			}
		}

		var table = $('wifiscan_table');
		show(table);
	});
}

function add_list_entry(device, ifname) {
	var list = $('wifiscan_selection');
	var o = append(list, 'option');
	o.style.paddingRight = "1em";
	o.innerHTML = device;
	o.value = ifname;
}

/*
* Create a selection of wireless devices
* represented as the first interface found.
*/
function init() {
	send("/cgi-bin/misc", {func:'wifiscan_info'}, function(data) {
		var uci = fromUCI(data);
		config_foreach(uci.wireless, "wifi-device", function(device, sobj) {
			var found = false;
			config_foreach(uci.wireless, "wifi-iface", function(sid, sobj) {
				if(sobj.device == device && sobj.ifname) {
					add_entry(device, sobj.ifname);
					found = true;
					return 1;
				}
			});

			if(!found) switch(device) {
				case "radio0": add_list_entry(device, "wlan0"); break;
				case "radio1": add_list_entry(device, "wlan1"); break;
			}
		});
	});
}
