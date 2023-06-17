local bit = require("scripts.numberlua")

local test_data = {}

--//////////////////////////////////////////////////////////////////////////
-- // floor division (lua 5.3)
function idiv(b, n)
    return (b / n) - ((b / n) % 1)
end
--//////////////////////////////////////////////////////////////////////////
function dec_to_bin(a)
    local result = ""
    for i = 1, 32 do
        result = result .. ((bit.band(a, 2147483648) == 0) and "0" or "1")
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
        local v = f(k)
        t[k] = v
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
    local n0 = x % 256
    local x = (x - n0) / 256
    local n1 = x % 256
    local x = (x - n1) / 256
    local n2 = x % 256
    local x = (x - n2) / 256
    local n3 = x
    return HW[n0] + HW[n1] + HW[n2] + HW[n3]
end

function brute_force(min_popcount, max_popcount, number_of_bits)
    result = {}
    max_i = bit.lshift(1, number_of_bits) - 1
    for i = 0, max_i do
        countSetBits = popcount(i)
        if countSetBits >= min_popcount and countSetBits <= max_popcount then
            table.insert(result, i)
        end
    end
    return result
end
--//////////////////////////////////////////////////////////////////////////
function test_print(message, print_is_enabled)
    if print_is_enabled then
        game.print(message)
    end
    game.write_file(test_data.name_of_log_file, message .. "\n", true)
end
--//////////////////////////////////////////////////////////////////////////
function test_print_table(a, text)
    local message = ""
    test_print(text, true)
    for i = 1, #a do
        message = message .. i .. "-" .. tostring(a[i].unit_number) .. " "
    end
    test_print(message, true)
end
--//////////////////////////////////////////////////////////////////////////
function test_init()
    test_data.inp = {}
    test_data.out = {}
    test_data.max_inp = 0
    test_data.max_out = 0
    test_data.name_of_log_file = "testing-belt-balancers.log"
    test_data.step = 0
    test_data.inp_bandwidth = {}
    test_data.inp_bandwidth_fifo = {}
    test_data.out_bandwidth = {}
    test_data.out_bandwidth_fifo = {}
    test_data.n = test_data.n or 0
    local p = game.player or test_data.player
    test_data.player = p

    local e = p.surface.find_entities_filtered {name = "chest-source-for-testing"}
    for _, i in pairs(e) do
        table.insert(test_data.inp, i)
    end
    test_data.max_inp = #test_data.inp

    local e = p.surface.find_entities_filtered {name = "chest-consumer-for-testing"}
    for _, i in pairs(e) do
        table.insert(test_data.out, i)
    end
    test_data.max_out = #test_data.out

    test_print("------------------------------------", true)
    local message = "inp: " .. test_data.max_inp .. " out: " .. test_data.max_out
    test_print(message, true)

    table.sort(
        test_data.inp,
        function(a, b)
            return a.unit_number < b.unit_number
        end
    )
    table.sort(
        test_data.out,
        function(a, b)
            return a.unit_number < b.unit_number
        end
    )
    --test_print_table(test_data.inp, "test_data.inp")
    --test_print_table(test_data.out, "test_data.out")
end
--//////////////////////////////////////////////////////////////////////////
-- get time to test all combinations
-- assumption: testing one combination = 1sec
function test_get_time(a)
    local drum = test_data.starting_value_of_counter or 600
    local a = a * drum / 600
    local sec = a % 60
    local min = idiv(a, 60) % 60
    local hours = idiv(a, 3600) % 24
    local days = idiv(a, 24 * 3600)
    return string.format("%d days %d hours %d minutes %d seconds", days, hours, min, sec)
end
--//////////////////////////////////////////////////////////////////////////
function test_print_the_number_of_combinations()
    local i = #test_data.combinations_for_inp
    local o = #test_data.combinations_for_out
    local combinations = i * o
    message = i .. "*" .. o .. " = " .. combinations .. " combinations (" .. test_get_time(combinations) .. ")"
    test_print(message, true)

    game.write_file(test_data.name_of_log_file, "drum = " .. test_data.starting_value_of_counter .. "\n", true)
    game.write_file(test_data.name_of_log_file, game.table_to_json(test_data.combinations_for_inp) .. "\n", true)
    game.write_file(test_data.name_of_log_file, game.table_to_json(test_data.combinations_for_out) .. "\n", true)
    test_print("")
end
--//////////////////////////////////////////////////////////////////////////
function test_init_all()
    test_print("test_init_all", true)
    test_data.combinations_for_inp = brute_force(1, test_data.max_inp, test_data.max_inp)
    test_data.combinations_for_out = brute_force(1, test_data.max_out, test_data.max_out)
