--dofile("WireBait/wirebait.lua")

local wireshark = require("wirebait.test.wireshark_mock")
local wirebait = require("wirebait.wirebait")


--[[ Simple protocol "smp" with header containing sequence number + payload containing N messages
    header :
        - uint64 sequence_number
    payload : 
        message_header:
            - uint8 message_type
            - uint16 message_size
            - uint8 is_urgent 1 = true, 0 = false
            - char[24] username
        message_payload:
            <depending on message type>
--]]--


--wirebait.dissector.dissectionFunction = function (buffer, packet_info, tree)

local function dissectionFunction(buffer, packet_info, tree)
    root_tree = wirebait.newTreeitem(tree, buffer, { auto_fit = true });
    
    --Dissecting packet header
    packet_header_tree = root_tree:add("smp.packetHeader", "Packet Header");
    packet_header_tree:addUint64("smp.pkt_seq_no", "Packet Sequence Number");
    
    --Dissecting packet payload
    packet_payload_tree = root_tree:add("smp.Payload", "Packet Payload");
    while packet_payload_tree:position() < buffer:len() do
        --Dissecting message header and message in same tree
        msg_tree = packet_payload_tree:add("smp.msg", "Message");
        _,msg_type msg_tree:addUint8("smp.msg_type", "Message Type", {[1] = "Login", [2] = "Transmit", [3] = "Logout"} )
        _,msg_size = msg_tree:addUint16("smp.msg_size", "Message Size")
        msg_tree:addUint8("smp.urgent", "Urgent", {[1] = "YES", [0] = "NO"});
        begin_msg_position,username = msg_tree:addCharArray("smp.username", "Username", 24);
        
        if(msg_type == 0x01) then
            --TODO: dissect Login msg
        elseif (msg_type == 0x02) then
            --TODO: dissect Transmit msg
        elseif (msg_type == 0x03) then
            --TODO: dissect Logout msg
        else
            warn("Unknown message type '" .. msg_type .. "' sent by '" .. username .. "'!");
        end
        
        msg_tree:skipTo(begin_msg_position + msg_size);
    end
end


local wb_dissector = wirebait.newDissector("smp", "Simple Protocol", dissectionFunction);

