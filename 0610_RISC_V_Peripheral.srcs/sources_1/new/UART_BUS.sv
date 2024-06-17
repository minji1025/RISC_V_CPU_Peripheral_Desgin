`timescale 1ns / 1ps

module UART_BUS (
    input  logic        clk,
    input  logic        reset,
    input  logic        ce,
    input  logic        we,
    input  logic [11:0] addr,
    input  logic [31:0] wdata,
    output logic [31:0] rdata,
    input  logic        UART_RX1,
    output logic        UART_TX1,
    input  logic        UART_RX2,
    output logic        UART_TX2
);

  logic [1:0] cePort;
  logic [31:0] w_rxData1, w_rxData2;

  BUS_UART U_Bus_uart (
      .address(addr),
      .ce(ce),
      .slave_sel(cePort),
      .slave_rdata1(w_rxData1),
      .slave_rdata2(w_rxData2),
      .master_rdata(rdata)
  );

  uartx U_UART1 (
      .clk  (clk),
      .reset(reset),

      .RX(UART_RX1),
      .TX(UART_TX1),
      .ce(cePort[0]),
      .we(we),
      .addr(addr[7:0]),
      .wdata(wdata),
      .rdata(w_rxData1)
  );

  uartx U_UART2 (
      .clk  (clk),
      .reset(reset),

      .RX(UART_RX2),
      .TX(UART_TX2),
      .ce(cePort[1]),
      .we(we),
      .addr(addr[7:0]),
      .wdata(wdata),
      .rdata(w_rxData2)
  );

endmodule

module BUS_UART (
    input  logic [11:0] address,
    input  logic        ce,
    output logic [ 1:0] slave_sel,
    input  logic [31:0] slave_rdata1,
    input  logic [31:0] slave_rdata2,
    output logic [31:0] master_rdata
);

  decoder_UART U_UART_Decoder (
      .x (address),
      .ce(ce),
      .y (slave_sel)
  );


  mux_UART U_MUX_UART_rdata (
      .sel(address),
      .ce (ce),
      .a  (slave_rdata1),
      .b  (slave_rdata2),
      .y  (master_rdata)
  );


endmodule

module decoder_UART (
    input logic [11:0] x,
    input logic ce,
    output logic [1:0] y
);

  always_comb begin : decoder
    y = 2'bx;
    if (ce) begin
      case (x[11:8])  //Address
        4'h4: y = 2'b01;
        4'h6: y = 2'b10;
        default: y = 2'bx;
      endcase
    end
  end

endmodule

module mux_UART (
    input  logic [11:0] sel,
    input  logic        ce,
    input  logic [31:0] a,
    input  logic [31:0] b,
    output logic [31:0] y
);
  always_comb begin : decoder
    y = 32'bx;
    if (ce) begin
      case (sel[11:8])  //Address
        4'h4: y = a;
        4'h6: y = b;
        default: y = 32'bx;
      endcase
    end
  end

endmodule


module uartx (
    input logic clk,
    input logic reset,

    input  logic RX,
    output logic TX,

    input  logic        ce,
    input  logic        we,
    input  logic [ 7:0] addr,
    input  logic [31:0] wdata,
    output logic [31:0] rdata
);

  logic [31:0] UART_SR, UART_RDR, UART_TDR, UART_BRR, UART_CR;
  logic rx_empty, rx_en, tx_en, rx_en_next, tx_en_next;


  assign UART_SR[1] = ~rx_empty;


  always_ff @(posedge clk, posedge reset) begin : UART_REG
    if (reset) begin
      UART_TDR <= 32'bx;
      UART_BRR <= 32'd1;
      UART_CR <= 32'd0;
      rx_en <= 1'b0;
      tx_en <= 1'b0;
    end else begin
      rx_en <= rx_en_next;
      tx_en <= tx_en_next;
      UART_TDR <= 32'bx;
      if (ce & we) begin
        case (addr[7:0])
          8'h08: UART_TDR <= wdata;
          8'h0c: UART_BRR <= wdata;
          8'h10: UART_CR <= wdata;
        endcase
      end
    end
  end

  always_comb begin
    rdata = 32'bx;
    rx_en_next = 1'b0;
    tx_en_next = 1'b0;
    if (ce) begin
      case (addr[7:0])
        8'h00:   rdata = UART_SR;
        8'h04: begin
          if (UART_SR[1]) begin
            rdata = UART_RDR;
            rx_en_next = 1'b1;
          end
        end
        8'h08: begin
          rdata = UART_TDR;
          if (we) tx_en_next = 1'b1;
        end
        8'h0c:   rdata = UART_BRR;
        8'h10:   rdata = UART_CR;
        default: rdata = 32'bx;
      endcase
    end
  end


  uart_fifo U_UART_FIFO (
      .clk  (clk),
      .reset(reset),

      .UART_CR (UART_CR[16:0]),
      .UART_BRR(UART_BRR[4:0]),

      .tx_en  (tx_en),
      .tx_data(UART_TDR[7:0]),
      .tx_full(),

      .rx_en(rx_en),
      .rx_data(UART_RDR[7:0]),
      .rx_empty(rx_empty),

      .RX(RX),
      .TX(TX)
  );

  // uartTest uartdebug (
  //     .clk(clk),  // input wire clk


  //     .probe0(we),  // input wire [0:0]  probe0  
  //     .probe1(tx_en),  // input wire [0:0]  probe1 
  //     .probe2(UART_SR[1]),  // input wire [0:0]  probe2 
  //     .probe3(UART_TDR[7:0]),  // input wire [7:0]  probe3 
  //     .probe4(addr[7:0])  // input wire [7:0]  probe4
  // );

endmodule
///////////////////////////////uart Module///////////////////////////////////////////

module uart (
    input        clk,
    input        reset,
    //enable
    input        UE,
    input        RE,
    input        TE,
    input  [4:0] BRR,
    // transmitter
    input        start,
    input  [7:0] tx_data,
    output       tx,
    output       tx_done,
    //Receiver
    input        rx,
    output [7:0] rx_data,
    output       rx_done
);

  wire w_br_tick;

  baudrate_generator U_BAUDRATE_GEN (
      .clk(clk),
      .reset(reset),
      .UE(UE),
      .BRR(BRR),
      .br_tick(w_br_tick)
  );

  transmitter U_transmitter (
      .clk(clk),
      .reset(reset),
      .start(start),
      .TE(TE),
      .tx_data(tx_data),
      .br_tick(w_br_tick),
      .tx(tx),
      .tx_done(tx_done)
  );

  receiver U_Receiver (
      .clk(clk),
      .reset(reset),
      .br_tick(w_br_tick),
      .RE(RE),
      .rx(rx),
      .rx_data(rx_data),
      .rx_done(rx_done)
  );

endmodule

module baudrate_generator (
    input clk,
    input reset,
    input UE,
    input [4:0] BRR,
    output br_tick
);
  reg [32 - 1 : 0] counter_reg, counter_next, Baudrate;
  reg tick_reg, tick_next;

  assign br_tick = tick_reg;

  always @(*) begin
    case (BRR)
      5'b00001: Baudrate = 32'd9600;
      5'b00010: Baudrate = 32'd19200;
      5'b00100: Baudrate = 32'd38400;
      5'b01000: Baudrate = 32'd57600;
      5'b10000: Baudrate = 32'd115200;
      default:  Baudrate = 32'd9600;
    endcase
  end

  always @(posedge clk, posedge reset) begin
    if (reset) begin
      counter_reg <= 0;
      tick_reg <= 1'b0;
    end else begin
      counter_reg <= counter_next;
      tick_reg <= tick_next;
    end
  end

  always @(*) begin
    counter_next = counter_reg;
    if (UE) begin
      if (counter_reg == 100_000_000 / Baudrate / 16 - 1) begin
        //  if (counter_reg == 3) begin
        counter_next = 0;
        tick_next = 1'b1;
      end else begin
        counter_next = counter_reg + 1;
        tick_next = 1'b0;
      end
    end
  end

endmodule

module transmitter (
    input        clk,
    input        reset,
    input        start,
    input        TE,
    input  [7:0] tx_data,
    input        br_tick,
    output       tx,
    output       tx_done
);

  localparam IDLE = 0, START = 1, DATA = 2, STOP = 3;
  reg [1:0] state, state_next;
  reg tx_reg, tx_next;
  reg tx_done_reg, tx_done_next;
  reg [7:0] data_tmp_reg, data_tmp_next;
  reg [3:0] br_cnt_next, br_cnt_reg;
  reg [2:0] data_bit_cnt_reg, data_bit_cnt_next;

  assign tx      = tx_reg;
  assign tx_done = tx_done_reg;

  always @(posedge clk, posedge reset) begin
    if (reset) begin
      state            <= IDLE;
      tx_reg           <= 1'b1;
      tx_done_reg      <= 1'b0;
      br_cnt_reg       <= 1'b0;
      data_bit_cnt_reg <= 1'b0;
      data_tmp_reg     <= 0;
    end else begin
      state            <= state_next;
      tx_reg           <= tx_next;
      tx_done_reg      <= tx_done_next;
      br_cnt_reg       <= br_cnt_next;
      data_bit_cnt_reg <= data_bit_cnt_next;
      data_tmp_reg     <= data_tmp_next;
    end
  end

  always @(*) begin
    state_next        = state;
    data_tmp_next     = data_tmp_reg;
    tx_next           = tx_reg;
    br_cnt_next       = br_cnt_reg;
    data_bit_cnt_next = data_bit_cnt_reg;
    tx_done_next      = tx_done_reg;
    if (TE) begin
      case (state)
        IDLE: begin
          tx_done_reg = 1'b0;
          tx_next     = 1'b1;
          if (start) begin
            state_next        = START;
            data_tmp_next     = tx_data;
            br_cnt_next       = 0;
            data_bit_cnt_next = 0;
          end
        end
        START: begin
          tx_next = 1'b0;
          if (br_tick) begin
            if (br_cnt_reg == 15) begin
              state_next  = DATA;
              br_cnt_next = 0;
            end else begin
              br_cnt_next = br_cnt_reg + 1;
            end
          end
        end
        DATA: begin
          tx_next = data_tmp_reg[0];
          if (br_tick) begin
            if (br_cnt_reg == 15) begin
              if (data_bit_cnt_reg == 7) begin
                state_next  = STOP;
                br_cnt_next = 0;
              end else begin
                data_bit_cnt_next = data_bit_cnt_reg + 1;
                data_tmp_next     = {1'b0, data_tmp_reg[7:1]};
                br_cnt_next       = 0;
              end

            end else begin
              br_cnt_next = br_cnt_reg + 1;
            end
          end
        end
        STOP: begin
          tx_next = 1'b1;
          if (br_tick) begin
            if (br_cnt_reg == 15) begin
              tx_done_reg = 1'b1;
              state_next  = IDLE;
            end else begin
              br_cnt_next = br_cnt_reg + 1;
            end
          end
        end
      endcase
    end
  end

endmodule

module receiver (
    input        clk,
    input        reset,
    input        br_tick,
    input        rx,
    input        RE,
    output [7:0] rx_data,
    output       rx_done
);
  localparam IDLE = 0, START = 1, DATA = 2, STOP = 3;

  reg [1:0] state, state_next;
  reg [7:0] rx_data_reg, rx_data_next;
  reg [4:0] br_cnt_reg, br_cnt_next;
  reg [2:0] data_bit_cnt_next, data_bit_cnt_reg;
  reg rx_done_reg, rx_done_next;

  assign rx_data = rx_data_reg;
  assign rx_done = rx_done_reg;

  always @(posedge clk, posedge reset) begin
    if (reset) begin
      state            <= IDLE;
      rx_data_reg      <= 0;
      rx_done_reg      <= 1'b0;
      br_cnt_reg       <= 1'b0;
      data_bit_cnt_reg <= 1'b0;
    end else begin
      state            <= state_next;
      rx_data_reg      <= rx_data_next;
      rx_done_reg      <= rx_done_next;
      br_cnt_reg       <= br_cnt_next;
      data_bit_cnt_reg <= data_bit_cnt_next;
    end
  end

  always @(*) begin
    state_next        = state;
    br_cnt_next       = br_cnt_reg;
    data_bit_cnt_next = data_bit_cnt_reg;
    rx_data_next      = rx_data_reg;
    rx_done_next      = rx_done_reg;
    if (RE) begin
      case (state)
        IDLE: begin
          rx_done_next = 1'b0;
          if (rx == 1'b0) begin
            br_cnt_next       = 0;
            data_bit_cnt_next = 0;
            rx_data_next      = 0;
            state_next        = START;
          end
        end
        START: begin
          if (br_tick) begin
            if (br_cnt_reg == 7) begin
              br_cnt_next = 0;
              state_next  = DATA;
            end else begin
              br_cnt_next = br_cnt_reg + 1;
            end
          end
        end

        DATA: begin
          if (br_tick) begin
            if (br_cnt_reg == 15) begin
              br_cnt_next  = 0;
              rx_data_next = {rx, rx_data_reg[7:1]};
              if (data_bit_cnt_reg == 7) begin
                state_next = STOP;
              end else begin
                data_bit_cnt_next = data_bit_cnt_reg + 1;
              end
            end else begin
              br_cnt_next = br_cnt_reg + 1;
            end
          end
        end
        STOP: begin
          if (br_tick) begin
            if (br_cnt_reg == 23) begin

              br_cnt_next  = 0;
              state_next   = IDLE;
              rx_done_next = 1'b1;
            end else begin
              br_cnt_next = br_cnt_reg + 1;
            end
          end
        end
      endcase
    end
  end

endmodule
/////////////////////////////////// Uart FIFO Module//////////////////////////////////////

module uart_loop (
    input clk,
    input reset,

    input  RX,
    output TX

);
  wire [7:0] w_rx_data;
  wire w_rx_empty;

  uart_fifo U_uart_fifo (
      .clk  (clk),
      .reset(reset),

      .tx_en  (~w_rx_empty),
      .tx_data(w_rx_data),
      .tx_full(),

      .rx_en(~w_rx_empty),
      .rx_data(w_rx_data),
      .rx_empty(w_rx_empty),

      .RX(RX),
      .TX(TX)
  );


endmodule

module uart_fifo (
    input clk,
    input reset,

    input [16:0] UART_CR,
    input [ 4:0] UART_BRR,


    input tx_en,
    input [7:0] tx_data,
    output tx_full,

    input rx_en,
    output [7:0] rx_data,
    output rx_empty,

    input  RX,
    output TX
);

  wire w_tx_empty;
  wire [7:0] w_tx_data;
  wire w_tx_done;
  wire [7:0] w_rx_data;
  wire w_rx_done;
  assign tx_done = w_tx_done;

  FIFO #(
      .ADDR_WIDTH(8),
      .DATA_WIDTH(8)
  ) U_txfifo (
      .clk  (clk),
      .reset(reset),
      .wr_en(tx_en),
      .full (tx_full),
      .wdata(tx_data),
      .rd_en(w_tx_done),
      .empty(w_tx_empty),
      .rdata(w_tx_data)
  );


  FIFO #(
      .ADDR_WIDTH(8),
      .DATA_WIDTH(8)
  ) U_rxfifo (
      .clk  (clk),
      .reset(reset),
      .wr_en(w_rx_done),
      .full (),
      .wdata(w_rx_data),
      .rd_en(rx_en),
      .empty(rx_empty),
      .rdata(rx_data)
  );


  uart U_uart (
      .clk    (clk),
      .reset  (reset),
      .UE     (UART_CR[0]),
      .RE     (UART_CR[1]),
      .TE     (UART_CR[2]),
      .BRR    (UART_BRR[4:0]),
      .start  (~w_tx_empty),
      .tx_data(w_tx_data),
      .tx     (TX),
      .tx_done(w_tx_done),
      .rx     (RX),
      .rx_data(w_rx_data),
      .rx_done(w_rx_done)
  );

endmodule

module FIFO #(
    parameter ADDR_WIDTH = 3,
    DATA_WIDTH = 8
) (
    input                   clk,
    input                   reset,
    input                   wr_en,
    output                  full,
    input  [DATA_WIDTH-1:0] wdata,
    input                   rd_en,
    output                  empty,
    output [DATA_WIDTH-1:0] rdata
);

  wire [ADDR_WIDTH-1:0] w_waddr, w_raddr;

  register_file #(
      .ADDR_WIDTH(ADDR_WIDTH),
      .DATA_WIDTH(DATA_WIDTH)
  ) U_register_file (
      .clk  (clk),
      .reset(reset),
      .wr_en(wr_en & ~full),
      .waddr(w_waddr),
      .wdata(wdata),
      .raddr(w_raddr),
      .rdata(rdata)
  );

  fifo_control_unit #(
      .ADDR_WIDTH(ADDR_WIDTH)
  ) U_fifo_control_unit (
      .clk  (clk),
      .reset(reset),
      .wr_en(wr_en),
      .full (full),
      .waddr(w_waddr),

      .rd_en(rd_en),
      .empty(empty),
      .raddr(w_raddr)
  );

endmodule

module register_file #(
    parameter ADDR_WIDTH = 3,
    DATA_WIDTH = 8
) (
    input                   clk,
    input                   reset,
    input                   wr_en,
    input  [ADDR_WIDTH-1:0] waddr,
    input  [DATA_WIDTH-1:0] wdata,
    input  [ADDR_WIDTH-1:0] raddr,
    output [DATA_WIDTH-1:0] rdata
);
  reg [DATA_WIDTH-1:0] mem[0:2**ADDR_WIDTH-1];

  always @(posedge clk) begin
    if (wr_en) mem[waddr] <= wdata;
  end

  assign rdata = mem[raddr];
endmodule

module fifo_control_unit #(
    parameter ADDR_WIDTH = 3
) (
    input                   clk,
    input                   reset,
    input                   wr_en,
    output                  full,
    output [ADDR_WIDTH-1:0] waddr,

    input rd_en,
    output empty,
    output [ADDR_WIDTH-1:0] raddr
);

  reg [ADDR_WIDTH-1:0] wr_ptr_reg, wr_ptr_next;
  reg [ADDR_WIDTH-1:0] rd_ptr_reg, rd_ptr_next;
  reg full_reg, full_next;
  reg empty_reg, empty_next;

  assign waddr = wr_ptr_reg;
  assign raddr = rd_ptr_reg;
  assign full  = full_reg;
  assign empty = empty_reg;

  always @(posedge clk, posedge reset) begin
    if (reset) begin
      wr_ptr_reg <= 0;
      rd_ptr_reg <= 0;
      full_reg   <= 1'b0;
      empty_reg  <= 1'b1;
    end else begin
      wr_ptr_reg <= wr_ptr_next;
      rd_ptr_reg <= rd_ptr_next;
      full_reg   <= full_next;
      empty_reg  <= empty_next;
    end
  end

  always @(*) begin
    wr_ptr_next = wr_ptr_reg;
    rd_ptr_next = rd_ptr_reg;
    full_next   = full_reg;
    empty_next  = empty_reg;
    case ({
      wr_en, rd_en
    })
      2'b01: begin  //read
        if (!empty_reg) begin
          full_next   = 1'b0;
          rd_ptr_next = rd_ptr_reg + 1;
          if (rd_ptr_next == wr_ptr_reg) begin
            empty_next = 1'b1;
          end
        end
      end
      2'b10: begin  //write
        if (!full_reg) begin
          empty_next  = 1'b0;
          wr_ptr_next = wr_ptr_reg + 1;
          if (wr_ptr_next == rd_ptr_reg) begin
            full_next = 1'b1;
          end
        end

      end
      2'b11: begin  //write&read
        if (empty_reg) begin
          wr_ptr_next = wr_ptr_reg;
          rd_ptr_next = rd_ptr_reg;
        end else begin
          wr_ptr_next = wr_ptr_reg + 1;
          rd_ptr_next = rd_ptr_reg + 1;
        end
      end
    endcase
  end

endmodule
