import string
import uuid
import math
import hct_constants as constants
import hct_config
import hct_logger as logger

import tools as tools_be

var Config=hct_config.Config

def sanitize_name(s, sep)
    sep= sep ? sep : '-'
    var chars=[]
    for c: tools_be.to_chars(string.tolower(s))
        if constants.SEPS_ALLOWED.find(c)!=nil
            chars.push(sep)
        elif constants.CHARS_ALLOWED.find(c)!=nil
            chars.push(c)
        end        
    end 
    return chars.concat()
end

def add_rule(id,trigger,closure)   
    
    var entry
    if string.find(trigger,'cron:')!=0
        entry={'type': 'trigger', 'trigger':trigger, 'function':closure} 
        tasmota.add_rule(entry['trigger'],closure,id)           
    else
        entry={'type': 'cron', 'trigger':string.replace(trigger,'cron:',''), 'function':closure}
        tasmota.add_cron(entry['trigger'],closure,id)
    end

    return entry
end

def remove_rule(id, entry)   
            
    if entry['type']=='trigger'
        tasmota.remove_rule(entry['trigger'],id)
    else
        tasmota.remove_cron(id)
    end

end

def add_rule_once(trigger, function)

    var id=uuid.uuid4()

    def wrapper(value, trigger_wrapper, message)      
        logger.logger.debug(['Removing rule-once', trigger, id])          
        tasmota.remove_rule(trigger,id)        
        return function(value, trigger_wrapper, message)
    end
    
    logger.logger.debug(['Adding rule-once', trigger, id])          
    tasmota.add_rule(trigger,wrapper, id)    

end

def update_hct(url,path_module)
    return tools_be.update_tapp_github_asset(url, constants.ORG, constants.NAME, constants.ASSET_FILENAME, path_module)
end



var mod = module("hct_tools")

mod.tools_be=tools_be

mod.to_bool=tools_be.converter.to_bool
mod.from_bool=tools_be.converter.from_bool
mod.read_url=tools_be.read_url
mod.download_url=tools_be.download_url

mod.get_mac=tools_be.get_mac
mod.get_mac_short=tools_be.get_mac_short
mod.get_mac_last_six=tools_be.get_mac_last_six

mod.get_topic=tools_be.get_topic
mod.get_topic_lwt=tools_be.get_topic_lwt

mod.get_device_name=tools_be.get_device_name
mod.get_uptime_sec=tools_be.get_uptime_sec
mod.to_chars=tools_be.to_chars
mod.sanitize_name=sanitize_name
mod.set_default=tools_be.set_default
mod.add_rule=add_rule
mod.remove_rule=remove_rule
mod.add_rule_once=add_rule_once
mod.reverse_map=tools_be.reverse_map
mod.update_map=tools_be.update_map
mod.get_keys=tools_be.get_keys
mod.update_hct=update_hct
mod.get_latest_version_github=tools_be.get_latest_version_github
mod.tuya_send=tools_be.tuya.tuya_send
mod.get_current_version_tasmota=tools_be.get_current_version_tasmota
mod.get_rand=tools_be.random.get_rand

return mod