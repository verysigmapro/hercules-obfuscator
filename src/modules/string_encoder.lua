local StringEncoder = {}

local function generate_random_name(len)
  len = len or math.random(8, 12)
  local charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
  local name = ""
  for _ = 1, len do
    local index = math.random(1, #charset)
    name = name .. charset:sub(index, index)
  end
  return name
end

local function is_valid_char(byte)
  return (byte >= 48 and byte <= 57) or (byte >= 65 and byte <= 90) or (byte >= 97 and byte <= 122)
end

local function next_seed(s)
  return (s * 214013 + 2531011) % 4294967296
end

local function bxor(a, b)
  local result = 0
  for i = 0, 7 do
    local bit_a = a % 2
    local bit_b = b % 2
    if bit_a ~= bit_b then
      result = result + 2^i
    end
    a = math.floor(a / 2)
    b = math.floor(b / 2)
  end
  return result
end

local function encryption(data, seed)
  local result = {}
  local current_seed = seed
  
  for i = 1, #data do
    local byte = data:byte(i)
    current_seed = next_seed(current_seed)
    local key_byte = current_seed % 256
    
    if is_valid_char(byte) then
      if byte >= 48 and byte <= 57 then
        current_seed = next_seed(current_seed)
        local offset = current_seed % 10
        byte = ((byte - 48 + offset) % 10) + 48
      elseif byte >= 65 and byte <= 90 then
        current_seed = next_seed(current_seed)
        local offset = current_seed % 26
        byte = ((byte - 65 + offset) % 26) + 65
      elseif byte >= 97 and byte <= 122 then
        current_seed = next_seed(current_seed)
        local offset = current_seed % 26
        byte = ((byte - 97 + offset) % 26) + 97
      end
    end
    
    byte = bxor(byte, key_byte)
    table.insert(result, string.char(byte))
  end
  
  return table.concat(result)
end

local function decode_function(decrypt_func_name, isvalid_func_name, result_var, code_var, seed_var, byte_var)
  local code = [[
local function next_seed(s)
  return (s * 214013 + 2531011) % 4294967296
end

local function bxor(a, b)
  local result = 0
  for i = 0, 7 do
    local bit_a = a % 2
    local bit_b = b % 2
    if bit_a ~= bit_b then
      result = result + 2^i
    end
    a = math.floor(a / 2)
    b = math.floor(b / 2)
  end
  return result
end

local function ]] .. isvalid_func_name .. [[(]] .. byte_var .. [[)
  return (]] .. byte_var .. [[ >= 48 and ]] .. byte_var .. [[ <= 57) or (]] .. byte_var .. [[ >= 65 and ]] .. byte_var .. [[ <= 90) or (]] .. byte_var .. [[ >= 97 and ]] .. byte_var .. [[ <= 122)
end

local function ]] .. decrypt_func_name .. [[(]] .. code_var .. [[, ]] .. seed_var .. [[)
  local ]] .. result_var .. [[ = {}
  local current_seed = ]] .. seed_var .. [[
  
  for i = 1, #]] .. code_var .. [[ do
    local ]] .. byte_var .. [[ = ]] .. code_var .. [[:byte(i)
    current_seed = next_seed(current_seed)
    local key_byte = current_seed % 256
    
    ]] .. byte_var .. [[ = bxor(]] .. byte_var .. [[, key_byte)
    
    if ]] .. isvalid_func_name .. [[(]] .. byte_var .. [[) then
      if ]] .. byte_var .. [[ >= 48 and ]] .. byte_var .. [[ <= 57 then
        current_seed = next_seed(current_seed)
        local offset = current_seed % 10
        ]] .. byte_var .. [[ = ((]] .. byte_var .. [[ - 48 - offset + 10) % 10) + 48
      elseif ]] .. byte_var .. [[ >= 65 and ]] .. byte_var .. [[ <= 90 then
        current_seed = next_seed(current_seed)
        local offset = current_seed % 26
        ]] .. byte_var .. [[ = ((]] .. byte_var .. [[ - 65 - offset + 26) % 26) + 65
      elseif ]] .. byte_var .. [[ >= 97 and ]] .. byte_var .. [[ <= 122 then
        current_seed = next_seed(current_seed)
        local offset = current_seed % 26
        ]] .. byte_var .. [[ = ((]] .. byte_var .. [[ - 97 - offset + 26) % 26) + 97
      end
    end
    
    table.insert(]] .. result_var .. [[, string.char(]] .. byte_var .. [[))
  end
  
  return table.concat(]] .. result_var .. [[)
end
]]
  return code
end

function StringEncoder.process(code)
  local random_decrypt_name = generate_random_name()
  local random_isvalidchar_name = generate_random_name()
  local random_result_name = generate_random_name()
  local random_code_name = generate_random_name()
  local random_seed_name = generate_random_name()
  local random_byte_name = generate_random_name()

  local decode_function = decode_function(random_decrypt_name, random_isvalidchar_name, random_result_name, random_code_name, random_seed_name, random_byte_name)
  
  code = code:gsub('\\"', '!@!'):gsub("\\'", "@!@")
  code = code:gsub("(['\"])(.-)%1", function(quote, str)
    if type(str) == "string" then
      str = str:gsub('!@!', '\\"'):gsub('@!@', "\\'")
      local seed = math.random(100000, 999999999)
      local encoded_str = encryption(str, seed)
      return string.format("%s(%s%s%s, %d)", random_decrypt_name, quote, encoded_str, quote, seed)
    else
      return str
    end
  end)
  return decode_function .. "\n" .. code
end

return StringEncoder
