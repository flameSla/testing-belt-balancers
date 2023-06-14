local bit = require('scripts.numberlua')


local test_data = {}


--//////////////////////////////////////////////////////////////////////////
function dec_to_bin(a)
    local result = ""
    for i=1,32 do
        result = result .. ((bit.band(a, 2147483648)==0) and "0" or "1")
        a = bit.lshift(a, 1)
    end
    return result
end
--//////////////////////////////////////////////////////////////////////////
-- get all combinations
--//////////////////////////////////////////////////////////////////////////

-- https://gist.github.com/2064991
local function memoize(f)
  local mt = {}
  local t = setmetatable({}, mt)
  function mt:__index(k)
    local v = f(k); t[k] = v
    return v
  end
  return t
end
-- Hamming weight of 32-bit integer.
-- Simple (naive) implementation.
local function hw_simple(x)
  local sum = 0
  while x ~= 0 do
    sum = sum + bit.band(x, 1)
    x = bit.rshift(x, 1)
  end
  return sum
end

local HW = memoize(hw_simple)
local function popcount(x)
  local n0 = x % 256; local x = (x - n0) / 256
  local n1 = x % 256; local x = (x - n1) / 256
  local n2 = x % 256; local x = (x - n2) / 256
  local n3 = x
  return HW[n0] + HW[n1] + HW[n2] + HW[n3]
end

function brute_force( min_popcount, max_popcount, number_of_bits)
    result = {}
    index = 1
    max_i = bit.lshift(1, number_of_bits) - 1
    --print("max_i = " .. max_i)
    for i=0, max_i do
        countSetBits = popcount(i)
        --print("i = " .. i .. "\tcountSetBits = " .. countSetBits)
        if countSetBits >= min_popcount and countSetBits <= max_popcount then
            result[index] = i
            index = index + 1
        end
    end
    return result;
end
--//////////////////////////////////////////////////////////////////////////
function test_print(message)
    game.print(message)
    game.write_file(test_data.name_of_log_file, message .. "\n", true)
end
--//////////////////////////////////////////////////////////////////////////
function test_init()
    test_data.inp = {}
    test_data.out = {}
    test_data.max_inp = 0
    test_data.max_out = 0
    test_data.name_of_log_file = 'testing-belt-balancers.log'
    test_data.step = 0
    test_data.inp_bandwidth = {}
    test_data.inp_bandwidth_0 = {}
    test_data.inp_bandwidth_1 = {}
    test_data.out_bandwidth = {}
    test_data.out_bandwidth_0 = {}
    test_data.out_bandwidth_1 = {}
    local index = 0
    local p=game.player 
    test_data.player = p

    index = 1
    local e=p.surface.find_entities_filtered{name='chest-source-for-testing'}
    for _, i in pairs(e) do
        test_data.inp[index] = i
        index = index + 1
    end
    test_data.max_inp = #test_data.inp

    index = 1
    local e=p.surface.find_entities_filtered{name='chest-consumer-for-testing'}
    for _, i in pairs(e) do
        test_data.out[index] = i
        index = index + 1
    end
    test_data.max_out = #test_data.out

    test_print('------------------------------------')
    local message = "inp: " .. test_data.max_inp .. " out: " .. test_data.max_out
    test_print(message)

end
--//////////////////////////////////////////////////////////////////////////
function test_init_all()
    test_print("test_init_all")
    test_data.combinations_for_inp = brute_force( 1, test_data.max_inp, test_data.max_inp)
    test_data.combinations_for_out = brute_force( 1, test_data.max_out, test_data.max_out)

    message = #test_data.combinations_for_inp .. "*" .. #test_data.combinations_for_out .. " = " .. #test_data.combinations_for_inp * #test_data.combinations_for_out .. " combinations"
    test_print(message)
    
    game.write_file(test_data.name_of_log_file, game.table_to_json(test_data.combinations_for_inp) .. "\n", true)
    game.write_file(test_data.name_of_log_file, game.table_to_json(test_data.combinations_for_out) .. "\n", true)
    test_print("")
end
--//////////////////////////////////////////////////////////////////////////
function test_init_2()
    test_print("test_init_2")
    test_data.combinations_for_inp = brute_force( 2, 2, test_data.max_inp)
    test_data.combinations_for_out = brute_force( 2, 2, test_data.max_out)

    message = #test_data.combinations_for_inp .. "*" .. #test_data.combinations_for_out .. " = " .. #test_data.combinations_for_inp * #test_data.combinations_for_out .. " combinations"
    test_print(message)
    
    game.write_file(test_data.name_of_log_file, game.table_to_json(test_data.combinations_for_inp) .. "\n", true)
    game.write_file(test_data.name_of_log_file, game.table_to_json(test_data.combinations_for_out) .. "\n", true)
    test_print("")
end
--//////////////////////////////////////////////////////////////////////////
function get_contents(a)
    local result = {}
    for i=1, #a do     
        result[i] = a[i].get_output_inventory().get_item_count()
    end
    return result
end
--//////////////////////////////////////////////////////////////////////////
function get_full_bandwidth()
    local i = popcount(test_data.combinations_for_inp[test_data.i_inp]) --number of source chests
    local o = popcount(test_data.combinations_for_out[test_data.i_out]) --number of consumer chests
    i = (o < i) and o or i
    local inp = i*45
    local out = 0
    for i=1,#test_data.out_bandwidth do
        out = out + test_data.out_bandwidth[i]
    end
    return 100*(out/inp)
