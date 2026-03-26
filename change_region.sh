#!/bin/sh
# LG webOS TV Region Change Script
# Writes area option directly to NVRAM via lowlevelstorage service,
# bypassing factorymanager's geolock permission check.
#
# Tested on: LG OLED77C5PUA, webOS 10.3.0, firmware 33.30.97

NODE_PATH=/tmp/node_modules:/usr/lib/node_modules:/usr/lib/nodejs
export NODE_PATH

# The webos-service node module requires pmloglib, which isn't available
# in the prisoner shell. This stub satisfies the dependency.
# Must be recreated after every reboot since /tmp is tmpfs.
setup_stub() {
    mkdir -p /tmp/node_modules
    echo 'function C(){return{log:function(){},info:function(){},warning:function(){},error:function(){}};}module.exports={log:function(){},info:function(){},warning:function(){},error:function(){},Console:C,Context:function(){return{log:function(){},info:function(){},warning:function(){},error:function(){}};}};' > /tmp/node_modules/pmloglib.js
    echo "[+] pmloglib stub created"
}

# Read contiArea2All from NVRAM via lowlevelstorage and decode the bit fields
read_area() {
    node -e '
var pb=require("palmbus"),h=new pb.Handle("",true);
h.call("luna://com.webos.service.lowlevelstorage/getData",
  JSON.stringify({dbgroups:[{dbid:"factory",items:["contiArea2All"]}]}))
.on("response",function(m){
  var r=JSON.parse(m.payload());
  if(r.returnValue){
    var v=parseInt(r.dbgroups[0].items.contiArea2All);
    console.log("Current area option: "+v);
    console.log("  continentIdx:     "+(v&0x7F));
    console.log("  languageCountry:  "+((v>>7)&0x1F));
    console.log("  hwSettingGroup:   "+((v>>12)&0xF));
  } else {
    console.log("Error: "+m.payload());
  }
  process.exit(0);
});
setTimeout(function(){process.exit(1);},5000);'
}

# Write contiArea2All to NVRAM via lowlevelstorage/setData
# This bypasses factorymanager's internal permission check (geolock)
write_area() {
    AREA="$1"
    node -e '
var area="'"$AREA"'";
var pb=require("palmbus"),h=new pb.Handle("",true);
h.call("luna://com.webos.service.lowlevelstorage/setData",
  JSON.stringify({dbgroups:[{dbid:"factory",items:{contiArea2All:area}}]}))
.on("response",function(m){
  var r=JSON.parse(m.payload());
  if(r.returnValue){
    console.log("[+] NVRAM contiArea2All set to "+area);
  } else {
    console.log("[-] Failed: "+m.payload());
    process.exit(1);
  }
});
setTimeout(function(){
  h.call("luna://com.webos.service.lowlevelstorage/getData",
    JSON.stringify({dbgroups:[{dbid:"factory",items:["contiArea2All"]}]}))
  .on("response",function(m){
    console.log("[+] Verify: "+m.payload());
    process.exit(0);
  });
},1000);
setTimeout(function(){process.exit(1);},5000);'
}

# Update configd overrides and settings DB to match US region.
# configd overrides persist through reboot.
# Settings DB stores user-facing values like country name.
set_configd_us() {
    node -e '
var pb=require("palmbus"),h=new pb.Handle("",true);
h.call("luna://com.webos.service.config/setConfigs",
  JSON.stringify({configs:{"tv.model.languageCountrySel":"US","tv.model.hwSettingGroup":"US","tv.model.continentIndx":10}}))
.on("response",function(m){console.log("[+] configd: "+m.payload());});
setTimeout(function(){
  h.call("luna://com.webos.service.settings/setSystemSettings",
    JSON.stringify({category:"option",settings:{country:"USA",smartServiceCountryCode3:"USA",localeCountryGroup:"langSelUS"}}))
  .on("response",function(m){console.log("[+] settings: "+m.payload());process.exit(0);});
},500);
setTimeout(function(){process.exit(1);},5000);'
}

# Reboot via luna service
reboot_tv() {
    echo "Rebooting TV..."
    node -e 'var pb=require("palmbus");var h=new pb.Handle("",true);h.call("luna://com.webos.service.sleep/shutdown/machineReboot",JSON.stringify({"reason":"remoteKey"}));setTimeout(function(){process.exit(0);},3000);'
}

# Verify all three layers: NVRAM, factorymanager, configd, settings DB
verify() {
    node -e '
var pb=require("palmbus"),h=new pb.Handle("",true);
h.call("luna://com.webos.service.lowlevelstorage/getData",
  JSON.stringify({dbgroups:[{dbid:"factory",items:["contiArea2All"]}]}))
.on("response",function(m){console.log("NVRAM:          "+m.payload());});
setTimeout(function(){
  h.call("luna://com.webos.service.factorymanager/getFactoryOpt",
    JSON.stringify({keys:["contiArea2All"],subscribe:false}))
  .on("response",function(m){console.log("factorymanager: "+m.payload());});
},500);
setTimeout(function(){
  h.call("luna://com.webos.service.config/getConfigs",
    JSON.stringify({configNames:["tv.model.languageCountrySel","tv.model.hwSettingGroup","tv.model.continentIndx"]}))
  .on("response",function(m){console.log("configd:        "+m.payload());});
},1000);
setTimeout(function(){
  h.call("luna://com.webos.service.settings/getSystemSettings",
    JSON.stringify({category:"option",keys:["country","smartServiceCountryCode3","localeCountryGroup"]}))
  .on("response",function(m){console.log("settings:       "+m.payload());process.exit(0);});
},1500);
setTimeout(function(){process.exit(1);},5000);'
}

# --- Main ---
setup_stub

case "$1" in
    setup)
        echo "Stub created. Ready to use."
        ;;
    read)
        read_area
        ;;
    verify)
        verify
        ;;
    reboot)
        reboot_tv
        ;;
    "")
        echo "Usage: $0 <area_code|read|verify|reboot|setup>"
        echo ""
        echo "Examples:"
        echo "  $0 read          Read current area option"
        echo "  $0 verify        Verify all region settings"
        echo "  $0 22282         Set area option to US (22282)"
        echo "  $0 reboot        Reboot the TV"
        echo "  $0 setup         Just create the pmloglib stub"
        echo ""
        echo "Common area codes:"
        echo "  22282 = US  (continentIdx=10, lang=US, hw=US)"
        echo "  19461 = EU/KR (continentIdx=5, lang=EU, hw=KR)"
        exit 1
        ;;
    *)
        echo "Setting area option to $1..."
        write_area "$1"
        echo ""
        echo "Setting configd and settings to US..."
        set_configd_us
        echo ""
        echo "Done. Run '$0 reboot' or use the remote to reboot."
        echo "After reboot, set country to United States in Settings if prompted."
        ;;
esac
