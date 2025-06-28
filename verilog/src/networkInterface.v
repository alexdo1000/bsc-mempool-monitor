module eth_p2p_interface (
    input wire clk,                    // System clock
    input wire rst_n,                  // Active low reset
    input wire [63:0] eth_rx_data,     // Ethernet receive data
    input wire eth_rx_valid,           // Ethernet receive valid
    input wire eth_rx_sof,             // Start of frame
    input wire eth_rx_eof,             // End of frame
    
    // P2P packet interface
    output reg [7:0] p2p_cmd,          // P2P command type
    output reg [31:0] p2p_length,      // P2P packet length
    output reg [7:0] p2p_payload[0:8191], // P2P payload (max 8KB)
    output reg p2p_valid,              // P2P packet valid
    output reg p2p_sof,                // Start of P2P packet
    output reg p2p_eof                 // End of P2P packet
);

    // P2P protocol constants
    localparam P2P_NEW_BLOCK_HASHES = 8'h01;
    localparam P2P_TRANSACTIONS = 8'h02;
    localparam P2P_GET_BLOCK_HEADERS = 8'h03;
    localparam P2P_BLOCK_HEADERS = 8'h04;
    localparam P2P_GET_BLOCK_BODIES = 8'h05;
    localparam P2P_BLOCK_BODIES = 8'h06;
    localparam P2P_NEW_BLOCK = 8'h07;
    localparam P2P_GET_NODES = 8'h0d;
    localparam P2P_NODES = 8'h0e;
    localparam P2P_GET_RECEIPTS = 8'h0f;
    localparam P2P_RECEIPTS = 8'h10;

    // State machine states
    localparam IDLE = 3'b000;
    localparam WAIT_FOR_PACKET = 3'b001;
    localparam PARSE_HEADER = 3'b010;
    localparam STORE_PAYLOAD = 3'b011;
    localparam PACKET_COMPLETE = 3'b100;

    reg [2:0] state;
    reg [31:0] payload_counter;
    reg [31:0] expected_length;

    // P2P packet parser state machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            p2p_valid <= 1'b0;
            p2p_sof <= 1'b0;
            p2p_eof <= 1'b0;
            payload_counter <= 32'h0;
        end else begin
            case (state)
                IDLE: begin
                    if (eth_rx_valid && eth_rx_sof) begin
                        state <= PARSE_HEADER;
                        p2p_sof <= 1'b1;
                        p2p_valid <= 1'b0;
                    end
                end

                PARSE_HEADER: begin
                    p2p_sof <= 1'b0;
                    // Parse P2P header (first 8 bytes)
                    p2p_cmd <= eth_rx_data[7:0];
                    p2p_length <= eth_rx_data[39:8];
                    expected_length <= eth_rx_data[39:8];
                    state <= STORE_PAYLOAD;
                    payload_counter <= 32'h0;
                end

                STORE_PAYLOAD: begin
                    if (eth_rx_valid) begin
                        // Store payload data
                        p2p_payload[payload_counter] <= eth_rx_data[7:0];
                        p2p_payload[payload_counter + 1] <= eth_rx_data[15:8];
                        p2p_payload[payload_counter + 2] <= eth_rx_data[23:16];
                        p2p_payload[payload_counter + 3] <= eth_rx_data[31:24];
                        p2p_payload[payload_counter + 4] <= eth_rx_data[39:32];
                        p2p_payload[payload_counter + 5] <= eth_rx_data[47:40];
                        p2p_payload[payload_counter + 6] <= eth_rx_data[55:48];
                        p2p_payload[payload_counter + 7] <= eth_rx_data[63:56];
                        
                        payload_counter <= payload_counter + 8;
                        
                        if (payload_counter + 8 >= expected_length) begin
                            state <= PACKET_COMPLETE;
                            p2p_eof <= 1'b1;
                            p2p_valid <= 1'b1;
                        end
                    end
                end

                PACKET_COMPLETE: begin
                    p2p_eof <= 1'b0;
                    p2p_valid <= 1'b0;
                    state <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule