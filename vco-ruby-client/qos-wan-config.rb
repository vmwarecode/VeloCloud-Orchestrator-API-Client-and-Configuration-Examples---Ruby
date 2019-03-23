#!/usr/bin/env ruby
#
require_relative 'vco-client'

#
# Ruby configuration examples
#

ENTERPRISE_ID = 5
EDGE_ID = 5
LINK_INTERNAL_ID = '0fc3c135-42be-5670-0000-00002da247d9'

def main
  client = VcoRequestManager.new(ENV['VCO_PASSWORD'])
  client.authenticate(ENV['VCO_USERNAME'], ENV['VCO_PASSWORD'], true)
  
  # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
  #
  # Example 1: Modify QOS rules on a *network-based profile*.
  #
  #
  # The set of profiles that may be modified in this way (i.e. the set of valid
  # configurationIds) is the list returned by a call to
  # configuration/getEnterpriseConfigurations

  profile = client.call('configuration/getConfiguration', {:enterpriseId => ENTERPRISE_ID,
                                                           :configurationId => 44,
                                                           :with => ['modules']})
  qos_module = nil
  profile['modules'].each { |_module|
    if _module['name'] == 'QOS'
      qos_module = _module
      break
    end
  }
  qos_data = qos_module['data']
  qos_rules = qos_data['rules']
  new_rule = qos_data['rules'][0].clone()
  new_rule['name'] = 'RADIUS'
  new_rule['match']['appid'] = 158

  # In this example I've a-priori identified an application in the operator
  # application map for which I want to create a new business rule (RADIUS)

  # Modify other parameters as needed...
  # `pp new_rule` will expose the complete rule structure

  qos_rules.push(new_rule)
  update_result = client.call('configuration/updateConfigurationModule',
                              {:enterpriseId => ENTERPRISE_ID,
                               :configurationModuleId => qos_module['id'],
                               :_update => { :data => qos_data }})
  # Only the module data should be updated
  pp update_result

  # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
  #
  # Example 2: Set a link as a backup
  #
  #
  # This assumes you know know the internalId of the link you intend to modify,
  # which can be determined by calling edge/getEdge and specifying
  # with: ['recentLinks', ...]
  #
  # We first pull down the configuration 'stack' for the target Edge, which is
  # an array consisting of two entries:
  # (1) The edge-specific configuration (consists of edge-specific overrides
  #     and extensions to the Edge's assigned profile)
  # (2) The profile that is assigned to the target Edge
  stack = client.call('edge/getEdgeConfigurationStack', {:enterpriseId => ENTERPRISE_ID,
                                                         :edgeId => EDGE_ID,
                                                         :with => ['modules']})
  edge_specific_config = stack[0]
  wan_module = nil
  edge_specific_config['modules'].each { |_module|
    if _module['name'] == 'WAN'
      wan_module = _module
      break
    end
  }
  wan_data = wan_module['data']
  wan_links = wan_data['links']
  target_link = nil
  wan_links.each { |_link|
    if _link['internalId'] == LINK_INTERNAL_ID
      target_link = _link
      break
    end
  }

  # Configure as backup
  target_link['backupOnly'] = true
  update_result = client.call('configuration/updateConfigurationModule',
                              {:enterpriseId => ENTERPRISE_ID,
                               :configurationModuleId => wan_module['id'],
                               :_update => { :data => wan_data }})
  # Only the module data should be updated
  pp update_result

end

main()
