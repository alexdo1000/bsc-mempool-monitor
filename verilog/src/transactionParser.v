module tx_parser (
    input wire clk,
    input wire rst_n,
    input wire [7:0] p2p_cmd,
    input wire [31:0] p2p_length,
    input wire [7:0] p2p_payload[0:8191],
    input wire p2p_valid,
    
    // Transaction output interface
    output reg [255:0] tx_hash,
    output reg [159:0] tx_from,
    output reg [159:0] tx_to,
    output reg [255:0] tx_value,
    output reg [255:0] tx_gas_price,
    output reg tx_valid
);

    // RLP decoding states
    localparam IDLE = 3'b000;
    localparam PARSE_TX_LIST = 3'b001;
    localparam PARSE_TX = 3'b010;
    localparam PARSE_TX_FIELDS = 3'b011;
    localparam TX_COMPLETE = 3'b100;

    reg [2:0] state;
    reg [31:0] payload_index;
    reg [31:0] tx_length;
    reg [31:0] field_length;
    reg [7:0] field_type;

    // RLP length decoding function
    function [31:0] decode_rlp_length;
        input [7:0] first_byte;
        begin
            if (first_byte < 8'h80)
                decode_rlp_length = 1;
            else if (first_byte < 8'hB8)
                decode_rlp_length = first_byte - 8'h80;
            else if (first_byte < 8'hC0)
                decode_rlp_length = first_byte - 8'hB7;
            else
                decode_rlp_length = 0;
        end
    endfunction

    // Transaction parser state machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            tx_valid <= 1'b0;
            payload_index <= 32'h0;
        end else begin
            case (state)
                IDLE: begin
                    if (p2p_valid && p2p_cmd == 8'h02) begin // P2P_TRANSACTIONS
                        state <= PARSE_TX_LIST;
                        payload_index <= 32'h0;
                        tx_valid <= 1'b0;
                    end
                end

                PARSE_TX_LIST: begin
                    // Parse RLP list of transactions
                    tx_length <= decode_rlp_length(p2p_payload[payload_index]);
                    payload_index <= payload_index + 1;
                    state <= PARSE_TX;
                end

                PARSE_TX: begin
                    // Parse individual transaction
                    field_type <= p2p_payload[payload_index];
                    field_length <= decode_rlp_length(p2p_payload[payload_index]);
                    payload_index <= payload_index + 1;
                    state <= PARSE_TX_FIELDS;
                end

                PARSE_TX_FIELDS: begin
                    // Parse transaction fields (nonce, gasPrice, gasLimit, to, value, data, v, r, s)
                    case (field_type)
                        8'h80: begin // nonce
                            // Store nonce
                            payload_index <= payload_index + field_length;
                        end
                        8'h81: begin // gasPrice
                            // Store gasPrice
                            tx_gas_price <= {p2p_payload[payload_index + field_length - 1],
                                          p2p_payload[payload_index + field_length - 2],
                                          // ... more bytes ...
                                          p2p_payload[payload_index]};
                            payload_index <= payload_index + field_length;
                        end
                        // ... handle other fields ...
                    endcase
                    
                    if (payload_index >= tx_length) begin
                        state <= TX_COMPLETE;
                        tx_valid <= 1'b1;
                    end
                end

                TX_COMPLETE: begin
                    tx_valid <= 1'b0;
                    if (payload_index >= p2p_length) begin
                        state <= IDLE;
                    end else begin
                        state <= PARSE_TX;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule