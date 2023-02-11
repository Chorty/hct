# To use this code, add it to your `autoexec.be` - or upload this script to your device and add `load("/proscenic_t21.be")`.
# Before using this code, make sure you've completed the initial Tuya setup, as shown here: https://templates.blakadder.com/proscenic_T21.html

#First we import this library.

import hct

log("Setting up Proscenic T21 (using hct version "+hct.VERSION+")...")

# Now we add a Number slider to control cooking temperature in F.
# Since the fryer MCU uses F natively, this just the process similar to the cookbook pull-down above.

hct.Number(
    'Cooking Temperature (F)',
    170,                     # Minimum temperature
    399,                     # Maximum temperature
    'slider',                # Input type
    nil,                     # Entity ID
    '°F',                    # Unit of measure
    nil,                     # Slider step size (if not 1).
    'mdi:temperature-fahrenheit',
    'tuyareceived#dptype2id103',
    /value->tasmota.cmd('TuyaSend2 103,'+str(value))
)

# Now a slider for temperature in C (not necessary but nice to have if you use C in your country).
# This is a little more complex as it means converting the temperature in the callbacks.
# Here our outgoing callback is a map from the conversion function to the trigger that calls it.

import math

convert_f_to_c_map={
        /value->math.ceil((value-32)/1.8):
        'tuyareceived#dptype2id103'
}

convert_c_to_f=/value->tasmota.cmd('TuyaSend2 103,'+str(int((value*1.8)+32)))

hct.Number(
    'Cooking Temperature (C)',
    77,
    204,
    'slider',
    nil,
    '°C',
    nil,
    'mdi:temperature-celsius',
    convert_f_to_c_map,
    convert_c_to_f
)

hct.Number(
    'Cooking Time',
    1,
    60,
    'box',
    nil,
    'minutes',
    nil,
    'mdi:timer',
    'tuyareceived#DpType2Id7',
    /value->tasmota.cmd('TuyaSend2 7,'+str(value))
)

hct.Number(
    'Keep Warm Time',
    0,
    120,
    'box',
    nil,
    'minutes',
    nil,
    'mdi:timer-sync',
    {
        /v->v:'tuyareceived#DpType2Id105',
        /->0: 'Power3#state=0',
        /->5: 'Power3#state=1',

    },
    def (value)

        value=value!=nil ? value : 0

        if value==0
            tasmota.set_power(2,false)   
            return hct.Publish(value)
        end
        
        value=value<5 ? 5 : value        

        if !tasmota.get_power()[2]
            hct.add_rule_once(
                'Power3#state=1',
                /->tasmota.cmd('TuyaSend2 105,'+str(value))
                
            )
            tasmota.set_power(2,true)
        else
            tasmota.cmd('TuyaSend2 105,'+str(value))
        end

        return hct.Publish(value)

    end
)

hct.Number(
    'Delay Time',
    0,
    720,
    'box',
    nil,
    'minutes',
    nil,
    'mdi:timer-pause',
    {
        /v->v:'tuyareceived#DpType2Id6',
        /->0: 'Power4#state=0',
        /->5: 'Power4#state=1',

    },
    def (value)

        value=value!=nil ? value : 0

        if value==0
            tasmota.set_power(3,false)   
            return hct.Publish(value)     
        end
        
        value=value<5 ? 5 : value        

        if !tasmota.get_power()[3]
            hct.add_rule_once(
                'Power4#state=1',
                /->tasmota.cmd('TuyaSend2 6,'+str(value))
                
            )
            tasmota.set_power(3,true)
        else
            tasmota.cmd('TuyaSend2 6,'+str(value))
        end

        return hct.Publish(value)

    end
)

hct.Sensor(   
    'Status',    
    nil,
    nil,
    nil,
    'mdi:playlist-play',
    {
        /value->{0:'Ready',1:'Delayed Cook',2:'Cooking',3:'Keep Warm',4:'Off',5:'Cooking Complete'}.find(value,'Unknown'):
        'tuyareceived#dptype4id5'
    }
)

# Lastly we add the cookbook pull-down. This has already been covered in the README: https://github.com/fmtr/hct#example-walkthrough

FOODS_INDEXES={'Default':0, 'Fries':1,'Shrimp':2,'Pizza':3,'Chicken':4,'Fish':5,'Steak':6,'Cake':7,'Bacon':8,'Preheat':9,'Custom':10}
INDEXES_FOODS=hct.reverse_map(FOODS_INDEXES)
FOODS=hct.get_keys(FOODS_INDEXES)

hct.Select(   
    'Cookbook',
    FOODS,
    nil,
    'mdi:chef-hat',
    {/value->INDEXES_FOODS[value]:'tuyareceived#dptype4id3'},
    /value->tasmota.cmd('TuyaEnum1 '+str(FOODS_INDEXES.find(value)))
)   

hct.Button(        
    'Upgrade Tasmota',
    nil,
    'mdi:update',
    /value->tasmota.cmd("upgrade 1")
)

hct.Sensor(   
    'Time Remaining',    
    'minutes',
    nil,
    nil,
    'mdi:timer',
    'tuyareceived#dptype2Id8'
)

hct.Switch(   
    'Power',        
    nil,
    'mdi:power',
    'power1#state',    
    /value->tasmota.set_power(0,value)
)

hct.Switch(   
    'Cook/Pause',        
    nil,
    'mdi:play-pause',
    'power2#state',    
    /value->tasmota.set_power(1,value)
)

hct.BinarySensor(   
    'Keep Warm',        
    nil,
    'mdi:sync-circle',
    'power3#state'
)

hct.BinarySensor(   
    'Delay',        
    nil,
    'mdi:pause-circle',
    'power4#state'
)
