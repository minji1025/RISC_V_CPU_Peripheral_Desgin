`timescale 1ns / 1ps

module fndController (
    input  logic        clk,
    input  logic        reset,
    input  logic        ce,
    input  logic        we,
    input  logic [31:0] w_data,
    output logic [31:0] rdata,
    output logic [ 7:0] fndFont,
    output logic [ 3:0] fndCom
);

  logic [3:0] w_digit_1, w_digit_10, w_digit_100, w_digit_1000;
  logic [3:0] w_digit;
  logic [1:0] w_count;
  logic w_clk_1khz;

  logic [13:0] FNDR;
  always_ff @(posedge clk, posedge reset) begin : FND
    if (reset) begin
      FNDR <= 0;
    end else begin
      if (ce & we) FNDR <= w_data[13:0];
    end
  end

  always_comb begin
    if (ce) begin
      rdata = {18'b0, FNDR};
    end
  end

  clkDiv_FND #(
      .MAX_COUNT(100_000)
  ) U_ClkDiv (  // parameter에 매개변수와 같이 값 입력
      .clk  (clk),
      .reset(reset),
      .o_clk(w_clk_1khz)
  );

  counter_FND #(
      .MAX_COUNT(4)
  ) U_Counter_2bit (
      .clk  (w_clk_1khz),
      .reset(reset),
      .count(w_count)
  );

  decoder_FND U_Decoder_2x4 (
      .x(w_count),
      .y(fndCom)
  );

  digitSplitter U_DigitSplitter (
      .i_digit     (FNDR),         // 0부터 9999까지 나타내는 bit수
      .o_digit_1   (w_digit_1),
      .o_digit_10  (w_digit_10),
      .o_digit_100 (w_digit_100),
      .o_digit_1000(w_digit_1000)
  );

  mux_FND U_Mux_4x1 (
      .sel(w_count),
      .x0 (w_digit_1),
      .x1 (w_digit_10),
      .x2 (w_digit_100),
      .x3 (w_digit_1000),
      .y  (w_digit)
  );

  BCDtoSEG U_BcdToSeg (  // 숫자를 segment모양으로 출력
      .bcd(w_digit),
      .seg(fndFont)
  );

endmodule

module digitSplitter (
    input  logic [13:0] i_digit,      // 0부터 9999까지 나타내는 bit수
    output logic [ 3:0] o_digit_1,
    output logic [ 3:0] o_digit_10,
    output logic [ 3:0] o_digit_100,
    output logic [ 3:0] o_digit_1000
);

  assign o_digit_1 = (i_digit % 60) % 10;
  assign o_digit_10 = (i_digit % 60) / 10;
  assign o_digit_100 = (i_digit / 60) % 10;
  assign o_digit_1000 = (i_digit / 60) / 10;

  // assign o_digit_1    = i_digit % 10;
  // assign o_digit_10   = i_digit / 10 % 10;
  // assign o_digit_100  = i_digit / 100 % 10;
  // assign o_digit_1000 = i_digit / 1000 % 10;
endmodule

module mux_FND (
    input  logic [1:0] sel,
    input  logic [3:0] x0,
    input  logic [3:0] x1,
    input  logic [3:0] x2,
    input  logic [3:0] x3,
    output logic [3:0] y
);
  always_comb begin : mux
    case (sel)
      2'b00:   y = x0;
      2'b01:   y = x1;
      2'b10:   y = x2;
      2'b11:   y = x3;
      default: y = x0;
    endcase
  end

endmodule

module BCDtoSEG (  // 숫자를 segment모양으로 출력
    input  logic [3:0] bcd,
    output logic [7:0] seg
);
  always_comb begin : decoder
    case (bcd)
      4'h0: seg = 8'hc0;
      4'h1: seg = 8'hf9;
      4'h2: seg = 8'ha4;
      4'h3: seg = 8'hb0;
      4'h4: seg = 8'h99;
      4'h5: seg = 8'h92;
      4'h6: seg = 8'h82;
      4'h7: seg = 8'hf8;
      4'h8: seg = 8'h80;
      4'h9: seg = 8'h90;
      4'ha: seg = 8'h88;
      4'hb: seg = 8'h83;
      4'hc: seg = 8'hc6;
      4'hd: seg = 8'ha1;
      4'he: seg = 8'h86;
      4'hf: seg = 8'h8e;
      default: seg = 8'hff;
    endcase
  end

endmodule

module decoder_FND (
    input  logic [1:0] x,
    output logic [3:0] y
);
  always_comb begin : decoder
    case (x)
      2'b00:   y = 4'b1110;
      2'b01:   y = 4'b1101;
      2'b10:   y = 4'b1011;
      2'b11:   y = 4'b0111;
      default: y = 4'b1111;
    endcase
  end

endmodule

module counter_FND #(
    parameter MAX_COUNT = 4
) (  // parameter는 define과 유사기능
    input  logic                         clk,
    input  logic                         reset,
    output logic [$clog2(MAX_COUNT)-1:0] count
);
  logic [$clog2(MAX_COUNT)-1:0] counter = 0;

  assign count = counter;

  always @(posedge clk, posedge reset) begin  // 비동기 reset
    if (reset == 1'b1) begin
      counter <= 0;
    end else begin
      if (counter == MAX_COUNT - 1) begin
        counter <= 0;
      end else begin
        counter <= counter + 1;
      end
    end
  end
endmodule

module clkDiv_FND #(
    parameter MAX_COUNT = 100
) (
    input  logic clk,
    input  logic reset,
    output logic o_clk
);
  logic [$clog2(MAX_COUNT)-1:0] counter = 0;
  logic r_tick = 0;

  assign o_clk = r_tick;

  always @(posedge clk, posedge reset) begin
    if (reset) begin
      counter <= 0;
    end else begin
      if (counter == (MAX_COUNT - 1)) begin
        counter <= 0;
        r_tick  <= 1'b1;
      end else begin
        counter <= counter + 1;
        r_tick  <= 1'b0;
      end
    end
  end
endmodule