end
--//////////////////////////////////////////////////////////////////////////
function test_init_2()
    test_print("test_init_2", true)
    test_data.combinations_for_inp = brute_force(2, 2, test_data.max_inp)
    test_data.combinations_for_out = brute_force(2, 2, test_data.max_out)
end
--//////////////////////////////////////////////////////////////////////////
function test_init_n(n)
    test_print("test_init_" .. tostring(n), true)
    test_data.combinations_for_inp = brute_force(n, n, test_data.max_inp)
    test_data.combinations_for_out = brute_force(n, n, test_data.max_out)
end
--//////////////////////////////////////////////////////////////////////////
-- get the contents of all chests
function get_contents(a)
    local result = {}
    for i = 1, #a do
        result[i] = a[i].get_output_inventory().get_item_count()
    end
    return result
end
--//////////////////////////////////////////////////////////////////////////
function get_full_bandwidth()
    local i = popcount(test_data.combinations_for_inp[test_data.i_inp]) --number of source chests
    local o = popcount(test_data.combinations_for_out[test_data.i_out]) --number of consumer chests
    local inp = 45 * math.min(i, o)
    local out = 0
    for i = 1, #test_data.out_bandwidth do
        out = out + test_data.out_bandwidth[i]
    end
    return math.min(100 * (out / inp), 100)
end
--//////////////////////////////////////////////////////////////////////////
-- Calculates the arithmetic mean of a set of values
function test_arithmetic_mean(x)
    local s = 0
    for i = 1, #x do
        s = s + x[i]
    end
    return s / #x
end
--//////////////////////////////////////////////////////////////////////////
function test_bandwidth_to_string(a)
    local result = "["
    for i = 1, #a do
        result = result .. "<" .. string.format("%5.1f", a[i]) .. ">"
    end
    --result = result:sub(1, -2) .. "]"
    result = result .. "]"
    return result
end
--//////////////////////////////////////////////////////////////////////////
-- called once every 60 ticks
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
        --  for(i_inp=1; i_inp < max_i_inp; i_inp++)
        --      for(i_out=1; i_out < max_i_out; i_out++)
        --          do-test()
        test_data.i_out = test_data.i_out + 1
        if test_data.i_out > #test_data.combinations_for_out then
            test_data.i_out = 1
            test_data.i_inp = test_data.i_inp + 1
            if test_data.i_inp > #test_data.combinations_for_inp then
                -- all options are checked
                test_data.step = 255
                return
            end
        end
        --game.print("i_inp = " .. test_data.i_inp .. " i_out = " .. test_data.i_out)
        test_data.step = 2
    end
    if test_data.step == 2 then
        -- clear the chests
        for i = 1, #test_data.inp do
            test_data.inp[i].get_output_inventory().clear()
        end
        for i = 1, #test_data.out do
            test_data.out[i].get_output_inventory().set_bar()
        end
        --game.print("clear the chests")
        test_data.step = 3
    end
    if test_data.step == 3 then
        -- clear belts
        -- deleted, there are few benefits, many problems
        test_data.step = 4
    end
    if test_data.step == 4 then
        -- set the configuration of chests
        local inp = test_data.combinations_for_inp[test_data.i_inp]
        --game.print("inp = " .. inp)
        for i = 1, #test_data.inp do
            if bit.band(inp, 1) == 1 then
                test_data.inp[i].get_output_inventory().insert({name = "iron-plate", count = 27000}) -- 10min -> 600sec * 45 = 27000
            end
            inp = bit.rshift(inp, 1)
        end
        local out = test_data.combinations_for_out[test_data.i_out]
        --game.print("out = " .. out)
        for i = 1, #test_data.out do
            test_data.out[i].get_output_inventory().clear()
            if bit.band(out, 1) == 1 then
                test_data.out[i].get_output_inventory().set_bar()
            else
                test_data.out[i].get_output_inventory().set_bar(1)
            end
            out = bit.rshift(out, 1)
        end
        test_data.inp_contents = get_contents(test_data.inp)
        for i = 1, #test_data.inp_contents do
            test_data.inp_bandwidth_fifo[i] = {0, 0, 0, 0}
        end
        test_data.out_contents = get_contents(test_data.out)
        for i = 1, #test_data.out_contents do
            test_data.out_bandwidth_fifo[i] = {0, 0, 0, 0}
        end
        -- maximum of 599 calls for the test
        -- (599 is better than 600 for averaging)
        -- it is necessary if there are no belts between the entrance and exit
        test_data.count = test_data.starting_value_of_counter or 599
        test_data.step = 5
    elseif test_data.step == 5 then
        -- bandwidth calculation
        test_data.count = test_data.count - 1
        local temp = get_contents(test_data.out)
        for i = 1, #temp do
            table.remove(test_data.out_bandwidth_fifo[i], 1)
            table.insert(test_data.out_bandwidth_fifo[i], temp[i] - test_data.out_contents[i])
            test_data.out_bandwidth[i] = test_arithmetic_mean(test_data.out_bandwidth_fifo[i])
        end
        test_data.out_contents = temp

        local temp = get_contents(test_data.inp)
        local empty_chest_counter = 0
        for i = 1, #temp do
            if temp[i] < 1000 then
                empty_chest_counter = empty_chest_counter + 1
            end
            table.remove(test_data.inp_bandwidth_fifo[i], 1)
            table.insert(test_data.inp_bandwidth_fifo[i], temp[i] - test_data.inp_contents[i])
            test_data.inp_bandwidth[i] = test_arithmetic_mean(test_data.inp_bandwidth_fifo[i])
        end
        test_data.inp_contents = temp
        --game.print("inp_bandwidth: " .. game.table_to_json(test_data.inp_bandwidth))
        --game.print("out_bandwidth: " .. game.table_to_json(test_data.out_bandwidth))
        if empty_chest_counter == #temp or test_data.count <= 0 then
            local message = ""
            message = message .. " inp:" .. dec_to_bin(test_data.combinations_for_inp[test_data.i_inp])
            message = message .. " out:" .. dec_to_bin(test_data.combinations_for_out[test_data.i_out])
            message = message .. " inp_bandwidth: " .. test_bandwidth_to_string(test_data.inp_bandwidth)
            message = message .. " out_bandwidth: " .. test_bandwidth_to_string(test_data.out_bandwidth)
            local throughput = get_full_bandwidth()
            message = message .. "   Throughput: " .. string.format("%.2f", throughput) .. "%"
            message = message .. ((throughput ~= 100) and "\t BAD!!!" or "")
            test_print(message)
            --game.print(game.table_to_json(test_data.inp_bandwidth_fifo))
            --game.print(game.table_to_json(test_data.out_bandwidth_fifo))

            test_data.step = 1
        end
    end
    if test_data.step == 255 then
        if test_data.n <= 0 then
            -- all options are checked
            script.on_nth_tick(EventData.nth_tick, nil)
            game.speed = 1
            test_data.step = 256
            game.print("Testing completed")
            return
        else
            test_init()
            test_init_n(test_data.n)
            test_print_the_number_of_combinations()

            test_data.n = test_data.n - 1
            test_data.step = 0
        end
    end