end
--//////////////////////////////////////////////////////////////////////////
function drum_machine(EventData)
    if test_data.step == 0 then
        -- cycle start
        test_data.i_inp = 1
        test_data.i_out = 0
        test_data.step = 1
        game.speed = 1000
    end
    if test_data.step == 1 then
        -- main cycle
        test_data.i_out = test_data.i_out + 1
        if test_data.i_out > #test_data.combinations_for_out then
            test_data.i_out = 1
            test_data.i_inp = test_data.i_inp + 1
            if test_data.i_inp > #test_data.combinations_for_inp then
                -- all options are checked
                script.on_nth_tick(EventData.nth_tick,nil)
                game.speed = 1
                test_data.step = 255
                game.print("Testing completed")
                return
            end
        end
        game.print("i_inp = " .. test_data.i_inp .. " i_out = " .. test_data.i_out)
        test_data.step = 2
    end
    if test_data.step == 2 then
        -- clear the chests
        for i=1, #test_data.inp do
            test_data.inp[i].get_output_inventory().clear()
        end
        for i=1, #test_data.out do
            test_data.out[i].get_output_inventory().set_bar()
        end
        game.print("clear the chests")
        test_data.step = 3
    end
    if test_data.step == 3 then
        -- clear belts
        test_data.step = 4
        --local name_to_search = {'transport-belt', 'splitter', 'fast-transport-belt', 'fast-splitter', 'express-transport-belt', 'express-splitter','underground-belt','fast-underground-belt','express-underground-belt'}
        local name_to_search = {'transport-belt', 'fast-transport-belt', 'express-transport-belt', 'underground-belt','fast-underground-belt','express-underground-belt'}
        local e=test_data.player.surface.find_entities_filtered{name=name_to_search}
        local items = 0
        for _, i in pairs(e) do     
            items = items + i.get_item_count()
        end
        --game.print("items on belts = " .. items)
        if items == 0 then
            test_data.step = 4
        end
    end
    if test_data.step == 4 then
        -- set the configuration of chests
        local inp = test_data.combinations_for_inp[test_data.i_inp]
        game.print("inp = " .. inp)
        for i=1, #test_data.inp do
            if bit.band(inp, 1) == 1 then
                test_data.inp[i].get_output_inventory().insert({name="iron-plate", count=27000})
            end
            inp = bit.rshift(inp, 1)
        end
        local out = test_data.combinations_for_out[test_data.i_out]
        game.print("out = " .. out)
        for i=1, #test_data.out do
            test_data.out[i].get_output_inventory().clear()
            if bit.band(out, 1) == 1 then
                test_data.out[i].get_output_inventory().set_bar()
            else
                test_data.out[i].get_output_inventory().set_bar(1)
            end
            out = bit.rshift(out, 1)
        end
        test_data.step = 5
        --game.print("step = " .. test_data.step)
        test_data.inp_contents = get_contents(test_data.inp)
        for i=1,#test_data.inp_contents do
            test_data.inp_bandwidth_0[i] = 0
            test_data.inp_bandwidth_1[i] = 0
        end
        test_data.out_contents = get_contents(test_data.out)
        for i=1,#test_data.out_contents do
            test_data.out_bandwidth_0[i] = 0
            test_data.out_bandwidth_1[i] = 0
        end
        test_data.count = 600
    elseif test_data.step == 5 then
        -- bandwidth calculation
        test_data.count = test_data.count - 1
        local temp = get_contents(test_data.out)
        for i=1,#temp do
            test_data.out_bandwidth_0[i] = test_data.out_bandwidth_1[i]
            test_data.out_bandwidth_1[i] = temp[i] - test_data.out_contents[i]
            test_data.out_bandwidth[i] = (test_data.out_bandwidth_0[i] + test_data.out_bandwidth_1[i]) / 2
        end
        test_data.out_contents = temp

        local temp = get_contents(test_data.inp)
        local empty_chest_counter = 0
        for i=1,#temp do
            if temp[i] < 1000 then
                empty_chest_counter = empty_chest_counter + 1
            end
            test_data.inp_bandwidth_0[i] = test_data.inp_bandwidth_1[i]
            test_data.inp_bandwidth_1[i] = temp[i] - test_data.inp_contents[i]
            test_data.inp_bandwidth[i] = (test_data.inp_bandwidth_0[i] + test_data.inp_bandwidth_1[i]) / 2
        end
        test_data.inp_contents = temp
        --game.print("inp_bandwidth: " .. game.table_to_json(test_data.inp_bandwidth))
        --game.print("out_bandwidth: " .. game.table_to_json(test_data.out_bandwidth))
        if empty_chest_counter == #temp or test_data.count <= 0 then
            --game.print("finish !!!")
            local message = ""
            message = message .. " inp:" .. dec_to_bin(test_data.combinations_for_inp[test_data.i_inp])
            message = message .. " out:" .. dec_to_bin(test_data.combinations_for_out[test_data.i_out])
            message = message .. " inp_bandwidth: " .. game.table_to_json(test_data.inp_bandwidth)
            message = message .. " out_bandwidth: " .. game.table_to_json(test_data.out_bandwidth)
            message = message .. "   Throughput: " .. get_full_bandwidth() .. "%"
            test_print(message)

            test_data.step = 1
        end
    end
end
--//////////////////////////////////////////////////////////////////////////
script.on_init(function()
    register_commands()
end)

script.on_load(function()
    register_commands()
end)
--//////////////////////////////////////////////////////////////////////////
function processing_commands(event)
    local parameter = event.parameter == nil and '' or event.parameter
    local res = string.match(parameter, 'init%Dall')
    if res ~= nil then
        test_init()
        test_init_all()
    end
    local res = string.match(parameter, 'init%D2')
    if res ~= nil then
        test_init()
        test_init_2()
    end
    local res = string.match(parameter, 'start')
    if res ~= nil then
        script.on_nth_tick(60, drum_machine)
    end
end
--//////////////////////////////////////////////////////////////////////////
function register_commands()
    commands.add_command("test","init-2 init-all start", function(param)
        processing_commands(param)
    end)
end
--//////////////////////////////////////////////////////////////////////////





