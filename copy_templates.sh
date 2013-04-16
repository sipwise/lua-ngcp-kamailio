#!/bin/sh
tpage --define PRO=true templates/proxy/prefs.lua > /etc/ngcp-config/templates/etc/kamailio/proxy/prefs.lua.tt2
tpage --define PRO=true templates/proxy/kamailio.cfg > /etc/ngcp-config/templates/etc/kamailio/proxy/kamailio.cfg.customtt.tt2
tpage --define PRO=true templates/proxy/proxy.cfg > /etc/ngcp-config/templates/etc/kamailio/proxy/proxy.cfg.customtt.tt2
ngcpcfg build /etc/kamailio/proxy
invoke-rc.d kamailio-proxy restart 
