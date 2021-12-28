`timescale 1ns/1ns

module arp_response_tb();

  reg ARESET;
  reg [47:0] MY_MAC;
  reg [31:0] MY_IPV4;
  reg CLK_RX;
  reg DATA_VALID_RX;
  reg [7:0] DATA_RX;
  reg CLK_TX;
  reg DATA_ACK_TX;
  wire DATA_VALID_TX;
  wire [7:0] DATA_TX;

  reg [31:0] THEIR_IPV4;
  reg [47:0] THEIR_MAC;

  reg [31:0] error_count;

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
  localparam ETH_TYPE_VALUE      = 16'h0806;
  localparam HRD_VALUE           = 16'h0001;
  localparam PRO_VALUE           = 16'h0800;
  localparam HLN_VALUE           = 8'h06;
  localparam PLN_VALUE           = 8'h04;
  localparam OP_VALUE            = 16'h0001;


  task send_arp_request (input [31:0] dest_ipv4_inst);
    begin
      @(posedge CLK_RX);
      DATA_VALID_RX = 1;
      //DEST MAC
      for (integer i = DEST_MAC_SIZE-1; i>=0; i=i-1 ) begin
        DATA_RX = 8'hFF;
        @(posedge CLK_RX);
      end
      //SRC MAC
      for (integer i = SRC_MAC_SIZE-1; i>=0; i=i-1 ) begin
        DATA_RX = THEIR_MAC[7+8*i -: 8];
        @(posedge CLK_RX);
      end
      //ETH TYPE
      for (integer i = ETH_TYPE_SIZE-1; i>=0; i=i-1 ) begin
        DATA_RX = ETH_TYPE_VALUE[7+8*i -: 8];
        @(posedge CLK_RX);
      end
      //HRD
      for (integer i = HRD_SIZE-1; i>=0; i=i-1 ) begin
        DATA_RX = HRD_VALUE[7+8*i -: 8];
        @(posedge CLK_RX);
      end
      //PRO
      for (integer i = PRO_SIZE-1; i>=0; i=i-1 ) begin
        DATA_RX = PRO_VALUE[7+8*i -: 8];
        @(posedge CLK_RX);
      end
      //HLN
      for (integer i = HLN_SIZE-1; i>=0; i=i-1 ) begin
        DATA_RX = HLN_VALUE[7+8*i -: 8];
        @(posedge CLK_RX);
      end
      //PLN
      for (integer i = PLN_SIZE-1; i>=0; i=i-1 ) begin
        DATA_RX = PLN_VALUE[7+8*i -: 8];
        @(posedge CLK_RX);
      end
      //OP
      for (integer i = OP_SIZE-1; i>=0; i=i-1 ) begin
        DATA_RX = OP_VALUE[7+8*i -: 8];
        @(posedge CLK_RX);
      end
      //SHA
      for (integer i = SHA_SIZE-1; i>=0; i=i-1 ) begin
        DATA_RX = THEIR_MAC[7+8*i -: 8];
        @(posedge CLK_RX);
      end
      //SPA
      for (integer i = SPA_SIZE-1; i>=0; i=i-1 ) begin
        DATA_RX = THEIR_IPV4[7+8*i -: 8];
        @(posedge CLK_RX);
      end
      //THA
      for (integer i = THA_SIZE-1; i>=0; i=i-1 ) begin
        DATA_RX = 8'd0;
        @(posedge CLK_RX);
      end
      //TPA
      for (integer i = TPA_SIZE-1; i>=0; i=i-1 ) begin
        DATA_RX = dest_ipv4_inst[7+8*i -: 8];
        @(posedge CLK_RX);
      end
      DATA_VALID_RX = 0;
      @(posedge CLK_RX);
    end
  endtask

  task check_arp_response ();
    begin
      @(posedge DATA_VALID_TX);
      repeat (5) @(posedge CLK_TX);
      DATA_ACK_TX = 1;
      @(posedge CLK_TX);
      DATA_ACK_TX = 0;
      //DEST MAC
      for (integer i = DEST_MAC_SIZE-1; i>=0; i=i-1 ) begin
        assert (DATA_TX == THEIR_MAC[7+8*i -: 8]) else begin $error("Byte %1d of Dest MAC: Recieved: %h Expected: %h",i, DATA_TX, THEIR_MAC[7+8*i -: 8]); error_count++;end
        @(posedge CLK_TX);
      end
      //SRC MAC
      for (integer i = SRC_MAC_SIZE-1; i>=0; i=i-1 ) begin
        assert (DATA_TX == MY_MAC[7+8*i -: 8]) else begin $error("Byte %1d of Src MAC: Recieved: %h Expected: %h",i, DATA_TX, MY_MAC[7+8*i -: 8]); error_count++;end
        @(posedge CLK_TX);
      end
      //ETH_TYPE
      for (integer i = ETH_TYPE_SIZE-1; i>=0; i=i-1 ) begin
        assert (DATA_TX == ETH_TYPE_VALUE[7+8*i -: 8]) else begin $error("Byte %1d of ETH_TYPE: Recieved: %h Expected: %h",i, DATA_TX, ETH_TYPE_VALUE[7+8*i -: 8]); error_count++;end
        @(posedge CLK_TX);
      end
      //HRD
      for (integer i = HRD_SIZE-1; i>=0; i=i-1 ) begin
        assert (DATA_TX == HRD_VALUE[7+8*i -: 8]) else begin $error("Byte %1d of HRD: Recieved: %h Expected: %h",i, DATA_TX, HRD_VALUE[7+8*i -: 8]); error_count++;end
        @(posedge CLK_TX);
      end
      //PRO
      for (integer i = PRO_SIZE-1; i>=0; i=i-1 ) begin
        assert (DATA_TX == PRO_VALUE[7+8*i -: 8]) else begin $error("Byte %1d of PRO: Recieved: %h Expected: %h",i, DATA_TX, PRO_VALUE[7+8*i -: 8]); error_count++;end
        @(posedge CLK_TX);
      end
      //HLN
      for (integer i = HLN_SIZE-1; i>=0; i=i-1 ) begin
        assert (DATA_TX == HLN_VALUE[7+8*i -: 8]) else begin $error("Byte %1d of HLN: Recieved: %h Expected: %h",i, DATA_TX, HLN_VALUE[7+8*i -: 8]); error_count++;end
        @(posedge CLK_TX);
      end
      //PLN
      for (integer i = PLN_SIZE-1; i>=0; i=i-1 ) begin
        assert (DATA_TX == PLN_VALUE[7+8*i -: 8]) else begin $error("Byte %1d of PLN: Recieved: %h Expected: %h",i, DATA_TX, PLN_VALUE[7+8*i -: 8]); error_count++;end
        @(posedge CLK_TX);
      end
      //OP
      for (integer i = OP_SIZE-1; i>=0; i=i-1 ) begin
        assert (DATA_TX == OP_VALUE[7+8*i -: 8]) else begin $error("Byte %1d of OP: Recieved: %h Expected: %h",i, DATA_TX, OP_VALUE[7+8*i -: 8]); error_count++;end
        @(posedge CLK_TX);
      end
      //SHA
      for (integer i = SHA_SIZE-1; i>=0; i=i-1 ) begin
        assert (DATA_TX == MY_MAC[7+8*i -: 8]) else begin $error("Byte %1d of SHA: Recieved: %h Expected: %h",i, DATA_TX, MY_MAC[7+8*i -: 8]); error_count++;end
        @(posedge CLK_TX);
      end
      //SPA
      for (integer i = SPA_SIZE-1; i>=0; i=i-1 ) begin
        assert (DATA_TX == MY_IPV4[7+8*i -: 8]) else begin $error("Byte %1d of SPA: Recieved: %h Expected: %h",i, DATA_TX, MY_IPV4[7+8*i -: 8]); error_count++;end
        @(posedge CLK_TX);
      end
      //THA
      for (integer i = THA_SIZE-1; i>=0; i=i-1 ) begin
        assert (DATA_TX == THEIR_MAC[7+8*i -: 8]) else begin $error("Byte %1d of THA: Recieved: %h Expected: %h",i, DATA_TX, THEIR_MAC[7+8*i -: 8]); error_count++;end
        @(posedge CLK_TX);
      end
      //TPA
      for (integer i = TPA_SIZE-1; i>=0; i=i-1 ) begin
        assert (DATA_TX == THEIR_IPV4[7+8*i -: 8]) else begin $error("Byte %1d of TPA: Recieved: %h Expected: %h",i, DATA_TX, THEIR_IPV4[7+8*i -: 8]); error_count++;end
        @(posedge CLK_TX);
      end
      @(posedge CLK_TX);

    end
  endtask

  arp_response DUT ( .ARESET(ARESET),
                     .MY_MAC(MY_MAC),
                     .MY_IPV4(MY_IPV4),
                     .CLK_RX(CLK_RX),
                     .DATA_VALID_RX(DATA_VALID_RX),
                     .DATA_RX(DATA_RX),
                     .CLK_TX(CLK_TX),
                     .DATA_ACK_TX(DATA_ACK_TX),
                     .DATA_VALID_TX(DATA_VALID_TX),
                     .DATA_TX(DATA_TX)
                      );

  // 125MHz clock from GbE
  always begin
    #4;
    CLK_RX = 0;
    #4;
    CLK_RX = 1;
  end

  // 125MHz clock from oscillator
  always begin
    CLK_TX = 0;
    #4;
    CLK_TX = 1;
    #4;
  end

  // Generate Test Frames
  initial begin
    // Initial Values
    MY_MAC    = 48'h00_02_23_01_02_03;
    MY_IPV4   = 32'hC0_A8_01_02;
    THEIR_MAC = 48'h00_01_42_00_5F_68;
    THEIR_IPV4 =32'hC0_A8_01_01;
    ARESET    = 1;
    DATA_VALID_RX = 0;

    // Handle reset
    #10;
    ARESET  = 0;
    #10;

    //Send Valid Packet
    send_arp_request(MY_IPV4);
    repeat (10) @(posedge CLK_TX);
    //Send Invalid Packet
    send_arp_request(32'hDEAD_BEEF);
    repeat (10) @(posedge CLK_TX);
    //Send Valid Packet
    send_arp_request(MY_IPV4);
  end

  // Check for expected ARP Responses
  initial begin
    // Initial Values
    DATA_ACK_TX  = 0;
    error_count  = 0;

    // Check for 2 valid packets
    check_arp_response();
    check_arp_response();

    // Output test results
    if (error_count > 0)
    begin
      $display("----------------------------------");
      $display("Simulation Failed");
      $display("Errors detected: %4d ",error_count);
      $display("----------------------------------");
    end else begin
      $display("----------------------------------");
      $display("Simulation Successful");
      $display("----------------------------------");
    end
    #100;
    $finish;
  end

  // Timeout if simulation hangs
  initial begin
    #2000;
    $display("----------------------------------");
    $display("Timeout Reached: Simulation Failed");
    $display("----------------------------------");
    $finish;
  end

endmodule