/*
Author: Dennis Grabiak
Description: Recieves and Parses Ethernet Frame and checks for ARP Request.
             If the frame is an ARP Request, an ARP Response is sent.
*/

module arp_response (input  ARESET,
                     input  [47:0] MY_MAC,
                     input  [31:0] MY_IPV4,
                     input  CLK_RX,
                     input  DATA_VALID_RX,
                     input  [7:0] DATA_RX,
                     input  CLK_TX,
                     input  DATA_ACK_TX,
                     output reg DATA_VALID_TX,
                     output reg [7:0] DATA_TX
                    );

  reg [3:0] rx_byte;
  reg [3:0] tx_byte;
  reg arp_req;
  reg [0:1] arp_req_tx;
  reg DATA_VALID_RX_Q;
  reg [47:0] THIER_MAC;
  reg [31:0] THIER_IPV4;

  // FSM
  reg [3:0] rx_state;
  reg [3:0] tx_state;
  localparam IDLE          = 4'b0000;
  localparam DEST_MAC      = 4'b0001;
  localparam SRC_MAC       = 4'b0010;
  localparam ETH_TYPE      = 4'b0011;
  localparam HRD           = 4'b0100;
  localparam PRO           = 4'b0101;
  localparam HLN           = 4'b0110;
  localparam PLN           = 4'b0111;
  localparam OP            = 4'b1000;
  localparam SHA           = 4'b1001;
  localparam SPA           = 4'b1010;
  localparam THA           = 4'b1011;
  localparam TPA           = 4'b1100;
  localparam WAIT_FOR_HS   = 4'b1101;

  // Number of bytes per field
  localparam DEST_MAC_SIZE = 6;
  localparam SRC_MAC_SIZE  = 6;
  localparam ETH_TYPE_SIZE = 2;
  localparam HRD_SIZE      = 2;
  localparam PRO_SIZE      = 2;
  localparam HLN_SIZE      = 1;
  localparam PLN_SIZE      = 1;
  localparam OP_SIZE       = 2;
  localparam SHA_SIZE      = 6;
  localparam SPA_SIZE      = 4;
  localparam THA_SIZE      = 6;
  localparam TPA_SIZE      = 4;

  // Expected field values for a compatible Ethernet IPV4 ARP Request
  localparam [15:0] ETH_TYPE_VALUE      = 16'h0806;
  localparam HRD_VALUE           = 16'h0001;
  localparam PRO_VALUE           = 16'h0800;
  localparam HLN_VALUE           = 8'h06;
  localparam PLN_VALUE           = 8'h04;
  localparam OP_VALUE            = 16'h0001;

  reg [8:0] rx_check;

  // Check for ARP Request
  always @ (posedge CLK_RX)
  begin
    if(ARESET) begin
      rx_byte  <= 4'b0000;
      rx_state <= IDLE;
    end else begin
      DATA_VALID_RX_Q <= DATA_VALID_RX;
      // Start parsing frame using edge detect
      case (rx_state)

        IDLE:
        begin
          if(DATA_VALID_RX == 1 && DATA_VALID_RX_Q == 0)
            rx_state <= DEST_MAC;
        end

        DEST_MAC:
        begin
          if(DATA_VALID_RX == 1) begin
            if (rx_byte == DEST_MAC_SIZE-2) begin
              rx_byte  <= 4'b0000;
              rx_state <= SRC_MAC;
            end else
              rx_byte <= rx_byte+1;
          end else begin
            rx_state <= IDLE;
            rx_byte  <= 4'b0000;
          end
        end

        SRC_MAC:
        begin
          if(DATA_VALID_RX == 1) begin
            THIER_MAC[7+rx_byte*8 -: 8] <= DATA_RX;
            if (rx_byte == SRC_MAC_SIZE-1) begin
              rx_byte  <= ETH_TYPE_SIZE-1;
              rx_state <= ETH_TYPE;
            end else begin
              rx_byte <= rx_byte+1;
            end
          end else begin
            rx_state <= IDLE;
            rx_byte  <= 4'b0000;
          end
        end

        ETH_TYPE:
        begin
          if(DATA_VALID_RX == 1) begin
            rx_check <= ETH_TYPE_VALUE[7+rx_byte*8 -: 8];
            // Check for expected value in ARP Request
            if (DATA_RX == ETH_TYPE_VALUE[7+rx_byte*8 -: 8]) begin
              if (rx_byte == 0) begin
                rx_state <= HRD;
                rx_byte  <= 4'b0000;
              end else begin
                rx_byte <= rx_byte-1;
              end
            end else begin
              rx_state <= IDLE;
              rx_byte  <= 4'b0000;
            end
          end else begin
            rx_state <= IDLE;
            rx_byte  <= 4'b0000;
          end
        end

        HRD:
        begin
          if(DATA_VALID_RX == 1) begin
            // Check for expected value in ARP Request
            if (DATA_RX == HRD_VALUE[7+rx_byte*8 -: 8]) begin
              if (rx_byte == HRD_SIZE-1) begin
                rx_state <= HLN;
                rx_byte  <= 4'b0000;
              end else begin
                rx_byte <= rx_byte+1;
              end
            end else begin
              rx_state <= IDLE;
              rx_byte  <= 4'b0000;
            end
          end else begin
            rx_state <= IDLE;
            rx_byte  <= 4'b0000;
          end
        end

        HLN:
        begin
          if(DATA_VALID_RX == 1) begin
            if (rx_byte == HLN_SIZE-1) begin
              rx_byte  <= 4'b0000;
              // Check for expected value in ARP Request
              if (DATA_RX == HLN_VALUE[7+rx_byte*8 -: 8])
                rx_state <= PLN;
              else
                rx_state <= IDLE;
            end else begin
              rx_byte <= rx_byte+1;
            end
          end else begin
            rx_state <= IDLE;
            rx_byte  <= 4'b0000;
          end
        end

        PLN:
        begin
          if(DATA_VALID_RX == 1) begin
            if (rx_byte == PLN_SIZE-1) begin
              rx_byte  <= 4'b0000;
              // Check for expected value in ARP Request
              if (DATA_RX == PLN_VALUE[7+rx_byte*8 -: 8])
                rx_state <= OP;
              else
                rx_state <= IDLE;
            end else begin
              rx_byte <= rx_byte+1;
            end
          end else begin
            rx_state <= IDLE;
            rx_byte  <= 4'b0000;
          end
        end

        OP:
        begin
          if(DATA_VALID_RX == 1) begin
            if (rx_byte == OP_SIZE-1) begin
              rx_byte  <= 4'b0000;
              // Check for expected value in ARP Request
              if (DATA_RX == OP_VALUE[7+rx_byte*8 -: 8])
                rx_state <= ETH_TYPE;
              else
                rx_state <= SHA;
            end else begin
              rx_byte <= rx_byte+1;
            end
          end else begin
            rx_state <= IDLE;
            rx_byte  <= 4'b0000;
          end
        end

        SHA:
        begin
          if(DATA_VALID_RX == 1) begin
            if (rx_byte == SHA_SIZE-1) begin
              rx_byte  <= 4'b0000;
              rx_state <= SPA;
            end else begin
              rx_byte <= rx_byte+1;
            end
          end else begin
            rx_state <= IDLE;
            rx_byte  <= 4'b0000;
          end
        end

        SPA:
        begin
          if(DATA_VALID_RX == 1) begin
            if (rx_byte == SPA_SIZE-1) begin
              rx_byte  <= 4'b0000;
              rx_state <= THA;
            end else begin
              rx_byte <= rx_byte+1;
            end
          end else begin
            rx_state <= IDLE;
            rx_byte  <= 4'b0000;
          end
        end

        THA:
        begin
          if(DATA_VALID_RX == 1) begin
            if (rx_byte == THA_SIZE-1) begin
              rx_byte  <= 4'b0000;
              rx_state <= IDLE;
            end else begin
              rx_byte <= rx_byte+1;
            end
          end else begin
            rx_state <= IDLE;
            rx_byte  <= 4'b0000;
          end
        end

        TPA:
        begin
          if(DATA_VALID_RX == 1) begin
            // Check for expected value in ARP Request
            if (DATA_RX == MY_IPV4[7+rx_byte*8 -: 8]) begin
              if (rx_byte == TPA_SIZE-1) begin
                arp_req  <= 1;
                rx_byte  <= 4'b0000;
                rx_state <= WAIT_FOR_HS;
              end else begin
                rx_byte <= rx_byte+1;
              end
            end else begin
              rx_state <= IDLE;
              rx_byte  <= 4'b0000;
            end
          end else begin
            rx_state <= IDLE;
            rx_byte  <= 4'b0000;
          end
        end

        WAIT_FOR_HS:
        begin
          rx_state <= IDLE;
          rx_byte  <= 4'b0000;
        end

        default:
          rx_state <= IDLE;

      endcase
    end
  end

  // ARP Request CDC
  always @ (posedge CLK_TX)
  begin
    if(ARESET)
      arp_req_tx <= 2'b00;
    else begin
      arp_req_tx[0] <= arp_req;
      arp_req_tx[1] <= arp_req_tx[0];
    end
  end

  // Send out ARP
  always @ (posedge CLK_TX)
  begin
    if(ARESET) begin
      DATA_VALID_TX <= 0;
      tx_state      <= IDLE;
      tx_byte       <= 4'b0000;
    end else begin
      case (tx_state)

        IDLE:
        begin
          if(arp_req_tx[1] == 1 ) begin
            tx_state      <= DEST_MAC;
            tx_byte       <= 4'b0000;
            DATA_VALID_TX <= 1;
          end
        end

        DEST_MAC:
        begin
          DATA_TX <= THIER_MAC[7+tx_byte*8 -: 8];
          if (tx_byte == DEST_MAC_SIZE-1) begin
            tx_byte  <= 4'b0000;
            tx_state <= SRC_MAC;
          end else begin
            // For the first byte, wait for awk
            if (tx_byte == 0) begin
              if (DATA_ACK_TX == 1)
                tx_byte <= tx_byte+1;
            end else
              tx_byte <= tx_byte+1;
          end
        end

        SRC_MAC:
        begin
          DATA_TX <= MY_MAC[7+tx_byte*8 -: 8];
          if (tx_byte == SRC_MAC_SIZE-1) begin
            tx_byte  <= 4'b0000;
            tx_state <= ETH_TYPE;
          end else begin
            tx_byte <= tx_byte+1;
          end
        end

        ETH_TYPE:
        begin
          DATA_TX <= ETH_TYPE_VALUE[7+tx_byte*8 -: 8];
          if (tx_byte == ETH_TYPE_SIZE-1) begin
            tx_byte  <= 4'b0000;
            tx_state <= HRD;
          end else begin
            tx_byte <= tx_byte+1;
          end
        end

        HRD:
        begin
          DATA_TX <= HRD_VALUE[7+tx_byte*8 -: 8];
          if (tx_byte == HRD_SIZE-1) begin
            tx_byte  <= 4'b0000;
            tx_state <= HLN;
          end else begin
            tx_byte <= tx_byte+1;
          end
        end

        HLN:
        begin
          DATA_TX <= HLN_VALUE[7+tx_byte*8 -: 8];
          if (tx_byte == HLN_SIZE-1) begin
            tx_byte  <= 4'b0000;
            tx_state <= PLN;
          end else begin
            tx_byte <= tx_byte+1;
          end
        end

        PLN:
        begin
          DATA_TX <= PLN_VALUE[7+tx_byte*8 -: 8];
          if (tx_byte == PLN_SIZE-1) begin
            tx_byte  <= 4'b0000;
            tx_state <= OP;
          end else begin
            tx_byte <= tx_byte+1;
          end
        end

        OP:
        begin
          DATA_TX <= OP_VALUE[7+tx_byte*8 -: 8];
          if (tx_byte == OP_SIZE-1) begin
            tx_byte  <= 4'b0000;
            tx_state <= SHA;
          end else begin
            tx_byte <= tx_byte+1;
          end
        end

        SHA:
        begin
          DATA_TX <= MY_MAC[7+tx_byte*8 -: 8];
          if (tx_byte == SHA_SIZE-1) begin
            tx_byte  <= 4'b0000;
            tx_state <= SPA;
          end else begin
            tx_byte <= tx_byte+1;
          end
        end

        SPA:
        begin
          DATA_TX <= MY_IPV4[7+tx_byte*8 -: 8];
          if (tx_byte == SPA_SIZE-1) begin
            tx_byte  <= 4'b0000;
            tx_state <= THA;
          end else begin
            tx_byte <= tx_byte+1;
          end
        end

        THA:
        begin
          DATA_TX <= THIER_MAC[7+tx_byte*8 -: 8];
          if (tx_byte == THA_SIZE-1) begin
            tx_byte  <= 4'b0000;
            tx_state <= TPA;
          end else begin
            tx_byte <= tx_byte+1;
          end
        end

        TPA:
        begin
          DATA_TX <= THIER_IPV4[7+tx_byte*8 -: 8];
          if (tx_byte == TPA_SIZE-1) begin
            tx_byte       <= 4'b0000;
            tx_state      <= IDLE;
            DATA_VALID_TX <= 1'b0;
          end else begin
            tx_byte <= tx_byte+1;
          end
        end

        default:
          tx_state <= IDLE;

      endcase
    end
  end

endmodule
