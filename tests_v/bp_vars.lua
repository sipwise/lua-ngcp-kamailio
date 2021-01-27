--
-- Copyright 2021 SipWise Team <development@sipwise.com>
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This package is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program. If not, see <http://www.gnu.org/licenses/>.
-- .
-- On Debian systems, the complete text of the GNU General
-- Public License version 3 can be found in "/usr/share/common-licenses/GPL-3".
--

local bp_vars = {
    {
        id = 1,
        preference_id = 14,
        content_type = 'application/xml',
        value = [[
<?xml version="1.0" encoding="UTF-8"?>
<presence
  xmlns="urn:ietf:params:xml:ns:pidf"
  xmlns:gp="urn:ietf:params:xml:ns:pidf:geopriv10"
  xmlns:gbp="urn:ietf:params:xml:ns:pidf:geopriv10:basicPolicy"
  xmlns:dm="urn:ietf:params:xml:ns:pidf:data-model"
  xmlns:cl="urn:ietf:params:xml:ns:pidf:geopriv10:civicAddr"
  xmlns:gml="http://www.opengis.net/gml"
  entity="pres:alice@atlanta.example.com">
    <dm:device id="target123-1">
      <gp:geopriv>
        <gp:location-info>
          <gml:location>
            <gml:Point srsName="urn:ogc:def:crs:EPSG::4326">
              <gml:pos>32.86726 -97.16054</gml:pos>
            </gml:Point>
          </gml:location>
        </gp:location-info>
        <gp:usage-rules>
          <gbp:retransmission-allowed>false
          </gbp:retransmission-allowed>
         <gbp:retention-expiry>2010-11-14T20:00:00Z
          </gbp:retention-expiry>
        </gp:usage-rules>
        <gp:method>802.11</gp:method>
      </gp:geopriv>
      <dm:deviceID>mac:1234567890ab</dm:deviceID>
      <dm:timestamp>2010-11-04T20:57:29Z</dm:timestamp>
    </dm:device>
    <dm:person id="target123">
      <gp:geopriv>
        <gp:location-info>
          <cl:civicAddress>
            <cl:country>US</cl:country>
            <cl:A1>Texas</cl:A1>
            <cl:A3>Colleyville</cl:A3>
            <cl:RD>Treemont</cl:RD>
            <cl:STS>Circle</cl:STS>
            <cl:HNO>3913</cl:HNO>
            <cl:FLR>1</cl:FLR>
            <cl:NAM>Haley's Place</cl:NAM>
            <cl:PC>76034</cl:PC>
          </cl:civicAddress>
        </gp:location-info>
        <gp:usage-rules>
          <gbp:retransmission-allowed>false
          </gbp:retransmission-allowed>
          <gbp:retention-expiry>2010-11-14T20:00:00Z
          </gbp:retention-expiry>
        </gp:usage-rules>
        <gp:method>triangulation</gp:method>
      </gp:geopriv>
      <dm:timestamp>2010-11-04T12:28:04Z</dm:timestamp>
    </dm:person>
</presence>
]]
    },
    {
        id = 2,
        preference_id = 2,
        content_type = 'application/xml',
        value = [[
<?xml version="1.0" encoding="UTF-8"?>
<emergencyCall.ProviderInfo xmlns="urn:ietf:params:xml:ns:emergencyCall.ProviderInfo">
 <DataProviderString>Telekom Deutschland</DataProviderString>
 <ProviderID>D124</ProviderID>
 <contactURI>sip:+492281234567@t-mobile.de;user=phone</contactURI>
 <ProviderIDSeries>BNetzA</ProviderIDSeries>
</emergencyCall.ProviderInfo>
]]
    }
}

return bp_vars