end
--//////////////////////////////////////////////////////////////////////////
function factorial(n)
    if n <= 0 then
        return 1
    else
        return n * factorial(n - 1)
    end
end

function k_combinations(k, n)
    local res = factorial(n) / (factorial(k) * factorial(n - k))
    return res
end
--//////////////////////////////////////////////////////////////////////////
function test_print_the_number_of_n_combinations(n, number_of_bits)
    test_print("************************************", true)
    test_print("test_init_n-all", true)
    test_print("************************************", true)

    local combinations = 0
    for i = 1, n do
        combinations = combinations + k_combinations(i, number_of_bits) ^ 2
    end

    local message = combinations .. " combinations"
    test_print(message, true)
    test_print("")
end
--//////////////////////////////////////////////////////////////////////////
script.on_init(
    function()
        register_commands()
    end
)

script.on_load(
    function()
        register_commands()
    end
)
--//////////////////////////////////////////////////////////////////////////
function processing_commands(event)
    local parameter = event.parameter == nil and "" or event.parameter
    local par = "drum="
    local res = string.match(parameter, par)
    if res ~= nil then
        res = string.match(parameter, par .. "%d+")
        res = string.gsub(res, par, "")
        res = tonumber(res)
        test_data.starting_value_of_counter = res
    end
    local res = string.match(parameter, "init.all")
    if res ~= nil then
        test_init()
        test_init_all()
        test_print_the_number_of_combinations()
    end
    local res = string.match(parameter, "init.2")
    if res ~= nil then
        test_init()
        test_init_2()
        test_print_the_number_of_combinations()
    end
    local res = string.match(parameter, "init.n=")
    if res ~= nil then
        test_init()
        local par = "n="
        local res = string.match(parameter, par)
        if res ~= nil then
            res = string.match(parameter, par .. "%d+")
            res = string.gsub(res, par, "")
            res = tonumber(res)
            test_data.n = res
        end
        test_data.n = math.min(test_data.n, test_data.max_inp, test_data.max_out)
        test_print_the_number_of_n_combinations(test_data.n, test_data.n)
        game.print("n = " .. tostring(test_data.n))
        test_data.step = 255
    end
    local res = string.match(parameter, "start")
    if res ~= nil then
        script.on_nth_tick(60, drum_machine)
    end
end
--//////////////////////////////////////////////////////////////////////////
function register_commands()
    commands.add_command(
        "test",
        "init-2 init-all start drum=600",
        function(param)
            processing_commands(param)
        end
    )
end
--//////////////////////////////////////////////////////////////////////////
